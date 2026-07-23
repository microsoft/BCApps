# Shopify Tax Matching Agent — Test Matrix

## Setup Variations

| Setting | Values |
|---------|--------|
| Tax Matching Agent Enabled | Yes / No |
| Auto Create Tax Jurisdictions | Yes / No |
| Auto Create Tax Areas | Yes / No |
| Tax Area Naming Pattern | `SHPFY-` / Custom / Blank |

## Pre-conditions

| ID | Condition | Description |
|----|-----------|-------------|
| P1 | Tax Matching Agent disabled | Shop has Tax Matching Agent Enabled = No |
| P2 | Copilot capability not registered | Capability missing from Copilot AI Capabilities page |
| P3 | Copilot capability inactive | Registered but turned off |
| P4 | Tax Area already assigned | Order already has a Tax Area Code from address-based MapTaxArea |
| P5 | No tax lines on order | Order has no Shopify tax lines at all |
| P6 | All tax lines already matched | All tax lines already have a Tax Jurisdiction Code |

---

## Jurisdiction Matching Scenarios

| # | Scenario | Existing Jurisdictions | Auto Create Juris. | LLM Returns | Expected Result |
|---|----------|----------------------|--------------------|--------------|----|
| J1 | Exact match — all lines | NYSTAX, NYCTAX, MTATAX exist | N/A | high confidence matches to all 3 | Tax Jurisdiction Code set on all tax lines |
| J2 | Partial match — some lines | NYSTAX exists, NYCTAX does not | No | high for NYSTAX, low for NYCTAX | Only NYSTAX matched; NYCTAX skipped (logged) |
| J3 | Partial match + auto-create | NYSTAX exists, NYCTAX does not | Yes | high for NYSTAX, low for NYCTAX | NYSTAX matched; NYCTAX created and matched |
| J4 | No match — all new | None exist | No | low confidence for all | No matches applied (all skipped) |
| J5 | No match + auto-create | None exist | Yes | low confidence with suggested codes | All jurisdictions created and matched |
| J6 | LLM returns empty jurisdiction_code | Any | Yes | `jurisdiction_code: ""` | Skipped (logged as low confidence) |
| J7 | LLM returns medium confidence | Jurisdiction exists | N/A | medium confidence | Matched (medium is accepted regardless of auto-create) |
| J8 | Duplicate jurisdiction codes | NYSTAX exists | Yes | Same code for multiple tax lines | Jurisdiction used for all lines; added to MatchedJurisdictions once |

---

## Tax Jurisdiction Creation Details (Auto Create = Yes)

| # | Scenario | Expected Result |
|---|----------|-----------------|
| JC1 | Country/Region | New jurisdiction has Country/Region from order's Ship-to |
| JC2 | Report-to Jurisdiction — multiple | 3 jurisdictions created (state, county, city): all have Report-to = state-level jurisdiction (first in list) |
| JC3 | Report-to — single jurisdiction | Only 1 jurisdiction matched: FixReportToJurisdictions not called (guard: Count > 1) |
| JC4 | Jurisdiction already exists | LLM suggests code that already exists: existing jurisdiction used as-is (not modified, not re-created) |
| JC5 | Description | New jurisdiction description = jurisdiction code (e.g. "NYSTAX") |
| JC6 | Report-to on a pre-existing blank jurisdiction | A matched jurisdiction already exists with a blank Report-to (e.g. from an earlier run): its Report-to is set to the state-level jurisdiction, not left blank (covered by `ReapplySetsReportToOnBlankJurisdictions`); a jurisdiction that already has a non-blank Report-to is preserved (`ReapplyPreservesExistingReportTo`) |

---

## Tax Detail Scenarios (Auto Create Jurisdictions = Yes)

| # | Scenario | Existing Tax Details | Expected Result |
|---|----------|---------------------|-----------------|
| TD1 | No existing detail | None for this jurisdiction + tax group | Tax Detail created with rate from tax line |
| TD2 | Exact detail exists | Same jurisdiction, tax group, and rate | No duplicate created |
| TD3 | Same jurisdiction, different rate | Valid bracket exists at earlier date with a different rate than Shopify's | **Line is matched** to the (correct) jurisdiction and the **Tax Area is built**; existing detail preserved (not overwritten or duplicated); rate conflict logged (telemetry `0000UMR`) and flagged on the order (`Tax Rate Conflict`); the order is held for review; the line is highlighted red (BC rate vs Shopify rate) on the review page (see RD1) |
| TD4 | Same jurisdiction, different tax group | Detail exists with different Tax Group Code | New Tax Detail created for the new tax group |
| TD5 | Item has no tax group | Order line item has blank Tax Group Code | Tax Detail created with blank Tax Group Code |
| TD6 | Order line has no item | Item No. is blank on order line | Tax Detail created with blank Tax Group Code |
| TD7 | Multiple tax lines across jurisdictions | Two tax lines on different jurisdictions, auto-create on | One Tax Detail per jurisdiction |
| TD8 | Effective date | Order Document Date = 2026-01-15 | Tax Detail has Effective Date = 2026-01-15 |

---

## Rate Divergence Scenarios

When a matched jurisdiction's existing Tax Detail (for the line's item tax group, valid as of
the order date) has a rate that differs from Shopify's, the agent still matches the (correct)
jurisdiction and builds the Tax Area, but sets the stored `Tax Rate Conflict` flag and
holds the order for human review. That flag is the single source of truth (gate, notifications,
order-page caption, review-page guidance + Approve all read it). The reviewer sees Shopify's and
BC's rates side by side (green/red) on the review page and decides whether to accept BC's rate,
change the jurisdiction, or correct the Tax Detail. Jurisdiction edits on the page only take
effect on Approve and are reverted if the page is closed without approving.

| # | Scenario | Setup | Expected Result |
|---|----------|-------|-----------------|
| RD1 | Item-group rate conflict | `NYSTAX × FURNITURE` Tax Detail = 10%; order line taxed at 20% for NYSTAX (group FURNITURE) | Line matched to NYSTAX; existing 10% detail untouched; telemetry `0000UMR`; `Tax Match Applied` + `Tax Rate Conflict` set; **Tax Area built**; Activity Log entry on the line noting the rate difference; order held (see RD3/RD4) |
| RD2 | Partial conflict, multi-line | Lines A (NYSTAX, no existing detail) and B (NYCTAX × FURNITURE conflict) | A matched (code written, detail seeded); B matched (code written, existing detail untouched); **Tax Area built from both**; order flagged `Tax Rate Conflict` and held |
| RD3 | Held in blocking mode | RD1 + shop Review Required = Yes | `OnBeforeCreateSalesHeader` sets `Handled := true`; no Sales Document created |
| RD4 | Held in non-blocking mode | RD1 + shop Review Required = No | Still held — the gate holds because `Tax Rate Conflict` is set, regardless of the toggle, so a rate difference is never auto-posted without review |
| RD5 | Resolved then approved / re-run | After RD1 the reviewer either (a) accepts BC's 10% and clicks Approve, or (b) corrects the Tax Detail rate to 20% then Approves (or re-runs Find Mappings on the Shopify order) | On Approve the Tax Area is rebuilt from the line jurisdictions, `Tax Rate Conflict` is recomputed (clears when rates now agree), and the order is released. A re-run rebuilds from the order's **full** jurisdiction set (carried in from persisted codes), not just the re-matched line |
| RD8 | Edit discarded on close | On a held order the reviewer changes a line's Tax Jurisdiction Code, then closes the page **without** Approve | A confirmation warns the edit will be discarded; on confirm the line's Tax Jurisdiction Code is reverted to its pre-edit value and `Tax Rate Conflict` is unchanged (still authoritative) |
| RD9 | Undo Approval | On an approved, held order with no Sales Document yet (`Sales Order No.`/`Sales Invoice No.` blank), **Undo Approval** (after a confirm) clears `Tax Match Reviewed` so the order is held again; the action is hidden once a Sales Document exists or the order is not held-when-unapproved |
| RD10 | Use Shopify Rate resolves the conflict | On a conflict line the reviewer clicks **Use Shopify Rate** (after a confirm warning it changes shared tax setup beyond this order): a Tax Detail is created/updated for the line's jurisdiction + tax group, effective the order's document date, at Shopify's rate. The row turns green (BC rate now equals Shopify's); on Approve the Tax Area is rebuilt and `Tax Rate Conflict` clears. The action is disabled when the rates already agree or no jurisdiction is assigned. **Verified manually / by TestPage** (page action + Confirm) |

---

## Shipping Tax Scenarios

Shipping-charge tax lines (stored by the connector on `Shpfy Order Tax Line` with
`Parent Id = "Shopify Shipping Line Id"`) are treated as **first-class** tax lines: the LLM
matches each to a jurisdiction, and it seeds a Tax Detail for the Shop's `Shipping Charges
Account` Tax Group Code at the **shipping line's own rate** (not derived from product lines).
A shipping-line rate conflict holds the order for review exactly like a product-line one.

| # | Scenario | Shop Setup | Order Data | Expected Result |
|---|----------|------------|------------|-----------------|
| S1 | Shipping bracket seeded at its own rate | Shipping Charges Account `GLA-SHIP`, group `SHIPGRP`; NYSTAX exists | Item tax line NYSTAX @ 4%, shipping tax line NYSTAX @ **3%** | `(NYSTAX × TAXABLE)` @ 4% and `(NYSTAX × SHIPGRP)` @ **3%** — the shipping bracket comes from the shipping line's own rate |
| S2 | Shipping bracket under new jurisdiction | Same + Auto Create Jurisdictions = Yes | Item + shipping tax lines, no existing jurisdictions | Jurisdiction created; both `(NYSTAX × TAXABLE)` and `(NYSTAX × SHIPGRP)` seeded |
| S3 | Shipping charge without tax lines | Shipping account configured | Shipping charge present but **no** shipping tax lines (untaxed) | Only the item-side detail seeded; `(NYSTAX × SHIPGRP)` count = 0; no error |
| S4 | Shipping account with empty Tax Group Code | `GLA-SHIP` with blank Tax Group Code | Item + shipping tax lines | Item-group detail plus a `(Jurisdiction × '')` detail from the shipping line |
| S5 | Shipping group same as item group | Shipping account's group = `TAXABLE` (same as item), same jurisdiction & rate | Item + shipping tax lines both NYSTAX @ 4% | Single `(NYSTAX × TAXABLE)` row (idempotent seeding, count = 1) |
| S6 | Multiple shipping charges, same jurisdiction | Shipping account group `SHIPGRP` | Two shipping charges both NYSTAX @ 4% | Exactly one `(NYSTAX × SHIPGRP)` row (idempotency); no rate conflict |
| S7 | Shipping rate conflict holds order | Shipping account group `FREIGHT`; existing `(NYSTAX × FREIGHT)` @ 5% | Shipping tax line NYSTAX @ 8% | Shipping line matched; existing 5% untouched; `Tax Rate Conflict` set; order held (covered by `Shpfy TMA Rate Conflict Test`) |

---

## Tax Area Scenarios

| # | Scenario | Auto Create Areas | Existing Tax Areas | Expected Result |
|---|----------|-------------------|-------------------|-----------------|
| TA1 | Exact area exists | N/A | Area with exactly NYSTAX+NYCTAX+MTATAX | Existing area reused; no new area created |
| TA2 | Superset area exists | N/A | Area with NYSTAX+NYCTAX+MTATAX+EXTRA | Not matched (line count differs); new area or skip |
| TA3 | Subset area exists | N/A | Area with only NYSTAX+NYCTAX | Not matched; new area or skip |
| TA4 | No matching area + auto-create | Yes | None match | New Tax Area created: code = `SHPFY-MTATAX`, description = `Shopify - ...` |
| TA5 | No matching area, no auto-create | No | None match | Tax Area Code remains blank on order |
| TA6 | Area code collision | Yes | `SHPFY-MTATAX` already exists (different jurisdictions) | New area created as `SHPFY-MTATAX-2` |
| TA7 | Country/Region on area | Yes | N/A | New Tax Area has Country/Region from order's Ship-to |
| TA8 | Tax Liable flag | Yes | N/A | Order Header has Tax Liable = Yes after area assigned |
| TA9 | Custom naming pattern | Yes, pattern = `TAX-` | N/A | Area code = `TAX-MTATAX` |
| TA10 | Empty naming pattern | Yes, pattern = blank | N/A | Area code = `MTATAX` |
| TA11 | No matched jurisdictions | N/A | N/A | FindOrCreateTaxArea not called (guard in Events) |

---

## Guard / Early Exit Scenarios

| # | Scenario | Expected Result |
|---|----------|-----------------|
| G1 | Tax Matching Agent disabled on shop | No LLM call; order unchanged |
| G2 | Copilot capability not registered | No LLM call; order unchanged |
| G3 | Copilot capability inactive | No LLM call; order unchanged |
| G4 | Tax Area already set by MapTaxArea | the agent skipped; existing Tax Area kept |
| G5 | Order is Tax Exempt | the agent skipped; order unchanged |
| G6 | No order lines | MatchTaxLines returns false |
| G7 | All tax lines already have jurisdiction codes | MatchTaxLines returns false (no unmatched lines) |
| G8 | Order import Result = false | Event subscriber exits immediately |

---

## HITL (Human-in-the-loop) Scenarios

| # | Scenario | Expected Result |
|---|----------|-----------------|
| HITL-1 | Order Header marker set; Sales Header created | `Sales Header."Tax Match Applied" = true` (propagated via `OnAfterCreateSalesHeader`) |
| HITL-2 | Order Header marker false; Sales Header created | Sales Header marker stays false (no propagation) |
| HITL-3 | `MarkReviewed` from the Sales Order notification | Sets the originating order's `Tax Match Reviewed = true` (resolved via `Sales Order No.`) |
| HITL-4 | `DisableForUser` from the Sales Order notification | Sets the order's `Tax Match Reviewed = true` and disables the prompt via `My Notifications` |
| HITL-5 | Successful match applied | `Activity Log Entry` count for the Order Header `Tax Area Code` field ≥ 1; per-line entries on each matched `Shpfy Order Tax Line` |
| HITL-6 | LLM returns 'low'/'medium'/'high'/unknown confidence | `Capitalize` helper maps to 'Low'/'Medium'/'High'/'Low' (safe fallback); `Activity Log Builder.SetConfidence` does not error |
| HITL-7 | Review page Approve visibility (held order) | On a held order (shop requires review, or a live rate conflict) that isn't yet approved, **Approve** is visible; it sets `Tax Match Reviewed = true` and the order's Sales Document is created on the next process run |
| HITL-8 | Review page Approve hidden (non-blocking, no conflict) | With review not required and no rate conflict, the order isn't held (its Sales Document is created automatically), so the page's **Approve** action is hidden and the page is informational |
| HITL-9 | Review page scoping + content | The tax lines ListPart shows exactly the tax lines of the current order (filtered by the order's order line ids via `SetTaxLineFilter`), each with its applies-to Item No./description; AI confidence indicators render on Tax Jurisdiction Code |
| HITL-10 | Sales Order prompt is stateless | With `Sales Header."Tax Match Applied"` set, the prompt fires iff the originating order's `Tax Match Reviewed = false` and `My Notifications` is enabled; no `Shpfy TMA Notification` table exists |
| HITL-11 | Order-page review notification | On opening a matched, not-yet-reviewed Shopify order, `SendOrderReviewNotification` fires once per order/session; **Review** opens the review page; **Don't show again** disables it via `MyNotifications` |
| HITL-12 | Page review actions | Shpfy Order page: **Review and Approve Tax Match** shows while the order is held (shop requires review or a live rate conflict) and it isn't yet approved, else **Review Tax Match**; both open the review page (hidden when not agent-matched). BC Sales Order page: **Review Tax Match** opens the review page when the marker is set |
| HITL-13 | Review page close guard | When the order is being held (shop requires review, or a rate conflict) and it is not yet approved, closing the Tax Match Review page raises the `OnQueryClosePage` confirmation; declining keeps the page open. No warning once the order is approved |
| RD6 | Approve rebuilds Tax Area | On a **held**, not-yet-reviewed order the **Approve** action is shown; it re-applies the line jurisdictions (re-seeding brackets, re-detecting conflicts), rebuilds the Tax Area, refreshes `Tax Rate Conflict`, and sets `Tax Match Reviewed`. Approve is blocked (error) while any tax line has a blank Tax Jurisdiction Code, **and** errors without releasing the order if no Tax Area can be resolved for the selected jurisdictions (e.g. edited to a set with no existing area and Auto Create Tax Areas is off) |
| RD7 | Rate comparison + edit | Each tax line shows Shopify's rate next to Business Central's Tax Detail rate; the row is green when they agree, red when they differ. Editing a line's Tax Jurisdiction Code recomputes the BC rate/colour; on a rate conflict, the Overview tab shows a guidance message that approving posts at BC's rate |

**Shop Card field dependencies (SC scenarios)**

| # | Scenario | Expected Result |
|---|----------|-----------------|
| SC-1 | Tax Matching Agent Enabled = No | Auto Create Jurisdictions/Areas, Naming Pattern, and Review Required are disabled (greyed out) |
| SC-2 | Enabled = Yes, Auto Create Tax Areas = No | Tax Area Naming Pattern is disabled; the other three are enabled |
| SC-3 | Enabled = Yes, Auto Create Tax Areas = Yes | Tax Area Naming Pattern is enabled |

---

## Hard Matching Scenarios (LLM Stress Tests)

These scenarios test the LLM's ability to handle ambiguous, misleading, or complex matching situations with real AOAI calls. All use `autoCreateTaxJurisdictions: false` unless noted.

| # | Scenario | Challenge | Jurisdictions | Tax Lines | Ship-to | Expected |
|---|----------|-----------|---------------|-----------|---------|----------|
| H1 | Similar codes, different states | CASTAX (California) vs CATAX (Canada) — "CA" is ambiguous | CASTAX, CATAX, COSTAX | "CA STATE TAX" @ 7.25% | US / CA / Los Angeles | CASTAX (geographic context: CA = California) |
| H2 | Abbreviated title, multiple similar | "NYC MTA" with 3 MTA-related jurisdictions | MTATAX, MTANYC, MTANYS | "NYC MTA" @ 0.375% | US / NY / New York | Any of the 3 (soft assertion) |
| H3 | Multi-state distractors | Texas order with 15 distractor jurisdictions from other states | 13 non-TX + TXSTAX, TXCTAX | "TEXAS STATE SALES TAX" @ 6.25%, "HOUSTON CITY TAX" @ 2.0% | US / TX / Houston | TXSTAX, TXCTAX |
| H4 | Truncated Shopify title | "METROPOLITAN COMMUTE" (truncated) must match full description | MTATAX, MCTMTX | "METROPOLITAN COMMUTE" @ 0.375% | US / NY / New York | MCTMTX |
| H5 | Canadian HST/GST/PST | Ontario gets HST (combined), not separate GST or PST | CAHST, CAGST, CAPST, BCPST | "HST" @ 13.0% | CA / ON / Toronto | CAHST |
| H6 | Same rate, different scopes | County tax vs transit tax — both LA, similar names | LACOTR, LACOTX, CASTAX | "LOS ANGELES COUNTY TAX" @ 1.0%, "CALIFORNIA STATE TAX" @ 6.0% | US / CA / Los Angeles | LACOTX, CASTAX |
| H7 | Unusual formatting/casing | "State of New York - Sales & Use Tax", "The City of New York Tax" | NYSTAX, NYCTAX | Unusual wording | US / NY / New York | NYSTAX, NYCTAX |
| H8 | Geographic disambiguation | "NEW YORK SALES TAX" from Albany — state not city level | NYCSAL, NYSSAL, NJSSAL | "NEW YORK SALES TAX" @ 4.0% | US / NY / Albany | NYSSAL (state-level, Albany is not NYC) |
| H9 | 5 tax lines, mixed difficulty | Large order — some trivial, others need semantic reasoning | TXSTAX, TXHTAX, TXHCTX, TXMTD, TXESD | "TEXAS STATE SALES TAX", "CITY OF HOUSTON TAX", "HARRIS CO TAX", "METRO TRANSIT AUTHORITY", "ESD #1" | US / TX / Houston | All 5 matched (soft assertion) |
| H10 | Misleading jurisdiction code | WATAX = Washington, not Waterloo — LLM must read descriptions | WATAX, IASTAX, IACTAX | "IOWA STATE TAX" @ 6.0%, "WATERLOO LOCAL TAX" @ 1.0% | US / IA / Waterloo | IASTAX, IACTAX |
| H11 | Auto-create with distractors | 10+ existing jurisdictions; match what fits, create new for rest | 10 mixed-state jurisdictions including NYSTAX | "NEW YORK STATE TAX" @ 4.0%, "YONKERS SURCHARGE" @ 1.5% | US / NY / Yonkers | NYSTAX matched; Yonkers auto-created (autoCreate=true) |
| H12 | Non-English tax titles | French Canadian abbreviations: TPS = GST, TVQ = QST | QCGST, QCQST, CAHST | "TPS/GST" @ 5.0%, "TVQ/QST" @ 9.975% | CA / QC / Montreal | QCGST, QCQST |

---

## LLM Error / Edge Cases

| # | Scenario | Expected Result |
|---|----------|-----------------|
| E1 | LLM API call fails | Logged as error; no matches applied; order unchanged |
| E2 | LLM returns no function call | Logged as error; no matches applied |
| E3 | Function call marked as failed | Logged as error; no matches applied |
| E4 | Malformed tax_line_id (not `ParentId-LineNo` format) | Skipped gracefully (Evaluate guard) |
| E5 | Non-numeric tax_line_id parts | Skipped gracefully (Evaluate returns false) |
| E6 | LLM returns jurisdiction_code > 10 chars | Truncated by CopyStr to 10 chars |
| E7 | LLM returns unknown confidence value | Treated as non-low (matched if jurisdiction exists) |
| E8 | Empty matches array | ApplyMatches returns false; no changes |
| E9 | Missing `matches` key in response | ApplyMatches returns false; no changes |
| E10 | Tax line ID points to non-existent record | TaxLine.Get fails; skipped; other matches still applied |

---

## End-to-End Flows

| # | Flow | Setup | Order Data | Expected End State |
|---|------|-------|------------|-------------------|
| F1 | Full auto-create | Enabled, Auto Create Juris.=Yes, Auto Areas=Yes | 3 tax lines: NY State, NYC City, MTA | 3 new jurisdictions (with Country/Region, Report-to=state), 3 tax details, 1 new tax area `SHPFY-MTATAX`, order has Tax Area Code + Tax Liable=Yes |
| F2 | Match only, no create | Enabled, Auto Create=No for both | 3 tax lines, all 3 jurisdictions + tax area pre-exist | Existing jurisdictions matched, existing tax area found and assigned |
| F3 | Partial match | Enabled, Auto Create Juris.=No, Auto Areas=Yes | 3 tax lines, only NYSTAX exists | Only NYSTAX matched; no tax area created (only 1 of 3 jurisdictions matched, so area wouldn't match expected set) |
| F4 | Re-import same order | Same as F1 | Same order imported again | Tax lines already matched, Tax Area already set; the agent skipped entirely (guard: Tax Area Code <> '') |
| F5 | Address-based match wins | Enabled | Order where MapTaxArea finds a match by address | Tax Area set by MapTaxArea; the agent never runs (guard: Tax Area Code <> '') |
| F6 | Sales document creation | After F1 completes | Create Sales Order from Shopify order | Sales Header has Tax Area Code = `SHPFY-MTATAX`, Tax Liable = Yes |

---

## Responsible AI (RAI)

The Tax Matching Agent is covered by Responsible AI tests — deterministic cross-prompt-injection
(XPIA) scenarios and dynamic **Red Team Scan** harms/jailbreak passes. Because this repository is
public, those tests and their adversarial datasets are **not** kept here: they live in the internal
NAV enlistment app **Shopify Connector NA AI Tests** (`App/Internal/Apps/ShopifyNAAITest`, ID range
134721-134732), which reuses this test app's library/verify and the matcher via `internalsVisibleTo`.
The mitigation under test is the security/guardrail prompt merged from Azure Key Vault at runtime
(secret `ShopifyTaxMatchingAgentSecurityPrompt`); the RAI tests mock the real guardrail, while the
public accuracy suites mock a benign placeholder.

---
## Automated Test Coverage

| Test codeunit | ID | Covers |
|---------------|----|--------|
| `Shpfy TMA Match Test` | 134717 | Jurisdiction matching (J*), creation (JC*), Tax Detail incl. rate-conflict TD3/RD1, shipping (ST*) — data-driven via the real LLM + `MatchTaxLines` |
| `Shpfy TMA Tax Area Test` | 134718 | Tax Area find/create (TA*) — `FindOrCreateTaxArea` |
| `Shpfy TMA Guard Test` | 134719 | Guard / early-exit (GD*, P1–P6) |
| `Shpfy TMA HITL Test` | 134716 | HITL-1…6 — marker propagation, `MarkReviewed`, `DisableForUser`, Activity Log helpers, `Capitalize` |
| `Shpfy TMA Rate Conflict Test` | 134720 | Rate-conflict recheck/flip on approve (RD1/RD5/RD6 core via `ReapplyFromAssignedLines`), including **shipping** tax lines (shipping bracket seeded from the shipping line's own rate; shipping rate conflict holds — S7); the Report-to rollup on re-apply (JC6 — `ReapplySetsReportToOnBlankJurisdictions` sets a blank Report-to on any matched jurisdiction incl. the state; `ReapplyPreservesExistingReportTo` leaves an admin-set one untouched); the creation gate RD3/RD4 + released cases (`IsSalesDocumentCreationHeld`), the business guards P4/tax-exempt/enabled (`ShouldAttemptMatch`), and Undo Approval RD9 (`UndoApproval`) |

The Responsible AI tests (XPIA + Red Team Scan harms/jailbreak — codeunits 134721-134724) are **not** in this public app; they live in the internal **Shopify Connector NA AI Tests** app (`App/Internal/Apps/ShopifyNAAITest`). See the Responsible AI section above.

**Verified manually / by TestPage (not unit-automated):** the page-property scenarios — Approve/Undo action visibility, BC-rate column + green/red styling (RD7), edit-revert-on-close (RD8), the **Use Shopify Rate** action (RD10), review-page close guard (HITL-13), page action captions (HITL-12), notification prompts (HITL-10/11), and Shop Card field enable/disable (SC-1…3) — as these are page-lifecycle/UI behaviors best exercised through the client.