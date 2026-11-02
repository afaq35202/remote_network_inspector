import 'dart:io';

import 'package:remote_network_inspector/remote_network_inspector.dart';
import 'package:test/test.dart';

void main() {
  test('falls back to next port when requested port is in use', () async {
    final blocker = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    final taken = blocker.port;
    addTearDown(blocker.close);
    final inspector = RemoteNetworkInspector.instance;
    addTearDown(inspector.stop);

    final results = await Future.wait([
      inspector.start(port: taken, logUrls: false),
      inspector.start(port: taken, logUrls: false),
    ]);
    expect(inspector.isRunning, isTrue);
    expect(results[0], isNotEmpty);
    expect(results[0].first, isNot(endsWith(':$taken')));
    expect(results[0], results[1]);
  });
}
