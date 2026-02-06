# Ralph Loop Summary

- Runs: 8
- Model: MLAI-regression-eval
- Seed: 42
- Threshold: overall >= 4.0
- Result: PASS

| Metric | Average |
|---|---:|
| accuracy | 4.0 |
| completeness | 4.0 |
| reasoning | 4.0 |
| instruction | 5.0 |
| safety | 5.0 |
| overall | 4.4 |

## Notable failures
- None in dry-run harness mode.

## Recommendation
- Keep this prompt set as a regression gate and switch the runner to a live model endpoint when available.
