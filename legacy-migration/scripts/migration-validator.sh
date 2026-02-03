#!/bin/bash

# Migration Validator Script
# This script validates migration progress, functionality, and business continuity

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)/migration-validation}"
LEGACY_SYSTEM_URL="${LEGACY_SYSTEM_URL:-http://localhost:8080}"
NEW_SYSTEM_URL="${NEW_SYSTEM_URL:-http://localhost:8081}"
VALIDATION_TYPE="${VALIDATION_TYPE:-all}"  # all, functional, performance, data-consistency
TEST_SCOPE="${TEST_SCOPE:-sample}"  # sample, full, synthetic

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Create output directory
create_output_directory() {
    log_info "Creating output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"/{functional,performance,data-consistency,reports,logs}
}

# System health check
check_system_health() {
    log_info "Checking system health..."

    local legacy_status=0
    local new_status=0

    # Check legacy system
    if curl -s -f "$LEGACY_SYSTEM_URL/health" > /dev/null 2>&1; then
        log_success "Legacy system is healthy"
        legacy_status=1
    else
        log_error "Legacy system is not responding"
        legacy_status=0
    fi

    # Check new system
    if curl -s -f "$NEW_SYSTEM_URL/health" > /dev/null 2>&1; then
        log_success "New system is healthy"
        new_status=1
    else
        log_error "New system is not responding"
        new_status=0
    fi

    # Write health status to file
    cat > "$OUTPUT_DIR/logs/system-health.json" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "legacy_system": {
    "url": "$LEGACY_SYSTEM_URL",
    "healthy": $legacy_status
  },
  "new_system": {
    "url": "$NEW_SYSTEM_URL",
    "healthy": $new_status
  }
}
EOF

    # Return 0 if at least one system is healthy
    if [[ $legacy_status -eq 1 || $new_status -eq 1 ]]; then
        return 0
    else
        return 1
    fi
}

# Functional validation
validate_functionality() {
    log_info "Performing functional validation..."

    cat > "$OUTPUT_DIR/functional/api-validation.js" << 'EOF'
const axios = require('axios');

const LEGACY_URL = process.env.LEGACY_SYSTEM_URL || 'http://localhost:8080';
const NEW_URL = process.env.NEW_SYSTEM_URL || 'http://localhost:8081';

const testCases = [
    {
        name: 'Health Check',
        path: '/health',
        method: 'GET',
        expectedFields: ['status', 'timestamp']
    },
    {
        name: 'Get Users',
        path: '/api/users',
        method: 'GET',
        expectedFields: ['users', 'total']
    },
    {
        name: 'Get Orders',
        path: '/api/orders',
        method: 'GET',
        expectedFields: ['orders', 'pagination']
    },
    {
        name: 'Get Products',
        path: '/api/products',
        method: 'GET',
        expectedFields: ['products', 'categories']
    }
];

async function validateEndpoint(testCase) {
    console.log(`Testing: ${testCase.name}`);

    try {
        // Test legacy system
        const legacyResponse = await axios({
            method: testCase.method,
            url: `${LEGACY_URL}${testCase.path}`,
            timeout: 5000
        });

        // Test new system
        const newResponse = await axios({
            method: testCase.method,
            url: `${NEW_URL}${testCase.path}`,
            timeout: 5000
        });

        // Validate response structure
        const legacyStructure = validateStructure(legacyResponse.data, testCase.expectedFields);
        const newStructure = validateStructure(newResponse.data, testCase.expectedFields);

        // Compare responses
        const comparison = compareResponses(legacyResponse.data, newResponse.data);

        return {
            name: testCase.name,
            legacyStatus: legacyResponse.status,
            newStatus: newResponse.status,
            legacyStructureValid: legacyStructure,
            newStructureValid: newStructure,
            responsesMatch: comparison.match,
            differences: comparison.differences,
            legacyResponseTime: legacyResponse.headers['x-response-time'] || 'N/A',
            newResponseTime: newResponse.headers['x-response-time'] || 'N/A'
        };

    } catch (error) {
        return {
            name: testCase.name,
            error: error.message,
            legacyStatus: error.response?.status || 'ERROR',
            newStatus: error.response?.status || 'ERROR'
        };
    }
}

function validateStructure(data, expectedFields) {
    const missingFields = expectedFields.filter(field => !(field in data));
    return missingFields.length === 0;
}

function compareResponses(legacyData, newData) {
    const differences = [];

    // Simple comparison - this can be enhanced based on specific requirements
    const keys = new Set([...Object.keys(legacyData), ...Object.keys(newData)]);

    for (const key of keys) {
        const legacyValue = legacyData[key];
        const newValue = newData[key];

        if (JSON.stringify(legacyValue) !== JSON.stringify(newValue)) {
            differences.push({
                field: key,
                legacy: legacyValue,
                new: newValue
            });
        }
    }

    return {
        match: differences.length === 0,
        differences: differences
    };
}

async function runFunctionalValidation() {
    const results = [];

    for (const testCase of testCases) {
        const result = await validateEndpoint(testCase);
        results.push(result);
        console.log(`✓ ${testCase.name}: ${result.error ? 'FAILED' : 'PASSED'}`);
    }

    return results;
}

if (require.main === module) {
    runFunctionalValidation()
        .then(results => {
            console.log(JSON.stringify(results, null, 2));
        })
        .catch(error => {
            console.error('Validation failed:', error);
            process.exit(1);
        });
}

module.exports = { runFunctionalValidation };
EOF

    # Run functional validation if Node.js is available
    if command -v node &> /dev/null; then
        cd "$OUTPUT_DIR/functional"
        LEGACY_SYSTEM_URL="$LEGACY_SYSTEM_URL" NEW_SYSTEM_URL="$NEW_SYSTEM_URL" \
        node api-validation.js > "$OUTPUT_DIR/functional/functional-results.json"

        # Generate summary
        python3 << EOF > "$OUTPUT_DIR/functional/functional-summary.json"
import json

with open('$OUTPUT_DIR/functional/functional-results.json', 'r') as f:
    results = json.load(f)

total_tests = len(results)
passed_tests = len([r for r in results if not r.get('error')])
failed_tests = total_tests - passed_tests

summary = {
    'total_tests': total_tests,
    'passed_tests': passed_tests,
    'failed_tests': failed_tests,
    'success_rate': (passed_tests / total_tests * 100) if total_tests > 0 else 0,
    'test_results': results
}

print(json.dumps(summary, indent=2))
EOF

        log_success "Functional validation completed"
    else
        log_warning "Node.js not found. Skipping functional validation."
    fi
}

# Performance validation
validate_performance() {
    log_info "Performing performance validation..."

    cat > "$OUTPUT_DIR/performance/performance-test.sh" << 'EOF'
#!/bin/bash

LEGACY_URL=${LEGACY_SYSTEM_URL:-http://localhost:8080}
NEW_URL=${NEW_SYSTEM_URL:-http://localhost:8081}
RESULTS_FILE=${1:-"$OUTPUT_DIR/performance/performance-results.json"}

# Test endpoints
ENDPOINTS=(
    "/api/users"
    "/api/orders"
    "/api/products"
)

# Test parameters
CONCURRENT_USERS=10
REQUESTS_PER_USER=50
TIMEOUT=10

echo "Running performance tests..."
echo "Legacy System: $LEGACY_URL"
echo "New System: $NEW_URL"
echo "Concurrent Users: $CONCURRENT_USERS"
echo "Requests per User: $REQUESTS_PER_USER"

# Initialize results
echo '{"timestamp":"'$(date -Iseconds)'","tests":[]}' > "$RESULTS_FILE"

for endpoint in "${ENDPOINTS[@]}"; do
    echo "Testing endpoint: $endpoint"

    # Test legacy system
    echo "  Testing legacy system..."
    legacy_result=$(ab -n $((CONCURRENT_USERS * REQUESTS_PER_USER)) \
                        -c $CONCURRENT_USERS \
                        -t $TIMEOUT \
                        "$LEGACY_URL$endpoint" 2>/dev/null | \
        grep -E "(Requests per second|Time per request|Failed requests)" || \
        echo "Legacy system test failed")

    # Test new system
    echo "  Testing new system..."
    new_result=$(ab -n $((CONCURRENT_USERS * REQUESTS_PER_USER)) \
                   -c $CONCURRENT_USERS \
                   -t $TIMEOUT \
                   "$NEW_URL$endpoint" 2>/dev/null | \
        grep -E "(Requests per second|Time per request|Failed requests)" || \
        echo "New system test failed")

    # Parse results (simplified parsing)
    legacy_rps=$(echo "$legacy_result" | grep "Requests per second" | awk '{print $4}' || echo "0")
    legacy_time=$(echo "$legacy_result" | grep "Time per request" | awk '{print $4}' || echo "0")
    legacy_failed=$(echo "$legacy_result" | grep "Failed requests" | awk '{print $3}' || echo "0")

    new_rps=$(echo "$new_result" | grep "Requests per second" | awk '{print $4}' || echo "0")
    new_time=$(echo "$new_result" | grep "Time per request" | awk '{print $4}' || echo "0")
    new_failed=$(echo "$new_result" | grep "Failed requests" | awk '{print $3}' || echo "0")

    # Calculate performance difference
    if (( $(echo "$legacy_rps > 0" | bc -l) )); then
        rps_improvement=$(echo "scale=2; (($new_rps - $legacy_rps) / $legacy_rps) * 100" | bc)
    else
        rps_improvement="N/A"
    fi

    if (( $(echo "$legacy_time > 0" | bc -l) )); then
        time_improvement=$(echo "scale=2; (($legacy_time - $new_time) / $legacy_time) * 100" | bc)
    else
        time_improvement="N/A"
    fi

    # Save results
    jq --arg endpoint "$endpoint" \
       --arg legacy_rps "$legacy_rps" \
       --arg legacy_time "$legacy_time" \
       --arg legacy_failed "$legacy_failed" \
       --arg new_rps "$new_rps" \
       --arg new_time "$new_time" \
       --arg new_failed "$new_failed" \
       --arg rps_improvement "$rps_improvement" \
       --arg time_improvement "$time_improvement" \
       '.tests += [{
         "endpoint": $endpoint,
         "legacy": {
           "rps": ($legacy_rps | tonumber),
           "avg_response_time": ($legacy_time | tonumber),
           "failed_requests": ($legacy_failed | tonumber)
         },
         "new": {
           "rps": ($new_rps | tonumber),
           "avg_response_time": ($new_time | tonumber),
           "failed_requests": ($new_failed | tonumber)
         },
         "improvements": {
           "rps_improvement_percent": ($rps_improvement | tonumber? // "N/A"),
           "response_time_improvement_percent": ($time_improvement | tonumber? // "N/A")
         }
       }]' "$RESULTS_FILE" > "$RESULTS_FILE.tmp" && mv "$RESULTS_FILE.tmp" "$RESULTS_FILE"

    echo "  Legacy: ${legacy_rps} RPS, ${legacy_time}ms avg, ${legacy_failed} failed"
    echo "  New: ${new_rps} RPS, ${new_time}ms avg, ${new_failed} failed"
    echo "  Improvement: ${rps_improvement}% RPS, ${time_improvement}% response time"
    echo ""
done

echo "Performance tests completed. Results saved to $RESULTS_FILE"
EOF

    chmod +x "$OUTPUT_DIR/performance/performance-test.sh"

    # Check if Apache Bench (ab) is available
    if command -v ab &> /dev/null; then
        cd "$OUTPUT_DIR/performance"
        ./performance-test.sh

        # Generate performance summary
        python3 << EOF > "$OUTPUT_DIR/performance/performance-summary.json"
import json

with open('$OUTPUT_DIR/performance/performance-results.json', 'r') as f:
    data = json.load(f)

tests = data.get('tests', [])
total_tests = len(tests)

if total_tests > 0:
    avg_rps_improvement = sum(test.get('improvements', {}).get('rps_improvement_percent', 0) or 0 for test in tests if isinstance(test.get('improvements', {}).get('rps_improvement_percent'), (int, float))) / total_tests

    avg_time_improvement = sum(test.get('improvements', {}).get('response_time_improvement_percent', 0) or 0 for test in tests if isinstance(test.get('improvements', {}).get('response_time_improvement_percent'), (int, float))) / total_tests

    better_performance = len([t for t in tests if t.get('improvements', {}).get('rps_improvement_percent', 0) > 0 or t.get('improvements', {}).get('response_time_improvement_percent', 0) > 0])
else:
    avg_rps_improvement = 0
    avg_time_improvement = 0
    better_performance = 0

summary = {
    'total_endpoints_tested': total_tests,
    'endpoints_with_better_performance': better_performance,
    'average_rps_improvement_percent': avg_rps_improvement,
    'average_response_time_improvement_percent': avg_time_improvement,
    'performance_grade': 'A' if avg_rps_improvement > 10 and avg_time_improvement > 10 else 'B' if avg_rps_improvement > 0 and avg_time_improvement > 0 else 'C',
    'tests': tests
}

print(json.dumps(summary, indent=2))
EOF

        log_success "Performance validation completed"
    else
        log_warning "Apache Bench (ab) not found. Install Apache Bench for performance testing."
        log_warning "On Ubuntu/Debian: sudo apt-get install apache2-utils"
        log_warning "On macOS: brew install apache2"
    fi
}

# Data consistency validation
validate_data_consistency() {
    log_info "Performing data consistency validation..."

    cat > "$OUTPUT_DIR/data-consistency/data-consistency-checker.py" << 'EOF'
import os
import json
import requests
from datetime import datetime, timedelta
import sys

class DataConsistencyValidator:
    def __init__(self, legacy_url, new_url):
        self.legacy_url = legacy_url
        self.new_url = new_url
        self.results = {
            'timestamp': datetime.now().isoformat(),
            'checks': []
        }

    def check_order_consistency(self):
        """Check order data consistency between legacy and new systems"""
        try:
            # Get orders from both systems
            legacy_response = requests.get(f"{self.legacy_url}/api/orders", timeout=10)
            new_response = requests.get(f"{self.new_url}/api/orders", timeout=10)

            if legacy_response.status_code == 200 and new_response.status_code == 200:
                legacy_orders = legacy_response.json().get('orders', [])
                new_orders = new_response.json().get('orders', [])

                # Compare order counts
                result = {
                    'check_name': 'order_consistency',
                    'legacy_order_count': len(legacy_orders),
                    'new_order_count': len(new_orders),
                    'count_difference': abs(len(legacy_orders) - len(new_orders)),
                    'count_match': len(legacy_orders) == len(new_orders)
                }

                # Sample comparison of specific orders
                sample_size = min(5, len(legacy_orders))
                if sample_size > 0:
                    legacy_sample = legacy_orders[:sample_size]
                    matched_orders = 0

                    for legacy_order in legacy_sample:
                        order_id = legacy_order.get('id')
                        if order_id:
                            # Try to find matching order in new system
                            new_order = next((o for o in new_orders if o.get('id') == order_id), None)
                            if new_order:
                                # Compare key fields
                                fields_to_compare = ['customer_id', 'total_amount', 'status']
                                field_matches = []

                                for field in fields_to_compare:
                                    if str(legacy_order.get(field, '')) == str(new_order.get(field, '')):
                                        field_matches.append(field)

                                if len(field_matches) == len(fields_to_compare):
                                    matched_orders += 1

                    result['sample_size'] = sample_size
                    result['matched_sample_orders'] = matched_orders
                    result['sample_match_rate'] = matched_orders / sample_size

                self.results['checks'].append(result)

        except Exception as e:
            self.results['checks'].append({
                'check_name': 'order_consistency',
                'error': str(e)
            })

    def check_user_consistency(self):
        """Check user data consistency between legacy and new systems"""
        try:
            legacy_response = requests.get(f"{self.legacy_url}/api/users", timeout=10)
            new_response = requests.get(f"{self.new_url}/api/users", timeout=10)

            if legacy_response.status_code == 200 and new_response.status_code == 200:
                legacy_users = legacy_response.json().get('users', [])
                new_users = new_response.json().get('users', [])

                result = {
                    'check_name': 'user_consistency',
                    'legacy_user_count': len(legacy_users),
                    'new_user_count': len(new_users),
                    'count_difference': abs(len(legacy_users) - len(new_users)),
                    'count_match': len(legacy_users) == len(new_users)
                }

                self.results['checks'].append(result)

        except Exception as e:
            self.results['checks'].append({
                'check_name': 'user_consistency',
                'error': str(e)
            })

    def check_product_consistency(self):
        """Check product data consistency between legacy and new systems"""
        try:
            legacy_response = requests.get(f"{self.legacy_url}/api/products", timeout=10)
            new_response = requests.get(f"{self.new_url}/api/products", timeout=10)

            if legacy_response.status_code == 200 and new_response.status_code == 200:
                legacy_products = legacy_response.json().get('products', [])
                new_products = new_response.json().get('products', [])

                result = {
                    'check_name': 'product_consistency',
                    'legacy_product_count': len(legacy_products),
                    'new_product_count': len(new_products),
                    'count_difference': abs(len(legacy_products) - len(new_products)),
                    'count_match': len(legacy_products) == len(new_products)
                }

                self.results['checks'].append(result)

        except Exception as e:
            self.results['checks'].append({
                'check_name': 'product_consistency',
                'error': str(e)
            })

    def run_all_checks(self):
        """Run all consistency checks"""
        self.check_order_consistency()
        self.check_user_consistency()
        self.check_product_consistency()

        # Calculate overall consistency score
        total_checks = len(self.results['checks'])
        passed_checks = len([c for c in self.results['checks'] if c.get('count_match', False)])

        self.results['overall_score'] = {
            'total_checks': total_checks,
            'passed_checks': passed_checks,
            'consistency_percentage': (passed_checks / total_checks * 100) if total_checks > 0 else 0,
            'status': 'PASS' if passed_checks == total_checks else 'FAIL'
        }

        return self.results

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: python data-consistency-checker.py <legacy-url> <new-url>')
        sys.exit(1)

    legacy_url = sys.argv[1]
    new_url = sys.argv[2]

    validator = DataConsistencyValidator(legacy_url, new_url)
    results = validator.run_all_checks()
    print(json.dumps(results, indent=2))
EOF

    # Run data consistency checks
    cd "$OUTPUT_DIR/data-consistency"
    python3 data-consistency-checker.py "$LEGACY_SYSTEM_URL" "$NEW_SYSTEM_URL" \
        > "$OUTPUT_DIR/data-consistency/consistency-results.json"

    log_success "Data consistency validation completed"
}

# Generate comprehensive validation report
generate_validation_report() {
    log_info "Generating validation report..."

    cat > "$OUTPUT_DIR/reports/validation-summary.md" << EOF
# Migration Validation Report

Generated on: $(date)
Legacy System: $LEGACY_SYSTEM_URL
New System: $NEW_SYSTEM_URL
Validation Type: $VALIDATION_TYPE
Test Scope: $TEST_SCOPE

## Executive Summary

EOF

    # Add system health status
    if [[ -f "$OUTPUT_DIR/logs/system-health.json" ]]; then
        echo "### System Health Status" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "\`\`\`json" >> "$OUTPUT_DIR/reports/validation-summary.md"
        cat "$OUTPUT_DIR/logs/system-health.json" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "\`\`\`" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "" >> "$OUTPUT_DIR/reports/validation-summary.md"
    fi

    # Add functional validation results
    if [[ -f "$OUTPUT_DIR/functional/functional-summary.json" ]]; then
        echo "### Functional Validation" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "\`\`\`json" >> "$OUTPUT_DIR/reports/validation-summary.md"
        cat "$OUTPUT_DIR/functional/functional-summary.json" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "\`\`\`" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "" >> "$OUTPUT_DIR/reports/validation-summary.md"
    fi

    # Add performance validation results
    if [[ -f "$OUTPUT_DIR/performance/performance-summary.json" ]]; then
        echo "### Performance Validation" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "\`\`\`json" >> "$OUTPUT_DIR/reports/validation-summary.md"
        cat "$OUTPUT_DIR/performance/performance-summary.json" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "\`\`\`" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "" >> "$OUTPUT_DIR/reports/validation-summary.md"
    fi

    # Add data consistency results
    if [[ -f "$OUTPUT_DIR/data-consistency/consistency-results.json" ]]; then
        echo "### Data Consistency Validation" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "\`\`\`json" >> "$OUTPUT_DIR/data-consistency/consistency-results.json" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "\`\`\`" >> "$OUTPUT_DIR/reports/validation-summary.md"
        echo "" >> "$OUTPUT_DIR/reports/validation-summary.md"
    fi

    cat >> "$OUTPUT_DIR/reports/validation-summary.md" << 'EOF'
## Validation Results Summary

### Success Criteria
- **Functional Tests**: 100% pass rate required
- **Performance**: New system should perform equal to or better than legacy
- **Data Consistency**: 100% consistency required
- **System Health**: Both systems should be operational

### Recommendations

#### If All Validations Pass
- ✓ Migration is ready for production deployment
- ✓ Monitor systems closely after deployment
- ✓ Prepare rollback procedures

#### If Validations Fail
- ⚠ Address critical issues before deployment
- ⚠ Review failed test cases and fix underlying problems
- ⚠ Re-run validation after fixes

#### Next Steps
1. Review detailed validation results
2. Address any identified issues
3. Update migration plan based on findings
4. Schedule production deployment

## Generated Files
EOF

    # List generated files
    find "$OUTPUT_DIR" -name "*.json" -o -name "*.log" | while read -r file; do
        relative_path=$(basename "$file")
        echo "- \`$relative_path\`" >> "$OUTPUT_DIR/reports/validation-summary.md"
    done

    log_success "Validation report generated at $OUTPUT_DIR/reports/validation-summary.md"
}

# Main execution
main() {
    log_info "Starting migration validation"
    log_info "Legacy system URL: $LEGACY_SYSTEM_URL"
    log_info "New system URL: $NEW_SYSTEM_URL"
    log_info "Validation type: $VALIDATION_TYPE"
    log_info "Output directory: $OUTPUT_DIR"

    # Create output directory
    create_output_directory

    # Check system health
    if ! check_system_health; then
        log_error "System health check failed. At least one system must be operational."
        exit 1
    fi

    # Run validation based on type
    case "$VALIDATION_TYPE" in
        "functional")
            validate_functionality
            ;;
        "performance")
            validate_performance
            ;;
        "data-consistency")
            validate_data_consistency
            ;;
        "all")
            validate_functionality
            validate_performance
            validate_data_consistency
            ;;
        *)
            log_warning "Unknown validation type: $VALIDATION_TYPE. Running all validations."
            validate_functionality
            validate_performance
            validate_data_consistency
            ;;
    esac

    # Generate comprehensive report
    generate_validation_report

    log_success "Migration validation completed!"
    log_info "Results saved in: $OUTPUT_DIR"
    log_info "View the main report: $OUTPUT_DIR/reports/validation-summary.md"
}

# Run main function
main "$@"