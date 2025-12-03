# Claude Agent System for Bug Fix Sample Creation

This directory contains the **Task Coordinator** and specialized **Phase Agents** for automatically creating training samples from GitHub repository bug fixes.

---

## 🎯 Purpose

Generate training samples for AI coding agents by:
1. Analyzing GitHub repositories
2. Extracting bug fix PRs
3. Creating validation environments
4. Documenting solution trajectories

---

## 📁 Structure

```
.claude/
├── commands/
│   └── task-coordinator.md   # Main orchestrator (START HERE)
└── agents/
    ├── repo-analyzer.md      # Phase 1: Analyze repository
    ├── patch-extractor.md    # Phase 2: Extract patches
    ├── trajectory-generator.md # Phase 3: Generate solution steps
    ├── docker-builder.md     # Phase 4: Create Docker environment
    └── validator.md          # Phase 5: Validate complete sample
```

---

## 🚀 Quick Start

### Running in Claude (AI Agent)

1. **Open `commands/task-coordinator.md` in Claude interface**

2. **Provide repository URL:**
   ```
   REPO_URL: https://github.com/owner/repo.git
   PR_NUMBER: 42  (optional)
   ```

3. **Claude will orchestrate all phases automatically:**
   - Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
   - Each phase invokes the corresponding agent
   - Progress reported after each phase

4. **Result:** Complete sample in `samples/task-N/`

---

## 📋 What Gets Created

Each sample contains:

```
samples/task-N/
├── metadata.json           # Repo info, PR, commit
├── fix.patch               # Bug fix code only
├── tests.patch             # Test changes only  
├── ideal_trajectory.json   # Solution steps
├── Dockerfile              # Validation environment
├── run.sh                  # Validation script
├── PASS_pre_tests.log      # Initial test run
├── FAIL_pre_patch.log      # After tests.patch (should fail)
└── PASS_post_patch.log     # After fix.patch (should pass)
```

---

## 🔄 Workflow

### Phase 1: Repository Analysis (5-10 min)
**Agent:** `repo-analyzer.md`

- Clone repository
- Detect language/framework
- Find suitable bug fix PR
- Extract commit information

**Output:** Repository metadata, selected PR details

---

### Phase 2: Patch Extraction (10-15 min)
**Agent:** `patch-extractor.md`

- Get PR diff
- Separate solution code from tests
- Generate `fix.patch` and `tests.patch`
- Validate patches apply cleanly

**Output:** Two clean patches

---

### Phase 3: Trajectory Generation (15-25 min)
**Agent:** `trajectory-generator.md`

- Analyze the bug fix
- Create realistic solving steps
- Generate `ideal_trajectory.json`
- Include exploration, solution, and test phases

**Output:** Complete trajectory JSON

---

### Phase 4: Docker Environment (10-20 min)
**Agent:** `docker-builder.md`

- Select appropriate base image
- Generate `Dockerfile`
- Create `run.sh` validation script
- Test Docker build

**Output:** Dockerfile and validation script

---

### Phase 5: Validation & Assembly (20-30 min)
**Agent:** `validator.md`

- Create `metadata.json`
- Assemble all files
- Run validation cycle (PASS → FAIL → PASS)
- Verify quality

**Output:** Complete validated sample

---

## ✅ Validation Cycle

Every sample must pass this cycle:

```bash
./run.sh
```

**Expected results:**
1. **Pre-tests:** ✅ PASS (original code works)
2. **After tests.patch:** ❌ FAIL (new test exposes bug)
3. **After fix.patch:** ✅ PASS (fix resolves bug)

This proves the sample correctly captures a fail→pass scenario.

---

## 🎓 Sample References

Study existing samples to understand quality standards:

- `samples/task-1/` - TypeScript/React (tldraw useContext fix)
- `samples/task-2/` - Go (context propagation)
- `samples/task-3/` - Python/Django (URL linkification)

---

## 🛠️ Supported Technologies

### Languages
- ✅ Java (Maven, Gradle)
- ✅ JavaScript/TypeScript (npm, yarn)
- ✅ Python (pip, pytest)
- ✅ Go (go modules)

### Test Frameworks
- ✅ JUnit, TestNG (Java)
- ✅ Jest, Vitest (JavaScript)
- ✅ Pytest, unittest (Python)
- ✅ go test (Go)

### Frameworks
- ✅ Spring Boot, Jakarta EE
- ✅ React, Vue, Next.js
- ✅ Django, Flask, FastAPI
- ✅ Gin, Echo, Chi

---

## 📊 Quality Metrics

Good samples have:

- **Clarity:** Bug is well-defined and understandable
- **Scope:** 20-200 lines changed (focused but substantial)
- **Testability:** Clear fail→pass validation
- **Realism:** Trajectory reflects actual debugging process
- **Completeness:** All required files present and valid

---

## 🔧 Troubleshooting

### Docker build fails
- Check base image is correct
- Verify dependencies are available
- Review `docker-builder.md` for guidance

### Validation cycle wrong
- Ensure tests.patch introduces failing test
- Verify fix.patch resolves the issue
- Check patches apply in correct order

### Patches don't apply
- Confirm correct base commit in metadata.json
- Verify patch file paths are correct
- Review `patch-extractor.md` for help

---

## 📝 Manual Overrides

If automatic agent fails, you can:

1. **Manually select PR:**
   ```
   PR_NUMBER: 42
   ```

2. **Skip to specific phase:**
   - Invoke phase agent directly
   - Provide previous phase outputs

3. **Adjust parameters:**
   - Modify Dockerfile base image
   - Change test commands
   - Customize validation script

---

## 🎯 Best Practices

### For Task Coordinator:
- Let phases complete before proceeding
- Validate outputs between phases
- Report errors clearly

### For Phase Agents:
- Follow output format strictly
- Validate all inputs before processing
- Provide detailed error messages
- Include recovery suggestions

### For Sample Quality:
- Choose focused bug fixes (not large refactors)
- Ensure clear problem statement
- Verify realistic trajectory
- Test validation cycle thoroughly

---

## 📚 Learn More

Each agent prompt contains:
- Detailed instructions
- Examples and templates
- Validation checklists
- Error handling guidance
- Output formats

Start with `task-coordinator.md` to understand the full workflow.

---

## 🤝 Usage Tips

1. **First time:** Read through all agent prompts to understand capabilities
2. **Running:** Use task-coordinator.md with REPO_URL
3. **Stuck:** Check error messages and agent-specific troubleshooting
4. **Quality:** Compare output with existing samples
5. **Iteration:** Don't hesitate to regenerate phases if quality is low

---

## 📍 Current Status

- ✅ 3 sample tasks in `samples/` directory
- ✅ Multi-language support
- ✅ Automated validation
- ✅ Complete documentation
- ✅ Ready for production use

---

**Ready to create samples? Start with `commands/task-coordinator.md`!** 🚀

