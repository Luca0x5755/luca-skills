---
name: git-release
description: 先在終端機預覽繁體中文發布摘要，使用者確認後才更新版本、commit、打 tag、推送並發佈 release 頁面。
disable-model-invocation: true
argument-hint: 目標版本號，如 v0.8.1
allowed-tools: Bash(git log:*), Bash(git show:*), Bash(git tag:*), Bash(git push:*), Bash(git describe:*), Bash(git commit:*), Bash(git add:*), Bash(gh pr:*), Bash(gh release:*)
---

# Git Release

Release at the given version: collect changes → write and print the release preview → wait for explicit approval → update and commit the version → tag → push → publish the release page.

## 1. Detect the version file — never assume

Find the project's version source by type: `pyproject.toml`, `package.json`, `.claude-plugin/plugin.json`, `Cargo.toml`, `*.csproj`…

- **Multiple found** → identify all files to update to the same version after approval. Two files with different version numbers are two files lying to each other.
- **None found** → stop and ask the user where the version lives.

## 2. Collect changes between versions

```bash
git describe --tags --abbrev=0        # find the previous tag
git log <previous-tag>..HEAD --oneline --no-merges
```

- `--no-merges` drops meaningless automatic merge records.

## 3. Write the release notes (Traditional Chinese)

Write for users and operators. Distill the commits and PRs into changes they can observe; include internal work when it changes usage, deployment, or operations. Combine related PRs into one entry. Use `gh pr list --state merged --json number,mergeCommit` to match changes to PRs.

Group entries under `新增`, `變更`, and `修正`; put removed features under `變更`. Keep only nonempty categories. Add a one- or two-sentence opening when the release has a clear theme. Add `升級注意事項` before the categories when upgrading requires action.

Start each entry with a relevant emoji and short bold title, explain the outcome or upgrade impact, then cite relevant PRs at the end. For a direct commit without a PR, cite its short SHA. The release page already shows the version and date, so start the body with the opening or first section. The tag name and bump commit stay English.

```markdown
這個版本主要改善……，並修正……。

### 升級注意事項

- 升級前請……；既有部署需要……。

### 新增

- 📦 **功能名稱。** 說明現在能做什麼，以及必要的使用條件。 [#12](<repo>/pull/12)

### 變更

- 🔄 **現有功能名稱。** 說明行為如何改變，以及對既有部署的影響。 [#13](<repo>/pull/13)、[#14](<repo>/pull/14)

### 修正

- 🛠️ **問題名稱。** 說明原本會發生什麼問題，以及現在的結果。 [`930a450`](<repo>/commit/930a450)
```

This step is complete when every user- or operator-facing change in the release range is represented by a reader-facing entry, with its relevant source links at the end.

## 4. Print the preview and wait for approval

Write the exact release notes to a file, then print the full file in the terminal. Alongside it, print the target version, previous tag, release branch, release commit list and current HEAD SHA, and version files to be updated. The preview identifies the current release content; the version-bump commit is created only after approval.

Inspect the target tag and release page before asking for approval. If either exists, print the tag's current commit and annotation, and the release's current title and body, identifying what will be replaced. Use read-only queries such as `git tag -l`, `git show`, and `gh release view` (or the forge equivalent).

**Stop after printing and ask the user to confirm this preview.** Before explicit confirmation, perform only read-only queries and preparation of the notes file: version edits, commits, tag creation or replacement, pushes, and release creation or updates all belong after approval. Invoking this skill is not approval of the preview.

If the notes change, print the revised preview and obtain confirmation again. Recheck HEAD and existing tag/release content before starting step 5; changes require a refreshed preview and confirmation. After that, the approved version-bump commit is the expected HEAD change; any additional changes require renewed confirmation. The approved notes file supplies both the tag annotation and release body verbatim.

## 5. Bump and commit

After approval, update the version file(s) to the target version, as its own commit. Read `git-commit/SKILL.md` in the parent of this skill's base directory and follow its staging and message rules.

**Release exception to the branch rule:** on `main` / `master`, commit the approved version-only bump directly on that branch. Keep a supplied release branch when the user chose one. Include the branch in the preview; this skill does not create a new branch for the bump. Stage only the detected version files and verify that their diff contains only version changes before committing. A guard denial requires fixing the guard or reporting the block, never disabling hooks.

```
Bump version to 0.8.1
```

## 6. Tag and push

```bash
git tag -l v0.8.1                     # check whether the tag already exists
git tag -a v0.8.1 --cleanup=verbatim -F <notes> # exists → add -f to replace (this skill's stated exception)
git push                              # publish the version-bump commit first
git push origin v0.8.1                # replacing an existing tag → git push -f origin v0.8.1
```

Stop on a failed branch push before publishing the tag or release. Verify that the remote branch and peeled tag both point to the bump commit, and that the tag annotation matches the approved notes.

## 7. Publish the release page

A bare tag buries the notes in `git show`; clicking the tag on GitHub must land on a release page.

```bash
gh release view v0.8.1                              # exists → gh release edit to update the notes
gh release create v0.8.1 --title "v0.8.1" --notes-file <notes>   # same notes as the tag, verbatim
```

GitLab remote → `glab release create`. No remote or no forge CLI → the annotated tag is the endpoint; say so in the report.
