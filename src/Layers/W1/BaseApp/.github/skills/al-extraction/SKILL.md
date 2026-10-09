---
name: al-extraction
description: Extract feature modules from AL objects (tables, pages) into extensions for better modularity
applyTo:
  - "**/*.Table.al"
  - "**/*.Page.al"
  - "**/*.Codeunit.al"
  - "**/*.PermissionSet.al"
  - "**/*.PermissionSetExt.al"
---

# AL Feature Extraction Skill

This skill provides a comprehensive workflow for extracting feature-specific functionality from AL objects (tables and pages) into table/page extensions for better modularity and namespace separation.

## When to Use This Skill

- Extracting a feature module (e.g., Intercompany) from base AL objects
- Separating concerns in large monolithic AL objects
- Organizing code by namespace and feature boundaries
- Improving maintainability and modularity

## 8-Step Workflow

### 1. Identify Feature Elements

**For Tables:**
- Search for feature-related fields using `grep_search` with patterns like `field\(.*Feature|Feature.*field`
- Look for feature-specific using statements (e.g., `using Microsoft.Intercompany.*`)
- Identify feature-specific procedures/triggers in table code

**For Pages:**
- Search for feature-related controls, actions, and parts using `grep_search`
- Look for feature-specific using statements
- Check for feature-specific variables and procedures

**Example:**
```powershell
grep_search(includePattern="**/ObjectName.*.al", query="Intercompany|IC Partner|IC Account", isRegexp=true)
```

### 2. Create Extension File

**Location:** Place in feature-specific folder (e.g., `Finance/Intercompany/`)

**Naming Convention:**
- Table extensions: `{Feature}{BaseTable}.TableExt.al` (e.g., `ICPostedGenJnlLine.TableExt.al`)
- Page extensions: `{Feature}{BasePage}.PageExt.al` (e.g., `ICDimensions.PageExt.al`)
- **Object name length must be <= 30 characters** (AL limit)
- **Object name must match the file name stem** (without `.TableExt.al`/`.PageExt.al`), for example `ICPostedPurchInvoiceSubform.PageExt.al` -> `ICPostedPurchInvoiceSubform`

**Object ID Selection:**
- Search existing extension IDs to avoid conflicts
- Use next available ID in feature range

**Namespace:**
- **CRITICAL:** Use the SAME namespace as the base object, NOT the feature namespace
- Example: If base table is in `Microsoft.Finance.GeneralLedger.Journal`, extension must use `Microsoft.Finance.GeneralLedger.Journal`

**Template:**
```al
// Copyright header
namespace Microsoft.Original.Namespace.From.BaseObject;

using Microsoft.Feature.Namespace1;
using Microsoft.Feature.Namespace2;

/// <summary>
/// Extends [Base Object] with [Feature]-specific functionality.
/// [Description of what the extension adds]
/// </summary>
[tableextension|pageextension] [ID] "[Feature] [Base Name]" extends "[Base Object Name]"
{
    // Extension content
}
```

### 3. Move Elements to Extension

**For Table Extensions:**
- Copy field definitions with all properties
- **MANDATORY:** Add `DataClassification = CustomerContent;` to EVERY field
- Maintain field numbers and structure
- Include compiler directives (e.g., `#if not CLEANSCHEMA25`) if present
- Copy field-level documentation comments

**Field Properties Order:**
1. Caption
2. **DataClassification** (REQUIRED)
3. Editable
4. TableRelation
5. Other properties
6. ObsoleteReason, ObsoleteState, ObsoleteTag (if applicable)

**For Page Extensions:**
- Move controls/actions with proper positioning (`addafter`, `addbefore`, `addlast`, `addfirst`)
- Ensure action names are globally unique (prefix with feature abbreviation if needed)
- Move related variables and procedures

### 4. Move Variables and Procedures

- Move feature-specific variables from base object to extension
- Move feature-specific procedures/functions
- Update XML documentation comments
- Verify all dependencies are resolved

### 5. Clean Base Object

**Use `multi_replace_string_in_file` for efficiency:**

**Remove:**
- Feature-specific using statements (keep those still needed by base object references)
- Extracted fields/controls/actions
- Feature-specific variables and procedures
- Update XML documentation to reflect removal

**Important:** 
- Keep using statements if base object still references feature types (e.g., enum options)
- Test compilation after each removal

### 6. Update Documentation

- Update XML doc comments in base object to indicate feature was extracted
- Ensure extension has complete documentation for all elements moved
- Document any behavioral changes or dependencies

### 7. Validate Compilation

**Check both files:**
```powershell
get_errors(filePaths=["path/to/BaseObject.al", "path/to/Extension.al"])
```

**Common Issues:**
- Missing DataClassification on fields
- Namespace mismatch (extension must match base object namespace)
- Object ID conflicts
- Missing using statements
- Referenced tables/types not imported
- Action name conflicts in page extensions

### 8. Verify Functionality

- Confirm all feature elements moved successfully
- Verify no duplicate definitions
- Ensure base object still compiles
- Check for any broken references

## Table-Specific Guidance

### Field Extraction Checklist

- [ ] Field number preserved
- [ ] Caption property present
- [ ] **DataClassification property added (MANDATORY)**
- [ ] TableRelation preserved (if applicable)
- [ ] Editable property preserved (if set)
- [ ] Compiler directives maintained (if applicable)
- [ ] XML documentation complete
- [ ] ObsoleteReason/State/Tag for deprecated fields (if applicable)

### Example Table Extension

```al
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.GLAccount;

tableextension 8420 "IC Posted Gen. Jnl. Line" extends "Posted Gen. Journal Line"
{
    fields
    {
        /// <summary>
        /// Intercompany partner code for transaction processing.
        /// </summary>
        field(113; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        
        field(114; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';
            DataClassification = CustomerContent;
        }
    }
}
```

## Page-Specific Guidance

### Action Naming

**Avoid Conflicts:**
- Use feature prefix for action names (e.g., `ICGeneralJournals` instead of `GeneralJournals`)
- AL requires globally unique action names within the final compiled page
- Even after removing from base page, names must be unique in extension

### Control Positioning

**Use Specific Anchors:**
- Reference exact control IDs or action names from base page
- Confirm anchor exists using `grep_search` or `read_file`
- Use `addafter`, `addbefore`, `addlast`, or `addfirst` appropriately

### Integration Events in Triggers and Procedures

When extracting feature logic from a trigger or procedure, replace the feature code with an integration event call. The placement of the event call follows a strict convention:

- **`OnBeforeXxx()`** — must be the **first line** of the trigger/procedure body
- **`OnAfterXxx()`** — must be the **last line** of the trigger/procedure body

**Example — `OnOpenPage` trigger:**
```al
trigger OnOpenPage()
begin
    OnBeforeOpenPage(Rec);      // FIRST line
    SetOpenPage();
    ActivateFields();
    CheckShowBackgrValidationNotification();
    VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
    OnAfterOpenPage(Rec);       // LAST line
end;
```

**Example — local procedure:**
```al
local procedure UpdateICPartner()
begin
    OnBeforeUpdateICPartner(Rec);   // FIRST line
    // ... other logic ...
    OnAfterUpdateICPartner(Rec);    // LAST line
end;
```

This pattern ensures subscribers can initialize state before any logic runs (`OnBefore`) and react to the completed state (`OnAfter`).

### Example Page Extension

```al
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;

pageextension 8406 "IC Accountant Role Center" extends "Accountant Role Center"
{
    layout
    {
        addlast(RoleCenter)
        {
            part(ICActivitiesPart; "IC Activities")
            {
                ApplicationArea = Intercompany;
            }
        }
    }
    
    actions
    {
        addafter(Action123)
        {
            action(ICGeneralJournals)
            {
                ApplicationArea = Intercompany;
                Caption = 'IC General Journal';
                RunObject = page "IC General Journal";
                Tooltip = 'Open IC General Journal.';
            }
        }
    }
}
```

## Permission Set-Specific Guidance

### When to Extract Permission Sets

Extract feature-specific permissions into a `permissionsetextension` when:
- A base permission set (e.g., `D365 AUTOMATION`) needs access to feature-specific tables
- Keeping feature table permissions in the base set creates unnecessary coupling
- The feature has dedicated tables that should only be exposed when the feature is present

### Naming Convention

```
{FeatureAbbreviation}{BasePermSetName}.PermissionSetExt.al
```

Examples:
- `ICD365Automation.PermissionSetExt.al` — IC module extending `D365 AUTOMATION`
- `ICD365Basic.PermissionSetExt.al` — IC module extending `D365 BASIC`

### Namespace

Use `System.Security.AccessControl` — this is the standard namespace for all permission set objects and extensions.

### Object ID

Choose the next available ID in the feature's reserved range (e.g., IC extensions use 8400+).

### Permission Codes

Common permission abbreviations:
- `R` — Read
- `I` — Insert
- `M` — Modify
- `D` — Delete
- `RIMD` — Full access (Read, Insert, Modify, Delete)
- `RI` — Read and Insert only
- `R` — Read only

### Template

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Feature.Table1Namespace;
using Microsoft.Feature.Table2Namespace;

permissionsetextension 8400 "IC D365 AUTOMATION" extends "D365 AUTOMATION"
{
    Permissions =
                  tabledata "Feature Table 1" = RIMD,
                  tabledata "Feature Table 2" = RIMD;
}
```

### Example (Intercompany)

```al
namespace System.Security.AccessControl;

using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

permissionsetextension 8400 "IC D365 AUTOMATION" extends "D365 AUTOMATION"
{
    Permissions =
                  tabledata "IC Bank Account" = RIMD,
                  tabledata "IC Partner" = RIMD,
                  tabledata "IC Setup" = RIMD;
}
```

### Workflow for Permission Set Extraction

1. **Identify** feature-specific tables currently listed in the base permission set
2. **Create** a `permissionsetextension` file in the feature's `Permissions/` folder
3. **Move** the feature table entries to the new extension
4. **Add** the necessary `using` statements for each table's namespace
5. **Remove** the moved entries from the base permission set
6. **Validate** with `get_errors` on both files

### Checklist

- [ ] Namespace is `System.Security.AccessControl`
- [ ] Object ID is unique within the feature range
- [ ] All feature tables moved from base permission set
- [ ] Using statements added for each table namespace
- [ ] Entries sorted alphabetically (consistent style)
- [ ] Both base and extension compile without errors

## Common Pitfalls and Solutions

### Problem: Compilation errors about duplicate fields
**Solution:** Ensure fields were properly removed from base object

### Problem: "Table X is missing" errors
**Solution:** Add necessary using statements to base object if it references feature types

### Problem: "Object ID already declared"
**Solution:** Search for existing IDs and choose an available one in the feature range

### Problem: Action name conflicts in pages
**Solution:** Rename actions in extension with feature prefix to ensure global uniqueness

### Problem: Fields missing DataClassification
**Solution:** Add `DataClassification = CustomerContent;` to every field in table extensions

### Problem: Wrong namespace in extension
**Solution:** Match extension namespace to base object namespace, not feature namespace

## Efficiency Tips

- Use `multi_replace_string_in_file` for batch removal operations instead of sequential edits
- Use `grep_search` with regex to find all feature references in one search
- Read larger file sections rather than making multiple small reads
- Parallelize independent file reads when gathering context

## Validation Checklist

- [ ] Extension uses same namespace as base object
- [ ] All fields have DataClassification property
- [ ] Object ID is unique and available
- [ ] Extension file created in correct feature folder
- [ ] All feature-specific using statements moved to extension
- [ ] Base object cleaned of extracted elements
- [ ] Both base object and extension compile without errors
- [ ] No duplicate field/action definitions
- [ ] XML documentation complete and accurate
- [ ] Action names are globally unique (for pages)
- [ ] Control anchors exist in base page (for page extensions)

## Notes

- Always validate with `get_errors` after major changes
- Keep base object references when extracting (e.g., if Account Type enum includes IC Partner)
- Document the extraction in both base object and extension XML comments
- Test incrementally - extract, clean, validate before moving to next object

## Recent Extractions Case Study - Bank/Reconciliation IC Partner Support

**Extraction Cycle:** April 2026

### Overview
Extracted IC Partner account type support from 6 Bank/Reconciliation tables into dedicated table extensions to support Intercompany module integration with payment reconciliation features.

### Tables Extracted

#### 1. Applied Payment Entry (Table 1294) → ICAppliedPaymentEntry.TableExt.al (ID 8415)
**Extraction:** IC Partner TableRelation from "Account No." field (field 22)
- Base file: `AppliedPaymentEntry.Table.al`
- Extension: `ICAppliedPaymentEntry.TableExt.al`
- Namespace: `Microsoft.Bank.Reconciliation`
- Change: Removed `if ("Account Type" = const("IC Partner")) "IC Partner"` TableRelation condition
- Status: ✅ Validated - no compile errors

#### 2. Payment Application Proposal (Table 1293) → ICPaymentApplProposal.TableExt.al (ID 8416)
**Extraction:** IC Partner TableRelation from "Account No." field (field 22)
- Base file: `PaymentApplicationProposal.Table.al`
- Extension: `ICPaymentApplProposal.TableExt.al`
- Namespace: `Microsoft.Bank.Reconciliation`
- Change: Removed `if ("Account Type" = const("IC Partner")) "IC Partner"` TableRelation condition
- Status: ✅ Validated - no compile errors

#### 3. Posted Payment Recon. Line (Table 1296) → ICPostedPaymentReconLine.TableExt.al (ID 8417)
**Extraction:** IC Partner TableRelation from "Account No." field (field 22)
- Base file: `PostedPaymentReconLine.Table.al`
- Extension: `ICPostedPaymentReconLine.TableExt.al`
- Namespace: `Microsoft.Bank.Reconciliation`
- Change: Removed `if ("Account Type" = const("IC Partner")) "IC Partner"` TableRelation condition
- Status: ✅ Validated - no compile errors

#### 4. Bank Acc. Reconciliation Line (Table 1287) - Validation Logic Extraction
**Extraction:** IC Partner validation dialog and confirmation logic
- Base file: `BankAccReconciliationLine.Table.al`
- Changes made:
  - Removed ConfirmManagement codeunit variable
  - Removed ICPartnerAccountTypeQst label
  - Removed IC Partner account type validation confirmation from OnValidate trigger
  - Kept necessary `using Microsoft.Intercompany.Partner;` statement (still used in "Account No." TableRelation)
- Status: ⚠️ Validation shows warning - kept necessary using statement to maintain TableRelation functionality

### Object ID Range
Assigned IDs **8415-8417** from available range reserved for Microsoft.Bank.Reconciliation IC extensions.

### Key Learnings

1. **TableRelation Strategy:** When removing IC Partner from base table TableRelation, always create a matching tableextension with the IC Partner condition modified in the extension. This allows feature-specific account types to be supported without bloating the base object.

2. **Using Statement Retention Rule:** Keep using statements if:
   - Referenced in TableRelation conditions (e.g., `"Account Type" = const("IC Partner")`)
   - Used by enum options or field properties
   - Required by procedures still in base object
   
   Only remove if truly unused after extraction.

3. **Namespace Consistency:** All extensions used `Microsoft.Bank.Reconciliation` (matching base tables), not the Intercompany module namespace, despite moving IC Partner support.

4. **Pattern for Account Type Extensions:** For tables with `Account Type` enum fields that include IC Partner:
   - Extract the IC Partner condition from the Account No. field's TableRelation
   - Create tableextension with modify on "Account No." field
   - Add conditional TableRelation targeting IC Partner

### Validation Results Summary

| Table | Extension | Status |
|-------|-----------|--------|
| Applied Payment Entry | ICAppliedPaymentEntry.TableExt.al (8415) | ✅ Clean |
| Payment Application Proposal | ICPaymentApplProposal.TableExt.al (8416) | ✅ Clean |
| Posted Payment Recon. Line | ICPostedPaymentReconLine.TableExt.al (8417) | ✅ Clean |
| Bank Acc. Reconciliation Line | Validation logic removed | ⚠️ Functional but using kept |

### Tool Usage Notes

- Used `grep_search` with "IC Partner" pattern to identify all affected tables (112 matches found)
- Used `file_search` to discover 17 table files in Bank/Reconciliation folder for analysis
- Applied `replace_string_in_file` for targeted TableRelation removals
- Validated with `get_errors` after each modification
- Used navigation selection in VS Code to identify exact line numbers for replacement

## Codeunit Extraction with SingleInstance and Event-Driven Isolation

This section documents patterns used when extracting feature logic from a **large posting codeunit** (e.g., `Purch.-Post`) into a dedicated feature codeunit (e.g., `IC Purch.-Post`). This is more complex than table/page extraction because the feature code participates in a multi-step stateful process.

**Reference implementation:** `ICPurchPost.Codeunit.al` (ID 8452) extracted from `PurchPost.Codeunit.al`

---

### Pattern 1: SingleInstance Codeunit for Stateful Feature Module

When the extracted feature codeunit must maintain state **across multiple event callbacks** that fire at different points during a single posting flow, declare it as `SingleInstance = true`.

```al
codeunit 8452 "IC Purch.-Post"
{
    SingleInstance = true;

    var
        TempICGenJnlLine: Record "Gen. Journal Line" temporary;
        TempInvoicePostingParameters: Record "Invoice Posting Parameters" temporary;
        PurchInvoicePostingInterface: Interface "Invoice Posting";
        PurchSuppressCommit: Boolean;
        ICGenJnlLineNo: Integer;
    ...
}
```

**When to use:** The extracted codeunit needs to accumulate data (e.g., temporary journal lines) during one phase and process it during a later phase of the same posting run, without those values being passed as procedure parameters through the base codeunit.

**Do NOT use** `SingleInstance` if the extracted codeunit only responds to a single event and does not need to share state between calls.

---

### Pattern 2: Event-Driven Lifecycle — Clear → Capture → Accumulate → Flush

Instead of being called directly from the base posting codeunit, the extracted codeunit subscribes to integration events and participates in discrete lifecycle phases:

| Phase | Event in base codeunit | Action in extracted codeunit |
|---|---|---|
| **Clear** | `OnAfterClearAllVariables` | Reset all accumulated state (`TempICGenJnlLine.DeleteAll()`) |
| **Capture** | `OnAfterGetInvoicePostingSetup` | Store posting context (`InvoicePostingInterface`, `InvoicePostingParameters`, `SuppressCommit`) |
| **Accumulate** | `OnPostPurchLineOnGLAccount` | Collect feature-specific journal lines per document line |
| **Flush** | `OnRunOnAfterPostInvoice` | Post all accumulated data in one batch |

**Example — Clear phase:**
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnAfterClearAllVariables, '', true, false)]
local procedure OnAfterClearAllVariables()
begin
    TempICGenJnlLine.DeleteAll();
end;
```

**Example — Capture phase (state from base codeunit captured via event, not parameter):**
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnAfterGetInvoicePostingSetup, '', true, false)]
local procedure OnAfterGetInvoicePostingSetup(var InvoicePostingInterface: Interface "Invoice Posting"; InvoicePostingParameters: Record "Invoice Posting Parameters"; SuppressCommit: Boolean)
begin
    PurchInvoicePostingInterface := InvoicePostingInterface;
    TempInvoicePostingParameters := InvoicePostingParameters;
    PurchSuppressCommit := SuppressCommit;
end;
```

**Example — Flush phase:**
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnRunOnAfterPostInvoice, '', true, false)]
local procedure OnRunOnAfterPostInvoice(...; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
begin
    if ICGenJnlLineNo > 0 then
        PostICGenJnl(GenJnlPostLine);
end;
```

---

### Pattern 3: Replacing Direct Calls with Event Subscribers

Procedures previously called directly from the base codeunit are replaced by event subscribers. The base codeunit fires a new integration event; the extracted codeunit subscribes to it and calls the local procedures.

**Before extraction (in base codeunit):**
```al
// Direct call in CheckAndUpdate procedure:
CheckICPartnerBlocked(PurchHeader);
SendICDocument(PurchHeader, ModifyHeader);
UpdateHandledICInboxTransaction(PurchHeader);
```

**After extraction — base codeunit fires an event instead:**
```al
// In CheckAndUpdate:
OnCheckAndUpdateOnBeforeLockTables(PurchHeader, ModifyHeader);
```

**Extracted codeunit subscribes:**
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnCheckAndUpdateOnBeforeLockTables, '', true, false)]
local procedure OnCheckAndUpdateOnBeforeLockTables(var PurchHeader: Record "Purchase Header"; var ModifyHeader: Boolean)
begin
    CheckICPartnerBlocked(PurchHeader);
    SendICDocument(PurchHeader, ModifyHeader);
    UpdateHandledICInboxTransaction(PurchHeader);
end;
```

This means the base codeunit has **zero direct dependency** on the extracted codeunit.

---

### Pattern 4: Backward Compatibility — Bridge Procedures in Base + Pair Calls in Extracted Codeunit

This is a two-part pattern. Both parts are required to ensure legacy subscribers (extensions that subscribed to the old events in the base codeunit) continue to work after extraction.

#### Part A — Bridge procedures in the base codeunit (`PurchPost.Codeunit.al`)

Every obsoleted IC event in the base codeunit gets:
1. An `internal procedure RunOnXxx(...)` that re-raises the old event — this is what the extracted codeunit calls
2. The old `[IntegrationEvent]` marked `[Obsolete]`, kept behind `#if not CLEAN29`

```al
#if not CLEAN29
    internal procedure RunOnBeforeInsertICGenJnlLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var ICGenJnlLineNo: Integer; var IsHandled: Boolean)
    begin
        OnBeforeInsertICGenJnlLine(PurchaseHeader, PurchaseLine, ICGenJnlLineNo, IsHandled);
    end;

    [Obsolete('Moved to codeunit ICPurchPost', '29.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertICGenJnlLine(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var ICGenJnlLineNo: Integer; var IsHandled: Boolean)
    begin
    end;
#endif
```

#### Part B — Pair calls in the extracted codeunit (`ICPurchPost.Codeunit.al`)

The extracted codeunit holds a reference to `Purch.-Post` as a codeunit variable (guarded by `#if not CLEAN29`):

```al
var
#if not CLEAN29
    PurchPost: Codeunit "Purch.-Post";
#endif
```

After every call to its own new integration event, the extracted codeunit immediately makes a **paired call** to the corresponding `RunOnXxx` bridge on the base codeunit — also guarded by `#if not CLEAN29`. This ensures any extension that subscribed to the old event in `Purch.-Post` is still notified.

```al
local procedure InsertICGenJnlLine(...)
begin
    IsHandled := false;
    OnBeforeInsertICGenJnlLine(PurchHeader, PurchLine, ICGenJnlLineNo, IsHandled);  // new event (subscribers use this going forward)
#if not CLEAN29
    PurchPost.RunOnBeforeInsertICGenJnlLine(PurchHeader, PurchLine, ICGenJnlLineNo, IsHandled);  // backward compat: fires old event in PurchPost
#endif
    if IsHandled then
        exit;
    ...
    OnInsertICGenJnlLineOnBeforeICGenJnlLineInsert(TempICGenJnlLine, PurchHeader, PurchLine, PurchSuppressCommit);
#if not CLEAN29
    PurchPost.RunOnInsertICGenJnlLineOnBeforeICGenJnlLineInsert(TempICGenJnlLine, PurchHeader, PurchLine, PurchSuppressCommit);
#endif
    TempICGenJnlLine.Insert();
end;
```

The same pair-call pattern is applied **at every integration event call site** inside the extracted codeunit, regardless of event type (`OnBefore`, `OnAfter`, `OnXxxOnBefore`, `OnXxxOnAfter`):

| Call site in `ICPurchPost` | New event fired | Legacy bridge called |
|---|---|---|
| `InsertICGenJnlLine` | `OnBeforeInsertICGenJnlLine` | `PurchPost.RunOnBeforeInsertICGenJnlLine` |
| `InsertICGenJnlLine` (after copy fields) | `OnInsertICGenJnlLineOnAfterCopyDocumentFields` | `PurchPost.RunOnInsertICGenJnlLineOnAfterCopyDocumentFields` |
| `InsertICGenJnlLine` (before insert) | `OnInsertICGenJnlLineOnBeforeICGenJnlLineInsert` | `PurchPost.RunOnInsertICGenJnlLineOnBeforeICGenJnlLineInsert` |
| `ValidateICPartnerBusPostingGroups` | `OnBeforeValidateICPartnerBusPostingGroups` | `PurchPost.RunOnBeforeValidateICPartnerBusPostingGroups` |
| `CheckICDocumentDuplicatePosting` | `OnBeforeCheckICDocumentDuplicatePosting` | `PurchPost.RunOnBeforeCheckICDocumentDuplicatePosting` |
| `CheckICDocumentDuplicatePosting` | `OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckPosted` | `PurchPost.RunOnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckPosted` |
| `CheckICDocumentDuplicatePosting` | `OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckUnposted` | `PurchPost.RunOnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckUnposted` |
| `CheckICPartnerBlocked` | `OnBeforeCheckICPartnerBlocked` | `PurchPost.RunOnBeforeCheckICPartnerBlocked` |
| `SendICDocument` | `OnBeforeSendICDocument` | `PurchPost.RunOnBeforeSendICDocument` |
| `UpdateHandledICInboxTransaction` | `OnBeforeUpdateHandledICInboxTransaction` | `PurchPost.RunOnBeforeUpdateHandledICInboxTransaction` |
| `CheckGLAccDirectPosting` | `OnBeforeCheckGLAccDirectPosting` | `PurchPost.RunOnBeforeCheckGLAccDirectPosting` |
| `PostGLAccICLine` | `OnBeforePostGLAccICLine` | `PurchPost.RunOnBeforePostGLAccICLine` |
| `PostGLAccICLine` | `OnPostGLAccICLineOnBeforeCreateJobPurchLine` | `PurchPost.RunOnPostGLAccICLineOnBeforeCreateJobPurchLine` |
| `PostGLAccICLine` | `OnPostGLAccICLineOnAfterCreateJobPurchLine` | `PurchPost.RunOnPostGLAccICLineOnAfterCreateJobPurchLine` |
| `PostGLAccICLine` | `OnPostGLAccICLineOnBeforeCheckAndInsertICGenJnlLine` | `PurchPost.RunOnPostGLAccICLineOnBeforeCheckAndInsertICGenJnlLine` |
| `PostGLAccICLine` | `OnAfterPostAccICLine` | `PurchPost.RunOnAfterPostAccICLine` |
| `CreateJobPurchLine` | `OnAfterCreateJobPurchLine` | `PurchPost.RunOnAfterCreateJobPurchLine` |

**Rules:**
- The pair call always comes **immediately after** the new event call, before any `if IsHandled then exit` or other logic that depends on the event result — so both old and new subscribers have the same opportunity to set `IsHandled` or modify parameters
- The extracted codeunit defines its own identically-named integration events for new subscribers
- The codeunit variable `PurchPost: Codeunit "Purch.-Post"` is declared inside `#if not CLEAN29` so it is compiled away after the clean version
- Obsolete tag format: `[Obsolete('Moved to codeunit <TargetCodeunit>', '<Version>')]`

---

### Pattern 5: New Integration Events Added to Base Codeunit

The base codeunit must add new `[IntegrationEvent]` procedures for any extraction points that did not previously have one. These serve as hook points for the extracted codeunit to subscribe to.

New events are declared as `local procedure` with `[IntegrationEvent(false, false)]` and empty bodies. They are called at the appropriate point in the base codeunit's flow.

**Events added to `PurchPost.Codeunit.al` for IC extraction:**

| Event | Location in flow | Purpose |
|---|---|---|
| `OnAfterClearAllVariables` | End of `ClearAllVariables` | Let extracted codeunit reset its SingleInstance state |
| `OnAfterGetInvoicePostingSetup` | After interface is set up | Let extracted codeunit capture posting context |
| `OnCheckAndUpdateOnBeforeLockTables` | Before table lock | Replace direct IC calls with subscriber hook |
| `OnAfterCheckPostrestrictions` | After posting restrictions check | Trigger IC duplicate document check |
| `OnPostPurchLineOnGLAccount` | When posting a G/L Account line | Let IC codeunit insert IC journal lines |
| `OnRunOnAfterPostInvoice` | After invoice is posted | Trigger deferred IC journal line posting |

---

### Checklist for Codeunit Extraction with SingleInstance and Events

- [ ] Extracted codeunit is `SingleInstance = true` if it accumulates state across events
- [ ] Extracted codeunit namespace matches the base codeunit namespace (not the feature namespace)
- [ ] All previously direct calls replaced with integration event hooks in base codeunit
- [ ] New integration events added to base codeunit at every extraction point
- [ ] State cleared via subscriber on `OnAfterClearAllVariables` (or equivalent)
- [ ] Posting context captured via event (not parameter injection into the extracted codeunit)
- [ ] Obsoleted events in base codeunit are guarded with `#if not CLEAN29`
- [ ] Each obsoleted event has a paired `internal procedure RunOnXxx(...)` bridge
- [ ] Extracted codeunit defines its own fresh integration events for new subscribers
- [ ] Base codeunit has zero `using` or direct reference to the extracted codeunit
- [ ] Both codeunits compile without errors (`get_errors`)

## Recent Extractions Case Study - IC Purchase Posting

**Extraction Cycle:** April 2026

### Overview

Extracted all Intercompany-specific logic from `PurchPost.Codeunit.al` (codeunit 90, `Purch.-Post`) into a new dedicated codeunit `ICPurchPost.Codeunit.al` (codeunit 8452, `IC Purch.-Post`).

**Files changed:**
- Modified: `Purchases/Posting/PurchPost.Codeunit.al`
- Created: `Finance/Intercompany/Purchases/Posting/ICPurchPost.Codeunit.al`

### What Was Moved

- `CheckICPartnerBlocked` — validates IC partner is not blocked before posting
- `SendICDocument` — sends IC purchase document if flagged
- `UpdateHandledICInboxTransaction` — marks handled IC inbox transaction as posted
- `CheckICDocumentDuplicatePosting` — confirms duplicate IC document posting with user
- `PostGLAccICLine` — posts G/L account lines with IC partner reference
- `InsertICGenJnlLine` — builds temporary IC general journal lines per purchase line
- `ValidateICPartnerBusPostingGroups` — applies customer posting group to IC journal line
- `PostICGenJnl` — bulk-posts all accumulated IC journal entries after invoice posting
- `CreateJobPurchLine` — recalculates direct unit cost for job-related purchase lines

### State Managed by ICPurchPost (SingleInstance Variables)

| Variable | Type | Purpose |
|---|---|---|
| `TempICGenJnlLine` | `Record "Gen. Journal Line" temporary` | Accumulates IC journal entries across line postings |
| `TempInvoicePostingParameters` | `Record "Invoice Posting Parameters" temporary` | Captured posting context (doc no., source code, etc.) |
| `PurchInvoicePostingInterface` | `Interface "Invoice Posting"` | Captured posting interface for `PrepareJobLine` calls |
| `PurchSuppressCommit` | `Boolean` | Captured commit suppression flag |
| `ICGenJnlLineNo` | `Integer` | Running line number counter for IC journal entries |

### Obsoleted Events in PurchPost (17 total)

All IC-specific integration events in `PurchPost.Codeunit.al` were obsoleted with tag `29.0` and moved to `ICPurchPost.Codeunit.al`. Each obsoleted event retains a `RunOnXxx` internal bridge procedure for backward compatibility. Examples:

- `OnBeforeCheckGLAccDirectPosting`
- `OnBeforeCheckICDocumentDuplicatePosting`
- `OnBeforeInsertICGenJnlLine`
- `OnBeforePostGLAccICLine`
- `OnBeforeSendICDocument`
- `OnBeforeUpdateHandledICInboxTransaction`
- `OnInsertICGenJnlLineOnAfterCopyDocumentFields`
- `OnInsertICGenJnlLineOnBeforeICGenJnlLineInsert`
- `OnAfterCreateJobPurchLine`
- `OnAfterPostAccICLine`
- `OnPostGLAccICLineOnBeforeCheckAndInsertICGenJnlLine`
- `OnPostGLAccICLineOnAfterCreateJobPurchLine`
- `OnBeforeValidateICPartnerBusPostingGroups`
- `OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckPosted`
- `OnCheckICDocumentDuplicatePostingOnAfterCalcShouldCheckUnposted`
- `OnPostGLAccICLineOnBeforeCreateJobPurchLine`
- `OnBeforeCheckICPartnerBlocked`

## Table-Level IC Extraction with Combined TableExt + Codeunit Pattern

This section documents patterns established when extracting IC logic from a **large base table** (`Gen. Journal Line`, table 81) where the feature participates in field validation, account type dispatch, and record copy flows.

**Reference implementation:** `ICGenJournalLine.TableExt.al` (8400) + `ICGenJournalLine.Codeunit.al` (8410), extracted from `GenJournalLine.Table.al`.

---

### Pattern 6: Combined TableExt + Subscriber Codeunit

When extracting IC logic from a table, you typically need **two files**:

| File | Purpose |
|---|---|
| `ICXxx.TableExt.al` | Fields that extend the record schema + public procedures that operate on the record |
| `ICXxx.Codeunit.al` | Event subscribers that react to base table integration events |

The subscriber codeunit uses the same namespace as the base table (not the feature namespace). The tableextension also uses the base table's namespace.

---

### Pattern 7: `modify()` for TableRelation of Existing Base Fields

When a base table field's `TableRelation` included an IC Partner-specific condition, remove that condition from the base and restore it in the tableextension via `modify()`:

**Base table — remove the IC Partner branch:**
```al
field(3; "Account No."; Code[20])
{
    TableRelation =
        if ("Account Type" = const(Customer)) Customer
        else if ("Account Type" = const(Vendor)) Vendor
        // IC Partner branch removed — moved to extension
        else if ("Account Type" = const("Fixed Asset")) "Fixed Asset";
}
```

**TableExt — re-add with `modify()`:**
```al
tableextension 8400 "IC Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        modify("Account No.")
        {
            TableRelation = if ("Account Type" = const("IC Partner")) "IC Partner";
        }
        modify("Bal. Account No.")
        {
            TableRelation = if ("Account Type" = const("IC Partner")) "IC Partner";
        }
        // ... IC-specific fields ...
    }
}
```

**Note:** `modify()` in a tableextension adds to or overrides properties of the named field. When the base field already has a multi-branch `TableRelation`, the extension's `modify()` adds the new conditional branch.

---

### Pattern 8: Procedures on TableExt (Not the IC Codeunit)

Procedures that operate directly on the record fields (accessing `"Account No."`, `"IC Partner Code"`, etc.) belong in the **tableextension** as `procedure` (public), not in the subscriber codeunit. The subscriber codeunit calls these via the record.

**In `ICGenJournalLine.TableExt.al`:**
```al
procedure GetICPartnerAccount()
var
    ICPartner: Record "IC Partner";
begin
    ICPartner.Get("Account No.");
    ICPartner.CheckICPartner();
    UpdateDescription(ICPartner.Name);
    "IC Partner Code" := "Account No.";
    OnAfterAccountNoOnValidateGetICPartnerAccount(Rec, ICPartner);
end;

procedure GetDefaultICPartnerGLAccNo(): Code[20]
begin
    // reads "Account No.", "Bal. Account No.", "IC Partner Code" directly
end;
```

**In `ICGenJournalLine.Codeunit.al` subscriber:**
```al
[EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnValidateAccountNoOnAfterAssignValue', '', true, false)]
local procedure OnValidateAccountNoOnAfterAssignValue(var GenJournalLine: Record "Gen. Journal Line"; ...)
begin
    if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"IC Partner" then
        GenJournalLine.GetICPartnerAccount();  // calls procedure on the tableextension
end;
```

---

### Pattern 9: `OnSetICAccountNoBlank` — Avoid Validate Calls in Base Triggers

When the base table's `AccountType`/`BalAccountType` `OnValidate` trigger previously called `Validate("IC Account No.", '')`, replace it with a dedicated event. The IC extension subscribes and blanks the field.

**Base table trigger — replace direct Validate with event:**
```al
trigger OnValidate()
begin
    // REMOVED: Validate("IC Account No.", '');
    OnSetICAccountNoBlank(Rec);      // NEW: fire event instead
    Validate("Account No.", '');
    ...
end;

[IntegrationEvent(false, false)]
local procedure OnSetICAccountNoBlank(var Rec: Record "Gen. Journal Line")
begin
end;
```

**IC codeunit subscriber:**
```al
[EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnSetICAccountNoBlank', '', true, false)]
local procedure OnSetICAccountNoBlank(var Rec: Record "Gen. Journal Line")
begin
    Rec.Validate("IC Account No.", '');
end;
```

---

### Pattern 10: `OnSetICPartnerCodeBlank` — Pass `xRec` Value, Not `Rec`

When blanking the IC Partner Code in response to an account type change, the event should pass the **old** account type (`xRec`) so the subscriber can check whether the previous type was IC-relevant. Passing `Rec."Account Type"` (the new type) would always be wrong because by the time the event fires the type has already changed.

**Base table — pass `xRec` field value:**
```al
trigger OnValidate()
begin
    ...
    OnSetICPartnerCodeBlank(Rec, xRec."Account Type");  // xRec, not Rec
    ...
end;
```

**IC codeunit subscriber:**
```al
[EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnSetICPartnerCodeBlank', '', true, false)]
local procedure OnSetICPartnerCodeBlank(var Rec: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type")
begin
    if AccountType in [AccountType::Customer, AccountType::Vendor, AccountType::"IC Partner"] then
        Rec."IC Partner Code" := '';
end;
```

---

### Pattern 11: "Case-Else" Events for Account Type Dispatch

When a `case "Account Type" of` block in the base table had IC Partner-specific arms, remove those arms and add an extensibility event for the `else` branch. Other feature account types (e.g., Allocation Account) may have their own extensions using the same pattern.

**Base table — remove IC case arm, add else event:**
```al
local procedure GetAccCurrencyCode(): Code[10]
var
    ...
begin
    case "Account Type" of
        "Account Type"::Customer:  CurrencyCode := Cust."Currency Code";
        "Account Type"::Vendor:    CurrencyCode := Vend."Currency Code";
        "Account Type"::"Bank Account": CurrencyCode := BankAccount."Currency Code";
        // IC Partner arm removed
    end;

    OnGetAccCurrencyCodeCaseElse(Rec, CurrencyCode);  // hook for removed arm
    exit(CurrencyCode);
end;

[IntegrationEvent(false, false)]
local procedure OnGetAccCurrencyCodeCaseElse(var Rec: Record "Gen. Journal Line"; var CurrencyCode: Code[10])
begin
end;
```

**IC codeunit subscriber:**
```al
[EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnGetAccCurrencyCodeCaseElse', '', true, false)]
local procedure OnGetAccCurrencyCodeCaseElse(var Rec: Record "Gen. Journal Line"; var CurrencyCode: Code[10])
var
    ICPartner: Record "IC Partner";
begin
    if Rec."Account Type" = Rec."Account Type"::"IC Partner" then begin
        ICPartner.Get(Rec."Account No.");
        CurrencyCode := ICPartner."Currency Code";
    end;
end;
```

---

### Pattern 12: `IsHandled` Event for "Else" Branch in Boolean Function

For boolean functions like `IsAdHocDescription` that use a `case` to check each AccountType and return a result, removing the IC branch leaves no natural "else" hook. Add an `OnAfterIsXxx(var Result: Boolean; var IsHandled: Boolean)` event at the end of the function so extensions can handle additional types:

**Base table — replace removed case arms with OnAfterXxx event:**
```al
local procedure IsAdHocDescription(): Boolean
var
    ...
    IsHandled: Boolean;
begin
    ...
    case xRec."Account Type" of
        xRec."Account Type"::Customer:  ...
        xRec."Account Type"::Vendor:    ...
        xRec."Account Type"::"Bank Account": ...
        xRec."Account Type"::"Fixed Asset":  ...
        xRec."Account Type"::Employee:  ...
        else begin
            IsHandled := false;
            OnAfterIsAdHocDescription(Rec, xRec, Result, IsHandled);
            if IsHandled then
                exit(Result);
        end;
    end;
    exit(false);
end;

[IntegrationEvent(false, false)]
local procedure OnAfterIsAdHocDescription(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
begin
end;
```

**IC codeunit subscriber (simpler, no IsHandled needed in subscriber):**
```al
[EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnIsAdHocDescriptionElseCase', '', true, false)]
local procedure OnIsAdHocDescriptionElseCase(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var Result: Boolean)
var
    ICPartner: Record "IC Partner";
begin
    if xRec."Account Type" = xRec."Account Type"::"IC Partner" then
        Result := ICPartner.Get(xRec."Account No.") and (ICPartner.Name <> Rec.Description);
end;
```

---

### Pattern 13: New Events for Existing Procedures to Enable IC Hooks

When the base table's `GetCustomerAccount()` / `GetVendorAccount()` procedures previously called `CheckICPartner()` directly (a procedure removed with extraction), add new `OnGetXxxOnAfterYyyGet` events to the procedures. The IC codeunit subscribes to call its own IC partner checking logic.

**Base table — add event after record Get, replace direct IC call:**
```al
local procedure GetVendorAccount()
var
    Vend: Record Vendor;
begin
    Vend.Get("Account No.");
    OnGetVendorAccountOnAfterVendGet(Rec, Vend, CurrFieldNo);  // NEW event (replaces CheckICPartner call)
    Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
    ...
end;

[IntegrationEvent(false, false)]
local procedure OnGetVendorAccountOnAfterVendGet(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor; CallingFieldNo: Integer)
begin
end;
```

**IC codeunit subscriber:**
```al
[EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnCheckICPartner', '', true, false)]
local procedure OnCheckICPartner(var Rec: Record "Gen. Journal Line"; ICPartnerCode: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
var
    ICPartner: Record "IC Partner";
begin
    if (ICPartnerCode <> '') and ICPartner.Get(ICPartnerCode) then begin
        ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
        Rec."IC Partner Code" := ICPartnerCode;
    end;
end;
```

---

### Checklist for Table-Level IC Extraction (GenJournalLine Pattern)

- [ ] TableExt namespace matches base table namespace (not feature namespace)
- [ ] Subscriber codeunit namespace matches base table namespace
- [ ] `modify()` used in TableExt to add IC Partner branch to existing field TableRelations
- [ ] IC-specific procedures moved to TableExt as public `procedure` (not to subscriber codeunit)
- [ ] `OnSetICAccountNoBlank` event fires instead of `Validate("IC Account No.", '')` in base triggers
- [ ] `OnSetICPartnerCodeBlank` passes `xRec."Account Type"` (old value), not `Rec."Account Type"`
- [ ] Case-else events added for removed IC branch in account-type dispatch functions
- [ ] `IsHandled` pattern used for boolean functions with IC-handled else cases
- [ ] New `OnGetXxxOnAfterVendGet` / `OnGetXxxOnAfterCustGet` events added where `CheckICPartner` was removed
- [ ] IC CopyFrom field assignments moved to subscriber codeunit via `OnAfterCopyXxx` events
- [ ] Event names are specific (e.g. `OnUpdateICAccountNo` not `OnUpdateICAccount`)
- [ ] Both TableExt and subscriber codeunit compile without errors

---

## Recent Extractions Case Study — Gen. Journal Line IC Extraction

**Extraction Cycle:** April 2026

### Overview

Extracted all Intercompany-specific fields, procedures, and logic from `GenJournalLine.Table.al` (table 81) into:
- `ICGenJournalLine.TableExt.al` (tableextension 8400) — IC fields and record-level procedures
- `ICGenJournalLine.Codeunit.al` (codeunit 8410) — event subscribers for base table hooks

### Fields Moved to TableExt

| # | Field | Notes |
|---|-------|-------|
| 113 | `IC Partner Code` | Added `DataClassification = CustomerContent` |
| 114 | `IC Direction` | Added `DataClassification = CustomerContent` |
| 116 | `IC Partner G/L Acc. No.` | Obsolete, inside `#if not CLEANSCHEMA25` |
| 117 | `IC Partner Transaction No.` | Added `DataClassification = CustomerContent` |
| 130 | `IC Account Type` | Added `DataClassification = CustomerContent` |
| 131 | `IC Account No.` | Complex multi-branch TableRelation, added `DataClassification` |

### Procedures Moved to TableExt (as public `procedure`)

- `GetICPartnerAccount()` — was `local procedure` in base
- `GetICPartnerBalAccount()` — was `local procedure` in base
- `GetDefaultICPartnerGLAccNo()` — was `local procedure` in base
- Events `OnAfterAccountNoOnValidateGetICPartnerAccount` / `OnAfterAccountNoOnValidateGetICPartnerBalAccount` — moved to TableExt

### Logic Moved to Subscriber Codeunit (`ICGenJournalLine.Codeunit.al`)

| Subscriber | Replaces |
|------------|----------|
| `OnAfterCopyGenJnlLineFromPurchHeader` | Direct `"IC Partner Code" := PurchHeader."Pay-to IC Partner Code"` |
| `OnAfterCopyGenJnlLineFromSalesHeader` | Direct `"IC Partner Code" := SalesHeader."Bill-to IC Partner Code"` |
| `OnValidateAccountTypeOnBeforeCheckTemplateType` | IC template type check in `AccountType` trigger |
| `OnValidateBalAccountTypeOnBeforeCheckTemplateType` | IC template type check in `BalAccountType` trigger |
| `OnUpdateICAccountNo` | Direct `Validate("IC Account No.", GetDefaultICPartnerGLAccNo())` calls |
| `OnValidateAccountNoOnAfterAssignValue` | `GetICPartnerAccount()` call when type = IC Partner |
| `OnValidateBalAccountNoOnAfterAssignValue` | `GetICPartnerBalAccount()` call when type = IC Partner |
| `OnCheckICPartner` | `CheckICPartner()` calls in `GetCustomerAccount/GetVendorAccount` |
| `OnGetAccCurrencyCodeCaseElse` | IC Partner arm in `GetAccCurrencyCode` case |
| `OnIsAdHocDescriptionElseCase` | IC Partner arm in `IsAdHocDescription` case |
| `OnSetICAccountNoBlank` | `Validate("IC Account No.", '')` in AccountType/BalAccountType triggers |
| `OnSetICPartnerCodeBlank` | IC Partner Code blanking when account type changes |

### Bug Fix in Same Cycle (April 20)

After initial extraction, two bugs were found and fixed in commit `6de795482e10`:

1. **`OnSetICPartnerCodeBlank` parameter** — calls were passing `Rec."Account Type"` (the new type after validation) instead of `xRec."Account Type"` (the old type). The subscriber logic checks if the *old* type was Customer/Vendor/IC Partner, so `xRec` is correct.

2. **Event rename: `OnUpdateICAccount` → `OnUpdateICAccountNo`** — the original name was ambiguous. Renamed for clarity. The subscriber in `ICGenJournalLine.Codeunit.al` was updated to match.
