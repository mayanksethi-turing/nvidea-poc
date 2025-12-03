# Phase 3: Trajectory Generator Agent

**Role:** Create realistic trajectory files showing both successful and failed AI agent problem-solving approaches.

**⚠️ CRITICAL: You MUST generate BOTH files:**
- ✅ `ideal_trajectory.json` - Perfect solution trajectory
- ✅ `failed_trajectory.json` - Realistic failure trajectory

**Both files are REQUIRED for every task sample.**

---

## Input

- Phase 1 output (problem statement, PR details)
- Phase 2 output (fix.patch, tests.patch)
- Repository context

---

## Understanding Trajectories

A trajectory is a **recording of an AI agent's problem-solving process**. It shows:
- What the agent explored (searches, file reads)
- What the agent thought (reasoning)
- What the agent did (code edits, commands)
- When things happened (timestamps, durations)

**Study these samples:**
- `samples/task-1/ideal_trajectory.json` (TypeScript/React - useContext fix)
- `samples/task-2/ideal_trajectory.json` (Go - context propagation)
- `samples/task-3/ideal_trajectory.json` (Python/Django - URL linkification)

---

## Trajectory Structure

```json
{
  "annotationTrace": [
    // Array of actions in chronological order
  ],
  "taskIssue": "Description of the bug/issue",
  "tags": {
    "difficulty": "easy|medium|hard",
    "issueType": "BugFix|Feature|Refactor",
    "techTags": ["Java", "Spring Boot", "JUnit"]
  }
}
```

---

## Action Types & Format

### 1. begin_interaction
**Purpose:** Start the debugging session

```json
{
  "action": "begin_interaction",
  "details": {
    "commandType": "INTERACT_WITH_ENVIRONMENT",
    "context": "I will investigate the null pointer exception in payment processing by examining the relevant code and tests.",
    "payload": null
  },
  "thought": "The issue states that payment processing crashes when customer email is null. I need to find the PaymentHandler class and understand how email is being used.",
  "timestamp": "2024-03-15T10:00:00Z",
  "elapsed_seconds": 0,
  "duration_seconds": 5,
  "partition": "EnvironmentSetup"
}
```

### 2. search_string (or search_dir)
**Purpose:** Search codebase for relevant code

```json
{
  "action": "search_string",
  "details": {
    "commandType": "SEARCH",
    "context": "PaymentHandler",
    "payload": {
      "searchQuery": "class PaymentHandler",
      "directory": "/app/src"
    }
  },
  "thought": "I need to locate the PaymentHandler class where the null pointer exception is occurring.",
  "timestamp": "2024-03-15T10:00:05Z",
  "elapsed_seconds": 5,
  "duration_seconds": 2,
  "partition": "Exploration"
}
```

### 3. open_file
**Purpose:** Read a file to understand the code

```json
{
  "action": "open_file",
  "details": {
    "commandType": "READ_FILE",
    "context": "/app/src/main/java/com/app/PaymentHandler.java",
    "payload": {
      "filePath": "/app/src/main/java/com/app/PaymentHandler.java",
      "lineStart": 1,
      "lineEnd": 100
    }
  },
  "thought": "Reading PaymentHandler.java to find where customer.getEmail() is called and identify the null pointer issue.",
  "timestamp": "2024-03-15T10:00:07Z",
  "elapsed_seconds": 7,
  "duration_seconds": 3,
  "partition": "Exploration"
}
```

### 4. find_and_replace_code
**Purpose:** Make code changes

```json
{
  "action": "find_and_replace_code",
  "details": {
    "commandType": "EDIT_FILE",
    "context": "/app/src/main/java/com/app/PaymentHandler.java",
    "payload": {
      "filePath": "/app/src/main/java/com/app/PaymentHandler.java",
      "oldCode": "    public PaymentResult processPayment(Order order) {\n        String email = customer.getEmail();\n        return gateway.charge(order, email);",
      "newCode": "    public PaymentResult processPayment(Order order) {\n        String email = customer.getEmail();\n        if (email == null || email.isEmpty()) {\n            email = \"noreply@example.com\";\n        }\n        return gateway.charge(order, email);"
    }
  },
  "thought": "Adding null check for email before using it. If email is null or empty, use a default value to prevent NullPointerException.",
  "timestamp": "2024-03-15T10:00:10Z",
  "elapsed_seconds": 10,
  "duration_seconds": 8,
  "partition": "Solution"
}
```

### 5. execute_terminal_command
**Purpose:** Run tests or build commands

```json
{
  "action": "execute_terminal_command",
  "details": {
    "commandType": "RUN_COMMAND",
    "context": "mvn test -Dtest=PaymentHandlerTest",
    "payload": {
      "command": "mvn test -Dtest=PaymentHandlerTest",
      "workingDirectory": "/app"
    }
  },
  "thought": "Running the test to verify the fix resolves the null pointer exception.",
  "timestamp": "2024-03-15T10:00:18Z",
  "elapsed_seconds": 18,
  "duration_seconds": 12,
  "partition": "Test"
}
```

### 6. end_interaction
**Purpose:** Complete the debugging session

```json
{
  "action": "end_interaction",
  "details": {
    "commandType": "END_SESSION",
    "context": "Successfully fixed null pointer exception by adding null check for customer email.",
    "payload": null
  },
  "thought": "The fix has been applied and verified. All tests pass. The payment handler now gracefully handles null email values.",
  "timestamp": "2024-03-15T10:00:30Z",
  "elapsed_seconds": 30,
  "duration_seconds": 0,
  "partition": "Completion"
}
```

---

## Partitions

Organize actions into logical phases:

1. **EnvironmentSetup** (0-5 sec)
   - `begin_interaction`
   - Initial context setting

2. **Exploration** (5-120 sec)
   - Search for relevant files
   - Read code to understand problem
   - Identify root cause
   - Usually 3-8 actions

3. **Solution** (120-600 sec)
   - Make code changes
   - Apply fix from fix.patch
   - Usually 2-10 edits

4. **Test** (600-900 sec)
   - Write/modify tests (from tests.patch)
   - Run tests
   - Verify fix works
   - Usually 2-5 actions

5. **Completion** (900+ sec)
   - `end_interaction`
   - Final summary

---

## Your Tasks

**⚠️ REMINDER: Generate BOTH ideal_trajectory.json AND failed_trajectory.json**

### Task 3.1: Analyze the Fix (10 min)

Study fix.patch and tests.patch:

```bash
# Review fix.patch
cat fix.patch

# Identify:
# - Which files changed?
# - What was added/removed?
# - What's the core logic change?
# - Why does this fix the bug?
```

**Document:**
- Root cause of bug
- How fix addresses it
- Key code patterns changed

---

### Task 3.2: Design Exploration Phase (15 min)

**Think like an agent discovering the bug:**

1. **What would the agent search for first?**
   - Class names mentioned in issue
   - Error messages
   - Function names

2. **Which files would the agent open?**
   - Start with main file containing bug
   - Related service/utility files
   - Test files to understand expected behavior

3. **What patterns would the agent recognize?**
   - Missing null checks
   - Incorrect logic
   - Missing error handling

**Create 4-8 exploration actions:**
- 1-2 searches
- 3-5 file opens
- 0-1 additional searches for related code

---

### Task 3.3: Map Fix to Solution Actions (20 min)

**For each hunk in fix.patch:**

```diff
@@ -45,7 +45,10 @@ public class PaymentHandler {
-        String email = customer.getEmail();
+        String email = customer.getEmail();
+        if (email == null || email.isEmpty()) {
+            email = "noreply@example.com";
+        }
```

**Create find_and_replace_code action:**
1. Extract `oldCode` (lines with `-`)
2. Extract `newCode` (lines with `+`)
3. Write thought explaining why
4. Assign appropriate timestamp

**Important:**
- Preserve exact indentation
- Include surrounding context (2-3 lines before/after)
- oldCode must match exactly what's in the file at commit_before

---

### Task 3.4: Map Tests to Test Actions (15 min)

**For each change in tests.patch:**

```diff
+    @Test
+    public void testPaymentWithNullEmail() {
+        Customer customer = new Customer();
+        customer.setEmail(null);
+        ...
+    }
```

**Create actions:**
1. `open_file` for test file
2. `find_and_replace_code` to add new test
3. `execute_terminal_command` to run tests

---

### Task 3.5: Generate Realistic Timestamps (5 min)

**Time allocation guidelines:**

```
EnvironmentSetup:     0-10 sec      (quick start)
Exploration:          10-180 sec    (2-3 min to explore)
Solution:             180-480 sec   (5 min to implement)
Test:                 480-720 sec   (4 min to test)
Completion:           720-750 sec   (wrap up)
```

**Duration guidelines:**
- `search_string`: 2-5 seconds
- `open_file`: 3-8 seconds
- `find_and_replace_code`: 5-15 seconds (simple) to 30-90 seconds (complex)
- `execute_terminal_command`: 10-60 seconds (depending on test suite size)

**Calculate timestamps:**
```python
timestamp = start_time + elapsed_seconds
elapsed_seconds += duration_seconds
```

---

### Task 3.6: Write Realistic Thoughts (10 min)

**Good thoughts:**
- ✅ "I need to find where customer.getEmail() is called without null checking"
- ✅ "The error occurs in processPayment(). I'll add a null check before using the email"
- ✅ "Running tests to verify the fix handles null emails correctly"

**Bad thoughts:**
- ❌ "Fixing bug" (too vague)
- ❌ "I will apply the patch" (meta - agent doesn't know about patches)
- ❌ "Changing line 45" (too mechanical)

**Thoughts should:**
- Explain what the agent is looking for
- Describe what the agent discovered
- Justify why the agent is making a change
- Sound natural and problem-solving oriented

---

### Task 3.7: Assemble Complete IDEAL Trajectory (10 min)

Save as `ideal_trajectory.json`:

```json
{
  "annotationTrace": [
    // 1. begin_interaction
    // 2-8. Exploration actions
    // 9-15. Solution actions (from fix.patch)
    // 16-20. Test actions (from tests.patch)
    // 21. end_interaction
  ],
  "taskIssue": "{Clear description of the bug from PR}",
  "tags": {
    "difficulty": "{easy|medium|hard}",
    "issueType": "BugFix",
    "techTags": ["{Language}", "{Framework}", "{TestFramework}"]
  }
}
```

---

### Task 3.8: Generate FAILED Trajectory (15 min) 🚨 MANDATORY

**⚠️ This step is REQUIRED - DO NOT skip!**

Create a realistic failure scenario to train the model on what NOT to do.

#### Steps

1. **Copy ideal_trajectory.json as base**
   ```bash
   cp ideal_trajectory.json failed_trajectory.json
   ```

2. **Select appropriate failure mode:**
   | Bug Type | Recommended Failure Mode |
   |----------|-------------------------|
   | Null pointer | Skip null check, incomplete fix |
   | Multi-file refactor | Update some files, miss others |
   | Context propagation | Forget to pass context somewhere |
   | CSS/UI bug | Fix one browser, ignore others |
   | Schema change | Wrong type assumption |
   | Any bug | Skip test verification (most common) |

3. **Modify the trajectory:**
   - **Remove** test execution actions (most common failure)
   - **Shorten** exploration (miss key files)
   - **Modify** thoughts to show hasty reasoning:
     - "This should fix it" → instead of → "Let me verify this works"
     - "The error is gone" → instead of → "The root cause is addressed"
   - **Add** incorrect assumptions in thoughts
   - **Remove or modify** 1-2 solution actions (incomplete fix)

4. **Common modifications:**
   ```diff
   - "thought": "Running tests to verify the fix resolves the issue"
   + "thought": "The fix looks correct, should be good now"
   
   - {"action": "execute_terminal_command", "details": {"command": "npm test"}}
   + // REMOVED - Agent skipped verification
   ```

5. **Add failure mode to tags:**
   ```json
   "tags": {
     "difficulty": "medium",
     "issueType": "BugFix",
     "techTags": ["TypeScript", "React"],
     "failureMode": "Incomplete Solution / Inadequate Verification"
   }
   ```

6. **Common failure modes:**
   - `"Incomplete Solution / Inadequate Verification"` - Most common
   - `"Partial Fix / Missing Edge Cases"`
   - `"Wrong Root Cause / Incorrect Fix"`
   - `"Insufficient Testing / No Verification"`
   - `"Multi-file Change / Missed Files"`

7. **Save as `failed_trajectory.json`**

#### Validation for Failed Trajectory

- [ ] failed_trajectory.json exists
- [ ] Has 10-30% fewer actions than ideal (typically removed test/verification)
- [ ] Thoughts show hasty or incorrect reasoning
- [ ] Tags include "failureMode" field
- [ ] File is valid JSON

---

## Validation Checklist

### For ideal_trajectory.json:
- [ ] All actions have required fields (action, details, thought, timestamp, elapsed_seconds, duration_seconds, partition)
- [ ] Timestamps are sequential
- [ ] elapsed_seconds increases monotonically
- [ ] Partitions are assigned correctly
- [ ] Thoughts are realistic and helpful
- [ ] oldCode matches what's at commit_before
- [ ] newCode matches what's in fix.patch
- [ ] Test actions match tests.patch
- [ ] Total elapsed time is realistic (5-15 minutes typical)
- [ ] File is valid JSON

### For failed_trajectory.json:
- [ ] **File exists** (MANDATORY)
- [ ] Has appropriate failure mode in tags.failureMode
- [ ] Has fewer actions than ideal (typically 10-30% less)
- [ ] Thoughts show hasty or incorrect reasoning
- [ ] Missing test verification OR incomplete fix
- [ ] File is valid JSON

### Both files:
- [ ] **Both ideal_trajectory.json AND failed_trajectory.json exist**
- [ ] Both have same taskIssue
- [ ] Both have same difficulty, issueType, techTags
- [ ] Failed has additional "failureMode" in tags

---

## Output Format

```json
{
  "status": "success",
  "files_generated": [
    "ideal_trajectory.json",
    "failed_trajectory.json"
  ],
  "ideal_trajectory": {
    "annotationTrace": [ /* full array */ ],
    "taskIssue": "...",
    "tags": { /* ... */ }
  },
  "failed_trajectory": {
    "annotationTrace": [ /* modified array */ ],
    "taskIssue": "...",
    "tags": { 
      /* ... */ 
      "failureMode": "Incomplete Solution / Inadequate Verification"
    }
  },
  "stats": {
    "ideal_actions": 18,
    "failed_actions": 14,
    "exploration_actions": 6,
    "solution_actions": 8,
    "test_actions": 3,
    "total_duration_seconds": 750,
    "files_modified": 3
  },
  "next_phase_ready": true
}
```

---

## Example Mini-Trajectory

```json
{
  "annotationTrace": [
    {
      "action": "begin_interaction",
      "details": {
        "commandType": "INTERACT_WITH_ENVIRONMENT",
        "context": "Starting investigation of payment null pointer exception",
        "payload": null
      },
      "thought": "The payment handler crashes when customer email is null. I'll locate the PaymentHandler class and identify the issue.",
      "timestamp": "2024-03-15T10:00:00Z",
      "elapsed_seconds": 0,
      "duration_seconds": 3,
      "partition": "EnvironmentSetup"
    },
    {
      "action": "search_string",
      "details": {
        "commandType": "SEARCH",
        "context": "PaymentHandler",
        "payload": {
          "searchQuery": "class PaymentHandler",
          "directory": "/app/src"
        }
      },
      "thought": "Searching for the PaymentHandler class definition.",
      "timestamp": "2024-03-15T10:00:03Z",
      "elapsed_seconds": 3,
      "duration_seconds": 2,
      "partition": "Exploration"
    }
    // ... more actions ...
  ],
  "taskIssue": "Payment processing fails with NullPointerException when customer email is null",
  "tags": {
    "difficulty": "easy",
    "issueType": "BugFix",
    "techTags": ["Java", "Spring Boot"]
  }
}
```

---

---

## Ready to Generate!

Provide Phase 1 and Phase 2 outputs, and I'll create realistic **BOTH** trajectory files:
- ✅ `ideal_trajectory.json` 
- ✅ `failed_trajectory.json`

**Both files are MANDATORY for Phase 3 completion.**

