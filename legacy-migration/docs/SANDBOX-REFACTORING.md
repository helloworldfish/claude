# 沙盒重构功能使用指南

## 概述

沙盒重构功能允许您在完全隔离的环境中进行代码重构，确保原始代码库不受任何影响。只有在验证并批准后，才将变更合并回原仓库。

## 核心优势

### ✅ 零风险
- 原始代码完全不受影响
- 可以随意实验和尝试
- 出错只需删除沙盒

### ✅ 隔离测试
- 独立的构建环境
- 独立的测试运行
- 不影响开发进度

### ✅ 轻松回滚
- 删除沙盒目录即可
- 无需复杂的 git 操作
- 无残留文件

### ✅ 并行开发
- 团队继续使用原代码
- 重构在隔离环境中进行
- 完成后合并变更

### ✅ 安全合并
- 多种合并策略
- 完整的代码审查
- 受控的变更应用

## 工作流程

```
┌─────────────────┐
│ 原始代码仓库     │
│ (Original Repo) │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│ 1. 创建沙盒环境              │
│ /refactor-sandbox --source .│
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ 2. 沙盒环境                  │
│ (Sandbox Environment)        │
│ ├─ 完整代码副本               │
│ ├─ 独立 git 历史             │
│ └─ 隔离构建目录              │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ 3. 生成重构计划              │
│ /refactor-plan --target .   │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ 4. 审查和批准                │
│ - 技术审查                   │
│ - 团队讨论                   │
│ - 获得批准                   │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ 5. 应用重构                  │
│ /refactor-apply --plan .    │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ 6. 测试验证                  │
│ - 编译检查                   │
│ - 单元测试                   │
│ - 集成测试                   │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ 7. 生成合并产物              │
│ - diff 文件                 │
│ - patch 文件                │
│ - 或创建 PR                 │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ 8. 合并回原仓库              │
│ - 审查变更                  │
│ - 应用变更                  │
│ - 最终测试                  │
└─────────────────────────────┘
```

## 快速开始

### 场景 1：快速沙盒测试

```bash
# 1. 创建沙盒（克隆模式）
/refactor-sandbox --source . --target ./sandbox-test/

# 2. 进入沙盒
cd sandbox-test/

# 3. 生成重构计划
/refactor-plan --target src/main/java/service/ --plan_type quality

# 4. 查看计划
cat ./refactoring-plans/*/01-refactoring-plan.md

# 5. 应用重构
/refactor-apply --plan ./refactoring-plans/*/ --commit

# 6. 运行测试
mvn clean test

# 7. 如果满意，生成差异文件
cd ..
/refactor-sandbox --source . --target ./sandbox-test/ --mode diff

# 8. 查看差异
ls patches/
cat patches/*.diff

# 9. 应用到原仓库（审查后）
git apply patches/001-approved-change.diff

# 10. 清理沙盒
rm -rf sandbox-test/
```

### 场景 2：分支模式重构

```bash
# 1. 创建分支沙盒
/refactor-sandbox \
  --source . \
  --mode branch \
  --git_branch refactor/payment-optimization

# 2. 已经在新分支上，直接工作
/refactor-plan --target PaymentService.java
/refactor-apply --plan ./refactoring-plans/*/ --commit

# 3. 推送到远程
git push -u origin refactor/payment-optimization

# 4. 在 GitHub/GitLab 创建 PR
# 5. 团队审查后合并

# 6. 清理（合并后）
git checkout main
git branch -D refactor/payment-optimization
```

### 场景 3：团队协作沙盒

```bash
# 1. 开发者 A 创建沙盒并推送到远程仓库
/refactor-sandbox \
  --source . \
  --mode clone \
  --target ./sandbox-payment/ \
  --remote git@github.com:company/project-refactor-sandbox.git

# 2. 开发者 B 克隆沙盒仓库
git clone git@github.com:company/project-refactor-sandbox.git
cd project-refactor-sandbox

# 3. 在沙盒中协作重构
/refactor-plan --target .
/refactor-apply --plan ./refactoring-plans/*/

# 4. 推送变更
git add .
git commit -m "Refactor: Apply strategy pattern"
git push

# 5. 完成后生成合并产物
/refactor-sandbox \
  --source . \
  --target ./project-refactor-sandbox/ \
  --merge_strategy patch

# 6. 在原仓库应用 patch
cd ../original-project
git apply ../project-refactor-sandbox/sandbox-refactor.patch
```

## 沙盒模式详解

### 1. Clone 模式（克隆）

**特点**:
- 创建完整的代码副本
- 独立的 git 历史
- 完全隔离的环境

**适用场景**:
- 大规模重构实验
- 学习和尝试新技术
- 不确定是否会保留的变更

**示例**:
```bash
/refactor-sandbox \
  --source . \
  --mode clone \
  --target ./sandbox-experiment/
```

**结果**:
```
project/                    # 原项目
sandbox-experiment/         # 完整副本
├── .git/                   # 独立 git 仓库
├── src/
├── pom.xml
└── .sandbox-info           # 沙盒元数据
```

### 2. Branch 模式（分支）

**特点**:
- 使用 git 分支隔离
- 共享 git 历史
- 易于合并

**适用场景**:
- 团队协作
- 计划合并回主分支
- 使用 PR 工作流

**示例**:
```bash
/refactor-sandbox \
  --source . \
  --mode branch \
  --git_branch refactor/sandbox-payment
```

**结果**:
```
Git Branches:
* refactor/sandbox-payment  (当前)
  main                      (原分支)
  master
```

### 3. Copy 模式（复制）

**特点**:
- 仅复制源文件
- 不包含 .git 目录
- 更小的空间占用

**适用场景**:
- 仅需要源代码
- 不需要 git 历史
- 快速测试环境

**示例**:
```bash
/refactor-sandbox \
  --source . \
  --mode copy \
  --target ./sandbox-clean/
```

**结果**:
```
sandbox-clean/
├── src/
├── pom.xml
├── build.gradle
└── .sandbox-info
# 注意：没有 .git 目录
```

## 合并策略

### 策略 1：Diff（差异文件）

**特点**:
- 为每个变更生成独立的 .diff 文件
- 可以选择性应用
- 适合详细审查

**使用**:
```bash
/refactor-sandbox \
  --source . \
  --target ./sandbox/ \
  --merge_strategy diff

# 输出:
patches/
├── 001-PaymentService-refactor.diff
├── 002-UserService-cleanup.diff
└── 003-OrderController-optimization.diff
```

**应用变更**:
```bash
# 审查每个差异
cat patches/001-PaymentService-refactor.diff

# 应用批准的变更
git apply patches/001-PaymentService-refactor.diff
git apply patches/002-UserService-cleanup.diff

# 跳过不需要的变更
# (不应用 003 文件)
```

### 策略 2：Patch（统一补丁）

**特点**:
- 生成单个 .patch 文件
- 一次性应用所有变更
- 易于分发

**使用**:
```bash
/refactor-sandbox \
  --source . \
  --target ./sandbox/ \
  --merge_strategy patch

# 输出:
sandbox-refactor.patch
```

**应用变更**:
```bash
# 应用整个补丁
git apply sandbox-refactor.patch

# 或使用 patch 命令
patch -p1 < sandbox-refactor.patch

# 如果有冲突
git apply --reject sandbox-refactor.patch
# 手动解决 .rej 文件
```

### 策略 3：Merge Commit（合并提交）

**特点**:
- 使用 git 合并
- 保留完整历史
- 适合分支模式

**使用**:
```bash
/refactor-sandbox \
  --source . \
  --mode branch \
  --git_branch refactor/sandbox \
  --merge_strategy merge-commit

# 合并回主分支
git checkout main
git merge refactor/sandbox
```

### 策略 4：Pull Request（拉取请求）

**特点**:
- 创建 GitHub/GitLab PR
- 支持团队审查
- CI/CD 集成

**使用**:
```bash
/refactor-sandbox \
  --source . \
  --mode branch \
  --git_branch refactor/sandbox \
  --remote git@github.com:company/project.git \
  --merge_strategy pr

# 脚本会：
# 1. 推送分支到远程
# 2. 显示 PR 创建链接
# 3. 生成 PR 描述
```

## 高级用法

### 自动化工作流

```bash
# 一键创建沙盒并应用计划
/refactor-sandbox \
  --source . \
  --target ./sandbox/ \
  --plan ./existing-plan/ \
  --auto_cleanup \
  --merge_strategy patch

# 这会自动：
# 1. 创建沙盒
# 2. 应用计划
# 3. 生成 patch
# 4. 清理沙盒
# 5. 留下 patch 文件
```

### 多沙盒并行

```bash
# 为不同模块创建独立沙盒
/refactor-sandbox --source . --target ./sandbox-payment/ --plan payment-plan/
/refactor-sandbox --source . --target ./sandbox-user/ --plan user-plan/
/refactor-sandbox --source . --target ./sandbox-order/ --plan order-plan/

# 并行工作
cd sandbox-payment/ && /refactor-apply --plan ./payment-plan/
cd ../sandbox-user/ && /refactor-apply --plan ./user-plan/
cd ../sandbox-order/ && /refactor-apply --plan ./order-plan/

# 比较结果
diff -r sandbox-payment/ sandbox-user/
```

### CI/CD 集成

```bash
# 在 CI 管道中
#!/bin/bash

# 创建沙盒
/refactor-sandbox \
  --source . \
  --target ./ci-sandbox/ \
  --plan ./refactoring-plans/auto/

# 在沙盒中运行测试
cd ci-sandbox/
mvn clean test
RESULT=$?

# 如果测试通过，生成 patch
if [ $RESULT -eq 0 ]; then
  cd ..
  /refactor-sandbox \
    --source . \
    --target ./ci-sandbox/ \
    --merge_strategy patch

  echo "Patch generated successfully"
else
  echo "Tests failed, aborting"
  exit 1
fi
```

## 管理沙盒

### 列出所有沙盒

```bash
# 使用命令
/refactor-sandbox --action list

# 或直接查看
ls -la .sandboxes/
git branch | grep refactor/sandbox
```

### 查看沙盒状态

```bash
/refactor-sandbox \
  --action status \
  --target ./sandbox-payment/
```

### 清理沙盒

```bash
# 清理目录沙盒
/refactor-sandbox \
  --action cleanup \
  --target ./sandbox-payment/

# 清理分支沙盒
/refactor-sandbox \
  --action cleanup \
  --mode branch \
  --git_branch refactor/sandbox
```

### 批量清理

```bash
# 清理所有目录沙盒
rm -rf .sandboxes/*

# 清理所有分支沙盒
git branch | grep refactor/sandbox | xargs git branch -D
```

## 最佳实践

### 1. 命名规范

```bash
# 使用描述性的沙盒名称
/refactor-sandbox --source . --target ./sandbox-payment-strategy-pattern/
/refactor-sandbox --source . --target ./sandbox-user-service-cleanup/
/refactor-sandbox --source . --target ./sandbox-experiment-async-processing/
```

### 2. 文档记录

```bash
# 在沙盒中创建 README
cd sandbox-payment/
cat > REFACTORING_NOTES.md << EOF
# Payment Service 重构

## 目标
- 应用策略模式
- 提取支付处理逻辑
- 添加新的支付方式

## 变更
- PaymentService.java
- 新增: PaymentStrategy.java
- 新增: CreditCardPaymentStrategy.java
- 新增: PayPalPaymentStrategy.java

## 测试
- mvn test -Dtest=PaymentServiceTest
- 所有测试通过 ✓

## 合并说明
- 使用 diff 策略
- 审查所有变更
- 先在测试环境验证
EOF
```

### 3. 测试验证

```bash
# 在沙盒中完整测试
cd sandbox-payment/
mvn clean test                    # 单元测试
mvn verify                        # 集成测试
mvn package                       # 构建验证

# 性能测试（如适用）
mvn gatling:test                  # 性能测试
```

### 4. 代码审查

```bash
# 生成清晰的合并产物
/refactor-sandbox \
  --source . \
  --target ./sandbox/ \
  --merge_strategy diff

# 审查每个 diff 文件
for patch in patches/*.diff; do
  echo "=== Reviewing: $patch ==="
  cat "$patch"
  read -p "Approve? (y/n): " approve
  if [ "$approve" = "y" ]; then
    git apply "$patch"
  fi
done
```

### 5. 渐进式合并

```bash
# 分批次合并
# 第一批：低风险变更
git apply patches/001-logging-cleanup.diff
git apply patches/002-constants-extraction.diff
mvn test
git commit -m "Refactor: Phase 1 - Low risk changes"

# 第二批：中等风险变更
git apply patches/003-helper-methods.diff
mvn test
git commit -m "Refactor: Phase 2 - Medium risk changes"

# 第三批：高风险变更（需要更仔细审查）
git apply patches/004-strategy-pattern.diff
mvn test
git commit -m "Refactor: Phase 3 - Strategy pattern"
```

## 故障排除

### 问题：磁盘空间不足

```bash
# 检查空间
df -h

# 清理旧的沙盒
rm -rf .sandboxes/old-*

# 使用 copy 模式节省空间
/refactor-sandbox --source . --mode copy
```

### 问题：Git 合并冲突

```bash
# 检查冲突
git apply --check sandbox.patch

# 应用并标记冲突
git apply --reject --whitespace=fix sandbox.patch

# 解决 .rej 文件后
# 确认所有文件已应用
git status
```

### 问题：沙盒测试失败

```bash
# 不要合并回原仓库
# 而是：
# 1. 在沙盒中修复问题
cd sandbox-payment/
# 修复问题
mvn test

# 2. 重新生成 patch
cd ..
/refactor-sandbox --source . --target ./sandbox-payment/ --merge_strategy patch
```

### 问题：需要保留沙盒

```bash
# 移动沙盒到其他位置
mv sandbox-payment/ ~/backup/sandbox-payment-$(date +%Y%m%d)/

# 或归档
tar -czf sandbox-payment-backup.tar.gz sandbox-payment/
```

## 安全建议

### 1. 敏感信息

```bash
# 确保沙盒不包含敏感文件
# 更新 .gitignore
cat >> sandbox/.gitignore << EOF
# 避免提交敏感信息
.env
*.key
*.pem
credentials.json
EOF
```

### 2. 访问控制

```bash
# 如果使用远程沙盒仓库
# 确保设置为私有
gh repo edit --visibility private
```

### 3. 备份原仓库

```bash
# 在创建沙盒前备份
git archive --format=tar.gz --output=backup-$(date +%Y%m%d).tar.gz HEAD

# 或使用备份脚本
/refactor-sandbox --source . --backup
```

## 相关命令

- `/refactor-plan` - 生成重构计划
- `/refactor-apply` - 应用重构计划
- `/refactor` - 直接重构
- `/migrate` - 完整迁移工作流

## 总结

沙盒重构提供了：

1. **零风险重构** - 原代码完全不受影响
2. **灵活的隔离** - 三种模式适应不同需求
3. **安全的合并** - 多种策略控制合并过程
4. **团队协作** - 支持远程协作和 PR
5. **完整工具链** - 从创建到清理的全生命周期管理

通过使用沙盒重构，您可以大胆地尝试重构，而不必担心破坏原有代码！
