# Trajectory Authoring Guide

## Overview

This guide clarifies **how to create trajectory files** for bug-fix samples. It addresses the central question: Should trajectories be **captured** or **authored**?

---

## The Reality: Hybrid Approach

**The truth is:** Most trajectories in this system are **manually authored based on patch analysis**, not automatically captured from real agent runs, because:

1. **The agent framework doesn't exist yet** - There's no production agent that can solve arbitrary GitHub issues
2. **The solution is already known** - We have the PR patches that fix the bug
3. **We're creating training data** - The goal is to show how an agent *should* solve the problem

However, trajectories must **simulate authentic agent behavior** to be useful training data.

---

## Two Valid Approaches

### Approach A: Manual Authoring (Realistic, Current)

**What it is:** Analyze the PR patches and manually write a realistic problem-solving trajectory.

**When to use:**
- ✅ No real agent available to capture from
- ✅ You have PR patches showing the solution
- ✅ You need to demonstrate ideal problem-solving approach

**Process:**

1. **Analyze the Bug Fix**
   ```bash
   # Study the PR
   gh pr view <PR_NUMBER>
   
   # Examine what changed
   git diff <before>..<after>
   
   # Understand the root cause
   # - What was broken?
   # - Why was it broken?
   # - How does the fix address it?
   ```

2. **Design Realistic Discovery Path**
   
   **Think:** How would an agent discover this bug?
   
   **Exploration questions:**
   - What would the agent search for first?
   - Which files would it need to read?
   - What patterns would it recognize?
   - What dead-ends might it explore?

3. **Map Patches to Actions**
   
   For each change in `fix.patch`:
   ```json
   {
     "action": "find_and_replace_code",
     "details": {
       "file": "/path/to/file.js",
       "changes": [{
         "originalText": { /* from patch */ },
         "newText": { /* from patch */ }
       }]
     },
     "thought": "Adding null check because customer.getEmail() can return null...",
     "timestamp": "<natural-progression-time>",
     "elapsed_seconds": <accumulated-time>,
     "duration_seconds": <action-duration>,
     "partition": "Solution"
   }
   ```

4. **Add Realistic Timestamps**
   
   **Guidelines:**
   - Start time: Any reasonable timestamp
   - Add milliseconds: `.146Z`, `.892Z` (not `.000Z`)
   - Vary elapsed times: 0, 7, 23, 51, 108... (not 0, 10, 20, 30...)
   - Action durations:
     - search: 2-5 seconds
     - read file: 3-8 seconds
     - code edit: 15-45 seconds
     - test run: 10-60 seconds

5. **Write Authentic Thoughts**
   
   **Good thoughts (specific):**
   - ✅ "The NullPointerException occurs at line 45 in PaymentHandler.java where we call customer.getEmail() without checking if customer is null"
   - ✅ "I need to add a null check before accessing the email. I'll also add a default email value to handle the case gracefully"
   - ✅ "Let me run the tests to verify this fix handles both null customers and null emails"
   
   **Bad thoughts (generic):**
   - ❌ "Fixing the bug"
   - ❌ "Looking for the error"
   - ❌ "Making changes to the file"

6. **Include Rich Details**
   
   For `search_string` actions:
   ```json
   {
     "details": {
       "path": "src/",
       "searchKey": "PaymentHandler",
       "results": [  // ← MUST include actual file paths
         "src/main/java/com/app/PaymentHandler.java:23",
         "src/test/java/com/app/PaymentHandlerTest.java:15"
       ]
     }
   }
   ```
   
   For `execute_terminal_command` actions:
   ```json
   {
     "details": {
       "command": "mvn test -Dtest=PaymentHandlerTest",
       "output": "Tests run: 5, Failures: 0, Errors: 0, Skipped: 0\n[INFO] BUILD SUCCESS",  // ← MUST include actual output
       "exitCode": 0
     }
   }
   ```

7. **Validate Authenticity**
   
   Use the validation tool:
   ```bash
   ./.claude/scripts/validate-trajectory.sh ideal_trajectory.json --type ideal
   ```
   
   Should pass with minimal warnings.

---

### Approach B: Real Agent Capture (Aspirational, Future)

**What it is:** Run an actual agent on the task and intercept its events in real-time.

**When to use:**
- ✅ You have a working agent that can solve GitHub issues
- ✅ You want to capture authentic problem-solving (including mistakes)
- ✅ You're testing agent capabilities

**Requirements:**

1. **Agent Must Support Event Logging**
   ```python
   # Example: Python agent with event hooks
   class AgentEventLogger:
       def on_action(self, action_type, details, thought):
           event = {
               "action": action_type,
               "details": details,
               "thought": thought,
               "timestamp": datetime.utcnow().isoformat() + "Z",
               "elapsed_seconds": int(time.time() - self.start_time),
               "duration_seconds": 0,
               "partition": self.current_partition
           }
           self.events.append(event)
   ```

2. **Run Agent on Task**
   ```bash
   # Enable event logging
   export AGENT_LOG_EVENTS=true
   export AGENT_LOG_FILE="trajectory_raw.json"
   
   # Give agent the task (without showing the solution)
   python agent.py --task "Fix NullPointerException in payment processing when customer email is null"
   
   # Agent explores, identifies issue, implements fix, runs tests
   # All events are logged to trajectory_raw.json
   ```

3. **Post-Process the Capture**
   ```bash
   # Add metadata
   jq '. + {
     "taskIssue": "Payment processing crashes...",
     "tags": {...}
   }' trajectory_raw.json > ideal_trajectory.json
   ```

**This approach is ideal but requires having a functioning agent.**

---

## Creating Failed Trajectories

Failed trajectories demonstrate common agent mistakes. They should show **realistic failure patterns**, not arbitrary errors.

### Method 1: Manual Authoring of Failure

Based on the ideal trajectory, create a failed version that demonstrates a specific failure mode:

**Example: Incomplete Verification**

Take the ideal trajectory and:
1. Copy all exploration and solution actions
2. **Remove test execution actions**
3. End with premature `end_interaction`
4. Adjust final thought: "The fix has been applied. The bug should be resolved." (no verification!)
5. Add `"failureMode": "Incomplete Solution / Inadequate Verification"` to tags

**Example: Partial Fix**

Take the ideal trajectory and:
1. Keep exploration
2. **Only apply some of the fixes** (miss edge cases)
3. Include test execution that **would actually fail** (if it were run)
4. Adjust thoughts to show flawed reasoning: "Adding null check for email should handle all cases"
5. Add `"failureMode": "Partial Fix / Missing Edge Cases"` to tags

### Method 2: Capture Real Failure (if agent available)

```bash
# Run agent with constraints
export AGENT_MAX_ACTIONS=15  # Force it to stop early
export AGENT_LOG_FILE="failed_trajectory_raw.json"

python agent.py --task "Fix NullPointerException..."

# Agent runs out of actions before verifying
# Saved to failed_trajectory_raw.json
```

### Requirements for Failed Trajectories

1. **Must have different timestamps from ideal** - proves different creation
2. **Must demonstrate realistic failure** - not random errors
3. **Must have failureMode in tags** - classify what went wrong
4. **Typically 10-30% fewer actions** - incomplete solution
5. **Should be believable** - an agent might actually make this mistake

---

## Quality Checklist

### For Ideal Trajectories

- [ ] 15-50 actions (realistic scope)
- [ ] Unique timestamps with milliseconds
- [ ] Non-round elapsed times
- [ ] Rich details:
  - [ ] Search results include actual file paths
  - [ ] Commands include actual outputs
  - [ ] File reads reference specific lines
- [ ] Specific thoughts referencing:
  - [ ] File names and paths
  - [ ] Line numbers
  - [ ] Function/class names
  - [ ] Specific issues found
- [ ] Realistic partitions:
  - [ ] EnvironmentSetup (1-2 actions)
  - [ ] Exploration (3-10 actions)
  - [ ] Solution (5-15 actions)
  - [ ] Test (2-5 actions)
- [ ] Test execution with output
- [ ] Natural action progression (not too perfect)

### For Failed Trajectories

- [ ] Different timestamps from ideal
- [ ] Demonstrates specific failure mode
- [ ] Has `failureMode` in tags
- [ ] 10-30% fewer actions than ideal
- [ ] Shows flawed reasoning in thoughts
- [ ] Missing critical step (test, edge case, file)
- [ ] Would actually fail if executed

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Too Clean/Perfect

```json
{
  "timestamp": "2025-01-01T10:00:00Z",  // Too round!
  "elapsed_seconds": 30,  // Perfect interval!
  "thought": "Fixing bug"  // Too vague!
}
```

**Fix:** Add natural variation and specificity

```json
{
  "timestamp": "2025-01-01T10:03:47.283Z",  // Real milliseconds
  "elapsed_seconds": 227,  // Natural progression
  "thought": "Adding null check at line 45 in PaymentHandler.java because customer.getEmail() can throw NullPointerException"
}
```

### ❌ Mistake 2: Empty Details

```json
{
  "action": "search_string",
  "details": {
    "searchKey": "PaymentHandler"
    // Missing: results array!
  }
}
```

**Fix:** Include actual search results

```json
{
  "action": "search_string",
  "details": {
    "searchKey": "PaymentHandler",
    "results": [
      "src/main/java/com/app/PaymentHandler.java:23",
      "src/main/java/com/app/handlers/PaymentService.java:15"
    ]
  }
}
```

### ❌ Mistake 3: Copied Failed Trajectory

```bash
# WRONG!
cp ideal_trajectory.json failed_trajectory.json
# Then manually removing a few actions
```

This creates identical timestamps and inauthentic failure patterns.

**Fix:** Author the failed trajectory separately with its own timestamps and failure-specific reasoning.

---

## Validation

Always validate trajectories before finalizing:

```bash
# Validate ideal trajectory
./.claude/scripts/validate-trajectory.sh ideal_trajectory.json --type ideal

# Validate failed trajectory
./.claude/scripts/validate-trajectory.sh failed_trajectory.json --type failed
```

Address any errors and warnings before including in the sample.

---

## Examples

See these reference trajectories:

- `samples/task-1/ideal_trajectory.json` - High-quality ideal trajectory (41 actions)
- `samples/task-1/failed_trajectory.json` - Realistic failed trajectory (20 actions)

Study these to understand:
- Level of detail required
- Natural timestamp progression
- Specific vs generic thoughts
- Rich details in actions
- Realistic failure patterns

---

## Conclusion

**The honest answer:** Most trajectories will be **manually authored** to simulate realistic agent behavior based on analyzing the bug fix patches.

**The important part:** They must be **indistinguishable from real captures** - with authentic timestamps, rich details, specific reasoning, and natural progression.

**The future:** As agent capabilities improve, we'll transition to capturing real agent sessions, but manual authoring following these guidelines produces high-quality training data today.

**Key principle:** Whether authored or captured, trajectories must reflect **authentic problem-solving patterns** that agents can learn from.

