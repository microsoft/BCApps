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

2. **Writes the jurisdiction code** to the Shopify tax line record.

3. **Creates Tax Detail records** (tax rate entries) when auto-creating jurisdictions, using the rate from the Shopify tax line and the Tax Group Code from the order line's item.

4. **Finds or creates a Tax Area**: Searches for an existing Tax Area that contains exactly the matched set of jurisdictions. If none exists and **Auto Create Tax Areas = Yes**, creates one named after the most specific (lowest-level) jurisdiction, e.g. `SHPFY-MTATAX`.

5. **Sets Tax Area Code and Tax Liable** on the Shopify order header, which flows through to the Sales Document when created.

## Guardrails and limitations

| Concern | Mitigation |
|---------|------------|
| LLM hallucination | Function calling constrains output to a fixed schema. Jurisdiction codes are validated against actual BC records before use. |
| Incorrect matches | Confidence levels allow filtering. Low-confidence matches (new jurisdictions) require explicit admin opt-in via Auto Create setting. |
| Data privacy | No PII sent. Only tax line titles, jurisdiction config, and city/state/country. No street addresses, amounts, or customer names. |
| Runaway creation | New jurisdictions are only created when admin enables Auto Create. Codes are max 10 chars. Tax Area codes have a collision suffix. |
| LLM unavailability | If the API call fails, the error is logged and the order proceeds without tax matching — same as if the feature were disabled. |
| Duplicate data | Existing Tax Areas are reused via exact jurisdiction set matching. Existing Tax Details are not duplicated (checked by jurisdiction + tax group + rate). |
| Feature gating | Requires Copilot capability to be both registered and active. Admin must explicitly enable per shop. Standard Copilot AI Capabilities page controls apply. |
| Determinism | Temperature = 0 for consistent results across identical inputs. |
| Token limits | Max 4096 output tokens. Input is bounded by the number of tax lines per order (typically 1-5) and total jurisdiction count in the tenant. |

## Model and infrastructure

- **Model**: GPT-4.1 (latest) via `AOAIDeployments.GetGPT41Latest()`
- **Infrastructure**: Azure OpenAI, accessed through BC's standard `AzureOpenAI` codeunit (already reviewed and using CAPI)
- **No data storage**: The LLM prompt and response are not persisted. Only the resulting jurisdiction codes, tax details, and tax areas are written to BC tables.
