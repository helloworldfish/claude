# /start-migration

一键启动智能代码迁移助手，通过问答交互引导用户完成整个迁移流程。

## 功能概述

`/start-migration` 是 legacy-migration 插件的统一入口点，它提供：
- 智能项目检测和分析
- 交互式迁移目标确认
- 自动化工作流执行
- 增量操作支持
- 状态持久化和恢复

## 使用方法

```
/start-migration [选项]
```

## 选项

| 参数 | 必需 | 描述 |
|------|------|------|
| `--project-path <路径>` | 可选 | 项目路径，默认当前目录 |
| `--config <文件>` | 可选 | 配置文件路径 |
| `--resume` | 可选 | 恢复上次会话 |
| `--list-sessions` | 可选 | 列出所有会话 |
| `--session-id <ID>` | 可选 | 指定恢复的会话ID |
| `--verbose` | 可选 | 详细输出模式 |

## 交互流程

### 1. 初始检测
```
🚀 欢迎使用智能代码迁移助手！

正在检测您的项目...
✅ 项目类型: Spring Boot 后端应用
✅ 代码规模: 15,000 行
✅ 检测到潜在迁移机会: 3个

项目概览:
├── 框架版本: Spring Boot 2.7.x
├── Java版本: Java 11
├── 主要依赖: Spring Web, Spring Data JPA
└── 测试覆盖率: 75%

是否继续分析? (y/n): y
```

### 2. 目标确认
```
请选择您的迁移目标 (可多选):

1. [ ] 升级到 Spring Boot 3.0
2. [ ] 升级到 Java 17
3. [ ] 迁移到微服务架构
4. [ ] 转换为 Kotlin
5. [ ] 性能优化
6. [ ] 安全加固
7. [ ] 自定义目标

选择 (1-7, 默认1): 1,2,4

您选择了:
- 升级到 Spring Boot 3.0
- 升级到 Java 17
- 转换为 Kotlin

确认迁移目标? (y/n): y
```

### 3. 方案制定
```
📋 正在制定迁移方案...

方案概览:
=== 阶段1: 升级准备 ===
- 升级 Spring Boot 到 3.0
- 兼容性修复 (预计 2-3 天)
- 测试套件更新

=== 阶段2: 运行时升级 ===
- Java 11 → Java 17
- 内存配置优化
- 性能基准测试

=== 阶段3: 代码转换 ===
- Java → Kotlin 转换
- 语法优化
- 类型安全提升

预计总工期: 5-7 天
风险等级: 中等
建议开始? (y/n): y
```

### 4. 自动执行
```
🔄 开始执行迁移流程...

[📊 阶段1] 项目分析中...
✅ 完成项目类型检测
✅ 识别兼容性问题: 5个
✅ 生成依赖报告

[🏗️ 阶段2] 升级方案制定中...
✅ Spring Boot 升级路径规划
✅ Java 版本迁移策略
✅ 代码转换计划

[⚡ 阶段3] 开始执行迁移...
✅ 创建备份: .refactor-backups/2026-02-01-14:30/
✅ 应用 Spring Boot 升级
⏳ 正在转换 Java 到 Kotlin (已处理 3,500/15,000 行)

会话ID: migration-2026-02-01-14:35
进度: 35% 完成
预计剩余时间: 25 分钟

需要暂停吗? (y/n): y
```

### 5. 状态保存
```
💾 已保存会话状态:
- 会话ID: migration-2026-02-01-14:35
- 当前进度: 35%
- 已完成项目:
  - 项目分析: ✅
  - Spring Boot 升级: ✅
  - Java 到 Kotlin 转换: 🔄 (进行中)
- 恢复命令: /start-migration --resume migration-2026-02-01-14:35

再见！下次继续迁移时请使用恢复命令。
```

## 会话管理

### 列出会话
```bash
/start-migration --list-sessions
```

输出示例：
```
📋 迁移会话列表

ID                  项目路径               开始时间              状态    进度
migration-2026-02-01-14:35  /home/user/my-app  2026-02-01 14:35   暂停    35%
migration-2026-01-30-10:20  /home/user/legacy  2026-01-30 10:20   完成    100%
migration-2026-01-25-16:45  /home/user/old-sys  2026-01-25 16:45   失败    72%
```

### 恢复会话
```bash
/start-migration --resume migration-2026-02-01-14:35
```

### 删除会话
```bash
/start-migration --delete-session migration-2026-01-25-16:45
```

## 配置选项

### 创建配置文件 (start-migration.yml)
```yaml
# 项目配置
project:
  path: "./my-project"
  name: "My Application"
  type: "spring-boot"

# 迁移目标
migration_goals:
  - "framework-upgrade"
  - "runtime-upgrade"
  - "language-conversion"

# 策略设置
strategy:
  safety_level: "high"
  parallel_execution: true
  auto_backup: true
  incremental_support: true

# 通知设置
notifications:
  email: "user@example.com"
  webhook_url: "https://api.example.com/hooks/migration"
  status_updates: true
```

## 高级功能

### 增量操作
插件支持增量操作，可以从中断的位置继续：

- **增量分析**: 只分析变更的文件
- **增量转换**: 只转换修改的代码
- **增量验证**: 只验证新的变更

### 状态监控
```bash
# 查看当前状态
/start-migration --status

# 查看详细日志
/start-migration --logs --session-id migration-2026-02-01-14:35

# 实时监控
/start-migration --monitor --session-id migration-2026-02-01-14:35
```

### 自动决策模式
对于经验丰富的用户，可以使用自动决策模式：

```bash
/start-migration --auto-confirm --project-path ./my-app
```

## 错误处理

### 自动重试
- 临时网络错误: 自动重试 3 次
- 资源不足: 自动降级处理
- 依赖冲突: 提供替代方案

### 回滚机制
```bash
# 自动回滚
/start-migration --rollback migration-2026-02-01-14:35

# 部分回滚
/start-migration --partial-rollback migration-2026-02-01-14:35 --to-step 2
```

## 最佳实践

1. **首次使用**: 建议先使用 `--config` 指定配置文件
2. **大型项目**: 启用 `--verbose` 查看详细进度
3. **长时间操作**: 定期保存状态，防止意外中断
4. **生产环境**: 先在测试环境验证，再应用到生产

## 输出示例

### 成功完成
```
🎉 迁移完成！

总结报告:
- 原始项目: Spring Boot 2.7 + Java 11
- 目标状态: Spring Boot 3.0 + Java 17 + Kotlin
- 处理文件: 234 个
- 转换代码: 15,000 行
- 修复问题: 45 个
- 耗时: 2 小时 15 分钟
- 成功率: 98%

输出位置:
- 代码: ./migrated-code/
- 报告: ./migration-report/
- 备份: .refactor-backups/migration-2026-02-01-14:35/

可以安全地部署到生产环境！
```

## 故障排除

### 常见问题

1. **会话恢复失败**
   ```bash
   # 清除 corrupted 会话
   /start-migration --cleanup-sessions
   ```

2. **权限问题**
   ```bash
   # 确保有写入权限
   chmod -R 755 ./my-project
   ```

3. **内存不足**
   ```bash
   # 启用低内存模式
   /start-migration --memory-efficient
   ```

### 日志查看
```bash
# 查看系统日志
tail -f /tmp/legacy-migration.log

# 查看会话日志
cat /tmp/sessions/migration-2026-02-01-14-35.log
```

## 支持

如有问题，请查看：
1. 完整文档: `README.md`
2. 错误代码: `ERROR_CODES.md`
3. 示例项目: `examples/`
4. 联系支持: `support@anthropic.com`

---

**提示**: 使用 `/start-migration 开始您的第一次智能迁移体验！