#!/bin/bash
set -e

TASK_ID="task-7"

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
echo "Phase 1: Pre-Fix Validation (Check Code)"
echo "======================================"
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "cat src/app/page.tsx | grep -A5 'removeItem'" > PASS_pre_tests.log 2>&1 || echo "No removeItem found yet" > PASS_pre_tests.log
docker exec $CONTAINER_ID bash -c "if grep -q \"href={getUrl('/')}\" src/components/input/NavButton.tsx; then echo 'BEFORE FIX: NavButton redirects to / (causes loop)'; exit 0; else echo 'ERROR: Already fixed?'; exit 1; fi" >> PASS_pre_tests.log 2>&1 && echo "✅ PASSED - Bug confirmed" || echo "❌ FAILED"
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Phase 2: Apply tests.patch (empty for routing fix)"
echo "======================================"
echo "No tests.patch to apply (routing/navigation fix)" > FAIL_pre_patch.log
echo "✅ SKIPPED (no tests for routing fix)"

echo ""
echo "======================================"
echo "Phase 3: Applying fix.patch"
echo "======================================"
docker cp fix.patch $CONTAINER_ID:/tmp/fix.patch
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "cd /app && git apply /tmp/fix.patch" >> FAIL_pre_patch.log 2>&1 && echo "✅ Patch applied successfully" || echo "❌ Failed to apply patch"
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Phase 4: Post-Fix Validation (Check Fixed Code)"
echo "======================================"
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "cat src/app/page.tsx src/components/input/NavButton.tsx" > PASS_post_patch.log 2>&1
docker exec $CONTAINER_ID bash -c "if ! grep -q 'removeItem' src/app/page.tsx; then echo 'AFTER FIX: Unnecessary removeItem call removed'; exit 0; else echo 'ERROR: removeItem still present'; exit 1; fi" >> PASS_post_patch.log 2>&1 && echo "✅ PASSED - removeItem removed" || echo "❌ FAILED"
docker exec $CONTAINER_ID bash -c "if grep -q \"href={getUrl('/websites')}\" src/components/input/NavButton.tsx; then echo 'AFTER FIX: NavButton now redirects to /websites (no loop)'; exit 0; else echo 'ERROR: Redirect not fixed'; exit 1; fi" >> PASS_post_patch.log 2>&1 && echo "✅ PASSED - Redirect fixed" || echo "❌ FAILED"
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Validation Complete"
echo "======================================"

docker rm $CONTAINER_ID
echo ""
echo "Log files created:"
ls -lh PASS_pre_tests.log FAIL_pre_patch.log PASS_post_patch.log
