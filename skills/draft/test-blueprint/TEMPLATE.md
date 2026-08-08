# Blueprint document template

The shape of `docs/test-blueprint.md` in the target project. Content in Traditional Chinese; identifiers and tier names in English. Every table row exists because step 2 derived it — an empty section stays present with a one-line reason rather than disappearing.

```markdown
# 測試藍圖

> 由 /test-blueprint 產生與修訂。手改條目視為藍圖失真 — 要改，走修訂提案。
> 本次核准：<日期>／來源：<spec 檔、story 清單>

## 層佈局

| 層 | 測什麼 | 誰落地 | CI 時段 |
| --- | --- | --- | --- |
| 靜態 | lint／format／型別 | scripts/check-*.sh（本藍圖產出） | presubmit |
| 單元 | 模組對其設計 | /tdd | presubmit |
| 整合 | 縫清單所列邊界 | /tdd | 受影響→presubmit；全套→merge |
| 驗收 | docs/uat-cases.md 全清單 | /uat-cases → /browser-evidence | 發佈前 |

## 縫清單

| 縫 | 服務的承諾 | 現況 |
| --- | --- | --- |
| OrderService ↔ PaymentGateway | spec §4.2 付款一致性 | 未測 |

## 追溯表

| 承諾 | 層 | 時段 | 測試／案例 |
| --- | --- | --- | --- |
| spec §3.1 會員登入 | 驗收 | 發佈前 | TC-AUTH-01 |

## 缺口清單

- spec §5.1 匯出報表 — 無任何層覆蓋

## CI 政策

- 時段：presubmit＝靜態全套＋單元＋受影響整合；merge＝完整套件；periodic＝（本專案無昂貴項，暫缺）
- flake：禁自動重試（預設）
- 覆蓋率：追溯覆蓋為完成定義；行覆蓋僅儀表，不設門檻
- 偏離預設：<無，或逐條列偏離＋理由>
```
