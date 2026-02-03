# Legacy Migration Plugin - 新功能概述

本文档概述 legacy-migration 插件的新增功能。

## 新增命令

### 1. `/refactor-plan` - 生成重构计划

**功能**: 在不修改源代码的情况下，生成详细的中间重构文档

**用法**:
```bash
/refactor-plan --target <文件/目录> [选项]
```

**示例**:
```bash
# 为整个项目生成计划
/refactor-plan --target . --output_dir ./plans/

# 为特定包生成计划
/refactor-plan --target src/main/java/service/

# 仅设计模式应用
/refactor-plan --target PaymentService.java --plan_type pattern
```

**输出**:
```
refactoring-plans/
├── 01-refactoring-plan.md          # 重构计划概述
├── 02-change-analysis.md            # 详细变更分析
├── 03-code-diffs/                  # Git 风格差异
│   ├── PaymentService.java.diff
│   └── UserService.java.diff
├── 04-impact-analysis.md            # 风险评估
├── 05-rollback-plan.md              # 回滚程序
└── 06-approval-checklist.md         # 批准清单
```

### 2. `/refactor-apply` - 应用重构计划

**功能**: 应用已批准的重构计划，包含完整的安全措施

**用法**:
```bash
/refactor-apply --plan <计划目录> [选项]
```

**示例**:
```bash
# 标准应用（自动备份和验证）
/refactor-apply --plan ./refactoring-plans/service-refactor/

# 预览模式（不修改文件）
/refactor-apply --plan ./refactoring-plans/*/ --mode dry-run

# 仅验证（检查计划是否可应用）
/refactor-apply --plan ./refactoring-plans/*/ --mode validate-only

# 交互模式（逐步确认）
/refactor-apply --plan ./refactoring-plans/*/ --mode interactive

# 带自动提交
/refactor-apply --plan ./refactoring-plans/*/ --commit
```

**安全特性**:
- ✅ 自动备份
- ✅ 编译验证
- ✅ 测试验证
- ✅ 自动回滚
- ✅ Git 集成

### 3. `/refactor-sandbox` - 沙盒重构 ⭐ 新增

**功能**: 在隔离环境中进行重构，不影响原代码

**用法**:
```bash
/refactor-sandbox --source <源目录> [选项]
```

**示例**:
```bash
# 创建克隆沙盒
/refactor-sandbox --source . --target ./sandbox-test/

# 创建分支沙盒
/refactor-sandbox --source . --mode branch --git_branch refactor/payment

# 远程仓库沙盒（团队协作）
/refactor-sandbox \
  --source . \
  --target ./sandbox/ \
  --remote git@github.com:company/project-refactor.git

# 自动化：创建 + 应用 + 清理
/refactor-sandbox \
  --source . \
  --target ./sandbox/ \
  --plan ./existing-plan/ \
  --auto_cleanup \
  --merge_strategy patch
```

**沙盒模式**:
1. **clone** - 完整克隆（默认）
2. **branch** - Git 分支
3. **copy** - 轻量复制

**合并策略**:
1. **diff** - 差异文件（可选择性应用）
2. **patch** - 统一补丁（一次性应用）
3. **merge-commit** - Git 合并
4. **pr** - 创建 Pull Request

## 工作流对比

### 传统工作流（不推荐）

```
原代码 → 直接重构 → 😱 风险高，难以回滚
```

### 三阶段工作流（推荐）

```
原代码
  ↓
/refactor-plan (生成计划)
  ↓
中间文档（审查和批准）
  ↓
/refactor-apply (安全应用)
  ↓
新代码
```

### 沙盒工作流（最安全）⭐

```
原代码
  ↓
/refactor-sandbox (创建沙盒)
  ↓
隔离环境
  ├─ /refactor-plan
  ├─ 审查和批准
  └─ /refactor-apply
  ↓
生成合并产物
  ├─ diff 文件
  ├─ patch 文件
  └─ 或 PR
  ↓
应用回原代码（审查后）
```

## 快速参考

### 场景 1: 小规模重构（三阶段工作流）

```bash
# 1. 生成计划
/refactor-plan --target UserService.java

# 2. 快速审查
cat ./refactoring-plans/*/01-refactoring-plan.md

# 3. 应用
/refactor-apply --plan ./refactoring-plans/*/ --commit
```

### 场景 2: 中等规模重构（三阶段工作流）

```bash
# 1. 生成详细计划
/refactor-plan --target src/main/java/service/ --depth 4

# 2. 团队审查
# - 计划会议
# - 讨论和修改
# - 获得批准

# 3. 预览验证
/refactor-apply --plan ./refactoring-plans/*/ --mode dry-run

# 4. 创建分支并应用
/refactor-apply --plan ./refactoring-plans/*/ --branch refactor/service-cleanup
```

### 场景 3: 大规模重构（沙盒工作流）

```bash
# 1. 创建沙盒
/refactor-sandbox --source . --target ./sandbox-payment/

# 2. 在沙盒中工作
cd sandbox-payment/
/refactor-plan --target src/main/java/payment/
/refactor-apply --plan ./refactoring-plans/*/

# 3. 测试验证
mvn clean test

# 4. 生成合并产物
cd ..
/refactor-sandbox --source . --target ./sandbox-payment/ --merge_strategy diff

# 5. 审查并应用
cat patches/*.diff
git apply patches/001-approved-change.diff

# 6. 清理
rm -rf sandbox-payment/
```

### 场景 4: 团队协作（沙盒 + PR）

```bash
# 1. 创建远程沙盒
/refactor-sandbox \
  --source . \
  --mode branch \
  --git_branch refactor/team-refactor \
  --remote git@github.com:company/project.git

# 2. 团队在分支协作
# - 多人提交变更
# - 代码审查
# - CI/CD 验证

# 3. 创建 PR
gh pr create --title "Refactor: Payment optimization" --body ./refactoring-plans/*/01-refactoring-plan.md

# 4. 合并后清理
git checkout main
git branch -D refactor/team-refactor
```

## 命令参数速查表

### /refactor-plan

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| target | string | 必需 | 目标文件/目录 |
| output_dir | string | ./refactoring-plans/ | 输出目录 |
| plan_type | string | comprehensive | 计划类型 |
| include_diffs | boolean | true | 生成 diff 文件 |
| depth | integer | 3 | 分析深度 (1-5) |
| severity_threshold | string | medium | 最低严重程度 |

### /refactor-apply

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| plan | string | 必需 | 计划目录路径 |
| mode | string | apply | 应用模式 |
| backup | boolean | true | 创建备份 |
| validate | boolean | true | 验证编译 |
| test | boolean | true | 运行测试 |
| commit | boolean | false | 创建提交 |
| branch | string | refactor/{plan-id} | Git 分支 |
| rollback_on_failure | boolean | true | 失败时自动回滚 |

### /refactor-sandbox

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| source | string | 必需 | 源目录 |
| target | string | 自动生成 | 目标目录 |
| mode | string | clone | 沙盒模式 |
| remote | string | "" | 远程仓库 URL |
| plan | string | "" | 应用计划路径 |
| auto_cleanup | boolean | false | 自动清理 |
| backup | boolean | true | 备份源代码 |
| merge_strategy | string | diff | 合并策略 |
| git_branch | string | refactor/sandbox | 分支名称 |

## 文档位置

- **三阶段重构工作流**: `docs/REFACTORING-WORKFLOW.md`
- **沙盒重构详细指南**: `docs/SANDBOX-REFACTORING.md`
- **命令详细文档**: `commands/refactor-plan.md`
- **命令详细文档**: `commands/refactor-apply.md`
- **命令详细文档**: `commands/refactor-sandbox.md`

## 配置文件

### .refactor-plan-config.yml

重构计划生成配置

```yaml
output:
  directory: "./refactoring-plans/"
  format: "all"

analysis:
  default_depth: 3
  include_test_files: true

quality_gates:
  min_test_coverage: 80
  max_complexity: 10
```

### .refactor-apply-config.yml

重构应用配置

```yaml
backup:
  enabled: true
  location: ".refactor-backups/"

validation:
  compile: true
  test: true

git:
  create_branch: true
  commit: false
```

### .sandbox-config.yml

沙盒配置

```yaml
sandbox:
  default_mode: "clone"
  auto_backup: true

merge:
  default_strategy: "diff"

cleanup:
  auto_cleanup: false
  keep_days: 7
```

## 辅助脚本

### scripts/apply-refactor.sh

重构应用脚本（由 refactor-apply 使用）

```bash
./apply-refactor.sh --dry-run
./apply-refactor.sh --validate-only
./apply-refactor.sh --interactive
./apply-refactor.sh --rollback
```

### scripts/sandbox-manager.sh

沙盒管理脚本（由 refactor-sandbox 使用）

```bash
./sandbox-manager.sh create --source . --target ./sandbox/
./sandbox-manager.sh merge --source . --target ./sandbox/
./sandbox-manager.sh cleanup --target ./sandbox/
./sandbox-manager.sh list
```

## 最佳实践

### 1. 选择合适的工作流

- **小改动**: 三阶段工作流
- **中等改动**: 三阶段工作流 + 分支
- **大改动/不确定**: 沙盒工作流
- **团队协作**: 沙盒 + PR

### 2. 始终审查

- 不要跳过审查步骤
- 技术审查 + 业务审查
- 风险评估

### 3. 充分测试

- 单元测试
- 集成测试
- 性能测试（如适用）

### 4. 渐进式合并

- 分批次合并变更
- 每批后测试验证
- 保留回滚能力

### 5. 文档记录

- 记录重构决策
- 更新相关文档
- 团队知识转移

## 总结

新功能提供了：

1. **安全性** - 中间文档和沙盒隔离
2. **可控性** - 审查流程和灵活执行
3. **透明性** - 详细文档和变更追踪
4. **可靠性** - 验证、备份、回滚

通过这些新功能，您可以：
- ✅ 大胆重构，无需担心破坏原代码
- ✅ 团队协作，完整的审查流程
- ✅ 零风险实验，沙盒中随意尝试
- ✅ 受控合并，只应用批准的变更

开始享受安全的代码重构吧！ 🚀
