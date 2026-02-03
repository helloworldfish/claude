---
name: transpile
description: 将代码从一种编程语言转换为另一种编程语言，包括框架和模式适配
parameters:
  - name: source
    type: string
    description: 源代码路径
    required: true
  - name: from
    type: string
    description: 源语言
    required: true
  - name: to
    type: string
    description: 目标语言
    required: true
  - name: output
    type: string
    description: 转换后代码的输出目录
    required: true
  - name: convert_framework
    type: boolean
    description: 同时转换框架特定代码
    required: false
    default: false
  - name: convert_tests
    type: boolean
    description: 同时转换测试代码
    required: false
    default: true
examples:
  - "/transpile --source src/main/java --from java --to kotlin --output src/main/kotlin"
  - "/transpile --source src --from javascript --to typescript --output src-ts --convert_framework"
  - "/transpile --source backend --from python --to go --output backend-go"
---

# 语言转换命令

您正在执行从一种编程语言到另一种编程语言的代码转换，包含智能语法转换、库映射和模式适配。

## 转换过程

### 阶段 1：源代码分析

#### 1.1 语言特性检测
```markdown
## 检测源语言特性
- 语法模式
- 标准库使用
- 框架特定代码
- 语言特定惯用语
- 代码模式和约定
```

#### 1.2 依赖映射
```markdown
## 将源依赖映射到目标
- 标准库等价物
- 第三方库替代方案
- 框架转换
- 构建系统更新
- 包管理器变更
```

### 阶段 2：转换策略

#### 2.1 语法转换
```markdown
## 按语言对映射语法

### Java → Kotlin
- Classes remain classes
- Getters/setters → properties
- Semicolons removed
- Null safety added
- Extension functions for utility methods
- Data classes for POJOs
- Coroutines for async

### Java → C#
- Package → namespace
- import → using
- @Override → override
- List<T> → List<T>
- Map<K,V> → Dictionary<K,V>
- @Entity, @Service attributes
- async/await instead of CompletableFuture

### JavaScript → TypeScript
- Add type annotations
- Interface definitions
- Type imports
- Generic types
- Null checks
- Strict type checking

### Python → Go
- Classes → structs + methods
- List comprehension → loops
- Decorators → middleware
- try/except → if err != nil
- List/Dict → slices/maps
- Goroutines for threading

### PHP → Node.js/TypeScript
- Arrays → objects/arrays
- foreach → for/forEach
- Classes → classes (TypeScript)
- PDO → database libraries
- Composer → npm
```

#### 2.2 Library and Framework Mapping
```markdown
## Framework Equivalents

### Web Frameworks
- Spring Boot (Java) → Gin (Go) / ASP.NET (C#) / FastAPI (Python)
- Express (Node.js) → Fiber (Go) / Gin (Go)
- Django (Python) → Go-Gin (Go) / ASP.NET MVC (C#)

### Database ORMs
- Hibernate (Java) → GORM (Go) / Entity Framework (C#) / SQLAlchemy (Python)
- JPA (Java) → GORM (Go) / EF Core (C#)
- MyBatis (Java) → sqlx (Go) / Dapper (C#)

### HTTP Clients
- RestTemplate (Java) → resty (Go) / HttpClient (C#) / axios (Node.js)
- OkHttp (Java) → http.Client (Go) / HttpClient (C#)

### Testing
- JUnit (Java) → testing (Go) / xUnit (C#) / pytest (Python)
- Mockito (Java) → testify/mock (Go) / Moq (C#)
- Jest (Node.js) → testing (Go)
```

### Phase 3: Code Transformation

#### 3.1 File Structure Mapping
```markdown
## Directory Structure Transformations

### Java (Maven)
src/
├── main/
│   ├── java/
│   │   └── com/example/
│   └── resources/
└── test/
    └── java/

↓ Convert to

### Go
go/
├── pkg/
│   └── example/
├── cmd/
│   └── app/
└── internal/
    └── ...

### Java (Maven)
↓ Convert to

### Kotlin (Gradle)
src/
├── main/
│   ├── kotlin/
│   │   └── com/example/
│   └── resources/
└── test/
    └── kotlin/

### JavaScript (npm)
src/
├── index.js
├── components/
└── utils/

↓ Convert to

### TypeScript
src/
├── index.ts
├── components/
│   ├── Component.tsx
│   └── Component.types.ts
└── utils/
    └── util.ts
```

#### 3.2 Code Pattern Transformations

##### Java to Kotlin Examples
```java
// Java Source
public class User {
    private String name;
    private int age;

    public User(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }
}

// Kotlin Target
data class User(
    var name: String,
    var age: Int
)
```

```java
// Java - Optional handling
public String getDisplayName(User user) {
    return Optional.ofNullable(user)
        .map(User::getName)
        .orElse("Unknown");
}

// Kotlin - Null safety
fun getDisplayName(user: User?): String {
    return user?.name ?: "Unknown"
}
```

```java
// Java - Stream API
List<String> names = users.stream()
    .filter(u -> u.getAge() > 18)
    .map(User::getName)
    .collect(Collectors.toList());

// Kotlin - Sequence/Collection
val names = users
    .filter { it.age > 18 }
    .map { it.name }
```

##### JavaScript to TypeScript Examples
```javascript
// JavaScript Source
function createUser(name, age, email) {
    return {
        name,
        age,
        email,
        createdAt: new Date()
    };
}

async function fetchUsers() {
    const response = await fetch('/api/users');
    const users = await response.json();
    return users;
}

// TypeScript Target
interface User {
    name: string;
    age: number;
    email: string;
    createdAt: Date;
}

function createUser(name: string, age: number, email: string): User {
    return {
        name,
        age,
        email,
        createdAt: new Date()
    };
}

async function fetchUsers(): Promise<User[]> {
    const response = await fetch('/api/users');
    const users: User[] = await response.json();
    return users;
}
```

##### Python to Go Examples
```python
# Python Source
class UserService:
    def __init__(self, db):
        self.db = db

    def get_user(self, user_id):
        return self.db.query("SELECT * FROM users WHERE id = %s", (user_id,))

    def create_user(self, name, email):
        self.db.execute("INSERT INTO users (name, email) VALUES (%s, %s)", (name, email))

# Go Target
type UserService struct {
    db *sql.DB
}

func NewUserService(db *sql.DB) *UserService {
    return &UserService{db: db}
}

func (s *UserService) GetUser(userID int) (*User, error) {
    user := &User{}
    err := s.db.QueryRow("SELECT * FROM users WHERE id = $1", userID).Scan(&user.ID, &user.Name, &user.Email)
    if err != nil {
        return nil, err
    }
    return user, nil
}

func (s *UserService) CreateUser(name, email string) error {
    _, err := s.db.Exec("INSERT INTO users (name, email) VALUES ($1, $2)", name, email)
    return err
}
```

### Phase 4: Build Configuration

#### 4.1 Build System Transformation
```markdown
## Build File Conversions

### pom.xml (Maven) → build.gradle.kts (Kotlin Gradle)
```xml
<!-- pom.xml -->
<project>
    <groupId>com.example</groupId>
    <artifactId>myapp</artifactId>
    <version>1.0.0</version>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>2.7.0</version>
        </dependency>
    </dependencies>
</project>
```

```kotlin
// build.gradle.kts
plugins {
    id("org.springframework.boot") version "2.7.0"
    id("io.spring.dependency-management") version "1.0.11.RELEASE"
    kotlin("jvm") version "1.6.0"
}

group = "com.example"
version = "1.0.0"

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
}
```

### package.json (JavaScript) → package.json (TypeScript)
```json
{
  "name": "myapp",
  "version": "1.0.0",
  "scripts": {
    "build": "webpack --mode production",
    "test": "jest"
  },
  "devDependencies": {
    "webpack": "^5.0.0",
    "jest": "^27.0.0"
  }
}
```

```json
{
  "name": "myapp",
  "version": "1.0.0",
  "scripts": {
    "build": "tsc && webpack --mode production",
    "test": "jest",
    "type-check": "tsc --noEmit"
  },
  "devDependencies": {
    "typescript": "^4.5.0",
    "@types/node": "^17.0.0",
    "@types/jest": "^27.0.0",
    "webpack": "^5.0.0",
    "ts-loader": "^9.0.0",
    "jest": "^27.0.0"
  }
}
```

### requirements.txt (Python) → go.mod (Go)
```
# requirements.txt
flask==2.0.0
sqlalchemy==1.4.0
pytest==6.2.0
```

```
// go.mod
module github.com/user/myapp

go 1.18

require (
    github.com/gin-gonic/gin v1.7.0
    gorm.io/gorm v1.22.0
    gorm.io/driver/postgres v1.2.0
)
```

### Phase 5: Test Conversion

#### 5.1 Test Framework Mapping
```markdown
## Test Framework Conversions

### JUnit (Java) → testify (Go)
```java
// Java JUnit
@Test
public void testGetUser() {
    User user = userService.get_User(1);
    assertNotNull(user);
    assertEquals("John", user.getName());
}
```

```go
// Go testify
func TestGetUser(t *testing.T) {
    user, err := userService.GetUser(1)
    assert.NoError(t, err)
    assert.NotNil(t, user)
    assert.Equal(t, "John", user.Name)
}
```

### Jest (JavaScript) → Jest (TypeScript)
```javascript
// JavaScript Jest
test('create user', () => {
    const user = createUser('John', 30, 'john@example.com');
    expect(user.name).toBe('John');
    expect(user.age).toBe(30);
});
```

```typescript
// TypeScript Jest
test('create user', () => {
    const user: User = createUser('John', 30, 'john@example.com');
    expect(user.name).toBe('John');
    expect(user.age).toBe(30);
    expect(user.createdAt).toBeInstanceOf(Date);
});
```

### pytest (Python) → testing (Go)
```python
# Python pytest
def test_get_user():
    user = user_service.get_user(1)
    assert user is not None
    assert user.name == 'John'
```

```go
// Go testing
func TestGetUser(t *testing.T) {
    user, err := userService.GetUser(1)
    if err != nil {
        t.Errorf("unexpected error: %v", err)
    }
    if user.Name != "John" {
        t.Errorf("expected name John, got %s", user.Name)
    }
}
```

## Transpilation Workflows

### Workflow 1: Java to Kotlin (Spring Boot)
```bash
# 1. Analyze Java project
/transpile --source src/main/java \
           --from java \
           --to kotlin \
           --output src/main/kotlin \
           --convert_framework

# 2. Review generated Kotlin code
# 3. Update build.gradle
# 4. Test the application
# 5. Iterate and refine
```

### Workflow 2: JavaScript to TypeScript (React)
```bash
# 1. Add TypeScript to project
npm install --save-dev typescript @types/react @types/node

# 2. Transpile JavaScript
/transpile --source src \
           --from javascript \
           --to typescript \
           --output src-ts \
           --convert_framework

# 3. Create type definitions
# 4. Update tsconfig.json
# 5. Test the application
```

### Workflow 3: Python to Go (API)
```bash
# 1. Initialize Go module
go mod init github.com/user/myapp

# 2. Transpile Python code
/transpile --source backend \
           --from python \
           --to go \
           --output backend-go \
           --convert_framework

# 3. Update go.mod
# 4. Implement main.go
# 5. Test the API
```

## Common Transformations

### Error Handling

#### Java to Kotlin
```java
// Java
try {
    doSomething();
} catch (IOException e) {
    log.error("Error", e);
    throw new RuntimeException(e);
}
```

```kotlin
// Kotlin
try {
    doSomething()
} catch (e: IOException) {
    log.error("Error", e)
    throw RuntimeException(e)
}
```

#### Python to Go
```python
# Python
try:
    result = do_something()
except Exception as e:
    log.error(f"Error: {e}")
    raise
```

```go
// Go
result, err := doSomething()
if err != nil {
    log.Printf("Error: %v", err)
    return err
}
```

### Async/Concurrent

#### Java to Kotlin
```java
// Java - CompletableFuture
CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> {
    return fetchUserData();
});
```

```kotlin
// Kotlin - Coroutines
val future = async {
    fetchUserData()
}
val result = future.await()
```

#### Python to Go
```python
# Python - asyncio
async def fetch_user_data():
    return await api_call()
```

```go
// Go - Goroutines
func fetchUserData() <-chan string {
    ch := make(chan string)
    go func() {
        ch <- apiCall()
    }()
    return ch
}
```

### Data Classes

#### Java to Kotlin
```java
// Java - POJO
public class User {
    private String name;
    private int age;

    // Constructor, getters, setters, equals, hashCode, toString
}
```

```kotlin
// Kotlin - Data Class
data class User(
    val name: String,
    val age: Int
)
```

#### Python to Go
```python
# Python - dataclass
@dataclass
class User:
    name: str
    age: int
```

```go
// Go - Struct
type User struct {
    Name string `json:"name"`
    Age  int    `json:"age"`
}
```

## Validation and Testing

### Validation Checklist
```markdown
## Post-Transpilation Validation

### Compilation
- [ ] Code compiles without errors
- [ ] No type errors (TypeScript)
- [ ] All dependencies resolved

### Functionality
- [ ] Core features work
- [ ] API endpoints respond
- [ ] Database operations work
- [ ] Business logic preserved

### Tests
- [ ] Unit tests converted and passing
- [ ] Integration tests passing
- [ ] Manual testing successful

### Performance
- [ ] Response times acceptable
- [ ] Memory usage normal
- [ ] No performance regression
```

## Best Practices

### Before Transpilation
1. ✅ Ensure code compiles and tests pass
2. ✅ Document complex logic
3. ✅ Refactor code-smells first
4. ✅ Create feature branches
5. ✅ Backup current state

### During Transpilation
1. ✅ Start with small modules
2. ✅ Convert incrementally
3. ✅ Maintain test coverage
4. ✅ Review generated code
5. ✅ Document manual changes

### After Transpilation
1. ✅ Comprehensive testing
2. ✅ Performance comparison
3. ✅ Code review
4. ✅ Update documentation
5. ✅ Team training

## Limitations and Considerations

### Language-Specific Challenges
```markdown
## Java → Kotlin
- Null safety: Requires careful handling of nullable types
- Extension functions: May refactor utility classes
- Coroutines: Async code transformation

## JavaScript → TypeScript
- Type inference: Some types may be 'any'
- Third-party libraries: May need @types packages
- Dynamic code: Requires careful typing

## Python → Go
- Dynamic typing: All types must be explicit
- Error handling: Go's error return pattern
- Classes vs structs: Different paradigms

## General Limitations
- Language-specific idioms may not translate perfectly
- Framework-specific features may need manual conversion
- Performance characteristics differ
- Standard library equivalents may not exist
```

## Integration with Other Commands

- **/detect-project**: Analyze source project structure
- **/refactor-plan**: Plan conversion strategy
- **/refactor-apply**: Apply code transformations
- **/upgrade**: Upgrade dependencies after conversion
- **/validate**: Validate transpiled code

You are providing intelligent code transpilation capabilities with syntax transformation, library mapping, and pattern adaptation to enable smooth language transitions while preserving functionality.
