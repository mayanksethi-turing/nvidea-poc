#!/bin/bash
# Cleanup agent worktree after completion
# Usage: ./scripts/cleanup-agent-worktree.sh <agent-id>

set -e

AGENT_ID="${1}"
MAIN_REPO=$(git rev-parse --show-toplevel)
WORKTREE_DIR="${MAIN_REPO}/worktrees/${AGENT_ID}"

if [ -z "$AGENT_ID" ]; then
    echo "❌ Error: Agent ID required"
    echo ""
    echo "Usage: $0 <agent-id>"
    echo ""
    echo "Available worktrees:"
    if [ -d "${MAIN_REPO}/worktrees" ]; then
        ls -1 "${MAIN_REPO}/worktrees/" 2>/dev/null | while read dir; do
            echo "  - $dir"
            if [ -f "${MAIN_REPO}/worktrees/$dir/.agent-state.json" ]; then
                STATUS=$(jq -r '.status // "unknown"' "${MAIN_REPO}/worktrees/$dir/.agent-state.json" 2>/dev/null)
                TARGET=$(jq -r '.target_repo // "unknown"' "${MAIN_REPO}/worktrees/$dir/.agent-state.json" 2>/dev/null)
                echo "    Status: $STATUS | Target: $TARGET"
            fi
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

# Check if agent state exists and read info
if [ -f "${WORKTREE_DIR}/.agent-state.json" ]; then
    TARGET_REPO=$(jq -r '.target_repo' "${WORKTREE_DIR}/.agent-state.json")
    STATUS=$(jq -r '.status' "${WORKTREE_DIR}/.agent-state.json")
    echo "📋 Agent Info:"
    echo "   Target Repo: $TARGET_REPO"
    echo "   Status: $STATUS"
    echo ""
fi

# Confirm cleanup
read -p "⚠️  Are you sure you want to remove this worktree? (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

# Get branch name before removing worktree
BRANCH_NAME=$(cd "$WORKTREE_DIR" && git branch --show-current)

echo "🧹 Removing worktree: ${AGENT_ID}"
git worktree remove "${WORKTREE_DIR}" --force

echo "🌿 Removing branch: ${BRANCH_NAME}"
git branch -D "${BRANCH_NAME}" 2>/dev/null || true

echo ""
echo "✅ Cleanup complete!"
echo ""

