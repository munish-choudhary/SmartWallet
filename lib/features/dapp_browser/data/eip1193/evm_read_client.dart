import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../walletconnect/data/models/wc_chain.dart';

sealed class RpcOutcome {
  const RpcOutcome();
}

final class RpcSuccess extends RpcOutcome {
  const RpcSuccess(this.value);
  final Object? value;
}

/// The node answered with a JSON-RPC error.
final class RpcFailure extends RpcOutcome {
  const RpcFailure(this.code, this.message, {this.data});
  final int code;
  final String message;
  final Object? data;
}

/// No usable answer (offline, timeout, malformed response).
final class RpcUnreachable extends RpcOutcome {
  const RpcUnreachable();
}

/// Forwards **read-only** JSON-RPC calls from a page to a node, so dApps
/// that route every call through `window.ethereum` (ethers' BrowserProvider)
/// keep working. The bridge decides which methods may reach this — it never
/// sees keys, and write methods are not forwarded.
abstract interface class EvmReadClient {
  Future<RpcOutcome> call(WcChain chain, String method, List<Object?> params);
}

/// Stopgap client over public endpoints until `core/chains` provides the
/// `EvmAdapter` (CLAUDE.md: adapters own RPC I/O). Requests carry only the
/// method and params the page asked for.
class DioEvmReadClient implements EvmReadClient {
  DioEvmReadClient({
    Dio? dio,
    Map<int, String>? endpoints,
    this.timeout = const Duration(seconds: 10),
  })  : _dio = dio ?? Dio(),
        _endpoints = endpoints ?? defaultEndpoints;

  static const defaultEndpoints = <int, String>{
    1: 'https://ethereum-rpc.publicnode.com',
    56: 'https://bsc-rpc.publicnode.com',
    137: 'https://polygon-bor-rpc.publicnode.com',
    42161: 'https://arbitrum-one-rpc.publicnode.com',
    8453: 'https://base-rpc.publicnode.com',
  };

  final Dio _dio;
  final Map<int, String> _endpoints;
  final Duration timeout;

  @override
  Future<RpcOutcome> call(
    WcChain chain,
    String method,
    List<Object?> params,
  ) async {
    final endpoint = _endpoints[chain.chainId];
    if (endpoint == null) return const RpcUnreachable();
    final cancel = CancelToken();
    final timer = Timer(timeout, () => cancel.cancel('timeout'));
    try {
      final response = await _dio.post<String>(
        endpoint,
        data: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': method,
          'params': params,
        }),
        cancelToken: cancel,
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.plain,
          followRedirects: false,
        ),
      );
      return _parse(response.data);
    } on DioException {
      return const RpcUnreachable();
    } finally {
      timer.cancel();
    }
  }

  static RpcOutcome _parse(String? body) {
    if (body == null) return const RpcUnreachable();
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return const RpcUnreachable();
    }
    if (json is! Map) return const RpcUnreachable();
    final error = json['error'];
    if (error is Map) {
      final code = error['code'];
      final message = error['message'];
      return RpcFailure(
        code is int ? code : -32603,
        message is String ? message : 'RPC error',
        data: error['data'],
      );
    }
    if (!json.containsKey('result')) return const RpcUnreachable();
    return RpcSuccess(json['result']);
  }
}
