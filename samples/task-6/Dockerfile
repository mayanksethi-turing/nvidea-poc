FROM elixir:1.19.4

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    jq \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /app

# Copy metadata and patches
COPY metadata.json tests.patch fix.patch /tmp/

# Clone repository and checkout specific commit
RUN export REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    export COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    git clone "$REPO_URL" . && \
    git reset --hard "$COMMIT_HASH"

# Install dependencies (but don't compile yet to keep image smaller)
RUN mix deps.get || true

# Default command
CMD ["mix", "--version"]
