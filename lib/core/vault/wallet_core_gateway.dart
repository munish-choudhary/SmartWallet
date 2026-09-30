import 'dart:typed_data';

import 'package:wallet_core_ffi/wallet_core_ffi.dart' as wc;

/// The only point where `core/vault` touches `wallet_core_ffi`. Kept as an
/// interface so `VaultImpl` can be unit-tested against a fake instead of
/// the real bindings (which don't exist yet — see
/// packages/wallet_core_ffi/README.md).
abstract interface class WalletCoreGateway {
  bool isValidMnemonic(String mnemonic);

  /// `strength: 128` -> 12 words, `256` -> 24 words.
  String createMnemonic({required int strength});

  String addressForCoin(String mnemonic, wc.CoinType coin);

  /// Validates [keyBytes] length/curve for [coin] before returning the
  /// derived address. Throws [ArgumentError] on invalid input.
  String addressForImportedKey(Uint8List keyBytes, wc.CoinType coin);

  /// Raw private key for [coin] at Wallet Core's default derivation path.
  /// Caller must zeroize the returned bytes.
  Uint8List privateKeyForCoin(String mnemonic, wc.CoinType coin);

  Uint8List sign({
    required String mnemonic,
    required wc.CoinType coin,
    required Uint8List signingInputProto,
  });

  Uint8List signWithImportedKey({
    required Uint8List keyBytes,
    required wc.CoinType coin,
    required Uint8List signingInputProto,
  });
}

final class WalletCoreFfiGateway implements WalletCoreGateway {
  const WalletCoreFfiGateway();

  @override
  bool isValidMnemonic(String mnemonic) => wc.Mnemonic.isValid(mnemonic);

  @override
  String createMnemonic({required int strength}) =>
      wc.HDWallet.create(strength: strength).mnemonic;

  @override
  String addressForCoin(String mnemonic, wc.CoinType coin) =>
      wc.HDWallet.createWithMnemonic(mnemonic).getAddressForCoin(coin);

  @override
  String addressForImportedKey(Uint8List keyBytes, wc.CoinType coin) =>
      wc.PrivateKey.fromBytes(keyBytes, coin).publicKeyForCoin(coin).addressForCoin(coin);

  @override
  Uint8List privateKeyForCoin(String mnemonic, wc.CoinType coin) =>
      wc.HDWallet.createWithMnemonic(mnemonic).getKeyForCoin(coin).data;

  @override
  Uint8List sign({
    required String mnemonic,
    required wc.CoinType coin,
    required Uint8List signingInputProto,
  }) {
    final key = wc.HDWallet.createWithMnemonic(mnemonic).getKeyForCoin(coin);
    return _signWithKey(key, coin, signingInputProto);
  }

  @override
  Uint8List signWithImportedKey({
    required Uint8List keyBytes,
    required wc.CoinType coin,
    required Uint8List signingInputProto,
  }) {
    final key = wc.PrivateKey.fromBytes(keyBytes, coin);
    return _signWithKey(key, coin, signingInputProto);
  }

  Uint8List _signWithKey(
    wc.PrivateKey key,
    wc.CoinType coin,
    Uint8List signingInputProto,
  ) {
    // TWAnySigner signs against a coin + protobuf SigningInput; the key
    // material is supplied inside that protobuf per Trust Wallet Core's
    // API, not as a separate parameter. This call shape will be finalized
    // once generated_bindings.dart exists.
    return wc.AnySigner.sign(signingInputProto, coin);
  }
}
