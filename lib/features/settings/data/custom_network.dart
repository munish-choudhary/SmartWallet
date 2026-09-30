import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_network.freezed.dart';

/// A user-added EVM network. Public configuration only (no key material),
/// but [rpcUrl] often embeds a provider API key, so never log it.
@freezed
abstract class CustomNetwork with _$CustomNetwork {
  const factory CustomNetwork({
    required String name,
    required Uri rpcUrl,
    required int chainId,
    required String currencySymbol,
    Uri? explorerUrl,
  }) = _CustomNetwork;
}
