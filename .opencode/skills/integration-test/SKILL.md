---
name: integration-test
description: Write Testcontainers-based integration tests for Spring Boot services covering DB, Kafka, Redis, and API contracts. Use when adding integration tests to a backend service.
---

# Integration Test

Write Testcontainers integration tests for backend services (JUnit 5, Spring Boot 3.4).

## When to use

- DB round-trips (JPA repositories, Liquibase schema validation)
- Kafka publish/consume (producer → consumer paths, idempotency)
- Redis interaction (cache lifecycle)
- Controller-to-service API integration (MockMvc + Testcontainers, not just Mockito)

## Base test

```java
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers(disabledWithoutDocker = true)
class OrderIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("pgvector/pg16:latest")
            .withDatabaseName("ecommerce")
            .withUsername("test")
            .withPassword("test");

    @Container
    static KafkaContainer kafka = new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.5.0"));

    @DynamicPropertySource
    static void props(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.kafka.bootstrap-servers", kafka::getBootstrapServers);
    }
}
```

## Rules
- One shared container set per test class (static `@Container`); reuse in a common base class for the service
- Prefer `@Transactional` when annotations don't break what you're testing; clean up otherwise
- Assert on responses, repository state, and consumed events via a `@TestConfiguration` test consumer or Mockito-injected listener
- Idempotency test: publish the same event twice → assert single side-effect + one idempotency row
- Config: Liquibase runs real changelogs (validates migration integrity); `spring.jpa.hibernate.ddl-auto=validate` in test profile

## Coverage checklist per service
- Repository CRUD + query methods
- Controller happy path + validation errors + 404/409 paths
- Kafka: produced event shape on each publishing action; consumed event side-effect + duplicate handling
- Redis cache hit/miss if caching configured

## Quality gates
- Tests must be hermetic (containers, no external hosts) — CI runs them via `./mvnw verify`
- No `@Disabled` without a tracked reason
- Reasonably fast: keep warm-up light, assert narrowly