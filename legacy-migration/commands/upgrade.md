---
name: upgrade
description: 升级框架、运行时和依赖项，包含全面的迁移规划
parameters:
  - name: target
    type: string
    description: 要升级的项目路径
    required: true
  - name: upgrade_type
    type: string
    description: 升级类型 - 'framework'（框架）、'runtime'（运行时）、'dependencies'（依赖项）、'security'（安全）
    required: true
  - name: framework
    type: string
    description: 框架名称（用于框架升级）
    required: false
  - name: to_version
    type: string
    description: 目标版本
    required: false
  - name: runtime
    type: string
    description: 运行时名称（java、nodejs、python、dotnet）
    required: false
  - name: plan_only
    type: boolean
    description: 生成迁移计划但不应用更改
    required: false
    default: false
examples:
  - "/upgrade --target . --upgrade_type framework --framework spring-boot --to-version 3.0"
  - "/upgrade --target . --upgrade_type runtime --runtime java --to-version 17"
  - "/upgrade --target . --upgrade_type dependencies --plan_only"
---

# 升级命令

您正在执行针对框架、运行时和依赖项的全面升级操作，包含完整的迁移规划和验证。

## 升级过程

### 阶段 1：升级前分析

#### 1.1 当前状态评估
```bash
# 检测当前版本
- 框架版本
- 运行时版本
- 依赖项版本
- 构建工具版本

# 分析兼容性
- 版本兼容性矩阵
- 已知破坏性变更
- 弃用警告
- 安全漏洞
```

#### 1.2 影响分析
```markdown
## 影响评估

### 代码影响
- 需要的 API 更改
- 已弃用代码的使用
- 依赖项中的破坏性变更
- 需要的配置更改

### 构建影响
- 构建配置更新
- 插件版本更新
- 编译更改
- 测试框架更新

### 运行时影响
- 性能变化
- 行为变化
- 安全改进
- 功能添加/移除
```

### 阶段 2：升级规划

#### 2.1 策略选择
```markdown
## 升级策略

### 直接升级
- 适用于：次要版本升级
- 过程：单步升级
- 风险：低到中
- 持续时间：短

### 渐进式升级
- 适用于：主要版本跨越
- 过程：通过中间版本多步升级
- 风险：中
- 持续时间：中到长

### 并行迁移
- 适用于：关键系统
- 过程：同时运行旧版本和新版本
- 风险：低
- 持续时间：长
```

#### 2.2 迁移计划生成
```markdown
## 迁移计划结构

### 1. 升级前检查清单
- [ ] 备份当前状态
- [ ] 运行完整测试套件
- [ ] 记录当前行为
- [ ] 创建回滚计划

### 2. 升级步骤
- 步骤 1：更新构建配置
- 步骤 2：更新依赖项
- 步骤 3：迁移代码更改
- 步骤 4：更新测试
- 步骤 5：验证功能

### 3. 升级后验证
- [ ] 编译成功
- [ ] 所有测试通过
- [ ] 手动测试
- [ ] 性能验证

### 4. 回滚程序
- 需要时恢复的步骤
- 回滚验证
- 恢复程序
```

### 阶段 3：升级执行（当 plan_only=false 时）

#### 3.1 Backup Creation
```bash
# Automatic backup
timestamp=$(date +%Y%m%d-%H%M%S)
backup_dir=".upgrade-backups/$timestamp"

# Backup critical files
- pom.xml / package.json / requirements.txt
- Source code directories
- Configuration files
- Build scripts
- Test files
```

#### 3.2 Configuration Updates
```bash
# Update build configuration files
# Framework version updates
# Dependency version updates
# Plugin/tool updates
```

#### 3.3 Code Migration
```bash
# Apply automated code transformations
- API usage updates
- Deprecated code replacement
- Annotation/package updates
- Configuration migration
```

### Phase 4: Validation

#### 4.1 Build Validation
```bash
# Compile the project
mvn clean compile
# or
npm run build
# or
python -m compileall
```

#### 4.2 Test Validation
```bash
# Run all tests
mvn test
# or
npm test
# or
pytest
```

#### 4.3 Quality Checks
```bash
# Code quality
- Linting checks
- Static analysis
- Security scans
- Performance benchmarks
```

## Framework Upgrade Guides

### Spring Boot 2.x → 3.0

#### Breaking Changes
```markdown
## Java Version
- Requires Java 17 or later
- Jakarta EE 9+ (namespace change javax.* → jakarta.*)

## Dependency Updates
- Spring Framework 6.0
- Tomcat 10+ (Jakarta EE 9)
- Hibernate 6.0+

## Configuration Changes
- application.yml properties updates
- DataSource configuration changes
- Actuator endpoint changes

## Code Changes
1. javax.* → jakarta.* imports
2. @ConfigurationProperties changes
3. Error handling updates
4. Security configuration changes
```

#### Migration Steps
```bash
# 1. Update Java version to 17
java -version

# 2. Update pom.xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.0.0</version>
</parent>

<properties>
    <java.version>17</java.version>
</properties>

# 3. Replace javax with jakarta
find . -name "*.java" -exec sed -i 's/javax\.jakarta./g' {} \;

# 4. Update dependencies
# Review and update all Spring dependencies

# 5. Update configuration
# Review application.yml/properties for deprecated properties

# 6. Update tests
# Update test dependencies and code

# 7. Validate
mvn clean compile test
```

### React 17 → 18

#### Breaking Changes
```markdown
## Changes
- New automatic batching
- New stricter effects
- New hydration error messages
- Component stacking improvements
- TypeScript improvements

## Actions Required
1. Update React and ReactDOM dependencies
2. Update React types
3. Review useEffect usage
4. Update test utilities
5. Check for hydration warnings
```

#### Migration Steps
```bash
# 1. Update package.json
npm install react@18 react-dom@18

# 2. Update createRoot (if using legacy API)
// Before
ReactDOM.render(<App />, document.getElementById('root'));

// After
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);

# 3. Update TypeScript types
npm install @types/react@18 @types/react-dom@18

# 4. Update tests
npm install @testing-library/react@13

# 5. Validate
npm run build
npm test
```

### Django 4.x → 5.0

#### Breaking Changes
```markdown
## Python Version
- Requires Python 3.10 or later

## Changes
- ADMIN enabled by default
- Form rendering changes
- Field choices validation
- Database constraint improvements

## Actions Required
1. Update Python version
2. Update Django version
3. Update form rendering
4. Review admin configuration
5. Update database constraints
```

#### Migration Steps
```bash
# 1. Update Python to 3.10+
python --version

# 2. Update requirements.txt
Django==5.0

# 3. Update code
# Review deprecation warnings
python manage.py check --deploy

# 4. Update settings
# Review and update settings.py

# 5. Run tests
python manage.py test

# 6. Validate
python manage.py check
python manage.py migrate --plan
```

## Runtime Upgrade Guides

### Java 8 → 11 → 17 → 21

#### Java 8 to 11
```markdown
## Notable Changes
- Removed: Java EE modules (javax.*)
- Removed: CORBA
- New: HTTP Client API
- New: Local variable syntax (var)

## Migration Steps
1. Update JAVA_HOME
2. Update Maven compiler plugin
3. Replace removed modules
4. Update build scripts
5. Run tests
```

#### Java 11 to 17
```markdown
## Notable Changes
- Records
- Pattern matching
- Sealed classes
- Text blocks
- New: Foreign Function & Memory API (incubator)

## Migration Steps
1. Update JAVA_HOME
2. Update pom.xml
3. Review and update modules
4. Apply new language features (optional)
5. Update build tools
```

#### Java 17 to 21
```markdown
## Notable Changes
- Virtual Threads (Project Loom)
- Pattern matching improvements
- Record patterns
- String templates (preview)
- Scoped values (preview)

## Migration Steps
1. Update JAVA_HOME
2. Update Maven/Gradle
3. Consider virtual threads for async
4. Review performance
5. Update profiling/monitoring
```

### Node.js Version Upgrades

#### Upgrade Process
```bash
# Check current version
node --version

# Install specific version
nvm install 18
nvm use 18

# Update package.json
"engines": {
  "node": ">=18.0.0"
}

# Update dependencies
npm update

# Test the upgrade
npm audit
npm test
```

#### Breaking Changes by Version
```markdown
## Node.js 16 → 18
- OpenSSL 3.0
- fetch() global
- Web Streams API
- Test Runner improvements

## Node.js 18 → 20
- Permission model
- Stable import attributes
- Single executable applications
- Performance improvements
```

### Python Version Upgrades

#### Python 2 to 3 (Legacy)
```markdown
## Major Changes
- print statement → function
- Unicode strings by default
- Integer division
- Iterator views
- Exception syntax

## Tools
- 2to3 automated converter
- six compatibility library
- modernize
```

#### Python 3.x to 3.y
```bash
# Check version
python --version

# Update pyproject.toml or setup.py
requires-python = ">=3.11"

# Update dependencies
pip install --upgrade -r requirements.txt

# Run tests
pytest

# Check for deprecation warnings
python -W all your_script.py
```

## Dependency Upgrades

### Security Updates
```bash
# Audit dependencies
npm audit
# or
mvn org.owasp:dependency-check-maven:check
# or
pip-audit

# Update vulnerable packages
npm audit fix
# or update manually
```

### All Dependencies
```bash
# Update all (careful!)
npm update
# or
pip install --upgrade -r requirements.txt
# or
mvn versions:use-latest-releases

# Test thoroughly
# Some updates may be breaking
```

## Upgrade Command Examples

### Example 1: Spring Boot Upgrade
```bash
# Generate plan first
/upgrade --target . --upgrade_type framework --framework spring-boot --to-version 3.0 --plan_only

# Review the plan
# Make adjustments if needed

# Execute upgrade
/upgrade --target . --upgrade_type framework --framework spring-boot --to-version 3.0
```

### Example 2: Java Runtime Upgrade
```bash
# Detect current Java version
/detect-project --path .

# Plan Java upgrade
/upgrade --target . --upgrade_type runtime --runtime java --to-version 17 --plan_only

# Execute upgrade
/upgrade --target . --upgrade_type runtime --runtime java --to-version 17
```

### Example 3: React Framework Upgrade
```bash
/upgrade --target frontend --upgrade_type framework --framework react --to-version 18
```

### Example 4: Security Updates Only
```bash
/upgrade --target . --upgrade_type security
```

### Example 5: All Dependencies
```bash
# Plan first
/upgrade --target . --upgrade_type dependencies --plan_only

# Review and execute
/upgrade --target . --upgrade_type dependencies
```

## Validation and Testing

### Automated Validation
```bash
# Compile
mvn clean compile
# or
npm run build

# Unit tests
mvn test
# or
npm test

# Integration tests
mvn verify
# or
npm run test:integration

# End-to-end tests
npm run test:e2e
```

### Manual Testing Checklist
```markdown
## Core Functionality
- [ ] Application starts successfully
- [ ] User authentication works
- [ ] CRUD operations work
- [ ] API endpoints respond correctly
- [ ] Database operations work

## UI/UX
- [ ] Pages render correctly
- [ ] Forms work properly
- [ ] Navigation works
- [ ] Responsive design works

## Performance
- [ ] Response times acceptable
- [ ] Memory usage normal
- [ ] No errors in logs
- [ ] CPU usage normal

## Security
- [ ] Authentication/authorization works
- [ ] No security warnings
- [ ] Data encryption works
- [ ] Input validation works
```

## Rollback Procedure

### Automatic Rollback
```bash
# If validation fails, automatic rollback
# Using backup created in phase 3.1

cp -r .upgrade-backups/$timestamp/* .
```

### Manual Rollback
```bash
# Restore from backup
rm -rf *
tar -xzf .upgrade-backups/$timestamp/backup.tar.gz

# Git rollback
git reset --hard HEAD~1
git clean -fd

# Revert dependencies
mvn dependency:purge-local-repository
# or
rm -rf node_modules
npm install
```

## Best Practices

### Before Upgrading
1. ✅ Read release notes thoroughly
2. ✅ Check breaking changes documentation
3. ✅ Create comprehensive backup
4. ✅ Ensure tests pass on current version
5. ✅ Schedule maintenance window

### During Upgrade
1. ✅ Follow migration guide precisely
2. ✅ Test incrementally
3. ✅ Document any workarounds
4. ✅ Keep rollback ready
5. ✅ Monitor logs carefully

### After Upgrading
1. ✅ Run full test suite
2. ✅ Perform manual testing
3. ✅ Monitor production metrics
4. ✅ Update documentation
5. ✅ Communicate changes to team

## Integration with Other Commands

- **/detect-project**: Analyze current state before upgrade
- **/refactor-plan**: Generate detailed refactoring plan
- **/refactor-apply**: Apply code changes
- **/validate**: Validate upgrade success
- **/analyze**: Analyze impact and dependencies

You are providing comprehensive upgrade capabilities with careful planning, execution, and validation to ensure safe and successful upgrades.
