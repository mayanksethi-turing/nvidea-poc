#!/bin/bash
# Safely merge samples from worktree to main repo with atomic locking
# Usage: ./scripts/merge-samples.sh <agent-id>

set -e

AGENT_ID="${1}"
MAIN_REPO=$(git rev-parse --show-toplevel)
WORKTREE_DIR="${MAIN_REPO}/worktrees/${AGENT_ID}"
LOCKFILE="${MAIN_REPO}/.samples-merge.lock"

if [ -z "$AGENT_ID" ]; then
    echo "❌ Error: Agent ID required"
    echo ""
    echo "Usage: $0 <agent-id>"
    echo ""
    echo "Available worktrees:"
    if [ -d "${MAIN_REPO}/worktrees" ]; then
        ls -1 "${MAIN_REPO}/worktrees/" 2>/dev/null | while read dir; do
            echo "  - $dir"
        done
    else
        echo "  (none)"
    fi
    exit 1
fi

if [ ! -d "$WORKTREE_DIR" ]; then
    echo "❌ Worktree not found: $WORKTREE_DIR"
    exit 1
fi

# Check if jq is installed for JSON manipulation
if ! command -v jq &> /dev/null; then
    echo "⚠️  Warning: jq not found. Install with: brew install jq"
    echo "   Continuing without metadata update..."
    JQ_AVAILABLE=false
else
    JQ_AVAILABLE=true
fi

# Find the sample directory in worktree
echo "🔍 Looking for samples in worktree..."
WORKTREE_SAMPLE=$(find "${WORKTREE_DIR}/samples" -maxdepth 1 -type d -name "task-*" 2>/dev/null | head -1)

if [ -z "$WORKTREE_SAMPLE" ]; then
    echo "❌ No sample found in worktree: ${WORKTREE_DIR}/samples/"
    echo "   Expected: task-* directory"
    exit 1
fi

SAMPLE_NAME=$(basename "$WORKTREE_SAMPLE")
echo "✓ Found sample: ${SAMPLE_NAME}"

# Show sample info if available
if [ -f "${WORKTREE_SAMPLE}/metadata.json" ] && [ "$JQ_AVAILABLE" = true ]; then
    echo ""
    echo "📋 Sample Info:"
    REPO_URL=$(jq -r '.repo // "unknown"' "${WORKTREE_SAMPLE}/metadata.json" 2>/dev/null)
    PR_NUM=$(jq -r '.prNumber // "unknown"' "${WORKTREE_SAMPLE}/metadata.json" 2>/dev/null)
    echo "   Repository: $REPO_URL"
    echo "   PR Number: $PR_NUM"
    echo ""
fi

echo "🔒 Acquiring lock for safe merge..."

# Use flock for atomic task number assignment
(
    # Try to acquire lock with 60 second timeout
    flock -x -w 60 200 || { 
        echo "❌ Failed to acquire lock after 60 seconds"
        echo "   Another merge might be in progress"
        exit 1
    }
    
    # Determine next task number atomically
    cd "${MAIN_REPO}"
    EXISTING_TASKS=$(ls -d samples/task-* 2>/dev/null | wc -l | xargs)
    NEXT_NUM=$((EXISTING_TASKS + 1))
    
    TARGET_DIR="${MAIN_REPO}/samples/task-${NEXT_NUM}"
    
    echo "📦 Copying sample to: task-${NEXT_NUM}"
    
    # Ensure target samples directory exists
    mkdir -p "${MAIN_REPO}/samples"
    
    # Copy the sample
    cp -r "${WORKTREE_SAMPLE}" "${TARGET_DIR}"
    
    # Update metadata with final task number if jq is available
    if [ -f "${TARGET_DIR}/metadata.json" ] && [ "$JQ_AVAILABLE" = true ]; then
        TMP_FILE=$(mktemp)
        jq --arg num "$NEXT_NUM" \
           --arg agent "$AGENT_ID" \
           '. + {"task_number": ($num | tonumber), "agent_id": $agent}' \
           "${TARGET_DIR}/metadata.json" > "$TMP_FILE"
        mv "$TMP_FILE" "${TARGET_DIR}/metadata.json"
    fi
    
    # Update agent state in worktree
    if [ -f "${WORKTREE_DIR}/.agent-state.json" ] && [ "$JQ_AVAILABLE" = true ]; then
        TMP_FILE=$(mktemp)
        jq --arg status "merged" \
           --arg task "task-${NEXT_NUM}" \
           '. + {"status": $status, "merged_as": $task, "merged_at": (now | todate)}' \
           "${WORKTREE_DIR}/.agent-state.json" > "$TMP_FILE"
        mv "$TMP_FILE" "${WORKTREE_DIR}/.agent-state.json"
    fi
    
    echo ""
    echo "✅ Sample merged successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📁 Location: ${TARGET_DIR}"
    echo "🔢 Task Number: ${NEXT_NUM}"
    echo "🤖 Agent ID: ${AGENT_ID}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
) 200>"$LOCKFILE"

echo "🔓 Lock released"
echo ""
echo "📝 Next steps:"
echo "   1. Validate the sample: cd ${TARGET_DIR} && ./run.sh"
echo "   2. Commit to git: git add samples/ && git commit -m 'Add task-${NEXT_NUM}'"
echo "   3. Cleanup worktree: ./scripts/cleanup-agent-worktree.sh ${AGENT_ID}"
echo ""

