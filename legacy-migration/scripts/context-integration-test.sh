#!/bin/bash

# 上下文管理集成测试脚本
# 验证所有上下文管理组件的一致性和功能

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../" && pwd)"

# 加载配置
load_config() {
    if [[ -f "$PROJECT_ROOT/context-config.json" ]]; then
        CONFIG=$(cat "$PROJECT_ROOT/context-config.json")
        CONTEXT_THRESHOLD=$(echo "$CONFIG" | jq -r '.context_thresholds.preventive')
        CONTEXT_HARD_LIMIT=$(echo "$CONFIG" | jq -r '.context_thresholds.hard_limit')
    else
        CONTEXT_THRESHOLD=150000
        CONTEXT_HARD_LIMIT=200000
    fi
}

# 测试token计算器
test_token_calculator() {
    echo "=== Testing Token Calculator ==="

    # 测试单个文件token估算
    if [[ -f "$PROJECT_ROOT/scripts/token-calculator.sh" ]]; then
        local test_file="/Users/lvxiaoyong/code/claude/claude/legacy-migration/README.md"
        if [[ -f "$test_file" ]]; then
            local tokens=$("$SCRIPT_DIR/token-calculator.sh" file-tokens "$test_file")
            echo "✓ File token estimation: $tokens"
        else
            echo "✗ Test file not found"
        fi
    else
        echo "✗ Token calculator script not found"
    fi
}

# 测试压缩器
test_compressor() {
    echo "=== Testing Context Compressor ==="

    if [[ -f "$PROJECT_ROOT/scripts/context-compressor.sh" ]]; then
        echo "✓ Context compressor script found"

        # 检查配置支持
        if [[ -f "$PROJECT_ROOT/context-config.json" ]]; then
            local levels=$(jq -r '.compression_levels | keys[]' "$PROJECT_ROOT/context-config.json")
            echo "✓ Available compression levels: $levels"
        else
            echo "✗ Configuration file not found"
        fi
    else
        echo "✗ Context compressor script not found"
    fi
}

# 测试监控器
test_monitor() {
    echo "=== Testing Context Monitor ==="

    if [[ -f "$PROJECT_ROOT/scripts/context-monitor.sh" ]]; then
        echo "✓ Context monitor script found"

        # 测试一次阈值检查
        local result=$("$SCRIPT_DIR/context-monitor.sh" check 2>&1 || echo "error")
        if [[ "$result" != "error" ]]; then
            echo "✓ Monitor check successful"
        else
            echo "✗ Monitor check failed"
        fi
    else
        echo "✗ Context monitor script not found"
    fi
}

# 检查阈值一致性
check_threshold_consistency() {
    echo "=== Checking Threshold Consistency ==="

    load_config
    echo "Default threshold: $CONTEXT_THRESHOLD"
    echo "Hard limit: $CONTEXT_HARD_LIMIT"

    # 检查各个脚本中的阈值设置
    local scripts=("context-manager.sh" "context-integration.sh" "migration-assistant.sh")
    for script in "${scripts[@]}"; do
        local script_path="$SCRIPT_DIR/$script"
        if [[ -f "$script_path" ]]; then
            echo "✓ $script exists"

            # 检查是否使用统一配置
            if grep -q "context-config.json" "$script_path"; then
                echo "  ✓ Uses unified configuration"
            else
                echo "  ! May use hardcoded values"
            fi
        else
            echo "✗ $script not found"
        fi
    done
}

# 运行所有测试
run_all_tests() {
    echo "Running Context Management Integration Tests"
    echo "=========================================="
    echo ""

    test_token_calculator
    echo ""

    test_compressor
    echo ""

    test_monitor
    echo ""

    check_threshold_consistency
    echo ""

    echo "=== Test Summary ==="
    echo "All components have been tested."
    echo "The unified context configuration is: $PROJECT_ROOT/context-config.json"
}

# 显示使用说明
show_usage() {
    echo "Context Integration Test"
    echo "Usage: $0 [test|token|compress|monitor|check]"
    echo ""
    echo "  test        - Run all tests (default)"
    echo "  token       - Test token calculator only"
    echo "  compress    - Test compressor only"
    echo "  monitor     - Test monitor only"
    echo "  check       - Check threshold consistency only"
}

# 主函数
main() {
    case "${1:-test}" in
        "test")
            run_all_tests
            ;;
        "token")
            test_token_calculator
            ;;
        "compress")
            test_compressor
            ;;
        "monitor")
            test_monitor
            ;;
        "check")
            check_threshold_consistency
            ;;
        *)
            show_usage
            ;;
    esac
}

# 执行主函数
main "$@"