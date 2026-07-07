import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'dashboard_html.dart';

/// Hosts the in-app inspector server and stores the captured network events.
///
/// Access it through the [instance] singleton:
/// ```dart
/// final urls = await RemoteNetworkInspector.instance.start();
/// print('Open ${urls.first} in a browser on the same Wi-Fi');
/// ```
class RemoteNetworkInspector {
  RemoteNetworkInspector._();

  /// The shared singleton instance.
  static final RemoteNetworkInspector instance = RemoteNetworkInspector._();

  final List<Map<String, dynamic>> _history = [];
  final Set<WebSocket> _clients = {};
  HttpServer? _server;
  int _seq = 0;

  int _maxHistory = 500;
  int _maxBodyChars = 200000;

  /// Whether the dashboard server is currently running.
  bool get isRunning => _server != null;

  /// Starts the dashboard server and returns the URL(s) to open in a
  /// browser on the same network (one per network interface).
  ///
  /// * [port] — TCP port for the dashboard (default `9945`).
  /// * [maxHistory] — how many calls to keep in memory for late-joining
  ///   browsers (default `500`).
  /// * [maxBodyChars] — request/response bodies longer than this are
  ///   truncated to keep memory and the UI snappy (default `200000`).
  /// * [logUrls] — print the dashboard URLs to the console (default `true`).
  ///
  /// Calling [start] when the server is already running is a no-op and
  /// simply returns the URLs again.
  Future<List<String>> start({
    int port = 9945,
    int maxHistory = 500,
    int maxBodyChars = 200000,
    bool logUrls = true,
  }) async {
    _maxHistory = maxHistory;
    _maxBodyChars = maxBodyChars;

    if (_server == null) {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _server!.listen(_handleRequest, onError: (_) {});
    }

    final urls = <String>[];
    for (final ni in await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    )) {
      for (final addr in ni.addresses) {
        urls.add('http://${addr.address}:${_server!.port}');
      }
    }
    if (logUrls) {
      for (final u in urls) {
        // ignore: avoid_print
        print('[RemoteNetworkInspector] Dashboard available at: $u');
      }
    }
    return urls;
  }

  /// Stops the server and disconnects all dashboard clients.
  Future<void> stop() async {
    for (final c in _clients) {
      c.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }

  /// Clears the captured history on the device and in every connected
  /// dashboard.
  void clear() {
    _history.clear();
    _broadcast({'type': 'clear'});
  }

  Future<void> _handleRequest(HttpRequest req) async {
    try {
      if (req.uri.path == '/ws' &&
          WebSocketTransformer.isUpgradeRequest(req)) {
        final ws = await WebSocketTransformer.upgrade(req);
        _clients.add(ws);
        // Send history so a late-joining dashboard sees earlier calls.
        ws.add(jsonEncode({'type': 'init', 'data': _history}));
        ws.listen(
          (msg) {
            if (msg == 'clear') clear();
          },
          onDone: () => _clients.remove(ws),
          onError: (_) => _clients.remove(ws),
        );
      } else {
        req.response.headers.contentType = ContentType.html;
        req.response.write(dashboardHtml);
        await req.response.close();
      }
    } catch (_) {
      try {
        await req.response.close();
      } catch (_) {}
    }
  }

  /// Returns a unique, monotonically increasing id for a network event.
  int nextId() => ++_seq;

  /// Records a network [event] and streams it to all connected dashboards.
  ///
  /// Normally called by [RemoteNetworkInspectorInterceptor]; call it
  /// yourself only if you are integrating a custom HTTP client.
  void addEvent(Map<String, dynamic> event) {
    _history.add(event);
    if (_history.length > _maxHistory) _history.removeAt(0);
    _broadcast({'type': 'call', 'data': event});
  }

  void _broadcast(Map<String, dynamic> message) {
    final msg = jsonEncode(message);
    for (final c in _clients.toList()) {
      try {
        c.add(msg);
      } catch (_) {
        _clients.remove(c);
      }
    }
  }

  /// Converts any request/response body into a display string, handling
  /// JSON, plain text, [FormData] and binary payloads, truncating anything
  /// longer than `maxBodyChars`.
  String describeBody(dynamic data) {
    if (data == null) return '';
    try {
      if (data is FormData) {
        final fields = {for (final f in data.fields) f.key: f.value};
        final files = data.files
            .map((f) =>
                '${f.key}: ${f.value.filename ?? 'file'} (${f.value.length} bytes)')
            .toList();
        return const JsonEncoder.withIndent('  ')
            .convert({'formData': fields, 'files': files});
      }
      if (data is List<int>) return '<binary ${data.length} bytes>';
      if (data is String) return _truncate(data);
      return _truncate(const JsonEncoder.withIndent('  ').convert(data));
    } catch (_) {
      return _truncate(data.toString());
    }
  }

  String _truncate(String s) => s.length > _maxBodyChars
      ? '${s.substring(0, _maxBodyChars)}\n…(truncated, ${s.length} chars total)'
      : s;
}
