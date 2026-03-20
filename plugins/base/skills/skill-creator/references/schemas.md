# JSON Schemas

Data structures used across skill-creator scripts and viewers.

## Contents

- [evals.json](#evalsjson) — Test case definitions
- [eval_metadata.json](#eval_metadatajson) — Per-test-case metadata in workspace
- [history.json](#historyjson) — Version progression tracking
- [grading.json](#gradingjson) — Grader agent output
- [metrics.json](#metricsjson) — Executor agent output
- [timing.json](#timingjson) — Wall clock timing per run
- [benchmark.json](#benchmarkjson) — Benchmark aggregation output
- [comparison.json](#comparisonjson) — Blind comparator output
- [analysis.json](#analysisjson) — Post-hoc analyzer output
- [feedback.json](#feedbackjson) — User review feedback

---

## evals.json

Test case definitions. Located at `evals/evals.json` within the skill directory.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's example prompt",
      "expected_output": "Description of expected result",
      "files": ["evals/files/sample1.pdf"],
      "assertions": [
        "The output includes X",
        "The skill used script Y"
      ]
    }
  ]
}
```

- `skill_name`: Matches the skill's frontmatter name
- `evals[].id`: Unique integer identifier
- `evals[].prompt`: The task to execute
- `evals[].expected_output`: Human-readable success description
- `evals[].files`: Optional input file paths (relative to skill root)
- `evals[].assertions`: Verifiable statements (added after initial draft)

---

## eval_metadata.json

Per-test-case metadata in workspace directories. Created for each eval run.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": [
    "Output contains a valid PDF",
    "All form fields are populated"
  ]
}
```

- `eval_name`: Descriptive name used as directory name and viewer section header
- `assertions`: Can be empty initially, populated during Step 2 of the eval workflow

---

## history.json

Version progression in improve mode. Located at workspace root.

```json
{
  "started_at": "2026-01-15T10:30:00Z",
  "skill_name": "pdf",
  "current_best": "v2",
  "iterations": [
    {
      "version": "v0",
      "parent": null,
      "expectation_pass_rate": 0.65,
      "grading_result": "baseline",
      "is_current_best": false
    }
  ]
}
```

- `current_best`: Version identifier of the best performer
- `iterations[].grading_result`: One of "baseline", "won", "lost", "tie"

---

## grading.json

Grader agent output. Located at `<run-dir>/grading.json`.

**Critical**: The viewer depends on the exact field names `text`, `passed`, and `evidence` in the expectations array. Do not use alternatives like `name`/`met`/`details`.

```json
{
  "expectations": [
    {
      "text": "The output includes the name 'John Smith'",
      "passed": true,
      "evidence": "Found in transcript Step 3: 'Extracted names: John Smith, Sarah Johnson'"
    }
  ],
  "summary": {
    "passed": 2,
    "failed": 1,
    "total": 3,
    "pass_rate": 0.67
  },
  "execution_metrics": {},
  "timing": {},
  "claims": [
    {
      "claim": "The form has 12 fillable fields",
      "type": "factual",
      "verified": true,
      "evidence": "Counted 12 fields in field_info.json"
    }
  ],
  "user_notes_summary": {
    "uncertainties": [],
    "needs_review": [],
    "workarounds": []
  },
  "eval_feedback": {
    "suggestions": [],
    "overall": "No suggestions, evals look solid"
  }
}
```

- `execution_metrics`: Copied from executor's metrics.json (if available)
- `timing`: From timing.json (if available)
- `claims[].type`: One of "factual", "process", "quality"
- `eval_feedback`: Only present when the grader identifies issues worth raising

---

## metrics.json

Executor agent output. Located at `<run-dir>/outputs/metrics.json`.

```json
{
  "tool_calls": {"Read": 5, "Write": 2, "Bash": 8, "Edit": 1, "Glob": 2, "Grep": 0},
  "total_tool_calls": 18,
  "total_steps": 6,
  "files_created": ["filled_form.pdf", "field_values.json"],
  "errors_encountered": 0,
  "output_chars": 12450,
  "transcript_chars": 3200
}
```

---

## timing.json

Wall clock timing. Located at `<run-dir>/timing.json`.

**How to capture**: When a subagent task completes, the notification includes `total_tokens` and `duration_ms`. Save immediately — this data is not persisted elsewhere.

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3,
  "executor_start": "2026-01-15T10:30:00Z",
  "executor_end": "2026-01-15T10:32:45Z",
  "executor_duration_seconds": 165.0,
  "grader_start": "2026-01-15T10:32:46Z",
  "grader_end": "2026-01-15T10:33:12Z",
  "grader_duration_seconds": 26.0
}
```

---

## benchmark.json

Benchmark aggregation output. Located at `benchmarks/<timestamp>/benchmark.json`.

**Important**: The viewer reads these field names exactly. Using `config` instead of `configuration`, or putting `pass_rate` at the top level instead of nested under `result`, causes the viewer to show empty values.

```json
{
  "metadata": {
    "skill_name": "pdf",
    "skill_path": "/path/to/pdf",
    "executor_model": "claude-sonnet-4-20250514",
    "timestamp": "2026-01-15T10:30:00Z",
    "evals_run": [1, 2, 3],
    "runs_per_configuration": 3
  },
  "runs": [
    {
      "eval_id": 1,
      "eval_name": "Ocean",
      "configuration": "with_skill",
      "run_number": 1,
      "result": {
        "pass_rate": 0.85,
        "passed": 6,
        "failed": 1,
        "total": 7,
        "time_seconds": 42.5,
        "tokens": 3800,
        "tool_calls": 18,
        "errors": 0
      },
      "expectations": [
        {"text": "...", "passed": true, "evidence": "..."}
      ],
      "notes": ["Used 2023 data, may be stale"]
    }
  ],
  "run_summary": {
    "with_skill": {
      "pass_rate": {"mean": 0.85, "stddev": 0.05},
      "time_seconds": {"mean": 45.0, "stddev": 12.0},
      "tokens": {"mean": 3800, "stddev": 400}
    },
    "without_skill": {
      "pass_rate": {"mean": 0.35, "stddev": 0.08},
      "time_seconds": {"mean": 32.0, "stddev": 8.0},
      "tokens": {"mean": 2100, "stddev": 300}
    },
    "delta": {
      "pass_rate": "+0.50",
      "time_seconds": "+13.0",
      "tokens": "+1700"
    }
  },
  "notes": []
}
```

- `runs[].configuration`: Must be `"with_skill"` or `"without_skill"` (viewer uses exact strings for grouping)
- `runs[].eval_name`: Used as section header in the viewer
- `run_summary`: Statistical aggregates with `mean` and `stddev` fields
- `notes`: Freeform observations from the analyzer

---

## comparison.json

Blind comparator output. Located at `<grading-dir>/comparison-N.json`.

```json
{
  "winner": "A",
  "reasoning": "Output A provides a complete solution with all required fields...",
  "rubric": {
    "A": {
      "content": {"correctness": 5, "completeness": 5, "accuracy": 4},
      "structure": {"organization": 4, "formatting": 5, "usability": 4},
      "content_score": 4.7,
      "structure_score": 4.3,
      "overall_score": 9.0
    },
    "B": {}
  },
  "output_quality": {
    "A": {"score": 9, "strengths": [], "weaknesses": []},
    "B": {"score": 5, "strengths": [], "weaknesses": []}
  },
  "expectation_results": {}
}
```

- `winner`: "A", "B", or "TIE"
- `expectation_results`: Omit entirely if no expectations were provided

---

## analysis.json

Post-hoc analyzer output. Located at `<grading-dir>/analysis.json`.

```json
{
  "comparison_summary": {
    "winner": "A",
    "winner_skill": "path/to/winner/skill",
    "loser_skill": "path/to/loser/skill",
    "comparator_reasoning": "Brief summary"
  },
  "winner_strengths": [],
  "loser_weaknesses": [],
  "instruction_following": {
    "winner": {"score": 9, "issues": []},
    "loser": {"score": 6, "issues": []}
  },
  "improvement_suggestions": [
    {
      "priority": "high",
      "category": "instructions",
      "suggestion": "Replace vague instruction with explicit steps",
      "expected_impact": "Would eliminate ambiguity"
    }
  ],
  "transcript_insights": {
    "winner_execution_pattern": "",
    "loser_execution_pattern": ""
  }
}
```

- `improvement_suggestions[].priority`: "high", "medium", or "low"
- `improvement_suggestions[].category`: One of "instructions", "tools", "examples", "error_handling", "structure", "references"

---

## feedback.json

User review feedback from the eval viewer. Located in the workspace iteration directory.

```json
{
  "reviews": [
    {
      "run_id": "eval-0-with_skill",
      "feedback": "the chart is missing axis labels",
      "timestamp": "2026-01-15T11:00:00Z"
    }
  ],
  "status": "complete"
}
```

- Empty `feedback` means the user thought the output was fine
- Focus improvements on test cases with specific complaints
