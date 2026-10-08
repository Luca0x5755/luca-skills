# Issue tracker

採本機 Markdown，議題正文位於 `docs/issues/ISSUE-NNN-<slug>.md`。
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
將刪除與實作一起提交。跨分支長期工作使用正式追蹤器。
規格的持久內容與 promise ID 在刪除前移入真相層。
