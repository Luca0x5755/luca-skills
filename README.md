# Luca's Skills

給 AI 編碼代理用的工程技能。每個技能是一個資料夾，`SKILL.md` 是唯一入口。

## 安裝

Windows：

```powershell
.\scripts\install.ps1            # Claude Code（預設）
.\scripts\install.ps1 copilot    # GitHub Copilot
.\scripts\install.ps1 all        # 兩邊都裝
```

Linux / macOS：

```bash
bash scripts/install.sh          # 同樣吃 claude / copilot / all
```

連進該代理的個人技能目錄 —— Claude Code 是 `~/.claude/skills`，Copilot 是 `~/.copilot/skills`。Windows 用 Junction，不需管理員權限；其他平台用 symlink。改這個 repo 的檔案立刻生效。

> Windows 上不要用 Git Bash 跑 `install.sh`：MSYS 的 `ln -s` 會退化成複製目錄，裝出一份不會跟著更新的技能。腳本會擋下來要你改用 `install.ps1`。

### 給 Copilot 用的差異

Copilot 直接讀同一份 `SKILL.md`，不需轉檔（[Agent Skills 是共通格式](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)）。但有一個行為差異要知道：

**Copilot 不支援 `disable-model-invocation`。** 本 repo 的編排型技能（`implement`、`to-spec`、`to-tickets`、`triage`…）在 Claude Code 只有你打字才會啟動；到了 Copilot，代理判斷吻合時會自己伸手拿。緩解的是這些技能的 `description` 本來就寫成不帶觸發語句的人話摘要，不容易被比對到 —— 但那是降低機率，不是關掉開關。

只想給某個 repo 用而不是全機安裝，把技能資料夾放進該 repo 的 `.github/skills/`、`.claude/skills/` 或 `.agents/skills/` 也可以，三個路徑 Copilot 都讀。

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

[![主流程：想法 → 出貨](./assets/flow.svg)](./assets/flow.svg)

哪個階段用哪個技能：

| 階段 | 你在做什麼 | 用這個 |
| --- | --- | --- |
| 0・前置 | 告訴技能們這個 repo 的議題追蹤器與領域文件在哪 | `/setup-skills`（每個 repo 一次） |
| 1・想清楚 | 把模糊的想法磨到可以動手，順手留下術語與決策紀錄 | `/grill-with-docs`（沒有 codebase 可寫時用 `/grilling`） |
| 1・繞道 | 有問題非跑起來答不出：狀態模型、商業邏輯、非看不可的 UI | `/handoff` → 新 session → `/prototype` → `/handoff` 回來 |
| 2・切開 | 建置超過一個 session 才需要這一步 | `/to-spec` → `/to-tickets` |
| 3・建置 | 一張票一個上下文視窗，做完清空再開下一張 | `/implement`（內部驅動 `/tdd`） |
| 4・收尾 | 提交前的雙軸審查：Standards 與 Spec | `/code-review`，通過才 commit |

交流道 — 不從階段 1 開始的三種進場方式：

| 起點 | 匯入 | 什麼時候 |
| --- | --- | --- |
| `/triage` | `/implement` | 別人丟進來的 bug 與需求。自己用 `/to-tickets` 開的票已經可接手，不要再 triage。 |
| `/diagnosing-bugs` | `/improve-codebase-architecture` | 修完的結論是「當初沒有接縫可以鎖住它」時，才走這條。 |
| `/wayfinder` | `/to-spec` | 迷霧大到一個 session 裝不下。產出決策不產出交付物 — 別直接跳 `/implement`。 |

底下還有一層詞彙：卡住的是**字**不是流程時，隨時取用 `/domain-modeling`（術語模糊、一詞多義、決策要留紀錄）與 `/grilling`（訪談原語）。不確定該用哪個，跑 `/ask-luca`。

`/grill-with-docs` 到 `/to-tickets` 要待在**同一個未中斷的上下文視窗**內。每個 `/implement` 之間清空上下文。

## 維護

```bash
bash scripts/check.sh
```

一致性規則全部由這支腳本強制，CI 每次 PR 都跑。詳見 [CLAUDE.md](./CLAUDE.md)。
