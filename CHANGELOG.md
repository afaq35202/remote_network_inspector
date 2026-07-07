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
