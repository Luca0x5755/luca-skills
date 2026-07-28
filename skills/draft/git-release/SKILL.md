---
name: git-release
description: 更新版本檔中的版本號，彙整兩版本間的 commit 寫成英文發布摘要，打 tag 推上遠端。
disable-model-invocation: true
argument-hint: 目標版本號，如 v0.8.1
allowed-tools: Bash(git log:*), Bash(git tag:*), Bash(git push:*), Bash(git describe:*), Bash(git commit:*), Bash(git add:*)
---

# Git Release

Release at the given version: update the version file → summarize changes → tag → push.

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
date +%Y-%m-%d                        # release date is looked up, not guessed
```

- `--no-merges` drops meaningless automatic merge records.
- **Collapse multiple commits on one feature into a single meaningful entry** — changelog readers care about what changed, not how many times.

## 4. Write the release notes (English)

```markdown
Release v0.8.1 - 2026-07-28

## Overview
One short paragraph summarizing the version's main purpose and core value.

## Changelog

### Features
- Added ... (past-tense verbs: Added, Resolved, Improved…)

### Bug Fixes
- Fixed ...

### Refactoring
- Simplified ...
```

Only categories with content appear; empty categories are omitted.

## 5. Tag and push

```bash
git tag -l v0.8.1                     # check whether the tag already exists
git tag -a v0.8.1 -m "<release notes>"  # exists → add -f to replace (this skill's stated exception)
git push origin v0.8.1                # replacing an existing tag → git push -f origin v0.8.1
git push                              # the version-bump commit goes up too
```

Before replacing an existing tag, report which commit it currently points to — let the user see what is being overwritten before it is overwritten.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "This project is obviously pyproject.toml" | Detection costs three seconds. Assume wrong and the version lands in a file nobody reads. |
| "The commit messages are clear enough, copy them into the changelog" | Commits are process records for developers; a changelog is a result summary for users. Distill, don't transplant. |
| "I know today's date" | You don't. `date +%Y-%m-%d`. |
