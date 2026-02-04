skill: "测试策略技能"
description: "自动化测试策略、测试框架选择和测试质量保证"
location: "plugin"
---

## 测试策略技能

### 核心能力

#### 1. 测试框架应用
- **单元测试**: JUnit、pytest、Mocha、Go testing
- **集成测试**: Spring Test、pytest-integration、testcontainers
- **端到端测试**: Selenium、Cypress、Playwright、Puppeteer
- **性能测试**: JMeter、Gatling、k6、Locust

#### 2. 测试策略设计
- **测试金字塔**: 单元测试、集成测试、端到端测试的比例
- **测试自动化**: CI/CD集成、自动化测试执行
- **测试数据管理**: 测试数据生成、隔离、清理
- **测试覆盖分析**: 代码覆盖率、分支覆盖率、路径覆盖率

#### 3. 测试质量保证
- **测试驱动开发**: TDD实践和BDD框架
- **行为驱动开发**: Cucumber、SpecFlow等BDD工具
- **契约测试**: Pact、Consumer-Driven Contract Testing
- **混沌工程**: 故障注入和容错能力测试

### 测试方法

#### 单元测试最佳实践
```markdown
## 单元测试实践

### 测试结构
```java
// 测试类结构
public class UserServiceTest {
    private UserService userService;
    private UserRepository userRepository;
    private PasswordEncoder passwordEncoder;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        passwordEncoder = mock(PasswordEncoder.class);
        userService = new UserService(userRepository, passwordEncoder);
    }

    @Test
    @DisplayName("创建用户成功")
    void createUser_Success() {
        // Given
        UserCreateRequest request = new UserCreateRequest(
            "test@example.com", "password123", "Test User");

        when(passwordEncoder.encode("password123"))
            .thenReturn("encoded123");
        when(userRepository.save(any(User.class)))
            .thenReturn(new User("1", "test@example.com", "encoded123", "Test User"));

        // When
        User result = userService.createUser(request);

        // Then
        assertThat(result.getId()).isNotNull();
        assertThat(result.getEmail()).isEqualTo("test@example.com");
        assertThat(result.getName()).isEqualTo("Test User");
        verify(userRepository).save(any(User.class));
    }

    @Test
    @DisplayName("创建用户时邮箱已存在")
    void createUser_EmailExists_ThrowsException() {
        // Given
        UserCreateRequest request = new UserCreateRequest(
            "existing@example.com", "password123", "Test User");

        when(userRepository.existsByEmail("existing@example.com"))
            .thenReturn(true);

        // When & Then
        assertThrows(DuplicateEmailException.class, () -> {
            userService.createUser(request);
        });
    }
}
```

### 断言最佳实践
- **明确命名**: 使用@DisplayName描述测试意图
- **AAA模式**: Arrange（准备）、Act（执行）、Assert（断言）
- **充分断言**: 验证关键结果，不遗漏重要内容
- **异常测试**: 使用assertThrows验证异常抛出
```

#### 集成测试策略
```markdown
## 集成测试策略

### 数据库集成测试
```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ContextConfiguration(classes = {TestConfig.class})
class UserRepositoryIntegrationTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private UserRepository userRepository;

    @Test
    @Transactional
    void findByEmail_UserExists_ReturnsUser() {
        // Given
        User user = new User("test@example.com", "password123", "Test User");
        entityManager.persist(user);
        entityManager.flush();

        // When
        Optional<User> result = userRepository.findByEmail("test@example.com");

        // Then
        assertThat(result).isPresent();
        assertThat(result.get().getEmail()).isEqualTo("test@example.com");
    }
}
```

### API集成测试
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class UserControllerIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    @Transactional
    void createUser_EndToEnd_ReturnsCreatedUser() {
        // Given
        UserCreateRequest request = new UserCreateRequest(
            "test@example.com", "password123", "Test User");

        // When
        ResponseEntity<User> response = restTemplate.postForEntity(
            "/api/users", request, User.class);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody().getEmail()).isEqualTo("test@example.com");
        assertThat(response.getBody().getId()).isNotNull();
    }
}
```
```

#### 端到端测试
```markdown
## 端到端测试实践

### Selenium测试
```java
@ExtendWith({SeleniumExtension.class})
class UserE2ETest {

    private WebDriver driver;
    private UserPage userPage;

    @BeforeEach
    void setUp(WebDriver driver) {
        this.driver = driver;
        this.userPage = new UserPage(driver);
        driver.get("http://localhost:8080/users");
    }

    @Test
    void createUser_Success() {
        // When
        userPage.clickCreateUser();
        userPage.fillForm("test@example.com", "password123", "Test User");
        userPage.clickSubmit();

        // Then
        assertThat(userPage.getSuccessMessage()).contains("用户创建成功");
        assertThat(userPage.getUserList()).contains("test@example.com");
    }
}
```

### Cypress测试
```javascript
describe('User Management', () => {
  beforeEach(() => {
    cy.visit('/users');
  });

  it('should create a new user', () => {
    cy.contains('创建用户').click();

    cy.get('input[name="email"]').type('test@example.com');
    cy.get('input[name="password"]').type('password123');
    cy.get('input[name="name"]').type('Test User');
    cy.get('button[type="submit"]').click();

    cy.contains('用户创建成功').should('be.visible');
    cy.contains('test@example.com').should('be.visible');
  });
});
```
```

### 测试自动化策略

#### CI/CD集成
```yaml
# GitHub Actions示例
name: Test Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        test-type: [unit, integration, e2e]

    steps:
    - uses: actions/checkout@v3

    - name: Setup JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'

    - name: Cache Maven dependencies
      uses: actions/cache@v3
      with:
        path: ~/.m2/repository
        key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}

    - name: Run ${{ matrix.test-type }} tests
      run: |
        if [ "${{ matrix.test-type }}" = "unit" ]; then
          mvn test -Dtest="*Test"
        elif [ "${{ matrix.test-type }}" = "integration" ]; then
          mvn verify -Dtest="*IntegrationTest"
        else
          mvn verify -Dtest="*E2ETest"
        fi

    - name: Upload test results
      uses: actions/upload-artifact@v3
      with:
        name: test-results-${{ matrix.test-type }}
        path: target/surefire-reports/
```

#### 测试数据管理
```markdown
## 测试数据管理

### 测试数据生成
```java
@TestConfiguration
class TestDataConfig {

    @Bean
    public TestDataGenerator testDataGenerator() {
        return new TestDataGenerator();
    }
}

@Component
public class TestDataGenerator {

    public User generateRandomUser() {
        return User.builder()
            .email(generateRandomEmail())
            .password(generateRandomPassword())
            .name(generateRandomName())
            .build();
    }

    private String generateRandomEmail() {
        return UUID.randomUUID().toString() + "@example.com";
    }

    private String generateRandomPassword() {
        return UUID.randomUUID().toString().substring(0, 12);
    }

    private String generateRandomName() {
        String[] names = {"Alice", "Bob", "Charlie", "David", "Eve"};
        return names[new Random().nextInt(names.length)];
    }
}
```

### 测试数据隔离
```java
@Transactional
@Rollback
@SpringBootTest
class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TestDataGenerator testDataGenerator;

    @Test
    void findByEmail_UserExists_ReturnsUser() {
        // Given - 使用生成的测试数据
        User user = testDataGenerator.generateRandomUser();
        userRepository.save(user);

        // When
        Optional<User> result = userRepository.findByEmail(user.getEmail());

        // Then
        assertThat(result).isPresent();
        assertThat(result.get().getEmail()).isEqualTo(user.getEmail());
    }
}
```
```

### 测试覆盖率分析

#### 覆盖率配置
```xml
<!-- Maven Surefire Plugin配置 -->
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <version>3.0.0-M7</version>
</plugin>

<!-- JaCoCo配置 -->
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.7</version>
    <executions>
        <execution>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

#### 覆盖率标准
```markdown
## 测试覆盖率标准

### 单元测试覆盖率
- **优秀**: >90%
- **良好**: 80-90%
- **及格**: 70-80%
- **需要改进**: <70%

### 分支覆盖率
- **条件语句**: 所有分支都要覆盖
- **异常处理**: 成功和失败场景都要测试
- **边界条件**: 边值测试必须覆盖

### 代码覆盖率规则
1. **核心业务逻辑**: 90%+ 覆盖率
2. **工具类**: 80%+ 覆盖率
3. **API层**: 85%+ 覆盖率
4. **数据层**: 80%+ 覆盖率
```

### 测试策略制定

### 测试金字塔
```markdown
## 测试金字塔比例

### 单元测试 (70%)
- 快速执行 (< 1秒)
- 大量测试用例
- 覆盖核心逻辑
- 自动化程度高

### 集成测试 (20%)
- 中等速度 (1-10秒)
- 测试组件交互
- 测试外部依赖
- 关键路径测试

### 端到端测试 (10%)
- 慢速执行 (> 10秒)
- 测试完整用户场景
- 测试系统集成
- 关键业务流程
```

### 测试计划制定
```markdown
# 测试计划

## 测试目标
- **功能覆盖**: 100%核心功能测试
- **性能目标**: 响应时间 < 2秒
- **质量目标**: 缺陷密度 < 1/KLOC
- **回归目标**: 95%测试自动化

## 测试策略
### 单元测试
- **测试框架**: JUnit 5 + Mockito
- **覆盖率**: 目标90%
- **执行频率**: 每次提交
- **责任人**: 开发人员

### 集成测试
- **测试框架**: Spring Boot Test
- **覆盖率**: 目标80%
- **执行频率**: 每次构建
- **责任人**: 测试团队

### 端到端测试
- **测试框架**: Selenium + Cypress
- **覆盖率**: 关键路径100%
- **执行频率**: 每天构建
- **责任人**: 测试团队

## 测试时间表
- **单元测试**: 持续执行
- **集成测试**: 每天构建执行
- **端到端测试**: 每周完整执行
- **性能测试**: 每月执行
```

### 输出产物

#### 测试报告模板
```markdown
# 测试报告

## 测试概览
- **测试执行时间**: [日期时间]
- **测试环境**: [环境配置]
- **测试版本**: [版本号]
- **测试工具**: [工具列表]

### 测试统计
| 测试类型 | 总数 | 通过 | 失败 | 跳过 | 通过率 |
|----------|------|------|------|------|--------|
| 单元测试 | [总数] | [通过数] | [失败数] | [跳过数] | [百分比]% |
| 集成测试 | [总数] | [通过数] | [失败数] | [跳过数] | [百分比]% |
| 端到端测试 | [总数] | [通过数] | [失败数] | [跳过数] | [百分比]% |

## 失败测试分析
### 高优先级问题
1. **[测试名称]**: [问题描述]
   - **影响**: [业务影响]
   - **原因**: [根本原因]
   - **解决方案**: [修复方案]
   - **责任人**: [负责人]

2. **[测试名称]**: [问题描述]
   - **影响**: [业务影响]
   - **原因**: [根本原因]
   - **解决方案**: [修复方案]
   - **责任人**: [负责人]

### 代码覆盖率
- **总体覆盖率**: [百分比]%
- **分支覆盖率**: [百分比]%
- **方法覆盖率**: [百分比]%
- **行覆盖率**: [百分比]%

## 改进建议
### 短期改进
- [改进建议1]
- [改进建议2]

### 长期改进
- [改进建议1]
- [改进建议2]
```

### 最佳实践

#### 测试文化建设
1. **测试左移**: 开发阶段就考虑测试
2. **测试驱动**: 先写测试再写代码
3. **持续集成**: 自动化测试执行
4. **质量门禁**: 测试不通过不得合并

#### 测试工具选择
- **Java生态**: JUnit 5 + Mockito + Spring Boot Test
- **JavaScript生态**: Jest + React Testing Library + Cypress
- **Python生态**: pytest + unittest + Selenium
- **Go生态**: testify + ginkgo + testcontainers

### 使用场景

#### 何时使用此技能
1. **项目启动**: 制定测试策略和框架
2. **开发阶段**: 编写和执行测试
3. **集成阶段**: 组件间测试
4. **上线前**: 完整测试验证
5. **维护阶段**: 回归测试和持续改进

#### 技能优势
- **全面覆盖**: 从单元到端到端的完整测试体系
- **实用框架**: 具体的测试工具和框架推荐
- **自动化策略**: CI/CD集成和自动化测试
- **质量保证**: 测试质量标准和覆盖率管理