---
name: liquibase-migration
description: Create a Liquibase changelog for a schema change in an e-commerce service. Use when adding/altering tables, columns, indexes, constraints, or seed data.
---

# Liquibase Migration

Add a database migration for a schema in the e-commerce platform. Liquibase is the ONLY schema authority — never JPA `ddl-auto`.

## Location & naming

```
src/main/resources/db/changelog/
├── db.changelog-master.xml
└── v1.0/
    ├── 01_create_users_table.xml
    ├── 02_create_refresh_tokens_table.xml
    └── ...
```

Master file includes versioned changelogs:

```xml
<databaseChangeLog xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                   http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd">
    <includeAll path="db/changelog/v1.0/"/>
</databaseChangeLog>
```

## ChangeSet rules

- Every changeSet has a unique `id` combining version + sequence (e.g. `1-001`)
- `author` = `sushant`
- **Never modify an already-shipped changeSet** — append a new one (rollback discipline)
- Provide `rollback` where practical (`dropTable`, `dropColumn`, etc.)

## Example

```xml
<databaseChangeLog ...>
    <changeSet id="1-001" author="sushant">
        <createTable tableName="users">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true" nullable="false"/>
            </column>
            <column name="email" type="VARCHAR(255)">
                <constraints nullable="false" unique="true"/>
            </column>
            <column name="password_hash" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="full_name" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="role" type="VARCHAR(50)" defaultValue="CUSTOMER"/>
            <column name="created_at" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP"/>
        </createTable>
    </changeSet>
</databaseChangeLog>
```

## Naming conventions
- Tables: snake_case, plural (`cart_items`); join tables `product_categories`
- Columns: snake_case (`stock_quantity`, `created_at`)
- Indexes: `idx_{table}_{columns}`; unique constraints as inline column constraint or `idx_unique_...`
- FKs: `fk_{child_table}_{parent_table}`

## YAML service mapping
- auth-service → `auth` schema, cart-service → `cart`, product-service → `product`, order-management-api → `orders`, admin-service → `admin`. The `default-schema` in application.yml must match.

## Quality gates
- Migration idempotent/safe to run twice
- Backward compatible on rollback (no data loss on down-revision)
- `./mvnw spring-boot:run` or integration test boots with the new schema before finalizing