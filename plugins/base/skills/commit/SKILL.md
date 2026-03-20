---
name: commit
description: Generates and executes Conventional Commit messages from staged or unstaged Git changes. Use when the user says "commit", "git commit", "commit this", "commit changes", "save my changes", "quick commit", or "commit preview". Also triggers on partial commit requests like "commit src/" or "commit -p", and on preview/dry-run requests.
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git add:*), Bash(git commit:*), Bash(git reset HEAD:*), AskUserQuestion
---

# Git Commit

Generate and execute Conventional Commit messages from Git changes.

## Arguments

`$ARGUMENTS` overrides auto-detection. User hints always take precedence.

| Input                    | Effect                              |
|--------------------------|-------------------------------------|
| `preview` or `--dry-run` | Generate message without committing |
| `"add login page"`       | Use as commit subject directly      |
| `fix auth`               | Set type to `fix`, scope to `auth`  |
| `feat(payments)`         | Preserve type and scope exactly     |
| `src/api/` or `file.ts`  | Limit commit to specific paths      |
| `-p` or `partial`        | Interactive file selection          |

## Execution flow

### 1. Check working tree

Run `git status --porcelain`. If clean, say "Nothing to commit" and stop.

### 2. Resolve target files

Parse `$ARGUMENTS` for paths, flags, or patterns. If none provided, use all modified and untracked files.

### 3. Stage files

If no files are already staged, stage the resolved files.

Ask confirmation when:

- **More than 20 files** — large commits deserve a second look before staging.
- **Sensitive files detected** — accidental commits of secrets are hard to fully remove from Git history, so flag them before staging.

Sensitive patterns: `.env*`, `*.pem`, `*.key`, `*.secret`, `id_rsa`, `*.pfx`, `*.p12`, `credentials*`, `secrets*`

When confirmation is needed, list files (highlight sensitive ones with a warning) and offer three choices: stage all, select files, or cancel.

Track which files this skill staged so they can be unstaged on cancellation.

**Interactive selection** (`-p` or `partial`): list modified/untracked files with indices, let the user pick (`1,3,5`, `1-3`, `all`), stage only those.

### 4. Collect diff

```bash
git diff --cached --stat
git diff --cached
```

If the diff exceeds 200 lines, truncate and note: `[Diff truncated — first 200 of N lines]`. 200 lines covers most single-feature diffs while keeping context usage reasonable.

### 5. Generate commit message

Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification:

```
<type>(<scope>): <subject>

[optional body]
```

**Types:**

| Type       | When to use                            |
|------------|----------------------------------------|
| `feat`     | New feature                            |
| `fix`      | Bug fix                                |
| `docs`     | Documentation only                     |
| `style`    | Formatting, no logic change            |
| `refactor` | Code restructuring, no behavior change |
| `perf`     | Performance improvement                |
| `test`     | Adding or updating tests               |
| `build`    | Build system or dependencies           |
| `ci`       | CI configuration                       |
| `chore`    | Maintenance tasks                      |

**Subject:** imperative mood, lowercase, no trailing period, max 50 characters. Be specific — subjects like "update files" or "fix bug" give the reader no useful information.

**Body:** include only when the subject alone is insufficient. Max 3 lines explaining what changed and why, not how. Wrap at 72 characters. Separate from subject with a blank line.

**Scope:** infer from the lowest common meaningful directory or dominant module. If the user provides a scope in `$ARGUMENTS`, use it as-is. Omit scope when paths are unrelated — a missing scope is better than a misleading one.

**Mixed concerns:** if the diff combines unrelated changes (e.g., a refactor and a feature), ask the user to clarify intent rather than guessing the type. If the diff is too large to reason about confidently, suggest splitting into multiple focused commits — smaller commits are easier to review and revert.

**No AI metadata:** do not add `Co-Authored-By`, `Generated-By`, or any header that reveals AI involvement. Many organizations audit commit metadata and flag non-human authorship — this can block merges, trigger compliance reviews, or violate team policy. The commit must be indistinguishable from a manually written one.

**Examples:**

```
feat(auth): add OAuth2 refresh token support

Tokens auto-refresh 5 minutes before expiry.
Reduces session interruptions for long-running tasks.
```

```
fix(parser): handle empty input without panic
```

```
docs: update API rate limit section in README
```

### 6. Preview or commit

- **Preview mode** (`preview` or `--dry-run`): display the generated message, then ask: `Commit with this message? (yes / edit / cancel)`.
- **Normal mode**: execute `git commit` directly.

### 7. Handle cancellation

If the user cancels after this skill staged files, offer to unstage with `git reset HEAD`. Leaving unintended staged files causes confusion for the next commit.

## Output

On success, output only the commit first line and short SHA:

```
feat(auth): add OAuth2 refresh token support
[a1b2c3d]
```
