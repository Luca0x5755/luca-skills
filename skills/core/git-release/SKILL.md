---
name: git-release
description: 更新版本檔中的版本號，彙整兩版本間的 commit 寫成繁體中文發布摘要，打 tag 推上遠端並發佈 release 頁面。
disable-model-invocation: true
argument-hint: 目標版本號，如 v0.8.1
allowed-tools: Bash(git log:*), Bash(git tag:*), Bash(git push:*), Bash(git describe:*), Bash(git commit:*), Bash(git add:*), Bash(gh pr:*), Bash(gh release:*)
---

# Git Release

Release at the given version: update the version file → summarize changes → tag → push → publish the release page.

## 1. Detect the version file — never assume

Find the project's version source by type: `pyproject.toml`, `package.json`, `.claude-plugin/plugin.json`, `Cargo.toml`, `*.csproj`…

- **Multiple found** → update all of them to the same version. Two files with different version numbers are two files lying to each other.
- **None found** → stop and ask the user where the version lives.

## 2. Bump and commit

Update the version file(s) to the target version, as its own commit (English, following the `/git-commit` format rules):

```
Bump version to 0.8.1
```

## 3. Collect changes between versions

```bash
git describe --tags --abbrev=0        # find the previous tag
git log <previous-tag>..HEAD --oneline --no-merges
```

- `--no-merges` drops meaningless automatic merge records.

## 4. Write the release notes (Traditional Chinese)

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

## 5. Tag and push

```bash
git tag -l v0.8.1                     # check whether the tag already exists
git tag -a v0.8.1 -m "<release notes>"  # exists → add -f to replace (this skill's stated exception)
git push origin v0.8.1                # replacing an existing tag → git push -f origin v0.8.1
git push                              # the version-bump commit goes up too
```

Before replacing an existing tag, report which commit it currently points to — let the user see what is being overwritten before it is overwritten.

## 6. Publish the release page

A bare tag buries the notes in `git show`; clicking the tag on GitHub must land on a release page.

```bash
gh release view v0.8.1                              # exists → gh release edit to update the notes
gh release create v0.8.1 --title "v0.8.1" --notes-file <notes>   # same notes as the tag, verbatim
```

GitLab remote → `glab release create`. No remote or no forge CLI → the annotated tag is the endpoint; say so in the report.
