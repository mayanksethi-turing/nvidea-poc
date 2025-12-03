FROM node:20-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN npm install -g pnpm

WORKDIR /app

# Copy metadata and patches
COPY metadata.json tests.patch fix.patch /tmp/

# Clone repository and checkout specific commit
RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Install dependencies
RUN pnpm install || true

# Default command
CMD ["pnpm", "--version"]
