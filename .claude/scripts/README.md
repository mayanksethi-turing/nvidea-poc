# Parallel Execution Scripts

This directory contains scripts for running multiple task-coordinator agents in parallel using git worktrees.

## 📋 Overview

When running multiple agents simultaneously to process different repositories, each agent needs its own isolated workspace to prevent:
- Task number collisions
- File overwrites
- Docker image naming conflicts
- Git conflicts

These scripts implement a worktree-based solution with atomic merging.

---

## 🔧 Scripts

### `setup-agent-worktree.sh`

**Purpose:** Create an isolated worktree for a new agent.

**Usage:**
```bash
./.claude/scripts/setup-agent-worktree.sh <repo-name>

# Examples:
./.claude/scripts/setup-agent-worktree.sh tldraw
./.claude/scripts/setup-agent-worktree.sh django-cms
./.claude/scripts/setup-agent-worktree.sh react-router
```

**What it does:**
1. Creates a unique agent ID: `agent-{repo-name}-{timestamp}-{random}`
2. Creates a new git branch: `agent/{agent-id}`
3. Creates a worktree at: `worktrees/{agent-id}/`
4. Creates `.agent-state.json` with agent metadata
5. Displays instructions for next steps

**Output:**
```
✅ Worktree created successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Agent ID:     agent-tldraw-1701234567-abc123
🌿 Branch:       agent/agent-tldraw-1701234567-abc123
📁 Path:         /path/to/worktrees/agent-tldraw-1701234567-abc123
🎯 Target Repo:  tldraw
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### `merge-samples.sh`

**Purpose:** Atomically merge completed samples from worktree to main repo.

**Usage:**
```bash
./.claude/scripts/merge-samples.sh <agent-id>

# Example:
./.claude/scripts/merge-samples.sh agent-tldraw-1701234567-abc123
```

**What it does:**
1. Locates the sample in the worktree
2. Acquires a file lock for atomic operation (prevents race conditions)
3. Determines the next sequential task number
4. Copies sample to `samples/task-N/`
5. Updates metadata with final task number
6. Updates agent state to "merged"
7. Releases the lock

**Features:**
- ✅ **Atomic:** Uses `flock` to prevent multiple merges simultaneously
- ✅ **Safe:** Validates sample exists before merging
- ✅ **Smart:** Adds agent_id and task_number to metadata.json
- ✅ **Informative:** Shows sample info before merging

**Output:**
```
✅ Sample merged successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 Location: samples/task-4
🔢 Task Number: 4
🤖 Agent ID: agent-tldraw-1701234567-abc123
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### `cleanup-agent-worktree.sh`

**Purpose:** Remove a worktree after sample has been merged.

**Usage:**
```bash
./.claude/scripts/cleanup-agent-worktree.sh <agent-id>

# Example:
./.claude/scripts/cleanup-agent-worktree.sh agent-tldraw-1701234567-abc123
```

**What it does:**
1. Shows agent info (target repo, status)
2. Asks for confirmation
3. Removes the worktree directory
4. Deletes the agent branch
5. Cleans up all references

**Safety:**
- ⚠️ Prompts for confirmation before deletion
- ℹ️ Shows agent status to help decide
- ✅ Gracefully handles missing worktrees

**Output:**
```
📋 Agent Info:
   Target Repo: tldraw
   Status: merged

⚠️  Are you sure you want to remove this worktree? (y/N): y
🧹 Removing worktree: agent-tldraw-1701234567-abc123
🌿 Removing branch: agent/agent-tldraw-1701234567-abc123

✅ Cleanup complete!
```

---

## 🚀 Complete Workflow

### Step 1: Setup Worktrees (run in parallel)

**Terminal 1:**
```bash
cd /path/to/nvidea-poc
./.claude/scripts/setup-agent-worktree.sh tldraw
cd worktrees/agent-tldraw-*/
```

**Terminal 2:**
```bash
cd /path/to/nvidea-poc
./.claude/scripts/setup-agent-worktree.sh django
cd worktrees/agent-django-*/
```

**Terminal 3:**
```bash
cd /path/to/nvidea-poc
./.claude/scripts/setup-agent-worktree.sh react
cd worktrees/agent-react-*/
```

---

### Step 2: Run Agents

In each terminal (within the worktree directory):

1. Open Cursor in agent mode
2. Open `.claude/commands/task-coordinator.md`
3. Provide the REPO_URL
4. Let the agent run through all 5 phases

The task-coordinator will automatically detect worktree mode and use unique identifiers.

---

### Step 3: Merge Results

After agents complete, from the **main repo** directory:

```bash
cd /path/to/nvidea-poc

# Merge each sample (one at a time, safely)
./.claude/scripts/merge-samples.sh agent-tldraw-1701234567-abc123
./.claude/scripts/merge-samples.sh agent-django-1701234568-def456
./.claude/scripts/merge-samples.sh agent-react-1701234569-ghi789

# Results will be in:
# samples/task-4/  (from tldraw)
# samples/task-5/  (from django)
# samples/task-6/  (from react)
```

---

### Step 4: Validate and Commit

```bash
# Validate each sample
cd samples/task-4 && ./run.sh && cd ../..
cd samples/task-5 && ./run.sh && cd ../..
cd samples/task-6 && ./run.sh && cd ../..

# Commit to git
git add samples/
git commit -m "Add samples from parallel agent run (task-4, task-5, task-6)"
```

---

### Step 5: Cleanup Worktrees

```bash
# Clean up all worktrees
./.claude/scripts/cleanup-agent-worktree.sh agent-tldraw-1701234567-abc123
./.claude/scripts/cleanup-agent-worktree.sh agent-django-1701234568-def456
./.claude/scripts/cleanup-agent-worktree.sh agent-react-1701234569-ghi789
```

---

## 🔒 Thread Safety

### Problem Solved: Race Conditions

Without these scripts, running agents in parallel would cause:

```
Agent 1: counts 3 tasks → creates task-4
Agent 2: counts 3 tasks → creates task-4  ❌ COLLISION!
Agent 3: counts 3 tasks → creates task-4  ❌ COLLISION!
```

### Solution: Atomic Merging

The `merge-samples.sh` script uses **file locking**:

```bash
# Only ONE merge can happen at a time
(
  flock -x 200  # Acquire exclusive lock
  NEXT_NUM=$(ls -d samples/task-* | wc -l)
  NEXT_NUM=$((NEXT_NUM + 1))
  cp -r worktree-sample samples/task-$NEXT_NUM
) 200>".samples-merge.lock"
```

**Result:**
```
Agent 1 merge: locks → counts 3 → creates task-4 → unlocks
Agent 2 merge: waits → locks → counts 4 → creates task-5 → unlocks
Agent 3 merge: waits → locks → counts 5 → creates task-6 → unlocks
```

✅ **No collisions, sequential task numbers preserved!**

---

## 🏗️ Directory Structure

```
nvidea-poc/
├── .gitignore                # Excludes worktrees/
├── samples/
│   ├── task-1/               # Existing samples
│   ├── task-2/
│   ├── task-3/
│   ├── task-4/               # Merged from agent 1
│   ├── task-5/               # Merged from agent 2
│   └── task-6/               # Merged from agent 3
├── worktrees/                # Gitignored, temporary
│   ├── agent-tldraw-.../     # Agent 1 workspace
│   │   ├── .agent-state.json
│   │   ├── samples/
│   │   │   └── task-tldraw-1701234567/
│   │   └── ... (full repo copy)
│   ├── agent-django-.../     # Agent 2 workspace
│   └── agent-react-.../      # Agent 3 workspace
├── .claude/
│   ├── scripts/              # Management scripts
│   │   ├── setup-agent-worktree.sh
│   │   ├── merge-samples.sh
│   │   ├── cleanup-agent-worktree.sh
│   │   └── README.md
│   ├── docs/
│   │   └── ARCHITECTURE_DIAGRAM.txt
│   ├── commands/
│   │   └── task-coordinator.md
│   └── agents/
└── .samples-merge.lock       # Temporary lock file
```

---

## 💡 Tips

1. **Unique naming:** Always provide a descriptive repo name to `setup-agent-worktree.sh`
2. **Merge order:** Doesn't matter! The lock ensures correct numbering
3. **Check status:** Run `./.claude/scripts/cleanup-agent-worktree.sh` without args to list all worktrees
4. **Failed agents:** If an agent fails, just cleanup the worktree and try again
5. **Disk space:** Worktrees are full repo copies, ensure you have enough space

---

## 🛠️ Dependencies

- **Required:**
  - `git` (with worktree support, Git 2.5+)
  - `bash` 4.0+
  - `flock` (usually pre-installed on Linux/macOS)

- **Optional:**
  - `jq` (for JSON parsing, enhances metadata updates)
    - Install: `brew install jq` (macOS) or `apt-get install jq` (Linux)

---

## 🐛 Troubleshooting

### "Failed to acquire lock"

Another merge is in progress. Wait 60 seconds or check:
```bash
ls -la .samples-merge.lock
# If stale (old timestamp), remove it:
rm .samples-merge.lock
```

### "Worktree not found"

List available worktrees:
```bash
ls worktrees/
# or
./scripts/cleanup-agent-worktree.sh
```

### "flock: command not found"

Install util-linux:
```bash
# macOS (already included)
# Linux
sudo apt-get install util-linux
```

### Docker image name conflicts

Each sample's `run.sh` generates unique image names automatically:
```
nvidea-poc-tldraw-task-tldraw-1701234567
```

If you see conflicts, ensure you're running the updated `run.sh` from the scripts.

---

## 📚 Related Documentation

- Main coordination: `.claude/commands/task-coordinator.md`
- Docker setup: `.claude/agents/docker-builder.md`
- Validation: `.claude/agents/validator.md`
- Main README: `.claude/README.md`

---

## 🆕 New Quality Assurance Scripts

### `validate-trajectory.sh` ⭐

**Purpose:** Validate trajectory files for authenticity and quality.

**Usage:**
```bash
./.claude/scripts/validate-trajectory.sh samples/task-1/ideal_trajectory.json --type ideal
./.claude/scripts/validate-trajectory.sh samples/task-1/failed_trajectory.json --type failed
```

**What it checks:**
- JSON syntax and schema compliance
- Action count (warns if < 15 for real trajectories)
- Timestamp authenticity (millisecond precision check)
- Round elapsed times detection (synthetic indicator)
- Details richness (search results, command outputs)
- Thought quality (specific vs generic)
- Required actions (begin/end_interaction, test execution)
- Partition distribution
- failureMode field for failed trajectories

**Exit codes:**
- `0`: Passed (may have warnings for improvement)
- `1`: Failed validation (must fix errors)

---

### `count-tokens.sh` ⭐

**Purpose:** Estimate input/output tokens for trajectory files to populate metadata.json.

**Usage:**
```bash
./.claude/scripts/count-tokens.sh samples/task-1/ideal_trajectory.json
```

**What it calculates:**
- **Input tokens:** Problem statement + exploration thoughts + file reads + search results
- **Output tokens:** Solution thoughts + code changes + test outputs + completion summary
- **Complexity assessment:** Simple/medium/complex classification
- **Action statistics:** Counts by type (searches, edits, commands, etc.)
- **Duration analysis:** Total elapsed time

**Output provides ready-to-use values:**
```
For metadata.json, use:
  "inputTokens": 13600,
  "outputTokens": 1900
```

---

### `validate-sample.sh` (Enhanced)

**New feature:** Added `--dry-run` mode for fast validation without Docker operations.

**Usage:**
```bash
# Full validation (includes Docker build/test)
./.claude/scripts/validate-sample.sh samples/task-1

# Dry-run mode (skips Docker, faster)
./.claude/scripts/validate-sample.sh samples/task-1 --dry-run
```

**Dry-run mode validates:**
- File presence and structure
- JSON syntax
- Patch format
- Metadata completeness
- Trajectory authenticity (calls validate-trajectory.sh)
- *(Skips Docker build and test execution)*

---

## 🔄 Complete Quality Workflow

### When Creating a New Sample:

1. **Author trajectories** (see `.claude/docs/TRAJECTORY_AUTHORING_GUIDE.md`)

2. **Validate trajectories:**
   ```bash
   ./.claude/scripts/validate-trajectory.sh ideal_trajectory.json --type ideal
   ./.claude/scripts/validate-trajectory.sh failed_trajectory.json --type failed
   ```

3. **Estimate tokens:**
   ```bash
   ./.claude/scripts/count-tokens.sh ideal_trajectory.json
   # Copy the output values to metadata.json
   ```

4. **Quick validation:**
   ```bash
   ./.claude/scripts/validate-sample.sh samples/task-N --dry-run
   ```

5. **Full validation:**
   ```bash
   ./.claude/scripts/validate-sample.sh samples/task-N
   ```

### Batch Validation:

```bash
# Validate all ideal trajectories
for traj in samples/task-*/ideal_trajectory.json; do
    echo "Validating $traj"
    ./.claude/scripts/validate-trajectory.sh "$traj" --type ideal
done

# Validate all failed trajectories  
for traj in samples/task-*/failed_trajectory.json; do
    echo "Validating $traj"
    ./.claude/scripts/validate-trajectory.sh "$traj" --type failed
done

# Quick validation of all samples
for task in samples/task-*/; do
    echo "Validating $task"
    ./.claude/scripts/validate-sample.sh "$task" --dry-run
done
```

---

## 📖 Additional Documentation

- **Trajectory Authoring Guide:** `.claude/docs/TRAJECTORY_AUTHORING_GUIDE.md`
- **Trajectory Schema:** `.claude/schemas/trajectory-schema.json`
- **Metadata Schema:** `.claude/schemas/metadata-schema.md`
- **Improvements Summary:** `.claude/docs/WORKFLOW_IMPROVEMENTS.md`

