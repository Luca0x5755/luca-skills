---
name: penpot-versions
description: 把 mockup 歷史存成 Penpot 版本、依需求更新 repo 快照。專案 CLAUDE.md 宣告了 Penpot 檔案 id 且剛開好 PR 時使用，也對應「存版本」「更新快照」「累積多少 PR」等說法。
---

# Penpot Versions

The design file on Penpot is the **master**. A **version** is a record inside Penpot. The `.penpot` file in the repo is a **snapshot**, and it may lag the master.

The project's `CLAUDE.md` declares the file id and the snapshot path. A project that declares neither is out of scope. Run every command from the project root, because the script reads `.env` from the working directory:

```bash
node <this skill's base directory>/penpot-versions.mjs --file <id> <command>
```

The token comes from the user-level `PENPOT_ACCESS_TOKEN`, then the project `.env`. Only the user sets it. When it is missing, ask them to set it and stop.

## After opening a PR: `--pr <number>`

Run once the PR exists. The script saves `pr-<number>` and appends the label to the PR body. It skips both when the file's `revn` is no newer than the latest version saved by a person, meaning that version already records the design.

Done when the command exits 0 and its output is reported: saved, or skipped. On a non-zero exit, fix the cause and rerun the same command; a rerun fills in a PR body that a failed run left out.

A design change after that run needs another run. It saves a second version under the same label, and `--check` still counts that PR once.

## When the user asks to update the snapshot: `--export <snapshot path>`

Timing is the user's call, so run this only when they ask. The script downloads the file, confirms it is a zip and that `revn` held still, then saves `repo-r<revn>` and replaces the snapshot. An edit during the export fails the run, so ask the user to pause editing and rerun.

Done when the command exits 0 and you have told the user the snapshot is ready to commit. The commit stays with the user. When the export fails, the old snapshot is intact: report the error, and offer the manual route, Penpot's "Download Penpot file (.penpot)".

## When asked how much has accumulated: `--check`

Read-only. Reports the last `repo-*` version, its age, and how many `pr-*` versions followed it. Relay the numbers and leave the export decision to the user.

## Limits

- Versions live only on the Penpot instance; a snapshot carries none of them. Tell the user before any step that relies on restoring a version from a snapshot.
- The script uses Penpot's internal RPC (`create-file-snapshot`, `export-binfile`), which an upgrade can change. A failure right after a Penpot upgrade points there first.
