---
name: refactor-backend
description: 针对后端应用程序的专业重构，包括 API 设计、数据库层、服务架构和性能优化
parameters:
  - name: target
    type: string
    description: 后端项目路径
    required: true
  - name: strategy
    type: string
    description: 重构策略 - 'api-design'（API设计）、'database-layer'（数据库层）、'service-architecture'（服务架构）、'performance'（性能）、'security'（安全）
    required: true
  - name: framework
    type: string
    description: 框架名称（未指定时自动检测）
    required: false
  - name: architecture_pattern
    type: string
    description: 目标架构模式（用于 service-architecture）
    required: false
examples:
  - "/refactor-backend --target src/main/java --strategy api-design"
  - "/refactor-backend --target . --strategy database-layer --framework spring-boot"
  - "/refactor-backend --target . --strategy service-architecture --architecture_pattern layered"
---

# 后端重构命令

您正在执行针对后端的专业重构，重点关注 API 设计、数据库层优化、服务架构、性能和安全。

## 后端重构策略

### 1. API 设计重构

#### 目标
- RESTful API 最佳实践
- GraphQL 采用（如适用）
- API 版本控制策略
- 适当的错误处理
- 全面的 API 文档

#### API 模式分析
```markdown
## API 设计评估

### 当前 API 模式
- HTTP 方法使用（GET、POST、PUT、DELETE）
- 资源命名约定
- 状态码使用
- 请求/响应格式
- 身份验证/授权
- 速率限制
- 分页
- 过滤和排序

### 需要解决的常见问题
- 命名不一致
- HTTP 方法错误
- 缺少状态码
- 没有分页
- 错误消息不佳
- 缺少文档
```

#### RESTful API Refactoring
```java
// Before - Non-RESTful endpoints
@GetMapping("/getUsers")
public List<User> getUsers() { }

@GetMapping("/getUserById")
public User getUserById(@RequestParam Long id) { }

@PostMapping("/createUser")
public User createUser(@RequestBody User user) { }

@PostMapping("/updateUser")
public User updateUser(@RequestBody User user) { }

@PostMapping("/deleteUser")
public void deleteUser(@RequestParam Long id) { }

// After - RESTful endpoints
@GetMapping("/users")
public List<User> getUsers(
    @RequestParam(defaultValue = "0") int page,
    @RequestParam(defaultValue = "20") int size,
    @RequestParam(required = false) String sort
) { }

@GetMapping("/users/{id}")
public ResponseEntity<User> getUserById(@PathVariable Long id) { }

@PostMapping("/users")
public ResponseEntity<User> createUser(@RequestBody User user) {
    User saved = userService.save(user);
    return ResponseEntity.status(HttpStatus.CREATED).body(saved);
}

@PutMapping("/users/{id}")
public ResponseEntity<User> updateUser(
    @PathVariable Long id,
    @RequestBody User user
) { }

@DeleteMapping("/users/{id}")
public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
    userService.delete(id);
    return ResponseEntity.noContent().build();
}
```

#### API Versioning Strategies
```java
// Strategy 1: URI Path Versioning
@RestController
@RequestMapping("/api/v1/users")
public class UserControllerV1 { }

@RestController
@RequestMapping("/api/v2/users")
public class UserControllerV2 { }

// Strategy 2: Header Versioning
@RestController
@RequestMapping("/api/users")
@HeaderMapping(value = "X-API-Version", equals = "1")
public class UserControllerV1 { }

// Strategy 3: Query Parameter Versioning
@GetMapping(value = "/api/users", params = "version=1")
public List<User> getUsersV1() { }

@GetMapping(value = "/api/users", params = "version=2")
public List<UserDTO> getUsersV2() { }
```

#### Error Handling
```java
// Before - Inconsistent error responses
@GetMapping("/users/{id}")
public User getUser(@PathVariable Long id) {
    User user = userRepository.findById(id);
    if (user == null) {
        return null; // Bad practice
    }
    return user;
}

// After - Proper error handling
@GetMapping("/users/{id}")
public ResponseEntity<User> getUser(@PathVariable Long id) {
    return userRepository.findById(id)
        .map(ResponseEntity::ok)
        .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
}

// Global Exception Handler
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleResourceNotFound(ResourceNotFoundException ex) {
        ErrorResponse error = ErrorResponse.builder()
            .status(HttpStatus.NOT_FOUND.value())
            .message(ex.getMessage())
            .timestamp(LocalDateTime.now())
            .build();
        return new ResponseEntity<>(error, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });

        ErrorResponse error = ErrorResponse.builder()
            .status(HttpStatus.BAD_REQUEST.value())
            .message("Validation failed")
            .errors(errors)
            .timestamp(LocalDateTime.now())
            .build();
        return new ResponseEntity<>(error, HttpStatus.BAD_REQUEST);
    }
}
```

#### API Documentation (OpenAPI/Swagger)
```java
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("User Management API")
                .version("2.0")
                .description("RESTful API for user management")
                .contact(new Contact()
                    .name("API Team")
                    .email("api@example.com")))
            .addSecurityItem(new SecurityRequirement().addList("bearerAuth"))
            .components(new Components()
                .addSecuritySchemes("bearerAuth",
                    new SecurityScheme()
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")));
    }
}

// Controller with documentation
@RestController
@RequestMapping("/api/v2/users")
@Tag(name = "User", description = "User management APIs")
public class UserControllerV2 {

    @Operation(summary = "Get all users", description = "Returns paginated list of users")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved"),
        @ApiResponse(responseCode = "400", description = "Bad request"),
        @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    @GetMapping
    public Page<UserDTO> getUsers(
        @Parameter(description = "Page number (0-indexed)") @RequestParam(defaultValue = "0") int page,
        @Parameter(description = "Page size") @RequestParam(defaultValue = "20") int size
    ) { }
}
```

### 2. Database Layer Refactoring

#### Goals
- Repository pattern implementation
- Proper transaction management
- Query optimization
- Connection pooling
- Database abstraction

#### Repository Pattern
```java
// Before - Direct database access in service
@Service
public class UserService {
    @Autowired
    private JdbcTemplate jdbcTemplate;

    public User findById(Long id) {
        return jdbcTemplate.queryForObject(
            "SELECT * FROM users WHERE id = ?",
            new BeanPropertyRowMapper<>(User.class),
            id
        );
    }
}

// After - Repository pattern
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);

    @Query("SELECT u FROM User u WHERE u.createdAt > :date")
    List<User> findUsersCreatedAfter(@Param("date") LocalDateTime date);

    @Modifying
    @Query("UPDATE User u SET u.lastLogin = :loginTime WHERE u.id = :id")
    void updateLastLogin(@Param("id") Long id, @Param("loginTime") LocalDateTime loginTime);
}

@Service
@Transactional
public class UserService {
    private final UserRepository userRepository;

    public User findById(Long id) {
        return userRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }
}
```

#### Database Migration
```sql
-- Version 1: Initial schema
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Version 2: Add index
CREATE INDEX idx_users_email ON users(email);

-- Version 3: Add column
ALTER TABLE users ADD COLUMN last_login TIMESTAMP;

-- Version 4: Add new table
CREATE TABLE user_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    preferences_json JSONB,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Query Optimization
```java
// Before - N+1 query problem
@Entity
public class User {
    @OneToMany(mappedBy = "user")
    private List<Order> orders;
}

@GetMapping("/users")
public List<User> getUsers() {
    return userRepository.findAll(); // N+1 queries!
}

// After - Fetch joins
@Query("SELECT u FROM User u LEFT JOIN FETCH u.orders WHERE u.id = :id")
Optional<User> findByIdWithOrders(@Param("id") Long id);

// Or use EntityGraph
@EntityGraph(attributePaths = {"orders"})
Optional<User> findById(Long id);

// Batch fetching
@BatchSize(size = 50)
private List<Order> orders;
```

### 3. Service Architecture Refactoring

#### Layered Architecture
```markdown
## Classic Layered Architecture

┌─────────────────────────────┐
│   Presentation Layer        │
│   (Controllers/REST APIs)   │
└─────────────────────────────┘
             ↓
┌─────────────────────────────┐
│   Business Logic Layer      │
│   (Services)                │
└─────────────────────────────┘
             ↓
┌─────────────────────────────┐
│   Data Access Layer         │
│   (Repositories)            │
└─────────────────────────────┘
             ↓
┌─────────────────────────────┐
│   Database                  │
└─────────────────────────────┘
```

#### Service Layer Refactoring
```java
// Before - Fat service with multiple responsibilities
@Service
public class UserService {

    public User createUser(User user) {
        // Validation
        if (user.getEmail() == null) {
            throw new IllegalArgumentException("Email required");
        }

        // Password encoding
        user.setPassword(passwordEncoder.encode(user.getPassword()));

        // Save to database
        User saved = userRepository.save(user);

        // Send email
        emailService.sendWelcomeEmail(user.getEmail());

        // Log activity
        logService.logActivity("User created: " + user.getId());

        return saved;
    }
}

// After - Separated concerns
@Service
public class UserService {

    @Autowired
    private UserValidator userValidator;

    @Autowired
    private PasswordService passwordService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ApplicationEventPublisher eventPublisher;

    @Transactional
    public User createUser(User user) {
        // Validate
        userValidator.validate(user);

        // Encode password
        user.setPassword(passwordService.encode(user.getPassword()));

        // Save
        User saved = userRepository.save(user);

        // Publish event
        eventPublisher.publishEvent(new UserCreatedEvent(saved));

        return saved;
    }
}

// Separate validator
@Component
public class UserValidator {

    public void validate(User user) {
        Objects.requireNonNull(user, "User cannot be null");

        if (user.getEmail() == null || user.getEmail().isBlank()) {
            throw new ValidationException("Email is required");
        }

        if (!EmailValidator.isValid(user.getEmail())) {
            throw new ValidationException("Invalid email format");
        }
    }
}

// Event handler for side effects
@Component
public class UserEventListener {

    @Autowired
    private EmailService emailService;

    @Autowired
    private ActivityLogService logService;

    @EventListener
    @Async
    public void handleUserCreated(UserCreatedEvent event) {
        emailService.sendWelcomeEmail(event.getUser().getEmail());
        logService.logActivity("User created: " + event.getUser().getId());
    }
}
```

#### Domain-Driven Design
```java
// Domain Model
@Entity
public class Order {
    private OrderStatus status;
    private List<OrderItem> items;

    public void placeOrder() {
        // Business rule validation
        if (items.isEmpty()) {
            throw new IllegalStateException("Cannot place order with no items");
        }

        this.status = OrderStatus.PLACED;

        // Domain event
        DomainEvents.publish(new OrderPlacedEvent(this.getId()));
    }

    public void cancel() {
        if (status != OrderStatus.PLACED) {
            throw new IllegalStateException("Can only cancel placed orders");
        }

        this.status = OrderStatus.CANCELLED;
        DomainEvents.publish(new OrderCancelledEvent(this.getId()));
    }
}

// Repository (interface in domain)
public interface OrderRepository {
    Order save(Order order);
    Optional<Order> findById(OrderId id);
}

// Service (application layer)
@Service
public class OrderService {

    @Transactional
    public OrderId createOrder(CreateOrderCommand command) {
        Order order = new Order(command.getItems());
        orderRepository.save(order);
        order.placeOrder();
        return order.getId();
    }
}
```

### 4. Performance Optimization

#### Caching Strategies
```java
// Method-level caching
@Service
public class UserService {

    @Cacheable(value = "users", key = "#id")
    public User findById(Long id) {
        return userRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    @CachePut(value = "users", key = "#user.id")
    public User update(User user) {
        return userRepository.save(user);
    }

    @CacheEvict(value = "users", key = "#id")
    public void delete(Long id) {
        userRepository.deleteById(id);
    }

    @CacheEvict(value = "users", allEntries = true)
    public void clearCache() { }
}

// Cache configuration
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        return new RedisCacheManager.Builder(
            redisCacheConfiguration()
        ).cacheDefaults(redisCacheConfiguration()).build();
    }

    private RedisCacheConfiguration redisCacheConfiguration() {
        return RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(10))
            .disableCachingNullValues()
            .serializeKeysWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new GenericJackson2JsonRedisSerializer()));
    }
}
```

#### Async Processing
```java
@Configuration
@EnableAsync
public class AsyncConfig {

    @Bean(name = "taskExecutor")
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(10);
        executor.setMaxPoolSize(50);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("async-");
        executor.initialize();
        return executor;
    }
}

@Service
public class EmailService {

    @Async("taskExecutor")
    public void sendWelcomeEmail(String email) {
        // Runs in separate thread
        try {
            Thread.sleep(5000); // Simulate slow operation
            // Send email
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

#### Database Connection Pooling
```yaml
# application.yml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      connection-test-query: SELECT 1
```

### 5. Security Hardening

#### Authentication
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf().disable()
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/api/v1/users/**").hasRole("USER")
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .addFilterBefore(jwtAuthenticationFilter(),
                           UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

#### Input Validation
```java
// DTO with validation
public class CreateUserRequest {

    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 100)
    private String name;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    @Pattern(regexp = "^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=]).*$",
             message = "Password must contain uppercase, lowercase, digit and special character")
    private String password;
}

// Controller validation
@PostMapping("/users")
public ResponseEntity<User> createUser(@Valid @RequestBody CreateUserRequest request) {
    // ...
}
```

#### SQL Injection Prevention
```java
// Bad - String concatenation
String query = "SELECT * FROM users WHERE email = '" + email + "'";

// Good - Parameterized queries
@Query("SELECT u FROM User u WHERE u.email = :email")
Optional<User> findByEmail(@Param("email") String email);

// Or use positional parameters
Optional<User> findByEmail(String email);
```

## Backend Framework Specifics

### Spring Boot
```markdown
## Spring Boot Refactoring
- Configuration externalization
- Profile-based configuration
- Actuator endpoints
- Custom starters
- Auto-configuration optimization
```

### Express.js
```markdown
## Express.js Refactoring
- Middleware organization
- Route modularization
- Error handling middleware
- Async/await migration
- TypeScript adoption
```

### Django
```markdown
## Django Refactoring
- Middleware optimization
- View class migration
- Django REST framework
- Database router implementation
- Custom management commands
```

### ASP.NET Core
```markdown
## ASP.NET Core Refactoring
- Middleware pipeline
- Dependency injection
- Configuration options pattern
- Action filter refactoring
- Minimal APIs adoption
```

## Refactoring Workflow

```bash
# 1. Analyze backend architecture
/refactor-backend --target src/main/java --strategy service-architecture --depth 4

# 2. Generate refactoring plan
/refactor-plan --target src/main/java/service --plan_type architecture

# 3. Review and approve plan

# 4. Apply refactoring
/refactor-apply --plan ./refactoring-plans/backend-refactor/

# 5. Validate
/validate --validation_type backend
```

## Best Practices

### API Design
1. ✅ Use proper HTTP methods
2. ✅ Resource-oriented URLs
3. ✅ Consistent naming conventions
4. ✅ Proper status codes
5. ✅ Version your APIs

### Database Layer
1. ✅ Repository pattern
2. ✅ Transaction boundaries
3. ✅ Connection pooling
4. ✅ Query optimization
5. ✅ Indexing strategy

### Service Layer
1. ✅ Single responsibility
2. ✅ Dependency injection
3. ✅ Transaction management
4. ✅ Event-driven architecture
5. ✅ Async processing

### Security
1. ✅ Input validation
2. ✅ SQL injection prevention
3. ✅ XSS protection
4. ✅ Authentication/authorization
5. ✅ Secure headers

You are providing comprehensive backend refactoring capabilities covering API design, database layer, service architecture, performance optimization, and security hardening.
