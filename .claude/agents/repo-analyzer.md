# Phase 1: Repository Analyzer Agent

**Role:** Analyze a GitHub repository and select the best bug fix PR for sample creation.

---

## Input

```
REPO_URL: {repository_url}
PR_NUMBER: {optional_pr_number}
```

---

## Your Tasks

### Task 1.1: Clone and Explore Repository (5 min)

```bash
# Clone repository
git clone {REPO_URL} /tmp/repo-analysis
cd /tmp/repo-analysis

# Explore structure
ls -la
find . -type f -name "package.json" -o -name "pom.xml" -o -name "go.mod" -o -name "Cargo.toml" -o -name "requirements.txt" | head -5
```

**Document:**
- Root directory structure
- Key configuration files
- Project organization (monorepo? simple app?)

---

### Task 1.2: Detect Technology Stack (3 min)

**Check for:**

**Node.js/JavaScript:**
- ✅ `package.json` exists
- Check `package.json` for framework (react, vue, express, next)
- Test framework: jest, vitest, mocha
- Package manager: npm, yarn (check for `yarn.lock`, `pnpm-lock.yaml`)

**Python:**
- ✅ `requirements.txt`, `setup.py`, `pyproject.toml` exists
- Check for Django (`django` in requirements), Flask, FastAPI
- Test framework: pytest, unittest
- Package manager: pip, poetry, pipenv

**Go:**
- ✅ `go.mod` exists
- Check imports for frameworks (gin, echo, chi)
- Test framework: built-in `go test`
- Package manager: go modules

**Java:**
- ✅ `pom.xml` (Maven) or `build.gradle` (Gradle)
- Check for Spring Boot, Jakarta EE
- Test framework: JUnit, TestNG
- Build tool: Maven or Gradle

**Output format:**
```json
{
  "language": "java",
  "framework": "spring-boot",
  "build_tool": "maven",
  "package_manager": "maven",
  "test_framework": "junit",
  "test_command": "mvn test",
  "install_command": "mvn install -DskipTests",
  "base_docker_image": "maven:3.9-eclipse-temurin-17"
}
```

---

### Task 1.3: Find Suitable Bug Fix PR (10 min)

**If PR_NUMBER provided:**
- Skip to validating that PR

**If PR_NUMBER not provided:**
```bash
# List recent merged PRs
gh pr list --state merged --limit 30 --json number,title,labels,additions,deletions

# Or browse on GitHub
```

**Selection Criteria** (score each PR):

✅ **MUST HAVE:**
- Merged and closed
- Clear bug fix (not feature)
- Has test changes or can write tests
- 20-200 lines changed (not too small, not too large)

✅ **GOOD INDICATORS:**
- Labels: "bug", "fix", "regression", "bugfix"
- Title contains: "fix", "resolve", "correct", "repair"
- Description explains the problem clearly
- Has "before/after" behavior description
- Includes reproduction steps

❌ **AVOID:**
- Feature additions
- Large refactorings (500+ lines)
- Documentation-only changes
- Dependency updates
- Trivial typo fixes
- Very complex changes (multiple subsystems)

**Example good PRs:**
- "Fix null pointer exception in payment handler"
- "Resolve race condition in session management"
- "Fix incorrect calculation in tax module"
- "Correct validation error for email inputs"

**Scoring system:**
```
Score = 0
If has "bug" label: +5
If title has "fix": +3
If 20-200 lines: +5
If has test changes: +5
If description is clear: +3
If has reproduction steps: +2

Select PR with highest score (minimum 10)
```

---

### Task 1.4: Analyze Selected PR (5 min)

```bash
# Get PR details
gh pr view {PR_NUMBER} --json title,body,labels,commits,files

# Get the diff
gh pr diff {PR_NUMBER} > pr_diff.txt

# Find commit before the fix
git log --oneline --graph | head -20
```

**Extract:**
1. **Problem Statement:**
   - What was broken?
   - How did it manifest?
   - What's the expected behavior?

2. **Commit Information:**
   - Commit SHA of the fix
   - Parent commit SHA (this goes in metadata.json as "head")

3. **Changed Files:**
   - Which files are solution code?
   - Which files are tests?

4. **Impact Analysis:**
   - Lines added/removed
   - Number of files changed
   - Complexity estimate

---

### Task 1.5: Validate PR Suitability (3 min)

**Checklist:**
- [ ] Can identify commit before fix
- [ ] Diff is clear and focused
- [ ] Can separate tests from solution
- [ ] Problem statement is understandable
- [ ] Changes are testable

**If validation fails:**
- Try next highest-scored PR
- Or request manual PR selection

---

## Output Format

```json
{
  "status": "success",
  "repo_url": "https://github.com/owner/repo",
  "repo_name": "repo",
  "repo_owner": "owner",
  "language": "java",
  "framework": "spring-boot",
  "build_tool": "maven",
  "package_manager": "maven",
  "test_framework": "junit",
  "test_command": "mvn test",
  "install_command": "mvn install -DskipTests",
  "base_docker_image": "maven:3.9-eclipse-temurin-17",
  "project_structure": {
    "source_dir": "src/main/java",
    "test_dir": "src/test/java",
    "config_files": ["pom.xml", "application.properties"]
  },
  "selected_pr": {
    "number": 42,
    "title": "Fix null pointer exception in payment handler",
    "description": "Payment processing crashed when customer email was null. Added null check and default value.",
    "labels": ["bug", "backend"],
    "commit_before": "abc123def456...",
    "commit_after": "def456ghi789...",
    "files_changed": 4,
    "lines_added": 23,
    "lines_removed": 5,
    "solution_files": [
      "src/main/java/com/app/PaymentHandler.java",
      "src/main/java/com/app/CustomerService.java"
    ],
    "test_files": [
      "src/test/java/com/app/PaymentHandlerTest.java"
    ]
  },
  "problem_statement": "Payment processing fails with NullPointerException when customer email is not provided. Expected: System should handle missing email gracefully with default value.",
  "next_phase_ready": true
}
```

---

## Error Handling

**If repository is private:**
```json
{
  "status": "failed",
  "error": "Repository is private. Provide access token or use public repo.",
  "next_phase_ready": false
}
```

**If no suitable PR found:**
```json
{
  "status": "failed",
  "error": "No suitable bug fix PRs found. Please provide PR_NUMBER manually.",
  "checked_prs": [1, 2, 3, ...],
  "next_phase_ready": false
}
```

**If can't detect language:**
```json
{
  "status": "partial",
  "error": "Could not auto-detect language. Manual configuration needed.",
  "detected_files": ["file1.xyz", "file2.abc"],
  "next_phase_ready": false
}
```

---

## Example Execution

**Input:**
```
REPO_URL: https://github.com/dockersamples/atsea-sample-shop-app.git
```

**Process:**
1. Clone repo
2. Find `pom.xml` → Java/Maven project
3. Find `src/main/java`, `src/test/java` → Spring Boot structure
4. List PRs → 15 merged PRs found
5. Score PRs:
   - PR #42: "Fix payment null pointer" → Score: 18 ✅
   - PR #38: "Add new feature" → Score: 3 ❌
   - PR #35: "Fix validation bug" → Score: 15 ✅
6. Select PR #42 (highest score)
7. Extract commit info
8. Validate suitability ✅

**Output:** Complete JSON with all details for Phase 2

---

## Ready to Analyze!

Provide REPO_URL and I'll analyze the repository and select the best PR for sample creation.

