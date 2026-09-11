# Sales Order Agent — Item Variant Support

## 1. Overview

This document describes the implemented Item Variant support in the Sales Order Agent (SOA). The agent resolves customer requests to an **item + variant combination** when variant intent is present, checks availability and pricing under that variant, and exposes only safe alternatives.

### Scope

| Area | Baseline | Implemented State |
|---|---|---|
| Item Search | Finds items; variant data exists in index but is unused for selection | Resolve to item + variant via Item Selector |
| Availability | Hard-coded `Variant Filter = ''` (item-level only) | Variant-level availability via filter field on header |
| Pricing | No variant code on temp Sales Line | Variant-aware pricing |
| Alternatives | Item-level only | LLM returns alternative variants; pre-checked for availability |

### Reference

- TODO 558879 — broader variant test updates; the base `SOA-QUOTE_ITEMS_HANDLING_VARIANTS.yaml` dataset now has active `variantCode` assertions
- Variant Code is visible on the Sales Quote/Order subform page customizations
- Application changes are in the BCApps PR; the accuracy dataset changes are in a separate internal test-app PR

---

## 2. Item Search & Variant Resolution

### Current Flow

```
Email → SOA Dispatcher → SOA Impl
  → SOA Multi Items Availability page opens
    → OnBeforeFindRecord fires
      → SOAItemSearch.FindRecordItem()
        → GlobalItemSearch (platform ALSearch.FindItems API)
        → or SOABroaderItemSearch (AOAI-assisted)
        → SOAItemSelector (AOAI picks matching vs alternative)
      → Results: list of Item SystemIds
```

The platform item search API returns item candidates with indexed column values. The implementation does not rely on those results containing complete variant data: after exact, standard, or broader candidate collection, `SOAItemSearch` enriches every candidate from authoritative `Item Variant` records (Code, Description, and Description 2). `SOAVariantSearch.Codeunit.al` also exists for cross-column Item Variant search and is bound via `SOASessionEvents`.

### Design — Unified Resolution via Item Selector (AGREED)

**Key decision from design review:** Resolve variants through the **existing Item Selector** in a single LLM call, rather than a separate two-step process.

The Item Selector receives each search candidate's indexed item fields plus an authoritative `Variants` array added by application code. The LLM can distinguish variants from attributes because the payload labels them separately. The Item Selector returns both the best item **and** the best variant in one pass.

```
Item Search pipeline:
  → GlobalItemSearch / BroaderItemSearch finds candidates
  → SOAItemSearch enriches every candidate with authoritative Item Variant data
  → Item Selector receives candidates with column_values including the Variants array
  → Item Selector returns selected_items entries with item_no, optional variant_code,
    overall selection confidence, variant_match, variant_substitution_safety, and reason
  → Result: best match item+variant AND alternative item+variants
```

**Behavior:**
- Item Selector runs for standard and broader candidates and for exact item matches that have variants. A single exact item match with no variants bypasses the selector
- Candidate enrichment runs after exact, standard, and broader search so selector behavior does not depend on variant data being present in the search index payload
- `variant_code` is optional. When no variant is requested, omit it and set `variant_match` to `not_requested`
- When a returned code fulfills the request, set `variant_match` to `matching`; when it is a safe substitute, set it to `alternative`
- `variant_substitution_safety` independently classifies a substitution as `safe`, `unsafe`, or `not_applicable`. Application code retains an alternative only when it is explicitly `safe`; missing or unsafe decisions are discarded
- Alternative variants must be concrete entries in `selected_items`; application code does not synthesize variants omitted by the model
- If a requested non-interchangeable variant does not exist, return an empty `selected_items` array
- A valid empty result is successful and authoritative. It clears the item filter and never falls back to the original candidates
- Missing or malformed `selected_items`, AOAI failure, and missing function calls remain selector failures and retain the existing fallback behavior
- Returned item numbers are validated against the original candidate set, and variant codes are validated against the selected item before use
- `Variant Mandatory if Exists` is not included in the Item Selector candidate payload. Mandatory-without-request behavior is deferred until that metadata is available to the selector or enforced downstream
- Alternative variants are returned alongside the best match, avoiding extra LLM round-trips

### Implemented Components

| File | Change |
|---|---|
| `itemselector-task.md` | Defines item and variant selection behavior, interchangeability rules, safe alternatives, and valid empty results. |
| `itemselector-tool.md` | Defines one required `selected_items` array. Each entry requires `item_no`, `confidence`, `variant_match`, `variant_substitution_safety`, and `reason`; `variant_code` is optional. |
| `SOAItemSelector.Codeunit.al` | Runs AOAI, distinguishes valid empty results from failures, and emits non-sensitive failure telemetry. |
| `SOAItemSelectorFunc.Codeunit.al` | Strictly parses the function result and classifies malformed item, variant, and `variant_match` output. |
| `SOAItemSearch.Codeunit.al` | Enriches every candidate from authoritative Item Variant records, invokes Item Selector, validates candidate ownership, prefers concrete variant alternatives over generic item alternatives, applies variant-specific availability, and stores the resolved `Item SystemId → Variant Code` mapping. |

### Why this approach (from design review)

- The LLM receives existing indexed item fields plus authoritative variant data loaded in one batched Item Variant query
- We don't know which keywords match to variants vs. item names — the LLM decides
- Single LLM call for both item and variant selection avoids latency of separate round-trips
- LLM can distinguish between variants (e.g., colors) and attributes because the JSON payload labels each column
- Alternative variants come back in the same response, ready for use if primary is unavailable
- The latest incoming email body and the extracted text of its non-ignored attachments are combined in the `message_content` field of the untrusted-data envelope. The extracted `search_query` remains primary; supporting context may recover omitted same-item intent such as "any color," but must not contribute item or variant intent from unrelated lines in a multi-item email or attachment.

### Selector follow-up raised in handoff review (NOT YET DECIDED)

- **Schema-constrained variant values:** Dynamically constraining `variant_code` to candidate variant codes may reduce rejected output. Server-side candidate and variant validation remains mandatory even if a dynamic enum is added.

---

## 3. Availability with Variants (AGREED)

### Baseline

`SOA Multi Items Availability` uses **Item** as its source table. Each row = one item. Before this feature, the flow forced `Variant Filter = ''` in four places:

1. **`OnOpenPage`** — `Rec.SetRange("Variant Filter", '');`
2. **`CalcAvailQuantities`** — `Item.SetRange("Variant Filter", '');`
3. **`SOACreateTaskImpl.CalcItemProjAvailableBalance`** — `Item.SetRange("Variant Filter", '');`
4. **`SOAItemSearch.OnAfterCheckItemAvailable`** — `Item.SetRange("Variant Filter", '');`

The Item table's availability FlowFields (`Inventory`, `Qty. on Sales Order`, etc.) all respect the `Variant Filter` — so setting it to a specific variant code will correctly calculate variant-level availability. The platform handles this.

### Constraint: Page source table is Item, not Item Variant

The page source table is `Item`, meaning:
- **One row per item** — we cannot show the same item twice with different variants
- Variant Filter is a FlowFilter on Item, not a field per row

### Decision: Add Variant Filter field on page header (Option 1)

**Agreed and implemented.** The page keeps `Item` as its source table and obtains the resolved variant through its existing event pattern. Availability, pricing, translation, and shipment-date calculations use that resolved code.

```
OnAfterGetRecord:
  VariantCode := GetResolvedVariant(Rec."No.");  // from Item Selector result
  → CalcAvailQuantities uses VariantCode instead of ''
  → CalcPrice uses VariantCode
  → SOAShipmentDateMgt.SetParameters uses VariantCode
```

**Why this approach:**
- Minimal change to existing page structure
- All Item FlowFields already calculate correctly when Variant Filter is set — no rework needed
- Pricing naturally picks up variant-specific prices
- Confirmed by Volodymyr: "if we know the exact variant code, it's very easy to calculate price"

**Accepted limitation:** One variant per item row. For multi-variant same-item requests (e.g., "5 Blue + 3 Red Fairy Dolls"), these are handled as **separate searches** via agent instructions (agreed with Qasim).

**Future consideration:** May change to support multiple lines per item later, but the first iteration intentionally avoids redesigning the availability page. Ship the single-variant behavior first, gather feedback and telemetry, and revisit an item+variant buffer only if users need all alternatives displayed.

### Programmatic availability pre-check (AGREED)

Before showing results to the agent, **programmatically check availability** for the resolved item+variant:

```
Item Selector returns: best match (item + variant) + alternatives (item + variant)
  → Check: is best match available?
    Yes → show only best match to agent
    No  → show alternatives to agent instead
```

This avoids relying on the agent to interpret availability and make decisions. The decision is made in code before the agent sees the results.

### Implemented Components

| File | Change |
|---|---|
| `SOAMultiItemsAvailability.Page.al` | Reads the resolved variant, applies it to availability and translation, validates it on the temporary Sales Line, and passes it to shipment-date calculation. |
| `SOAItemSearch.Codeunit.al` | Supplies the resolved variant, applies variant-specific availability filtering, and stores the selected mapping. |
| `SOACreateTaskImpl.Codeunit.al` | Preserves the source item's Variant Filter when calculating projected available balance. |

---

## 4. Pricing with Variants (AGREED)

### Baseline

`CalcPrice` previously created a temporary Sales Quote line without Variant Code:
```al
TempSalesLine.Validate(Type, TempSalesLine.Type::Item);
TempSalesLine.Validate("No.", Rec."No.");
TempSalesLine.Validate(Quantity, 1);
// Baseline omitted Variant Code, producing a generic item price
```

BC's pricing engine uses Variant Code to find variant-specific prices and discounts.

### Implemented Behavior

After validating `"No."`, validate the variant code:

```al
TempSalesLine.Validate("No.", Rec."No.");
if VariantCode <> '' then
    TempSalesLine.Validate("Variant Code", VariantCode);
TempSalesLine.Validate(Quantity, 1);
```

**Confirmed straightforward** by Volodymyr: "if we know the exact variant code, it's very easy to calculate price." The BC pricing engine handles the rest.

### Item Translation with Variants

Variant-specific Item Translation lookup uses:

```al
if ItemTranslation.Get(Rec."No.", VariantCode, LanguageCode) then ...
```

This ensures variant-specific translated descriptions are shown when available.

---

## 5. Alternative Variant Suggestions (AGREED)

### Scenario

Customer requests "5 Blue Fairy Dolls". The Blue variant is out of stock. The agent should suggest other available variants (Red, Green).

### Design — LLM-driven alternatives with programmatic availability pre-check

**Agreed in design review:** The Item Selector returns both the best match and alternative variants in a single LLM call. We then programmatically check availability before showing results to the agent.

```
Item Selector returns:
  - Best match: AItem-0004 + variant BLUE (confidence: matching)
  - Alternative: AItem-0004 + variant RED (confidence: alternative)
  - Alternative: AItem-0004 + variant GREEN (confidence: alternative)

Programmatic pre-check:
  - BLUE available? → Show only BLUE to agent
  - BLUE not available? → Pick the first available same-item alternative variant and show that single variant to the agent
```

**Key principles (from design review):**
- No extra LLM round-trip for finding alternatives — they come back in the same Item Selector response
- Availability check is done **programmatically** (using existing helper functions), not by the agent
- Agent only sees items/variants that are already confirmed available (or the best match if availability check is disabled)
- Item Selector runs for exact matches when the item has variants. A single exact item with no variants bypasses the selector

### Implementation compromise — single displayed alternative variant

The initial implementation keeps `SOA Multi Items Availability` source table as `Item` and therefore keeps one row per item. To avoid redesigning the availability page as a temporary item+variant buffer, alternative variants are handled internally as an ordered list of candidates for the same item. The programmatic availability check selects the first available alternative variant and stores only that variant in the `Item SystemId → Variant Code` mapping shown on the page.

This means the agent sees one available alternative variant, not all available alternatives. This preserves the existing item-based page behavior and reduces risk to non-variant item flows.

**Confirmed for the first iteration in the handoff review:** Andrei selected the simplest current behavior: show one available alternative variant, ship it in the major release, and use feedback and telemetry to decide whether displaying all available variants justifies an availability-page redesign.

The alternative is a suggestion, not an automatic substitution. When the requested variant is unavailable, do not create a quote until the customer confirms the offered alternative variant.

For requests where an interchangeable variant does not exist, such as "Yellow MagicToyland Fairy Doll" when only BLUE, GREEN, and RED exist, the Item Selector may return concrete same-item variants. When at least one concrete variant alternative is present, search post-processing suppresses generic variantless item alternatives, availability-checks the concrete alternatives, and exposes the first available same-item variant. It does not synthesize variants omitted by the selector.

### Smart alternative suggestions via prompting

Andrei raised that variant interchangeability is context-dependent:
- Shoe sizes (44 vs 42) — **not interchangeable**
- Keyboard colors (black vs white) — **interchangeable**

**Agreed approach:** Use LLM prompting to handle this. Instruct the Item Selector to only return alternative variants that are "closely related" or "reasonable substitutes." The LLM should use common sense — e.g., don't suggest adult bicycle when kids bicycle is requested, but do suggest white keyboard when black is unavailable.

Variant values that affect fit, compatibility, or another non-interchangeable requirement are not reasonable substitutes. For example, do not suggest shoe size 42 when the customer requested size 44 unless the customer explicitly permits other sizes.

### Fallback behavior

If no matching variant or safe concrete alternative qualifies:
- The selector returns a valid empty result
- Search treats the empty result as authoritative and does not restore the original candidates
- The agent treats the result as a customer-facing unavailability outcome, sends a reply explaining that the requested item/variant and any suitable alternative are unavailable, and does not request internal assistance
- The agent must not create a quote or offer an unsafe substitute

### Implemented Components

| File | Change |
|---|---|
| `itemselector-task.md` | Restricts alternatives to interchangeable dimensions and requires concrete alternative entries. |
| `SOAItemSelectorFunc.Codeunit.al` | Parses matching and alternative variant entries and validates their state combinations. |
| `SOAItemSearch.Codeunit.al` | Availability-checks matching entries first, then concrete alternatives, and stores the selected mapping. |
| `SalesOrderAgent-AgentInstructions.md` | Routes an empty result for a variant-specific request to a customer reply instead of internal availability assistance. |

---

## 6. Sales Quote/Order Line Creation (AGREED)

### Implemented State

The `Variant Code` field is visible on both Sales Quote Subform and Sales Order Subform page customizations:

```al
modify("Variant Code") { Visible = true; }
```

### Implementation

1. `Variant Code` is visible on the SOA page customizations
2. When the agent creates a sales line, it sets Variant Code after Item No. when a variant was resolved
3. The orchestration flow carries the resolved variant code from search and availability through line creation

### Agent behavior with visible Variant Code

Volodymyr raised: if Variant Code is always visible but some items don't have variants, will the agent try to fill it with something? 

**Agreed approach:** Rely on proper prompting/instructions to guide the agent. If items have variants, the agent uses the resolved variant code from the search phase. If items don't have variants, the field stays empty. Andrei noted companies using variants typically want it selected everywhere — this aligns with making it always visible.

### Implemented Components

| File | Change |
|---|---|
| `SOASalesQuoteSubform.PageCust.al` | Shows Variant Code on Sales Quote lines. |
| `SOASalesOrderSubform.PageCust.al` | Shows Variant Code on Sales Order lines. |

---

## 7. End-to-End Flow (Target State)

```
1. Email arrives: "5 Blue Fairy Dolls, 3 Red Bicycles"

2. SOA Dispatcher → SOA Impl → Opens SOA Multi Items Availability

3. OnBeforeFindRecord fires → SOAItemSearch.FindRecordItem():
   a. Platform search finds candidates including AItem-0004 (Fairy Doll) and AItem-0011 (Bicycle)
  b. SOAItemSearch enriches candidates with authoritative Item Variant data
  c. Item Selector (LLM) receives candidates with column_values including the Variants array
  d. Item Selector returns:
    - AItem-0004, variant_code: BLUE, confidence: matching, variant_match: matching
    - AItem-0004, variant_code: RED, confidence: alternative, variant_match: alternative
    - AItem-0004, variant_code: GREEN, confidence: alternative, variant_match: alternative
    - AItem-0011, variant_code: RED, confidence: matching, variant_match: matching
    - Each entry also contains a concise reason (omitted here for brevity)
  e. Programmatic availability check:
      - AItem-0004 + BLUE → available ✓ → use BLUE
      - AItem-0011 + RED → available ✓ → use RED
  f. Store mapping: {AItem-0004 → BLUE, AItem-0011 → RED}

4. OnAfterGetRecord for AItem-0004:
   a. VariantCode = BLUE (from mapping)
   b. CalcAvailQuantities with Variant Filter = 'BLUE'
   c. CalcPrice with Variant Code = BLUE on temp Sales Line

5. OnAfterGetRecord for AItem-0011:
   a. VariantCode = RED (from mapping)
   b. CalcAvailQuantities with Variant Filter = 'RED'
   c. CalcPrice with Variant Code = RED on temp Sales Line

6. Agent reads availability results → Creates Sales Quote:
   a. Line 1: Item AItem-0004, Variant Code BLUE, Qty 5
   b. Line 2: Item AItem-0011, Variant Code RED, Qty 3

7. Agent sends reply email mentioning variants in descriptions
```

### Alternative scenario (variant unavailable):

```
3c. Item Selector returns:
  - AItem-0004, variant_code: BLUE, confidence: matching, variant_match: matching
  - AItem-0004, variant_code: RED, confidence: alternative, variant_match: alternative
  - AItem-0004, variant_code: GREEN, confidence: alternative, variant_match: alternative

3d. Programmatic availability check:
    - AItem-0004 + BLUE → NOT available ✗
  - AItem-0004 + RED → available ✓ → use RED as the selected alternative
  - AItem-0004 + GREEN → not shown because the item page displays one variant per item row

3e. Agent sees RED (not BLUE) on availability page
  → Does not create a quote yet
  → Reply email says BLUE is unavailable, offers RED, and asks the customer to confirm
  → Creates the quote with RED only after customer confirmation
```

---

## 8. Test Scenarios

The base `SOA-QUOTE_ITEMS_HANDLING_VARIANTS.yaml` dataset contains ten active scenarios:

| Test | Required behavior |
|---|---|
| `QUOTE_5_ITEMS_VARIANTS_01` | Resolve explicit variant labels to exact Variant Codes on quote lines. |
| `QUOTE_5_ITEMS_VARIANTS_02` | Resolve variant wording embedded in item descriptions. |
| `QUOTE_3_ITEMS_VARIANTS_03` | Resolve semantic and broad variant wording, including an acceptable "any color" request. |
| `QUOTE_3_ITEMS_VARIANTS_04` | Omit Variant Code when no variant is requested. |
| `QUOTE_1_ITEM_VARIANT_ALTERNATIVE_05` | For a missing interchangeable color, offer exactly one available same-item color, do not offer another item, and wait for confirmation. |
| `QUOTE_1_ITEM_VARIANT_ALTERNATIVE_06` | When the requested size exists but is unavailable, do not offer other sizes. |
| `QUOTE_1_ITEM_VARIANT_ALTERNATIVE_07` | When the requested size does not exist, preserve the authoritative empty selection, offer no other size, and create no quote. |
| `QUOTE_1_ITEM_VARIANT_ALTERNATIVE_08` | Honor an explicit customer prohibition against color substitution and create no quote. |
| `QUOTE_1_ITEM_VARIANT_ALTERNATIVE_10` | When the requested color exists but is unavailable, offer one safe available same-item color without silently substituting. |
| `QUOTE_2_ITEMS_VARIANT_CONTEXT_ISOLATION_11` | Keep variant context isolated between multiple requested items. |

The `variantCode` expectations are active. Scenarios `_07`, `_08`, `_10`, and `_11` were specifically verified while simplifying the prompt contract. All ten active scenarios should be rerun after changes to selector output parsing, candidate validation, or availability fallback.

### Deferred Scenario

`_09` (variant mandatory but not specified) is intentionally not active. The Item Selector candidate payload does not include `Variant Mandatory if Exists`, so the selector cannot reliably distinguish an optional blank variant from a mandatory missing variant. Add this scenario only after that metadata is supplied to the selector or deterministic downstream enforcement is implemented.

### Additional Coverage

- Variant-specific pricing differs from the base item price
- Variant code and semantic variant wording in non-English languages
- Same item requested with multiple variants through separate searches
- PDF or attachment input containing item variants
- Larger item counts and mixed variant requests
- Alternative item whose best candidate also requires an alternative variant

### Known Runtime Note

A spaced variant code such as `AGE - 6-8` can trigger an agent-runtime lookup failure and produce a quote line with quantity 0 even when the outgoing message is otherwise correct. Track this separately from application search and availability behavior.

---

## 9. Implemented Architecture

### Selector Contract

1. The tool schema requires one `selected_items` array.
2. Every selected entry requires `item_no`, overall selection `confidence`, `variant_match`, `variant_substitution_safety`, and `reason`.
3. `variant_code` is optional and must be omitted when `variant_match` is `not_requested`.
4. `variant_match` is `matching` when the code fulfills the request and `alternative` when the code is a safe substitute.
5. `variant_substitution_safety` is `safe` only for presentation-only changes that preserve suitability or changes explicitly permitted by the customer. It is `unsafe` for suitability-affecting, prohibited, or uncertain changes and `not_applicable` for exact matches or requests without variant intent.
6. The parser discards every alternative that is not explicitly classified `safe`, independently of its code or description. If no safe entry remains, the result is a valid empty selection.
7. A valid empty array is a successful business result. Missing or malformed required output outside the fail-closed alternative-safety handling is a selector failure.
8. There is no separate unresolved-request output. Safe alternatives must be concrete selected entries; unsafe missing variants produce an empty result.

### Search and Validation

1. Item Selector runs after candidate collection for standard and broader search paths and for exact item matches that have variants. A single exact item match with no variants bypasses the selector.
2. Candidate payloads preserve indexed item fields and add an authoritative `Variants` array from Item Variant records before entering the untrusted-data envelope with supporting message context.
3. Returned item numbers must belong to the original candidate set.
4. Returned variant codes must exist for the selected item.
5. Matching item+variant pairs are availability-filtered first; concrete alternatives are considered only when no matching pair remains available.
6. The selected mapping is stored as `Item SystemId -> Variant Code` and consumed by the availability page.

### Availability, Pricing, and Quote Creation

1. Availability calculations apply the resolved Variant Filter.
2. Shipment date calculations receive the resolved Variant Code.
3. Temporary sales lines validate Variant Code before price calculation.
4. Item Translation lookup uses the resolved variant.
5. Variant Code is visible on SOA sales quote and sales order subforms.
6. Alternative variants are suggestions and require customer confirmation before quote creation.

### Telemetry

Telemetry distinguishes valid empty selection, AOAI failure, malformed function output, invalid item number, invalid variant code, rejected `variant_match` combinations, and server-side candidate or variant ownership rejection counts. It records categories, booleans, and aggregate counts only; customer content, item numbers, variant codes, and descriptions are not logged.

### Validation Workflow

1. Run focused AL diagnostics after selector, search, availability, or prompt changes.
2. Build the full workspace with CodeCop.
3. Run all ten active variant accuracy scenarios after changes to selector parsing or fallback behavior.
4. Run the regular accuracy suite to detect non-variant regressions.
5. Track agent-runtime issues, including spaced variant codes, separately from application search and availability failures.

---

## 10. Decisions from Design Review

| Question | Decision |
|---|---|
| No variant specified but item has variants | Omit `variant_code` and set `variant_match` to `not_requested`. Do not choose a variant without a request signal. |
| Variant feature configuration | Do not add a separate SOA setup Boolean. Customers without Item Variant records retain the standard flow. Mandatory-without-request enforcement is deferred because that field is not in the selector payload. |
| Non-existent variant requested | Return concrete alternatives only for interchangeable dimensions. Return a valid empty result when substitution could change suitability or the customer rejects substitutions. |
| Multi-variant same item | Handle as **separate searches** via agent instructions. One variant per item row on availability page. |
| Variant in reply email | Include variant information (code and/or description) in outgoing email. |
| Item Selector contract | Return one `selected_items` array with optional `variant_code`, required `variant_match`, independent `variant_substitution_safety`, overall selection confidence, and reason. Alternatives are retained only when safety is explicitly `safe`. |
| Where to resolve variants | In Item Selector during search phase (not on availability page). |
| Availability page redesign | Not needed for initial implementation. Keep Item source table + Variant Filter field on header. |
| Alternative variant logic | LLM-driven with deterministic post-processing. When the selector returns concrete variant alternatives, code suppresses generic variantless item alternatives without synthesizing variants from unknown terms. Availability is pre-checked programmatically, and the initial implementation shows the first available same-item alternative variant only. |
| Quote creation for an alternative | Offer the available alternative and wait for customer confirmation. Do not silently substitute the variant or create the quote in the initial response. |
| When best match is unavailable | Show the first available concrete safe alternative. If none qualifies, preserve the authoritative empty result, reply to the customer without requesting internal assistance, and create no quote. |
| Valid empty selector result | Treat it as successful and never fall back to original candidates. |
| Release scope | Target the major release. Do not initially backport to version 28 because the cross-cutting behavior change needs broader validation. |

---

## 11. Notes & Future Considerations

- **Item attributes at variant level:** Andrei noted that item attributes now exist at the variant level (recently added) and may not yet be included in the item index table. Platform could add more columns to the index. Not a blocker for initial implementation but worth exploring.
- **Item Variant Index Table:** Platform created an item variant index table for this purpose, but the implementation does not query it directly. Search still uses the existing item index for discovery, then enriches selected candidates from authoritative Item Variant records before Item Selector runs.
- **Consistency of alternatives:** Item Selector runs whenever variant evaluation may be needed, so concrete alternatives remain available for exact items with variants and for standard and broader search paths.
- **Buffer table approach:** Could be revisited after feedback and telemetry if we need to display multiple variants per item as separate rows on the availability page.
- **Message-context scope:** The latest incoming email body and its non-ignored extracted attachment text are approved as supporting context for same-item intent. Broader use for vague item discovery should be evaluated separately for relevance, token cost, and cross-item interference.
- **Dynamic variant enum:** Potential way to constrain model output to known variant codes, but not approved as a requirement; server-side validation remains necessary either way.
- **Mandatory variant metadata:** Add `Variant Mandatory if Exists` to candidate metadata or enforce it downstream before activating the deferred `_09` scenario.
- **Alternative item + alternative variant:** The handoff review did not confirm this combined fallback scenario as supported. Keep it explicit in tests and scope discussions.
