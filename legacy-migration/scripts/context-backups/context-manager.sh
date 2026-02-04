#!/bin/bash

# Legacy Migration Context Manager
# 优化上下文使用，防止超出限制

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${STATE_DIR:-$HOME/.legacy-migration/state}"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../" && pwd)"
CONFIG_FILE="$PROJECT_ROOT/context-config.json"
COMPRESSION_DIR="$STATE_DIR/compression"
TEMP_COMPRESSION="$TEMP_DIR/compression_$$"

# Load configuration from unified config file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        CONTEXT_THRESHOLD=$(jq -r '.context_thresholds.preventive' "$CONFIG_FILE")
        CONTEXT_HARD_LIMIT=$(jq -r '.context_thresholds.hard_limit' "$CONFIG_FILE")
    else
        CONTEXT_THRESHOLD="${CONTEXT_THRESHOLD:-150000}"  # 150K tokens - 预警线
        CONTEXT_HARD_LIMIT="${CONTEXT_HARD_LIMIT:-200000}"  # 200K tokens - 硬限制
    fi
}

# Initialize config
load_config

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

log_debug() {
    if [[ "${VERBOSE:-false}" == true ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

# Context monitoring
monitor_context_usage() {
    local current_tokens="${1:-0}"

    log_debug "Current context: $current_tokens tokens"

    if (( current_tokens > CONTEXT_HARD_LIMIT )); then
        log_error "Context exceeded hard limit ($current_tokens > $CONTEXT_HARD_LIMIT)"
        trigger_emergency_compression "$current_tokens"
        return 2
    elif (( current_tokens > CONTEXT_THRESHOLD )); then
        log_warning "Context approaching limit ($current_tokens > $CONTEXT_THRESHOLD)"
        trigger_preventive_compression "$current_tokens"
        return 1
    fi

    return 0
}

# Trigger preventive compression
trigger_preventive_compression() {
    local current_tokens="${1:-0}"

    log_info "Triggering preventive compression (Level 1)..."

    # Create compression directory
    mkdir -p "$TEMP_COMPRESSION"

    # Compress code context (30-50% compression)
    compress_code_context "$TEMP_COMPRESSION"

    # Update context markers
    update_context_markers "$TEMP_COMPRESSION"

    # Log compression event
    log_compression_event "preventive" "$current_tokens"

    log_success "Preventive compression completed"
}

# Trigger emergency compression
trigger_emergency_compression() {
    local current_tokens="${1:-0}"

    log_error "Triggering emergency compression (Level 3)..."

    # Create compression directory
    mkdir -p "$TEMP_COMPRESSION"

    # Maximum compression (70-90%)
    compress_code_context_emergency "$TEMP_COMPRESSION"

    # Update context markers
    update_context_markers "$TEMP_COMPRESSION"

    # Log compression event
    log_compression_event "emergency" "$current_tokens"

    log_success "Emergency compression completed"
}

# Compress code context
compress_code_context() {
    local output_dir="$1"

    # Get project files
    local project_path=$(get_current_project_path)

    if [[ -z "$project_path" ]]; then
        log_warning "No project path found, skipping code compression"
        return
    fi

    # Create compressed file structure
    mkdir -p "$output_dir/structure"
    mkdir -p "$output_dir/signatures"

    # Extract function signatures and class definitions
    find "$project_path" -name "*.java" -o -name "*.py" -o -name "*.js" -o -name "*.ts" | head -100 | while read -r file; do
        # Extract signatures only
        extract_function_signatures "$file" "$output_dir/signatures/$(basename "$file").sig"

        # Extract structure only
        extract_file_structure "$file" "$output_dir/structure/$(basename "$file").struct"
    done

    # Create compressed manifest
    cat > "$output_dir/compression-manifest.json" << EOF
{
  "compression_level": "1",
  "files_processed": $(find "$output_dir/signatures" -type f | wc -l),
  "original_size": 0,
  "compressed_size": 0,
  "compression_ratio": 0.0
}
EOF
}

# Emergency compression
compress_code_context_emergency() {
    local output_dir="$1"

    # Get only essential files
    local project_path=$(get_current_project_path)

    if [[ -z "$project_path" ]]; then
        return
    fi

    # Create minimal structure
    mkdir -p "$output_dir/minimal"

    # Copy only configuration files
    find "$project_path" -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.xml" | head -50 | while read -r file; do
        cp "$file" "$output_dir/minimal/"
    done

    # Extract only critical information
    cat > "$output_dir/critical-info.json" << EOF
{
  "project_config": {},
  "dependencies": [],
  "entry_points": [],
  "compression_level": "3",
  "files_kept": $(find "$output_dir/minimal" -type f | wc -l)
}
EOF
}

# Extract function signatures
extract_function_signatures() {
    local input_file="$1"
    local output_file="$2"

    local ext="${input_file##*.}"

    case "$ext" in
        "java")
            # Extract method signatures
            grep -E "^\s*(public|private|protected)?\s*(static)?\s*[a-zA-Z_][a-zA-Z0-9_]*\s+[a-zA-Z_][a-zA-Z0-9_]*\s*([^)]*)\s*\{" "$input_file" > "$output_file"
            ;;
        "py")
            # Extract function definitions
            grep -E "^\s*def\s+[a-zA-Z_][a-zA-Z0-9_]*\s*([^:]*)" "$input_file" > "$output_file"
            ;;
        "js"|"ts")
            # Extract function declarations
            grep -E "^\s*(function\s+[a-zA-Z_][a-zA-Z0-9_]*|const\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=.*=>)" "$input_file" > "$output_file"
            ;;
    esac
}

# Extract file structure
extract_file_structure() {
    local input_file="$1"
    local output_file="$2"

    # Extract class/interface definitions and imports
    local ext="${input_file##*.}"

    case "$ext" in
        "java")
            # Extract imports and class definitions
            grep -E "^(import|package|class|interface|enum)" "$input_file" > "$output_file"
            ;;
        "py")
            # Extract imports and class definitions
            grep -E "^(import|from|class|def|@)" "$input_file" > "$output_file"
            ;;
        "js"|"ts")
            # Extract imports and exports
            grep -E "^(import|export|class|function|const|let|var)" "$input_file" > "$output_file"
            ;;
    esac
}

# Update context markers
update_context_markers() {
    local compression_dir="$1"

    # Create context marker
    cat > "$compression_dir/context-marker.json" << EOF
{
  "compressed_at": "$(date -Iseconds)",
  "compression_level": "$(jq -r '.compression_level' "$compression_dir/compression-manifest.json")",
  "project_session": "$(get_current_session_id)",
  "temp_path": "$TEMP_COMPRESSION"
}
EOF
}

# Get current project path
get_current_project_path() {
    # Try to get from session
    if [[ -f "$STATE_DIR/current-session.json" ]]; then
        cat "$STATE_DIR/current-session.json" | jq -r '.project_path // empty'
    fi
}

# Get current session ID
get_current_session_id() {
    if [[ -f "$STATE_DIR/current-session.json" ]]; then
        cat "$STATE_DIR/current-session.json" | jq -r '.session_id // empty'
    fi
}

# Log compression event
log_compression_event() {
    local level="$1"
    local tokens="$2"

    mkdir -p "$STATE_DIR/compression-history"

    local history_file="$STATE_DIR/compression-history/$(date +%Y%m%d).json"

    if [[ ! -f "$history_file" ]]; then
        cat > "$history_file" << 'EOF'
{
  "events": []
}
EOF
    fi

    # Add compression event
    jq --arg level "$level" --arg tokens "$tokens" --arg timestamp "$(date -Iseconds)" \
       '.events += [{
         "type": "compression",
         "level": $level,
         "trigger_tokens": ($tokens | tonumber),
         "timestamp": $timestamp
       }]' "$history_file" > "${history_file}.tmp" && mv "${history_file}.tmp" "$history_file"
}

# Clean up old compression data
cleanup_compression_data() {
    local days="${1:-7}"

    log_info "Cleaning up compression data older than $days days"

    # Find and remove old compression directories
    find "$TEMP_DIR" -name "compression_*" -type d -mtime +"$days" -exec rm -rf {} \;

    # Clean up history
    find "$STATE_DIR/compression-history" -name "*.json" -mtime +"$days" -delete

    log_success "Compression data cleaned up"
}

# Get context statistics
get_context_stats() {
    echo "Context Management Statistics:"
    echo "================================"
    echo "Threshold: $CONTEXT_THRESHOLD tokens"
    echo "Hard Limit: $CONTEXT_HARD_LIMIT tokens"
    echo ""

    # Show compression history
    if [[ -d "$STATE_DIR/compression-history" ]]; then
        echo "Recent Compression Events:"
        find "$STATE_DIR/compression-history" -name "*.json" -mtime -7 | while read -r file; do
            echo "$(basename "$file"): $(jq '.events | length' "$file") events"
        done
    fi
}

# Main execution
main() {
    local command="${1:-}"

    case "$command" in
        "monitor")
            monitor_context_usage "$2"
            ;;
        "compress")
            trigger_preventive_compression
            ;;
        "emergency")
            trigger_emergency_compression
            ;;
        "cleanup")
            cleanup_compression_data "$2"
            ;;
        "stats")
            get_context_stats
            ;;
        "help")
            echo "Context Manager Usage:"
            echo "  $0 monitor <tokens>    - Monitor context usage"
            echo "  $0 compress            - Trigger preventive compression"
            echo "  $0 emergency            - Trigger emergency compression"
            echo "  $0 cleanup [days]      - Clean up old compression data"
            echo "  $0 stats               - Show context statistics"
            ;;
        *)
            echo "Unknown command: $command"
            exit 1
            ;;
    esac
}

# Export functions for external use
export -f monitor_context_usage
export -f trigger_preventive_compression
export -f trigger_emergency_compression

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi