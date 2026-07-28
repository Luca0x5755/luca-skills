# 維護規則

技能放在 `skills/` 下的桶裡。桶的分界是**對外發佈與否**，不是能不能用：

| 桶 | 本機可用 | 對外發佈 | 受不變量 2–6 約束 |
| --- | --- | --- | --- |
| `core/` | ✅ | ✅ | ✅ |
| `draft/` | ✅ | ❌ | ❌ |
| `archive/` | ❌ | ❌ | ❌ |

`scripts/install.ps1` 連結 `core/` 與 `draft/`。draft 叫得動才試得了，試得了才畢得了業。

## 不變量

以下每一條都由 `scripts/check.sh` 強制，CI 每次 PR 跑。**加規則就要加檢查** — 沒有檢查的規則不是規則，是願望。

1. 每個技能資料夾都有 `SKILL.md`，其 `name` 等於資料夾名，且有 `description`。
2. `core/` 的每個技能在 `README.md` 都有指向 `./skills/core/<name>/SKILL.md` 的連結。
3. `draft/` 與 `archive/` 的技能不得出現在 `README.md`。
4. `.claude-plugin/plugin.json` 的 `skills` 陣列，與 `skills/core/` 的內容完全相等。
5. `.claude-plugin/plugin.json` 與 `package.json` 的 `version` 相等。
6. `skills/core/ask-luca/SKILL.md` 提到每一個 core 技能。路由器漏掉一個，就是一張說謊的地圖。

## 寫技能

**技能寫的是「怎麼做」，不是「做什麼」。** 「更新 `CONTEXT.md`」是任務。「更新 `CONTEXT.md` 時，先檢查該術語是否被三個以上意義佔用」是技能。

**觸發權限只有一個判準：模型自己主動抓這個技能，會不會做出蠢事？**

- 會 → **使用者觸發**。frontmatter 加 `disable-model-invocation: true`，`description` 改寫成給人看的一句話摘要，拿掉觸發語句。編排型的、會寫檔案的、會發議題的，都屬此類。
- 不會 → **模型觸發**。省略該欄位，`description` 保留豐富的觸發語句（"Use when the user wants…, mentions…"），讓自動呼叫打得中。純參考型、純紀律型的屬此類。

使用者觸發的技能可以呼叫模型觸發的技能，反之不行，使用者觸發之間也不行。

**依賴用 `/skill` 散文呼叫表達**（"Run the `/grilling` skill"），不要跨資料夾 `../other/FILE.md` 深連結。共用的參考文件放在擁有它的技能資料夾內。

**超過約 150 行就往外拆**成同資料夾的參考檔，`SKILL.md` 用相對連結指過去。

**留白也是一種指令。** 每一個你沒決定的事，都被交給模型的先驗，不是留在中立狀態。草稿寫完要讀它的沉默：這個省略是刻意的嗎？

## 新增技能

判準是**這份內容有沒有被真實使用驗證過**，不是它新不新。

- 從已驗證的來源移植過來（另一個 repo 用了很久的流程）→ 可以直接進 `core/`。
- 自己新推導出來的 → 進 `draft/`。沒跑過的東西沒有資格上路由器。

draft 的畢業流程：

1. `skills/draft/<name>/SKILL.md`，跑一次 `scripts/install.ps1` 讓它可被叫用。
2. 用兩週。從來沒被觸發 → `description` 的觸發語句寫壞了。觸發了但做錯事 → 該鎖成使用者觸發。內容在真實情境下改過至少一輪。
3. `git mv` 進 `core/`，同時補 `README.md` 條目、`plugin.json` 條目、`ask-luca` 的路由。
4. `bash scripts/check.sh` 綠了才 commit。
