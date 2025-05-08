FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    postgresql-client \
    sudo \
    unzip \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Go
ARG GO_VERSION=1.24.3
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

# Create non-root user - handle case where GID/UID 1000 might already exist
RUN groupadd --gid 1000 vscode 2>/dev/null || groupmod -n vscode $(getent group 1000 | cut -d: -f1) && \
    useradd --uid 1000 --gid 1000 -m vscode 2>/dev/null || usermod -l vscode -d /home/vscode -m $(getent passwd 1000 | cut -d: -f1) && \
    mkdir -p /home/vscode && \
    chown vscode:vscode /home/vscode && \
    echo "vscode ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode

# Environment variables
ENV GOROOT=/usr/local/go
ENV GOPATH=/home/vscode/go
ENV PATH=$GOROOT/bin:$GOPATH/bin:$PATH

USER vscode
WORKDIR /home/vscode

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash || (echo "Bun installation failed, retrying with updated PATH" && PATH=$PATH:/home/vscode/.bun/bin curl -fsSL https://bun.sh/install | bash)
ENV BUN_INSTALL=/home/vscode/.bun
ENV PATH=$BUN_INSTALL/bin:$PATH

# Install Go tools
RUN go install github.com/swaggo/swag/cmd/swag@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install github.com/air-verse/air@latest

# Verify installations
RUN echo "Verifying installations..." && \
    go version || echo "Go not properly installed" && \
    bun --version || echo "Bun not properly installed"

# Install dependencies conditionally (if files exist)
# Note: Dependencies will be installed when the container is first started
# and the actual source code is mounted
WORKDIR /workspace

# Create initialization script
RUN echo '#!/bin/bash \n\
    git submodule update --init --recursive \n\
    # Set correct ownership of backend and frontend directories \n\
    echo "Setting correct ownership for workspace directories..." \n\
    sudo chown -R vscode:vscode /workspace/backend \n\
    sudo chown -R vscode:vscode /workspace/frontend \n\
    # Clean potential problematic Next.js build directories \n\
    if [ -d "/workspace/frontend/.next" ]; then \n\
    echo "Removing existing .next directory for clean build..." \n\
    sudo rm -rf /workspace/frontend/.next \n\
    fi \n\
    \n\
    if [ -f "/workspace/backend/go.mod" ]; then \n\
    echo "Installing backend dependencies..." \n\
    cd /workspace/backend && go mod download \n\
    fi \n\
    \n\
    if [ -f "/workspace/frontend/package.json" ]; then \n\
    echo "Installing frontend dependencies..." \n\
    cd /workspace/frontend && bun install \n\
    fi \n\
    ' > /home/vscode/init.sh && chmod +x /home/vscode/init.sh

WORKDIR /workspace