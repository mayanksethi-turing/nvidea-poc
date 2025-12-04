FROM golang:1.21-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    jq \
    bash

WORKDIR /app

# Copy metadata and patches
COPY metadata.json fix.patch tests.patch /tmp/

# Clone repository and checkout specific commit
RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Download dependencies
RUN go mod download

# Note: This is a case-sensitivity bug fix in HTTP header parsing
# Validation will verify that:
# 1. Project builds successfully before fix
# 2. Project builds successfully after fix
# 3. fix.patch applies cleanly
# 4. Expected code changes are present (case-insensitive header parsing)

# Default command - build the project
CMD ["go", "build", "-v", "./..."]
