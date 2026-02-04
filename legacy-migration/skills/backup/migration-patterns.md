---
name: migration-patterns
description: 微服务迁移模式和最佳实践库
level: expert
prerequisites:
  - 微服务架构知识
- 企业集成模式
- 分布式系统经验
outputs:
  - 模式实现指南
  - 迁移策略建议
  - 最佳实践文档
  - 反模式识别
---

# 微服务迁移模式库

本技能提供了全面的迁移模式、反模式和最佳实践，用于将单体应用转换为微服务架构。

## 核心迁移模式

### 1. Strangler Fig Pattern

#### Pattern Overview
```markdown
## Strangler Fig Pattern

### Description
Gradually replace functionality in a monolithic application by building new services around the existing application, slowly "strangling" the old system until it can be decommissioned.

### When to Use
- Large, mission-critical systems that cannot be replaced all at once
- Systems requiring continuous business operation during migration
- Complex business logic with unknown dependencies
- Risk-averse migration approaches needed

### Benefits
- Minimizes business disruption
- Allows incremental value delivery
- Reduces migration risk
- Provides rollback capabilities

### Challenges
- Requires careful routing and proxy management
- Longer migration timeline
- Complex integration period
- Requires dual system maintenance
```

#### Implementation Strategy
```markdown
## Strangler Fig Implementation Phases

### Phase 1: API Gateway Setup
```yaml
# Example API Gateway Configuration
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: legacy-routing
spec:
  http:
  - match:
    - headers:
        x-migration-phase:
          exact: "complete"
    route:
    - destination:
        host: new-service
        port:
          number: 8080
  - match:
    - headers:
        x-feature-flag:
          exact: "new-service-enabled"
    route:
    - destination:
        host: new-service
        port:
          number: 8080
      weight: 100
    - destination:
        host: legacy-service
        port:
          number: 8080
      weight: 0
  - route:
    - destination:
        host: legacy-service
        port:
          number: 8080
```

### Phase 2: Feature Flag Implementation
```java
// Feature Flag Service
@Service
public class FeatureFlagService {

    @Autowired
    private FeatureFlagRepository flagRepository;

    public boolean isFeatureEnabled(String featureName, String userId) {
        Optional<FeatureFlag> flag = flagRepository.findByFeatureName(featureName);

        if (!flag.isPresent()) {
            return false;
        }

        FeatureFlag feature = flag.get();

        // Check if feature is globally enabled
        if (feature.isGloballyEnabled()) {
            return true;
        }

        // Check user-specific rollout
        return feature.getEnabledUsers().contains(userId) ||
               shouldEnableForUser(feature, userId);
    }

    private boolean shouldEnableForUser(FeatureFlag feature, String userId) {
        // Implement percentage-based rollout
        return Math.abs(userId.hashCode() % 100) < feature.getRolloutPercentage();
    }
}

// Service Router with Feature Flags
@RestController
@RequestMapping("/api/orders")
public class OrderRouterController {

    @Autowired
    private FeatureFlagService featureFlagService;

    @Autowired
    private NewOrderService newOrderService;

    @Autowired
    private LegacyOrderService legacyOrderService;

    @PostMapping
    public ResponseEntity<OrderResponse> createOrder(
            @RequestBody OrderRequest request,
            @RequestHeader("X-User-ID") String userId) {

        if (featureFlagService.isFeatureEnabled("new-order-service", userId)) {
            OrderResponse response = newOrderService.createOrder(request);
            return ResponseEntity.ok()
                .header("X-Service-Version", "new")
                .body(response);
        } else {
            OrderResponse response = legacyOrderService.createOrder(request);
            return ResponseEntity.ok()
                .header("X-Service-Version", "legacy")
                .body(response);
        }
    }
}
```

### Phase 3: Gradual Traffic Migration
```bash
#!/bin/bash
# Gradual traffic migration script

MIGRATION_PHASES=("5" "10" "25" "50" "75" "90" "100")
NEW_SERVICE_HOST="new-order-service.default.svc.cluster.local"
LEGACY_SERVICE_HOST="legacy-order-service.default.svc.cluster.local"

for phase in "${MIGRATION_PHASES[@]}"; do
    echo "Migrating $phase% traffic to new service..."

    # Update Istio VirtualService
    kubectl patch virtualservice legacy-routing -p '
    {
        "spec": {
            "http": [
                {
                    "match": [
                        {
                            "headers": {
                                "x-traffic-split": {"exact": "test"}
                            }
                        }
                    ],
                    "route": [
                        {
                            "destination": {"host": "'$NEW_SERVICE_HOST'"},
                            "weight": '$phase'
                        },
                        {
                            "destination": {"host": "'$LEGACY_SERVICE_HOST'"},
                            "weight": '$((100 - phase))'
                        }
                    ]
                }
            ]
        }
    }'

    # Wait for stability period
    echo "Waiting for stability check..."
    sleep 300

    # Run health checks
    ./scripts/health-check.sh $phase

    # Prompt for manual confirmation
    read -p "Continue to next phase? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Migration paused. Manual intervention required."
        exit 1
    fi
done

echo "Migration to new service complete!"
```

### 2. Anticorruption Layer Pattern

#### Pattern Implementation
```markdown
## Anticorruption Layer (ACL) Pattern

### Description
Create a translation layer between new microservices and legacy systems to prevent legacy concepts from "infecting" the new architecture.

### Implementation Structure
```
Legacy System ← Anticorruption Layer ← New Microservices
```

### ACL Components
1. **Translation Layer**: Convert data formats and protocols
2. **Adapter Layer**: Adapt interfaces and APIs
3. **Facade Layer**: Simplify complex legacy interactions
4. **Validation Layer**: Ensure data integrity and business rules
```

#### Code Implementation
```java
// Anticorruption Layer for Legacy Order System
@Service
@Transactional
public class LegacyOrderACL {

    private final LegacyOrderWebService legacyService;
    private final OrderMapper orderMapper;
    private final OrderRepository orderRepository;
    private final CircuitBreaker circuitBreaker;

    @Autowired
    public LegacyOrderACL(LegacyOrderWebService legacyService,
                         OrderMapper orderMapper,
                         OrderRepository orderRepository,
                         CircuitBreaker circuitBreaker) {
        this.legacyService = legacyService;
        this.orderMapper = orderMapper;
        this.orderRepository = orderRepository;
        this.circuitBreaker = circuitBreaker;
    }

    // Create order using legacy system via ACL
    public Order createOrder(OrderRequest request) {
        return circuitBreaker.executeSupplier(() -> {
            try {
                // Translate to legacy format
                LegacyOrderRequest legacyRequest = orderMapper.toLegacyRequest(request);

                // Call legacy system
                LegacyOrderResponse legacyResponse = legacyService.createOrder(legacyRequest);

                // Translate back to domain model
                Order order = orderMapper.fromLegacyResponse(legacyResponse);

                // Persist in new system for consistency
                orderRepository.save(order);

                return order;

            } catch (LegacySystemException e) {
                // Handle legacy-specific errors
                throw new OrderCreationException(
                    "Failed to create order via legacy system", e);
            }
        });
    }

    // Get order with fallback to legacy system
    public Optional<Order> getOrder(String orderId) {
        // Try new system first
        Optional<Order> order = orderRepository.findById(orderId);
        if (order.isPresent()) {
            return order;
        }

        // Fallback to legacy system
        return circuitBreaker.executeSupplier(() -> {
            try {
                LegacyOrder legacyOrder = legacyService.getOrder(orderId);
                Order newOrder = orderMapper.fromLegacy(legacyOrder);
                orderRepository.save(newOrder);
                return Optional.of(newOrder);
            } catch (OrderNotFoundException e) {
                return Optional.empty();
            }
        });
    }
}

// Data Mapper for translation
@Component
public class OrderMapper {

    public LegacyOrderRequest toLegacyRequest(OrderRequest request) {
        LegacyOrderRequest legacy = new LegacyOrderRequest();

        // Translate field names and formats
        legacy.setOrderNumber(request.getOrderNumber());
        legacy.setCustomerIdentifier(request.getCustomerId());
        legacy.setOrderTotal(request.getTotalAmount().doubleValue());
        legacy.setOrderDateString(request.getOrderDate().format(DateTimeFormatter.ISO_DATE));

        // Translate line items
        List<LegacyLineItem> legacyItems = request.getLineItems().stream()
            .map(this::toLegacyLineItem)
            .collect(Collectors.toList());
        legacy.setLineItems(legacyItems);

        // Set legacy-specific fields
        legacy.setLegacyVersion("1.0");
        legacy.setProcessingCenterId(determineProcessingCenter(request.getShippingAddress()));

        return legacy;
    }

    public Order fromLegacyResponse(LegacyOrderResponse response) {
        Order order = new Order();

        order.setId(response.getOrderId());
        order.setOrderNumber(response.getOrderNumber());
        order.setCustomerId(response.getCustomerIdentifier());
        order.setTotalAmount(BigDecimal.valueOf(response.getOrderTotal()));
        order.setStatus(mapLegacyStatus(response.getOrderStatus()));
        order.setOrderDate(LocalDate.parse(response.getOrderDateString()));

        // Map line items
        List<LineItem> items = response.getLineItems().stream()
            .map(this::fromLegacyLineItem)
            .collect(Collectors.toList());
        order.setLineItems(items);

        return order;
    }

    private OrderStatus mapLegacyStatus(String legacyStatus) {
        switch (legacyStatus) {
            case "NEW": return OrderStatus.PENDING;
            case "PROCESSING": return OrderStatus.CONFIRMED;
            case "SHIPPED": return OrderStatus.SHIPPED;
            case "COMPLETED": return OrderStatus.DELIVERED;
            case "CANCELLED": return OrderStatus.CANCELLED;
            default: return OrderStatus.UNKNOWN;
        }
    }
}
```

### 3. Database Decomposition Patterns

#### Database-per-Service Pattern
```markdown
## Database-per-Service Implementation

### Phase 1: Database Analysis
```sql
-- Identify table ownership patterns
SELECT
    t.table_name,
    COUNT(DISTINCT s.service_name) as service_count,
    GROUP_CONCAT(DISTINCT s.service_name) as services
FROM tables t
JOIN table_service_mapping s ON t.table_id = s.table_id
GROUP BY t.table_name
ORDER BY service_count, t.table_name;

-- Analyze foreign key relationships
SELECT
    fk.child_table,
    fk.parent_table,
    COUNT(*) as relationship_count,
    s1.service_name as child_service,
    s2.service_name as parent_service
FROM foreign_keys fk
JOIN table_service_mapping s1 ON fk.child_table_id = s1.table_id
JOIN table_service_mapping s2 ON fk.parent_table_id = s2.table_id
WHERE s1.service_name != s2.service_name
GROUP BY fk.child_table, fk.parent_table, s1.service_name, s2.service_name;
```

### Phase 2: Database Schema Creation
```sql
-- Create service-specific database schema
CREATE DATABASE orders_service;
CREATE DATABASE customers_service;
CREATE DATABASE products_service;
CREATE DATABASE payments_service;

-- Copy tables to service databases
-- Orders service tables
CREATE TABLE orders_service.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL,
    order_date TIMESTAMP NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders_service.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id),
    product_id UUID NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Phase 3: Data Synchronization
```java
// Event-based data synchronization
@Component
public class DataSyncService {

    @Autowired
    private JdbcTemplate legacyJdbcTemplate;

    @Autowired
    private JdbcTemplate newJdbcTemplate;

    @EventListener
    @Transactional
    public void handleOrderCreated(OrderCreatedEvent event) {
        // Sync to legacy system during migration
        String syncSql = """
            INSERT INTO legacy.orders (id, customer_id, order_date, total_amount, status)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT (id) DO UPDATE SET
                customer_id = EXCLUDED.customer_id,
                order_date = EXCLUDED.order_date,
                total_amount = EXCLUDED.total_amount,
                status = EXCLUDED.status
            """;

        newJdbcTemplate.update(syncSql,
            event.getOrderId(),
            event.getCustomerId(),
            event.getOrderDate(),
            event.getTotalAmount(),
            event.getStatus());
    }

    // Bulk data migration
    @Scheduled(cron = "0 2 * * *") // Daily at 2 AM
    public void migrateHistoricalData() {
        int batchSize = 1000;
        int offset = 0;
        boolean hasMoreData = true;

        while (hasMoreData) {
            String selectSql = """
                SELECT id, customer_id, order_date, total_amount, status, created_at, updated_at
                FROM legacy.orders
                WHERE created_at >= ?
                ORDER BY created_at
                LIMIT ? OFFSET ?
                """;

            List<Order> orders = legacyJdbcTemplate.query(
                selectSql,
                new Object[]{getMigrationCutoffDate(), batchSize, offset},
                new OrderRowMapper()
            );

            if (orders.isEmpty()) {
                hasMoreData = false;
            } else {
                batchInsertOrders(orders);
                offset += batchSize;
                log.info("Migrated {} orders", offset + orders.size());
            }
        }
    }
}
```

### 4. Saga Pattern for Distributed Transactions

#### Saga Implementation
```java
// Saga orchestration for order processing
@Component
public class OrderProcessingSaga {

    @Autowired
    private SagaManager sagaManager;

    @Autowired
    private InventoryService inventoryService;

    @Autowired
    private PaymentService paymentService;

    @Autowired
    private OrderService orderService;

    @Autowired
    private NotificationService notificationService;

    public CompletableFuture<Order> processOrder(OrderRequest request) {
        return sagaManager.choreography()
            .step("reserveInventory")
            .compensateWith("releaseInventory")
            .execute(() -> inventoryService.reserveInventory(request.getItems()))

            .step("processPayment")
            .compensateWith("refundPayment")
            .execute(() -> paymentService.processPayment(
                request.getPaymentInfo(),
                request.getTotalAmount()))

            .step("createOrder")
            .compensateWith("cancelOrder")
            .execute(() -> orderService.createOrder(request))

            .step("sendConfirmation")
            .compensateWith("sendCancellation")
            .execute(() -> notificationService.sendOrderConfirmation(
                request.getCustomerId(),
                request.getOrderNumber()))

            .thenApply(result -> extractOrderFromResult(result))
            .exceptionally(throwable -> {
                log.error("Order processing failed", throwable);
                throw new OrderProcessingException("Failed to process order", throwable);
            });
    }
}

// Saga manager implementation
@Service
public class SagaManager {

    @Autowired
    private ApplicationEventPublisher eventPublisher;

    public <T> SagaChoreography<T> choreography() {
        return new SagaChoreography<>(eventPublisher);
    }
}

public class SagaChoreography<T> {

    private final List<SagaStep<T>> steps = new ArrayList<>();
    private final ApplicationEventPublisher eventPublisher;

    public SagaChoreography(ApplicationEventPublisher eventPublisher) {
        this.eventPublisher = eventPublisher;
    }

    public SagaChoreography<T> step(String stepName) {
        SagaStep<T> step = new SagaStep<>(stepName);
        steps.add(step);
        return step;
    }

    public <R> SagaChoreography<T> execute(Supplier<R> operation) {
        if (!steps.isEmpty()) {
            steps.get(steps.size() - 1).setOperation(operation);
        }
        return this;
    }

    public SagaChoreography<T> compensateWith(String compensationStep) {
        if (!steps.isEmpty()) {
            steps.get(steps.size() - 1).setCompensationStep(compensationStep);
        }
        return this;
    }

    public CompletableFuture<T> thenApply(Function<T, T> mapper) {
        CompletableFuture<T> result = CompletableFuture.completedFuture(null);

        for (SagaStep<T> step : steps) {
            result = result.thenCompose(ignored -> {
                try {
                    T stepResult = (T) step.getOperation().get();
                    eventPublisher.publishEvent(new SagaStepCompletedEvent(step.getStepName(), stepResult));
                    return CompletableFuture.completedFuture(stepResult);
                } catch (Exception e) {
                    eventPublisher.publishEvent(new SagaStepFailedEvent(step.getStepName(), e));
                    return executeCompensationSteps(steps.indexOf(step));
                }
            });
        }

        return result.thenApply(mapper);
    }

    private <T> CompletableFuture<T> executeCompensationSteps(int failedStepIndex) {
        // Execute compensation steps in reverse order
        for (int i = failedStepIndex; i >= 0; i--) {
            SagaStep<T> step = steps.get(i);
            if (step.getCompensationStep() != null) {
                eventPublisher.publishEvent(new SagaCompensationEvent(step.getCompensationStep()));
            }
        }

        return CompletableFuture.failedFuture(new SagaRollbackException("Saga rolled back due to failure"));
    }
}
```

## Anti-Patterns to Avoid

### 1. Distributed Monolith
```markdown
## Distributed Monolith Anti-Pattern

### Description
Services that are tightly coupled through synchronous communication, shared databases, or complex deployment dependencies.

### Symptoms
- Services cannot be deployed independently
- Changes to one service require coordinated deployments of others
- Performance issues due to excessive inter-service communication
- Complex deployment and rollback procedures

### Solutions
- Implement asynchronous communication patterns
- Ensure proper service boundaries
- Use database-per-service pattern
- Implement proper service discovery and configuration
```

### 2. Shared Database Anti-Pattern
```markdown
## Shared Database Anti-Pattern

### Description
Multiple services sharing the same database, creating tight coupling and making independent deployment difficult.

### Symptoms
- Database schema changes require coordinated service updates
- Performance issues due to conflicting database access patterns
- Difficulty implementing service-specific data models
- Complex transaction management

### Solutions
- Implement database-per-service pattern
- Use event-driven data synchronization
- Implement API-based data access
- Use sagas for distributed transactions
```

### 3. Service Granularity Issues
```markdown
## Service Granularity Anti-Patterns

### Nanoservices
- **Problem**: Services that are too small, doing very little
- **Symptoms**: Excessive network overhead, operational complexity
- **Solution**: Combine related functionality into coherent services

### Monolithic Services
- **Problem**: Services that are too large, essentially monoliths
- **Symptoms**: Deployment issues, team coordination problems
- **Solution**: Further decompose based on business capabilities

### Solution
Apply the "Single Responsibility Principle" at the service level:
- Each service should own one business capability
- Services should be independently deployable
- Services should have their own data
- Services should be independently scalable
```

## Best Practices

### 1. Service Design Principles
```markdown
## Service Design Best Practices

### High Cohesion
- Group related functionality together
- Ensure services have clear business boundaries
- Align services with business capabilities

### Loose Coupling
- Minimize inter-service dependencies
- Use asynchronous communication where possible
- Implement proper service contracts

### Bounded Context
- Define clear service responsibilities
- Ensure data ownership boundaries
- Establish service governance

### Autonomy
- Services should be independently deployable
- Services should be independently scalable
- Services should have independent data
```

### 2. Migration Best Practices
```markdown
## Migration Best Practices

### Incremental Approach
- Start with low-risk, high-value services
- Implement proper feature flags and circuit breakers
- Use gradual traffic migration
- Monitor business metrics closely

### Data Consistency
- Implement eventual consistency patterns
- Use sagas for distributed transactions
- Plan data migration carefully
- Implement proper rollback procedures

### Operational Excellence
- Implement comprehensive monitoring
- Use proper logging and tracing
- Automate deployment and rollback
- Plan for disaster recovery
```

### 3. Technology Selection
```markdown
## Technology Selection Guidelines

### Right-Sizing Technology
- Choose technology based on service requirements
- Avoid technology heterogeneity where not needed
- Consider team expertise and learning curve
- Plan for long-term maintenance

### Integration Patterns
- Use API gateways for external access
- Implement service mesh for internal communication
- Use message brokers for asynchronous communication
- Implement proper authentication and authorization
```

This comprehensive migration patterns library provides the essential patterns, anti-patterns, and best practices needed to successfully navigate the complex journey from monolithic to microservices architecture.