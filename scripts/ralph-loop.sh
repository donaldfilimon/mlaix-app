#!/usr/bin/env bash
# Ralph Loop — regression eval harness for MLAIX.
#
# Reads prompts from docs/evals/ralph/prompts.json, runs the command specified
# in each prompt entry, records results in a timestamped run directory, and
# updates the root summary.
#
# Usage:
#   ./scripts/ralph-loop.sh              # Run all eval prompts
#   ./scripts/ralph-loop.sh --dry-run    # Validate schema without executing
#
# Prerequisites:
#   - jq (brew install jq)
#   - Swift toolchain with SwiftPM

set -euo pipefail
cd "$(dirname "$0")/.."

PROMPTS_FILE="docs/evals/ralph/prompts.json"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
RUN_DIR="docs/evals/ralph/runs/${TIMESTAMP}"
DRY_RUN=false
TMPDIR_RUN=$(mktemp -d)

trap 'rm -rf "$TMPDIR_RUN"' EXIT

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Verify jq is available
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required. Install with: brew install jq" >&2
    exit 1
fi

# Verify prompts file exists
if [[ ! -f "$PROMPTS_FILE" ]]; then
    echo "Error: $PROMPTS_FILE not found" >&2
    exit 1
fi

# Validate every prompt has a command field
MISSING_CMD=$(jq '[.[] | select(.command == null or .command == "")] | length' "$PROMPTS_FILE")
if [[ "$MISSING_CMD" -gt 0 ]]; then
    echo "Error: $MISSING_CMD prompt(s) missing a 'command' field in $PROMPTS_FILE" >&2
    exit 1
fi

mkdir -p "$RUN_DIR"
cp "$PROMPTS_FILE" "$RUN_DIR/prompts.json"

TOTAL=$(jq 'length' "$PROMPTS_FILE")
PASS_COUNT=0
FAIL_COUNT=0
RESULTS="[]"

echo "=== Ralph Loop Eval Run ==="
echo "Timestamp: $TIMESTAMP"
echo "Prompts:   $TOTAL"
echo "Dry run:   $DRY_RUN"
echo ""

# Build once upfront (unless dry-run) to avoid redundant rebuilds
if [[ "$DRY_RUN" == "false" ]]; then
    echo "Pre-building MLAIX..."
    if swift build 2>&1; then
        echo "Pre-build succeeded."
    else
        echo "Warning: Pre-build had issues; individual checks may fail."
    fi
    echo ""
fi

# run_check executes a command and writes exit_code, duration_ms, and output
# snippet to TMPDIR_RUN. Used when deduplicating shared commands.
run_check() {
    local cmd="$1"
    local out_file="$TMPDIR_RUN/output.txt"
    local start_ms end_ms

    start_ms=$(python3 -c 'import time; print(int(time.time()*1000))')

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] $cmd" > "$out_file"
        echo 0 > "$TMPDIR_RUN/exit_code"
    else
        set +e
        eval "$cmd" > "$out_file" 2>&1
        echo $? > "$TMPDIR_RUN/exit_code"
        set -e
    fi

    end_ms=$(python3 -c 'import time; print(int(time.time()*1000))')
    echo $((end_ms - start_ms)) > "$TMPDIR_RUN/duration_ms"
    head -c 500 "$out_file" > "$TMPDIR_RUN/snippet.txt"
}

# Cache for command results: keyed by command hash, stores exit_code,duration_ms,snippet
CACHE_DIR="$TMPDIR_RUN/cache"
mkdir -p "$CACHE_DIR"

# Get unique commands in order of first occurrence; run each once and cache.
UNIQUE_CMDS=$(jq -r '.[].command' "$PROMPTS_FILE" | awk '!seen[$0]++')
UNIQUE_COUNT=$(echo "$UNIQUE_CMDS" | grep -c . || true)
CHECK_NUM=0

while IFS= read -r CMD; do
    [[ -z "$CMD" ]] && continue
    CHECK_NUM=$((CHECK_NUM + 1))
    CMD_HASH=$(echo -n "$CMD" | shasum -a 256 | cut -c1-16)
    CACHE_FILE="$CACHE_DIR/$CMD_HASH"

    echo "[check $CHECK_NUM/$UNIQUE_COUNT] $CMD"
    run_check "$CMD"
    echo "$(cat "$TMPDIR_RUN/exit_code")" > "$CACHE_FILE.exit"
    echo "$(cat "$TMPDIR_RUN/duration_ms")" > "$CACHE_FILE.duration"
    cp "$TMPDIR_RUN/snippet.txt" "$CACHE_FILE.snippet"
done <<< "$UNIQUE_CMDS"

# Build results: iterate prompts in order, reuse cached result for each command.
for i in $(seq 0 $((TOTAL - 1))); do
    PROMPT_ID=$(jq -r ".[$i].id" "$PROMPTS_FILE")
    PROMPT_TEXT=$(jq -r ".[$i].prompt" "$PROMPTS_FILE")
    CATEGORY=$(jq -r ".[$i].category" "$PROMPTS_FILE")
    SEVERITY=$(jq -r ".[$i].severity" "$PROMPTS_FILE")
    CMD=$(jq -r ".[$i].command" "$PROMPTS_FILE")
    CMD_HASH=$(echo -n "$CMD" | shasum -a 256 | cut -c1-16)
    CACHE_FILE="$CACHE_DIR/$CMD_HASH"

    EXIT_CODE=$(cat "$CACHE_FILE.exit")
    DURATION_MS=$(cat "$CACHE_FILE.duration")
    OUTPUT_SNIPPET=$(cat "$CACHE_FILE.snippet")

    if [[ "$EXIT_CODE" -eq 0 ]]; then
        RESULT="pass"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        RESULT="fail"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    echo "[$((i + 1))/$TOTAL] $PROMPT_ID ($CATEGORY/$SEVERITY) -> $RESULT (${DURATION_MS}ms)"

    ENTRY=$(jq -n \
        --arg pid "$PROMPT_ID" \
        --arg prompt "$PROMPT_TEXT" \
        --arg result "$RESULT" \
        --arg cmd "$CMD" \
        --argjson exit_code "$EXIT_CODE" \
        --argjson duration "$DURATION_MS" \
        --arg snippet "$OUTPUT_SNIPPET" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg category "$CATEGORY" \
        --arg severity "$SEVERITY" \
        '{
            prompt_id: $pid,
            prompt: $prompt,
            category: $category,
            severity: $severity,
            result: $result,
            command: $cmd,
            exit_code: $exit_code,
            duration_ms: $duration,
            output_snippet: $snippet,
            timestamp: $ts
        }')
    RESULTS=$(echo "$RESULTS" | jq --argjson entry "$ENTRY" '. + [$entry]')
done

# Write results JSON
echo "$RESULTS" | jq '.' > "$RUN_DIR/results.json"

# Count failures by severity
CRITICAL_FAILS=$(echo "$RESULTS" | jq '[.[] | select(.severity == "critical" and .result == "fail")] | length')
HIGH_FAILS=$(echo "$RESULTS" | jq '[.[] | select(.severity == "high" and .result == "fail")] | length')
MEDIUM_FAILS=$(echo "$RESULTS" | jq '[.[] | select(.severity == "medium" and .result == "fail")] | length')

if [[ "$CRITICAL_FAILS" -gt 0 ]] || [[ "$HIGH_FAILS" -gt 0 ]]; then
    VERDICT="FAIL"
else
    VERDICT="PASS"
fi

# Generate summary markdown
cat > "$RUN_DIR/summary.md" <<SUMMARY
# Ralph Loop Summary

- Run folder: \`$RUN_DIR\`
- Timestamp: $TIMESTAMP
- Total prompts: $TOTAL
- Passed: $PASS_COUNT
- Failed: $FAIL_COUNT
- Verdict: **$VERDICT**

## Results by Category

| ID | Category | Severity | Result | Duration |
|----|----------|----------|--------|----------|
SUMMARY

echo "$RESULTS" | jq -r '.[] | "| \(.prompt_id) | \(.category) | \(.severity) | \(.result) | \(.duration_ms)ms |"' >> "$RUN_DIR/summary.md"

cat >> "$RUN_DIR/summary.md" <<SUMMARY

## Failure Breakdown

- Critical failures: $CRITICAL_FAILS
- High failures: $HIGH_FAILS
- Medium failures: $MEDIUM_FAILS
SUMMARY

# Append failure details if any
if [[ "$FAIL_COUNT" -gt 0 ]]; then
    cat >> "$RUN_DIR/summary.md" <<SUMMARY

## Failed Prompts
SUMMARY
    echo "$RESULTS" | jq -r '.[] | select(.result == "fail") | "### \(.prompt_id) (\(.severity))\n- **Prompt**: \(.prompt)\n- **Command**: `\(.command)`\n- **Exit code**: \(.exit_code)\n- **Output**: \(.output_snippet)\n"' >> "$RUN_DIR/summary.md"
fi

cat >> "$RUN_DIR/summary.md" <<SUMMARY

## Recommendation
SUMMARY

if [[ "$VERDICT" == "PASS" ]]; then
    echo "- All critical and high severity checks passed. Safe to proceed." >> "$RUN_DIR/summary.md"
else
    echo "- $CRITICAL_FAILS critical and $HIGH_FAILS high severity failures detected. Fix before release." >> "$RUN_DIR/summary.md"
fi

# Update root files
cp "$RUN_DIR/results.json" "docs/evals/ralph/results.scored.json"
cp "$RUN_DIR/summary.md" "docs/evals/ralph/summary.md"

echo "=== Ralph Loop Complete ==="
echo "Verdict: $VERDICT ($PASS_COUNT pass, $FAIL_COUNT fail)"
echo "Results: $RUN_DIR/results.json"
echo "Summary: $RUN_DIR/summary.md"
