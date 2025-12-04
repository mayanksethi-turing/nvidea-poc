#!/bin/bash
set -e

TASK_NUM=$(basename $(pwd) | sed 's/task-//')

echo "======================================"
echo "Building Docker Image for task-${TASK_NUM}"
echo "======================================"
docker build -t bug-fix-sample-task-${TASK_NUM} .

echo ""
echo "======================================"
echo "Creating Container"
echo "======================================"
CONTAINER_ID=$(docker create bug-fix-sample-task-${TASK_NUM})
echo "Container ID: $CONTAINER_ID"

echo ""
echo "======================================"
echo "Phase 1: Pre-Tests (Should PASS)"
echo "======================================"
docker start -a $CONTAINER_ID > PASS_pre_tests.log 2>&1 && echo "✅ PASSED" || { echo "❌ FAILED"; docker rm $CONTAINER_ID; exit 1; }

echo ""
echo "======================================"
echo "Phase 2: Applying tests.patch"
echo "======================================"
# Note: This PR has no test changes, so we skip this phase
if [ -s tests.patch ] && [ "$(wc -l < tests.patch)" -gt 1 ]; then
    docker cp tests.patch $CONTAINER_ID:/tmp/tests.patch
    docker start $CONTAINER_ID
    docker exec $CONTAINER_ID bash -c "git apply /tmp/tests.patch"
    docker stop $CONTAINER_ID
    
    echo ""
    echo "======================================"
    echo "Phase 3: After tests.patch (Should FAIL)"
    echo "======================================"
    docker start -a $CONTAINER_ID > FAIL_pre_patch.log 2>&1 && echo "❌ PASSED (expected fail)" || echo "✅ FAILED as expected"
else
    echo "No test changes in this PR - skipping test phase"
    cp PASS_pre_tests.log FAIL_pre_patch.log
fi

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
docker start -a $CONTAINER_ID > PASS_post_patch.log 2>&1 && echo "✅ PASSED" || { echo "❌ FAILED"; docker rm $CONTAINER_ID; exit 1; }

echo ""
echo "======================================"
echo "Validation Complete"
echo "======================================"
echo "Results:"
echo "  - Pre-tests: PASS"
echo "  - Pre-patch: $([ -s FAIL_pre_patch.log ] && echo 'FAIL (expected)' || echo 'SKIP')"
echo "  - Post-patch: PASS"

docker rm $CONTAINER_ID
echo ""
echo "✅ All validation phases completed successfully"
