# 上游 v1.3.1 移植分析

來源：[mattpocock/skills](https://github.com/mattpocock/skills)。
比較範圍：[v1.2.3…v1.3.1](https://github.com/mattpocock/skills/compare/v1.2.3...v1.3.1)。
目標 commit：`24fe0ef7737efae15c87225755e9f6f5965e4888`。
本專案 `8c89c57` 明確移植過 v1.2.3；後續本地改寫也納入判斷。
本專案版本仍為 0.2.3，上游版本不等於本專案版本。

## 新技能與整合研究

| 技能 | 上游能力 | 本專案對應與差異 |
| --- | --- | --- |
| implement-spec | 票構成任務圖，ready frontier 由隔離工作樹的 implementer 平行建置，merger 合入 integration branch，最後 code-review | run-queue 已有核准規格、seam reviewer、每票最多五輪、擱置與依賴傳播、人工 merge、自我核准痕跡；直接覆蓋會失去這些契約。若取代，需保留護欄、串行整合，且 worker 最後同步不能保證永遠 fast-forward：另一個 worker 可能先合入，merger 必須再次確認最新 tip |
| pr | 最小視覺摘要、before/after 證據、合併可逆性與影響範圍 | git-pr／git-mr 已負責英文標題、繁中內容、建立與清理；可吸收內容規則，保留平台生命週期，避免增加另一個入口 |
| retro | 回看 session 的第一手來源，按嚴重性提出代理環境改善 | 已新增 core 技能；機械違規優先 deterministic check，判斷規則留在審查；只提出候選，使用者選擇落實項目 |

Q5 已裁決：pr 元素併入 git-pr／git-mr，保留既有段落、新增合併風險，不另增技能。Q4 已核可並套用：保留兩個流程，run-queue 預設串行，可選最多兩個 worker 平行建置，整合與驗證串行。
來源：[implement-spec](https://github.com/mattpocock/skills/blob/v1.3.1/skills/engineering/implement-spec/SKILL.md)、[pr](https://github.com/mattpocock/skills/blob/v1.3.1/skills/engineering/pr/SKILL.md)、[retro](https://github.com/mattpocock/skills/blob/v1.3.1/skills/engineering/retro/SKILL.md)。

## Q4：兩流程並存與平行 run-queue 的可行性

結論：可行，使用者已核可並完成技能契約實作。並存的分界是執行契約，不是串行與平行：

- implement-spec：跨追蹤器、可由操作者介入、完整規格落在整合分支，PR 視需要建立。
- run-queue：已提交的本機規格與票、有限重試、卡票擱置、揭露自我核准痕跡，收尾開 PR，merge 歸使用者。

上游[文件](https://github.com/mattpocock/skills/blob/v1.3.1/docs/engineering/implement-spec.md)明示工作樹衝突、缺少 gitignored 測試資料、frontier 更新與審查收斂的限制。保留兩者不代表照抄未處理的限制。

| 最低必要設計 | 本地原因 |
| --- | --- |
| coordinator 獨占整合分支；worker 各有工作樹 | 現行 reset 與刪除不能作用在其他 worker 的工作樹 |
| running／claimed 僅作 session 暫態；重啟先檢查既有 worker 分支與工作樹 | 票尚未整合時仍存在，不能重複派工；不新增永久進度帳本 |
| 完成以整合分支上刪票且驗證綠為準 | worker 刪票只表示候選完成，不能放行下游 |
| worker 保留 spec；coordinator 最後檢查引用與 truth layer 後刪除 | implement 的最後一票判斷在平行快照中不可靠 |
| 候選整合工作樹先合併與驗證，綠才推進整合分支；整合操作串行 | worker 各自綠不代表組合綠，避免壞合併污染已交付票 |
| 整合修復計入該票重試預算，擱置不放行依賴 | 平行不能繞過既有五輪與無進展停止規則 |
| 檢查共享檔案、DB、port、fixtures 與輸出目錄；不能隔離就串行 | 任務圖獨立不等於執行資源獨立 |
| denied 停新派工與整合，worker 安全停下並保留已提交候選 | 系統性拒絕不能靠其他 worker 繼續繞過，也不能抹除別票成果 |
| worker 開工先驗 hooks、依賴、測試資料與環境 | guard-secrets 未使用 payload.cwd；check-on-stop 固定從 hook 位置定位，必須確認實際 worker 路徑；現有 Bash matcher 不能泛稱跨 harness 都生效 |

run-queue 已保留預設串行與兩個 worker 的可選平行模式；新增 implement-spec 至 core，仍以操作者可介入與跨追蹤器流程為契約。run-queue 的候選整合規則收於同目錄 PARALLEL.md。hook 工作樹定位已有 linked-worktree 回歸測試；完整平行代理執行尚未在真實票佇列演練，run-queue 維持 draft。
兩技能不能互相直接呼叫使用者觸發入口；若日後抽出共用契約，須遵循本專案的技能引用與觸發規則。

本輪驗證：新增 linked-worktree 的 hook 回歸案例，Stop hook 原版已重現漏擋；修正後從 worker root／子目錄與實際 settings 掛載命令測試。憑證檢查從 worker 子目錄掃該工作樹整份 index。三軸審查修正了子目錄漏掃、串行獨占委派與 denied 收尾規則；重用軸沒有必修。尚未以真實規格執行整輪平行代理，因此這是技能契約與機械護欄驗證，不是平行交付效能證據。

## Q5：已核可的 PR／MR 內文章節

摘要 → 問題 → 變更內容 → 設計決定 → 遷移／部署提醒（需要時） → 合併風險 → 測試。
未驗證維持在測試內。摘要只在有幫助時用最小視覺；前後證據必須是實際觀察，缺失明說；合併風險寫可逆性、回復方式與具體影響範圍。
git-pr 同時改以 --body-file 傳遞精確內文，與既有 git-commit 的多行參數規則一致。

## 優化與修正的處置

| 上游變更 | 本地處置 |
| --- | --- |
| CONTEXT／CONTEXT-MAP 改為 GLOSSARY／GLOSSARY-MAP | 遷移根目錄詞彙表與現役技能引用，setup-skills 補遷移、雙檔衝突與 private exclude 指引；歷史 decision-log 與 archive 維持原文 |
| domain-modeling 擴充觸發 | description 加入術語討論、直接撰寫或編輯詞彙表與 ADR |
| grilling 題間水平線 | 更新題目模板 |
| 明確呼叫 Skill tool，多技能分開載入 | 更新既有載入步驟；保留 mandatory 要求與本地 user-triggered 提交原語、子代理隔離例外 |
| setup 被錯誤自動呼叫 | to-spec、to-tickets、triage、wayfinder 改請使用者執行 setup-skills，設定完成後續行 |
| diagnosing 的自動架構轉接失效 | 移除 post-mortem 自動 hand-off，補清理與回報條件；ask-luca 建議修復後 retro，缺 seam 才由使用者另啟架構流程 |
| wait-what 支援 glossary map | 加入依 map 選擇對應詞彙表 |
| 六個 description 的 YAML colon-space 錯誤 | 本地未搬入上游造成錯誤的文風替換；檢查本地 frontmatter，僅修實際不合法格式 |
| 移除 resolving-merge-conflicts | 本專案原無此技能；git-merge 是獨立的人工衝突裁決契約，保留 |
| link-skills 不再連結 misc | 本地按 core／draft／archive 分桶，不存在 misc；保留既有安全安裝器 |

v1.3.1 本身只修 router 與 diagnosing 文件的過時 post-mortem 轉接；其餘集中於 v1.3.0。
完整來源：[CHANGELOG](https://github.com/mattpocock/skills/blob/v1.3.1/CHANGELOG.md)。

## Em-dash 文風

Em-dash 是 `—`，常作插入、補充或轉折，例如「先讀規格 — 再寫測試」。
上游改成「先讀規格，再寫測試」或分成兩句，依語意改用逗號、冒號、括號、句號與連接詞。
目的在於直接、平實的指令文風，不是程式行為修正，也不是所有破折號用法都錯。
使用者已裁決不搬移全庫文風改寫，因此本地既有 em-dash 保留；不能把 `—` 與 CLI 的 `--flag` 混為一談。
