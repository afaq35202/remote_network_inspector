# remote_network_inspector

[![pub package](https://img.shields.io/pub/v/remote_network_inspector.svg)](https://pub.dev/packages/remote_network_inspector)
[![pub points](https://img.shields.io/pub/points/remote_network_inspector)](https://pub.dev/packages/remote_network_inspector/score)
[![likes](https://img.shields.io/pub/likes/remote_network_inspector)](https://pub.dev/packages/remote_network_inspector/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**A DevTools-style network inspector your whole team can open in any browser — no Flutter SDK, no adb, no proxy certificates.**

Your app hosts a tiny dashboard. Anyone on the same Wi-Fi opens `http://<device-ip>:9945` and watches every Dio API call live: method, status, duration, size, request headers, payload, and pretty-printed response — just like the Network tab in Chrome DevTools.

Works in **debug and profile builds**, and is **automatically disabled in release builds** so it can never ship enabled by accident.

![Remote Network Inspector dashboard](https://raw.githubusercontent.com/afaq35202/remote_network_inspector/main/doc/demo.gif)

## Why?

| Approach | You need | Untethered? | Sees HTTPS? |
|---|---|---|---|
| Flutter DevTools | Flutter SDK + USB/adb | ❌ | ✅ |
| Charles / mitmproxy | Proxy + CA certificate setup | ✅ | ⚠️ breaks with cert pinning |
| In-app inspectors (Alice, Chucker) | Nothing, but UI is on the small phone screen | ✅ | ✅ |
| **remote_network_inspector** | **A browser on the same Wi-Fi** | ✅ | ✅ |

Perfect for developers debugging on their own machine **and** for handing profile/QA builds to testers who can't run developer tooling but need to attach API payloads to bug reports.

## Features

- 📡 Live stream of every request/response over WebSocket
- 🔍 DevTools-style UI: filter by text or method, status coloring, auto-scroll
- 🗂 Headers / Payload / Response tabs with pretty-printed JSON
- 📋 **Copy as cURL** for instant bug reports
- 🕓 Buffers the last 500 calls — browsers that connect late still see app-startup requests
- 🛡 Automatically disabled in release builds — safe to wire up unconditionally
- 🤖 Detects the Android emulator and prints the exact `adb forward` command you need
- 🪶 Zero dependencies besides `dio`, no assets, no native code, pure Dart

## Quick start

```yaml
dependencies:
  remote_network_inspector: ^0.2.0
```

```dart
import 'package:remote_network_inspector/remote_network_inspector.dart';

final dio = Dio();

// 1. Add the interceptor FIRST so even startup calls are captured.
dio.interceptors.add(RemoteNetworkInspectorInterceptor());

// 2. Start the dashboard (non-blocking is fine — history is buffered).
RemoteNetworkInspector.instance.start().then((urls) {
  if (urls.isNotEmpty) debugPrint('Inspector dashboard: ${urls.first}');
  // Show urls.first in a toast or on a debug/QA screen.
});
```

That's it — no build-mode checks required. The inspector runs in **debug and profile** mode and `start()` is a no-op in **release** builds (it returns an empty list). If you prefer to keep the code out of release binaries entirely, you can still guard it yourself:

```dart
if (kDebugMode || kProfileMode) {
  dio.interceptors.add(RemoteNetworkInspectorInterceptor());
  RemoteNetworkInspector.instance.start();
}
```

Run the app, open the printed URL in a browser on the same network. Done.

## Running on an emulator or simulator

### Android emulator

The Android emulator sits behind NAT: the address the package prints (usually `http://10.0.2.15:9945`) exists only *inside* the emulator and is **not reachable from your computer**. The package detects this and logs the fix — forward the port over adb:

```bash
adb forward tcp:9945 tcp:9945
```

Then open **http://localhost:9945** in your browser. (Using a custom port? Forward that port instead: `adb forward tcp:<port> tcp:<port>`.)

To remove the forwarding later:

```bash
adb forward --remove tcp:9945
```

The server runs and captures traffic on the emulator either way — `adb forward` only changes how your browser reaches it.

### iOS simulator

Nothing to do. The simulator shares your Mac's network stack, so **http://localhost:9945** works directly — no forwarding.

### Real devices

Use the printed `http://<device-ip>:9945` URL from any browser on the **same Wi-Fi network** as the device.

## Configuration

```dart
RemoteNetworkInspector.instance.start(
  port: 9945,           // dashboard port
  maxHistory: 500,      // calls kept for late-joining browsers
  maxBodyChars: 200000, // truncate giant bodies
  logUrls: true,        // print dashboard URLs to the console
  allowRelease: false,  // keep false — see Security below
);
```

Add the interceptor **after** your auth/logging interceptors so the dashboard shows requests exactly as they leave the device (auth headers included).

## Security — read this

The dashboard is visible to **anyone on the same network** and shows full headers (including auth tokens) and bodies. Therefore:

- The inspector is **disabled in release builds by default**. `allowRelease: true` overrides this — don't use it unless you fully understand the exposure.
- Prefer trusted office Wi-Fi or a personal hotspot.

## Troubleshooting

- **Dashboard won't load on the Android emulator:** you need `adb forward tcp:9945 tcp:9945` — see [Running on an emulator or simulator](#running-on-an-emulator-or-simulator).
- **Dashboard won't load on a real device:** many corporate/guest networks enable *AP client isolation*, which blocks device-to-device traffic. Share a hotspot from the phone (or to the phone from the laptop) instead.
- **No calls appearing:** the interceptor only sees the Dio instance(s) it's added to. Add it to each instance. Native SDK traffic (Firebase, payment SDKs) doesn't go through Dart and can't be captured.
- **Nothing at all in a release build:** that's by design — the inspector auto-disables in release. Use a debug or profile build.
- **Android:** `INTERNET` permission must be in your main `AndroidManifest.xml` (it already is if your app calls APIs).

## Roadmap

- `package:http` client adapter
- Optional access token for the dashboard
- Cloud relay mode for QA on a different network
- Export session as HAR

Contributions welcome!

## License

MIT
