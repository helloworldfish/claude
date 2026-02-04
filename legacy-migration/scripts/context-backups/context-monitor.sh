#!/bin/bash

# 实时上下文监控器 - 持续监控上下文使用情况并提供预警
# 支持实时监控、日志记录和自动清理

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../" && pwd)"
CONFIG_FILE="$PROJECT_ROOT/context-config.json"
LOG_DIR="$PROJECT_ROOT/.context-monitor-logs"

# 加载配置
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        CONFIG=$(cat "$CONFIG_FILE")
        CHECK_INTERVAL=$(echo "$CONFIG" | jq -r '.monitoring.check_interval')
        LOG_LEVEL=$(echo "$CONFIG" | jq -r '.monitoring.log_level')
        ENABLE_REAL_TIME=$(echo "$CONFIG" | jq -r '.monitoring.enable_real_time')
        CLEANUP_ON_THRESHOLD=$(echo "$CONFIG" | jq -r '.monitoring.cleanup_on_threshold')
        AUTO_CLEANUP_RATIO=$(echo "$CONFIG" | jq -r '.monitoring.auto_cleanup_ratio')
    else
        CHECK_INTERVAL=30
        LOG_LEVEL="info"
        ENABLE_REAL_TIME=true
        CLEANUP_ON_THRESHOLD=true
        AUTO_CLEANUP_RATIO=0.8
    fi
}

# 创建日志目录
setup_logging() {
    mkdir -p "$LOG_DIR"
}

# 记录日志
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if [[ "$LOG_LEVEL" == "debug" ]] || ([[ "$LOG_LEVEL" == "info" ]] && [[ "$level" != "debug" ]]); then
        echo "[$timestamp] [$level] $message" >> "$LOG_DIR/context-monitor.log"
    fi
}

# 获取当前上下文使用量（模拟实现）
get_current_context() {
    # 在实际实现中，这里应该通过API获取真实的上下文使用量
    # 现在使用模拟数据
    local base_usage=0
    local file_count=$(find "$PROJECT_ROOT" -type f | wc -l)

    # 基于文件数量估算
    base_usage=$((file_count * 1000))

    # 添加随机波动
    local fluctuation=$((RANDOM % 20000))

    echo $((base_usage + fluctuation))
}

# 获取当前时间戳（秒）
get_timestamp() {
    date +%s
}

# 计算上下文使用率
calculate_usage_ratio() {
    local current_context=$1
    local threshold=$(echo "$CONFIG" | jq -r '.context_thresholds.preventive')
    echo "scale=2; $current_context / $threshold" | bc
}

# 触发压缩
trigger_compression() {
    local level=$1
    local current_context=$2

    log_message "info" "Triggering compression at level $level (current: $current_context)"

    # 调用压缩器
    "$SCRIPT_DIR/context-compressor.sh" auto-compress "$PROJECT_PATH" 2>/dev/null

    # 记录压缩后状态
    local new_context=$(get_current_context)
    local saved=$((current_context - new_context))

    log_message "info" "Compression saved: $saved tokens"
    echo "$saved"
}

# 检查阈值并处理
check_thresholds() {
    local current_context=$(get_current_context)
    local timestamp=$(get_timestamp)

    # 各阈值定义
    local warning=$(echo "$CONFIG" | jq -r '.context_thresholds.warning')
    local preventive=$(echo "$CONFIG" | jq -r '.context_thresholds.preventive')
    local cleanup=$(echo "$CONFIG" | jq -r '.context_thresholds.cleanup')
    local critical=$(echo "$CONFIG" | jq -r '.context_thresholds.critical')
    local emergency=$(echo "$CONFIG" | jq -r '.context_thresholds.emergency')
    local hard_limit=$(echo "$CONFIG" | jq -r '.context_thresholds.hard_limit')

    # 根据当前值采取行动
    if [[ $current_context -gt $hard_limit ]]; then
        log_message "error" "Context exceeded hard limit: $current_context / $hard_limit"
        echo "ERROR: Context exceeded hard limit!"
        return 1
    elif [[ $current_context -gt $emergency ]]; then
        log_message "critical" "Context at emergency level: $current_context / $hard_limit"
        trigger_compression "level_3" "$current_context"
        echo "CRITICAL: Emergency compression triggered!"
    elif [[ $current_context -gt $critical ]]; then
        log_message "alert" "Context at critical level: $current_context"
        trigger_compression "level_2" "$current_context"
        echo "ALERT: Critical compression triggered!"
    elif [[ $current_context -gt $cleanup ]]; then
        log_message "warning" "Context at cleanup level: $current_context"
        if [[ "$CLEANUP_ON_THRESHOLD" == "true" ]]; then
            trigger_compression "level_1" "$current_context"
        fi
        echo "WARNING: Context approaching cleanup threshold!"
    elif [[ $current_context -gt $preventive ]]; then
        log_message "info" "Context at preventive level: $current_context"
        echo "INFO: Context reached preventive threshold"
    else
        log_message "debug" "Context normal: $current_context"
    fi
}

# 生成状态报告
generate_status_report() {
    local timestamp=$(get_timestamp)
    local current_context=$(get_current_context)
    local ratio=$(calculate_usage_ratio "$current_context")

    local report_file="$LOG_DIR/status-$(date +%Y%m%d-%H%M%S).json"

    cat > "$report_file" << EOF
{
  "timestamp": $timestamp,
  "current_context": $current_context,
  "usage_ratio": $ratio,
  "thresholds": {
    "warning": $(echo "$CONFIG" | jq -r '.context_thresholds.warning'),
    "preventive": $(echo "$CONFIG" | jq -r '.context_thresholds.preventive'),
    "cleanup": $(echo "$CONFIG" | jq -r '.context_thresholds.cleanup'),
    "critical": $(echo "$CONFIG" | jq -r '.context_thresholds.critical'),
    "emergency": $(echo "$CONFIG" | jq -r '.context_thresholds.emergency'),
    "hard_limit": $(echo "$CONFIG" | jq -r '.context_thresholds.hard_limit')
  },
  "status": "$(get_context_status "$current_context")"
}
EOF
}

# 获取上下文状态
get_context_status() {
    local context=$1
    local critical=$(echo "$CONFIG" | jq -r '.context_thresholds.critical')

    if [[ $context -gt $critical ]]; then
        "critical"
    elif [[ $context -gt $(echo "$CONFIG" | jq -r '.context_thresholds.cleanup') ]]; then
        "warning"
    elif [[ $context -gt $(echo "$CONFIG" | jq -r '.context_thresholds.preventive') ]]; then
        "normal"
    else
        "good"
    fi
}

# 显示实时监控界面
show_realtime_monitor() {
    if [[ "$ENABLE_REAL_TIME" != "true" ]]; then
        return
    fi

    echo "=== Real-time Context Monitor ==="
    echo "Project: $PROJECT_ROOT"
    echo "Press Ctrl+C to stop monitoring"
    echo ""

    while true; do
        # 清屏
        clear

        # 获取当前状态
        local context=$(get_current_context)
        local ratio=$(calculate_usage_ratio "$context")
        local status=$(get_context_status "$context")

        # 显示状态
        echo "Context Usage Monitor - $(date)"
        echo "=================================="
        echo "Current Context: $context tokens"
        echo "Usage Ratio: $ratio"
        echo "Status: $status"
        echo ""

        # 显示阈值进度条
        echo "Threshold Progress:"
        local preventive=$(echo "$CONFIG" | jq -r '.context_thresholds.preventive')
        show_progress_bar "$context" "$preventive"
        echo ""

        # 显示历史统计
        show_statistics

        sleep "$CHECK_INTERVAL"
    done
}

# 显示进度条
show_progress_bar() {
    local current=$1
    local max=$2
    local width=50
    local filled=$((current * width / max))

    printf "["
    for ((i=0; i<filled; i++)); do printf "#"; done
    for ((i=filled; i<width; i++)); do printf " "; done
    printf "] %d/%d (%d%%)" "$current" "$max" $((current * 100 / max))
}

# 显示统计信息
show_statistics() {
    echo ""
    echo "Statistics:"

    # 检查最近的日志
    if [[ -f "$LOG_DIR/context-monitor.log" ]]; then
        local recent_entries=$(tail -n 10 "$LOG_DIR/context-monitor.log" | grep -c "ALERT\|CRITICAL\|ERROR")
        echo "  Recent alerts: $recent_entries"
    fi

    # 显示文件数量
    local file_count=$(find "$PROJECT_ROOT" -type f | wc -l)
    echo "  Total files: $file_count"

    # 显示备份数量
    if [[ -d "$PROJECT_ROOT/.context-compression-backups" ]]; then
        local backup_count=$(find "$PROJECT_ROOT/.context-compression-backups" -type f | wc -l)
        echo "  Backup files: $backup_count"
    fi
}

# 启动后台监控
start_background_monitor() {
    log_message "info" "Starting background context monitor"

    while true; do
        check_thresholds
        sleep "$CHECK_INTERVAL"
    done
}

# 主函数
main() {
    load_config
    setup_logging

    case "${1:-help}" in
        "start")
            if [[ "$ENABLE_REAL_TIME" == "true" ]]; then
                show_realtime_monitor
            else
                start_background_monitor
            fi
            ;;
        "check")
            check_thresholds
            ;;
        "status")
            generate_status_report
            echo "Status report generated: $LOG_DIR/status-$(date +%Y%m%d-%H%M%S).json"
            ;;
        "logs")
            if [[ -f "$LOG_DIR/context-monitor.log" ]]; then
                tail -f "$LOG_DIR/context-monitor.log"
            else
                echo "No logs found"
            fi
            ;;
        *)
            echo "Context Monitor"
            echo "Usage:"
            echo "  $0 start        - Start monitoring (real-time or background)"
            echo "  $0 check        - Check thresholds once"
            echo "  $0 status       - Generate status report"
            echo "  $0 logs         - Show live logs"
            ;;
    esac
}

# 执行主函数
main "$@"