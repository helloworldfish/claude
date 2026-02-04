#!/bin/bash

# 增强的上下文压缩器 - 支持多种文件类型的智能压缩
# 基于配置文件进行压缩策略选择

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../" && pwd)"
CONFIG_FILE="$PROJECT_ROOT/context-config.json"

# 加载配置
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        CONFIG=$(cat "$CONFIG_FILE")
        COMPRESSION_LEVELS=$(echo "$CONFIG" | jq -r '.compression_levels')
        COMPRESSION_TARGETS=$(echo "$CONFIG" | jq -r '.compression_targets')
        SAFETY_SETTINGS=$(echo "$CONFIG" | jq -r '.safety_settings')
    else
        echo "ERROR: Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
}

# 获取当前上下文使用量
get_current_context() {
    # 这里应该通过API或其他方式获取当前上下文使用量
    # 暂时返回模拟值
    echo 0
}

# 确定压缩级别
determine_compression_level() {
    local current_context=$(get_current_context)
    local threshold=$(echo "$CONFIG" | jq -r '.context_thresholds.preventive')
    local hard_limit=$(echo "$CONFIG" | jq -r '.context_thresholds.hard_limit')

    if [[ $current_context -gt $hard_limit ]]; then
        echo "level_3"
    elif [[ $current_context -gt $((threshold * 12 / 10)) ]]; then
        echo "level_3"
    elif [[ $current_context -gt $((threshold * 11 / 10)) ]]; then
        echo "level_2"
    elif [[ $current_context -gt $threshold ]]; then
        echo "level_1"
    else
        echo "none"
    fi
}

# 提取函数签名
extract_function_signatures() {
    local file_path=$1
    local temp_file=$(mktemp)

    case "$file_path" in
        *.java)
            grep -E "^(public|private|protected)\s+\w+\s+\w+\s*\(" "$file_path" > "$temp_file"
            ;;
        *.py)
            grep -E "^def\s+\w+\s*\(" "$file_path" > "$temp_file"
            ;;
        *.js|*.ts)
            grep -E "^(export\s+)?(async\s+)?function\s+\w+\s*\(|^\w+\s*=\s*(async\s+)?function\s*\(" "$file_path" > "$temp_file"
            ;;
        *)
            return
            ;;
    esac

    echo "$temp_file"
}

# 压缩代码文件
compress_code_file() {
    local file_path=$1
    local level=$2
    local temp_file=$(mktemp)

    # 备份原文件
    cp "$file_path" "$file_path.backup"

    # 根据级别选择压缩策略
    case "$level" in
        "level_1")
            # 保留结构，压缩注释
            grep -v "^\s*//\|^\s*\*" "$file_path" > "$temp_file"
            ;;
        "level_2")
            # 提取函数签名和类定义
            extract_function_signatures "$file_path" > "$temp_file"
            # 提取类定义
            if [[ "$file_path" == *.java ]]; then
                grep -E "^class\s+\w+|^interface\s+\w+" "$file_path" >> "$temp_file"
            elif [[ "$file_path" == *.py ]]; then
                grep -E "^class\s+\w+" "$file_path" >> "$temp_file"
            fi
            ;;
        "level_3")
            # 仅保留关键信息
            echo "/* Compressed version of $file_path */" > "$temp_file"
            echo "// Original file: $(wc -l < "$file_path") lines" >> "$temp_file"
            if [[ "$file_path" == *.java ]]; then
                echo "// Main class: $(grep -o "^class\s+\w+" "$file_path" | head -1)" >> "$temp_file"
            fi
            ;;
    esac

    # 替换原文件
    mv "$temp_file" "$file_path"

    echo "Compressed: $file_path ($level)"
}

# 压缩配置文件
compress_config_file() {
    local file_path=$1
    local level=$2
    local temp_file=$(mktemp)

    case "$file_path" in
        *.json)
            # 简化JSON，保留结构
            jq -c '.' "$file_path" > "$temp_file"
            ;;
        *.yml|*.yaml)
            # 移除注释和空行
            grep -v "^\s*#" "$file_path" | grep -v "^\s*$" > "$temp_file"
            ;;
    esac

    if [[ -s "$temp_file" ]]; then
        mv "$temp_file" "$file_path"
        echo "Compressed config: $file_path"
    fi
}

# 压缩文档文件
compress_document_file() {
    local file_path=$1
    local level=$2
    local temp_file=$(mktemp)

    case "$level" in
        "level_1")
            # 保留标题和关键段落
            grep -E "^#+ |^[A-Z].*\.$" "$file_path" > "$temp_file"
            ;;
        "level_2")
            # 仅保留标题
            grep -E "^#+ " "$file_path" > "$temp_file"
            ;;
        "level_3")
            # 仅保留第一个标题
            head -n 1 "$file_path" | grep -E "^#+ " > "$temp_file"
            ;;
    esac

    if [[ -s "$temp_file" ]]; then
        mv "$temp_file" "$file_path"
        echo "Compressed doc: $file_path"
    fi
}

# 处理大文件
process_large_file() {
    local file_path=$1
    local file_size=$(wc -c < "$file_path")
    local max_size=$(echo "$SAFETY_SETTINGS" | jq -r '.max_single_file_size')

    if [[ $file_size -gt $max_size ]]; then
        local temp_file=$(mktemp)

        # 提取文件头部和尾部
        head -n 100 "$file_path" > "$temp_file"
        echo "/* ... (中间内容被压缩) ... */" >> "$temp_file"
        tail -n 100 "$file_path" >> "$temp_file"

        mv "$temp_file" "$file_path"
        echo "Split large file: $file_path"
    fi
}

# 执行压缩
execute_compression() {
    local project_path=$1
    local level=$2
    local backup_dir="$project_path/.context-compression-backups"

    # 创建备份目录
    mkdir -p "$backup_dir"

    # 获取时间戳
    local timestamp=$(date +%Y%m%d-%H%M%S)

    # 根据压缩级别处理不同类型的文件
    echo "Starting compression (level: $level)..."

    # 处理代码文件
    if [[ -n "$COMPRESSION_TARGETS" ]]; then
        echo "$COMPRESSION_TARGETS" | jq -r '.code_files.extensions[]' | while read -r ext; do
            find "$project_path" -name "$ext" -type f | while read -r file; do
                compress_code_file "$file" "$level"
                # 备份
                cp "$file" "$backup_dir/$(basename "$file")-$timestamp"
            done
        done
    fi

    # 处理配置文件
    if [[ -n "$COMPRESSION_TARGETS" ]]; then
        echo "$COMPRESSION_TARGETS" | jq -r '.config_files.extensions[]' | while read -r ext; do
            find "$project_path" -name "$ext" -type f | while read -r file; do
                compress_config_file "$file" "$level"
            done
        done
    fi

    # 处理文档文件
    if [[ -n "$COMPRESSION_TARGETS" ]]; then
        echo "$COMPRESSION_TARGETS" | jq -r '.documentation.extensions[]' | while read -r ext; do
            find "$project_path" -name "$ext" -type f | while read -r file; do
                compress_document_file "$file" "$level"
            done
        done
    fi

    # 处理大文件
    process_large_file "$project_path/pom.xml" "$level"
    process_large_file "$project_path/build.gradle" "$level"

    echo "Compression completed."
}

# 生成压缩报告
generate_compression_report() {
    local project_path=$1
    local output_file="$2"

    echo "Context Compression Report - $(date)" > "$output_file"
    echo "====================================" >> "$output_file"
    echo "Project: $project_path" >> "$output_file"
    echo "" >> "$output_file"

    # 统计压缩效果
    local backup_count=$(find "$project_path/.context-compression-backups" -name "*.backup" | wc -l)
    local backup_size=$(du -sh "$project_path/.context-compression-backups" | cut -f1)

    echo "Files compressed: $backup_count" >> "$output_file"
    echo "Backup size: $backup_size" >> "$output_file"
    echo "" >> "$output_file"

    # 压缩后的文件统计
    echo "Current file sizes:" >> "$output_file"
    find "$project_path" -name "*.java" -o -name "*.py" | head -10 | while read -r file; do
        local size=$(wc -l < "$file")
        echo "  $file: $size lines" >> "$output_file"
    done
}

# 主函数
main() {
    load_config

    case "${1:-help}" in
        "compress")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 compress <PROJECT_PATH> <LEVEL>"
                echo "LEVEL: level_1, level_2, level_3"
                exit 1
            fi
            execute_compression "$2" "$3"
            ;;
        "auto-compress")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 auto-compress <PROJECT_PATH>"
                exit 1
            fi
            local level=$(determine_compression_level)
            if [[ "$level" != "none" ]]; then
                echo "Auto-compression triggered at level: $level"
                execute_compression "$2" "$level"
            else
                echo "No compression needed"
            fi
            ;;
        "report")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 report <PROJECT_PATH> <OUTPUT_FILE>"
                exit 1
            fi
            generate_compression_report "$2" "$3"
            ;;
        *)
            echo "Context Compressor"
            echo "Usage:"
            echo "  $0 compress <PROJECT_PATH> <LEVEL>"
            echo "  $0 auto-compress <PROJECT_PATH>"
            echo "  $0 report <PROJECT_PATH> <OUTPUT_FILE>"
            ;;
    esac
}

# 执行主函数
main "$@"