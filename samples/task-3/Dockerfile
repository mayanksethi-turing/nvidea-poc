# Base stage with common dependencies
FROM python:3.11-bookworm AS base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            build-essential \
            gettext \
            git \
            libffi-dev \
            libjpeg-dev \
            libmemcached-dev \
            libpq-dev \
            libssl-dev \
            libxml2-dev \
            libxslt1-dev \
            locales \
            nginx \
            python3-virtualenv \
            python3-dev \
            sudo \
            supervisor \
            libmaxminddb0 \
            libmaxminddb-dev \
            zlib1g-dev \
            nodejs  \
            npm \
            jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    dpkg-reconfigure locales &&  \
    locale-gen C.UTF-8 &&  \
    /usr/sbin/update-locale LANG=C.UTF-8 && \
    mkdir /etc/pretix && \
    mkdir /data && \
    mkdir /static && \
    mkdir /etc/supervisord

ENV LC_ALL=C.UTF-8

# Copy only the metadata and patch files to /tmp
COPY metadata.json tests.patch fix.patch /tmp/

# Configure git for operations
RUN git config --global user.email "docker@pretix.com" && \
    git config --global user.name "Docker Build"

# Extract repo URL and commit hash, clone repo directly to /pretix
RUN REPO_URL=$(jq -r '.repo' /tmp/metadata.json) && \
    COMMIT_HASH=$(jq -r '.head' /tmp/metadata.json) && \
    echo "Cloning repository: $REPO_URL" && \
    git clone "$REPO_URL" /pretix && \
    cd /pretix && \
    echo "Resetting to commit: $COMMIT_HASH" && \
    git reset --hard "$COMMIT_HASH"

# Create pretixuser after cloning the repo
RUN useradd -M -d /pretix -u 15371 pretixuser && \
    echo 'pretixuser ALL=(ALL) NOPASSWD:SETENV: /usr/bin/supervisord' >> /etc/sudoers

# Set working directory to cloned repo
WORKDIR /pretix

# Upgrade pip, setuptools, and wheel
RUN pip3 install -U \
        pip \
        setuptools \
        wheel

# Test stage - includes dev dependencies and testing tools
FROM base AS test

ENV DJANGO_SETTINGS_MODULE=tests.settings

# Install yarn globally for test execution
RUN npm install -g yarn

# Install Python dev dependencies
RUN cd /pretix && \
    PRETIX_DOCKER_BUILD=TRUE pip3 install \
        -e ".[dev,memcached]" \
        psycopg2-binary && \
    rm -rf ~/.cache/pip

# Build frontend assets
RUN cd /pretix/src && \
    chown -R pretixuser:pretixuser /pretix && \
    sudo -u pretixuser make npminstall && \
    sudo -u pretixuser make all compress

WORKDIR /pretix/src
USER pretixuser

# Default command runs tests with SQLite
CMD ["pytest", "-n", "3", "-p", "no:sugar", "--cov=./", "--cov-report=xml", "--cov-report=term", "tests", "--maxfail=100"]

# Production stage - optimized for production deployment
FROM base AS production

ENV DJANGO_SETTINGS_MODULE=production_settings

# Copy deployment files from cloned repo
RUN cp /pretix/deployment/docker/pretix.bash /usr/local/bin/pretix && \
    cp -r /pretix/deployment/docker/supervisord /etc/supervisord && \
    cp /pretix/deployment/docker/supervisord.all.conf /etc/supervisord.all.conf && \
    cp /pretix/deployment/docker/supervisord.web.conf /etc/supervisord.web.conf && \
    cp /pretix/deployment/docker/nginx.conf /etc/nginx/nginx.conf && \
    cp /pretix/deployment/docker/nginx-max-body-size.conf /etc/nginx/conf.d/nginx-max-body-size.conf && \
    cp /pretix/deployment/docker/production_settings.py /pretix/src/production_settings.py

RUN cd /pretix && \
    PRETIX_DOCKER_BUILD=TRUE pip3 install \
        -e ".[memcached]" \
        gunicorn django-extensions ipython && \
    rm -rf ~/.cache/pip

RUN chmod +x /usr/local/bin/pretix && \
    rm /etc/nginx/sites-enabled/default && \
    cd /pretix/src && \
    rm -f pretix.cfg &&  \
    mkdir -p data && \
    chown -R pretixuser:pretixuser /pretix /data data &&  \
    sudo -u pretixuser make production

USER pretixuser
VOLUME ["/etc/pretix", "/data"]
EXPOSE 80
ENTRYPOINT ["pretix"]
CMD ["all"]
