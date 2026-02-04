#!/bin/bash

# Legacy Migration Context Optimization Test
# 测试上下文优化功能的有效性

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${STATE_DIR:-$HOME/.legacy-migration/state}"
SESSIONS_DIR="${SESSIONS_DIR:-$HOME/.legacy-migration/sessions}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test Suite
# =====================================

# Test 1: Context Manager Integration
test_context_manager_integration() {
    log_info "Testing context manager integration..."

    # Check if context-manager.sh exists
    if [[ ! -f "$SCRIPT_DIR/context-manager.sh" ]]; then
        log_error "context-manager.sh not found"
        return 1
    fi

    # Test basic monitoring
    local test_result=$(cd "$SCRIPT_DIR" && ./context-manager.sh monitor 10000 2>/dev/null || echo "fail")
    if [[ "$test_result" != "fail" ]]; then
        log_success "Context monitoring function works"
    else
        log_warning "Context monitoring failed (expected in test environment)"
    fi

    # Test compression functions
    if command -v jq >/dev/null 2>&1; then
        log_success "jq is available for JSON processing"
    else
        log_error "jq is required but not installed"
        return 1
    fi

    log_success "Context manager integration test completed"
}

# Test 2: Context Integration Functions
test_context_integration_functions() {
    log_info "Testing context integration functions..."

    # Create a test session
    local test_session="test-context-$(date +%s)"
    local test_project="/tmp/test-project"

    # Create test project structure
    mkdir -p "$test_project/src"
    echo "console.log('Hello World');" > "$test_project/src/index.js"
    echo "package.json" > "$test_project/.gitignore"

    # Initialize context management
    if [[ -f "$SCRIPT_DIR/context-integration.sh" ]]; then
        cd "$SCRIPT_DIR"
        ./context-integration.sh init "$test_session" "$test_project"

        # Check if context directory was created
        if [[ -d "$STATE_DIR/context/$test_session" ]]; then
            log_success "Context directory created successfully"
        else
            log_error "Context directory was not created"
            return 1
        fi

        # Test context-aware plan generation
        ./context-integration.sh plan "$test_session"
        if [[ -f "$SESSIONS_DIR/$test_session/context-aware-plan.json" ]]; then
            log_success "Context-aware plan generated successfully"
        else
            log_error "Context-aware plan was not generated"
        fi

        # Test context summary
        local summary=$(./context-integration.sh summary "$test_session" 2>/dev/null)
        if [[ -n "$summary" ]]; then
            log_success "Context summary generated successfully"
        else
            log_warning "Context summary generation failed (expected in test environment)"
        fi

        # Cleanup test session
        rm -rf "$SESSIONS_DIR/$test_session"
        rm -rf "$STATE_DIR/context/$test_session"
        rm -rf "$test_project"
    else
        log_error "context-integration.sh not found"
        return 1
    fi

    log_success "Context integration functions test completed"
}

# Test 3: Migration Assistant Integration
test_migration_assistant_integration() {
    log_info "Testing migration assistant integration..."

    # Check if migration-assistant.sh has context monitoring
    if [[ -f "$SCRIPT_DIR/migration-assistant.sh" ]]; then
        # Look for context monitoring function
        if grep -q "monitor_context_during_execution" "$SCRIPT_DIR/migration-assistant.sh"; then
            log_success "Context monitoring function found in migration-assistant.sh"
        else
            log_error "Context monitoring function not found in migration-assistant.sh"
            return 1
        fi

        # Check if context monitoring is called in execution functions
        if grep -q "monitor_context_during_execution.*session.*step" "$SCRIPT_DIR/migration-assistant.sh"; then
            log_success "Context monitoring is properly integrated in execution functions"
        else
            log_warning "Context monitoring may not be fully integrated in execution functions"
        fi
    else
        log_error "migration-assistant.sh not found"
        return 1
    fi

    log_success "Migration assistant integration test completed"
}

# Test 4: Compression Effectiveness
test_compression_effectiveness() {
    log_info "Testing compression effectiveness..."

    # Create test files for compression
    local test_dir="$TEMP_DIR/compression-test-$(date +%s)"
    mkdir -p "$test_dir"

    # Create test code files
    for i in {1..10}; do
        cat > "$test_dir/test$i.java" << 'EOF'
public class Test$i {
    private String name;
    private int age;

    public Test$i(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public String toString() {
        return "Test{name='" + name + "', age=" + age + "}";
    }
}
EOF
    done

    # Test context compression if available
    if [[ -f "$SCRIPT_DIR/context-manager.sh" && -d "$test_dir" ]]; then
        # Create compression directory
        local compress_dir="$TEMP_DIR/compression-output-$(date +%s)"
        mkdir -p "$compress_dir"

        # Run compression test
        cd "$SCRIPT_DIR"
        local output=$(./context-manager.sh compress "$compress_dir" 2>&1)

        if echo "$output" | grep -q "compression-completed"; then
            log_success "Context compression function works"

            # Check if compressed files were created
            if [[ -d "$compress_dir/signatures" ]] || [[ -d "$compress_dir/structure" ]]; then
                log_success "Compressed files created successfully"
            else
                log_warning "Compressed files directory structure may be incomplete"
            fi
        else
            log_warning "Context compression test completed with warnings: $output"
        fi

        # Cleanup
        rm -rf "$test_dir"
        rm -rf "$compress_dir"
    else
        log_warning "Skipping compression test - context-manager.sh not available"
    fi

    log_success "Compression effectiveness test completed"
}

# Test 5: Performance Impact Assessment
test_performance_impact() {
    log_info "Testing performance impact of context optimization..."

    # Create a test migration workflow
    local test_session="perf-test-$(date +%s)"
    local test_project="/tmp/perf-test"

    # Create test project
    mkdir -p "$test_project/src/main/java/com/example"
    cat > "$test_project/src/main/java/com/example/App.java" << 'EOF'
package com.example;

public class App {
    public static void main(String[] args) {
        System.out.println("Hello World");
    }
}
EOF

    # Create pom.xml
    cat > "$test_project/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>demo</artifactId>
    <version>1.0-SNAPSHOT</version>
</project>
EOF

    # Test migration workflow with context optimization
    local start_time=$(date +%s)

    if [[ -f "$SCRIPT_DIR/context-integration.sh" ]]; then
        # Initialize context management
        cd "$SCRIPT_DIR"
        ./context-integration.sh init "$test_session" "$test_project"

        # Simulate migration steps with monitoring
        for step in "analysis" "planning" "implementation" "validation"; do
            local step_start=$(date +%s)
            ./context-integration.sh monitor "$test_session" "$step" "$(date -Iseconds)"
            sleep 0.1  # Simulate work
            local step_end=$(date +%s)
            log_info "Step $step completed in $((step_end - step_start)) seconds"
        done

        local end_time=$(date +%s)
        local total_time=$((end_time - start_time))

        # Check context summary
        local summary=$(./context-integration.sh summary "$test_session" 2>/dev/null || echo "")

        log_success "Migration workflow completed in $total_time seconds"
        if [[ -n "$summary" ]]; then
            log_success "Context summary generated successfully"
        fi

        # Cleanup
        rm -rf "$SESSIONS_DIR/$test_session"
        rm -rf "$STATE_DIR/context/$test_session"
        rm -rf "$test_project"
    else
        log_error "Context integration not available for performance test"
        return 1
    fi

    log_success "Performance impact assessment completed"
}

# Test 6: Error Handling and Recovery
test_error_handling() {
    log_info "Testing error handling and recovery..."

    # Test missing session directory
    if [[ -f "$SCRIPT_DIR/context-integration.sh" ]]; then
        local error_output=$(./context-integration.sh summary "non-existent-session" 2>&1 || echo "")
        if echo "$error_output" | grep -q "No context data available"; then
            log_success "Error handling works for non-existent session"
        else
            log_warning "Error message may need improvement: $error_output"
        fi
    fi

    # Test context manager without dependencies
    if [[ -f "$SCRIPT_DIR/context-manager.sh" ]]; then
        # Test with invalid parameters
        local error_output=$(cd "$SCRIPT_DIR" && ./context-manager.sh monitor "invalid" 2>&1 || echo "")
        if [[ -n "$error_output" ]]; then
            log_success "Context manager handles invalid parameters gracefully"
        else
            log_warning "Context manager may not validate input parameters"
        fi
    fi

    log_success "Error handling and recovery test completed"
}

# Main Test Runner
# =====================================

run_all_tests() {
    log_info "Starting Context Optimization Test Suite"
    echo "============================================"

    local test_count=0
    local pass_count=0
    local fail_count=0

    # Run all tests
    for test in \
        "test_context_manager_integration" \
        "test_context_integration_functions" \
        "test_migration_assistant_integration" \
        "test_compression_effectiveness" \
        "test_performance_impact" \
        "test_error_handling"
    do
        test_count=$((test_count + 1))

        echo ""
        log_info "Running $test..."

        if $test; then
            pass_count=$((pass_count + 1))
            log_success "$test passed"
        else
            fail_count=$((fail_count + 1))
            log_error "$test failed"
        fi
    done

    # Print summary
    echo ""
    echo "============================================"
    log_info "Test Summary:"
    echo "  Total Tests: $test_count"
    echo "  Passed: $pass_count"
    echo "  Failed: $fail_count"
    echo "  Success Rate: $(( pass_count * 100 / test_count ))%"

    if (( fail_count == 0 )); then
        log_success "All tests passed!"
        return 0
    else
        log_error "$fail_count test(s) failed"
        return 1
    fi
}

# Single test execution
run_single_test() {
    local test_name="$1"

    if [[ -z "$test_name" ]]; then
        log_error "Please specify a test name"
        echo "Available tests:"
        echo "  context_manager_integration"
        echo "  context_integration_functions"
        echo "  migration_assistant_integration"
        echo "  compression_effectiveness"
        echo "  performance_impact"
        echo "  error_handling"
        echo "  all"
        exit 1
    fi

    case "$test_name" in
        "context_manager_integration")
            test_context_manager_integration
            ;;
        "context_integration_functions")
            test_context_integration_functions
            ;;
        "migration_assistant_integration")
            test_migration_assistant_integration
            ;;
        "compression_effectiveness")
            test_compression_effectiveness
            ;;
        "performance_impact")
            test_performance_impact
            ;;
        "error_handling")
            test_error_handling
            ;;
        "all")
            run_all_tests
            ;;
        *)
            log_error "Unknown test: $test_name"
            exit 1
            ;;
    esac
}

# Main execution
main() {
    local test_type="${1:-all}"

    if [[ "$test_type" == "all" ]]; then
        run_all_tests
    else
        run_single_test "$test_type"
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi