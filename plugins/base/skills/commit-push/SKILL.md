---
name: commit-push
description: Commits changes using Conventional Commits then pushes to the upstream tracking branch. Use when the user says "commit and push", "commit-push", "push my changes", or "commit then push".
disable-model-invocation: true
allowed-tools: Bash(git push:*), Bash(git pull:*), Bash(git rev-parse:*), Bash(git branch:*)
---

# Commit and Push

Commit changes then push to the upstream tracking branch.

## Execution flow

1. Run `/commit $ARGUMENTS` to stage, generate a message, and commit.
2. If the commit succeeds, detect the upstream tracking branch:
   ```bash
   git rev-parse --abbrev-ref --symbolic-full-name @{upstream}
   ```
   - **Upstream exists**: push to it with `git push`.
   - **No upstream set**: suggest `git push -u origin <branch>` and ask before executing — the user may want a different remote.
3. If the push is rejected (remote has new commits), suggest `git pull --rebase` and ask before executing.
