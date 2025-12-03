FROM postgres:9.6

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy metadata and patches
COPY metadata.json tests.patch fix.patch /tmp/

# Clone repository and checkout specific commit
RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Copy database init script for validation
RUN cp database/docker-entrypoint-initdb.d/init-db.sql /tmp/init-db-original.sql

# Default command - validate SQL syntax
CMD ["psql", "--version"]
