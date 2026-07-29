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

- **[ask-luca](./skills/core/ask-luca/SKILL.md)** — 問這個情況該用哪個技能、走哪條流程。這個 repo 的技能路由器。
- **[setup-skills](./skills/core/setup-skills/SKILL.md)** — 為這個 repo 設定工程技能所需的組態 — 議題追蹤器與領域文件位置。每個 repo 跑一次。
- **[grill-with-docs](./skills/core/grill-with-docs/SKILL.md)** — 窮追不捨的訪談，磨利一個計畫，並沿路留下紙本軌跡 — 術語表與 ADR。
- **[handoff](./skills/core/handoff/SKILL.md)** — 把當前對話壓縮成一份交接文件，讓全新的 session 能接手這份工作。
- **[to-spec](./skills/core/to-spec/SKILL.md)** — 把當前對話收斂成一份規格，並發佈到議題追蹤器。
- **[to-tickets](./skills/core/to-tickets/SKILL.md)** — 把計畫、規格或對話切成一張張曳光彈票，每張都標明自己的阻塞邊。
- **[implement](./skills/core/implement/SKILL.md)** — 依規格或一組票建置，在議定的接縫上驅動 TDD，收尾跑一次程式碼審查。
- **[triage](./skills/core/triage/SKILL.md)** — 把外來議題推過一台由分診角色組成的狀態機，直到每一張都代理可接手或關閉。
- **[improve-codebase-architecture](./skills/core/improve-codebase-architecture/SKILL.md)** — 勘查程式庫的深化機會，排序後呈上，再對你挑中的那一個進行拷問。
- **[wayfinder](./skills/core/wayfinder/SKILL.md)** — 把龐大而迷霧重重的工程畫成一張決策票地圖，一次解一張，直到通往終點的路清晰為止。
- **[git-commit](./skills/core/git-commit/SKILL.md)** — 檢視已暫存的變更，撰寫英文 commit 並推上遠端。只提交 staged 的內容，絕不代替使用者 stage。
- **[git-pr](./skills/core/git-pr/SKILL.md)** — 開 PR（英文標題＋繁中六段式內文）與合併後清理分支，分支生命週期的頭與尾。
- **[git-release](./skills/core/git-release/SKILL.md)** — 更新版本檔中的版本號，彙整兩版本間的 commit 寫成繁體中文發布摘要，打 tag 推上遠端並發佈 release 頁面。

### 模型觸發

- **[grilling](./skills/core/grilling/SKILL.md)** — 就一個計畫、決策或想法窮追不捨地拷問使用者。當使用者想壓力測試自己的思路、想被質疑一個設計，或說出 "grill"、「拷問我」、「戳破我」這類觸發語時使用。
- **[domain-modeling](./skills/core/domain-modeling/SKILL.md)** — 建立並磨利一個專案的領域語言 — 挑戰模糊術語、拆開超載的詞、把難以回頭的決策寫成 ADR。當問題出在命名、當同一個詞在不同地方意思不同、或當一個決策需要白紙黑字的紀錄時使用。
- **[prototype](./skills/core/prototype/SKILL.md)** — 做一個用完即丟的原型來回答一個設計問題 — 狀態與邏輯用可執行的程式，UI 則做幾個可切換的變體。當一個設計問題在紙上定不下來時使用，也對應 "prototype"、"spike"、「先做個雛形看看」等說法。
- **[tdd](./skills/core/tdd/SKILL.md)** — 測試驅動開發，紅—綠—重構。當要以測試先行的方式建置功能或修 bug、當使用者提到 "TDD"、"red-green"、「紅綠」，或要求寫出能撐過重構的測試時使用。
- **[code-review](./skills/core/code-review/SKILL.md)** — 沿兩條軸審查自某個定點以來的 diff — Standards（有沒有遵守這個 repo 的規範？）與 Spec（有沒有做到票要求的事？）。當使用者要審查一個分支、一個 PR 或進行中的工作時使用，也對應 "code review"、"review this branch"、「審一下」等說法。
- **[diagnosing-bugs](./skills/core/diagnosing-bugs/SKILL.md)** — 對付硬 bug、間歇性失敗與效能回歸的紀律迴圈 — 重現、最小化、立假說、下探針、修好、補回歸測試。當東西壞了而原因不明顯時使用，也對應 "flaky"、"regression"、「時好時壞」、「找不到原因」等說法。

## 主流程

[![主流程：想法 → 出貨](./assets/flow.svg)](./assets/flow.svg)

哪個階段用哪個技能：

| 階段 | 做什麼 | 怎麼做 |
| --- | --- | --- |
| 0・前置 | 告訴技能們議題追蹤器與領域文件在哪 | `/setup-skills`，每個 repo 只跑一次 |
| 1・想清楚 | 一問一答把想法磨到可以動手 | `/grill-with-docs`（還沒有 codebase 時用 `/grilling`） |
| 1・繞道 | 有問題要跑起來才能回答 | ① `/handoff` 拿文件路徑 → ② 開新 session 貼路徑，跑 `/prototype` → ③ 答完再 `/handoff` 拿新路徑 → ④ 開新 session 貼路徑，回主流程 |
| 2・切開 | 一個 session 做不完，先切小 | `/to-spec` → `/to-tickets` |
| 3・建置 | 一個 session 做一張票 | `/clear` → `/implement` 指定一張票（會自動跑 `/tdd` 與 `/code-review`）→ 還有票就回到 `/clear` |
| 4・收尾 | 審查通過才 commit | `/code-review`（`/implement` 收尾自動跑） |

session 規則：

- 階段 1 到 2 在同一個 session 一路做完，中間不 `/clear`。
- `/to-tickets` 之後，每張票各開一個新 session。
- session 快滿了就 `/handoff`，開新 session 貼上路徑接著做。

交流道 — 不從階段 1 開始的三種進場：

| 起點 | 匯入 | 什麼時候 |
| --- | --- | --- |
| `/triage` | `/implement` | 別人回報的 bug 與需求。自己用 `/to-tickets` 開的票直接 `/implement`。 |
| `/diagnosing-bugs` | `/improve-codebase-architecture` | 難修的 bug。修完發現病根在架構，才走這條。 |
| `/wayfinder` | `/to-spec` | 題目大到不知從何下手。出來後接 `/to-spec`，不能直接跳 `/implement`。 |

名詞卡住時，隨時可用 `/domain-modeling`（術語模糊、一詞多義、決策要留紀錄）與 `/grilling`（一問一答的基本功）。不確定用哪個，打 `/ask-luca`。

## 維護

```bash
bash scripts/check.sh
```

一致性規則全部由這支腳本強制，CI 每次 PR 都跑。詳見 [CLAUDE.md](./CLAUDE.md)。
