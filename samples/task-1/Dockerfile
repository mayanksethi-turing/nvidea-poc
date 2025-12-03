FROM node:22-slim

# Install git and jq (for JSON parsing)
RUN apt-get update && apt-get install -y git jq && rm -rf /var/lib/apt/lists/*

# Enable Corepack to use Yarn
RUN corepack enable

WORKDIR /app

# Copy only the metadata, trajectory, and patch files to /tmp
COPY metadata.json tests.patch fix.patch /tmp/

# Extract repo URL and commit hash, clone repo, reset to commit, and apply patch
RUN REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
		echo "Cloning repository: $REPO_URL" && \
    git clone "$REPO_URL" .
RUN COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
		echo "Resetting to commit: $COMMIT_HASH" && \
    git reset --hard "$COMMIT_HASH"

# Configure git for potential operations
RUN git config --global user.email "docker@tldraw.com" && \
    git config --global user.name "Docker Build"

# Install dependencies
RUN yarn install --immutable

# Expose the port that Vite dev server uses
EXPOSE 5420

# Disable Husky git hooks in the container
ENV HUSKY=0

# Default command runs dev server, but can be overridden for tests
CMD ["yarn", "dev"]
