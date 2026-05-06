# Shopify Copilot Tax Matching — Architecture & Design

## Problem

When Shopify orders are imported into Business Central, each order carries free-text tax line descriptions (e.g. "NEW YORK STATE TAX at 4%"). BC requires structured Tax Jurisdiction codes and a Tax Area to apply correct tax rules, accounts, and reporting. The standard connector attempts an address-based lookup, but when that fails the Tax Area remains blank and must be filled manually.

This feature uses an LLM to automate the mapping from free-text Shopify tax descriptions to BC Tax Jurisdictions and Tax Areas.

## Design Principles

- **Minimal footprint**: Ships as a separate app. Requires a small set of additions to the standard connector (integration event, Tax Jurisdiction Code field on tax lines, Tax Area/Tax Liable/Tax Exempt fields on order header, MapTaxArea procedure). The Copilot app hooks in via the integration event.
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
| 30476 | Codeunit | Shpfy Copilot Tax Notify | Owns the non-blocking review notification: queue, send-on-page-open, action handlers |
| 30477 | Codeunit | Shpfy CT Activity Log | Wraps `Activity Log Builder` chain for per-line + per-area AI audit entries |
| 30476 | Table | Shpfy Copilot Tax Notification | Per-(Sales Header, user) review-prompt log; key `(Sales Header SystemId, User Id)` |
| 30476 | TableExtension | Shpfy CT Order Header | Two markers: `Copilot Tax Match Applied` (set by matcher) + `Copilot Tax Match Reviewed` (set by Approve action) on `Shpfy Order Header` |
| 30477 | TableExtension | Shpfy CT Sales Header | `Copilot Tax Match Applied` Boolean marker on `Sales Header` |
| 30480 | TableExtension | Shpfy CT Order Tax Line | `Tax Jurisdiction Code` (Code[10], `TableRelation = "Tax Jurisdiction"`) — moved out of the connector since the connector itself does not read or write it |
| 30470 | TableExtension | Shpfy Copilot Tax Shop | 5 config fields on `Shpfy Shop` (incl. `Tax Match Review Required` for blocking mode) |
| 30478 | PageExtension | Shpfy CT Order Tax Lines | Adds the Tax Jurisdiction Code column to the standalone Tax Lines list, visible only when the parent order's shop has Copilot Tax Matching enabled |
| 30479 | Page (ListPart) | Shpfy CT Order Tax Lines Part | Tax lines list embedded as a subform on the Shopify Order Card so the platform AI confidence indicator renders on the Tax Jurisdiction Code cell |
| 30479 | PageExtension | Shpfy CT Order | Embeds the tax lines ListPart + adds the **Approve Copilot Tax Match** action that releases an order from review-blocked state |
| 30476 | PageExtension | Shpfy CT Sales Order | Read-only badge field, "Show Copilot Tax Decisions" action, `OnAfterGetCurrRecord` notification trigger |

## Execution Flow

```
Shopify Order Import (standard connector)
  |
  v
OrderMapping.DoMapping()
  |-- MapHeaderFields() or MapB2BHeaderFields()
  |     |-- MapTaxArea() (address-based lookup, respects Tax Exempt)
  |-- Map order lines (items, tips, gift cards)
  |-- OnAfterMapShopifyOrder event fires
  |
  v
Copilot Tax Events (30473) — Event Subscriber
  |-- Guard: Result = true?
  |-- Guard: Tax Area Code still blank?
  |-- Guard: Tax Exempt = false?
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
  |     |-- Ensure Tax Detail bracket valid at the order date exists (always; rate-mismatch is logged, never overridden)
  |     |     |-- Once for the item line's Tax Group Code (Item.Tax Group Code)
  |     |     |-- Once for the Shop's Shipping Charges Account Tax Group Code (G/L Account.Tax Group Code), at the same Shopify rate
  |-- FixReportToJurisdictions() if >1 jurisdiction matched
  |-- Return matched jurisdiction list
  |
  v
Tax Area Builder (30472) — FindOrCreateTaxArea()
  |-- Search all Tax Areas for exact jurisdiction set match
  |-- If found: use existing (WasCreated = false)
  |-- If not found + Auto Create Tax Areas: create new area (WasCreated = true)
  |     |-- Code: {NamingPattern}{LowestJurisdiction} (e.g. SHPFY-MTATAX)
  |     |-- Collision: append -2, -3, ... up to -999
  |     |-- Description: "Shopify - " + joined jurisdiction descriptions
  |     |-- Create Tax Area Lines with calculation order
  |-- Set OrderHeader."Tax Area Code" + "Tax Liable" = true
  |
  v
Copilot Tax Events (30473) — HITL writes (after Tax Area resolved)
  |-- Set OrderHeader."Copilot Tax Match Applied" = true
  |-- Shpfy CT Activity Log (30477):
  |     |-- LogPerLineEntries — one Activity Log entry per matched tax line
  |     |     (anchor = Shpfy Order Tax Line, field "Tax Jurisdiction Code")
  |     |-- LogTaxAreaEntry — one Activity Log entry on the Order Header
  |           (anchor = Shpfy Order Header, field "Tax Area Code")
  |
  v
Order continues through standard import pipeline
  |
  v
ShpfyProcessOrder.CreateHeaderFromShopifyOrder()
  |-- Fires OnBeforeCreateSalesHeader event
        |
        v
      Copilot Tax Events (30473) — OnBeforeCreateSalesHeader subscriber [BLOCKING GATE]
        |-- If Shop."Tax Match Review Required" AND
        |     OrderHeader."Copilot Tax Match Applied" AND
        |     NOT OrderHeader."Copilot Tax Match Reviewed":
        |        |-- Handled := true  (connector skips Sales Doc creation)
        |        |-- Order stays in pending-review state until user clicks
        |              Approve Copilot Tax Match on the Shpfy Order page
  |
  |  (only when Handled = false — i.e. blocking off, or user already approved)
  v
  ShpfyProcessOrder propagates Tax Area Code + Tax Liable to Sales Header,
  fires OnAfterCreateSalesHeader event
        |
        v
      Copilot Tax Events (30473) — OnAfterCreateSalesHeader subscriber
        |-- If OrderHeader."Copilot Tax Match Applied" -> true:
        |     |-- Set SalesHeader."Copilot Tax Match Applied" = true
        |     |-- If NOT OrderHeader."Copilot Tax Match Reviewed":
        |           |-- Shpfy Copilot Tax Notify (30476):
        |                 QueueNotificationFor — insert one row into
        |                 Shpfy Copilot Tax Notification keyed
        |                 (SalesHeader.SystemId, UserId())
        |     (in blocking mode the user just approved — no redundant prompt)
        |
        v
      User opens Sales Order page → PageExt 30476 OnAfterGetCurrRecord
        |-- If marker set + row not Reviewed + MyNotifications enabled:
        |     |-- Send one-time notification with three actions
        |           (Show Copilot Tax Decisions / Mark as reviewed / Don't show again)
```

## Human-in-the-loop

The matcher runs synchronously during order import without prompting the user, but every Copilot decision is recorded, customer-configurable to block document creation, and surfaced for human review. Four pillars:

1. **Audit trail** — `Shpfy CT Activity Log` (30477) writes a System Application `Activity Log` entry (Type = `AI`) for each matched tax line and one for the resulting Tax Area. Each entry carries the LLM confidence (`Low`/`Medium`/`High`), the LLM's reasoning text, and a drill-back URL to the Tax Jurisdiction or Tax Area card. The platform automatically renders a confidence indicator next to the field on the originating record (Shpfy Order Tax Line for per-line, Shpfy Order Header for per-area).

2. **Persistent badge** — a `Copilot Tax Match Applied` Boolean on `Shpfy Order Header` (field 30476, set by `ShpfyCopilotTaxEvents` after `FindOrCreateTaxArea` succeeds) propagates to `Sales Header` (field 30476) via the existing `OnAfterCreateSalesHeader` event in `ShpfyOrderEvents` (line 161). The Sales Order page extension shows this as a read-only field (`Importance = Additional`).

3. **Configurable blocking review (default on)** — a per-shop `Tax Match Review Required` Boolean (field 30474, default `true`) and a per-order `Copilot Tax Match Reviewed` Boolean (field 30477) gate Sales Document creation. `ShpfyCopilotTaxEvents` subscribes to `OnBeforeCreateSalesHeader` and sets `Handled := true` when the shop requires review, the order has the marker, and the user has not yet approved — so the connector skips Sales Doc creation. The Shpfy Order page exposes an **Approve Copilot Tax Match** action (visible only when blocking is on, marker is set, and not yet reviewed) that flips `Copilot Tax Match Reviewed` to `true`. On the next process run (auto or manual) the order proceeds. Customers can clear the shop toggle to opt into non-blocking mode.

4. **Active notification** (non-blocking mode only) — when the marker propagates onto a Sales Header for an order the user has *not* already approved, `ShpfyCopilotTaxNotify` queues a row in the `Shpfy Copilot Tax Notification` table keyed on `(SalesHeader.SystemId, UserId())`. The Sales Order page extension's `OnAfterGetCurrRecord` trigger fires a non-blocking BC `Notification` ("Copilot set Tax Area %1 on this Shopify order. Review before posting.") with three actions:
   - **Show Copilot Tax Decisions** — opens the originating Shopify order, where platform-rendered AI confidence indicators are visible on each Copilot-matched field.
   - **Mark as reviewed** — flips `Reviewed` on the row so the prompt does not fire again for this Sales Header for this user.
   - **Don't show again** — calls `MyNotifications.Disable` for the feature notification GUID, suppressing the prompt across all Sales Orders for this user.

   When the user approved the match in blocking mode (i.e. `OrderHeader."Copilot Tax Match Reviewed" = true`), the notification is suppressed: the user has already done the review and the prompt would be noise.

For safety, `ShpfyCopilotTaxEvents.OnAfterMapShopifyOrder` resets both the marker and the reviewed flag to `false` before each matcher run so re-matching (after a user manually clears Tax Area Code on the Shpfy Order Header) cannot leave stale flags from a prior run.

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

The Copilot's matching itself runs silently during order import — no dialog, wizard, or chat interface. The visible surfaces are:

**Shopify Shop Card** — a "Copilot Tax Matching" group with the per-shop configuration:

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| Copilot Tax Matching Enabled | Boolean | false | Master toggle per shop |
| Auto Create Tax Jurisdictions | Boolean | false | Allow LLM-suggested new jurisdictions to be created |
| Auto Create Tax Areas | Boolean | true | Allow system to create Tax Area records |
| Tax Area Naming Pattern | Text[20] | `SHPFY-` | Prefix for auto-generated Tax Area codes |
| Copilot Tax Match Review Required | Boolean | true | When enabled, the Sales Document is not created until a user clicks **Approve Copilot Tax Match** on the Shopify order. Default is on per RAI guidance; clear it to opt into non-blocking mode. |

**Shopify Order page** — adds an **Approve Copilot Tax Match** action (visible only when blocking is on, the marker is set, and the order has not yet been approved). Clicking flips `Copilot Tax Match Reviewed` so the next process run can create the Sales Document.

**BC Sales Order page** — the HITL review surface:

- Read-only `Copilot Tax Match Applied` field (next to Tax Liable, `Importance = Additional`).
- "Show Copilot Tax Decisions" navigation action (visible when the marker is set) that opens the originating Shopify order.
- One-time non-blocking notification on first open of the Sales Order, with actions to drill in, mark reviewed, or suppress per-user.

## Data Model

The feature reads from and writes to the standard Shopify connector tables and BC tax tables:

### Connector tables (read/write)

| Table | Field | Usage |
|-------|-------|-------|
| Shpfy Order Header | Tax Area Code (1070) | Written by Tax Area Builder |
| Shpfy Order Header | Tax Liable (1080) | Set to `true` by Tax Area Builder |
| Shpfy Order Header | Tax Exempt (1090) | Imported from Shopify `taxExempt` field; guards skip matching |
| Shpfy Order Tax Line | Tax Jurisdiction Code (30476, via Copilot TableExt) | Written by Matcher for each matched line |
| Shpfy Refund Header | Tax Area Code (110) | FlowField → Order Header; shown on Refund page |
| Shpfy Refund Header | Tax Liable (111) | FlowField → Order Header; inherited by credit memo |
| Shpfy Refund Header | Tax Exempt (112) | FlowField → Order Header; shown on Refund page |
| Shpfy Shop | 4 config fields (30470-30473) | Read by Events + Matcher + Builder |

### BC tax tables

| Table | Usage |
|-------|-------|
| Tax Jurisdiction | Read for matching; created when `Auto Create Tax Jurisdictions` enabled |
| Tax Area | Read for exact-match search; created when `Auto Create Tax Areas` enabled |
| Tax Area Line | Read/created as part of Tax Area |
| Tax Detail | Seeded twice per matched tax line: once for the item line's Tax Group Code (`Item.Tax Group Code`) and once for the Shop's `Shipping Charges Account` Tax Group Code (`G/L Account.Tax Group Code`). Both calls use Shopify's reported rate from the matched tax line — the assumption is that Shopify charges the same per-jurisdiction rate to items and shipping in essentially all real configurations, so the item-line rate is a valid source for the shipping bracket. For each seed, look for the latest Tax Detail with `Effective Date <= order date` for the jurisdiction + tax group + tax type. If none exists, insert a new one at the order date with Shopify's rate. If one exists with the same rate, do nothing. If one exists with a different rate, leave it untouched and log a rate-divergence warning (telemetry `0000SHK`) — admin owns rate updates. Empty Tax Group Code is a valid value for both seeds (an item or shipping account with no group results in a `(Jurisdiction × '')` Tax Detail row). The shipping seed is skipped only when the Shop has no `Shipping Charges Account` configured at all (no target). |

## Integration Points

The feature hooks into the standard connector via three existing integration events on `Shpfy Order Events` (codeunit 30162):

```al
[IntegrationEvent(false, false)]
internal procedure OnAfterMapShopifyOrder(var ShopifyOrderHeader: Record "Shpfy Order Header"; Result: Boolean)

[IntegrationEvent(false, false)]
internal procedure OnBeforeCreateSalesHeader(ShopifyOrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header"; var LastCreatedDocumentId: Guid; var Handled: Boolean)

[IntegrationEvent(false, false)]
internal procedure OnAfterCreateSalesHeader(OrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header")
```

- `OnAfterMapShopifyOrder` fires after `OrderMapping.DoMapping()` completes; the Copilot subscriber runs the matcher (the connector's `MapTaxArea` runs first via address-based lookup; Copilot only activates if that lookup didn't find a Tax Area).
- `OnBeforeCreateSalesHeader` fires at the top of `ShpfyProcessOrder.CreateHeaderFromShopifyOrder()`; the Copilot subscriber sets `Handled := true` to skip Sales Doc creation when the shop requires review and the order hasn't yet been approved.
- `OnAfterCreateSalesHeader` fires after the connector's existing Tax Area Code propagation; the Copilot subscriber uses it to propagate the marker flag and queue the review notification.

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
| 0000SHA | Usage | Events | Copilot Tax Match Applied marker set on Order Header |
| 0000SHB | Usage | Events | Marker propagated to Sales Header |
| 0000SHC | Usage | Notify | Notification row queued |
| 0000SHD | Usage | Notify | Notification sent to user |
| 0000SHE | Usage | Notify | User clicked "Show Copilot Tax Decisions" |
| 0000SHF | Usage | Notify | User marked notification reviewed |
| 0000SHH | Usage | Notify | User chose "Don't show again" |
| 0000SHI | Uptake: Used | Activity Log | Per-tax-line entry written |
| 0000SHJ | Uptake: Used | Activity Log | Per-tax-area entry written |
| 0000SHK | Warning | Matcher | Existing Tax Detail rate differs from Shopify's reported rate (existing left untouched) |
| 0000SHL | Usage | Events | Sales Document creation blocked pending Copilot tax match review |

## Test App

A separate test app (`CopilotTaxMatching/test/`, ID range 30490-30499) uses the **AI Test Toolkit** framework:

- Data-driven YAML scenarios iterated by the framework
- Real LLM calls (no mocking) for matching tests
- Test output logged via `AITTestContext.SetQueryResponse()` for eval spreadsheets
- Categories: Jurisdiction Matching (J, H), Jurisdiction Creation (JC), Tax Detail (TD), Shipping Tax (S), Tax Area (TA), Guard (G), End-to-End (F)

See `TestMatrix.md` for the full test scenario inventory.

## Refund Support

Refunds inherit all tax context from their parent order — no separate LLM call or tax matching is performed for refunds.

### Data flow
- **Refund Header** has FlowFields (110-112) that look up Tax Area Code, Tax Liable, and Tax Exempt from the linked `Shpfy Order Header` via `Order Id`. No data duplication.
- **Credit memo creation** (`ShpfyCreateSalesDocRefund`) reads Tax Area Code and Tax Liable from the original order header and validates both on the Sales Credit Memo header.
- **Tax-exempt orders**: If the parent order is tax exempt, the credit memo's Tax Liable stays false (no Tax Area Code to trigger the block).

### UI
- The **Refund page** shows a "Tax" group with Tax Area Code, Tax Liable, and Tax Exempt (read-only, inherited from order).
- A **"Tax Lines"** navigation action opens the existing `Shpfy Order Tax Lines` page filtered to the parent order's lines, so users can see the tax jurisdiction breakdown without leaving the refund.

### Why no Copilot for refunds
The Copilot event subscriber (`ShpfyCopilotTaxEvents`) only subscribes to `OnAfterMapShopifyOrder`. Refunds don't go through order mapping — they reference an already-processed order. If the order's tax was matched by Copilot, that data is already on the order and flows through to the refund via FlowFields.
