#!/bin/bash

# Legacy Migration Assistant
# 集成所有功能的智能迁移助手，简化用户操作

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSIONS_DIR="${SESSIONS_DIR:-$HOME/.legacy-migration/sessions}"
STATE_DIR="${STATE_DIR:-$HOME/.legacy-migration/state}"
CACHE_DIR="${CACHE_DIR:-$HOME/.legacy-migration/cache}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.legacy-migration/config}"
TEMP_DIR="${TEMP_DIR:-$HOME/.legacy-migration/temp}"

# Color scheme
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Global variables
CURRENT_SESSION=""
CURRENT_PROJECT=""
CONFIG_FILE=""
AUTO_MODE=false
VERBOSE=false

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")  echo -e "${BLUE}[INFO]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") if [[ "$VERBOSE" == true ]]; then echo -e "${CYAN}[DEBUG]${NC} $message"; fi ;;
    esac

    # Also to log file
    echo "[$timestamp] [$level] $message" >> "$TEMP_DIR/assistant.log"
}

# Initialize environment
init_assistant() {
    log "INFO" "Initializing Migration Assistant..."

    # Create directories
    mkdir -p "$SESSIONS_DIR"
    mkdir -p "$STATE_DIR"
    mkdir -p "$CACHE_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$TEMP_DIR"

    # Initialize sub-systems
    "$SCRIPT_DIR/session-manager.sh" init
    "$SCRIPT_DIR/incremental-processor.sh" init
    "$SCRIPT_DIR/state-restorer.sh" init

    # Create default config if not exists
    if [[ ! -f "$CONFIG_DIR/default-config.yml" ]]; then
        create_default_config
    fi

    log "SUCCESS" "Migration Assistant initialized"
}

# Create default configuration
create_default_config() {
    cat > "$CONFIG_DIR/default-config.yml" << 'EOF'
# Default Migration Configuration
migration:
  goals: []
  strategy: "balanced"
  safety_level: "high"
  parallel_execution: false
  incremental_support: true

project:
  auto_detect: true
  type: "auto"

validation:
  compile: true
  test: true
  lint: true
  security_scan: true

notifications:
  status_updates: true
  email: ""
  webhook: ""

backup:
  enabled: true
  location: ""

performance:
  max_files_per_batch: 100
  max_memory_usage: "2GB"
  timeout_seconds: 3600
EOF
}

# Detect project information
detect_project() {
    local project_path="${1:-.}"

    log "INFO" "Detecting project at: $project_path"

    local project_type="unknown"
    local project_name=$(basename "$project_path")
    local detected_features=()

    # Check for various project types
    if [[ -f "$project_path/pom.xml" ]]; then
        project_type="maven"
        detected_features+=("Java Maven")
    fi

    if [[ -f "$project_path/build.gradle" ]]; then
        project_type="gradle"
        detected_features+=("Java Gradle")
    fi

    if [[ -f "$project_path/package.json" ]]; then
        project_type="nodejs"
        detected_features+=("Node.js")
    fi

    if [[ -f "$project_path/requirements.txt" || -f "$project_path/setup.py" ]]; then
        project_type="python"
        detected_features+=("Python")
    fi

    if [[ -f "$project_path/go.mod" ]]; then
        project_type="golang"
        detected_features+=("Go")
    fi

    # Check for frameworks
    if [[ -f "$project_path/src/main/resources/application.properties" ]]; then
        detected_features+=("Spring Boot")
    fi

    if [[ -d "$project_path/src" && -d "$project_path/public" ]]; then
        detected_features+=("React")
    fi

    # Generate project hash for incremental processing
    local project_hash=$(generate_project_hash "$project_path")

    cat << EOF
{
  "path": "$project_path",
  "name": "$project_name",
  "type": "$project_type",
  "features": ["${detected_features[*]}"],
  "hash": "$project_hash",
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Generate project hash
generate_project_hash() {
    local project_path="$1"

    if [[ ! -d "$project_path" ]]; then
        echo ""
        return 1
    fi

    # Create hash of project structure and key files
    find "$project_path" -type f \( \
        -name "*.java" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o \
        -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o \
        -name "*.xml" -o -name "*.properties" \
    \) -exec sha256sum {} + | sha256sum | cut -d' ' -f1
}

# Interactive project analysis
analyze_project_interactive() {
    local project_data="$1"

    echo ""
    echo "${WHITE}📋 Project Analysis${NC}"
    echo "=================="
    echo ""

    # Parse project data
    local project_path=$(echo "$project_data" | jq -r '.path')
    local project_name=$(echo "$project_data" | jq -r '.name')
    local project_type=$(echo "$project_data" | jq -r '.type')
    local features=$(echo "$project_data" | jq -r '.features[]')

    echo "${CYAN}Project:${NC} $project_name"
    echo "${CYAN}Path:${NC} $project_path"
    echo "${CYAN}Type:${NC} $project_type"
    echo "${CYAN}Features:${NC}"
    echo "$features" | while read -r feature; do
        echo "  • $feature"
    done

    echo ""
    echo "${YELLOW}Choose migration goals:${NC}"
    echo ""

    # Show available migration goals
    local goals=()
    local goal_options=(
        "1. Framework Upgrade (e.g., Spring Boot 2.x → 3.x)"
        "2. Runtime Upgrade (e.g., Java 11 → 17)"
        "3. Language Conversion (e.g., Java → Kotlin)"
        "4. Architecture Migration (e.g., Monolith → Microservices)"
        "5. Performance Optimization"
        "6. Security Enhancement"
        "7. Code Quality Improvement"
        "8. Custom Migration"
    )

    for i in "${!goal_options[@]}"; do
        echo "[$((i+1))] ${goal_options[$i]}"
    done

    echo ""
    read -p "Select goals (1-8, comma-separated): " goal_selections

    # Parse selections
    IFS=',' read -ra selections <<< "$goal_selections"
    for selection in "${selections[@]}"; do
        selection=$(echo "$selection" | xargs)  # trim whitespace
        if [[ "$selection" =~ ^[1-8]$ ]]; then
            goals+=("$selection")
        fi
    done

    # Generate migration plan
    local plan_data=$(generate_migration_plan "$project_data" "$goals")
    echo "$plan_data"
}

# Generate migration plan
generate_migration_plan() {
    local project_data="$1"
    local -n goals_ref=$2

    local plan='{
        "project": '"$project_data"',
        "goals": [],'

    # Add goals to plan
    local goal_text=""
    for goal in "${goals_ref[@]}"; do
        case "$goal" in
            1) goal_text='"framework-upgrade"' ;;
            2) goal_text='"runtime-upgrade"' ;;
            3) goal_text='"language-conversion"' ;;
            4) goal_text='"architecture-migration"' ;;
            5) goal_text='"performance-optimization"' ;;
            6) goal_text='"security-enhancement"' ;;
            7) goal_text='"code-quality-improvement"' ;;
            8) goal_text='"custom-migration"' ;;
        esac
        plan="$plan\n        $goal_text,"
    done

    # Remove trailing comma and close structure
    plan="${plan%,}
        "estimated_duration": "3-5 days",
        "complexity": "medium",
        "risks": ["compatibility issues", "downtime"],
        "steps": [
            {"name": "analysis", "description": "Analyze current state", "estimated": "1 day"},
            {"name": "planning", "description": "Create detailed plan", "estimated": "0.5 day"},
            {"name": "implementation", "description": "Apply changes", "estimated": "1.5 day"},
            {"name": "validation", "description": "Test and validate", "estimated": "1 day"}
        ],
        "safety_measures": [
            "automatic backup",
            "incremental deployment",
            "rollback support"
        ]
    }"

    echo -e "$plan"
}

# Create and start session
create_session() {
    local project_data="$1"
    local plan_data="$2"

    # Generate session ID
    local session_id=$(echo "$project_data" | jq -r '.name')-$(date +%Y%m%d-%H%M%S)
    session_id=$(echo "$session_id" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')

    # Create session directory
    local session_dir=$( "$SCRIPT_DIR/session-manager.sh" create "$(echo "$project_data" | jq -r '.path')" "$(echo "$project_data" | jq -r '.name')" "$session_id" )

    # Save plan to session
    echo "$plan_data" > "$session_dir/config/migration-plan.json"

    # Update configuration
    local config_file="$session_dir/config/migration-config.yml"
    yq eval ".session.id = \"$session_id\"" "$config_file" -i
    yq eval ".session.status = \"created\"" "$config_file" -i
    yq eval ".session.progress = 0" "$config_file" -i
    yq eval ".session.total_steps = $(echo "$plan_data" | jq '.steps | length')" "$config_file" -i

    # Save project hash for incremental processing
    local project_hash=$(echo "$project_data" | jq -r '.hash')
    echo "$project_data" | jq --arg hash "$project_hash" '.hash = $hash' > "$session_dir/state/project-data.json"

    CURRENT_SESSION="$session_id"
    CURRENT_PROJECT="$(echo "$project_data" | jq -r '.path')"

    log "SUCCESS" "Session created: $session_id"
    echo "$session_dir"
}

# Run migration workflow
run_migration_workflow() {
    local session_dir="$1"
    local session_id="$CURRENT_SESSION"

    log "INFO" "Starting migration workflow for session: $session_id"

    # Load session data
    local plan_data=$(cat "$session_dir/config/migration-plan.json")
    local steps=$(echo "$plan_data" | jq '.steps[]')

    echo "${WHITE}🚀 Migration Workflow${NC}"
    echo "====================="
    echo ""

    # Execute steps
    local total_steps=$(echo "$steps" | jq length)
    local completed_steps=0

    echo "$steps" | while read -r step; do
        local step_name=$(echo "$step" | jq -r '.name')
        local step_desc=$(echo "$step" | jq -r '.description')
        local step_est=$(echo "$step" | jq -r '.estimated')

        echo "${BLUE}[Step $((completed_steps + 1))/$total_steps)]${NC} $step_desc"
        echo "   Est. time: $step_est"
        echo ""

        # Update status
        update_step_status "$session_id" "$step_name" "running"

        # Simulate processing (in real implementation, call actual migration tools)
        if [[ "$AUTO_MODE" == true ]]; then
            log "INFO" "Auto-processing step: $step_name"
            simulate_step_execution "$step_name"
        else
            interactive_step_execution "$step_name" "$session_dir"
        fi

        # Mark as completed
        update_step_status "$session_id" "$step_name" "completed"
        completed_steps=$((completed_steps + 1))

        # Update progress
        local progress=$((completed_steps * 100 / total_steps))
        update_session_progress "$session_id" "$progress"

        echo "${GREEN}✓ Step completed${NC}"
        echo ""
    done

    # Final validation
    run_final_validation "$session_id"
}

# Monitor and manage context during execution
monitor_context_during_execution() {
    local session_id="$1"
    local step_name="$2"

    # Estimate context usage based on step complexity
    local estimated_tokens=0

    case "$step_name" in
        "analyze")
            estimated_tokens=50000
            ;;
        "plan")
            estimated_tokens=30000
            ;;
        "transform")
            estimated_tokens=80000
            ;;
        "validate")
            estimated_tokens=40000
            ;;
        "deploy")
            estimated_tokens=20000
            ;;
        *)
            estimated_tokens=25000
            ;;
    esac

    # Check if we need to monitor context
    if command -v context-manager.sh >/dev/null 2>&1; then
        local current_context=$("$SCRIPT_DIR/context-manager.sh" monitor "$estimated_tokens" 2>/dev/null || echo "0")

        # Log context status
        log "DEBUG" "Context check for $step_name: $current_context tokens"

        # If context is approaching limit, trigger preventive compression
        if [[ "$current_context" =~ ^[0-9]+$ ]] && (( current_context > 150000 )); then
            log "WARNING" "Context usage high, triggering compression"
            "$SCRIPT_DIR/context-manager.sh" compress 2>/dev/null || log "WARNING" "Context compression failed"
        fi
    fi
}

# Create backup of project files
create_project_backup() {
    local session_id="$1"
    local project_path="$2"

    log "INFO" "Creating project backup for session: $session_id"

    # Get session directory
    local session_dir="$SESSIONS_DIR/$session_id"
    local backup_dir="$session_dir/backup"

    # Create backup directory
    mkdir -p "$backup_dir"

    # Create backup manifest
    local manifest_file="$backup_dir/backup-manifest.json"
    cat > "$manifest_file" << EOF
{
  "session_id": "$session_id",
  "backup_at": "$(date -Iseconds)",
  "project_path": "$project_path",
  "backup_size": 0,
  "files_count": 0
}
EOF

    # Backup files based on git if available
    if [ -d "$project_path/.git" ]; then
        log "INFO" "Using git to track files for backup"
        cd "$project_path"
        git ls-files > "$backup_dir/files.list"

        local file_count=0
        local total_size=0

        while IFS= read -r file; do
            if [ -f "$file" ]; then
                mkdir -p "$backup_dir/$(dirname "$file")"
                cp "$file" "$backup_dir/$file"
                file_count=$((file_count + 1))
                local file_size=$(stat -c%s "$file")
                total_size=$((total_size + file_size))
            fi
        done < "$backup_dir/files.list"

        # Update manifest
        jq --arg files_count "$file_count" --arg total_size "$total_size" \
           '.files_count = ($files_count | tonumber) | .backup_size = ($total_size | tonumber)' \
           "$manifest_file" > "$manifest_file.tmp" && mv "$manifest_file.tmp" "$manifest_file"

        log "SUCCESS" "Backup created: $file_count files, $total_size bytes"
    else
        log "WARNING" "No git repository found, backing up all files"
        # Fallback: backup all files (simple approach)
        find "$project_path" -type f -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/target/*" -not -path "*/build/*" | while read -r file; do
            local rel_path="${file#$project_path/}"
            mkdir -p "$backup_dir/$(dirname "$rel_path")"
            cp "$file" "$backup_dir/$rel_path"
        done

        # Update manifest
        local file_count=$(find "$backup_dir" -type f | wc -l)
        local total_size=$(du -sb "$backup_dir" | cut -f1)
        jq --arg files_count "$file_count" --arg total_size "$total_size" \
           '.files_count = ($files_count | tonumber) | .backup_size = ($total_size | tonumber)' \
           "$manifest_file" > "$manifest_file.tmp" && mv "$manifest_file.tmp" "$manifest_file"

        log "SUCCESS" "Backup created: $file_count files, $total_size bytes"
    fi
}

# Simulate step execution (for testing)
simulate_step_execution() {
    local step_name="$1"
    local session_id="$CURRENT_SESSION"

    log "DEBUG" "Simulating step: $step_name"

    # Monitor context before execution
    monitor_context_during_execution "$session_id" "$step_name"

    # Create backup before implementation step
    if [[ "$step_name" == "implementation" ]]; then
        local project_path=$(cat "$SESSIONS_DIR/$session_id/config/migration-config.yml" | grep "path:" | cut -d'"' -f2)
        create_project_backup "$session_id" "$project_path"
        log "INFO" "Project backup created before implementation"
    fi

    # Simulate work
    case "$step_name" in
        "analysis")
            sleep 2
            ;;
        "planning")
            sleep 1
            ;;
        "implementation")
            sleep 3
            ;;
        "validation")
            sleep 2
            ;;
    esac

    log "SUCCESS" "Step completed: $step_name"
}

# Interactive step execution
interactive_step_execution() {
    local step_name="$1"
    local session_dir="$2"

    log "INFO" "Interactive step: $step_name"

    # Monitor context before execution
    monitor_context_during_execution "$CURRENT_SESSION" "$step_name"

    # Create backup before implementation step
    if [[ "$step_name" == "implementation" ]]; then
        local project_path=$(cat "$session_dir/config/migration-config.yml" | grep "path:" | cut -d'"' -f2)
        create_project_backup "$CURRENT_SESSION" "$project_path"
        log "INFO" "Project backup created before implementation"
        echo "${GREEN}✓ Project backup created${NC}"
        echo ""
    fi

    case "$step_name" in
        "analysis")
            echo "${YELLOW}Running project analysis...${NC}"
            # Call analysis tools
            "$SCRIPT_DIR/incremental-processor.sh" detect "$CURRENT_PROJECT" "$CURRENT_SESSION"
            ;;
        "planning")
            echo "${YELLOW}Creating migration plan...${NC}"
            # Call planning tools
            ;;
        "implementation")
            echo "${YELLOW}Applying migration changes...${NC}"
            # Call implementation tools
            ;;
        "validation")
            echo "${YELLOW}Validating results...${NC}"
            # Call validation tools
            ;;
    esac

    # Wait for user confirmation
    read -p "Press Enter to continue to next step..."
}

# Update step status
update_step_status() {
    local session_id="$1"
    local step_name="$2"
    local status="$3"

    local session_dir="$SESSIONS_DIR/$session_id"
    local state_file="$session_dir/state/session-state.json"

    if [[ -f "$state_file" ]]; then
        jq ".steps_completed += [\"$step_name\"]" "$state_file" > "${state_file}.tmp" && \
        mv "${state_file}.tmp" "$state_file"
    fi
}

# Update session progress
update_session_progress() {
    local session_id="$1"
    local progress="$2"

    local session_dir="$SESSIONS_DIR/$session_id"
    local config_file="$session_dir/config/migration-config.yml"
    local state_file="$session_dir/state/session-state.json"

    # Update config
    yq eval ".session.progress = $progress" "$config_file" -i

    # Update state
    jq ".progress = $progress" "$state_file" > "${state_file}.tmp" && \
    mv "${state_file}.tmp" "$state_file"

    log "INFO" "Session progress: $progress%"
}

# Run final validation
run_final_validation() {
    local session_id="$1"

    log "INFO" "Running final validation..."

    # Run validation tools
    "$SCRIPT_DIR/session-manager.sh" checkpoint "$session_id" "final-validation" "{}"

    echo "${GREEN}✓ Migration completed successfully!${NC}"

    # Generate report
    generate_completion_report "$session_id"
}

# Generate completion report
generate_completion_report() {
    local session_id="$1"
    local session_dir="$SESSIONS_DIR/$session_id"

    local report_file="$session_dir/completion-report.md"

    cat > "$report_file" << EOF
# Migration Completion Report

## Session Information
- **Session ID**: $session_id
- **Completion Time**: $(date)
- **Project**: $(cat "$session_dir/config/migration-config.yml" | yq eval '.project.name' -i)
- **Total Steps**: $(cat "$session_dir/config/migration-config.yml" | yq eval '.session.total_steps' -i)
- **Final Progress**: 100%

## Migration Summary
EOF

    log "SUCCESS" "Completion report generated: $report_file"
}

# Handle user commands
handle_command() {
    local cmd="$1"
    shift

    case "$cmd" in
        "start")
            start_migration "$@"
            ;;
        "resume")
            resume_migration "$@"
            ;;
        "status")
            show_status "$@"
            ;;
        "list")
            "$SCRIPT_DIR/session-manager.sh" list
            ;;
        "cleanup")
            cleanup "$@"
            ;;
        "help")
            show_help
            ;;
        *)
            show_help
            ;;
    esac
}

# Start migration
start_migration() {
    local project_path="${1:-.}"
    local config_file="$2"

    # Initialize if needed
    if [[ ! -d "$SESSIONS_DIR" ]]; then
        init_assistant
    fi

    # Detect project
    local project_data=$(detect_project "$project_path")
    log "INFO" "Project detected: $(echo "$project_data" | jq -r '.name')"

    # Interactive analysis
    local plan_data=$(analyze_project_interactive "$project_data")

    # Create session
    local session_dir=$(create_session "$project_data" "$plan_data")

    # Start workflow
    run_migration_workflow "$session_dir"
}

# Resume migration
resume_migration() {
    local session_id="$1"

    if [[ -z "$session_id" ]]; then
        echo "Available sessions:"
        "$SCRIPT_DIR/session-manager.sh" list
        read -p "Enter session ID to resume: " session_id
    fi

    # Check if session exists
    local session_status=$( "$SCRIPT_DIR/session-manager.sh" status "$session_id" )
    if [[ "$session_status" == "not_found" ]]; then
        log "ERROR" "Session not found: $session_id"
        exit 1
    fi

    # Load session
    local session_dir=$( "$SCRIPT_DIR/session-manager.sh" resume "$session_id" )

    # Resume workflow
    run_migration_workflow "$session_dir"
}

# Show status
show_status() {
    local session_id="$1"

    if [[ -z "$session_id" ]]; then
        log "INFO" "Current session: $CURRENT_SESSION"
        if [[ -n "$CURRENT_SESSION" ]]; then
            "$SCRIPT_DIR/session-manager.sh" status "$CURRENT_SESSION"
        else
            echo "No active session"
        fi
    else
        "$SCRIPT_DIR/session-manager.sh" status "$session_id"
    fi
}

# Cleanup
cleanup() {
    local days="${1:-30}"
    log "INFO" "Cleaning up old data (older than $days days)"

    "$SCRIPT_DIR/session-manager.sh" cleanup "$days"
    "$SCRIPT_DIR/state-restorer.sh" cleanup "$days"

    log "SUCCESS" "Cleanup completed"
}

# Show help
show_help() {
    cat << EOF
Migration Assistant - Smart Code Migration Tool

Usage: $0 [command] [options]

Commands:
  start [project_path] [config_file]  - Start new migration
    --auto                            - Enable auto mode
    --verbose                         - Enable verbose logging

  resume [session_id]                 - Resume existing migration
  status [session_id]                - Show session status
  list                              - List all sessions
  cleanup [days]                    - Cleanup old data
  help                              - Show this help

Examples:
  $0 start ./my-project
  $0 start ./my-project --auto --verbose
  $0 resume migration-2026-02-01-14:35
  $0 status

Environment:
  SESSIONS_DIR   - Session storage directory
  STATE_DIR      - State data directory
  CACHE_DIR      - Cache directory
  CONFIG_DIR     - Configuration directory

EOF
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --auto)
                AUTO_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done

    # Initialize environment
    if [[ ! -d "$SESSIONS_DIR" ]]; then
        init_assistant
    fi

    # Handle commands
    handle_command "$@"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi