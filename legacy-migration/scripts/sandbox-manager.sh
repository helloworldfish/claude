#!/bin/bash
##############################################################################
# Sandbox Manager Script
#
# This script creates and manages isolated sandbox environments for safe
# refactoring operations.
#
# Usage:
#   ./sandbox-manager.sh [action] [options]
#
# Actions:
#   create       Create a new sandbox
#   apply-plan   Apply refactoring plan in sandbox
#   merge        Merge sandbox changes back to source
#   cleanup      Remove sandbox and artifacts
#   status       Show sandbox status
#   list         List all sandboxes
#
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
SANDBOX_ROOT="${PLUGIN_DIR}/../.sandboxes"
BACKUP_ROOT="${PLUGIN_DIR}/../.sandbox-backups"

# Default values
SOURCE_DIR="."
TARGET_DIR=""
SANDBOX_MODE="clone"
REMOTE_REPO=""
PLAN_PATH=""
AUTO_CLEANUP=false
BACKUP_SOURCE=true
MERGE_STRATEGY="diff"
GIT_BRANCH="refactor/sandbox"

##############################################################################
# Helper Functions
##############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "=================================="
    echo "$1"
    echo "=================================="
    echo ""
}

print_step() {
    echo -e "\n${BLUE}▶ $1${NC}\n"
}

##############################################################################
# Validation Functions
##############################################################################

validate_source() {
    local source="$1"

    log_info "Validating source directory..."

    if [ ! -d "$source" ]; then
        log_error "Source directory not found: $source"
        exit 1
    fi

    if [ ! -r "$source" ]; then
        log_error "Source directory not readable: $source"
        exit 1
    fi

    log_success "Source validation passed"
}

validate_disk_space() {
    local required_mb=500
    local available_mb=$(df -m . | tail -1 | awk '{print $4}')

    if [ "$available_mb" -lt "$required_mb" ]; then
        log_error "Insufficient disk space. Required: ${required_mb}MB, Available: ${available_mb}MB"
        exit 1
    fi

    log_success "Disk space check passed (${available_mb}MB available)"
}

validate_git_state() {
    if [ "$SANDBOX_MODE" = "branch" ]; then
        log_info "Checking git state..."

        if [ -n "$(git status --porcelain)" ]; then
            log_warning "You have uncommitted changes"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Operation cancelled"
                exit 0
            fi
        fi

        log_success "Git state validation passed"
    fi
}

##############################################################################
# Backup Functions
##############################################################################

create_backup() {
    local source="$1"

    if [ "$BACKUP_SOURCE" != true ]; then
        log_info "Backup skipped (disabled)"
        return
    fi

    print_step "Creating Source Backup"

    local timestamp=$(date +"%Y-%m-%d-%H%M%S")
    local backup_dir="${BACKUP_ROOT}/backup-${timestamp}"

    log_info "Creating backup at: $backup_dir"
    mkdir -p "$backup_dir"

    # Create backup manifest
    cat > "${backup_dir}/backup-manifest.json" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "source": "${source}",
  "backup_type": "pre-sandbox"
}
EOF

    # Backup based on mode
    if [ "$SANDBOX_MODE" = "branch" ]; then
        # For branch mode, just backup git state
        git rev-parse HEAD > "${backup_dir}/git-head.txt"
        git diff HEAD > "${backup_dir}/git-diff.patch" || true
    else
        # For clone/copy modes, backup critical files
        if [ -f "${source}/pom.xml" ]; then
            cp "${source}/pom.xml" "${backup_dir}/"
        fi
        if [ -f "${source}/build.gradle" ]; then
            cp "${source}/build.gradle" "${backup_dir}/"
        fi
    fi

    log_success "Backup created at $backup_dir"
}

##############################################################################
# Sandbox Creation Functions
##############################################################################

generate_sandbox_name() {
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local random_suffix=$(openssl rand -hex 3 2>/dev/null || echo "default")
    echo "sandbox-${timestamp}-${random_suffix}"
}

create_sandbox_clone() {
    local source="$1"
    local target="$2"

    print_step "Creating Clone Sandbox"

    log_info "Cloning from: $source"
    log_info "Cloning to: $target"

    mkdir -p "$target"

    # Copy all files
    if [ -d "${source}/.git" ]; then
        # Copy including git directory
        cp -r "$source"/. "$target"/

        # Make it a new repository
        cd "$target"
        rm -rf .git
        git init
        git add .
        git commit -m "Initial commit - sandbox clone from $(basename "$source")"
        cd - > /dev/null
    else
        # Simple directory copy
        cp -r "$source"/* "$target"/
    fi

    # Create sandbox metadata
    create_sandbox_metadata "$target" "$source" "clone"

    log_success "Sandbox created: $target"
}

create_sandbox_branch() {
    local source="$1"
    local branch_name="$2"

    print_step "Creating Branch Sandbox"

    log_info "Creating branch: $branch_name"

    cd "$source"

    # Create and checkout new branch
    git checkout -b "$branch_name" 2>/dev/null || {
        log_error "Failed to create branch (may already exist)"
        exit 1
    }

    # Create sandbox metadata in branch
    create_sandbox_metadata "$source" "$source" "branch" "$branch_name"

    log_success "Branch sandbox created: $branch_name"
}

create_sandbox_copy() {
    local source="$1"
    local target="$2"

    print_step "Creating Copy Sandbox"

    log_info "Copying from: $source"
    log_info "Copying to: $target"

    mkdir -p "$target"

    # Copy excluding .git and build artifacts
    rsync -av \
        --exclude='.git/' \
        --exclude='.idea/' \
        --exclude='target/' \
        --exclude='build/' \
        --exclude='node_modules/' \
        --exclude='.sandboxes/' \
        "$source"/ "$target"/

    # Create sandbox metadata
    create_sandbox_metadata "$target" "$source" "copy"

    log_success "Sandbox created: $target"
}

create_sandbox_metadata() {
    local target="$1"
    local source="$2"
    local mode="$3"
    local branch="${4:-N/A}"

    local metadata_file="${target}/.sandbox-info"

    cat > "$metadata_file" << EOF
# Sandbox Information

**Created**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Source**: $source
**Target**: $target
**Mode**: $mode
**Branch**: $branch

## Sandbox Files

- **Metadata**: .sandbox-info (this file)
- **Manifest**: .sandbox-manifest.json
- **Changes**: .sandbox-changes.md (generated after refactoring)

## Working in Sandbox

1. Make your changes
2. Run tests: mvn test (or ./gradlew test)
3. Commit changes: git add . && git commit -m "Describe changes"
4. Merge back when ready

## Cleanup

To remove this sandbox:
- Branch mode: \`git checkout <original-branch> && git branch -D $branch\`
- Clone/Copy mode: \`rm -rf $target\`

Generated by: Claude Code Refactoring Sandbox
EOF

    # Create JSON manifest
    cat > "${target}/.sandbox-manifest.json" << EOF
{
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "source": "${source}",
  "target": "${target}",
  "mode": "${mode}",
  "branch": "${branch}",
  "version": "1.0.0"
}
EOF
}

##############################################################################
# Refactor Application Functions
##############################################################################

apply_plan_in_sandbox() {
    local sandbox="$1"
    local plan="$2"

    print_step "Applying Refactoring Plan in Sandbox"

    if [ ! -d "$plan" ]; then
        log_error "Plan directory not found: $plan"
        exit 1
    fi

    log_info "Sandbox: $sandbox"
    log_info "Plan: $plan"

    # Navigate to sandbox
    cd "$sandbox"

    # Copy plan to sandbox
    local sandbox_plan="${sandbox}/.sandbox-plan"
    cp -r "$plan" "$sandbox_plan"

    # Apply the plan using the apply script
    if [ -f "${sandbox_plan}/09-apply-refactor.sh" ]; then
        bash "${sandbox_plan}/09-apply-refactor.sh" --apply
    else
        log_warning "No apply script found in plan"
        log_info "Please apply manually using: /refactor-apply --plan $plan"
    fi

    cd - > /dev/null

    log_success "Plan applied in sandbox"
}

##############################################################################
# Merge Functions
##############################################################################

generate_diff_patches() {
    local sandbox="$1"
    local source="$2"
    local patches_dir="${source}/patches"

    print_step "Generating Diff Patches"

    mkdir -p "$patches_dir"

    local timestamp=$(date +"%Y%m%d-%H%M%S")

    if [ -d "${sandbox}/.git" ] && [ -d "${source}/.git" ]; then
        # Both are git repos - use git diff
        cd "$source"

        # Add sandbox as remote
        git remote add sandbox-temp "$sandbox" 2>/dev/null || true
        git fetch sandbox-temp 2>/dev/null || true

        # Generate patches
        git diff sandbox-temp/main > "${patches_dir}/sandbox-${timestamp}.diff" || true

        # Clean up
        git remote remove sandbox-temp 2>/dev/null || true

        cd - > /dev/null
    else
        # Use regular diff
        diff -r "$source" "$sandbox" > "${patches_dir}/sandbox-${timestamp}.diff" || true
    fi

    log_success "Patches generated in: $patches_dir"
    ls -la "$patches_dir"
}

generate_unified_patch() {
    local sandbox="$1"
    local source="$2"

    print_step "Generating Unified Patch"

    local patch_file="${source}/sandbox-refactor.patch"

    if [ -d "${sandbox}/.git" ] && [ -d "${source}/.git" ]; then
        cd "$source"
        git remote add sandbox-temp "$sandbox" 2>/dev/null || true
        git diff sandbox-temp/main > "$patch_file" || true
        git remote remove sandbox-temp 2>/dev/null || true
        cd - > /dev/null
    else
        diff -ur "$source" "$sandbox" > "$patch_file" || true
    fi

    log_success "Unified patch: $patch_file"
}

create_pull_request() {
    local sandbox="$1"
    local branch="$2"

    print_step "Creating Pull Request"

    if [ -z "$REMOTE_REPO" ]; then
        log_error "No remote repository specified (--remote)"
        exit 1
    fi

    cd "$sandbox"

    # Add remote and push
    git remote add sandbox-origin "$REMOTE_REPO" 2>/dev/null || true
    git push -u sandbox-origin "$branch" || {
        log_error "Failed to push to remote"
        exit 1
    }

    # PR creation instructions
    log_success "Branch pushed to: $REMOTE_REPO"
    log_info "Create PR at: $(echo "$REMOTE_REPO" | sed 's|git@github.com:|https://github.com/|')/pull/new/$branch"

    cd - > /dev/null
}

##############################################################################
# Cleanup Functions
##############################################################################

cleanup_sandbox() {
    local sandbox="$1"

    print_step "Cleaning Up Sandbox"

    if [ ! -e "$sandbox" ]; then
        log_warning "Sandbox not found: $sandbox"
        return
    fi

    log_warning "This will delete: $sandbox"
    read -p "Continue? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$sandbox"
        log_success "Sandbox removed"
    else
        log_info "Cleanup cancelled"
    fi
}

cleanup_sandbox_branch() {
    local branch="$1"

    print_step "Cleaning Up Sandbox Branch"

    # Switch to main branch first
    git checkout main 2>/dev/null || git checkout master 2>/dev/null || {
        log_error "Cannot switch away from branch $branch"
        exit 1
    }

    # Delete the branch
    git branch -D "$branch" 2>/dev/null || {
        log_warning "Branch already deleted or doesn't exist"
        return
    }

    log_success "Branch deleted: $branch"
}

list_sandboxes() {
    print_header "Sandbox Environments"

    if [ ! -d "$SANDBOX_ROOT" ] && [ ! -f ".sandbox-branches" ]; then
        log_info "No sandboxes found"
        return
    fi

    # List directory sandboxes
    if [ -d "$SANDBOX_ROOT" ]; then
        echo "Directory Sandboxes:"
        echo ""
        for sandbox in "$SANDBOX_ROOT"/*; do
            if [ -d "$sandbox" ]; then
                local name=$(basename "$sandbox")
                local info="${sandbox}/.sandbox-info"

                echo "📁 $name"

                if [ -f "$info" ]; then
                    echo "   Created: $(grep 'Created:' "$info" | cut -d':' -f2 | xargs)"
                    echo "   Mode: $(grep 'Mode:' "$info" | cut -d':' -f2 | xargs)"
                fi

                echo ""
            fi
        done
    fi

    # List branch sandboxes
    if [ -d ".git" ]; then
        echo "Branch Sandboxes:"
        echo ""

        git branch | grep "refactor/sandbox" | while read -r branch; do
            echo "🌿 $branch"
        done
    fi
}

show_sandbox_status() {
    local sandbox="$1"

    print_header "Sandbox Status: $sandbox"

    if [ ! -e "$sandbox" ]; then
        log_error "Sandbox not found: $sandbox"
        exit 1
    fi

    # Show metadata
    if [ -f "${sandbox}/.sandbox-info" ]; then
        cat "${sandbox}/.sandbox-info"
    fi

    # Show git status if applicable
    if [ -d "${sandbox}/.git" ]; then
        echo ""
        echo "Git Status:"
        cd "$sandbox"
        git status
        cd - > /dev/null
    fi

    # Show changes
    if [ -f "${sandbox}/.sandbox-changes.md" ]; then
        echo ""
        echo "Refactoring Changes:"
        cat "${sandbox}/.sandbox-changes.md"
    fi
}

##############################################################################
# Main Functions
##############################################################################

action_create() {
    print_header "Creating Sandbox Environment"

    # Validate
    validate_source "$SOURCE_DIR"
    validate_disk_space
    validate_git_state

    # Create backup
    create_backup "$SOURCE_DIR"

    # Generate target name if not provided
    if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="${SANDBOX_ROOT}/$(generate_sandbox_name)"
    fi

    # Create sandbox based on mode
    case "$SANDBOX_MODE" in
        clone)
            create_sandbox_clone "$SOURCE_DIR" "$TARGET_DIR"
            ;;
        branch)
            create_sandbox_branch "$SOURCE_DIR" "$GIT_BRANCH"
            TARGET_DIR="$SOURCE_DIR"  # In branch mode, target is source
            ;;
        copy)
            create_sandbox_copy "$SOURCE_DIR" "$TARGET_DIR"
            ;;
        *)
            log_error "Unknown sandbox mode: $SANDBOX_MODE"
            exit 1
            ;;
    esac

    # Apply plan if provided
    if [ -n "$PLAN_PATH" ]; then
        apply_plan_in_sandbox "$TARGET_DIR" "$PLAN_PATH"
    fi

    # Success message
    echo ""
    log_success "Sandbox created successfully!"
    echo ""
    echo "Sandbox location: $TARGET_DIR"
    echo "Mode: $SANDBOX_MODE"

    if [ "$SANDBOX_MODE" = "branch" ]; then
        echo "Branch: $GIT_BRANCH"
        echo ""
        echo "Next steps:"
        echo "  cd $SOURCE_DIR  # Already on branch $GIT_BRANCH"
        echo "  # Make your changes"
        echo "  /refactor-plan --target ."
        echo "  /refactor-apply --plan ./refactoring-plans/*/"
    else
        echo ""
        echo "Next steps:"
        echo "  cd $TARGET_DIR"
        echo "  # Make your changes"
        echo "  /refactor-plan --target ."
        echo "  /refactor-apply --plan ./refactoring-plans/*/"
    fi

    if [ "$AUTO_CLEANUP" = true ]; then
        echo ""
        log_warning "Auto-cleanup enabled - sandbox will be removed after merge"
    fi
}

action_merge() {
    local sandbox="$1"

    print_header "Merging Sandbox Changes"

    if [ -z "$sandbox" ]; then
        log_error "Please specify sandbox path"
        exit 1
    fi

    case "$MERGE_STRATEGY" in
        diff)
            generate_diff_patches "$sandbox" "$SOURCE_DIR"
            ;;
        patch)
            generate_unified_patch "$sandbox" "$SOURCE_DIR"
            ;;
        merge-commit)
            log_warning "Manual merge required"
            log_info "Use: git checkout <original-branch> && git merge <sandbox-branch>"
            ;;
        pr)
            create_pull_request "$sandbox" "$GIT_BRANCH"
            ;;
        *)
            log_error "Unknown merge strategy: $MERGE_STRATEGY"
            exit 1
            ;;
    esac

    # Auto cleanup if enabled
    if [ "$AUTO_CLEANUP" = true ]; then
        if [ "$SANDBOX_MODE" = "branch" ]; then
            cleanup_sandbox_branch "$GIT_BRANCH"
        else
            cleanup_sandbox "$sandbox"
        fi
    fi
}

action_cleanup() {
    local sandbox="$1"

    if [ -z "$sandbox" ]; then
        log_error "Please specify sandbox path or branch name"
        exit 1
    fi

    if [ "$SANDBOX_MODE" = "branch" ]; then
        cleanup_sandbox_branch "$sandbox"
    else
        cleanup_sandbox "$sandbox"
    fi
}

action_status() {
    local sandbox="$1"

    if [ -z "$sandbox" ]; then
        log_error "Please specify sandbox path"
        exit 1
    fi

    show_sandbox_status "$sandbox"
}

action_list() {
    list_sandboxes
}

##############################################################################
# Argument Parsing
##############################################################################

parse_arguments() {
    ACTION="$1"
    shift

    while [[ $# -gt 0 ]]; do
        case $1 in
            --source)
                SOURCE_DIR="$2"
                shift 2
                ;;
            --target)
                TARGET_DIR="$2"
                shift 2
                ;;
            --mode)
                SANDBOX_MODE="$2"
                shift 2
                ;;
            --remote)
                REMOTE_REPO="$2"
                shift 2
                ;;
            --plan)
                PLAN_PATH="$2"
                shift 2
                ;;
            --auto-cleanup)
                AUTO_CLEANUP=true
                shift
                ;;
            --no-backup)
                BACKUP_SOURCE=false
                shift
                ;;
            --merge-strategy)
                MERGE_STRATEGY="$2"
                shift 2
                ;;
            --git-branch)
                GIT_BRANCH="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

##############################################################################
# Main Entry Point
##############################################################################

main() {
    # Parse action and arguments
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <action> [options]"
        echo ""
        echo "Actions:"
        echo "  create    Create a new sandbox"
        echo "  merge     Merge sandbox changes back"
        echo "  cleanup   Remove sandbox"
        echo "  status    Show sandbox status"
        echo "  list      List all sandboxes"
        echo ""
        echo "Run: $0 <action> --help for more details"
        exit 1
    fi

    parse_arguments "$@"

    # Execute action
    case "$ACTION" in
        create)
            action_create
            ;;
        merge)
            action_merge "$TARGET_DIR"
            ;;
        cleanup)
            action_cleanup "$TARGET_DIR"
            ;;
        status)
            action_status "$TARGET_DIR"
            ;;
        list)
            action_list
            ;;
        *)
            log_error "Unknown action: $ACTION"
            exit 1
            ;;
    esac
}

# Run main
main "$@"
