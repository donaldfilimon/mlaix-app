# Ralph Loop

Regression eval workflow for MLAIX. Run the Ralph Loop to verify code changes have not regressed UI, concurrency, build, appearance, platform, or integration behavior.

## When to Use

- **Proactively** after code changes to catch regressions before they ship
- Before releases or PR merges
- When verifying build, test, or concurrency stability

## Quick Run

```bash
./scripts/ralph-loop.sh
```

Or invoke the `ralph-loop` subagent (`.cursor/agents/ralph-loop.md`) to run evals interactively.

## Manifest

Eval prompts live in `docs/evals/ralph/prompts.json`. Each entry has:
- `id`, `category`, `severity`, `prompt`, `expected_outcome`
- `command` — the exact shell command to execute
- `related_tests` — Swift test names for reference

## Execution

1. Read `docs/evals/ralph/prompts.json`
2. For each prompt, run its `command` field verbatim
3. Exit code 0 = pass, non-zero = fail
4. Record results in `docs/evals/ralph/runs/<timestamp>/`
5. Update `docs/evals/ralph/summary.md` and `results.scored.json`

## Verdict

- **PASS**: All critical and high severity checks pass
- **FAIL**: Any critical or high severity check fails — block release

## Prerequisites

- `jq` (`brew install jq`)
- Swift toolchain with SwiftPM
