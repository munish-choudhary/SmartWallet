# CLAUDE.md

Guidance for Claude Code when working in this repository. Read fully before making changes.

## Project

Non-custodial, multi-chain crypto wallet built with Flutter (iOS + Android).

- **Chains:** EVM (Ethereum, BNB Chain, Polygon, Arbitrum, Base), Solana, Tron, Bitcoin
- **Features:** create/import wallet (mnemonic + private key), portfolio, send/receive, swap, buy/sell, activity, dApp browser, WalletConnect, AI assistant, price alerts, address book, settings/security
- **Priority order:** Security > Correctness > Performance > UI polish. Never trade the first two for the last two.

## Tech Stack

| Concern | Choice |
|---|---|
| State / ViewModel | `flutter_bloc` (Cubit by default, Bloc when events need transformers) |
| DI | `RepositoryProvider` / `MultiRepositoryProvider` (from flutter_bloc) |
| Routing | `go_router` (`StatefulShellRoute` for tabs, redirect guards) |
| Key generation & signing | Trust Wallet Core via our own `ffigen` bindings (`packages/wallet_core_ffi`) |
| Encryption | `cryptography` (+ `cryptography_flutter`): AES-256-GCM, Argon2id |
| Hardware key storage | Custom platform channel `vault_keystore` (Android Keystore / iOS Keychain + Secure Enclave) |
| Secure storage | `flutter_secure_storage` |
| Local DB | Drift (SQLite) |
| Models | `freezed` + `json_serializable` |
| Network | `dio`, `web_socket_channel` |
| Biometrics | `local_auth` |
| WalletConnect | `reown_walletkit` |
| dApp browser | `flutter_inappwebview` |
| Animations | `flutter_animate`, Rive |
| Tests | `flutter_test`, `bloc_test`, `mocktail`, golden tests |

Do **not** introduce Riverpod, Provider (for state), GetX, or get_it. Do not add any new package (especially crypto-related) without asking first.

## Architecture: MVVM + Repository

```
View (Widget)  →  ViewModel (Cubit/Bloc)  →  Repository  →  Service
```

- **View:** UI and animations only. No business logic, no direct repository/service calls. Uses `BlocBuilder` / `BlocSelector` / `BlocListener`.
- **ViewModel (Cubit/Bloc):** holds screen state and exposes actions. One per screen or per cohesive flow. Depends only on repositories.
- **Repository:** single source of truth for a feature's data. Cache-first (Drift, then network). Combines services. Returns `Result<T>`.
- **Service:** thin, stateless wrappers over external things: Wallet Core FFI, RPC/indexer clients, Drift DAOs, platform channels.

Rules:
- Use a separate use-case class **only** when logic spans 2+ repositories (e.g. `PrepareSwap`, `CalculatePortfolioHealth`). Otherwise ViewModel → Repository directly.
- Use **Cubit** by default. Use **Bloc** only when you need event transformers (debounced search, swap quote refresh, signing pipeline state machine).
- Services and repositories are provided at app root via `MultiRepositoryProvider`. Cubits/Blocs are provided at route level via `BlocProvider`.

### Folder Structure

```
lib/
  app/
    app.dart                 # MaterialApp.router, root providers
    router.dart              # single GoRouter instance
    routes.dart              # route path/name constants
    flavors.dart
    theme/                   # colors, typography, glass tokens
  core/
    vault/                   # Vault facade, envelope, KDF, session, keystore channel
    signing/                 # SignRequest, SigningBloc, simulation, risk checks
    chains/
      chain_adapter.dart
      evm/ solana/ tron/ bitcoin/
    network/                 # dio clients, interceptors, websocket prices
    db/                      # Drift database, tables, DAOs
    security/                # FLAG_SECURE, root/jailbreak, clipboard, pinning
    result/                  # Result, AppFailure
    design_system/           # GlassCard, PillButton, OrbButton, sheets, animations
  features/
    onboarding/  portfolio/  token_detail/  send/  receive/  swap/  buy_sell/
    activity/  dapp_browser/  walletconnect/  ai_assistant/  alerts/
    address_book/  notifications/  settings/
packages/
  wallet_core_ffi/           # ffigen bindings to Trust Wallet Core C API
```

Each feature:

```
features/<feature>/
  data/        # <feature>_repository.dart, DTOs
  view_model/  # <screen>_cubit.dart, <screen>_state.dart
  view/        # screens and widgets
```

### State Conventions

States are `freezed` sealed unions:

```dart
@freezed
sealed class PortfolioState with _$PortfolioState {
  const factory PortfolioState.loading() = _Loading;
  const factory PortfolioState.loaded(PortfolioSnapshot data, {@Default(false) bool refreshing}) = _Loaded;
  const factory PortfolioState.failure(AppFailure failure) = _Failure;
}
```

- No nullable-flag soup (`isLoading`, `hasError`, `data?`). Use sealed states.
- **Never** put secrets (mnemonic, private key, PIN, derived keys) in any Bloc/Cubit state.

### Error Handling

- Repositories and services return `Result<T>` (sealed: `Ok<T>` / `Err(AppFailure)`). Do not throw across layer boundaries.
- `AppFailure` is a sealed class (`network`, `insufficientFunds`, `invalidAddress`, `wrongPin`, `vaultLocked`, `userRejected`, `chainError`, ...). UI maps failures to messages.
- Exception messages and failures must never contain secret material.

## Routing (go_router)

- One `GoRouter` in `app/router.dart`. Path and name constants live in `app/routes.dart`. No hardcoded path strings in widgets.
- Main tabs (Portfolio, Swap, Buy/Sell, dApps, Settings) use `StatefulShellRoute.indexedStack`.
- `refreshListenable` listens to `VaultSessionCubit` and `OnboardingStatus`.
- `redirect` order:
  1. No wallet → `/onboarding`
  2. Wallet exists but vault locked → `/lock` (preserve original location in `from` query param, then return after unlock)
  3. Otherwise allow
- **Never** pass mnemonic, private key, PIN, or keys via path params, query params, or `extra`. Sensitive flows read from the Vault inside their own Cubit.
- Sensitive routes (recovery phrase, export key, review/confirm, passcode) must enable screen protection on enter and disable on exit.

## Vault & Key Management (NON-NEGOTIABLE)

All key material lives behind the `Vault` facade in `core/vault/`. No other code may call Wallet Core key/signing APIs or read the encrypted envelope.

### Key Generation (Trust Wallet Core)

- **Create:** `HDWallet(strength: 128)` for 12 words, `256` for 24 words.
- **Derive:** `getKeyForCoin(coinType)` / `getAddressForCoin(coinType)` using Wallet Core's default derivation paths. Custom paths only via an explicit, documented setting.
- **Import mnemonic:** validate with `Mnemonic.isValid` first, then `HDWallet.createWithMnemonic`.
- **Import private key:** validate length and curve per chain (secp256k1 for EVM/Tron/BTC, ed25519 for Solana) via `PrivateKey` before storing.
- **Sign:** `AnySigner.sign(signingInputProto, coinType)` only.
- Never implement BIP39, BIP32/44, key derivation, address encoding, or transaction signing in Dart.

### Encryption at Rest

**What gets encrypted:** the mnemonic (HD wallets) or the raw private key (imported key wallets). Public keys and addresses may be stored in plaintext in Drift.

**Scheme (two layers):**

1. **PIN layer**
   - KDF: **Argon2id** (`m = 64 MiB, t = 3, p = 1` as starting point). Benchmark on a low-end Android device; target 300–800 ms. Run in `Isolate.run`.
   - Fallback (only if Argon2id is not viable on a platform): PBKDF2-HMAC-SHA256, ≥ 600,000 iterations. KDF choice and params are always stored in the envelope.
   - **Salt:** 16 bytes from a CSPRNG (`Random.secure()` or `cryptography` secure random). New salt per wallet and on every PIN change.
   - Output: 32-byte KEK.
   - Cipher: **AES-256-GCM**, 12-byte random nonce generated fresh for every encryption, never reused. AAD = `walletId || envelopeVersion`.
2. **Hardware layer**
   - The serialized PIN-layer envelope is wrapped again with a non-exportable key:
     - Android: Keystore AES-256-GCM key, StrongBox when available, `setUnlockedDeviceRequired(true)`.
     - iOS: Secure Enclave P-256 key, ECIES (`eciesEncryptionCofactorVariableIVX963SHA256AESGCM`), `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
   - **Why:** a 6-digit PIN has only 10^6 combinations. Without hardware binding, an extracted envelope can be brute-forced offline no matter how strong the KDF is.

**Envelope format (before hardware wrap):**

```json
{
  "v": 1,
  "walletId": "uuid",
  "type": "mnemonic | privateKey",
  "kdf": { "alg": "argon2id", "m": 65536, "t": 3, "p": 1 },
  "salt": "base64",
  "nonce": "base64",
  "ct": "base64 (ciphertext + 16-byte GCM tag)"
}
```

**Storage:** the hardware-wrapped envelope goes in `flutter_secure_storage` only. Never in Drift, plain files, SharedPreferences, logs, crash reports, or analytics. Exclude from cloud/device backups (Android `dataExtractionRules` / `fullBackupContent`, iOS `ThisDeviceOnly`).

### PIN Rules

- Minimum 6 digits. The PIN is **never stored**, not even as a hash. Verification = successful GCM decryption (tag check).
- Failed attempt counter stored in secure storage. Lockout with backoff: 5 failures → 1 min, then escalating (5, 15, 60 min). Optional "wipe after 10 failures" is a user setting, off by default, with a clear warning.
- **PIN change:** decrypt with old PIN → re-encrypt with new salt + new nonce → write new envelope → verify it decrypts → delete old. Must be atomic; never leave the user with zero valid envelopes.

### Biometrics (PIN stored behind biometrics)

The user's PIN is stored encrypted, retrievable only after a successful strong biometric check. Biometric unlock then runs the normal PIN unlock path (`PIN → Argon2id → AES-256-GCM decrypt`), so there is one decrypt code path.

**Storage (via `vault_keystore` platform channel, not plain `flutter_secure_storage`):**
- **Android:** dedicated Keystore AES-256-GCM key (`biometric_pin_key`, StrongBox if available) with:
  - `setUserAuthenticationRequired(true)`
  - `setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)` (auth per use, biometric only)
  - `setInvalidatedByBiometricEnrollment(true)`
  - The `Cipher` is unlocked through `BiometricPrompt` with a `CryptoObject`. Ciphertext + IV of the PIN stored in secure storage.
- **iOS:** Keychain item holding the PIN with `SecAccessControl` flags `.biometryCurrentSet`, accessibility `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`, read via `LAContext`.
- **Biometric only.** Do not allow device passcode / device credential as a fallback for this item (`AUTH_DEVICE_CREDENTIAL`, `.userPresence`, `.devicePasscode` are forbidden). Otherwise the phone's lock-screen PIN would bypass the app PIN.
- Only Class 3 / strong biometrics on Android. If the device only has weak biometrics, biometric unlock is unavailable.

**Enable flow:**
1. User opts in (onboarding step or Settings → Security).
2. User enters PIN manually; verify it by successfully decrypting the envelope.
3. Show biometric prompt, encrypt PIN bytes with the biometric-bound key, store ciphertext.
4. Zero the PIN buffer.

**Unlock flow:**
1. Biometric prompt → PIN bytes returned from native as `Uint8List`.
2. Call the normal `unlock(pin)` path inside an isolate.
3. Zero the PIN buffer in `finally`. The PIN never enters Bloc state, logs, or route params, and is never converted to `String`.

**Invalidation and cleanup:**
- Biometric enrollment changed / key invalidated (`KeyPermanentlyInvalidatedException` on Android, item unreadable on iOS) → delete the stored PIN item, fall back to manual PIN, prompt to re-enable.
- Stored PIN fails to decrypt the envelope (stale) → delete the biometric item, fall back to manual PIN. Do not count this against the lockout counter.
- PIN change → re-store the new PIN behind biometrics (requires a fresh biometric prompt) or disable biometrics. Never leave the old PIN stored.
- Biometrics disabled, wallet removed, or app reset → delete the biometric key and stored PIN.
- Device passcode removed (iOS) → item is destroyed by the OS; handle gracefully.

**Actions that always require manual PIN entry (never the biometric-retrieved PIN):**
- Reveal recovery phrase
- Export private key
- Change PIN
- Disable biometrics
- Remove wallet

Reason: biometrics can be coerced (sleeping or forced user). High-risk, irreversible actions need knowledge-based auth.

**Transaction signing (user choice: PIN or biometric):**
- Setting: Settings → Security → "Confirm transactions with" = `PIN` | `Biometric` (biometric always has manual PIN as fallback).
- Both methods end in the same step: obtain PIN bytes (typed, or released by the biometric-bound key) → Argon2id → AES-256-GCM decrypt of mnemonic/private key inside an isolate → derive key → `Vault.sign()` → zero all buffers.
- The decrypted mnemonic/private key exists only for the duration of signing, inside the isolate. It is never returned to the main isolate or cached.
- If biometrics are not enabled, the PIN is **not** stored in hardware at all. The stored PIN exists only behind biometric access control; storing it without biometric binding would make PIN encryption pointless.

### Memory Hygiene

- Hold secrets as `Uint8List`. Zero-fill (`fillRange(0, length, 0)`) in a `finally` block after use.
- Minimize `String` conversions of secrets (Dart strings are immutable and cannot be wiped). Where Wallet Core requires a `String` mnemonic, create it, use it, and drop the reference immediately.
- Run KDF, decrypt, derive, and sign inside `Isolate.run`. Return only signed bytes or public data to the main isolate.
- The unlocked session keeps only the KEK in memory inside `VaultSession`. Clear it on auto-lock timeout, app backgrounded beyond the timeout, manual lock, and wallet removal.

### Vault API

```dart
abstract interface class Vault {
  Future<Result<WalletId>> createWallet({required Pin pin, int words = 12});
  Future<Result<WalletId>> importMnemonic(String mnemonic, {required Pin pin});
  Future<Result<WalletId>> importPrivateKey(Uint8List key, CoinType coin, {required Pin pin});

  Future<Result<void>> unlock(Pin pin);
  Future<Result<void>> unlockWithBiometrics(); // biometric → stored PIN → unlock(pin)
  Future<Result<void>> enableBiometrics({required Pin pin});  // manual PIN required
  Future<Result<void>> disableBiometrics({required Pin pin}); // manual PIN required
  Future<bool> get isBiometricAvailable; // strong biometrics enrolled + device passcode set
  void lock();
  Stream<VaultStatus> get status;

  Future<Result<List<Account>>> accounts(WalletId id);
  Future<Result<SignedPayload>> sign(SignRequest request); // requires unlocked session
  Future<Result<SecretReveal>> revealSecret(WalletId id, {required Pin pin}); // PIN always
  Future<Result<void>> changePin({required Pin current, required Pin next});
  Future<Result<void>> removeWallet(WalletId id, {required Pin pin});
}
```

## Signing Pipeline

Every signature, regardless of source (user, AI assistant, WalletConnect, dApp browser), goes through `core/signing/`:

```
SignRequest(source, intent)
  → validate (address format, chain, balance, nonce)
  → simulate / risk check (balance changes, token approvals, flagged contracts)
  → review screen (shows source badge: "You", "Prepared by AI", "<dApp> via WalletConnect")
  → authenticate (biometric or PIN)
  → Vault.sign()
  → broadcast (ChainAdapter)
  → track status → notify
```

- `SigningBloc` states: `validating → simulating → awaitingReview → authenticating → signing → broadcasting → submitted | failed | rejected`. Explicit sealed states, no booleans.
- No auto-signing, no "remember approval", no signing path that skips the review screen.
- Unlimited token approvals must show a warning and an editable spending cap.

## Chain Adapters

```dart
abstract interface class ChainAdapter {
  ChainId get chain;
  bool validateAddress(String address);
  Future<Result<List<TokenBalance>>> getBalances(String address);
  Future<Result<UnsignedTx>> buildTransfer(TransferIntent intent);
  Future<Result<FeeOptions>> estimateFee(UnsignedTx tx);
  Future<Result<TxHash>> broadcast(SignedPayload signed);
  Stream<TxStatus> track(TxHash hash);
  Future<Result<Page<TxRecord>>> history(String address, {Cursor? cursor});
}
```

- Adapters handle RPC/indexer I/O and build Wallet Core `SigningInput` protobufs. They never hold or see private keys.
- One implementation per chain family (`EvmAdapter`, `SolanaAdapter`, `TronAdapter`, `BitcoinAdapter`). Adding a chain means adding an adapter, not editing features.

## Data & Caching

- Drift is the local cache: balances, token metadata, tx history, address book, price alerts, WalletConnect sessions, AI chat history.
- Repositories are cache-first: emit cached data immediately via Drift `watch()` streams, refresh from network in the background.
- Prices come over websocket; throttle UI updates to ~1/sec.
- Parse large JSON payloads (token lists, history) in `compute`/isolates.

## AI Assistant

- LLM orchestration runs on the backend. The app never holds LLM API keys.
- The AI returns **intents only** (`TransferIntent`, `SwapIntent`, `BuyIntent`, `PriceAlertIntent`, `AddContactIntent`). The app re-validates every intent locally (address book match, address format, balance, chain) before rendering a card.
- Transaction intents go through the signing pipeline with `source = ai`. The AI has no access to the Vault, secrets, or signing.
- Local-only actions (address book, alerts setup UI) execute in the app, not on the backend.
- Treat token names, contract metadata, dApp metadata, and any on-chain text as untrusted. Never forward them to the LLM as instructions.
- Share minimal portfolio data with the backend (aggregated values), behind a user toggle.

## WalletConnect & dApp Browser

- `reown_walletkit` session proposals are handled by `WalletConnectBloc`. All requests (`eth_sendTransaction`, `personal_sign`, `eth_signTypedData_v4`, Solana sign requests) become `SignRequest`s.
- dApp browser injects an EIP-1193 provider (EVM) and Wallet Standard provider (Solana). All JS bridge messages become `SignRequest`s.
- Connected sessions and permissions are persisted in Drift and shown in Settings → Connected Apps.

## Security Checklist

- Screen protection (`FLAG_SECURE` on Android, blur overlay on iOS app switcher) on: onboarding phrase screens, recovery phrase reveal, private key export, passcode, review/confirm.
- Clipboard auto-clear after 60 seconds when copying any secret.
- Certificate pinning for backend and primary RPC endpoints.
- Root/jailbreak and debugger detection: warn the user, do not silently block.
- Release builds: `--obfuscate --split-debug-info`.
- No `print`/`debugPrint`/logging of secrets. Use the project logger, which redacts by default. No analytics events on sensitive screens.
- Backups excluded for all secure storage.

## Performance Rules

- Real `BackdropFilter` blur only on headers, bottom sheets, and the tab bar. List items use static translucent glass (gradient + alpha fill), not live blur.
- Wrap charts, the AI orb, and other continuously animated widgets in `RepaintBoundary`.
- Use `BlocSelector` to rebuild only what changed.
- `const` constructors everywhere possible.
- Keep the dApp browser screen free of blur overlays (platform view performance).

## Testing

- **Vault:** encrypt/decrypt round-trip, wrong PIN fails, tampered ciphertext fails (GCM tag), nonce uniqueness, salt uniqueness, PIN change atomicity, lockout behavior.
- **Biometrics:** enable requires valid PIN, stored PIN updated on PIN change, invalidation deletes the item and falls back to manual PIN, stale PIN does not increment lockout, sensitive actions reject biometric-only auth, device-credential fallback is not possible.
- **Key generation & signing:** use Trust Wallet Core's published test vectors for derivation and signed tx output per chain. Any change to vault/signing code must include tests.
- **Cubits/Blocs:** `bloc_test` for every ViewModel.
- **Design system:** golden tests for core components.
- **Integration:** send/swap flows per chain on testnets.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # freezed, json, drift
flutter analyze
flutter test
flutter run --flavor dev -t lib/main_dev.dart
flutter build apk --flavor prod -t lib/main_prod.dart --obfuscate --split-debug-info=build/symbols
```

## Rules for Claude

- Never write cryptographic primitives. Use Trust Wallet Core and the `cryptography` package only.
- Never log, print, or include secrets in state, route params, exceptions, or test snapshots.
- Ask before modifying anything in `core/vault/` or `core/signing/`, and include tests with every change there.
- Ask before adding dependencies.
- Keep widgets dumb; logic goes in Cubits/Blocs and repositories.
- Follow the folder structure and naming conventions (`*_cubit.dart`, `*_state.dart`, `*_repository.dart`, `*_service.dart`, `*_screen.dart`).
- Run `dart run build_runner build` after changing any `freezed`, `json_serializable`, or Drift file.
- Prefer small, focused PR-sized changes over large refactors.