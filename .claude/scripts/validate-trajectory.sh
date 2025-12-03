#!/bin/bash
# Validate trajectory files for authenticity and correctness
# Usage: ./validate-trajectory.sh <trajectory-file> [--type ideal|failed]

set -e

TRAJECTORY_FILE="${1}"
TYPE="${2:-ideal}"

if [ -z "$TRAJECTORY_FILE" ] || [ ! -f "$TRAJECTORY_FILE" ]; then
    echo "❌ Error: Trajectory file not found: $TRAJECTORY_FILE"
    echo "Usage: ./validate-trajectory.sh <trajectory-file> [--type ideal|failed]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SCRIPT_DIR}/../schemas/trajectory-schema.json"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Validating Trajectory: $(basename "$TRAJECTORY_FILE")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

ERRORS=0
WARNINGS=0

# ============================================
# 1. JSON Syntax Validation
# ============================================
echo "📝 Validating JSON syntax..."
if jq empty "$TRAJECTORY_FILE" 2>/dev/null; then
    echo "  ✅ Valid JSON syntax"
else
    echo "  ❌ Invalid JSON syntax"
    ERRORS=$((ERRORS + 1))
    exit 1
fi
echo

# ============================================
# 2. Schema Validation (if ajv-cli available)
# ============================================
if command -v ajv &> /dev/null; then
    echo "📋 Validating against schema..."
    if ajv validate -s "$SCHEMA_FILE" -d "$TRAJECTORY_FILE" 2>/dev/null; then
        echo "  ✅ Schema validation passed"
    else
        echo "  ⚠️  Schema validation failed (some fields may be missing)"
        WARNINGS=$((WARNINGS + 1))
    fi
    echo
fi

# ============================================
# 3. Required Fields Check
# ============================================
echo "📦 Checking required fields..."

# Check annotationTrace exists and is array
if jq -e '.annotationTrace | type == "array"' "$TRAJECTORY_FILE" > /dev/null 2>&1; then
    echo "  ✅ annotationTrace is array"
else
    echo "  ❌ annotationTrace missing or not an array"
    ERRORS=$((ERRORS + 1))
fi

# Check taskIssue exists
if jq -e '.taskIssue | type == "string" and length > 0' "$TRAJECTORY_FILE" > /dev/null 2>&1; then
    echo "  ✅ taskIssue is present"
else
    echo "  ❌ taskIssue missing or empty"
    ERRORS=$((ERRORS + 1))
fi

# Check tags exists
if jq -e '.tags | type == "object"' "$TRAJECTORY_FILE" > /dev/null 2>&1; then
    echo "  ✅ tags object exists"
else
    echo "  ❌ tags object missing"
    ERRORS=$((ERRORS + 1))
fi

# For failed trajectories, check failureMode
if [ "$TYPE" = "failed" ]; then
    if jq -e '.tags.failureMode | type == "string" and length > 0' "$TRAJECTORY_FILE" > /dev/null 2>&1; then
        FAILURE_MODE=$(jq -r '.tags.failureMode' "$TRAJECTORY_FILE")
        echo "  ✅ failureMode present: \"$FAILURE_MODE\""
    else
        echo "  ❌ failureMode missing (REQUIRED for failed trajectories)"
        ERRORS=$((ERRORS + 1))
    fi
fi

echo

# ============================================
# 4. Action Count Analysis
# ============================================
echo "📊 Analyzing action count..."
ACTION_COUNT=$(jq '.annotationTrace | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")

echo "  Actions: $ACTION_COUNT"

if [ "$ACTION_COUNT" -lt 5 ]; then
    echo "  ❌ Too few actions ($ACTION_COUNT < 5) - likely synthetic"
    ERRORS=$((ERRORS + 1))
elif [ "$ACTION_COUNT" -lt 15 ]; then
    echo "  ⚠️  Fewer than 15 actions - may indicate synthetic or simplified trajectory"
    WARNINGS=$((WARNINGS + 1))
else
    echo "  ✅ Action count appropriate for real agent run"
fi

echo

# ============================================
# 5. Timestamp Authenticity Check
# ============================================
echo "🕐 Checking timestamp authenticity..."

# Check for millisecond precision
FIRST_TS=$(jq -r '.annotationTrace[0].timestamp' "$TRAJECTORY_FILE" 2>/dev/null || echo "")

if [ -z "$FIRST_TS" ]; then
    echo "  ❌ No timestamp found in first action"
    ERRORS=$((ERRORS + 1))
elif [[ "$FIRST_TS" =~ \.[0-9]{3}Z$ ]]; then
    echo "  ✅ Timestamps have millisecond precision"
    echo "     Example: $FIRST_TS"
else
    echo "  ⚠️  Timestamps lack millisecond precision"
    echo "     Found: $FIRST_TS"
    echo "     Expected: 2025-12-01T18:27:05.146Z"
    echo "     This indicates synthetic/manually-created timestamps"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for round elapsed times (sign of synthetic data)
ROUND_COUNT=$(jq '[.annotationTrace[].elapsed_seconds] | map(select(. % 30 == 0)) | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
TOTAL_COUNT=$(jq '[.annotationTrace[].elapsed_seconds] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "1")

if [ "$TOTAL_COUNT" -gt 0 ]; then
    ROUND_RATIO=$(echo "scale=0; $ROUND_COUNT * 100 / $TOTAL_COUNT" | bc 2>/dev/null || echo "0")
    
    if [ "$ROUND_RATIO" -gt 50 ]; then
        echo "  ⚠️  ${ROUND_RATIO}% of elapsed times are round numbers (0, 30, 60, 90s)"
        echo "     Real agent runs have natural progression, not round intervals"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "  ✅ Elapsed times show natural progression"
    fi
fi

echo

# ============================================
# 6. Details Richness Check
# ============================================
echo "📚 Checking details richness..."

# Check if search actions have results
SEARCH_ACTIONS=$(jq '[.annotationTrace[] | select(.action == "search_string" or .action == "search_dir")] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
SEARCHES_WITH_RESULTS=$(jq '[.annotationTrace[] | select(.action == "search_string" or .action == "search_dir") | select(.details.results | type == "array" and length > 0)] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")

if [ "$SEARCH_ACTIONS" -gt 0 ]; then
    echo "  Search actions: $SEARCH_ACTIONS"
    echo "  With results: $SEARCHES_WITH_RESULTS"
    
    if [ "$SEARCHES_WITH_RESULTS" -eq 0 ]; then
        echo "  ⚠️  No search actions have results arrays - likely synthetic"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "  ✅ Search actions contain actual results"
    fi
fi

# Check if terminal commands have output
COMMAND_ACTIONS=$(jq '[.annotationTrace[] | select(.action == "execute_terminal_command")] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
COMMANDS_WITH_OUTPUT=$(jq '[.annotationTrace[] | select(.action == "execute_terminal_command") | select(.details.output | type == "string" and length > 0)] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")

if [ "$COMMAND_ACTIONS" -gt 0 ]; then
    echo "  Terminal commands: $COMMAND_ACTIONS"
    echo "  With output: $COMMANDS_WITH_OUTPUT"
    
    if [ "$COMMANDS_WITH_OUTPUT" -eq 0 ]; then
        echo "  ⚠️  No terminal commands have output - likely synthetic"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "  ✅ Terminal commands include actual output"
    fi
fi

echo

# ============================================
# 7. Required Actions Check
# ============================================
echo "🎬 Checking required actions..."

# Check for begin_interaction
if jq -e '.annotationTrace[0].action == "begin_interaction"' "$TRAJECTORY_FILE" > /dev/null 2>&1; then
    echo "  ✅ Starts with begin_interaction"
else
    echo "  ⚠️  Should start with begin_interaction"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for end_interaction
LAST_IDX=$((ACTION_COUNT - 1))
if jq -e ".annotationTrace[$LAST_IDX].action == \"end_interaction\"" "$TRAJECTORY_FILE" > /dev/null 2>&1; then
    echo "  ✅ Ends with end_interaction"
else
    if [ "$TYPE" = "failed" ]; then
        echo "  ℹ️  No end_interaction (acceptable for failed trajectory)"
    else
        echo "  ⚠️  Should end with end_interaction"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Check for test execution (ideal should have it, failed might not)
HAS_TESTS=$(jq '[.annotationTrace[] | select(.action == "execute_terminal_command" and (.details.command | contains("test") or contains("Test")))] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")

if [ "$TYPE" = "ideal" ]; then
    if [ "$HAS_TESTS" -gt 0 ]; then
        echo "  ✅ Includes test execution ($HAS_TESTS test commands)"
    else
        echo "  ⚠️  No test execution found (ideal trajectory should verify solution)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    if [ "$HAS_TESTS" -eq 0 ]; then
        echo "  ℹ️  No test execution (common failure mode)"
    else
        echo "  ℹ️  Includes test execution ($HAS_TESTS test commands)"
    fi
fi

echo

# ============================================
# 8. Thought Quality Check
# ============================================
echo "💭 Analyzing thought quality..."

# Check for generic thoughts
GENERIC_COUNT=$(jq '[.annotationTrace[].thought | select(. == "Looking for the bug" or . == "Fixing the issue" or . == "Fixing bug" or length < 15)] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")

if [ "$GENERIC_COUNT" -gt 0 ]; then
    echo "  ⚠️  Found $GENERIC_COUNT generic/short thoughts"
    echo "     Real trajectories have specific, detailed reasoning"
    WARNINGS=$((WARNINGS + 1))
else
    echo "  ✅ Thoughts are specific and detailed"
fi

# Check for thoughts with file/line references (good sign)
SPECIFIC_COUNT=$(jq '[.annotationTrace[].thought | select(contains("line ") or contains("Line ") or contains("file ") or contains(".ts") or contains(".js") or contains(".py") or contains(".java"))] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")

if [ "$SPECIFIC_COUNT" -gt 0 ]; then
    echo "  ✅ $SPECIFIC_COUNT thoughts reference specific files/lines"
else
    echo "  ℹ️  No thoughts reference specific files/lines"
fi

echo

# ============================================
# 9. Partition Distribution
# ============================================
echo "📂 Checking partition distribution..."

SETUP_COUNT=$(jq '[.annotationTrace[] | select(.partition == "EnvironmentSetup")] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
EXPLORE_COUNT=$(jq '[.annotationTrace[] | select(.partition == "Exploration")] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
SOLUTION_COUNT=$(jq '[.annotationTrace[] | select(.partition == "Solution")] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")
TEST_COUNT=$(jq '[.annotationTrace[] | select(.partition == "Test" or .partition == "FailtoPassUnitTest")] | length' "$TRAJECTORY_FILE" 2>/dev/null || echo "0")

echo "  EnvironmentSetup: $SETUP_COUNT"
echo "  Exploration: $EXPLORE_COUNT"
echo "  Solution: $SOLUTION_COUNT"
echo "  Test: $TEST_COUNT"

if [ "$EXPLORE_COUNT" -eq 0 ]; then
    echo "  ⚠️  No exploration actions - agents should explore before solving"
    WARNINGS=$((WARNINGS + 1))
fi

if [ "$SOLUTION_COUNT" -eq 0 ]; then
    echo "  ❌ No solution actions - trajectory must include code changes"
    ERRORS=$((ERRORS + 1))
fi

echo

# ============================================
# Summary
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Validation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ ALL CHECKS PASSED - HIGH QUALITY TRAJECTORY"
    echo
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  PASSED WITH WARNINGS"
    echo "   Warnings: $WARNINGS"
    echo
    echo "   This trajectory may be acceptable but shows some signs of"
    echo "   synthetic creation or missing details."
    echo
    exit 0
else
    echo "❌ VALIDATION FAILED"
    echo "   Errors: $ERRORS"
    echo "   Warnings: $WARNINGS"
    echo
    echo "   This trajectory does not meet quality standards."
    echo "   Please review and address the issues above."
    echo
    exit 1
fi

