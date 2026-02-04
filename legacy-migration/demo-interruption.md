# 中断和恢复功能演示

## 功能概述

Legacy Migration 插件现在已经具备完整的中断和恢复功能：

### 🔧 **中断时自动状态保存**

当用户按下 `Ctrl+C` 或进程被意外中断时，插件会：

1. **捕获中断信号**：自动捕获 SIGINT 和 SIGTERM
2. **保存当前状态**：
   - 更新会话状态为 "interrupted"
   - 记录中断时间戳
   - 保存当前进度
3. **创建检查点**：自动保存 `interrupted` 检查点
4. **显示恢复信息**：提示用户如何恢复

### 📋 **待办清单记录**

插件会详细记录：

- **已完成的步骤**：`steps_completed`
- **失败的步骤**：`steps_failed`（包含错误信息）
- **正在进行的步骤**：`steps_in_progress`
- **未完成的步骤**：通过对比计划自动计算
- **进度百分比**：实时更新

### 🔄 **恢复功能**

恢复时会：

1. **检测中断的会话**：自动识别状态为 "interrupted" 的会话
2. **显示恢复摘要**：
   - 项目信息
   - 当前进度
   - 待完成任务列表
   - 恢复命令
3. **确认恢复**：用户确认后继续执行
4. **增量恢复**：从中断点继续，不会重复已完成的工作

## 实际使用场景

### 场景1：长时间迁移被中断

```bash
# 1. 开始迁移（可能在后台运行）
./commands/start-migration --project-path ./my-large-project --auto

# 2. 运行过程中按 Ctrl+C 中断
# 系统会自动保存状态并显示:
# 状态已保存，可以通过以下命令恢复: ./commands/start-migration --resume --session-id my-project-2026-02-03-1430

# 3. 稍后恢复
./commands/start-migration --resume --session-id my-project-2026-02-03-1430
```

### 场景2：手动暂停迁移

```bash
# 在交互模式下执行
./commands/start-migration --project-path ./my-project

# 在步骤执行过程中按 Ctrl+C
# 会显示恢复摘要，包含待完成任务列表

# 恢复时会从中断的步骤继续
```

### 场景3：查看恢复摘要

```bash
# 查看所有可恢复的会话
./commands/start-migration --list-sessions

# 查看特定会话的恢复摘要
./commands/start-migration --resume --session-id my-project-2026-02-03-1430
# 会显示详细的恢复信息，包括待完成任务
```

## 技术实现细节

### 中断处理流程

```bash
trap handle_interrupt SIGINT SIGTERM

handle_interrupt() {
    # 1. 设置中断标志
    INTERRUPTED=true

    # 2. 保存会话状态
    save_interrupted_state "$session_id"

    # 3. 创建检查点
    save_checkpoint "$session_id" "interrupted"

    # 4. 显示恢复信息
    log "INFO" "状态已保存，可以通过以下命令恢复..."
}
```

### 定期检查点保存

```bash
# 每2个步骤或每5分钟保存一次检查点
if [[ $((current_time - last_checkpoint_time)) -gt 300 || $completed_steps -gt 0 && $((completed_steps % 2)) -eq 0 ]]; then
    save_periodic_checkpoint "$session_id"
fi
```

### 状态数据结构

```json
{
  "session_id": "my-project-2026-02-03-1430",
  "status": "interrupted",
  "progress": 25,
  "steps_completed": ["analysis"],
  "steps_failed": [],
  "step_errors": {},
  "steps_in_progress": [],
  "interrupted": true,
  "interrupted_at": "2026-02-03T14:30:45Z",
  "recovery_attempts": 1,
  "last_update": "2026-02-03T14:30:45Z"
}
```

## 检查点类型

1. **定期检查点**（periodic）：每5分钟或每2个步骤
2. **步骤完成检查点**（step_completed）：步骤完成时
3. **步骤失败检查点**（step_failed）：步骤失败时
4. **中断检查点**（interrupted）：用户中断时

## 恢复策略

1. **智能恢复**：自动检测中断点
2. **增量恢复**：只处理未完成的步骤
3. **错误恢复**：可以重试失败的步骤
4. **状态恢复**：完全恢复执行环境

## 安全特性

- **原子性操作**：状态更新使用临时文件 + 重命名
- **备份机制**：每次状态更新都会备份原文件
- **验证机制**：恢复时验证状态完整性
- **冲突处理**：多次恢复尝试会被记录

这个功能确保了即使在长时间运行的迁移过程中出现中断，用户也能安全地恢复工作，避免数据丢失或重复工作。