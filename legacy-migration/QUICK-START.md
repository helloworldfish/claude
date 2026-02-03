# 快速开始指南

## 概述

通用重构插件提供零风险的重构体验。本指南将帮助您快速上手。

## 安装

```bash
claude plugin install legacy-migration@local-marketplace
```

## 基本工作流

### 方法1：三阶段重构工作流（推荐）

```bash
# 1. 生成重构计划
/refactor-plan --target src/main/java/service/UserService.java

# 2. 审查计划
cat ./refactoring-plans/*/01-refactoring-plan.md

# 3. 应用重构
/refactor-apply --plan ./refactoring-plans/*/
```

### 方法2：沙盒重构（零风险）

```bash
# 1. 创建沙盒
/refactor-sandbox --source . --target ./sandbox/ --mode clone

# 2. 在沙盒中工作
cd sandbox/
/refactor-plan --target .
/refactor-apply --plan ./refactoring-plans/*/

# 3. 生成差异
cd ..
/refactor-sandbox --source . --target ./sandbox/ --merge_strategy diff

# 4. 审查并应用
cat patches/*.diff
git apply patches/001-change.diff

# 5. 清理
rm -rf sandbox/
```

### 方法3：智能重构（最简单）

```bash
# 自动检测并重构
/refactor --target . --type auto

# 特定类型重构
/refactor --target . --type framework-upgrade --framework spring-boot --to-version 3.0
```

## 快速示例

### 场景1：项目检测和分析

```bash
# 检测项目类型和技术栈
/detect-project --path ~/my-project

# 分析代码库
/analyze --target . --depth 3
```

### 场景2：Spring Boot升级

```bash
# 检测项目
/detect-project --path ~/my-spring-app

# 升级框架
/upgrade --target . --upgrade_type framework --framework spring-boot --to-version 3.0

# 验证升级
/validate --validation_type backend
```

### 场景3：React现代化

```bash
# 检测项目
/detect-project --path ~/my-react-app

# 升级React
/upgrade --target . --upgrade_type framework --framework react --to-version 18

# 重构为Hooks
/refactor-frontend --target src --strategy modernization

# 转换为TypeScript
/transpile --source src --from javascript --to typescript --output src-ts
```

### 场景4：微服务提取

```bash
# 分析单体应用
/migrate --project ~/my-monolith --output ./migration-output/

# 提取服务
/extract-service --target ~/my-monolith --service user-service --boundary "src/main/java/user/*"

# 验证提取
/validate --validation_type all
```

## 配置

### 基本配置文件（.refactor-config.yml）

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

## 命令速查

| 命令 | 用途 | 示例 |
|------|------|------|
| `/detect-project` | 检测项目 | `/detect-project --path .` |
| `/refactor` | 智能重构 | `/refactor --target . --type auto` |
| `/refactor-plan` | 生成计划 | `/refactor-plan --target src` |
| `/refactor-apply` | 应用重构 | `/refactor-apply --plan ./plans/` |
| `/refactor-sandbox` | 沙盒重构 | `/refactor-sandbox --source . --target ./sandbox/` |
| `/upgrade` | 升级框架 | `/upgrade --target . --framework spring-boot` |
| `/transpile` | 语言转换 | `/transpile --from java --to kotlin` |
| `/migrate` | 完整迁移 | `/migrate --project . --output ./out/` |

## 最佳实践

### 1. 从小开始
```bash
# 先测试单个文件
/refactor-plan --target PaymentService.java
```

### 2. 始终备份
```bash
# 检查自动备份
ls .refactor-backups/
```

### 3. 分步验证
```bash
# 每步后验证
/validate --validation_type test
```

### 4. 团队协作
```bash
# 使用分支模式
/refactor-sandbox --source . --mode branch --git_branch refactor/experiment
```

## 故障排除

### 常见问题

#### 问题：命令不存在
```bash
# 检查插件安装
claude plugin list | grep legacy-migration
```

#### 问题：权限错误
```bash
# 给脚本执行权限
chmod +x scripts/*.sh
```

#### 问题：分析失败
```bash
# 降低分析深度
/analyze --target . --depth 1
```

### 获取帮助

```bash
# 查看命令帮助
/refactor --help

# 查看所有命令
claude plugin commands legacy-migration@local-marketplace
```

## 下一步

1. 阅读 [README.md](README.md) 了解完整功能
2. 查看 [PLUGIN-GUIDE.md](PLUGIN-GUIDE.md) 了解详细用法
3. 查看 [docs/](docs/) 目录获取更多文档

开始您的重构之旅吧！🚀