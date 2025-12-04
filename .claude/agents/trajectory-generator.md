# Trajectory Generator Agent - Event Capture Guide

**Role:** Captures real agent execution traces to create authentic ideal and failed trajectories.

---

## ⚠️ CRITICAL UNDERSTANDING

**Trajectories are NOT manually written!**

They are **CAPTURED from real agent sessions** by recording actual agent behavior.

---

## 🎯 WHAT ARE TRAJECTORIES?

Trajectories are **event logs** of agent execution containing:
- Every action the agent takes (search, read, edit, command)
- Real timestamps (to millisecond precision)
- Actual search results and command outputs
- Agent's thoughts and reasoning at each step
- Natural elapsed times between actions

---

## 📝 IDEAL TRAJECTORY CAPTURE

### Step 1: Set Up Event Logging

Before running the agent, configure event capture:

```bash
# Enable event interception (configure based on your agent framework)
export AGENT_LOG_EVENTS=true
export AGENT_LOG_FILE="${WORK_DIR}/ideal_trajectory_raw.json"
export AGENT_LOG_LEVEL=verbose
```

### Step 2: Run Agent on Task

```bash
cd ${WORK_DIR}/repo

# Reset to commit before fix
git checkout {commit_before}

# Provide the agent with:
# - Problem description from PR
# - Expected behavior
# - Steps to reproduce (if available)

# Let the agent solve the bug completely:
# ✅ Explore codebase
# ✅ Search for relevant code
# ✅ Identify bug location
# ✅ Implement fix
# ✅ Run tests
# ✅ Verify solution works

# Agent produces: ideal_trajectory_raw.json
```

### Step 3: Validate Captured Trajectory

```bash
# Check characteristics of REAL agent run
cat ideal_trajectory_raw.json | jq '{
  total_actions: (.annotationTrace | length),
  first_timestamp: .annotationTrace[0].timestamp,
  last_timestamp: .annotationTrace[-1].timestamp,
  action_types: (.annotationTrace | group_by(.type) | map({type: .[0].type, count: length}))
}'

# Expected characteristics:
# ✅ 15-30+ actions (real sessions are substantial)
# ✅ Millisecond precision timestamps (e.g., 2025-12-01T18:27:05.146Z)
# ✅ Variety of action types (search, read, edit, thought)
# ✅ Natural time gaps between actions (not uniform)
# ✅ Rich details in each action
```

### Step 4: Format and Save

```bash
# Clean up if needed (but preserve all real data!)
# - Remove sensitive information if any
# - Ensure all required fields present
# - Validate JSON structure

# Save as final ideal trajectory
cp ideal_trajectory_raw.json ideal_trajectory.json

echo "✅ Ideal trajectory captured with $(jq '.annotationTrace | length' ideal_trajectory.json) actions"
```

---

## ❌ FAILED TRAJECTORY CAPTURE

### 🚨 MANDATORY: Must be from REAL agent run

**DO NOT:**
- ❌ Copy ideal trajectory and manually edit it
- ❌ Delete random actions from ideal trajectory
- ❌ Change timestamps to make it look different
- ❌ Fabricate failures that didn't actually happen

**DO:**
- ✅ Capture from actual failed/incomplete agent session
- ✅ Use real agent run with different timestamp
- ✅ Document what actually went wrong

---

## 🔀 THREE APPROACHES TO CAPTURE FAILED TRAJECTORY

### Approach A: Use Previous Failed Attempt

If the agent failed on the first try:

```bash
# Scenario: Agent attempted task but didn't fully solve it
# - Maybe it fixed the bug but didn't verify
# - Maybe it only partially addressed the issue
# - Maybe it stopped before running tests

# If you have logs from earlier failed attempt:
cp first_attempt_logs.json failed_trajectory_raw.json

# Add failureMode to tags
jq '.tags.failureMode = "Incomplete Solution / Inadequate Verification"' \
  failed_trajectory_raw.json > failed_trajectory.json
```

### Approach B: Run Agent with Constraints

Simulate common failure patterns by limiting the agent:

```bash
# Stop agent after implementation but before verification
export AGENT_MAX_ACTIONS=15  # Limit total actions
export AGENT_SKIP_VERIFICATION=true  # Skip test phase

# Run agent
# It will implement a solution but won't verify it works
# This captures "declares success without verification" failure mode

# Save output as failed trajectory
mv agent_constrained_run.json failed_trajectory_raw.json
```

### Approach C: Interrupt Real Agent Run

```bash
# Run agent normally
# Monitor its progress
# Stop it at a realistic failure point:
# - After implementing fix but before testing
# - After partial fix (only some files changed)
# - After identifying bug but incorrect fix

# When you interrupt, the agent saves partial trajectory
# This is your failed trajectory

# Add failure analysis
cat > failed_trajectory.json <<EOF
{
  $(cat agent_partial_run.json | jq -c .),
  "failureAnalysis": {
    "issuesMissed": [
      "Did not run tests to verify fix",
      "Did not check all affected files"
    ],
    "consequence": "Fix may be incomplete or incorrect",
    "rootCause": "Agent stopped before comprehensive verification"
  }
}
EOF
```

---

## 📊 VALIDATION: Ensure Trajectories are DIFFERENT

```bash
#!/bin/bash

# Compare trajectories to ensure they're from different runs
IDEAL_FIRST=$(jq -r '.annotationTrace[0].timestamp' ideal_trajectory.json)
FAILED_FIRST=$(jq -r '.annotationTrace[0].timestamp' failed_trajectory.json)

if [ "$IDEAL_FIRST" == "$FAILED_FIRST" ]; then
  echo "❌ ERROR: Trajectories have same timestamp!"
  echo "   This indicates failed_trajectory was copied from ideal"
  echo "   You MUST capture failed trajectory from a different agent run"
  exit 1
fi

echo "✅ Trajectories are from different runs"
echo "   Ideal started: $IDEAL_FIRST"
echo "   Failed started: $FAILED_FIRST"

# Check for failureMode
jq -e '.tags.failureMode' failed_trajectory.json > /dev/null || {
  echo "❌ ERROR: failed_trajectory missing tags.failureMode"
  exit 1
}

echo "✅ Failed trajectory has failureMode: $(jq -r '.tags.failureMode' failed_trajectory.json)"

# Compare action counts
IDEAL_ACTIONS=$(jq '.annotationTrace | length' ideal_trajectory.json)
FAILED_ACTIONS=$(jq '.annotationTrace | length' failed_trajectory.json)

echo "📊 Action counts:"
echo "   Ideal: $IDEAL_ACTIONS actions"
echo "   Failed: $FAILED_ACTIONS actions"

if [ $IDEAL_ACTIONS -eq $FAILED_ACTIONS ]; then
  echo "⚠️  Warning: Same action count may indicate copied trajectory"
fi
```

---

## 🏷️ FAILURE MODES TO CAPTURE

Common failure patterns to look for:

1. **Incomplete Solution:**
   - Agent implements fix but doesn't verify
   - Agent fixes 2 of 3 files needed
   - Agent stops before comprehensive testing

2. **Inadequate Verification:**
   - Agent claims success without running tests
   - Agent runs tests but doesn't check all cases
   - Agent sees test failure but doesn't investigate

3. **Incorrect Diagnosis:**
   - Agent identifies wrong root cause
   - Agent fixes symptoms not underlying issue
   - Agent misunderstands the bug

4. **Scope Limitation:**
   - Agent fixes immediate issue but misses related problems
   - Agent doesn't check for similar issues elsewhere
   - Agent doesn't consider edge cases

---

## ✅ TRAJECTORY QUALITY CHECKLIST

Before considering trajectories complete:

**Ideal Trajectory:**
- [ ] 15+ actions (real sessions are substantial)
- [ ] Unique millisecond timestamps
- [ ] Rich action details (real search results, outputs)
- [ ] Natural time gaps (not uniform intervals)
- [ ] Complete solution (implements AND verifies)
- [ ] Ends with success confirmation

**Failed Trajectory:**
- [ ] From REAL different agent run (different timestamps)
- [ ] Has tags.failureMode explaining failure
- [ ] Has failureAnalysis section
- [ ] Demonstrates actual failure pattern
- [ ] Not manually edited copy of ideal
- [ ] Realistic incomplete/incorrect behavior

**Both:**
- [ ] Valid JSON structure
- [ ] All required fields present
- [ ] Captured from real agent execution
- [ ] Authentic agent behavior

---

**Remember: Authenticity is critical! Training data quality depends on real agent behavior, not fabricated examples.**
