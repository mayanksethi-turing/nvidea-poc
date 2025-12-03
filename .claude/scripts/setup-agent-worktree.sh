#!/bin/bash
# Setup a new worktree for parallel agent execution
# Usage: ./scripts/setup-agent-worktree.sh <repo-name>

set -e

# Generate unique agent ID
REPO_NAME="${1:-unknown}"

if [ "$REPO_NAME" = "unknown" ]; then
    echo "⚠️  Warning: No repo name provided. Usage: $0 <repo-name>"
    echo "   Example: $0 tldraw"
    echo ""
    read -p "Enter repo name (or press Enter for 'unknown'): " REPO_INPUT
    if [ -n "$REPO_INPUT" ]; then
        REPO_NAME="$REPO_INPUT"
    fi
fi

TIMESTAMP=$(date +%s)
RANDOM_SUFFIX=$(head /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 6)
AGENT_ID="agent-${REPO_NAME}-${TIMESTAMP}-${RANDOM_SUFFIX}"

# Paths
MAIN_REPO=$(git rev-parse --show-toplevel)
WORKTREE_DIR="${MAIN_REPO}/worktrees/${AGENT_ID}"

# Create worktrees directory if not exists
mkdir -p "${MAIN_REPO}/worktrees"

# Create a new branch for this agent's work
BRANCH_NAME="agent/${AGENT_ID}"

# Create worktree on a new branch from current HEAD
echo "🔧 Creating worktree: ${WORKTREE_DIR}"
git worktree add -b "${BRANCH_NAME}" "${WORKTREE_DIR}" HEAD

# Create agent-specific state file
cat > "${WORKTREE_DIR}/.agent-state.json" << EOF
{
  "agent_id": "${AGENT_ID}",
  "branch": "${BRANCH_NAME}",
  "created_at": "$(date -Iseconds)",
  "status": "initialized",
  "target_repo": "${REPO_NAME}",
  "worktree_path": "${WORKTREE_DIR}"
}
EOF

echo ""
echo "✅ Worktree created successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Agent ID:     ${AGENT_ID}"
echo "🌿 Branch:       ${BRANCH_NAME}"
echo "📁 Path:         ${WORKTREE_DIR}"
echo "🎯 Target Repo:  ${REPO_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 To start the agent:"
echo "   cd ${WORKTREE_DIR}"
echo "   # Then open task-coordinator.md in Cursor and provide REPO_URL"
echo ""
echo "📝 To merge results after completion:"
echo "   cd ${MAIN_REPO}"
echo "   ./scripts/merge-samples.sh ${AGENT_ID}"
echo ""
echo "🧹 To cleanup when done:"
echo "   ./scripts/cleanup-agent-worktree.sh ${AGENT_ID}"
echo ""

