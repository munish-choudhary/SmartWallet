import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/network/rpc_probe_service.dart';
import 'package:smart_wallet/core/result/result.dart';

/// Answers every request from [respond]; nothing touches the network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final FutureOr<ResponseBody> Function(RequestOptions options) respond;
  RequestOptions? last;
  String? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    if (requestStream != null) {
      final bytes = await requestStream.expand((c) => c).toList();
      lastBody = utf8.decode(bytes);
    }
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Never answers; only gives up when the request is cancelled.
class _HangingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await cancelFuture;
    throw DioException.requestCancelled(
      requestOptions: options,
      reason: 'cancelled',
    );
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, {int status = 200}) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

RpcProbeService _service(
  FutureOr<ResponseBody> Function(RequestOptions) respond, {
  Duration timeout = const Duration(seconds: 2),
  void Function(_FakeAdapter adapter)? capture,
}) {
  final adapter = _FakeAdapter(respond);
  capture?.call(adapter);
  return RpcProbeService(
    dio: Dio()..httpClientAdapter = adapter,
    timeout: timeout,
  );
}

final _url = Uri.parse('https://rpc.example.com/v2/secret-api-key');

void main() {
  test('parses the chain ID and reports latency', () async {
    late _FakeAdapter adapter;
    final service = _service(
      (_) => _json('{"jsonrpc":"2.0","id":1,"result":"0x89"}'),
      capture: (a) => adapter = a,
    );

    final result = await service.probe(_url);

    final probe = result.valueOrNull!;
    expect(probe.chainId, 137);
    expect(probe.latency, greaterThanOrEqualTo(Duration.zero));
    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.uri, _url);
    expect(jsonDecode(adapter.lastBody!), {
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'eth_chainId',
      'params': <Object?>[],
    });
  });

  test('never follows redirects', () async {
    late _FakeAdapter adapter;
    final service = _service(
      (_) => _json('{"result":"0x1"}'),
      capture: (a) => adapter = a,
    );
    await service.probe(_url);
    expect(adapter.last!.followRedirects, isFalse);
  });

  test('a redirect response is a failure, not a hop to another host', () async {
    final service = _service(
      (_) => ResponseBody.fromString(
        '',
        302,
        headers: {
          Headers.contentTypeHeader: ['text/plain'],
          'location': ['https://evil.example.com'],
        },
      ),
    );
    expect((await service.probe(_url)).failureOrNull, isA<NetworkFailure>());
  });

  test('HTTP errors are network failures', () async {
    final service = _service((_) => _json('{"error":"nope"}', status: 500));
    expect((await service.probe(_url)).failureOrNull, isA<NetworkFailure>());
  });

  test('a JSON-RPC error body is not a chain ID', () async {
    final service = _service(
      (_) => _json('{"jsonrpc":"2.0","id":1,"error":{"code":-32601}}'),
    );
    expect((await service.probe(_url)).failureOrNull, isA<ChainErrorFailure>());
  });

  test('non-JSON, wrong-shaped and non-hex replies are rejected', () async {
    for (final body in [
      '<html>hello</html>',
      '[]',
      '{"result":137}',
      '{"result":"137"}',
      '{"result":"0x"}',
      '{"result":"0xzz"}',
      // 16 hex digits could overflow a safe integer.
      '{"result":"0xffffffffffffffff"}',
    ]) {
      final service = _service((_) => _json(body));
      expect(
        (await service.probe(_url)).failureOrNull,
        isA<ChainErrorFailure>(),
        reason: body,
      );
    }
  });

  test('gives up after the timeout', () async {
    final service = RpcProbeService(
      dio: Dio()..httpClientAdapter = _HangingAdapter(),
      timeout: const Duration(milliseconds: 50),
    );
    // The guard only fails the test if the service never gives up.
    final result = await service.probe(_url).timeout(const Duration(seconds: 3));
    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('failures never contain the URL (it may carry an API key)', () async {
    final failing = _service((_) => _json('{}', status: 500));
    final garbled = _service((_) => _json('nonsense'));
    for (final service in [failing, garbled]) {
      final failure = (await service.probe(_url)).failureOrNull!;
      expect(failure.toString(), isNot(contains('secret-api-key')));
      expect(failure.toString(), isNot(contains('rpc.example.com')));
    }
  });
}
