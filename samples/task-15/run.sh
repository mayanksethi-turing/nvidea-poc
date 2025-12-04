#!/bin/bash
set -e

echo "======================================"
echo "Building Docker Image"
echo "======================================"
docker build -t bug-fix-sample-task-15 .

echo ""
echo "======================================"
echo "Creating Container"
echo "======================================"
CONTAINER_ID=$(docker create bug-fix-sample-task-15)

echo ""
echo "======================================"
echo "Phase 1: Pre-Tests (Should PASS)"
echo "======================================"
docker start -a $CONTAINER_ID > PASS_pre_tests.log 2>&1 && echo "✅ PASSED" || echo "❌ FAILED"

echo ""
echo "======================================"
echo "Phase 2: Applying tests.patch"
echo "======================================"
docker cp tests.patch $CONTAINER_ID:/tmp/tests.patch
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "git apply /tmp/tests.patch"
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Phase 3: After tests.patch (Should FAIL)"
echo "======================================"
docker start -a $CONTAINER_ID > FAIL_pre_patch.log 2>&1 && echo "❌ PASSED (expected fail)" || echo "✅ FAILED as expected"

echo ""
echo "======================================"
echo "Phase 4: Applying fix.patch"
echo "======================================"
docker cp fix.patch $CONTAINER_ID:/tmp/fix.patch
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "git apply /tmp/fix.patch"
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Phase 5: After fix.patch (Should PASS)"
echo "======================================"
docker start -a $CONTAINER_ID > PASS_post_patch.log 2>&1 && echo "✅ PASSED" || echo "❌ FAILED"

echo ""
echo "======================================"
echo "Validation Complete"
echo "======================================"

docker rm $CONTAINER_ID
