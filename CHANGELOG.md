## 0.2.1

- Shortened the package description to fit pub.dev's 180-character limit.
- Bumped `lints` to `^6.0.0` to keep dev dependencies current.

## 0.2.0

- **Release-mode safety:** the inspector is now automatically disabled in
  release builds — `start()` becomes a no-op and no events are buffered.
  Debug and profile builds work with no build-mode checks needed. A new
  `allowRelease` parameter on `start()` overrides this (not recommended).
- **Android emulator support:** `start()` detects the emulator's NAT address
  (`10.0.2.15`), logs the exact `adb forward tcp:<port> tcp:<port>` command to
  reach the dashboard from your computer, and includes
  `http://localhost:<port>` in the returned URLs.
- Falls back to `http://localhost:<port>` when no external network interface
  is found, instead of returning an empty list.
- README: emulator/simulator guide (Android `adb forward`, iOS simulator
  works out of the box), debug+profile quick start, badges.

## 0.1.2

- Added live demo GIF to README.

## 0.1.1

- Fixed homepage, repository and issue tracker links in package metadata.

## 0.1.0

- Initial release.
- Device-hosted dashboard (HTTP + WebSocket) served at `http://<device-ip>:9945`.
- `RemoteNetworkInspectorInterceptor` for Dio: captures method, URL, status,
  duration, headers, request payload (incl. FormData), and response body.
- DevTools-style web UI: filtering, status coloring, Headers/Payload/Response
  tabs, pretty-printed JSON, auto-scroll, Copy as cURL.
- History buffer (default 500 calls) replayed to late-joining browsers.
- Configurable port, history size, and body truncation.
