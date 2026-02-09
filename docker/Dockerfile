# Dockerfile for Ralph Claude Code environment
# Build: docker build -t ralph-claude:latest .
# 
# This image includes:
# - Claude Code CLI
# - Beads task management
# - Python development tools
# - Node.js for JavaScript projects
# - Playwright for UI testing

FROM ubuntu:24.04

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

# Set up working directory
WORKDIR /workspace

# Git configuration (will be overridden by volume mount)
RUN git config --global user.email "ralph@example.com" && \
    git config --global user.name "Ralph Loop"

# Default entrypoint
ENTRYPOINT ["/bin/bash"]
