# Dockerfile for Ralph Claude Code environment
# Build: docker build -t ralph-claude:latest .
#
# This image includes:
# - Claude Code CLI
# - Beads task management
# - Python development tools
# - Node.js for JavaScript projects
# - Playwright for UI testing
#
# Security: runs as non-root user, git wrapper blocks dangerous operations

FROM ubuntu:24.04

LABEL security.nonroot="true"
LABEL security.readonlyfilesystem="false"
LABEL security.privileged="false"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    nodejs \
    npm \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN curl -fsSL https://claude.ai/install | sh

# Install Node.js tools: Beads task management + Playwright for UI testing
RUN npm install -g beads playwright \
    && npx playwright install --with-deps chromium

# Install Python development tools
RUN pip3 install --break-system-packages \
    pytest \
    pytest-cov \
    ruff \
    black \
    mypy

# --- Security: Git wrapper (pre-tool-use hook) ---
COPY git-wrapper.sh /usr/local/bin/git-wrapper.sh
RUN chmod +x /usr/local/bin/git-wrapper.sh

# --- Security: Non-root user ---
RUN useradd -m -u 1000 claude && \
    mkdir -p /home/claude/.claude && \
    chown -R claude:claude /home/claude/.claude

# Ensure logs directory is writable by claude user
RUN mkdir -p /var/log && \
    touch /var/log/git-commands.log && \
    chown claude:claude /var/log/git-commands.log && \
    chmod 644 /var/log/git-commands.log

# Set up working directory with secure permissions
WORKDIR /workspace
RUN chown -R claude:claude /workspace && \
    chmod 750 /workspace

# Git configuration (will be overridden by volume mount)
RUN git config --global user.email "ralph@example.com" && \
    git config --global user.name "Ralph Loop" && \
    git config --global alias.git '!/usr/local/bin/git-wrapper.sh'

# Switch to non-root user
USER claude

# Default entrypoint
ENTRYPOINT ["/bin/bash"]
