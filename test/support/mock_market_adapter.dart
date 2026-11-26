import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class MockMarketAdapter implements HttpClientAdapter {
  MockMarketAdapter(this.respond);
  final Future<http.Response> Function(http.Request) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    final request = http.Request(options.method, options.uri)
      ..headers.addAll(
        options.headers.map((key, value) => MapEntry(key, '$value')),
      );
    if (stream != null) {
      request.bodyBytes = await stream.expand((chunk) => chunk).toList();
    }
    final response = await respond(request);
    return ResponseBody.fromBytes(
      response.bodyBytes,
      response.statusCode,
      headers: response.headers.map((key, value) => MapEntry(key, [value])),
    );
  }

  @override
  void close({bool force = false}) {}
}
