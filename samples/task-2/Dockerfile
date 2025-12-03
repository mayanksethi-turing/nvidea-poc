FROM golang:1.12-alpine

# Install git, gcc, dep, and other dependencies
RUN apk add --no-cache git make bash curl gcc musl-dev jq

# Install dep for dependency management
RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

# Set working directory
WORKDIR /go/src/github.com/bxcodec/go-clean-arch

# Copy metadata and patch files
COPY metadata.json tests.patch fix.patch /tmp/

# Extract repo URL and commit hash, clone repo, reset to commit
RUN REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    echo "Cloning repository: $REPO_URL" && \
    git clone "$REPO_URL" .

RUN COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    echo "Resetting to commit: $COMMIT_HASH" && \
    git reset --hard "$COMMIT_HASH"

# Configure git for potential operations
RUN git config --global user.email "docker@go-clean-arch.com" && \
    git config --global user.name "Docker Build"

# Add constraint for golang.org/x/sync to use a version compatible with Go 1.12
RUN printf '\n[[constraint]]\n  name = "golang.org/x/sync"\n  revision = "1d60e4601c6fd243af51cc01ddf169918a5407ca"\n' >> Gopkg.toml

# Install dependencies using dep
RUN dep ensure -v

# Default command keeps container running
CMD ["tail", "-f", "/dev/null"]
