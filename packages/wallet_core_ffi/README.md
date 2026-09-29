# wallet_core_ffi

Internal package. FFI bindings to [Trust Wallet Core](https://github.com/trustwallet/wallet-core)'s C API. Consumed only by `lib/core/vault` — nothing else in the app should depend on this package directly.

## Current state

`lib/wallet_core_ffi.dart` defines the full Dart API surface `core/vault` needs (`HDWallet`, `Mnemonic`, `PrivateKey`, `AnySigner`, `CoinType`). Every method currently throws `WalletCoreNotReadyError` — there are no native bindings yet. This lets `core/vault` and its tests be written and reviewed against a stable API before the native side exists.

## Steps to generate real bindings

1. **Vendor the headers.** Copy `include/TrustWalletCore/*.h` from a tagged release of [trustwallet/wallet-core](https://github.com/trustwallet/wallet-core) into `packages/wallet_core_ffi/src/TrustWalletCore/`. Do not hand-edit them.
2. **Build native libraries** for each target ABI:
   - Android: `libTrustWalletCore.so` for `arm64-v8a`, `armeabi-v7a`, `x86_64`, built via wallet-core's own CMake + Android NDK toolchain, placed under `android/src/main/jniLibs/<abi>/`.
   - iOS: `TrustWalletCore.xcframework` (wallet-core ships a build script for this), added to `ios/Frameworks/` and referenced from the podspec.
   - This requires the Android NDK and Xcode and is out of scope for source-only changes — do it on a machine with those toolchains installed.
3. **Run ffigen**: `dart run ffigen --config ffigen.yaml` from this directory. Produces `lib/src/generated_bindings.dart`.
4. **Wire it in**: replace each `_notReady('...')` call in `lib/wallet_core_ffi.dart` with the corresponding call into `generated_bindings.dart`, using `dart:ffi`/`package:ffi` to marshal Dart types (`Uint8List`, `String`) to/from `TWData*`/`TWString*`.
5. **Verify against Trust Wallet Core's own test vectors** (mnemonic → address, sign → expected tx bytes) per chain, per CLAUDE.md's Testing section, before this is used for any real signing.

## Android/iOS build wiring (not yet done)

- `android/build.gradle` + `CMakeLists.txt` need to declare the `ffiPlugin`'s native library and load `libTrustWalletCore.so`.
- `ios/wallet_core_ffi.podspec` needs `vendored_frameworks: 'Frameworks/TrustWalletCore.xcframework'`.

Both are follow-up work once native binaries exist.
