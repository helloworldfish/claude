# Universal Refactoring Plugin - New Architecture

## 概述 (Overview)

本架构设计将 legacy-migration 插件升级为通用的代码重构工具，支持多种重构场景和项目类型。

## 设计原则 (Design Principles)

1. **模块化架构** (Modular Architecture)
   - 每个重构类型独立的 agent 和 skill
   - 可组合的重构流水线
   - 插件化的重构策略

2. **多语言支持** (Multi-Language Support)
   - 语言无关的分析框架
   - 特定语言的优化策略
   - 跨语言重构能力

3. **类型检测** (Type Detection)
   - 自动识别项目类型
   - 智能选择重构策略
   - 混合项目支持

4. **安全重构** (Safe Refactoring)
   - 保留现有的三阶段工作流
   - 自动备份和回滚
   - 全面验证机制

## 新架构分层

### 1. 项目类型检测层 (Project Type Detection)

```
Project Detector
    ↓
├── Frontend Projects
│   ├── React/Vue/Angular
│   ├── Mobile Apps (React Native, Flutter)
│   └── Desktop Apps
├── Backend Projects
│   ├── Monolithic Applications
│   ├── Microservices
│   └── Serverless Functions
├── Full Stack Projects
│   ├── Monolithic Web Apps
│   ├── JAMstack
│   └── Traditional MVC
└── Infrastructure Projects
    ├── Configuration (Terraform, CloudFormation)
    ├── CI/CD Pipelines
    └── Docker/Kubernetes
```

### 2. 重构类型分类层 (Refactoring Type Classification)

```
Refactoring Types:
├── Architecture Refactoring
│   ├── Monolith to Microservices
│   ├── Microservices Consolidation
│   ├── Layered Architecture Cleanup
│   └── Event-Driven Migration
├── Technology Migration
│   ├── Framework Upgrades
│   ├── Language Transpilation
│   ├── Runtime Upgrades (JDK, Node.js, Python)
│   └── Database Migration
├── Code Quality
│   ├── Design Pattern Application
│   ├── Code Smell Elimination
│   ├── Technical Debt Reduction
│   └── Performance Optimization
├── Platform Migration
│   ├── On-Premises to Cloud
│   ├── Cloud Provider Migration
│   ├── Containerization
│   └── Serverless Migration
└── Dependency Management
    ├── Dependency Updates
    ├── Security Vulnerability Fixes
    ├── License Compliance
    └── Dependency Consolidation
```

### 3. 重构策略引擎 (Refactoring Strategy Engine)

```
Strategy Engine
    ↓
├── Analysis Phase
│   ├── Project Type Detection
│   ├── Dependency Analysis
│   ├── Impact Assessment
│   └── Risk Evaluation
├── Planning Phase
│   ├── Strategy Selection
│   ├── Step Generation
│   ├── Resource Estimation
│   └── Timeline Planning
├── Execution Phase
│   ├── Code Transformation
│   ├── Configuration Updates
│   ├── Build System Updates
│   └── Test Adaptation
└── Validation Phase
    ├── Compilation Verification
    ├── Test Execution
    ├── Performance Validation
    └── Regression Testing
```

## 新 Agents 设计

### 1. **project-type-detector** - 项目类型检测器
```yaml
triggers:
  - "/refactor" (通用重构命令)
  - "upgrade" (升级场景)
  - "migrate" (迁移场景)

responsibilities:
  - 检测项目类型和结构
  - 识别主要编程语言
  - 检测框架和版本
  - 分析构建系统
  - 识别依赖管理工具
```

### 2. **framework-upgrader** - 框架升级专家
```yaml
supports:
  - Spring Boot upgrades
  - React/Vue/Angular upgrades
  - Django/Flask upgrades
  - .NET Framework upgrades

responsibilities:
  - 版本兼容性分析
  - Breaking Changes 识别
  - API 迁移指南
  - 配置文件更新
  - 依赖项升级
```

### 3. **runtime-upgrader** - 运行时升级专家
```yaml
supports:
  - JDK 8 → 11 → 17 → 21
  - Node.js 版本升级
  - Python 2 → 3, 3.x → 3.y
  - .NET Core 版本升级

responsibilities:
  - 运行时特性变化分析
  - 弃用 API 识别
  - 性能影响评估
  - 代码兼容性检查
  - 迁移路径规划
```

### 4. **language-transpiler** - 语言转换器
```yaml
supports:
  - Java → Kotlin
  - Java → C#
  - JavaScript → TypeScript
  - Python → Go/Rust
  - PHP → Node.js

responsibilities:
  - 语法转换
  - 标准库映射
  - 框架对应关系
  - 模式适配
  - 测试转换
```

### 5. **frontend-refactorer** - 前端重构专家
```yaml
supports:
  - 组件化重构
  - 状态管理迁移
  - CSS 架构优化
  - 性能优化
  - 构建工具升级

responsibilities:
  - 组件结构分析
  - 依赖关系映射
  - 状态管理迁移（Redux → Zustand, MobX 等）
  - 样式系统迁移
  - 构建配置更新
```

### 6. **backend-refactorer** - 后端重构专家
```yaml
supports:
  - API 设计优化
  - 数据库层重构
  - 服务分层优化
  - 缓存策略优化
  - 安全加固

responsibilities:
  - API 契约分析
  - 数据访问模式识别
  - 业务逻辑分层
  - 性能瓶颈识别
  - 安全漏洞修复
```

### 7. **microservice-architect** - 微服务架构师
```yaml
supports:
  - 单体拆分
  - 微服务合并
  - 服务边界优化
  - 数据拆分策略
  - 服务间通信

responsibilities:
  - 领域边界识别
  - 服务拆分规划
  - API 网关设计
  - 数据一致性策略
  - 迁移路径设计
```

### 8. **database-migrator** - 数据库迁移专家
```yaml
supports:
  - 关系型数据库迁移
  - NoSQL 迁移
  - 数据库版本升级
  - Schema 演进
  - 数据迁移脚本

responsibilities:
  - Schema 分析
  - 数据映射策略
  - 迁移脚本生成
  - 数据验证
  - 回滚策略
```

### 9. **cloud-migrator** - 云迁移专家
```yaml
supports:
  - 本地到云迁移
  - 云提供商间迁移
  - 容器化改造
  - Serverless 转换
  - DevOps 配置

responsibilities:
  - 云服务映射
  - 基础设施即代码
  - CI/CD 流水线
  - 监控和日志
  - 成本优化
```

### 10. **validation-engineer** - 验证工程师（增强版）
```yaml
supports:
  - 多语言测试
  - 性能基准测试
  - 安全扫描
  - 合规性检查
  - 业务逻辑验证

responsibilities:
  - 测试策略制定
  - 测试代码生成
  - 自动化测试集成
  - 性能分析
  - 质量门禁
```

## 新 Skills 设计

### 1. **refactoring-patterns** - 重构模式库
```markdown
patterns/
├── architectural/
│   ├── strangler-fig.md
│   ├── anti-corruption-layer.md
│   ├── event-driven.md
│   └── cqrs.md
├── code-quality/
│   ├── extract-method.md
│   ├── rename-variable.md
│   ├── remove-duplication.md
│   └── simplify-conditional.md
├── performance/
│   ├── caching-strategies.md
│   ├── database-optimization.md
│   ├── async-patterns.md
│   └── lazy-loading.md
└── security/
    ├── authentication-patterns.md
    ├── authorization-patterns.md
    ├── data-encryption.md
    └── input-validation.md
```

### 2. **upgrade-guides** - 升级指南库
```markdown
upgrades/
├── frameworks/
│   ├── spring-boot-2-to-3.md
│   ├── react-17-to-18.md
│   ├── angular-upgrade.md
│   └── vue-2-to-3.md
├── runtimes/
│   ├── java-8-to-11.md
│   ├── java-11-to-17.md
│   ├── nodejs-upgrade.md
│   └── python-upgrade.md
└── databases/
    ├── postgresql-upgrade.md
    ├── mysql-upgrade.md
    └── mongodb-upgrade.md
```

### 3. **language-mappings** - 语言映射库
```markdown
mappings/
├── java-to-kotlin/
│   ├── syntax-mapping.md
│   ├── standard-library.md
│   ├── framework-equivalent.md
│   └── patterns.md
├── java-to-csharp/
│   └── ...
├── js-to-ts/
│   └── ...
└── python-to-go/
    └── ...
```

### 4. **framework-migrations** - 框架迁移指南
```markdown
framework-migrations/
├── frontend/
│   ├── jquery-to-react.md
│   ├── angular-to-react.md
│   ├── vue-to-react.md
│   └── class-to-hooks.md
└── backend/
    ├── express-to-nestjs.md
    ├── mvc-to-webflux.md
    └── servlet-to-spring-boot.md
```

## 新命令设计

### 1. **/refactor** - 通用重构命令
```bash
# 自动检测并重构
/refactor --target <path> --type auto

# 指定重构类型
/refactor --target <path> --type framework-upgrade --from spring-boot-2 --to spring-boot-3

# 框架升级
/refactor --target <path> --type upgrade-framework --framework spring-boot --to-version 3.0

# 运行时升级
/refactor --target <path> --type upgrade-runtime --runtime java --from-version 8 --to-version 17

# 语言转换
/refactor --target <path> --type transpile --from java --to kotlin

# 前端重构
/refactor --target <path> --type frontend --subtype component-structure
```

### 2. **/detect-project** - 项目检测
```bash
/detect-project --path <path>

# 输出：
# - 项目类型
# - 主要语言
# - 框架和版本
# - 构建系统
# - 依赖项
# - 推荐的重构选项
```

### 3. **/upgrade** - 升级命令
```bash
# 框架升级
/upgrade --target <path> --framework spring-boot --to-version 3.0

# JDK 升级
/upgrade --target <path> --runtime java --to-version 17

# 依赖项升级
/upgrade --target <path> --dependencies all

# 安全补丁升级
/upgrade --target <path> --security-only
```

### 4. **/transpile** - 语言转换
```bash
# Java 到 Kotlin
/transpile --source <java-path> --target kotlin --output <output-path>

# JavaScript 到 TypeScript
/transpile --source <js-path> --target typescript --output <output-path>

# 带框架转换
/transpile --source <java-path> --target kotlin --convert-framework spring
```

### 5. **/refactor-frontend** - 前端专用重构
```bash
# 组件化重构
/refactor-frontend --target <path> --strategy component-extraction

# 状态管理迁移
/refactor-frontend --target <path> --migrate-state redux-to-zustand

# CSS 架构
/refactor-frontend --target <path> --css-architecture css-modules
```

### 6. **/refactor-backend** - 后端专用重构
```bash
# API 重构
/refactor-backend --target <path> --strategy api-restful

# 数据库层
/refactor-backend --target <path> --layer database --pattern repository

# 服务分层
/refactor-backend --target <path> --strategy layered-architecture
```

## 配置系统

### 项目级配置 `.refactor-config.yml`
```yaml
# 项目类型和配置
project:
  type: auto  # auto, monolith, microservice, frontend, backend, fullstack
  primary_language: auto
  frameworks: []

# 重构策略
refactoring:
  strategy: auto  # auto, conservative, aggressive
  safety_level: high  # low, medium, high
  test_coverage_threshold: 80

# 分析配置
analysis:
  depth: 3
  include_tests: true
  exclude_patterns:
    - node_modules
    - target
    - build
    - .git

# 验证配置
validation:
  compile: true
  test: true
  lint: true
  security_scan: false
  performance_test: false

# 输出配置
output:
  format: markdown  # markdown, json, html
  include_diffs: true
  include_metrics: true
  visualizations: true
```

## 重构模板系统

### 预定义重构模板
```yaml
templates:
  spring-boot-3-upgrade:
    description: "Spring Boot 2.x to 3.x migration"
    steps:
      - detect-version
      - analyze-dependencies
      - generate-migration-plan
      - update-pom-xml
      - migrate-code
      - update-tests
      - validate

  java-8-to-17:
    description: "Java 8 to Java 17 migration"
    steps:
      - detect-java-version
      - analyze-deprecated-apis
      - update-modules
      - migrate-code
      - update-build-config
      - test

  react-class-to-hooks:
    description: "React class components to hooks"
    steps:
      - identify-class-components
      - analyze-state-and-lifecycle
      - convert-to-hooks
      - update-tests
      - validate

  monolith-to-microservices:
    description: "Extract microservices from monolith"
    steps:
      - analyze-domains
      - identify-boundaries
      - design-apis
      - extract-service
      - migrate-data
      - validate
```

## 工作流集成

### 自动检测和推荐流程
```
用户执行 /refactor
    ↓
project-type-detector 分析项目
    ↓
根据项目类型和状态，推荐重构选项：
    ↓
┌─────────────────────────────────────┐
│ 检测到: Spring Boot 2.7 + Java 8   │
│                                     │
│ 推荐重构选项:                       │
│ 1. Spring Boot 2.7 → 3.0          │
│ 2. Java 8 → 17                     │
│ 3. 单体 → 微服务（如适用）         │
│ 4. 代码质量优化                    │
│ 5. 性能优化                        │
└─────────────────────────────────────┘
    ↓
用户选择重构类型
    ↓
调用对应的 agent 执行重构
```

## 质量保证

### 多维度质量检查
```yaml
quality_gates:
  code_quality:
    - complexity_check
    - code_duplication
    - naming_conventions
    - documentation_coverage

  functionality:
    - unit_tests
    - integration_tests
    - e2e_tests
    - api_tests

  performance:
    - response_time
    - throughput
    - memory_usage
    - database_query_performance

  security:
    - vulnerability_scan
    - dependency_check
    - security_headers
    - authz_authn

  compatibility:
    - api_backward_compatibility
    - data_format_compatibility
    - client_compatibility
```

## 实现优先级

### Phase 1: 基础架构（高优先级）
1. ✅ 保留现有功能（微服务迁移）
2. ⬜ project-type-detector agent
3. ⬜ 扩展的 /refactor 命令
4. ⬜ 配置系统
5. ⬜ 基础文档更新

### Phase 2: 框架和运行时升级（高优先级）
1. ⬜ framework-upgrader agent
2. ⬜ runtime-upgrader agent
3. ⬜ upgrade-guides skills
4. ⬜ /upgrade 命令
5. ⬜ Spring Boot upgrade 实现
6. ⬜ JDK upgrade 实现

### Phase 3: 前后端重构（中优先级）
1. ⬜ frontend-refactorer agent
2. ⬜ backend-refactorer agent
3. ⬜ /refactor-frontend 命令
4. ⬜ /refactor-backend 命令
5. ⬜ React/Vue/Angular 支持

### Phase 4: 语言转换（中优先级）
1. ⬜ language-transpiler agent
2. ⬜ language-mappings skills
3. ⬜ /transpile 命令
4. ⬜ Java → Kotlin 实现
5. ⬜ JavaScript → TypeScript 实现

### Phase 5: 高级场景（低优先级）
1. ⬜ cloud-migrator agent
2. ⬜ database-migrator agent
3. ⬜ 云迁移支持
4. ⬜ 容器化支持
5. ⬜ Serverless 转换

## 向后兼容性

- 保留所有现有的 agents、commands 和 skills
- 现有命令继续工作
- 新命令提供增强功能
- 逐步迁移到新架构

## 总结

这个新架构将 legacy-migration 插件从专门的"单体到微服务"迁移工具，升级为通用的、多语言的代码重构平台，支持：

✅ 多种项目类型（前端、后端、全栈、基础设施）
✅ 多种重构类型（架构、技术栈、质量、平台、依赖）
✅ 多种编程语言（Java, JavaScript, Python, Go, C# 等）
✅ 智能检测和推荐
✅ 安全的三阶段工作流
✅ 全面的验证和质量保证

通过模块化设计和可扩展的架构，可以逐步添加对新语言、框架和重构场景的支持。
