# E-Document MLLM Extraction V2 — Design Spec

**Date:** 2026-05-26  
**Status:** Draft  
**Replaces:** `EDocumentMLLMHandler.Codeunit.al` (V1)

---

## Problem

V1 performs a single-pass extraction: one AOAI call, one system prompt, one UBL JSON response. It has no mechanism to detect or correct errors it is confident about. Known failure modes observed in production:

- **Locale number formats** — Swedish `"2,34"` extracted as `234` (comma stripped by `AsDecimal()`)
- **Discount ambiguity** — invoice shows both gross price (`Pris`) and net price (`Pris efter rab.`); model uses net price AND applies a discount percentage, double-counting the discount
- **Silent wrong values** — extraction passes schema validation but produces semantically wrong output (wrong totals, wrong unit prices)

The root cause is that V1 sweeps the document left-to-right without understanding its structure, and has no self-correction capability.

---

## Solution: Plan-Act-Verify Agentic Loop

A single agentic AOAI call where the agent:

1. **Plans** — identifies document structure as chain-of-thought reasoning (regions, column roles, locale, flags) *before* extracting any values
2. **Acts** — extracts from the identified regions, guided by the structural understanding from the plan step
3. **Verifies** — calls deterministic AL-implemented tools to check its own output; self-corrects if tools report failures; repeats until all tools pass or the tool call budget is exhausted

The loop is entirely inside the model's reasoning turn. AL code sets up the tools and runs the agent; it does not orchestrate the plan/act/verify sequence.

---

## Architecture

### Single Agentic Call

```
PDF (base64)
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  AGENT REASONING (one AOAI call, tool-use loop)     │
│                                                      │
│  1. PLAN (chain-of-thought)                          │
│     "This is a Swedish invoice. Columns: Antal,      │
│      Pris, Rabatt, Rabatt, Pris efter rab., Belopp.  │
│      Decimal sep = comma. Two chained discount cols. │
│      Net price column present."                      │
│                                                      │
│  2. ACT (targeted extraction)                        │
│     Extract from identified regions using column     │
│     roles, not left-to-right text sweep.             │
│                                                      │
│  3. VERIFY (tool calls)                              │
│     verify_line_math()   verify_totals()             │
│     verify_vat()         verify_dates()              │
│     verify_required()    verify_ranges()             │
│                                                      │
│     On failure → agent reads error, re-extracts,    │
│     calls tools again. Loops until pass or budget.   │
└─────────────────────────────────────────────────────┘
    │                          │
    ▼                          ▼
Verified UBL JSON          Error (budget
→ BC Purchase Draft         exhausted)
```

**Model:** GPT-4.1 Mini (chosen for vision capability — the agent reads the PDF visually, not as extracted text)  
**Tool call budget:** 20 (sufficient for 6 verify calls × 3 correction rounds on a multi-line invoice)  
**Temperature:** 0

### On Budget Exhaustion

E-Document status set to `Error`. A log entry records which verify check was still failing on the last iteration. No draft is created. ADI is not used as a fallback for verify failures.

ADI fallback is retained only for AOAI call failures (network error, content filter, empty response) — the same signal V1 uses today.

---

## New AL Components

### `EDocMLLMHandlerV2.Codeunit.al`

Implements `IStructureReceivedEDocument` (same interface as V1). Registered as enum value `"MLLM V2"` on `"Structure Data Impl."` — existing services using `"MLLM"` are unaffected until explicitly migrated.

Responsibilities:
- Build the AOAI chat messages (system prompt + PDF user message)
- Register the 6 verify tools as AOAI function definitions (`AOAITools`)
- Run the agentic dispatch loop in AL:
  1. Call `GenerateChatCompletion`
  2. If response contains tool call requests: execute via `EDocMLLMVerifyTools`, append results to `AOAIChatMessages`, increment call counter, go to 1
  3. If response contains no tool calls (model is done): extract final JSON
  4. If call counter exceeds budget: surface error
- On success: pass the final JSON to the existing `EDocMLLMSchemaHelper.MapHeaderFromJson` / `MapLinesFromJson` pipeline unchanged

The tool dispatch loop runs in AL, not inside the SDK. Each iteration is a new `GenerateChatCompletion` call with the tool results appended to the conversation history.

### `EDocMLLMVerifyTools.Codeunit.al`

Six methods, each returning `JsonObject` with `{ "pass": bool, "error": string }`:

| Tool | Inputs | Check |
|------|--------|-------|
| `verify_line_math` | unit_price, quantity, discount_pct, line_extension_amount | `unit_price × qty × (1 − disc/100) ≈ line_total` (within 1% relative tolerance) |
| `verify_invoice_totals` | line_amounts[], tax_exclusive_amount | `sum(lines) ≈ sub_total` (within 1% relative tolerance) |
| `verify_vat` | tax_exclusive_amount, vat_rate, tax_amount | `sub_total × rate/100 ≈ tax_amount` (within 1% relative tolerance) |
| `verify_dates` | issue_date, due_date | Both parse as valid dates; `due_date ≥ issue_date`; year in 1900–2100 |
| `verify_required_fields` | vendor_name, invoice_no, line_count | None are blank/zero |
| `verify_ranges` | quantities[], prices[], vat_rates[], discount_pcts[] | All > 0 (qty, price); 0–100 (vat, discount) |

Numeric tolerance for amount comparisons: 1% relative (`|expected − actual| / max(|actual|, 1) < 0.01`). A fixed absolute tolerance fails on large-quantity invoices where per-unit rounding accumulates (e.g. 1083 items × 0.005 rounding = 5.4 max error).

### `EDocMLLMExtractionV2-SystemPrompt.md`

New prompt resource. Three explicit sections:

1. **Structure identification** — "Before extracting any values, describe in your reasoning: document type, language, decimal separator, thousands separator, line item table column names and their roles (gross price, discount %, net price, quantity, line total), header and totals regions, and any flags (e.g. multiple discount columns, net price column present)."

2. **Targeted extraction** — "Extract data from the regions you identified. Do not sweep left-to-right across the full page. Use the column roles you identified to assign values correctly. Use XML decimal format (period as decimal separator, no thousands separators)."

3. **Verification** — "After producing the UBL JSON, call the verify tools on your output. If any tool reports a failure, read the error message, correct the relevant fields, and call the tools again. Finalize only when all tools pass."

---

## What Is Unchanged

- `EDocMLLMSchemaHelper.Codeunit.al` — `MapHeaderFromJson`, `MapLinesFromJson`, `GetDecimal` (with `Evaluate(..., 9)` from the V1 fix), `GetDate`
- `ubl_example.json` — UBL schema template (updated by V1 fix to use numeric `0` placeholders)
- `EDocMLLMHandler.Codeunit.al` — V1 stays registered under `"MLLM"` until removed

---

## What Is Retired

V1 (`"MLLM"` enum value and `EDocumentMLLMHandler.Codeunit.al`) is not removed in this change — existing service configurations keep working. A follow-up cleanup removes V1 once all services have migrated to `"MLLM V2"`.

---

## Error Flow

```
AOAI call fails entirely          → FallbackToADI() (existing path)
AOAI returns bad JSON             → FallbackToADI() (existing path)
Verify tools never all pass       → EDocument.Status = Error + log entry
Vendor fields missing (schema)    → FallbackToADI() (existing V1 ValidateMLLMResponse path)
```

---

## Open Questions

None — all design decisions confirmed.
