# Report template

The output contract for `AI_README.md`. Nine sections in this order — the order is the reading order: run it, locate the entry, follow one path.

The headings below are the skeleton to copy. The prose under each heading is instruction, and does not survive into the report.

Write in Traditional Chinese; technical nouns stay English (`進入點 entry point`, `PostgreSQL`). Every section obeys the evidence discipline in [`SKILL.md`](SKILL.md).

Angle brackets go inside backticks — `` `<tool-agent>` ``. Bare ones render as HTML tags and vanish from the page.

---

# Project Analysis: <專案名稱>

## 1. 專案概覽

一句話核心目的。接著規模數據：檔案數、語言分佈、最後 commit 日期。

## 2. 跑起來

### 環境前提

runtime 版本、env vars、系統依賴。內容來自 step 2 的執行前簡報。

### 開發環境 (Development)

### 正式環境 (Production)

指令逐條列出，每條帶一行白話說明（做什麼、動到哪裡）與 `✅ 已驗證（…）` 或 `⚠️ 未驗證`。會執行任意碼的指令附出處 `path:line` 的警示。Production 指令永不實跑，恆為 `⚠️`。實跑踩到的坑寫在該指令下方——那是這一節最值錢的部分。

## 3. 地圖與入口點

目錄表：哪個資料夾放什麼，一行一個，只列進得了主幹的。

入口點：執行從哪裡開始，精確到 `path/to/file:line`。

## 4. 核心資料結構

主要型別／schema／狀態形狀，附程式碼片段與路徑。看懂資料就看懂一半。

## 5. 一條核心路徑

![核心路徑](./AI_README-flow.svg)

逐站說明圖上的每一步：做什麼、在哪個檔案。只追一條。

## 6. 專案黑話

| 術語 | 在這個專案裡的意思 | 出處 |
| --- | --- | --- |

只收這個 repo 自造的、或用得跟業界慣例不同的詞。

## 7. 測試作為規格

測試在哪、怎麼跑、哪一支最值得先讀（附路徑與一句話理由）。

## 8. 值得偷／別學

**值得偷**（最多三項）：每項 = 手法 + 路徑 + 為什麼這樣寫 + 搬進自己專案的前提。

**別學**（最多三項）：歷史包袱、危險寫法、已被更好方案取代的東西。

上限是三，逼出排序。

## 9. 覆蓋範圍

實際讀過的檔案清單。未讀的區域明寫。前八節的每個結論都回得到這張清單上的某個檔案。

---

> 拋棄式文件，看完請刪：`rm AI_README.md AI_README-flow.svg`
