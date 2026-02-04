#!/bin/bash

# Legacy Migration Assistant
# 集成所有功能的智能迁移助手，简化用户操作

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSIONS_DIR="${SESSIONS_DIR:-$PROJECT_ROOT/.legacy-migration/sessions}"
STATE_DIR="${STATE_DIR:-$PROJECT_ROOT/.legacy-migration/state}"
CACHE_DIR="${CACHE_DIR:-$PROJECT_ROOT/.legacy-migration/cache}"
CONFIG_DIR="${CONFIG_DIR:-$PROJECT_ROOT/.legacy-migration/config}"
TEMP_DIR="${TEMP_DIR:-$PROJECT_ROOT/.legacy-migration/temp}"

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
INTERRUPTED=false

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

# Handle interruption
handle_interrupt() {
    log "WARNING" "收到中断信号，正在保存状态..."
    INTERRUPTED=true

    # Save current state if we have an active session
    if [[ -n "$CURRENT_SESSION" ]]; then
        save_interrupted_state "$CURRENT_SESSION"

        # Save checkpoint
        "$SCRIPT_DIR/session-manager.sh" checkpoint "$CURRENT_SESSION" "interrupted" "{}"

        log "INFO" "状态已保存，可以通过以下命令恢复: $0 --resume --session-id $CURRENT_SESSION"
    fi

    exit 130
}

# Save state when interrupted
save_interrupted_state() {
    local session_id="$1"
    local session_dir="$SESSIONS_DIR/$session_id"
    local state_file="$session_dir/state/session-state.json"

    if [[ -f "$state_file" ]]; then
        # Update state to reflect interruption
        jq ".status = \"interrupted\" | .interrupted_at = \"$(date -Iseconds)\" | .interrupted = true" "$state_file" > "${state_file}.tmp" && \
        mv "${state_file}.tmp" "$state_file"

        log "INFO" "中断状态已保存: $session_id"
    fi
}

# Save periodic checkpoint
save_periodic_checkpoint() {
    local session_id="$1"

    if [[ -n "$session_id" ]]; then
        local checkpoint_data=$(jq -n \
            --arg timestamp "$(date -Iseconds)" \
            --arg progress "$(cat "$SESSIONS_DIR/$session_id/state/session-state.json" | jq '.progress')" \
            '{timestamp: $timestamp, progress: $progress}')

        "$SCRIPT_DIR/session-manager.sh" checkpoint "$session_id" "periodic" "$checkpoint_data"

        if [[ "$VERBOSE" == true ]]; then
            log "DEBUG" "检查点已保存: $session_id"
        fi
    fi
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

    # Set up signal traps
    trap handle_interrupt SIGINT SIGTERM

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
    local last_checkpoint_time=0

    echo "$steps" | while read -r step; do
        local step_name=$(echo "$step" | jq -r '.name')
        local step_desc=$(echo "$step" | jq -r '.description')
        local step_est=$(echo "$step" | jq -r '.estimated')

        echo "${BLUE}[Step $((completed_steps + 1))/$total_steps)]${NC} $step_desc"
        echo "   Est. time: $step_est"
        echo ""

        # Update status
        update_step_status "$session_id" "$step_name" "running"

        # Save periodic checkpoint every 2 steps or every 5 minutes
        local current_time=$(date +%s)
        if [[ $((current_time - last_checkpoint_time)) -gt 300 || $completed_steps -gt 0 && $((completed_steps % 2)) -eq 0 ]]; then
            save_periodic_checkpoint "$session_id"
            last_checkpoint_time=$current_time
        fi

        # Simulate processing (in real implementation, call actual migration tools)
        if [[ "$AUTO_MODE" == true ]]; then
            log "INFO" "Auto-processing step: $step_name"
            simulate_step_execution "$step_name"
        else
            interactive_step_execution "$step_name" "$session_dir"
        fi

        # Check if was interrupted
        if [[ "$INTERRUPTED" == true ]]; then
            log "WARNING" "检测到中断，退出迁移工作流"
            return
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

    # Load unified configuration
    if [[ -f "$PROJECT_ROOT/context-config.json" ]]; then
        # Get step weights from config
        local step_config=$(jq -r ".token_estimation.step_weights.$step_name" "$PROJECT_ROOT/context-config.json")
        if [[ "$step_config" != "null" ]]; then
            local base_tokens=$(echo "$step_config" | jq -r '.base')
            local multiplier=$(echo "$step_config" | jq -r '.multiplier')
            local estimated_tokens=$((base_tokens * multiplier / 100 * 100))  # Handle potential decimals
        else
            estimated_tokens=50000  # fallback
        fi
    else
        # Estimate context usage based on step complexity
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
    fi

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

# Validate backup integrity
validate_backup() {
    local backup_dir="$1"
    local manifest_file="$backup_dir/backup-manifest.json"

    if [[ ! -f "$manifest_file" ]]; then
        log "ERROR" "Backup manifest not found: $manifest_file"
        return 1
    fi

    # Check if all files in manifest exist
    local files_list="$backup_dir/files.list"
    if [[ -f "$files_list" ]]; then
        local missing_files=0
        while IFS= read -r file; do
            if [[ ! -f "$backup_dir/$file" ]]; then
                log "WARNING" "Missing file in backup: $file"
                missing_files=$((missing_files + 1))
            fi
        done < "$files_list"

        if [[ $missing_files -gt 0 ]]; then
            log "ERROR" "Backup validation failed: $missing_files files missing"
            return 1
        fi
    fi

    # Check backup status
    local status=$(jq -r '.status' "$manifest_file")
    if [[ "$status" != "completed" ]]; then
        log "ERROR" "Backup not completed: status = $status"
        return 1
    fi

    log "SUCCESS" "Backup validation passed: $backup_dir"
    return 0
}

# List available backups
list_backups() {
    local backup_root="${1:-$PROJECT_ROOT/.refactor-backups}"

    if [[ ! -d "$backup_root" ]]; then
        echo "No backups found"
        return 0
    fi

    echo "📋 可用备份列表"
    echo "==============="
    echo ""

    # Find backup directories
    for backup_dir in "$backup_root"/migration-*; do
        if [[ -d "$backup_dir" ]]; then
            local manifest_file="$backup_dir/backup-manifest.json"
            if [[ -f "$manifest_file" ]]; then
                local session_id=$(jq -r '.session_id' "$manifest_file")
                local backup_time=$(jq -r '.backup_at' "$manifest_file")
                local files_count=$(jq -r '.files_count' "$manifest_file")
                local backup_size=$(jq -r '.backup_size' "$manifest_file")
                local status=$(jq -r '.status' "$manifest_file")

                # Format size
                local size_str=""
                if [[ "$backup_size" -gt 1048576 ]]; then
                    size_str=$(echo "scale=2; $backup_size / 1048576" | bc)" MB"
                elif [[ "$backup_size" -gt 1024 ]]; then
                    size_str=$(echo "scale=2; $backup_size / 1024" | bc)" KB"
                else
                    size_str="$backup_size B"
                fi

                # Status indicator
                local status_indicator="✅"
                if [[ "$status" != "completed" ]]; then
                    status_indicator="❌"
                fi

                echo "${status_indicator} 会话: $session_id"
                echo "   时间: $backup_time"
                echo "   文件: $files_count 个"
                echo "   大小: $size_str"
                echo ""
            fi
        fi
    done

    # Show latest backup symlink
    if [[ -L "$backup_root/latest" ]]; then
        local latest_path=$(readlink "$backup_root/latest")
        echo "🔄 最新备份: $latest_path"
    fi
}

# Create backup of project files
create_project_backup() {
    local session_id="$1"
    local project_path="$2"
    local backup_root="${3:-$PROJECT_ROOT/.refactor-backups}"

    log "INFO" "Creating project backup for session: $session_id"

    # Create backup directory with timestamp
    local timestamp=$(date +%Y-%m-%d-%H%M%S)
    local backup_dir="$backup_root/migration-$timestamp"
    local session_backup_dir="$SESSIONS_DIR/$session_id/backup"

    # Create backup directories
    mkdir -p "$backup_dir"
    mkdir -p "$session_backup_dir"

    # Create backup manifest
    local manifest_file="$backup_dir/backup-manifest.json"
    cat > "$manifest_file" << EOF
{
  "session_id": "$session_id",
  "backup_at": "$(date -Iseconds)",
  "project_path": "$project_path",
  "backup_dir": "$backup_dir",
  "backup_size": 0,
  "files_count": 0,
  "status": "created"
}
EOF

    # Create session backup manifest
    cat > "$session_backup_dir/backup-manifest.json" << EOF
{
  "session_id": "$session_id",
  "backup_at": "$(date -Iseconds)",
  "project_path": "$project_path",
  "main_backup_dir": "$backup_dir",
  "backup_size": 0,
  "files_count": 0,
  "status": "created"
}
EOF

    # Backup files based on git if available
    if [ -d "$project_path/.git" ]; then
        log "INFO" "Using git to track files for backup"
        cd "$project_path"
        git ls-files > "$backup_dir/files.list"
        git ls-files > "$session_backup_dir/files.list"

        local file_count=0
        local total_size=0

        while IFS= read -r file; do
            if [ -f "$file" ]; then
                mkdir -p "$backup_dir/$(dirname "$file")"
                mkdir -p "$session_backup_dir/$(dirname "$file")"
                cp "$file" "$backup_dir/$file"
                cp "$file" "$session_backup_dir/$file"
                file_count=$((file_count + 1))
                local file_size=$(stat -c%s "$file")
                total_size=$((total_size + file_size))
            fi
        done < "$backup_dir/files.list"

        # Update manifests
        jq --arg files_count "$file_count" --arg total_size "$total_size" \
           '.files_count = ($files_count | tonumber) | .backup_size = ($total_size | tonumber) | .status = "completed"' \
           "$manifest_file" > "$manifest_file.tmp" && mv "$manifest_file.tmp" "$manifest_file"

        jq --arg files_count "$file_count" --arg total_size "$total_size" \
           '.files_count = ($files_count | tonumber) | .backup_size = ($total_size | tonumber) | .status = "completed"' \
           "$session_backup_dir/backup-manifest.json" > "$session_backup_dir/backup-manifest.tmp" && \
           mv "$session_backup_dir/backup-manifest.tmp" "$session_backup_dir/backup-manifest.json"

        log "SUCCESS" "Backup created: $file_count files, $total_size bytes in $backup_dir"
    else
        log "WARNING" "No git repository found, backing up all files"
        # Fallback: backup all files (simple approach)
        find "$project_path" -type f -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/target/*" -not -path "*/build/*" | while read -r file; do
            local rel_path="${file#$project_path/}"
            mkdir -p "$backup_dir/$(dirname "$rel_path")"
            mkdir -p "$session_backup_dir/$(dirname "$rel_path")"
            cp "$file" "$backup_dir/$rel_path"
            cp "$file" "$session_backup_dir/$rel_path"
        done

        # Update manifests
        local file_count=$(find "$backup_dir" -type f | wc -l)
        local total_size=$(du -sb "$backup_dir" | cut -f1)
        jq --arg files_count "$file_count" --arg total_size "$total_size" \
           '.files_count = ($files_count | tonumber) | .backup_size = ($total_size | tonumber) | .status = "completed"' \
           "$manifest_file" > "$manifest_file.tmp" && mv "$manifest_file.tmp" "$manifest_file"

        jq --arg files_count "$file_count" --arg total_size "$total_size" \
           '.files_count = ($files_count | tonumber) | .backup_size = ($total_size | tonumber) | .status = "completed"' \
           "$session_backup_dir/backup-manifest.json" > "$session_backup_dir/backup-manifest.tmp" && \
           mv "$session_backup_dir/backup-manifest.tmp" "$session_backup_dir/backup-manifest.json"

        log "SUCCESS" "Backup created: $file_count files, $total_size bytes in $backup_dir"
    fi

    # Create symlink for easy access
    if [[ -L "$backup_root/latest" ]]; then
        rm "$backup_root/latest"
    fi
    ln -s "$backup_dir" "$backup_root/latest"

    # Validate backup
    if validate_backup "$backup_dir"; then
        log "SUCCESS" "Backup created and validated: $backup_dir"
    else
        log "ERROR" "Backup validation failed: $backup_dir"
        return 1
    fi

    echo "$backup_dir"
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
        local project_path=$(cat "$session_dir/config/migration-config.yml" | grep "path:" | cut -d'"' -f2)
        local backup_dir=$(create_project_backup "$session_id" "$project_path" "$PROJECT_ROOT/.refactor-backups")
        log "INFO" "Project backup created: $backup_dir"
        echo "${GREEN}✓ 项目备份已创建: $backup_dir${NC}"
        echo ""
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
        local backup_dir=$(create_project_backup "$CURRENT_SESSION" "$project_path" "$PROJECT_ROOT/.refactor-backups")
        log "INFO" "Project backup created: $backup_dir"
        echo "${GREEN}✓ 项目备份已创建: $backup_dir${NC}"
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

# Update step status with more detailed tracking
update_step_status() {
    local session_id="$1"
    local step_name="$2"
    local status="$3"
    local additional_info="$4"  # Optional: error details, files processed, etc.

    local session_dir="$SESSIONS_DIR/$session_id"
    local state_file="$session_dir/state/session-state.json"

    if [[ -f "$state_file" ]]; then
        # Create backup of current state
        cp "$state_file" "$state_file.backup.$(date +%s)"

        # Update step status
        if [[ "$status" == "completed" ]]; then
            jq ".steps_completed += [\"$step_name\"]" "$state_file" > "${state_file}.tmp" && \
            mv "${state_file}.tmp" "$state_file"
        elif [[ "$status" == "failed" ]]; then
            jq ".steps_failed += [\"$step_name\"]" "$state_file" > "${state_file}.tmp" && \
            mv "${state_file}.tmp" "$state_file"

            # Add error information if provided
            if [[ -n "$additional_info" ]]; then
                jq ".step_errors += {\"$step_name\": $additional_info}" "$state_file" > "${state_file}.tmp" && \
                mv "${state_file}.tmp" "$state_file"
            fi
        elif [[ "$status" == "running" ]]; then
            jq ".steps_in_progress = [\"$step_name\"]" "$state_file" > "${state_file}.tmp" && \
            mv "${state_file}.tmp" "$state_file"
        fi

        # Update last update time
        sed -i "s/\"last_update\": \"[^\"]*\"/\"last_update\": \"$(date -Iseconds)\"/" "$state_file"

        # Save checkpoint when status changes
        if [[ "$status" == "completed" || "$status" == "failed" ]]; then
            local checkpoint_data=$(jq -n \
                --arg step "$step_name" \
                --arg status "$status" \
                --arg timestamp "$(date -Iseconds)" \
                '{step: $step, status: $status, timestamp: $timestamp}')

            "$SCRIPT_DIR/session-manager.sh" checkpoint "$session_id" "step_$status" "$checkpoint_data"
        fi
    fi
}

# Get pending tasks for recovery
get_pending_tasks() {
    local session_id="$1"
    local session_dir="$SESSIONS_DIR/$session_id"
    local state_file="$session_dir/state/session-state.json"

    if [[ ! -f "$state_file" ]]; then
        echo "[]"
        return
    fi

    # Get plan data
    local plan_file="$session_dir/config/migration-plan.json"
    local all_steps=$(jq '.steps[] | .name' "$plan_file")

    # Get completed steps
    local completed_steps=$(jq '.steps_completed[]' "$state_file" 2>/dev/null || echo "")

    # Find pending steps
    echo "$all_steps" | jq -n 'inputs | select(. as $item | inputs | contains($item) | not)'
}

# Generate recovery summary
generate_recovery_summary() {
    local session_id="$1"
    local session_dir="$SESSIONS_DIR/$session_id"

    if [[ ! -d "$session_dir" ]]; then
        echo "Session not found: $session_id"
        return 1
    fi

    local state_file="$session_dir/state/session-state.json"
    local config_file="$session_dir/config/migration-config.yml"
    local plan_file="$session_dir/config/migration-plan.json"

    # Extract information
    local project_name=$(grep "name:" "$config_file" | cut -d'"' -f2)
    local progress=$(jq -r '.progress // 0' "$state_file" 2>/dev/null)
    local status=$(jq -r '.status // "unknown"' "$state_file" 2>/dev/null)
    local completed_steps=$(jq '.steps_completed | length // 0' "$state_file" 2>/dev/null)
    local total_steps=$(jq '.steps | length' "$plan_file")

    # Get pending tasks
    local pending_tasks=$(get_pending_tasks "$session_id")
    local pending_count=$(echo "$pending_tasks" | jq length)

    # Generate summary
    cat << EOF
# 恢复摘要 - 会话: $session_id

## 项目信息
- **项目名称**: $project_name
- **当前进度**: $progress%
- **会话状态**: $status

## 任务统计
- **总步骤数**: $total_steps
- **已完成**: $completed_steps
- **待完成**: $pending_count

## 待完成任务$(echo "$pending_tasks" | jq -r '.[]' | sed 's/^/- /' | head -10)
$(if [[ $pending_count -gt 10 ]]; then echo "(只显示前10个)"; fi)

## 恢复命令
\`\`\`
./commands/start-migration --resume --session-id $session_id
\`\`\`

---
*恢复时间: $(date)*
EOF
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

    # Check if session was interrupted
    local state_file="$SESSIONS_DIR/$session_id/state/session-state.json"
    if [[ -f "$state_file" ]]; then
        local interrupted=$(jq -r '.interrupted // false' "$state_file")
        if [[ "$interrupted" == "true" ]]; then
            log "INFO" "检测到之前中断的会话，正在恢复..."
            # Save interrupted state record
            jq ".recovery_attempts = (.recovery_attempts // 0 + 1)" "$state_file" > "${state_file}.tmp" && \
            mv "${state_file}.tmp" "$state_file"
        fi
    fi

    # Load session
    local session_dir=$( "$SCRIPT_DIR/session-manager.sh" resume "$session_id" )

    # Generate and show recovery summary
    echo "${WHITE}📋 恢复摘要${NC}"
    echo "============="
    echo ""
    generate_recovery_summary "$session_id"
    echo ""

    # Ask for confirmation to resume
    read -p "是否继续恢复此会话? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log "INFO" "恢复已取消"
        exit 0
    fi

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