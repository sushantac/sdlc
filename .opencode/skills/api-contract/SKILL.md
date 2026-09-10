---
name: api-contract
description: Author an OpenAPI 3.0 specification for an e-commerce service. Use when creating a new service spec, updating endpoints, or generating client types.
---

# API Contract

Author OpenAPI 3.0 YAML specs, one per service, under `sdlc/docs/07-api-specs/{service}.yaml`. These are the source of truth for endpoint contracts (mirror planning/SDLC-PLAN-v2.0.md section 3).

## Conventions

- `openapi: 3.0.3`
- `servers`: `/` (relative — services behind gateway all serve `/api/v1/...`)
- Version the API in the URL path (`/api/v1/...`); each spec covers one service's namespace
- Response envelope: successful resource data directly; errors as RFC 7807-style `{timestamp,status,error,message,path}`
- Auth: JWT via `Authorization: Bearer` header (SecurityScheme `http`, scheme `bearer`); inter-service calls use `X-Internal-API-Key` (SecurityScheme `apiKey`)
- Every endpoint documents: summary, description, params, request/response schemas with one example each, and the 4xx/5xx errors it can return

## Paging convention (collections)

```yaml
parameters:
  page: { name: page, in: query, schema: { type: integer, default: 0 } }
  size: { name: size, in: query, schema: { type: integer, default: 20, maximum: 100 } }
# responses:
#   PaginatedResponse<T>: { content, page, size, totalElements, totalPages, last }
```

## Schema style

- Component names PascalCase (`ProductResponse`, `CartItemDto`, `OrderStatus`)
- Enums for states (OrderStatus: `PLACED, CONFIRMED, SHIPPED, DELIVERED, CANCELLED`)
- Use `required`, `minimum`/`maximum`, `format: uuid`/`date-time` where applicable
- IDs: `format: int64` for DB longs; UUIDs `format: uuid`

## Per-service files (one spec, five services + gateway routes)
- `auth-service.yaml` — /auth, /profile
- `cart-service.yaml` — /cart
- `product-service.yaml` — /products, /categories
- `order-service.yaml` — /orders, /customers (order-management-api)
- `admin-service.yaml` — /admin/...

## Quality gates
- Validate with `npx @redocly/cli lint` or openapi validator of choice if available; otherwise manual review
- Spec matches implemented controllers exactly (recheck after code changes)
- Examples match documented data types