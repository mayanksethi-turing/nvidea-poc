#!/bin/bash

# run.sh - Build Docker image and run unit tests for go-clean-arch

# Note: We don't use 'set -e' to allow tests to fail without blocking execution

# Container name for persisting changes across runs
CONTAINER_NAME="go-clean-arch-test-container"

echo "==================================="
echo "Building Docker image..."
echo "==================================="
docker build -t go-clean-arch-test .

# Remove any existing container with the same name
docker rm -f $CONTAINER_NAME 2>/dev/null || true

echo ""
echo "==================================="
echo "Creating container..."
echo "==================================="
docker create --name $CONTAINER_NAME go-clean-arch-test tail -f /dev/null
docker start $CONTAINER_NAME

echo ""
echo "==================================="
echo "Running unit tests PRE-TESTS..."
echo "Running baseline tests (should pass)"
echo "==================================="
docker exec $CONTAINER_NAME go test -v ./... 2>&1 | tee PASS_pre_tests.log

echo ""
echo "==================================="
echo "Applying tests modifications..."
echo "==================================="
docker exec $CONTAINER_NAME git apply /tmp/tests.patch

echo ""
echo "==================================="
echo "Running unit tests POST-TESTS..."
echo "Tests should FAIL (tests added but code not updated)"
echo "==================================="
docker exec $CONTAINER_NAME go test -v ./... 2>&1 | tee FAIL_post_tests.log

echo ""
echo "==================================="
echo "Applying implementation fixes..."
echo "==================================="
docker exec $CONTAINER_NAME git apply /tmp/fix.patch

echo ""
echo "==================================="
echo "Installing new dependencies..."
echo "==================================="
docker exec $CONTAINER_NAME dep ensure -v

echo ""
echo "==================================="
echo "Running unit tests POST-PATCH..."
echo "Tests should PASS (implementation applied)"
echo "==================================="
docker exec $CONTAINER_NAME go test -v ./... 2>&1 | tee PASS_post_patch.log

echo ""
echo "==================================="
echo "Tests execution completed!"
echo "Expected workflow: baseline PASS → tests FAIL → fix applied → tests PASS"
echo "==================================="

echo ""
echo "==================================="
echo "Removing Docker container..."
echo "==================================="
docker rm -f $CONTAINER_NAME

echo ""
echo "==================================="
echo "Cleanup completed!"
echo "==================================="
