---
description: "What the Business Central application contains, mapped to the repo, and which tours suit which area. Input for choosing what to tour."
---

# The application, as a tourer needs it

Companion to [`exploratory-tours.instructions.md`](./exploratory-tours.instructions.md). That file
says *how* to tour; this one says *what is out there* and which tours suit it.

Source: the public documentation at
<https://learn.microsoft.com/dynamics365/business-central/>, in particular
[Business functionality](https://learn.microsoft.com/dynamics365/business-central/across-business-functionality).

## 0. How to use public docs — they are claims, not specification

The docs describe **intended** behaviour written for users. That makes them two things:

- **An oracle for Claims tours (§2) and tooltips (§6.1).** A documented promise is a testable
  assertion. *"Demand is not included beyond this date"* turned out to say nothing about existing
  supply being deleted beyond that date — a documentation disagreement worth filing alongside a
  finding.
- **A retirement mechanism for false findings (§5.2).** Negative sales quantities looked like
  missing validation until the returns documentation turned out to *prescribe* them.

What they are **not** is a statement of what the code does. Never file a finding because behaviour
differs from the docs without checking source and configuration first; and never assume a
documented feature is installed or populated in your container (§3 gates 3 and 4).

## 1. The areas

Docs area → repo folder under `src/Layers/W1/BaseApp/` (`.al` file counts, for a sense of mass).

| Area | Covers | Folder | Files |
| --- | --- | --- | --- |
| Finance | Payments, cash flow, deferrals, year-end close, VAT, intercompany | `Finance` | 1038 |
| Inventory | Items, costing, adjustments, item tracking, planning worksheets | `Inventory` | 958 |
| Service | Service orders, contracts, repair parts | `Service` | 637 |
| Sales | Quotes, orders, returns, customers, drop shipment | `Sales` | 591 |
| Manufacturing | Production orders, BOMs, routings, capacity | `Manufacturing` | 530 |
| Purchasing | Invoices, orders, returns, vendors | `Purchases` | 371 |
| Relationship Mgmt | Contacts, segments, opportunities | `CRM` | 370 |
| Warehouse | Receipts, shipments, put-away, picks, bins | `Warehouse` | 355 |
| Project Mgmt | Jobs, project budgets, resource scheduling | `Projects` | 338 |
| Integration | Data exchange, incoming documents, external sync | `Integration` | 332 |
| Bank | Reconciliation, payment files, deposits | `Bank` | 239 |
| Fixed Assets | Depreciation, maintenance, disposal | `FixedAssets` | 213 |
| Foundation | No. series, dimensions, reporting, shared primitives | `Foundation` | 210 |
| Human Resources | Employees, absence | `HumanResources` | 115 |
| Assembly | Kits, assembly orders | `Assembly` | 113 |
| Cost Accounting | Cost centres, allocations | `CostAccounting` | 82 |
| Pricing | Price lists, discounts | `Pricing` | 78 |
| Cash Flow | Forecasts | `CashFlow` | 49 |

Planning and Workflow are documented as areas but live inside others:
`Inventory/Planning`, `Manufacturing/…`, and workflow/approvals in `Foundation` + `Modules`.

Outside BaseApp, `src/Apps/W1/*` holds the newer bolt-on apps — Sustainability, ExpenseAgent,
EDocument, Shopify, Subscription Billing, Subcontracting, ExciseTaxes.

## 2. Where the defects actually live — the seams

The docs describe areas; the product is a set of **processes that cross them**. Every confirmed
finding these tours produced sat on a crossing, not inside a box.

| Seam | Why it is thin |
| --- | --- |
| Planning ↔ Manufacturing ↔ Inventory | Planning proposes, carry-out creates real orders, inventory reserves against them. Three owners, one flow. |
| Document ↔ Item Ledger (posting) | The point where a proposal becomes irreversible. Posting failures use a different error surface entirely (playwright §8). |
| Item tracking ↔ reservation ↔ posting | Serial/lot data crosses three representations; the durable one is not the obvious one (§5.6). |
| Sales / Purchases ↔ Inventory costing | Value entries are computed elsewhere from documents you posted here. |
| Warehouse ↔ Inventory | Bin-level truth vs item-level truth. |
| Any area ↔ Workflow / approvals | Cuts across everything and is rarely exercised together with the area it gates. |
| W1 ↔ localisations (`src/Layers/<CC>`) | Parallel implementations of one idea — the natural home of differential touring (§7). |

**Prefer a charter that crosses a seam over one that stays inside a folder.**

## 3. Demo-data reality (measured, not assumed)

CRONUS covers the classic Base Application and little else. Re-run the census (§3 gate 4) — these
were true on build 30.0.54812.0-W1:

- **Classic areas have data**: ~149 items, sales/purchase documents, 336 item ledger entries.
- **Newer apps have none.** Sustainability, ExpenseAgent, EDocument, Shopify, ExciseTaxes all
  installed, all healthy, **zero rows** in their master tables.
- **Item tracking ships configuration but no history**: 6 tracking codes, **0** ledger entries
  carrying a serial/lot, 0 tracking specifications. Inbound assignment creates its own data.
- **No tracking code enables package tracking at all** — absence of package behaviour can never be
  a finding here.
- **Planning is lopsided**: of 149 items only 36 carry a reordering policy, and all but one are
  *Fixed Reorder Qty.* Maximum Qty. and Lot-for-Lot have **no** demo data.
- `Requisition Line`, `Planning Component` start empty, so count-based oracles are safe there —
  but see §5.5, count oracles are weak anyway.

## 4. Choosing tours by area

| Area shape | Tours that fit |
| --- | --- |
| Arithmetic-heavy (Finance, Pricing, Costing, Planning quantities) | **Money**, Complexity, Intellectual |
| Document lifecycle (Sales, Purchases, Service, Warehouse) | **Cancelled Bus**, Obsessive-Compulsive, Saboteur |
| Setup-gated (Manufacturing, Warehouse, Tracking, Subscription Billing) | **Configuration**, Landmark, Back Alley |
| Parallel implementations (localisations, sales vs purchase vs transfer) | **Differential touring (§7)** |
| New app with no data (`src/Apps/W1/*`) | **First-run**, Feature, Empty-state (§3.1) |
| Cross-area flow | **Scenario**, User, Interoperability |

Two cautions learned the hard way:

- **Client-side abandonment does not interrupt server-side report runs.** Cancelled Bus is a weak
  fit for anything driven by a request page (planning, batch posting) — the run commits regardless.
- **High churn in codeunits means write integration tests, not run a tour** (§3).

## 5. Anchor tables

Names must be discovered, never constructed (playwright §9). These were verified in a container
this session and are safe starting points:

| Flow | Oracle |
| --- | --- |
| Planning proposal | `Requisition Line`, `Planning Component` |
| Reservation / order tracking | `Reservation Entry` |
| Posted inventory movement | `Item Ledger Entry` |
| Item tracking, post-posting | `Item Entry Relation` (**not** `Tracking Specification` — transient) |
| Production supply | `Production Order`, `Prod. Order Line`, `Prod. Order Component` |
| Purchase posting | `Purch. Rcpt. Header`, `Purch. Inv. Header` |
| Planning failures | `Planning Error Log` |

For anything else, discover it — and confirm it means what you think before it decides a verdict
(§5.6).
