# remote_network_inspector

**A DevTools-style network inspector your QA team can open in any browser — no Flutter SDK, no adb, no proxy certificates.**

Your app hosts a tiny dashboard. Testers on the same Wi-Fi open `http://<device-ip>:9945` and watch every Dio API call live: method, status, duration, size, request headers, payload, and pretty-printed response — just like the Network tab in Chrome DevTools.

![Remote Network Inspector dashboard](https://raw.githubusercontent.com/afaq35202/remote_network_inspector/main/doc/demo.gif)

## Why?

| Approach | QA needs | Untethered? | Sees HTTPS? |
|---|---|---|---|
| Flutter DevTools | Flutter SDK + USB/adb | ❌ | ✅ |
| Charles / mitmproxy | Proxy + CA certificate setup | ✅ | ⚠️ breaks with cert pinning |
| In-app inspectors (Alice, Chucker) | Nothing, but UI is on the small phone screen | ✅ | ✅ |
| **remote_network_inspector** | **A browser on the same Wi-Fi** | ✅ | ✅ |

Perfect for handing **profile/QA builds** to testers who can't run developer tooling but need to attach API payloads to bug reports.

## Features

- 📡 Live stream of every request/response over WebSocket
- 🔍 DevTools-style UI: filter by text or method, status coloring, auto-scroll
- 🗂 Headers / Payload / Response tabs with pretty-printed JSON
- 📋 **Copy as cURL** for instant bug reports
- 🕓 Buffers the last 500 calls — browsers that connect late still see app-startup requests
- 🪶 Zero dependencies besides `dio`, no assets, no native code, pure Dart

## Quick start

```yaml
dev_dependencies:
  remote_network_inspector: ^0.1.2
```

```dart
import 'package:remote_network_inspector/remote_network_inspector.dart';

final dio = Dio();

if (kProfileMode) { // or your own QA-flavor flag
  // 1. Add the interceptor FIRST so even startup calls are captured.
  dio.interceptors.add(RemoteNetworkInspectorInterceptor());

  // 2. Start the dashboard (non-blocking is fine — history is buffered).
  RemoteNetworkInspector.instance.start().then((urls) {
    debugPrint('Inspector dashboard: ${urls.first}');
    // Show urls.first in a toast or on a QA/debug screen.
  });
}
```

Build for QA, e.g. `flutter build apk --profile`, install, open the printed URL in a browser on the same network. Done.

### Configuration

```dart
RemoteNetworkInspector.instance.start(
  port: 9945,          // dashboard port
  maxHistory: 500,     // calls kept for late-joining browsers
  maxBodyChars: 200000 // truncate giant bodies
);
```

Add the interceptor **after** your auth/logging interceptors so the dashboard shows requests exactly as they leave the device (auth headers included).

## Security — read this

The dashboard is visible to **anyone on the same network** and shows full headers (including auth tokens) and bodies. Therefore:

- Gate it behind a QA flavor or `kProfileMode` — **never compile it into release builds**.
- Prefer trusted office Wi-Fi or a personal hotspot.

## Troubleshooting

- **Dashboard won't load:** many corporate/guest networks enable *AP client isolation*, which blocks device-to-device traffic. Share a hotspot from the phone (or to the phone from the laptop) instead.
- **No calls appearing:** the interceptor only sees the Dio instance(s) it's added to. Add it to each instance. Native SDK traffic (Firebase, payment SDKs) doesn't go through Dart and can't be captured.
- **Android:** `INTERNET` permission must be in your main `AndroidManifest.xml` (it already is if your app calls APIs).

## Roadmap

- `package:http` client adapter
- Optional access token for the dashboard
- Cloud relay mode for QA on a different network
- Export session as HAR

Contributions welcome!

## License

MIT
