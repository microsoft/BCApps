# Implementation Plan: Shopify Tax Jurisdiction Matching Agent

## Context

The Shopify Connector currently uses simple address-based matching (Country + County) via the `Shpfy Tax Area` table (30109) to determine BC Tax Areas when creating sales documents. This fails when Shopify provides detailed tax jurisdiction names (e.g., "California Sales Tax", "Los Angeles County Tax"), when multiple jurisdictions apply, or when tax descriptions don't match exactly.

This plan implements an AI-powered agent that matches Shopify tax line descriptions to BC Tax Jurisdictions, assembles the correct Tax Area, and assigns it to the order before sales document creation. The implementation follows the BC Agent Framework patterns from the PayablesAgent and SalesOrderAgent.

**This is a prototype** -- we keep the AL code simple and focus on getting the agent instructions right.

---

## Architecture: Two-App Split

The implementation is split across **two apps**:

### 1. Standard Shopify Connector (`src/Apps/W1/Shopify/App/`)
Contains generic improvements to order processing that benefit all users, not just agent users:
- **Tax Area Code field** on Order Header (field 1070 added directly to table 30118) -- stores resolved Tax Area during mapping
- **Tax Jurisdiction Code field** on Order Tax Line (field 10 added directly to table 30122) -- maps each Shopify tax line to a BC Tax Jurisdiction
- **New MapTaxArea in OrderMapping** -- moves address-based Tax Area lookup from ProcessOrder to the mapping step
- **New `OnAfterMapShopifyOrder` event** in `ShpfyOrderEvents` -- fired at the end of `DoMapping()` in OrderMapping; the agent subscribes here
- **Simplified ProcessOrder** (line 129) -- just reads Tax Area Code from order header, no fallback
- **Simplified CreateSalesDocRefund** (line 123) -- same pattern for refunds
- **`internalsVisibleTo`** updated in `app.json` to allow the agent app access to internal objects

### 2. Shopify Tax Agent App (`src/Apps/W1/Shopify/ShpfyTaxAgent/app/`)
A separate app containing all agent-specific logic:
- Agent framework implementation (IAgentFactory, IAgentMetadata, IAgentTaskExecution)
- Agent instructions (system prompt)
- On Hold field on Order Header (table extension)
- Agent configuration on setup table (Auto Create Tax Jurisdictions, Auto Create Tax Areas, Tax Area Naming Pattern)
- Event subscribers for order hold, agent task creation, sales document blocking
- Setup page and permission set

**Dependency**: The agent app depends on the Shopify Connector. The connector's `internalsVisibleTo` grants the agent app access to internal tables (`Shpfy Order Tax Line`, `Shpfy Tax Area`) and codeunits (`Shpfy Order Mgt.`).

---

## Part 1: Agent Instructions

**File**: `src/Apps/W1/Shopify/ShpfyTaxAgent/app/.resources/Prompts/ShpfyTaxAgent-SystemPrompt.md`

This is the core deliverable. The agent instructions follow the PayablesAgent pattern with structured task guidance:
- Identity & Mission section
- 11 critical instructions (safety rails)
- Main todo template with 7 top-level steps
- 7 detailed task definitions with `<task>` / `<success_criteria>` XML tags
- Sitemap reference for page navigation
- Field mappings reference (read/write fields on each table)

The full content is in the file itself.

---

## Part 2: Standard Connector Changes

### 2.1 New Field on Shpfy Order Header: Tax Area Code

**File**: `src/Apps/W1/Shopify/App/src/Order handling/Tables/ShpfyOrderHeader.Table.al`

Added directly to the table (not a table extension):
- Field 1070: `Tax Area Code` (Code[20]) - TableRelation to "Tax Area"

This field is populated during **order mapping** (step 2.1: address-based lookup via `MapTaxArea`) and can be later overridden by the agent with the matched Tax Area. ProcessOrder and CreateSalesDocRefund simply read from this field.

### 2.2 OrderMapping Change: New MapTaxArea procedure

**File**: `src/Apps/W1/Shopify/App/src/Order handling/Codeunits/ShpfyOrderMapping.Codeunit.al`

Added `MapTaxArea(var OrderHeader)` procedure called from both `MapHeaderFields` and `MapB2BHeaderFields`, alongside existing mapping procedures (MapShippingMethodCode, MapShippingAgent, MapPaymentMethodCode):

```al
local procedure MapTaxArea(var OrderHeader: Record "Shpfy Order Header")
var
    ShpfyTaxArea: Record "Shpfy Tax Area";
    OrderMgt: Codeunit "Shpfy Order Mgt.";
begin
    if OrderHeader."Tax Area Code" <> '' then
        exit;

    if OrderMgt.FindTaxArea(OrderHeader, ShpfyTaxArea) and (ShpfyTaxArea."Tax Area Code" <> '') then
        OrderHeader."Tax Area Code" := ShpfyTaxArea."Tax Area Code";
end;
```

This moves the `FindTaxArea` logic from ProcessOrder to where it belongs: the mapping step. The Tax Area Code is resolved and stored on the order header during mapping, so ProcessOrder just reads it. The `if OrderHeader."Tax Area Code" <> '' then exit` guard ensures that if the field is already set (e.g., by the agent), it is not overwritten.

### 2.3 ProcessOrder Change (line 129)

**File**: `src/Apps/W1/Shopify/App/src/Order handling/Codeunits/ShpfyProcessOrder.Codeunit.al`

Changed from:
```al
if OrderMgt.FindTaxArea(ShopifyOrderHeader, ShopifyTaxArea) and (ShopifyTaxArea."Tax Area Code" <> '') then
    SalesHeader.Validate("Tax Area Code", ShopifyTaxArea."Tax Area Code");
```

To:
```al
if ShopifyOrderHeader."Tax Area Code" <> '' then
    SalesHeader.Validate("Tax Area Code", ShopifyOrderHeader."Tax Area Code");
```

No fallback needed -- the Tax Area was already resolved during mapping. The `ShopifyTaxArea` variable and `OrderMgt` codeunit reference were removed from ProcessOrder as they are no longer used.

### 2.4 CreateSalesDocRefund Change (line 123)

**File**: `src/Apps/W1/Shopify/App/src/Order Return Refund Processing/Codeunits/ShpfyCreateSalesDocRefund.Codeunit.al`

Same simplification as ProcessOrder -- just reads from order header, no fallback. Unused `ShopifyTaxArea` and `OrderMgt` variables removed.

### 2.5 New Event: OnAfterMapShopifyOrder

**File**: `src/Apps/W1/Shopify/App/src/Order handling/Codeunits/ShpfyOrderEvents.Codeunit.al`

New integration event fired at the end of `DoMapping()`:
```al
[IntegrationEvent(false, false)]
internal procedure OnAfterMapShopifyOrder(var ShopifyOrderHeader: Record "Shpfy Order Header"; Result: Boolean)
begin
end;
```

**File**: `src/Apps/W1/Shopify/App/src/Order handling/Codeunits/ShpfyOrderMapping.Codeunit.al`

Added at the end of `DoMapping()`, after all mapping procedures:
```al
OrderEvents.OnAfterMapShopifyOrder(OrderHeader, Result);
```

This fires everywhere `DoMapping` is called: sync report, Find Mappings action, ProcessOrder, and ReimportExistingOrderConfirmIfConflicting. The agent subscriber uses guards (mapping success, On Hold check, unmatched tax lines) to only act when appropriate.

### 2.7 New Field on Shpfy Order Tax Line: Tax Jurisdiction Code

**File**: `src/Apps/W1/Shopify/App/src/Order handling/Tables/ShpfyOrderTaxLine.Table.al`

Added directly to the table (not a table extension):
- Field 10: `Tax Jurisdiction Code` (Code[10]) - TableRelation to "Tax Jurisdiction"

This field maps each Shopify tax line to a BC Tax Jurisdiction. It can be set manually or by the agent. It is useful independently of the agent for visibility into how Shopify taxes correspond to BC jurisdictions.

### 2.8 Tax Area Code on Order Card Page

**File**: `src/Apps/W1/Shopify/App/src/Order handling/Pages/ShpfyOrder.Page.al`

Added `Tax Area Code` field to the InvoiceDetails group (after Channel Liable Taxes). This is a standard field on the order header that should be visible and editable on the order card.

### 2.9 Tax Jurisdiction Code on Tax Lines Page

**File**: `src/Apps/W1/Shopify/App/src/Order handling/Pages/ShpfyOrderTaxLines.Page.al`

- Removed page-level `Editable = false` and `ModifyAllowed = false`
- Added `Editable = false` to each existing Shopify-sourced field individually (Title, Rate, Amount, etc.)
- Added `Tax Jurisdiction Code` as the only editable field in the repeater

This allows the Tax Jurisdiction Code to be set on each tax line through the UI (by the agent or manually) while keeping all Shopify-sourced data read-only.

### 2.10 app.json Update

**File**: `src/Apps/W1/Shopify/App/app.json`

Added to `internalsVisibleTo`:
```json
{
    "id": "f8c7b6a5-d4e3-42f1-9a8b-7c6d5e4f3a2b",
    "publisher": "Microsoft",
    "name": "Shopify Tax Agent"
}
```

---

## Part 3: Agent App Implementation

### App Manifest

**File**: `src/Apps/W1/Shopify/ShpfyTaxAgent/app/app.json`

| Property | Value |
|---|---|
| ID | `f8c7b6a5-d4e3-42f1-9a8b-7c6d5e4f3a2b` |
| Name | Shopify Tax Agent |
| Publisher | Microsoft |
| ID Range | 30470 - 30499 |
| Dependency | Shopify Connector (`ec255f57-31d0-4ca2-b751-f2fa7c745abb`) v28.0.0.0 |
| Platform | 28.0.0.0 |
| Target | OnPrem |

### Object ID Allocations

| Object Type | ID | Name |
|---|---|---|
| Table | 30470 | `Shpfy Tax Agent Setup` |
| Table Extension | 30470 | `Shpfy Tax Ord. Header` extends `Shpfy Order Header` (On Hold field only) |
| Page | 30470 | `Shpfy Tax Agent Setup` (ConfigurationDialog) |
| Page Extension | 30471 | `Shpfy Tax Order` extends `Shpfy Order` (On Hold field) |
| Page Extension | 30472 | `Shpfy Tax Orders` extends `Shpfy Orders` (On Hold column) |
| Codeunit | 30470 | `Shpfy Tax Agent` (IAgentFactory + IAgentMetadata + Install) |
| Codeunit | 30471 | `Shpfy Tax Agent Task Exec.` (IAgentTaskExecution) |
| Codeunit | 30473 | `Shpfy Tax Agent Events` (event subscribers) |
| Enum Extension | 30470 | `Shpfy Tax Agent Metadata` extends `Agent Metadata Provider` |
| Enum Extension | 30471 | `Shpfy Tax Copilot Cap.` extends `Copilot Capability` |
| Permission Set | 30470 | `Shpfy Tax Agent` |

### File Structure

```
src/Apps/W1/Shopify/ShpfyTaxAgent/
  app/
    app.json
    .resources/
      Prompts/
        ShpfyTaxAgent-SystemPrompt.md          ← Agent instructions
    src/
      Codeunits/
        ShpfyTaxAgent.Codeunit.al              (30470 - IAgentFactory + IAgentMetadata + Install)
        ShpfyTaxAgentTaskExec.Codeunit.al      (30471 - IAgentTaskExecution)
        ShpfyTaxAgentEvents.Codeunit.al        (30473 - Event subscribers)
      Enum Extensions/
        ShpfyTaxAgentMetadata.EnumExt.al       (30470)
        ShpfyTaxCopilotCap.EnumExt.al          (30471)
      Page Extensions/
        ShpfyTaxOrder.PageExt.al               (30471 - Order Card: On Hold field)
        ShpfyTaxOrders.PageExt.al              (30472 - Orders List: On Hold column)
      Pages/
        ShpfyTaxAgentSetup.Page.al             (30470)
      PermissionSets/
        ShpfyTaxAgent.PermissionSet.al         (30470)
      Table Extensions/
        ShpfyTaxOrdHeader.TableExt.al          (30470 - On Hold field only)
      Tables/
        ShpfyTaxAgentSetup.Table.al            (30470)
```

---

### Detailed AL Object Specifications

#### 3.1 Enum Extension: Agent Metadata Provider (30470)
**File**: `src/Enum Extensions/ShpfyTaxAgentMetadata.EnumExt.al`

```al
enumextension 30470 "Shpfy Tax Agent Metadata" extends "Agent Metadata Provider"
{
    value(30470; "Shpfy Tax Agent")
    {
        Caption = 'Shopify Tax Matching Agent';
        Implementation =
            IAgentFactory = "Shpfy Tax Agent",
            IAgentMetadata = "Shpfy Tax Agent",
            IAgentTaskExecution = "Shpfy Tax Agent Task Exec.";
    }
}
```

#### 3.2 Enum Extension: Copilot Capability (30471)
**File**: `src/Enum Extensions/ShpfyTaxCopilotCap.EnumExt.al`

```al
enumextension 30471 "Shpfy Tax Copilot Cap." extends "Copilot Capability"
{
    value(30470; "Shpfy Tax Matching")
    {
        Caption = 'Shopify Tax Matching';
    }
}
```

#### 3.3 Table: Shpfy Tax Agent Setup (30470)
**File**: `src/Tables/ShpfyTaxAgentSetup.Table.al`

Setup table keyed by Shop Code — each shop can have at most one tax matching agent.

Fields:
- Field 1: `Shop Code` (Code[20]) - PK, CustomerContent, TableRelation to "Shpfy Shop"
- Field 2: `User Security ID` (Guid) - SystemMetadata
- Field 3: `Auto Create Tax Jurisdictions` (Boolean) - CustomerContent, InitValue = false
- Field 4: `Auto Create Tax Areas` (Boolean) - CustomerContent, InitValue = false
- Field 5: `Tax Area Naming Pattern` (Text[50]) - CustomerContent, InitValue = 'SHPFY-AUTO-'

Keys:
- PK: `Shop Code` (Clustered)
- `AgentUser`: `User Security ID` (secondary key, used to look up setup by agent)

Properties: `Access = Internal`, `Caption = 'Shopify Tax Agent Setup'`

#### 3.4 Table Extension: Shpfy Order Header - On Hold (30470)
**File**: `src/Table Extensions/ShpfyTaxOrdHeader.TableExt.al`

Extends `"Shpfy Order Header"` (table 30118). Agent-specific field only:
- Field 1104: `On Hold` (Boolean) - Caption = 'On Hold', InitValue = false

**Note**: The `Tax Area Code` field (1070) is directly on the `Shpfy Order Header` table in the standard connector (not a table extension). The `Tax Jurisdiction Code` field (10) is directly on the `Shpfy Order Tax Line` table in the standard connector. Both are standard mapping fields that exist independently of the agent.

#### 3.5 Codeunit: Shpfy Tax Agent (30470) - IAgentFactory + IAgentMetadata + Install
**File**: `src/Codeunits/ShpfyTaxAgent.Codeunit.al`

Implements both `IAgentFactory` and `IAgentMetadata`, plus `Subtype = Install` for Copilot capability registration.

**IAgentFactory methods**:
- `GetFirstTimeSetupPageId()` → `Page::"Shpfy Tax Agent Setup"` (30470)
- `ShowCanCreateAgent()` → `true`
- `GetDefaultProfile()` → 'BUSINESS MANAGER' profile
- `GetDefaultAccessControls()` → Empty (defaults)
- `GetCopilotCapability()` → `"Copilot Capability"::"Shpfy Tax Matching"`

**IAgentMetadata methods**:
- `GetSetupPageId()` → 30470
- `GetSummaryPageId()` → 0 (no summary page for prototype)
- `GetAgentTaskMessagePageId()` → 0 (use default)
- `GetAgentAnnotations()` → Error annotation if Copilot capability not registered

**Install trigger**:
- `OnInstallAppPerDatabase` → Calls `RegisterCapability()`

Also contains `SetAgentInstructions()` that loads from `.resources/Prompts/ShpfyTaxAgent-SystemPrompt.md` via `NavApp.GetResourceAsText()` and calls `Agent.SetInstructions()`.

#### 3.7 Codeunit: Shpfy Tax Agent Task Exec. (30471) - IAgentTaskExecution
**File**: `src/Codeunits/ShpfyTaxAgentTaskExec.Codeunit.al`

Implements `IAgentTaskExecution`.

**Methods**:
- `AnalyzeAgentTaskMessage()` → Minimal for prototype (no special message analysis)
- `GetAgentTaskUserInterventionSuggestions()` → Two suggestions:
  - "Create Tax Jurisdiction" (when agent can't find a match)
  - "Assign Tax Area" (when agent can't find or create a Tax Area)
- `GetAgentTaskPageContext()` → Default context

#### 3.9 Codeunit: Shpfy Tax Agent Events (30473)
**File**: `src/Codeunits/ShpfyTaxAgentEvents.Codeunit.al`

Event subscribers for integration with the existing Shopify order flow.

**Subscriber 1**: `OnAfterMapShopifyOrder` (from `Shpfy Order Events` codeunit 30162, fired at end of `DoMapping`)
- Checks in order: **mapping succeeded** (`Result`) → **not already On Hold** → **enabled agent exists for shop** → **order has unmatched tax lines** (Tax Jurisdiction Code = '')
- Having an enabled agent for the shop IS the enable flag — no separate `Enable LLM Tax Matching` toggle needed
- The On Hold guard prevents duplicate tasks (e.g., when ProcessOrder calls DoMapping for an agent-processed order)
- The unmatched tax lines guard prevents re-processing orders the agent already handled (jurisdiction codes already set)
- If all checks pass: Set `On Hold` = true, create Agent Task via `AgentTaskBuilder`
- `CreateAgentTask` receives the Agent record AND the `TaxAgentSetup` record, and includes the agent's configuration settings (Auto Create Tax Jurisdictions, Auto Create Tax Areas, Tax Area Naming Pattern) in the task message text

**Helper**: `FindTaxAgentForShop(ShopCode: Code[20]; var Agent: Record Agent; var TaxAgentSetup: Record "Shpfy Tax Agent Setup"): Boolean`
- Uses `TaxAgentSetup.Get(ShopCode)` (direct PK lookup since Shop Code is the primary key)
- Then verifies `Agent.Get(TaxAgentSetup."User Security ID")` and `Agent.State = Enabled`
- Returns both the Agent and TaxAgentSetup records for use by CreateAgentTask
- Returns false at any step if lookup fails or agent is disabled

**Subscriber 2**: `OnBeforeProcessSalesDocument` (from `Shpfy Order Events` codeunit 30162)
- If order `On Hold` = true, raise Error to block sales document creation

#### 3.10 Page: Shpfy Tax Agent Setup (30470)
**File**: `src/Pages/ShpfyTaxAgentSetup.Page.al`

`PageType = ConfigurationDialog`, `SourceTable = Agent`, `SourceTableTemporary = true`

Layout:
1. Agent Info group: Badge, Name, State, Manage User Access link
2. Configuration group:
   - Shop Code (bound to local variable, lookup to Shpfy Shop)
   - Auto Create Tax Jurisdictions (bound to local variable)
   - Auto Create Tax Areas (bound to local variable)
   - Tax Area Naming Pattern (bound to local variable)
3. About group: Summary text

Actions:
- `systemaction(OK)` - Caption = 'Update', enabled when `SetupChanged`
- `systemaction(Cancel)` - Caption = 'Cancel'

**One-agent-per-shop enforcement**: The Shop Code field's OnValidate checks if another agent already owns that shop (`ExistingSetup.Get(ShopCode)` + compare User Security IDs). Raises an error if the shop is already assigned to a different agent.

OnOpenPage: Validates Copilot capability is enabled. Loads existing shop code and configuration fields via `SetRange("User Security ID")` on the secondary key.
OnQueryClosePage: Saves all configuration fields to setup record. If shop code changed, deletes old setup record and inserts new one keyed by the new Shop Code. Sets agent instructions from resource file.

#### 3.11 Page Extension: Shpfy Order Card (30471)
**File**: `src/Page Extensions/ShpfyTaxOrder.PageExt.al`

Extends `"Shpfy Order"` (page 30113).

Adds `On Hold` field to the General group (`addlast(General)`). This allows the agent and users to see and modify the hold status directly on the order card.

#### 3.13 Page Extension: Shpfy Orders List (30472)
**File**: `src/Page Extensions/ShpfyTaxOrders.PageExt.al`

Extends `"Shpfy Orders"` (page 30115).

Adds `On Hold` column after `Closed` in the list repeater. This allows the agent to filter for on-hold orders and gives users visibility into which orders are awaiting tax matching.

#### 3.14 Permission Set: Shpfy Tax Agent (30470)
**File**: `src/PermissionSets/ShpfyTaxAgent.PermissionSet.al`

```
IncludedPermissionSets = "Shpfy - Edit";
Permissions =
    table "Shpfy Tax Agent Setup" = X,
    tabledata "Shpfy Tax Agent Setup" = RIMD,
    tabledata "Tax Area" = RIMD,
    tabledata "Tax Area Line" = RIMD,
    tabledata "Tax Jurisdiction" = RIMD,
    codeunit "Shpfy Tax Agent" = X,
    codeunit "Shpfy Tax Agent Task Exec." = X,
    codeunit "Shpfy Tax Agent Events" = X,
    page "Shpfy Tax Agent Setup" = X;
```

---

## Part 4: Critical Existing Files

These files must be read/understood:

| File | Why |
|---|---|
| `src/Apps/W1/Shopify/App/src/Order handling/Tables/ShpfyOrderTaxLine.Table.al` | Internal table being extended; Parent Id links to Order Line, not Order Header directly |
| `src/Apps/W1/Shopify/App/src/Order handling/Tables/ShpfyOrderHeader.Table.al` | Public table being extended; 135+ fields |
| `src/Apps/W1/Shopify/App/src/Base/Tables/ShpfyShop.Table.al` | Public table; agent events read Shop Code from order headers |
| `src/Apps/W1/Shopify/App/src/Order handling/Codeunits/ShpfyOrderMapping.Codeunit.al` | New `MapTaxArea()` procedure added; Tax Area lookup moved here from ProcessOrder |
| `src/Apps/W1/Shopify/App/src/Order handling/Codeunits/ShpfyProcessOrder.Codeunit.al` | Line 129: simplified to just read Tax Area Code from order header (no fallback) |
| `src/Apps/W1/Shopify/App/src/Order Return Refund Processing/Codeunits/ShpfyCreateSalesDocRefund.Codeunit.al` | Line 123: same simplification |
| `src/Apps/W1/Shopify/App/src/Order handling/Codeunits/ShpfyOrderEvents.Codeunit.al` | Public codeunit; all integration events we subscribe to (including new `OnAfterMapShopifyOrder`) |
| `src/Apps/W1/Shopify/App/src/Order handling/Codeunits/ShpfyOrderMgt.Codeunit.al` | Internal codeunit; `FindTaxArea()` method for address-based lookup |
| `src/Apps/W1/Shopify/App/src/Customers/Tables/ShpfyTaxArea.Table.al` | Internal table (30109); existing Country/County → Tax Area mapping |
| `src/Apps/W1/Shopify/App/src/Order handling/Pages/ShpfyOrder.Page.al` | Order Card page (30113); Tax Area Code field added in InvoiceDetails group |
| `src/Apps/W1/Shopify/App/src/Order handling/Pages/ShpfyOrders.Page.al` | Orders List page (30115); extended by agent app to add On Hold column |
| `src/Apps/W1/Shopify/App/src/Order handling/Pages/ShpfyOrderTaxLines.Page.al` | Tax Lines page (30168); made partially editable for Tax Jurisdiction Code |
| `src/Apps/W1/Shopify/App/app.json` | ID range 30100-30460; `internalsVisibleTo` updated for agent app |

---

## Part 5: Key Design Decisions

1. **Two-App Architecture**: Agent-specific code lives in a separate app (`ShpfyTaxAgent`) that depends on the standard Shopify Connector. Generic improvements (Tax Area Code field, ProcessOrder/Refund changes) stay in the connector. This keeps the connector clean and allows the agent to be deployed independently.

2. **`internalsVisibleTo`**: The agent app needs access to internal connector objects (`Shpfy Order Tax Line`, `Shpfy Tax Area`, `Shpfy Order Mgt.`). The connector's `app.json` grants this via `internalsVisibleTo`.

3. **Field Ownership**: The `Tax Area Code` field (1070) is added directly to the `Shpfy Order Header` table (30118) because it's a standard mapping concern -- populated by `MapTaxArea`, read by ProcessOrder. The `On Hold` field (1104) is in the agent app's table extension (30470) because it's only used by agent logic. Agent configuration fields (Auto Create Tax Jurisdictions, Auto Create Tax Areas, Tax Area Naming Pattern) live on the `Shpfy Tax Agent Setup` table — not on the Shop table — because they are per-agent settings, and having an enabled agent for a shop IS the feature toggle (no separate `Enable LLM Tax Matching` flag needed).

4. **Tax Area Mapping Moved to OrderMapping (Step 2.1)**: The address-based Tax Area lookup (`OrderMgt.FindTaxArea`) was moved from ProcessOrder to `OrderMapping.MapTaxArea()`. This runs during the standard mapping step, storing the result in `OrderHeader."Tax Area Code"`. ProcessOrder and CreateSalesDocRefund simply read from this field with no fallback. This benefits all users (not just agent users) and follows the same pattern as other mappings (shipping method, payment method, etc.). The `MapTaxArea` guard (`if OrderHeader."Tax Area Code" <> '' then exit`) ensures that if the agent (or any other mechanism) has already set the field, the address-based lookup is skipped.

5. **Tax Line Parent Id**: The `Shpfy Order Tax Line.Parent Id` links to Order Line IDs, NOT Order Header IDs. To get all tax lines for an order: `OrderLine.SetRange("Shopify Order Id", OrderId)` then for each line `TaxLine.SetRange("Parent Id", OrderLine."Line Id")`.

6. **On Hold Enforcement**: The agent subscribes to `OnBeforeProcessSalesDocument` to raise an Error when the order is on hold. This prevents processing orders that haven't been tax-matched yet.

7. **Shpfy Tax Area Mapping**: The agent is instructed to navigate to the Shopify Customer Templates page (via Shop Card → "Customer Setup by Country/Region") and create records in the `Shpfy Tax Area` table (30109) after processing an order. This teaches the standard connector's address-based lookup to handle future orders from the same Country+County automatically. All Tax Area creation and mapping is done by the agent through the UI — there is no server-side business logic codeunit for this.

8. **One Agent Per Shop**: The setup table is keyed by Shop Code (PK), enforcing that each shop can have at most one tax matching agent. The setup page validates on Shop Code change that the shop isn't already assigned to a different agent. `FindTaxAgentForShop` uses a direct `Get(ShopCode)` PK lookup for simplicity.

9. **Event at End of DoMapping**: The `OnAfterMapShopifyOrder` event fires at the end of `DoMapping()` in the `OrderMapping` codeunit, passing the mapping result. This means it fires everywhere DoMapping is called (sync report, Find Mappings, ProcessOrder, reimport). The agent subscriber uses multiple guards to only act when appropriate: (1) `Result` must be true (mapping succeeded), (2) order must not already be On Hold (prevents duplicate tasks), (3) enabled agent must exist for the shop, (4) order must have unmatched tax lines (Tax Jurisdiction Code = ''). Guard #4 also prevents the agent from re-firing when ProcessOrder calls DoMapping for an already-processed order. The agent's configuration settings are included in the task message so the agent knows its permissions without navigating to any setup page.

10. **Prototype Simplicity**: No KPI page, no summary page, no billing tracking, no dedicated role center. The agent uses the default Business Manager profile. These can be added later.

---

## Part 6: Verification

1. **Compile connector**: Build the Shopify Connector app -- the new fields on Order Header/Tax Line tables and ProcessOrder/Refund/OrderMapping changes should compile
2. **Compile agent app**: Build the Shopify Tax Agent app -- all 11 objects should compile with the connector as a dependency
3. **Deploy to sandbox**: Publish both apps to a BC sandbox environment (v28.0+)
4. **Enable capability**: Go to Copilot & AI Capabilities page, enable "Shopify Tax Matching"
5. **Create agent**: On the Agents page, create a new Shopify Tax Matching Agent
6. **Configure agent**: On the agent setup page, set the Shop Code and optionally enable auto-create options
7. **Import test order**: Import a Shopify order with tax lines → verify order gets "On Hold" = true and Tax Area Code is pre-populated from address lookup
8. **Run agent task**: The agent task should have been created automatically → verify it processes the order per instructions
9. **Verify result**: Check the order has Tax Area Code set (possibly overridden by agent) and On Hold = false
10. **Create sales document**: Process the order → verify the sales header gets the Tax Area Code from the order header
