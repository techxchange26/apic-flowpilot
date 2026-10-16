# Products, Plans, and Quotas Reference

Products, Plans, and Quotas form the subscription tier of IBM API Connect. A **Product** bundles one or more APIs and exposes them to consumers via one or more **Plans**. Each Plan controls access with **Quotas** (named rate-limit buckets).

> **Always retrieve live schemas at runtime** before generating any asset:
> ```bash
> apic schema get Product --gateway <type>
> apic schema get Plan    --gateway <type>
> apic schema get Quota   --gateway <type>
> ```
> The snippets in this file are for conceptual guidance only — do not use them as templates.

> **Note:** `RateLimit` / `RateLimitDef` are standalone API policy assets (applied inside a PolicySequence). They are unrelated to Products, Plans, and Quotas — do not conflate them.

---

## Relationship Model

```
Product
├── spec.apis[]     → [$ref → API assets]    (1 or more)
└── spec.plans[]    → [$ref → Plan assets]   (1 or more)

Plan
└── spec.qos.withQuota
    ├── unlimited: {}                          (open access — no rate limiting)
    └── <label>: [$ref → Quota assets]        (1 or more named quota buckets)

Quota
└── spec: maxRequest + interval               (shared core, both gateways)
    └── spec.extensions.<gateway>             (gateway-specific behaviour)
```

A Product, Plan, or Quota never embeds another asset's content inline — always reference via `$ref: <namespace>:<name>:<version>`.

---

## Asset Summaries

### Product

- **Gateway schema:** identical for DataPower Nano Gateway and webMethods API Gateway at the top level
- **`spec.apis[]`** — array of `$ref` pointing to API assets bundled in this product
- **`spec.plans[]`** — array of `$ref` pointing to Plan assets included in this product
- **`spec.extensions.portal-config`** — optional portal visibility (`public` / `authenticated` / `custom`)
- **`spec.extensions.dp-nano-gateway`** — DataPower Nano Gateway-only config: `replicas`, `resources`, `autoScaling`, `logLevel`, `quotaService` (quota cache tuning), `env`, `sqlInjectionFilters`, `tlsServerCertificateSecretName`
- Omit `dp-nano-gateway` for webMethods API Gateway Products; there is no equivalent block on Product

**Snippet — minimal product:**
```yaml
spec:
  apis:
    - $ref: <namespace>:<api-name>:<version>
  plans:
    - $ref: <namespace>:<plan-name>:<version>
```

---

### Plan

- **`spec.qos.withQuota`** is required on every Plan (use `unlimited: {}` or quota refs)
- The label key inside `withQuota` (e.g., `default`, `burst`) is user-defined and used for logging/identification only — it does not need to match the Quota name
- Plans can also carry per-API / per-operation quota overrides inside the gateway extension

**`withQuota` — two forms:**
```yaml
# Unlimited (no rate limiting)
spec:
  qos:
    withQuota:
      unlimited: {}

# Named quota refs (one or more buckets)
spec:
  qos:
    withQuota:
      default:
        - $ref: <namespace>:<quota-name>:<version>
```

**Gateway extension differences:**

| Concern | DataPower Nano Gateway (`dp-nano-gateway`) | webMethods API Gateway (`webm-gateway`) |
|---|---|---|
| Rate limiting | Via Quota `$ref` in `withQuota` | Inline `withRateLimit[]` entries in `webm-gateway` extension |
| Approval gate | `isApprovalRequired: true/false` | Same field, same extension |
| Per-operation quota | `apis[].operations[].withQuota` → `$ref` or `unlimited` | Same structure under `dp-gateway` extension |
| Assembly count limit | `withAssemblyCountLimit` (object of `$ref` arrays) | Not applicable |
| Pricing | N/A | `pricing: {value, currency}` |

---

### Quota

- **Shared core fields:** `spec.maxRequest` (integer) and `spec.interval` (string, e.g. `"1h"`, `"1m"`, `"1s"`)
- Schema is the same for both gateways; behaviour differences live in `spec.extensions`

**Gateway extension differences:**

| Behaviour | DataPower Nano Gateway (`dp-nano-gateway`) | webMethods API Gateway (`webm-gateway`) |
|---|---|---|
| On limit reached | `exceedAction`: `continue` / `return429` / `return500` | `onLimitReach`: `block` / `allow` |
| Dynamic weight | `weightExpr` — expression string (default `'1'`) | N/A |
| Dynamic key | `dynamicValue` — per-consumer bucketing expression | N/A |
| Interval offset | `intervalOffset` (milliseconds) | N/A |
| Alerting | N/A (use a Telemetry policy instead) | `alertMessage`, `alertFrequency` (`once`/`always`), `notification` block |

---

## File Layout

```
<project>/
├── quotas/
│   └── <quota-name>.yaml
├── plans/
│   └── <plan-name>.yaml
└── products/
    └── <product-name>.yaml
```

---

## Creation Workflow

Generate in dependency order: **Quotas → Plans → Product**

1. Retrieve all three schemas for the target gateway (see top of file)
2. Ask the user in a single consolidated prompt:
   - Product name/version and which API(s) to bundle
   - Plan name(s) — unlimited or quota-controlled?
   - For each quota: `maxRequest`, `interval`, and exceed behaviour (`exceedAction` for DataPower Nano Gateway / `onLimitReach` for webMethods API Gateway)
3. Show a confirmation summary, then generate in order: Quotas → Plans → Product
4. Save to `<project>/quotas/`, `<project>/plans/`, `<project>/products/`
