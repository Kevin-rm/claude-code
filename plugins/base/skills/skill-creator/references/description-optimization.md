# Description Optimization

The description field is the primary mechanism controlling whether Claude invokes a skill. Read this when the user wants to improve triggering accuracy after the skill itself is finalized.

## Step 1: Generate trigger eval queries

Create 20 eval queries — a mix of should-trigger (8–10) and should-not-trigger (8–10). Save as JSON.

Queries must be realistic — what a user would actually type, with file paths, personal context, column names, company names, casual speech, abbreviations, and varying lengths. Focus on edge cases rather than clear-cut examples.

For **should-trigger** queries, aim for diverse phrasings of the same intent: formal and casual, implicit and explicit, common and uncommon use cases.

For **should-not-trigger** queries, prioritize near-misses — queries that share keywords but need something different. Avoid obviously irrelevant queries like "write a fibonacci function" as a negative for a PDF skill.

## Step 2: Review with user

Present the eval set using the HTML template:

1. Read `assets/eval_review.html`
2. Replace placeholders: `__EVAL_DATA_PLACEHOLDER__` → JSON array, `__SKILL_NAME_PLACEHOLDER__` → name, `__SKILL_DESCRIPTION_PLACEHOLDER__` → current description
3. Write to a temp file and open it
4. The user edits, then clicks "Export Eval Set" — check `~/Downloads/` for the result

## Step 3: Run the optimization loop

Inform the user this will take time, then run in the background:

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id-powering-this-session> \
  --max-iterations 5 \
  --verbose
```

Use the model ID from the current session so the triggering test matches the user's actual experience.

The script splits the eval set 60/40 train/held-out test, evaluates the current description (3 runs per query for reliability), proposes improvements based on failures, and iterates up to 5 times. It selects by test score to avoid overfitting and produces an HTML report with `best_description` in the JSON output.

## How skill triggering works

Skills appear in Claude's `available_skills` list by name and description. Claude consults a skill only when the task is complex enough to benefit from it — simple one-step queries may not trigger even with a matching description. Design eval queries that are substantive enough that Claude would genuinely benefit from consulting the skill.

## Step 4: Apply the result

Take `best_description` from the JSON output and update the skill's SKILL.md frontmatter. Show before/after and report scores.
