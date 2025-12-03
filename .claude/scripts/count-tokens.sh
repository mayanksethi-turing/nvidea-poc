#!/bin/bash
# Token counting utility for trajectory files
# Estimates input/output tokens based on trajectory content
# Usage: ./count-tokens.sh <trajectory-file>

set -e

TRAJECTORY_FILE="${1}"

if [ -z "$TRAJECTORY_FILE" ] || [ ! -f "$TRAJECTORY_FILE" ]; then
    echo "❌ Error: Trajectory file not found: $TRAJECTORY_FILE"
    echo "Usage: ./count-tokens.sh <trajectory-file>"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔢 Token Count Estimation for: $(basename "$TRAJECTORY_FILE")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Rough estimation formula:
# - 1 word ≈ 1.3 tokens (average)
# - Code lines ≈ 10 tokens per line
# - JSON structure overhead ≈ 20% of content

# ============================================
# Count Input Tokens
# ============================================
echo "📥 Input Tokens (Problem Understanding):"
echo

# 1. TaskIssue (problem statement)
TASK_ISSUE=$(jq -r '.taskIssue' "$TRAJECTORY_FILE" 2>/dev/null || echo "")
TASK_ISSUE_WORDS=$(echo "$TASK_ISSUE" | wc -w | tr -d ' ')
TASK_ISSUE_TOKENS=$(echo "scale=0; $TASK_ISSUE_WORDS * 1.3" | bc 2>/dev/null || echo "0")

echo "  Problem Statement: ~${TASK_ISSUE_TOKENS} tokens"

# 2. Exploration thoughts (understanding phase)
EXPLORATION_THOUGHTS=$(jq -r '[.annotationTrace[] | select(.partition == "EnvironmentSetup" or .partition == "Exploration") | .thought] | join(" ")' "$TRAJECTORY_FILE" 2>/dev/null || echo "")
EXPLORATION_WORDS=$(echo "$EXPLORATION_THOUGHTS" | wc -w | tr -d ' ')
EXPLORATION_TOKENS=$(echo "scale=0; $EXPLORATION_WORDS * 1.3" | bc 2>/dev/null || echo "0")

echo "  Exploration Thoughts: ~${EXPLORATION_TOKENS} tokens"

# 3. Files opened (estimate 150 tokens per file read)
FILES_OPENED=$(jq '[.annotationTrace[] | select(.action == "open_file")] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
FILE_READ_TOKENS=$(echo "scale=0; $FILES_OPENED * 150" | bc 2>/dev/null || echo "0")

echo "  File Reads (${FILES_OPENED} files): ~${FILE_READ_TOKENS} tokens"

# 4. Search results (estimate 50 tokens per search result)
SEARCH_RESULTS=$(jq '[.annotationTrace[] | select(.action == "search_string" or .action == "search_dir") | .details.results[]?] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
SEARCH_TOKENS=$(echo "scale=0; $SEARCH_RESULTS * 50" | bc 2>/dev/null || echo "0")

echo "  Search Results (${SEARCH_RESULTS} results): ~${SEARCH_TOKENS} tokens"

# Total input (rounded)
INPUT_TOTAL=$(echo "scale=0; ($TASK_ISSUE_TOKENS + $EXPLORATION_TOKENS + $FILE_READ_TOKENS + $SEARCH_TOKENS) / 1" | bc)

echo "  ────────────────────────────"
echo "  Total Input: ~${INPUT_TOTAL} tokens"
echo

# ============================================
# Count Output Tokens
# ============================================
echo "📤 Output Tokens (Solution Generation):"
echo

# 1. Solution thoughts
SOLUTION_THOUGHTS=$(jq -r '[.annotationTrace[] | select(.partition == "Solution" or .partition == "Test" or .partition == "FailtoPassUnitTest") | .thought] | join(" ")' "$TRAJECTORY_FILE" 2>/dev/null || echo "")
SOLUTION_WORDS=$(echo "$SOLUTION_THOUGHTS" | wc -w | tr -d ' ')
SOLUTION_TOKENS=$(echo "scale=0; $SOLUTION_WORDS * 1.3" | bc 2>/dev/null || echo "0")

echo "  Solution Thoughts: ~${SOLUTION_TOKENS} tokens"

# 2. Code changes (estimate 10 tokens per line of code)
CODE_CHANGES=$(jq -r '[.annotationTrace[] | select(.action == "find_and_replace_code") | .details.changes[]? | .newText.context] | join("\n")' "$TRAJECTORY_FILE" 2>/dev/null || echo "")
CODE_LINES=$(echo "$CODE_CHANGES" | wc -l | tr -d ' ')
CODE_TOKENS=$(echo "scale=0; $CODE_LINES * 10" | bc 2>/dev/null || echo "0")

echo "  Code Changes (~${CODE_LINES} lines): ~${CODE_TOKENS} tokens"

# 3. Test outputs (estimate from command outputs)
TEST_OUTPUTS=$(jq -r '[.annotationTrace[] | select(.action == "execute_terminal_command") | .details.output] | join(" ")' "$TRAJECTORY_FILE" 2>/dev/null || echo "")
TEST_WORDS=$(echo "$TEST_OUTPUTS" | wc -w | tr -d ' ')
TEST_TOKENS=$(echo "scale=0; $TEST_WORDS * 1.3" | bc 2>/dev/null || echo "0")

echo "  Test Outputs: ~${TEST_TOKENS} tokens"

# 4. Completion summary
COMPLETION_THOUGHT=$(jq -r '[.annotationTrace[] | select(.action == "end_interaction") | .thought] | join(" ")' "$TRAJECTORY_FILE" 2>/dev/null || echo "")
COMPLETION_WORDS=$(echo "$COMPLETION_THOUGHT" | wc -w | tr -d ' ')
COMPLETION_TOKENS=$(echo "scale=0; $COMPLETION_WORDS * 1.3" | bc 2>/dev/null || echo "0")

echo "  Completion Summary: ~${COMPLETION_TOKENS} tokens"

# Total output (rounded)
OUTPUT_TOTAL=$(echo "scale=0; ($SOLUTION_TOKENS + $CODE_TOKENS + $TEST_TOKENS + $COMPLETION_TOKENS) / 1" | bc)

echo "  ────────────────────────────"
echo "  Total Output: ~${OUTPUT_TOTAL} tokens"
echo

# ============================================
# Summary
# ============================================
TOTAL_TOKENS=$(echo "$INPUT_TOTAL + $OUTPUT_TOTAL" | bc)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "  Input Tokens:  ~${INPUT_TOTAL}"
echo "  Output Tokens: ~${OUTPUT_TOTAL}"
echo "  Total Tokens:  ~${TOTAL_TOKENS}"
echo
echo "💡 These are estimates based on heuristics:"
echo "   - Words × 1.3 for text"
echo "   - Lines × 10 for code"
echo "   - Files × 150 for file reads"
echo "   - Results × 50 for search results"
echo
echo "📝 For metadata.json, use these rounded values:"
echo
echo '  "inputTokens": '${INPUT_TOTAL}','
echo '  "outputTokens": '${OUTPUT_TOTAL}
echo

# ============================================
# Complexity Assessment
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📏 Complexity Assessment:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

if [ "$INPUT_TOTAL" -lt 3000 ]; then
    echo "  Problem Complexity: Simple"
elif [ "$INPUT_TOTAL" -lt 6000 ]; then
    echo "  Problem Complexity: Medium"
else
    echo "  Problem Complexity: Complex"
fi

if [ "$OUTPUT_TOTAL" -lt 1500 ]; then
    echo "  Solution Complexity: Simple"
elif [ "$OUTPUT_TOTAL" -lt 3500 ]; then
    echo "  Solution Complexity: Medium"
else
    echo "  Solution Complexity: Complex"
fi

echo

# ============================================
# Action Statistics
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Action Statistics:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

TOTAL_ACTIONS=$(jq '.annotationTrace | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
SEARCH_ACTIONS=$(jq '[.annotationTrace[] | select(.action == "search_string" or .action == "search_dir")] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
FILE_ACTIONS=$(jq '[.annotationTrace[] | select(.action == "open_file")] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
EDIT_ACTIONS=$(jq '[.annotationTrace[] | select(.action == "find_and_replace_code")] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
COMMAND_ACTIONS=$(jq '[.annotationTrace[] | select(.action == "execute_terminal_command")] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")

echo "  Total Actions: $TOTAL_ACTIONS"
echo "  Searches: $SEARCH_ACTIONS"
echo "  File Reads: $FILE_ACTIONS"
echo "  Code Edits: $EDIT_ACTIONS"
echo "  Commands: $COMMAND_ACTIONS"
echo

ELAPSED_SECONDS=$(jq '.annotationTrace[-1].elapsed_seconds // 0' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
MINUTES=$(echo "scale=1; $ELAPSED_SECONDS / 60" | bc 2>/dev/null || echo "0")

echo "  Duration: ${ELAPSED_SECONDS}s (~${MINUTES} min)"
echo

