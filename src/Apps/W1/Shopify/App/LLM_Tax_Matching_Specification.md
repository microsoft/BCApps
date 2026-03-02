# LLM-Based Tax Jurisdiction Matching - Feature Specification

## Overview

**Feature Name:** Intelligent Tax Jurisdiction Matching for Shopify Orders
**Module:** Microsoft.Integration.Shopify
**Target Version:** 28.0+
**Dependencies:** Business Central Agent Framework, Azure OpenAI Service

### Purpose

Automatically match Shopify tax line descriptions to Business Central Tax Jurisdictions using AI/LLM analysis, and dynamically create/assign appropriate Tax Areas to ensure accurate tax calculation when creating sales documents from Shopify orders.

### Business Problem

Current Shopify connector uses simple address-based matching (Country + County) to determine BC Tax Area. This fails when:
- Shopify provides detailed tax jurisdiction names (e.g., "California Sales Tax", "Los Angeles County Tax") that don't align with address lookups
- Multiple tax jurisdictions apply to a single order (state + county + city)
- Tax rates in BC are outdated or missing
- Tax jurisdiction descriptions don't match exactly

---

## Data Model

### Table Extensions

#### 1. Shpfy Order Tax Line (Table 30122)

**New Fields:**

| Field ID | Field Name | Type | Length | Description | Editable |
|----------|------------|------|--------|-------------|----------|
| 10 | Tax Jurisdiction Code | Code | 10 | Links to BC Tax Jurisdiction table. Stores the matched jurisdiction. | Yes |


---

#### 2. Shpfy Order Header (Table 30118)

**New Fields:**

| Field ID | Field Name | Type | Length | Description | Editable |
|----------|------------|------|--------|-------------|----------|
| 1102 | Tax Area Code | Code | 20 | Tax Area Code determined by agent (takes precedence over address-based lookup) | No |
| 1104 | On hold | boolean | - | Blocks creation of sales documents | Yes |


---

#### 3. Shpfy Shop (Table 30102) or Agent Setup

**New Fields:**

| Field ID | Field Name | Type | Length | Description | Default | Editable |
|----------|------------|------|--------|-------------|---------|----------|
| 130 | Enable LLM Tax Matching | Boolean | - | Master switch to enable AI-powered tax matching | false | Yes |
| 131 | Auto Create Tax Jurisdictions | Boolean | - | Allow automatic creation of new Tax Jurisdictions when no match found | false | Yes |
| 132 | Auto Create Tax Areas | Boolean | - | Allow automatic creation of new Tax Areas for matched jurisdiction sets | false | Yes |
| 133 | Tax Area Naming Pattern | Text | 100 | Pattern for generating Tax Area codes. Supports {COUNTRY} and {HASH} placeholders | 'SHPFY-{COUNTRY}-{HASH}' | Yes |


---

---

## Processing Logic

### Workflow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Order Import (Existing)                                     │
│    - Shopify order imported                                    │
│    - Tax lines stored in Shpfy Order Tax Line                  │
└────────────────────┬────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────────┐
│ 2. Order Mapping (Existing)                                    │
│    - Customer/Company mapping                                  │
│    - Item mapping                                              │
│    - Shipping/Payment method mapping                           │
└────────────────────┬────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────────┐
│ 2.1. Tax Area populated based on address                      |
│    - move logic from Process Sales Document codeunit          │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │
                     │
                     │
┌────────────────────▼────────────────────────────────────────────┐
│ 3. Tax Agent Decision (NEW)                                    │
│    - Check if Shop."Enable LLM Tax Matching" = true           │
│    - Check if order has tax lines                             │
│    - If YES → Create Agent Task, Set Order to "On Hold"       │
│    - If NO → Continue to existing sales document creation     │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ (Agent picks up task)
                     │
┌────────────────────▼────────────────────────────────────────────┐
│ 4. Agent Tax Processing (NEW)                                  │
│    A. For each tax line:                                       │
│       - Try Exact Match (description)                          │
│       - Try Rate Match (tax rate + item tax group)             │
│       - Try LLM Match (semantic analysis)                      │
│       - Auto Create Jurisdiction (if enabled)                  │
│    B. Find or Create Tax Area:                                 │
│       - Search for Tax Area with exact jurisdiction set        │
│       - Create new if not found (if enabled)                   │
│    C. Update Order:                                            │
│       - Set Computed Tax Area Code                             │
│       - Restore Fulfillment Status (release from hold)         │
│       - Set Tax Processing Status = Completed                  │
└────────────────────┬────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────────┐
│ 5. Sales Document Creation (Modified)                         │
│    - uses Tax Area from the Shopify Order                     │
│    - Creates Sales Order/Invoice with correct Tax Area        │
└─────────────────────────────────────────────────────────────────┘
```



**Matching Strategies (Applied in Order):**

#### 1. Exact Match
- Compare Shopify tax line Title to Tax Jurisdiction Description
- Case-insensitive comparison
- 100% confidence if found


#### 2. LLM Match
- Build structured prompt with:
  - Shopify tax info (title, rate, country, county)
  - List of BC Tax Jurisdictions (code, description)
  - Instructions for matching
  - Expected JSON response format
- Call Azure OpenAI Chat Completion API
- Parse response: `{"code": "JURISDICTION_CODE", "confidence": 85, "reasoning": "..."}`
- Accept if confidence ≥ 70%

#### 3. Auto Create
- Generate unique jurisdiction code (e.g., "USCASTATE1")
- Create Tax Jurisdiction record
- Create Tax Detail record with rate and item tax group
- 100% confidence (newly created)

---

### 4. Codeunit 30183: Shpfy Tax Area Builder

**Purpose:** Find or create Tax Area containing the matched jurisdictions

**Key Procedures:**

#### FindOrCreateTaxArea(OrderHeader): Code[20]
- **Access:** Internal
- **Purpose:** Main entry point for tax area resolution
- **Logic:**
  1. Collect all distinct Tax Jurisdiction Codes from order's tax lines
  2. Call FindTaxAreaByJurisdictions() to search existing
  3. If found: Return existing Tax Area Code
  4. If not found and auto-create enabled:
     - Call CreateTaxArea()
     - Return new Tax Area Code
  5. If not found and auto-create disabled:
     - Return empty (requires manual setup)

#### FindTaxAreaByJurisdictions(JurisdictionCodes: List): Code[20]
- **Access:** Local
- **Purpose:** Search for Tax Area with exact jurisdiction set
- **Algorithm:**
  1. Find all Tax Areas containing first jurisdiction
  2. For each candidate Tax Area:
     - Count how many jurisdictions match
     - Count total jurisdictions in Tax Area
  3. Return Tax Area where:
     - All required jurisdictions are present
     - Tax Area has no extra jurisdictions (exact match)
- **Returns:** Tax Area Code or empty if none match

#### CreateTaxArea(JurisdictionCodes: List, OrderHeader): Code[20]
- **Access:** Local
- **Purpose:** Create new Tax Area with jurisdiction lines
- **Logic:**
  1. Generate unique code via GenerateTaxAreaCode()
  2. Create Tax Area record:
     - Code: Generated code
     - Description: "Shopify - [Country] - [County]"
     - Country/Region: From order
  3. Create Tax Area Lines for each jurisdiction
  4. Create Shpfy Tax Area mapping (Country + County → Tax Area)
  5. Return new Tax Area Code

#### GenerateTaxAreaCode(OrderHeader): Code[20]
- **Access:** Local
- **Purpose:** Generate unique Tax Area code using shop pattern
- **Algorithm:**
  1. Get pattern from Shop."Tax Area Naming Pattern"
  2. Replace placeholders:
     - {COUNTRY} → Order Ship-to Country/Region Code
     - {HASH} → Hash value (mod 10000) of Country + County
  3. Ensure uniqueness with counter suffix if needed
- **Example:** "SHPFY-US-12345"

#### CreateShopifyTaxAreaMapping(TaxAreaCode, OrderHeader)
- **Access:** Local
- **Purpose:** Create mapping record in Shpfy Tax Area table
- **Logic:**
  - Insert if not exists: Country/Region + County → Tax Area Code
  - Used for future address-based lookups

---



## User Interface

### Page Extension: Shpfy Shop Card (Page 30101)

**New FastTab:** "Tax Processing"

**Layout:**

```
┌─────────────────────────────────────────────────────────────┐
│ Tax Processing                                              │
├─────────────────────────────────────────────────────────────┤
│ [✓] Enable LLM Tax Matching                                │
│                                                             │
│ Tax Agent User:  [SHOPIFY_TAX_AGENT      ▼]               │
│                                                             │
│ [✓] Auto Create Tax Jurisdictions                          │
│ [✓] Auto Create Tax Areas                                  │
│                                                             │
│ Tax Area Naming Pattern:  SHPFY-{COUNTRY}-{HASH}          │
│                                                             │
│                                                             │
│ ℹ  Use AI to automatically match Shopify taxes to         │
│    Business Central Tax Jurisdictions and Tax Areas.       │
└─────────────────────────────────────────────────────────────┘
```


---

## Future Enhancements

### Phase 2 Considerations
1. **Rate Update Logic:** Automatically update Tax Detail when Shopify rate differs
2. **Manual Review Queue:** UI for reviewing low-confidence matches (< 70%)
3. **Bulk Reprocessing:** Action to reprocess all failed orders
4. **Learning System:** Store successful matches to improve future matching
5. **Multi-Country Optimization:** Filter jurisdiction lists by country for faster LLM processing
7. **Match History:** Track jurisdiction mapping changes over time
8. **Statistics Dashboard:** Show matching success rates, confidence distribution

---

