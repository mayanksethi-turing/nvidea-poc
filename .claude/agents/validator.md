# Phase 5: Validator Agent

**Role:** Assemble all components, validate the complete sample, and ensure quality.

---

## Input

All previous phase outputs:
- Phase 1: Repository analysis
- Phase 2: Patches (fix.patch, tests.patch)
- Phase 3: Trajectory (ideal_trajectory.json)
- Phase 4: Docker files (Dockerfile, run.sh)

---

## Your Tasks

### Task 5.1: Create metadata.json (10 min)

**Generate metadata file with DETAILED failure mode flagging:**

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

**Fields explained:**
- `author`: **ALWAYS use "mayanksethi-turing"** (GitHub handle)
- `repo`: Full GitHub repository URL
- `head`: Commit SHA before the fix (this is what we clone and test against)
- `prNumber`: Pull request number as string
- `failure`: **SPECIFIC failure mode classification** (see below)
- `inputTokens`: Estimated tokens for problem statement + exploration (calculate from trajectory)
- `outputTokens`: Estimated tokens for solution + verification (calculate from trajectory)

---

#### Failure Mode Classification (REQUIRED)

**DO NOT use generic labels like "BugFix"!**

Choose the most specific failure mode from these categories:

**Logic Errors:**
- `Logic Error / Null Pointer Exception` - Missing null/undefined checks
- `Logic Error / Infinite Loop` - Loop termination issues
- `Logic Error / Infinite Redirect Loop` - Navigation/routing loops
- `Logic Error / Off-by-One Error` - Array/index boundary issues
- `Logic Error / Race Condition` - Timing/concurrency issues
- `Logic Error / Incorrect Conditional` - Wrong boolean logic

**Type/Schema Errors:**
- `Schema Data Type Error / Type Mismatch` - Wrong data types in schema
- `Type Error / Missing Type Conversion` - Failed type casting
- `Type Error / Incorrect Interface Implementation` - Wrong API signatures

**Integration Errors:**
- `Integration Error / Missing Context Propagation` - Context not passed through layers
- `Integration Error / Dependency Injection Failure` - DI container issues
- `Integration Error / API Contract Violation` - Mismatched API expectations
- `Integration Error / Tight Component Coupling` - Components too dependent on each other

**UI/Frontend Errors:**
- `CSS Inconsistency / Cross-Browser Compatibility Issue` - Browser-specific rendering
- `UI Error / State Management Bug` - Incorrect state updates
- `UI Error / Component Lifecycle Issue` - Mount/unmount problems
- `UI Error / Missing Event Handler` - Unhandled user interactions

**Configuration Errors:**
- `Config Error / Environment Variable Missing` - Missing env vars
- `Config Error / Incorrect Default Values` - Wrong defaults

**Verification Failures (for failed trajectories):**
- `Incomplete Solution / Inadequate Verification` - Didn't run tests
- `Incomplete Solution / Partial Fix` - Fixed symptom not root cause
- `Incomplete Solution / Missing Edge Cases` - Didn't handle all scenarios

---

#### Token Count Estimation

**Calculate from trajectory files:**

```bash
# Input tokens (problem statement + exploration):
# - begin_interaction thought
# - All exploration action thoughts
# - File content reads (estimate 100 tokens per file opened)

# Output tokens (solution + verification):
# - Solution action thoughts
# - Code changes (count lines * 10)
# - Test action thoughts
# - end_interaction summary

# Rough estimation formula:
inputTokens = (thought_count * 50) + (files_opened * 100) + (problem_statement_words * 1.3)
outputTokens = (code_lines_changed * 10) + (solution_thoughts * 50) + (test_output_estimate)
```

**Typical ranges:**
- Simple fix: 1500-3000 input, 800-1500 output
- Medium fix: 3000-5000 input, 1500-3000 output
- Complex fix: 5000-10000 input, 3000-6000 output

---

#### Example metadata.json

**Simple Schema Fix:**
```json
{
  "author": "mayanksethi-turing",
  "repo": "https://github.com/dockersamples/atsea-sample-shop-app",
  "head": "abc123...",
  "prNumber": "60",
  "failure": "Schema Data Type Error / Type Mismatch",
  "inputTokens": 2500,
  "outputTokens": 1200
}
```

**Complex Context Propagation:**
```json
{
  "author": "mayanksethi-turing",
  "repo": "https://github.com/bxcodec/go-clean-arch",
  "head": "7e2d3a2b...",
  "prNumber": "9",
  "failure": "Integration Error / Missing Context Propagation",
  "inputTokens": 8500,
  "outputTokens": 4200
}
```

**React Component Issue:**
```json
{
  "author": "mayanksethi-turing",
  "repo": "https://github.com/tldraw/tldraw",
  "head": "8e28283d...",
  "prNumber": "7007",
  "failure": "Integration Error / Tight Component Coupling",
  "inputTokens": 13600,
  "outputTokens": 1900
}
```

---

### Task 5.2: Create Sample Directory Structure (3 min)

```bash
# Determine next task number
cd samples
NEXT_NUM=$(ls -d task-* 2>/dev/null | wc -l | xargs expr 1 +)
mkdir -p samples/task-$NEXT_NUM

# Directory structure
samples/task-{N}/
├── metadata.json           # With detailed failure mode & tokens
├── fix.patch               # Bug fix code only
├── tests.patch             # Test changes only  
├── ideal_trajectory.json   # How to solve correctly
├── failed_trajectory.json  # How agents commonly fail (REQUIRED)
├── Dockerfile              # Validation environment
├── run.sh                  # Validation script
├── PASS_pre_tests.log      # Initial test run WITH COVERAGE
├── FAIL_pre_patch.log      # After tests.patch (should fail)
└── PASS_post_patch.log     # After fix.patch (should pass) WITH COVERAGE
```

---

### Task 5.2.5: Create failed_trajectory.json (15 min)

**REQUIRED: Every sample must have both ideal and failed trajectories.**

The failed trajectory demonstrates common failure modes an AI agent might encounter:

#### Purpose of Failed Trajectory
- Shows realistic debugging failures
- Demonstrates anti-patterns to avoid
- Provides training data for failure detection
- Contrasts with ideal trajectory

#### Common Failure Patterns to Model

**1. Incomplete Verification (Most Common)**
```json
{
  "annotationTrace": [
    // ... exploration and solution actions (same as ideal) ...
    {
      "action": "end_interaction",
      "details": {
        "commandType": "END_SESSION",
        "context": "Fix applied",
        "payload": {}
      },
      "thought": "The changes have been made. The bug should be fixed now.",
      "partition": "Completion"
    }
    // MISSING: execute_terminal_command to run tests!
  ]
}
```

**2. Partial Fix (Fixed Symptom Not Root Cause)**
```json
{
  "action": "find_and_replace_code",
  "thought": "Adding a try-catch to handle the error",
  // Wrong: Catching exception instead of fixing null check
}
```

**3. Wrong File Modified**
```json
{
  "action": "find_and_replace_code",
  "details": {
    "context": "/app/src/utils/helper.js",  // Wrong file!
    // Should be /app/src/handlers/payment.js
  }
}
```

**4. Incomplete Refactoring**
```json
// Changed interface but not all implementations
{
  "action": "find_and_replace_code",
  "thought": "Updated the interface to accept context",
  // MISSING: Updates to all implementing classes
}
```

#### Generate Failed Trajectory

1. **Copy ideal_trajectory.json structure**
2. **Choose failure mode that matches the bug type:**
   - Logic errors → Incomplete verification
   - Multi-file changes → Incomplete refactoring
   - Schema changes → Wrong type assumption
3. **Remove or modify critical actions:**
   - Remove test execution
   - Skip verification steps
   - Make incorrect assumptions in thoughts
4. **Adjust thoughts to show flawed reasoning:**
   - "This should work" instead of "Let me verify this works"
   - "The error is handled" instead of "The root cause is fixed"

#### Failed Trajectory Template

```json
{
  "annotationTrace": [
    {
      "action": "begin_interaction",
      "details": { /* same as ideal */ },
      "thought": "I'll fix this quickly by addressing the immediate error.",
      "partition": "EnvironmentSetup"
    },
    // Exploration: Maybe fewer steps, missed key file
    // Solution: Partial fix or wrong approach
    // Test: MISSING or skipped
    {
      "action": "end_interaction",
      "details": {
        "commandType": "END_SESSION",
        "context": "Applied fix",
        "payload": {}
      },
      "thought": "The fix has been applied. Moving on to the next task.",
      "partition": "Completion"
      // Note: No verification that tests pass!
    }
  ],
  "taskIssue": "{ same as ideal }",
  "tags": {
    "difficulty": "{ same as ideal }",
    "issueType": "BugFix",
    "techTags": [ /* same as ideal */ ],
    "failureMode": "Incomplete Verification"  // ADD THIS
  }
}
```

#### Validation Checklist for failed_trajectory.json

- [ ] Same problem statement as ideal_trajectory
- [ ] Demonstrates realistic failure pattern
- [ ] Thoughts show flawed reasoning (but not obviously wrong)
- [ ] Missing verification or test execution
- [ ] `failureMode` tag added to tags section
- [ ] Would actually fail to fix the bug if executed

---

### Task 5.3: Copy All Files to Sample Directory (2 min)

```bash
SAMPLE_DIR="samples/task-$NEXT_NUM"

# Copy metadata
cp metadata.json $SAMPLE_DIR/

# Copy patches
cp fix.patch $SAMPLE_DIR/
cp tests.patch $SAMPLE_DIR/

# Copy trajectory
cp ideal_trajectory.json $SAMPLE_DIR/

# Copy Docker files
cp Dockerfile $SAMPLE_DIR/
cp run.sh $SAMPLE_DIR/

# Make run.sh executable
chmod +x $SAMPLE_DIR/run.sh
```

---

### Task 5.4: Validate File Integrity (5 min)

**Check all required files exist:**

```bash
cd $SAMPLE_DIR

# Required files checklist
FILES=(
  "metadata.json"
  "fix.patch"
  "tests.patch"
  "ideal_trajectory.json"
  "Dockerfile"
  "run.sh"
)

for file in "${FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "❌ Missing: $file"
    exit 1
  fi
done
echo "✅ All required files present"
```

**Validate file formats:**

```bash
# metadata.json is valid JSON
jq . metadata.json > /dev/null && echo "✅ metadata.json valid" || echo "❌ metadata.json invalid"

# ideal_trajectory.json is valid JSON
jq . ideal_trajectory.json > /dev/null && echo "✅ trajectory valid" || echo "❌ trajectory invalid"

# Patches are valid git diffs
head -1 fix.patch | grep -q "^diff --git" && echo "✅ fix.patch valid" || echo "❌ fix.patch invalid"
head -1 tests.patch | grep -q "^diff --git" && echo "✅ tests.patch valid" || echo "❌ tests.patch invalid"

# run.sh is executable
[ -x run.sh ] && echo "✅ run.sh executable" || echo "❌ run.sh not executable"
```

---

### Task 5.5: Run Full Validation Cycle (20-30 min)

**This is the most critical step!**

```bash
cd $SAMPLE_DIR

echo "Starting validation cycle..."
./run.sh
```

**Expected output:**
```
======================================
Building Docker Image
======================================
[docker build output...]
✅ Image built successfully

======================================
Phase 1: Running Pre-Tests (Should PASS)
======================================
✅ Pre-tests PASSED

======================================
Phase 2: Applying tests.patch
======================================
✅ tests.patch applied

======================================
Phase 3: Running Tests After tests.patch (Should FAIL)
======================================
✅ Tests FAILED as expected

======================================
Phase 4: Applying fix.patch
======================================
✅ fix.patch applied

======================================
Phase 5: Running Tests After fix.patch (Should PASS)
======================================
✅ Post-fix tests PASSED

======================================
Validation Complete
======================================
```

**Validation must show:**
1. ✅ Pre-tests: **PASS** (or at least don't fail on the specific test)
2. ✅ After tests.patch: **FAIL** (new test exposes bug)
3. ✅ After fix.patch: **PASS** (fix resolves bug)

**This is the "fail→pass" pattern that validates the sample!**

---

### Task 5.6: Verify Log Files (5 min)

```bash
# Check logs were created
ls -lh *.log

# Verify log contents
echo "=== Pre-tests Log ==="
tail -20 PASS_pre_tests.log

echo "=== Pre-patch Log (should show failure) ==="
tail -20 FAIL_pre_patch.log

echo "=== Post-patch Log (should show success) ==="
tail -20 PASS_post_patch.log
```

**Look for:**
- Test execution output
- Pass/fail indicators
- Error messages (in FAIL log)
- Success messages (in PASS logs)

---

### Task 5.6.5: Verify Code Coverage Reports (REQUIRED) (5 min)

**CRITICAL: All PASS logs must include code coverage reports**

```bash
echo "======================================"
echo "Validating Coverage Reports"
echo "======================================"

# Check PASS_pre_tests.log for coverage
if grep -qi "coverage\|% Cov\|% Stmts\|% Branch\|Statements\|Functions\|Lines" PASS_pre_tests.log; then
    echo "✅ Coverage report found in PASS_pre_tests.log"
else
    echo "❌ ERROR: No coverage report in PASS_pre_tests.log"
    echo "   The test command must include coverage flags!"
    exit 1
fi

# Check PASS_post_patch.log for coverage
if grep -qi "coverage\|% Cov\|% Stmts\|% Branch\|Statements\|Functions\|Lines" PASS_post_patch.log; then
    echo "✅ Coverage report found in PASS_post_patch.log"
else
    echo "❌ ERROR: No coverage report in PASS_post_patch.log"
    echo "   The test command must include coverage flags!"
    exit 1
fi

# Display coverage summary from logs
echo ""
echo "=== Coverage from PASS_pre_tests.log ==="
grep -i "coverage\|% Stmts\|Statements" PASS_pre_tests.log | head -10

echo ""
echo "=== Coverage from PASS_post_patch.log ==="
grep -i "coverage\|% Stmts\|Statements" PASS_post_patch.log | head -10

echo ""
echo "✅ All coverage reports validated"
```

**Coverage validation checklist:**
- [ ] PASS_pre_tests.log contains "Coverage" or percentage metrics
- [ ] PASS_post_patch.log contains "Coverage" or percentage metrics
- [ ] Reports show statement/branch/function/line coverage
- [ ] Reports are human-readable text (not just XML)
- [ ] Coverage percentages are visible

**Language-specific patterns to look for:**

**JavaScript/TypeScript (Jest/Vitest):**
- Look for: "Coverage report", "% Stmts", "% Branch", "% Funcs", "% Lines"
- Example: `Statements   : 88.8%`

**Python (pytest):**
- Look for: "coverage:", "Stmts", "Miss", "Cover"
- Example: `pretix/api/models.py    88    5    94%`

**Go:**
- Look for: "coverage:", "ok", "%"
- Example: `ok  	github.com/repo/pkg	0.123s	coverage: 85.5% of statements`

**Java (JaCoCo):**
- Look for: "JaCoCo", "Instructions", "Branches", "Lines"

**If coverage is missing:**
1. Check run.sh uses correct test command with coverage flags
2. Verify language-specific coverage tool is installed in Dockerfile
3. Ensure coverage reports to terminal/text (not just files)
4. Refer to `.claude/coverage-reference.md` for correct commands

---

### Task 5.7: Quality Checks (10 min)

**Check 1: Patch Quality**
```bash
# Verify patches are clean
cat fix.patch | grep "^@@" | wc -l   # Number of hunks
cat tests.patch | grep "^@@" | wc -l

# Ensure no merge conflicts
grep -q "<<<<<" fix.patch && echo "❌ Merge conflict in fix.patch" || echo "✅ No conflicts"
grep -q "<<<<<" tests.patch && echo "❌ Merge conflict in tests.patch" || echo "✅ No conflicts"
```

**Check 2: Trajectory Quality**
```bash
# Validate trajectory structure
jq '.annotationTrace | length' ideal_trajectory.json  # Should be 10-30 actions
jq '.annotationTrace[0].action' ideal_trajectory.json  # Should be "begin_interaction"
jq '.annotationTrace[-1].action' ideal_trajectory.json  # Should be "end_interaction"
jq '.taskIssue' ideal_trajectory.json  # Should have issue description
```

**Check 3: Metadata Accuracy**
```bash
# Verify metadata fields
jq -r '.repo' metadata.json  # Should be valid URL
jq -r '.head' metadata.json  # Should be valid commit SHA (40 chars)
jq -r '.prNumber' metadata.json  # Should be number
```

**Check 4: Dockerfile Quality**
```bash
# Check Dockerfile has required sections
grep -q "FROM" Dockerfile && echo "✅ Has base image"
grep -q "COPY metadata.json" Dockerfile && echo "✅ Copies metadata"
grep -q "git clone" Dockerfile && echo "✅ Clones repo"
grep -q "git reset --hard" Dockerfile && echo "✅ Checks out commit"
```

---

### Task 5.8: Compare with Sample References (5 min)

**Study existing samples for quality:**

```bash
# Compare structure
ls samples/task-1/
ls samples/task-2/
ls samples/task-3/

# Compare file sizes (rough guide)
du -h samples/task-1/ideal_trajectory.json  # Typical: 50-200KB
du -h samples/task-1/fix.patch              # Typical: 1-10KB
du -h samples/task-1/tests.patch            # Typical: 1-5KB
```

**Quality indicators:**
- Trajectory has 15-25 actions
- fix.patch is 20-200 lines
- tests.patch is 10-100 lines
- Dockerfile is 25-50 lines
- run.sh is 40-80 lines

---

### Task 5.9: Final Checklist (3 min)

```
Sample Validation Checklist:

File Presence:
[ ] metadata.json exists and is valid JSON
[ ] fix.patch exists and is valid diff
[ ] tests.patch exists and is valid diff
[ ] ideal_trajectory.json exists and is valid JSON
[ ] Dockerfile exists
[ ] run.sh exists and is executable

Content Quality:
[ ] metadata.json has all required fields
[ ] fix.patch contains only solution code
[ ] tests.patch contains only test code
[ ] trajectory has begin_interaction and end_interaction
[ ] trajectory actions have realistic timestamps
[ ] Dockerfile uses appropriate base image
[ ] run.sh has all 5 phases

Validation Results:
[ ] Docker image builds successfully
[ ] Pre-tests PASS (or don't fail on specific test)
[ ] After tests.patch: Tests FAIL ⚠️ (expected)
[ ] After fix.patch: Tests PASS ✅
[ ] Log files generated (3 files)

Documentation:
[ ] taskIssue in trajectory describes the bug clearly
[ ] Patch comments explain changes (if any)
[ ] run.sh output is clear and informative
```

---

### Task 5.10: Generate Summary Report (5 min)

```json
{
  "sample_id": "task-4",
  "sample_path": "samples/task-4",
  "status": "validated",
  "created_at": "2024-03-15T10:00:00Z",
  "repository": {
    "url": "https://github.com/dockersamples/atsea-sample-shop-app.git",
    "pr_number": 42,
    "commit_before": "abc123...",
    "commit_after": "def456..."
  },
  "technology": {
    "language": "Java",
    "framework": "Spring Boot",
    "build_tool": "Maven",
    "test_framework": "JUnit"
  },
  "files": {
    "metadata": {
      "size_bytes": 234,
      "valid": true
    },
    "fix_patch": {
      "size_bytes": 1456,
      "files_changed": 2,
      "lines_added": 18,
      "lines_removed": 3
    },
    "tests_patch": {
      "size_bytes": 892,
      "files_changed": 1,
      "lines_added": 12,
      "lines_removed": 0
    },
    "trajectory": {
      "size_bytes": 45678,
      "actions": 18,
      "duration_seconds": 750
    },
    "dockerfile": {
      "size_bytes": 1234,
      "base_image": "maven:3.9-eclipse-temurin-17"
    }
  },
  "validation": {
    "docker_build": "success",
    "pre_tests": "PASS",
    "post_tests_patch": "FAIL",
    "post_fix_patch": "PASS",
    "cycle_correct": true
  },
  "quality_score": {
    "completeness": 10,
    "accuracy": 10,
    "documentation": 9,
    "total": 29
  },
  "issues": [],
  "next_steps": [
    "Sample ready for training/evaluation"
  ]
}
```

---

## Error Recovery

### Issue 1: Validation Cycle Wrong

**Problem:** Tests don't follow PASS → FAIL → PASS pattern

**Diagnosis:**
```bash
# Check each log
cat PASS_pre_tests.log | grep -i "test.*pass\|test.*fail"
cat FAIL_pre_patch.log | grep -i "test.*pass\|test.*fail"
cat PASS_post_patch.log | grep -i "test.*pass\|test.*fail"
```

**Common causes:**
- tests.patch doesn't introduce a failing test
- fix.patch incomplete
- Test framework not detecting changes

**Solution:**
- Revisit Phase 2 (patch extraction)
- May need to adjust test to explicitly test buggy behavior
- Verify patches apply in correct order

### Issue 2: Docker Build Fails

**Problem:** `docker build` errors out

**Diagnosis:**
```bash
# Try building manually to see full error
docker build -t test-sample . 2>&1 | tee build.log
```

**Common causes:**
- Missing system dependencies
- Wrong base image
- Repository clone fails
- Dependency installation fails

**Solution:**
- Add missing dependencies to Dockerfile
- Verify repository is public
- Check commit hash is valid
- Revisit Phase 4 (Docker builder)

### Issue 3: Patches Don't Apply

**Problem:** `git apply` fails

**Diagnosis:**
```bash
# Test patch application
git apply --check fix.patch 2>&1
git apply --check tests.patch 2>&1
```

**Common causes:**
- Wrong base commit in metadata.json
- Patches have incorrect paths
- File has changed between commits

**Solution:**
- Verify head commit in metadata.json
- Check patch file paths are correct
- Regenerate patches from correct commits
- Revisit Phase 2

---

## Output Format

```json
{
  "status": "success",
  "sample_id": "task-4",
  "sample_path": "samples/task-4",
  "files_created": [
    "samples/task-4/metadata.json",
    "samples/task-4/fix.patch",
    "samples/task-4/tests.patch",
    "samples/task-4/ideal_trajectory.json",
    "samples/task-4/Dockerfile",
    "samples/task-4/run.sh",
    "samples/task-4/PASS_pre_tests.log",
    "samples/task-4/FAIL_pre_patch.log",
    "samples/task-4/PASS_post_patch.log"
  ],
  "validation_results": {
    "all_files_present": true,
    "docker_build": "success",
    "pre_tests": "PASS",
    "post_tests_patch": "FAIL",
    "post_fix_patch": "PASS",
    "cycle_validated": true
  },
  "quality_checks": {
    "metadata_valid": true,
    "patches_clean": true,
    "trajectory_complete": true,
    "dockerfile_builds": true,
    "logs_generated": true
  },
  "summary": "Sample task-4 created and validated successfully. Ready for use.",
  "next_phase_ready": false,
  "completion": true
}
```

---

## Success Criteria

Sample is considered **complete and valid** when:

✅ All 6 required files exist  
✅ All files pass format validation  
✅ Docker image builds successfully  
✅ Validation cycle shows PASS → FAIL → PASS  
✅ Log files generated with correct content  
✅ No errors in quality checks  
✅ Trajectory is realistic and complete  
✅ Patches are clean and apply correctly  

---

## Ready to Validate!

Provide all phase outputs and I'll assemble, validate, and deliver a complete training sample!

