#!/bin/bash
# Validate a task sample for completeness and correctness
# Usage: ./validate-sample.sh <task-directory>
# Example: ./validate-sample.sh samples/task-1

set -e

TASK_DIR="${1:-.}"

if [ ! -d "$TASK_DIR" ]; then
    echo "❌ Error: Directory $TASK_DIR does not exist"
    exit 1
fi

cd "$TASK_DIR"
TASK_NAME=$(basename "$TASK_DIR")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Validating $TASK_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Track validation status
ERRORS=0
WARNINGS=0

# ============================================
# 1. Check Required Files
# ============================================
echo "📁 Checking required files..."

REQUIRED_FILES=(
    "metadata.json"
    "fix.patch"
    "tests.patch"
    "ideal_trajectory.json"
    "failed_trajectory.json"
    "Dockerfile"
    "run.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ MISSING: $file"
        ERRORS=$((ERRORS + 1))
    fi
done

echo

# ============================================
# 2. Validate JSON Files
# ============================================
echo "📝 Validating JSON syntax..."

for json_file in metadata.json ideal_trajectory.json failed_trajectory.json; do
    if [ -f "$json_file" ]; then
        if jq . "$json_file" > /dev/null 2>&1; then
            echo "  ✅ $json_file is valid JSON"
        else
            echo "  ❌ $json_file is INVALID JSON"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

echo

# ============================================
# 3. Validate metadata.json Structure
# ============================================
echo "🏷️  Validating metadata.json structure..."

if [ -f "metadata.json" ]; then
    # Check for standard format fields (task-1 style)
    MISSING_FIELDS=""
    
    for field in author repo head prNumber failure; do
        if ! jq -e ".$field" metadata.json > /dev/null 2>&1; then
            MISSING_FIELDS="$MISSING_FIELDS $field"
        fi
    done
    
    if [ -z "$MISSING_FIELDS" ]; then
        echo "  ✅ All standard fields present (author, repo, head, prNumber, failure)"
    else
        echo "  ⚠️  Warning: Missing standard fields:$MISSING_FIELDS"
        echo "     (Alternative format acceptable, but task-1 format preferred)"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Check failure field is not empty
    FAILURE=$(jq -r '.failure // "null"' metadata.json)
    if [ "$FAILURE" == "null" ] || [ -z "$FAILURE" ]; then
        echo "  ❌ failure field is missing or empty"
        ERRORS=$((ERRORS + 1))
    else
        echo "  ✅ failure field: \"$FAILURE\""
    fi
    
    # Check prNumber type
    if jq -e '.prNumber | type == "string"' metadata.json > /dev/null 2>&1; then
        echo "  ✅ prNumber is string type"
    elif jq -e '.prNumber | type == "number"' metadata.json > /dev/null 2>&1; then
        echo "  ⚠️  prNumber is number (should be string in standard format)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo

# ============================================
# 4. Validate Trajectory Files
# ============================================
echo "🔄 Validating trajectory structure..."

# Check ideal_trajectory.json
if [ -f "ideal_trajectory.json" ]; then
    IDEAL_ACTIONS=$(jq '.annotationTrace | length' ideal_trajectory.json 2>/dev/null || echo "0")
    IDEAL_ISSUE=$(jq -r '.taskIssue // "missing"' ideal_trajectory.json 2>/dev/null)
    
    if [ "$IDEAL_ACTIONS" -gt 0 ]; then
        echo "  ✅ ideal_trajectory.json: $IDEAL_ACTIONS actions"
    else
        echo "  ❌ ideal_trajectory.json: No actions found"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ "$IDEAL_ISSUE" != "missing" ]; then
        echo "  ✅ ideal_trajectory.json: taskIssue defined"
    else
        echo "  ❌ ideal_trajectory.json: taskIssue missing"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check for required action types
    if jq -e '.annotationTrace[] | select(.action == "begin_interaction")' ideal_trajectory.json > /dev/null 2>&1; then
        echo "  ✅ ideal_trajectory.json: Has begin_interaction"
    else
        echo "  ⚠️  ideal_trajectory.json: Missing begin_interaction"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if jq -e '.annotationTrace[] | select(.action == "end_interaction")' ideal_trajectory.json > /dev/null 2>&1; then
        echo "  ✅ ideal_trajectory.json: Has end_interaction"
    else
        echo "  ⚠️  ideal_trajectory.json: Missing end_interaction"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo

# Check failed_trajectory.json
if [ -f "failed_trajectory.json" ]; then
    FAILED_ACTIONS=$(jq '.annotationTrace | length' failed_trajectory.json 2>/dev/null || echo "0")
    FAILED_ISSUE=$(jq -r '.taskIssue // "missing"' failed_trajectory.json 2>/dev/null)
    FAILURE_MODE=$(jq -r '.tags.failureMode // "missing"' failed_trajectory.json 2>/dev/null)
    
    if [ "$FAILED_ACTIONS" -gt 0 ]; then
        echo "  ✅ failed_trajectory.json: $FAILED_ACTIONS actions"
    else
        echo "  ❌ failed_trajectory.json: No actions found"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ "$FAILED_ISSUE" != "missing" ]; then
        echo "  ✅ failed_trajectory.json: taskIssue defined"
    else
        echo "  ❌ failed_trajectory.json: taskIssue missing"
        ERRORS=$((ERRORS + 1))
    fi
    
    # 🚨 CRITICAL: Check for failureMode in tags
    if [ "$FAILURE_MODE" != "missing" ] && [ ! -z "$FAILURE_MODE" ]; then
        echo "  ✅ failed_trajectory.json: failureMode = \"$FAILURE_MODE\""
    else
        echo "  ❌ failed_trajectory.json: tags.failureMode is MISSING (MANDATORY)"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Compare action counts (failed should typically have fewer)
    if [ "$IDEAL_ACTIONS" -gt 0 ] && [ "$FAILED_ACTIONS" -gt 0 ]; then
        RATIO=$(echo "scale=2; $FAILED_ACTIONS * 100 / $IDEAL_ACTIONS" | bc)
        echo "  📊 Action count ratio: ${RATIO}% (failed/ideal)"
        
        if (( $(echo "$RATIO < 70" | bc -l) )); then
            echo "     ✅ Failed trajectory is appropriately shorter"
        elif (( $(echo "$RATIO == 100" | bc -l) )); then
            echo "     ⚠️  Failed trajectory has same action count as ideal"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
else
    echo "  ❌ failed_trajectory.json: FILE MISSING (MANDATORY)"
    ERRORS=$((ERRORS + 1))
fi

echo

# ============================================
# 5. Validate Patch Files
# ============================================
echo "🔧 Validating patch files..."

for patch_file in fix.patch tests.patch; do
    if [ -f "$patch_file" ]; then
        if head -1 "$patch_file" | grep -q "^diff --git"; then
            LINES=$(wc -l < "$patch_file")
            echo "  ✅ $patch_file: Valid ($LINES lines)"
        else
            echo "  ❌ $patch_file: Invalid format (doesn't start with 'diff --git')"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

echo

# ============================================
# 6. Check Log Files
# ============================================
echo "📋 Checking validation logs..."

LOG_FILES=(
    "PASS_pre_tests.log"
    "FAIL_pre_patch.log"
    "PASS_post_patch.log"
)

for log_file in "${LOG_FILES[@]}"; do
    if [ -f "$log_file" ]; then
        echo "  ✅ $log_file"
    else
        echo "  ⚠️  Missing: $log_file (generated by run.sh)"
        # Don't count as error - these are generated by run.sh
    fi
done

echo

# ============================================
# Summary
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Validation Summary for $TASK_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ ALL CHECKS PASSED"
    echo
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  PASSED WITH WARNINGS"
    echo "   Warnings: $WARNINGS"
    echo
    exit 0
else
    echo "❌ VALIDATION FAILED"
    echo "   Errors: $ERRORS"
    echo "   Warnings: $WARNINGS"
    echo
    exit 1
fi

