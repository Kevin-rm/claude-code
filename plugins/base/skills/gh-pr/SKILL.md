---
name: gh-pr
description: Creates a GitHub pull request using the gh CLI with Conventional Commits formatting. Use when the user says "create PR", "open PR", "make PR", "pull request", "gh-pr", "PR from X to Y", or asks to push changes for review. Handles branch detection, push confirmation, existing PR detection, and generates a structured title and body.
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git push:*), Bash(git rev-parse:*), Bash(git remote:*), Bash(gh pr:*), Bash(gh api:*), AskUserQuestion
---

# GitHub Pull Request

Create a GitHub pull request following standard conventions using the `gh` CLI.

## Arguments

`$ARGUMENTS` overrides auto-detection. Examples:

- `dev to main` → explicit head/base branches
- `--draft`, `--reviewer @user`, `--label bug` → passed to `gh pr create`
- `"fix auth flow"` → used as PR title directly

## Execution flow

### 1. Resolve branches

Detect the current branch as `head`. Use `main` as `base` unless `$ARGUMENTS` specifies otherwise.

If head equals base, stop: "Cannot create a PR from the base branch to itself."

### 2. Check for uncommitted changes

Run `git status --porcelain`. If there are uncommitted changes, warn the user and ask whether to proceed or commit first.

### 3. Ensure remote is up to date

```bash
git rev-parse --abbrev-ref --symbolic-full-name @{upstream}
```

- **Upstream exists**: check if local is ahead of remote. If so, ask the user before pushing.
- **No upstream**: suggest `git push -u origin <branch>` and ask before executing.

Never push without user confirmation.

### 4. Check for existing PR

```bash
gh pr list --head <branch> --state open
```

If a PR already exists, show its URL and ask whether to update it or stop.

### 5. Analyze changes

```bash
git log --oneline <base>..HEAD
git diff <base>...HEAD --stat
```

Read all commit messages to understand the full scope of changes, not just the latest commit.

### 6. Generate PR title and body

**Title rules:**
- Conventional Commits style: `<type>(<scope>): <subject>`
- Max 70 characters, imperative mood, lowercase, no trailing period
- Be specific — titles like "update code" or "fix bug" give no useful information
- If `$ARGUMENTS` provides a title, use it as-is

**Body template:**

```markdown
## Summary

- What changed and why (max 3 bullets, focus on why)

## Test plan

- [ ] Verification step
- [ ] Another verification step
```

### 7. Create the PR

```bash
gh pr create --base <base> --title "<title>" --body "$(cat <<'EOF'
<generated body>
EOF
)"
```

Append `--draft`, `--reviewer`, `--label` flags from `$ARGUMENTS` if provided.

## Example

Given these commits on `feat/retry-auth` vs `main`:

```
abc1234 add retry logic to auth middleware
def5678 update error messages for token expiry
```

**Title:**

```
feat(auth): add retry logic and improve token error messages
```

**Body:**

```markdown
## Summary

- Added retry with exponential backoff for transient auth failures to reduce 503 errors
- Clarified error messages on token expiry so users see actionable next steps

## Test plan

- [ ] Trigger transient auth failure and verify retry resolves it
- [ ] Force token expiry and confirm updated error message displays
```

**Output on success:**

```
feat(auth): add retry logic and improve token error messages
https://github.com/owner/repo/pull/42
```

## Error handling

If `gh pr create` fails:

- **Auth error** (`not logged in`) → suggest `gh auth login`
- **No remote / repo not found** → suggest `git remote add origin <url>`
- **Permission denied** → inform user, do not retry
- **Network error** → retry once, then report failure
