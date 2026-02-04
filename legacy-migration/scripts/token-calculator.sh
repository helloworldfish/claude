#!/bin/bash

# Token计算器 - 基于实际文件大小的智能token估算
# 用于精确计算上下文使用量，预防超限

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../" && pwd)"
CONFIG_FILE="$PROJECT_ROOT/context-config.json"

# 加载配置
if [[ -f "$CONFIG_FILE" ]]; then
    CONFIG=$(cat "$CONFIG_FILE")
    CONTEXT_THRESHOLD=$(echo "$CONFIG" | jq -r '.context_thresholds.preventive')
    CONTEXT_HARD_LIMIT=$(echo "$CONFIG" | jq -r '.context_thresholds.hard_limit')
    BASE_OVERHEAD=$(echo "$CONFIG" | jq -r '.token_estimation.base_system_overhead')
    SAFETY_MARGIN=$(echo "$CONFIG" | jq -r '.token_estimation.safety_margin')
else
    CONTEXT_THRESHOLD=150000
    CONTEXT_HARD_LIMIT=200000
    BASE_OVERHEAD=20000
    SAFETY_MARGIN=0.2
fi

# 文件大小分类函数
classify_file_size() {
    local file_size=$1
    if [[ $file_size -lt 1000 ]]; then
        echo "small"
    elif [[ $file_size -lt 5000 ]]; then
        echo "medium"
    elif [[ $file_size -lt 20000 ]]; then
        echo "large"
    else
        echo "xlarge"
    fi
}

# 估算单个文件的token数
estimate_file_tokens() {
    local file_path=$1
    if [[ ! -f "$file_path" ]]; then
        echo 0
        return
    fi

    local file_size=$(wc -c < "$file_path")
    local size_class=$(classify_file_size "$file_size")

    # 基础token估算（字符数/4）
    local base_tokens=$((file_size / 4))

    # 根据文件类型调整
    case "$file_path" in
        *.java|*.py|*.js|*.ts)
            base_tokens=$((base_tokens * 12 / 10))  # 代码文件额外20%
            ;;
        *.md|*.txt)
            base_tokens=$((base_tokens * 8 / 10))   # 文档文件减少20%
            ;;
        *.yml|*.yaml|*.json)
            base_tokens=$((base_tokens * 9 / 10))   # 配置文件减少10%
            ;;
        *.xml)
            base_tokens=$((base_tokens * 11 / 10))  # XML文件增加10%
            ;;
    esac

    echo $base_tokens
}

# 估算步骤的token使用量
estimate_step_tokens() {
    local step=$1
    local project_path=$2
    local config="$3"

    # 从配置中获取基础值和倍数
    local base_tokens=$(echo "$config" | jq -r ".token_estimation.step_weights.$step.base")
    local multiplier=$(echo "$config" | jq -r ".token_estimation.step_weights.$step.multiplier")

    if [[ "$base_tokens" == "null" || "$multiplier" == "null" ]]; then
        echo "50000"  # 默认值
        return
    fi

    # 计算项目文件数量和复杂度
    local file_count=$(find "$project_path" -type f -name "*.java" -o -name "*.py" -o -name "*.js" -o -name "*.ts" | wc -l)
    local complexity_factor=$((file_count / 100 + 1))  # 每100个文件增加1倍复杂度

    # 计算预估token
    local estimated_tokens=$((base_tokens * multiplier * complexity_factor))

    # 添加安全边际
    local final_tokens=$((estimated_tokens * 100 / (100 - SAFETY_MARGIN * 100)))

    echo $final_tokens
}

# 计算当前上下文使用量
calculate_current_context() {
    # 这里需要根据实际情况实现
    # 可以通过API或日志来获取当前上下文使用量
    echo 0
}

# 监控上下文使用情况
monitor_context() {
    local current_context=$(calculate_current_context)

    if [[ $current_context -gt $CONTEXT_HARD_LIMIT ]]; then
        echo "ERROR: Context exceeded hard limit: $current_context / $CONTEXT_HARD_LIMIT"
        return 1
    elif [[ $current_context -gt $CONTEXT_THRESHOLD ]]; then
        echo "WARNING: Context approaching limit: $current_context / $CONTEXT_THRESHOLD"
        return 2
    else
        echo "OK: Context within limits: $current_context / $CONTEXT_THRESHOLD"
        return 0
    fi
}

# 生成token使用报告
generate_token_report() {
    local project_path=$1
    local output_file="$2"

    echo "Token Usage Report - $(date)" > "$output_file"
    echo "====================================" >> "$output_file"
    echo "Project: $project_path" >> "$output_file"
    echo "" >> "$output_file"

    # 计算各步骤预估使用量
    local steps=("analyze" "plan" "transform" "validate" "deploy")
    for step in "${steps[@]}"; do
        local tokens=$(estimate_step_tokens "$step" "$project_path" "$(cat "$CONFIG_FILE")")
        echo "$step: ~$tokens tokens" >> "$output_file"
    done

    echo "" >> "$output_file"
    echo "System overhead: $BASE_OVERHEAD tokens" >> "$output_file"
    echo "Safety margin: $SAFETY_MARGIN%" >> "$output_file"
    echo "" >> "$output_file"

    # 计算文件级别的token使用
    echo "File breakdown:" >> "$output_file"
    find "$project_path" -type f \( -name "*.java" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \) | head -20 | while read -r file; do
        local tokens=$(estimate_file_tokens "$file")
        echo "  $file: $tokens tokens" >> "$output_file"
    done
}

# 主要功能函数
main() {
    case "${1:-help}" in
        "estimate-step")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 estimate-step <STEP_NAME> <PROJECT_PATH>"
                exit 1
            fi
            local step=$2
            local project_path=$3
            local tokens=$(estimate_step_tokens "$step" "$project_path" "$(cat "$CONFIG_FILE")")
            echo "Estimated tokens for $step: $tokens"
            ;;
        "monitor")
            monitor_context
            ;;
        "report")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 report <PROJECT_PATH> <OUTPUT_FILE>"
                exit 1
            fi
            generate_token_report "$2" "$3"
            ;;
        "file-tokens")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 file-tokens <FILE_PATH>"
                exit 1
            fi
            local tokens=$(estimate_file_tokens "$2")
            echo "Tokens for $2: $tokens"
            ;;
        *)
            echo "Token Calculator"
            echo "Usage:"
            echo "  $0 estimate-step <STEP_NAME> <PROJECT_PATH>"
            echo "  $0 monitor"
            echo "  $0 report <PROJECT_PATH> <OUTPUT_FILE>"
            echo "  $0 file-tokens <FILE_PATH>"
            ;;
    esac
}

# 执行主函数
main "$@"