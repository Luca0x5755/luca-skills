// 從 CLI 邊界測試：假 Penpot 伺服器、假 gh，不碰本機真實 Penpot 與 GitHub
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { delimiter, join } from 'node:path';
import { after, test } from 'node:test';
import { fileURLToPath } from 'node:url';

const SCRIPT = fileURLToPath(new URL('./penpot-versions.mjs', import.meta.url));
const FILE = 'file-1';
const servers = [];
const tempDirs = [];
after(() => {
  servers.forEach((s) => s.close());
  tempDirs.forEach((d) => rmSync(d, { recursive: true, force: true }));
});

function tempDir(prefix) {
  const dir = mkdtempSync(join(tmpdir(), prefix));
  tempDirs.push(dir);
  return dir;
}

// 假 Penpot：versions 與 revn 由測試指定，收到的呼叫記在 calls
async function fakePenpot({ revn = 10, versions = [] } = {}) {
  const state = { revn, versions: [...versions], calls: [] };
  const server = createServer((req, res) => {
    let body = '';
    req.on('data', (c) => (body += c));
    req.on('end', () => {
      const name = req.url.split('/').pop();
      state.calls.push({ name, auth: req.headers.authorization });
      if (state.failStatus) {
        res.statusCode = state.failStatus;
        return res.end('{}');
      }
      if (name === 'export-binfile' && state.editDuringExport) state.revn += 1;
      if (name === 'export-binfile') {
        res.setHeader('Content-Type', 'text/event-stream');
        const uri = state.exportUri ?? `${state.url}/assets/out.penpot`;
        res.write('event: progress\ndata: {"section":"files"}\n\n');
        if (!state.exportNoEnd) res.write(`event: end\ndata: ${JSON.stringify({ '~#uri': uri })}\n\n`);
        return res.end();
      }
      if (name === 'out.penpot') return res.end(state.download ?? Buffer.from('PK-new-snapshot'));
      const json = (v) => res.end(JSON.stringify(v));
      if (name === 'get-file') return json({ revn: state.revn });
      if (name === 'get-file-snapshots') return json(state.versions);
      if (name === 'create-file-snapshot') {
        const { label } = JSON.parse(body);
        state.versions.push({ label, revn: state.revn, createdBy: 'user', createdAt: new Date().toISOString() });
        return json({ id: 'new' });
      }
      res.statusCode = 404;
      json({ code: 'not-found' });
    });
  });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  servers.push(server);
  state.url = `http://127.0.0.1:${server.address().port}`;
  return state;
}

function run(args, { penpot, cwd = tempDir('pv-'), env = {} }) {
  return new Promise((resolve) => {
    const childEnv = { ...process.env, PENPOT_URL: penpot.url, PENPOT_ACCESS_TOKEN: 'tok', ...env };
    for (const k of Object.keys(childEnv)) if (childEnv[k] === undefined) delete childEnv[k];
    const p = spawn(process.execPath, [SCRIPT, '--file', FILE, ...args], { cwd, env: childEnv });
    let out = '';
    let err = '';
    p.stdout.on('data', (d) => (out += d));
    p.stderr.on('data', (d) => (err += d));
    p.on('close', (code) => resolve({ code, out, err }));
  });
}

const daysAgo = (n) => new Date(Date.now() - n * 86400000).toISOString();
const version = (label, revn, days, createdBy = 'user') => ({ label, revn, createdBy, createdAt: daysAgo(days) });

test('--check 回報上次 repo-* 之後累積的 pr-* 數量與天數', async () => {
  const penpot = await fakePenpot({
    versions: [version('pr-1', 3, 20), version('repo-r5', 5, 9), version('pr-2', 6, 4), version('pr-3', 7, 1)],
  });
  const r = await run(['--check'], { penpot });
  assert.equal(r.code, 0, r.err);
  assert.match(r.out, /repo-r5/);
  assert.match(r.out, /9 天/);
  assert.match(r.out, /pr-\* 版本：2 個/);
});

test('--check 沒有 repo-* 時說明尚無並計入全部 pr-*，系統版本不計', async () => {
  const penpot = await fakePenpot({
    versions: [version('pr-1', 3, 5), version('snapshot-x', 4, 1, 'system'), version('November 4th', 2, 9)],
  });
  const r = await run(['--check'], { penpot });
  assert.equal(r.code, 0, r.err);
  assert.match(r.out, /尚無/);
  assert.match(r.out, /pr-\* 版本：1 個/);
});

test('--check 不建立任何版本', async () => {
  const penpot = await fakePenpot({ versions: [version('pr-1', 3, 5)] });
  await run(['--check'], { penpot });
  assert.equal(penpot.versions.length, 1);
  assert.ok(!penpot.calls.some((c) => c.name === 'create-file-snapshot'));
});

test('環境變數優先於 .env 的 token', async () => {
  const penpot = await fakePenpot();
  const cwd = tempDir('pv-');
  writeFileSync(join(cwd, '.env'), 'PENPOT_ACCESS_TOKEN=from-dotenv\n');
  await run(['--check'], { penpot, cwd, env: { PENPOT_ACCESS_TOKEN: 'from-env' } });
  assert.equal(penpot.calls[0].auth, 'Token from-env');
});

test('沒有環境變數時讀執行目錄的 .env', async () => {
  const penpot = await fakePenpot();
  const cwd = tempDir('pv-');
  writeFileSync(join(cwd, '.env'), 'OTHER=1\nPENPOT_ACCESS_TOKEN="from-dotenv"\n');
  await run(['--check'], { penpot, cwd, env: { PENPOT_ACCESS_TOKEN: undefined } });
  assert.equal(penpot.calls[0].auth, 'Token from-dotenv');
});

test('完全找不到 token 時失敗且不呼叫 Penpot', async () => {
  const penpot = await fakePenpot();
  const r = await run(['--check'], { penpot, env: { PENPOT_ACCESS_TOKEN: undefined } });
  assert.notEqual(r.code, 0);
  assert.match(r.err, /PENPOT_ACCESS_TOKEN/);
  assert.equal(penpot.calls.length, 0);
});

test('連不到 Penpot 時失敗，輸出不含 token', async () => {
  const penpot = await fakePenpot();
  penpot.url = 'http://127.0.0.1:1';
  const r = await run(['--check'], { penpot, env: { PENPOT_ACCESS_TOKEN: 'secret-token' } });
  assert.notEqual(r.code, 0);
  assert.doesNotMatch(r.out + r.err, /secret-token/);
});

// 假 gh：放在 PATH 最前面，PR 說明存在檔案裡；同時提供 sh 與 Windows 的進入點
function fakeGh({ body = '原本的說明\n', failEdit = false } = {}) {
  const dir = tempDir('pv-gh-');
  const bodyFile = join(dir, 'body.txt');
  const log = join(dir, 'log.txt');
  writeFileSync(bodyFile, body);
  writeFileSync(log, '');
  const impl = join(dir, 'gh.mjs');
  writeFileSync(
    impl,
    `import { appendFileSync, readFileSync, writeFileSync } from 'node:fs';
const a = process.argv.slice(2);
appendFileSync(${JSON.stringify(log)}, a.join(' ') + String.fromCharCode(10));
if (a[1] === 'view') process.stdout.write(readFileSync(${JSON.stringify(bodyFile)}, 'utf8'));
if (a[1] === 'edit') {
  if (${failEdit}) { console.error('gh edit failed'); process.exit(1); }
  writeFileSync(${JSON.stringify(bodyFile)}, readFileSync(0, 'utf8'));
}
`,
  );
  writeFileSync(join(dir, 'gh'), `#!/bin/sh\nexec "${process.execPath}" "${impl}" "$@"\n`, { mode: 0o755 });
  writeFileSync(join(dir, 'gh.cmd'), `@"${process.execPath}" "${impl}" %*\r\n`);
  return {
    env: { PATH: `${dir}${delimiter}${process.env.PATH}`, Path: `${dir}${delimiter}${process.env.PATH}` },
    body: () => readFileSync(bodyFile, 'utf8'),
    log: () => readFileSync(log, 'utf8'),
  };
}

test('--pr 在 revn 較新時存 pr-<編號> 並把標籤寫進 PR 說明', async () => {
  const penpot = await fakePenpot({ revn: 12, versions: [version('pr-1', 10, 3)] });
  const gh = fakeGh();
  const r = await run(['--pr', '7'], { penpot, env: gh.env });
  assert.equal(r.code, 0, r.err);
  assert.equal(penpot.versions.at(-1).label, 'pr-7');
  assert.match(gh.body(), /^原本的說明/);
  assert.match(gh.body(), /pr-7/);
  assert.match(gh.log(), /pr edit 7/);
});

test('--pr 在 revn 沒有更新時略過，不存版本也不改 PR 說明', async () => {
  const penpot = await fakePenpot({ revn: 10, versions: [version('pr-1', 10, 3)] });
  const gh = fakeGh();
  const r = await run(['--pr', '7'], { penpot, env: gh.env });
  assert.equal(r.code, 0, r.err);
  assert.match(r.out, /略過/);
  assert.equal(penpot.versions.length, 1);
  assert.equal(gh.body(), '原本的說明\n');
});

test('--pr 比對時忽略系統版本，自動版本追上 revn 仍會存', async () => {
  const penpot = await fakePenpot({
    revn: 12,
    versions: [version('pr-1', 10, 3), version('snapshot-x', 12, 0, 'system')],
  });
  const r = await run(['--pr', '7'], { penpot, env: fakeGh().env });
  assert.equal(r.code, 0, r.err);
  assert.equal(penpot.versions.at(-1).label, 'pr-7');
});

test('--pr 的 revn 比對取最大值，不看建立順序', async () => {
  const penpot = await fakePenpot({ revn: 8, versions: [version('a', 10, 5), version('b', 2, 1)] });
  const r = await run(['--pr', '7'], { penpot, env: fakeGh().env });
  assert.match(r.out, /略過/);
});

test('--pr 重跑不重複寫入 PR 說明', async () => {
  const penpot = await fakePenpot({ revn: 12 });
  const gh = fakeGh();
  await run(['--pr', '7'], { penpot, env: gh.env });
  await run(['--pr', '7'], { penpot, env: gh.env });
  assert.equal(gh.body().match(/pr-7/g).length, 1);
  assert.equal(penpot.versions.length, 1);
});

test('--pr 改說明失敗時回報版本已存，重跑可補寫', async () => {
  const penpot = await fakePenpot({ revn: 12 });
  const broken = fakeGh({ failEdit: true });
  const first = await run(['--pr', '7'], { penpot, env: broken.env });
  assert.notEqual(first.code, 0);
  assert.match(first.err, /pr-7/);
  const gh = fakeGh();
  const second = await run(['--pr', '7'], { penpot, env: gh.env });
  assert.equal(second.code, 0, second.err);
  assert.equal(penpot.versions.length, 1);
  assert.match(gh.body(), /pr-7/);
});

test('--pr 拒絕不是數字的編號，且不碰 Penpot', async () => {
  const penpot = await fakePenpot();
  const r = await run(['--pr', '7; rm -rf x'], { penpot, env: fakeGh().env });
  assert.notEqual(r.code, 0);
  assert.equal(penpot.calls.length, 0);
});

// 匯出測試的快照放在獨立目錄，才能確認沒有留下暫存檔
function snapshotPath(content) {
  const dir = tempDir('pv-out-');
  const path = join(dir, 'design.penpot');
  if (content !== undefined) writeFileSync(path, content);
  return { dir, path };
}

test('--export 確認下載成功後才存 repo-r<revn> 並覆蓋快照', async () => {
  const penpot = await fakePenpot({ revn: 12 });
  const { path } = snapshotPath('old');
  const r = await run(['--export', path], { penpot });
  assert.equal(r.code, 0, r.err);
  assert.equal(penpot.versions.at(-1).label, 'repo-r12');
  assert.match(readFileSync(path, 'latin1'), /^PK/);
  const names = penpot.calls.map((c) => c.name);
  assert.ok(names.indexOf('export-binfile') < names.indexOf('create-file-snapshot'));
});

test('--export 在同一個 revn 重跑不會重複存版本', async () => {
  const penpot = await fakePenpot({ revn: 12, versions: [version('repo-r12', 12, 1)] });
  const { path } = snapshotPath();
  const r = await run(['--export', path], { penpot });
  assert.equal(r.code, 0, r.err);
  assert.equal(penpot.versions.length, 1);
  assert.ok(existsSync(path));
});

test('--export 伺服器沒回傳完成事件時失敗且不動舊快照', async () => {
  const penpot = await fakePenpot({ revn: 12 });
  penpot.exportNoEnd = true;
  const { dir, path } = snapshotPath('old');
  const r = await run(['--export', path], { penpot });
  assert.notEqual(r.code, 0);
  assert.equal(readFileSync(path, 'utf8'), 'old');
  assert.deepEqual(readdirSync(dir), ['design.penpot']);
});

test('--export 下載內容不是 zip 時失敗且不動舊快照', async () => {
  const penpot = await fakePenpot({ revn: 12 });
  penpot.download = Buffer.from('<html>error</html>');
  const { dir, path } = snapshotPath('old');
  const r = await run(['--export', path], { penpot });
  assert.notEqual(r.code, 0);
  assert.equal(readFileSync(path, 'utf8'), 'old');
  assert.deepEqual(readdirSync(dir), ['design.penpot']);
});

test('--export 的下載連結指向其他來源時拒絕，不把 token 送出去', async () => {
  const other = await fakePenpot();
  const penpot = await fakePenpot({ revn: 12 });
  penpot.exportUri = `${other.url}/assets/out.penpot`;
  const { path } = snapshotPath('old');
  const r = await run(['--export', path], { penpot });
  assert.notEqual(r.code, 0);
  assert.equal(other.calls.length, 0);
  assert.equal(readFileSync(path, 'utf8'), 'old');
});

test('Penpot 回 HTTP 錯誤時失敗並指出方法', async () => {
  const penpot = await fakePenpot();
  penpot.failStatus = 500;
  const r = await run(['--check'], { penpot });
  assert.notEqual(r.code, 0);
  assert.match(r.err, /get-file-snapshots.*500/);
});

test('沒給指令或給空路徑時失敗，不會假裝完成', async () => {
  const penpot = await fakePenpot();
  assert.notEqual((await run([], { penpot })).code, 0);
  assert.notEqual((await run(['--export', ''], { penpot })).code, 0);
  assert.equal(penpot.calls.length, 0);
});

test('--check 同一個 PR 存過兩次只算一個', async () => {
  const penpot = await fakePenpot({ versions: [version('pr-1', 3, 5), version('pr-1', 4, 2)] });
  const r = await run(['--check'], { penpot });
  assert.match(r.out, /pr-\* 版本：1 個/);
});

test('--pr 說明裡有相似標籤時仍會寫入', async () => {
  const penpot = await fakePenpot({ revn: 12 });
  const gh = fakeGh({ body: '延續 pr-7-followup\n' });
  await run(['--pr', '7'], { penpot, env: gh.env });
  assert.match(gh.body(), /Penpot 版本：`pr-7`/);
});

test('--pr 重跑且說明已有標籤時回報狀態', async () => {
  const penpot = await fakePenpot({ revn: 12 });
  const gh = fakeGh();
  await run(['--pr', '7'], { penpot, env: gh.env });
  const r = await run(['--pr', '7'], { penpot, env: gh.env });
  assert.match(r.out, /PR 說明已有 pr-7/);
});

test('--export 下載失敗時不留下 repo-* 版本', async () => {
  const penpot = await fakePenpot({ revn: 12 });
  penpot.download = Buffer.from('<html>error</html>');
  const { path } = snapshotPath('old');
  await run(['--export', path], { penpot });
  assert.equal(penpot.versions.length, 0);
});

test('--export 目標目錄不存在時不留下 repo-* 版本', async () => {
  const penpot = await fakePenpot({ revn: 12 });
  const { dir } = snapshotPath();
  const r = await run(['--export', join(dir, 'missing', 'design.penpot')], { penpot });
  assert.notEqual(r.code, 0);
  assert.equal(penpot.versions.length, 0);
});

test('--export 期間檔案被修改時失敗，不存版本也不動舊快照', async () => {
  const penpot = await fakePenpot({ revn: 12 });
  penpot.editDuringExport = true;
  const { dir, path } = snapshotPath('old');
  const r = await run(['--export', path], { penpot });
  assert.notEqual(r.code, 0);
  assert.match(r.err, /修改/);
  assert.equal(penpot.versions.length, 0);
  assert.equal(readFileSync(path, 'utf8'), 'old');
  assert.deepEqual(readdirSync(dir), ['design.penpot']);
});

test('--export 無法覆蓋快照時回報錯誤並清掉暫存檔', async () => {
  const penpot = await fakePenpot({ revn: 12 });
  const { dir, path } = snapshotPath();
  mkdirSync(path);
  const r = await run(['--export', path], { penpot });
  assert.notEqual(r.code, 0);
  assert.match(r.err, /repo-r12/);
  assert.deepEqual(readdirSync(dir), ['design.penpot']);
});
