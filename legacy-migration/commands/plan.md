---
name: plan
description: 基于分析结果创建详细的迁移计划、时间表和路线图
parameters:
  - name: analysis_results
    type: string
    description: 之前分析结果的路径或使用 'auto' 先运行分析
    required: false
    default: "auto"
  - name: migration_strategy
    type: string
    description: 迁移策略 - 'strangler-fig'（绞杀者模式）、'big-bang'（大爆炸模式）、'incremental'（增量模式）
    required: false
    default: "strangler-fig"
  - name: timeline_months
    type: integer
    description: 目标迁移时间表（月）
    required: false
    default: 12
  - name: team_size
    type: integer
    description: 迁移团队规模
    required: false
    default: 8
  - name: business_priority
    type: string
    description: 业务优先级重点 - 'speed'（速度）、'cost'（成本）、'risk-minimization'（风险最小化）
    required: false
    default: "risk-minimization"
examples:
  - "/plan analysis_results=~/analysis-output timeline_months=18"
  - "/plan migration_strategy=incremental team_size=10 business_priority=speed"
  - "/plan analysis_results=auto migration_strategy=strangler-fig"
---

# Migration Planning Command

You are creating a comprehensive migration plan that translates analysis results into actionable migration roadmaps, timelines, and resource requirements.

## Planning Process

### 1. Input Validation and Analysis

#### When analysis_results='auto':
1. **Execute Analysis Phase**
   - Run comprehensive codebase analysis
   - Identify migration opportunities and challenges
   - Generate initial assessment reports
   - Estimate system complexity and migration effort

#### When analysis_results is a path:
1. **Load Existing Analysis**
   - Verify analysis results are complete and valid
   - Cross-check analysis depth and coverage
   - Validate that key migration insights are available
   - Check for any missing or incomplete analysis areas

### 2. Strategy Selection and Customization

Based on `migration_strategy` parameter:

#### Strangler Fig Strategy (Default)
- **Best for**: Large, critical systems requiring minimal risk
- **Process**: Gradual replacement using feature flags and routing
- **Timeline**: Typically 12-24 months
- **Risk Profile**: Low risk, high control
- **Resource Requirements**: Moderate to high

```markdown
## Strangler Fig Implementation Plan

### Phase Structure
1. **Anticorruption Layer Setup** (Weeks 1-4)
   - Create API gateway
   - Implement routing logic
   - Set up feature flag system
   - Create monitoring framework

2. **Service Extraction Phases** (Weeks 5-48)
   - Extract services based on business value and complexity
   - Gradual traffic migration
   - Continuous integration and testing
   - Legacy system integration maintenance

3. **Legacy Decommissioning** (Weeks 49-52)
   - Final data migration
   - Legacy system shutdown
   - Post-migration optimization
   - Documentation and knowledge transfer
```

#### Big Bang Strategy
- **Best for**: Smaller systems or complete rewrites
- **Process**: Complete replacement with cutover
- **Timeline**: Typically 6-12 months
- **Risk Profile**: High risk, fast delivery
- **Resource Requirements**: High

```markdown
## Big Bang Implementation Plan

### Phase Structure
1. **Complete Parallel Development** (Weeks 1-20)
   - Full new system development
   - Comprehensive testing
   - Data migration tools
   - Performance optimization

2. **Cutover Preparation** (Weeks 21-24)
   - Final testing and validation
   - Data synchronization
   - Rollback procedures
   - Team readiness

3. **Cutover Execution** (Weekend)
   - Final data migration
   - System switchover
   - Intensive monitoring
   - Rapid issue resolution
```

#### Incremental Strategy
- **Best for**: Systems with clear modular boundaries
- **Process**: Component-by-component migration
- **Timeline**: Typically 9-18 months
- **Risk Profile**: Medium risk, balanced approach
- **Resource Requirements**: Moderate

### 3. Timeline Planning

Based on `timeline_months` and `team_size`:

#### Resource Capacity Calculation
```markdown
## Team Capacity Planning

### Available Development Hours
- Team Members: {team_size} people
- Working Hours: 160 hours/person/month
- Available Hours: {team_size * 160} hours/month
- Productive Hours (80%): {team_size * 160 * 0.8} hours/month
- Story Point Capacity: ~{team_size * 40} points/month

### Time Allocation
- Development Work: 70%
- Testing and Validation: 15%
- Infrastructure and Tooling: 10%
- Communication and Planning: 5%
```

#### Phase Duration Calculation
```markdown
## Phase Duration Estimation

### Foundation Phase (20% of timeline)
- Duration: {timeline_months * 0.2} months
- Activities: Infrastructure setup, team training, tooling
- Resource Allocation: 40% of team capacity

### Core Migration Phase (60% of timeline)
- Duration: {timeline_months * 0.6} months
- Activities: Service extraction, data migration, testing
- Resource Allocation: 100% of team capacity

### Finalization Phase (20% of timeline)
- Duration: {timeline_months * 0.2} months
- Activities: Legacy decommissioning, optimization, documentation
- Resource Allocation: 60% of team capacity
```

### 4. Business Priority Optimization

Based on `business_priority`:

#### Speed Priority
- **Approach**: Parallel development, aggressive timelines
- **Trade-offs**: Higher risk, increased resource requirements
- **Optimization**: Focus on quick wins and critical path activities

```markdown
## Speed-Optimized Timeline

### Acceleration Strategies
1. **Parallel Development Tracks**
   - Multiple services developed simultaneously
   - Separate teams for different domains
   - Increased coordination overhead

2. **Tool and Process Automation**
   - Automated testing and deployment
   - Code generation and scaffolding
   - Infrastructure as code

3. **External Resources**
   - Contract developers for specific domains
   - Consulting for specialized knowledge
   - Managed services for infrastructure
```

#### Cost Priority
- **Approach**: Lean team, extended timeline, phased investment
- **Trade-offs**: Longer timeline, increased opportunity cost
- **Optimization**: Minimize external resources, use existing infrastructure

#### Risk Minimization Priority
- **Approach**: Conservative timeline, extensive testing, gradual migration
- **Trade-offs**: Longer timeline, higher initial investment
- **Optimization**: Comprehensive validation, rollback capabilities, extensive monitoring

### 5. Service Prioritization Matrix

Create service migration order based on:
- **Business Value**: Impact on business objectives
- **Technical Complexity**: Implementation difficulty
- **Dependency Analysis**: Prerequisites and impacts
- **Risk Assessment**: Migration risk levels

```markdown
## Service Migration Priority Matrix

### High Priority (First 25% of timeline)
1. **Authentication and Authorization**
   - Business Value: High (foundational)
   - Complexity: Low
   - Dependencies: None
   - Risk: Low

2. **Configuration Management**
   - Business Value: High (enabling)
   - Complexity: Low
   - Dependencies: Authentication
   - Risk: Low

### Medium Priority (Next 50% of timeline)
3. **User Profile Management**
   - Business Value: Medium-High
   - Complexity: Medium
   - Dependencies: Authentication
   - Risk: Medium

4. **Order Processing**
   - Business Value: High
   - Complexity: High
   - Dependencies: User Management, Products
   - Risk: High

### Low Priority (Final 25% of timeline)
5. **Legacy Reporting**
   - Business Value: Medium
   - Complexity: High
   - Dependencies: All business services
   - Risk: Medium
```

### 6. Resource Planning

#### Team Structure
```markdown
## Migration Team Organization

### Core Team ({team_size} members)

#### Leadership (2-3 members)
- **Migration Architect**: Technical leadership, architecture decisions
- **Project Manager**: Timeline, resources, stakeholder communication
- **QA Lead**: Testing strategy, quality assurance

#### Development Team ({team_size - 3} members)
- **Service Developers**: 60-70% of team
- **DevOps Engineers**: 15-20% of team
- **Database Specialists**: 10-15% of team
- **UI/Frontend Developers**: 10-15% of team (if needed)

### Extended Team (as needed)
- **Security Specialists**: Security review and implementation
- **Business Analysts**: Business rule validation
- **UX Designers**: User experience consistency
- **External Consultants**: Specialized knowledge transfer
```

#### Infrastructure Requirements
```yaml
# Infrastructure Resource Plan
infrastructure_needs:
  development:
    kubernetes_clusters: 2
    database_instances: 3
    storage_gb: 500
    monthly_cost: "$2,000"

  staging:
    kubernetes_clusters: 1
    database_instances: 2
    storage_gb: 300
    monthly_cost: "$1,500"

  production:
    kubernetes_clusters: 2
    database_instances: 4
    storage_gb: 1000
    monthly_cost: "$4,000"

  tools_and_services:
    cicd_platform: "$500/month"
    monitoring_tools: "$300/month"
    security_tools: "$200/month"
    backup_services: "$150/month"
```

### 7. Risk Management Planning

#### Risk Identification and Mitigation
```markdown
## Migration Risk Management

### Technical Risks
1. **Data Migration Failures**
   - Probability: Medium
   - Impact: High
   - Mitigation: Comprehensive testing, rollback procedures
   - Monitoring: Real-time data consistency checks

2. **Performance Degradation**
   - Probability: Medium
   - Impact: High
   - Impact: High
   - Mitigation: Load testing, performance monitoring
   - Monitoring: Continuous performance benchmarks

### Business Risks
1. **Business Disruption**
   - Probability: Low
   - Impact: Critical
   - Mitigation: Gradual migration, feature flags
   - Monitoring: Business metrics tracking

2. **Budget Overruns**
   - Probability: Medium
   - Impact: Medium
   - Mitigation: Regular budget reviews, scope control
   - Monitoring: Weekly cost tracking

### Team Risks
1. **Knowledge Loss**
   - Probability: Medium
   - Impact: Medium
   - Mitigation: Documentation, knowledge sharing
   - Monitoring: Team skill assessments
```

## Output Deliverables

### Migration Plan Structure
```
migration_plan/
├── executive_summary.md
├── detailed_roadmap/
│   ├── phases_and_milestones.md
│   ├── service_migration_order.md
│   └── timeline_and_dependencies.md
├── resource_plan/
│   ├── team_structure.md
│   ├── budget_allocation.md
│   └── infrastructure_requirements.md
├── risk_management/
│   ├── risk_register.md
│   ├── mitigation_strategies.md
│   └── contingency_plans.md
├── success_metrics/
│   ├── kpis_and_measurements.md
│   ├── quality_gates.md
│   └── validation_criteria.md
└── artifacts/
    ├── gantt_chart.pdf
    ├── dependency_graph.png
    └── resource_allocation.xlsx
```

### Executive Summary Example
```markdown
# Migration Plan Executive Summary

## Project Overview
- **System**: Legacy Order Management Platform
- **Migration Strategy**: Strangler Fig Pattern
- **Timeline**: {timeline_months} months
- **Team Size**: {team_size} members
- **Estimated Budget**: $2.5M

## Key Milestones
1. **Foundation Phase Complete**: Month 3
2. **Core Services Migrated**: Month 9
3. **80% Functionality Migrated**: Month {timeline_months - 2}
4. **Full Migration Complete**: Month {timeline_months}

## Business Benefits
- **Scalability**: 10x improvement in capacity
- **Development Velocity**: 3x faster feature delivery
- **Reliability**: 99.9% uptime target
- **Cost Reduction**: 40% operational savings

## Risk Profile
- **Overall Risk Level**: Medium
- **Primary Concerns**: Data migration complexity, business continuity
- **Mitigation Approach**: Gradual migration with comprehensive testing

## Resource Requirements
- **Development Team**: {team_size} members
- **Infrastructure**: $8,000/month peak
- **External Services**: $1,200/month
- **Training and Tools**: $50,000 one-time
```

## Integration with Migration Workflow

### Input to /migrate Command
The migration plan provides:
- Detailed timeline and milestones
- Resource allocation and budget
- Risk mitigation strategies
- Success criteria and KPIs
- Team structure and training needs

### Execution Framework
- Clear phase boundaries and completion criteria
- Defined handoffs between migration phases
- Established governance and decision processes
- Built-in quality gates and validation points

You are creating the strategic framework that guides the entire migration process from analysis to successful completion.