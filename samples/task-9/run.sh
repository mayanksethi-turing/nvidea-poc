#!/bin/bash
set -e

TASK_ID="task-9"
IMAGE_NAME="bug-fix-sample-${TASK_ID}"

echo "======================================"
echo "Building Docker Image"
echo "======================================"
docker build -t "$IMAGE_NAME" .

echo ""
echo "======================================"
echo "Creating Container"
echo "======================================"
CONTAINER_ID=$(docker create "$IMAGE_NAME")

echo ""
echo "======================================"
echo "Phase 1: Pre-Lint (Should PASS)"
echo "======================================"
docker start -a $CONTAINER_ID > PASS_pre_tests.log 2>&1 && echo "✅ PASSED" || echo "❌ FAILED"

echo ""
echo "======================================"
echo "Phase 2: Applying tests.patch"
echo "======================================"
# Note: tests.patch is empty for this PR
if [ -s tests.patch ]; then
    docker cp tests.patch $CONTAINER_ID:/tmp/tests.patch
    docker start $CONTAINER_ID
    docker exec $CONTAINER_ID bash -c "git apply /tmp/tests.patch"
    docker stop $CONTAINER_ID
    echo "✓ tests.patch applied"
else
    echo "ℹ️  tests.patch is empty (no test changes in PR)"
fi

echo ""
echo "======================================"
echo "Phase 3: After tests.patch (Should PASS - no changes)"
echo "======================================"
docker start -a $CONTAINER_ID > FAIL_pre_patch.log 2>&1 && echo "✅ PASSED" || echo "❌ FAILED"

echo ""
echo "======================================"
echo "Phase 4: Reverting to buggy state and testing"
echo "======================================"
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "git reset --hard HEAD"
docker stop $CONTAINER_ID
echo "✓ Reverted to commit before fix"

echo ""
echo "======================================"
echo "Phase 5: Applying fix.patch"
echo "======================================"
docker cp fix.patch $CONTAINER_ID:/tmp/fix.patch
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "git apply /tmp/fix.patch"
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Phase 6: After fix.patch (Should PASS)"
echo "======================================"
docker start -a $CONTAINER_ID > PASS_post_patch.log 2>&1 && echo "✅ PASSED" || echo "❌ FAILED"

echo ""
echo "======================================"
echo "Validation Complete"
echo "======================================"

docker rm $CONTAINER_ID
docker rmi "$IMAGE_NAME"

echo ""
echo "Results:"
echo "  - PASS_pre_tests.log: Initial state should pass lint"
echo "  - FAIL_pre_patch.log: After empty tests.patch (should still pass)"
echo "  - PASS_post_patch.log: After fix.patch should pass lint"
