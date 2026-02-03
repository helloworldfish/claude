---
name: analyze
description: 对单体代码库进行全面分析，识别迁移机会
parameters:
  - name: project_path
    type: string
    description: 要分析的代码库路径
    required: true
  - name: analysis_type
    type: string
    description: 分析类型 - 'architecture'（架构）、'dependencies'（依赖）、'business-domains'（业务域）、'all'（全部）
    required: false
    default: "all"
  - name: output_format
    type: string
    description: 输出格式 - 'markdown'（Markdown）、'json'（JSON）、'html'（HTML）
    required: false
    default: "markdown"
  - name: depth
    type: integer
    description: 分析深度级别（1-5，数字越深越详细）
    required: false
    default: 3
examples:
  - "/analyze project_path=~/legacy-monolith"
  - "/analyze project_path=~/src analysis_type=architecture depth=4"
  - "/analyze project_path=~/myapp analysis_type=dependencies output_format=json"
---

# Legacy System Analysis Command

You are executing a comprehensive analysis of a monolithic codebase to understand its structure, dependencies, and migration opportunities.

## Analysis Process

### 1. Project Discovery and Validation
1. **Verify Project Access**
   - Check if the project path exists and is accessible
   - Identify project type, languages, and frameworks
   - Scan for build files and project structure
   - Validate that this is indeed a monolithic application

2. **Initial Project Scan**
   - Count total files and lines of code
   - Identify programming languages and their proportions
   - Detect build systems and dependency management
   - Map out the overall project structure

### 2. Analysis Execution (based on analysis_type)

#### When analysis_type='all' or 'architecture':
**Launch monolith-analyzer agent** with focus on:
- **Architecture Pattern Recognition**: Identify layered architecture, MVC patterns, etc.
- **Component Analysis**: Map out major components and their responsibilities
- **Technology Stack Analysis**: Identify frameworks, libraries, and platforms
- **Code Organization**: Analyze package structure and module organization
- **Design Pattern Detection**: Identify common design patterns and anti-patterns

#### When analysis_type='all' or 'dependencies':
**Launch dependency-mapper agent** with focus on:
- **Structural Dependencies**: Class inheritance, composition, imports
- **Data Dependencies**: Database schemas, shared data structures
- **External Dependencies**: Third-party integrations, API calls
- **Dependency Graph Generation**: Create visual dependency maps
- **Coupling Analysis**: Identify tight coupling points

#### When analysis_type='all' or 'business-domains':
**Launch monolith-analyzer agent** with focus on:
- **Business Capability Mapping**: Identify distinct business functions
- **Domain Boundary Analysis**: Find logical separation points
- **Data Ownership**: Analyze which components own which data
- **User Interaction Flows**: Map user journeys through the system
- **Business Process Analysis**: Understand business workflows

### 3. Analysis Depth Configuration

Based on the `depth` parameter (1-5):

#### Depth 1-2 (High-Level Analysis)
- Package/module level analysis
- Major component identification
- High-level dependency mapping
- Technology stack overview

#### Depth 3-4 (Detailed Analysis)
- Class-level dependency analysis
- Method call graph analysis
- Detailed architecture patterns
- Business domain identification

#### Depth 5 (Comprehensive Analysis)
- Method-level analysis
- Complex dependency mapping
- Performance bottleneck identification
- Code quality metrics

### 4. Output Generation

#### Standard Output Structure (for 'all' analysis):
```
analysis_output/
├── executive_summary.md
├── architecture_analysis/
│   ├── overview.md
│   ├── components.md
│   ├── patterns.md
│   └── technology_stack.md
├── dependency_analysis/
│   ├── dependency_graph.dot
│   ├── coupling_analysis.md
│   ├── circular_dependencies.md
│   └── external_integrations.md
├── business_domain_analysis/
│   ├── capabilities.md
│   ├── domain_boundaries.md
│   ├── user_journeys.md
│   └── data_ownership.md
├── recommendations/
│   ├── service_candidates.md
│   ├── migration_strategy.md
│   └── risk_assessment.md
└── artifacts/
    ├── metrics.json
    ├── visualizations/
    └── raw_data/
```

## Analysis Execution Steps

### Step 1: Project Discovery
```bash
# Example commands for project discovery
find {project_path} -name "*.java" -o -name "*.py" -o -name "*.js" | wc -l
find {project_path} -name "pom.xml" -o -name "package.json" -o -name "requirements.txt"
find {project_path} -type f -name "*.sql" | head -10
tree {project_path} -L 3 -d
```

### Step 2: Technology Stack Identification
Look for common indicators:
- **Java**: pom.xml, build.gradle, .java files
- **Python**: requirements.txt, setup.py, .py files
- **JavaScript/Node**: package.json, .js/.ts files
- **Databases**: .sql files, migrations folders
- **Frameworks**: Spring, Django, React, Angular imports

### Step 3: Architecture Analysis
Analyze code structure for patterns:
```markdown
## Architecture Analysis Checklist

### Package Structure
- [ ] Layered architecture (controller, service, repository)
- [ ] Domain-driven design patterns
- [ ] Modular organization
- [ ] Separation of concerns

### Design Patterns
- [ ] Singleton usage
- [ ] Factory patterns
- [ ] Observer patterns
- [ ] Strategy patterns
- [ ] Repository patterns

### Anti-Patterns
- [ ] God objects
- [ ] Spaghetti code
- [ ] Copy-paste programming
- [ ] Magic numbers/strings
- [ ] Long methods/classes
```

### Step 4: Dependency Analysis
Generate dependency information:
```bash
# Language-specific dependency analysis
# Java
mvn dependency:tree -DoutputFile=dependencies.txt

# Python
pipdeptree --json > dependencies.json

# JavaScript
npm ls --json > npm_dependencies.json

# General
find {project_path} -name "*.java" -exec grep -l "import" {} \; | head -20
```

### Step 5: Business Domain Mapping
Identify business capabilities:
```markdown
## Business Domain Analysis Framework

### User-Facing Features
- Customer management
- Order processing
- Product catalog
- Payment processing
- Reporting and analytics

### Internal Operations
- Inventory management
- User administration
- System configuration
- Audit and logging
- Data export/import

### Integration Points
- Third-party APIs
- Payment gateways
- Shipping providers
- Email services
- External databases
```

## Output Formats

### Markdown Output (default)
- Human-readable analysis reports
- Structured with headings and bullet points
- Includes code examples and diagrams
- Suitable for technical documentation

### JSON Output
- Machine-readable analysis data
- Structured format for programmatic processing
- Includes metrics and raw analysis data
- Suitable for integration with other tools

### HTML Output
- Interactive analysis reports
- Visual dependency graphs
- Expandable sections for detailed analysis
- Suitable for stakeholder presentations

## Analysis Validation

### Quality Checks
- [ ] Project is successfully scanned
- [ ] All specified analysis types completed
- [ ] Output files generated in correct format
- [ ] Analysis depth matches requested level
- [ ] No critical errors encountered

### Consistency Validation
- Cross-check dependency analysis with code structure
- Validate business domain mapping with actual functionality
- Ensure architecture analysis matches code organization
- Verify all major components are identified

## Example Analysis Results

### Executive Summary
```markdown
# Executive Summary

## Project Overview
- **Project Name**: Legacy Order Management System
- **Total LOC**: 145,000 lines of code
- **Primary Language**: Java (85%), JavaScript (10%), SQL (5%)
- **Architecture**: Layered monolith with some modularization
- **Build System**: Maven with Spring Boot

## Key Findings
1. **Clear Layer Separation**: Well-defined controller, service, repository layers
2. **Business Domain Grouping**: Some natural domain boundaries already exist
3. **Database Coupling**: High coupling through shared database schema
4. **External Dependencies**: Moderate third-party integrations
5. **Technical Debt**: Some long methods and classes need refactoring

## Migration Recommendations
- **Candidate Services**: User Management, Order Processing, Product Catalog
- **Migration Strategy**: Strangler Fig pattern recommended
- **Estimated Timeline**: 12-18 months
- **Risk Level**: Medium (well-structured codebase)
```

## Integration with Migration Workflow

This analysis command serves as the foundation for the complete migration process:
1. **Input to /migrate command**: Analysis results feed into migration planning
2. **Agent Coordination**: Identifies which agents need to be involved
3. **Scope Definition**: Helps define migration scope and approach
4. **Risk Assessment**: Provides initial risk evaluation
5. **Resource Planning**: Informs team and infrastructure requirements

You are providing the essential analysis capabilities that enable informed migration decision-making and planning.