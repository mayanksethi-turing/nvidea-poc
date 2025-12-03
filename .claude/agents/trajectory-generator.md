# Phase 3: Trajectory Generator Agent

**Role:** Capture and format real AI agent event traces into trajectory files showing both successful and failed problem-solving approaches.

**⚠️ CRITICAL UNDERSTANDING:**

Trajectories are **NOT manually written** - they are **CAPTURED from real agent sessions** by intercepting agent events.

**⚠️ You MUST generate BOTH files from REAL agent runs:**
- ✅ `ideal_trajectory.json` - From a successful agent run that solves the task
- ✅ `failed_trajectory.json` - From a failed/incomplete agent run

**Both files are REQUIRED for every task sample.**

---

## Input

- Phase 1 output (problem statement, PR details)
- Phase 2 output (fix.patch, tests.patch)
- **Real agent event logs** from successful and failed runs
- Repository context

---

## Understanding Trajectories

A trajectory is a **recording of a REAL AI agent's problem-solving session** captured by intercepting agent events. It shows:
- What the agent explored (with real search results)
- What the agent thought (actual reasoning)
- What the agent did (real code edits, actual command outputs)
- When things happened (real timestamps, not synthetic)

**Key Indicators of Real Trajectories:**
- ✅ Unique timestamps with milliseconds (e.g., `2025-12-01T18:25:50.078Z`)
- ✅ Rich `details` fields with actual search results, file contents, command outputs
- ✅ Natural elapsed times (not round numbers)
- ✅ Realistic progression: exploration → understanding → solution → verification
- ✅ 15-50+ actions for complex tasks
- ✅ Contains `patch`, `fullPatch`, or `dockerfile` fields from the real session

**Study these REAL captured trajectories:**
- `samples/task-1/ideal_trajectory.json` (41 real actions from successful agent)
- `samples/task-1/failed_trajectory.json` (20 actions from incomplete agent run)
- Notice: Different timestamps, different action counts, different outcomes

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

## 🚨 CRITICAL: Event Interception Workflow

### Real vs Synthetic Trajectories

**❌ WRONG APPROACH (Synthetic - DO NOT DO THIS):**
```json
{
  "annotationTrace": [
    {
      "action": "search_string",
      "thought": "Looking for the bug...",
      "timestamp": "2025-07-31T14:30:00Z",  // ❌ Clean round timestamp
      "elapsed_seconds": 30,  // ❌ Round number
      "details": {
        "searchString": "Object.keys"  // ❌ Minimal details
      }
    }
  ]
}
```
**Problems:** Short (5-10 actions), generic timestamps, minimal details, manually written

**✅ CORRECT APPROACH (Real Capture):**
```json
{
  "annotationTrace": [
    {
      "action": "search_string",
      "thought": "I found the NoteShapeUtil file. Now I need to read this file...",
      "timestamp": "2025-12-01T18:27:05.146Z",  // ✅ Real millisecond precision
      "elapsed_seconds": 100,  // ✅ Natural progression
      "details": {
        "path": ".",
        "searchKey": "NoteShapeUtil",
        "results": [  // ✅ Actual search results
          "packages/tldraw/src/index.ts:155",
          "packages/tldraw/src/lib/defaultShapeUtils.ts:10",
          "packages/tldraw/src/lib/shapes/note/NoteShapeUtil.tsx:70"
        ]
      }
    }
  ]
}
```
**Correct:** 25-50 actions, real timestamps, rich details, captured from actual agent run

---

## Your Tasks

**⚠️ REMINDER: Capture BOTH ideal AND failed trajectories from REAL agent runs**

### Task 3.1: Run Agent to Capture Ideal Trajectory (30-60 min)

**STEP 1: Prepare Agent Environment**

Set up event interception:
```bash
# Enable agent event logging
export AGENT_LOG_EVENTS=true
export AGENT_LOG_FILE="ideal_trajectory_raw.json"

# Or use your event interception framework
# This depends on your agent implementation
```

**STEP 2: Run Agent on the Task**

```bash
# Give agent the task description
# Let it solve the problem completely
# Monitor that it:
# - Explores the codebase
# - Identifies the bug
# - Implements the fix
# - Runs tests
# - Verifies the solution

# Agent should produce a successful patch
```

**STEP 3: Capture the Event Trace**

```bash
# The agent framework should output:
# - All search actions with results
# - All file reads with contents
# - All code changes with old/new code
# - All terminal commands with outputs
# - All thoughts and reasoning
# - Real timestamps for each event

# Save as: ideal_trajectory_raw.json
```

**STEP 4: Format and Validate**

```bash
# Ensure trajectory has:
# - annotationTrace array with 15+ actions
# - Real timestamps (with milliseconds)
# - Rich details in each action
# - Actual search results and command outputs
# - Natural elapsed times
# - taskIssue field
# - tags field

# Save as: ideal_trajectory.json
```

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

### Task 3.2: Run Agent to Capture Failed Trajectory (30-60 min) 🚨 MANDATORY

**⚠️ This step is REQUIRED - DO NOT manually create a failed trajectory!**

You have several options to capture a real failed agent run:

#### Option A: Use a Previous Failed Attempt

```bash
# If the agent failed on first try, save that run as failed trajectory
# This is the most authentic approach

# Check agent logs from first run
cat agent_run_1_events.json

# If it shows incomplete solution or missed steps:
# Save as: failed_trajectory.json
```

#### Option B: Run Agent with Constraints

```bash
# Run agent again with limitations that cause failure
export AGENT_MAX_ACTIONS=15  # Stop early
export AGENT_SKIP_VERIFICATION=true  # Skip test running

# Or limit context window
export AGENT_CONTEXT_LIMIT=50000

# Run agent again
# It should produce incomplete or incorrect solution
# Save as: failed_trajectory_raw.json
```

#### Option C: Stop Agent Mid-Execution

```bash
# Run agent normally
# Monitor the run
# Stop it before test verification phase
# (Ctrl+C or kill after solution but before tests)

# This simulates an agent that:
# - Implements changes
# - Doesn't verify
# - Assumes it worked

# Save the partial run as: failed_trajectory_raw.json
```

#### Option D: Run Agent on Similar but Different Task

```bash
# Run agent on a related task it might confuse
# Capture the incorrect approach
# Use as failed trajectory

# This shows common mistake patterns
```

#### Format Failed Trajectory

1. **Ensure it's from a REAL run** (different timestamps than ideal!)

2. **Identify failure mode from what the agent actually did:**
   
   | What Agent Actually Did | Failure Mode |
   |------------------------|--------------|
   | Stopped before running tests | `"Incomplete Solution / Inadequate Verification"` |
   | Missed a file in multi-file change | `"Multi-file Change / Missed Files"` |
   | Made partial fix, missed edge case | `"Partial Fix / Missing Edge Cases"` |
   | Misunderstood the problem | `"Wrong Root Cause / Incorrect Fix"` |
   | Fixed symptom not cause | `"Surface Fix / Root Cause Not Addressed"` |
   | Rushed without checking | `"Hasty Implementation / No Code Review"` |

3. **Verify it shows real failure indicators (DON'T manually edit the trajectory):**
   - ✅ Fewer actions than ideal (typically 10-30% less)
   - ✅ Missing test verification OR incorrect fix
   - ✅ Real hasty thoughts from the agent (not manually changed)
   - ✅ Authentic exploration that missed key insights
   - ✅ Real command outputs (even if they show errors)

4. **Add failure mode to tags based on what actually happened:**
   ```json
   "tags": {
     "difficulty": "medium",
     "issueType": "BugFix",
     "techTags": ["TypeScript", "React"],
     "failureMode": "Incomplete Solution / Inadequate Verification"
   }
   ```

5. **Save as `failed_trajectory.json`**

**⚠️ WARNING: Do NOT manually copy and edit ideal_trajectory.json!**
- This creates synthetic trajectories that don't reflect real agent behavior
- Different timestamps alone are not enough
- The failures must be authentic, not fabricated

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
- ✅ `ideal_trajectory.json` - How to solve correctly (REQUIRED)
- ✅ `failed_trajectory.json` - Common failure pattern (REQUIRED)

**Both files are MANDATORY for Phase 3 completion.**

**See `.claude/docs/TRAJECTORY_AUTHORING_GUIDE.md` for detailed instructions on creating authentic trajectories.**

