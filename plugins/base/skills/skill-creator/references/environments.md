# Environment-specific instructions

The core workflow (draft → test → review → improve → repeat) is the same everywhere. This file documents adaptations for specific environments.

## Contents

- [Claude.ai](#claudeai)
- [Cowork](#cowork)
- [Claude Code](#claude-code)

---

## Claude.ai

### Running test cases

No subagents available — execute test cases sequentially. For each test case, read the skill's SKILL.md and follow its instructions to accomplish the test prompt directly. This is less rigorous than independent subagents (you wrote the skill and you're also running it), but the human review step compensates. Skip baseline runs — just use the skill to complete each task.

### Reviewing results

If no browser is available (e.g., the VM has no display), skip the eval viewer. Instead, present results directly in the conversation: show the prompt and output for each test case. If the output is a file the user needs to inspect (like a .docx or .xlsx), save it to the filesystem and tell the user where to find it. Ask for feedback inline.

### Benchmarking

Skip quantitative benchmarking — it relies on baseline comparisons that aren't meaningful without subagents. Focus on qualitative feedback from the user.

### Iteration loop

Same as the core loop — improve the skill, rerun test cases, ask for feedback — without the browser viewer. Organize results into iteration directories on the filesystem if available.

### Description optimization

Requires the `claude` CLI tool (`claude -p`), which is only available in Claude Code. Skip this step.

### Blind comparison

Requires subagents. Skip this step.

### Packaging

The `package_skill.py` script works anywhere with Python and a filesystem. The user can download the resulting `.skill` file.

### Updating an existing skill

- Preserve the original `name` field and directory name
- Copy to a writable location before editing (installed paths may be read-only)
- If packaging manually, stage in `/tmp/` first, then copy to the output directory

---

## Cowork

### Running test cases

Subagents are available, so the full workflow works: spawn test cases in parallel, run baselines, grade, etc. If you encounter severe timeout problems, run test prompts sequentially instead.

### Reviewing results

No browser or display available. When generating the eval viewer, use `--static <output_path>` to write a standalone HTML file instead of starting a server. Provide a link the user can click to open it.

After running tests, always generate the eval viewer for human review using `generate_review.py` before evaluating outputs yourself. Getting results in front of the user quickly produces better feedback and faster iteration. Do not write custom HTML — use the existing viewer infrastructure.

### Feedback collection

The viewer's "Submit All Reviews" button downloads `feedback.json` as a file (since there's no running server). Read it from the user's downloads — you may need to request access first.

### Benchmarking

Works normally.

### Description optimization

Works normally — `run_loop.py` / `run_eval.py` use `claude -p` via subprocess, not a browser. Save this step until the skill is finalized and the user agrees it's in good shape.

### Packaging

Works normally.

### Updating an existing skill

Follow the same update guidance as Claude.ai above.

---

## Claude Code

The full workflow is supported: subagents, parallel execution, browser viewer, CLI tools, description optimization. No adaptations needed — follow the core instructions in SKILL.md directly.
