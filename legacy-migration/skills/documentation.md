skill: "文档技能"
description: "技术文档编写、API文档生成和文档质量保证"
location: "plugin"
---

## 文档技能

### 核心能力

#### 1. 技术文档编写
- **架构文档**: 系统架构图、组件关系、设计决策
- **API文档**: REST API、GraphQL、WebSocket接口文档
- **开发文档**: 开发指南、最佳实践、代码规范
- **部署文档**: 部署流程、配置说明、运维指南

#### 2. 文档自动化
- **API文档生成**: Swagger/OpenAPI、Javadoc、Doxygen
- **代码文档**: 注释规范、文档生成
- **文档模板**: 标准化文档结构和格式
- **文档管理**: 版本控制、更新流程

#### 3. 文档质量保证
- **一致性检查**: 文档与代码的一致性验证
- **可读性评估**: 文档清晰度和易用性
- **完整性检查**: 文档覆盖度和完整性
- **时效性维护**: 文档更新和维护机制

### 文档类型和标准

#### 1. 架构文档
```markdown
# 系统架构文档

## 架构概览
### 系统愿景
- **业务目标**: [业务目标描述]
- **技术目标**: [技术目标描述]
- **关键特性**: [主要特性列表]

### 架构原则
- **高可用性**: 系统可用性 > 99.9%
- **可扩展性**: 支持水平扩展
- **安全性**: 数据安全和隐私保护
- **性能**: 响应时间 < 200ms

## 架构组件
### 核心组件
```
┌─────────────────────────────────────┐
│           API Gateway              │
├─────────────────────────────────────┤
│   │   │   │   │   │   │   │   │   │
│   │   │   │   │   │   │   │   │   │
├─────────────────────────────────────┤
│           Service Layer            │
├─────────────────────────────────────┤
│           Data Layer               │
└─────────────────────────────────────┘
```

### 服务架构
#### 用户服务 (User Service)
- **职责**: 用户注册、登录、权限管理
- **技术栈**: Spring Boot、MySQL、Redis
- **端口**: 8081
- **依赖**: 认证服务、日志服务

#### 订单服务 (Order Service)
- **职责**: 订单创建、支付、状态管理
- **技术栈**: Spring Boot、PostgreSQL、Kafka
- **端口**: 8082
- **依赖**: 用户服务、支付服务、产品服务

### 数据架构
#### 数据库设计
```sql
-- 用户表
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 订单表
CREATE TABLE orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 部署架构
#### 基础设施
- **容器化**: Docker + Kubernetes
- **数据库**: PostgreSQL 主从复制
- **缓存**: Redis 集群
- **消息队列**: Kafka 集群
- **监控**: Prometheus + Grafana

#### 网络架构
- **负载均衡**: Nginx + HAProxy
- **CDN**: CloudFlare
- **安全**: SSL/TLS、防火墙、WAF
```

#### 2. API文档
```markdown
# API 文档

## 基础信息
- **Base URL**: `https://api.example.com/v1`
- **版本**: v1.0.0
- **认证方式**: Bearer Token
- **响应格式**: JSON

## 用户管理API

### 创建用户
#### 请求
```http
POST /users
Content-Type: application/json
Authorization: Bearer {token}

{
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe"
}
```

#### 响应
```http
HTTP/1.1 201 Created
Content-Type: application/json

{
    "id": 123,
    "email": "user@example.com",
    "name": "John Doe",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
}
```

### 错误响应
```http
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
    "error": {
        "code": "INVALID_EMAIL",
        "message": "Invalid email format"
    }
}
```

## 订单管理API

### 获取订单列表
#### 请求
```http
GET /orders?page=1&size=10&status=pending
Authorization: Bearer {token}
```

#### 响应
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
    "data": [
        {
            "id": 456,
            "user_id": 123,
            "total_amount": "99.99",
            "status": "pending",
            "created_at": "2024-01-01T10:00:00Z"
        }
    ],
    "pagination": {
        "page": 1,
        "size": 10,
        "total": 25
    }
}
```

## WebSocket API
### 订单状态更新
```javascript
// 连接
const socket = new WebSocket('wss://api.example.com/v1/orders/updates');

// 订阅订单状态更新
socket.send(JSON.stringify({
    type: 'subscribe',
    channel: 'order_status',
    order_id: 456
}));

// 接收更新
socket.onmessage = function(event) {
    const update = JSON.parse(event.data);
    console.log('Order status:', update);
};

// 示例消息
{
    "type": "order_status_update",
    "order_id": 456,
    "status": "confirmed",
    "timestamp": "2024-01-01T10:15:00Z"
}
```
```

#### 3. 开发文档
```markdown
# 开发指南

## 开发环境设置
### 前置条件
- Java 17+
- Maven 3.8+
- Node.js 18+
- Docker 20+
- MySQL 8.0+

### 环境变量
```bash
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=app_dev
DB_USER=dev_user
DB_PASSWORD=dev_password

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379

# 应用配置
SERVER_PORT=8080
LOG_LEVEL=INFO
JWT_SECRET=your-secret-key
```

### 项目结构
```
src/
├── main/
│   ├── java/
│   │   └── com/example/
│   │       ├── config/      # 配置类
│   │       ├── controller/  # 控制器
│   │       ├── service/     # 业务逻辑
│   │       ├── repository/  # 数据访问
│   │       ├── entity/      # 实体类
│   │       ├── dto/         # 数据传输对象
│   │       └── exception/   # 异常处理
│   └── resources/
│       ├── application.yml # 应用配置
│       ├── schema.sql      # 数据库schema
│       └── static/         # 静态资源
└── test/
    ├── java/
    │   └── com/example/    # 测试代码
    └── resources/
        ├── application.yml # 测试配置
        └── data/           # 测试数据
```

## 代码规范
### Java代码规范
```java
// 命名规范
public class UserService {
    private UserRepository userRepository;

    public User createUser(UserCreateRequest request) {
        User user = new User();
        user.setEmail(request.getEmail());
        user.setName(request.getName());
        return userRepository.save(user);
    }
}

// 异常处理
public Order createOrder(OrderCreateRequest request) {
    try {
        validateOrder(request);
        Order order = buildOrder(request);
        return orderRepository.save(order);
    } catch (ValidationException e) {
        throw new OrderValidationException("Invalid order data", e);
    } catch (DatabaseException e) {
        throw new OrderCreationException("Failed to create order", e);
    }
}

// 日志记录
@Slf4j
public class OrderService {
    public Order processOrder(Order order) {
        log.info("Processing order: {}", order.getId());
        try {
            // 处理逻辑
            log.debug("Order processed successfully");
            return processedOrder;
        } catch (Exception e) {
            log.error("Failed to process order: {}", order.getId(), e);
            throw e;
        }
    }
}
```

### Git工作流
```bash
# 分支命名规范
- feature/user-management     # 功能分支
- bugfix/login-validation     # 修复分支
- hotfix/security-patch       # 紧急修复
- release/v1.2.0             # 发布分支

# 提交信息规范
# 格式：<type>(<scope>): <description>
#
# 类型:
# feat: 新功能
# fix: 修复bug
# docs: 文档更新
# style: 代码格式化
# refactor: 重构
# test: 测试相关
# chore: 构建或工具变动
#
# 示例:
# feat(auth): add OAuth2 support
# fix(order): resolve payment timeout issue
# docs(api): update user API documentation
```

## 调试指南
### 日志配置
```yaml
# application.yml
logging:
  level:
    root: INFO
    com.example: DEBUG
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
  file:
    name: logs/application.log
    max-size: 10MB
    max-history: 30
```

### 常见问题排查
#### 1. 数据库连接失败
```bash
# 检查数据库状态
systemctl status mysql

# 检查网络连接
ping database-host
telnet database-host 3306

# 检查配置文件
cat src/main/resources/application.yml | grep db
```

#### 2. 内存溢出
```bash
# JVM参数设置
java -Xms256m -Xmx1024m -XX:+UseG1GC -jar app.jar

# 分析堆转储
jmap -dump:format=b,file=heapdump.hprof <pid>

# 分析线程堆栈
jstack <pid> > thread_dump.txt
```
```

### 文档自动化工具

#### 1. API文档生成
```yaml
# OpenAPI 3.0 配置
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0
  description: User management API

paths:
  /users:
    post:
      summary: Create user
      description: Create a new user account
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UserCreateRequest'
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
          format: int64
        email:
          type: string
          format: email
        name:
          type: string
```

#### 2. 代码文档生成
```java
/**
 * 用户服务类，提供用户管理相关功能
 * <p>
 * 主要功能包括：
 * <ul>
 *   <li>用户注册和登录</li>
 *   <li>用户信息更新</li>
 *   <li>用户权限管理</li>
 * </ul>
 *
 * @author Developer Name
 * @version 1.0.0
 * @since 2024-01-01
 */
@Service
@Slf4j
public class UserService {

    /**
     * 创建新用户
     *
     * @param request 用户创建请求
     * @return 创建的用户信息
     * @throws DuplicateEmailException 当邮箱已存在时抛出
     * @throws ValidationException 当数据验证失败时抛出
     */
    public User createUser(UserCreateRequest request) {
        // 实现逻辑
    }

    /**
     * 根据邮箱获取用户
     *
     * @param email 用户邮箱
     * @return 用户信息，如果不存在则返回Optional.empty()
     */
    public Optional<User> findByEmail(String email) {
        // 实现逻辑
    }
}
```

#### 3. 文档生成工具配置
```xml
<!-- Maven配置 -->
<plugin>
    <groupId>org.asciidoctor</groupId>
    <artifactId>asciidoctor-maven-plugin</artifactId>
    <version>2.2.4</version>
    <configuration>
        <sourceDirectory>src/docs/asciidoc</sourceDirectory>
        <outputDirectory>target/docs</outputDirectory>
        <backend>html5</backend>
        <doctype>book</doctype>
    </configuration>
</plugin>

<!-- Swagger配置 -->
<plugin>
    <groupId>io.github.swagger2markup</groupId>
    <artifactId>swagger2markup-maven-plugin</artifactId>
    <version>1.3.3</version>
    <configuration>
        <apiFiles>src/main/resources/api.yaml</apiFiles>
        <outputDir>target/docs/asciidoc</outputDir>
        <markupLanguage>asciidoc</markupLanguage>
    </configuration>
</plugin>
```

### 文档质量保证

#### 1. 文档检查清单
```markdown
## 文档质量检查清单

### 完整性
- [ ] 所有API都有文档
- [ ] 所有配置项都有说明
- [ ] 所有错误码都有解释
- [ ] 所有功能都有操作指南

### 准确性
- [ ] 代码与文档一致
- [ ] 版本信息正确
- [ ] 示例代码可运行
- [ ] 配置项值正确

### 清晰性
- [ ] 语言简洁明了
- [ ] 术语使用一致
- [ ] 示例易于理解
- [ ] 结构逻辑清晰

### 时效性
- [ ] 文档版本与代码同步
- [ ] 过期文档已标记
- [ ] 更新责任人明确
- [ ] 更新流程健全
```

#### 2. 文档维护策略
```markdown
## 文档维护策略

### 自动化检查
- **CI集成**: 文档检查集成到CI流程
- **链接检查**: 自动检查文档中的有效链接
- **代码匹配**: 自动验证文档与代码的一致性
- **拼写检查**: 自动检查拼写错误

### 定期更新
- **版本发布**: 每个版本同步更新文档
- **日常维护**: 及时修复文档问题
- **季度审核**: 全面审核文档质量
- **用户反馈**: 响应用户反馈改进文档

### 责任分配
- **技术负责人**: 架构文档维护
- **开发团队**: API文档更新
- **产品团队**: 业务文档更新
- **运维团队**: 部署文档维护
```

### 输出产物

#### 文档模板
```markdown
# [项目名称] 文档模板

## 1. 概述
### 1.1 项目背景
- [项目背景描述]

### 1.2 项目目标
- [项目目标列表]

### 1.3 技术栈
- [主要技术列表]

## 2. 架构设计
### 2.1 系统架构
- [架构图和说明]

### 2.2 组件设计
- [组件列表和职责]

### 2.3 数据设计
- [数据库设计和关系]

## 3. API文档
### 3.1 认证方式
- [认证方式说明]

### 3.2 接列表
- [所有API的详细文档]

## 4. 开发指南
### 4.1 环境搭建
- [环境搭建步骤]

### 4.2 开发规范
- [代码规范和标准]

### 4.3 调试指南
- [调试工具和方法]

## 5. 部署文档
### 5.1 系统要求
- [硬件和软件要求]

### 5.2 部署步骤
- [详细的部署步骤]

### 5.3 监控配置
- [监控和告警配置]
```

#### 文档维护计划
```markdown
# 文档维护计划

## 维护周期
### 每周维护
- 检查文档链接有效性
- 修复拼写和语法错误
- 更新示例代码

### 每月维护
- 同步代码变更
- 更新版本信息
- 审核文档完整性

### 每季度维护
- 全面审核文档质量
- 更新技术栈信息
- 优化文档结构

### 年度维护
- 文档版本升级
- 整合用户反馈
- 制定改进计划

## 质量指标
- **准确性**: 100%
- **完整性**: 95%
- **时效性**: 90%
- **可用性**: 95%
```

### 最佳实践

#### 文档写作原则
1. **面向读者**: 根据目标读者调整内容深度
2. **简洁明了**: 使用清晰简洁的语言
3. **图文并茂**: 适当使用图表和示例
4. **及时更新**: 保持文档与代码同步

#### 文档管理规范
1. **版本控制**: 所有文档纳入版本控制
2. **变更管理**: 文档变更需要审核流程
3. **访问控制**: 敏感文档需要访问控制
4. **备份策略**: 定期备份重要文档

### 使用场景

#### 何时使用此技能
1. **项目启动**: 建立文档体系
2. **开发阶段**: 编写和维护技术文档
3. **发布前**: 完善文档和API文档
4. **维护阶段**: 持续更新和完善文档
5. **知识传承**: 团队知识转移和沉淀

#### 技能优势
- **全面覆盖**: 从架构到运维的完整文档体系
- **实用工具**: 提供文档生成和自动化工具
- **质量保证**: 文档质量检查和维护策略
- **标准化**: 统一的文档模板和规范