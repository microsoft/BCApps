# Shopify Copilot Tax Matching — Architecture & Design

## Problem

When Shopify orders are imported into Business Central, each order carries free-text tax line descriptions (e.g. "NEW YORK STATE TAX at 4%"). BC requires structured Tax Jurisdiction codes and a Tax Area to apply correct tax rules, accounts, and reporting. The standard connector attempts an address-based lookup, but when that fails the Tax Area remains blank and must be filled manually.

This feature uses an LLM to automate the mapping from free-text Shopify tax descriptions to BC Tax Jurisdictions and Tax Areas.

## Design Principles

- **Non-invasive**: Ships as a separate app. Zero modifications to the standard Shopify connector — hooks in via integration events only.
- **Sync, invisible**: Runs inline during order import with no user interaction. No Copilot dialog, chat, or wizard.
- **Fail-safe**: If the LLM call fails or returns bad data, the order proceeds unchanged — same as if the feature were disabled.
- **Admin-controlled**: Every creation action (jurisdictions, areas) requires explicit opt-in per shop. The feature itself requires both a per-shop toggle and Copilot AI Capabilities activation.

## App Identity

| Property | Value |
|----------|-------|
| Name | Shopify Copilot Tax Matching |
| ID | a1b2c3d4-e5f6-47a8-9b0c-1d2e3f4a5b6c |
| Object ID Range | 30470-30499 |
| Version | 29.0.0.0 |
| Target | OnPrem |
| Dependency | Shopify Connector (`ec255f57-31d0-4ca2-b751-f2fa7c745abb`) |

## Object Inventory

| ID | Type | Name | Purpose |
|----|------|------|---------|
| 30470 | Codeunit | Shpfy Copilot Tax Register | Capability registration + `OnRegisterCopilotCapability` subscriber |
| 30471 | Codeunit | Shpfy Copilot Tax Matcher | Core: gather data, call AOAI, parse response, apply matches |
| 30472 | Codeunit | Shpfy Tax Area Builder | Find existing or create new Tax Area from matched jurisdictions |
| 30473 | Codeunit | Shpfy Copilot Tax Events | `OnAfterMapShopifyOrder` subscriber — orchestrates the flow |
| 30474 | Codeunit | Shpfy Tax Match Function | `AOAI Function` interface — tool definition + passthrough Execute |
| 30475 | Codeunit | Shpfy Copilot Tax Install | Install trigger → registers capability |
| 30470 | TableExtension | Shpfy Copilot Tax Shop | 4 config fields on `Shpfy Shop` |
| 30470 | PageExtension | Shpfy Copilot Tax Shop Card | "Copilot Tax Matching" group on Shop Card |
| 30470 | EnumExtension | Shpfy Copilot Tax Cap. | `"Shpfy Tax Matching"` value on `Copilot Capability` enum |
| 30470 | PermissionSet | Shpfy Copilot Tax Matching | RIMD on tax tables + all codeunits; includes `Shpfy - Edit` |

## Execution Flow

```
Shopify Order Import (standard connector)
  |
  v
OrderMapping.DoMapping()
  |-- MapHeaderFields() --> MapTaxArea()  (address-based lookup)
  |-- OnAfterMapShopifyOrder event fires
  |
  v
Copilot Tax Events (30473) — Event Subscriber
  |-- Guard: Result = true?
  |-- Guard: Tax Area Code still blank?
  |-- Guard: Shop.Get + Copilot Tax Matching Enabled?
  |-- Guard: Capability registered + active?
  |-- Telemetry: log start
  |
  v
Copilot Tax Matcher (30471) — MatchTaxLines()
  |-- Gather unmatched tax lines (Tax Jurisdiction Code = '')
  |-- Gather all BC Tax Jurisdictions (code + description)
  |-- Build ship-to address context (country, state, city)
  |-- Construct user prompt from template
  |
  v
CallLLMAndApplyMatches()
  |-- Load system prompt from .resources
  |-- Configure AOAI: GPT-4.1, temp=0, max_tokens=4096
  |-- Add tool: match_tax_jurisdictions (forced)
  |-- GenerateChatCompletion()
  |-- Parse function call response
  |
  v
ApplyMatches()
  |-- For each match in response:
  |     |-- Skip if jurisdiction_code empty or low-confidence + no auto-create
  |     |-- Parse tax_line_id -> ParentId + LineNo
  |     |-- Validate jurisdiction exists, or create if auto-create enabled
  |     |-- Write jurisdiction code to Shpfy Order Tax Line
  |     |-- Ensure Tax Detail record exists (when auto-creating)
  |-- FixReportToJurisdictions() if >1 jurisdiction matched
  |-- Return matched jurisdiction list
  |
  v
Tax Area Builder (30472) — FindOrCreateTaxArea()
  |-- Search all Tax Areas for exact jurisdiction set match
  |-- If found: use existing
  |-- If not found + Auto Create Tax Areas: create new area
  |     |-- Code: {NamingPattern}{LowestJurisdiction} (e.g. SHPFY-MTATAX)
  |     |-- Collision: append -2, -3, ... up to -999
  |     |-- Description: "Shopify - " + joined jurisdiction descriptions
  |     |-- Create Tax Area Lines with calculation order
  |-- Set OrderHeader."Tax Area Code" + "Tax Liable" = true
  |
  v
Order continues through standard import pipeline
```

## Data Sent to LLM

A single API call per order. The user prompt is assembled from this template:

```
Match the following Shopify tax lines to BC Tax Jurisdictions.

Tax lines:
[{id, title, rate_pct, channel_liable}, ...]

Available Tax Jurisdictions:
[{code, description}, ...]

Ship-to address:
{country, state, city}

Auto Create Tax Jurisdictions: Yes/No
```

**What is NOT sent**: customer names, monetary amounts, item details, street addresses, postal codes, or any PII.

## LLM Configuration

| Setting | Value |
|---------|-------|
| Model | GPT-4.1 Latest (`AOAIDeployments.GetGPT41Latest()`) |
| Temperature | 0 (deterministic) |
| Max tokens | 4096 |
| Tool choice | Forced — `match_tax_jurisdictions` |
| Infrastructure | Azure OpenAI via BC's `AzureOpenAI` codeunit |

## System Prompt Strategy

The system prompt (`ShpfyCopilotTaxMatching-SystemPrompt.md`) instructs the LLM to match using a four-tier strategy:

1. **Exact match** — title matches jurisdiction code or description (case-insensitive)
2. **Keyword/semantic match** — common tax abbreviation patterns (GST, PST, HST, MTA, NYC, etc.)
3. **Geographic context** — use ship-to address to disambiguate when multiple jurisdictions could match
4. **Auto-create** — when enabled and no match found, suggest a new code (max 10 chars, uppercase, no spaces)

## Tool Definition

The LLM must return a structured JSON object via function calling:

```json
{
  "matches": [
    {
      "tax_line_id": "12345-1",
      "jurisdiction_code": "NYSTAX",
      "confidence": "high|medium|low",
      "reason": "Brief explanation"
    }
  ]
}
```

Confidence levels drive business logic:
- `high` / `medium` — match applied if jurisdiction exists
- `low` — only applied if Auto Create Tax Jurisdictions is enabled (treated as a "suggestion" for a new jurisdiction)
- Empty `jurisdiction_code` — always skipped

## UI Surface

The only user-facing UI is a **"Copilot Tax Matching" group** on the Shopify Shop Card page:

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| Copilot Tax Matching Enabled | Boolean | false | Master toggle per shop |
| Auto Create Tax Jurisdictions | Boolean | false | Allow LLM-suggested new jurisdictions to be created |
| Auto Create Tax Areas | Boolean | true | Allow system to create Tax Area records |
| Tax Area Naming Pattern | Text[20] | `SHPFY-` | Prefix for auto-generated Tax Area codes |

There is no Copilot dialog, wizard, or chat interface. The feature operates silently during order import.

## Data Model

The feature reads from and writes to the standard Shopify connector tables and BC tax tables:

### Connector tables (read/write)

| Table | Field | Usage |
|-------|-------|-------|
| Shpfy Order Header | Tax Area Code (1070) | Written by Tax Area Builder |
| Shpfy Order Header | Tax Liable (1080) | Set to `true` by Tax Area Builder |
| Shpfy Order Tax Line | Tax Jurisdiction Code (10) | Written by Matcher for each matched line |
| Shpfy Shop | 4 config fields (30470-30473) | Read by Events + Matcher + Builder |

### BC tax tables (read/write when auto-creating)

| Table | Usage |
|-------|-------|
| Tax Jurisdiction | Read for matching; created when auto-create enabled |
| Tax Area | Read for exact-match search; created when auto-create enabled |
| Tax Area Line | Read/created as part of Tax Area |
| Tax Detail | Created for new jurisdictions (rate from Shopify tax line) |

## Integration Point

The feature hooks into the standard connector via a single integration event:

```al
// In Shpfy Order Events (30162) — standard connector
[IntegrationEvent(false, false)]
internal procedure OnAfterMapShopifyOrder(var ShopifyOrderHeader: Record "Shpfy Order Header"; Result: Boolean)
```

This event fires after `OrderMapping.DoMapping()` completes. The standard connector's `MapTaxArea` runs first (address-based lookup). Copilot only activates if that lookup didn't find a Tax Area.

## Capability Registration

Registration follows the standard BC Copilot pattern:

1. **Install codeunit** (30475) — calls `RegisterCopilotCapability()` on `OnInstallAppPerDatabase`
2. **Register codeunit** (30470) — subscribes to `OnRegisterCopilotCapability` on the Copilot AI Capabilities page, so the capability is also registered when the admin visits that page
3. The capability appears as **"Shopify Tax Jurisdiction Matching with AI"** in the Copilot AI Capabilities page

## Telemetry

| Event ID | Level | Location | Trigger |
|----------|-------|----------|---------|
| 0000SH1 | Uptake: Set up | Register | App installed |
| 0000SH2 | Uptake: Used | Matcher | MatchTaxLines called |
| 0000SH3 | Error | Matcher | AOAI call failed (status code + error) |
| 0000SH4 | Error | Matcher | No function call in LLM response |
| 0000SH5 | Error | Matcher | Function execution failed |
| 0000SH6 | Normal | Matcher | Low-confidence match skipped |
| 0000SH7 | Warning | Matcher | Jurisdiction not found, auto-create disabled |
| 0000SH8 | Normal | Events | Match starting for order |
| 0000SH9 | Usage | Events | Match successful |

## Test App

A separate test app (`ShpfyCopilotTaxMatching/test/`, ID range 30490-30499) uses the **AI Test Toolkit** framework:

- Data-driven YAML scenarios iterated by the framework
- Real LLM calls (no mocking) for matching tests
- Test output logged via `AITTestContext.SetQueryResponse()` for eval spreadsheets
- Categories: Jurisdiction Matching (J, H), Jurisdiction Creation (JC), Tax Detail (TD), Tax Area (TA), Guard (G), End-to-End (F)

See `TestMatrix.md` for the full test scenario inventory.
