// Run with: dart example/main.dart
// Then open the printed URL in a browser on the same network and watch the
// requests appear live.
//
// Running your app on the Android emulator instead? The printed IP
// (10.0.2.15) is only reachable inside the emulator. Forward the port first:
//   adb forward tcp:9945 tcp:9945
// then open http://localhost:9945 on your computer. The iOS simulator needs
// no forwarding — http://localhost:9945 works directly.
import 'package:dio/dio.dart';
import 'package:remote_network_inspector/remote_network_inspector.dart';

Future<void> main() async {
  final dio = Dio();

  // 1. Capture everything this Dio instance does.
  dio.interceptors.add(RemoteNetworkInspectorInterceptor());

  // 2. Start the dashboard server.
  final urls = await RemoteNetworkInspector.instance.start();
  print('Open ${urls.isNotEmpty ? urls.first : 'http://<device-ip>:9945'} in a browser');

  // 3. Make some calls — they show up in the dashboard instantly.
  await dio.get('https://jsonplaceholder.typicode.com/todos/1');
  await dio.post('https://jsonplaceholder.typicode.com/posts',
      data: {'title': 'hello', 'body': 'world', 'userId': 1});
  try {
    await dio.get('https://jsonplaceholder.typicode.com/404');
  } catch (_) {}

  // Keep the process alive so you can browse the dashboard.
  print('Press Ctrl+C to stop.');
  await Future<void>.delayed(const Duration(hours: 1));
}
