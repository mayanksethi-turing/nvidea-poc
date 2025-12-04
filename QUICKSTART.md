# Quick Start Guide - Metadata Enrichment System

## 🎯 What Was Implemented

A comprehensive metadata enrichment system integrated into your Claude agentic workflow that automatically adds 7 detailed sections to each sample's metadata:

1. **Task Goal** - Problem statement and expected outcome
2. **Failure Mode Analysis** - Detailed classification and root cause
3. **Step-Level Metrics** - Tool calls, wall time, token counts
4. **Diff Semantics** - AST-aware code changes
5. **Test Execution** - Coverage and pass/fail metrics
6. **Navigation Metrics** - Files opened vs edited, precision
7. **Plan & Memory Signals** - Thought count, verification status

---

## 📦 What Changed

### ✅ Removed
- `repo/` folder (1.0GB) - No longer needed as Docker clones repos fresh

### ✅ Added
- `.claude/scripts/enrich_metadata.py` - Single sample enrichment
- `.claude/scripts/batch_enrich.py` - Batch processing
- `README.md` - Comprehensive documentation

### ✅ Moved
- `task-coordinator.md` → `.claude/commands/task-coordinator.md`
- `scripts/` → `.claude/scripts/`

### ✅ Updated
- `.claude/commands/task-coordinator.md` - Added Phase 6 (enrichment)
- `.claude/agents/validator.md` - Added enrichment validation
- `.claude/agents/trajectory-generator.md` - Enhanced capture guide

---

## 🚀 Quick Start

### 1. Enrich a Single Sample

```bash
python3 .claude/scripts/enrich_metadata.py samples/task-16
```

**Output:**
```
📊 Enriching metadata for task-16...
  ├─ Analyzing ideal trajectory...
  ├─ Analyzing failed trajectory...
  ├─ Analyzing patches...
  ├─ Parsing test logs...
  └─ Generating failure analysis...
✅ Enriched metadata saved to samples/task-16/metadata.json
```

### 2. Enrich All Samples

```bash
python3 .claude/scripts/batch_enrich.py
```

### 3. Preview Changes (Dry Run)

```bash
python3 .claude/scripts/batch_enrich.py --dry-run
```

### 4. Enrich Specific Samples

```bash
python3 .claude/scripts/batch_enrich.py --tasks task-1 task-2 task-3
```

---

## 📊 View Enriched Data

### View All Metadata

```bash
cat samples/task-16/metadata.json | python3 -m json.tool
```

### View Specific Section

```bash
# Navigation metrics
cat samples/task-16/metadata.json | jq '.navigationMetrics'

# Step-level metrics
cat samples/task-16/metadata.json | jq '.stepLevelMetrics'

# Failure analysis
cat samples/task-16/metadata.json | jq '.failureModeAnalysis'
```

### Compare Ideal vs Failed

```bash
cat samples/task-16/metadata.json | jq '{
  ideal_steps: .stepLevelMetrics.totalSteps.idealTrajectory,
  failed_steps: .stepLevelMetrics.totalSteps.failedTrajectory,
  ideal_thoughts: .planAndMemorySignals.idealTrajectory.thoughtActionsCount,
  failed_thoughts: .planAndMemorySignals.failedTrajectory.thoughtActionsCount,
  missed_files: .navigationMetrics.failedTrajectory.missedFiles
}'
```

---

## 🎓 Integration with Workflow

The enrichment is now **Phase 6** of the sample creation process:

```
Phase 1: Repository Analysis      (10 min)
Phase 2: Patch Extraction          (15 min)
Phase 3: Trajectory Generation     (60-120 min)
Phase 4: Docker Environment        (20 min)
Phase 5: Validation & Assembly     (30 min)
Phase 6: Metadata Enrichment       (7 min) ⭐ NEW
────────────────────────────────────────────
Total: ~97 minutes per sample
```

### Automatic Enrichment

When using the task-coordinator command:

```
REPO_URL: https://github.com/owner/repo
PR_NUMBER: 42
```

Claude will automatically run enrichment in Phase 6. No manual intervention needed!

---

## 📈 Before vs After

### Before Enrichment
```json
{
  "author": "mayanksethi-turing",
  "repo": "https://github.com/...",
  "head": "abc123...",
  "prNumber": "42",
  "failure": "UI/Styling Error",
  "inputTokens": 8500,
  "outputTokens": 3200
}
```

### After Enrichment
```json
{
  "author": "mayanksethi-turing",
  "repo": "https://github.com/...",
  "head": "abc123...",
  "prNumber": "42",
  "failure": "UI/Styling Error / Z-Index Layer Conflict",
  "inputTokens": 8500,
  "outputTokens": 3200,
  
  "taskGoal": { ... },                    // ⭐ NEW
  "failureModeAnalysis": { ... },         // ⭐ NEW
  "stepLevelMetrics": { ... },            // ⭐ NEW
  "diffSemantics": { ... },               // ⭐ NEW
  "testExecution": { ... },               // ⭐ NEW
  "navigationMetrics": { ... },           // ⭐ NEW
  "planAndMemorySignals": { ... }         // ⭐ NEW
}
```

---

## ✅ Validation

### Check if Sample is Enriched

```bash
# Check for enrichment sections
if grep -q "navigationMetrics" samples/task-16/metadata.json; then
  echo "✅ Enriched"
else
  echo "⚠️  Not enriched"
fi
```

### Check All Samples

```bash
for dir in samples/task-*/; do
  if grep -q "navigationMetrics" "$dir/metadata.json" 2>/dev/null; then
    echo "✅ $(basename $dir)"
  else
    echo "⚠️  $(basename $dir) - needs enrichment"
  fi
done
```

### Verify Enrichment Quality

```bash
python3 -c "
import json

with open('samples/task-16/metadata.json') as f:
    data = json.load(f)

required_sections = [
    'taskGoal',
    'failureModeAnalysis',
    'stepLevelMetrics',
    'diffSemantics',
    'testExecution',
    'navigationMetrics',
    'planAndMemorySignals'
]

present = [s for s in required_sections if s in data]
missing = [s for s in required_sections if s not in data]

print(f'✅ Present: {len(present)}/{len(required_sections)}')
if missing:
    print(f'❌ Missing: {missing}')
else:
    print('✅ All sections present!')
    
# Show metrics
ideal_steps = data['stepLevelMetrics']['totalSteps']['idealTrajectory']
failed_steps = data['stepLevelMetrics']['totalSteps']['failedTrajectory']
print(f'\n📊 Metrics:')
print(f'  Ideal trajectory: {ideal_steps} steps')
print(f'  Failed trajectory: {failed_steps} steps')
print(f'  Edit precision: {data[\"navigationMetrics\"][\"idealTrajectory\"][\"editPrecision\"]}')
"
```

---

## 🔧 Troubleshooting

### Script Not Found

```bash
# Verify script location
ls -la .claude/scripts/

# Should show:
# enrich_metadata.py
# batch_enrich.py
```

### Permission Denied

```bash
# Make scripts executable
chmod +x .claude/scripts/enrich_metadata.py
chmod +x .claude/scripts/batch_enrich.py
```

### Missing Dependencies

```bash
# Check Python version (requires 3.7+)
python3 --version

# All dependencies are standard library - no installs needed!
```

### Enrichment Fails

```bash
# Check if required files exist
ls samples/task-16/

# Required for enrichment:
# - metadata.json (base)
# - ideal_trajectory.json
# - failed_trajectory.json  
# - fix.patch
# - PASS_pre_tests.log (optional)
# - PASS_post_patch.log (optional)
```

---

## 📚 Next Steps

1. **Enrich existing samples:**
   ```bash
   python3 .claude/scripts/batch_enrich.py
   ```

2. **Generate new samples** (auto-enriched):
   ```
   Use task-coordinator command with REPO_URL
   ```

3. **Verify quality:**
   ```bash
   # Check a sample
   cat samples/task-16/metadata.json | jq keys
   ```

4. **Export for training:**
   ```bash
   # All metadata is ready for training pipeline!
   ```

---

## 📖 Documentation

- **Main README:** `/README.md`
- **Task Coordinator:** `.claude/commands/task-coordinator.md`
- **Validator Guide:** `.claude/agents/validator.md`
- **Trajectory Guide:** `.claude/agents/trajectory-generator.md`

---

**Questions?** Check the main README.md or agent documentation in `.claude/agents/`

