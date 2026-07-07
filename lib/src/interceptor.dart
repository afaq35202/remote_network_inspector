import 'package:dio/dio.dart';

import 'inspector.dart';

/// A [Dio] interceptor that records every request, response and error and
/// streams it to the [RemoteNetworkInspector] dashboard.
///
/// Add it **last**, after your auth/logging interceptors, so the dashboard
/// shows requests exactly as they go over the wire:
/// ```dart
/// dio.interceptors.add(RemoteNetworkInspectorInterceptor());
/// ```
class RemoteNetworkInspectorInterceptor extends Interceptor {
  static const _idKey = '_rniId';
  static const _startKey = '_rniStart';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_idKey] = RemoteNetworkInspector.instance.nextId();
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    RemoteNetworkInspector.instance.addEvent(
      _buildEvent(response.requestOptions, response: response),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    RemoteNetworkInspector.instance.addEvent(
      _buildEvent(err.requestOptions, response: err.response, error: err),
    );
    handler.next(err);
  }

  Map<String, dynamic> _buildEvent(
    RequestOptions options, {
    Response? response,
    DioException? error,
  }) {
    final inspector = RemoteNetworkInspector.instance;
    final start = options.extra[_startKey] as int?;
    final now = DateTime.now();
    final durationMs =
        start != null ? now.millisecondsSinceEpoch - start : null;

    String responseBody = '';
    int? responseSize;
    if (response != null) {
      responseBody = inspector.describeBody(response.data);
      responseSize = responseBody.length;
    }

    return {
      'id': options.extra[_idKey],
      'time': now.toIso8601String(),
      'method': options.method,
      'url': options.uri.toString(),
      'path': options.uri.path.isEmpty ? '/' : options.uri.path,
      'query': options.uri.query,
      'status': response?.statusCode,
      'statusMessage': response?.statusMessage ?? '',
      'durationMs': durationMs,
      'requestHeaders':
          options.headers.map((k, v) => MapEntry(k, v.toString())),
      'requestBody': inspector.describeBody(options.data),
      'responseHeaders': response?.headers.map
              .map((k, v) => MapEntry(k, v.join(', '))) ??
          {},
      'responseBody': responseBody,
      'responseSize': responseSize,
      'error': error == null
          ? null
          : '${error.type.name}: ${error.message ?? ''}'.trim(),
    };
  }
}
