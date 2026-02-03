#!/bin/bash

# Legacy Migration Incremental Processor
# 支持增量操作，只处理变更的文件和代码

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${STATE_DIR:-$HOME/.legacy-migration/state}"
CACHE_DIR="${CACHE_DIR:-$HOME/.legacy-migration/cache}"
FILE_TRACKER="$STATE_DIR/file-tracker.json"
CHANGE_DETECTOR="$STATE_DIR/change-detector.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Initialize incremental processing
init_incremental() {
    log_info "Initializing incremental processing..."

    mkdir -p "$STATE_DIR"
    mkdir -p "$CACHE_DIR"

    # Create file tracker if not exists
    if [[ ! -f "$FILE_TRACKER" ]]; then
        cat > "$FILE_TRACKER" << 'EOF'
{
  "files": {},
  "last_scan": null,
  "total_files": 0,
  "modified_files": 0,
  "new_files": 0,
  "deleted_files": 0
}
EOF
    fi

    # Create change detector if not exists
    if [[ ! -f "$CHANGE_DETECTOR" ]]; then
        cat > "$CHANGE_DETECTOR" << 'EOF'
{
  "project_hash": "",
  "last_snapshot": "",
  "change_threshold": 0.1,
  "tracked_patterns": [
    "*.java",
    "*.js",
    "*.ts",
    "*.py",
    "*.go",
    "*.properties",
    "*.xml",
    "*.yml",
    "*.yaml",
    "*.json"
  ]
}
EOF
    fi

    log_success "Incremental processing initialized"
}

# Generate project hash
generate_project_hash() {
    local project_path="$1"

    if [[ ! -d "$project_path" ]]; then
        log_error "Project path not found: $project_path"
        return 1
    fi

    # Generate hash based on project structure and file contents
    find "$project_path" -type f \( -name "*.java" -o -name "*.js" -o -name "*.py" \) | \
        sort | xargs sha256sum | sha256sum | cut -d' ' -f1
}

# Detect changes
detect_changes() {
    local project_path="$1"
    local session_id="$2"

    log_info "Detecting changes in project: $project_path"

    # Generate current project hash
    local current_hash=$(generate_project_hash "$project_path")

    # Load previous state
    local previous_hash=$(jq -r '.project_hash' "$CHANGE_DETECTOR" 2>/dev/null || echo "")

    if [[ "$previous_hash" == "" ]]; then
        # First scan
        log_info "Initial project scan..."
        first_scan "$project_path" "$session_id"
        update_project_hash "$current_hash"
        return 0
    fi

    if [[ "$current_hash" == "$previous_hash" ]]; then
        log_info "No changes detected"
        echo "no_changes"
        return 0
    fi

    # Detect changes
    log_info "Changes detected, analyzing differences..."
    analyze_differences "$project_path" "$session_id"

    # Update project hash
    update_project_hash "$current_hash"

    echo "changes_detected"
}

# First scan
first_scan() {
    local project_path="$1"
    local session_id="$2"

    log_info "Performing first scan of project: $project_path"

    # Track all files
    local temp_file=$(mktemp)
    find "$project_path" -type f \( \
        -name "*.java" -o \
        -name "*.js" -o \
        -name "*.ts" -o \
        -name "*.py" -o \
        -name "*.go" -o \
        -name "*.properties" -o \
        -name "*.xml" -o \
        -name "*.yml" -o \
        -name "*.yaml" -o \
        -name "*.json" \
    \) | while read -r file; do
        local rel_path=$(realpath --relative-to="$project_path" "$file")
        local file_hash=$(sha256sum "$file" | cut -d' ' -f1)
        local file_size=$(stat -c%s "$file")
        local mod_time=$(stat -c%Y "$file")

        cat >> "$temp_file" << EOF
{
  "path": "$rel_path",
  "absolute_path": "$file",
  "hash": "$file_hash",
  "size": $file_size,
  "modified": $mod_time,
  "status": "new",
  "session_id": "$session_id",
  "last_processed": null,
  "processing_count": 0
}
EOF
    done

    # Update file tracker
    jq --arg session_id "$session_id" \
       --slurpfile files "$temp_file" '
        .last_scan = now |
        .total_files += ($files | length) |
        .files += ($files | map({(.path): .})) |
        .modified_files = 0 |
        .new_files = $files | length |
        .deleted_files = 0
        ' "$FILE_TRACKER" > "$FILE_TRACKER.tmp" && \
    mv "$FILE_TRACKER.tmp" "$FILE_TRACKER"

    log_success "First scan completed: $(jq -r '.total_files' "$FILE_TRACKER") files tracked"
}

# Analyze differences
analyze_differences() {
    local project_path="$1"
    local session_id="$2"

    log_info "Analyzing project differences..."

    # Load current files
    local current_files=$(mktemp)
    find "$project_path" -type f \( \
        -name "*.java" -o \
        -name "*.js" -o \
        -name "*.ts" -o \
        -name "*.py" -o \
        -name "*.go" -o \
        -name "*.properties" -o \
        -name "*.xml" -o \
        -name "*.yml" -o \
        -name "*.yaml" -o \
        -name "*.json" \
    \) | while read -r file; do
        local rel_path=$(realpath --relative-to="$project_path" "$file")
        local file_hash=$(sha256sum "$file" | cut -d' ' -f1)
        local file_size=$(stat -c%s "$file")
        local mod_time=$(stat -c%Y "$file")

        echo "$rel_path|$file_hash|$file_size|$mod_time"
    done > "$current_files"

    # Load previous files
    local previous_files=$(mktemp)
    jq -r '.files | to_entries | map(.key + "|" + .value.hash + "|" + (.value | tostring)) | .[]' "$FILE_TRACKER" > "$previous_files"

    # Compare files
    local changes=0
    local new_files=0
    local modified_files=0
    local deleted_files=0

    # Check for new and modified files
    while IFS='|' read -r rel_path hash size mod_time; do
        if ! grep -q "^$rel_path|" "$previous_files"; then
            # New file
            new_files=$((new_files + 1))
            mark_file_as "$rel_path" "new" "$session_id"
            changes=$((changes + 1))
        else
            # Check if modified
            local prev_hash=$(grep "^$rel_path|" "$previous_files" | cut -d'|' -f2)
            if [[ "$hash" != "$prev_hash" ]]; then
                modified_files=$((modified_files + 1))
                mark_file_as "$rel_path" "modified" "$session_id"
                changes=$((changes + 1))
            fi
        fi
    done < "$current_files"

    # Check for deleted files
    while IFS='|' read -r rel_path _; do
        if ! grep -q "^$rel_path|" "$current_files"; then
            deleted_files=$((deleted_files + 1))
            mark_file_as "$rel_path" "deleted" "$session_id"
            changes=$((changes + 1))
        fi
    done < "$previous_files"

    # Update statistics
    jq \
        ".last_scan = now |
         .modified_files = $modified_files |
         .new_files = $new_files |
         .deleted_files = $deleted_files" \
        "$FILE_TRACKER" > "$FILE_TRACKER.tmp" && \
    mv "$FILE_TRACKER.tmp" "$FILE_TRACKER"

    log_success "Change analysis completed:"
    log_info "  New files: $new_files"
    log_info "  Modified files: $modified_files"
    log_info "  Deleted files: $deleted_files"
    log_info "  Total changes: $changes"
}

# Mark file status
mark_file_as() {
    local file_path="$1"
    local status="$2"
    local session_id="$3"

    jq \
        ".files[\"$file_path\"].status = \"$status\" |
         .files[\"$file_path\"].session_id = \"$session_id\" |
         .files[\"$file_path\"].last_scan = now" \
        "$FILE_TRACKER" > "$FILE_TRACKER.tmp" && \
    mv "$FILE_TRACKER.tmp" "$FILE_TRACKER"
}

# Update project hash
update_project_hash() {
    local hash="$1"

    jq ".project_hash = \"$hash\"" "$CHANGE_DETECTOR" > "$CHANGE_DETECTOR.tmp" && \
    mv "$CHANGE_DETECTOR.tmp" "$CHANGE_DETECTOR"
}

# Get files to process
get_files_to_process() {
    local status="$1"
    local limit="${2:-0}"

    jq -r "
        .files |
        to_entries |
        map(select(.value.status == \"$status\" and .value.session_id == \"$2\")) |
        if $limit > 0 then .[:$limit] else . end |
        map(.key)
    " "$FILE_TRACKER"
}

# Mark file as processed
mark_file_as_processed() {
    local file_path="$1"
    local session_id="$2"
    local processing_time="$3"
    local success="$4"
    local error_message="$5"

    local current_count=$(jq ".files[\"$file_path\"].processing_count // 0" "$FILE_TRACKER")
    local new_count=$((current_count + 1))

    jq \
        ".files[\"$file_path\"].status = \"processed\" |
         .files[\"$file_path\"].session_id = \"$session_id\" |
         .files[\"$file_path\"].last_processed = now |
         .files[\"$file_path\"].processing_time = \"$processing_time\" |
         .files[\"$file_path\"].processing_count = $new_count |
         .files[\"$file_path\"].success = $success |
         .files[\"$file_path\"].error_message = \"$error_message\"" \
        "$FILE_TRACKER" > "$FILE_TRACKER.tmp" && \
    mv "$FILE_TRACKER.tmp" "$FILE_TRACKER"
}

# Create incremental cache
create_incremental_cache() {
    local cache_key="$1"
    local data="$2"

    local cache_file="$CACHE_DIR/$cache_key.json"
    echo "$data" > "$cache_file"

    # Clean old cache files
    find "$CACHE_DIR" -name "*.json" -mtime +7 -delete

    log_info "Cache created: $cache_file"
}

# Get from cache
get_from_cache() {
    local cache_key="$1"

    local cache_file="$CACHE_DIR/$cache_key.json"
    if [[ -f "$cache_file" ]]; then
        # Check if cache is still valid (1 hour)
        local cache_age=$(($(date +%s) - $(stat -c%Y "$cache_file")))
        if [[ $cache_age -lt 3600 ]]; then
            cat "$cache_file"
            return 0
        fi
    fi

    echo "not_found"
    return 1
}

# Get processing statistics
get_statistics() {
    local session_id="$1"

    local total_files=$(jq '.files | length' "$FILE_TRACKER")
    local processed_files=$(jq "
        .files |
        to_entries |
        map(select(.value.session_id == \"$session_id\" and (.value.status == \"processed\" or .value.status == \"ignored\"))) |
        length
    " "$FILE_TRACKER")
    local pending_files=$(jq "
        .files |
        to_entries |
        map(select(.value.session_id == \"$session_id\" and (.value.status == \"new\" or .value.status == \"modified\"))) |
        length
    " "$FILE_TRACKER")
    local failed_files=$(jq "
        .files |
        to_entries |
        map(select(.value.session_id == \"$session_id\" and .value.success == false)) |
        length
    " "$FILE_TRACKER")

    local progress=$((processed_files * 100 / total_files)) 2>/dev/null || 0

    cat << EOF
{
  "total_files": $total_files,
  "processed_files": $processed_files,
  "pending_files": $pending_files,
  "failed_files": $failed_files,
  "progress_percent": $progress
}
EOF
}

# Clear session data
clear_session_data() {
    local session_id="$1"

    log_info "Clearing session data: $session_id"

    # Remove session files from tracker
    jq '
        del(.files | .[] | select(.value.session_id == "'"$session_id"'"))
    ' "$FILE_TRACKER" > "$FILE_TRACKER.tmp" && \
    mv "$FILE_TRACKER.tmp" "$FILE_TRACKER"

    # Clear related cache
    find "$CACHE_DIR" -name "*$session_id*" -delete

    log_success "Session data cleared: $session_id"
}

# Export incremental data
export_incremental_data() {
    local session_id="$1"
    local export_file="$2"

    log_info "Exporting incremental data: $session_id to $export_file"

    # Create archive
    tar -czf "$export_file" \
        -C "$STATE_DIR" "file-tracker.json" \
        -C "$STATE_DIR" "change-detector.json"

    log_success "Incremental data exported: $export_file"
}

# Import incremental data
import_incremental_data() {
    local import_file="$1"

    log_info "Importing incremental data from: $import_file"

    # Extract archive
    local temp_dir=$(mktemp -d)
    tar -xzf "$import_file" -C "$temp_dir"

    # Import files
    cp "$temp_dir/file-tracker.json" "$STATE_DIR/"
    cp "$temp_dir/change-detector.json" "$STATE_DIR/"

    # Cleanup
    rm -rf "$temp_dir"

    log_success "Incremental data imported"
}

# Main execution
main() {
    case "${1:-}" in
        "init")
            init_incremental
            ;;
        "detect")
            detect_changes "$2" "$3"
            ;;
        "files")
            get_files_to_process "$2" "$3"
            ;;
        "mark-processed")
            mark_file_as_processed "$2" "$3" "$4" "$5" "$6"
            ;;
        "cache")
            if [[ "${7:-}" == "get" ]]; then
                get_from_cache "$2"
            else
                create_incremental_cache "$2" "$3"
            fi
            ;;
        "stats")
            get_statistics "$2"
            ;;
        "clear")
            clear_session_data "$2"
            ;;
        "export")
            export_incremental_data "$2" "$3"
            ;;
        "import")
            import_incremental_data "$2"
            ;;
        "help")
            echo "Incremental Processor Usage:"
            echo "  $0 init                          - Initialize incremental processing"
            echo "  $0 detect <project_path> <session_id> - Detect changes"
            echo "  $0 files <status> [limit] <session_id> - Get files to process"
            echo "  $0 mark-processed <file> <session> <time> <success> [error] - Mark file as processed"
            echo "  $0 cache <key> [data]            - Manage cache"
            echo "  $0 stats <session_id>            - Get processing statistics"
            echo "  $0 clear <session_id>            - Clear session data"
            echo "  $0 export <session_id> <file>    - Export incremental data"
            echo "  $0 import <file>                 - Import incremental data"
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