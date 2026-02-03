# Analyze Dependencies Command

## Description
Comprehensive dependency analysis command that visualizes code dependencies, identifies coupling issues, detects circular dependencies, and provides recommendations for improving code architecture and modularity.

## Usage

### Basic Syntax
```bash
/analyze-dependencies [options] [target]
```

### Examples

#### Basic Dependency Analysis
```bash
# Analyze dependencies for entire project
/analyze-dependencies

# Analyze specific package
/analyze-dependencies src/main/java/com/example/service/

# Analyze specific class
/analyze-dependencies src/main/java/com/example/service/UserService.java
```

#### Advanced Analysis
```bash
# Generate comprehensive dependency report
/analyze-dependencies \
  --comprehensive \
  --output-format json \
  --visualization \
  --target .

# Find circular dependencies
/analyze-dependencies \
  --circular-dependencies \
  --package-level \
  --target src/main/java/

# Analyze coupling metrics
/analyze-dependencies \
  --coupling-metrics \
  --threshold 0.7 \
  --architecture-violations
```

#### Visual Analysis
```bash
# Generate dependency graph
/analyze-dependencies \
  --graph \
  --output-file dependency-graph.png \
  --layout force-directed

# Layer architecture analysis
/analyze-dependencies \
  --layer-analysis \
  --layers "controller,service,repository,domain" \
  --check-violations

# Microservice boundary analysis
/analyze-dependencies \
  --service-boundaries \
  --suggest-extraction
```

## Analysis Types

### 1. Static Dependency Analysis
```java
// Example of dependency analysis results
Class: UserService
├── Direct Dependencies: 5
│   ├── UserRepository (interface)
│   ├── EmailService (interface)
│   ├── UserValidator (class)
│   ├── PasswordEncoder (interface)
│   └── UserMapper (class)
├── Indirect Dependencies: 12
│   ├── JpaRepository (through UserRepository)
│   ├── JavaMailSender (through EmailService)
│   └── BCryptPasswordEncoder (through PasswordEncoder)
└── Dependencies on this Class: 8
    ├── UserController
    ├── UserRegistrationController
    ├── AdminUserController
    └── ... (5 more)
```

### 2. Package Level Analysis
```
Package: com.example.service
├── Afferent Coupling (Ca): 15  (15 classes depend on this package)
├── Efferent Coupling (Ce): 8   (This package depends on 8 other packages)
├── Instability (I): 0.35        (Ce / (Ca + Ce))
├── Abstractness (A): 0.62       (Abstract classes / Total classes)
├── Distance from Main Sequence (DMS): 0.17
└── Status: STABLE (Good balance between stability and abstractness)

Package Dependencies:
├── Depends on:
│   ├── com.example.repository (3 classes)
│   ├── com.example.dto (2 classes)
│   ├── com.example.config (1 class)
│   ├── org.springframework.stereotype (2 classes)
│   └── java.util (0 classes - framework)
└── Used by:
    ├── com.example.controller (8 classes)
    ├── com.example.web (4 classes)
    └── com.example.batch (3 classes)
```

### 3. Circular Dependency Detection
```bash
# Circular Dependencies Found:
# ==================================
#
# 1. HIGH SEVERITY
#    Path: com.example.service -> com.example.util -> com.example.service
#    Details:
#    • UserService.java:45 uses StringUtils from com.example.util
#    • ValidationUtils.java:23 imports UserService for validation
#    • Impact: Compilation issues, testing complexity
#    • Solution: Extract validation interface from UserService
#
# 2. MEDIUM SEVERITY
#    Path: com.example.controller -> com.example.config -> com.example.controller
#    Details:
#    • UserController.java:15 uses WebConfig from com.example.config
#    • WebConfig.java:32 references UserController for URL mapping
#    • Impact: Configuration complexity, startup issues
#    • Solution: Move URL mapping to @RequestMapping annotations
```

### 4. Architecture Violations
```
Architecture Layer Analysis:
============================

Layer Definitions:
├── Controller Layer: com.example.controller.*
├── Service Layer: com.example.service.*
├── Repository Layer: com.example.repository.*
└── Domain Layer: com.example.domain.*

Violations Detected:
-------------------

1. Controller accessing Repository directly
   File: UserController.java:78
   Issue: Direct call to UserRepository.findById()
   Should: Call through UserService
   Impact: Bypasses business logic, reduced maintainability

2. Service accessing Controller
   File: NotificationService.java:45
   Issue: Direct instantiation of UserController
   Should: Use event-driven communication
   Impact: Tight coupling, test complexity

3. Domain Layer accessing Service
   File: User.java:89
   Issue: User entity calling EmailService
   Should: Move to service layer or use domain events
   Impact: Violates DDD principles, mixed responsibilities
```

## Command Options

### Analysis Scope
```bash
--target <path>                    # Target directory, package, or file
--recursive                        # Analyze subdirectories recursively
--include-tests                    # Include test dependencies in analysis
--exclude-framework                # Exclude framework dependencies (Spring, Java, etc.)
```

### Analysis Types
```bash
--static-analysis                  # Basic static dependency analysis
--dynamic-analysis                 # Runtime dependency analysis (requires instrumentation)
--transitive-dependencies          # Include transitive dependencies
--runtime-dependencies             # Analyze runtime-loaded dependencies
```

### Coupling Analysis
```bash
--coupling-metrics                # Calculate coupling metrics
--threshold <value>               # Threshold for high coupling warnings
--package-level                  # Analyze at package level
--class-level                    # Analyze at class level
```

### Circular Dependencies
```bash
--circular-dependencies           # Detect circular dependencies
--package-cycles                 # Detect package-level cycles
--class-cycles                   # Detect class-level cycles
--max-cycle-length <n>           # Maximum cycle length to detect
```

### Architecture Analysis
```bash
--layer-analysis                  # Analyze layered architecture
--layers <list>                   # Define layer packages (comma-separated)
--architecture-violations         # Check for architectural violations
--suggest-refactoring             # Suggest refactoring to fix violations
```

### Output Options
```bash
--output-format <format>          # Output format: json, yaml, csv, html
--output-file <path>              # Write output to file
--graph                           # Generate dependency graph
--graph-format <format>           # Graph format: png, svg, pdf, dot
--visualization                   # Generate interactive visualization
--summary                         # Generate executive summary
```

## Visualization Options

### Dependency Graph Generation
```bash
# Generate force-directed graph
/analyze-dependencies \
  --graph \
  --layout force-directed \
  --output-file dependency-graph.png \
  --node-size coupling \
  --edge-color dependency-type

# Generate hierarchical graph
/analyze-dependencies \
  --graph \
  --layout hierarchical \
  --group-by-package \
  --output-file architecture-hierarchy.svg

# Generate circular dependency diagram
/analyze-dependencies \
  --circular-dependencies \
  --graph \
  --layout circular \
  --highlight-cycles \
  --output-file circular-deps.pdf
```

### Interactive HTML Report
```html
<!DOCTYPE html>
<html>
<head>
    <title>Dependency Analysis Report</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
</head>
<body>
    <div id="dependency-graph"></div>
    <div id="metrics-dashboard"></div>
    <div id="violations-table"></div>

    <script>
        // Interactive dependency graph
        const container = document.getElementById('dependency-graph');
        const data = {
            nodes: [
                {id: 'UserService', label: 'UserService', group: 'service'},
                {id: 'UserRepository', label: 'UserRepository', group: 'repository'},
                {id: 'UserController', label: 'UserController', group: 'controller'},
                // ... more nodes
            ],
            edges: [
                {from: 'UserService', to: 'UserRepository', label: 'uses'},
                {from: 'UserController', to: 'UserService', label: 'calls'},
                // ... more edges
            ]
        };

        const options = {
            layout: {
                hierarchical: {
                    direction: 'UD',
                    sortMethod: 'directed'
                }
            },
            groups: {
                controller: {color: '#e74c3c'},
                service: {color: '#3498db'},
                repository: {color: '#2ecc71'},
                domain: {color: '#f39c12'}
            }
        };

        new vis.Network(container, data, options);
    </script>
</body>
</html>
```

## Output Examples

### JSON Analysis Report
```json
{
  "analysisMetadata": {
    "timestamp": "2023-12-22T10:30:00Z",
    "target": "/src/main/java/com/example/",
    "analysisType": "comprehensive",
    "version": "1.0.0"
  },
  "summary": {
    "totalClasses": 156,
    "totalPackages": 23,
    "totalDependencies": 892,
    "circularDependencies": 3,
    "architectureViolations": 7,
    "highCouplingClasses": 12
  },
  "couplingMetrics": {
    "averageAfferentCoupling": 5.7,
    "averageEfferentCoupling": 8.3,
    "averageInstability": 0.59,
    "classesAboveThreshold": 12
  },
  "circularDependencies": [
    {
      "severity": "HIGH",
      "path": ["com.example.service.UserService", "com.example.util.ValidationUtils", "com.example.service.UserService"],
      "description": "UserService depends on ValidationUtils which depends on UserService",
      "suggestedSolution": "Extract IValidationService interface from UserService"
    }
  ],
  "architectureViolations": [
    {
      "type": "LAYER_VIOLATION",
      "severity": "MEDIUM",
      "file": "UserController.java",
      "line": 78,
      "description": "Controller directly accessing repository",
      "recommendation": "Move repository access to service layer"
    }
  ],
  "refactoringRecommendations": [
    {
      "type": "EXTRACT_INTERFACE",
      "target": "UserService",
      "reason": "High afferent coupling (15 classes depend on this)",
      "impact": "MEDIUM",
      "estimatedEffort": "2-4 hours"
    },
    {
      "type": "BREAK_CIRCULAR_DEPENDENCY",
      "target": "UserService -> ValidationUtils",
      "reason": "Circular dependency causing compilation issues",
      "impact": "HIGH",
      "estimatedEffort": "1-2 days"
    }
  ]
}
```

### Markdown Summary Report
```markdown
# Dependency Analysis Report

## Executive Summary
- **Total Classes Analyzed**: 156
- **Total Dependencies**: 892
- **Circular Dependencies**: 3 ⚠️
- **Architecture Violations**: 7 ⚠️
- **High Coupling Classes**: 12 ⚠️

## Key Findings

### 🔴 High Priority Issues
1. **Circular Dependency** between UserService and ValidationUtils
   - **Impact**: Compilation issues, testing complexity
   - **Effort**: 1-2 days
   - **Solution**: Extract IValidationService interface

2. **Controller Direct Repository Access** in UserController
   - **Impact**: Bypassed business logic
   - **Effort**: 2-4 hours
   - **Solution**: Route through UserService

### 🟡 Medium Priority Issues
1. **High Coupling** in PaymentService (Affertent: 23, Efferent: 18)
2. **Package Instability** in com.example.util (I: 0.81)
3. **Mixed Responsibilities** in OrderService (validation + processing + notification)

## Metrics Overview

### Coupling Metrics Heatmap
| Package | Ca | Ce | Instability | Status |
|---------|----|----|-------------|--------|
| com.example.service | 15 | 8 | 0.35 | ✅ Stable |
| com.example.util | 23 | 18 | 0.44 | ⚠️ High Coupling |
| com.example.controller | 5 | 12 | 0.71 | ⚠️ Unstable |
| com.example.repository | 8 | 3 | 0.27 | ✅ Stable |

## Recommendations

### Immediate Actions (This Week)
1. Fix circular dependencies
2. Implement proper layered architecture
3. Extract interfaces for high coupling classes

### Short Term (This Month)
1. Implement dependency injection for all services
2. Separate concerns in complex classes
3. Add architectural tests to prevent violations

### Long Term (This Quarter)
1. Consider microservice extraction for tightly coupled modules
2. Implement domain-driven design principles
3. Add automated dependency analysis to CI/CD pipeline

## Generated Artifacts
- 📊 [dependency-graph.png](./dependency-graph.png)
- 📋 [full-analysis.json](./full-analysis.json)
- 🎯 [refactoring-plan.md](./refactoring-plan.md)
- 📹 [interactive-report.html](./interactive-report.html)
```

## Configuration Files

### Analysis Configuration
```yaml
# dependency-analysis.yml
analysis:
  scope:
    includeTests: false
    includeFramework: false
    recursive: true

  metrics:
    couplingThreshold: 0.7
    instabilityThreshold: 0.8
    maxCircularDependencies: 0

  layers:
    controller: "com.example.controller.*"
    service: "com.example.service.*"
    repository: "com.example.repository.*"
    domain: "com.example.domain.*"
    util: "com.example.util.*"

  visualization:
    layout: "hierarchical"
    groupByPackage: true
    colorByLayer: true
    nodeSize: "coupling"

  output:
    formats: ["json", "markdown", "html"]
    includeGraphs: true
    generateReport: true
```

### Custom Rules
```yaml
# custom-dependency-rules.yml
rules:
  - name: "no-controller-to-repository"
    description: "Controllers should not access repositories directly"
    from: "com.example.controller.*"
    to: "com.example.repository.*"
    severity: "HIGH"

  - name: "no-domain-to-service"
    description: "Domain entities should not depend on services"
    from: "com.example.domain.*"
    to: "com.example.service.*"
    severity: "MEDIUM"

  - name: "limit-util-dependencies"
    description: "Limit dependencies on utility classes"
    from: "com.example.service.*"
    to: "com.example.util.*"
    maxCount: 3
    severity: "LOW"
```

## Integration with CI/CD

### GitHub Actions
```yaml
# .github/workflows/dependency-analysis.yml
name: Dependency Analysis

on: [push, pull_request]

jobs:
  analyze-dependencies:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Java
        uses: actions/setup-java@v2
        with:
          java-version: '11'

      - name: Run Dependency Analysis
        run: |
          claude analyze-dependencies \
            --target src/main/java/ \
            --output-format json \
            --output-file dependency-report.json \
            --threshold 0.7

      - name: Check for Violations
        run: |
          violations=$(cat dependency-report.json | jq '.architectureViolations | length')
          if [ $violations -gt 0 ]; then
            echo "Found $violations architecture violations"
            exit 1
          fi

      - name: Upload Report
        uses: actions/upload-artifact@v2
        with:
          name: dependency-report
          path: dependency-report.json
```

### Automated Refactoring Suggestions
```java
@Component
public class DependencyAnalysisScheduler {

    @Scheduled(cron = "0 0 2 * * ?")  # Daily at 2 AM
    public void runNightlyAnalysis() {
        DependencyAnalysisResult result = dependencyAnalyzer.analyze(
            "src/main/java/",
            AnalysisConfig.defaultConfig()
        );

        if (result.hasHighPriorityIssues()) {
            notificationService.sendAlert(
                "High priority dependency issues detected",
                result.getSummary()
            );
        }

        analysisRepository.save(result);
    }
}
```