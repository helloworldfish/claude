# Legacy-Migration 快速开始指南

**版本：3.1.0**
**更新时间：** 2026-02-01

---

## 🎯 概览

Legacy-Migration 现已升级为 **智能代码迁移助手**，提供一键启动、智能问答交互、增量操作和状态恢复功能。用户只需一个命令即可开始复杂的代码迁移工作！

---

## 🚀 快速开始

### 1. 初始化系统

```bash
# 首次使用时初始化
./scripts/migration-assistant.sh init
```

### 2. 开始第一次迁移

```bash
# 简单启动，会引导完成整个过程
./scripts/migration-assistant.sh start ./my-project

# 自动模式（无交互）
./scripts/migration-assistant.sh start ./my-project --auto

# 详细日志模式
./scripts/migration-assistant.sh start ./my-project --verbose
```

### 3. 体验智能交互

启动后，系统会：

1. **自动检测项目**
   ```
   🚀 欢迎使用智能代码迁移助手！

   正在检测您的项目...
   ✅ 项目类型: Spring Boot 后端应用
   ✅ 代码规模: 15,000 行
   ✅ 检测到潜在迁移机会: 3个
   ```

2. **智能问答**
   ```
   请选择您的迁移目标:
   1. [ ] 升级到 Spring Boot 3.0
   2. [ ] 升级到 Java 17
   3. [ ] 迁移到微服务架构
   4. [ ] 转换为 Kotlin
   5. [ ] 性能优化
   6. [ ] 安全加固
   7. [ ] 自定义目标

   选择 (1-7, 默认1): 1,2,4
   ```

3. **自动执行**
   ```
   📋 正在制定迁移方案...
   🔄 开始执行迁移流程...
   ✅ 完成项目分析
   ✅ Spring Boot 升级
   ⏳ 正在转换 Java 到 Kotlin (35% 完成)
   ```

---

## 🔄 状态管理

### 查看所有会话

```bash
# 列出所有迁移会话
./scripts/migration-assistant.sh list
```

输出示例：
```
📋 迁移会话列表

Session ID                  项目路径               开始时间              状态    进度
migration-2026-02-01-14:35  /home/user/my-app    2026-02-02 14:35   运行中   35%
migration-2026-01-30-10:20  /home/user/legacy   2026-01-30 10:20   完成    100%
```

### 暂停和恢复

```bash
# 优雅暂停（Ctrl+C 或手动暂停）
# 下次对话时自动保存状态

# 恢复上次的工作
./scripts/migration-assistant.sh resume

# 恢复特定会话
./scripts/migration-assistant.sh resume migration-2026-02-01-14:35
```

### 查看状态

```bash
# 查看当前会话状态
./scripts/migration-assistant.sh status

# 查看特定会话状态
./scripts/migration-assistant.sh status migration-2026-02-01-14:35
```

---

## 📈 增量操作

### 系统自动支持增量操作

- **第一次运行**：分析整个项目，创建基线
- **后续运行**：只处理变更的文件
- **智能缓存**：避免重复计算和转换

### 手动触发增量处理

```bash
# 检测项目变化
./scripts/incremental-processor.sh detect ./my-project migration-2026-02-01-14:35

# 获取需要处理的文件
./scripts/incremental-processor.sh files modified 10 migration-2026-02-01-14:35

# 标记文件为已处理
./scripts/incremental-processor.sh mark-processed src/Main.java migration-2026-02-01-14:35 "5s" true
```

### 增量操作统计

```bash
# 查看增量处理统计
./scripts/incremental-processor.sh stats migration-2026-02-01-14:35
```

输出示例：
```json
{
  "total_files": 234,
  "processed_files": 156,
  "pending_files": 12,
  "failed_files": 2,
  "progress_percent": 67
}
```

---

## 💾 状态持久化

### 自动保存机制

- **每完成一个步骤**：自动保存状态
- **创建检查点**：关键节点自动创建快照
- **崩溃恢复**：意外中断后可恢复

### 状态存储位置

```
~/.legacy-migration/
├── sessions/           # 会话数据
│   └── migration-2026-02-01-14:35/
│       ├── config/     # 配置文件
│       ├── state/      # 状态数据
│       ├── logs/       # 日志文件
│       └── checkpoints/ # 检查点
├── state/              # 全局状态
├── cache/              # 缓存数据
├── recovery/           # 恢复数据
└── temp/               # 临时文件
```

### 数据导出

```bash
# 导出会话数据
./scripts/session-manager.sh export migration-2026-02-01-14:35 ./migration-backup.tar.gz

# 导出增量数据
./scripts/incremental-processor.sh export migration-2026-02-01-14:35 ./incremental-data.tar.gz
```

---

## 🛠️ 高级功能

### 自动模式

```bash
# 完全自动执行（无用户交互）
./scripts/migration-assistant.sh start ./my-project --auto

# 自动模式 + 详细日志
./scripts/migration-assistant.sh start ./my-project --auto --verbose
```

### 配置文件

创建自定义配置文件 `my-config.yml`：

```yaml
migration:
  goals:
    - "framework-upgrade"
    - "runtime-upgrade"
  strategy: "balanced"
  safety_level: "high"
  parallel_execution: true

project:
  auto_detect: true
  type: "spring-boot"

validation:
  compile: true
  test: true
  lint: true

notifications:
  status_updates: true
  email: "team@example.com"
```

使用自定义配置：
```bash
./scripts/migration-assistant.sh start ./my-project my-config.yml
```

### 清理旧数据

```bash
# 清理30天前的旧数据
./scripts/migration-assistant.sh cleanup 30

# 清理所有数据（谨慎使用）
./scripts/migration-assistant.sh cleanup 0
```

---

## 🎯 实际使用场景

### 场景1：大型项目逐步迁移

```bash
# 第一次：启动迁移
./scripts/migration-assistant.sh start ./large-project

# 中途暂停（Ctrl+C）
# 系统自动保存进度

# 下次：恢复迁移
./scripts/migration-assistant.sh resume
```

### 场景2：团队协作

```bash
# 开发者1：开始迁移
./scripts/migration-assistant.sh start ./team-project

# 导出进度
./scripts/session-manager.sh export session-id ./progress-export.tar.gz

# 开发者2：导入并继续
./scripts/session-manager.sh import ./progress-export.tar.gz
./scripts/migration-assistant.sh resume session-id
```

### 场景3：快速验证

```bash
# 自动模式快速验证
./scripts/migration-assistant.sh start ./test-project --auto

# 查看结果
./scripts/migration-assistant.sh status
```

---

## 🔧 故障排除

### 常见问题

#### 1. 会话无法恢复
```bash
# 列出可用的恢复点
./scripts/state-restorer.sh list

# 手动恢复
./scripts/state-restorer.sh restore session session-id session-path
```

#### 2. 增量处理失败
```bash
# 重新初始化增量处理
./scripts/incremental-processor.sh init

# 重新检测变化
./scripts/incremental-processor.sh detect ./project session-id
```

#### 3. 状态损坏
```bash
# 清理损坏的会话
rm -rf ~/.legacy-migration/sessions/corrupted-session-id

# 重新初始化
./scripts/migration-assistant.sh init
```

### 日志查看

```bash
# 查看系统日志
tail -f ~/.legacy-migration/temp/assistant.log

# 查看特定会话日志
tail -f ~/.legacy-migration/sessions/session-id/logs/session.log
```

### 调试模式

```bash
# 启用详细调试
./scripts/migration-assistant.sh start ./project --verbose

# 查看调试信息
grep DEBUG ~/.legacy-migration/temp/assistant.log
```

---

## 📊 性能优化

### 大型项目处理

1. **增量处理**：只处理变更的文件
2. **并行执行**：启用 `parallel_execution: true`
3. **内存控制**：设置合理的 `max_memory_usage`
4. **分批处理**：配置 `max_files_per_batch`

### 缓存策略

```bash
# 清理缓存
rm -rf ~/.legacy-migration/cache/*

# 查看 cache 大小
du -sh ~/.legacy-migration/cache/
```

---

## 🎉 最佳实践

### 1. 首次使用
- 先在测试环境验证
- 使用 `--verbose` 查看详细日志
- 定期保存状态

### 2. 大型项目
- 启用增量支持
- 使用配置文件
- 定期导出备份

### 3. 团队协作
- 使用统一的配置
- 定期同步进度
- 保持沟通状态

### 4. 生产环境
- 先在预发布环境测试
- 准备回滚计划
- 监控执行状态

---

## 📞 支持

如有问题，请查看：
1. 完整文档：`README.md`
2. 故障排除：`TROUBLESHOOTING.md`
3. API 文档：`API_REFERENCE.md`
4. 示例项目：`examples/`
5. 联系支持：`support@anthropic.com`

---

**提示**: 现在开始您的智能迁移之旅吧！只需一个命令即可！ 🚀