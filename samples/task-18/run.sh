#!/bin/bash
set -e

TASK_ID="task-18"

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
echo "Phase 1: Pre-Fix Installation (Should PASS)"
echo "======================================"
echo "Installing project at commit BEFORE fix..."
docker start -a $CONTAINER_ID > PASS_pre_tests.log 2>&1 && {
    echo "✅ PASSED - Project installs successfully before fix"
    tail -20 PASS_pre_tests.log
} || {
    echo "❌ FAILED - Project should install before fix"
    tail -20 PASS_pre_tests.log
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
echo "Phase 3: Post-Fix Installation (Should PASS)"
echo "======================================"
echo "Installing project after applying fix..."
docker start -a $CONTAINER_ID > PASS_post_patch.log 2>&1 && {
    echo "✅ PASSED - Project installs successfully after fix"
    tail -20 PASS_post_patch.log
} || {
    echo "❌ FAILED - Project should install after fix"
    tail -20 PASS_post_patch.log
    docker stop $CONTAINER_ID
    exit 1
}

echo ""
echo "======================================"
echo "Phase 4: Verify Fix Content"
echo "======================================"
echo "Checking that expected changes are present..."

# Check for variable initialization before if block
docker exec $CONTAINER_ID bash -c "grep -B2 'if output.returncode == 0:' murakami/runners/speedtest.py | grep -q 'murakami_output = {}'" && {
    echo "✅ Variable initialization moved before if block"
} || {
    echo "❌ Expected code changes NOT found"
    docker stop $CONTAINER_ID
    exit 1
}

echo ""
echo "======================================"
echo "Validation Complete"
echo "======================================"
echo "✅ All validations passed!"
echo "   - Project installs before fix"
echo "   - Patch applies cleanly"
echo "   - Project installs after fix"
echo "   - Variable initialization properly placed"

docker rm $CONTAINER_ID
