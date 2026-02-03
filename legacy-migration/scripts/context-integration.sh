#!/bin/bash

# Legacy Migration Context Integration
# 集成上下文管理到主迁移工作流

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${STATE_DIR:-$HOME/.legacy-migration/state}"
SESSIONS_DIR="${SESSIONS_DIR:-$HOME/.legacy-migration/sessions}"
LOGS_DIR="${LOGS_DIR:-$HOME/.legacy-migration/logs}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

# Context Management Integration
# =====================================

# Initialize context management for a session
init_context_management() {
    local session_id="$1"
    local project_path="$2"

    log_info "Initializing context management for session: $session_id"

    # Create context directory
    local context_dir="$STATE_DIR/context/$session_id"
    mkdir -p "$context_dir"

    # Create context tracking file
    local context_file="$context_dir/context-tracker.json"
    cat > "$context_file" << EOF
{
  "session_id": "$session_id",
  "project_path": "$project_path",
  "initialized_at": "$(date -Iseconds)",
  "context_events": [],
  "compression_history": [],
  "current_level": "normal",
  "total_tokens": 0
}
EOF

    # Initialize context manager if available
    if [[ -f "$SCRIPT_DIR/context-manager.sh" ]]; then
        # Set context-specific thresholds
        export CONTEXT_THRESHOLD="170000"
        export CONTEXT_HARD_LIMIT="185000"

        log_success "Context management initialized for session: $session_id"
    else
        log_warning "Context manager not found, using basic monitoring"
    fi
}

# Monitor context throughout migration
monitor_migration_context() {
    local session_id="$1"
    local step_name="$2"
    local step_start_time="$3"

    local context_dir="$STATE_DIR/context/$session_id"
    local context_file="$context_dir/context-tracker.json"

    if [[ ! -f "$context_file" ]]; then
        log_warning "Context tracking file not found: $context_file"
        return 1
    fi

    # Get current context status
    local current_tokens=0
    if command -v context-manager.sh >/dev/null 2>&1; then
        current_tokens=$("$SCRIPT_DIR/context-manager.sh" monitor "0" 2>/dev/null || echo "0")
    fi

    # Record context event
    local event_time=$(date -Iseconds)
    local step_duration=$(( $(date +%s) - $(date -d "$step_start_time" +%s) ))

    jq --arg step "$step_name" --arg tokens "$current_tokens" --arg time "$event_time" --arg duration "$step_duration" \
       '.context_events += [{
         "step": $step,
         "tokens_at_start": ($tokens | tonumber),
         "duration_seconds": ($duration | tonumber),
         "timestamp": $time
       }]' "$context_file" > "${context_file}.tmp" && mv "${context_file}.tmp" "$context_file"

    # Check if we need context optimization
    if [[ "$current_tokens" =~ ^[0-9]+$ ]] && (( current_tokens > 160000 )); then
        log_warning "High context usage detected: $current_tokens tokens"

        # Trigger context optimization
        if [[ -f "$SCRIPT_DIR/context-manager.sh" ]]; then
            log_info "Triggering context optimization..."
            "$SCRIPT_DIR/context-manager.sh" compress 2>/dev/null || log_error "Context optimization failed"

            # Update context level
            jq --arg level "optimized" '.current_level = $level' "$context_file" > "${context_file}.tmp" && mv "${context_file}.tmp" "$context_file"
        fi
    fi
}

# Generate context-aware migration plan
generate_context_aware_plan() {
    local session_id="$1"

    local context_dir="$STATE_DIR/context/$session_id"
    local context_file="$context_dir/context-tracker.json"
    local session_dir="$SESSIONS_DIR/$session_id"

    if [[ ! -f "$context_file" ]]; then
        log_warning "Context tracking file not found"
        return 1
    fi

    # Get current context status
    local current_tokens=$(jq -r '.total_tokens // 0' "$context_file")

    # Generate context-aware plan
    local plan_file="$session_dir/context-aware-plan.json"

    cat > "$plan_file" << EOF
{
  "session_id": "$session_id",
  "generated_at": "$(date -Iseconds)",
  "context_status": "normal",
  "optimization_recommendations": [],
  "step_adjustments": []
}
EOF

    # Analyze context usage and provide recommendations
    if (( current_tokens > 140000 )); then
        jq --arg rec "Enable incremental processing to reduce context usage" \
           '.optimization_recommendations += [$rec]' "$plan_file" > "${plan_file}.tmp" && mv "${plan_file}.tmp" "$plan_file"

        jq --arg adjustment "Use compressed analysis for subsequent steps" \
           '.step_adjustments += [$adjustment]' "$plan_file" > "${plan_file}.tmp" && mv "${plan_file}.tmp" "$plan_file"

        jq '.context_status = "warning"' "$plan_file" > "${plan_file}.tmp" && mv "${plan_file}.tmp" "$plan_file"
    fi

    if (( current_tokens > 170000 )); then
        jq --arg rec "Enable emergency compression and minimal processing" \
           '.optimization_recommendations += [$rec]' "$plan_file" > "${plan_file}.tmp" && mv "${plan_file}.tmp" "$plan_file"

        jq '.context_status = "critical"' "$plan_file" > "${plan_file}.tmp" && mv "${plan_file}.tmp" "$plan_file"
    fi

    log_info "Context-aware plan generated for session: $session_id"
}

# Cleanup context data
cleanup_context_data() {
    local session_id="$1"
    local keep_days="${2:-7}"

    local context_dir="$STATE_DIR/context/$session_id"

    if [[ -d "$context_dir" ]]; then
        # Find old compression files
        find "$context_dir" -name "*.compressed" -mtime +"$keep_days" -delete

        # Clean up temporary files
        find "$context_dir" -name "*.tmp" -delete

        # Clean up old event logs
        local context_file="$context_dir/context-tracker.json"
        if [[ -f "$context_file" ]]; then
            # Keep only recent events (last 50)
            jq 'if .context_events then
                  .context_events = (.context_events | length > 50 | .[-50:])
                else
                  .
                end' "$context_file" > "${context_file}.tmp" && mv "${context_file}.tmp" "$context_file"
        fi

        log_info "Context data cleaned up for session: $session_id"
    fi
}

# Get context summary
get_context_summary() {
    local session_id="$1"

    local context_dir="$STATE_DIR/context/$session_id"
    local context_file="$context_dir/context-tracker.json"

    if [[ ! -f "$context_file" ]]; then
        echo "No context data available"
        return 1
    fi

    echo "Context Summary for Session: $session_id"
    echo "====================================="

    # Basic stats
    local total_events=$(jq '.context_events | length // 0' "$context_file")
    local compression_count=$(jq '.compression_history | length // 0' "$context_file")
    local current_level=$(jq -r '.current_level // "unknown"' "$context_file")

    echo "Total Context Events: $total_events"
    echo "Compression Events: $compression_count"
    echo "Current Level: $current_level"

    # Recent events
    if (( total_events > 0 )); then
        echo ""
        echo "Recent Context Events:"
        jq -r '.context_events[-5:][] | "  - \(.step): \(.tokens_at_start) tokens (\(.duration_seconds)s)"' "$context_file"
    fi

    echo ""
}

# Main execution
main() {
    local command="${1:-}"

    case "$command" in
        "init")
            init_context_management "$2" "$3"
            ;;
        "monitor")
            monitor_migration_context "$2" "$3" "$4"
            ;;
        "plan")
            generate_context_aware_plan "$2"
            ;;
        "cleanup")
            cleanup_context_data "$2" "$3"
            ;;
        "summary")
            get_context_summary "$2"
            ;;
        "help")
            echo "Context Integration Usage:"
            echo "  $0 init <session_id> <project_path>     - Initialize context management"
            echo "  $0 monitor <session_id> <step> <time>  - Monitor context during migration"
            echo "  $0 plan <session_id>                   - Generate context-aware plan"
            echo "  $0 cleanup <session_id> [days]         - Clean up context data"
            echo "  $0 summary <session_id>                - Get context summary"
            echo "  $0 help                                - Show this help"
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use '$0 help' for usage."
            exit 1
            ;;
    esac
}

# Export functions for external use
export -f init_context_management
export -f monitor_migration_context
export -f generate_context_aware_plan
export -f cleanup_context_data
export -f get_context_summary

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi