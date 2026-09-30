import 'dart:convert';

/// EIP-1193 / JSON-RPC error codes the provider can return.
abstract final class RpcCode {
  static const userRejected = 4001;
  static const unauthorized = 4100;
  static const unsupportedMethod = 4200;
  static const disconnected = 4900;
  static const unrecognizedChain = 4902;
  static const invalidParams = -32602;
  static const internal = -32603;
  static const invalidRequest = -32600;
}

/// One call from the page's `window.ethereum.request(...)`.
///
/// [origin] is **not** taken from the message: it is the origin the native
/// layer observed for the frame that posted it.
final class BridgeRequest {
  const BridgeRequest({
    required this.id,
    required this.method,
    required this.params,
    required this.origin,
  });

  final Object id;
  final String method;
  final List<Object?> params;
  final String origin;

  /// Returns null for anything that isn't a well-formed request — page
  /// content is untrusted, so malformed input is dropped, never guessed at.
  static BridgeRequest? parse(Object? raw, {required String origin}) {
    if (raw is! String || raw.length > 512 * 1024) return null;
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (json is! Map) return null;
    final id = json['id'];
    final method = json['method'];
    final params = json['params'];
    if (id is! num && id is! String) return null;
    if (method is! String || method.isEmpty || method.length > 128) return null;
    final List<Object?> list;
    if (params == null) {
      list = const [];
    } else if (params is List) {
      list = params.cast<Object?>();
    } else if (params is Map) {
      list = [params];
    } else {
      return null;
    }
    return BridgeRequest(
      id: id as Object,
      method: method,
      params: list,
      origin: origin,
    );
  }
}

sealed class BridgeResponse {
  const BridgeResponse(this.id);
  final Object id;

  String toJsonString();
}

final class BridgeResult extends BridgeResponse {
  const BridgeResult(super.id, this.value);
  final Object? value;

  @override
  String toJsonString() =>
      jsonEncode({'type': 'response', 'id': id, 'result': value});
}

final class BridgeError extends BridgeResponse {
  const BridgeError(super.id, this.code, this.message, {this.data});
  final int code;
  final String message;

  /// Node-supplied error data (e.g. revert payload), passed through so
  /// libraries can decode revert reasons.
  final Object? data;

  @override
  String toJsonString() => jsonEncode({
        'type': 'response',
        'id': id,
        'error': {
          'code': code,
          'message': message,
          if (data != null) 'data': data,
        },
      });
}

/// Something the page should be told about (EIP-1193 provider events).
sealed class BridgeEvent {
  const BridgeEvent(this.origin);

  /// Only pages on this origin receive the event.
  final String origin;
  String get name;
  Object? get data;
}

final class ChainChangedEvent extends BridgeEvent {
  const ChainChangedEvent(super.origin, this.chainIdHex);
  final String chainIdHex;
  @override
  String get name => 'chainChanged';
  @override
  Object? get data => chainIdHex;
}

final class AccountsChangedEvent extends BridgeEvent {
  const AccountsChangedEvent(super.origin, this.accounts);
  final List<String> accounts;
  @override
  String get name => 'accountsChanged';
  @override
  Object? get data => accounts;
}
