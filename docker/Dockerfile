# Ralph Claude Code environment
# Based on Anthropic's official devcontainer pattern
# https://github.com/anthropics/claude-code/tree/main/.devcontainer
#
# Build (from repo root): docker build -t ralph-claude:latest docker/
#
# This image includes:
# - Claude Code CLI
# - Beads (bd) task management
# - Python development tools (pytest, ruff, black, mypy)
# - Playwright + Chromium for UI testing
#
# Security: runs as non-root user (node, UID 1000), git wrapper blocks dangerous operations

FROM node:20

ARG CLAUDE_CODE_VERSION=latest

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    gh \
    python3 \
    python3-pip \
    python3-venv \
    sudo \
    jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up npm global prefix for non-root install
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share/npm-global

USER node
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=/usr/local/share/npm-global/bin:$PATH

# Install Claude Code via npm (NOT the curl installer — it fails in Docker)
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Install beads and playwright
RUN npm install -g @beads/bd playwright

# System-level installs (Playwright browsers + Python dev tools)
USER root
RUN npx playwright install --with-deps chromium && \
    pip3 install --no-cache-dir --break-system-packages \
        pytest pytest-cov ruff black mypy

# --- Security: Git wrapper intercepts all git commands via PATH precedence ---
# /usr/local/bin precedes /usr/bin in PATH, so this wrapper intercepts all git calls.
# The wrapper validates commands then delegates to /usr/bin/git.
COPY git-wrapper.sh /usr/local/bin/git
RUN chmod +x /usr/local/bin/git
RUN touch /var/log/git-commands.log && \
    chown node:node /var/log/git-commands.log

# Git configuration (use real binary directly — wrapper is already in PATH)
RUN /usr/bin/git config --system user.email "ralph-loop[bot]@users.noreply.github.com" && \
    /usr/bin/git config --system user.name "Ralph Loop"

# Workspace and config directories
RUN mkdir -p /workspace /home/node/.claude && \
    chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace
USER node

# Environment for Claude Code
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV CLAUDE_CONFIG_DIR=/home/node/.claude

ENTRYPOINT ["/bin/bash"]
