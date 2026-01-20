#!/bin/bash
# Copyright (c) 2025-2026 Marc Allgeier (fidpa)
# SPDX-License-Identifier: MIT
# https://github.com/fidpa/server-scripts-cli
#
# Server Scripts CLI - Installer
#
# Automated installation script for server-scripts-cli (ssc).
# Supports three installation modes: local alias, system-wide, or user-local.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/fidpa/server-scripts-cli/main/install.sh | bash
#   ./install.sh --local      # Add alias to ~/.bashrc
#   ./install.sh --system     # Install to /usr/local/bin (requires sudo)
#   ./install.sh --user       # Symlink to ~/.local/bin
#
# Version: 1.0.0
# Created: 2026-01-20

set -uo pipefail

# ===== Configuration =====
readonly VERSION="1.0.0"
readonly REPO_URL="https://github.com/fidpa/server-scripts-cli"
readonly MIN_BASH_VERSION=4
readonly INSTALL_DIR="${HOME}/server-scripts-cli"

# ===== Color Logging Functions =====
log() {
    echo -e "\033[0;36m[INFO]\033[0m $*"
}

warn() {
    echo -e "\033[0;33m[WARN]\033[0m $*" >&2
}

error() {
    echo -e "\033[0;31m[ERROR]\033[0m $*" >&2
}

success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $*"
}

# ===== Prerequisites Check =====
check_bash_version() {
    local current_version="${BASH_VERSINFO[0]}"

    if [[ "$current_version" -lt "$MIN_BASH_VERSION" ]]; then
        error "Bash $MIN_BASH_VERSION or higher required (found: $current_version)"
        return 1
    fi

    log "Bash version: $current_version (OK)"
    return 0
}

check_yq() {
    if command -v yq >/dev/null 2>&1; then
        local yq_version
        yq_version=$(yq --version 2>&1 | head -n1)
        log "yq found: $yq_version"
        return 0
    else
        warn "yq not found - required for ssc to function"
        echo ""
        echo "Install yq via one of:"
        echo "  • wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ~/.local/bin/yq && chmod +x ~/.local/bin/yq"
        echo "  • sudo apt install yq (Debian/Ubuntu)"
        echo "  • brew install yq (macOS)"
        echo ""
        return 1
    fi
}

check_git() {
    if ! command -v git >/dev/null 2>&1; then
        error "git not found - required for installation"
        return 1
    fi

    log "git found: $(git --version)"
    return 0
}

# ===== Installation Functions =====
clone_repository() {
    if [[ -d "$INSTALL_DIR" ]]; then
        log "Repository already exists at $INSTALL_DIR"

        # Check if it's a git repo
        if [[ -d "$INSTALL_DIR/.git" ]]; then
            log "Pulling latest changes..."
            cd "$INSTALL_DIR" && git pull --quiet
            success "Repository updated"
        else
            warn "Directory exists but is not a git repository"
            return 1
        fi
    else
        log "Cloning repository to $INSTALL_DIR..."
        if git clone --quiet "$REPO_URL" "$INSTALL_DIR"; then
            success "Repository cloned"
        else
            error "Failed to clone repository"
            return 1
        fi
    fi

    return 0
}

generate_manifest() {
    log "Generating manifest..."
    cd "$INSTALL_DIR" || return 1

    if [[ -f "generate-manifest.sh" ]]; then
        if bash generate-manifest.sh >/dev/null 2>&1; then
            success "Manifest generated"
        else
            warn "Manifest generation failed (may require scripts directory)"
        fi
    else
        warn "generate-manifest.sh not found"
    fi
}

install_local_alias() {
    local bashrc="${HOME}/.bashrc"
    local alias_line="alias ssc='${INSTALL_DIR}/ssc.sh'"

    # Check if alias already exists
    if grep -q "alias ssc=" "$bashrc" 2>/dev/null; then
        log "Alias already configured in $bashrc"
        return 0
    fi

    log "Adding alias to $bashrc..."
    {
        echo ""
        echo "# Server Scripts CLI (ssc)"
        echo "$alias_line"
    } >> "$bashrc"

    success "Alias added to $bashrc"
    echo ""
    echo "Run: source ~/.bashrc"
    echo "Then: ssc list"
}

install_system_wide() {
    log "Installing system-wide to /usr/local/bin..."

    if [[ "$EUID" -ne 0 ]]; then
        error "System-wide installation requires sudo"
        echo ""
        echo "Run: sudo ./install.sh --system"
        return 1
    fi

    # Copy binaries
    cp "${INSTALL_DIR}/ssc.sh" /usr/local/bin/ssc
    cp "${INSTALL_DIR}/generate-manifest.sh" /usr/local/bin/

    # Make executable
    chmod +x /usr/local/bin/ssc
    chmod +x /usr/local/bin/generate-manifest.sh

    success "Installed to /usr/local/bin/ssc"
    echo ""
    echo "Run: ssc list"
}

install_user_local() {
    local bin_dir="${HOME}/.local/bin"

    # Ensure ~/.local/bin exists
    mkdir -p "$bin_dir"

    # Check if already in PATH
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        warn "~/.local/bin not in PATH"
        echo ""
        echo "Add to ~/.bashrc:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi

    log "Creating symlink in $bin_dir..."

    # Remove existing symlink if present
    [[ -L "$bin_dir/ssc" ]] && rm "$bin_dir/ssc"

    ln -s "${INSTALL_DIR}/ssc.sh" "$bin_dir/ssc"

    success "Symlink created: $bin_dir/ssc"
    echo ""
    echo "Run: ssc list"
}

# ===== Help Message =====
show_help() {
    cat <<EOF
Server Scripts CLI - Installer v${VERSION}

Usage:
  ./install.sh [MODE]

Installation Modes:
  --local     Add alias to ~/.bashrc (default)
  --system    Install to /usr/local/bin (requires sudo)
  --user      Symlink to ~/.local/bin
  --help      Show this help message

One-Liner Installation:
  curl -sSL https://raw.githubusercontent.com/fidpa/server-scripts-cli/main/install.sh | bash

Examples:
  ./install.sh              # Local alias mode
  sudo ./install.sh --system
  ./install.sh --user

Documentation: https://github.com/fidpa/server-scripts-cli
EOF
}

# ===== Main Installation Logic =====
main() {
    local mode="${1:---local}"

    echo ""
    echo "===== Server Scripts CLI Installer v${VERSION} ====="
    echo ""

    # Show help
    if [[ "$mode" == "--help" || "$mode" == "-h" ]]; then
        show_help
        return 0
    fi

    # Prerequisites
    log "Checking prerequisites..."
    check_bash_version || return 1
    check_git || return 1
    check_yq || {
        warn "yq missing - ssc will not function until installed"
        echo ""
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 1
    }

    echo ""

    # Clone repository
    clone_repository || return 1

    echo ""

    # Generate manifest (optional, may fail if no scripts/ directory)
    generate_manifest

    echo ""

    # Install based on mode
    case "$mode" in
        --local)
            install_local_alias
            ;;
        --system)
            install_system_wide
            ;;
        --user)
            install_user_local
            ;;
        *)
            error "Unknown mode: $mode"
            echo ""
            show_help
            return 1
            ;;
    esac

    echo ""
    success "Installation complete!"
}

# Execute
main "$@"
