# Agent Event Interception Guidelines

## Overview

Trajectories **MUST** be captured from real agent sessions, not manually written. This document explains how to properly intercept and format agent events.

---

## Why Real Event Capture Matters

### ❌ Problems with Synthetic Trajectories

**Manual Writing Creates:**
- Unrealistic action sequences
- Clean timestamps (round numbers)
- Missing real exploration paths
- Fabricated "failures" that don't reflect actual agent behavior
- Loss of authentic problem-solving patterns

**Example of Synthetic (WRONG):**
```json
{
  "action": "search_string",
  "thought": "Looking for the bug",
  "timestamp": "2025-07-31T14:30:00Z",  // Too clean!
  "elapsed_seconds": 30,  // Round number
  "details": {
    "searchString": "Object.keys"  // Minimal info
  }
}
```

### ✅ Benefits of Real Event Capture

**Real Captures Provide:**
- Authentic exploration patterns
- Real timestamps with millisecond precision
- Actual search results and file contents
- Real command outputs (including errors)
- Natural reasoning progression
- Genuine failure modes

**Example of Real Capture (CORRECT):**
```json
{
  "action": "search_string",
  "thought": "I found the NoteShapeUtil implementation at packages/tldraw/src/lib/shapes/note/NoteShapeUtil.tsx. Now I need to search for the useCurrentTranslation hook...",
  "timestamp": "2025-12-01T18:27:05.146Z",  // Real milliseconds
  "elapsed_seconds": 100,  // Natural progression
  "duration_seconds": 0,
  "partition": "EnvironmentSetup",
  "details": {
    "path": ".",
    "searchKey": "NoteShapeUtil",
    "results": [  // Actual search results!
      "packages/tldraw/src/index.ts:155",
      "packages/tldraw/src/lib/defaultShapeUtils.ts:10",
      "packages/tldraw/src/lib/shapes/note/NoteShapeUtil.tsx:70",
      "apps/examples/src/examples/resize-note/ResizeNoteExample.tsx:1"
    ]
  }
}
```

---

## Event Interception Setup

### Required Agent Capabilities

Your agent framework must be able to log:

1. **All Actions:**
   - `search_string` with real results
   - `open_file` with actual file contents
   - `find_and_replace_code` with old/new code
   - `execute_terminal_command` with stdout/stderr
   - `add_thought` with reasoning
   - `begin_interaction` / `end_interaction`

2. **All Metadata:**
   - Real timestamps (with milliseconds)
   - Elapsed time from session start
   - Duration of each action
   - Partition/phase assignment

3. **Rich Details:**
   - Search results with file paths and line numbers
   - File contents (at least relevant snippets)
   - Command outputs (full or truncated)
   - Error messages if any

### Configuration Examples

#### For Python-based Agents:

```python
import json
import time
from datetime import datetime

class EventLogger:
    def __init__(self, output_file):
        self.output_file = output_file
        self.start_time = time.time()
        self.events = []
    
    def log_action(self, action_type, details, thought, partition):
        elapsed = time.time() - self.start_time
        event = {
            "action": action_type,
            "details": details,
            "thought": thought,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "elapsed_seconds": int(elapsed),
            "duration_seconds": 0,  # Calculate from timing
            "partition": partition
        }
        self.events.append(event)
        self._save()
    
    def _save(self):
        with open(self.output_file, 'w') as f:
            json.dump({
                "annotationTrace": self.events,
                "taskIssue": "...",
                "tags": {...}
            }, f, indent=2)

# Usage
logger = EventLogger("trajectory_raw.json")

# Before each agent action
logger.log_action(
    action_type="search_string",
    details={
        "path": "src/",
        "searchKey": "MyClass",
        "results": actual_search_results  # MUST be real!
    },
    thought=agent.current_thought,
    partition="Exploration"
)
```

#### For TypeScript/JavaScript Agents:

```typescript
interface AgentEvent {
  action: string;
  details: any;
  thought: string;
  timestamp: string;
  elapsed_seconds: number;
  duration_seconds: number;
  partition: string;
}

class EventInterceptor {
  private events: AgentEvent[] = [];
  private startTime: number = Date.now();
  
  logAction(
    action: string,
    details: any,
    thought: string,
    partition: string
  ): void {
    const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
    this.events.push({
      action,
      details,
      thought,
      timestamp: new Date().toISOString(),
      elapsed_seconds: elapsed,
      duration_seconds: 0,
      partition
    });
    this.save();
  }
  
  private save(): void {
    const trajectory = {
      annotationTrace: this.events,
      taskIssue: "...",
      tags: {...}
    };
    fs.writeFileSync('trajectory_raw.json', JSON.stringify(trajectory, null, 2));
  }
}
```

---

## Capturing Ideal Trajectories

### Process

1. **Setup Environment:**
   ```bash
   export AGENT_LOG_EVENTS=true
   export AGENT_LOG_FILE="ideal_trajectory_raw.json"
   ```

2. **Run Agent Completely:**
   - Give it the full task description
   - Let it explore the codebase
   - Let it implement the fix
   - Let it run tests
   - Let it verify the solution

3. **Monitor the Run:**
   - Watch for proper exploration
   - Ensure it finds the root cause
   - Verify it implements complete fix
   - Confirm test execution

4. **Validate Capture:**
   ```bash
   # Check action count
   ACTIONS=$(jq '.annotationTrace | length' ideal_trajectory_raw.json)
   echo "Captured $ACTIONS actions"
   
   # Verify timestamps have milliseconds
   jq -r '.annotationTrace[0].timestamp' ideal_trajectory_raw.json
   # Should output: 2025-12-01T18:27:05.146Z
   
   # Check for rich details
   jq '.annotationTrace[1].details' ideal_trajectory_raw.json
   # Should show actual search results, not empty
   ```

5. **Format and Save:**
   ```bash
   # Add any missing metadata
   jq '. + {
     "taskIssue": "Description from PR",
     "tags": {
       "difficulty": "medium",
       "issueType": "BugFix",
       "techTags": ["TypeScript", "React"]
     }
   }' ideal_trajectory_raw.json > ideal_trajectory.json
   ```

---

## Capturing Failed Trajectories

### Option A: Previous Failed Attempt

If agent failed on first try, **that's your failed trajectory!**

```bash
# Check if you have a failed run logged
ls agent_runs/
# agent_run_2025-12-01_attempt1.json  <- Failed
# agent_run_2025-12-01_attempt2.json  <- Succeeded

# Use the failed one
cp agent_run_2025-12-01_attempt1.json failed_trajectory_raw.json

# Identify what went wrong
jq '.annotationTrace | map(.action)' failed_trajectory_raw.json
# If missing "execute_terminal_command" at end → no verification

# Add appropriate failureMode
jq '.tags.failureMode = "Incomplete Solution / Inadequate Verification"' \
   failed_trajectory_raw.json > failed_trajectory.json
```

### Option B: Run with Constraints

Force agent to produce incomplete solution:

```bash
# Limit max actions (stops early)
export AGENT_MAX_ACTIONS=15
export AGENT_LOG_FILE="failed_trajectory_raw.json"

# Run agent - it will stop before completion
./run_agent.sh

# Result: Agent implements fix but doesn't verify
# This is authentic "incomplete solution" failure
```

### Option C: Stop Mid-Execution

```bash
# Start agent with logging
export AGENT_LOG_FILE="failed_trajectory_raw.json"
./run_agent.sh &
AGENT_PID=$!

# Monitor progress
tail -f failed_trajectory_raw.json

# When you see solution phase complete but before tests:
# (watch for "Solution" partition ending)
kill $AGENT_PID

# This captures authentic "skipped verification" failure
```

### Option D: Use Different Agent

```bash
# Run a less capable agent version
export AGENT_VERSION="v1.0"  # Older, less complete
export AGENT_LOG_FILE="failed_trajectory_raw.json"

./run_agent.sh

# The older agent might:
# - Miss some files
# - Make incomplete fix
# - Skip edge cases

# This provides authentic failure patterns
```

### Validating Failed Trajectory

```bash
# Verify it's from a DIFFERENT run
IDEAL_TS=$(jq -r '.annotationTrace[0].timestamp' ideal_trajectory.json)
FAILED_TS=$(jq -r '.annotationTrace[0].timestamp' failed_trajectory.json)

if [ "$IDEAL_TS" == "$FAILED_TS" ]; then
  echo "❌ ERROR: Timestamps match! Not from different runs!"
  exit 1
fi

# Verify it has failure indicators
IDEAL_ACTIONS=$(jq '.annotationTrace | length' ideal_trajectory.json)
FAILED_ACTIONS=$(jq '.annotationTrace | length' failed_trajectory.json)

echo "Ideal: $IDEAL_ACTIONS actions"
echo "Failed: $FAILED_ACTIONS actions"

if [ $FAILED_ACTIONS -ge $IDEAL_ACTIONS ]; then
  echo "⚠️  Warning: Failed has same or more actions than ideal"
  echo "   This is unusual for a real failure"
fi

# Check for test execution
HAS_TESTS=$(jq '[.annotationTrace[] | select(.action == "execute_terminal_command")] | length' failed_trajectory.json)

if [ $HAS_TESTS -eq 0 ]; then
  echo "✅ Failed trajectory skipped test execution"
  echo "   Failure mode: Incomplete Solution / Inadequate Verification"
fi
```

---

## Common Failure Modes from Real Captures

### 1. Incomplete Solution / Inadequate Verification

**What happens:** Agent implements fix but doesn't run tests

**In the trajectory:**
- No `execute_terminal_command` with test execution
- Last thought: "The fix looks correct" instead of "Tests pass"
- Ends with `end_interaction` without verification

**Example:**
```json
{
  "action": "end_interaction",
  "thought": "Fixed the Object.keys crash by adding a type check. This should prevent the crash on null values.",
  // ❌ No mention of running tests!
  // ❌ Assumes it works without verification
}
```

### 2. Multi-file Change / Missed Files

**What happens:** Agent updates some files but misses related ones

**In the trajectory:**
- Fewer `find_and_replace_code` actions than ideal
- Exploration missed some files
- Thought mentions one file but not others

**Example:**
```json
{
  "action": "find_and_replace_code",
  "thought": "Fixed the NoteShapeUtil to use TranslationsContext",
  // ❌ But didn't export TranslationsContext!
  // ❌ Missed updating index.ts
}
```

### 3. Partial Fix / Missing Edge Cases

**What happens:** Agent fixes main case but misses edge cases

**In the trajectory:**
- Solution looks correct but incomplete
- Only one `find_and_replace_code` where two were needed
- Thought identifies issue but solution is partial

**Example:**
```json
{
  "action": "find_and_replace_code",
  "thought": "Adding null check for hit[objectKey]",
  "details": {
    "oldCode": "const sizeOfObject = Object.keys(hit[objectKey])?.length",
    "newCode": "const sizeOfObject = hit[objectKey] ? Object.keys(hit[objectKey]).length : 0"
  }
  // ❌ But didn't fix getFieldValueType to handle null!
  // ❌ Incomplete fix - misses root cause
}
```

---

## Quality Checks

### Indicators of Real Trajectory (✅ GOOD)

- [ ] **15+ actions** for non-trivial tasks
- [ ] **Millisecond-precision timestamps** (e.g., `.146Z`)
- [ ] **Non-round elapsed times** (e.g., 1543 seconds, not 1500)
- [ ] **Rich details with real data:**
  - Search results with actual file paths
  - File contents with real code snippets
  - Command outputs with actual stdout/stderr
- [ ] **Natural thought progression:**
  - "I found X at path Y. Now I need to..."
  - References specific line numbers, function names
  - Shows real debugging thought process
- [ ] **May include errors/retries:**
  - Real agents make mistakes
  - Command failures
  - Incorrect first attempts

### Red Flags for Synthetic Trajectory (❌ BAD)

- [ ] **Few actions** (5-10 for non-trivial task)
- [ ] **Round timestamps** (`:00Z`, `:30Z`)
- [ ] **Round elapsed times** (0, 30, 60, 90 seconds)
- [ ] **Minimal details:**
  - Empty search results
  - No file contents
  - No command outputs
- [ ] **Generic thoughts:**
  - "Looking for the bug..."
  - "Fixing the issue..."
  - No specific references
- [ ] **Too perfect:**
  - No exploration missteps
  - Direct path to solution
  - No errors ever

---

## Testing Your Event Capture

### Validation Script

```bash
#!/bin/bash
# validate_trajectory_authenticity.sh

TRAJ_FILE="$1"

echo "🔍 Validating trajectory authenticity..."

# Check action count
ACTIONS=$(jq '.annotationTrace | length' "$TRAJ_FILE")
if [ $ACTIONS -lt 15 ]; then
  echo "⚠️  Only $ACTIONS actions (expected 15+)"
fi

# Check timestamp precision
FIRST_TS=$(jq -r '.annotationTrace[0].timestamp' "$TRAJ_FILE")
if [[ ! "$FIRST_TS" =~ \.[0-9]{3}Z$ ]]; then
  echo "❌ Timestamps lack millisecond precision"
  echo "   Real: 2025-12-01T18:27:05.146Z"
  echo "   Found: $FIRST_TS"
fi

# Check for rich details
FIRST_DETAILS=$(jq '.annotationTrace[1].details | keys | length' "$TRAJ_FILE")
if [ $FIRST_DETAILS -lt 2 ]; then
  echo "⚠️  Sparse details in actions (expected rich information)"
fi

# Check elapsed time distribution
ELAPSED=$(jq '[.annotationTrace[].elapsed_seconds] | unique | length' "$TRAJ_FILE")
if [ $ELAPSED -lt 5 ]; then
  echo "⚠️  Too few unique elapsed times (may be synthetic)"
fi

echo "✅ Validation complete"
```

---

## Best Practices

1. **Always capture from real runs** - Never manually write trajectories

2. **Keep both successful and failed runs** - Don't delete failed attempts

3. **Preserve all event data** - Rich details are valuable for training

4. **Different timestamps prove authenticity** - Ideal and failed MUST have different timestamps

5. **Validate immediately** - Check captures right after agent completes

6. **Document the setup** - Record agent version, configuration used

7. **Test trajectory quality** - Use validation scripts before finalizing

---

## Common Pitfalls

### ❌ Don't Do This:

1. **Copying and editing:**
   ```bash
   # WRONG!
   cp ideal_trajectory.json failed_trajectory.json
   # Then manually editing thoughts and removing actions
   ```

2. **Synthetic timestamps:**
   ```json
   // WRONG!
   "timestamp": "2025-07-31T14:30:00Z"  // Too clean
   ```

3. **Empty details:**
   ```json
   // WRONG!
   "details": {
     "searchString": "MyClass"  // Where are the results?
   }
   ```

4. **Perfect trajectories:**
   - Agent never explores wrong paths
   - Never makes mistakes
   - Too direct to solution

### ✅ Do This Instead:

1. **Capture from real runs:**
   ```bash
   # Run agent twice with logging enabled
   # Use both captures
   ```

2. **Preserve real timestamps:**
   ```json
   // From actual agent execution
   "timestamp": "2025-12-01T18:27:05.146Z"
   ```

3. **Include full details:**
   ```json
   "details": {
     "path": "src/",
     "searchKey": "MyClass",
     "results": [
       "src/components/MyClass.tsx:45",
       "src/utils/MyClass.test.ts:12"
     ]
   }
   ```

4. **Embrace imperfection:**
   - Real exploration paths
   - Include dead ends
   - Show actual debugging process

---

## Reference Examples

See these real captured trajectories:
- `samples/task-1/ideal_trajectory.json` - 41 actions from successful agent
- `samples/task-1/failed_trajectory.json` - 20 actions from incomplete run
- Notice: Different timestamps, different approaches, authentic behavior

---

**Remember:** Trajectories are training data for AI models. Synthetic data teaches models synthetic behavior. Real captures teach real problem-solving!

