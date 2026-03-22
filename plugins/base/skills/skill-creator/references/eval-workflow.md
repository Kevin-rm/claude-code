# Eval Workflow

Detailed procedure for running, grading, and reviewing test cases. Read this when entering the evaluation phase.

## Setup

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Organize by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a directory (`eval-0/`, `eval-1/`, etc.). Create directories as you go.

## Step 1: Spawn all runs (with-skill AND baseline) in the same turn

For each test case, spawn two subagents simultaneously — one with the skill, one without. Launching everything at once ensures results arrive around the same time, keeping the feedback loop tight.

**With-skill run:**
```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about — e.g., "the .docx file", "the final CSV">
```

**Baseline run** (same prompt, but the baseline depends on context):
- **Creating a new skill**: no skill at all — same prompt, no skill path, save to `without_skill/outputs/`
- **Improving an existing skill**: the previous version — snapshot the skill first (`cp -r <skill-path> <workspace>/skill-snapshot/`), then point the baseline subagent at the snapshot. Save to `old_skill/outputs/`

Write an `eval_metadata.json` for each test case. Give each eval a descriptive name based on what it tests. See [schemas.md](schemas.md) for the exact structure.

## Step 2: Draft assertions while runs execute

Use waiting time productively. Draft quantitative assertions for each test case and explain them to the user. If assertions already exist in `evals/evals.json`, review and explain them.

Good assertions are objectively verifiable and have descriptive names that read clearly in the benchmark viewer. Subjective skills (writing style, design quality) are better evaluated qualitatively — do not force assertions onto things that need human judgment.

Update `eval_metadata.json` files and `evals/evals.json` with the assertions.

## Step 3: Capture timing data as runs complete

When each subagent task completes, the notification includes `total_tokens` and `duration_ms`. Save this immediately to `timing.json` in the run directory — this data is only available through the task notification and cannot be recovered later.

## Step 4: Grade, aggregate, and launch the viewer

Once all runs complete:

1. **Grade each run** — spawn a grader subagent (or grade inline). Save results to `grading.json` in each run directory. The expectations array must use fields `text`, `passed`, and `evidence` — the viewer depends on these exact names. For programmatically checkable assertions, write and run a script rather than evaluating manually.

2. **Aggregate into benchmark** — run from the skill-creator directory:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <n>
   ```
   This produces `benchmark.json` and `benchmark.md`. See [schemas.md](schemas.md) for the schema the viewer expects. Place each with_skill version before its baseline counterpart.

3. **Launch the eval viewer** — getting outputs in front of the user quickly produces better feedback than analyzing results yourself, so generate the viewer first:
   ```bash
   python eval-viewer/generate_review.py \
     --workspace <workspace>/iteration-N \
     --skill-name <n> \
     --port 8099
   ```
   For subsequent iterations, add `--previous-workspace` pointing at the prior iteration to enable side-by-side comparison.

### What the user sees in the viewer

The **Outputs** tab shows one test case at a time with the prompt, rendered output files, previous iteration output (if applicable), formal grades, and a feedback textbox. The **Benchmark** tab shows pass rates, timing, and token usage per configuration. Navigation is via prev/next buttons or arrow keys. "Submit All Reviews" saves feedback to `feedback.json`.

## Step 5: Read the feedback

When the user finishes reviewing, read `feedback.json`. Empty feedback means the test case looked fine. Focus improvements on test cases where the user had specific complaints.

Kill the viewer server when done:
```bash
kill $VIEWER_PID 2>/dev/null
```
