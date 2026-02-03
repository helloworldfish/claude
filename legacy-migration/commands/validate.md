---
name: validate
description: 验证迁移进度、功能，并确保在整个迁移过程中的业务连续性
parameters:
  - name: validation_type
    type: string
    description: 验证类型 - 'functional'（功能）、'performance'（性能）、'data-consistency'（数据一致性）、'business-continuity'（业务连续性）、'all'（全部）
    required: false
    default: "all"
  - name: migration_phase
    type: string
    description: 当前迁移阶段 - 'analysis'（分析）、'planning'（规划）、'implementation'（实施）、'post-migration'（迁移后）
    required: false
    default: "implementation"
  - name: target_system
    type: string
    description: 要验证的目标系统 - URL 或服务标识符
    required: false
    default: "auto"
  - name: baseline_system
    type: string
    description: 用于比较的基线/旧系统 URL
    required: false
    default: "auto"
  - name: test_data_scope
    type: string
    description: Test data scope - 'sample', 'full', 'synthetic'
    required: false
    default: "sample"
examples:
  - "/validate validation_type=all migration_phase=implementation"
  - "/validate validation_type=performance target_system=https://new-api.example.com"
  - "/validate validation_type=data-consistency test_data_scope=full"
---

# Migration Validation Command

You are executing comprehensive validation procedures to ensure migration quality, functionality preservation, and business continuity throughout the legacy system transformation process.

## Validation Process

### 1. Validation Context Setup

#### Phase-Specific Validation
Based on `migration_phase` parameter:

##### Analysis Phase Validation
- Verify analysis completeness and accuracy
- Validate that all migration opportunities are identified
- Check dependency analysis coverage
- Ensure risk assessment comprehensiveness

##### Planning Phase Validation
- Validate migration plan feasibility
- Check resource allocation realism
- Verify timeline achievability
- Ensure risk mitigation strategies are adequate

##### Implementation Phase Validation (Default)
- Comprehensive functional and performance validation
- Data consistency and integrity verification
- Business continuity monitoring
- Security and compliance validation

##### Post-Migration Validation
- Complete system equivalence verification
- Performance benchmarking and optimization
- Business value realization assessment
- Legacy system decommissioning validation

### 2. System Discovery and Configuration

#### Automatic System Detection (when target_system='auto')
1. **Discover Running Services**
   - Scan for active microservices
   - Identify API endpoints and interfaces
   - Detect database connections and schemas
   - Map service dependencies and communications

2. **Baseline System Identification**
   - Locate legacy system endpoints
   - Identify database connections
   - Map current system architecture
   - Establish comparison baselines

### 3. Validation Execution by Type

#### validation_type='functional' or 'all'

Launch validation-engineer agent for functional testing:

```markdown
## Functional Validation Framework

### Core Functionality Testing
1. **API Equivalence Testing**
   - Compare request/response between legacy and new systems
   - Validate error handling consistency
   - Check authentication and authorization behavior
   - Verify business rule implementation

2. **User Journey Testing**
   - End-to-end user workflow validation
   - Cross-service transaction testing
   - Edge case and error condition testing
   - User interface consistency validation

3. **Integration Testing**
   - External service connectivity validation
   - Database operation consistency
   - Message queue functionality
   - File processing and batch jobs

### Test Data Strategy
Based on `test_data_scope` parameter:

#### Sample Data (Default)
- Use representative subset of production data
- Focus on common use cases and edge cases
- Ensure privacy and compliance requirements
- Quick validation execution

#### Full Data
- Use complete production data set
- Comprehensive validation coverage
- Longer execution time
- Higher resource requirements

#### Synthetic Data
- Generated test data covering all scenarios
- Privacy-safe approach
- Controlled test conditions
- Faster execution cycles
```

#### validation_type='performance' or 'all'

```markdown
## Performance Validation Framework

### Response Time Validation
1. **API Response Time Comparison**
   - Compare response times between systems
   - Analyze percentile performance (50th, 95th, 99th)
   - Validate under different load conditions
   - Monitor degradation over time

2. **Throughput Testing**
   - Concurrent request handling capacity
   - Peak load performance validation
   - Sustained load testing
   - Resource utilization analysis

3. **Scalability Assessment**
   - Horizontal scaling validation
   - Auto-scaling behavior testing
   - Resource efficiency measurement
   - Performance under failure conditions

### Performance Benchmarks
```bash
# Example performance validation script
#!/bin/bash

echo "Starting performance validation..."

# Configuration
LEGACY_URL="https://legacy-api.example.com"
NEW_URL="https://new-api.example.com"
CONCURRENT_USERS=100
TEST_DURATION=300 # 5 minutes

# Test scenarios
SCENARIOS=(
    "GET /api/orders"
    "POST /api/orders"
    "GET /api/customers"
    "PUT /api/customers/{id}"
    "GET /api/products"
)

for scenario in "${SCENARIOS[@]}"; do
    echo "Testing scenario: $scenario"

    # Test legacy system
    echo "Testing legacy system..."
    legacy_result=$(hey -n 1000 -c $CONCURRENT_USERS -z ${TEST_DURATION}s \
        -m GET -H "Authorization: Bearer $LEGACY_TOKEN" \
        "$LEGACY_URL$scenario" | grep "Response time")

    # Test new system
    echo "Testing new system..."
    new_result=$(hey -n 1000 -c $CONCURRENT_USERS -z ${TEST_DURATION}s \
        -m GET -H "Authorization: Bearer $NEW_TOKEN" \
        "$NEW_URL$scenario" | grep "Response time")

    # Compare results
    echo "Legacy: $legacy_result"
    echo "New: $new_result"

    # Alert if performance degradation > 20%
    if performance_degradation > 20%; then
        send_alert "Performance degradation detected: $scenario"
    fi
done
```

#### validation_type='data-consistency' or 'all'

```markdown
## Data Consistency Validation Framework

### Real-time Consistency Checking
1. **Data Synchronization Validation**
   - Compare data between legacy and new systems
   - Validate data format and type consistency
   - Check referential integrity maintenance
   - Monitor data replication lag

2. **Business Rule Validation**
   - Validate business logic consistency
   - Check calculation accuracy
   - Verify constraint enforcement
   - Validate trigger and workflow behavior

3. **Audit Trail Verification**
   - Compare audit logs between systems
   - Validate operation sequencing
   - Check user action attribution
   - Verify compliance record completeness

### Data Consistency Scripts
```sql
-- Data consistency validation queries
-- Compare order data between legacy and new systems

-- Check order count consistency
SELECT
    'order_count_validation' as check_type,
    COUNT(*) as legacy_count,
    (SELECT COUNT(*) FROM new_service.orders) as new_count,
    ABS(COUNT(*) - (SELECT COUNT(*) FROM new_service.orders)) as difference,
    CASE
        WHEN COUNT(*) = (SELECT COUNT(*) FROM new_service.orders)
        THEN 'PASS'
        ELSE 'FAIL'
    END as validation_result
FROM legacy.orders
WHERE created_at >= CURRENT_DATE;

-- Check financial data consistency
SELECT
    'financial_consistency' as check_type,
    COALESCE(SUM(total_amount), 0) as legacy_total,
    (SELECT COALESCE(SUM(total_amount), 0) FROM new_service.orders) as new_total,
    ABS(COALESCE(SUM(total_amount), 0) - (SELECT COALESCE(SUM(total_amount), 0) FROM new_service.orders)) as difference,
    CASE
        WHEN ABS(COALESCE(SUM(total_amount), 0) - (SELECT COALESCE(SUM(total_amount), 0) FROM new_service.orders)) < 0.01
        THEN 'PASS'
        ELSE 'FAIL'
    END as validation_result
FROM legacy.orders
WHERE created_at >= CURRENT_DATE;
```

#### validation_type='business-continuity' or 'all'

```markdown
## Business Continuity Validation Framework

### Critical Function Monitoring
1. **Revenue-Generating Functions**
   - Order processing validation
   - Payment transaction verification
   - Inventory management checks
   - Customer service operations

2. **Customer Experience Metrics**
   - Response time measurements
   - Error rate tracking
   - User journey completion rates
   - Customer satisfaction monitoring

3. **Operational Readiness**
   - Monitoring and alerting validation
   - Backup and recovery testing
   - Disaster recovery verification
   - Support procedure validation

### Business Impact Monitoring
```javascript
// Business continuity monitoring dashboard
const businessMonitor = {
    validateOrderProcessing: async () => {
        const now = new Date();
        const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000);

        // Check order processing rate
        const recentOrders = await orderRepository.count({
            created_at: { $gte: fiveMinutesAgo }
        });

        const expectedRate = 10; // orders per minute
        const actualRate = recentOrders / 5;

        const healthy = actualRate >= expectedRate * 0.8;

        if (!healthy) {
            await alertManager.sendCriticalAlert(
                'Order processing rate below threshold',
                { expected: expectedRate, actual: actualRate }
            );
        }

        return {
            expected: expectedRate,
            actual: actualRate,
            healthy,
            status: healthy ? 'PASS' : 'FAIL'
        };
    },

    validatePaymentProcessing: async () => {
        const recentPayments = await paymentRepository.findRecent(300);
        const successRate = recentPayments.filter(p => p.status === 'success').length / recentPayments.length;

        const healthy = successRate >= 0.95; // 95% success rate threshold

        if (!healthy) {
            await alertManager.sendCriticalAlert(
                'Payment success rate below threshold',
                { successRate: successRate, threshold: 0.95 }
            );
        }

        return {
            successRate,
            healthy,
            status: healthy ? 'PASS' : 'FAIL'
        };
    }
};
```

### 4. Automated Validation Pipeline

#### Continuous Validation Framework
```yaml
# Continuous validation pipeline configuration
name: Migration Validation Pipeline

on:
  push:
    branches: [ migration/* ]
  schedule:
    - cron: '*/15 * * * *' # Every 15 minutes during migration

jobs:
  functional-validation:
    runs-on: ubuntu-latest
    steps:
      - name: API Equivalence Testing
        run: |
          ./scripts/api-equivalence-tests.sh
      - name: User Journey Testing
        run: |
          ./scripts/user-journey-tests.sh
      - name: Integration Testing
        run: |
          ./scripts/integration-tests.sh

  performance-validation:
    runs-on: ubuntu-latest
    steps:
      - name: Response Time Validation
        run: |
          ./scripts/performance-validation.sh
      - name: Load Testing
        run: |
          ./scripts/load-testing.sh

  data-consistency-check:
    runs-on: ubuntu-latest
    steps:
      - name: Data Consistency Validation
        run: |
          ./scripts/data-consistency-validation.sh
      - name: Business Rule Validation
        run: |
          ./scripts/business-rule-validation.sh

  business-continuity-test:
    runs-on: ubuntu-latest
    steps:
      - name: Critical Function Monitoring
        run: |
          ./scripts/critical-function-monitoring.sh
      - name: Business Metrics Validation
        run: |
          ./scripts/business-metrics-validation.sh
```

### 5. Validation Results and Reporting

#### Validation Dashboard
```markdown
# Migration Validation Dashboard

## Overall Validation Status: [PASS/FAIL/WARNING]

### Functional Validation
- API Equivalence: [PASS/FAIL]
- User Journeys: [PASS/FAIL]
- Integration Testing: [PASS/FAIL]

### Performance Validation
- Response Times: [PASS/FAIL/WARNING]
- Throughput: [PASS/FAIL]
- Scalability: [PASS/FAIL]

### Data Consistency
- Data Synchronization: [PASS/FAIL]
- Business Rules: [PASS/FAIL]
- Audit Trails: [PASS/FAIL]

### Business Continuity
- Order Processing: [PASS/FAIL]
- Payment Processing: [PASS/FAIL]
- Customer Experience: [PASS/FAIL]

### Critical Issues
[List any critical validation failures that require immediate attention]

### Recommendations
[Actionable recommendations based on validation results]
```

#### Detailed Validation Report
```
validation_results/
├── executive_summary.md
├── functional_validation/
│   ├── api_equivalence_results.md
│   ├── user_journey_results.md
│   ├── integration_test_results.md
│   └── functional_coverage_report.md
├── performance_validation/
│   ├── response_time_analysis.md
│   ├── throughput_benchmarks.md
│   ├── scalability_assessment.md
│   └── performance_regression_report.md
├── data_consistency/
│   ├── data_synchronization_report.md
│   ├── business_rule_validation.md
│   ├── audit_trail_comparison.md
│   └── data_quality_metrics.md
├── business_continuity/
│   ├── critical_function_status.md
│   ├── business_metrics_dashboard.md
│   ├── customer_experience_report.md
│   └── operational_readiness_assessment.md
└── artifacts/
    ├── validation_logs/
    ├── performance_charts/
    ├── test_data_samples/
    └── monitoring_screenshots/
```

### 6. Success Criteria and Quality Gates

#### Validation Thresholds
```markdown
## Validation Success Criteria

### Functional Validation Thresholds
- API Equivalence: 100% response compatibility
- User Journey Success Rate: ≥ 99%
- Integration Test Pass Rate: 100%
- Error Rate: ≤ 0.1%

### Performance Validation Thresholds
- Response Time: ≤ 110% of baseline (≤ 10% degradation)
- Throughput: ≥ 90% of baseline
- 95th Percentile Response Time: ≤ 200ms
- Resource Utilization: ≤ 80% of capacity

### Data Consistency Thresholds
- Data Synchronization: 100% consistency
- Business Rule Accuracy: 100%
- Audit Trail Completeness: 100%
- Data Quality Score: ≥ 99%

### Business Continuity Thresholds
- Order Processing Rate: ≥ 90% of expected
- Payment Success Rate: ≥ 99%
- Customer Satisfaction: No degradation
- System Availability: ≥ 99.9%
```

### Quality Gates
```markdown
## Migration Quality Gates

### Gate 1: Functional Equivalence
- [ ] All API responses match baseline system
- [ ] All user journeys complete successfully
- [ ] All integration tests pass
- [ ] Error handling behaves consistently

### Gate 2: Performance Standards
- [ ] Response times within acceptable limits
- [ ] Throughput meets business requirements
- [ ] System scales under load
- [ ] Resource utilization is efficient

### Gate 3: Data Integrity
- [ ] Data synchronization is complete
- [ ] Business calculations are accurate
- [ ] Audit trails are consistent
- [ ] Data quality meets standards

### Gate 4: Business Continuity
- [ ] Critical business functions operate normally
- [ ] Customer experience is maintained
- [ ] Revenue-generating processes work
- [ ] Support procedures are effective
```

### 7. Alerting and Escalation

#### Automated Alerting
```markdown
## Validation Alerting Framework

### Alert Severity Levels
1. **Critical**: Business impact, requires immediate action
2. **High**: Significant deviation, action required within 1 hour
3. **Medium**: Minor issues, action required within 4 hours
4. **Low**: Informational, action required within 24 hours

### Alert Conditions
- Functional test failures > 5%
- Performance degradation > 20%
- Data inconsistency detected
- Business function failure
- System availability < 99%

### Escalation Procedures
1. **Level 1**: Automated alerts to on-call engineer
2. **Level 2**: Escalate to migration team lead
3. **Level 3**: Escalate to migration architect
4. **Level 4**: Escalate to project stakeholders
```

## Integration with Migration Workflow

### Continuous Validation Loop
1. **Execute validation tests** based on migration phase
2. **Analyze results** against success criteria
3. **Generate alerts** for threshold violations
4. **Report findings** to migration team
5. **Recommend actions** for issue resolution
6. **Validate fixes** and close the loop

### Migration Decision Support
- Provide objective data for go/no-go decisions
- Identify risks before they impact business
- Ensure migration quality standards are met
- Support rollback decisions when necessary

You are ensuring migration success by providing comprehensive validation that guarantees business continuity, data integrity, and system reliability throughout the transformation process.