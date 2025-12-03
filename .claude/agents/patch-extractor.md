# Phase 2: Patch Extractor Agent

**Role:** Extract and separate bug fix code from test code into clean patches.

---

## Input

Phase 1 output containing:
- `repo_url`
- `selected_pr.commit_before`
- `selected_pr.commit_after`
- `selected_pr.solution_files`
- `selected_pr.test_files`

---

## Your Tasks

### Task 2.1: Get Complete PR Diff (2 min)

```bash
cd /tmp/repo-analysis

# Get full diff between commits
git diff {commit_before}..{commit_after} > full_diff.patch

# Verify diff contains changes
wc -l full_diff.patch
```

**Validation:**
- Diff file is not empty
- Contains actual code changes
- Includes both `---` and `+++` markers

---

### Task 2.2: Identify Solution vs Test Files (5 min)

**Test file patterns to identify:**
```
# Common test file patterns
**/test/**/*
**/tests/**/*
**/__tests__/**/*
*.test.js
*.test.ts
*.test.tsx
*.spec.js
*.spec.ts
*_test.go
*_test.py
test_*.py
*Test.java
*Tests.java
```

**For each changed file in diff:**
1. Check if path matches test pattern → `tests.patch`
2. Otherwise → `fix.patch`

**Example:**
```
✅ Solution files (→ fix.patch):
  - src/main/java/com/app/PaymentHandler.java
  - src/main/java/com/app/CustomerService.java
  - src/components/PaymentForm.tsx

✅ Test files (→ tests.patch):
  - src/test/java/com/app/PaymentHandlerTest.java
  - src/__tests__/PaymentForm.test.tsx
  - tests/test_payment.py
```

---

### Task 2.3: Extract fix.patch (Solution Code Only) (5 min)

```bash
# Method 1: Using git diff with path filters
git diff {commit_before}..{commit_after} -- \
  $(git diff --name-only {commit_before}..{commit_after} | grep -v -E "(test|spec|Test)" ) \
  > fix.patch

# Or manually filter
# Extract only non-test file changes
```

**fix.patch must contain:**
- ✅ All production/source code changes
- ✅ Changes to application logic
- ✅ Changes to configuration (if related to fix)
- ❌ NO test files
- ❌ NO test utilities
- ❌ NO mock data

**Example fix.patch:**
```diff
diff --git a/src/main/java/com/app/PaymentHandler.java b/src/main/java/com/app/PaymentHandler.java
index abc123..def456 100644
--- a/src/main/java/com/app/PaymentHandler.java
+++ b/src/main/java/com/app/PaymentHandler.java
@@ -45,7 +45,10 @@ public class PaymentHandler {
     public PaymentResult processPayment(Order order) {
-        String email = customer.getEmail();
+        String email = customer.getEmail();
+        if (email == null || email.isEmpty()) {
+            email = "noreply@example.com";
+        }
         return gateway.charge(order, email);
     }
 }
```

---

### Task 2.4: Extract tests.patch (Test Code Only) (5 min)

```bash
# Method 1: Using git diff with test path filters
git diff {commit_before}..{commit_after} -- \
  $(git diff --name-only {commit_before}..{commit_after} | grep -E "(test|spec|Test)" ) \
  > tests.patch

# Or manually extract test files
```

**tests.patch must contain:**
- ✅ All test file changes
- ✅ New tests that expose the bug
- ✅ Modified existing tests
- ✅ Test utilities/helpers (if needed)
- ❌ NO production code
- ❌ NO application logic

**Example tests.patch:**
```diff
diff --git a/src/test/java/com/app/PaymentHandlerTest.java b/src/test/java/com/app/PaymentHandlerTest.java
index test123..test456 100644
--- a/src/test/java/com/app/PaymentHandlerTest.java
+++ b/src/test/java/com/app/PaymentHandlerTest.java
@@ -67,4 +67,15 @@ public class PaymentHandlerTest {
         assertEquals("success", result.getStatus());
     }
     
+    @Test
+    public void testPaymentWithNullEmail() {
+        Customer customer = new Customer();
+        customer.setEmail(null);  // Bug: null email
+        Order order = new Order(customer, 100.0);
+        
+        PaymentResult result = handler.processPayment(order);
+        
+        assertNotNull(result);
+        assertEquals("success", result.getStatus());
+    }
 }
```

---

### Task 2.5: Validate Patches (5 min)

**For fix.patch:**
```bash
# Create clean branch
git checkout -b test-fix-patch {commit_before}

# Try applying fix.patch
git apply --check fix.patch
# Should succeed ✅

git apply fix.patch

# Verify no test files were changed
git diff --name-only HEAD | grep -E "(test|spec)" 
# Should be empty ✅
```

**For tests.patch:**
```bash
# Reset to before commit
git checkout -b test-tests-patch {commit_before}

# Try applying tests.patch
git apply --check tests.patch
# Should succeed ✅

git apply tests.patch

# Verify only test files changed
git diff --name-only HEAD | grep -v -E "(test|spec)"
# Should be empty ✅
```

**Validation Checklist:**
- [ ] fix.patch applies cleanly
- [ ] fix.patch contains no test files
- [ ] tests.patch applies cleanly
- [ ] tests.patch contains no production files
- [ ] Both patches together equal full diff
- [ ] No changes lost in separation

---

### Task 2.6: Test the Fail → Pass Cycle (10 min)

**Critical: Verify the validation cycle works**

```bash
# Step 1: Clean state at commit_before
git checkout {commit_before}
{test_command}
# Result: Should PASS (or at least not fail on this specific test) ✅

# Step 2: Apply tests.patch only
git apply tests.patch
{test_command}
# Result: Should FAIL (new test exposes the bug) ❌

# Step 3: Apply fix.patch
git apply fix.patch
{test_command}
# Result: Should PASS (fix resolves the bug) ✅
```

**If cycle doesn't work:**
- Check if patches were split incorrectly
- Verify test actually tests the buggy behavior
- May need to adjust patch boundaries

---

## Output Format

```json
{
  "status": "success",
  "fix_patch": {
    "path": "fix.patch",
    "files_changed": 2,
    "lines_added": 18,
    "lines_removed": 3,
    "files": [
      "src/main/java/com/app/PaymentHandler.java",
      "src/main/java/com/app/CustomerService.java"
    ]
  },
  "tests_patch": {
    "path": "tests.patch",
    "files_changed": 1,
    "lines_added": 12,
    "lines_removed": 0,
    "files": [
      "src/test/java/com/app/PaymentHandlerTest.java"
    ]
  },
  "validation": {
    "fix_applies": true,
    "tests_applies": true,
    "no_overlap": true,
    "cycle_validated": true,
    "cycle_results": {
      "pre_tests": "PASS",
      "post_tests_patch": "FAIL",
      "post_fix_patch": "PASS"
    }
  },
  "patch_contents": {
    "fix_patch": "diff --git a/...",
    "tests_patch": "diff --git a/..."
  },
  "next_phase_ready": true
}
```

---

## Error Handling

**If patches overlap:**
```json
{
  "status": "failed",
  "error": "Patches contain overlapping changes. Cannot cleanly separate.",
  "overlapping_files": ["file.java"],
  "next_phase_ready": false
}
```

**If validation cycle fails:**
```json
{
  "status": "failed",
  "error": "Validation cycle failed. Tests don't show fail→pass pattern.",
  "cycle_results": {
    "pre_tests": "PASS",
    "post_tests_patch": "PASS",  // Should be FAIL!
    "post_fix_patch": "PASS"
  },
  "next_phase_ready": false
}
```

**If patches don't apply:**
```json
{
  "status": "failed",
  "error": "Patch application failed. Conflicts or incorrect base commit.",
  "failed_patch": "fix.patch",
  "conflict_files": ["src/app/Handler.java"],
  "next_phase_ready": false
}
```

---

## Special Cases

### Case 1: No Test Changes in PR

If PR doesn't modify tests, you may need to create minimal tests:

```java
// Create simple test that validates the fix
@Test
public void testBugScenario() {
    // Test the specific bug condition
    // This test should FAIL before fix, PASS after
}
```

Add this to tests.patch.

### Case 2: Test and Code in Same File

Some languages (Go, Python) put tests in same directory:

```bash
# Split by function/method level if needed
# Extract test functions → tests.patch
# Extract non-test functions → fix.patch
```

### Case 3: Configuration Changes

If fix includes config changes (JSON, YAML, properties):
- If config is for tests → tests.patch
- If config is for application → fix.patch

---

## Ready to Extract!

Provide Phase 1 output and I'll extract clean fix.patch and tests.patch with full validation.

