---
name: kafka-consumer
description: Create a Kafka consumer/producer with idempotency for a Spring Boot service. Use when wiring async inter-service events, adding topics, or consuming platform events.
---

# Kafka Consumer

Add event publishing/consuming to a Spring Boot service using the platform's Kafka patterns.

## Event envelope

```java
public record OrderPlacedEvent(
    String eventId,          // UUID — idempotency key, set by producer
    Long orderId,
    String orderNumber,
    Long userId,
    BigDecimal totalAmount,
    List<OrderItemDto> items,
    LocalDateTime occurredAt
) {}
```

## Producer (transactional)

```java
@Service
@RequiredArgsConstructor
public class OrderEventPublisher {
    private final KafkaTemplate<String, Object> kafka;
    private final ObjectMapper mapper;

    public void publishOrderPlaced(Order order) {
        var event = new OrderPlacedEvent(
            UUID.randomUUID().toString(), order.getId(), order.getOrderNumber(),
            order.getUserId(), order.getTotalAmount(), mapItems(order),
            LocalDateTime.now());
        kafka.send("order.placed", order.getOrderNumber(), event);
    }
}
```

Topic string constants live in a `Topics` utility (or config `app.kafka.topics.*`).

## Consumer with idempotency

```java
@Service
@RequiredArgsConstructor
public class CheckoutEventConsumer {
    private final IdempotencyKeyRepository idempotencyRepo;
    private final OrderService orderService;

    @KafkaListener(topics = "cart.checkout.initiated", groupId = "order-api")
    public void handle(CartCheckoutEvent event) {
        if (idempotencyRepo.existsById(event.eventId())) {
            log.warn("Duplicate event ignored: {}", event.eventId());
            return;
        }
        orderService.placeOrderFromCheckout(event);
        idempotencyRepo.save(new IdempotencyRecord(event.eventId(), "CART_CHECKOUT", LocalDateTime.now()));
    }
}
```

Persist the key **in the same DB transaction** as the side effect to avoid the "consume → crash → duplicate" window. Wrap consumer body in `@Transactional`. The dedicated `idempotency_keys` table lives in the consuming service's own schema.

## Config

```yaml
spring:
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:kafka:9092}
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
      properties.spring.json.add.type.headers: false
    consumer:
      group-id: "{service}"
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties.spring.json.trusted.packages: "com.ecommerce.*,com.company.orderapi.*"
      properties.spring.json.value.default.type: com.ecommerce.{service}.event.CartCheckoutEvent
      enable-auto-commit: false
```

Set `ackMode: MANUAL_IMMEDIATE` or rely on the default `@Transactional` ack — do not auto-commit raw.

## Security
- Validate `spring.json.trusted.packages` — never `*`
- Schema the idempotency table in Liquibase (see liquibase-migration skill)

## Quality gates
- Idempotent consumers (tested: duplicate event → no-op)
- Event payloads are final records (immutable)
- Integration test with `@EmbeddedKafka` or Testcontainers Kafka