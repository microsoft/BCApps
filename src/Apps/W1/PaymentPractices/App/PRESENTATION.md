# Payment Practices — Redesign Review

**Format:** ~10 min, 8 slides, short bullet notes per slide. Focus on GB. Goal: show OLD → NEW, explain upgrade, invite criticism.

---

## Slide 1: Context (30 sec)

- Payment Practices W1 app — needs to support UK and AU/NZ regulations
- UK: dispute tracking, construction contract retention, CSV export to gov portal
- AU: small business supplier filtering, invoice counts (separate workstream, not ours)
- Challenge: extend one app cleanly, no regression for existing W1/FR users

---

## Slide 2: Current Architecture (1.5 min)

- Three-layer pipeline: Raw Data (T686) → Aggregated Lines (T688) → Header Totals (T687)
- Two pluggable dimensions via enums:
  - **Header Type** → which ledger entries (Vendor / Customer / Both)
  - **Aggregation Type** → how lines are grouped (Period / Company Size)
- Each enum value → codeunit implementing an interface
- Payment periods: single flat table shared by all headers

```
┌──────────────────────────────────────────────────────────┐
│              CURRENT: Two Enum Dimensions                │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Header Type (enum)          Aggregation Type (enum)     │
│  ┌─────────┐                 ┌─────────────┐            │
│  │ Vendor  │──┐         ┌───▶│   Period    │            │
│  │Customer │  │         │    │ CompanySize │            │
│  │  Both   │  │         │    └─────────────┘            │
│  └─────────┘  │         │                               │
│               ▼         │                               │
│          ┌─────────────────────┐    ┌──────────┐        │
│   VLE/CLE│  Builders → Data   │───▶│  Lines   │        │
│    ──────▶    (T686)          │    │  (T688)  │        │
│          └─────────────────────┘    └────┬─────┘        │
│                                          │              │
│                                    ┌─────▼─────┐       │
│                                    │  Header   │       │
│                                    │  Totals   │       │
│                                    │  (T687)   │       │
│                                    └───────────┘       │
│                                                          │
│  Payment Periods: flat table (T685), one global set      │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Slide 3: What Changes — The Third Dimension (2 min)

- Adding **Reporting Scheme** as 3rd enum with 2 new interfaces
- Values: `Standard` (W1/FR), `Dispute & Retention` (GB), `Small Business` (AU/NZ)
- Standard handler = **does nothing extra** → zero regression for existing users
- Each handler controls: validation, data modification/filtering, header totals, line totals
- Extensible enum → partners can add country-specific schemes

```
┌───────────────────────────────────────────────────────────┐
│            NEW: Three Enum Dimensions                     │
├───────────────────────────────────────────────────────────┤
│                                                           │
│  Header Type    Aggregation Type    Reporting Scheme      │
│  ┌────────┐     ┌─────────────┐     ┌─────────────────┐  │
│  │Vendor  │     │  Period     │     │ Standard        │  │
│  │Customer│     │  Comp.Size  │     │ Dispute & Ret.  │  │
│  │Both    │     └─────────────┘     │ Small Business  │  │
│  └────────┘                         └─────────────────┘  │
│      │               │                     │              │
│      ▼               ▼                     ▼              │
│  DataGenerator   LinesAggregator    SchemeHandler         │
│  (interface)     (interface)        (2 interfaces)        │
│                                     ├ DefaultPeriods      │
│                                     └ SchemeHandler       │
│                                                           │
│  SchemeHandler hooks into Generate():                     │
│    ValidateHeader()          - block bad combos           │
│    UpdatePaymentPracData()   - modify or SKIP rows        │
│    CalculateHeaderTotals()   - scheme-specific sums       │
│    CalculateLineTotals()     - scheme-specific per-line   │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

---

## Slide 4: OLD vs NEW — Data Model (2 min)

| Aspect | OLD | NEW |
|--------|-----|-----|
| Payment Periods | Flat table, global | Template pattern: Header + Lines (named templates per scheme) |
| Reporting Scheme | None | Auto-detected from environment country/region, user can change |
| GB fields | None | ~40 qualitative fields in **new table T689** (Dispute & Ret. Data) |
| GB data fields | None | Dispute Status, SCF Payment Date on Payment Practice Data |
| AU data filtering | None | Small Business Supplier on Vendor → non-small vendors skipped |
| BaseApp new fields | None | `SCF Payment Date` on Vendor Ledger Entry, `Small Business Supplier` on Vendor |
| CSV exports | None | GB gov format (52 cols), AU format (TBD — not our scope) |

- Key design choice: GB qualitative fields live in **separate table T689** (not on Header) → own page, linked from card
- Why separate? ~40 fields, complex conditional visibility, "copy from previous period" feature, keeps main card clean

---

## Slide 5: Payment Period Templates — OLD vs NEW (1 min)

```
┌─────────────────────────────────────────────────────────────────────────┐
│          OLD                          │          NEW                    │
├───────────────────────────────────────┼─────────────────────────────────┤
│                                       │                                 │
│  ┌──────────────────────┐             │  ┌──────────────────────────┐   │
│  │ Payment Period (T685)│             │  │  Payment Period Header   │   │
│  │ (one flat table)     │             │  │  (T680)                  │   │
│  ├──────────────────────┤             │  ├──────────────────────────┤   │
│  │ P0_30  │  0  │  30   │             │  │ W1-DEFAULT │ Std   │ ✓  │   │
│  │ P31_60 │ 31  │  60   │             │  │ GB-DEFAULT │ D&R   │ ✓  │   │
│  │ P61_90 │ 61  │  90   │             │  │ AU-DEFAULT │ SmBus │ ✓  │   │
│  │ P91_120│ 91  │ 120   │             │  │ MIGRATED   │ (any) │    │   │
│  │ P121+  │121  │   0   │             │  │ MY-CUSTOM  │ (any) │    │   │
│  └──────────────────────┘             │  └────────────┬─────────────┘   │
│                                       │               │ 1:N             │
│  • One global set for all headers     │  ┌────────────▼─────────────┐   │
│  • All headers use same periods       │  │  Payment Period Line     │   │
│  • Country defaults hardcoded         │  │  (T681)                  │   │
│    in install codeunit                │  ├──────────────────────────┤   │
│                                       │  │  0  │  30 │ "0-30 days" │   │
│                                       │  │ 31  │  60 │ "31-60 days"│   │
│                                       │  │ 61  │ 120 │ "61-120 d." │   │
│                                       │  │121  │   0 │ "121+ days" │   │
│                                       │  └──────────────────────────┘   │
│                                       │                                 │
│                                       │  • Named templates per scheme   │
│                                       │  • Each header picks its own    │
│                                       │  • Users can create custom ones │
│                                       │  • One default per scheme       │
│                                       │  • Install seeds from env       │
│                                       │                                 │
└───────────────────────────────────────┴─────────────────────────────────┘
```

---

## Slide 6: GB — Dispute & Retention Details (1.5 min)

- **New table T689** holds all GB qualitative fields:
  - Payment policies (5 booleans)
  - Qualifying contracts (3 booleans)
  - Payment terms (8 fields incl. narratives)
  - Construction contract retention (~18 fields with conditional gates)
  - Dispute resolution (narrative)
- **New page P693** (Card) — organized in FastTab groups, single-column layout
- Linked from Payment Practice Card via drilldown (not embedded — too many fields)
- **"Copy from Previous Period"** — copies standing-policy fields, clears period-specific ones (saves time for recurring reports)
- **CSV export** — 52 columns matching UK gov portal download format
- **SCF Payment Date** — dual-source: auto-copied from Vendor Ledger Entry during generation, user can override manually, recalculates payment days when set

---

## Slide 7: Upgrade & Migration (1.5 min)

```
Upgrade Flow:
┌──────────────────────────────────────────────────────┐
│  1. Read old Payment Period rows (T685)              │
│  2. Get default periods for detected scheme          │
│  3. Compare:                                         │
│     ┌─────────────────┐    ┌─────────────────────┐  │
│     │ Rows MATCH       │    │ Rows DIFFER          │  │
│     │ defaults?        │    │ (user customized)    │  │
│     ├─────────────────┤    ├─────────────────────┤  │
│     │ Create 1 template│    │ Create 2 templates:  │  │
│     │ (e.g. GB-DEFAULT)│    │ • MIGRATED (old data)│  │
│     │ Default = true   │    │ • GB-DEFAULT (new)   │  │
│     │                  │    │ Default = true on new │  │
│     └────────┬────────┘    └──────────┬──────────┘  │
│              │                        │              │
│  4. Backfill ALL existing headers:                   │
│     • Reporting Scheme ← auto-detected from env      │
│     • Payment Period Code ← MIGRATED if exists,     │
│       else default template                          │
│  5. Old table T685 → deprecated                      │
└──────────────────────────────────────────────────────┘
```

- Key: existing headers get **MIGRATED** template if periods were customized → preserves their data
- New headers get the scheme default → correct periods for the country
- No data loss, no breaking changes for existing users

---

## Slide 8: Discussion (remaining time)

1. Is the 3-interface pattern overengineered? Could SchemeHandler + DefaultPeriods be merged?
2. GB detail table (T689) — right call to separate from header, or should we keep all on header?
3. Upgrade logic with MIGRATED vs default — are there edge cases we missed?
4. SCF Payment Date dual-source (VLE field + manual override) — acceptable complexity?
5. Are we missing any fundamental problems?
6. CSV export — should we use Report objects or Codeunits for file generation?
