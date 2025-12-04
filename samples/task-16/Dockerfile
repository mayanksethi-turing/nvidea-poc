FROM node:20-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN npm install -g pnpm@9

WORKDIR /app

# Copy metadata and patches
COPY metadata.json fix.patch tests.patch /tmp/

# Clone repository and checkout specific commit
RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Install dependencies
RUN pnpm install

# Note: This is a UI/styling bug fix without automated tests
# Validation will verify that:
# 1. Project builds successfully before fix
# 2. Project builds successfully after fix
# 3. Fix.patch applies cleanly
# 4. Expected files are modified (z-index.scss, root.tsx, etc.)

# Default command - build the project
CMD ["pnpm", "run", "build"]
