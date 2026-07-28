# Luca's Skills

給 AI 編碼代理用的工程技能。每個技能是一個資料夾，`SKILL.md` 是唯一入口。

## 安裝

Windows：

```powershell
.\scripts\install.ps1
```

Linux / macOS：

```bash
bash scripts/install.sh
```

連進 `~/.claude/skills`（Windows 用 Junction，不需管理員權限；其他平台用 symlink）。改這個 repo 的檔案立刻生效。

或當作外掛市集掛載（版本凍結，改檔案不會即時生效）：

```
/plugin marketplace add D:\luca-skills
/plugin install luca-skills@luca
```

## 起手式

```
/setup-skills    # 每個 repo 跑一次
/ask-luca        # 不確定該用哪個技能時
```

## 技能

分成兩類，差別只有一個：誰能呼叫它。**使用者觸發**的技能只有你打字才會啟動，它們負責編排流程。**模型觸發**的技能你和代理都能叫，代理判斷任務吻合時會自己伸手拿，它們裝的是可重複使用的紀律。

### 使用者觸發

- **[ask-luca](./skills/core/ask-luca/SKILL.md)** — 路由器。問「這個情況該用哪個技能」。
- **[setup-skills](./skills/core/setup-skills/SKILL.md)** — 設定這個 repo 的議題追蹤器與領域文件位置。每個 repo 跑一次。
- **[grill-with-docs](./skills/core/grill-with-docs/SKILL.md)** — 有狀態的訪談：磨利想法，順手把術語寫進 `CONTEXT.md`、決策寫成 ADR。
- **[handoff](./skills/core/handoff/SKILL.md)** — 把當前對話壓縮成交接文件，讓新的 session 接手。
- **[to-spec](./skills/core/to-spec/SKILL.md)** — 把對話收斂成規格並發到議題追蹤器。不訪談，只綜合。
- **[to-tickets](./skills/core/to-tickets/SKILL.md)** — 切成曳光彈票，每張標明阻塞邊。
- **[implement](./skills/core/implement/SKILL.md)** — 依規格或票建置，在議定的接縫上驅動 `/tdd`，收尾跑 `/code-review` 再提交。
- **[triage](./skills/core/triage/SKILL.md)** — 把外來議題推過五個角色的狀態機。
- **[improve-codebase-architecture](./skills/core/improve-codebase-architecture/SKILL.md)** — 掃描深化機會，排序後交給你挑。只勘查，不動手。
- **[wayfinder](./skills/core/wayfinder/SKILL.md)** — 大到一個 session 裝不下的迷霧：畫決策票地圖，一次解一張。產出決策，不產出交付物。

### 模型觸發

- **[grilling](./skills/core/grilling/SKILL.md)** — 訪談原語。一次一題、每題附建議答案、事實自己查決策問人。
- **[domain-modeling](./skills/core/domain-modeling/SKILL.md)** — 挑戰模糊術語、拆開超載的詞、把難以回頭的決策寫成 ADR。
- **[prototype](./skills/core/prototype/SKILL.md)** — 用完即丟的原型，只回答一個設計問題。
- **[tdd](./skills/core/tdd/SKILL.md)** — 紅綠循環，一次一片垂直切面。測試打在接縫上，不打內部實作。
- **[code-review](./skills/core/code-review/SKILL.md)** — 雙軸審查：Standards（合不合這個 repo 的規範）與 Spec（有沒有做到票要求的事），平行子代理跑。
- **[diagnosing-bugs](./skills/core/diagnosing-bugs/SKILL.md)** — 硬 bug 的診斷迴圈。沒有緊迴圈之前不准提理論。

## 主流程

```
/setup-skills（一次）
      ↓
/grill-with-docs ──→ /to-spec ──→ /to-tickets ──→ /implement ──→ /tdd ──→ /code-review ──→ commit
      │                                              ↑
      └─ 需要可執行的答案時：                          │
         /handoff → /prototype → /handoff ────────────┘

交流道：/triage → /implement
       /diagnosing-bugs → /improve-codebase-architecture
       /wayfinder → /to-spec
```

`/grill-with-docs` 到 `/to-tickets` 要待在**同一個未中斷的上下文視窗**內。每個 `/implement` 之間清空上下文。

## 維護

```bash
bash scripts/check.sh
```

一致性規則全部由這支腳本強制，CI 每次 PR 都跑。詳見 [CLAUDE.md](./CLAUDE.md)。
