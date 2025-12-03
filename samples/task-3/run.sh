#!/bin/bash

# run-tests.sh - Build Docker image and run unit tests

# Note: We don't use 'set -e' to allow tests to fail without blocking execution

# Container name for persisting changes across runs
CONTAINER_NAME="pretix-test-container"

echo "==================================="
echo "Building Docker image..."
echo "==================================="
docker build --target test -t pretix-test .

# Remove any existing container with the same name
docker rm -f $CONTAINER_NAME 2>/dev/null || true

echo ""
echo "==================================="
echo "Creating container..."
echo "==================================="
docker create --name $CONTAINER_NAME pretix-test tail -f /dev/null
docker start $CONTAINER_NAME

echo ""
echo "==================================="
echo "Running unit tests PRE-TESTS..."
echo "==================================="
docker exec $CONTAINER_NAME pytest -n 3 -p no:sugar --cov=./ --cov-report=xml --cov-report=term tests/base/test_mail.py --maxfail=100

echo ""
echo "==================================="
echo "Applying tests modifications..."
echo "==================================="
docker exec $CONTAINER_NAME git apply /tmp/tests.patch

echo ""
echo "==================================="
echo "Running unit tests POST-TESTS, PRE-PATCH..."
echo "==================================="
docker exec $CONTAINER_NAME pytest tests/base/test_mail.py

echo ""
echo "==================================="
echo "Applying patch modifications..."
echo "==================================="
docker exec $CONTAINER_NAME git apply /tmp/fix.patch

echo ""
echo "==================================="
echo "Running unit tests POST-PATCH..."
echo "==================================="
docker exec $CONTAINER_NAME pytest tests/base/test_mail.py

echo ""
echo "==================================="
echo "Running unit tests on Changed files"
echo "==================================="
# Get list of changed files from git diff and pass to coverage.include
# Note: coverage.include expects multiple --coverage.include flags, one per file
CHANGED_FILES=$(docker exec $CONTAINER_NAME git diff --name-only --diff-filter=ACMR HEAD | grep -E '\.(ts|tsx|js|jsx)$')
if [ -n "$CHANGED_FILES" ]; then
	echo "Changed files:"
	echo "$CHANGED_FILES"

	# Build the coverage.include arguments
	COVERAGE_ARGS=""
	while IFS= read -r file; do
		if [ -n "$file" ]; then
			COVERAGE_ARGS="$COVERAGE_ARGS --coverage.include=$file"
		fi
	done <<< "$CHANGED_FILES"

  docker exec $CONTAINER_NAME sh -c "yarn vitest run --coverage --silent --changed --reporter=dot --coverage.reporter=text --retry=1 $COVERAGE_ARGS"
else
  echo "No changed files to collect coverage from"
fi

echo ""
echo "==================================="
echo "Tests completed!"
echo "==================================="

echo ""
echo "==================================="
echo "Removing Docker container and image..."
echo "==================================="
docker rm -f $CONTAINER_NAME
docker rmi pretix-test

echo ""
echo "==================================="
echo "Cleanup completed!"
echo "==================================="

