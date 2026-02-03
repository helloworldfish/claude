# CLAUDE.md

**默认语言：中文**

本文档为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 插件概览

通用重构插件是一个全面的 Claude Code 插件，用于智能代码重构和迁移，支持多种项目类型，包括单体应用到微服务迁移、框架升级、运行时升级、语言转换和云迁移。

## 架构

### 核心组件
- **命令（18个命令）**：主要接口层，包括 `/migrate`、`/analyze`、`/plan`、`/validate`、`/refactor`、`/upgrade`、`/transpile` 等
- **代理（6个代理）**：不同任务的专门化 AI 代理：
  - 核心分析器：项目类型检测和代码库分析
  - 迁移架构师：目标架构设计
  - 依赖映射器：依赖关系图生成
  - 重构顾问：代码重构策略
  - 迁移规划师：详细迁移路线图
  - 验证工程师：迁移验证和测试
- **技能（8个技能）**：用于模式、最佳实践和技术的可重用知识模块
- **自动化脚本（5个脚本）**：用于分析、验证和重构应用的支持工具

### 三阶段重构工作流
```
原始代码 → /refactor-plan → 审阅文档 → /refactor-apply → 新代码
```

### 沙盒重构环境
支持三种模式：克隆、分支、复制，以及四种合并策略：差异、补丁、合并提交、PR

## 开发命令

### 插件开发
```bash
# 验证插件结构
claude plugin validate .

# 测试插件安装
claude plugin install legacy-migration@local-marketplace

# 运行分析脚本
./scripts/analyze-dependencies.sh
./scripts/code-metrics.sh
./scripts/migration-validator.sh
```

### 测试和验证
```bash
# 验证迁移计划
/validate --validation_type all

# 运行沙盒测试
/refactor-sandbox --target . --mode branch

# 应用重构并备份
/refactor-apply --plan refactoring-plan.json
```

## 新功能：智能迁移助手

### 一键启动（推荐）
```bash
# 新的统一入口命令
/start-migration

# 启动新迁移
/start-migration --project-path ./my-project

# 恢复上次工作
/start-migration --resume

# 查看所有会话
/start-migration --list-sessions
```

### 智能交互流程
1. **自动检测**：自动识别项目类型和技术栈
2. **问答引导**：通过交互式问答确认迁移目标
3. **自动执行**：智能执行迁移步骤
4. **增量支持**：只处理变更的文件
5. **状态保存**：自动保存进度，支持恢复

### 迁移助手脚本
```bash
# 主控脚本
./scripts/migration-assistant.sh start ./my-project

# 状态管理
./scripts/session-manager.sh list
./scripts/session-manager.sh resume session-id

# 增量处理
./scripts/incremental-processor.sh detect ./project session-id

# 状态恢复
./scripts/state-restorer.sh list
```

## 支持的技术

### 编程语言
- Java、JavaScript/TypeScript、Python、Go、C#、Ruby、PHP

### 框架
- 后端：Spring Boot、Django、.NET Core、Express/NestJS
- 前端：React、Vue、Angular

### 运行时版本
- Java：8 → 11 → 17 → 21
- Node.js：14 → 16 → 18 → 20
- Python：3.8 → 3.12

## 配置文件

### 主要配置
`.refactor-config.yml`:
```yaml
project:
  auto_detect: true
  type: auto

refactoring:
  strategy: balanced
  safety_level: high
  backup_enabled: true

analysis:
  depth: 3
  include_tests: true
  exclude_patterns:
    - node_modules
    - target
    - build

validation:
  compile: true
  test: true
  lint: true
```

### 计划配置
`refactoring-plan-config.yml` 用于自定义计划生成参数

## 安全特性

### 自动备份系统
所有操作都会在 `.refactor-backups/` 中创建包含清单、文件列表和校验和的备份。

### 回滚支持
```bash
# 验证失败时自动回滚
/refactor-apply --rollback .refactor-backups/2025-12-30-15:30/

# 手动 Git 回滚
git reset --hard HEAD~1
```

### 验证管道
- 编译验证
- 测试执行
- 代码质量检查
- 性能验证
- 安全扫描

## 常见工作流

### 框架升级（Spring Boot）
```bash
/detect-project --path ~/my-spring-app
/upgrade --target . --upgrade_type framework --framework spring-boot --to-version 3.0
/validate --validation_type backend
```

### 语言转换（Java 到 Kotlin）
```bash
/transpile --source src/main/java --from java --to kotlin --output src/main/kotlin
/validate --validation_type backend
```

### 单体应用到微服务
```bash
/analyze --project_path ~/my-monolith --analysis_type all
/plan --analysis_results ~/my-monolith/analysis-output --migration_strategy strangler-fig
/migrate --scope=service --project_path ~/my-monolith --service=user-service
```

## 输出结构

生成的输出遵循标准化结构：
```
output/
├── 01-analysis/        # 分析报告
├── 02-planning/        # 迁移计划
├── 03-implementation/  # 实施指南
├── 04-automation/      # 脚本和工具
└── migration-summary.md # 摘要文档
```

## 代理协调

代理按顺序执行并传递信息：
1. 核心分析器 → 依赖映射器
2. 迁移架构师 → 重构顾问
3. 迁移规划师 → 验证工程师

每个代理都有特定的输入要求，其输出将作为工作流中下一个代理的输入。