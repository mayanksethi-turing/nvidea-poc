# metadata.json Schema

## Standard Format (Preferred - Based on task-1)

This is the **recommended format** for all task samples.

```json
{
  "author": "string",
  "repo": "string (GitHub URL)",
  "head": "string (commit SHA after fix)",
  "prNumber": "string (PR number)",
  "failure": "string (description of failure mode)",
  "inputTokens": number,
  "outputTokens": number
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `author` | string | ✅ | GitHub username or name of person who worked on the sample |
| `repo` | string | ✅ | Full GitHub repository URL (e.g., `https://github.com/tldraw/tldraw`) |
| `head` | string | ✅ | Git commit SHA after the fix is applied (commit_after) |
| `prNumber` | string | ✅ | Pull request number as string (e.g., `"7007"`) |
| `failure` | string | ✅ | Description of what went wrong in the failed trajectory |
| `inputTokens` | number | ⚠️  | Estimated input tokens used (optional but recommended) |
| `outputTokens` | number | ⚠️  | Estimated output tokens used (optional but recommended) |

### Common Failure Modes

Use these standard descriptions for the `failure` field:

- `"Incomplete Solution / Inadequate Verification"` - Agent skipped testing/verification
- `"Partial Fix / Missing Edge Cases"` - Only fixed part of the problem
- `"Wrong Root Cause / Incorrect Fix"` - Misdiagnosed the issue
- `"Insufficient Testing / No Verification"` - No test execution
- `"Multi-file Change / Missed Files"` - Forgot to update related files
- `"Hasty Implementation / No Code Review"` - Rushed without checking

---

## Alternative Format (Acceptable)

Some tasks may use this extended format with additional metadata:

```json
{
  "repository_url": "string",
  "commit_before": "string",
  "commit_after": "string",
  "pr_number": number,
  "pr_url": "string",
  "branch": "string",
  "author": "string",
  "date": "string (ISO 8601)",
  "difficulty": "easy|medium|hard",
  "issue_type": "BugFix|Feature|Refactor",
  "tech_tags": ["array", "of", "strings"],
  "failure": "string",
  "inputTokens": number,
  "outputTokens": number
}
```

**Note:** This format is acceptable but should include the core fields from the standard format.

---

## Example: task-1 (Ideal Reference)

```json
{
  "author": "hernanmog-turing",
  "repo": "https://github.com/tldraw/tldraw",
  "head": "8e28283dc716412e31ce3713e61c9870174d9688",
  "prNumber": "7007",
  "failure": "Incomplete Solution / Inadequate Verification",
  "inputTokens": 13600,
  "outputTokens": 1900000
}
```

---

## Example: Extended Format

```json
{
  "repository_url": "https://github.com/outline/outline",
  "commit_before": "82021b685ec6b961f1bdedde295bf19a9c1f1e91",
  "commit_after": "1be502105a50d67a74b8e3e0b6e9b1a8ea59774c",
  "pr_number": 10705,
  "pr_url": "https://github.com/outline/outline/pull/10705",
  "branch": "main",
  "author": "task-coordinator",
  "date": "2024-12-03T00:00:00Z",
  "difficulty": "medium",
  "issue_type": "BugFix",
  "tech_tags": ["TypeScript", "React", "Mermaid.js"],
  "failure": "Incomplete Solution / Inadequate Verification",
  "inputTokens": 15000,
  "outputTokens": 2000000,
  "repo": "https://github.com/outline/outline",
  "head": "1be502105a50d67a74b8e3e0b6e9b1a8ea59774c",
  "prNumber": "10705"
}
```

---

## Validation

### Required Fields Check

```bash
# Standard format validation
jq -e '.author, .repo, .head, .prNumber, .failure' metadata.json > /dev/null || {
  echo "❌ Missing required fields in metadata.json"
  exit 1
}

# Verify failure field is not empty
FAILURE=$(jq -r '.failure' metadata.json)
if [ -z "$FAILURE" ] || [ "$FAILURE" == "null" ]; then
  echo "❌ failure field is missing or empty"
  exit 1
fi

echo "✅ metadata.json validation passed"
```

### Field Type Validation

```bash
# Check that prNumber is a string (standard format)
jq -e '.prNumber | type == "string"' metadata.json > /dev/null || {
  echo "⚠️  Warning: prNumber should be a string in standard format"
}

# Check that token counts are numbers if present
if jq -e '.inputTokens' metadata.json > /dev/null 2>&1; then
  jq -e '.inputTokens | type == "number"' metadata.json > /dev/null || {
    echo "❌ inputTokens must be a number"
    exit 1
  }
fi

if jq -e '.outputTokens' metadata.json > /dev/null 2>&1; then
  jq -e '.outputTokens | type == "number"' metadata.json > /dev/null || {
    echo "❌ outputTokens must be a number"
    exit 1
  }
fi
```

---

## Migration Guide

If you have metadata.json in alternative format, add these fields to match standard format:

```bash
# Map alternative fields to standard format
REPO_URL=$(jq -r '.repository_url // .repo' metadata.json)
COMMIT_AFTER=$(jq -r '.commit_after // .head' metadata.json)
PR_NUM=$(jq -r '.pr_number // .prNumber' metadata.json)

# Update metadata.json to include standard fields
jq ". + {repo: \"$REPO_URL\", head: \"$COMMIT_AFTER\", prNumber: \"$PR_NUM\"}" metadata.json > metadata.json.tmp
mv metadata.json.tmp metadata.json
```

---

## Best Practices

1. **Always use standard format** for new tasks (task-1 style)
2. **Include failure field** - describes the failure pattern in failed_trajectory.json
3. **Use string for prNumber** - consistent with task-1 format
4. **Include token estimates** - helps track costs
5. **Keep failure descriptions** consistent with common patterns
6. **Validate** before finalizing the task

---

## Related Files

- Task samples: `samples/task-*/metadata.json`
- Reference implementation: `samples/task-1/metadata.json`
- Trajectory schema: `.claude/schemas/trajectory-schema.md`
- Validation script: `.claude/scripts/validate-sample.sh`

