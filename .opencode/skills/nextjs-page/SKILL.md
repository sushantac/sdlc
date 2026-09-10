---
name: nextjs-page
description: Create a Next.js 14 App Router page with React/TypeScript components using Tailwind + shadcn/ui. Use when building frontend pages or components for the e-commerce storefront.
---

# Next.js Page

Create or extend a Next.js 14 page in `src/app` (App Router, TypeScript, Tailwind, shadcn/ui).

## Conventions

- Route segments under `src/app/{route}/page.tsx`
- Layouts under `src/app/{segment}/layout.tsx` where shared UI exists
- Path alias `@/*` → `src/*`; imports via alias, never deep relative
- Server Component by default; add `"use client"` only where hooks/events are needed
- Data fetching: server components call API via `src/lib/api.ts`; client components use a typed hook (`useQuery`-style wrapper) also via `src/lib/api.ts`
- All API interactions go through the central client (JWT + refresh handled there), never `fetch` inline

## Page structure for a typical page

```tsx
// page.tsx (server) — initial data
export default async function ProductPage({ searchParams }) {
  const data = await api.getProducts(searchParams);
  return <ProductList initialData={data} />;
}

// product-list.tsx ("use client") — interactivity
"use client";
export function ProductList({ initialData }) { ... }
```

## Component rules

- Only shadcn/ui components (Button, Card, Dialog, Input, Select, Badge, Table, Toast, Tabs, Sheet, Skeleton, Avatar, Dropdown, Pagination, Breadcrumb, Carousel, Separator, Slider)
- Style with Tailwind utility classes using design tokens from `tailwind.config` (SDLC plan section 7.1)
- Every interactive element: keyboard focus, visible focus ring, aria-label
- Loading states with `<Skeleton>`; empty states; error states with retry
- Forms: controlled inputs, client validation mirroring backend validation rules, errors linked via `aria-describedby`

## Testing

- Vitest + React Testing Library for components/hooks only
- Update `src/lib/api.ts` mock when adding endpoints
- Full flows covered by Playwright (see playwright-e2e skill)

## Quality gates
- `npm run lint` clean, `npm test` green
- No `any`; `import type` for type-only imports
- Match wireframes/specs from planning/SDLC-PLAN-v2.0.md section 7