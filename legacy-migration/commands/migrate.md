---
name: migrate
description: 统一的迁移入口，集成检测、分析、规划、执行功能
aliases:
  - migrate
  - migration
usage: /migrate [options]
hidden: false
---

# 迁移助手

统一的迁移入口，智能处理从项目检测到迁移执行的全过程。

## 快速开始

```bash
# 基本使用：自动检测并执行迁移
/migrate

# 指定项目路径
/migrate --path ./my-project

# 恢复之前的会话
/migrate --resume

# 列出所有会话
/migrate --list-sessions
```

## 命令选项

### 基本选项
| 选项 | 说明 | 默认值 |
|------|------|--------|
| `--path, -p` | 项目路径 | 当前目录 |
| `--type, -t` | 项目类型 (auto/detect/java/python/go/js) | auto |
| `--strategy` | 迁移策略 (conservative/balanced/aggressive) | balanced |
| `--resume` | 恢复上次会话 | false |
| `--list-sessions` | 列出所有会话 | false |
| `--session-id` | 指定要恢复的会话ID | - |
| `--dry-run` | 试运行，不执行实际操作 | false |

### 迁移选项
| 选项 | 说明 | 默认值 |
|------|------|--------|
| `--target` | 目标技术栈 | - |
| `--from-version` | 源版本 | - |
| `--to-version` | 目标版本 | - |
| `--framework` | 框架名称 | - |
| `--scope` | 迁移范围 (service/module/full) | full |
| `--validate` | 执行验证 | true |
| `--backup` | 创建备份 | true |

### 输出选项
| 选项 | 说明 | 默认值 |
|------|------|--------|
| `--output, -o` | 输出目录 | ./migration-output |
| `--verbose, -v` | 详细输出 | false |
| `--quiet, -q` | 静默模式 | false |
| `--json` | JSON格式输出 | false |

## 使用示例

### 1. 自动迁移（推荐）
```bash
# 自动检测项目类型并执行迁移
/migrate

# 指定项目路径
/migrate --path ~/my-spring-app
```

### 2. 指定技术栈
```bash
# Java项目升级到Spring Boot 3.0
/migrate --path ~/my-java-app \
         --type java \
         --target spring-boot \
         --from-version 2.7 \
         --to-version 3.0

# Python项目迁移到FastAPI
/migrate --path ~/my-flask-app \
         --type python \
         --target fastapi \
         --strategy conservative
```

### 3. 分步执行
```bash
# 检测项目（包含分析）
/migrate --path ~/my-project --dry-run

# 执行迁移
/migrate --path ~/my-project

# 仅执行验证
/migrate --path ~/my-project --validate-only

# 查看输出结果
cat migration-output/migration-summary.md
```

### 4. 会话管理
```bash
# 查看所有会话
/migrate --list-sessions

# 恢复特定会话
/migrate --resume --session-id 2024-01-15-14:30:00

# 查看会话详情
/migrate --session-id 2024-01-15-14:30:00 --verbose
```

## 迁移流程

### 自动检测阶段
1. **项目类型识别**：自动检测编程语言和框架
2. **技术栈分析**：识别依赖项、版本、配置
3. **迁移可行性评估**：检查兼容性风险
4. **生成项目摘要**：项目结构和关键信息

### 智能规划阶段
1. **迁移策略制定**：基于项目特点选择策略
2. **依赖关系分析**：识别核心和依赖模块
3. **风险评估**：识别潜在问题和高风险区域
4. **生成迁移计划**：分步骤的实施方案

### 执行阶段
1. **项目备份**：创建完整备份（可配置）
2. **代码转换**：自动应用迁移规则
3. **配置更新**：更新构建和部署配置
4. **依赖管理**：更新依赖版本

### 验证阶段
1. **语法检查**：确保代码语法正确
2. **测试执行**：运行现有测试套件
3. **功能验证**：验证核心功能
4. **性能测试**：检查性能回归

## 输出结构

```
migration-output/
├── 01-detection/          # 项目检测结果
│   ├── project-type.json
│   ├── tech-stack.json
│   └── compatibility-report.md
├── 02-planning/           # 迁移计划
│   ├── migration-strategy.md
│   ├── risk-assessment.md
│   └── step-by-step-plan.md
├── 03-execution/          # 执行结果
│   ├── backup-location.txt
│   ├── code-changes.md
│   └── configuration-updates.md
├── 04-validation/         # 验证结果
│   ├── test-results.md
│   ├── performance-report.md
│   └── issues-found.md
└── migration-summary.md   # 最终摘要
```

## 策略说明

### Conservative（保守策略）
- **适用场景**：大型企业项目、复杂系统
- **特点**：最小化风险，详细验证，逐步推进
- **预期时间**：较长
- **风险等级**：低

### Balanced（平衡策略，默认）
- **适用场景**：大多数项目
- **特点**：平衡速度和安全性，自动化与人工审核结合
- **预期时间**：中等
- **风险等级**：中

### Aggressive（激进策略）
- **适用场景**：小型项目、实验性项目
- **特点**：最大速度，最小验证，快速迭代
- **预期时间**：短
- **风险等级**：高

## 故障排除

### 常见问题

1. **项目检测失败**
```bash
# 使用强制类型检测
/migrate --path ./my-project --type java
```

2. **迁移过程中断**
```bash
# 恢复中断的会话
/migrate --resume

# 查看详细日志
/migrate --verbose --output ./debug-output
```

3. **验证失败**
```bash
# 仅执行验证
/migrate --validate-only

# 修复问题后重新验证
/migrate --retry-validation
```

### 调试模式
```bash
# 启用详细日志
/migrate --verbose

# 生成调试报告
/migrate --debug-output ./debug-reports

# 保存中间状态
/migrate --keep-intermediate-states
```

## 与旧命令的映射

| 旧命令 | 新命令 | 说明 |
|--------|--------|------|
| `/detect-project` | `/migrate --dry-run` | 项目检测和分析 |
| `/analyze` | `/migrate --dry-run` | 项目分析 |
| `/plan` | `/migrate` 中的规划阶段 | 迁移计划制定 |
| `/migrate` | `/migrate` | 执行迁移 |
| `/validate` | `/migrate --validate-only` | 验证结果 |
| `/upgrade` | `/migrate --transform` | 版本升级 |
| `/transpile` | `/migrate --transform` | 代码转换 |

## 支持

如果遇到问题，请：
1. 检查 `migration-summary.md` 中的详细报告
2. 使用 `--verbose` 获取更多信息
3. 查看项目日志目录
4. 提交问题报告并附上完整日志