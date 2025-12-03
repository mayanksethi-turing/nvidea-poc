#!/bin/bash
set -e

TASK_ID="task-6"

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
echo "Phase 1: Pre-Fix Validation (Check UI Code)"
echo "======================================"
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "cat extra/lib/plausible_web/live/funnel_settings/form.ex | grep -A2 'Add another step'" > PASS_pre_tests.log 2>&1
docker exec $CONTAINER_ID bash -c "if grep -q 'class=\"flex mb-3 mt-3\"' extra/lib/plausible_web/live/funnel_settings/form.ex; then echo 'BEFORE FIX: Inconsistent margin classes detected'; exit 0; else echo 'ERROR: Already fixed?'; exit 1; fi" >> PASS_pre_tests.log 2>&1 && echo "✅ PASSED - Bug confirmed" || echo "❌ FAILED"
docker exec $CONTAINER_ID bash -c "if grep -q 'class=\"underline text-indigo-500 text-sm cursor-pointer mt-6\"' extra/lib/plausible_web/live/funnel_settings/form.ex; then echo 'BEFORE FIX: Button has problematic mt-6 margin'; exit 0; else echo 'WARNING: Button style may differ'; exit 0; fi" >> PASS_pre_tests.log 2>&1
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Phase 2: Apply tests.patch (empty for UI fix)"
echo "======================================"
echo "No tests.patch to apply (UI/CSS fix)" > FAIL_pre_patch.log
echo "✅ SKIPPED (no tests for UI fix)"

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
docker exec $CONTAINER_ID bash -c "cat extra/lib/plausible_web/live/funnel_settings/form.ex | grep -A5 'Add another step'" > PASS_post_patch.log 2>&1
docker exec $CONTAINER_ID bash -c "if grep -q 'class=\"flex my-3\"' extra/lib/plausible_web/live/funnel_settings/form.ex; then echo 'AFTER FIX: Consistent margin classes (my-3) confirmed'; exit 0; else echo 'ERROR: Fix not applied'; exit 1; fi" >> PASS_post_patch.log 2>&1 && echo "✅ PASSED - Margin fixed" || echo "❌ FAILED"
docker exec $CONTAINER_ID bash -c "if grep -q 'class=\"flex flex-col gap-y-4 mt-6\"' extra/lib/plausible_web/live/funnel_settings/form.ex; then echo 'AFTER FIX: Flex container with gap spacing confirmed'; exit 0; else echo 'ERROR: Flex container not added'; exit 1; fi" >> PASS_post_patch.log 2>&1 && echo "✅ PASSED - Layout fixed" || echo "❌ FAILED"
docker exec $CONTAINER_ID bash -c "if grep -q 'class=\"text-indigo-500 text-sm font-medium cursor-pointer\"' extra/lib/plausible_web/live/funnel_settings/form.ex; then echo 'AFTER FIX: Button styling updated correctly'; exit 0; else echo 'ERROR: Button style not updated'; exit 1; fi" >> PASS_post_patch.log 2>&1 && echo "✅ PASSED - Button styling fixed" || echo "❌ FAILED"
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Validation Complete"
echo "======================================"

docker rm $CONTAINER_ID
echo ""
echo "Log files created:"
ls -lh PASS_pre_tests.log FAIL_pre_patch.log PASS_post_patch.log
