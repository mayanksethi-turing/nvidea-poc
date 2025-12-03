# Trajectory Examples: Real vs Synthetic

This document shows concrete examples of properly captured trajectories vs synthetically created ones.

---

## ✅ Example 1: Real Captured Trajectory (CORRECT)

From `samples/task-1/ideal_trajectory.json` - A real agent session solving the tldraw bug.

### Characteristics of Real Capture:

**Action Count:** 41 actions (substantial for a real problem-solving session)

**Timestamps:** Unique with millisecond precision
```json
{
  "timestamp": "2025-12-01T18:27:05.146Z",  // Real milliseconds
  "elapsed_seconds": 100,  // Natural progression
}
```

**Rich Details:** Actual search results
```json
{
  "action": "search_string",
  "details": {
    "path": ".",
    "searchKey": "NoteShapeUtil",
    "results": [
      "packages/tldraw/src/index.ts:155",
      "packages/tldraw/src/lib/defaultShapeUtils.ts:10",
      "packages/tldraw/src/lib/shapes/note/NoteShapeUtil.tsx:70",
      "apps/examples/src/examples/resize-note/ResizeNoteExample.tsx:1"
    ]
  },
  "thought": "I found the NoteShapeUtil implementation at packages/tldraw/src/lib/shapes/note/NoteShapeUtil.tsx. Now I need to search for the useCurrentTranslation hook to understand how it's currently being used..."
}
```

**Natural Thought Process:** Shows real exploration
```json
{
  "thought": "I can see that TranslationsContext is defined on line 26 but it's not exported. The useCurrentTranslation hook on line 29 throws an error when the context is null. To fix the NoteShapeUtil issue, I need to export TranslationsContext from this file..."
}
```

**Includes Test Execution:**
```json
{
  "action": "execute_terminal_command",
  "details": {
    "command": "cd packages/tldraw && npm test 2>&1 | head -100",
    "directory": "/home/hernan/dev/turing/agentic_code/tldraw",
    "output": "All tests passed successfully. The test suite shows that NoteShapeUtil tests are passing...",
    "exitCode": 0
  }
}
```

---

## ❌ Example 2: Synthetic Trajectory (INCORRECT)

From `samples/task-9/failed_trajectory.json` - Appears to be manually written.

### Problems with This Trajectory:

**Action Count:** Only 5 actions (too few for a real session)

**Clean Timestamps:** Round numbers, no milliseconds
```json
{
  "timestamp": "2025-07-31T14:30:00Z",  // ❌ Too clean!
  "elapsed_seconds": 30,  // ❌ Round number
}
```

**Minimal Details:** No actual search results
```json
{
  "action": "search_string",
  "details": {
    "commandType": "SEARCH_CODE",
    "payload": {
      "searchString": "Object.keys",
      "searchPath": "/app"
    }
  },
  // ❌ Missing: actual search results!
  // Real capture would show file paths and line numbers
}
```

**Generic Thoughts:** Lacks specificity
```json
{
  "thought": "Looking for Object.keys usage that might be causing the crash."
  // ❌ Too vague!
  // Real: "I found Object.keys usage at Hit.js:496..."
}
```

**No Test Execution:** Missing verification step
```json
{
  "action": "end_interaction",
  "thought": "Fixed the Object.keys crash by adding a type check. This should prevent the crash on null values."
  // ❌ No test execution before ending!
  // Real agents verify their fixes
}
```

---

## Detailed Comparison

### Search Action

#### ✅ Real Capture:
```json
{
  "action": "search_string",
  "details": {
    "path": "packages/tldraw/src",
    "searchKey": "TranslationsContext",
    "results": [
      "packages/tldraw/src/lib/ui/hooks/useTranslation/useTranslation.tsx:26",
      "packages/tldraw/src/lib/ui/hooks/useTranslation/useTranslation.tsx:30",
      "packages/tldraw/src/lib/ui/hooks/useTranslation/useTranslation.tsx:93"
    ]
  },
  "thought": "I found that TranslationsContext is defined in the useTranslation.tsx file. Now I need to read this file to understand the context structure and see if TranslationsContext is exported.",
  "timestamp": "2025-12-01T18:18:45.832Z",
  "elapsed_seconds": 43,
  "duration_seconds": 0,
  "partition": "EnvironmentSetup"
}
```

#### ❌ Synthetic:
```json
{
  "action": "search_string",
  "details": {
    "commandType": "SEARCH_CODE",
    "payload": {
      "searchString": "Object.keys",
      "searchPath": "/app"
    }
  },
  "thought": "Looking for Object.keys usage that might be causing the crash.",
  "timestamp": "2025-07-31T14:30:15Z",
  "elapsed_seconds": 15,
  "duration_seconds": 3,
  "partition": "Exploration"
}
```

**Key Differences:**
1. Real has **actual search results** (file paths with line numbers)
2. Real thought **references specific files** found in results
3. Real timestamp has **millisecond precision** (`.832Z`)
4. Real elapsed time is **natural** (43 seconds, not round number)

---

### File Operation

#### ✅ Real Capture:
```json
{
  "action": "open_file",
  "details": {
    "file": "packages/tldraw/src/lib/ui/hooks/useTranslation/useTranslation.tsx"
  },
  "thought": "I've read the useTranslation hook file and the NoteShapeUtil file. I can see that TranslationsContext is defined at line 26 in useTranslation.tsx, and useCurrentTranslation throws an error when the context is null (line 32). To fix the NoteShapeUtil issue, I need to export TranslationsContext from this file so it can be imported and used directly with useContext in NoteShapeUtil.",
  "timestamp": "2025-12-01T18:27:31.247Z",
  "elapsed_seconds": 126,
  "duration_seconds": 0,
  "partition": "EnvironmentSetup"
}
```

#### ❌ Synthetic:
```json
{
  "action": "open_file",
  "details": {
    "commandType": "OPEN_FILE",
    "payload": {
      "path": "/app/src/components/Results/Hit.js"
    }
  },
  "thought": "Opening Hit.js to find the problematic code.",
  "timestamp": "2025-07-31T14:30:30Z",
  "elapsed_seconds": 30,
  "duration_seconds": 2,
  "partition": "Exploration"
}
```

**Key Differences:**
1. Real thought **references specific line numbers** from the file
2. Real thought **explains what was discovered** and next steps
3. Real elapsed time shows **natural progression** (126 seconds)
4. Synthetic thought is **generic** ("find problematic code")

---

### Code Edit

#### ✅ Real Capture:
```json
{
  "action": "find_and_replace_code",
  "details": {
    "file": "packages/tldraw/src/lib/shapes/note/NoteShapeUtil.tsx",
    "changes": [
      {
        "originalText": {
          "startLine": 32,
          "endLine": 36,
          "context": "\tuseValue,\n} from '@tldraw/editor'\nimport { useCallback } from 'react'\nimport { startEditingShapeWithLabel } from '../../tools/SelectTool/selectHelpers'\nimport { useCurrentTranslation } from '../../ui/hooks/useTranslation/useTranslation'"
        },
        "newText": {
          "startLine": 32,
          "endLine": 36,
          "context": "\tuseValue,\n} from '@tldraw/editor'\nimport { useCallback, useContext } from 'react'\nimport { startEditingShapeWithLabel } from '../../tools/SelectTool/selectHelpers'\nimport { TranslationsContext } from '../../ui/hooks/useTranslation/useTranslation'"
        }
      }
    ]
  },
  "thought": "Good, I've updated the imports. Now I need to update the actual usage of the hook in the useNoteKeydownHandler function on line 496. I'll change from useCurrentTranslation() to useContext(TranslationsContext), and then update the code that accesses translation.dir to use optional chaining (translation?.dir).",
  "timestamp": "2025-12-02T19:19:46.869Z",
  "elapsed_seconds": 104,
  "duration_seconds": 0,
  "partition": "Solution"
}
```

#### ❌ Synthetic:
```json
{
  "action": "find_and_replace_code",
  "details": {
    "commandType": "EDIT_FILE",
    "context": "/app/src/components/Results/Hit.js",
    "payload": {
      "filePath": "/app/src/components/Results/Hit.js",
      "oldCode": "const FieldValue = ({ hit, objectKey }) => {\n  const fieldValueType = getFieldValueType(hit[objectKey])\n  const sizeOfObject = Object.keys(hit[objectKey])?.length || 0",
      "newCode": "const FieldValue = ({ hit, objectKey }) => {\n  const fieldValueType = getFieldValueType(hit[objectKey])\n  let sizeOfObject = 0\n  if (fieldValueType === 'array' || fieldValueType === 'object') {\n    sizeOfObject = Object.values(hit[objectKey]).length\n  }"
    }
  },
  "thought": "Found the issue - Object.keys is being called on potentially null values. Adding a guard to only calculate size when the value is an array or object.",
  "timestamp": "2025-07-31T14:31:30Z",
  "elapsed_seconds": 90,
  "duration_seconds": 10,
  "partition": "Solution"
}
```

**Key Differences:**
1. Real provides **exact line numbers** and surrounding context
2. Real thought **references specific implementation details**
3. Real shows **iterative problem-solving** ("Now I need to...")
4. Synthetic thought is **more generic** description

---

### Terminal Command

#### ✅ Real Capture:
```json
{
  "action": "execute_terminal_command",
  "details": {
    "command": "cd packages/tldraw && npx eslint src/lib/shapes/note/NoteShapeUtil.tsx src/lib/ui/hooks/useTranslation/useTranslation.tsx 2>&1",
    "directory": "packages/tldraw",
    "output": "",
    "error": "",
    "exitCode": 0
  },
  "thought": "Excellent! The eslint check passed with no errors, which means my code changes follow the project's linting rules and coding standards. Now let me verify the changes are correct by reading the modified files to confirm all the changes were applied properly.",
  "timestamp": "2025-12-01T18:23:46.714Z",
  "elapsed_seconds": 344,
  "duration_seconds": 0,
  "partition": "Solution"
}
```

#### ❌ Synthetic (missing!):
```json
// NO terminal command execution in synthetic trajectory!
// Agent just ends without verification
{
  "action": "end_interaction",
  "thought": "The fix looks correct, should be good now"
  // ❌ No test execution!
}
```

**Key Difference:**
- Real agent **runs tests/linters** to verify
- Synthetic **assumes fix works** without verification

---

## Timestamp Analysis

### ✅ Real Trajectory Timestamps:
```
2025-12-01T18:25:50.078Z  (elapsed:   25s, duration: 0s)
2025-12-01T18:27:05.146Z  (elapsed:  100s, duration: 0s)
2025-12-01T18:27:15.644Z  (elapsed:  110s, duration: 0s)
2025-12-01T18:27:31.247Z  (elapsed:  126s, duration: 0s)
2025-12-01T18:27:55.122Z  (elapsed:  150s, duration: 0s)
2025-12-01T18:28:22.828Z  (elapsed:  178s, duration: 0s)
```

**Analysis:**
- ✅ Milliseconds change naturally (.078, .146, .644, .247, .122, .828)
- ✅ Elapsed times are not round numbers (25, 100, 110, 126, 150, 178)
- ✅ Shows natural progression of a real agent thinking and acting

### ❌ Synthetic Trajectory Timestamps:
```
2025-07-31T14:30:00Z      (elapsed:    0s, duration: 0s)
2025-07-31T14:30:15Z      (elapsed:   15s, duration: 3s)
2025-07-31T14:30:30Z      (elapsed:   30s, duration: 2s)
2025-07-31T14:31:30Z      (elapsed:   90s, duration: 10s)
2025-07-31T14:32:00Z      (elapsed:  120s, duration: 0s)
```

**Analysis:**
- ❌ All timestamps end in `:00Z` or `:15Z` or `:30Z` (too clean!)
- ❌ No milliseconds (real captures always have them)
- ❌ Elapsed times are perfect intervals (0, 15, 30, 90, 120)
- ❌ Looks manually constructed, not from real execution

---

## Failed Trajectory Comparison

### ✅ Real Failed Trajectory (task-1):

**Different timestamps from ideal:**
```
Ideal:  2025-12-01T18:25:50.078Z
Failed: 2025-12-02T19:18:10.907Z
// ✅ Different day and time - proves different run!
```

**Authentic failure pattern:**
```json
{
  "action": "execute_terminal_command",
  "details": {
    "command": "cd packages/tldraw && npm run build 2>&1 | head -100",
    "output": "Error: ENOENT: no such file or directory...",
    "exitCode": 1
  },
  "thought": "The build failed because it's looking for a pre-generated API file that doesn't exist. This is likely a build artifact issue and not related to my changes."
}
```

**Shows real agent recovery attempts:**
```json
{
  "thought": "Let me try running TypeScript compilation directly to check if my code changes are syntactically correct."
}
```

### ❌ Synthetic Failed Trajectory (task-9):

**Same timestamp pattern as ideal:**
```
Both use clean timestamps: 14:30:00Z, 14:30:15Z, 14:30:30Z
// ❌ Indicates both were manually created at same time
```

**Generic failure:**
```json
{
  "action": "end_interaction",
  "thought": "Fixed the Object.keys crash by adding a type check. This should prevent the crash on null values."
  // ❌ Just shortened version of ideal
  // ❌ Not from a real failed agent run
}
```

---

## Summary Checklist

### Real Trajectory Indicators ✅

- [ ] **15+ actions** for complex tasks
- [ ] **Millisecond-precision timestamps**
- [ ] **Non-round elapsed times** (125s, not 120s)
- [ ] **Rich details:**
  - Actual search results with paths
  - Real command outputs
  - File contents or snippets
- [ ] **Natural thought progression:**
  - References specific discoveries
  - Shows iterative problem-solving
  - Adjusts approach based on findings
- [ ] **Test/verification execution**
- [ ] **May include errors/retries** (real agents aren't perfect)

### Synthetic Trajectory Red Flags ❌

- [ ] **Few actions** (< 10)
- [ ] **Clean timestamps** (`:00Z`, `:30Z`)
- [ ] **Round elapsed times** (30s, 60s, 90s)
- [ ] **Minimal details:**
  - No search results
  - No command outputs
  - Generic descriptions
- [ ] **Generic thoughts:**
  - "Looking for..."
  - "Fixing..."
  - No specifics
- [ ] **No test execution**
- [ ] **Too perfect** (no exploration dead-ends)
- [ ] **Copied timestamps** (failed matches ideal)

---

## How to Avoid Creating Synthetic Trajectories

1. **Never manually write trajectories** - Always capture from real runs

2. **Run the agent twice:**
   - First run: Capture full session
   - Second run: Capture with constraints or stop early

3. **Preserve authenticity:**
   - Don't edit timestamps
   - Don't sanitize "messy" exploration
   - Keep real command outputs (even errors)

4. **Validate with script:**
   ```bash
   ./.claude/scripts/validate-sample.sh samples/task-N
   # Will detect synthetic patterns
   ```

5. **Compare with task-1:**
   - Your trajectories should have similar depth and detail
   - Not the same structure, but same level of richness

---

## Real-World Example from task-1

Here's a complete real action showing all characteristics:

```json
{
  "action": "find_and_replace_code",
  "details": {
    "file": "packages/tldraw/src/lib/ui/hooks/useTranslation/useTranslation.tsx",
    "changes": [
      {
        "originalText": {
          "startLine": 23,
          "endLine": 26,
          "context": "/** @public */\nexport type TLUiTranslationContextType = TLUiTranslation\n\nconst TranslationsContext = React.createContext<TLUiTranslationContextType | null>(null)"
        },
        "newText": {
          "startLine": 23,
          "endLine": 29,
          "context": "/** @public */\nexport type TLUiTranslationContextType = TLUiTranslation\n\n/**\n * @internal\n */\nexport const TranslationsContext = React.createContext<TLUiTranslationContextType | null>(null)"
        }
      }
    ]
  },
  "thought": "I've successfully exported TranslationsContext with the @internal annotation. Now I need to update the tldraw index.ts file to export TranslationsContext, and then modify NoteShapeUtil to use useContext directly with optional chaining instead of useCurrentTranslation.",
  "timestamp": "2025-12-01T18:29:05.746Z",
  "elapsed_seconds": 221,
  "duration_seconds": 0,
  "partition": "Solution"
}
```

**What makes this real:**
1. Exact line numbers (23-26 → 23-29)
2. Full code context with proper formatting
3. Specific thought about what was done and next steps
4. Natural timestamp (`.746Z`)
5. Natural elapsed time (221 seconds)
6. Shows iterative progress ("successfully exported... now I need to...")

---

**Remember:** Real trajectories are training data. Synthetic data teaches synthetic behavior. Only capture from real agent runs!

