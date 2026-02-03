---
name: migrate
description: 协调全面的旧系统迁移工作流程，从分析到实施
parameters:
  - name: scope
    type: string
    description: 迁移范围 - 'full'（完整）、'analysis'（分析）、'planning'（规划）、'implementation'（实施）
    required: true
  - name: target
    type: string
    description: 目标架构类型 - 'microservices'（微服务）、'modular'（模块化）、'cloud-native'（云原生）
    required: false
  - name: strategy
    type: string
    description: 迁移策略 - 'strangler-fig'（绞杀者模式）、'big-bang'（大爆炸模式）、'incremental'（增量模式）
    required: false
  - name: project_path
    type: string
    description: 要分析的旧代码库路径
    required: false
  - name: output_dir
    type: string
    description: 迁移输出和文档的目录
    required: false
examples:
  - "/migrate scope=analysis project_path=~/legacy-app"
  - "/migrate scope=full target=microservices strategy=strangler-fig project_path=~/monolith"
  - "/migrate scope=planning target=cloud-native"
---

# Legacy System Migration Workflow

You are orchestrating a comprehensive legacy system migration process. This command coordinates multiple specialized agents to analyze, plan, and guide the migration of large monolithic applications.

## Migration Workflow Process

### Phase 1: Initial Assessment & Scope Definition
1. **Validate Input Parameters**
   - Verify project path exists and is accessible
   - Confirm migration scope is appropriate for the codebase
   - Check if target architecture matches business requirements
   - Validate migration strategy feasibility

2. **Preliminary Analysis**
   - Quick scan of codebase structure and size
   - Identify languages, frameworks, and technologies
   - Estimate migration complexity and timeline
   - Set up output directory structure

### Phase 2: Comprehensive Analysis (if scope includes analysis)
Launch the **monolith-analyzer** agent to perform:
- Detailed architecture assessment
- Business domain mapping
- Service decomposition opportunity identification
- Database and dependency analysis
- Risk assessment and mitigation planning

**Expected Outputs from monolith-analyzer:**
- Complete analysis report
- Service candidate prioritization
- Dependency mapping
- Migration complexity assessment

### Phase 3: Architecture Design (if scope includes planning)
Based on analysis results, trigger the **migration-architect** agent to:
- Design target microservices architecture
- Define service boundaries and API contracts
- Plan infrastructure migration strategy
- Create data migration approach
- Design integration patterns

**Simultaneously trigger the **dependency-mapper** agent for:**
- Detailed dependency graph generation
- Circular dependency resolution
- Impact analysis for proposed changes
- Integration point mapping

### Phase 4: Implementation Guidance (if scope includes implementation)
Coordinate multiple agents for execution guidance:

**transformation-advisor** for:
- Code refactoring strategies
- Design pattern implementation
- Database transformation guidance
- Testing approach recommendations

**migration-planner** for:
- Detailed migration roadmap
- Timeline and milestone planning
- Resource allocation recommendations
- Rollback strategy development

**validation-engineer** for:
- Migration validation criteria
- Testing framework setup
- Performance benchmarking
- Business continuity verification

## Output Structure

Generate comprehensive migration documentation in the specified output directory:

```
output_dir/
├── 01-analysis/
│   ├── architecture-assessment.md
│   ├── service-candidates.md
│   ├── dependency-analysis.md
│   └── risk-assessment.md
├── 02-planning/
│   ├── target-architecture.md
│   ├── migration-roadmap.md
│   ├── infrastructure-plan.md
│   └── api-contracts.md
├── 03-implementation/
│   ├── transformation-guides/
│   ├── database-migration.md
│   ├── testing-strategy.md
│   └── validation-criteria.md
├── 04-automation/
│   ├── scripts/
│   ├── templates/
│   └── tools/
└── migration-summary.md
```

## Agent Coordination Logic

### Trigger Sequence
1. **Always start with monolith-analyzer** - This provides the foundation
2. **Trigger migration-architect and dependency-mapper in parallel** - They can work simultaneously once analysis is complete
3. **Sequentially trigger transformation-advisor, migration-planner, and validation-engineer** - These build on previous outputs

### Information Flow
- **monolith-analyzer → migration-architect**: Service boundaries, business domains, technical constraints
- **monolith-analyzer → dependency-mapper**: High-level dependencies, integration points
- **migration-architect → transformation-advisor**: Target architecture, service contracts
- **dependency-mapper → migration-planner**: Migration dependencies, sequence constraints
- **All agents → validation-engineer**: Validation requirements, success criteria

### Output Integration
Combine all agent outputs into a cohesive migration plan by:
- Cross-referencing recommendations
- Resolving conflicts between agents
- Creating unified timeline and roadmap
- Ensuring consistency across all deliverables

## Migration Strategy Specifics

### Strangler Fig Pattern
- **Best for**: Large, critical systems requiring minimal risk
- **Process**: Gradual replacement with feature toggles
- **Key Considerations**: API compatibility, data consistency, operational overhead
- **Timeline**: 6-24 months depending on system size

### Big Bang Migration
- **Best for**: Smaller systems or complete rewrites
- **Process**: Complete replacement with cutover period
- **Key Considerations**: Extensive testing, rollback procedures, business continuity
- **Timeline**: 3-12 months

### Incremental Migration
- **Best for**: Modular monoliths or systems with clear boundaries
- **Process**: Component-by-component migration with phased approach
- **Key Considerations**: Interface stability, data synchronization, testing complexity
- **Timeline**: 4-18 months

## Quality Gates

### Analysis Phase Completion Criteria
- [ ] Architecture assessment complete
- [ ] Service candidates identified and prioritized
- [ ] Dependencies mapped and analyzed
- [ ] Risk assessment documented
- [ ] Business impact analysis complete

### Planning Phase Completion Criteria
- [ ] Target architecture designed
- [ ] Migration roadmap created
- [ ] Resource requirements defined
- [ ] Success criteria established
- [ ] Rollback procedures documented

### Implementation Phase Completion Criteria
- [ ] Transformation guides created
- [ ] Testing strategy defined
- [ ] Validation criteria established
- [ ] Automation tools prepared
- [ ] Team training materials ready

## Error Handling

### Common Issues and Solutions
1. **Cannot access project path**
   - Verify directory exists and is readable
   - Check file permissions
   - Confirm path is correct

2. **Analysis fails due to complexity**
   - Break down into smaller components
   - Use sampling techniques for large codebases
   - Increase analysis timeout

3. **Agent coordination issues**
   - Verify agent outputs are complete
   - Check for conflicting recommendations
   - Ensure proper information flow between agents

4. **Migration strategy conflicts**
   - Reassess business requirements
   - Consider hybrid approaches
   - Update timeline and resource estimates

## Success Metrics

### Analysis Success
- Complete understanding of current architecture
- Clear identification of migration opportunities
- Accurate complexity assessment
- Actionable risk mitigation strategies

### Planning Success
- Realistic migration timeline
- Comprehensive resource planning
- Clear success criteria
- Proper risk mitigation

### Implementation Success
- Detailed transformation guides
- Automated tools and scripts
- Comprehensive testing approach
- Clear validation procedures

## Next Steps After Migration Command

1. **Review generated documentation** - Ensure all outputs meet requirements
2. **Stakeholder approval** - Get buy-in from business and technical teams
3. **Resource allocation** - Assign team members and set up infrastructure
4. **Begin implementation** - Follow the generated roadmap and guides
5. **Continuous monitoring** - Track progress against milestones and adjust as needed

This migration command provides the foundation for successful legacy system transformation by coordinating specialized agents and delivering comprehensive, actionable migration plans.