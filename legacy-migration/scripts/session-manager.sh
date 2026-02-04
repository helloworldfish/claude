#!/bin/bash

# Legacy Migration Session Manager
# 管理会话状态、恢复和增量操作

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSIONS_DIR="${SESSIONS_DIR:-$PROJECT_ROOT/.legacy-migration/sessions}"
LOGS_DIR="${LOGS_DIR:-$PROJECT_ROOT/.legacy-migration/logs}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_ROOT/.refactor-backups}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
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

# Initialize directories
init_directories() {
    log_info "Initializing session directories..."

    mkdir -p "$SESSIONS_DIR"
    mkdir -p "$LOGS_DIR"
    mkdir -p "$BACKUP_DIR"

    # Create session directory structure
    local template_dir="$SESSIONS_DIR/template"
    mkdir -p "$template_dir/config"
    mkdir -p "$template_dir/state"
    mkdir -p "$template_dir/backup"
    mkdir -p "$template_dir/logs"

    # Create template files
    cat > "$template_dir/config/migration-config.yml" << 'EOF'
# Migration Configuration Template
project:
  name: ""
  path: ""
  type: ""
  original_state: {}
  target_state: {}

migration:
  goals: []
  strategy: "balanced"
  safety_level: "high"
  parallel_execution: false
  incremental_support: true

session:
  id: ""
  created_at: ""
  status: "created"
  progress: 0
  current_step: 0
  total_steps: 0

state:
  analyzed_files: []
  transformed_files: []
  validated_files: []
  failed_files: []
  warnings: []
  errors: []

backup:
  enabled: true
  location: ""
  manifest: {}

logs:
  session_log: ""
  error_log: ""
  audit_log: ""
EOF

    cat > "$template_dir/state/session-state.json" << 'EOF'
{
  "session_id": "",
  "status": "created",
  "progress": 0,
  "current_step": "",
  "steps_completed": [],
  "steps_pending": [],
  "files_processed": [],
  "files_remaining": [],
  "metrics": {
    "start_time": null,
    "last_update": null,
    "files_processed_count": 0,
    "errors_count": 0,
    "warnings_count": 0
  },
  "context": {
    "project_path": "",
    "project_type": "",
    "detected_issues": [],
    "migration_plan": {},
    "current_operation": null
  }
}
EOF

    log_success "Session directories initialized"
}

# Generate session ID
generate_session_id() {
    local project_name="$1"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    echo "${project_name}-${timestamp}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g'
}

# Create new session
create_session() {
    local project_path="$1"
    local project_name="$2"
    local session_id="$3"

    log_info "Creating session: $session_id"

    # Create session directory
    local session_dir="$SESSIONS_DIR/$session_id"
    mkdir -p "$session_dir"

    # Copy template
    cp -r "$SESSIONS_DIR/template" "$session_dir/"

    # Update configuration
    local config_file="$session_dir/config/migration-config.yml"
    sed -i "s/name: \"\"/name: \"$project_name\"/" "$config_file"
    sed -i "s/path: \"\"/path: \"$project_path\"/" "$config_file"
    sed -i "s/id: \"\"/id: \"$session_id\"/" "$config_file"
    sed -i "s/created_at: \"\"/created_at: \"$(date -Iseconds)\"/" "$config_file"

    # Initialize state
    local state_file="$session_dir/state/session-state.json"
    sed -i "s/\"session_id\": \"\"/\"session_id\": \"$session_id\"/" "$state_file"
    sed -i "s/\"status\": \"created\"/\"status\": \"in_progress\"/" "$state_file"
    sed -i "s/\"start_time\": null/\"start_time\": \"$(date -Iseconds)\"/" "$state_file"
    sed -i "s/\"last_update\": null/\"last_update\": \"$(date -Iseconds)\"/" "$state_file"

    # Create log files
    touch "$session_dir/logs/session.log"
    touch "$session_dir/logs/error.log"
    touch "$session_dir/logs/audit.log"

    log_success "Session created: $session_dir"

    echo "$session_dir"
}

# Enhanced session state update with context preservation
update_session_state() {
    local session_id="$1"
    local state_data="$2"

    local session_dir="$SESSIONS_DIR/$session_id"
    local state_file="$session_dir/state/session-state.json"
    local context_dir="$STATE_DIR/context/$session_id"

    # Backup current state
    cp "$state_file" "$state_file.backup.$(date +%s)"

    # Preserve context data if available
    if [[ -d "$context_dir" ]]; then
        # Create context snapshot
        local context_snapshot="$context_dir/snapshot-$(date +%s).json"

        if [[ -f "$context_dir/context-tracker.json" ]]; then
            cp "$context_dir/context-tracker.json" "$context_snapshot"

            # Update state with context reference
            jq --arg snapshot "$context_snapshot" \
               '.context_snapshot = $snapshot' <<< "$state_data" > "${state_file}.tmp" && \
               mv "${state_file}.tmp" "$state_data"
        fi
    fi

    # Update state
    echo "$state_data" > "$state_file"

    # Update timestamp and context version
    sed -i "s/\"last_update\": \"[^\"]*\"/\"last_update\": \"$(date -Iseconds)\"/" "$state_file"
    sed -i "s/\"context_version\": \"[^\"]*\"/\"context_version\": \"$(date +%s)\"/" "$state_file"

    log_info "Session state updated: $session_id"
}

# Get session status
get_session_status() {
    local session_id="$1"

    local session_dir="$SESSIONS_DIR/$session_id"
    local state_file="$session_dir/state/session-state.json"
    local backup_dir="$session_dir/backup"

    if [[ ! -f "$state_file" ]]; then
        echo "not_found"
        return 1
    fi

    # Extract status from JSON
    local status=$(grep -o '"status": "[^"]*"' "$state_file" | cut -d'"' -f4)

    # Check if backup exists
    if [[ -f "$backup_dir/backup-manifest.json" ]]; then
        local backup_info=$(cat "$backup_dir/backup-manifest.json")
        local files_count=$(echo "$backup_info" | jq -r '.files_count // 0')
        local backup_size=$(echo "$backup_info" | jq -r '.backup_size // 0')
        echo "$status|backup_exists|$files_count|$backup_size"
    else
        echo "$status|no_backup|0|0"
    fi
}

# List sessions
list_sessions() {
    log_info "Listing sessions..."

    if [[ ! -d "$SESSIONS_DIR" ]]; then
        echo "No sessions found"
        return 0
    fi

    # Create table header
    printf "%-25s %-30s %-15s %-10s %-15s %-15s\n" \
           "Session ID" "Created" "Status" "Progress" "Backup" "Project"
    printf "%-25s %-30s %-15s %-10s %-15s %-15s\n" \
           "----------" "-------" "------" "--------" "------" "-------"

    # List sessions
    for session_dir in "$SESSIONS_DIR"/*; do
        if [[ -d "$session_dir" ]]; then
            local session_id=$(basename "$session_dir")
            local config_file="$session_dir/config/migration-config.yml"
            local state_file="$session_dir/state/session-state.json"
            local backup_dir="$session_dir/backup"

            # Extract data
            local created=$(grep "created_at:" "$config_file" | cut -d'"' -f2 | cut -c1-16)
            local status_info=$(get_session_status "$session_id")
            local status=$(echo "$status_info" | cut -d'|' -f1)
            local backup_status=$(echo "$status_info" | cut -d'|' -f2)
            local files_count=$(echo "$status_info" | cut -d'|' -f3)
            local progress=$(grep '"progress":' "$state_file" | cut -d'"' -f4)
            local project=$(grep "name:" "$config_file" | cut -d'"' -f2)

            # Format backup status
            if [[ "$backup_status" == "backup_exists" ]]; then
                local backup_display="✓ ${files_count} files"
            else
                local backup_display="No backup"
            fi

            # Format output
            printf "%-25s %-30s %-15s %-10s %-15s %-15s\n" \
                   "$session_id" "$created" "$status" "$progress%" "$backup_display" "${project:0:15}..."
        fi
    done
}

# Resume session
resume_session() {
    local session_id="$1"

    local session_dir="$SESSIONS_DIR/$session_id"
    local state_file="$session_dir/state/session-state.json"

    if [[ ! -d "$session_dir" ]]; then
        log_error "Session not found: $session_id"
        return 1
    fi

    log_info "Resuming session: $session_id"

    # Load session state
    if [[ -f "$state_file" ]]; then
        # Extract key information
        local status=$(get_session_status "$session_id")
        local project_path=$(grep "path:" "$session_dir/config/migration-config.yml" | cut -d'"' -f2)
        local progress=$(grep '"progress":' "$state_file" | cut -d'"' -f4)

        log_info "Session Details:"
        log_info "  Status: $status"
        log_info "  Project: $project_path"
        log_info "  Progress: $progress%"

        # Update status to resuming
        sed -i 's/"status": "[^"]*"/"status": "resuming"/' "$state_file"
        sed -i "s/\"last_update\": \"[^\"]*\"/\"last_update\": \"$(date -Iseconds)\"/" "$state_file"

        log_success "Session $session_id resumed"
        echo "$session_dir"
    else
        log_error "Session state file not found"
        return 1
    fi
}

# Context-aware session recovery
resume_session_with_context() {
    local session_id="$1"

    local session_dir="$SESSIONS_DIR/$session_id"
    local state_file="$session_dir/state/session-state.json"

    if [[ ! -d "$session_dir" ]]; then
        log_error "Session not found: $session_id"
        return 1
    fi

    log_info "Context-aware resume for session: $session_id"

    # Load session state
    if [[ -f "$state_file" ]]; then
        # Extract context information
        local context_snapshot=$(grep -o '"context_snapshot": "[^"]*"' "$state_file" | cut -d'"' -f4)
        local context_version=$(grep -o '"context_version": "[^"]*"' "$state_file" | cut -d'"' -f4)

        log_info "Session Details:"
        log_info "  Status: $(grep -o '"status": "[^"]*"' "$state_file" | cut -d'"' -f4)"
        log_info "  Project: $(grep "path:" "$session_dir/config/migration-config.yml" | cut -d'"' -f2)"
        log_info "  Progress: $(grep '"progress":' "$state_file" | cut -d'"' -f4)%"
        log_info "  Context Version: $context_version"

        # Restore context if snapshot exists
        if [[ -n "$context_snapshot" && -f "$context_snapshot" ]]; then
            local context_dir="$STATE_DIR/context/$session_id"
            local context_tracker="$context_dir/context-tracker.json"

            # Copy snapshot back to tracker
            cp "$context_snapshot" "$context_tracker"

            log_info "Context restored from snapshot: $context_snapshot"

            # Initialize context management if needed
            if [[ -f "$SCRIPT_DIR/context-integration.sh" ]]; then
                local project_path=$(grep "path:" "$session_dir/config/migration-config.yml" | cut -d'"' -f2)
                "$SCRIPT_DIR/context-integration.sh" init "$session_id" "$project_path"
            fi
        else
            log_warning "No context snapshot found, initializing fresh context"
        fi

        # Update status to resuming
        sed -i 's/"status": "[^"]*"/"status": "resuming"/' "$state_file"
        sed -i "s/\"last_update\": \"[^\"]*\"/\"last_update\": \"$(date -Iseconds)\"/" "$state_file"
        sed -i "s/\"context_version\": \"[^\"]*\"/\"context_version\": \"$(date +%s)\"/" "$state_file"

        log_success "Context-aware session $session_id resumed"
        echo "$session_dir"
    else
        log_error "Session state file not found"
        return 1
    fi
}

# Save checkpoint
save_checkpoint() {
    local session_id="$1"
    local checkpoint_name="$2"
    local additional_data="$3"

    local session_dir="$SESSIONS_DIR/$session_id"
    local checkpoint_dir="$session_dir/checkpoints"

    # Create checkpoint directory
    mkdir -p "$checkpoint_dir"

    # Create checkpoint
    local checkpoint_file="$checkpoint_dir/${checkpoint_name}.json"
    local timestamp=$(date -Iseconds)

    cat > "$checkpoint_file" << EOF
{
  "checkpoint_name": "$checkpoint_name",
  "created_at": "$timestamp",
  "session_state": {
    $(cat "$session_dir/state/session-state.json")
  },
  "additional_data": $additional_data
}
EOF

    log_info "Checkpoint saved: $checkpoint_file"
}

# List checkpoints
list_checkpoints() {
    local session_id="$1"

    local session_dir="$SESSIONS_DIR/$session_id"
    local checkpoint_dir="$session_dir/checkpoints"

    if [[ ! -d "$checkpoint_dir" ]]; then
        echo "No checkpoints found"
        return 0
    fi

    echo "Checkpoints for session $session_id:"
    for checkpoint in "$checkpoint_dir"/*.json; do
        if [[ -f "$checkpoint" ]]; then
            local name=$(grep -o '"checkpoint_name": "[^"]*"' "$checkpoint" | cut -d'"' -f4)
            local time=$(grep -o '"created_at": "[^"]*"' "$checkpoint" | cut -d'"' -f2)
            echo "  - $name ($time)"
        fi
    done
}

# Cleanup old sessions
cleanup_sessions() {
    local max_age_days="${1:-30}"

    log_info "Cleaning up sessions older than $max_age_days days..."

    local cutoff_date=$(date -d "$max_age_days days ago" +%s)

    for session_dir in "$SESSIONS_DIR"/*; do
        if [[ -d "$session_dir" ]]; then
            local session_id=$(basename "$session_dir")
            local created_date=$(stat -c %Y "$session_dir" 2>/dev/null || stat -f %m "$session_dir" 2>/dev/null)

            if [[ $created_date -lt $cutoff_date ]]; then
                log_info "Removing old session: $session_id"
                rm -rf "$session_dir"
            fi
        fi
    done

    log_success "Cleanup completed"
}

# Export session
export_session() {
    local session_id="$1"
    local export_dir="$2"

    local session_dir="$SESSIONS_DIR/$session_id"

    if [[ ! -d "$session_dir" ]]; then
        log_error "Session not found: $session_id"
        return 1
    fi

    log_info "Exporting session: $session_id to $export_dir"

    mkdir -p "$export_dir"
    cp -r "$session_dir" "$export_dir/"

    # Create export manifest
    cat > "$export_dir/export-manifest.json" << EOF
{
  "session_id": "$session_id",
  "exported_at": "$(date -Iseconds)",
  "exported_to": "$export_dir",
  "files": [
    "config/migration-config.yml",
    "state/session-state.json",
    "logs/",
    "checkpoints/",
    "backup/"
  ]
}
EOF

    log_success "Session exported successfully"
}

# Import session
import_session() {
    local import_file="$1"

    if [[ ! -f "$import_file" ]]; then
        log_error "Import file not found: $import_file"
        return 1
    fi

    log_info "Importing session from: $import_file"

    # Extract session ID from manifest
    local session_id=$(grep -o '"session_id": "[^"]*"' "$import_file/export-manifest.json" | cut -d'"' -f4)

    # Import to sessions directory
    local import_dir="$SESSIONS_DIR/imported-$session_id"
    mkdir -p "$import_dir"
    tar -xzf "$import_file" -C "$import_dir"

    log_success "Session imported: $session_id"
    echo "$import_dir"
}

# Error handling
handle_error() {
    local session_id="$1"
    local error_message="$2"
    local error_code="${3:-1}"

    local session_dir="$SESSIONS_DIR/$session_id"
    local error_file="$session_dir/logs/error.log"

    # Log error
    echo "$(date -Iseconds) - ERROR [$error_code]: $error_message" >> "$error_file"

    # Update session state
    local state_file="$session_dir/state/session-state.json"
    sed -i 's/"status": "[^"]*"/"status": "failed"/' "$state_file"
    sed -i "s/\"last_update\": \"[^\"]*\"/\"last_update\": \"$(date -Iseconds)\"/" "$state_file"

    log_error "Error handled for session $session_id: $error_message"
}

# Main execution
main() {
    case "${1:-}" in
        "init")
            init_directories
            ;;
        "create")
            create_session "$2" "$3" "$4"
            ;;
        "list")
            list_sessions
            ;;
        "status")
            get_session_status "$2"
            ;;
        "resume")
            resume_session "$2"
            ;;
        "resume-context")
            resume_session_with_context "$2"
            ;;
        "checkpoint")
            save_checkpoint "$2" "$3" "$4"
            ;;
        "checkpoints")
            list_checkpoints "$2"
            ;;
        "cleanup")
            cleanup_sessions "$2"
            ;;
        "export")
            export_session "$2" "$3"
            ;;
        "import")
            import_session "$2"
            ;;
        "help")
            echo "Session Manager Usage:"
            echo "  $0 init                    - Initialize session directories"
            echo "  $0 create <path> <name> <id> - Create new session"
            echo "  $0 list                    - List all sessions"
            echo "  $0 status <id>             - Get session status"
            echo "  $0 resume <id>             - Resume session"
            echo "  $0 resume-context <id>     - Resume session with context"
            echo "  $0 checkpoint <id> <name> [data] - Save checkpoint"
            echo "  $0 checkpoints <id>        - List checkpoints"
            echo "  $0 cleanup [days]          - Cleanup old sessions"
            echo "  $0 export <id> <dir>       - Export session"
            echo "  $0 import <file>           - Import session"
            ;;
        *)
            echo "Unknown command. Use '$0 help' for usage."
            exit 1
            ;;
    esac
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi