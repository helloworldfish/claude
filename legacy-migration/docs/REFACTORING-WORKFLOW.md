# 三阶段重构工作流 (Three-Stage Refactoring Workflow)

本文档说明 legacy-migration 插件的三阶段重构工作流，通过中间文档实现安全的代码重构。

## 工作流概述

```
旧代码 (Old Code)
    ↓
/refactor-plan (生成计划)
    ↓
中间文档 (Intermediate Documents)
    ├── 01-refactoring-plan.md
    ├── 02-change-analysis.md
    ├── 03-code-diffs/
    ├── 04-impact-analysis.md
    ├── 05-rollback-plan.md
    └── 06-approval-checklist.md
    ↓
团队审查和批准 (Review & Approve)
    ↓
/refactor-apply (应用变更)
    ↓
新代码 (New Code)
```

## 核心优势

### 1. 审查流程
- ✅ 变更前审查所有修改
- ✅ 团队可以讨论和批准
- ✅ 详细的变更分析
- ✅ 完整的回滚计划

### 2. 安全保障
- ✅ 自动备份原始代码
- ✅ 编译验证
- ✅ 测试验证
- ✅ 自动回滚机制

### 3. 灵活执行
- ✅ Dry-run 模式预览变更
- ✅ Validate-only 模式验证可行性
- ✅ Interactive 模式逐步确认
- ✅ Git 集成（分支、提交）

## 命令使用

### 阶段1：生成重构计划

```bash
# 基本用法
/refactor-plan --target <文件或目录>

# 示例：为整个项目生成计划
/refactor-plan --target . --output_dir ./refactoring-plans/

# 示例：为特定包生成计划
/refactor-plan --target src/main/java/service/

# 示例：仅设计模式应用
/refactor-plan --target PaymentService.java --plan_type pattern

# 示例：包含详细分析和指标
/refactor-plan --target . --include_diffs --include_metrics --depth 5
```

**输出结构**:
```
refactoring-plans/
└── 2025-12-23_<target>_refactoring/
    ├── 01-refactoring-plan.md          # 重构计划概述
    ├── 02-change-analysis.md            # 详细变更分析
    ├── 03-code-diffs/                  # Git风格差异文件
    │   ├── PaymentService.java.diff
    │   ├── UserService.java.diff
    │   └── ...
    ├── 04-impact-analysis.md            # 风险评估
    ├── 05-rollback-plan.md              # 回滚程序
    ├── 06-approval-checklist.md         # 批准清单
    ├── 07-metrics-report.json           # 质量指标
    └── 09-apply-refactor.sh             # 应用脚本
```

### 阶段2：审查和批准

1. **技术审查**
   - 查看重构计划: `01-refactoring-plan.md`
   - 检查变更分析: `02-change-analysis.md`
   - 审查代码差异: `03-code-diffs/*.diff`
   - 评估风险: `04-impact-analysis.md`

2. **讨论和完善**
   - 团队讨论变更方案
   - 修改计划文档（如需要）
   - 确认回滚策略

3. **正式批准**
   - 填写批准清单: `06-approval-checklist.md`
   - 获得必要的批准签字
   - 记录批准决定

### 阶段3：应用重构

```bash
# 基本应用（自动备份、验证、回滚）
/refactor-apply --plan ./refactoring-plans/2025-12-23_service_refactoring/

# Dry-run 模式（预览变更，不修改文件）
/refactor-apply --plan ./refactoring-plans/2025-12-23_service_refactoring/ --mode dry-run

# Validate-only 模式（验证计划可应用）
/refactor-apply --plan ./refactoring-plans/2025-12-23_service_refactoring/ --mode validate-only

# Interactive 模式（逐步确认每个变更）
/refactor-apply --plan ./refactoring-plans/2025-12-23_service_refactoring/ --mode interactive

# 创建 Git 分支和提交
/refactor-apply --plan ./refactoring-plans/2025-12-23_service_refactoring/ --branch refactor/payment-optimization --commit

# 使用生成的脚本
cd ./refactoring-plans/2025-12-23_service_refactoring/
./09-apply-refactor.sh
```

## 安全特性

### 自动备份

在应用任何变更之前，系统会自动创建时间戳备份：

```bash
# 备份位置
.refactor-backups/2025-12-23-15:30/

# 备份内容
├── backup-manifest.json       # 备份元数据
├── files.list                 # 文件列表
├── sha256sum.txt             # 文件校验和
└── [原始文件副本]
```

### 验证流程

```bash
✅ 编译验证
   mvn clean compile
   或 ./gradlew clean compile

✅ 测试验证
   mvn test
   或 ./gradlew test

✅ 代码质量检查
   - Checkstyle
   - PMD
   - SpotBugs
```

### 自动回滚

如果验证失败：

```bash
❌ 编译失败或测试失败
    ↓
🔄 自动回滚触发
    ↓
✅ 从备份恢复
    ↓
✅ 验证系统稳定
```

手动回滚：

```bash
# 使用命令回滚
/refactor-apply --rollback .refactor-backups/2025-12-23-15:30/

# 或使用备份脚本
cd .refactor-backups/2025-12-23-15:30/
./rollback.sh
```

## 执行模式对比

| 模式 | 说明 | 修改文件 | 运行测试 | 创建提交 |
|------|------|----------|----------|----------|
| **apply** | 完整应用 | ✅ | ✅ | 可选 |
| **dry-run** | 预览变更 | ❌ | ❌ | ❌ |
| **validate-only** | 验证可行性 | ❌ | 可选 | ❌ |
| **interactive** | 逐步确认 | ✅ | ✅ | 可选 |

## 典型工作流程

### 场景1：小规模重构

```bash
# 1. 生成计划
/refactor-plan --target UserService.java --plan_type quality

# 2. 快速审查
cat ./refactoring-plans/*/01-refactoring-plan.md

# 3. 应用（带自动提交）
/refactor-apply --plan ./refactoring-plans/*/ --commit
```

### 场景2：中等规模重构

```bash
# 1. 生成详细计划
/refactor-plan --target src/main/java/service/ --depth 4 --include_metrics

# 2. 团队审查
# - 计划会议讨论
# - 修改文档
# - 获得批准

# 3. 先 dry-run 验证
/refactor-apply --plan ./refactoring-plans/*/ --mode dry-run

# 4. 创建分支并应用
/refactor-apply --plan ./refactoring-plans/*/ --branch refactor/service-cleanup
```

### 场景3：大规模重构

```bash
# 1. 分阶段生成计划
/refactor-plan --target src/main/java/service/ --output_dir ./plans/service/
/refactor-plan --target src/main/java/controller/ --output_dir ./plans/controller/
/refactor-plan --target src/main/java/repository/ --output_dir ./plans/repository/

# 2. 逐个审查和批准
# - 详细的技术审查
# - 风险评估
# - 利益相关者批准

# 3. 逐个应用，带充分测试
/refactor-apply --plan ./plans/service/ --test
/refactor-apply --plan ./plans/controller/ --test
/refactor-apply --plan ./plans/repository/ --test

# 4. 全面集成测试
mvn verify
```

## 配置文件

### 重构计划配置

创建 `.refactor-plan-config.yml`:

```yaml
# 重构计划生成配置
output:
  directory: "./refactoring-plans/"
  format: "all"
  include_timestamp: true
  include_git_info: true

analysis:
  default_depth: 3
  include_test_files: true
  include_generated_files: false

quality_gates:
  min_test_coverage: 80
  max_complexity: 10
  check_api_compatibility: true

approval:
  require_lead_approval: true
  require_architect_review: true
  min_reviewers: 2
```

### 重构应用配置

创建 `.refactor-apply-config.yml`:

```yaml
# 重构应用配置
backup:
  enabled: true
  location: ".refactor-backups/"
  compression: true
  retention_days: 30

validation:
  compile: true
  test: true
  code_quality: true
  performance: false

git:
  create_branch: true
  branch_prefix: "refactor/"
  commit: false
  commit_message_template: |
    Refactor: {plan_title}

    {plan_summary}

    Refs: {plan_id}

application:
  parallel: false
  max_parallel: 3
  stop_on_error: true
  auto_rollback: true

rollback:
  auto_rollback: true
  rollback_on_test_failure: true
  rollback_on_compile_error: true
  create_rollback_script: true
```

## 故障排除

### 问题：计划生成失败

```bash
# 检查目标是否可访问
ls -la <target-path>

# 验证代码可编译
mvn clean compile

# 尝试降低分析深度
/refactor-plan --target . --depth 1
```

### 问题：应用失败

```bash
# 检查计划结构
ls -la ./refactoring-plans/<plan-dir>/

# 验证模式
/refactor-apply --plan ./refactoring-plans/<plan-dir>/ --mode validate-only

# 查看日志
cat ./refactoring-plans/<plan-dir>/application.log
```

### 问题：回滚

```bash
# 自动回滚
/refactor-apply --rollback <backup-location>

# 手动回滚使用 Git
git reset --hard HEAD~1
git clean -fd

# 从备份恢复
cp -r <backup-location>/* .
```

## 最佳实践

### 1. 计划阶段
- ✅ 从干净的代码库开始（提交或暂存更改）
- ✅ 使用适当的分析深度（depth 1-5）
- ✅ 包含相关指标和建议
- ✅ 生成代码差异文件

### 2. 审查阶段
- ✅ 技术审查：代码质量和正确性
- ✅ 业务审查：与业务需求一致
- ✅ 风险评估：影响和缓解措施
- ✅ 资源规划：时间和人力

### 3. 应用阶段
- ✅ 从 dry-run 或 validate-only 开始
- ✅ 使用独立分支进行重构
- ✅ 运行完整测试套件
- ✅ 准备好回滚计划

### 4. 应用后
- ✅ 代码审查（标准 PR 流程）
- ✅ 更新文档
- ✅ 知识转移
- ✅ 监控生产环境

## 相关命令

- `/migrate` - 完整的迁移工作流
- `/analyze` - 分析代码库
- `/plan` - 生成迁移计划
- `/validate` - 验证重构
- `/refactor` - 直接重构（旧工作流）

## 总结

三阶段重构工作流提供：

1. **安全性**：备份、验证、自动回滚
2. **可控性**：审查、批准、灵活执行
3. **透明性**：详细文档、变更追踪
4. **可靠性**：验证流程、质量检查

通过中间文档，团队可以在应用前充分理解和审查所有变更，确保重构的安全性和质量。
