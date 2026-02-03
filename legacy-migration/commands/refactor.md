# 重构命令

## 描述
综合自动化重构命令，协调各种重构操作，包括代码分析、模式应用、微服务提取和基于规则的转换。

## 使用方法

### 基本语法
```bash
/refactor [options] [target] [operation]
```

### Examples

#### Quick Refactoring
```bash
# Analyze and apply basic refactorings to current directory
/refactor

# Refactor specific file
/refactor src/main/java/com/example/ UserService.java

# Refactor entire package
/refactor src/main/java/com/example/service/
```

#### Pattern-Based Refactoring
```bash
# Apply specific design pattern
/refactor --pattern strategy --target PaymentService.java

# Apply multiple patterns
/refactor --patterns "strategy,factory,repository" --target .

# Auto-detect and apply patterns
/refactor --detect-patterns --target .
```

#### Rule-Based Refactoring
```bash
# Apply custom refactoring rules
/refactor --rules ./refactoring-rules.yml --target .

# Apply specific rule
/refactor --rule "extract-service-layer" --target controller/

# Interactive rule application
/refactor --interactive --rules all --target .
```

#### Microservice Extraction
```bash
# Extract microservice from monolith
/refactor --extract-service UserManagement --bounded-context user

# Full microservice analysis and extraction
/refactor --microservice-analysis --output-dir extracted-services/

# Gradual service extraction with migration plan
/refactor --extract-service OrderProcessing --migration-plan --incremental
```

## Command Options

### Target Specification
```bash
--target <path>           # Target file, directory, or package
--exclude <pattern>       # Exclude files matching pattern
--include <pattern>       # Include only files matching pattern
--recursive               # Process subdirectories recursively
```

### Analysis Options
```bash
--analyze                 # Only analyze, don't apply changes
--depth <level>           # Analysis depth (1-5)
--metrics                 # Include quality metrics in output
--report <format>         # Generate report (json, yaml, markdown)
```

### Pattern Application
```bash
--pattern <name>          # Apply specific design pattern
--patterns <list>         # Apply multiple patterns (comma-separated)
--detect-patterns         # Auto-detect pattern opportunities
--pattern-config <file>   # Pattern configuration file
```

### Rule-Based Refactoring
```bash
--rules <path>            # Apply rules from file
--rule <name>             # Apply specific rule
--interactive             # Interactive mode for rule selection
--dry-run                 # Preview changes without applying
```

### Microservice Extraction
```bash
--extract-service <name>  # Extract named microservice
--bounded-context <name>  # Use bounded context for extraction
--migration-plan          # Generate migration plan
--incremental             # Enable incremental migration
--output-dir <path>       # Output directory for extracted services
```

### Safety Options
```bash
--backup                  # Create backup before refactoring
--test-after              # Run tests after each refactoring
--validate                # Validate refactoring results
--rollback-on-failure     # Rollback changes if validation fails
```

## Configuration Files

### refactoring-config.yml
```yaml
# Global refactoring configuration
refactoring:
  backup:
    enabled: true
    directory: ".refactoring-backup/"
    retentionDays: 30

  validation:
    compileCheck: true
    testExecution: true
    qualityGates: true
    performanceTest: false

  patterns:
    autoDetect: true
    applyAutomatically: false
    requireConfirmation: true

  rules:
    defaultPath: ".claude/refactoring-rules/"
    enabled:
      - "extract-service-layer"
      - "replace-magic-numbers"
      - "fix-naming-conventions"
    disabled:
      - "major-restructuring"

  output:
    format: "markdown"
    includeMetrics: true
    generateDiff: true
    createSummary: true
```

### service-extraction-config.yml
```yaml
# Microservice extraction configuration
extraction:
  boundedContexts:
    UserManagement:
      includes:
        - "com.example.service.user.*"
        - "com.example.repository.user.*"
      excludes:
        - "*Test.java"
      outputDirectory: "extracted-services/user-service/"
      databaseSeparation: true
      apiGeneration: true

    OrderProcessing:
      includes:
        - "com.example.service.order.*"
        - "com.example.service.payment.*"
      outputDirectory: "extracted-services/order-service/"
      databaseSeparation: true
      eventDriven: true

  apiGeneration:
    style: "rest"  # rest, graphql, grpc
    includeDocs: true
    addValidation: true
    generateTests: true

  databaseStrategy:
    separateSchema: true
    migrationScripts: true
    dataValidation: true

  deployment:
    generateDockerfile: true
    kubernetes: false
    helmChart: false
```

## Output Examples

### Refactoring Summary Report
```markdown
# Refactoring Summary Report

## Overview
- **Target**: src/main/java/com/example/
- **Duration**: 2m 34s
- **Files Processed**: 45
- **Refactorings Applied**: 12

## Applied Refactorings

### Design Patterns
1. **Strategy Pattern** - PaymentService.java
   - **Location**: src/main/java/com/example/service/PaymentService.java:45-78
   - **Change**: Extracted payment processing strategies (CreditCardPaymentStrategy, PayPalPaymentStrategy)
   - **Impact**: Medium - Improved extensibility and maintainability

2. **Factory Pattern** - NotificationService.java
   - **Location**: src/main/java/com/example/service/NotificationService.java:23-34
   - **Change**: Created NotificationFactory for different notification types
   - **Impact**: Low - Better separation of concerns

### Code Quality
1. **Extract Method** - OrderService.processOrder()
   - **Method Length**: 45 lines → 12 lines
   - **Cyclomatic Complexity**: 15 → 6
   - **Extracted Methods**: validateOrder(), calculateTotal(), sendConfirmation()

2. **Extract Constants** - UserService.java
   - **Replaced Magic Numbers**: 3.14159 → PI, 299792458 → SPEED_OF_LIGHT
   - **Generated Constants**: 2
   - **Impact**: Low - Improved code readability

### Microservice Extraction
1. **User Management Service**
   - **Extracted Components**: 8 classes, 2 repositories
   - **Generated API**: 5 REST endpoints
   - **Database**: Separate schema created
   - **Tests**: 12 unit tests generated

## Quality Metrics

### Before vs After
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Cyclomatic Complexity | 8.5 | 5.2 | 38% ↓ |
| Method Lines | 28 | 16 | 43% ↓ |
| Test Coverage | 65% | 78% | 20% ↑ |
| Code Duplication | 12% | 8% | 33% ↓ |

### Technical Debt Reduction
- **Total Debt Points**: 450 → 320
- **Reduction**: 130 points (29%)
- **High Priority Issues**: 8 → 3

## Generated Files
```
refactoring-output/
├── reports/
│   ├── refactoring-summary.md
│   ├── quality-metrics.json
│   └── dependency-graph.png
├── generated/
│   ├── UserManagementService/
│   │   ├── src/main/java/
│   │   ├── Dockerfile
│   │   └── pom.xml
│   └── refactor-backups/
└── scripts/
    ├── rollback.sh
    └── validate-refactoring.sh
```

## Recommendations

### Immediate Actions
1. **Review Extracted Services**: Validate microservice boundaries make sense
2. **Update Documentation**: Update API documentation with new services
3. **Integration Testing**: Run comprehensive integration tests

### Future Improvements
1. **Implement Caching**: Consider caching for frequently accessed data
2. **Add Monitoring**: Implement application performance monitoring
3. **Service Discovery**: Set up service discovery infrastructure

## Next Steps
1. Deploy extracted services to staging environment
2. Configure API Gateway for routing
3. Implement gradual traffic migration
4. Monitor performance and adjust as needed
```

## Error Handling

### Common Issues and Solutions

#### Compilation Errors
```bash
# If refactoring causes compilation errors
/refactor --rollback --target <failed-target>

# Or fix manually and re-run validation
/refactor --validate-only --target <target>
```

#### Test Failures
```bash
# Run tests in debug mode to see detailed failure information
/refactor --test-after --debug --target <target>

# Skip problematic tests temporarily
/refactor --test-after --exclude-tests "*IntegrationTest" --target <target>
```

#### Performance Issues
```bash
# Limit analysis depth for large codebases
/refactor --depth 2 --target <large-target>

# Process files in batches
/refactor --batch-size 10 --target <target>
```

## Advanced Usage

### Custom Rule Integration
```bash
# Apply custom business rules
/refactor --custom-rules ./business-rules/ --target .

# Combine with machine learning recommendations
/refactor --ml-recommendations --confidence 0.8 --target .
```

### Team Collaboration
```bash
# Generate refactoring proposal for team review
/refactor --proposal --team-review --target .

# Apply only approved refactorings
/refactor --apply-approved ./approved-refactorings.json --target .
```

### CI/CD Integration
```bash
# Refactoring in CI pipeline
/refactor --ci-mode --fail-on-error --generate-report --target .

# Pull request refactoring suggestions
/refactor --pr-suggestions --base-branch main --target .
```