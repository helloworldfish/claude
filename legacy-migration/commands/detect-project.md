---
name: detect-project
description: 检测项目类型、技术栈，并推荐重构选项
parameters:
  - name: path
    type: string
    description: 要分析的项目路径
    required: true
  - name: output_format
    type: string
    description: 输出格式 - 'markdown', 'json', 'yaml'
    required: false
    default: "markdown"
  - name: include_recommendations
    type: boolean
    description: 包含重构建议
    required: false
    default: true
examples:
  - "/detect-project --path ~/my-project"
  - "/detect-project --path . --output_format json"
  - "/detect-project --path ~/src --include_recommendations true"
---

# 项目类型检测命令

您正在执行全面的项目分析，以检测项目类型、技术栈，并推荐重构选项。

## 检测过程

### 1. 项目发现
1. **路径验证**
   - 验证项目路径存在且可访问
   - 检查是否为有效的项目目录
   - 识别版本控制系统（Git、SVN等）

2. **结构分析**
   - 分析目录结构
   - 识别构建配置文件
   - 检测包管理文件
   - 查找配置文件

### 2. 技术栈检测

#### 编程语言
```bash
# 语言检测指标
Java: pom.xml, build.gradle, *.java 文件
Python: requirements.txt, setup.py, pyproject.toml, *.py 文件
JavaScript/TypeScript: package.json, *.js, *.ts 文件
Go: go.mod, *.go 文件
Rust: Cargo.toml, *.rs 文件
C#: *.csproj, *.sln, *.cs 文件
Ruby: Gemfile, *.rb 文件
PHP: composer.json, *.php 文件
```

#### 框架检测
```bash
# 后端框架
Spring Boot: spring-boot-starter 依赖
Django: requirements.txt 中的 Django
Flask: requirements.txt 中的 Flask
Express: package.json 中的 express
NestJS: package.json 中的 @nestjs/core
.NET Core: Microsoft.AspNetCore.* 引用
Rails: Gemfile 中的 rails

# 前端框架
React: package.json 中的 react
Vue: package.json 中的 vue
Angular: package.json 中的 @angular/core
Svelte: package.json 中的 svelte
```

#### 构建工具
```bash
# Java: Maven, Gradle
# JavaScript: npm, yarn, pnpm
# Python: pip, poetry, pipenv
# Go: go modules
# Rust: cargo
# .NET: dotnet CLI
```

### 3. 项目类型分类

```markdown
## 项目类型

### 前端项目
指标：
- 包含 react/vue/angular 的 package.json
- 无后端框架
- 构建工具：webpack, vite, parcel
- 重点关注：UI/UX、用户交互

示例：
- React SPA
- Vue 应用
- Angular 企业应用
- 移动应用（React Native、Flutter）

### 后端项目
指标：
- 服务器端框架（Spring、Django、Express）
- 无或极少前端代码
- API 专注
- 业务逻辑复杂

示例：
- REST API
- GraphQL API
- 微服务
- 后台任务处理器

### 全栈项目
指标：
- 同时包含前端和后端
- 单体结构
- 共享构建系统
- 集成部署

示例：
- 传统 MVC Web 应用
- JAMstack 应用
- Serverless 应用

### 单体应用
指标：
- 单个可部署单元
- 共享数据库
- 紧耦合
- 大型代码库

### 微服务
指标：
- 多个服务
- 独立部署
- API 通信
- 分布式数据

### 基础设施项目
指标：
- Terraform、CloudFormation、Pulumi
- Docker、Kubernetes
- CI/CD 配置
- 配置文件
```

### 4. 版本和依赖分析

```bash
# 版本检测
Java 版本：pom.xml 中的 java.version，maven-compiler-plugin 中的 source/target
Node 版本：package.json 中的 engines 字段
Python 版本：setup.py 或 pyproject.toml 中的 python_version
.NET 版本：.csproj 中的 TargetFramework

# 依赖分析
# 列出所有依赖
# 检查过时版本
# 识别安全漏洞
# 查找已弃用的 API
```

### 5. 架构模式检测

```markdown
## 架构模式

### 分层架构
- 清晰的分层：控制器、服务、仓储
- 常见于 Spring Boot、Django、.NET MVC

### MVC 模式
- 模型-视图-控制器
- 传统 Web 应用中常见

### 事件驱动
- 消息队列（RabbitMQ、Kafka）
- 事件处理器
- 异步处理

### 微服务
- 多个服务
- API 网关
- 服务发现

### Serverless
- 云函数（AWS Lambda、Azure Functions）
- FaaS 框架（Serverless、SAM）
- 短期运行函数
```

## 输出结构

### Markdown 输出（默认）
```markdown
# 项目检测报告

## 项目概览
- **名称**: [项目名称]
- **类型**: [前端/后端/全栈/微服务/单体]
- **主要语言**: [语言]
- **次要语言**: [列表]

## 技术栈

### 语言
- Java (85%) - 版本 11
- JavaScript (12%) - 版本 ES2020
- SQL (3%)

### 框架
- Spring Boot 2.7.0
- React 17.0.2
- Hibernate 5.6.3

### 构建工具
- Maven 3.8.1
- npm 8.1.0
- Webpack 5.0.0

### 数据库
- PostgreSQL 13.2
- Redis 6.2

## 项目结构
- **架构**: 分层单体
- **模块**: [列表]
- **总文件数**: [数量]
- **代码行数**: [数量]

## 当前状态分析
- **代码质量**: [评估]
- **测试覆盖率**: [百分比]%
- **技术债务**: [低/中/高]
- **已知问题**: [列表]

## 重构建议

### 高优先级
1. **Spring Boot 升级** (2.7 → 3.0)
   - 破坏性变更: [列表]
   - 预估工作量: [时间]
   - 风险等级: [级别]

2. **Java 版本升级** (11 → 17)
   - 收益: [列表]
   - 兼容性: [信息]
   - 预估工作量: [时间]

### 中优先级
1. **提取微服务**
   - 候选服务: [列表]
   - 迁移策略: [方法]
   - 预估时间线: [时间]

2. **前端现代化**
   - React 17 → 18 升级
   - 类组件转 Hooks
   - 预估工作量: [时间]

### 低优先级
1. **代码质量改进**
   - 减少代码重复
   - 提高测试覆盖率
   - 应用设计模式

## 建议的下一步
1. /refactor --type upgrade-framework --framework spring-boot --to-version 3.0
2. /refactor --type upgrade-runtime --runtime java --to-version 17
3. /analyze --path . --analysis_type all

## 其他资源
- [文档链接]
- [迁移指南]
- [最佳实践]
```

### JSON 输出
```json
{
  "project": {
    "name": "project-name",
    "path": "/path/to/project",
    "type": "monolith",
    "primary_language": "Java",
    "languages": [
      {"name": "Java", "version": "11", "percentage": 85},
      {"name": "JavaScript", "version": "ES2020", "percentage": 12}
    ]
  },
  "technology_stack": {
    "frameworks": [
      {"name": "Spring Boot", "version": "2.7.0", "type": "backend"},
      {"name": "React", "version": "17.0.2", "type": "frontend"}
    ],
    "build_tools": [
      {"name": "Maven", "version": "3.8.1"},
      {"name": "npm", "version": "8.1.0"}
    ],
    "databases": [
      {"name": "PostgreSQL", "version": "13.2"},
      {"name": "Redis", "version": "6.2"}
    ]
  },
  "architecture": {
    "pattern": "layered",
    "layers": ["controller", "service", "repository"],
    "coupling": "medium",
    "cohesion": "high"
  },
  "metrics": {
    "total_files": 1500,
    "lines_of_code": 145000,
    "test_coverage": 65
  },
  "recommendations": [
    {
      "type": "framework_upgrade",
      "priority": "high",
      "description": "Spring Boot 2.7 → 3.0",
      "effort": "2-3 周",
      "risk": "medium",
      "command": "/refactor --type upgrade-framework --framework spring-boot --to-version 3.0"
    }
  ]
}
```

## 检测算法

### 语言百分比计算
```bash
# 计算每种语言的代码行数
find . -name "*.java" -exec cat {} \; | wc -l
find . -name "*.js" -o -name "*.jsx" -exec cat {} \; | wc -l
find . -name "*.py" -exec cat {} \; | wc -l

# 计算百分比
language_percentage = (language_loc / total_loc) * 100
```

### 框架版本提取
```bash
# Java/Maven
grep -A 1 "spring-boot-starter-parent" pom.xml | grep version

# JavaScript/npm
cat package.json | grep '"react"' | grep '"version"'

# Python
cat requirements.txt | grep Django
```

### 架构模式检测
```bash
# 分层架构
find . -type d -name "controller" -o -name "service" -o -name "repository"

# 微服务
find . -name "application.yml" -o -name "application.properties" | wc -l

# 事件驱动
find . -name "*Listener.java" -o -name "*Handler.java"
```

## 与其他命令的集成

此检测命令为所有重构操作提供了基础：

1. **作为 /refactor 的输入**：项目类型决定重构策略
2. **作为 /upgrade 的输入**：当前版本 informs 升级路径
3. **作为 /transpile 的输入**：源语言和框架
4. **作为 /analyze 的输入**：项目结构指导分析深度
5. **代理选择**：结果确定要调用哪些代理

## 使用示例

### 场景1：Spring Boot 单体应用
```bash
$ /detect-project --path ~/my-spring-app

输出：
- 类型：后端单体
- 技术栈：Spring Boot 2.7, Java 11, PostgreSQL
- 建议：
  1. 升级到 Spring Boot 3.0
  2. 升级到 Java 17
  3. 考虑微服务提取
```

### 场景2：React 应用
```bash
$ /detect-project --path ~/my-react-app

输出：
- 类型：前端 SPA
- 技术栈：React 17, Redux, TypeScript
- 建议：
  1. 升级到 React 18
  2. 迁移到 Hooks
  3. 考虑状态管理替代方案
```

### 场景3：全栈应用
```bash
$ /detect-project --path ~/my-fullstack-app

输出：
- 类型：全栈单体
- 前端：React 17
- 后端：Spring Boot 2.7
- 建议：
  1. 前端：React 17 → 18
  2. 后端：Spring Boot 2.7 → 3.0
  3. 考虑前后端分离
```

您正在提供必要的项目检测能力，支持智能重构决策和建议。
