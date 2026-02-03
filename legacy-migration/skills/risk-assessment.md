---
name: risk-assessment
description: 旧系统迁移项目的风险评估和缓解策略
level: expert
prerequisites:
- 风险管理经验
- 企业架构知识
- 项目管理专业知识
outputs:
  - 风险识别报告
  - 风险量化矩阵
  - 缓解策略
  - 应急计划
---

# 迁移风险评估技能

本技能提供全面的风险评估方法、识别框架和缓解策略，专门针对旧系统迁移项目量身定制。

## 风险评估框架

### 1. Risk Identification Categories

#### Technical Risks
```markdown
## Technical Risk Categories

### Architecture and Design Risks
1. **Service Boundary Misidentification**
   - **Description**: Incorrect identification of service boundaries leading to poor decomposition
   - **Probability**: Medium
   - **Impact**: High
   - **Indicators**: Complex inter-service dependencies, frequent cross-service calls
   - **Detection Methods**: Dependency analysis, business domain mapping

2. **Data Migration Failures**
   - **Description**: Data loss, corruption, or inconsistency during migration
   - **Probability**: Medium
   - **Impact**: Critical
   - **Indicators**: Complex data transformations, large data volumes
   - **Detection Methods**: Data profiling, migration dry-runs

3. **Performance Degradation**
   - **Description**: System performance worse after migration
   - **Probability**: High
   - **Impact**: High
   - **Indicators**: Increased response times, reduced throughput
   - **Detection Methods**: Load testing, performance benchmarking

4. **Integration Complexity**
   - **Description**: Unexpected complexity in system integration
   - **Probability**: High
   - **Impact**: Medium
   - **Indicators**: Multiple external dependencies, complex protocols
   - **Detection Methods**: Interface analysis, dependency mapping

### Infrastructure and Operations Risks
1. **Deployment Automation Failures**
   - **Description**: CI/CD pipeline failures causing deployment issues
   - **Probability**: Medium
   - **Impact**: Medium
   - **Indicators**: Manual deployment steps, complex environment setup
   - **Detection Methods**: Pipeline analysis, deployment rehearsals

2. **Monitoring Gaps**
   - **Description**: Insufficient monitoring leading to undetected issues
   - **Probability**: High
   - **Impact**: Medium
   - **Indicators**: Limited observability, manual health checks
   - **Detection Methods**: Monitoring audit, incident analysis

3. **Scaling Issues**
   - **Description**: Inability to scale services effectively
   - **Probability**: Medium
   - **Impact**: High
   - **Indicators**: Resource constraints, performance bottlenecks
   - **Detection Methods**: Capacity planning, stress testing
```

#### Business Risks
```markdown
## Business Risk Categories

### Business Continuity Risks
1. **Revenue Impact**
   - **Description**: Migration affecting revenue-generating capabilities
   - **Probability**: Medium
   - **Impact**: Critical
   - **Indicators**: Core business functions affected, long downtime windows
   - **Detection Methods**: Business impact analysis, revenue dependency mapping

2. **Customer Experience Degradation**
   - **Description**: Poor customer experience during or after migration
   - **Probability**: High
   - **Impact**: High
   - **Indicators**: UI inconsistencies, feature regressions, performance issues
   - **Detection Methods**: User journey testing, customer satisfaction monitoring

3. **Compliance Violations**
   - **Description**: Failure to meet regulatory or compliance requirements
   - **Probability**: Medium
   - **Impact**: Critical
   - **Indicators**: Data privacy issues, audit trail problems, security controls
   - **Detection Methods**: Compliance audit, security assessment

### Organizational Risks
1. **Team Capability Gaps**
   - **Description**: Team lacking necessary skills for microservices
   - **Probability**: High
   - **Impact**: Medium
   - **Indicators**: Lack of experience, skill gaps, learning curve
   - **Detection Methods**: Skills assessment, training gap analysis

2. **Stakeholder Resistance**
   - **Description**: Resistance from business stakeholders or teams
   - **Probability**: Medium
   - **Impact**: Medium
   - **Indicators**: Change resistance, communication issues, priority conflicts
   - **Detection Methods**: Stakeholder analysis, communication audit

3. **Knowledge Loss**
   - **Description**: Loss of critical system knowledge during transition
   - **Probability**: Medium
   - **Impact**: High
   - **Indicators**: Documentation gaps, key person dependencies
   - **Detection Methods**: Knowledge audit, documentation review
```

#### Project Management Risks
```markdown
## Project Management Risk Categories

### Planning and Execution Risks
1. **Timeline Overruns**
   - **Description**: Project taking longer than planned
   - **Probability**: High
   - **Impact**: Medium
   - **Indicators**: Scope creep, unexpected complexity, resource constraints
   - **Detection Methods**: Timeline analysis, milestone tracking

2. **Budget Overruns**
   - **Description**: Exceeding allocated budget
   - **Probability**: Medium
   - **Impact**: Medium
   - **Indicators**: Resource cost increases, scope expansion, delays
   - **Detection Methods**: Budget tracking, cost variance analysis

3. **Scope Creep**
   - **Description**: Uncontrolled expansion of project scope
   - **Probability**: Medium
   - **Impact**: High
   - **Indicators**: Additional requirements, feature additions
   - **Detection Methods**: Scope analysis, change request tracking

### Resource Risks
1. **Team Attrition**
   - **Description**: Loss of key team members during project
   - **Probability**: Medium
   - **Impact**: High
   - **Indicators**: High workload, long hours, team stress
   - **Detection Methods**: Team satisfaction surveys, workload analysis

2. **Resource Constraints**
   - **Description**: Insufficient resources (people, infrastructure, tools)
   - **Probability**: Medium
   - **Impact**: Medium
   - **Indicators**: Resource conflicts, bottlenecks, delays
   - **Detection Methods**: Resource utilization analysis, capacity planning
```

### 2. Risk Quantification Methodology

#### Risk Assessment Matrix
```markdown
## Risk Scoring Framework

### Probability Scale
- **Very High (5)**: > 70% chance of occurrence
- **High (4)**: 50-70% chance of occurrence
- **Medium (3)**: 30-50% chance of occurrence
- **Low (2)**: 10-30% chance of occurrence
- **Very Low (1)**: < 10% chance of occurrence

### Impact Scale
- **Critical (5)**: Project failure, major business impact
- **High (4)**: Significant delays, major functionality loss
- **Medium (3)**: Moderate delays, partial functionality loss
- **Low (2)**: Minor delays, minimal functionality loss
- **Very Low (1)**: Insignificant impact

### Risk Score Calculation
**Risk Score = Probability × Impact**

#### Risk Categories
- **Critical (16-25)**: Immediate action required
- **High (9-15)**: Active management required
- **Medium (4-8)**: Monitor and manage
- **Low (1-3)**: Accept and monitor
```

#### Risk Register Template
```markdown
# Risk Register

## Risk Identification
- **Risk ID**: Unique identifier
- **Risk Category**: Technical/Business/Organizational/Project
- **Risk Description**: Clear description of the risk
- **Risk Source**: Where the risk originates

## Risk Assessment
- **Probability**: 1-5 scale
- **Impact**: 1-5 scale
- **Risk Score**: Probability × Impact
- **Risk Category**: Critical/High/Medium/Low
- **Risk Owner**: Person responsible for managing the risk

## Risk Response
- **Response Strategy**: Mitigate/Accept/Transfer/Avoid
- **Mitigation Actions**: Specific actions to reduce risk
- **Contingency Plan**: Backup plan if risk materializes
- **Timeline**: When actions should be completed
- **Status**: Not Started/In Progress/Completed

## Risk Monitoring
- **Review Frequency**: How often to review the risk
- **Key Indicators**: Early warning signs
- **Last Review Date**: Date of last review
- **Next Review Date**: Date of next scheduled review
```

### 3. Risk Mitigation Strategies

#### Technical Risk Mitigation
```markdown
## Technical Risk Mitigation Strategies

### Architecture Risk Mitigation
1. **Proof of Concepts (PoCs)**
   - Create small-scale prototypes for risky architectural decisions
   - Validate technology choices before full implementation
   - Test integration patterns with actual systems

2. **Incremental Migration**
   - Use Strangler Fig pattern for gradual migration
   - Implement feature flags for controlled rollout
   - Maintain rollback capabilities at all times

3. **Architecture Reviews**
   - Regular architecture decision reviews
   - External expert consultation
   - Peer reviews of critical design decisions

### Data Migration Risk Mitigation
1. **Dry-Run Migrations**
   - Practice migrations with test data
   - Validate migration scripts and processes
   - Test rollback procedures

2. **Data Validation**
   - Implement comprehensive data consistency checks
   - Use data comparison tools
   - Plan for data reconciliation processes

3. **Backup and Recovery**
   - Create complete system backups before migration
   - Test restore procedures regularly
   - Document emergency recovery processes
```

#### Business Risk Mitigation
```markdown
## Business Risk Mitigation Strategies

### Business Continuity Mitigation
1. **Phased Rollout**
   - Migrate non-critical functions first
   - Maintain legacy system for critical functions
   - Gradual traffic migration with monitoring

2. **User Communication**
   - Transparent communication about migration progress
   - User training and support during transition
   - Feedback mechanisms for user issues

3. **Service Level Agreements (SLAs)**
   - Define clear service level objectives
   - Monitor SLA compliance closely
   - Have escalation procedures for SLA breaches

### Compliance Risk Mitigation
1. **Compliance by Design**
   - Include compliance requirements from the beginning
   - Regular compliance audits during development
   - Documentation of compliance measures

2. **Data Privacy Protection**
   - Implement data encryption and access controls
   - Anonymize test data where possible
   - Follow GDPR/CCPA requirements strictly

3. **Audit Trail Maintenance**
   - Comprehensive logging of all system changes
   - Immutable audit trails for critical operations
   - Regular audit trail verification
```

#### Organizational Risk Mitigation
```markdown
## Organizational Risk Mitigation Strategies

### Team Capability Mitigation
1. **Skills Development**
   - Comprehensive training programs
   - Knowledge sharing sessions
   - External training and certification

2. **Knowledge Management**
   - Detailed documentation of all systems and processes
   - Knowledge transfer sessions
   - Pair programming and code reviews

3. **Team Structure**
   - Cross-functional teams with diverse skills
   - Clear roles and responsibilities
   - Regular team health assessments

### Change Management Mitigation
1. **Stakeholder Engagement**
   - Regular stakeholder communication
   - Involvement in decision-making processes
   - Clear value proposition demonstration

2. **Change Communication**
   - Regular project updates and progress reports
   - Success stories and lessons learned
   - Open channels for feedback and concerns
```

### 4. Risk Monitoring and Control

#### Risk Monitoring Dashboard
```markdown
## Risk Monitoring Framework

### Key Risk Indicators (KRIs)
1. **Technical KRIs**
   - Code defect density: < 2 defects per KLOC
   - Test coverage: > 80%
   - Performance regression: < 10%
   - System availability: > 99.9%

2. **Project KRIs**
   - Schedule variance: < 10%
   - Budget variance: < 15%
   - Scope creep: < 5%
   - Team turnover: < 10%

3. **Business KRIs**
   - User satisfaction: > 4.0/5.0
   - Customer support tickets: < 5% increase
   - Revenue impact: < 2% reduction
   - Compliance violations: Zero

### Risk Reporting
- **Daily**: Risk status updates for critical risks
- **Weekly**: Risk register review and updates
- **Monthly**: Risk assessment and trend analysis
- **Quarterly**: Comprehensive risk review and strategy adjustment
```

#### Risk Control Processes
```java
// Risk monitoring and alerting system
@Service
public class RiskMonitoringService {

    @Autowired
    private RiskRepository riskRepository;

    @Autowired
    private AlertService alertService;

    @Scheduled(cron = "0 */6 * * *") // Every 6 hours
    public void monitorRisks() {
        List<Risk> activeRisks = riskRepository.findByStatusIn(
            Arrays.asList(RiskStatus.ACTIVE, RiskStatus.MONITORING));

        for (Risk risk : activeRisks) {
            RiskAssessment assessment = assessRisk(risk);

            if (assessment.hasTriggeredThreshold()) {
                handleRiskThresholdBreach(risk, assessment);
            }

            updateRiskStatus(risk, assessment);
        }
    }

    private RiskAssessment assessRisk(Risk risk) {
        RiskAssessment assessment = new RiskAssessment();

        switch (risk.getCategory()) {
            case TECHNICAL:
                assessment = assessTechnicalRisk(risk);
                break;
            case BUSINESS:
                assessment = assessBusinessRisk(risk);
                break;
            case ORGANIZATIONAL:
                assessment = assessOrganizationalRisk(risk);
                break;
            case PROJECT:
                assessment = assessProjectRisk(risk);
                break;
        }

        return assessment;
    }

    private RiskAssessment assessTechnicalRisk(Risk risk) {
        RiskAssessment assessment = new RiskAssessment();

        // Check performance metrics
        if (risk.getName().contains("Performance")) {
            double avgResponseTime = getAverageResponseTime();
            double baselineResponseTime = getBaselineResponseTime();

            if (avgResponseTime > baselineResponseTime * 1.2) {
                assessment.setTriggered(true);
                assessment.setSeverity(RiskSeverity.HIGH);
                assessment.setMessage("Response time degraded by " +
                    String.format("%.1f%%", (avgResponseTime / baselineResponseTime - 1) * 100));
            }
        }

        // Check error rates
        if (risk.getName().contains("Error Rate")) {
            double errorRate = getErrorRate();
            if (errorRate > 0.01) { // 1% error rate threshold
                assessment.setTriggered(true);
                assessment.setSeverity(RiskSeverity.MEDIUM);
                assessment.setMessage("Error rate at " + String.format("%.2f%%", errorRate * 100));
            }
        }

        return assessment;
    }

    private void handleRiskThresholdBreach(Risk risk, RiskAssessment assessment) {
        // Send alert to risk owner
        Alert alert = Alert.builder()
            .type(AlertType.RISK_THRESHOLD_BREACH)
            .severity(assessment.getSeverity())
            .message("Risk threshold breached: " + risk.getName())
            .details(assessment.getMessage())
            .recipients(Arrays.asList(risk.getOwner().getEmail()))
            .build();

        alertService.sendAlert(alert);

        // Update risk status
        risk.setStatus(RiskStatus.CRITICAL);
        risk.setLastAssessment(LocalDateTime.now());
        riskRepository.save(risk);

        // Trigger escalation if needed
        if (assessment.getSeverity() == RiskSeverity.CRITICAL) {
            escalateRisk(risk, assessment);
        }
    }
}
```

### 5. Contingency Planning

#### Rollback Strategies
```markdown
## Rollback Contingency Planning

### Immediate Rollback Triggers
- System availability < 99%
- Error rate > 5%
- Response time degradation > 50%
- Revenue impact > 10%
- Customer satisfaction drop > 20%

### Rollback Procedures
1. **Feature Flag Rollback**
   - Immediate disable new features
   - Route all traffic back to legacy system
   - Monitor system stability

2. **Database Rollback**
   - Restore from pre-migration backup
   - Verify data integrity
   - Resume legacy system operations

3. **Infrastructure Rollback**
   - Decommission new infrastructure
   - Restart legacy infrastructure
   - Validate all connections

### Rollback Validation
- Complete system health check
- Data consistency verification
- Business function testing
- Performance validation
- User acceptance confirmation
```

#### Emergency Response Plan
```markdown
## Emergency Response Framework

### Incident Classification
1. **Critical**: Complete system failure, major business impact
2. **High**: Significant functionality loss, revenue impact
3. **Medium**: Partial functionality loss, customer impact
4. **Low**: Minor issues, minimal impact

### Response Procedures
1. **Immediate Response (0-15 minutes)**
   - Acknowledge incident
   - Activate incident response team
   - Begin initial assessment
   - Communicate with stakeholders

2. **Investigation (15-60 minutes)**
   - Identify root cause
   - Assess impact scope
   - Determine rollback requirements
   - Plan recovery actions

3. **Recovery (60 minutes - 4 hours)**
   - Execute rollback or fix
   - Validate system stability
   - Monitor for regressions
   - Communicate resolution

4. **Post-Incident (4-24 hours)**
   - Complete root cause analysis
   - Document lessons learned
   - Update procedures and controls
   - Plan preventive measures
```

## Output Templates

### Risk Assessment Report
```markdown
# Migration Risk Assessment Report

## Executive Summary
- Overall risk level: [Critical/High/Medium/Low]
- Top 5 risks requiring immediate attention
- Risk mitigation effectiveness
- Recommended risk management actions

## Risk Analysis
### Technical Risks
[Detailed analysis of technical risks with scores and mitigation plans]

### Business Risks
[Detailed analysis of business risks with scores and mitigation plans]

### Organizational Risks
[Detailed analysis of organizational risks with scores and mitigation plans]

### Project Risks
[Detailed analysis of project risks with scores and mitigation plans]

## Risk Heat Map
[Visual representation of risks by probability and impact]

## Mitigation Plan
### Immediate Actions (Next 30 days)
- [ ] Action 1
- [ ] Action 2
- [ ] Action 3

### Short-term Actions (30-90 days)
- [ ] Action 1
- [ ] Action 2
- [ ] Action 3

### Long-term Actions (90+ days)
- [ ] Action 1
- [ ] Action 2
- [ ] Action 3

## Monitoring and Control
### Key Risk Indicators
[List of KRIs with thresholds and monitoring frequency]

### Reporting Schedule
- Daily: Critical risk status
- Weekly: Risk register updates
- Monthly: Risk assessment review
- Quarterly: Comprehensive risk review

## Appendices
- Detailed Risk Register
- Risk Assessment Methodology
- Mitigation Strategy Details
- Contingency Plan Documents
```

This comprehensive risk assessment skill provides the framework and tools needed to identify, evaluate, and mitigate risks throughout the migration lifecycle, ensuring successful project outcomes while minimizing business impact.