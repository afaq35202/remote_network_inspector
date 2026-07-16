/// A DevTools-style network inspector for debug, profile and QA builds.
///
/// The device hosts a tiny HTTP + WebSocket server. Anyone on the same
/// Wi-Fi opens `http://<device-ip>:9945` in a browser and sees a live,
/// filterable list of every API call the app makes — method, status,
/// duration, headers, request payload and response body — without
/// installing the Flutter SDK or a proxy.
///
/// Runs in debug and profile mode; automatically disabled in release
/// builds. On the Android emulator, run
/// `adb forward tcp:9945 tcp:9945` and open `http://localhost:9945`
/// (the exact command is logged for you).
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
