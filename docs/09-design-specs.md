# 09 — UX/UI Design Specifications

> Source of truth for all visual tokens, wireframes, components, responsive
> behavior, and accessibility requirements. Derived directly from SDLC-PLAN-v2.0
> sections 7.1–7.5.

---

## 1. Design Tokens

> Values below are copied verbatim from the plan's JSON block (section 7.1).

### 1.1 Colors

| Token | Value |
|-------|-------|
| **primary.50** | `#eff6ff` |
| **primary.500** | `#3b82f6` |
| **primary.600** | `#2563eb` |
| **primary.700** | `#1d4ed8` |
| **primary.900** | `#1e3a8a` |
| **neutral.50** | `#fafafa` |
| **neutral.100** | `#f4f4f5` |
| **neutral.300** | `#d4d4d8` |
| **neutral.500** | `#71717a` |
| **neutral.700** | `#3f3f46` |
| **neutral.900** | `#18181b` |
| **success** | `#22c55e` |
| **warning** | `#f59e0b` |
| **error** | `#ef4444` |
| **info** | `#3b82f6` |

### 1.2 Typography

| Token | Value |
|-------|-------|
| **fontFamily.sans** | `Inter, system-ui, sans-serif` |
| **fontFamily.mono** | `JetBrains Mono, monospace` |
| **fontSize.xs** | `0.75rem` |
| **fontSize.sm** | `0.875rem` |
| **fontSize.base** | `1rem` |
| **fontSize.lg** | `1.125rem` |
| **fontSize.xl** | `1.25rem` |
| **fontSize.2xl** | `1.5rem` |
| **fontSize.3xl** | `1.875rem` |
| **fontSize.4xl** | `2.25rem` |

### 1.3 Spacing

| Token | Value |
|-------|-------|
| **xs** | `0.25rem` |
| **sm** | `0.5rem` |
| **md** | `1rem` |
| **lg** | `1.5rem` |
| **xl** | `2rem` |
| **2xl** | `3rem` |
| **3xl** | `4rem` |

### 1.4 Border Radius

| Token | Value |
|-------|-------|
| **sm** | `0.25rem` |
| **md** | `0.375rem` |
| **lg** | `0.5rem` |
| **xl** | `0.75rem` |
| **2xl** | `1rem` |
| **full** | `9999px` |

### 1.5 Breakpoints

| Token | Value |
|-------|-------|
| **mobile** | `375px` |
| **tablet** | `768px` |
| **desktop** | `1280px` |
| **wide** | `1536px` |

---

## 2. Wireframes (14 Screens)

All wireframes are annotated ASCII layout sketches. Notes reference design tokens
and shadcn/ui components by name.

---

### Screen 1 — Home Page

```
┌──────────────────────────────────────────────────────────────────────┐
│ [SKIP TO CONTENT]                       [logo]     nav links  [cart] │
│  Skip-to-content link (aria-hidden until focused)                    │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                     HERO SECTION                               │  │
│  │  Background: neutral.50                                        │  │
│  │  ┌──────────────────────────────────────────────────────────┐  │  │
│  │  │  Headline: fontSize.4xl, neutral.900, font-weight bold   │  │  │
│  │  │  Subtext:   fontSize.lg, neutral.500                     │  │  │
│  │  │  CTA Button: primary.500 bg, white text, radius.lg       │  │  │
│  │  │             hover:primary.600                             │  │  │
│  │  └──────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  FEATURED CATEGORIES (3-col grid, gap: spacing.md)            │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐          │  │
│  │  │  [img]       │ │  [img]       │ │  [img]       │          │  │
│  │  │  Category    │ │  Category    │ │  Category    │          │  │
│  │  │  Card        │ │  Card        │ │  Card        │          │  │
│  │  └──────────────┘ └──────────────┘ └──────────────┘          │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  FEATURED PRODUCTS (4-col grid, gap: spacing.md)              │  │
│  │  Each: Card component — img, name (fontSize.base),            │  │
│  │        price (primary.600, font-semibold),                     │  │
│  │        "Add to Cart" Button (variant: outline)                 │  │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ │  │
│  │  │   [img]    │ │   [img]    │ │   [img]    │ │   [img]    │ │  │
│  │  │   Product  │ │   Product  │ │   Product  │ │   Product  │ │  │
│  │  │   $XX.XX   │ │   $XX.XX   │ │   $XX.XX   │ │   $XX.XX   │ │  │
│  │  │ [Add Cart] │ │ [Add Cart] │ │ [Add Cart] │ [Add Cart]  │ │  │
│  │  └────────────┘ └────────────┘ └────────────┘ └────────────┘ │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  FOOTER: neutral.100 bg, neutral.500 text, spacing.lg padding │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - <nav> element wraps header navigation.
  - <main> wraps hero + product sections.
  - <footer> for footer.
  - All images require alt text (WCAG).
  - Focus order: logo → nav links → CTA → product cards → footer.
```

---

### Screen 2 — Product Listing

```
┌──────────────────────────────────────────────────────────────────────┐
│ [header nav — same as home]                                          │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Breadcrumb: Home > Products > {Category}  (Breadcrumb comp)  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────┬───────────────────────────────────────────────────────┐│
│  │ SIDEBAR  │  RESULTS AREA                                        ││
│  │ (desktop)│                                                       ││
│  │          │  Search: Input + Button (spacing.sm below)            ││
│  │ Filter:  │  Sort: Select dropdown (Relevance, Price ↑↓, Name)   ││
│  │ Categories│                                                      ││
│  │ - Cat 1  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   ││
│  │ - Cat 2  │  │  Card   │ │  Card   │ │  Card   │ │  Card   │   ││
│  │ - Cat 3  │  │  [img]  │ │  [img]  │ │  [img]  │ │  [img]  │   ││
│  │          │  │  name   │ │  name   │ │  name   │ │  name   │   ││
│  │ Price:   │  │  $XX.XX │ │  $XX.XX │ │  $XX.XX │ │  $XX.XX │   ││
│  │ [────●──]│  │ [Add]   │ │ [Add]   │ │ [Add]   │ │ [Add]   │   ││
│  │ Slider   │  └─────────┘ └─────────┘ └─────────┘ └─────────┘   ││
│  │          │                                                       ││
│  │ Stock:   │  ┌──────────────────────────────────────────────────┐││
│  │ Checkbox │  │  Pagination: < 1  2  3  ... 10 >  (Pagination)  │││
│  └──────────┴──────────────────────────────────────────────────────┘││
│                                                                      │
│  Mobile (<768px): Sidebar collapses to Sheet (slide-over filter).   │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - <aside> for sidebar filters, aria-label="Product filters".
  - Price range: Slider component with two thumbs.
  - Sidebar filter checkboxes use aria-label per category.
  - Grid: 1 col (mobile), 2 col (tablet), 3 col (desktop), 4 col (wide).
  - Skeleton loader shown during fetch (Skeleton component).
```

---

### Screen 3 — Product Detail

```
┌──────────────────────────────────────────────────────────────────────┐
│ [header nav]                                                        │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  Breadcrumb: Home > Products > {Category} > {Product Name}          │
│                                                                      │
│  ┌──────────────────────────────────┬─────────────────────────────┐  │
│  │                                  │                             │  │
│  │  IMAGE CAROUSEL (Carousel)       │  Product Name               │  │
│  │  ┌──────────────────────────┐    │  fontSize.2xl, neutral.900  │  │
│  │  │                          │    │                             │  │
│  │  │     [product image]      │    │  Price: $XX.XX              │  │
│  │  │     400x400              │    │  fontSize.xl, primary.600   │  │
│  │  │                          │    │                             │  │
│  │  └──────────────────────────┘    │  Stock: In Stock (success) │  │
│  │  [thumb] [thumb] [thumb] [thumb] │  or Out of Stock (error)    │  │
│  │                                  │                             │  │
│  │                                  │  Qty: [- 1 +] Input         │  │
│  │                                  │                             │  │
│  │                                  │  [Add to Cart] Button       │  │
│  │                                  │  full-width, primary.500    │  │
│  └──────────────────────────────────┴─────────────────────────────┘  │
│                                                                      │
│  Separator (spacing.lg)                                              │
│                                                                      │
│  Tabs: [Description] [Specifications] [Reviews]                     │
│  (Tabs component — neutral.50 active indicator)                     │
│                                                                      │
│  <aside> Related Products (horizontal scroll, 4 cards)              │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - Carousel arrows: Button (variant: ghost), aria-label="Next image".
  - Quantity input: type="number", min=1, max=stock_quantity.
  - Alt text on carousel images: "{product name} - image {n}".
  - Price formatted with Intl.NumberFormat.
```

---

### Screen 4 — Shopping Cart

```
┌──────────────────────────────────────────────────────────────────────┐
│ [header nav]                                                        │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  <h1> Shopping Cart (fontSize.3xl)                                   │
│                                                                      │
│  ┌──────────────────────────────────┬─────────────────────────────┐  │
│  │  CART ITEMS                      │  ORDER SUMMARY              │  │
│  │                                  │                             │  │
│  │  ┌─────────────────────────────┐ │  Subtotal:  $XXX.XX        │  │
│  │  │ [img] Product A   [- 2 +]  │ │  Tax:       $XX.XX         │  │
│  │  │             $49.99  [×]     │ │  Shipping:  $X.XX          │  │
│  │  ├─────────────────────────────┤ │  ──────────────────         │  │
│  │  │ [img] Product B   [- 1 +]  │ │  Total:     $XXX.XX        │  │
│  │  │             $29.99  [×]     │ │                             │  │
│  │  └─────────────────────────────┘ │  [Proceed to Checkout]      │  │
│  │                                  │  Button primary.500         │  │
│  │  [Continue Shopping] link        │  full-width                 │  │
│  │  (neutral.500, underline)        │                             │  │
│  └──────────────────────────────────┴─────────────────────────────┘  │
│                                                                      │
│  Empty state: illustration + "Your cart is empty" + CTA link        │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - Remove item (×): Dialog confirmation for destructive action.
  - Mobile: order summary stacks below items (Sheet on mobile toggle).
  - Each item row: aria-label="Remove {product name} from cart".
  - Loading skeleton on initial fetch.
```

---

### Screen 5 — Checkout: Address

```
┌──────────────────────────────────────────────────────────────────────┐
│ [header nav]                                                        │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  Checkout Progress (Tabs — 4 steps, step 1 active):                 │
│  [1: Address ●─────── 2: Payment ─────── 3: Review ─────── 4: Done] │
│                                                                      │
│  ┌──────────────────────────────────┬─────────────────────────────┐  │
│  │  SHIPPING ADDRESS FORM           │  ORDER SUMMARY (sticky)    │  │
│  │                                  │                             │  │
│  │  Full Name    [______________]   │  Item A × 2    $99.98      │  │
│  │  Street       [______________]   │  Item B × 1    $29.99      │  │
│  │  City         [______________]   │  ─────────────────────      │  │
│  │  State        [______________]   │  Subtotal:      $129.97    │  │
│  │  Postal Code  [______________]   │  Tax:           $10.40     │  │
│  │  Country      [Select ▼]        │  Total:         $140.37    │  │
│  │                                  │                             │  │
│  │  ☐ Billing same as shipping     │                             │  │
│  │                                  │                             │  │
│  │  [Continue to Payment]           │                             │  │
│  │  Button primary.500              │                             │  │
│  └──────────────────────────────────┴─────────────────────────────┘  │
│                                                                      │
│  Errors: red text below input, aria-describedby linked              │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - Each input: aria-label, aria-describedby on error message.
  - Country: Select component with search.
  - Form validation on submit; inline errors after first attempt.
  - "Continue" disabled until all required fields valid.
```

---

### Screen 6 — Checkout: Payment

```
┌──────────────────────────────────────────────────────────────────────┐
│ [header nav]                                                        │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  Checkout Progress (Tabs — step 2 active):                          │
│  [1: Address ✓] [2: Payment ●─────── 3: Review ─────── 4: Done]    │
│                                                                      │
│  ┌──────────────────────────────────┬─────────────────────────────┐  │
│  │  PAYMENT METHOD (Simulated)      │  ORDER SUMMARY (sticky)    │  │
│  │                                  │                             │  │
│  │  ○ Credit Card  ○ PayPal         │  [same as step 1]          │  │
│  │                                  │                             │  │
│  │  Card Number  [______________]   │                             │  │
│  │  Expiry       [MM/YY]           │                             │  │
│  │  CVV          [___]             │                             │  │
│  │  Name on Card [______________]   │                             │  │
│  │                                  │                             │  │
│  │  🔒 Your payment is secure       │                             │  │
│  │                                  │                             │  │
│  │  [Continue to Review]            │                             │  │
│  │  Button primary.500              │                             │  │
│  └──────────────────────────────────┴─────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - Simulated: no real payment gateway integration.
  - Card inputs: Input with type="tel" for numeric fields.
  - Lock icon + "secure" text for trust signal.
  - CVV: maxLength=4, inputMode="numeric".
```

---

### Screen 7 — Checkout: Review

```
┌──────────────────────────────────────────────────────────────────────┐
│ [header nav]                                                        │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  Checkout Progress (Tabs — step 3 active):                          │
│  [1: Address ✓] [2: Payment ✓] [3: Review ●─────── 4: Done]       │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  REVIEW ORDER                                                 │  │
│  │                                                                │  │
│  │  Shipping Address          [Edit link → step 1]               │  │
│  │  ┌──────────────────────────────────────────────────────┐     │  │
│  │  │  John Doe                                             │     │  │
│  │  │  123 Main St, Apt 4B                                  │     │  │
│  │  │  San Francisco, CA 94102                               │     │  │
│  │  │  United States                                        │     │  │
│  │  └──────────────────────────────────────────────────────┘     │  │
│  │                                                                │  │
│  │  Payment Method           [Edit link → step 2]                │  │
│  │  ┌──────────────────────────────────────────────────────┐     │  │
│  │  │  Credit Card ending in ****4242                       │     │  │
│  │  └──────────────────────────────────────────────────────┘     │  │
│  │                                                                │  │
│  │  Items                                                          │  │
│  │  ┌──────────────────────────────────────────────────────┐     │  │
│  │  │  Product A × 2          $99.98                       │     │  │
│  │  │  Product B × 1          $29.99                       │     │  │
│  │  │  ─────────────────────────────────────                │     │  │
│  │  │  Subtotal:              $129.97                      │     │  │
│  │  │  Tax:                   $10.40                       │     │  │
│  │  │  Total:                 $140.37                      │     │  │
│  │  └──────────────────────────────────────────────────────┘     │  │
│  │                                                                │  │
│  │  ☐ I agree to the Terms & Conditions                          │  │
│  │                                                                │  │
│  │  [Place Order] Button primary.500, full-width                 │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - "Place Order" disabled until checkbox checked.
  - Loading spinner (Skeleton/Button loading state) on submit.
  - "Edit" links are anchor buttons jumping back to relevant steps.
  - Dialog confirmation: "Are you sure you want to place this order?"
```

---

### Screen 8 — Checkout: Confirmation

```
┌──────────────────────────────────────────────────────────────────────┐
│ [header nav]                                                        │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                               │  │
│  │                      ✓  (success icon, success color)         │  │
│  │                                                               │  │
│  │           Order Confirmed! (fontSize.3xl, neutral.900)        │  │
│  │                                                               │  │
│  │   Order Number: #ORD-2026-001234                              │  │
│  │   (fontSize.lg, font-mono, primary.600)                       │  │
│  │                                                               │  │
│  │   We've sent a confirmation email to john@example.com         │  │
│  │   (neutral.500, fontSize.sm)                                  │  │
│  │                                                               │  │
│  │   ┌──────────────────────────────────────────────────────┐    │  │
│  │   │  Order Summary                                       │    │  │
│  │   │  Items, subtotal, tax, total                         │    │  │
│  │   └──────────────────────────────────────────────────────┘    │  │
│  │                                                               │  │
│  │   [View Order Details] Button primary.500                    │  │
│  │   [Continue Shopping]  Button variant:outline                │  │
│  │                                                               │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - Success checkmark: success color (#22c55e) with aria-hidden="true"
    (screen reader announces "Order confirmed").
  - Order number: monospace, copy-to-clipboard Button (ghost variant).
```

---

### Screen 9 — Login

```
┌──────────────────────────────────────────────────────────────────────┐
│ [header nav — simplified: logo only]                                │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                               │  │
│  │              Welcome Back (fontSize.2xl, neutral.900)         │  │
│  │              Sign in to your account (neutral.500)            │  │
│  │                                                               │  │
│  │  ┌──────────────────────────────────────┐                     │  │
│  │  │  Email                                │                     │  │
│  │  │  [________________________________]   │                     │  │
│  │  │                                       │                     │  │
│  │  │  Password                             │                     │  │
│  │  │  [________________] [👁 show]          │                     │  │
│  │  │                                       │                     │  │
│  │  │  [Sign In] Button primary.500         │                     │  │
│  │  │  full-width                           │                     │  │
│  │  │                                       │                     │  │
│  │  │  ─────── or ───────                   │                     │  │
│  │  │                                       │                     │  │
│  │  │  Don't have an account? Register →    │                     │  │
│  │  │  (primary.500 link)                   │                     │  │
│  │  └──────────────────────────────────────┘                     │  │
│  │                                                               │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - Form method="post", action="/api/v1/auth/login".
  - Password toggle: Button with aria-label="Toggle password visibility".
  - Error toast (Toast component) on failed login.
  - Redirect to / after successful login.
  - Rate limiting: max 10 attempts per minute (backend enforced).
```

---

### Screen 10 — Register

```
┌──────────────────────────────────────────────────────────────────────┐
│ [header nav — simplified: logo only]                                │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                               │  │
│  │              Create Account (fontSize.2xl, neutral.900)       │  │
│  │              Join us today (neutral.500)                      │  │
│  │                                                               │  │
│  │  ┌──────────────────────────────────────┐                     │  │
│  │  │  Full Name                            │                     │  │
│  │  │  [________________________________]   │                     │  │
│  │  │                                       │                     │  │
│  │  │  Email                                │                     │  │
│  │  │  [________________________________]   │                     │  │
│  │  │                                       │                     │  │
│  │  │  Phone Number (optional)              │                     │  │
│  │  │  [________________________________]   │                     │  │
│  │  │                                       │                     │  │
│  │  │  Password                             │                     │  │
│  │  │  [________________] [👁 show]          │                     │  │
│  │  │  • At least 8 characters              │                     │  │
│  │  │                                       │                     │  │
│  │  │  Confirm Password                     │                     │  │
│  │  │  [________________] [👁 show]          │                     │  │
│  │  │                                       │                     │  │
│  │  │  [Create Account] Button primary.500  │                     │  │
│  │  │  full-width                           │                     │  │
│  │  │                                       │                     │  │
│  │  │  Already have an account? Sign in →   │                     │  │
│  │  │  (primary.500 link)                   │                     │  │
│  │  └──────────────────────────────────────┘                     │  │
│  │                                                               │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - Password strength: visual indicator (neutral.300 → success color).
  - Confirm password: real-time match validation.
  - All fields required except phone_number.
  - Rate limiting: max 5 registrations per minute (backend enforced).
```

---

### Screen 11 — Order History

```
┌──────────────────────────────────────────────────────────────────────┐
│ [header nav]                                                        │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  Breadcrumb: Home > My Orders                                        │
│  <h1> My Orders (fontSize.3xl)                                       │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Table (shadcn/ui Table component)                            │  │
│  │                                                                │  │
│  │  ┌──────────┬──────────┬──────────┬──────────┬──────────┐    │  │
│  │  │ Order #  │ Date     │ Items    │ Total    │ Status   │    │  │
│  │  ├──────────┼──────────┼──────────┼──────────┼──────────┤    │  │
│  │  │#ORD-001  │ Sep 1,26 │ 3 items  │ $149.97  │[Delivered│    │  │
│  │  │          │          │          │          │ success] │    │  │
│  │  ├──────────┼──────────┼──────────┼──────────┼──────────┤    │  │
│  │  │#ORD-002  │ Sep 5,26 │ 1 item   │ $29.99   │[Shipped  │    │  │
│  │  │          │          │          │          │ info]    │    │  │
│  │  ├──────────┼──────────┼──────────┼──────────┼──────────┤    │  │
│  │  │#ORD-003  │ Sep 8,26 │ 2 items  │ $89.98   │[Placed   │    │  │
│  │  │          │          │          │          │ warning] │    │  │
│  │  └──────────┴──────────┴──────────┴──────────┴──────────┘    │  │
│  │                                                                │  │
│  │  Pagination: < 1  2 >                                        │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Empty state: "No orders yet" + "Start Shopping" CTA                │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - Status badges use Badge component with semantic color:
    PLACED → warning, CONFIRMED → info, SHIPPED → info,
    DELIVERED → success, CANCELLED → error.
  - Row click navigates to /orders/{id}.
  - Mobile: table becomes stacked cards layout.
  - Loading: Skeleton rows (3 rows).
```

---

### Screen 12 — Order Detail

```
┌──────────────────────────────────────────────────────────────────────┐
│ [header nav]                                                        │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  Breadcrumb: Home > My Orders > #ORD-2026-001234                    │
│  <h1> Order #ORD-2026-001234  [Badge: Delivered]                    │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  STATUS TIMELINE (vertical, left-aligned)                     │  │
│  │                                                                │  │
│  │  ●─── Order Placed         Sep 1, 2026 10:30 AM              │  │
│  │  │                                                               │  │
│  │  ●─── Order Confirmed      Sep 1, 2026 11:15 AM              │  │
│  │  │                                                               │  │
│  │  ●─── Shipped              Sep 2, 2026 09:00 AM              │  │
│  │  │    Carrier: FedEx #123456789                                │  │
│  │  │                                                               │  │
│  │  ●─── Delivered             Sep 5, 2026 02:45 PM              │  │
│  │                                                                │  │
│  │  (filled circles = completed, hollow = pending)                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────┬─────────────────────────────┐  │
│  │  ORDER ITEMS                     │  ORDER SUMMARY              │  │
│  │  ┌──────────────────────────┐    │                             │  │
│  │  │ [img] Product A × 2     │    │  Subtotal:  $129.97        │  │
│  │  │          $99.98          │    │  Tax:       $10.40         │  │
│  │  ├──────────────────────────┤    │  Total:     $140.37        │  │
│  │  │ [img] Product B × 1     │    │                             │  │
│  │  │          $29.99          │    │  Payment: Visa ****4242    │  │
│  │  └──────────────────────────┘    │                             │  │
│  └──────────────────────────────────┴─────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  SHIPPING ADDRESS                                             │  │
│  │  John Doe, 123 Main St, San Francisco CA 94102               │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - Timeline: custom component using Separator between steps.
  - Current status highlighted: primary.500 dot; past: success; future: neutral.300.
  - Carrier tracking: external link Button (variant: ghost).
  - Print order: Button (variant: outline) triggers window.print().
```

---

### Screen 13 — Admin Dashboard

```
┌──────────────────────────────────────────────────────────────────────┐
│ [admin header: logo, nav (Dashboard | Orders | Products), user]     │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  <h1> Dashboard (fontSize.3xl)                                       │
│                                                                      │
│  ┌───────────┬───────────┬───────────┬───────────┐                  │
│  │ STAT CARD │ STAT CARD │ STAT CARD │ STAT CARD │                  │
│  │           │           │           │           │                  │
│  │ Total     │ Total     │ Total     │ Total     │                  │
│  │ Orders    │ Revenue   │ Users     │ Products  │                  │
│  │           │           │           │           │                  │
│  │ 1,234     │ $45,678   │ 567       │ 89        │                  │
│  │ fontSize  │ fontSize  │ fontSize  │ fontSize  │                  │
│  │ .2xl      │ .2xl      │ .2xl      │ .2xl      │                  │
│  │ bold      │ bold      │ bold      │ bold      │                  │
│  │           │           │           │           │                  │
│  │ +12% ↑    │ +8% ↑     │ +5% ↑     │ +2 ↑      │                  │
│  └───────────┴───────────┴───────────┴───────────┘                  │
│  (Card component, each with primary.50 left border accent)          │
│                                                                      │
│  ┌──────────────────────────────┬──────────────────────────────┐    │
│  │  REVENUE CHART               │  ORDERS BY STATUS            │    │
│  │  (placeholder area)          │  (placeholder area)           │    │
│  │  400px × 250px               │  400px × 250px               │    │
│  │  neutral.100 bg              │  neutral.100 bg              │    │
│  │  label: "Revenue (7 days)"   │  label: "Orders by Status"   │    │
│  └──────────────────────────────┴──────────────────────────────┘    │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  RECENT ORDERS (Table)                                         │  │
│  │  ┌──────────┬──────────┬──────────┬──────────┬──────────┐    │  │
│  │  │ Order #  │ Customer │ Date     │ Total    │ Status   │    │  │
│  │  ├──────────┼──────────┼──────────┼──────────┼──────────┤    │  │
│  │  │ ...      │ ...      │ ...      │ ...      │ [Badge]  │    │  │
│  │  └──────────┴──────────┴──────────┴──────────┴──────────┘    │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - Stat cards: Card component with border-l-4 (primary.500).
  - Charts: placeholder divs; actual library TBD (Recharts recommended).
  - Table rows clickable → /admin/orders/{id}.
  - All stat values auto-refresh via polling or WebSocket.
  - Dashboard data fetched from GET /api/v1/admin/dashboard.
```

---

### Screen 14 — Admin Products/Orders Tables

```
┌──────────────────────────────────────────────────────────────────────┐
│ [admin header]                                                      │
├──────────────────────────────────────────────────────────────────────┤
│ <main>                                                               │
│  Tabs: [Orders] [Products] (Tab component)                          │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  TOOLBAR                                                      │  │
│  │  Search: [________________]  Filter: [Status ▼]  [Export]     │  │
│  │  (Input)                (Select)       (Button variant:outline)│  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  DATA TABLE (shadcn/ui Table)                                 │  │
│  │                                                                │  │
│  │  ┌────┬────────┬──────────┬────────┬────────┬────────┬─────┐ │  │
│  │  │ ID │ Order# │ Customer │ Date   │ Total  │ Status │ ... │ │  │
│  │  ├────┼────────┼──────────┼────────┼────────┼────────┼─────┤ │  │
│  │  │  1 │#ORD-01 │ John D.  │ Sep 1  │$140.37 │[Deliv] │ [✎] │ │  │
│  │  │  2 │#ORD-02 │ Jane S.  │ Sep 2  │ $89.99 │[Ship]  │ [✎] │ │  │
│  │  │  3 │#ORD-03 │ Bob W.   │ Sep 3  │$200.00 │[Placed]│ [✎] │ │  │
│  │  └────┴────────┴──────────┴────────┴────────┴────────┴─────┘ │  │
│  │                                                                │  │
│  │  Pagination: < 1  2  3  ... 10 >  showing 1-10 of 95         │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Status update: Dialog modal with Select to change status            │
└──────────────────────────────────────────────────────────────────────┘

Notes:
  - Products tab: similar table with Name, Price, Stock, Categories, Actions.
  - Actions column: DropdownMenu (Edit, View, Delete).
  - Delete: Dialog confirmation with danger styling.
  - Bulk actions: checkboxes, bulk delete Button.
  - Status change: Dialog → Select → Confirm → Toast notification.
  - Table sortable: click column header to sort (arrow indicator).
  - Mobile: horizontal scroll on table, or card-based layout.
  - Empty search state: "No results found" + clear filters link.
```

---

## 3. Component Library (shadcn/ui)

> 18 components from plan section 7.3 with usage context and state notes.

| # | Component | Usage | Key States |
|---|-----------|-------|------------|
| 1 | **Button** | All CTAs: add to cart, checkout, login, form submissions, pagination arrows | default, hover (primary.600), active, disabled (neutral.300 bg), loading (spinner), destructive (error bg) |
| 2 | **Card** | Product cards (grid), stat cards (dashboard), summary panels (checkout sidebar) | default, hover (shadow elevation), active/clicked |
| 3 | **Dialog** | Modals: order confirmation, delete confirmation, status update form, error details | closed, open (aria-modal="true"), focus-trapped |
| 4 | **Input** | All form fields: search, text, email, password, quantity, address fields | default, focus (primary.500 ring), error (error border + message), disabled, readonly |
| 5 | **Select** | Dropdowns: country, sort, filter status, category filter, payment method | default, open, selected, disabled |
| 6 | **Badge** | Order status indicators (PLACED/warning, CONFIRMED/info, SHIPPED/info, DELIVERED/success, CANCELLED/error), role badges | default, success, warning, error, info, outline variants |
| 7 | **Table** | Admin orders/products data, order history, cart items (mobile) | default, hover row, selected row, empty state, loading (skeleton) |
| 8 | **Toast** | Notifications: item added to cart, order placed, error messages, form saved | info, success, warning, error variants; auto-dismiss after 5s |
| 9 | **Tabs** | Checkout steps (Address→Payment→Review→Confirmation), product detail tabs, admin section tabs | active (primary.500 underline), inactive (neutral.500), disabled |
| 10 | **Sheet** | Cart slide-over on mobile, filter sidebar on mobile, admin detail side panel | open-left, open-right, open-top, closed; focus trapped when open |
| 11 | **Separator** | Between sections: cart items/summary, checkout sections, timeline steps, footer/content | horizontal (default), vertical (sidebar) |
| 12 | **Skeleton** | Loading states: product grid (4 cards), table rows (5 rows), stat cards, profile page | pulse animation, matches expected content shape |
| 13 | **Avatar** | User profile in header dropdown, admin "performed by" display, customer detail | fallback initials, image loaded, size (sm/md/lg) |
| 14 | **DropdownMenu** | User menu (profile, orders, logout), admin row actions (edit, delete, view) | closed, open, item hover, disabled item, separator |
| 15 | **Pagination** | Product listing pages, admin tables, order history | previous, page numbers (current highlighted primary.500), next, disabled states |
| 16 | **Breadcrumb** | Navigation trail: Home > Products > Category > Product, Home > My Orders > #ORD | last item plain text (current page), ancestors as links |
| 17 | **Carousel** | Product detail image gallery, hero banners (optional) | prev/next arrows (ghost buttons), dots indicator, swipe on touch |
| 18 | **Slider** | Price range filter (min/max), optional quantity selector | min/max thumbs, track fill (primary.500), disabled, step increments |

---

## 4. Responsive Behavior

> Per plan section 7.4. All breakpoints are min-width media queries.

### 4.1 Breakpoint Mapping

| Breakpoint | Min Width | Grid Columns | Layout Changes |
|------------|-----------|-------------|----------------|
| **Mobile** | `375px` | 1 | Single column; hamburger nav (Sheet); stacked cards; table → stacked cards; sidebar filters → Sheet slide-over; hero text fontSize.lg; stat cards 2×2 grid |
| **Tablet** | `768px` | 2 | 2-column product grid; collapsible sidebar; header nav inline (3 items max, overflow → dropdown); hero text fontSize.xl; stat cards 4×1 row |
| **Desktop** | `1280px` | 3–4 | 3–4 column product grid; full nav bar visible; sidebar filters always visible; detail page: 2-column (image + info); stat cards 4×1 row |
| **Wide** | `1536px` | 4 | Max-width container (1280px centered); 4-column grid; extra padding (spacing.2xl side margins) |

### 4.2 Component-Specific Responsive Rules

| Component | Mobile | Tablet+ |
|-----------|--------|---------|
| **Navigation** | Hamburger → Sheet with all links | Inline horizontal nav |
| **Product Grid** | 1 column, full-width cards | 2 (tablet), 3 (desktop), 4 (wide) |
| **Product Detail** | Stacked: carousel → info → tabs | Side-by-side: carousel left, info right |
| **Cart** | Stacked: items → summary | Side-by-side: items left, summary right (sticky) |
| **Checkout** | Stacked: form → summary | Side-by-side: form left, summary right (sticky) |
| **Order History Table** | Card-based layout (no table) | Table with all columns |
| **Admin Table** | Horizontal scroll wrapper | Full table with all columns |
| **Sidebar Filters** | Sheet (slide-over from left) | Persistent sidebar |
| **Stat Cards** | 2×2 grid | 4×1 row |
| **Charts** | Full-width stacked | 2-column side-by-side |

### 4.3 Touch Targets

- All interactive elements: minimum `44px × 44px` touch target (WCAG 2.5.5).
- Spacing between tappable items: minimum `8px` (spacing.sm).

---

## 5. Accessibility Requirements (WCAG 2.1 AA)

> Per plan section 7.5. Each requirement is stated as a testable criterion.

### 5.1 Color Contrast

| Criterion | Requirement | How to Test |
|-----------|-------------|-------------|
| Text contrast | Normal text (< fontSize.lg): contrast ratio ≥ `4.5:1` against background | axe-core rule `color-contrast`; manual check with WebAIM Contrast Checker |
| Large text contrast | Large text (≥ fontSize.lg and bold, or ≥ fontSize.2xl): contrast ratio ≥ `3:1` | Same tools |
| UI component contrast | Borders, icons, focus rings: contrast ratio ≥ `3:1` against adjacent colors | axe-core rule `color-contrast` |
| Status badge text | Badge text must meet 4.5:1 against its badge background color | Verify each Badge variant: warning bg `#f59e0b` needs dark text; error bg `#ef4444` needs white text; success bg `#22c55e` needs white text |
| Info color note | `info` token (`#3b82f6`) used only on white/light backgrounds; dark text on primary.500 backgrounds | Verify primary.500 buttons use white text (`#3b82f6` bg → `#ffffff` text = 4.63:1 ✓) |

### 5.2 Keyboard Navigation

| Criterion | Requirement | How to Test |
|-----------|-------------|-------------|
| Focusable elements | All interactive elements (buttons, links, inputs, selects, tabs) are focusable via `Tab`/`Shift+Tab` | Manual keyboard test; axe-core `keyboard` rule |
| Focus order | Focus follows visual/DOM order: top-to-bottom, left-to-right | Tab through every page; verify logical order |
| Focus visible | Every focused element shows a visible focus indicator: `outline: 2px solid primary.500; outline-offset: 2px` | Visual check; no `outline: none` without replacement |
| No keyboard traps | User can Tab into and out of every component (dialogs, sheets, dropdowns) | Tab into Dialog → Tab through all items → verify Escape closes and focus returns to trigger |
| Escape key | Dialog, Sheet, DropdownMenu close on `Escape` key press | Press Escape in each overlay component |
| Skip-to-content | First focusable element on every page is "Skip to main content" link; activates `#main-content` anchor | Tab once on page load; verify skip link appears; Enter jumps to `<main>` |

### 5.3 ARIA & Semantics

| Criterion | Requirement | How to Test |
|-----------|-------------|-------------|
| Landmark regions | Use `<nav>`, `<main>`, `<aside>`, `<header>`, `<footer>` semantic elements | axe-core `landmark-*` rules; inspect DOM |
| Page titles | Each page has a unique `<title>` element (e.g., "Products | E-Commerce") | Check browser tab text on each route |
| Heading hierarchy | Each page has exactly one `<h1>`, headings descend in order (h1→h2→h3), no skipped levels | axe-core `heading-order` rule |
| Form labels | Every `<input>`, `<select>`, `<textarea>` has an associated `<label>` (via `htmlFor`/`id` or `aria-label`) | axe-core `label` rule; inspect each form |
| Error association | Validation error messages are linked to their input via `aria-describedby` | Inspect error DOM: `<span id="email-error" role="alert">...</span>` and `<input aria-describedby="email-error">` |
| Live regions | Toast notifications use `aria-live="polite"` (info/success) or `aria-live="assertive"` (error) | Inspect Toast DOM for `aria-live` attribute |
| Image alt text | Every `<img>` has a non-empty `alt` attribute; decorative images use `alt=""` | axe-core `image-alt` rule |
| Button accessible names | Icon-only buttons (cart icon, hamburger, close) have `aria-label` | Inspect each icon button |
| Table headers | Data tables use `<th>` with `scope="col"` for column headers | Inspect admin and order history tables |
| Status timeline | Order detail timeline uses `role="list"` and `role="listitem"` with `aria-label` on each step | Inspect timeline DOM |

### 5.4 Reduced Motion

| Criterion | Requirement | How to Test |
|-----------|-------------|-------------|
| Respect prefers-reduced-motion | All animations (skeleton pulse, carousel transitions, toast slide-in) are disabled when `prefers-reduced-motion: reduce` is active | Enable reduced motion in OS settings; verify no animations play |

### 5.5 Screen Reader

| Criterion | Requirement | How to Test |
|-----------|-------------|-------------|
| Meaningful sequence | DOM order matches visual order (no CSS reordering that breaks reading flow) | Test with VoiceOver (macOS) or NVDA; verify content reads logically |
| Status updates | Adding item to cart triggers screen reader announcement (via `aria-live` region or `role="status"`) | Enable VoiceOver; add item to cart; verify announcement |
| Form error announcement | Submitting invalid form announces error count ("2 errors found") via `role="alert"` | Enable VoiceOver; submit empty form; verify announcement |

### 5.6 Automated Testing Baseline

| Tool | Scope | Gate Criteria |
|------|-------|---------------|
| **axe-core** (via Playwright) | All 14 pages | 0 violations, 0 serious issues |
| **Lighthouse accessibility** | All 14 pages | Score ≥ 90 |
| **Manual keyboard test** | Critical flows (login, browse, cart, checkout) | 0 traps, all elements reachable |

---

## Appendix A — Token-to-Tailwind Mapping

| Design Token | Tailwind Config Key | Value |
|-------------|-------------------|-------|
| `colors.primary.50` | `--color-primary-50` | `#eff6ff` |
| `colors.primary.500` | `--color-primary-500` | `#3b82f6` |
| `colors.primary.600` | `--color-primary-600` | `#2563eb` |
| `colors.primary.700` | `--color-primary-700` | `#1d4ed8` |
| `colors.primary.900` | `--color-primary-900` | `#1e3a8a` |
| `colors.neutral.50` | `--color-neutral-50` | `#fafafa` |
| `colors.neutral.100` | `--color-neutral-100` | `#f4f4f5` |
| `colors.neutral.300` | `--color-neutral-300` | `#d4d4d8` |
| `colors.neutral.500` | `--color-neutral-500` | `#71717a` |
| `colors.neutral.700` | `--color-neutral-700` | `#3f3f46` |
| `colors.neutral.900` | `--color-neutral-900` | `#18181b` |
| `colors.success` | `--color-success` | `#22c55e` |
| `colors.warning` | `--color-warning` | `#f59e0b` |
| `colors.error` | `--color-error` | `#ef4444` |
| `colors.info` | `--color-info` | `#3b82f6` |
| `borderRadius.sm` | `--radius-sm` | `0.25rem` |
| `borderRadius.md` | `--radius-md` | `0.375rem` |
| `borderRadius.lg` | `--radius-lg` | `0.5rem` |
| `borderRadius.xl` | `--radius-xl` | `0.75rem` |
| `borderRadius.2xl` | `--radius-2xl` | `1rem` |
| `borderRadius.full` | `--radius-full` | `9999px` |
