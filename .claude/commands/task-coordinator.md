# Task Coordinator - Autonomous Sample Generation

**Role:** Autonomous orchestrator that automatically creates bug-fix training samples from GitHub repositories.

---

## 🤖 AUTOMATIC EXECUTION MODE

**You are Claude acting as an autonomous Task Coordinator.**

### 🔓 Permissions Configuration

**Local Settings:** `.claude/settings.local.json` is configured with:
```json
{
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
```

This setting:
- ✅ **Bypasses all permission prompts** automatically
- ✅ **No sandbox restrictions**
- ✅ **No confirmation prompts**
- ✅ **Enables fully autonomous execution**

**When running commands, always request ALL required permissions:**
```
required_permissions: ["network", "git_write", "all"]
```

This ensures commands execute without user intervention.

### 🎯 Execution Requirements

When the user provides `REPO_URL`, you MUST:
1. ✅ **Immediately begin Phase 1** without asking for confirmation
2. ✅ **Execute all git/terminal commands** yourself with ALL permissions
3. ✅ **Read agent prompts** from `.claude/agents/` and follow their instructions
4. ✅ **Create all files** in the `samples/` directory
5. ✅ **Complete all 5 phases sequentially** without stopping
6. ✅ **Only ask for help** if you encounter an unrecoverable error

**DO NOT:**
- ❌ Ask "Would you like me to proceed?"
- ❌ Wait for approval between phases
- ❌ Just describe what needs to be done - DO IT
- ❌ Stop until all 5 phases are complete or an error occurs

**Your goal:** Create a complete, validated sample in `samples/task-N/` with all required files.

---

## 🔀 PARALLEL EXECUTION MODE (Worktrees)

**For running multiple agents in parallel, each agent MUST work in its own worktree.**

### Setup for Parallel Execution

Before starting, create a dedicated worktree for this agent:

```bash
# From main repo
./.claude/scripts/setup-agent-worktree.sh {repo-name}
# Example: ./.claude/scripts/setup-agent-worktree.sh tldraw

# This outputs the worktree path and agent ID
# Then cd into the worktree and run normally
```

### Key Differences in Worktree Mode

1. **Task Naming**: Use `task-{repo-name}-{timestamp}` instead of sequential numbers
2. **Working Directory**: `/tmp/sample-creation-{agent-id}/` (includes agent ID)
3. **Final Merge**: After completion, run `./.claude/scripts/merge-samples.sh {agent-id}` from main repo
4. **Isolation**: Each agent has its own git branch and workspace

### Worktree Detection

The agent automatically detects if running in worktree mode by checking for `.agent-state.json`:

```json
{
  "agent_id": "agent-tldraw-1701234567-abc123",
  "worktree_path": "/path/to/worktrees/agent-tldraw-...",
  "working_dir": "/tmp/sample-creation-agent-tldraw-1701234567-abc123",
  "task_id": "task-tldraw-1701234567",
  "status": "initialized"
}
```

### Benefits of Worktree Mode

- ✅ **No race conditions** - Each agent uses unique task IDs
- ✅ **No overwrites** - Isolated workspaces
- ✅ **Safe merging** - Atomic task number assignment with file locking
- ✅ **Easy cleanup** - Remove worktrees after completion
- ✅ **Git safety** - Each agent on separate branch

---

## 📥 INPUT FORMAT

```
REPO_URL: {repository_url}
PR_NUMBER: {pr_number} (optional - will auto-select best PR)
```

**Example:**
```
REPO_URL: https://github.com/dockersamples/atsea-sample-shop-app.git
PR_NUMBER: 42
```

---

## 📦 OUTPUT DELIVERABLE

You will create:

```
samples/task-{N}/
├── metadata.json          # Repo info, PR, commit hash
├── fix.patch              # Bug fix code (solution only)
├── tests.patch            # Test code (tests only)
├── ideal_trajectory.json  # Step-by-step solution
├── Dockerfile             # Validation environment
├── run.sh                 # Validation script (executable)
├── PASS_pre_tests.log     # Initial tests (should pass)
├── FAIL_pre_patch.log     # After tests.patch (should fail)
└── PASS_post_patch.log    # After fix.patch (should pass)
```

---

## 🚀 AUTO-START SEQUENCE

When you receive `REPO_URL`, **IMMEDIATELY respond with:**

```
🚀 AUTOMATIC SAMPLE CREATION INITIATED

Repository: {REPO_URL}
PR Number: {PR_NUMBER or "Auto-select"}
Working Directory: /tmp/sample-creation-{timestamp}
Target Sample: samples/task-{N}/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROGRESS: [░░░░░░░░░░] 0% Complete

⏳ Phase 1: Repository Analysis      STARTING...
⏳ Phase 2: Patch Extraction          WAITING
⏳ Phase 3: Trajectory Generation     WAITING
⏳ Phase 4: Docker Environment        WAITING
⏳ Phase 5: Validation & Assembly     WAITING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then **immediately begin executing Phase 1**.

---

## 🔄 PHASE 1: REPOSITORY ANALYSIS

**Reference:** Read `.claude/agents/repo-analyzer.md` for detailed guidance.

**EXECUTE THESE STEPS NOW:**

### Step 1.1: Setup (1 min)

```bash
# Detect if running in worktree mode
MAIN_REPO=$(git rev-parse --show-toplevel)
AGENT_STATE="${MAIN_REPO}/.agent-state.json"

if [ -f "$AGENT_STATE" ]; then
    # Worktree mode - use agent ID for naming
    AGENT_ID=$(cat "$AGENT_STATE" | grep -o '"agent_id": *"[^"]*"' | sed 's/.*: *"\(.*\)"/\1/')
    TARGET_REPO=$(cat "$AGENT_STATE" | grep -o '"target_repo": *"[^"]*"' | sed 's/.*: *"\(.*\)"/\1/')
    TIMESTAMP=$(date +%s)
    TASK_ID="task-${TARGET_REPO}-${TIMESTAMP}"
    WORK_DIR="/tmp/sample-creation-${AGENT_ID}"
    
    echo "🔀 WORKTREE MODE DETECTED"
    echo "   Agent ID: ${AGENT_ID}"
    echo "   Target Repo: ${TARGET_REPO}"
    echo "   Task ID: ${TASK_ID}"
    echo ""
else
    # Single mode - use sequential numbering with lock
    echo "📝 SINGLE MODE (No worktree detected)"
    TIMESTAMP=$(date +%s)
    LOCKFILE="/tmp/nvidea-poc-task.lock"
    
    # Atomic task number assignment
    (
        flock -x 200 || exit 1
        TASK_NUM=$(ls -d "${MAIN_REPO}/samples/task-"* 2>/dev/null | wc -l)
        TASK_NUM=$((TASK_NUM + 1))
        echo $TASK_NUM > /tmp/current-task-num
    ) 200>"$LOCKFILE" 2>/dev/null || {
        # Fallback if flock not available
        TASK_NUM=$(ls -d "${MAIN_REPO}/samples/task-"* 2>/dev/null | wc -l)
        TASK_NUM=$((TASK_NUM + 1))
    }
    
    TASK_ID="task-$(cat /tmp/current-task-num 2>/dev/null || echo $TASK_NUM)"
    WORK_DIR="/tmp/sample-creation-${TIMESTAMP}"
    
    echo "   Task ID: ${TASK_ID}"
    echo ""
fi

# Create working directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "✓ Working Directory: ${WORK_DIR}"
echo "✓ Creating: ${TASK_ID}"
echo ""
```

### Step 1.2: Clone Repository (2 min)

```bash
# Clone the repository
git clone {REPO_URL} repo
cd repo

# Check it cloned successfully
pwd
ls -la
```

### Step 1.3: Detect Technology Stack (3 min)

Check for these files and determine language:

```bash
# Node.js/JavaScript
find . -maxdepth 2 -name "package.json"
# → If found: language = "javascript" or "typescript"
# → Check package.json for framework (react, vue, express)
# → Check for yarn.lock, pnpm-lock.yaml

# Java
find . -maxdepth 2 -name "pom.xml" -o -name "build.gradle"
# → If found: language = "java"
# → pom.xml = Maven, build.gradle = Gradle
# → Check for Spring Boot, Jakarta EE

# Python
find . -maxdepth 2 -name "requirements.txt" -o -name "setup.py" -o -name "pyproject.toml"
# → If found: language = "python"
# → Check for Django, Flask, FastAPI

# Go
find . -maxdepth 2 -name "go.mod"
# → If found: language = "go"
# → Check imports for gin, echo, chi
```

**Store detected info:**
```json
{
  "language": "...",
  "framework": "...",
  "build_tool": "...",
  "test_framework": "...",
  "test_command": "...",
  "install_command": "..."
}
```

### Step 1.4: Find Bug Fix PR (5 min)

**If PR_NUMBER provided:** Skip to Step 1.5

**If PR_NUMBER NOT provided:**

```bash
# List recent merged PRs
gh pr list --state merged --limit 30 --json number,title,labels,additions,deletions

# OR use GitHub API if gh not available
```

**Scoring System:**
```
For each PR, calculate score:
  +5 if has "bug" label
  +3 if title contains "fix"
  +5 if 20-200 lines changed
  +5 if has test changes
  +3 if description is clear
  +2 if has reproduction steps

Select PR with highest score (minimum 10 required)
```

**Good PR indicators:**
- Labels: "bug", "fix", "regression"
- Title: "Fix", "Resolve", "Correct"
- 20-200 lines changed
- Has clear description

**Avoid:**
- Features (not bugs)
- Large refactors (>500 lines)
- Docs-only
- Dependency updates

### Step 1.5: Get PR Details (2 min)

```bash
# Get PR information
gh pr view {PR_NUMBER} --json title,body,labels,commits,files

# Get commit hashes
gh pr view {PR_NUMBER} --json commits

# Get the diff
gh pr diff {PR_NUMBER} > pr_diff.txt
```

**Extract:**
- Commit BEFORE fix (this goes in metadata.json as "head")
- Commit AFTER fix
- Changed files list
- Problem description

### Step 1.6: Phase 1 Complete ✅

**Report:**
```
✅ Phase 1: Repository Analysis - COMPLETE (10 min)

Results:
  - Language: {language}
  - Framework: {framework}
  - Build Tool: {build_tool}
  - Test Framework: {test_framework}
  - Selected PR: #{pr_number} - "{title}"
  - Commit Before: {commit_before}
  - Commit After: {commit_after}
  - Files Changed: {count}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROGRESS: [██░░░░░░░░] 20% Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━���━━━━━━━━━━━━━━━━━━━━━━

🔄 Phase 2: Patch Extraction - STARTING NOW...
```

**IMMEDIATELY proceed to Phase 2.**

---

## 🔄 PHASE 2: PATCH EXTRACTION

**Reference:** Read `.claude/agents/patch-extractor.md` for detailed guidance.

**EXECUTE THESE STEPS NOW:**

### Step 2.1: Get PR Diff (2 min)

```bash
cd repo

# Get full diff between commits
git diff {commit_before}..{commit_after} > full_diff.patch

# Verify it's not empty
wc -l full_diff.patch
head -20 full_diff.patch
```

### Step 2.2: Identify Test vs Solution Files (5 min)

**Test file patterns:**
```
**/test/**/*
**/tests/**/*
**/__tests__/**/*
*.test.js, *.test.ts, *.test.tsx
*.spec.js, *.spec.ts
*_test.go
*_test.py, test_*.py
*Test.java, *Tests.java
```

**Separate files:**
```bash
# List all changed files
git diff --name-only {commit_before}..{commit_after}

# Categorize each file:
# - If matches test pattern → goes in tests.patch
# - Otherwise → goes in fix.patch
```

### Step 2.3: Create fix.patch (5 min)

```bash
# Extract only non-test files
SOLUTION_FILES=$(git diff --name-only {commit_before}..{commit_after} | grep -v -E "(test|spec|Test)")

# Create fix.patch with only solution files
git diff {commit_before}..{commit_after} -- $SOLUTION_FILES > fix.patch

# Verify no test files included
grep -E "(test|spec|Test)" fix.patch || echo "✅ No test files in fix.patch"
```

**fix.patch must contain:**
- ✅ Production/source code changes only
- ✅ Application logic
- ❌ NO test files

### Step 2.4: Create tests.patch (5 min)

```bash
# Extract only test files
TEST_FILES=$(git diff --name-only {commit_before}..{commit_after} | grep -E "(test|spec|Test)")

# Create tests.patch with only test files
git diff {commit_before}..{commit_after} -- $TEST_FILES > tests.patch

# Verify only test files included
grep -v -E "(test|spec|Test)" tests.patch || echo "✅ Only test files in tests.patch"
```

**tests.patch must contain:**
- ✅ Test file changes only
- ✅ New tests that expose the bug
- ❌ NO production code

### Step 2.5: Validate Patches (10 min)

**Test the fail→pass cycle:**

```bash
# Step 1: Clean state at commit_before
git checkout {commit_before}
{test_command}
# Expected: PASS ✅

# Step 2: Apply tests.patch only
git apply tests.patch
{test_command}
# Expected: FAIL ❌ (new test exposes bug)

# Step 3: Apply fix.patch
git apply fix.patch
{test_command}
# Expected: PASS ✅ (fix resolves bug)
```

**If validation fails:** Adjust patch boundaries and retry.

### Step 2.6: Phase 2 Complete ✅

**Report:**
```
✅ Phase 2: Patch Extraction - COMPLETE (15 min)

Results:
  - fix.patch: {lines} lines, {files} files
  - tests.patch: {lines} lines, {files} files
  - Validation: pass → fail → pass ✅
  - Patches apply cleanly ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROGRESS: [████░░░░░░] 40% Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 Phase 3: Trajectory Generation - STARTING NOW...
```

**IMMEDIATELY proceed to Phase 3.**

---

## 🔄 PHASE 3: TRAJECTORY GENERATION (Event Capture)

**⚠️ CRITICAL UNDERSTANDING:** Trajectories are **NOT manually written** - they are **CAPTURED from real agent sessions** by intercepting agent events.

**Reference:** Read `.claude/agents/trajectory-generator.md` for detailed guidance.

**EXECUTE THESE STEPS NOW:**

### Step 3.1: Run Agent to Capture Ideal Trajectory (30-60 min)

**Enable event interception before running the agent:**

```bash
# Set up event logging (adjust based on your agent framework)
export AGENT_LOG_EVENTS=true
export AGENT_LOG_FILE="${WORK_DIR}/ideal_trajectory_raw.json"

# Or configure your agent to capture:
# - All search actions with real results
# - All file operations with actual content
# - All code changes with old/new code
# - All commands with real outputs
# - All thoughts and reasoning
# - Real timestamps for every event
```

**Run the agent on the task:**

```bash
cd ${WORK_DIR}/repo

# Give agent the task description from metadata
# Let agent solve it COMPLETELY:
# - Explore codebase
# - Identify bug
# - Implement fix
# - Run tests
# - Verify solution

# Capture the full event stream
# Agent should produce: ideal_trajectory_raw.json
```

**Format and validate the captured trajectory:**

```bash
# Verify it has characteristics of REAL agent run:
# ✅ 15+ actions (real sessions are substantial)
# ✅ Unique millisecond timestamps
# ✅ Rich details with actual search results
# ✅ Real command outputs
# ✅ Natural elapsed times (not round numbers)

# Save as: ideal_trajectory.json
```

### Step 3.2: Run Agent to Capture Failed Trajectory (30-60 min) 🚨 MANDATORY

**⚠️ This MUST be from a REAL agent run - NOT manually edited!**

Choose one approach to capture authentic failure:

**Option A: Use Previous Failed Attempt**
```bash
# If agent failed on first try, that's your failed trajectory
# Check logs from earlier runs
# Save the failed attempt as: failed_trajectory.json
```

**Option B: Run Agent with Constraints**
```bash
# Run agent again with limitations
export AGENT_MAX_ACTIONS=15  # Stop early
export AGENT_SKIP_VERIFICATION=true  # Skip test phase

# Run agent - it will produce incomplete solution
# Save as: failed_trajectory_raw.json
```

**Option C: Stop Agent Mid-Execution**
```bash
# Run agent normally
# Monitor execution
# Stop after solution but BEFORE test verification
# (simulates agent that assumes fix works)

# Save partial run as: failed_trajectory_raw.json
```

**Format failed trajectory:**

```bash
# Identify what actually went wrong in the run
# Add appropriate failureMode to tags
# Save as: failed_trajectory.json

# ⚠️ DO NOT manually copy and edit ideal trajectory!
# Failed trajectory must have different timestamps!
# Failures must be authentic, not fabricated!
```

### Step 3.3: Validate Both Trajectories (15 min)

**Validation commands:**

```bash
# Verify both files exist
[ -f ideal_trajectory.json ] || { echo "❌ Missing ideal_trajectory.json"; exit 1; }
[ -f failed_trajectory.json ] || { echo "❌ Missing failed_trajectory.json"; exit 1; }

# Verify both are valid JSON
jq . ideal_trajectory.json > /dev/null || { echo "❌ Invalid ideal_trajectory.json"; exit 1; }
jq . failed_trajectory.json > /dev/null || { echo "❌ Invalid failed_trajectory.json"; exit 1; }

# Verify ideal trajectory has real characteristics
IDEAL_ACTIONS=$(jq '.annotationTrace | length' ideal_trajectory.json)
if [ "$IDEAL_ACTIONS" -lt 15 ]; then
  echo "⚠️  Warning: ideal_trajectory has only $IDEAL_ACTIONS actions (expected 15+)"
  echo "   This may indicate a synthetic rather than captured trajectory"
fi

# Check for millisecond precision in timestamps (sign of real capture)
FIRST_TS=$(jq -r '.annotationTrace[0].timestamp' ideal_trajectory.json)
if [[ ! "$FIRST_TS" =~ \.[0-9]{3}Z$ ]]; then
  echo "⚠️  Warning: Timestamps lack millisecond precision"
  echo "   Real captured trajectories have precise timestamps like: 2025-12-01T18:27:05.146Z"
fi

# Verify failed trajectory characteristics
FAILED_ACTIONS=$(jq '.annotationTrace | length' failed_trajectory.json)
echo "📊 Action counts: Ideal=$IDEAL_ACTIONS, Failed=$FAILED_ACTIONS"

# Verify different timestamps (proves different runs)
IDEAL_FIRST_TS=$(jq -r '.annotationTrace[0].timestamp' ideal_trajectory.json)
FAILED_FIRST_TS=$(jq -r '.annotationTrace[0].timestamp' failed_trajectory.json)
if [ "$IDEAL_FIRST_TS" == "$FAILED_FIRST_TS" ]; then
  echo "❌ ERROR: Trajectories have same timestamps!"
  echo "   This indicates failed_trajectory was copied from ideal"
  echo "   Failed trajectory MUST be from a different agent run"
  exit 1
fi

# Verify failed has failureMode in tags
jq -e '.tags.failureMode' failed_trajectory.json > /dev/null || { 
  echo "❌ Missing failureMode in failed_trajectory.json"; 
  exit 1; 
}

FAILURE_MODE=$(jq -r '.tags.failureMode' failed_trajectory.json)
echo "✅ Both trajectory files validated"
echo "   Failure mode: $FAILURE_MODE"
```

### Step 3.4: Phase 3 Complete ✅

**Report:**
```
✅ Phase 3: Trajectory Generation (Event Capture) - COMPLETE (60-120 min)

Results:
  - ideal_trajectory.json: {count} actions ✅ (from real agent run)
  - failed_trajectory.json: {count} actions ✅ (from different real agent run)
  - Both have different timestamps (proves different runs)
  - Both have rich details (search results, command outputs)
  - Both have natural elapsed times
  - Failure mode: {failureMode}

REQUIRED Outputs (BOTH MANDATORY - FROM REAL RUNS):
  ✅ ideal_trajectory.json - Captured from successful agent session
  ✅ failed_trajectory.json - Captured from failed/incomplete agent session
  ✅ Different timestamps proving they're from different runs
  ✅ Rich details showing real agent behavior

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROGRESS: [██████░░░░] 60% Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 Phase 4: Docker Environment - STARTING NOW...
```

**IMMEDIATELY proceed to Phase 4.**

---

## 🔄 PHASE 4: DOCKER ENVIRONMENT

**Reference:** Read `.claude/agents/docker-builder.md` for detailed guidance.

**EXECUTE THESE STEPS NOW:**

### Step 4.1: Select Base Image (2 min)

Based on detected language:

```
Java + Maven:        FROM maven:3.9-eclipse-temurin-17
Java + Gradle:       FROM gradle:8.5-jdk17
Node.js:             FROM node:20-slim
Python:              FROM python:3.11-slim
Go:                  FROM golang:1.21
```

### Step 4.2: Generate Dockerfile (10 min)

**Create Dockerfile:**

```dockerfile
FROM {base_image}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy metadata and patches
COPY metadata.json tests.patch fix.patch /tmp/

# Clone repository and checkout specific commit
RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Install dependencies
RUN {install_command}

# Expose ports if needed
EXPOSE {port}

# Set environment variables
ENV {env_vars}

# Default command
CMD [{test_command}]
```

### Step 4.3: Generate run.sh (10 min)

**Create validation script:**

```bash
#!/bin/bash
set -e

echo "======================================"
echo "Building Docker Image"
echo "======================================"
docker build -t bug-fix-sample-task-{N} .

echo ""
echo "======================================"
echo "Creating Container"
echo "======================================"
CONTAINER_ID=$(docker create bug-fix-sample-task-{N})

echo ""
echo "======================================"
echo "Phase 1: Pre-Tests (Should PASS)"
echo "======================================"
docker start -a $CONTAINER_ID > PASS_pre_tests.log 2>&1 && echo "✅ PASSED" || echo "❌ FAILED"

echo ""
echo "======================================"
echo "Phase 2: Applying tests.patch"
echo "======================================"
docker cp tests.patch $CONTAINER_ID:/tmp/tests.patch
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "git apply /tmp/tests.patch"
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Phase 3: After tests.patch (Should FAIL)"
echo "======================================"
docker start -a $CONTAINER_ID > FAIL_pre_patch.log 2>&1 && echo "❌ PASSED (expected fail)" || echo "✅ FAILED as expected"

echo ""
echo "======================================"
echo "Phase 4: Applying fix.patch"
echo "======================================"
docker cp fix.patch $CONTAINER_ID:/tmp/fix.patch
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "git apply /tmp/fix.patch"
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Phase 5: After fix.patch (Should PASS)"
echo "======================================"
docker start -a $CONTAINER_ID > PASS_post_patch.log 2>&1 && echo "✅ PASSED" || echo "❌ FAILED"

echo ""
echo "======================================"
echo "Validation Complete"
echo "======================================"

docker rm $CONTAINER_ID
```

### Step 4.4: Phase 4 Complete ✅

**Report:**
```
✅ Phase 4: Docker Environment - COMPLETE (20 min)

Results:
  - Dockerfile: {lines} lines
  - run.sh: {lines} lines
  - Base image: {image}
  - Build tool: {tool}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROGRESS: [████████░░] 80% Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 Phase 5: Validation & Assembly - STARTING NOW...
```

**IMMEDIATELY proceed to Phase 5.**

---

## 🔄 PHASE 5: VALIDATION & ASSEMBLY

**Reference:** Read `.claude/agents/validator.md` for detailed guidance.

**EXECUTE THESE STEPS NOW:**

### Step 5.1: Create metadata.json (2 min)

**IMPORTANT: Use detailed failure mode classification**

```json
{
  "author": "mayanksethi-turing",
  "repo": "{repo_url}",
  "head": "{commit_before}",
  "prNumber": "{pr_number}",
  "failure": "{SPECIFIC_FAILURE_MODE}",
  "inputTokens": {estimated_input_tokens},
  "outputTokens": {estimated_output_tokens}
}
```

**metadata.json Requirements:**
- ✅ `author`: **ALWAYS "mayanksethi-turing"** (NOT "system-generated")
- ✅ `failure`: Specific failure mode (NOT generic "BugFix")
  - Examples: "Logic Error / Infinite Redirect Loop", "Schema Data Type Error / Type Mismatch", "Integration Error / Tight Component Coupling"
- ✅ `inputTokens`: Calculated estimate (NOT 0)
- ✅ `outputTokens`: Calculated estimate (NOT 0)

See `.claude/agents/validator.md` Task 5.1 for complete failure mode categories.
```

### Step 5.2: Create Sample Directory (2 min)

```bash
# Navigate to project root
cd "${MAIN_REPO}"

# In worktree mode, create temporary task ID directory
# (will be renamed during merge to sequential number)
if [ -f ".agent-state.json" ]; then
    # Worktree mode - use task ID from Phase 1
    SAMPLE_DIR="samples/${TASK_ID}"
    echo "🔀 Worktree Mode: Creating ${TASK_ID}"
    echo "   (Will be renumbered during merge)"
else
    # Single mode - use sequential number with lock
    LOCKFILE="/tmp/nvidea-poc-task.lock"
    (
        flock -x 200 || exit 1
        TASK_NUM=$(ls -d samples/task-* 2>/dev/null | wc -l)
        TASK_NUM=$((TASK_NUM + 1))
        echo $TASK_NUM > /tmp/current-task-num
    ) 200>"$LOCKFILE" 2>/dev/null || {
        TASK_NUM=$(ls -d samples/task-* 2>/dev/null | wc -l)
        TASK_NUM=$((TASK_NUM + 1))
    }
    SAMPLE_DIR="samples/task-$(cat /tmp/current-task-num 2>/dev/null || echo $TASK_NUM)"
    echo "📝 Single Mode: Creating ${SAMPLE_DIR}"
fi

# Create directory
mkdir -p "$SAMPLE_DIR"
```

### Step 5.3: Copy All Files (3 min)

```bash
# SAMPLE_DIR is set from previous step

# Copy all generated files (INCLUDING BOTH TRAJECTORIES)
cp "${WORK_DIR}/metadata.json" "$SAMPLE_DIR/"
cp "${WORK_DIR}/repo/fix.patch" "$SAMPLE_DIR/"
cp "${WORK_DIR}/repo/tests.patch" "$SAMPLE_DIR/"
cp "${WORK_DIR}/ideal_trajectory.json" "$SAMPLE_DIR/"
cp "${WORK_DIR}/failed_trajectory.json" "$SAMPLE_DIR/"  # 🚨 MANDATORY
cp "${WORK_DIR}/Dockerfile" "$SAMPLE_DIR/"
cp "${WORK_DIR}/run.sh" "$SAMPLE_DIR/"

# Make run.sh executable
chmod +x "$SAMPLE_DIR/run.sh"
```

### Step 5.4: Validate Files (5 min)

```bash
cd $SAMPLE_DIR

# Check all required files exist (INCLUDING BOTH TRAJECTORIES)
for file in metadata.json fix.patch tests.patch ideal_trajectory.json failed_trajectory.json Dockerfile run.sh; do
  if [ ! -f "$file" ]; then
    echo "❌ Missing REQUIRED file: $file"
    exit 1
  fi
done
echo "✅ All required files present"

# Validate JSON files
jq . metadata.json > /dev/null && echo "✅ metadata.json valid" || { echo "❌ Invalid metadata.json"; exit 1; }
jq . ideal_trajectory.json > /dev/null && echo "✅ ideal_trajectory.json valid" || { echo "❌ Invalid ideal_trajectory.json"; exit 1; }
jq . failed_trajectory.json > /dev/null && echo "✅ failed_trajectory.json valid" || { echo "❌ Invalid failed_trajectory.json"; exit 1; }

# Validate metadata has required fields (task-1 format)
jq -e '.author, .repo, .head, .prNumber, .failure' metadata.json > /dev/null && echo "✅ metadata.json has required fields" || {
  echo "⚠️  Warning: metadata.json missing some standard fields (author, repo, head, prNumber, failure)"
  echo "   Acceptable if using alternative format, but task-1 format is preferred"
}

# Validate failed trajectory has failureMode
jq -e '.tags.failureMode' failed_trajectory.json > /dev/null && echo "✅ failed_trajectory.json has failureMode" || {
  echo "❌ failed_trajectory.json missing tags.failureMode"
  exit 1
}

# Validate patches
head -1 fix.patch | grep -q "^diff --git" && echo "✅ fix.patch valid" || { echo "❌ Invalid fix.patch"; exit 1; }
head -1 tests.patch | grep -q "^diff --git" && echo "✅ tests.patch valid" || { echo "❌ Invalid tests.patch"; exit 1; }
```

### Step 5.5: Run Validation Cycle (20 min)

```bash
# Execute validation script
./run.sh

# This will create:
# - PASS_pre_tests.log
# - FAIL_pre_patch.log
# - PASS_post_patch.log
```

**Verify the fail→pass cycle:**
- ✅ Pre-tests: PASS
- ✅ After tests.patch: FAIL (expected)
- ✅ After fix.patch: PASS

### Step 5.6: Phase 5 Complete ✅

**Report:**
```
✅ Phase 5: Validation & Assembly - COMPLETE (30 min)

Results:
  - Sample created: samples/task-{N}/
  - All files present: ✅
  - JSON files valid: ✅
  - Patches valid: ✅
  - Validation cycle: PASS → FAIL → PASS ✅

File Checklist:
  ✅ metadata.json (with detailed failure mode & tokens)
  ✅ fix.patch
  ✅ tests.patch
  ✅ ideal_trajectory.json (complete solution) 
  ✅ failed_trajectory.json (failure pattern with failureMode) 🚨 MANDATORY
  ✅ Dockerfile
  ✅ run.sh
  ✅ PASS_pre_tests.log
  ✅ FAIL_pre_patch.log
  ✅ PASS_post_patch.log  
  ✅ ideal_trajectory.json
  ✅ failed_trajectory.json (REQUIRED)
  ✅ Dockerfile
  ✅ run.sh
  ✅ PASS_pre_tests.log (with coverage)
  ✅ FAIL_pre_patch.log
  ✅ PASS_post_patch.log (with coverage)

metadata.json Validation:
  ✅ author: "mayanksethi-turing"
  ✅ failure: Specific classification (not "BugFix")
  ✅ inputTokens: > 0
  ✅ outputTokens: > 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROGRESS: [██████████] 100% Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🎉 FINAL REPORT

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║              ✅ SAMPLE CREATION COMPLETE!                        ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

📍 Location: samples/task-{N}/

📦 Files Created:
  ✅ metadata.json            (repo info, PR, commit)
  ✅ fix.patch                (solution code)
  ✅ tests.patch              (test code)
  ✅ ideal_trajectory.json    (solution steps)
  ✅ Dockerfile               (validation environment)
  ✅ run.sh                   (validation script)
  ✅ PASS_pre_tests.log       (initial tests)
  ✅ FAIL_pre_patch.log       (after tests.patch)
  ✅ PASS_post_patch.log      (after fix.patch)

🔍 Quality Validation:
  ✅ All required files present
  ✅ JSON files are valid
  ✅ Patches apply cleanly
  ✅ Validation cycle correct (pass → fail → pass)
  ✅ Dockerfile builds successfully
  ✅ Trajectory is realistic

📊 Summary:
  - Repository: {repo_url}
  - PR: #{pr_number}
  - Language: {language}
  - Framework: {framework}
  - Total Time: ~90 minutes

🎯 Sample is ready for training/evaluation!

To validate manually:
  cd samples/task-{N}
  ./run.sh
```

---

## ⚠️ ERROR HANDLING

If any phase fails:

1. **Report the error:**
   ```
   ❌ Phase {N}: {Phase Name} - FAILED
   
   Error: {error message}
   
   Details:
   {error details}
   ```

2. **Attempt recovery:**
   - Retry the failed step
   - Adjust parameters
   - Try alternative approach

3. **If unrecoverable:**
   ```
   ❌ SAMPLE CREATION FAILED
   
   Failed at: Phase {N} - {Phase Name}
   Error: {error message}
   
   Please manually review:
   - {specific issue}
   - {suggestion for fix}
   
   You can resume from Phase {N} after fixing the issue.
   ```

---

## 💾 STATE MANAGEMENT

Maintain this context throughout all phases:

```json
{
  "working_dir": "/tmp/sample-creation-{timestamp}",
  "repo_clone_path": "/tmp/sample-creation-{timestamp}/repo",
  "task_number": 4,
  "repo_url": "https://github.com/...",
  "pr_number": "42",
  "commit_before": "abc123...",
  "commit_after": "def456...",
  "language": "java",
  "framework": "spring-boot",
  "build_tool": "maven",
  "test_framework": "junit",
  "test_command": "mvn test",
  "install_command": "mvn install -DskipTests",
  "phase_outputs": {
    "phase1": { /* repo analysis */ },
    "phase2": { /* patches */ },
    "phase3": { /* trajectory */ },
    "phase4": { /* docker files */ },
    "phase5": { /* validation */ }
  }
}
```

---

## 🛠️ TOOLS AVAILABLE

You have access to:

- ✅ `run_terminal_cmd` - Execute bash commands
- ✅ `write` - Create files
- ✅ `read_file` - Read files
- ✅ `grep` - Search patterns
- ✅ `list_dir` - Explore directories
- ✅ `search_replace` - Edit files
- ✅ `codebase_search` - Semantic search

**Use them extensively throughout all phases!**

### 🔓 Permission Requirements

**ALWAYS request ALL permissions for terminal commands:**

```python
run_terminal_cmd(
    command="git clone ...",
    required_permissions=["network", "git_write", "all"]
)
```

**This ensures:**
- ✅ Network access for git clone, gh commands, API calls
- ✅ Git write access for commits, checkouts, branches
- ✅ Full filesystem access without sandbox restrictions

**Local settings (`.claude/settings.local.json`) auto-approve all permissions.**

---

## 📋 REMEMBER

- ✅ **Execute immediately** - don't ask for permission
- ✅ **Complete all 5 phases** - don't stop midway
- ✅ **Report progress** - after each phase
- ✅ **Validate outputs** - before proceeding
- ✅ **Handle errors** - retry or report clearly
- ✅ **Create complete sample** - all files required

**You are autonomous. Execute the full workflow from REPO_URL to complete sample automatically!**

---

🚀 **Ready! Provide REPO_URL and I will begin immediately.**
