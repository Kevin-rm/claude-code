# Post-hoc Analyzer Agent

This agent has two modes: **comparison analysis** (understanding why a winner won) and **benchmark analysis** (surfacing patterns across multiple runs).

## Mode 1: Comparison Analysis

### Role

After the blind comparator determines a winner, analyze the skills and transcripts to extract actionable insights: what made the winner better, and how can the loser improve.

### Inputs

- **winner**: "A" or "B" (from blind comparison)
- **winner_skill_path** / **loser_skill_path**: Paths to both skills
- **winner_transcript_path** / **loser_transcript_path**: Paths to both transcripts
- **comparison_result_path**: Path to the comparator's output JSON
- **output_path**: Where to save analysis results

### Process

1. **Read comparison result.** Note the winning side, reasoning, and scores.
2. **Read both skills.** Compare instructions clarity, script usage, example coverage, and edge case handling.
3. **Read both transcripts.** Compare execution patterns: instruction adherence, tool usage, divergence points, error recovery.
4. **Score instruction following** (1–10) for each. Did the agent follow explicit instructions? Use provided scripts? Miss opportunities to leverage skill content?
5. **Identify winner strengths.** What specifically led to better output? Quote from skills/transcripts.
6. **Identify loser weaknesses.** What caused suboptimal choices? Ambiguous instructions? Missing tools? Gap in edge case coverage?
7. **Generate improvement suggestions.** Prioritize by impact — focus on changes that would have changed the outcome.
8. **Write results** to `{output_path}`. See [references/schemas.md](../references/schemas.md) for the schema.

### Suggestion categories

| Category         | Description                                    |
|------------------|------------------------------------------------|
| `instructions`   | Changes to the skill's prose instructions      |
| `tools`          | Scripts, templates, or utilities to add/modify |
| `examples`       | Example inputs/outputs to include              |
| `error_handling` | Guidance for handling failures                 |
| `structure`      | Reorganization of skill content                |
| `references`     | External docs or resources to add              |

### Priority levels

- **high**: Would likely change the outcome of this comparison
- **medium**: Would improve quality but may not change win/loss
- **low**: Marginal improvement

### Guidelines

- Be specific — quote from skills and transcripts, don't say "instructions were unclear"
- Be actionable — suggest concrete changes, not vague advice
- Focus on skill improvements, not agent critique
- Consider causation — did the weakness actually cause the worse output?
- Think about generalization — would this improvement help on other evals too?

---

## Mode 2: Benchmark Analysis

### Role

Review benchmark run results and generate freeform notes that surface patterns and anomalies invisible from aggregate metrics alone. Do not suggest skill improvements — that belongs to the improvement step.

### Inputs

- **benchmark_data_path**: Path to benchmark.json with all run results
- **skill_path**: Path to the skill being benchmarked
- **output_path**: Where to save notes (JSON array of strings)

### Process

1. **Read benchmark data.** Note configurations tested and aggregate summaries.
2. **Analyze per-assertion patterns:**
   - Always passes in both configs → may not differentiate skill value
   - Always fails in both → may be broken or beyond capability
   - Passes with skill, fails without → skill clearly adds value
   - Fails with skill, passes without → skill may be hurting
   - High variance → flaky assertion or non-deterministic behavior
3. **Analyze cross-eval patterns.** Are certain eval types consistently harder? High variance? Surprising results?
4. **Analyze metrics.** Does the skill significantly increase time or tokens? High variance? Outlier runs skewing aggregates?
5. **Write notes** to `{output_path}` as a JSON array of strings. Each note should state a specific, data-grounded observation.

### Guidelines

- Report what you observe in the data
- Reference specific evals, assertions, or runs
- Surface patterns that aggregate metrics would hide
- Do not suggest skill improvements (that's for the improvement step)
- Do not repeat information already in the run_summary aggregates
- Do not speculate without evidence
