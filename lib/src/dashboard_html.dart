// The web dashboard served by [RemoteNetworkInspector].
// Kept as a raw Dart string so the package needs no asset declarations.

const String dashboardHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Remote Network Inspector</title>
<style>
  :root {
    --bg: #17191c;
    --panel: #1e2126;
    --panel-2: #24282e;
    --border: #33383f;
    --text: #d7dce2;
    --text-dim: #8b929c;
    --accent: #4fb6ff;
    --ok: #6fcf7c;
    --warn: #e6b455;
    --err: #ef6b6b;
    --mono: "SF Mono", "Cascadia Code", Consolas, Menlo, monospace;
    --sans: "Segoe UI", system-ui, -apple-system, sans-serif;
  }
  * { box-sizing: border-box; margin: 0; }
  html, body { height: 100%; }
  body {
    background: var(--bg); color: var(--text);
    font: 13px/1.45 var(--sans);
    display: flex; flex-direction: column; overflow: hidden;
  }

  /* Toolbar */
  #toolbar {
    display: flex; align-items: center; gap: 10px;
    padding: 8px 12px; background: var(--panel);
    border-bottom: 1px solid var(--border); flex-wrap: wrap;
  }
  #toolbar h1 { font-size: 13px; font-weight: 600; letter-spacing: .3px; }
  .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--err); display: inline-block; }
  .dot.on { background: var(--ok); }
  #conn { color: var(--text-dim); font-size: 12px; display: flex; align-items: center; gap: 6px; }
  #filter {
    background: var(--panel-2); border: 1px solid var(--border); color: var(--text);
    border-radius: 6px; padding: 5px 10px; width: 220px; font: 12px var(--sans); outline: none;
  }
  #filter:focus { border-color: var(--accent); }
  select, button.tb {
    background: var(--panel-2); border: 1px solid var(--border); color: var(--text);
    border-radius: 6px; padding: 5px 10px; font: 12px var(--sans); cursor: pointer;
  }
  button.tb:hover { border-color: var(--accent); }
  #count { color: var(--text-dim); font-size: 12px; margin-left: auto; }

  /* Layout */
  #main { flex: 1; display: flex; min-height: 0; }
  #listwrap { flex: 1.2; min-width: 0; overflow: auto; border-right: 1px solid var(--border); }
  table { width: 100%; border-collapse: collapse; font-family: var(--mono); font-size: 12px; }
  thead th {
    position: sticky; top: 0; background: var(--panel); color: var(--text-dim);
    text-align: left; font-weight: 500; padding: 6px 10px; border-bottom: 1px solid var(--border);
    font-family: var(--sans);
  }
  tbody td { padding: 5px 10px; border-bottom: 1px solid #24272c; white-space: nowrap; }
  td.path { max-width: 320px; overflow: hidden; text-overflow: ellipsis; }
  tbody tr { cursor: pointer; }
  tbody tr:hover { background: #23272d; }
  tbody tr.sel { background: #2b3743; }
  tbody tr.failed td { color: var(--err); }
  .m { font-weight: 600; }
  .s-ok { color: var(--ok); } .s-warn { color: var(--warn); } .s-err { color: var(--err); }

  /* Detail pane */
  #detail { flex: 1; min-width: 0; display: flex; flex-direction: column; background: var(--panel); }
  #detail .placeholder { margin: auto; color: var(--text-dim); }
  #dhead { padding: 10px 14px; border-bottom: 1px solid var(--border); font-family: var(--mono); font-size: 12px; word-break: break-all; }
  #tabs { display: flex; gap: 2px; padding: 0 8px; border-bottom: 1px solid var(--border); }
  #tabs button {
    background: none; border: none; color: var(--text-dim); padding: 8px 12px;
    font: 12px var(--sans); cursor: pointer; border-bottom: 2px solid transparent;
  }
  #tabs button.active { color: var(--accent); border-bottom-color: var(--accent); }
  #dbody { flex: 1; overflow: auto; padding: 12px 14px; }
  pre {
    font: 12px/1.5 var(--mono); white-space: pre-wrap; word-break: break-word; color: var(--text);
  }
  .kv { display: grid; grid-template-columns: max-content 1fr; gap: 3px 14px; font-family: var(--mono); font-size: 12px; }
  .kv .k { color: var(--accent); }
  .sec { color: var(--text-dim); font-size: 11px; text-transform: uppercase; letter-spacing: .6px; margin: 12px 0 6px; font-family: var(--sans); }
  .sec:first-child { margin-top: 0; }
  #copycurl { margin: 0 14px 10px; align-self: flex-start; }
  @media (max-width: 760px) { #main { flex-direction: column; } #listwrap { border-right: none; border-bottom: 1px solid var(--border); } }
</style>
</head>
<body>
  <div id="toolbar">
    <h1>Network Inspector</h1>
    <span id="conn"><span class="dot" id="dot"></span><span id="connText">Connecting…</span></span>
    <input id="filter" placeholder="Filter by URL, status, body…">
    <select id="method">
      <option value="">All methods</option>
      <option>GET</option><option>POST</option><option>PUT</option>
      <option>PATCH</option><option>DELETE</option>
    </select>
    <button class="tb" id="clear">Clear</button>
    <span id="count"></span>
  </div>

  <div id="main">
    <div id="listwrap">
      <table>
        <thead><tr>
          <th>Name</th><th>Method</th><th>Status</th><th>Time</th><th>Size</th><th>Started</th>
        </tr></thead>
        <tbody id="rows"></tbody>
      </table>
    </div>
    <div id="detail"><div class="placeholder">Select a request to inspect it</div></div>
  </div>

<script>
  let calls = [];
  let selectedId = null;
  let activeTab = "headers";
  let ws = null;

  const rowsEl = document.getElementById("rows");
  const detailEl = document.getElementById("detail");
  const filterEl = document.getElementById("filter");
  const methodEl = document.getElementById("method");

  function connect() {
    ws = new WebSocket("ws://" + location.host + "/ws");
    ws.onopen = () => setConn(true);
    ws.onclose = () => { setConn(false); setTimeout(connect, 2000); };
    ws.onmessage = (e) => {
      const msg = JSON.parse(e.data);
      if (msg.type === "init") { calls = msg.data || []; }
      else if (msg.type === "call") { calls.push(msg.data); }
      else if (msg.type === "clear") { calls = []; selectedId = null; renderDetail(); }
      renderList();
    };
  }
  function setConn(on) {
    document.getElementById("dot").className = "dot" + (on ? " on" : "");
    document.getElementById("connText").textContent = on ? "Connected" : "Reconnecting…";
  }

  function visible() {
    const q = filterEl.value.toLowerCase();
    const m = methodEl.value;
    return calls.filter(c => {
      if (m && c.method !== m) return false;
      if (!q) return true;
      return (c.url + " " + (c.status || "") + " " + (c.requestBody || "") + " " +
              (c.responseBody || "")).toLowerCase().includes(q);
    });
  }

  function statusClass(c) {
    if (c.error || !c.status) return "s-err";
    if (c.status >= 500) return "s-err";
    if (c.status >= 400) return "s-warn";
    return "s-ok";
  }
  function fmtSize(n) {
    if (n == null) return "–";
    if (n < 1024) return n + " B";
    if (n < 1048576) return (n / 1024).toFixed(1) + " KB";
    return (n / 1048576).toFixed(1) + " MB";
  }
  function esc(s) {
    return String(s ?? "").replace(/[&<>"]/g, ch =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[ch]));
  }

  function renderList() {
    const list = visible();
    document.getElementById("count").textContent =
      list.length + " / " + calls.length + " requests";
    const nearBottom =
      rowsEl.parentElement.parentElement.scrollTop + rowsEl.parentElement.parentElement.clientHeight
      >= rowsEl.parentElement.parentElement.scrollHeight - 60;

    rowsEl.innerHTML = list.map(c => {
      const st = c.error ? "FAIL" : (c.status ?? "…");
      return '<tr data-id="' + c.id + '" class="' +
        (c.id === selectedId ? "sel " : "") + (c.error ? "failed" : "") + '">' +
        '<td class="path" title="' + esc(c.url) + '">' + esc(c.path) + '</td>' +
        '<td class="m">' + esc(c.method) + '</td>' +
        '<td class="' + statusClass(c) + '">' + esc(st) + '</td>' +
        '<td>' + (c.durationMs != null ? c.durationMs + " ms" : "–") + '</td>' +
        '<td>' + fmtSize(c.responseSize) + '</td>' +
        '<td>' + esc((c.time || "").substring(11, 19)) + '</td></tr>';
    }).join("");

    if (nearBottom) {
      const scroller = rowsEl.parentElement.parentElement;
      scroller.scrollTop = scroller.scrollHeight;
    }
  }

  rowsEl.addEventListener("click", e => {
    const tr = e.target.closest("tr");
    if (!tr) return;
    selectedId = Number(tr.dataset.id);
    renderList();
    renderDetail();
  });

  function pretty(body) {
    if (!body) return "(empty)";
    try { return JSON.stringify(JSON.parse(body), null, 2); }
    catch { return body; }
  }
  function kv(obj) {
    const entries = Object.entries(obj || {});
    if (!entries.length) return '<span style="color:var(--text-dim)">(none)</span>';
    return '<div class="kv">' + entries.map(([k, v]) =>
      '<span class="k">' + esc(k) + '</span><span>' + esc(v) + '</span>').join("") + '</div>';
  }
  function toCurl(c) {
    let cmd = "curl -X " + c.method + " '" + c.url + "'";
    for (const [k, v] of Object.entries(c.requestHeaders || {}))
      cmd += " \\\n  -H '" + k + ": " + v + "'";
    if (c.requestBody)
      cmd += " \\\n  -d '" + c.requestBody.replace(/'/g, "'\\''") + "'";
    return cmd;
  }

  function renderDetail() {
    const c = calls.find(x => x.id === selectedId);
    if (!c) {
      detailEl.innerHTML = '<div class="placeholder">Select a request to inspect it</div>';
      return;
    }
    const tabs = ["headers", "payload", "response"];
    let body = "";
    if (activeTab === "headers") {
      body = '<div class="sec">General</div>' +
        kv({ "Request URL": c.url, "Method": c.method,
             "Status": (c.status ?? "") + " " + (c.statusMessage || ""),
             "Duration": c.durationMs != null ? c.durationMs + " ms" : "–",
             ...(c.error ? { "Error": c.error } : {}) }) +
        '<div class="sec">Request headers</div>' + kv(c.requestHeaders) +
        '<div class="sec">Response headers</div>' + kv(c.responseHeaders);
    } else if (activeTab === "payload") {
      body = (c.query ? '<div class="sec">Query string</div><pre>' +
              esc(decodeURIComponent(c.query)) + '</pre>' : "") +
        '<div class="sec">Request body</div><pre>' + esc(pretty(c.requestBody)) + '</pre>';
    } else {
      body = '<pre>' + esc(pretty(c.responseBody)) + '</pre>';
    }

    detailEl.innerHTML =
      '<div id="dhead"><span class="m">' + esc(c.method) + '</span> ' + esc(c.url) + '</div>' +
      '<div id="tabs">' + tabs.map(t =>
        '<button data-tab="' + t + '" class="' + (t === activeTab ? "active" : "") + '">' +
        t[0].toUpperCase() + t.slice(1) + '</button>').join("") + '</div>' +
      '<div id="dbody">' + body + '</div>' +
      '<button class="tb" id="copycurl">Copy as cURL</button>';

    detailEl.querySelectorAll("#tabs button").forEach(b =>
      b.addEventListener("click", () => { activeTab = b.dataset.tab; renderDetail(); }));
    detailEl.querySelector("#copycurl").addEventListener("click", () => {
      navigator.clipboard.writeText(toCurl(c));
    });
  }

  filterEl.addEventListener("input", renderList);
  methodEl.addEventListener("change", renderList);
  document.getElementById("clear").addEventListener("click", () => {
    if (ws && ws.readyState === 1) ws.send("clear");
    calls = []; selectedId = null; renderList(); renderDetail();
  });

  connect();
  renderList();
</script>
</body>
</html>''';
