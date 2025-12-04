#!/bin/bash
set -e

TASK_ID="task-17"

echo "======================================"
echo "Building Docker Image"
echo "======================================"
docker build -t bug-fix-sample-${TASK_ID} .

echo ""
echo "======================================"
echo "Creating Container"
echo "======================================"
CONTAINER_ID=$(docker create bug-fix-sample-${TASK_ID})

echo ""
echo "======================================"
echo "Phase 1: Pre-Fix Build (Should PASS)"
echo "======================================"
echo "Building project at commit BEFORE fix..."
docker start -a $CONTAINER_ID > PASS_pre_tests.log 2>&1 && {
    echo "✅ PASSED - Project builds successfully before fix"
    cat PASS_pre_tests.log | tail -20
} || {
    echo "❌ FAILED - Project should build before fix"
    cat PASS_pre_tests.log | tail -20
    exit 1
}

echo ""
echo "======================================"
echo "Phase 2: Applying fix.patch"
echo "======================================"
docker cp fix.patch $CONTAINER_ID:/tmp/fix.patch
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "git apply /tmp/fix.patch" && {
    echo "✅ fix.patch applied successfully"
} || {
    echo "❌ fix.patch failed to apply"
    docker stop $CONTAINER_ID
    exit 1
}
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Phase 3: Post-Fix Build (Should PASS)"
echo "======================================"
echo "Building project after applying fix..."
docker start -a $CONTAINER_ID > PASS_post_patch.log 2>&1 && {
    echo "✅ PASSED - Project builds successfully after fix"
    cat PASS_post_patch.log | tail -20
} || {
    echo "❌ FAILED - Project should build after fix"
    cat PASS_post_patch.log | tail -20
    docker stop $CONTAINER_ID
    exit 1
}

echo ""
echo "======================================"
echo "Phase 4: Verify Fix Content"
echo "======================================"
echo "Checking that expected changes are present..."

# Check for case-insensitive header parsing
docker exec $CONTAINER_ID bash -c "grep -q 'strings.ToLower' pkg/agent/proxy/integrations/http/chunk.go" && {
    echo "✅ Case-insensitive header parsing found"
} || {
    echo "❌ Expected code changes NOT found"
    docker stop $CONTAINER_ID
    exit 1
}

# Check that the fix is in both functions
TOLOWER_COUNT=$(docker exec $CONTAINER_ID bash -c "grep -c 'strings.ToLower' pkg/agent/proxy/integrations/http/chunk.go")
if [ "$TOLOWER_COUNT" -ge 3 ]; then
    echo "✅ Case-insensitive parsing applied to multiple locations ($TOLOWER_COUNT instances)"
else
    echo "⚠️  Only $TOLOWER_COUNT instances found (expected 3+)"
fi

echo ""
echo "======================================"
echo "Validation Complete"
echo "======================================"
echo "✅ All validations passed!"
echo "   - Project builds before fix"
echo "   - Patch applies cleanly"
echo "   - Project builds after fix"
echo "   - Case-insensitive header parsing implemented"

docker rm $CONTAINER_ID
