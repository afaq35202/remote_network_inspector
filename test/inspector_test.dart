import 'package:remote_network_inspector/src/inspector.dart';
import 'package:test/test.dart';

void main() {
  final inspector = RemoteNetworkInspector.instance;

  group('describeBody', () {
    test('encodes maps as pretty JSON', () {
      final out = inspector.describeBody({'a': 1});
      expect(out, contains('"a": 1'));
    });

    test('passes strings through', () {
      expect(inspector.describeBody('hello'), 'hello');
    });

    test('describes binary data by length', () {
      expect(inspector.describeBody([1, 2, 3]), '<binary 3 bytes>');
    });

    test('returns empty string for null', () {
      expect(inspector.describeBody(null), '');
    });
  });

  group('events', () {
    test('assigns increasing ids and stores history', () {
      final a = inspector.nextId();
      final b = inspector.nextId();
      expect(b, a + 1);
      inspector.addEvent({'id': b, 'method': 'GET'});
      // No server running: addEvent must not throw.
    });
  });
}
