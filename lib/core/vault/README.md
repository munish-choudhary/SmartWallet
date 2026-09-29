# core/vault

Implements CLAUDE.md's Vault & Key Management section. This is the only code allowed to touch key material or `wallet_core_ffi`.

## Layout

- `vault.dart` — the `Vault` interface (+ placeholder `Account`/`SignRequest`/`SignedPayload`/`SecretReveal` types, to be replaced by `core/chains`/`core/signing`'s real types once those exist).
- `vault_impl.dart` — `VaultImpl`, the concrete implementation of every flow (create/import, unlock, PIN change, biometrics, sign, reveal, remove).
- `envelope.dart` — the PIN-layer envelope model (freezed + json_serializable), matching CLAUDE.md's JSON shape exactly.
- `kdf.dart` — Argon2id (default) / PBKDF2-HMAC-SHA256 (fallback) key derivation.
- `encryption.dart` — AES-256-GCM encrypt/decrypt.
- `vault_keystore.dart` — the `VaultKeystore` interface + `MethodChannel` wiring for the hardware wrap. **Native Kotlin/Swift implementations are not written yet** — see below.
- `envelope_store.dart` — `flutter_secure_storage`-backed persistence for wrapped envelopes and small bookkeeping (secret type, imported-key coin, biometric-wrapped PIN).
- `vault_session.dart` — in-memory KEKs for the unlocked session.
- `lockout_policy.dart` — the 5-failures → 1/15/60-minute escalating lockout.
- `wallet_core_gateway.dart` — the sole call site into `wallet_core_ffi`.
- `pin.dart`, `secrets.dart` — PIN and zeroization helpers.

## What's not done yet

1. **`wallet_core_ffi` has no real bindings.** Every `WalletCoreGateway` call currently throws at runtime (`WalletCoreNotReadyError`) until someone runs `ffigen` there — see `packages/wallet_core_ffi/README.md`. `VaultImpl` is written and tested against a fake gateway (`test/core/vault/fakes.dart`), so this doesn't block vault development, only real signing.
2. **`VaultKeystore` has no native implementation.** `MethodChannelVaultKeystore` will throw `MissingPluginException` on a real device until Android Keystore (Kotlin) and iOS Secure Enclave (Swift) handlers exist for the `vault_keystore` channel, implementing `wrap`/`unwrap`/`deleteKey`/`isStrongBiometricAvailable` as documented in `vault_keystore.dart`'s doc comment.
3. Multi-wallet `changePin` is only atomic per-wallet, not across the whole vault — see the comment in `VaultImpl.changePin`.

## Testing

`test/core/vault/` covers the CLAUDE.md Vault checklist using fakes for both of the above (`FakeWalletCoreGateway`, `FakeVaultKeystore`, `FakeKeyDerivation` — the last swaps out real Argon2id for a fast deterministic stand-in so tests don't take 300-800ms each). Run with:

```bash
flutter test test/core/vault/
```
