#!/usr/bin/env node
// 存 Penpot 版本並回報快照累積狀況。token 只送往 PENPOT_URL，絕不印出。
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, renameSync, rmSync, writeFileSync } from 'node:fs';
import { parseArgs, parseEnv } from 'node:util';

const { values: args } = parseArgs({
  options: {
    file: { type: 'string' },
    check: { type: 'boolean' },
    pr: { type: 'string' },
    export: { type: 'string' },
  },
});

const origin = process.env.PENPOT_URL ?? 'http://localhost:9001';

function fail(message) {
  console.error(message);
  process.exit(1);
}

// 先讀使用者層級環境變數，沒有才讀執行目錄的 .env。
// 用 parseEnv 而非 loadEnvFile，避免整份 .env 被 gh 子行程繼承。
function readToken() {
  const dotenv = existsSync('.env') ? parseEnv(readFileSync('.env', 'utf8')) : {};
  const token = process.env.PENPOT_ACCESS_TOKEN || dotenv.PENPOT_ACCESS_TOKEN;
  return token || fail('找不到 PENPOT_ACCESS_TOKEN：請設定環境變數或寫進專案 .env');
}

if (!args.file) fail('缺少 --file <檔案 id>');
if (args.pr !== undefined && !/^\d+$/.test(args.pr)) fail(`PR 編號必須是數字：${args.pr}`);
if (!args.check && !args.pr && !args.export) fail('請指定 --check、--pr <編號> 或 --export <快照路徑>');

const auth = { Authorization: `Token ${readToken()}` };

async function post(method, params, accept) {
  const res = await fetch(`${origin}/api/main/methods/${method}`, {
    method: 'POST',
    headers: { ...auth, Accept: accept, 'Content-Type': 'application/json' },
    body: JSON.stringify(params),
  }).catch((e) => fail(`連不到 Penpot（${origin}）：${e.message}`));
  if (!res.ok) fail(`${method} 失敗：HTTP ${res.status}`);
  return res;
}

async function rpc(method, params) {
  return (await post(method, params, 'application/json')).json();
}

// 只看人存的版本；系統自動版本的 revn 不代表有人記過這個狀態
async function userVersions(fileId) {
  const all = await rpc('get-file-snapshots', { fileId });
  return all
    .filter((v) => v.createdBy === 'user')
    .sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
}

async function currentRevn(fileId) {
  return (await rpc('get-file', { id: fileId })).revn;
}

async function check(fileId) {
  const versions = await userVersions(fileId);
  const last = versions.findLast((v) => v.label?.startsWith('repo-'));
  const since = last ? versions.slice(versions.indexOf(last) + 1) : versions;
  // 同一個 PR 改過設計會存多次，只算一個
  const prs = new Set(since.map((v) => v.label).filter((l) => l?.startsWith('pr-')));
  if (last) {
    const days = Math.floor((Date.now() - new Date(last.createdAt)) / 86400000);
    console.log(`上次快照版本：${last.label}（${days} 天前）`);
  } else {
    console.log('上次快照版本：尚無');
  }
  console.log(`之後累積的 pr-* 版本：${prs.size} 個`);
}

// 走 shell 才找得到 .cmd 形式的 gh；參數只有驗證過的數字，內文走 stdin
function gh(command, input) {
  return spawnSync(`gh ${command}`, { shell: true, input, encoding: 'utf8' });
}

// 回傳錯誤訊息；成功回傳 null
function addLabelToPrBody(pr, label) {
  const line = `Penpot 版本：\`${label}\``;
  const view = gh(`pr view ${pr} --json body -q .body`);
  if (view.status !== 0) return view.stderr || 'gh pr view 失敗';
  if (view.stdout.includes(line)) {
    console.log(`PR 說明已有 ${label}`);
    return null;
  }
  const edit = gh(`pr edit ${pr} --body-file -`, `${view.stdout.trimEnd()}\n\n${line}\n`);
  if (edit.status !== 0) return edit.stderr || 'gh pr edit 失敗';
  console.log(`已把 ${label} 寫進 PR 說明`);
  return null;
}

async function savePrVersion(fileId, pr) {
  const label = `pr-${pr}`;
  const revn = await currentRevn(fileId);
  const versions = await userVersions(fileId);
  const latest = Math.max(0, ...versions.map((v) => v.revn));
  if (revn > latest) {
    await rpc('create-file-snapshot', { fileId, label });
    console.log(`已存版本 ${label}（r${revn}）`);
  } else if (!versions.some((v) => v.label === label)) {
    console.log(`略過：r${revn} 沒有比最新版本 r${latest} 新`);
    return;
  }
  // 版本已存在時仍補寫說明，上次改說明失敗才救得回來
  const error = addLabelToPrBody(pr, label);
  if (error) fail(`版本 ${label} 已存，但 PR 說明沒有改成：${error}\n修好後重跑同一個指令即可補寫。`);
}

// export-binfile 以事件串流回報進度，完成事件帶下載連結
async function downloadBinfile(fileId) {
  const res = await post('export-binfile', { fileId, includeLibraries: false, embedAssets: false }, 'text/event-stream');
  const end = (await res.text()).split(/\r?\n\r?\n/).find((block) => /^event:\s*end/m.test(block));
  if (!end) fail('匯出失敗：伺服器沒有回傳完成事件');
  const data = end.split(/\r?\n/).filter((l) => l.startsWith('data:')).map((l) => l.slice(5).trim());
  const uri = JSON.parse(data.join(''))['~#uri'];
  // token 只能送往 Penpot 本身
  if (new URL(uri).origin !== new URL(origin).origin) fail(`匯出失敗：下載連結指向其他來源 ${new URL(uri).origin}`);
  const download = await fetch(uri, { headers: auth }).catch((e) => fail(`下載失敗：${e.message}`));
  if (!download.ok) fail(`下載失敗：HTTP ${download.status}`);
  const bytes = Buffer.from(await download.arrayBuffer());
  // .penpot 是 zip；擋掉錯誤頁，避免覆蓋掉好的快照
  if (bytes.subarray(0, 2).toString('latin1') !== 'PK') fail('匯出失敗：下載內容不是 .penpot 檔');
  return bytes;
}

// 順序讓失敗時不留假紀錄：確認下載內容與 revn、寫好暫存檔，才存版本並覆蓋快照
async function exportSnapshot(fileId, path) {
  const revn = await currentRevn(fileId);
  const bytes = await downloadBinfile(fileId);
  if ((await currentRevn(fileId)) !== revn) fail('匯出失敗：檔案在匯出期間被修改，等修改停下後再跑一次');

  const label = `repo-r${revn}`;
  const temp = `${path}.tmp`;
  // fail() 直接結束行程，finally 不會跑，所以掛在 exit 上清理
  process.on('exit', () => rmSync(temp, { force: true }));
  try {
    writeFileSync(temp, bytes);
    const versions = await userVersions(fileId);
    if (!versions.some((v) => v.label === label)) {
      await rpc('create-file-snapshot', { fileId, label });
      console.log(`已存版本 ${label}`);
    }
    renameSync(temp, path);
  } catch (e) {
    fail(`快照沒有更新（版本 ${label} 可能已存）：${e.message}`);
  }
  console.log(`已更新快照 ${path}（${(bytes.length / 1048576).toFixed(2)} MiB），提交由人決定`);
}

if (args.check) await check(args.file);
if (args.pr) await savePrVersion(args.file, args.pr);
if (args.export) await exportSnapshot(args.file, args.export);
