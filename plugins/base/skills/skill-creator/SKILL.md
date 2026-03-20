---
name: skill-creator
description: Creates, evaluates, and improves Claude skills through iterative testing and benchmarking. Use when a user wants to create a new skill, refine an existing one, test skill behavior, benchmark performance, improve triggering accuracy, or turn a workflow into a reusable skill. Triggers on phrases like "make this into a skill", "improve my skill", "test this skill", "why isn't my skill triggering", or "package this skill".
---

# Skill Creator

Create, evaluate, and iteratively improve skills through a structured draft → test → review → improve cycle.

## Contents

- [Mode detection](#mode-detection)
- [Core workflow](#core-workflow)
- [Communicating with the user](#communicating-with-the-user)
- [Creating a skill](#creating-a-skill)
- [Skill writing guide](#skill-writing-guide)
- [Improving the skill](#improving-the-skill)
- [Reference files](#reference-files)

## Mode detection

Determine the user's intent and follow only the relevant path:

- **Create**: User wants a new skill → Capture intent → Write → Test → Iterate
- **Improve**: User has an existing skill to enhance → Read it → Test current version → Iterate
- **Evaluate**: User wants to test or benchmark a skill → See [references/eval-workflow.md](references/eval-workflow.md)
- **Optimize trigger**: User's skill doesn't trigger correctly → See [references/description-optimization.md](references/description-optimization.md)
- **Package**: User wants to distribute a finished skill → See [references/packaging.md](references/packaging.md)

Most sessions involve Create or Improve, which both follow the core workflow below.

## Core workflow

The process follows an iterative loop:

1. Understand what the user wants the skill to do and how
2. Draft the skill
3. Create 2–3 test prompts and run Claude-with-access-to-the-skill on them
4. Help the user evaluate results both qualitatively and quantitatively
   - While runs execute in the background, draft quantitative evals if none exist, then explain them to the user
   - Use `eval-viewer/generate_review.py` to present results for human review, and show quantitative metrics
5. Rewrite the skill based on feedback and benchmark findings
6. Repeat until satisfied
7. Expand the test set and try again at larger scale

Determine where the user is in this process and help them progress. If they say "I want to make a skill for X", help narrow intent, draft, write test cases, evaluate, and iterate. If they already have a draft, jump straight to eval/iterate.

Remain flexible — if the user says "I don't need evaluations, just vibe with me", adapt accordingly.

After the skill is finalized, offer to run the description optimizer to improve triggering accuracy.

## Communicating with the user

Skill creation attracts users across a wide range of technical familiarity. Pay attention to context cues and adjust vocabulary accordingly. Terms like "evaluation" and "benchmark" are generally safe. For terms like "JSON" or "assertion", look for cues that the user is comfortable with them, or briefly explain when in doubt.

## Creating a skill

### Capture intent

Start by understanding what the user wants. The current conversation may already contain a workflow to capture (e.g., "turn this into a skill"). If so, extract answers from the conversation history first — tools used, sequence of steps, corrections made, input/output formats observed. Confirm with the user before proceeding.

Key questions to resolve:

1. What should this skill enable Claude to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What is the expected output format?
4. Should test cases verify the skill works? Skills with objectively verifiable outputs (file transforms, data extraction, code generation) benefit from tests. Skills with subjective outputs (writing style, art) often don't. Suggest the appropriate default, but let the user decide.

### Interview and research

Proactively ask about edge cases, input/output formats, example files, success criteria, and dependencies. Wait to write test prompts until this is solid.

Check available MCPs — if useful for research (searching docs, finding similar skills, looking up best practices), research in parallel via subagents if available, otherwise inline.

### Write the SKILL.md

Based on the interview, fill in:

- **name**: Skill identifier (lowercase, hyphens, max 64 chars)
- **description**: The primary triggering mechanism. Include both what the skill does AND specific contexts for when to use it. All "when to use" information belongs here, not in the body. Claude tends to undertrigger skills, so make descriptions assertive about when the skill applies. For example, instead of "How to build a dashboard to display data", write "How to build a dashboard to display data. Use whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of data, even if they don't explicitly ask for a 'dashboard.'"
- **the skill body**: Instructions, workflows, references

## Skill writing guide

### Anatomy of a skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

### Progressive disclosure

Skills use a three-level loading system:

1. **Metadata** (name + description) — always in context (~100 words)
2. **SKILL.md body** — loaded when the skill triggers (target under 500 lines)
3. **Bundled resources** — loaded as needed (scripts can execute without loading into context)

Keep SKILL.md under 500 lines. When approaching this limit, split into reference files with clear pointers about when to read them. For large reference files (300+ lines), include a table of contents at the top.

### Principle of no surprises

Skills must not contain malware, exploit code, or security-compromising content. A skill's contents should not surprise the user in their intent. Do not create misleading skills or skills designed for unauthorized access or data exfiltration. Roleplay-style skills are acceptable.

### Writing patterns

Use the imperative form in instructions.

**Defining output formats:**
```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Examples pattern** — include input/output pairs to guide style and expectations:
```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

### Writing style

Explain to the model *why* things matter rather than relying on heavy-handed directives. Use theory of mind and aim for general instructions that aren't over-fitted to specific examples. Draft first, then review with fresh eyes and improve.

## Test cases

After drafting the skill, create 2–3 realistic test prompts — the kind of thing a real user would actually say. Share them with the user for confirmation, then run them.

Save test cases to `evals/evals.json`. Start with just the prompts — assertions come later. See [references/schemas.md](references/schemas.md) for the full schema including the `assertions` field.

## Running and evaluating test cases

Treat these steps as a continuous workflow — pausing mid-sequence risks losing timing data from subagent notifications, which aren't persisted elsewhere.

For the detailed step-by-step procedure (spawning runs, drafting assertions, grading, launching the viewer), see [references/eval-workflow.md](references/eval-workflow.md).

## Improving the skill

This is the heart of the loop. Test cases have run, the user has reviewed results, and now the skill needs to get better.

### How to think about improvements

1. **Generalize from the feedback.** The goal is a skill that works across many different prompts, not just the test examples. Rather than adding narrow, overfitting fixes or oppressively constrictive directives, try different metaphors or recommend different working patterns when something is stubborn. It's cheap to experiment.

2. **Keep the prompt lean.** Remove anything that isn't pulling its weight. Read the transcripts, not just final outputs — if the skill makes the model waste time on unproductive steps, remove those instructions and observe what happens.

3. **Explain the why.** Convey the reasoning behind every instruction. Today's LLMs have strong theory of mind and, given good context, go beyond rote instructions to deliver excellent results. If you find yourself writing ALWAYS or NEVER in all caps, that's a signal to reframe: explain the reasoning so the model understands the importance. That approach is more effective and more durable than rigid directives.

4. **Look for repeated work across test cases.** Read transcripts and notice when all subagents independently wrote similar helper scripts or took the same multistep approach. If every test case resulted in a `create_docx.py` or `build_chart.py`, bundle that script in `scripts/` and tell the skill to use it.

This work has high impact — invest thinking time and iterate on your draft revision before finalizing.

### The iteration loop

After improving the skill:

1. Apply improvements
2. Rerun all test cases into `iteration-<N+1>/`, including baselines. For new skills, the baseline is always no-skill. For existing skills, use your judgment — the original version or the previous iteration
3. Launch the reviewer with `--previous-workspace` pointing at the previous iteration
4. Wait for user review
5. Read feedback, improve again, repeat

Stop when the user is satisfied, feedback is all empty, or improvements plateau.

## Advanced: Blind comparison

For rigorous comparison between two skill versions, use the blind comparison system. Read [agents/comparator.md](agents/comparator.md) and [agents/analyzer.md](agents/analyzer.md) for details. An independent agent judges two outputs without knowing which skill produced which, then analyzes why the winner won.

This is optional, requires subagents, and most users won't need it. The human review loop is usually sufficient.

## Description optimization

After a skill is finalized, optimizing its description improves triggering accuracy. For the full procedure, see [references/description-optimization.md](references/description-optimization.md).

## Environment-specific instructions

The core workflow applies everywhere. For Claude.ai and Cowork-specific adaptations, see [references/environments.md](references/environments.md).

## Packaging

When the skill is ready to distribute, see [references/packaging.md](references/packaging.md).

## Reference files

**Agents** — read when spawning the relevant subagent:

- [agents/grader.md](agents/grader.md) — Evaluate assertions against outputs
- [agents/comparator.md](agents/comparator.md) — Blind A/B comparison between two outputs
- [agents/analyzer.md](agents/analyzer.md) — Analyze why one version beat another

**References** — read when entering the relevant phase:

- [references/schemas.md](references/schemas.md) — JSON structures for evals.json, grading.json, benchmark.json, etc.
- [references/eval-workflow.md](references/eval-workflow.md) — Step-by-step eval procedure (spawning, grading, viewer)
- [references/description-optimization.md](references/description-optimization.md) — Trigger eval queries and optimization loop
- [references/packaging.md](references/packaging.md) — Packaging and distributing finished skills
- [references/environments.md](references/environments.md) — Claude.ai and Cowork-specific adaptations

---

**Core loop reminder:**

```
Task Progress:
- [ ] Understand what the skill is about
- [ ] Draft or edit the skill
- [ ] Run Claude-with-access-to-the-skill on test prompts
- [ ] Evaluate outputs with the user (see references/eval-workflow.md)
- [ ] Iterate until user is satisfied
- [ ] Package the final skill (see references/packaging.md)
```

Add these steps to your TodoList if available to ensure nothing is missed.
