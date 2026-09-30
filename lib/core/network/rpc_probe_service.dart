import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../result/result.dart';

/// What an EVM JSON-RPC endpoint told us about itself.
final class RpcProbe {
  const RpcProbe({required this.latency, required this.chainId});

  /// Round trip of the probe request. The first call to a host includes
  /// DNS + TLS setup, so it reads a little high.
  final Duration latency;
  final int chainId;
}

/// Asks an EVM JSON-RPC endpoint for its chain ID (`eth_chainId`) and times
/// the round trip. Read-only: sends no addresses or keys.
///
/// Failure messages are deliberately generic. The URL is user-supplied and
/// often carries a provider API key, so it never appears in a failure.
class RpcProbeService {
  RpcProbeService({Dio? dio, this.timeout = const Duration(seconds: 8)})
      : _dio = dio ?? Dio();

  final Dio _dio;

  /// Hard cap for the whole request, connection setup included.
  final Duration timeout;

  static const _request =
      '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}';

  // 13 hex digits stay below 2^52, so the value is always a safe integer.
  static final _hexQuantity = RegExp(r'^0x[0-9a-fA-F]{1,13}$');

  Future<Result<RpcProbe>> probe(Uri rpcUrl) async {
    final cancel = CancelToken();
    final timer = Timer(timeout, () => cancel.cancel('timeout'));
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.postUri<String>(
        rpcUrl,
        data: _request,
        cancelToken: cancel,
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.plain,
          // A hostile endpoint could bounce the request somewhere else.
          followRedirects: false,
        ),
      );
      stopwatch.stop();
      final chainId = _parseChainId(response.data);
      if (chainId == null) {
        return const Result.err(
          AppFailure.chainError('Endpoint did not return a valid chain ID'),
        );
      }
      return Result.ok(RpcProbe(latency: stopwatch.elapsed, chainId: chainId));
    } on DioException {
      return const Result.err(AppFailure.network('Endpoint unreachable'));
    } finally {
      timer.cancel();
    }
  }

  static int? _parseChainId(String? body) {
    if (body == null) return null;
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (json is! Map) return null;
    final result = json['result'];
    if (result is! String || !_hexQuantity.hasMatch(result)) return null;
    return int.tryParse(result.substring(2), radix: 16);
  }
}
