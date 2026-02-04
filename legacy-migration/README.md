# Legacy-Migration 智能代码迁移助手

一个全面智能化的Claude Code插件，将复杂的代码重构和迁移任务简化为简单的交互式流程。支持一键启动、智能问答交互、增量操作和状态恢复。

## 概述

通用重构插件提供了智能代理、自动化工具和最佳实践，指导组织完成各种代码转换场景。从遗留系统现代化到前沿技术采用，它支持端到端的重构，具有自动项目检测、智能推荐和安全执行功能。

## 🚀 v3.1.0 智能迁移助手 新特性

### 智能迁移助手
- **一键启动**：`/start-migration` 命令简化用户操作
- **智能问答**：交互式问答引导用户选择迁移目标
- **增量操作**：只处理变更的文件，效率提升 60%+
- **状态管理**：完整的会话生命周期管理和持久化
- **自动恢复**：支持中断后继续工作，零丢失
- **自动备份**：安全可靠的备份和回滚机制

### 通用重构支持
- **多语言支持**：Java、JavaScript/TypeScript、Python、Go、C#、Ruby、PHP等
- **前端和后端重构**：专用于UI和服务器端代码的命令
- **框架升级**：Spring Boot、React、Vue、Django、.NET等自动化迁移
- **运行时升级**：Java（8→17→21）、Node.js、Python、Go版本迁移
- **语言转换**：Java↔Kotlin、JavaScript→TypeScript、Python→Go等
- **智能检测**：自动项目类型和技术栈分析

## 功能特性

### 🤖 智能代理

#### 核心迁移代理
- **单体分析器**：全面的代码库分析和架构评估
- **迁移架构师**：目标微服务架构设计
- **依赖映射器**：依赖图生成和耦合分析
- **转换顾问**：代码重构策略和设计模式
- **验证工程师**：迁移验证和业务连续性保障
- **迁移规划师**：详细路线图创建和资源规划

#### 新通用重构代理
- **项目类型检测器**：智能项目分析和技术栈检测
- **框架升级器**：框架版本迁移和破坏性变更处理
- **运行时升级器**：运行时版本升级（Java、Node.js、Python、Go）

### 🛠️ 命令

#### 智能迁移命令
- **/start-migration**：一键启动智能迁移助手，交互式引导整个流程
- **/detect-project**：自动识别项目类型和技术栈
- **/plan**：制定详细的迁移路线图和时间表
- **/validate**：验证迁移结果的正确性

#### 重构工作流命令
- **/refactor**：智能重构，支持多种重构模式
- **/upgrade**：框架和运行时版本升级
- **/transpile**：编程语言间转换
- **/migrate**：执行具体的迁移任务

## 🚀 快速开始

### 基础使用

```bash
# 1. 安装插件
claude plugin install legacy-migration@local-marketplace

# 2. 一键开始迁移
/start-migration

# 3. 系统会自动检测项目并引导您完成选择
```

### 高级功能

```bash
# 智能迁移助手
/start-migration --resume                    # 恢复上次工作
/start-migration --project-path ./my-project # 指定项目路径
/start-migration --list-sessions              # 查看所有会话

# 项目检测
/detect-project --path ./legacy-system       # 检测指定项目

# 框架升级
/upgrade --target . --upgrade_type framework --framework spring-boot --to-version 3.0

# 语言转换
/transpile --source src --from java --to kotlin --output src-kotlin
```

## 📚 文档资源

- **[快速开始指南](./QUICK_START_GUIDE.md)** - 详细的快速开始教程和示例

## 安装

插件可在本地市场使用。安装命令：

```bash
claude plugin install legacy-migration@local-marketplace
```

## 快速开始

### 场景1：框架升级（Spring Boot）

```bash
# 1. 检测项目并获取建议
/detect-project --path ~/my-spring-app

# 2. 查看推荐升级
# 输出显示：Spring Boot 2.7 → 3.0，Java 11 → 17

# 3. 执行Spring Boot升级
/upgrade --target . --upgrade_type framework --framework spring-boot --to-version 3.0

# 4. 验证升级
/validate --validation_type backend
```

### 场景2：React现代化

```bash
# 1. 检测项目
/detect-project --path ~/my-react-app

# 2. 升级React框架
/upgrade --target . --upgrade_type framework --framework react --to-version 18

# 3. 重构为使用Hooks
/refactor-frontend --target src --strategy modernization

# 4. 转换为TypeScript
/transpile --source src --from javascript --to typescript --output src-ts
```

### 场景3：Java到Kotlin迁移

```bash
# 1. 分析Java项目
/detect-project --path ~/my-java-app

# 2. 转换Java到Kotlin
/transpile --source src/main/java --from java --to kotlin --output src/main/kotlin

# 3. 更新构建配置（手动或辅助）
# 4. 验证
/validate --validation_type backend
```

### 场景4：单体应用到微服务

```bash
# 1. 分析单体应用
/analyze --project_path ~/my-monolith --analysis_type all

# 2. 创建迁移计划
/plan --analysis_results ~/my-monolith/analysis-output --migration_strategy strangler-fig

# 3. 提取第一个微服务
/migrate --scope=service --project_path ~/my-monolith --service=user-service

# 4. 验证提取
/validate --validation_type all
```

### 场景5：多阶段全栈升级

```bash
# 第一阶段：后端运行时升级
/upgrade --target backend --upgrade_type runtime --runtime java --to-version 17

# 第二阶段：后端框架升级
/upgrade --target backend --upgrade_type framework --framework spring-boot --to-version 3.0

# 第三阶段：前端框架升级
/upgrade --target frontend --upgrade_type framework --framework react --to-version 18

# 第四阶段：前端TypeScript迁移
/transpile --source frontend/src --from javascript --to typescript --output frontend/src-ts
```

## 支持的重构类型

### 1. 框架升级
- **后端**：Spring Boot（2→3）、Django（3→5）、.NET Core、Express→NestJS
- **前端**：React（17→18）、Vue（2→3）、Angular版本升级

### 2. 运行时升级
- **Java**：8 → 11 → 17 → 21
- **Node.js**：14 → 16 → 18 → 20
- **Python**：3.8 → 3.9 → 3.10 → 3.11 → 3.12
- **Go**：版本升级和语言变化
- **.NET**：框架版本升级

### 3. 语言转换
- **Java → Kotlin**：JVM语言迁移
- **Java → C#**：平台迁移
- **JavaScript → TypeScript**：添加类型安全
- **Python → Go**：性能和并发
- **PHP → Node.js**：平台现代化

### 4. 架构重构
- **单体 → 微服务**：服务提取
- **微服务 → 单体**：合并
- **分层架构清理**：更好的关注点分离
- **事件驱动迁移**：添加异步消息

### 5. 前端重构
- **组件结构**：提取可重用组件
- **状态管理**：Redux→Zustand，Context API优化
- **性能**：代码分割、记忆化、虚拟化
- **现代化**：类组件→Hooks，CSS采用

### 6. 后端重构
- **API设计**：RESTful最佳实践，GraphQL采用
- **数据库层**：Repository模式，查询优化
- **服务架构**：分层架构，DDD
- **性能**：缓存、异步处理、连接池

### 7. 代码质量
- **设计模式**：应用GoF模式
- **代码异味**：消除重复，简化复杂度
- **技术债务**：系统性债务减少
- **测试**：改善测试覆盖率和质量

## 命令参考

### 项目检测

```bash
/detect-project --path <路径>
```

分析项目结构、技术栈，并推荐重构选项。

**示例**：
```bash
/detect-project --path ~/my-project
```

**输出**：
- 项目类型（前端/后端/全栈）
- 主要语言和版本
- 框架版本
- 推荐的重构选项
- 要执行的命令

### 通用重构

```bash
/refactor --target <路径> --type <类型> [选项]
```

智能重构，自动选择策略。

**类型**：
- `auto` - 自动检测和推荐
- `framework-upgrade` - 升级框架版本
- `runtime-upgrade` - 升级运行时版本
- `transpile` - 语言间转换
- `architecture` - 架构重构
- `quality` - 代码质量改进
- `performance` - 性能优化

**示例**：
```bash
/refactor --target . --type auto
/refactor --target . --type framework-upgrade --framework spring-boot --to-version 3.0
```

### 框架/运行时升级

```bash
/upgrade --target <路径> --upgrade_type <类型> [选项]
```

**升级类型**：
- `framework` - 框架版本升级
- `runtime` - 运行时版本升级
- `dependencies` - 所有依赖
- `security` - 仅安全更新

**示例**：
```bash
/upgrade --target . --upgrade_type framework --framework spring-boot --to-version 3.0
/upgrade --target . --upgrade_type runtime --runtime java --to-version 17
```

### 语言转换

```bash
/transpile --source <路径> --from <语言> --to <语言> --output <路径>
```

**示例**：
```bash
/transpile --source src/main/java --from java --to kotlin --output src/main/kotlin
/transpile --source src --from javascript --to typescript --output src-ts
```

### 前端/后端重构

```bash
/refactor-frontend --target <路径> --strategy <策略>
/refactor-backend --target <路径> --strategy <策略>
```

**前端策略**：
- `component-structure` - 提取和组织组件
- `state-migration` - 迁移状态管理
- `performance` - 优化渲染和加载
- `modernization` - 采用现代模式

**后端策略**：
- `api-design` - RESTful API最佳实践
- `database-layer` - Repository模式优化
- `service-architecture` - 分层架构或DDD
- `performance` - 缓存和异步处理

## 架构重构工作流

### 绞杀者模式（推荐）

```
单体应用
    ↓
识别候选服务
    ↓
创建并行微服务
    ↓
逐步路由流量
    ↓
停用单体代码
```

**优势**：
- 零停机迁移
- 逐步切换
- 易于回滚
- 低风险

## 配置

### 项目配置（`.refactor-config.yml`）

```yaml
project:
  auto_detect: true
  type: auto  # auto, monolith, microservice, frontend, backend

refactoring:
  strategy: balanced  # conservative, balanced, aggressive
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
  security_scan: false

output:
  format: markdown
  include_diffs: true
  include_metrics: true
```

## 最佳实践

### 重构前
1. ✅ 运行 `/detect-project` 了解你的代码库
2. ✅ 审查所有推荐的重构选项
3. ✅ 创建功能分支
4. ✅ 确保测试通过
5. ✅ 记录当前状态

### 重构中
1. ✅ 从保守策略开始
2. ✅ 每个阶段后验证
3. ✅ 准备好回滚计划
4. ✅ 监控错误
5. ✅ 记录变更

### 重构后
1. ✅ 运行全面测试
2. ✅ 执行手动测试
3. ✅ 测量性能
4. ✅ 更新文档
5. ✅ 验证后合并到主分支

## 安全特性

### 自动备份
所有重构操作都会创建自动备份：
```bash
.refactor-backups/
└── 2025-12-30-15:30/
    ├── backup-manifest.json
    ├── files.list
    ├── sha256sum.txt
    └── [原始文件]
```

### 回滚支持
```bash
# 验证失败时自动回滚
/refactor-apply --rollback <备份位置>

# 使用Git手动回滚
git reset --hard HEAD~1
git clean -fd
```

### 验证管道
- 编译验证
- 测试执行
- 代码质量检查
- 性能验证
- 安全扫描

## 成功指标

### 技术指标
- **框架版本**：与最新的LTS保持同步
- **运行时版本**：当前稳定版本
- **代码质量**：改进的指标
- **测试覆盖率**：保持或改善
- **性能**：无回退

### 业务指标
- **功能速度**：更快的开发
- **可维护性**：更容易修改
- **稳定性**：减少bug
- **开发人员满意度**：改善的体验

## 故障排除

### 常见问题

#### 升级失败
```bash
# 检查不兼容的依赖
/analyze --project_path . --analysis_type dependencies

# 尝试增量升级
/upgrade --target . --upgrade_type framework --framework spring-boot --to-version 2.7
```

#### 转换错误
```bash
# 降低分析深度以获得更简单的输出
/transpile --source src --from java --to kotlin --output src-kotlin

# 查看并修复手动问题
```

#### 验证失败
```bash
# 检查详细日志
/validate --validation_type all --verbose

# 如需要，回滚
/refactor-apply --rollback .refactor-backups/latest/
```

## 贡献

我们欢迎贡献！有关详细信息，请参阅我们的[贡献指南](CONTRIBUTING.md)。

### 开发设置

```bash
# 克隆插件仓库
git clone <repository-url>
cd legacy-migration

# 验证插件结构
claude plugin validate .

# 在本地测试插件
# 添加到本地市场并测试
```

## 支持

- **文档**：查看此README和内联文档
- **问题**：在[GitHub仓库](https://github.com/anthropics/claude-plugins-official)报告问题
- **社区**：加入我们的[Discord社区](https://discord.gg/claude-code)

## 更新日志

### 版本 3.0.0（当前）
- ✨ 支持多种项目类型的通用重构
- ✨ 智能项目类型检测
- ✨ 框架升级自动化（Spring Boot、React、Vue、Django、.NET）
- ✨ 运行时升级支持（Java、Node.js、Python、Go）
- ✨ 语言转换（Java↔Kotlin、JS→TS、Python→Go）
- ✨ 专用前端/后端重构命令
- ✨ 多语言支持（Java、JavaScript、Python、Go、C#、Ruby、PHP）
- ✨ 增强的安全功能，支持自动备份和回滚
- ✨ 全面的升级指南和破坏性变更文档

### 版本 2.0.0
- ✨ 三阶段重构工作流（计划、评审、应用）
- ✨ 沙盒重构环境
- ✨ 增强的验证和回滚机制
- ✨ 改进的依赖分析

### 版本 1.0.0
- 🎉 初始发布，包含单体到微服务迁移
- 🎉 六个智能代理支持全面迁移
- 🎉 四个主要命令用于迁移协调
- 🎉 三个知识库技能用于最佳实践
- 🎉 三个自动化脚本用于分析和验证

## 许可证

本插件采用MIT许可证。详情请参见[LICENSE](LICENSE)。

## 致谢

由Anthropic的Claude Code团队创建。

---

**使用通用重构插件自信地转换你的代码！** 🚀

从遗留单体应用到前沿微服务，从过时框架到现代技术，我们都能为你提供支持。