# Issue tracker

本機與遠端兩套並存，依下列判準分流；判準只寫在這裡，技能一律指向本檔，不重述。

## 分流判準

- 預期一個 PR 內做完並刪除 → **本機議題**。
- 需多個 PR、合併後有維護或驗收、或 PR 之外有人需要追蹤它的狀態（回報者、驗收者、別的團隊）→ **遠端議題**。
- 整份規格連同票若由 `/run-queue` 或 `/implement-spec` 在一個 PR 內整合，算本機。
- 規格與它的票永遠同一邊，不跨兩邊拆。

## 本機

議題正文位於 `docs/issues/ISSUE-NNN-<slug>.md`。
NNN 為三位數，取現存議題最大編號加一；沒有議題時從 001 開始。
slug 使用英文 kebab-case。

建立議題（PowerShell；先填入編號、slug 與正文）：
```powershell
New-Item -ItemType Directory -Path docs/issues -Force | Out-Null
Set-Content -LiteralPath docs/issues/ISSUE-NNN-<slug>.md -Value $issueBody -Encoding utf8
```

列出未完成議題：
```text
rg --files docs/issues -g 'ISSUE-*.md'
```
目錄不存在或沒有檔案表示目前沒有議題。

阻塞關係寫在正文：`Blocked by: ISSUE-NNN-<slug>.md`；
沒有依賴時寫 `Blocked by: none`。

議題在同一分支建立、完成並刪除；完成時以
```text
git rm -- docs/issues/ISSUE-NNN-<slug>.md
```
將刪除與實作一起提交。規格的持久內容與 promise ID 在刪除前移入真相層。

## 遠端

GitHub（`origin` 為 `github.com/Luca0x5755/luca-skills`），以 `gh` 操作。正文位於 GitHub 議題本體，不落檔。

建立議題（正文先寫成檔，用 `-F` 傳入，不內嵌多行字串）：
```text
gh issue create --title "<title>" -F <body-file>
```

列出未完成議題：
```text
gh issue list --state open
```

阻塞關係：`gh` 沒有對應旗標，走 REST API。`<blocking-id>` 是擋住它那張議題的數字 `id`（不是議題編號 `number`）：
```text
gh api repos/{owner}/{repo}/issues/<blocked-number>/dependencies/blocked_by -F issue_id=<blocking-id>
gh issue view <number> --json id
```
第二行取 `id`。端點與 `issue_id` 來自 GitHub REST 文件 issue-dependencies 頁：`POST /repos/{owner}/{repo}/issues/{issue_number}/dependencies/blocked_by`，`issue_id` 為「The id of the issue that blocks the current issue」。實跑未驗證。

PR 與議題的引用：
- 關閉引用：`Closes #N`（同族還有 close／fix／resolve 及其變化形）。依官方文件，關鍵字只在 PR 指向預設分支時生效，合併後議題自動關閉。
- 非關閉引用（驗收議題用，由人驗收後手動關）：在 PR 描述寫 `Refs #N`，不帶任何關閉關鍵字。
  依據（GitHub Docs「Using keywords in issues and pull requests」與「Linking a pull request to an issue」）：關閉語法只有 `close／closes／closed／fix／fixes／fixed／resolve／resolves／resolved` 加議題參照；「Autolinked references」頁寫「references to issues and pull requests are automatically converted to shortened links」並「generate a backlink」。官方文件沒有逐字寫出 `Refs` 這個詞，結論是「不在關鍵字清單內的 `#N` 只連結、不關閉」的推論，未實跑驗證。
