FROM node:20-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    jq \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Enable corepack for pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy metadata and patches
COPY metadata.json tests.patch fix.patch /tmp/

# Clone repository and checkout specific commit
RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Install dependencies
RUN pnpm install --frozen-lockfile || pnpm install

# Expose port
EXPOSE 8080

# Default command - run tests
CMD ["pnpm", "test"]
