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

implement-spec 的取代方案與 PR/MR 格式整合方式等待第二輪裁決。
來源：[implement-spec](https://github.com/mattpocock/skills/blob/v1.3.1/skills/engineering/implement-spec/SKILL.md)、[pr](https://github.com/mattpocock/skills/blob/v1.3.1/skills/engineering/pr/SKILL.md)、[retro](https://github.com/mattpocock/skills/blob/v1.3.1/skills/engineering/retro/SKILL.md)。

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
