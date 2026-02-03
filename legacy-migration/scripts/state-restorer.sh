#!/bin/bash

# Legacy Migration State Restorer
# 支持恢复上次对话的工作状态，继续未完成的迁移任务

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSIONS_DIR="${SESSIONS_DIR:-$HOME/.legacy-migration/sessions}"
STATE_DIR="${STATE_DIR:-$HOME/.legacy-migration/state}"
RECOVERY_DIR="${RECOVERY_DIR:-$HOME/.legacy-migration/recovery}"
LOG_FILE="$RECOVERY_DIR/recovery.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging with timestamp
log_with_time() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${CYAN}[$timestamp]${NC} $1"
}

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

# Initialize recovery system
init_recovery_system() {
    log_with_time "Initializing recovery system..."

    mkdir -p "$RECOVERY_DIR"
    mkdir -p "$STATE_DIR"

    # Create recovery log file
    touch "$LOG_FILE"

    # Create recovery status file
    cat > "$RECOVERY_DIR/recovery-status.json" << 'EOF'
{
  "initialized": true,
  "last_recovery": null,
  "recovery_attempts": 0,
  "successful_recoveries": 0,
  "failed_recoveries": 0,
  "active_sessions": []
}
EOF

    log_success "Recovery system initialized"
}

# Detect available recovery points
detect_recovery_points() {
    log_info "Detecting available recovery points..."

    local recovery_points=()

    # Check for incomplete sessions
    if [[ -d "$SESSIONS_DIR" ]]; then
        for session_dir in "$SESSIONS_DIR"/*; do
            if [[ -d "$session_dir" ]]; then
                local session_id=$(basename "$session_dir")
                local state_file="$session_dir/state/session-state.json"

                if [[ -f "$state_file" ]]; then
                    local status=$(jq -r '.status' "$state_file")
                    local progress=$(jq -r '.progress' "$state_file")

                    if [[ "$status" != "completed" && "$status" != "failed" ]]; then
                        local project_name=$(jq -r '.project.name' "$session_dir/config/migration-config.yml" 2>/dev/null || echo "Unknown")
                        local created_at=$(jq -r '.created_at' "$session_dir/config/migration-config.yml" 2>/dev/null | cut -c1-16)

                        recovery_points+=("$session_id|$project_name|$status|$progress|$created_at|$session_dir")
                    fi
                fi
            fi
        done
    fi

    # Check for checkpoint files
    if [[ -d "$STATE_DIR" ]]; then
        local checkpoint_dir="$STATE_DIR/checkpoints"
        if [[ -d "$checkpoint_dir" ]]; then
            for checkpoint in "$checkpoint_dir"/*.json; do
                if [[ -f "$checkpoint" ]]; then
                    local checkpoint_id=$(basename "$checkpoint" .json)
                    recovery_points+=("checkpoint|$checkpoint_id|checkpoint|pending|$(date -r "$checkpoint" +'%Y-%m-%d %H:%M')|$checkpoint")
                fi
            done
        fi
    fi

    echo "${recovery_points[@]}"
}

# List recovery points
list_recovery_points() {
    local recovery_points=($1)

    if [[ ${#recovery_points[@]} -eq 0 ]]; then
        echo "No recovery points found"
        return 0
    fi

    # Create table header
    printf "%-15s %-30s %-15s %-10s %-20s %-40s\n" \
           "Type" "ID/Name" "Status" "Progress" "Created" "Details"
    printf "%-15s %-30s %-15s %-10s %-20s %-40s\n" \
           "----" "--------" "------" "--------" "------" "-------"

    # List recovery points
    for point in "${recovery_points[@]}"; do
        IFS='|' read -r type id status progress created details <<< "$point"

        if [[ "$type" == "session" ]]; then
            local session_dir="$details"
            printf "%-15s %-30s %-15s %-10s %-20s %-40s\n" \
                   "Session" "$id" "$status" "$progress%" "$created" "$(basename "$session_dir")"
        elif [[ "$type" == "checkpoint" ]]; then
            printf "%-15s %-30s %-15s %-10s %-20s %-40s\n" \
                   "Checkpoint" "$id" "$status" "N/A" "$created" "File: $(basename "$details")"
        fi
    done
}

# Load session state
load_session_state() {
    local session_id="$1"
    local session_dir="$SESSIONS_DIR/$session_id"

    if [[ ! -d "$session_dir" ]]; then
        log_error "Session directory not found: $session_dir"
        return 1
    fi

    local state_file="$session_dir/state/session-state.json"
    if [[ ! -f "$state_file" ]]; then
        log_error "Session state file not found: $state_file"
        return 1
    fi

    # Load and validate state
    if ! jq empty "$state_file" 2>/dev/null; then
        log_error "Invalid JSON in state file: $state_file"
        return 1
    fi

    # Update status to recovering
    jq '.status = "recovering"' "$state_file" > "$state_file.tmp" && \
    mv "$state_file.tmp" "$state_file"

    log_success "Session state loaded: $session_id"
    cat "$state_file"
}

# Load checkpoint state
load_checkpoint_state() {
    local checkpoint_id="$1"
    local checkpoint_file="$STATE_DIR/checkpoints/$checkpoint_id.json"

    if [[ ! -f "$checkpoint_file" ]]; then
        log_error "Checkpoint file not found: $checkpoint_file"
        return 1
    fi

    # Validate checkpoint
    if ! jq empty "$checkpoint_file" 2>/dev/null; then
        log_error "Invalid JSON in checkpoint file: $checkpoint_file"
        return 1
    fi

    log_success "Checkpoint state loaded: $checkpoint_id"
    cat "$checkpoint_file"
}

# Restore session context
restore_session_context() {
    local session_id="$1"
    local session_dir="$SESSIONS_DIR/$session_id"

    log_info "Restoring session context: $session_id"

    # Load configuration
    local config_file="$session_dir/config/migration-config.yml"
    if [[ -f "$config_file" ]]; then
        log_info "Loading configuration from: $config_file"
    fi

    # Load state
    local state_file="$session_dir/state/session-state.json"
    if [[ -f "$state_file" ]]; then
        log_info "Loading state from: $state_file"

        # Extract key information
        local current_step=$(jq -r '.current_step' "$state_file")
        local progress=$(jq -r '.progress' "$state_file")
        local steps_completed=$(jq -r '.steps_completed // []' "$state_file")

        log_info "Current step: $current_step"
        log_info "Progress: $progress%"
        log_info "Completed steps: $steps_completed"
    fi

    # Load logs
    local log_dir="$session_dir/logs"
    if [[ -d "$log_dir" ]]; then
        local recent_log=$(find "$log_dir" -name "*.log" -type f -mtime -1 | head -1)
        if [[ -n "$recent_log" ]]; then
            log_info "Recent log found: $recent_log"
            log_info "Last 10 lines:"
            tail -n 10 "$recent_log" | sed 's/^/  /'
        fi
    fi

    # Restore file tracker
    local file_tracker="$STATE_DIR/file-tracker.json"
    if [[ -f "$file_tracker" ]]; then
        local session_files=$(jq "
            .files |
            to_entries |
            map(select(.value.session_id == \"$session_id\")) |
            length
        " "$file_tracker")
        log_info "Tracked files in session: $session_files"
    fi

    log_success "Session context restored: $session_id"
}

# Validate recovery point
validate_recovery_point() {
    local point_type="$1"
    local point_id="$2"
    local session_dir="$3"

    log_info "Validating recovery point: $point_type - $point_id"

    case "$point_type" in
        "session")
            if [[ ! -d "$session_dir" ]]; then
                log_error "Session directory missing: $session_dir"
                return 1
            fi

            # Check essential files
            local essential_files=(
                "$session_dir/config/migration-config.yml"
                "$session_dir/state/session-state.json"
                "$session_dir/logs/session.log"
            )

            for file in "${essential_files[@]}"; do
                if [[ ! -f "$file" ]]; then
                    log_error "Essential file missing: $file"
                    return 1
                fi
            done

            log_success "Session recovery point validated"
            ;;
        "checkpoint")
            local checkpoint_file="$session_dir/checkpoints/$point_id.json"
            if [[ ! -f "$checkpoint_file" ]]; then
                log_error "Checkpoint file missing: $checkpoint_file"
                return 1
            fi

            log_success "Checkpoint recovery point validated"
            ;;
        *)
            log_error "Unknown recovery point type: $point_type"
            return 1
            ;;
    esac
}

# Create recovery snapshot
create_recovery_snapshot() {
    local session_id="$1"
    local session_dir="$SESSIONS_DIR/$session_id"

    log_info "Creating recovery snapshot: $session_id"

    local snapshot_dir="$RECOVERY_DIR/snapshots/$session_id/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$snapshot_dir"

    # Create snapshot
    cp -r "$session_dir/config" "$snapshot_dir/"
    cp -r "$session_dir/state" "$snapshot_dir/"
    cp -r "$session_dir/logs" "$snapshot_dir/" 2>/dev/null || true

    # Create snapshot manifest
    cat > "$snapshot_dir/manifest.json" << EOF
{
  "session_id": "$session_id",
  "created_at": "$(date -Iseconds)",
  "snapshot_type": "manual",
  "files_copied": $(find "$snapshot_dir" -type f | wc -l),
  "total_size": $(du -sb "$snapshot_dir" | cut -f1)
}
EOF

    log_success "Recovery snapshot created: $snapshot_dir"
    echo "$snapshot_dir"
}

# Perform recovery
perform_recovery() {
    local point_type="$1"
    local point_id="$2"
    local session_dir="$3"

    log_info "Starting recovery: $point_type - $point_id"

    # Update recovery status
    local status_file="$RECOVERY_DIR/recovery-status.json"
    local attempt_count=$(jq '.recovery_attempts + 1' "$status_file")

    jq \
        ".recovery_attempts = $attempt_count |
         .last_recovery = \"$(date -Iseconds)\" |
         .active_sessions = [\"$point_id\"]" \
        "$status_file" > "$status_file.tmp" && \
    mv "$status_file.tmp" "$status_file"

    # Validate recovery point
    if ! validate_recovery_point "$point_type" "$point_id" "$session_dir"; then
        log_error "Recovery point validation failed"

        # Update failure count
        local fail_count=$(jq '.failed_recoveries + 1' "$status_file")
        jq ".failed_recoveries = $fail_count" "$status_file" > "$status_file.tmp" && \
        mv "$status_file.tmp" "$status_file"

        return 1
    fi

    # Load state based on type
    local state_data
    if [[ "$point_type" == "session" ]]; then
        state_data=$(load_session_state "$point_id")
    else
        state_data=$(load_checkpoint_state "$point_id")
    fi

    # Restore context
    if [[ "$point_type" == "session" ]]; then
        restore_session_context "$point_id" "$session_dir"
    fi

    # Log recovery
    echo "$(date -Iseconds) - RECOVERY - Started recovery for $point_type - $point_id" >> "$LOG_FILE"

    log_success "Recovery initiated: $point_type - $point_id"

    # Update success count
    local success_count=$(jq '.successful_recoveries + 1' "$status_file")
    jq ".successful_recoveries = $success_count" "$status_file" > "$status_file.tmp" && \
    mv "$status_file.tmp" "$status_file"

    echo "$state_data"
}

# Resume migration workflow
resume_migration() {
    local session_id="$1"
    local session_dir="$SESSIONS_DIR/$session_id"

    log_info "Resuming migration workflow: $session_id"

    # Load current state
    local state_file="$session_dir/state/session-state.json"
    local current_step=$(jq -r '.current_step' "$state_file")
    local progress=$(jq -r '.progress' "$state_file")

    # Determine next action
    case "$current_step" in
        "analysis")
            log_info "Resuming from analysis phase"
            return 1
            ;;
        "planning")
            log_info "Resuming from planning phase"
            return 2
            ;;
        "execution")
            log_info "Resuming from execution phase"
            return 3
            ;;
        "validation")
            log_info "Resuming from validation phase"
            return 4
            ;;
        *)
            log_warning "Unknown step: $current_step, starting from beginning"
            return 0
            ;;
    esac
}

# Cleanup old recovery data
cleanup_recovery_data() {
    local max_age_days="${1:-30}"

    log_info "Cleaning up recovery data older than $max_age_days days"

    # Clean snapshots
    find "$RECOVERY_DIR/snapshots" -type d -mtime +"$max_age_days" -exec rm -rf {} +

    # Clean recovery log
    if [[ -f "$LOG_FILE" ]]; then
        local log_size=$(stat -c%s "$LOG_FILE")
        if [[ $log_size -gt 10485760 ]]; then  # 10MB
            tail -n 1000 "$LOG_FILE" > "${LOG_FILE}.tmp" && \
            mv "${LOG_FILE}.tmp" "$LOG_FILE"
        fi
    fi

    log_success "Recovery data cleanup completed"
}

# Export recovery data
export_recovery_data() {
    local session_id="$1"
    local export_file="$2"

    log_info "Exporting recovery data: $session_id to $export_file"

    # Create archive
    tar -czf "$export_file" \
        -C "$RECOVERY_DIR" "snapshots/$session_id" 2>/dev/null || true \
        -C "$RECOVERY_DIR" "recovery-status.json" \
        -C "$RECOVERY_DIR" "recovery.log"

    log_success "Recovery data exported: $export_file"
}

# Main execution
main() {
    case "${1:-}" in
        "init")
            init_recovery_system
            ;;
        "detect")
            detect_recovery_points
            ;;
        "list")
            list_recovery_points "$(detect_recovery_points)"
            ;;
        "load")
            if [[ "${4:-}" == "session" ]]; then
                load_session_state "$2"
            elif [[ "${4:-}" == "checkpoint" ]]; then
                load_checkpoint_state "$2"
            else
                log_error "Unknown type: $4"
                exit 1
            fi
            ;;
        "restore")
            perform_recovery "$2" "$3" "$4"
            ;;
        "snapshot")
            create_recovery_snapshot "$2"
            ;;
        "resume")
            resume_migration "$2"
            ;;
        "cleanup")
            cleanup_recovery_data "$2"
            ;;
        "export")
            export_recovery_data "$2" "$3"
            ;;
        "status")
            cat "$RECOVERY_DIR/recovery-status.json"
            ;;
        "help")
            echo "State Restorer Usage:"
            echo "  $0 init                              - Initialize recovery system"
            echo "  $0 detect                            - Detect available recovery points"
            echo "  $0 list                              - List all recovery points"
            echo "  $0 load <id> <type>                 - Load state (type: session/checkpoint)"
            echo "  $0 restore <type> <id> <session_dir> - Perform recovery"
            echo "  $0 snapshot <session_id>             - Create recovery snapshot"
            echo "  $0 resume <session_id>               - Resume migration workflow"
            echo "  $0 cleanup [days]                    - Cleanup old recovery data"
            echo "  $0 export <session_id> <file>       - Export recovery data"
            echo "  $0 status                           - Show recovery system status"
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