# Copilot Tax Matching — Responsible AI Overview

## What it does

When a Shopify order is imported into Business Central, the order may carry tax lines — e.g. "NEW YORK STATE TAX at 4%", "NYC CITY TAX at 4.5%". Business Central needs to map these free-text tax descriptions to its own structured Tax Jurisdiction records so that the correct tax rules, accounts, and reporting apply to the resulting sales document.

Today this mapping is manual. This feature uses an LLM to automate it.

## When it runs

The feature triggers automatically during Shopify order import, only when all of these conditions are met:

- The shop has **Copilot Tax Matching Enabled** = Yes
- The **Copilot capability** is registered and active in the Copilot AI Capabilities page
- The order does **not** already have a Tax Area Code (i.e. the standard address-based mapping didn't find a match)
- The order is **not tax exempt** (i.e. tax was not disabled at POS)
- The order has **unmatched tax lines** (tax lines without a Tax Jurisdiction Code)

If any condition is not met, the feature does nothing and the order is processed normally.

## What data is sent to the LLM

A single API call is made per order. The request contains:

1. **System prompt** — static instructions describing the matching strategy (exact match, keyword/semantic, geographic context, auto-create rules). No customer data.

2. **User prompt** — constructed from the order, containing:
   - **Tax lines**: identifier, title (e.g. "NEW YORK STATE TAX"), rate percentage, and whether the channel is liable. No monetary amounts, no customer names, no PII.
   - **Available Tax Jurisdictions**: code and description of all Tax Jurisdiction records in the BC tenant. These are system configuration data, not customer data.
   - **Ship-to address**: country, state/county, and city only. No street address, no postal code, no customer name.
   - **Auto Create Tax Jurisdictions setting**: "Yes" or "No".

3. **Tool definition** — a JSON schema that constrains the LLM's response format (described below).

**No customer names, financial amounts, item details, or personally identifiable information is sent.**

## How the LLM responds

The LLM is called using **Azure OpenAI** (GPT-4.1) via Business Central's standard AOAI integration. The call uses **function calling** (tool use) to force the response into a strict JSON schema. The LLM cannot respond with free text — it must return a structured object with:

```json
{
  "matches": [
    {
      "tax_line_id": "12345-1",
      "jurisdiction_code": "NYSTAX",
      "confidence": "high",
      "reason": "Title 'NEW YORK STATE TAX' matches jurisdiction description"
    }
  ]
}
```

For each tax line, the LLM returns:
- **jurisdiction_code** — either an existing BC Tax Jurisdiction code, a suggested new code (max 10 chars), or empty string if no match
- **confidence** — `high` (exact match), `medium` (semantic/keyword match), or `low` (suggested new jurisdiction)
- **reason** — brief explanation of the match logic

The temperature is set to **0** (deterministic), and max tokens is capped at **4096**.

## What happens with the LLM response

The response is parsed and validated entirely in AL code. The LLM does not execute any actions — it only suggests matches. The AL code then:

1. **Validates each match**: Checks that the jurisdiction code exists in BC. If it doesn't:
   - If **Auto Create Tax Jurisdictions = No**: the match is skipped and logged.
   - If **Auto Create Tax Jurisdictions = Yes** and confidence is `low`: a new Tax Jurisdiction is created with the suggested code, the order's country, and a Report-to reference to the state-level jurisdiction.
   - Medium and high confidence matches to non-existent jurisdictions are also skipped when auto-create is off.

2. **Writes the jurisdiction code and checks for a rate conflict**: The matcher writes the matched Tax Jurisdiction Code to the Shopify tax line record. It then compares Shopify's rate against any existing Tax Detail bracket for that jurisdiction + the item's tax group (valid as of the order date). If a bracket exists with a **different** rate, the order is flagged with a rate conflict (telemetry `0000UMR`) and an Activity Log entry records it on the line — the match itself is correct, but Business Central would post its own rate rather than what the customer paid on Shopify, so the order is always held for human review. The existing admin-maintained rate is left untouched; the reviewer sees Shopify's and BC's rates side by side (green/red) on the review page and decides whether to accept BC's rate, change the jurisdiction, or correct the Tax Detail.

3. **Seeds a Tax Detail bracket** for each matched jurisdiction (item tax group, and the shop's shipping-charges-account tax group), so the posted Sales Document computes a non-zero tax rate. If no bracket exists it inserts one at the order date with Shopify's rate; if one exists with the same rate it does nothing. If one exists with a *different* rate the matcher never overwrites it — for the item tax group that difference raises the rate conflict in step 2 (held for review), and for the shipping tax group it is only logged as a warning and does not block.

4. **Finds or creates a Tax Area** — searches for an existing Tax Area that contains exactly the matched set of jurisdictions. If none exists and **Auto Create Tax Areas = Yes**, creates one named after the most specific (lowest-level) jurisdiction, e.g. `SHPFY-MTATAX`. A rate conflict does not stop this — the jurisdictions are correct, so the Tax Area is built and the order is held for review (see below).

5. **Sets Tax Area Code and Tax Liable** on the Shopify order header, which flows through to the Sales Document when created.

## Transparency to the user

Because automated tax matching has tax and legal implications, every Copilot decision is visibly recorded, customer-configurable to be blocking, and actively surfaced for human review. The mantra is "here's what Copilot did, please take a look" — no decision runs invisibly.

Five layers deliver this, centered on a dedicated **Copilot Tax Match Review page** that shows, for one order, the resolved Tax Area and each tax line's matched Tax Jurisdiction Code with the platform AI confidence indicators:

1. **Audit log** — every matched tax line and the resulting Tax Area each get a System Application `Activity Log` entry of Type `AI`, carrying the LLM's confidence (`Low`/`Medium`/`High`), the LLM's stated reasoning, and a drill-back link to the Tax Jurisdiction or Tax Area record. The platform automatically renders these as confidence indicators on the corresponding fields (visible on the review page).

2. **Review page** — the single canonical review-and-adjust surface for an order. It summarizes what Copilot did (resolved Tax Area, ship-to context, each tax line with the item it taxes, Shopify's rate next to Business Central's Tax Detail rate, and its Tax Jurisdiction Code + AI confidence indicators). The Tax Jurisdiction Code is editable so a reviewer can correct or complete a match, and a line is highlighted green when the two rates agree and red when they differ. The **Approve** action (shown only while the order is held — the shop requires review, or a live rate conflict — and not yet reviewed) rebuilds the Tax Area from the current line jurisdictions and is blocked while any line is unmatched. An **Undo Approval** action reverses an approval before the Sales Document is created. In non-blocking mode with no conflict the order isn't held, so Approve is hidden. In a rate-conflict case the divergent line shows red and a guidance message on the Overview tab explains that approving posts at Business Central's rate — the reviewer can instead change the jurisdiction or correct the Tax Detail first.

3. **Persistent badge on the BC Sales Order** — a `Copilot Tax Match Applied` Boolean propagates from the Shopify order onto the Sales Header that BC creates from it. The Sales Order page shows it as a read-only field plus a **Review Copilot Tax Match** action that opens the review page.

4. **Active notifications** — an actionable, dismissible BC `Notification` prompts the user to review what Copilot did, on the Shopify order itself (both modes) and on the Sales Order (non-blocking mode). Each opens the review page; each can be suppressed per-user (`MyNotifications.Disable`).

5. **Configurable blocking review (default on)** — a per-shop setting `Copilot Tax Match Review Required` (default `true`) holds back Sales Document creation until a user explicitly approves the Copilot tax match. While blocking is on, an order whose Tax Area was populated by Copilot stays as a Shopify order — the connector's auto-create-sales-doc, manual creation actions, and background job all skip it — until the user opens the review page (from the review action on the order or the notification), reviews the matched Tax Area + per-line Tax Jurisdiction Codes (with the platform's AI confidence indicators visible inline), and clicks **Approve**. Closing the review page without approving raises a confirmation warning. The customer can opt out of blocking by clearing the toggle on the Shopify Shop card; in that mode the Sales Document is created automatically and the user reviews it after the fact via layers 1–4.

**Default is blocking.** A merchant who wants the older auto-flow behavior can switch to non-blocking explicitly. This honors RAI feedback that the conservative default is a human gate, and lets high-throughput merchants opt back into automation as a deliberate decision.

**v1 limitations** documented for awareness:

- In non-blocking mode, the Sales Order review prompt is derived live from the originating order's `Copilot Tax Match Reviewed` flag and the per-user `My Notifications` toggle (no per-user state table). "Mark as reviewed" sets the order flag, so once any user reviews it the prompt stops for everyone — appropriate for a "someone should look at this" gate. The persistent badge and the always-on **Review Copilot Tax Match** action remain available regardless.
- Refunds and credit memos inherit Tax Area via the standard return-doc path and do not get HITL prompts of their own.
- Chained automation that auto-releases and auto-posts the Sales Document immediately after auto-create (relevant only in non-blocking mode) can land in a posted state before a human sees it. A narrow gate suppressing one auto-post cycle when `Copilot Tax Match Applied = true` is planned for v1.1.

## Guardrails and limitations

| Concern | Mitigation |
|---------|------------|
| LLM hallucination | Function calling constrains output to a fixed schema. Jurisdiction codes are validated against actual BC records before use. |
| Incorrect matches | Confidence levels allow filtering. Low-confidence matches (new jurisdictions) require explicit admin opt-in via Auto Create setting. A rate conflict with an existing Tax Detail flags the order and holds it for review, showing Shopify's rate next to BC's (green/red) so a human decides whether BC's rate is acceptable, the jurisdiction is wrong, or the Tax Detail needs correcting before posting. |
| Data privacy | No PII sent. Only tax line titles, jurisdiction config, and city/state/country. No street addresses, amounts, or customer names. |
| Runaway creation | New jurisdictions are only created when admin enables Auto Create. Codes are max 10 chars. Tax Area codes have a collision suffix. |
| LLM unavailability | If the API call fails, the error is logged and the order proceeds without tax matching — same as if the feature were disabled. |
| Duplicate data | Existing Tax Areas are reused via exact jurisdiction set matching. Existing Tax Details are not duplicated (checked by jurisdiction + tax group + rate). |
| Feature gating | Requires Copilot capability to be both registered and active. Admin must explicitly enable per shop. Standard Copilot AI Capabilities page controls apply. |
| Determinism | Temperature = 0 for consistent results across identical inputs. |
| Token limits | Max 4096 output tokens. Input is bounded by the number of tax lines per order (typically 1-5) and total jurisdiction count in the tenant. |
| Silent automation | Sales Document creation is held by default until a user explicitly approves the Copilot tax match (`Copilot Tax Match Review Required` defaults to true on the shop). Every match additionally writes an `Activity Log` entry (Type = AI) with confidence + reason + drill-back, the resulting Sales Order shows a persistent `Copilot Tax Match Applied` badge and an action that drills into the AI decisions, and in non-blocking mode a one-time notification fires on first view to actively prompt review. |

## Model and infrastructure

- **Model**: GPT-4.1 (latest) via `AOAIDeployments.GetGPT41Latest()`
- **Infrastructure**: Azure OpenAI, accessed through BC's standard `AzureOpenAI` codeunit (already reviewed and using CAPI)
- **No data storage**: The LLM prompt and response are not persisted. Only the resulting jurisdiction codes, tax details, and tax areas are written to BC tables.
