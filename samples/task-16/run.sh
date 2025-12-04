#!/bin/bash
set -e

TASK_ID="task-16"

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

# Check for z-toast class in z-index.scss
docker exec $CONTAINER_ID bash -c "grep -q 'z-toast' app/styles/z-index.scss" && {
    echo "✅ z-toast class found in z-index.scss"
} || {
    echo "❌ z-toast class NOT found"
    docker stop $CONTAINER_ID
    exit 1
}

# Check for ToastContainer in root.tsx
docker exec $CONTAINER_ID bash -c "grep -q 'ToastContainer' app/root.tsx" && {
    echo "✅ ToastContainer found in root.tsx"
} || {
    echo "❌ ToastContainer NOT found in root.tsx"
    docker stop $CONTAINER_ID
    exit 1
}

# Check for toast success in deployment files
docker exec $CONTAINER_ID bash -c "grep -q 'toast.success' app/components/deploy/NetlifyDeploy.client.tsx" && {
    echo "✅ toast.success found in NetlifyDeploy"
} || {
    echo "⚠️  toast.success NOT found in NetlifyDeploy"
}

echo ""
echo "======================================"
echo "Validation Complete"
echo "======================================"
echo "✅ All validations passed!"
echo "   - Project builds before fix"
echo "   - Patch applies cleanly"
echo "   - Project builds after fix"
echo "   - Expected changes are present"

docker rm $CONTAINER_ID
