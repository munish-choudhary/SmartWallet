import 'package:freezed_annotation/freezed_annotation.dart';

import 'custom_network.dart';

part 'network_draft.freezed.dart';

enum NetworkField { name, rpcUrl, chainId, symbol, explorerUrl }

/// Why a field was rejected. The view maps these to user-facing text.
enum NetworkFieldError {
  required,
  tooLong,
  invalidUrl,
  insecureUrl,
  invalidChainId,
  invalidSymbol,
  chainIdMismatch,
}

/// The raw strings the user has typed so far, plus the rules that turn
/// them into a [CustomNetwork].
@freezed
abstract class NetworkDraft with _$NetworkDraft {
  const NetworkDraft._();

  const factory NetworkDraft({
    @Default('') String name,
    @Default('') String rpcUrl,
    @Default('') String chainId,
    @Default('') String symbol,
    @Default('') String explorerUrl,
  }) = _NetworkDraft;

  static const maxNameLength = 40;

  /// EIP-155 folds the chain ID into the signature's `v` (`chainId * 2 + 35`),
  /// which has to stay a safe integer. This bound keeps it there.
  static const maxChainId = 4503599627370476;

  static final _digits = RegExp(r'^[0-9]+$');
  static final _symbol = RegExp(r'^[A-Za-z0-9]{2,6}$');

  /// Every field currently invalid; empty means [toNetwork] will succeed.
  Map<NetworkField, NetworkFieldError> validate() {
    final errors = <NetworkField, NetworkFieldError>{};
    final nameError = validateName(name);
    if (nameError != null) errors[NetworkField.name] = nameError;
    final rpcError = validateUrl(rpcUrl);
    if (rpcError != null) errors[NetworkField.rpcUrl] = rpcError;
    final chainError = validateChainId(chainId);
    if (chainError != null) errors[NetworkField.chainId] = chainError;
    final symbolError = validateSymbol(symbol);
    if (symbolError != null) errors[NetworkField.symbol] = symbolError;
    // The explorer is optional: only reject it when something was typed.
    if (explorerUrl.trim().isNotEmpty) {
      final explorerError = validateUrl(explorerUrl);
      if (explorerError != null) errors[NetworkField.explorerUrl] = explorerError;
    }
    return errors;
  }

  /// The validated network, or `null` if any field is invalid.
  CustomNetwork? toNetwork() {
    if (validate().isNotEmpty) return null;
    final explorer = explorerUrl.trim();
    return CustomNetwork(
      name: name.trim(),
      rpcUrl: Uri.parse(rpcUrl.trim()),
      chainId: int.parse(chainId.trim()),
      currencySymbol: symbol.trim().toUpperCase(),
      explorerUrl: explorer.isEmpty ? null : Uri.parse(explorer),
    );
  }

  static NetworkFieldError? validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return NetworkFieldError.required;
    if (trimmed.length > maxNameLength) return NetworkFieldError.tooLong;
    return null;
  }

  /// HTTPS only. Plain HTTP is accepted solely for loopback hosts (a local
  /// dev node); over the network it lets anyone on the path feed the wallet
  /// forged balances and chain data. Embedded credentials are rejected: they
  /// are a classic way to disguise the real host in a displayed URL.
  static NetworkFieldError? validateUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return NetworkFieldError.required;
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return NetworkFieldError.invalidUrl;
    }
    return switch (uri.scheme) {
      'https' => null,
      'http' => _isLoopback(uri.host) ? null : NetworkFieldError.insecureUrl,
      _ => NetworkFieldError.invalidUrl,
    };
  }

  static NetworkFieldError? validateChainId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return NetworkFieldError.required;
    if (!_digits.hasMatch(trimmed)) return NetworkFieldError.invalidChainId;
    final id = int.tryParse(trimmed);
    if (id == null || id < 1 || id > maxChainId) {
      return NetworkFieldError.invalidChainId;
    }
    return null;
  }

  static NetworkFieldError? validateSymbol(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return NetworkFieldError.required;
    if (!_symbol.hasMatch(trimmed)) return NetworkFieldError.invalidSymbol;
    return null;
  }

  static bool _isLoopback(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1';
}
