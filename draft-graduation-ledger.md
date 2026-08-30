# Draft 畢業帳本

draft 技能的試用紀錄，只增不改。畢業判準見 `CLAUDE.md`〈新增技能〉：用滿試用期、真實情境下內容修過至少一輪，才搬進 `core/`。一行一事件：日期、技能、發生什麼、為什麼。

## 2026-08-27 — 真相刀組重構（第一輪修訂）

- **bootstrap-truth** — 修訂第 1 輪：與 consolidate-docs 合併為一次性正規化刀。新增：既有治理煞車（Phase A 第一步）、mapping 表 `drop` 去向帶主張層級、矛盾偵測委派 audit-truth 子代理、機械檢查安裝步驟、「視圖由 join 機讀邊生成」規則。LAYERS.yaml 分層段留白，等 Smart-Lock 實測回報。
- **consolidate-docs** — 進 `archive/`：搬運工性格與 Phase A/B 骨架被 bootstrap-truth 吸收，單獨存在只剩「先跑我再跑它」的順序負擔。
- **audit-truth** — 新建：持續性稽核刀，唯一矛盾引擎（只收文件↔程式碼、文件↔文件兩類），轉接模式優先寫宿主漂移總帳、絕不自開第二本帳。與 bootstrap-truth 成對（一把立真相、一把守真相）。尚未實戰；首戰預定 Smart-Lock（spec-drift-ledger 轉接）。
- **frontend-spec** — 對齊：`/consolidate-docs` 指涉改為 `/bootstrap-truth`。
- **to-architecture** — 對齊：`/consolidate-docs` 指涉改為 `/bootstrap-truth`；Rules 新增「視圖由生成器 join 機讀邊、不手寫」。

## 2026-08-28 — 問卷補建議行

- **audit-truth / bootstrap-truth** — 修訂：裁決問卷每題除封閉選項外，必附 `➡️` 建議裁決＋一行證據依據（採 `/grilling` 的事實／決策分工：證據是代理的活、裁決是使用者的權；無證據依據就建議「不確定」）。這是舊 consolidate-docs 衝突表「carries a recommendation」的性格，合併時漏掉、本次補回。

## 2026-08-29 — 實測回饋修訂（badminton＋Smart-Lock 首戰，grilling 定案）

實測結果：badminton 稽核跑得像樣但 22 張票死在帳本、產出 untracked；Smart-Lock 稽核裁決落 CHANGELOG 沒寫回帳本（名義轉接）、bootstrap 的 688 檔映射表 15 分鐘被 revert（使用者要瘦身，刀給搬家計畫）。據此：

- **bootstrap-truth** — 修訂第 2 輪：性格從搬運工轉瘦身師。目標形狀定為「編號合訂本（01/03/04/05/mockup）＋ `capabilities/` 能力薄檔」；煞車改為「在宿主治理形狀內提瘦身方案＋補能力層」；提案報告從映射表改為每文件瘦身方案；砍字 commit 事實零增刪、事實變更走問卷另開 commit；搬運模式降級為 `MIGRATION.md` 分支（僅限完全無治理的四散專案）。
- **audit-truth** — 修訂第 2 輪：補收尾四件套 — 裁決完成判準＝帳本檔 diff 非空、票必開進 tracker、產出走 /git-commit 自行提交、問卷不落 repo 根且記完即刪。
- **to-architecture / frontend-spec** — 對齊第 2 輪：落點從 `docs/architecture.md`＋`docs/specs/<cap>.md` 改為 03／05 合訂本，章節標能力、能力薄檔反列章節（落單即紅）；style tokens 收進 05 的章節（`docs/design-system.md` 退場）。
- **連鎖對齊**：implement 的真相層行、setup-skills 的 private-mode 排除清單、flow.svg 的真相層倉儲卡。

定案依據：與使用者 grilling 九題收樹（能力文件多份、規格不拆散、不訂行數、對應機械可查、只改技能不動專案）。

待驗證（回報後才動）：Smart-Lock 手動走分層四步 → bootstrap-truth 補分層段；audit-truth 轉接模式首戰 → 修訂內容；兩處 HOOKS.md 活過 → 修訂 `/writing-hooks`。
