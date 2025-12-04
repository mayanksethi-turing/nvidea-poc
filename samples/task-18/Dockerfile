FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"

WORKDIR /app

# Copy metadata and patches
COPY metadata.json fix.patch tests.patch /tmp/

# Clone repository and checkout specific commit
RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Install dependencies
RUN poetry install

# Note: This is an uninitialized variable bug fix
# Validation will verify that:
# 1. Project installs successfully before fix
# 2. Project installs successfully after fix  
# 3. fix.patch applies cleanly
# 4. Expected code changes are present (variable initialization moved)

# Default command - run tests
CMD ["poetry", "run", "pytest", "tests/"]
