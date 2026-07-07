/// A DevTools-style network inspector for QA builds.
///
/// The device hosts a tiny HTTP + WebSocket server. Anyone on the same
/// Wi-Fi opens `http://<device-ip>:9945` in a browser and sees a live,
/// filterable list of every API call the app makes — method, status,
/// duration, headers, request payload and response body — without
/// installing the Flutter SDK, adb, or a proxy.
///
/// Quick start:
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(RemoteNetworkInspectorInterceptor());
/// final urls = await RemoteNetworkInspector.instance.start();
/// // Show urls.first to your QA (log, toast, or debug screen).
/// ```
library;

export 'src/inspector.dart' show RemoteNetworkInspector;
export 'src/interceptor.dart' show RemoteNetworkInspectorInterceptor;
