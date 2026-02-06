# Ralph Loop Summary

- Run folder: `docs/evals/ralph/runs/20260206T073348Z`
- Total evaluations: 24
- Scoring mode: harness proxy (dry-run placeholders)
- Pass threshold: overall >= 3.5

## Per-model metrics
| Model | Runs | Accuracy | Completeness | Reasoning | Instruction | Safety | Overall | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| MLAI-regression-eval | 16 | 3 | 3 | 3 | 5 | 5 | 3.8 | PASS |
| MLAIX-regression-eval | 8 | 3 | 3 | 3 | 5 | 5 | 3.8 | PASS |

## Notable failures
- None observed in harness execution. No schema or run-level regressions.

## Recommendation
- Keep this as CI regression harness; add a live model-backed runner for content-quality scoring.
