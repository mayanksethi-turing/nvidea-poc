# Validator Agent - Sample Quality Assurance

**Role:** Ensures sample completeness, validates metadata, and performs final quality checks.

---

## 📋 VALIDATION CHECKLIST

### Phase 5.1: Create metadata.json

**IMPORTANT: metadata.json Structure Requirements**

#### Required Fields (Task-1 Format - PREFERRED):

```json
{
  "author": "mayanksethi-turing",
  "repo": "{full_repo_url}",
  "head": "{commit_hash_before_fix}",
  "prNumber": "{pr_number_as_string}",
  "failure": "{SPECIFIC_FAILURE_MODE}",
  "inputTokens": {estimated_input_tokens},
  "outputTokens": {estimated_output_tokens}
}
```

#### Failure Mode Categories (MUST BE SPECIFIC):

**DO NOT use generic "BugFix" - use one of these specific categories:**

1. **Logic Errors:**
   - "Logic Error / Infinite Redirect Loop"
   - "Logic Error / Race Condition"
   - "Logic Error / Off-by-One Error"
   - "Logic Error / Incorrect Conditional"
   
2. **Type/Schema Errors:**
   - "Schema Data Type Error / Type Mismatch"
   - "Type Error / Null Pointer Exception"
   - "Type Error / Type Coercion Issue"
   
3. **Integration Errors:**
   - "Integration Error / Tight Component Coupling"
   - "Integration Error / Missing Dependency Injection"
   - "Integration Error / API Contract Mismatch"
   
4. **UI/Styling Errors:**
   - "UI/Styling Error / Z-Index Layer Conflict"
   - "UI Error / Broken Responsive Layout"
   - "UI Error / Incorrect CSS Selector"
   
5. **Performance Errors:**
   - "Performance Error / Memory Leak"
   - "Performance Error / N+1 Query Problem"
   - "Performance Error / Unnecessary Re-renders"
   
6. **State Management Errors:**
   - "State Error / Stale Closure"
   - "State Error / Missing State Update"
   - "State Error / Incorrect Dependency Array"
   
7. **Validation/Security Errors:**
   - "Validation Error / Input Not Sanitized"
   - "Security Error / XSS Vulnerability"
   - "Security Error / CORS Misconfiguration"
   
8. **Error Handling:**
   - "Error Handling / Unhandled Exception"
   - "Error Handling / Silent Failure"
   - "Error Handling / Incorrect Error Propagation"

#### Token Estimation Guidelines:

**Input Tokens (Typical Ranges):**
- Small bug fix: 5,000 - 15,000 tokens
- Medium bug fix: 15,000 - 30,000 tokens
- Large bug fix: 30,000 - 50,000 tokens

**Output Tokens (Typical Ranges):**
- Small bug fix: 1,000 - 3,000 tokens
- Medium bug fix: 3,000 - 8,000 tokens
- Large bug fix: 8,000 - 15,000 tokens

**Calculate based on:**
- Lines of code in files read/modified
- Number of search operations
- Command outputs
- Thoughts and reasoning

---

## 🚨 MANDATORY REQUIREMENTS

### failed_trajectory.json is REQUIRED

**Every sample MUST include failed_trajectory.json with:**

1. **From a REAL agent run** (not manually edited)
2. **Different timestamps** than ideal trajectory
3. **tags.failureMode** field explaining what went wrong
4. **failureAnalysis** section with:
   - issuesMissed: list of things the failed agent didn't do
   - consequence: what happened as a result
   - rootCause: why the agent failed

**Example failed_trajectory.json structure:**

```json
{
  "taskId": "...",
  "description": "...",
  "startTime": "2025-12-03T14:22:17.384Z",
  "endTime": "2025-12-03T14:35:29.127Z",
  "success": false,
  "tags": {
    "language": "typescript",
    "framework": "remix-react",
    "bugType": "UI/Styling Bug",
    "difficulty": "medium",
    "failureMode": "Incomplete Implementation / Missing Global Scope"
  },
  "annotationTrace": [
    // ... real agent actions with timestamps
  ],
  "failureAnalysis": {
    "issuesMissed": [
      "Did not move ToastContainer from Chat.client.tsx to root.tsx",
      "Did not add success toasts to all deployment services"
    ],
    "consequence": "Toasts may still not appear in some contexts",
    "rootCause": "Agent identified surface issue but didn't expand scope"
  }
}
```

---

## 📊 PHASE 6: METADATA ENRICHMENT

After Phase 5 completes, the metadata enrichment script automatically adds:

### Enriched Sections:

1. **taskGoal:**
   ```json
   "taskGoal": {
     "summary": "Fix toast visibility issue",
     "problemStatement": "Toast messages appearing behind other elements",
     "expectedOutcome": "Toasts appear above all UI elements"
   }
   ```

2. **failureModeAnalysis:**
   ```json
   "failureModeAnalysis": {
     "failureType": "UI/Styling Error / Z-Index Layer Conflict",
     "failureCategory": "Incomplete Implementation",
     "failureDescription": "...",
     "rootCause": "...",
     "consequence": "...",
     "issuesMissed": [...]
   }
   ```

3. **stepLevelMetrics:**
   ```json
   "stepLevelMetrics": {
     "totalSteps": {
       "idealTrajectory": 22,
       "failedTrajectory": 12
     },
     "toolCallBreakdown": {
       "idealTrajectory": {
         "thought": 6,
         "search": 4,
         "read_file": 8,
         "edit_file": 8
       },
       "failedTrajectory": {...}
     },
     "wallTime": {...},
     "tokenCounts": {...}
   }
   ```

4. **diffSemantics:**
   ```json
   "diffSemantics": {
     "filesChanged": 8,
     "totalLinesAdded": 70,
     "totalLinesRemoved": 34,
     "modifiedFiles": [...],
     "changedSymbols": [...]
   }
   ```

5. **testExecution:**
   ```json
   "testExecution": {
     "hasAutomatedTests": true,
     "testType": "automated",
     "preTestStatus": {
       "totalTests": 118,
       "passed": 118,
       "coverage": 92.6
     },
     "postPatchStatus": {...}
   }
   ```

6. **navigationMetrics:**
   ```json
   "navigationMetrics": {
     "idealTrajectory": {
       "filesOpened": 11,
       "filesEdited": 8,
       "editPrecision": 0.73,
       "filesOpenedList": [...],
       "filesEditedList": [...]
     },
     "failedTrajectory": {
       "missedFiles": [...]
     }
   }
   ```

7. **planAndMemorySignals:**
   ```json
   "planAndMemorySignals": {
     "idealTrajectory": {
       "thoughtActionsCount": 6,
       "planAdherence": 1.0,
       "verificationStepsCompleted": true
     },
     "failedTrajectory": {
       "thoughtActionsCount": 4,
       "planAdherence": 0.5
     }
   }
   ```

---

## ✅ FINAL VALIDATION

Before declaring sample complete, verify:

1. **All Files Present:**
   - [ ] metadata.json (enriched)
   - [ ] fix.patch
   - [ ] tests.patch
   - [ ] ideal_trajectory.json
   - [ ] failed_trajectory.json ⚠️ MANDATORY
   - [ ] Dockerfile
   - [ ] run.sh (executable)
   - [ ] PASS_pre_tests.log
   - [ ] FAIL_pre_patch.log
   - [ ] PASS_post_patch.log

2. **Metadata Quality:**
   - [ ] author: "mayanksethi-turing" (NOT "system-generated")
   - [ ] failure: Specific mode (NOT "BugFix")
   - [ ] inputTokens > 0 (NOT 0)
   - [ ] outputTokens > 0 (NOT 0)
   - [ ] All enrichment sections present

3. **Trajectory Quality:**
   - [ ] Both trajectories exist
   - [ ] Different timestamps (proves different runs)
   - [ ] Failed has failureMode in tags
   - [ ] Ideal has 15+ actions (real session)
   - [ ] Rich details (search results, outputs)

4. **Validation Cycle:**
   - [ ] Pre-tests: PASS
   - [ ] After tests.patch: FAIL
   - [ ] After fix.patch: PASS

---

**Remember: Quality over speed. A complete, enriched sample is better than a quick, incomplete one!**
