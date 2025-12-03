# Phase 4: Docker Builder Agent

**Role:** Create Dockerfile and run.sh validation script for the bug fix sample.

---

## Input

Phase 1 output containing:
- `language`
- `framework`
- `build_tool`
- `test_framework`
- `test_command`
- `install_command`
- `base_docker_image`
- `repo_url`

---

## Your Tasks

### Task 4.1: Select Base Docker Image (2 min)

**Based on language/build tool:**

**Java + Maven:**
```dockerfile
FROM maven:3.9-eclipse-temurin-17
```

**Java + Gradle:**
```dockerfile
FROM gradle:8.5-jdk17
```

**Node.js:**
```dockerfile
FROM node:20-slim
# or
FROM node:22-slim  # for newer projects
```

**Python:**
```dockerfile
FROM python:3.11-slim
# or
FROM python:3.9-slim  # based on project requirements
```

**Go:**
```dockerfile
FROM golang:1.21
```

---

### Task 4.2: Generate Dockerfile (15 min)

**IMPORTANT: For parallel execution, ensure unique Docker image naming!**

#### Docker Image Naming Convention

To prevent collisions when multiple agents build simultaneously:

```bash
# Get task ID from environment (set in Phase 1)
TASK_ID="${TASK_ID:-task-unknown}"

# Image naming convention
IMAGE_NAME="nvidea-poc-${TASK_ID}"
IMAGE_TAG="validation"

# Build with unique name
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

# Run with unique name
docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}"
```

#### Template structure:

```dockerfile
# 1. Base image
FROM {base_image}

# 2. Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    jq \
    {other_tools} \
    && rm -rf /var/lib/apt/lists/*

# 3. Set working directory
WORKDIR /app

# 4. Copy metadata and patches
COPY metadata.json tests.patch fix.patch /tmp/

# 5. Clone repository
RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# 6. Install dependencies
RUN {install_command}

# 7. Expose ports (if needed)
EXPOSE {port}

# 8. Set environment variables
ENV {ENV_VAR}=value

# 9. Default command
CMD [{default_command}]
```

---

### Task 4.3: Language-Specific Dockerfiles

#### Java + Maven Example

```dockerfile
FROM maven:3.9-eclipse-temurin-17

RUN apt-get update && apt-get install -y \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY metadata.json tests.patch fix.patch /tmp/

RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Install dependencies without running tests
RUN mvn install -DskipTests

# Expose port if app has a server
EXPOSE 8080

CMD ["mvn", "test"]
```

#### Node.js + Yarn Example

```dockerfile
FROM node:22-slim

RUN apt-get update && apt-get install -y \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY metadata.json tests.patch fix.patch /tmp/

RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Install dependencies
RUN yarn install --immutable

# Disable git hooks
ENV HUSKY=0

EXPOSE 5420

CMD ["yarn", "test"]
```

#### Python + Pytest Example

```dockerfile
FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    git \
    jq \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY metadata.json tests.patch fix.patch /tmp/

RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install test dependencies
RUN pip install --no-cache-dir pytest pytest-django

ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=app.settings

CMD ["pytest"]
```

#### Go Example

```dockerfile
FROM golang:1.21

RUN apt-get update && apt-get install -y \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY metadata.json tests.patch fix.patch /tmp/

RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Download dependencies
RUN go mod download

CMD ["go", "test", "./..."]
```

---

### Task 4.4: Generate run.sh Validation Script (15 min)

**Purpose:** Script that runs the fail→pass validation cycle

**IMPORTANT: Use unique Docker image names to prevent collisions!**

**Template:**

```bash
#!/bin/bash
set -e  # Exit on any error

# Generate unique image name from task directory or metadata
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_NAME=$(basename "$SCRIPT_DIR")

# If metadata.json exists, use repo name for more readable image name
if [ -f "$SCRIPT_DIR/metadata.json" ] && command -v jq &> /dev/null; then
    REPO_NAME=$(jq -r '.repo' "$SCRIPT_DIR/metadata.json" | sed 's|.*/||' | sed 's|\.git||')
    IMAGE_NAME="nvidea-poc-${REPO_NAME}-${TASK_NAME}"
else
    IMAGE_NAME="nvidea-poc-${TASK_NAME}"
fi

echo "======================================"
echo "Building Docker Image: ${IMAGE_NAME}"
echo "======================================"
docker build -t "$IMAGE_NAME" .

echo ""
echo "======================================"
echo "Creating Container"
echo "======================================"
CONTAINER_ID=$(docker create "$IMAGE_NAME")

# Cleanup function
cleanup() {
    echo ""
    echo "======================================"
    echo "Cleaning up container..."
    echo "======================================"
    docker rm -f $CONTAINER_ID 2>/dev/null || true
}
trap cleanup EXIT

echo ""
echo "======================================"
echo "Phase 1: Running Pre-Tests (Should PASS)"
echo "======================================"
docker start -a $CONTAINER_ID > PASS_pre_tests.log 2>&1 && echo "✅ Pre-tests PASSED" || echo "❌ Pre-tests FAILED"

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
echo "Phase 3: Running Tests After tests.patch (Should FAIL)"
echo "======================================"
docker start -a $CONTAINER_ID > FAIL_pre_patch.log 2>&1 && echo "❌ Tests PASSED (expected to fail)" || echo "✅ Tests FAILED as expected"

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
echo "Phase 5: Running Tests After fix.patch (Should PASS)"
echo "======================================"
docker start -a $CONTAINER_ID > PASS_post_patch.log 2>&1 && echo "✅ Post-fix tests PASSED" || echo "❌ Post-fix tests FAILED"

echo ""
echo "======================================"
echo "Validation Complete"
echo "======================================"
echo "Check logs:"
echo "  - PASS_pre_tests.log"
echo "  - FAIL_pre_patch.log"
echo "  - PASS_post_patch.log"

docker rm $CONTAINER_ID
```

**Customizations based on test framework:**

**For Maven:**
```bash
# Use specific test class if known
docker exec $CONTAINER_ID bash -c "mvn test -Dtest=PaymentHandlerTest"
```

**For Yarn/NPM:**
```bash
# Run specific test file or pattern
docker exec $CONTAINER_ID bash -c "yarn test PaymentHandler.test"
```

**For Pytest:**
```bash
# Run specific test file
docker exec $CONTAINER_ID bash -c "pytest tests/test_payment.py -v"
```

**For Go:**
```bash
# Run specific package
docker exec $CONTAINER_ID bash -c "go test ./pkg/payment/... -v"
```

---

### Task 4.5: Add Build Optimizations (Optional) (5 min)

**For faster builds:**

**Maven - cache dependencies:**
```dockerfile
# Copy pom.xml first and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline

# Then copy source
COPY . .
```

**Node.js - cache node_modules:**
```dockerfile
# Copy package files first
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Then copy source
COPY . .
```

**Python - cache pip packages:**
```dockerfile
# Copy requirements first
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Then copy source
COPY . .
```

---

### Task 4.6: Validate Dockerfile Builds (5 min)

```bash
# Test build
docker build -t test-sample .

# Check image size
docker images test-sample

# Test container creation
docker create test-sample

# Clean up
docker rmi test-sample
```

**Validation checklist:**
- [ ] Dockerfile builds without errors
- [ ] Dependencies install successfully
- [ ] Repository clones correctly
- [ ] Correct commit is checked out
- [ ] Image size is reasonable (< 2GB ideally)

---

### Task 4.7: Validate run.sh Works (5 min)

```bash
# Make executable
chmod +x run.sh

# Test run (this will take several minutes)
./run.sh

# Check logs created
ls -la *.log
```

**Expected results:**
```
✅ PASS_pre_tests.log    - Tests pass initially
✅ FAIL_pre_patch.log    - Tests fail after tests.patch
✅ PASS_post_patch.log   - Tests pass after fix.patch
```

---

## Special Considerations

### Multi-Module Projects

If project has multiple modules:

```dockerfile
# Build all modules
RUN mvn install -DskipTests

# Or specific module
WORKDIR /app/payment-service
RUN mvn install -DskipTests
```

### Database Requirements

If tests need database:

```dockerfile
# Install database
RUN apt-get update && apt-get install -y postgresql-client

# Or use docker-compose (mention in notes)
```

### Environment Variables

Add required env vars:

```dockerfile
ENV DATABASE_URL=sqlite:///test.db
ENV NODE_ENV=test
ENV SPRING_PROFILES_ACTIVE=test
```

---

## Output Format

```json
{
  "status": "success",
  "dockerfile": {
    "path": "Dockerfile",
    "base_image": "maven:3.9-eclipse-temurin-17",
    "size_estimate_mb": 450,
    "build_validated": true
  },
  "run_script": {
    "path": "run.sh",
    "executable": true,
    "phases": 5,
    "validated": true
  },
  "docker_contents": "FROM maven:3.9...",
  "script_contents": "#!/bin/bash\nset -e...",
  "notes": [
    "Tests require Maven",
    "Build takes ~2 minutes",
    "Image size: ~450MB"
  ],
  "next_phase_ready": true
}
```

---

## Error Handling

**If build fails:**
```json
{
  "status": "failed",
  "error": "Docker build failed: dependency not found",
  "build_log": "...",
  "suggestion": "Add missing dependency to Dockerfile",
  "next_phase_ready": false
}
```

**If validation cycle fails:**
```json
{
  "status": "failed",
  "error": "Validation cycle incorrect: tests didn't fail after tests.patch",
  "cycle_results": {
    "pre_tests": "PASS",
    "post_tests_patch": "PASS",
    "post_fix_patch": "PASS"
  },
  "suggestion": "Check if tests.patch actually introduces a failing test",
  "next_phase_ready": false
}
```

---

### Task 4.8: Configure Code Coverage (REQUIRED) (5 min)

**All test execution must include code coverage reports in logs.**

#### Coverage Requirements by Language:

##### **JavaScript/TypeScript (Jest/Vitest)**

```bash
# In run.sh - PRE_TESTS phase with coverage
docker exec $CONTAINER_ID yarn vitest run --coverage --silent --reporter=dot --coverage.reporter=text-summary --retry=1 > PASS_pre_tests.log 2>&1

# POST_PATCH phase with detailed coverage
docker exec $CONTAINER_ID yarn vitest run --coverage --silent --reporter=dot --coverage.reporter=text --retry=1 > PASS_post_patch.log 2>&1
```

**Vitest Configuration:**
- Use `--coverage` flag
- Use `--coverage.reporter=text-summary` for summary
- Use `--coverage.reporter=text` for detailed file-by-file coverage
- Coverage will appear at the end of test output

**Jest Configuration:**
```bash
# Add to test command
jest --coverage --coverageReporters=text --coverageReporters=text-summary
```

---

##### **Python (pytest)**

```bash
# In run.sh - with coverage
docker exec $CONTAINER_ID pytest --cov=./ --cov-report=term tests/ > PASS_pre_tests.log 2>&1
```

**Pytest Configuration:**
- Use `--cov=./` to cover entire codebase
- Use `--cov-report=term` for terminal output
- Optionally add `--cov-report=xml` for machine-readable format

**Multi-process tests:**
```bash
pytest -n 3 --cov=./ --cov-report=xml --cov-report=term tests/
```

---

##### **Go (go test)**

```bash
# In run.sh - with coverage
docker exec $CONTAINER_ID go test -v -cover ./... > PASS_pre_tests.log 2>&1

# For detailed coverage report:
docker exec $CONTAINER_ID bash -c "go test -v -cover -coverprofile=coverage.out ./... && go tool cover -func=coverage.out" > PASS_post_patch.log 2>&1
```

**Go Configuration:**
- Use `-cover` flag for inline coverage percentages
- Use `-coverprofile=coverage.out` for detailed report
- Use `go tool cover -func=coverage.out` to display coverage summary
- Optionally use `go tool cover -html=coverage.out` for HTML report

---

##### **Java (Maven)**

```bash
# In run.sh - with coverage
docker exec $CONTAINER_ID mvn test jacoco:report > PASS_pre_tests.log 2>&1
docker exec $CONTAINER_ID cat target/site/jacoco/index.html | grep -A10 "Total" >> PASS_pre_tests.log 2>&1
```

**Maven JaCoCo Configuration:**
Ensure pom.xml includes:
```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.10</version>
    <executions>
        <execution>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

---

##### **Java (Gradle)**

```bash
# In run.sh - with coverage
docker exec $CONTAINER_ID gradle test jacocoTestReport > PASS_pre_tests.log 2>&1
docker exec $CONTAINER_ID cat build/reports/jacoco/test/html/index.html | grep -A10 "Total" >> PASS_pre_tests.log 2>&1
```

**Gradle JaCoCo Configuration (build.gradle):**
```groovy
plugins {
    id 'jacoco'
}

jacoco {
    toolVersion = "0.8.10"
}

jacocoTestReport {
    reports {
        xml.required = true
        html.required = true
    }
}

test {
    finalizedBy jacocoTestReport
}
```

---

#### Updated run.sh Template with Coverage:

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_NAME=$(basename "$SCRIPT_DIR")
IMAGE_NAME="nvidea-poc-${TASK_NAME}"

echo "======================================"
echo "Building Docker Image: ${IMAGE_NAME}"
echo "======================================"
docker build -t "$IMAGE_NAME" .

CONTAINER_ID=$(docker create "$IMAGE_NAME")

cleanup() {
    docker rm -f $CONTAINER_ID 2>/dev/null || true
}
trap cleanup EXIT

echo ""
echo "======================================"
echo "Phase 1: Running Pre-Tests WITH COVERAGE (Should PASS)"
echo "======================================"
docker start $CONTAINER_ID

# Language-specific test command with coverage
# Choose appropriate command from above based on language
docker exec $CONTAINER_ID {TEST_COMMAND_WITH_COVERAGE} 2>&1 | tee PASS_pre_tests.log

docker stop $CONTAINER_ID

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
echo "Phase 3: Running Tests After tests.patch (Should FAIL)"
echo "======================================"
docker start $CONTAINER_ID
docker exec $CONTAINER_ID {TEST_COMMAND_NO_COVERAGE} 2>&1 | tee FAIL_pre_patch.log
docker stop $CONTAINER_ID

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
echo "Phase 5: Running Tests After fix.patch WITH COVERAGE (Should PASS)"
echo "======================================"
docker start $CONTAINER_ID
docker exec $CONTAINER_ID {TEST_COMMAND_WITH_COVERAGE} 2>&1 | tee PASS_post_patch.log
docker stop $CONTAINER_ID

echo ""
echo "======================================"
echo "Validation Complete - Checking Coverage Reports"
echo "======================================"

# Verify coverage reports exist in logs
if grep -q -i "coverage\|%\|stmts\|branch" PASS_pre_tests.log; then
    echo "✅ Coverage report found in PASS_pre_tests.log"
else
    echo "⚠️  WARNING: No coverage report detected in PASS_pre_tests.log"
fi

if grep -q -i "coverage\|%\|stmts\|branch" PASS_post_patch.log; then
    echo "✅ Coverage report found in PASS_post_patch.log"
else
    echo "⚠️  WARNING: No coverage report detected in PASS_post_patch.log"
fi

echo ""
echo "Check logs:"
echo "  - PASS_pre_tests.log (with coverage)"
echo "  - FAIL_pre_patch.log"
echo "  - PASS_post_patch.log (with coverage)"
```

---

#### Validation Checklist:

When generating run.sh, ensure:
- [ ] **PASS_pre_tests.log** will contain coverage report
- [ ] **PASS_post_patch.log** will contain coverage report
- [ ] Coverage shows percentage metrics (statements, branches, functions, lines)
- [ ] Coverage report is readable (not binary/XML only)
- [ ] Test commands use correct coverage flags for the language
- [ ] FAIL_pre_patch.log does NOT need coverage (to keep logs cleaner)

---

## Ready to Build!

Provide Phase 1 output and I'll generate a complete Dockerfile and run.sh validation script with proper coverage configuration.

