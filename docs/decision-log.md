2026-09-25 本機議題預設位置改為 `docs/issues/ISSUE-NNN-<slug>.md`，且只活在一條分支內、做完即刪 — 議題進版控後若可跨分支留存，就會退化成第二份 backlog 與第二份真相。
2026-09-25 promise ID 的帳本是真相層，不是發佈出去的規格議題 — 本機議題做完即刪，規格若兼當帳本，刪除就會讓 ID 可被重發；規格不另闢 `docs/specs/`，與 `/to-architecture` 的「規格保持合併」一致。
2026-09-25 「分支淨新增議題必須為零」的檢查建在 CI 而非 hook — 網頁開的 PR 也擋得到；分支保護（required check）留給使用者設定，技能不改儲存庫保護規則。
2026-10-01 迴圈的「一輪」只計單張票內的重試，不計票數 — 否則十張票的佇列第四張就會被判停；票的佇列是外圈，用 BLOCKED 與擱置收斂，不用輪數。
2026-10-01 為降低人工介入而評估移除 hook，結論是一條都不拆 — hook 只擋不問，不產生等待；`check-on-stop` 與 `guard-*` 正是無人看管迴圈的驗收尺與護欄。
2026-10-01 `/run-queue` 防自我核准用揭露而非關卡 — PR 按票列出被改或刪的既有測試與被駁回的審查發現；merge 本來就是人的關卡，再加驗收子代理只多一份判斷與誤擋。
2026-10-01 `/run-queue` 不做開工前「票已完成」的 no-op 判斷 — 票檔刪除即完成，誤判會讓沒做的票消失；等真實執行出現票重疊的證據再議。
2026-10-01 規劃技能（grill-with-docs、to-spec、to-tickets、to-architecture、frontend-spec）在使用者核可、寫入後自動 commit 但不 push — 原本產出全留未提交，`/run-queue` 的「工作樹乾淨」永遠過不了；不 push 讓 `git reset --soft HEAD~1` 仍能收回。
2026-10-01 `/run-queue` 開 PR 前不 squash — 每票各自的 commit 是自我核准痕跡的證據來源；`main` 由 squash merge 收成一個 commit，結果與手動 squash 相同。
2026-10-07 上游移植目標固定為 mattpocock/skills v1.3.1（24fe0ef7737efae15c87225755e9f6f5965e4888），以 v1.2.3 為基準；遷移詞彙表為 GLOSSARY 命名、採用行為修正並新增 retro，保留本地治理與 0.2.3 版本，不搬移全庫 em-dash 文風改寫。
