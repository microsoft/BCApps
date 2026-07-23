# Shopify Tax Matching Agent — Architecture & Design

## Problem

When Shopify orders are imported into Business Central, each order carries free-text tax line descriptions (e.g. "NEW YORK STATE TAX at 4%"). BC requires structured Tax Jurisdiction codes and a Tax Area to apply correct tax rules, accounts, and reporting. The standard connector attempts an address-based lookup, but when that fails the Tax Area remains blank and must be filled manually.

This feature uses an LLM to automate the mapping from free-text Shopify tax descriptions to BC Tax Jurisdictions and Tax Areas.

## Design Principles

- **Minimal footprint**: Ships as a separate app. Requires a small set of additions to the standard connector (integration event, Tax Jurisdiction Code field on tax lines, Tax Area/Tax Liable/Tax Exempt fields on order header, MapTaxArea procedure). The Tax Matching Agent app hooks in via the integration event.
- **Sync, invisible**: Runs inline during order import with no user interaction. No AI dialog, chat, or wizard.
- **Fail-safe**: If the LLM call fails or returns bad data, the order proceeds unchanged — same as if the feature were disabled.
- **Admin-controlled**: Every creation action (jurisdictions, areas) requires explicit opt-in per shop. The feature itself requires both a per-shop toggle and Copilot AI Capabilities activation.

## App Identity

Tax Matching Agent ships as a **feature inside the `Shopify Connector NA` app** — a North America
connector-localization container (mirrors *Shopify Connector BE*) that can host additional NA-only
features. The feature source lives under `src/Tax Matching Agent/`. Built, tested and published **US
only** for now (add CA/MX when supported). The main Shopify Connector shows a notification prompting
US environments to install this app (see *Localization promotion* below).

| Property | Value |
|----------|-------|
| App name | Shopify Connector NA |
| App ID | a1b2c3d4-e5f6-47a8-9b0c-1d2e3f4a5b6c |
| Folder | `src/Apps/NA/ShopifyNA` (feature under `app/src/Tax Matching Agent`) |
| Countries | US (add CA/MX when supported) |
| Object ID Range | 30470-30499 |
| Version | 29.0.0.0 |
| Target | OnPrem |
| Dependency | Shopify Connector (`ec255f57-31d0-4ca2-b751-f2fa7c745abb`) |

## Object Inventory

| ID | Type | Name | Purpose |
|----|------|------|---------|
| 30470 | Codeunit | Shpfy TMA Register | Capability registration + `OnRegisterCopilotCapability` subscriber |
| 30471 | Codeunit | Shpfy TMA Matcher | Core: gather data, call AOAI, parse response, apply matches |
| 30472 | Codeunit | Shpfy Tax Area Builder | Find existing or create new Tax Area from matched jurisdictions |
| 30473 | Codeunit | Shpfy TMA Events | `OnAfterMapShopifyOrder` subscriber — orchestrates the flow |
| 30474 | Codeunit | Shpfy Tax Match Function | `AOAI Function` interface — tool definition + passthrough Execute |
| 30475 | Codeunit | Shpfy TMA Install | Install trigger → registers capability (per database) + invokes the tag-guarded Shop-defaults backfill (per company) |
| 30478 | Codeunit | Shpfy TMA Upgrade | Upgrade trigger + shared `BackfillShopDefaults` — sets the tax config defaults on existing shops, guarded by an upgrade tag so it runs once per company (called from both install and upgrade) |
| 30470 | TableExtension | Shpfy TMA Shop | 4 config fields on `Shpfy Shop` |
| 30470 | PageExtension | Shpfy TMA Shop Card | "Tax Matching Agent" group on Shop Card |
| 30470 | EnumExtension | Shpfy TMA Cap. | `"Shpfy Tax Matching"` value on `Copilot Capability` enum |
| 30470 | PermissionSet | Shpfy TMA Matching | RIMD on tax tables + all codeunits; includes `Shpfy - Edit` |
| 30476 | Codeunit | Shpfy TMA Notify | Owns both review notifications (Sales Order + Shopify Order) and the review-page drills (`RunReviewForSalesHeader`, `OpenReviewForOrder`, single `RunReviewPage`). Notifications are stateless — no table |
| 30477 | Codeunit | Shpfy TMA Activity Log | Wraps `Activity Log Builder` chain for per-line + per-area AI audit entries |
| 30476 | TableExtension | Shpfy TMA Order Header | Two markers: `Tax Match Applied` (set by matcher) + `Tax Match Reviewed` (set by the review page's Approve action) on `Shpfy Order Header` |
| 30477 | TableExtension | Shpfy TMA Sales Header | `Tax Match Applied` Boolean marker on `Sales Header` |
| 30480 | TableExtension | Shpfy TMA Order Tax Line | `Tax Jurisdiction Code` (Code[10], `TableRelation = "Tax Jurisdiction"`) — moved out of the connector since the connector itself does not read or write it |
| 30470 | TableExtension | Shpfy TMA Shop | 5 config fields on `Shpfy Shop` (incl. `Tax Match Review Required` for blocking mode) |
| 30478 | PageExtension | Shpfy TMA Order Tax Lines | Adds the Tax Jurisdiction Code column to the standalone Tax Lines list, visible only when the parent order's shop has Tax Matching Agent enabled |
| 30471 | Page (Card) | Shpfy TMA Review | Per-order review summary: resolved Tax Area (with AI confidence indicator), ship-to context, and the tax lines ListPart (each line shows the item it taxes). Hosts the **Approve** action that sets `Tax Match Reviewed` |
| 30479 | Page (ListPart) | Shpfy TMA Order Tax Lines Part | Tax lines list embedded as a subform on the **Tax Match Review page** so the platform AI confidence indicator renders on the Tax Jurisdiction Code cell; `SetTaxLineFilter` scopes it to one order |
| 30479 | PageExtension | Shpfy TMA Order | Adds the review entry action (AI `SparkleFilled` icon) that opens the review page — captioned **Review and Approve Tax Match** while approval is pending, else **Review Tax Match** — and fires the actionable order-page review notification |
| 30476 | PageExtension | Shpfy TMA Sales Order | Read-only badge field, **Review Tax Match** action (opens the review page), `OnAfterGetCurrRecord` notification trigger |

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
TMA Events (30473) — Event Subscriber
  |-- Guard: Result = true?
  |-- Guard: Tax Area Code still blank?
  |-- Guard: Tax Exempt = false?
  |-- Guard: Shop.Get + Tax Matching Agent Enabled?
  |-- Guard: Capability registered + active?
  |-- Telemetry: log start
  |
  v
Tax Matcher (30471) — MatchTaxLines()
  |-- Walk the order's tax lines — BOTH product-line tax lines (Parent Id = order line
  |   "Line Id") AND shipping-charge tax lines (Parent Id = "Shopify Shipping Line Id",
  |   iterated from Shpfy Order Shipping Charges):
  |     |-- Tax Jurisdiction Code = '' -> send to the LLM (unmatched)
  |     |-- Tax Jurisdiction Code set (from a prior run) -> carry into MatchedJurisdictions
  |         so the Tax Area is built from the order's COMPLETE jurisdiction set on a re-run
  |   (product lines first to preserve state -> ... -> city ordering; shipping jurisdictions
  |    usually duplicate product ones and are de-duplicated)
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
  |     |-- ApplyAssignedJurisdiction(): write jurisdiction code to Shpfy Order Tax Line
  |     |   (the match is always applied — the jurisdiction is correct) and:
  |     |     |-- Resolve the tax line's Tax Group Code by owner: a product-line tax line uses
  |     |     |   the order line item's Tax Group Code; a shipping-charge tax line uses the Shop's
  |     |     |   Shipping Charges Account Tax Group Code.
  |     |     |-- Rate-conflict check: if a Tax Detail bracket valid at the order date already
  |     |     |   EXISTS for (jurisdiction × that tax group) with a DIFFERENT rate than Shopify's,
  |     |     |   set HasRateConflict, log telemetry 0000UMR + a per-line "matched, but rate
  |     |     |   differs" entry, and leave the existing (admin-maintained) rate untouched. This
  |     |     |   applies equally to product-line and shipping-charge tax lines.
  |     |     |-- Otherwise: seed a Tax Detail for (jurisdiction × that tax group) at Shopify's
  |     |         rate if none exists. Each tax line (product or shipping) seeds its own bracket
  |     |         from its OWN rate — there is no product-line-derived shipping inference.
  |-- FixReportToJurisdictions() if >1 jurisdiction matched — points every matched jurisdiction
  |     whose Report-to is still blank at the state (this covers jurisdictions auto-created this
  |     run AND pre-existing ones that never had a rollup target, including the state itself,
  |     which reports to itself), so the Tax Area rolls up correctly; a jurisdiction that already
  |     has a Report-to (admin-maintained hierarchy) is left untouched
  |-- Return matched jurisdiction list + HasRateConflict
  |
  v
TMA Events (30473):
  |-- (A rate conflict no longer blocks matching — the jurisdiction is applied and the Tax
  |   Area is built as usual; the conflict is recorded on the order to force review.)
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
TMA Events (30473) — HITL writes (after Tax Area resolved)
  |-- Set OrderHeader."Tax Match Applied" = true
  |-- Set OrderHeader."Tax Rate Conflict" = HasRateConflict
  |     (a conflict forces review in BOTH modes; telemetry 0000UMF logged)
  |-- Shpfy TMA Activity Log (30477):
  |     |-- LogPerLineEntries — one Activity Log entry per tax line (matched, or on a rate
  |     |     conflict a "matched, but rate differs" entry explaining the conflict)
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
      TMA Events (30473) — OnBeforeCreateSalesHeader subscriber [BLOCKING GATE]
          |-- If OrderHeader."Tax Match Applied" AND
          |     NOT OrderHeader."Tax Match Reviewed" AND
          |     (Shop."Tax Match Review Required" OR OrderHeader."Tax Rate Conflict"):
          |        |-- Tax Rate Conflict is the stored flag (field 30478), set at match
          |        |     time when a matched line's BC Tax Detail rate differs from Shopify's and
          |        |     refreshed on Approve — the single source of truth for the whole feature.
          |        |-- Handled := true  (connector skips Sales Doc creation)
          |        |-- A rate-conflict order is held in BOTH modes; a normal successful
          |              match is held only when the shop requires review.
          |        |-- Order stays in pending-review state until the user opens the
          |              Tax Match Review page (via the Shpfy Order page action
          |              or the order-page notification) and clicks Approve
  |
  |  (only when Handled = false — i.e. blocking off, or user already approved)
  v
  ShpfyProcessOrder propagates Tax Area Code + Tax Liable to Sales Header,
  fires OnAfterCreateSalesHeader event
        |
        v
      TMA Events (30473) — OnAfterCreateSalesHeader subscriber
        |-- If OrderHeader."Tax Match Applied" -> true:
        |     |-- Set SalesHeader."Tax Match Applied" = true
        |           (badge only — no notification queued; the Sales Order prompt
        |            is derived live on page open)
        |
        v
  Review surfaces (all open the Tax Match Review page 30471):
    - Shpfy Order page (30479): review entry action (Review and Approve
      Tax Match when approval is pending, else Review Tax
      Match) + an
      actionable "Review" notification fired on open (once per order/session)
      while the order is matched and not yet reviewed.
    - Sales Order page (30476): OnAfterGetCurrRecord sends one notification
      (once per session) when the Sales Header is marked and the originating
      order is not yet reviewed — Show Tax Match Decisions / Mark as reviewed /
      Don't show again. No table: the prompt reads the order's
      Tax Match Reviewed flag + the per-user My Notifications toggle.
    Approving on the review page (or Mark as reviewed) sets the order's
    Tax Match Reviewed flag — the single source of truth that stops
    both prompts.
```

## Human-in-the-loop

The matcher runs synchronously during order import without prompting the user, but every agent decision is recorded, customer-configurable to block document creation, and surfaced for human review. The primary review surface is the **Tax Match Review page** (page 30471) — a per-order Card that shows the resolved Tax Area (with the platform AI confidence indicator), the ship-to context the Tax Matching Agent reasoned over, and the tax lines with their matched Tax Jurisdiction Codes. Both entry points below open it. Five pillars:

1. **Audit trail** — `Shpfy TMA Activity Log` (30477) writes a System Application `Activity Log` entry (Type = `AI`) for each matched tax line and one for the resulting Tax Area. Each entry carries the LLM confidence (`Low`/`Medium`/`High`), the LLM's reasoning text, and a drill-back URL to the Tax Jurisdiction or Tax Area card. The platform automatically renders a confidence indicator next to the field on the originating record (Shpfy Order Tax Line for per-line — shown in the review page's tax lines ListPart; Shpfy Order Header for per-area — shown on the review page's Tax Area Code field).

2. **Persistent badge** — a `Tax Match Applied` Boolean on `Shpfy Order Header` (field 30476, set by `ShpfyTMAEvents` after `FindOrCreateTaxArea` succeeds) propagates to `Sales Header` (field 30476) via the existing `OnAfterCreateSalesHeader` event in `ShpfyOrderEvents`. The Sales Order page extension shows this as a read-only field (`Importance = Additional`) plus a **Review Tax Match** action that opens the review page.

3. **Review page** (page 30471) — the single canonical review-and-adjust surface for an order. It summarizes the resolved Tax Area (with AI confidence indicator), the ship-to context, and the tax lines. Each line shows the **item it taxes** (applies-to Item No. + description), **Shopify's rate**, the **Business Central Tax Detail rate** that would apply to that item for the assigned jurisdiction as of the order date, and the matched **Tax Jurisdiction Code** (with AI confidence indicators). The Tax Jurisdiction Code is **editable** so a reviewer can correct or complete a match, and the row is highlighted **green** when Shopify's and BC's rates agree and **red** when they differ. The **Approve** action (Approve icon, shown only while the order is being **held** — the shop requires review, or there is a live rate conflict — and it is not yet reviewed) **rebuilds the Tax Area from the current line jurisdictions** (re-seeding any missing Tax Detail brackets and re-detecting rate conflicts), then sets `Tax Match Reviewed` — the single source of truth that also stops the Sales Order and order-page prompts. In non-blocking mode with no rate conflict the order is never held (its Sales Document is created automatically), so Approve is hidden and the page is purely informational. Approve is blocked while any tax line is still unmatched (blank jurisdiction), so tax is never silently dropped. An **Undo Approval** action (Undo icon) reverses an approval while the order is still held-when-unapproved and no Sales Document has been created yet (`Sales Order No.`/`Sales Invoice No.` still blank) — it clears `Tax Match Reviewed` so the order is held again. If the order is being held and the user closes without approving, `OnQueryClosePage` warns them. **Rate-conflict case:** the jurisdiction is applied and a Tax Area is built, but the divergent line shows red and a guidance message on the Overview tab (shown only on a conflict) explains that approving will post at BC's rate. The reviewer can resolve it three ways: accept BC's rate (just Approve), change the jurisdiction, or click **Use Shopify Rate** on the tax lines part — which creates/updates a Tax Detail (effective the order's document date, at Shopify's rate) so BC posts what the customer paid. **Use Shopify Rate** mutates shared BC tax setup (not scoped to this order), so it asks for confirmation first; after it runs the row turns green, and approving then rebuilds the Tax Area and clears the stored rate-conflict flag. The tax lines ListPart is scoped to the order via `SetTaxLineFilter`. (tax lines link to order lines, so the page passes the order's order line ids). The standalone tax lines ListPart is **no longer embedded on the Shopify Order Card** — it lives only on this review page.

4. **Configurable blocking review (default on)** — a per-shop `Tax Match Review Required` Boolean (field 30474, default `true`) and a per-order `Tax Match Reviewed` Boolean (field 30477) gate Sales Document creation. `ShpfyTMAEvents` subscribes to `OnBeforeCreateSalesHeader` and sets `Handled := true` when the order has the marker, is not yet approved, and **(the shop requires review OR the order has a `Tax Rate Conflict`)**. The `Tax Rate Conflict` Boolean (field 30478) is the **single source of truth** for a rate conflict: it is set at match time when a matched line's BC Tax Detail rate differs from Shopify's, and refreshed whenever the match is re-applied on Approve. The gate, the notifications, the order-page action caption, and the review-page guidance + Approve visibility all read this stored flag, so they can never disagree. Because edits to a tax line's jurisdiction on the review page only take effect on Approve — and are **reverted** if the user closes without approving — the stored flag always matches the persisted tax lines. A rate conflict holds the order in **both** blocking and non-blocking mode; a normal successful match (no rate conflict) is held only when the shop requires review. The **Shpfy Order page** exposes a **Review and Approve Tax Match** entry action (shown while approval is pending — the order is held and not yet approved; captioned just **Review Tax Match** once approved or when not held) which opens the review page where the match is approved. If the user closes the review page while approval is still pending, an `OnQueryClosePage` confirm warns them the Sales Document will not be created until it is approved. On the next process run (auto or manual) the order proceeds. Customers can clear the shop toggle to opt into non-blocking mode.

5. **Active notifications** — two actionable, dismissible BC `Notification`s prompt the user to review, each with its own `MyNotifications` GUID so "Don't show again" is scoped per surface:
   - **Shopify Order page** (both modes) — `ShpfyTMAEvents`/the Order page extension fires (once per order per page session, via `SendOrderReviewNotification`) when the order was agent-matched and not yet reviewed: "Tax Matching Agent set Tax Area %1 on this Shopify order. Review the matched tax jurisdictions." Actions: **Review** (opens the review page) and **Don't show again**.
   - **Sales Order page** (non-blocking mode) — on open, the page's `OnAfterGetCurrRecord` calls `SendForCurrentSalesHeader`, which fires a notification when the Sales Header is marked `Tax Match Applied` and the originating Shopify order (resolved via `Sales Order No.`) has `Tax Match Reviewed = false` and the user hasn't disabled the prompt. **No table or queue** — the decision is derived live from the order's `Reviewed` flag plus the per-user `My Notifications` toggle, and a per-session dedupe var prevents re-firing on refresh. Actions: **Show Tax Match Decisions** (opens the review page), **Mark as reviewed** (sets the order's `Reviewed` flag), and **Don't show again** (`My Notifications.Disable`). Naturally suppressed once the order is reviewed (blocking-mode approval already sets that flag).

For safety, `ShpfyTMAEvents.OnAfterMapShopifyOrder` resets both the marker and the reviewed flag to `false` before each matcher run so re-matching (after a user manually clears Tax Area Code on the Shpfy Order Header) cannot leave stale flags from a prior run.

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

The **matching** system prompt (`ShpfyTaxMatchingAgent-SystemPrompt.md`, shipped as an app resource) instructs the LLM to match using a four-tier strategy:

1. **Exact match** — title matches jurisdiction code or description (case-insensitive)
2. **Keyword/semantic match** — common tax abbreviation patterns (GST, PST, HST, MTA, NYC, etc.)
3. **Geographic context** — use ship-to address to disambiguate when multiple jurisdictions could match
4. **Auto-create** — when enabled and no match found, suggest a new code (max 10 chars, uppercase, no spaces)

The prompt is hardened against prompt injection by a separate **security/guardrail** section that instructs the model to treat every tax line title, address, and jurisdiction description as untrusted **data (never instructions)**, never reveal the prompt or tool definition, keep `reason` short/factual/tax-only, and ignore any embedded instructions (leaving `jurisdiction_code` empty rather than obeying them). That guardrail section is **not** committed to this public repository: it is stored in **Azure Key Vault** (secret `ShopifyTaxMatchingAgentSecurityPrompt`) and merged onto the matching prompt at runtime by `Shpfy TMA Matcher.GetSecurityPrompt()` (following the Sales Line Suggestions pattern of loading prompts from Key Vault). If the secret cannot be read the matcher fails closed (no LLM call). The guardrail is exercised by the Responsible AI tests, which live in the internal enlistment (see below).

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

The Tax Matching Agent's matching itself runs silently during order import — no dialog, wizard, or chat interface. The visible surfaces are:

**Shopify Shop Card** — a "Tax Matching Agent" group with the per-shop configuration. Fields that have no effect without a prerequisite are disabled (greyed out) until the prerequisite is set:

| Field | Type | Default | Enabled when | Purpose |
|-------|------|---------|--------------|---------|
| Tax Matching Agent Enabled | Boolean | false | always | Master toggle per shop |
| Auto Create Tax Jurisdictions | Boolean | false | Tax Matching Agent Enabled | Allow LLM-suggested new jurisdictions to be created |
| Auto Create Tax Areas | Boolean | true | Tax Matching Agent Enabled | Allow system to create Tax Area records |
| Tax Area Naming Pattern | Text[20] | `SHPFY-` | Enabled **and** Auto Create Tax Areas | Prefix for auto-generated Tax Area codes |
| Tax Match Review Required | Boolean | true | Tax Matching Agent Enabled | When enabled, the Sales Document is not created until a user approves the match on the Tax Match Review page. Default is on per RAI guidance; clear it to opt into non-blocking mode. |

**Tax Match Review page** (page 30471) — the single canonical review-and-adjust surface. A Card showing the resolved Tax Area (with AI confidence indicator), the ship-to context, and an editable tax lines ListPart where each line shows the item it taxes (applies-to Item No. + description), Shopify's rate, Business Central's Tax Detail rate for the assigned jurisdiction, and its per-line Tax Jurisdiction Code (with AI confidence indicators). The Tax Jurisdiction Code is editable, and a line is highlighted green when the two rates agree, red when they differ. The **Approve** action (Approve icon) shows only while the order is being held (the shop requires review, or a live rate conflict) and is not yet reviewed; it rebuilds the Tax Area from the current line jurisdictions and is blocked while any line is unmatched. An **Undo Approval** action (Undo icon) reverses an approval before the Sales Document is created. In non-blocking mode with no conflict the order isn't held, so Approve is hidden and the page is informational. On a rate conflict the divergent line is red and a guidance message on the Overview tab explains that approving posts at BC's rate; a **Use Shopify Rate** action on the tax lines part lets the reviewer instead create/update a Tax Detail (effective the order's document date, at Shopify's rate) so BC posts the Shopify rate — it warns first that this changes shared tax setup beyond this order. The review-drill actions on the Shopify Order and Sales Order pages both use the AI `SparkleFilled` icon.

**Shopify Order page** — adds a review entry action (AI `SparkleFilled` icon) that opens the review page — captioned **Review and Approve Tax Match** while approval is pending, else **Review Tax Match** — and fires an actionable **Review** notification on open when the order was agent-matched and not yet reviewed. The tax lines are no longer embedded here — they live on the review page.

**BC Sales Order page** — a secondary HITL surface:

- Read-only `Tax Match Applied` field (next to Tax Liable, `Importance = Additional`).
- **Review Tax Match** navigation action (visible when the marker is set) that opens the review page for the originating order.
- One-time non-blocking notification on first open of the Sales Order (non-blocking mode), with actions to open the review page, mark reviewed, or suppress per-user.

## Data Model

The feature reads from and writes to the standard Shopify connector tables and BC tax tables:

### Connector tables (read/write)

| Table | Field | Usage |
|-------|-------|-------|
| Shpfy Order Header | Tax Area Code (1070) | Written by Tax Area Builder |
| Shpfy Order Header | Tax Liable (1080) | Set to `true` by Tax Area Builder |
| Shpfy Order Header | Tax Exempt (1090) | Imported from Shopify `taxExempt` field; guards skip matching |
| Shpfy Order Tax Line | Tax Jurisdiction Code (30476, via TMA TableExt) | Written by Matcher for each matched line |
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
| Tax Detail | Seeded per matched tax line for `(jurisdiction × the tax line's Tax Group)` at Shopify's reported rate. The Tax Group is resolved by what the tax line is charged on: a product-line tax line uses the order line item's `Tax Group Code`; a shipping-charge tax line uses the Shop's `Shipping Charges Account` Tax Group Code (`G/L Account.Tax Group Code`). For each seed, look for the latest Tax Detail with `Effective Date <= order date` for the jurisdiction + tax group + tax type. If none exists, insert a new one at the order date with Shopify's rate. If one exists with the same rate, do nothing. **Rate conflict:** if the bracket exists with a *different* rate, the existing (admin-maintained) rate is left untouched, telemetry `0000UMR` is logged, and the order is flagged (`Tax Rate Conflict`) — the jurisdiction is still matched and the Tax Area is built, but the order is held for review so a human accepts BC's rate or corrects the detail (see Human-in-the-loop). This applies uniformly to product-line and shipping-charge tax lines (a shipping rate conflict holds the order too). Empty Tax Group Code is a valid value (an item or shipping account with no group results in a `(Jurisdiction × '')` Tax Detail row). |

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

- `OnAfterMapShopifyOrder` fires after `OrderMapping.DoMapping()` completes; the agent subscriber runs the matcher (the connector's `MapTaxArea` runs first via address-based lookup; the agent only activates if that lookup didn't find a Tax Area).
- `OnBeforeCreateSalesHeader` fires at the top of `ShpfyProcessOrder.CreateHeaderFromShopifyOrder()`; the agent subscriber sets `Handled := true` to skip Sales Doc creation when the shop requires review and the order hasn't yet been approved.
- `OnAfterCreateSalesHeader` fires after the connector's existing Tax Area Code propagation; the agent subscriber uses it to propagate the marker flag onto the Sales Header (the review prompt itself is derived live on page open, not queued).

## Capability Registration

Registration follows the standard BC Copilot capability pattern:

1. **Install codeunit** (30475) — calls `RegisterCopilotCapability()` on `OnInstallAppPerDatabase`
2. **Register codeunit** (30470) — subscribes to `OnRegisterCopilotCapability` on the Copilot AI Capabilities page, so the capability is also registered when the admin visits that page
3. The capability appears as **"Shopify Tax Jurisdiction Matching with AI"** in the Copilot AI Capabilities page

### Shop defaults on install/upgrade

The tax config fields carry their defaults as field `InitValue`s (`Auto Create Tax Areas = true`, `Tax Area Naming Pattern = 'SHPFY-'`, `Tax Match Review Required = true`), which only apply to Shop records created *after* the app is installed. Because Shopify shops usually already exist when this app is added, `Shpfy TMA Upgrade` (30478) backfills those three fields onto existing shops from an `Init()`'d record. The backfill is guarded by an **upgrade tag** (`MS-445769-TMAShopDefaults-…`) so it runs **exactly once per company**, and it is invoked from both paths: the Install codeunit's `OnInstallAppPerCompany` (new install into a company that already has shops) and the Upgrade codeunit's `OnUpgradePerCompany` (a previously installed app being updated). The tag is intentionally **not** registered in `OnGetPerCompanyUpgradeTags`, so a fresh install — which has no tag yet — still backfills any pre-existing shops (mirroring how `Shpfy Installer` guards its Cue/retention setup). The other two fields (`Tax Matching Agent Enabled`, `Auto Create Tax Jurisdictions`) intentionally default to `false` and are left untouched.

## Telemetry

| Event ID | Level | Location | Trigger |
|----------|-------|----------|---------|
| 0000UMF | Usage | Events | Order held for review due to a rate conflict |
| 0000UMG | Usage | Events | Tax Match Applied marker set on Order Header |
| 0000UMH | Usage | Events | Tax lines matched (match successful) |
| 0000UMI | Usage | Events | Sales Document creation blocked pending tax match review |
| 0000UMJ | Usage | Events | Tax Match Applied marker propagated to Sales Header |
| 0000UMK | Normal | Events | Match starting for order |
| 0000UML | Uptake: Used | Matcher | MatchTaxLines called |
| 0000UMM | Error | Matcher | AOAI call failed (status code + error) |
| 0000UMN | Error | Matcher | No function call in LLM response |
| 0000UMO | Error | Matcher | Function execution failed |
| 0000UMP | Normal | Matcher | Low-confidence match skipped |
| 0000UMQ | Warning | Matcher | Jurisdiction not found, auto-create disabled |
| 0000UMR | Warning | Matcher | A matched tax line's Tax Detail rate differs from Shopify's (item or shipping tax group) — jurisdiction still matched, order held for review |
| 0000UMT | Usage | Notify | Sales Order review notification sent |
| 0000UMU | Usage | Notify | User opened the review from the Sales Order notification |
| 0000UMV | Usage | Notify | Order-page review notification sent |
| 0000UMW | Usage | Notify | User opened the Tax Match Review page from the order-page notification |
| 0000UMX | Usage | Notify | User marked notification reviewed |
| 0000UMY | Usage | Notify | User chose "Don't show again" |
| 0000UMZ | Uptake: Set up | Register | App installed |
| 0000UN0 | Uptake: Used | Activity Log | Per-tax-line entry written |
| 0000UN1 | Uptake: Used | Activity Log | Per-tax-area entry written |
| 0000UN7 | Usage | Notify | User undid an approval (order held for review again) |
| 0000UNP | Usage | Order Tax Lines Part | Reviewer clicked **Use Shopify Rate** — adopted Shopify's rate into a Tax Detail |

## Test App

A separate test app — **Shopify Connector NA Test** (`ShopifyNA/test/`, sources under
`test/src/Tax Matching Agent/`, ID range 134713-134720) — carries the public coverage in two layers:

**AI Test Toolkit (data-driven, real LLM):**
- `Shpfy TMA Match Test` (134717), `Shpfy TMA Tax Area Test` (134718), `Shpfy TMA Guard Test` (134719) read their scenarios via `AITTestContext.GetInput()` and must run **through the AI Test Toolkit** (they need the YAML datasets + suite). Only the Match test issues real LLM calls; Tax Area and Guard exercise post-LLM logic through the same harness.
- Data-driven YAML scenarios iterated by the framework; test output logged via `AITTestContext.SetQueryResponse()` for eval spreadsheets.
- Categories: Jurisdiction Matching (J, H), Jurisdiction Creation (JC), Tax Detail (TD), Shipping Tax (S), Tax Area (TA), Guard (G), End-to-End (F).

**Plain unit tests (standard test runner, no LLM, no toolkit):**
- `Shpfy TMA HITL Test` (134716) and `Shpfy TMA Rate Conflict Test` (134720) build records directly and drive the codeunit helpers (marker propagation, gate decision, rate-conflict recheck/flip, Undo Approval). They run as ordinary AL tests — the AI Test Toolkit is not required.

**Responsible AI (RAI) — prompt injection + harms (internal enlistment, not this repo):**
- Because `microsoft/BCApps` is public, the RAI tests — which would otherwise expose the adversarial datasets and the jailbreak-testing approach — live in a **separate internal app in the NAV enlistment**: **Shopify Connector NA AI Tests** (`App/Internal/Apps/ShopifyNAAITest`, ID range 134721-134732), covering deterministic cross-prompt-injection scenarios and dynamic Red Team Scan harms/jailbreak passes.
- It reuses this public test app's `Shpfy TMA Test Library` + `Shpfy TMA Verify` and calls the matcher via `internalsVisibleTo` (granted by both **Shopify Connector NA** and **Shopify Connector NA Test**).
- The tests read the security prompt from Key Vault (the norm — like Sales Line Suggestions), so the eval environment must have the secret provisioned (see *Capability Registration* below); there is no mock.

See `TestMatrix.md` for the full test scenario inventory and the Automated Test Coverage map.

## Localization promotion

The main Shopify Connector nudges eligible environments to install this app, mirroring the Belgian
localization pattern. `Shpfy Shop Mgt.SendNorthAmericaLocalizationNotification()` (called from the
`Shpfy Shops` list `OnOpenPage`) shows a dismissible `Notification` with **Install**
(`ExtensionManagement.InstallMarketplaceExtension`) and **Don't show again** (`MyNotifications`)
actions when: the application family is **US** (CA/MX to be added when supported), the app is not
already installed, and the user hasn't dismissed the prompt.

## Refund Support

Refunds inherit all tax context from their parent order — no separate LLM call or tax matching is performed for refunds.

### Data flow
- **Refund Header** has FlowFields (110-112) that look up Tax Area Code, Tax Liable, and Tax Exempt from the linked `Shpfy Order Header` via `Order Id`. No data duplication.
- **Credit memo creation** (`ShpfyCreateSalesDocRefund`) reads Tax Area Code and Tax Liable from the original order header and validates both on the Sales Credit Memo header.
- **Tax-exempt orders**: If the parent order is tax exempt, the credit memo's Tax Liable stays false (no Tax Area Code to trigger the block).

### UI
- The **Refund page** shows a "Tax" group with Tax Area Code, Tax Liable, and Tax Exempt (read-only, inherited from order).
- A **"Tax Lines"** navigation action opens the existing `Shpfy Order Tax Lines` page filtered to the parent order's lines, so users can see the tax jurisdiction breakdown without leaving the refund.

### Why no tax matching for refunds
The Tax Matching Agent event subscriber (`ShpfyTMAEvents`) only subscribes to `OnAfterMapShopifyOrder`. Refunds don't go through order mapping — they reference an already-processed order. If the order's tax was matched by the Tax Matching Agent, that data is already on the order and flows through to the refund via FlowFields.
