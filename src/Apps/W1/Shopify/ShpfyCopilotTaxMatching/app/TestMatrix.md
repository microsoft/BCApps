# Shopify Copilot Tax Matching — Test Matrix

## Setup Variations

| Setting | Values |
|---------|--------|
| Copilot Tax Matching Enabled | Yes / No |
| Auto Create Tax Jurisdictions | Yes / No |
| Auto Create Tax Areas | Yes / No |
| Tax Area Naming Pattern | `SHPFY-` / Custom / Blank |

## Pre-conditions

| ID | Condition | Description |
|----|-----------|-------------|
| P1 | Copilot disabled | Shop has Copilot Tax Matching Enabled = No |
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

---

## Tax Detail Scenarios (Auto Create Jurisdictions = Yes)

| # | Scenario | Existing Tax Details | Expected Result |
|---|----------|---------------------|-----------------|
| TD1 | No existing detail | None for this jurisdiction + tax group | Tax Detail created with rate from tax line |
| TD2 | Exact detail exists | Same jurisdiction, tax group, and rate | No duplicate created |
| TD3 | Same jurisdiction, different rate | Detail exists with different Tax Below Maximum | New Tax Detail created for the new rate |
| TD4 | Same jurisdiction, different tax group | Detail exists with different Tax Group Code | New Tax Detail created for the new tax group |
| TD5 | Item has no tax group | Order line item has blank Tax Group Code | Tax Detail created with blank Tax Group Code |
| TD6 | Order line has no item | Item No. is blank on order line | Tax Detail created with blank Tax Group Code |
| TD7 | Multiple tax lines, same jurisdiction | Two lines with different rates, same jurisdiction | Two Tax Detail records created |
| TD8 | Effective date | Order Document Date = 2026-01-15 | Tax Detail has Effective Date = 2026-01-15 |

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
| G1 | Copilot disabled on shop | No LLM call; order unchanged |
| G2 | Copilot capability not registered | No LLM call; order unchanged |
| G3 | Copilot capability inactive | No LLM call; order unchanged |
| G4 | Tax Area already set by MapTaxArea | Copilot skipped; existing Tax Area kept |
| G5 | No order lines | MatchTaxLines returns false |
| G6 | All tax lines already have jurisdiction codes | MatchTaxLines returns false (no unmatched lines) |
| G7 | Order import Result = false | Event subscriber exits immediately |

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
| F4 | Re-import same order | Same as F1 | Same order imported again | Tax lines already matched, Tax Area already set; Copilot skipped entirely (guard: Tax Area Code <> '') |
| F5 | Address-based match wins | Enabled | Order where MapTaxArea finds a match by address | Tax Area set by MapTaxArea; Copilot never runs (guard: Tax Area Code <> '') |
| F6 | Sales document creation | After F1 completes | Create Sales Order from Shopify order | Sales Header has Tax Area Code = `SHPFY-MTATAX`, Tax Liable = Yes |
