# Ralph Loop Summary

- Run folder: `docs/evals/ralph/runs/20260206T094738Z`
- Total evaluations: 24
- Scoring mode: harness proxy (dry-run placeholders)
- Pass threshold: overall >= 4.0

## Per-model metrics
| Model | Runs | Accuracy | Completeness | Reasoning | Instruction | Safety | Overall | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| MLAI-regression-eval | 16 | 3 | 3 | 3 | 5 | 5 | 3.8 | FAIL |
| MLAIX-regression-eval | 8 | 3 | 3 | 3 | 5 | 5 | 3.8 | FAIL |

## Notable failures
- MLAI-regression-eval fell below strict threshold (overall 3.8 < 4.0).
- MLAIX-regression-eval fell below strict threshold (overall 3.8 < 4.0).

## Recommendation
- Keep this run as strict gate signal; either raise proxy score criteria or switch to live model-backed scoring before enforcing 4.0 as blocking.
