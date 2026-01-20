#!/bin/bash
# Copyright (c) 2025-2026 Marc Allgeier (fidpa)
# SPDX-License-Identifier: MIT
# https://github.com/fidpa/server-scripts-cli
#
# server-scripts - Unified Script Management CLI
#
# Central CLI tool for managing scripts via YAML manifest.
# Provides discovery, execution, status checking, and systemd integration.
#
# Usage:
#   ssc list                      # List all scripts
#   ssc list --category ops       # Filter by category
#   ssc run <script-name>         # Execute script
#   ssc info <script-name>        # Show details
#   ssc status                    # Show systemd status
#   ssc logs <script-name>        # Show service logs
#
# Documentation: docs/SETUP.md
# Version: 1.2.0
# Created: 2026-01-02
# Updated: 2026-01-20

set -uo pipefail

# ===== Configuration =====
readonly VERSION="1.2.0"
readonly INTERACTIVE_TYPES="report admin diagnostic check orchestrator"
readonly SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# REPO_ROOT: Try git first, fallback to script directory
if REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    readonly REPO_ROOT
else
    readonly REPO_ROOT="$SCRIPT_DIR"
fi
readonly MANIFEST_FILE="${REPO_ROOT}/manifest.yaml"

# ===== Colors =====
if [[ -t 1 ]]; then
    readonly RED=$'\033[0;31m'
    readonly GREEN=$'\033[0;32m'
    readonly YELLOW=$'\033[1;33m'
    readonly BLUE=$'\033[0;34m'
    readonly CYAN=$'\033[0;36m'
    readonly MAGENTA=$'\033[0;35m'
    readonly BOLD=$'\033[1m'
    readonly DIM=$'\033[2m'
    readonly NC=$'\033[0m'
else
    readonly RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' BOLD='' DIM='' NC=''
fi

# ===== Helper Functions =====

print_header() {
    printf "%b%s%b\n" "$BOLD" "$1" "$NC"
}

print_success() {
    printf "%b✓%b %s\n" "$GREEN" "$NC" "$1"
}

print_error() {
    printf "%b✗%b %s\n" "$RED" "$NC" "$1" >&2
}

print_warning() {
    printf "%b⚠%b %s\n" "$YELLOW" "$NC" "$1"
}

print_info() {
    printf "%b→%b %s\n" "$BLUE" "$NC" "$1"
}

# Check if yq is available
check_yq() {
    if ! command -v yq &>/dev/null; then
        print_error "yq is required but not installed"
        print_info "Install: snap install yq   (or install mikefarah/yq v4+)"
        exit 1
    fi

    # Feature-test: mikefarah/yq supports 'eval' command
    # This fails for Python yq wrapper (which doesn't have 'eval')
    if ! yq eval '.' /dev/null >/dev/null 2>&1; then
        print_error "Unsupported yq detected (expected mikefarah/yq v4+)"
        print_info "Install: snap install yq"
        exit 1
    fi
}

# Check manifest exists
check_manifest() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        print_error "Manifest not found: $MANIFEST_FILE"
        print_info "Generate with: ssc generate"
        exit 1
    fi
}

# Require all dependencies for commands
require_dependencies() {
    check_manifest
    check_yq
}

# Validate script name (security: prevent injection)
validate_script_name() {
    local name="$1"
    if ! [[ "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        print_error "Invalid script name: $name"
        print_info "Allowed characters: a-z A-Z 0-9 . _ -"
        return 1
    fi
}

# ===== Command: list =====
cmd_list() {
    require_dependencies

    local filter_category=""
    local filter_status=""
    local filter_type=""
    local search_term=""
    local show_paths=false
    local show_all=false
    local limit=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--all)
                show_all=true
                shift
                ;;
            -c|--category)
                filter_category="$2"
                shift 2
                ;;
            -s|--status)
                filter_status="$2"
                shift 2
                ;;
            -t|--type)
                filter_type="$2"
                show_all=true  # --type implies --all
                shift 2
                ;;
            -p|--paths)
                show_paths=true
                shift
                ;;
            -n|--limit)
                limit="$2"
                shift 2
                ;;
            --search)
                search_term="$2"
                shift 2
                ;;
            -h|--help)
                cat << EOF
${BOLD}ssc list${NC} - List scripts in manifest

${BOLD}USAGE:${NC}
    ssc list [OPTIONS]

${BOLD}DEFAULT BEHAVIOR:${NC}
    By default, shows only ${GREEN}Interactive${NC} scripts (Tier 1).
    Use ${BOLD}--all${NC} to show complete list including libraries, helpers, daemons.

${BOLD}OPTIONS:${NC}
    -a, --all               Show ALL scripts (default: only interactive)
    -c, --category <name>   Filter by category
    -s, --status <status>   Filter by status (active, deprecated, unknown)
    -t, --type <type>       Filter by type (activates --all automatically)
    -p, --paths             Show full paths instead of names
    -n, --limit <num>       Limit output to N scripts
    --search <term>         Search scripts by name

${BOLD}SCRIPT TYPES:${NC}
    ${GREEN}Tier 1 - Interactive (default shown):${NC}
      report        Status/summary reports
      admin         Regular admin tools
      diagnostic    Debug/troubleshooting
      check         Validation/health-checks
      orchestrator  Multi-script coordinators

    ${YELLOW}Tier 2 - One-time (use --all or --type):${NC}
      deploy        Deployment scripts
      setup         Setup/installation
      migration     Data migrations
      generator     File generators
      benchmark     Performance testing

    ${CYAN}Tier 3 - Background (use --all or --type):${NC}
      daemon        systemd services
      scheduled     Timer-based scripts
      exporter      Prometheus exporters

    ${MAGENTA}Tier 4 - Internal (use --all or --type):${NC}
      library       Sourced by scripts
      helper        Called by scripts

${BOLD}EXAMPLES:${NC}
    ssc list                    # Interactive scripts only
    ssc list --all              # Show complete list
    ssc list --type check       # Show all validation scripts
    ssc list --search backup    # Search for backup scripts
EOF
                return 0
                ;;
            *)
                # Treat unknown args as search term
                search_term="$1"
                shift
                ;;
        esac
    done

    print_header "Scripts Registry"
    echo ""

    # Output format
    if [[ "$show_paths" == "true" ]]; then
        printf "%-40s %s\n" "NAME" "PATH"
        printf "%s\n" "$(printf '%.0s─' {1..80})"
    else
        printf "%-30s %-12s %-10s %-15s\n" "NAME" "TYPE" "STATUS" "CATEGORY"
        printf "%s\n" "$(printf '%.0s─' {1..70})"
    fi

    local count=0
    while IFS=$'\t' read -r name type status category path; do
        [[ -z "$name" ]] && continue

        # Apply filters in Bash
        [[ -n "$filter_status"   && "$status"   != "$filter_status" ]] && continue
        [[ -n "$filter_type"     && "$type"     != "$filter_type" ]] && continue
        [[ -n "$filter_category" && "$category" != "$filter_category" ]] && continue
        [[ -n "$search_term"     && "${name,,}" != *"${search_term,,}"* ]] && continue

        # Default filter: only show Interactive types (Tier 1) unless --all
        if [[ "$show_all" == "false" ]]; then
            local is_interactive=false
            for interactive_type in $INTERACTIVE_TYPES; do
                if [[ "$type" == "$interactive_type" ]]; then
                    is_interactive=true
                    break
                fi
            done
            [[ "$is_interactive" == "false" ]] && continue
        fi

        # Apply limit
        if [[ $limit -gt 0 && $count -ge $limit ]]; then
            break
        fi

        # Color-code status
        local status_color="$NC"
        case "$status" in
            active) status_color="$GREEN" ;;
            deprecated) status_color="$RED" ;;
            unknown) status_color="$DIM" ;;
        esac

        # Color-code type (by tier)
        local type_color="$NC"
        case "$type" in
            # Tier 1 - Interactive (Green)
            report|admin|diagnostic|check|orchestrator) type_color="$GREEN" ;;
            # Tier 2 - One-time (Yellow)
            deploy|setup|migration|generator|benchmark) type_color="$YELLOW" ;;
            # Tier 3 - Background (Cyan)
            daemon|scheduled|exporter) type_color="$CYAN" ;;
            # Tier 4 - Internal (Magenta)
            library|helper) type_color="$MAGENTA" ;;
            # Legacy/Unknown (Blue)
            cli-tool|*) type_color="$BLUE" ;;
        esac

        if [[ "$show_paths" == "true" ]]; then
            printf "%-40s %s\n" "$name" "$path"
        else
            printf "%-30s ${type_color}%-12s${NC} ${status_color}%-10s${NC} %-15s\n" \
                "$name" "$type" "$status" "$category"
        fi

        ((count++))
    done < <(yq '.scripts | to_entries | sort_by(.key) | .[] | [.key, .value.type // "-", .value.status // "-", .value.category // "-", .value.path // "-"] | @tsv' "$MANIFEST_FILE" 2>/dev/null)

    echo ""
    local total
    total=$(yq '.scripts | length' "$MANIFEST_FILE")
    if [[ "$show_all" == "false" ]]; then
        print_info "Showing: $count interactive scripts (Total: $total, use --all for complete list)"
    else
        print_info "Showing: $count scripts (Total in manifest: $total)"
    fi
}

# ===== Command: run =====
cmd_run() {
    require_dependencies

    local force_run=false
    local script_name=""
    local script_args=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force_run=true
                shift
                ;;
            -h|--help)
                # Only show cmd_run help if no script name yet
                # Otherwise pass --help to the script
                if [[ -z "$script_name" ]]; then
                    cat << EOF
${BOLD}ssc run${NC} - Execute a script by name

${BOLD}USAGE:${NC}
    ssc run [options] <script-name> [script-args...]

${BOLD}OPTIONS:${NC}
    -f, --force     Force run even if script is deprecated
    -h, --help      Show this help

${BOLD}EXAMPLES:${NC}
    ssc run backup-example --help
    ssc run --force deprecated-script
EOF
                    return 0
                else
                    script_args+=("$1")
                fi
                shift
                ;;
            *)
                if [[ -z "$script_name" ]]; then
                    script_name="$1"
                else
                    script_args+=("$1")
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$script_name" ]]; then
        print_error "Usage: ssc run [--force] <script-name> [args...]"
        return 1
    fi

    # Validate script name (security: prevent injection)
    validate_script_name "$script_name" || return 1

    # Find script path
    local script_path
    script_path=$(yq ".scripts.\"${script_name}\".path // \"\"" "$MANIFEST_FILE")

    if [[ -z "$script_path" || "$script_path" == "null" ]]; then
        print_error "Script not found: $script_name"
        print_info "Use 'ssc list --search $script_name' to find similar scripts"
        return 1
    fi

    local full_path="${REPO_ROOT}/${script_path}"

    if [[ ! -f "$full_path" ]]; then
        print_error "Script file not found: $full_path"
        print_info "Manifest may be outdated - run: ssc generate"
        return 1
    fi

    # Get script metadata
    local requires_root script_status
    requires_root=$(yq ".scripts.\"${script_name}\".requires_root // false" "$MANIFEST_FILE")
    script_status=$(yq ".scripts.\"${script_name}\".status // \"unknown\"" "$MANIFEST_FILE")

    # Warn about deprecated scripts (non-blocking with --force)
    if [[ "$script_status" == "deprecated" ]]; then
        print_warning "Script is marked as DEPRECATED"
        if [[ "$force_run" != "true" ]]; then
            print_error "Use --force to run anyway"
            return 1
        fi
        print_warning "Proceeding with --force (deprecated script)"
    fi

    # Execute with sudo if required
    if [[ "$requires_root" == "true" && $EUID -ne 0 ]]; then
        print_info "Script requires root privileges - using sudo"
        exec sudo "$full_path" "${script_args[@]}"
    else
        exec "$full_path" "${script_args[@]}"
    fi
}

# ===== Command: info =====
cmd_info() {
    require_dependencies

    if [[ $# -lt 1 ]]; then
        print_error "Usage: ssc info <script-name>"
        return 1
    fi

    local script_name="$1"

    # Validate script name (security: prevent injection)
    validate_script_name "$script_name" || return 1

    # Check if script exists
    local exists
    exists=$(yq ".scripts | has(\"${script_name}\")" "$MANIFEST_FILE")

    if [[ "$exists" != "true" ]]; then
        print_error "Script not found: $script_name"
        print_info "Use 'ssc list --search $script_name' to find similar scripts"
        return 1
    fi

    # Get all script info
    local path category deployment service status type requires_root
    path=$(yq ".scripts.\"${script_name}\".path // \"?\"" "$MANIFEST_FILE")
    category=$(yq ".scripts.\"${script_name}\".category // \"?\"" "$MANIFEST_FILE")
    deployment=$(yq ".scripts.\"${script_name}\".deployment // \"?\"" "$MANIFEST_FILE")
    service=$(yq ".scripts.\"${script_name}\".service // \"none\"" "$MANIFEST_FILE")
    status=$(yq ".scripts.\"${script_name}\".status // \"?\"" "$MANIFEST_FILE")
    type=$(yq ".scripts.\"${script_name}\".type // \"?\"" "$MANIFEST_FILE")
    requires_root=$(yq ".scripts.\"${script_name}\".requires_root // false" "$MANIFEST_FILE")

    # Status color
    local status_color="$NC"
    case "$status" in
        active) status_color="$GREEN" ;;
        deprecated) status_color="$RED" ;;
        unknown) status_color="$DIM" ;;
    esac

    print_header "Script: $script_name"
    echo ""
    printf "  %-15s %s\n" "Path:" "$path"
    printf "  %-15s %s\n" "Category:" "$category"
    printf "  %-15s %s\n" "Type:" "$type"
    printf "  %-15s ${status_color}%s${NC}\n" "Status:" "$status"
    printf "  %-15s %s\n" "Deployment:" "$deployment"
    printf "  %-15s %s\n" "Service:" "$service"
    printf "  %-15s %s\n" "Requires Root:" "$requires_root"

    # Show file info
    local full_path="${REPO_ROOT}/${path}"
    if [[ -f "$full_path" ]]; then
        local lines size
        lines=$(wc -l < "$full_path")
        size=$(du -h "$full_path" | cut -f1)
        echo ""
        printf "  %-15s %s lines, %s\n" "File Size:" "$lines" "$size"
    fi

    # Show systemd status if service exists
    if [[ "$service" != "none" && "$service" != "null" ]]; then
        echo ""
        print_header "Systemd Service: $service"
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            printf "  %-15s ${GREEN}%s${NC}\n" "State:" "active (running)"
        elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
            printf "  %-15s ${YELLOW}%s${NC}\n" "State:" "enabled (not running)"
        else
            printf "  %-15s ${DIM}%s${NC}\n" "State:" "inactive"
        fi
    fi
}

# ===== Command: status =====
cmd_status() {
    require_dependencies

    local filter_script=""
    local show_timers=false
    local show_logs=false
    local log_lines=10

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--script)
                filter_script="$2"
                shift 2
                ;;
            -t|--timers)
                show_timers=true
                shift
                ;;
            -l|--logs)
                show_logs=true
                shift
                ;;
            -n|--lines)
                log_lines="$2"
                shift 2
                ;;
            -h|--help)
                cat << EOF
${BOLD}ssc status${NC} - Show systemd service status

${BOLD}OPTIONS:${NC}
    -s, --script <name>   Show status for specific script
    -t, --timers          Show timer overview
    -l, --logs            Include recent logs
    -n, --lines <num>     Number of log lines (default: 10)

${BOLD}EXAMPLES:${NC}
    ssc status                         # Overview of all services
    ssc status -s backup-example       # Specific script
    ssc status --timers                # Timer overview
EOF
                return 0
                ;;
            *)
                filter_script="$1"
                shift
                ;;
        esac
    done

    if [[ -n "$filter_script" ]]; then
        # Show status for specific script
        local service
        service=$(yq ".scripts.\"${filter_script}\".service // \"none\"" "$MANIFEST_FILE")

        if [[ "$service" == "none" || "$service" == "null" ]]; then
            print_warning "Script '$filter_script' has no associated service"
            return 0
        fi

        print_header "Service: $service"
        echo ""
        systemctl status "$service" --no-pager 2>/dev/null || print_warning "Service not found"

        # Check for associated timer
        local timer="${service%.service}.timer"
        if systemctl list-timers --all 2>/dev/null | grep -q "$timer"; then
            echo ""
            print_header "Timer: $timer"
            systemctl list-timers "$timer" --no-pager 2>/dev/null || true
        fi

        # Logs if requested
        if [[ "$show_logs" == "true" ]]; then
            echo ""
            print_header "Recent Logs (last $log_lines lines)"
            journalctl -u "$service" -n "$log_lines" --no-pager 2>/dev/null || true
        fi
    else
        # Show overview
        print_header "Service Status Overview"
        echo ""

        # Get all unique services from manifest
        local services
        services=$(yq '.scripts | to_entries[] | select(.value.service != "none" and .value.service != null and .value.service != "") | .value.service' "$MANIFEST_FILE" 2>/dev/null | sort -u)

        if [[ -z "$services" ]]; then
            print_warning "No services found in manifest"
            return 0
        fi

        printf "%-40s %-12s %-12s\n" "SERVICE" "STATE" "SUBSTATE"
        printf "%s\n" "$(printf '%.0s─' {1..65})"

        while IFS= read -r service; do
            [[ -z "$service" ]] && continue

            local state substate
            state=$(systemctl show "$service" --property=ActiveState --value 2>/dev/null || echo "unknown")
            substate=$(systemctl show "$service" --property=SubState --value 2>/dev/null || echo "unknown")

            local color="$NC"
            case "$state" in
                active)   color="$GREEN" ;;
                failed)   color="$RED" ;;
                inactive) color="$DIM" ;;
            esac

            printf "%-40s ${color}%-12s${NC} %-12s\n" "$service" "$state" "$substate"
        done <<< "$services"

        # Timer overview if requested
        if [[ "$show_timers" == "true" ]]; then
            echo ""
            print_header "Timer Overview"
            echo ""
            systemctl list-timers --all --no-pager 2>/dev/null | head -25
        fi
    fi
}

# ===== Command: logs =====
cmd_logs() {
    require_dependencies

    if [[ $# -lt 1 ]]; then
        print_error "Usage: ssc logs <script-name> [journalctl options]"
        return 1
    fi

    local script_name="$1"
    shift

    # Validate script name (security: prevent injection)
    validate_script_name "$script_name" || return 1

    local service
    service=$(yq ".scripts.\"${script_name}\".service // \"none\"" "$MANIFEST_FILE")

    if [[ "$service" == "none" || "$service" == "null" ]]; then
        print_error "Script '$script_name' has no associated service"
        print_info "Only scripts with a 'service:' field can show logs"
        return 1
    fi

    print_info "Showing logs for: $service"
    echo ""

    # Pass through to journalctl
    exec journalctl -u "$service" "$@"
}

# ===== Command: validate =====
cmd_validate() {
    require_dependencies

    print_header "Validating Manifest"
    echo ""

    local errors=0
    local checked=0

    # Check YAML syntax
    if ! yq eval '.' "$MANIFEST_FILE" > /dev/null 2>&1; then
        print_error "Manifest has invalid YAML syntax"
        return 1
    fi
    print_success "YAML syntax valid"

    # Check each script exists
    print_info "Checking script paths..."

    while IFS=$'\t' read -r name path; do
        [[ -z "$name" ]] && continue
        ((checked++))

        local full_path="${REPO_ROOT}/${path}"
        if [[ ! -f "$full_path" ]]; then
            print_error "Missing: $path ($name)"
            ((errors++))
        fi
    done < <(yq '.scripts | to_entries[] | [.key, .value.path] | @tsv' "$MANIFEST_FILE" 2>/dev/null)

    echo ""
    if [[ $errors -eq 0 ]]; then
        print_success "All $checked script paths valid"
    else
        print_error "$errors missing files found"
    fi

    # Check for unknown status values
    local unknown_status
    unknown_status=$(yq '.scripts | to_entries[] | select(.value.status == "unknown") | .key' "$MANIFEST_FILE" 2>/dev/null | wc -l)
    if [[ $unknown_status -gt 0 ]]; then
        print_warning "$unknown_status scripts have unknown status (missing front-matter)"
    fi

    return $errors
}

# ===== Command: generate =====
cmd_generate() {
    print_header "Generating Manifest"
    echo ""

    local generator="${SCRIPT_DIR}/generate-manifest.sh"

    if [[ -f "$generator" ]]; then
        "$generator" "$@"
    else
        print_error "Generator not found: $generator"
        return 1
    fi
}

# ===== Command: help =====
cmd_help() {
    cat << EOF
${BOLD}ssc${NC} - Server Scripts CLI v${VERSION}

${BOLD}USAGE:${NC}
    ssc <command> [options]

${BOLD}COMMANDS:${NC}
    list        List all scripts in manifest
    run         Execute a script by name
    info        Show detailed script information
    status      Show systemd service status
    logs        Show service logs (journalctl)
    validate    Validate manifest integrity
    generate    Regenerate manifest from front-matter
    help        Show this help message

${BOLD}LIST OPTIONS:${NC}
    -c, --category <name>   Filter by category (production, operations, etc.)
    -s, --status <status>   Filter by status (active, deprecated, unknown)
    -t, --type <type>       Filter by type (admin, report, diagnostic, library, helper, daemon)
    -p, --paths             Show full paths
    -n, --limit <num>       Limit output
    --search <term>         Search by name

${BOLD}RUN OPTIONS:${NC}
    -f, --force             Force run even if deprecated

${BOLD}STATUS OPTIONS:${NC}
    -s, --script <name>     Status for specific script
    -t, --timers            Show timer overview
    -l, --logs              Include recent logs
    -n, --lines <num>       Number of log lines

${BOLD}EXAMPLES:${NC}
    ssc list --status active
    ssc list --category operations --type backup
    ssc run backup-example --help
    ssc info monitoring-example
    ssc status --timers
    ssc logs health-check -n 50

${BOLD}MANIFEST:${NC}
    ${MANIFEST_FILE}

EOF
}

# ===== Main =====
main() {
    if [[ $# -eq 0 ]]; then
        cmd_help
        exit 0
    fi

    local command="$1"
    shift

    case "$command" in
        list|ls)    cmd_list "$@" ;;
        run|exec)   cmd_run "$@" ;;
        info|show)  cmd_info "$@" ;;
        status|st)  cmd_status "$@" ;;
        logs|log)   cmd_logs "$@" ;;
        validate)   cmd_validate "$@" ;;
        generate)   cmd_generate "$@" ;;
        help|--help|-h)
                    cmd_help ;;
        --version|-v)
                    echo "ssc v${VERSION}" ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            print_info "Available commands: list, run, info, status, logs, validate, generate, help"
            exit 1
            ;;
    esac
}

main "$@"
