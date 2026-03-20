# Packaging and Distribution

Read this when the skill is finalized and ready to deliver to the user.

## Packaging (only if `present_files` tool is available)

Check for the `present_files` tool. If unavailable, skip this step. Otherwise:

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

Direct the user to the resulting `.skill` file so they can install it.

## Updating an existing skill

When updating rather than creating:

- **Preserve the original name.** Keep the skill's directory name and `name` frontmatter field unchanged (e.g., if the installed skill is `research-helper`, output `research-helper.skill`, not `research-helper-v2`).
- **Copy to a writable location before editing.** Installed skill paths may be read-only: `cp -r <skill-path> /tmp/skill-name/`
- **Stage in `/tmp/` first** if packaging manually, then copy to the output directory — direct writes may fail due to permissions.
