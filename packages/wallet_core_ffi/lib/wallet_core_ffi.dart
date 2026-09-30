/// Public Dart surface over Trust Wallet Core's C API.
///
/// This is consumed exclusively by `lib/core/vault`. Every call below is
/// currently a typed stub: the real implementation is one call to
/// `generated_bindings.dart`, produced by `dart run ffigen` once Trust
/// Wallet Core's headers/libs are vendored (see README.md). Until then,
/// every stub throws [WalletCoreNotReadyError] instead of silently
/// returning fake key material.
// The `_handle`/private-constructor scaffolding below is unused until real
// bindings are wired in — see the TODO at `_notReady`.
// ignore_for_file: unused_field, unused_element
library wallet_core_ffi;

import 'dart:typed_data';

/// Thrown by every binding until `generated_bindings.dart` exists and is
/// wired in. This is the single integration point: once the real bindings
/// are generated, each stub body below is replaced with the corresponding
/// native call — nothing else in this file's public API changes.
class WalletCoreNotReadyError extends UnsupportedError {
  WalletCoreNotReadyError(String member)
      : super(
          'wallet_core_ffi.$member: native bindings not generated yet. '
          'Run `dart run ffigen --config ffigen.yaml` in packages/wallet_core_ffi '
          'after vendoring Trust Wallet Core headers/libs — see README.md.',
        );
}

Never _notReady(String member) => throw WalletCoreNotReadyError(member);

/// Chains this wallet supports, mapped 1:1 to Trust Wallet Core's `TWCoinType`.
enum CoinType {
  ethereum,
  smartChain, // BNB Chain
  polygon,
  arbitrum,
  base,
  solana,
  tron,
  bitcoin,
}

extension CoinTypeCurve on CoinType {
  /// Curve used for private-key validation, per CLAUDE.md:
  /// secp256k1 for EVM/Tron/BTC, ed25519 for Solana.
  Curve get curve => switch (this) {
        CoinType.solana => Curve.ed25519,
        _ => Curve.secp256k1,
      };
}

enum Curve { secp256k1, ed25519 }

/// Wraps `TWMnemonic`.
abstract final class Mnemonic {
  /// BIP-39 checksum + wordlist validation. Must be called before
  /// [HDWallet.createWithMnemonic].
  static bool isValid(String mnemonic) => _notReady('Mnemonic.isValid');
}

/// Wraps `TWHDWallet`. Never construct or derive keys anywhere else —
/// per CLAUDE.md, BIP39/BIP32/44 must not be reimplemented in Dart.
final class HDWallet {
  HDWallet._(this._handle);

  final Object _handle;

  /// `strength: 128` → 12 words, `256` → 24 words.
  static HDWallet create({required int strength}) {
    assert(strength == 128 || strength == 256, 'strength must be 128 or 256');
    _notReady('HDWallet.create');
  }

  /// Caller must have already validated [mnemonic] with [Mnemonic.isValid].
  static HDWallet createWithMnemonic(String mnemonic) =>
      _notReady('HDWallet.createWithMnemonic');

  /// The wallet's mnemonic. Caller is responsible for zeroizing any buffer
  /// derived from this per CLAUDE.md's Memory Hygiene rules.
  String get mnemonic => _notReady('HDWallet.mnemonic');

  /// Uses Trust Wallet Core's default derivation path for [coin]. Custom
  /// paths only via an explicit, documented setting (not exposed here).
  PrivateKey getKeyForCoin(CoinType coin) => _notReady('HDWallet.getKeyForCoin');

  String getAddressForCoin(CoinType coin) =>
      _notReady('HDWallet.getAddressForCoin');
}

/// Wraps `TWPrivateKey`.
final class PrivateKey {
  PrivateKey._(this._handle);

  final Object _handle;

  /// Validates [bytes] length and curve for [coin] before constructing.
  /// Throws [ArgumentError] for invalid input — never partially constructs.
  factory PrivateKey.fromBytes(Uint8List bytes, CoinType coin) =>
      _notReady('PrivateKey.fromBytes');

  PublicKey publicKeyForCoin(CoinType coin) =>
      _notReady('PrivateKey.publicKeyForCoin');

  /// Raw key bytes (`TWPrivateKeyData`). Caller must zeroize the result.
  Uint8List get data => _notReady('PrivateKey.data');
}

/// Wraps `TWPublicKey`.
final class PublicKey {
  PublicKey._(this._handle);

  final Object _handle;

  String addressForCoin(CoinType coin) => _notReady('PublicKey.addressForCoin');
}

/// Wraps `TWAnySigner`. The only place a `SigningInput` protobuf becomes
/// signed bytes — `core/signing/` builds the input, this signs it, nothing
/// else in the app touches Wallet Core's signing surface.
abstract final class AnySigner {
  static Uint8List sign(Uint8List signingInputProto, CoinType coin) =>
      _notReady('AnySigner.sign');
}
