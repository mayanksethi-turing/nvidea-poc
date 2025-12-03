#!/bin/bash
set -e

TASK_ID="task-5"

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
echo "Phase 1: Pre-Fix Validation (Check SQL Schema)"
echo "======================================"
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "cat database/docker-entrypoint-initdb.d/init-db.sql | grep -A5 'CREATE TABLE product'" > PASS_pre_tests.log 2>&1
docker exec $CONTAINER_ID bash -c "if grep -q 'image oid' database/docker-entrypoint-initdb.d/init-db.sql; then echo 'BEFORE FIX: Wrong column type (oid) detected'; exit 0; else echo 'ERROR: Schema already fixed?'; exit 1; fi" >> PASS_pre_tests.log 2>&1 && echo "✅ PASSED - Wrong type confirmed" || echo "❌ FAILED"
docker exec $CONTAINER_ID bash -c "if grep -q '9.jpg' database/docker-entrypoint-initdb.d/init-db.sql; then echo 'BEFORE FIX: Wrong file extension (.jpg) detected'; exit 0; else echo 'WARNING: Extension may already be fixed'; exit 0; fi" >> PASS_pre_tests.log 2>&1
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Phase 2: Apply tests.patch (empty for SQL fix)"
echo "======================================"
echo "No tests.patch to apply (database schema fix)" > FAIL_pre_patch.log
echo "✅ SKIPPED (no tests for schema fix)"

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
echo "Phase 4: Post-Fix Validation (Check Correct Schema)"
echo "======================================"
docker start $CONTAINER_ID
docker exec $CONTAINER_ID bash -c "cat database/docker-entrypoint-initdb.d/init-db.sql | grep -A5 'CREATE TABLE product'" > PASS_post_patch.log 2>&1
docker exec $CONTAINER_ID bash -c "if grep -q 'image character varying(255)' database/docker-entrypoint-initdb.d/init-db.sql; then echo 'AFTER FIX: Correct column type (VARCHAR) confirmed'; exit 0; else echo 'ERROR: Fix not applied correctly'; exit 1; fi" >> PASS_post_patch.log 2>&1 && echo "✅ PASSED - Correct type confirmed" || echo "❌ FAILED"
docker exec $CONTAINER_ID bash -c "if grep -q '9.png' database/docker-entrypoint-initdb.d/init-db.sql && ! grep -q '9.jpg' database/docker-entrypoint-initdb.d/init-db.sql; then echo 'AFTER FIX: Correct file extension (.png) confirmed'; exit 0; else echo 'ERROR: Extension fix not applied'; exit 1; fi" >> PASS_post_patch.log 2>&1 && echo "✅ PASSED - Extension fixed" || echo "❌ FAILED"
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Validation Complete"
echo "======================================"

docker rm $CONTAINER_ID
echo ""
echo "Log files created:"
ls -lh PASS_pre_tests.log FAIL_pre_patch.log PASS_post_patch.log
