---
name: spring-boot-service
description: Scaffold or extend a Spring Boot 3.4 microservice (Java 21, Maven). Use when creating a new service repo or adding controllers, entities, repositories, or config to an existing e-commerce backend service.
---

# Spring Boot Service

Scaffold a production-grade Spring Boot 3.4 service consistent with the e-commerce platform.

## Layout

```
{service}/
├── pom.xml
├── Dockerfile
├── .dockerignore
├── .github/workflows/ci.yml
└── src/
    ├── main/
    │   ├── java/com/ecommerce/{service}/
    │   │   ├── {Service}Application.java
    │   │   ├── config/          # Security, Kafka, Redis, WebClient, Actuator
    │   │   ├── controller/
    │   │   ├── service/
    │   │   ├── repository/
    │   │   ├── entity/          # or domain/ for aggregates
    │   │   ├── dto/             # records: request/response
    │   │   ├── event/           # Kafka producers/consumers + records
    │   │   ├── exception/       # ApiException + @RestControllerAdvice
    │   │   └── util/
    │   └── resources/
    │       ├── application.yml
    │       ├── application-local.yml
    │       └── db/changelog/db.changelog-master.xml
    └── test/
        └── java/com/ecommerce/{service}/...
```

## pom.xml essentials

- `spring-boot-starter-parent` version `3.4.x`
- `java.version` = `21`
- Starters: `web`, `data-jpa`, `validation`, `security`, `actuator`, `micrometer-tracing-bridge-brave`, `micrometer-registry-prometheus`
- `springdoc-openapi-starter-webmvc-ui` `2.7.0`
- `liquibase-core`
- `spring-boot-starter-test`, `testcontainers` (postgresql, kafka, junit-jupiter)
- `maven-checkstyle-plugin` + `maven-surefire-plugin` + `jacoco` + `spotbugs-maven-plugin`

## application.yml essentials

```yaml
spring:
  application.name: {service}
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${POSTGRES_DB:ecommerce}?currentSchema={schema}
    username: ${POSTGRES_USER:ecommerce}
    password: ${POSTGRES_PASSWORD:secret}
    hikari:
      maximum-pool-size: 20
  liquibase:
    default-schema: {schema}
  jpa.hibernate.ddl-auto: validate
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:kafka:9092}
    producer.key-serializer: org.apache.kafka.common.serialization.StringSerializer
    producer.value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
    consumer.key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
    consumer.value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
    consumer.properties.spring.json.trusted.packages: "*"
server:
  port: {port}
  shutdown: graceful
spring.lifecycle.timeout-per-shutdown-phase: 20s
management:
  endpoints.web.exposure.include: health,info,prometheus
  health.readinessstate.enabled: true
  health.livenessstate.enabled: true
```

## Security pattern

For JWT validation in resource services: `spring-boot-starter-oauth2-resource-server` with `jwt` auth and a `SecurityFilterChain`. For internal API-key endpoints, filter on the `X-Internal-API-Key` header against `INTERNAL_API_KEY` env (constant-time compare).

## Rules
- Never `ddl-auto: update` — schema comes from Liquibase only
- DTOs are Java records; request validation via Jakarta Bean Validation annotations
- Single `@RestControllerAdvice` mapping exceptions to `{timestamp,status,error,message,path}` JSON
- Graceful shutdown + health endpoints wired (see above)
- Verify with `./mvnw test`