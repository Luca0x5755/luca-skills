"""接收 Penpot plugin POST 過來的 board PNG，寫成 Board 匯出圖。

用法（在目標專案的工作樹裡，背景執行）：
    python receive-board.py "<page> · Empty · Desktop" "<page> · Empty · Mobile" ...

參數是這次要收的 board 名稱。全部收齊就結束（exit 0）；
10 分鐘內沒收齊就結束並列出缺的名稱（exit 1）。
plugin 端：fetch("http://127.0.0.1:47811/?name=" + encodeURIComponent(name),
            { method: "POST", body: await board.export({ type: "png" }) })
"""

import http.server
import subprocess
import sys
import threading
import urllib.parse
from pathlib import Path

PORT = 47811
TIMEOUT_S = 600

# 放在 git-common-dir 底下：不進 git、所有 worktree 共用
common = subprocess.run(
    ["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
    capture_output=True, text=True, check=True,
).stdout.strip()
OUT = Path(common) / "board-exports"
OUT.mkdir(exist_ok=True)

expected = frozenset(sys.argv[1:])
pending = set(expected)
if not expected:
    sys.exit("give the board names to receive as arguments")
done = threading.Event()


class Handler(http.server.BaseHTTPRequestHandler):
    def _cors(self):
        # plugin 跑在 Penpot 網頁的 iframe 裡，對 127.0.0.1 屬跨來源請求
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Private-Network", "true")

    def _reply(self, code, text):
        self.send_response(code)
        self._cors()
        self.end_headers()
        self.wfile.write(text.encode())

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_POST(self):
        query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        name = query.get("name", [""])[0]
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        # 只收這次點名的 board，任意名稱寫不到目錄外
        if name not in expected:
            return self._reply(400, f"not expected: {name}")
        if not body.startswith(b"\x89PNG"):
            return self._reply(400, f"not a PNG: {name}")
        path = OUT / f"{name}.png"
        path.write_bytes(body)
        pending.discard(name)
        print(f"wrote {path} ({len(body)} bytes)", flush=True)
        self._reply(200, str(len(body)))
        if not pending:
            done.set()

    def log_message(self, *args):
        pass


server = http.server.HTTPServer(("127.0.0.1", PORT), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
print(f"listening on 127.0.0.1:{PORT}, writing to {OUT}", flush=True)
done.wait(TIMEOUT_S)
server.shutdown()
if pending:
    print("missing: " + " | ".join(sorted(pending)), flush=True)
    sys.exit(1)
print("all received", flush=True)
