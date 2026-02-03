# 通用重构插件完整功能指南

## 插件概述

**插件名称**: legacy-migration
**版本**: 3.0.0
**用途**: 大型单体应用的迁移和重构，包含分析、规划、转换、验证和自动化代码重构的完整生命周期支持。

## 核心功能模块

### 1. 迁移工作流（Migration Workflow）
### 2. 重构工作流（Refactoring Workflow）
### 3. 沙盒重构（Sandbox Refactoring）

---

## 命令列表（18个命令）

### 🚀 核心迁移命令

#### `/migrate` - 完整迁移工作流
**用途**: 协调多个专业代理执行大型单体应用的完整迁移流程

**工作流程**:
```
Phase 1: 初始化评估
  ├─ 验证项目参数
  ├─ 初步代码库扫描
  └─ 估算迁移复杂度

Phase 2: 深度分析
  └─ 启动 monolith-analyzer 代理
     ├─ 架构评估
     ├─ 业务领域映射
     ├─ 服务分解识别
     └─ 风险评估

Phase 3: 架构设计
  ├─ migration-architect (目标架构设计)
  └─ dependency-mapper (依赖关系映射)

Phase 4: 实施指导
  ├─ transformation-advisor (代码转换策略)
  ├─ migration-planner (详细路线图)
  └─ validation-engineer (验证标准)
```

**用法**:
```bash
/migrate --project <项目路径> --output <输出目录>
```

**输出结构**:
```
output_dir/
├── 01-analysis/           # 分析报告
├── 02-planning/           # 迁移计划
├── 03-implementation/     # 实施指南
├── 04-automation/         # 自动化工具
└── migration-summary.md   # 迁移总结
```

---

#### `/analyze` - 代码库分析
**用途**: 深度分析代码库结构、依赖关系和技术栈

**分析内容**:
- 代码复杂度
- 依赖关系图
- 技术栈识别
- 代码质量指标
- 重构机会识别

**用法**:
```bash
/analyze --target <文件/目录> --depth <分析深度(1-5)>
```

---

#### `/plan` - 迁移计划
**用途**: 创建详细的迁移计划和路线图

**规划内容**:
- 迁移策略选择
- 服务边界定义
- 数据迁移计划
- 基础设施升级
- 团队组织建议

**用法**:
```bash
/plan --analysis <分析结果> --output <输出目录>
```

---

#### `/validate` - 验证迁移
**用途**: 验证迁移的正确性和完整性

**验证内容**:
- 功能完整性
- 性能基准测试
- 数据一致性
- 业务连续性
- 回滚能力

**用法**:
```bash
/validate --target <验证目标> --criteria <验证标准>
```

---

#### `/analyze-dependencies` - 依赖分析
**用途**: 深度分析代码依赖关系和耦合度

**分析内容**:
- 循环依赖检测
- 强耦合识别
- 依赖层次结构
- 模块边界分析

**用法**:
```bash
/analyze-dependencies --target <项目路径>
```

---

### 🔧 重构工作流命令

#### `/refactor-plan` - 生成重构计划 ⭐
**用途**: 在不修改源代码的情况下，生成详细的中间重构文档

**工作流程**:
```
原代码
  ↓
/refactor-plan
  ↓
中间文档（审查和批准）
  ├─ 01-refactoring-plan.md         # 重构计划概述
  ├─ 02-change-analysis.md           # 详细变更分析
  ├─ 03-code-diffs/                  # Git 风格差异
  ├─ 04-impact-analysis.md           # 风险评估
  ├─ 05-rollback-plan.md             # 回滚程序
  └─ 06-approval-checklist.md        # 批准清单
  ↓
团队审查
  ↓
/refactor-apply
  ↓
新代码
```

**用法**:
```bash
# 基本用法
/refactor-plan --target <文件/目录>

# 完整选项
/refactor-plan \
  --target src/main/java/service/ \
  --output_dir ./refactoring-plans/ \
  --plan_type comprehensive \
  --include_diffs \
  --depth 4
```

**计划类型**:
- `pattern` - 设计模式应用
- `quality` - 代码质量改进
- `extraction` - 微服务提取
- `comprehensive` - 全面分析（默认）

---

#### `/refactor-apply` - 应用重构计划 ⭐
**用途**: 安全应用已批准的重构计划

**安全特性**:
- ✅ 自动备份
- ✅ 编译验证
- ✅ 测试验证
- ✅ 自动回滚
- ✅ Git 集成

**执行模式**:
- `apply` - 完整应用（默认）
- `dry-run` - 预览变更
- `validate-only` - 验证可行性
- `interactive` - 逐步确认

**用法**:
```bash
# 标准应用
/refactor-apply --plan ./refactoring-plans/service-refactor/

# 预览模式
/refactor-apply --plan ./refactoring-plans/*/ --mode dry-run

# 交互模式
/refactor-apply --plan ./refactoring-plans/*/ --mode interactive

# 带自动提交
/refactor-apply --plan ./refactoring-plans/*/ --commit
```

---

#### `/refactor-sandbox` - 沙盒环境重构 ⭐⭐⭐
**用途**: 在完全隔离的环境中进行重构，零风险影响原代码

**三种模式**:
1. **Clone 模式** - 创建独立的新仓库（最安全）
2. **Branch 模式** - 使用 Git 分支
3. **Copy 模式** - 轻量复制

**四种合并策略**:
1. **diff** - 差异文件（可选择性应用）
2. **patch** - 统一补丁
3. **merge-commit** - Git 合并
4. **pr** - 创建 Pull Request

**用法**:
```bash
# Clone 模式（推荐）
/refactor-sandbox \
  --source . \
  --target ./sandbox-test/ \
  --mode clone

# Branch 模式（团队协作）
/refactor-sandbox \
  --source . \
  --mode branch \
  --git_branch refactor/payment-optimization

# 远程仓库（团队协作）
/refactor-sandbox \
  --source . \
  --target ./sandbox/ \
  --remote git@github.com:company/project-refactor.git

# 自动化流程
/refactor-sandbox \
  --source . \
  --target ./sandbox/ \
  --plan ./existing-plan/ \
  --auto_cleanup \
  --merge_strategy patch
```

**工作流程**:
```
原代码仓库
  ↓
创建沙盒（完全隔离）
  ├─ Clone 模式: 新仓库
  ├─ Branch 模式: 新分支
  └─ Copy 模式: 文件副本
  ↓
在沙盒中工作
  ├─ /refactor-plan
  ├─ 审查和修改
  └─ /refactor-apply
  ↓
生成合并产物
  ├─ patches/*.diff
  ├─ sandbox.patch
  └─ 或创建 PR
  ↓
应用回原仓库（审查后）
  ↓
清理沙盒
```

---

### 🎯 通用重构命令

#### `/refactor` - 智能重构
**用途**: 通用重构命令，自动检测项目类型并推荐重构策略

**重构类型**:
- `auto` - 自动检测和推荐
- `framework-upgrade` - 框架版本升级
- `runtime-upgrade` - 运行时版本升级
- `transpile` - 语言间转换
- `architecture` - 架构重构
- `quality` - 代码质量改进
- `performance` - 性能优化

**用法**:
```bash
# 自动重构
/refactor --target . --type auto

# 框架升级
/refactor --target . --type framework-upgrade --framework spring-boot --to-version 3.0

# 代码质量改进
/refactor --target . --type quality --strategy conservative
```

---

#### `/detect-project` - 项目类型检测
**用途**: 自动检测项目类型、技术栈，并推荐重构选项

**检测内容**:
- 项目类型（单体/微服务/前端/后端/全栈）
- 主要语言和版本
- 框架版本
- 推荐的重构选项
- 建议执行的命令

**用法**:
```bash
# 基本检测
/detect-project --path ~/my-project

# JSON格式输出
/detect-project --path . --output_format json

# 包含详细建议
/detect-project --path ~/src --include_recommendations true
```

---

#### `/upgrade` - 升级框架和运行时
**用途**: 升级框架版本、运行时版本和依赖

**升级类型**:
- `framework` - 框架版本升级
- `runtime` - 运行时版本升级
- `dependencies` - 所有依赖
- `security` - 仅安全更新

**用法**:
```bash
# Spring Boot升级
/upgrade --target . --upgrade_type framework --framework spring-boot --to-version 3.0

# Java版本升级
/upgrade --target . --upgrade_type runtime --runtime java --to-version 17

# 所有依赖升级
/upgrade --target . --upgrade_type dependencies
```

---

#### `/transpile` - 语言转换
**用途**: 在编程语言之间转换代码

**支持的转换**:
- Java ↔ Kotlin
- JavaScript → TypeScript
- Python → Go
- Java → C#
- PHP → Node.js

**用法**:
```bash
# Java到Kotlin转换
/transpile --source src/main/java --from java --to kotlin --output src/main/kotlin

# JavaScript到TypeScript转换
/transpile --source src --from javascript --to typescript --output src-ts
```

---

#### `/refactor-frontend` - 前端重构
**用途**: 专用前端重构命令

**重构策略**:
- `component-structure` - 提取和组织组件
- `state-migration` - 迁移状态管理
- `performance` - 优化渲染和加载
- `modernization` - 采用现代模式

**用法**:
```bash
# 组件重构
/refactor-frontend --target src --strategy component-structure

# 性能优化
/refactor-frontend --target . --strategy performance
```

---

#### `/refactor-backend` - 后端重构
**用途**: 专用后端重构命令

**重构策略**:
- `api-design` - RESTful API最佳实践
- `database-layer` - Repository模式优化
- `service-architecture` - 分层架构或DDD
- `performance` - 缓存和异步处理

**用法**:
```bash
# API设计重构
/refactor-backend --target src/main/java --strategy api-design

# 数据库层重构
/refactor-backend --target . --strategy database-layer
```

---

#### `/refactor-universal` - 通用重构
**用途**: 根据选择的策略进行通用重构

**策略类型**:
- `conservative` - 保守策略，最小化风险
- `balanced` - 平衡策略，推荐默认
- `aggressive` - 激进策略，最大改进

**用法**:
```bash
# 平衡策略重构
/refactor-universal --target . --strategy balanced --depth 3
```

---

#### `/extract-service` - 服务提取
**用途**: 从单体应用中提取微服务

**提取步骤**:
1. 识别服务边界
2. 定义 API 契约
3. 数据访问层分离
4. 业务逻辑迁移
5. 测试验证

**用法**:
```bash
/extract-service \
  --target <项目路径> \
  --service <服务名称> \
  --boundary <边界定义>
```

---

#### `/apply-pattern` - 应用设计模式
**用途**: 自动应用设计模式改进代码

**支持的模式**:
- Strategy Pattern
- Factory Pattern
- Observer Pattern
- Decorator Pattern
- Builder Pattern
- Repository Pattern
- 等等...

**用法**:
```bash
/apply-pattern \
  --target <文件/目录> \
  --pattern <模式名称> \
  --scope <应用范围>
```

---

## 使用场景指南

### 场景 1: 大型项目微服务化迁移

```bash
# 第一步：完整分析
/migrate --project . --output ./migration-output/

# 第二步：审查分析结果
cat ./migration-output/migration-summary.md

# 第三步：提取第一个服务
/extract-service \
  --target . \
  --service payment-service \
  --boundary "src/main/java/payment/*"

# 第四步：在沙盒中验证
/refactor-sandbox \
  --source . \
  --target ./sandbox-payment/ \
  --plan ./migration-output/03-implementation/
```

---

### 场景 2: 框架升级

```bash
# 第一步：检测项目
/detect-project --path ~/my-spring-app

# 第二步：升级Spring Boot
/upgrade --target . --upgrade_type framework --framework spring-boot --to-version 3.0

# 第三步：验证升级
/validate --validation_type backend
```

---

### 场景 3: React现代化

```bash
# 第一步：检测项目
/detect-project --path ~/my-react-app

# 第二步：升级React框架
/upgrade --target . --upgrade_type framework --framework react --to-version 18

# 第三步：重构为使用Hooks
/refactor-frontend --target src --strategy modernization

# 第四步：转换为TypeScript
/transpile --source src --from javascript --to typescript --output src-ts
```

---

### 场景 4: 代码质量重构

```bash
# 第一步：生成重构计划
/refactor-plan \
  --target src/main/java/service/ \
  --plan_type quality \
  --depth 4

# 第二步：团队审查
cat ./refactoring-plans/*/01-refactoring-plan.md

# 第三步：应用重构
/refactor-apply \
  --plan ./refactoring-plans/*/ \
  --commit
```

---

### 场景 5: 零风险实验性重构

```bash
# 第一步：创建隔离沙盒
/refactor-sandbox \
  --source . \
  --mode clone \
  --target ./sandbox-experiment/

# 第二步：在沙盒中大胆实验
cd sandbox-experiment/
/refactor-plan --target .
/refactor-apply --plan ./refactoring-plans/*/

# 第三步：充分测试
mvn clean test

# 第四步：生成差异文件
cd ..
/refactor-sandbox \
  --source . \
  --target ./sandbox-experiment/ \
  --merge_strategy diff

# 第五步：审查并选择性应用
cat patches/*.diff
git apply patches/001-approved-change.diff

# 第六步：清理
rm -rf sandbox-experiment/
```

---

### 场景 6: 团队协作重构

```bash
# 第一步：创建分支沙盒
/refactor-sandbox \
  --source . \
  --mode branch \
  --git_branch refactor/team-payment

# 第二步：团队在分支上协作
git push -u origin refactor/team-payment
# 团队成员提交变更...

# 第三步：创建 PR
gh pr create --title "Payment Service Refactoring"

# 第四步：代码审查和合并
# 审查通过后合并 PR
```

---

### 场景 7: 设计模式应用

```bash
# 第一步：分析设计模式机会
/analyze --target PaymentService.java --depth 3

# 第二步：应用设计模式
/apply-pattern \
  --target PaymentService.java \
  --pattern Strategy \
  --scope class

# 或使用三阶段工作流
/refactor-plan --target PaymentService.java --plan_type pattern
/refactor-apply --plan ./refactoring-plans/*/
```

---

## 辅助脚本

### 1. analyze-dependencies.sh
依赖分析自动化脚本，支持：
- 自动生成依赖图
- 检测循环依赖
- 识别强耦合模块

### 2. code-metrics.sh
代码质量和复杂度分析脚本，支持：
- 圈复杂度分析
- 代码重复检测
- 类/方法大小统计

### 3. migration-validator.sh
迁移验证和测试脚本，支持：
- 自动化测试执行
- 性能基准测试
- 代码质量检查

### 4. sandbox-manager.sh
沙盒管理脚本，支持：
- `create` - 创建沙盒
- `merge` - 合并变更
- `cleanup` - 清理沙盒
- `status` - 查看状态
- `list` - 列出所有沙盒

### 5. apply-refactor.sh
重构应用脚本，支持：
- `--dry-run` - 预览变更
- `--validate-only` - 验证模式
- `--interactive` - 交互模式
- `--rollback` - 回滚变更

---

## 配置文件

### .refactor-plan-config.yml
重构计划生成配置

### .refactor-apply-config.yml
重构应用配置

### .sandbox-config.yml
沙盒环境配置

### .refactor-config.yml
项目重构主配置

---

## 文档资源

- `docs/REFACTORING-WORKFLOW.md` - 三阶段重构工作流详解
- `docs/SANDBOX-REFACTORING.md` - 沙盒重构完整指南
- `docs/NEW-FEATURES.md` - 新功能快速参考
- `docs/NEW-ARCHITECTURE.md` - 新架构说明
- `QUICK-START.md` - 快速开始指南

---

## 最佳实践

### 1. 选择合适的工作流

- **大型迁移** → `/migrate` 完整工作流
- **中等重构** → 三阶段工作流（`/refactor-plan` + `/refactor-apply`）
- **零风险实验** → `/refactor-sandbox` 沙盒模式
- **团队协作** → 沙盒 + Branch 模式 + PR
- **快速重构** → `/refactor` 通用重构命令

### 2. 始终审查

- 不要跳过审查步骤
- 技术审查 + 业务审查
- 风险评估

### 3. 充分测试

- 单元测试
- 集成测试
- 性能测试

### 4. 渐进式合并

- 分批次合并变更
- 每批后测试验证
- 保留回滚能力

### 5. 使用适当的重构策略

- 保守策略：风险最低，改动最小
- 平衡策略：推荐默认，平衡风险和收益
- 激进策略：最大改进，风险较高

---

## 命令速查表

| 命令 | 用途 | 推荐场景 |
|------|------|----------|
| `/migrate` | 完整迁移工作流 | 大型项目微服务化 |
| `/analyze` | 代码库分析 | 了解项目结构 |
| `/plan` | 迁移计划 | 制定迁移策略 |
| `/validate` | 验证迁移 | 确保迁移正确性 |
| `/refactor-plan` | 生成重构计划 | 代码重构前规划 |
| `/refactor-apply` | 应用重构计划 | 安全应用重构 |
| `/refactor-sandbox` | 沙盒重构 | 零风险实验 |
| `/detect-project` | 项目类型检测 | 获取重构建议 |
| `/refactor` | 智能重构 | 自动检测和重构 |
| `/upgrade` | 升级框架/运行时 | 版本升级 |
| `/transpile` | 语言转换 | 跨语言迁移 |
| `/refactor-frontend` | 前端重构 | UI代码优化 |
| `/refactor-backend` | 后端重构 | 服务端优化 |
| `/refactor-universal` | 通用重构 | 灵活重构选择 |
| `/extract-service` | 服务提取 | 微服务拆分 |
| `/apply-pattern` | 设计模式 | 代码模式优化 |
| `/analyze-dependencies` | 依赖分析 | 解耦优化 |

---

## 总结

**通用重构插件提供**:

1. **完整的迁移工具链** - 从分析到实施的全流程支持
2. **安全的重构工作流** - 中间文档 + 沙盒隔离
3. **灵活的执行模式** - 支持多种场景和需求
4. **团队协作支持** - PR 工作流和远程协作
5. **全面的自动化** - 脚本和工具自动化重复任务
6. **智能项目检测** - 自动识别项目类型和技术栈
7. **多语言支持** - 支持 Java、JavaScript、Python、Go 等主流语言

**核心价值**:
- ✅ 降低迁移风险
- ✅ 提高代码质量
- ✅ 加快重构速度
- ✅ 保障业务连续性
- ✅ 支持团队协作
- ✅ 智能化重构决策

开始您的安全重构之旅吧！ 🚀