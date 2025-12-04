# NVIDIA POC - Agentic Bug-Fix Sample Generator

Autonomous system for creating high-quality bug-fix training samples from GitHub repositories with comprehensive metadata enrichment.

---

## 📁 Project Structure

```
nvidea-poc/
├── .claude/
│   ├── commands/
│   │   └── task-coordinator.md       # Main orchestrator command
│   ├── agents/
│   │   ├── validator.md              # Quality assurance guidelines
│   │   └── trajectory-generator.md   # Event capture guide
│   ├── scripts/
│   │   ├── enrich_metadata.py        # Metadata enrichment script
│   │   └── batch_enrich.py           # Batch processing script
│   └── settings.local.json           # Bypass permissions config
│
├── samples/
│   ├── task-1/
│   │   ├── metadata.json             # ENRICHED with comprehensive metrics
│   │   ├── fix.patch
│   │   ├── tests.patch
│   │   ├── ideal_trajectory.json
│   │   ├── failed_trajectory.json    # REQUIRED
│   │   ├── Dockerfile
│   │   ├── run.sh
│   │   ├── PASS_pre_tests.log
│   │   ├── FAIL_pre_patch.log
│   │   └── PASS_post_patch.log
│   ├── task-2/
│   └── ...
│
└── README.md                         # This file
```

---

## 🚀 Quick Start

### Generate a New Sample

```bash
# In Claude with task-coordinator command loaded:
REPO_URL: https://github.com/owner/repo
PR_NUMBER: 42

# Claude will automatically:
# 1. Analyze repository (10 min)
# 2. Extract patches (15 min)
# 3. Capture trajectories (60-120 min)
# 4. Build Docker environment (20 min)
# 5. Validate & assemble (30 min)
# 6. Enrich metadata (7 min)
```

### Enrich Existing Samples

```bash
# Single sample
python3 .claude/scripts/enrich_metadata.py samples/task-16

# All samples
python3 .claude/scripts/batch_enrich.py

# Specific samples
python3 .claude/scripts/batch_enrich.py --tasks task-1 task-2 task-3

# Dry run (preview without changes)
python3 .claude/scripts/batch_enrich.py --dry-run
```

---

## 📊 Enhanced Metadata Schema

Each `metadata.json` is automatically enriched with:

### 1. Task Goal
```json
"taskGoal": {
  "summary": "Fix toast visibility issue",
  "problemStatement": "Toast messages appearing behind other elements",
  "expectedOutcome": "Toasts appear above all UI elements"
}
```

### 2. Failure Mode Analysis
```json
"failureModeAnalysis": {
  "failureType": "UI/Styling Error / Z-Index Layer Conflict",
  "failureCategory": "Incomplete Implementation",
  "failureDescription": "...",
  "rootCause": "Agent identified surface issue but didn't expand scope",
  "consequence": "Toasts may not appear in some contexts",
  "issuesMissed": [
    "Did not move ToastContainer to global scope",
    "Only fixed 2 of 4 deployment services"
  ]
}
```

### 3. Step-Level Metrics
```json
"stepLevelMetrics": {
  "totalSteps": {
    "idealTrajectory": 26,
    "failedTrajectory": 15
  },
  "toolCallBreakdown": {
    "idealTrajectory": {
      "thought": 6,
      "search": 3,
      "read_file": 7,
      "edit_file": 8
    }
  },
  "wallTime": {
    "idealTrajectory": {
      "durationSeconds": 1038.746
    }
  },
  "tokenCounts": {
    "inputTokens": 8500,
    "outputTokens": 3200,
    "totalTokens": 11700
  }
}
```

### 4. Diff Semantics
```json
"diffSemantics": {
  "filesChanged": 8,
  "totalLinesAdded": 54,
  "totalLinesRemoved": 34,
  "modifiedFiles": [...],
  "changedSymbols": [
    {
      "file": "app/root.tsx",
      "symbol": "toastAnimation",
      "type": "function"
    }
  ]
}
```

### 5. Test Execution
```json
"testExecution": {
  "hasAutomatedTests": true,
  "testType": "automated",
  "preTestStatus": {
    "totalTests": 118,
    "passed": 118,
    "coverage": 92.6
  },
  "postPatchStatus": {...}
}
```

### 6. Navigation Metrics
```json
"navigationMetrics": {
  "idealTrajectory": {
    "filesOpened": 8,
    "filesEdited": 8,
    "editPrecision": 1.0,
    "filesOpenedList": [...],
    "filesEditedList": [...]
  },
  "failedTrajectory": {
    "editPrecision": 1.0,
    "missedFiles": [
      "app/root.tsx",
      "app/components/chat/Chat.client.tsx"
    ]
  }
}
```

### 7. Plan & Memory Signals
```json
"planAndMemorySignals": {
  "idealTrajectory": {
    "thoughtActionsCount": 6,
    "planAdherence": 1.0,
    "verificationStepsCompleted": true
  },
  "failedTrajectory": {
    "thoughtActionsCount": 4,
    "planAdherence": 0.5,
    "verificationStepsCompleted": false
  }
}
```

---

## 🎯 Sample Requirements

### Mandatory Files

Every sample must include:

| File | Purpose | Requirement |
|------|---------|-------------|
| `metadata.json` | Enriched metadata | ✅ ENRICHED with 7 sections |
| `fix.patch` | Solution code | ✅ Production code only |
| `tests.patch` | Test code | ✅ Test files only |
| `ideal_trajectory.json` | Success pattern | ✅ From real agent run (15+ actions) |
| `failed_trajectory.json` | Failure pattern | ✅ From different real agent run |
| `Dockerfile` | Validation env | ✅ Self-contained |
| `run.sh` | Validation script | ✅ Executable |
| `PASS_pre_tests.log` | Initial state | ✅ With coverage |
| `FAIL_pre_patch.log` | After tests | ✅ Expected failure |
| `PASS_post_patch.log` | After fix | ✅ With coverage |

### Metadata Quality Standards

**Required Fields:**
- `author`: "mayanksethi-turing" (NOT "system-generated")
- `failure`: Specific mode (NOT generic "BugFix")
- `inputTokens`: Calculated estimate (NOT 0)
- `outputTokens`: Calculated estimate (NOT 0)

**Enrichment Sections (Auto-generated):**
- ✅ `taskGoal`
- ✅ `failureModeAnalysis`
- ✅ `stepLevelMetrics`
- ✅ `diffSemantics`
- ✅ `testExecution`
- ✅ `navigationMetrics`
- ✅ `planAndMemorySignals`

### Trajectory Authenticity

**Critical Requirements:**
- ✅ Captured from REAL agent runs (not manually written)
- ✅ Different timestamps proving different sessions
- ✅ Millisecond precision (e.g., `2025-12-01T18:27:05.146Z`)
- ✅ Rich details (search results, command outputs)
- ✅ Natural time gaps between actions
- ✅ Failed trajectory has `failureMode` in tags

---

## 🔧 Scripts Reference

### enrich_metadata.py

Enriches a single sample's metadata.

```bash
python3 .claude/scripts/enrich_metadata.py samples/task-16
python3 .claude/scripts/enrich_metadata.py samples/task-16 --output custom_path.json
```

**What it does:**
1. Parses ideal and failed trajectories
2. Analyzes fix.patch and tests.patch
3. Extracts test execution metrics from logs
4. Computes navigation metrics
5. Generates failure mode analysis
6. Writes enriched metadata.json

### batch_enrich.py

Enriches multiple samples at once.

```bash
# All samples
python3 .claude/scripts/batch_enrich.py

# Preview mode (no changes)
python3 .claude/scripts/batch_enrich.py --dry-run

# Specific samples
python3 .claude/scripts/batch_enrich.py --tasks task-1 task-2 task-3
```

**Output:**
```
Processing 18 samples...
======================================================================

📂 task-1
📊 Enriching metadata for task-1...
  ├─ Analyzing ideal trajectory...
  ├─ Analyzing failed trajectory...
  ├─ Analyzing patches...
  ├─ Parsing test logs...
  └─ Generating failure analysis...
✅ Enriched metadata saved to samples/task-1/metadata.json

...

======================================================================
✅ Successfully enriched: 18
```

---

## 📋 Workflow Phases

### Phase 1: Repository Analysis (10 min)
- Clone repository
- Detect tech stack (language, framework, build tool)
- Find suitable bug-fix PR
- Extract commit hashes

### Phase 2: Patch Extraction (15 min)
- Get PR diff
- Separate test vs solution files
- Create fix.patch (production code)
- Create tests.patch (test code)
- Validate pass → fail → pass cycle

### Phase 3: Trajectory Generation (60-120 min)
- Run agent to capture ideal trajectory (30-60 min)
- Run agent to capture failed trajectory (30-60 min)
- Validate both are from different runs
- Ensure rich details and timestamps

### Phase 4: Docker Environment (20 min)
- Generate Dockerfile for tech stack
- Create run.sh validation script
- Test Docker build

### Phase 5: Validation & Assembly (30 min)
- Create metadata.json
- Assemble all files in samples/task-N/
- Run validation cycle
- Generate test logs

### Phase 6: Metadata Enrichment (7 min) ⭐ NEW
- Run enrich_metadata.py
- Add 7 enrichment sections
- Validate completeness

**Total Time: ~97 minutes per sample**

---

## 🎓 Training Data Quality

### What Makes a Good Sample?

1. **Realistic Bug**: From actual PR, not synthetic
2. **Clear Fix**: 20-200 lines changed
3. **Testable**: Has automated tests
4. **Reproducible**: Docker validation passes
5. **Authentic Trajectories**: Captured from real agent runs
6. **Rich Metadata**: All 7 enrichment sections present

### Failure Mode Categories

Samples are classified by specific failure types:

- **Logic Errors**: Infinite loops, race conditions, off-by-one
- **Type/Schema Errors**: Type mismatches, null pointers
- **Integration Errors**: Tight coupling, missing injection
- **UI/Styling Errors**: Z-index conflicts, broken layouts
- **Performance Errors**: Memory leaks, N+1 queries
- **State Management**: Stale closures, missing updates
- **Validation/Security**: Unsanitized input, XSS
- **Error Handling**: Unhandled exceptions, silent failures

---

## 📈 Usage Examples

### View Enriched Metadata

```bash
# Pretty print entire metadata
cat samples/task-16/metadata.json | python3 -m json.tool

# View specific section
cat samples/task-16/metadata.json | jq '.navigationMetrics'

# Compare ideal vs failed
cat samples/task-16/metadata.json | jq '{
  ideal: .stepLevelMetrics.totalSteps.idealTrajectory,
  failed: .stepLevelMetrics.totalSteps.failedTrajectory,
  delta: (.stepLevelMetrics.totalSteps.idealTrajectory - .stepLevelMetrics.totalSteps.failedTrajectory)
}'
```

### Validate Sample

```bash
cd samples/task-16
./run.sh

# Expected output:
# ✅ Phase 1: Pre-Tests - PASSED
# ✅ Phase 2: After tests.patch - FAILED (expected)
# ✅ Phase 3: After fix.patch - PASSED
```

### Check Sample Quality

```bash
# Verify all files present
ls samples/task-16/

# Check trajectory authenticity
python3 -c "
import json

with open('samples/task-16/ideal_trajectory.json') as f:
    ideal = json.load(f)
with open('samples/task-16/failed_trajectory.json') as f:
    failed = json.load(f)

ideal_ts = ideal['annotationTrace'][0]['timestamp']
failed_ts = failed['annotationTrace'][0]['timestamp']

print(f'Ideal started:  {ideal_ts}')
print(f'Failed started: {failed_ts}')
print(f'Different runs: {ideal_ts != failed_ts}')
print(f'Ideal actions:  {len(ideal[\"annotationTrace\"])}')
print(f'Failed actions: {len(failed[\"annotationTrace\"])}')
"
```

---

## 🔍 Troubleshooting

### Issue: Enrichment script fails

```bash
# Check Python version (requires 3.7+)
python3 --version

# Check if sample has required files
ls -la samples/task-16/

# Run with verbose error messages
python3 .claude/scripts/enrich_metadata.py samples/task-16 2>&1
```

### Issue: Missing failed_trajectory.json

Every sample MUST have a failed trajectory. If missing:

1. Review agent logs from sample creation
2. Re-run agent with constraints to capture failure
3. See `.claude/agents/trajectory-generator.md` for guidance

### Issue: Trajectories have same timestamps

This means failed trajectory was copied from ideal (NOT ALLOWED).

Solution:
- Delete failed_trajectory.json
- Run agent again in different session
- Capture authentic failure pattern

---

## 📚 Documentation

- **`.claude/commands/task-coordinator.md`** - Main orchestration workflow
- **`.claude/agents/validator.md`** - Quality assurance guidelines
- **`.claude/agents/trajectory-generator.md`** - Event capture guide
- **This README** - Overview and usage

---

## 📊 Current Status

```bash
# Count samples
ls -d samples/task-* | wc -l

# Check which have enriched metadata
for dir in samples/task-*/; do
  if grep -q "navigationMetrics" "$dir/metadata.json" 2>/dev/null; then
    echo "✅ $dir"
  else
    echo "⚠️  $dir (not enriched)"
  fi
done
```

---

## 🎯 Next Steps

1. **Generate more samples**: Use task-coordinator with new repos
2. **Enrich existing samples**: Run batch_enrich.py
3. **Quality review**: Validate authenticity of trajectories
4. **Export dataset**: Prepare for training pipeline

---

**Created by:** Mayank Sethi - Turing
**Last Updated:** December 2025

