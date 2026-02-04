# 上下文管理机制修复说明

## 概述

本修复解决了项目中上下文管理机制中导致超出限制的问题，实现了统一的上下文管理和智能压缩功能。

## 问题分析

### 原有问题
1. **阈值设置不统一**：不同脚本使用不同的阈值
2. **Token估算不准确**：使用固定值，未考虑实际文件大小
3. **压缩效果有限**：仅支持代码文件压缩
4. **监控不够全面**：缺少实时预警机制

### 修复方案
1. 创建统一的配置文件 `context-config.json`
2. 实现基于实际文件大小的智能token估算
3. 增强压缩策略，支持多种文件类型
4. 完善监控机制，添加实时预警

## 组件说明

### 1. 统一配置文件 (`context-config.json`)

```json
{
  "context_thresholds": {
    "warning": 150000,
    "preventive": 160000,
    "cleanup": 170000,
    "critical": 180000,
    "emergency": 195000,
    "hard_limit": 200000
  },
  "compression_levels": {
    "level_1": {"trigger_ratio": 0.75, "compression_ratio": 0.4},
    "level_2": {"trigger_ratio": 0.85, "compression_ratio": 0.6},
    "level_3": {"trigger_ratio": 0.95, "compression_ratio": 0.8}
  }
}
```

### 2. Token计算器 (`scripts/token-calculator.sh`)

**功能**：
- 基于实际文件大小精确计算token使用量
- 支持多种文件类型的权重调整
- 提供安全边际估算

**使用方法**：
```bash
# 估算单个文件token数
./scripts/token-calculator.sh file-tokens <文件路径>

# 估算步骤token使用量
./scripts/token-calculator.sh estimate-step <STEP_NAME> <项目路径>

# 生成token使用报告
./scripts/token-calculator.sh report <项目路径> <输出文件>
```

### 3. 上下文压缩器 (`scripts/context-compressor.sh`)

**功能**：
- 支持多种文件类型的智能压缩
- 三级压缩策略（预防性、清理、紧急）
- 自动备份机制

**使用方法**：
```bash
# 手动压缩
./scripts/context-compressor.sh compress <项目路径> <level_1|level_2|level_3>

# 自动压缩
./scripts/context-compressor.sh auto-compress <项目路径>

# 生成压缩报告
./scripts/context-compressor.sh report <项目路径> <输出文件>
```

### 4. 上下文监控器 (`scripts/context-monitor.sh`)

**功能**：
- 实时监控上下文使用情况
- 多级预警机制
- 自动触发压缩
- 日志记录

**使用方法**：
```bash
# 启动实时监控
./scripts/context-monitor.sh start

# 检查当前状态
./scripts/context-monitor.sh check

# 生成状态报告
./scripts/context-monitor.sh status

# 查看日志
./scripts/context-monitor.sh logs
```

### 5. 集成测试脚本 (`scripts/context-integration-test.sh`)

**功能**：
- 验证所有组件的一致性
- 测试各组件功能
- 检查阈值设置

**使用方法**：
```bash
# 运行所有测试
./scripts/context-integration-test.sh

# 测试特定组件
./scripts/context-integration-test.sh token
./scripts/context-integration-test.sh compress
./scripts/context-integration-test.sh monitor
```

## 使用示例

### 完整工作流程

1. **启动迁移并启用上下文管理**
```bash
./scripts/migration-assistant.sh start --project-path ./my-project
```

2. **实时监控上下文使用**
```bash
# 在另一个终端运行
./scripts/context-monitor.sh start
```

3. **查看当前上下文状态**
```bash
./scripts/token-calculator.sh report ./my-project ./context-usage.json
```

4. **自动压缩（当触发阈值时）**
```bash
# 系统会自动触发压缩
# 也可以手动执行
./scripts/context-compressor.sh auto-compress ./my-project
```

### 命令行使用

```bash
# 查看预估token使用
./scripts/token-calculator.sh estimate-step transform ./my-project

# 检查阈值状态
./scripts/context-monitor.sh check

# 生成完整报告
./scripts/context-integration-test.sh test
```

## 配置说明

### 阈值设置
- **warning (150K)**：预警级别，开始准备压缩
- **preventive (160K)**：预防性压缩，触发level_1压缩
- **cleanup (170K)**：清理压缩，触发level_2压缩
- **critical (180K)**：关键级别，触发level_3压缩
- **emergency (195K)**：紧急级别，立即压缩
- **hard_limit (200K)**：硬限制，停止操作

### 压缩策略
- **level_1**：保留完整结构，压缩注释和次要内容（40%压缩率）
- **level_2**：提取关键信息，保留主要结构（60%压缩率）
- **level_3**：仅保留核心配置和必要信息（80%压缩率）

### 支持的文件类型
- 代码文件：.java, .py, .js, .ts, .go, .c, .cpp, .cs
- 配置文件：.yml, .yaml, .json, .xml, .properties
- 文档文件：.md, .txt, .rst, .adoc
- 构建文件：pom.xml, build.gradle, package.json, requirements.txt

## 故障排除

### 常见问题

1. **jq命令未找到**
```bash
# 安装jq
brew install jq  # macOS
sudo apt-get install jq  # Ubuntu
```

2. **权限问题**
```bash
# 确保所有脚本有执行权限
chmod +x scripts/*.sh
```

3. **配置文件读取失败**
```bash
# 检查配置文件格式
cat context-config.json | jq .

# 确保文件存在
ls -la context-config.json
```

### 调试方法

1. **查看日志**
```bash
tail -f .context-monitor-logs/context-monitor.log
```

2. **测试单个组件**
```bash
./scripts/token-calculator.sh file-tokens README.md
./scripts/context-monitor.sh check
```

3. **验证配置**
```bash
./scripts/context-integration-test.sh check
```

## 性能优化

### 优化建议

1. **定期清理**：定期清理压缩备份文件
2. **监控日志**：定期归档监控日志
3. **调整阈值**：根据项目特点调整阈值
4. **并行处理**：对于大型项目，使用并行压缩

### 维护任务

```bash
# 清理旧备份
find .context-compression-backups -mtime +7 -delete

# 清理日志
find .context-monitor-logs -name "*.log" -mtime +7 -delete

# 验证配置
./scripts/context-integration-test.sh test
```

## 总结

通过这次修复，我们实现了：
- ✅ 统一的阈值配置
- ✅ 智能的token估算
- ✅ 多级压缩策略
- ✅ 实时监控预警
- ✅ 完整的测试验证

现在系统能够有效预防上下文超出限制的问题，并提供智能的压缩和管理功能。