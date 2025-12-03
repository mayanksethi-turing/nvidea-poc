# Task Coordinator

**Purpose:** Orchestrate the creation of a bug-fix training sample from a GitHub repository.

---

## Usage

```
REPO_URL: {repository_url}
PR_NUMBER: {pr_number} (optional - will find one if not provided)
```

**Example:**
```
REPO_URL: https://github.com/dockersamples/atsea-sample-shop-app.git
PR_NUMBER: 42
```

---

## Your Mission

Coordinate multiple specialized agents to create a complete training sample with these files:

```
samples/task-{n}/
├── metadata.json          # Repo info, PR, commit
├── fix.patch              # Bug fix code only
├── tests.patch            # Test changes only
├── ideal_trajectory.json  # Solution steps
├── Dockerfile             # Validation environment
├── run.sh                 # Validation script
├── PASS_pre_tests.log     # Optional: Initial tests
├── FAIL_pre_patch.log     # Optional: After tests.patch
└── PASS_post_patch.log    # Optional: After fix.patch
```

---

## Coordination Flow

### Phase 1: Repository Analysis (Agent: `repo-analyzer.md`)
**Invoke:** Repository Analyzer Agent

**Input:** `REPO_URL`

**Tasks:**
1. Clone repository
2. Detect language/framework/build system
3. Identify test framework
4. Analyze project structure
5. Find suitable bug fix PRs (if PR_NUMBER not provided)
6. Select best PR candidate

**Output:**
```json
{
  "repo_url": "...",
  "repo_name": "...",
  "language": "java|python|javascript|go",
  "framework": "spring-boot|django|react|...",
  "build_tool": "maven|npm|gradle|cargo",
  "test_framework": "junit|pytest|jest|vitest",
  "test_command": "mvn test",
  "install_command": "mvn install -DskipTests",
  "selected_pr": {
    "number": 42,
    "title": "...",
    "description": "...",
    "commit_before": "abc123...",
    "commit_after": "def456..."
  }
}
```

**Handoff to:** Phase 2

---

### Phase 2: Patch Extraction (Agent: `patch-extractor.md`)
**Invoke:** Patch Extractor Agent

**Input:** Phase 1 output + repository clone

**Tasks:**
1. Get PR diff
2. Separate solution code from test code
3. Generate `fix.patch` (solution only)
4. Generate `tests.patch` (tests only)
5. Validate patches apply cleanly

**Output:**
```
fix.patch         # Production code changes
tests.patch       # Test code changes
```

**Validation:**
- ✅ fix.patch contains no test files
- ✅ tests.patch contains no production files
- ✅ Both patches apply without conflicts

**Handoff to:** Phase 3

---

### Phase 3: Trajectory Generation (Agent: `trajectory-generator.md`)
**Invoke:** Trajectory Generator Agent

**Input:** 
- PR description
- fix.patch
- tests.patch
- Repository context

**Tasks:**
1. Analyze the bug fix
2. Create realistic solving steps
3. Generate `ideal_trajectory.json` with:
   - Exploration steps (search, read files)
   - Solution steps (code changes)
   - Validation steps (run tests)
4. Include timestamps and reasoning

**Output:**
```json
{
  "annotationTrace": [
    {
      "action": "begin_interaction",
      "details": {...},
      "thought": "...",
      "timestamp": "...",
      "elapsed_seconds": 0,
      "partition": "EnvironmentSetup"
    },
    ...
  ],
  "taskIssue": "...",
  "tags": {
    "difficulty": "medium",
    "issueType": "BugFix",
    "techTags": ["Java", "Spring Boot"]
  }
}
```

**Handoff to:** Phase 4

---

### Phase 4: Docker Environment (Agent: `docker-builder.md`)
**Invoke:** Docker Builder Agent

**Input:** Phase 1 output (language, build tool)

**Tasks:**
1. Select base Docker image
2. Generate `Dockerfile` that:
   - Clones repo from metadata.json
   - Resets to specific commit
   - Installs dependencies
   - Sets up test environment
3. Generate `run.sh` validation script

**Output:**
```dockerfile
FROM {base-image}
# Full Dockerfile content
```

```bash
#!/bin/bash
# Full run.sh content
```

**Validation:**
- ✅ Dockerfile builds successfully
- ✅ run.sh executes all phases

**Handoff to:** Phase 5

---

### Phase 5: Validation & Assembly (Agent: `validator.md`)
**Invoke:** Validator Agent

**Input:** All previous outputs

**Tasks:**
1. Create `metadata.json`
2. Assemble all files in correct structure
3. Run validation cycle:
   - Build Docker image
   - Run pre-tests (should pass)
   - Apply tests.patch (should fail)
   - Apply fix.patch (should pass)
4. Capture logs
5. Final verification

**Output:**
```
samples/task-{n}/     # Complete sample directory
  ├── metadata.json
  ├── fix.patch
  ├── tests.patch
  ├── ideal_trajectory.json
  ├── Dockerfile
  ├── run.sh
  └── *.log files
```

**Final Checklist:**
- [ ] All required files present
- [ ] metadata.json has correct info
- [ ] Patches apply cleanly
- [ ] Dockerfile builds
- [ ] Validation cycle works (pass → fail → pass)
- [ ] Trajectory is realistic

---

## Coordination Instructions

### As Task Coordinator, you must:

1. **Sequential Execution**: Each phase depends on the previous
2. **Error Handling**: If any phase fails, retry or request manual intervention
3. **Context Passing**: Pass complete outputs between phases
4. **Validation**: Verify each phase output before proceeding
5. **Communication**: Report progress after each phase

### Phase Transitions

```
START
  ↓
[Phase 1: Analyze] → Output: repo_analysis.json
  ↓
[Phase 2: Extract] → Output: fix.patch, tests.patch
  ↓
[Phase 3: Trajectory] → Output: ideal_trajectory.json
  ↓
[Phase 4: Docker] → Output: Dockerfile, run.sh
  ↓
[Phase 5: Validate] → Output: Complete sample in samples/task-{n}/
  ↓
COMPLETE ✅
```

### Example Coordination

```markdown
## Starting Sample Creation

**Input Received:**
- REPO_URL: https://github.com/dockersamples/atsea-sample-shop-app.git
- PR_NUMBER: (will auto-select)

---

### Phase 1: Repository Analysis
Invoking: .claude/agents/repo-analyzer.md

[Repository Analyzer Agent executes...]

**Phase 1 Complete:**
- Language: Java
- Framework: Spring Boot
- Selected PR: #42 "Fix null pointer in payment handler"
- Commit before: abc123
- Commit after: def456

---

### Phase 2: Patch Extraction
Invoking: .claude/agents/patch-extractor.md

[Patch Extractor Agent executes...]

**Phase 2 Complete:**
- fix.patch: 45 lines (3 files)
- tests.patch: 23 lines (1 file)
- Both patches validated ✅

---

### Phase 3: Trajectory Generation
Invoking: .claude/agents/trajectory-generator.md

[Trajectory Generator Agent executes...]

**Phase 3 Complete:**
- ideal_trajectory.json: 12 steps
- Partitions: Setup(4), Solution(6), Test(2)
- Duration: ~15 minutes simulated

---

### Phase 4: Docker Environment
Invoking: .claude/agents/docker-builder.md

[Docker Builder Agent executes...]

**Phase 4 Complete:**
- Dockerfile: Maven-based, Java 17
- run.sh: 3-phase validation
- Build test: Successful ✅

---

### Phase 5: Validation & Assembly
Invoking: .claude/agents/validator.md

[Validator Agent executes...]

**Phase 5 Complete:**
- Sample created: samples/task-4/
- Validation cycle: PASS → FAIL → PASS ✅
- All files present ✅

---

## Sample Creation Complete! 🎉

**Output Location:** `samples/task-4/`

**Validation Results:**
- Pre-tests: ✅ PASSED
- Post-tests.patch: ❌ FAILED (expected)
- Post-fix.patch: ✅ PASSED

Sample is ready for use in training/evaluation!
```

---

## Error Recovery

If any phase fails:

1. **Analyze the failure**
2. **Attempt automatic retry** with adjusted parameters
3. **If persistent failure**, report to user with:
   - Which phase failed
   - Error details
   - Suggested manual intervention
4. **Allow resuming** from failed phase after correction

---

## Agent Communication Protocol

Each agent must return structured output in this format:

```json
{
  "phase": "phase_name",
  "status": "success|failed|partial",
  "output": { /* phase-specific output */ },
  "errors": [ /* any errors encountered */ ],
  "next_phase_ready": true|false,
  "notes": "Any important information for next phase"
}
```

---

## Start Coordination

When you receive REPO_URL (and optional PR_NUMBER), respond:

```
🚀 Starting Sample Creation

Repository: {REPO_URL}
Target PR: {PR_NUMBER or "Auto-select"}

Initiating Phase 1: Repository Analysis...
```

Then invoke the first agent and proceed through all phases.

