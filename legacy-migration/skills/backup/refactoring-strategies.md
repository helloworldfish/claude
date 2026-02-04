skill: "重构策略技能"
description: "代码重构技术、设计模式应用和代码质量改进的最佳实践"
location: "plugin"
---

## 重构策略技能

### 核心能力

#### 1. 代码质量改进
- **重复代码消除**：提取公共代码，遵循DRY原则
- **复杂度降低**：减少圈复杂度，优化长函数
- **可读性提升**：改进命名，优化代码结构
- **维护性增强**：模块化设计，降低耦合

#### 2. 设计模式应用
- **创建型模式**：单例、工厂、建造者模式应用
- **结构型模式**：适配器、装饰器、代理模式应用
- **行为型模式**：策略、观察者、命令模式应用
- **领域模式**：仓储、聚合根、领域服务应用

#### 3. 重构技术
- **方法重构**：提取方法、内联方法、参数化
- **类重构**：提取类、移动方法、引入中间类
- **包重构**：重新组织包结构，建立清晰边界
- **架构重构**：分层架构、微服务拆分

### 重构方法

#### 重构前准备
```markdown
## 重构前检查清单

### 代码质量评估
- **测试覆盖率**: >80%
- **代码复杂度**: 圈复杂度<10
- **重复代码**: <5%
- **方法长度**: <50行

### 重构目标明确
- **重构目标**: [具体目标]
- **成功标准**: [可衡量的标准]
- **风险控制**: [风险缓解措施]
- **回滚计划**: [回滚策略]
```

#### 小步重构原则
```bash
# 每次重构一个小的改进
# 1. 编写测试，确保功能不变
# 2. 进行小范围代码修改
# 3. 运行测试，验证结果
# 4. 重复直到完成目标
```

### 常用重构技术

#### 1. 方法重构
```java
// 重构前：长方法
public void processOrder(Order order) {
    // 验证订单
    if (order == null) {
        throw new IllegalArgumentException("Order cannot be null");
    }
    if (order.getItems().isEmpty()) {
        throw new IllegalArgumentException("Order cannot be empty");
    }

    // 计算总价
    double total = 0;
    for (Item item : order.getItems()) {
        total += item.getPrice() * item.getQuantity();
    }

    // 应用折扣
    if (total > 1000) {
        total *= 0.9;
    }

    // 处理支付
    Payment payment = new Payment(order, total);
    payment.process();

    // 发送确认
    NotificationService.sendConfirmation(order);
}

// 重构后：提取方法
public void processOrder(Order order) {
    validateOrder(order);
    double total = calculateTotal(order);
    total = applyDiscount(total);
    processPayment(order, total);
    sendConfirmation(order);
}

private void validateOrder(Order order) {
    if (order == null) {
        throw new IllegalArgumentException("Order cannot be null");
    }
    if (order.getItems().isEmpty()) {
        throw new IllegalArgumentException("Order cannot be empty");
    }
}

private double calculateTotal(Order order) {
    double total = 0;
    for (Item item : order.getItems()) {
        total += item.getPrice() * item.getQuantity();
    }
    return total;
}

private double applyDiscount(double total) {
    return total > 1000 ? total * 0.9 : total;
}

private void processPayment(Order order, double total) {
    Payment payment = new Payment(order, total);
    payment.process();
}

private void sendConfirmation(Order order) {
    NotificationService.sendConfirmation(order);
}
```

#### 2. 类重构
```java
// 重构前：职责不清的类
public class UserService {
    private UserRepository userRepository;
    private EmailService emailService;
    private NotificationService notificationService;
    private AuditService auditService;
    private CacheService cacheService;

    public User createUser(UserData userData) {
        // 复杂的用户创建逻辑
        // 包含验证、邮件发送、通知、审计、缓存等多个职责
    }

    public User updateUser(UserData userData) {
        // 复杂的用户更新逻辑
    }

    public void deleteUser(Long userId) {
        // 复杂的用户删除逻辑
    }
}

// 重构后：职责分离
public class UserService {
    private UserRepository userRepository;
    private UserValidator userValidator;
    private UserEventPublisher eventPublisher;

    public User createUser(UserData userData) {
        userValidator.validate(userData);
        User user = userRepository.save(userData.toUser());
        eventPublisher.publishUserCreated(user);
        return user;
    }

    public User updateUser(UserData userData) {
        User user = userRepository.findById(userData.getId());
        userValidator.validateForUpdate(user, userData);
        user = userRepository.save(user.updateFrom(userData));
        eventPublisher.publishUserUpdated(user);
        return user;
    }

    public void deleteUser(Long userId) {
        User user = userRepository.findById(userId);
        userRepository.delete(user);
        eventPublisher.publishUserDeleted(user);
    }
}

// 分离的验证器
public class UserValidator {
    public void validate(UserData userData) {
        // 用户验证逻辑
    }

    public void validateForUpdate(User existing, UserData update) {
        // 更新验证逻辑
    }
}

// 分离的事件发布器
public class UserEventPublisher {
    public void publishUserCreated(User user) {
        eventBus.publish(new UserCreatedEvent(user));
        emailService.sendWelcomeEmail(user);
    }

    public void publishUserUpdated(User user) {
        eventBus.publish(new UserUpdatedEvent(user));
    }

    public void publishUserDeleted(User user) {
        eventBus.publish(new UserDeletedEvent(user));
    }
}
```

#### 3. 设计模式应用
```java
// 策略模式应用
public interface PaymentStrategy {
    void pay(double amount);
}

public class CreditCardPayment implements PaymentStrategy {
    @Override
    public void pay(double amount) {
        // 信用卡支付逻辑
    }
}

public class AlipayPayment implements PaymentStrategy {
    @Override
    public void pay(double amount) {
        // 支付宝支付逻辑
    }
}

public class PaymentContext {
    private PaymentStrategy strategy;

    public void setStrategy(PaymentStrategy strategy) {
        this.strategy = strategy;
    }

    public void executePayment(double amount) {
        strategy.pay(amount);
    }
}

// 工厂模式应用
public abstract class AnimalFactory {
    public abstract Animal createAnimal();
}

public class DogFactory extends AnimalFactory {
    @Override
    public Animal createAnimal() {
        return new Dog();
    }
}

public class CatFactory extends AnimalFactory {
    @Override
    public Animal createAnimal() {
        return new Cat();
    }
}

// 观察者模式应用
public interface OrderObserver {
    void onOrderCreated(Order order);
    void onOrderCancelled(Order order);
}

public class EmailNotification implements OrderObserver {
    @Override
    public void onOrderCreated(Order order) {
        sendEmail("订单创建成功", order);
    }

    @Override
    public void onOrderCancelled(Order order) {
        sendEmail("订单已取消", order);
    }
}

public class OrderService {
    private List<OrderObserver> observers = new ArrayList<>();

    public void addObserver(OrderObserver observer) {
        observers.add(observer);
    }

    public void createOrder(Order order) {
        // 创建订单逻辑
        notifyOrderCreated(order);
    }

    public void cancelOrder(Order order) {
        // 取消订单逻辑
        notifyOrderCancelled(order);
    }

    private void notifyOrderCreated(Order order) {
        for (OrderObserver observer : observers) {
            observer.onOrderCreated(order);
        }
    }

    private void notifyOrderCancelled(Order order) {
        for (OrderObserver observer : observers) {
            observer.onOrderCancelled(order);
        }
    }
}
```

### 重构策略

#### 重构优先级
```markdown
## 重构优先级矩阵

### 高价值低风险（立即重构）
- **重复代码**: 消除重复，提高维护性
- **长方法**: 提取方法，提高可读性
- **简单条件**: 简化条件判断

### 高价值高风险（计划重构）
- **复杂类**: 重新设计，降低耦合
- **深层嵌套**: 减少嵌套，提高可读性
- **大型模块**: 拆分模块，提高内聚

### 低价值低风险（可选重构）
- **命名改进**: 提高可读性
- **格式优化**: 改善代码风格
- **注释完善**: 提高文档质量

### 低价值高风险（避免重构）
- **稳定核心**: 风险大于收益
- **遗留代码**: 缺乏测试，风险高
- **第三方集成**: 依赖复杂，风险高
```

#### 渐进式重构
```markdown
## 渐进式重构策略

### 第一阶段：基础重构
- **代码格式化**: 统一代码风格
- **命名规范**: 改善变量和类名
- **注释完善**: 添加必要的注释

### 第二阶段：结构重构
- **方法提取**: 提取长方法
- **类拆分**: 分离职责
- **包重组**: 建立清晰的包结构

### 第三阶段：架构重构
- **模式应用**: 应用设计模式
- **接口优化**: 改善接口设计
- **架构优化**: 提升整体架构
```

### 重构工具

#### 自动化工具
- **IDE重构**: IntelliJ IDEA、Eclipse的重构功能
- **静态分析**: SonarQube、Checkstyle、PMD
- **代码格式化**: Prettier、ESLint、Google Java Format
- **重构建议**: ReSharper、CodeRush

#### 手动重构
- **结对编程**: 两人协作重构
- **代码审查**: 通过审查重构代码
- **渐进式重构**: 小步快跑，持续改进
- **测试驱动**: 确保重构不破坏功能

### 输出产物

#### 重构计划
```markdown
# 重构计划

## 重构目标
- **主要目标**: [重构的主要目标]
- **次要目标**: [次要改进目标]
- **成功标准**: [可衡量的成功标准]

## 重构范围
- **包含模块**: [需要重构的模块]
- **排除模块**: [暂不重构的模块]
- **风险模块**: [需要谨慎处理的模块]

## 实施步骤
### 第一阶段：准备阶段
- **任务1**: [具体任务]
- **任务2**: [具体任务]
- **验收标准**: [验收标准]

### 第二阶段：重构实施
- **任务1**: [具体任务]
- **任务2**: [具体任务]
- **验收标准**: [验收标准]

### 第三阶段：验证阶段
- **任务1**: [具体任务]
- **任务2**: [具体任务]
- **验收标准**: [验收标准]
```

#### 重构指南
```markdown
# 重构指南

## 重构原则
1. **保持功能**: 重构不能改变外部行为
2. **小步前进**: 每次只做一个小改动
3. **测试先行**: 确保有充分的测试覆盖
4. **持续验证**: 每步都运行测试

## 重构技巧
- **先测试后重构**: 确保功能不变
- **渐进式重构**: 大重构分解为小步骤
- **命名改进**: 好的命名是最好的文档
- **简化设计**: 简单的解决方案往往更好

## 重构禁忌
- **不要重构没有测试的代码**
- **不要在压力下进行重构**
- **不要重构频繁变更的核心代码**
- **不要过度设计，保持简单
```

### 最佳实践

#### 重构时机
- **代码审查发现问题时**
- **添加新功能前**
- **修复bug时**
- **性能优化前**

#### 重构误区
- **为了重构而重构**: 没有明确目标
- **一次性大重构**: 风险太大
- **忽略测试**: 可能引入新问题
- **过度设计**: 增加复杂性

#### 成功标准
- **代码质量提升**: 复杂度降低，可读性提高
- **维护成本降低**: 修改更容易，bug更少
- **开发效率提高**: 新功能开发更快
- **团队满意度提高**: 开发者更乐于维护代码