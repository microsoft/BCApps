# Test Plan: Subcontracting – Inventory Put-Away (Single-Step Logistics)

**Feature**: Analogous support for Inventory Put-Away (one-step, `Require Receive = false, Require Put-away = true`)  
as exists for Warehouse Receipt + Put-Away (two-step, `Require Receive = true, Require Put-away = true`).

**Target file**: `Tests/SubcInvtPutAwayTest.Codeunit.al`  
**Codeunit ID**: `149908`  
**Codeunit name**: `"Subc. Invt. Put-away Test"`  
**Pattern**: Follows `SubcWhseReceiptLastOp.Codeunit.al` (149900) as reference

---

## Part 1 – Library Additions required in `SubcWarehouseLibrary.Codeunit.al`

The following helper procedures must be added before the test codeunit can be implemented.

### 1.1 `CreateLocationWithInvtPutAwaySetup`

```al
/// <summary>
/// Creates a location for single-step logistics (Inventory Put-Away).
/// Require Receive = false, Require Put-away = true, Bin Mandatory = false.
/// This is the minimal location setup that triggers the Inventory Put-away code path
/// instead of the two-step Warehouse Receipt + Put-Away path.
/// </summary>
procedure CreateLocationWithInvtPutAwaySetup(var Location: Record Location)
begin
    LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);
    Location."Require Receive" := false;
    Location."Require Put-away" := true;
    Location.Modify(true);
    LibraryInventory.UpdateInventoryPostingSetup(Location);
end;
```

### 1.2 `CreateLocationWithInvtPutAwaySetupAndBin`

```al
/// <summary>
/// Creates a location for single-step logistics with Bin Mandatory = true.
/// Require Receive = false, Require Put-away = true, Bin Mandatory = true.
/// Used to test Subscriber B (skip warehouse journal for NotLastOperation).
/// </summary>
procedure CreateLocationWithInvtPutAwaySetupAndBin(var Location: Record Location; var DefaultBin: Record Bin)
begin
    LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);
    Location."Require Receive" := false;
    Location."Require Put-away" := true;
    Location.Modify(true);
    LibraryInventory.UpdateInventoryPostingSetup(Location);
    LibraryWarehouse.CreateBin(DefaultBin, Location.Code, 'PUTAWAY', '', '');
    Location.Validate("Default Bin Code", DefaultBin.Code);
    Location.Modify(true);
end;
```

### 1.3 `CreateInventoryPutAwayFromPurchaseOrder`

```al
/// <summary>
/// Programmatically creates an Inventory Put-Away document from a released
/// subcontracting Purchase Order without showing the request page dialog.
/// </summary>
procedure CreateInventoryPutAwayFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
var
    WhseRequest: Record "Warehouse Request";
    CreateInvtPutAway: Codeunit "Create Inventory Put-away";
begin
    WhseRequest.Reset();
    WhseRequest.SetCurrentKey("Source Document", "Source No.");
    WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Purchase Order");
    WhseRequest.SetRange("Source No.", PurchaseHeader."No.");
    WhseRequest.SetRange("Document Status", WhseRequest."Document Status"::Released);
    WhseRequest.FindFirst();

    WarehouseActivityHeader.Init();
    WarehouseActivityHeader."Location Code" := WhseRequest."Location Code";
    WarehouseActivityHeader.Insert(true);

    CreateInvtPutAway.SetWhseRequest(WhseRequest, true);
    CreateInvtPutAway.AutoCreatePutAway(WarehouseActivityHeader);
end;
```

---

## Part 2 – Test Scenarios

### Structural conventions

```al
codeunit 149908 "Subc. Invt. Put-away Test"
{
    // [FEATURE] Subcontracting Inventory Put-Away Tests
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcLibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;
}
```

---

### TC-IPA-001: Activity Line – LastOperation gets real Qty. per Unit of Measure

**Purpose**: Validates Subscriber A (`OnBeforeNewWhseActivLineInsertFromPurchase`).  
The purchase line has `Qty. per Unit of Measure = 0` (set by `SubcCalculateSubcontracts`).  
For a LastOperation line, the subscriber must restore the real value from the item.

```
[GIVEN] Single-operation subcontracting routing (LastOperation)
[GIVEN] Location: Require Receive = false, Require Put-away = true
[GIVEN] Subcontracting purchase order created and released
[WHEN]  Create Inventory Put-Away from purchase order
[THEN]  One Warehouse Activity Line is created
[THEN]  WarehouseActivityLine."Subc. Purchase Line Type" = LastOperation
[THEN]  WarehouseActivityLine."Qty. per Unit of Measure" > 0   (real value, not 0)
[THEN]  WarehouseActivityLine."Qty. (Base)" = Quantity * "Qty. per Unit of Measure"
[THEN]  WarehouseActivityLine."Qty. (Base)" > 0
```

**Key assertion**:
```al
Assert.AreNotEqual(0, WarehouseActivityLine."Qty. per Unit of Measure",
    'LastOperation activity line must have real Qty. per Unit of Measure, not 0');
Assert.AreEqual(
    WarehouseActivityLine.Quantity * WarehouseActivityLine."Qty. per Unit of Measure",
    WarehouseActivityLine."Qty. (Base)",
    'Qty. (Base) must equal Quantity * Qty. per Unit of Measure for LastOperation');
```

---

### TC-IPA-002: Activity Line – NotLastOperation keeps Qty. per Unit of Measure = 0

**Purpose**: Validates that NotLastOperation lines are NOT modified by Subscriber A  
and intentionally carry `Qty. per Unit of Measure = 0` and `Qty. (Base) = 0`.

```
[GIVEN] Two-operation routing: Operation 10 (NotLastOperation), Operation 20 (LastOperation)
[GIVEN] Location: Require Receive = false, Require Put-away = true
[GIVEN] Subcontracting purchase order created for both operations
[WHEN]  Create Inventory Put-Away from purchase order
[THEN]  Two Warehouse Activity Lines are created (one per operation)
[THEN]  NotLastOperation line: "Qty. per Unit of Measure" = 0
[THEN]  NotLastOperation line: "Qty. (Base)" = 0
[THEN]  NotLastOperation line: "Subc. Purchase Line Type" = NotLastOperation
[THEN]  LastOperation line: "Qty. per Unit of Measure" > 0
[THEN]  LastOperation line: "Qty. (Base)" > 0
[THEN]  LastOperation line: "Subc. Purchase Line Type" = LastOperation
```

---

### TC-IPA-003: Posting – LastOperation creates Item Ledger Entry and Posted Invt. Put-away

**Purpose**: Validates the full post flow for a single LastOperation.

```
[GIVEN] Single-operation subcontracting routing (LastOperation)
[GIVEN] Location: Require Receive = false, Require Put-away = true
[GIVEN] Inventory Put-Away created from purchase order
[WHEN]  Set Qty. to Handle = Qty. Outstanding on all activity lines
[WHEN]  Post Inventory Put-Away (Whse.-Activity-Post.Run)
[THEN]  Purch. Rcpt. Header created (Purchase Order received)
[THEN]  Item Ledger Entry with Entry Type = Output, Quantity > 0 exists
[THEN]  Item Ledger Entry."Quantity" = original production order quantity
[THEN]  Capacity Ledger Entry created for the work center
[THEN]  Posted Invt. Put-away Header created
[THEN]  Posted Invt. Put-away Line created with matching source references
[THEN]  Purchase Line "Quantity Received" = original Quantity
[THEN]  Purchase Line "Outstanding Quantity" = 0
```

**Key assertion**:
```al
ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
ItemLedgerEntry.SetRange("Item No.", Item."No.");
Assert.RecordIsNotEmpty(ItemLedgerEntry);
ItemLedgerEntry.FindFirst();
Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity,
    'Item Ledger Entry must have the correct output quantity');
```

---

### TC-IPA-004: Posting – NotLastOperation produces Output entry without Warehouse Entry

**Purpose**: Validates that `Qty. (Base) = 0` on NotLastOperation activity lines does NOT prevent  
the MfgPurchPost from creating the correct Output entry, AND that no warehouse entry is created.

```
[GIVEN] Two-operation routing: Operation 10 (NotLastOperation), Operation 20 (LastOperation)
[GIVEN] Location: Require Receive = false, Require Put-away = true
[GIVEN] Inventory Put-Away created for the NotLastOperation purchase line
[WHEN]  Set Qty. to Handle on NotLastOperation activity line
[WHEN]  Post Inventory Put-Away
[THEN]  Item Ledger Entry with Entry Type = Output exists (via MfgPurchPost override)
[THEN]  Item Ledger Entry.Quantity > 0 (MfgPurchPost calculates real base qty from item)
[THEN]  No Warehouse Entry created for the NotLastOperation line
[THEN]  Purchase Line "Quantity Received" = posted quantity
```

**Note**: The `Warehouse Entry` table can be checked via:
```al
WarehouseEntry.SetRange("Item No.", Item."No.");
WarehouseEntry.SetRange("Source Type", Database::"Purchase Line");
Assert.RecordIsEmpty(WarehouseEntry);
// MfgPurchPost creates the ILE, but no bin-level entry exists
```

---

### TC-IPA-005: Bin Mandatory – Warehouse Journal skipped for NotLastOperation (Subscriber B)

**Purpose**: Validates Subscriber B on Locations with `Bin Mandatory = true`.  
No `Warehouse Entry` must be created for NotLastOperation, even on a bin-enabled location.

```
[GIVEN] Two-operation routing
[GIVEN] Location: Require Receive = false, Require Put-away = true, Bin Mandatory = true
[GIVEN] Default Bin configured on location
[GIVEN] Inventory Put-Away created for NotLastOperation line
[WHEN]  Set Qty. to Handle and post
[THEN]  No Warehouse Entry for the NotLastOperation line (Subscriber B fired: IsHandled = true)
[THEN]  No Bin Content created for NotLastOperation line
[THEN]  Item Ledger Entry (Output) still created
[THEN]  LastOperation line (posted separately): Warehouse Entry IS created
[THEN]  LastOperation line: Bin Content updated
```

---

### TC-IPA-006: Full Flow – Two-Operation Routing, Both Operations via Inventory Put-Away

**Purpose**: End-to-end test validating the complete subcontracting lifecycle  
using single-step logistics for both operations.

```
[GIVEN] Two-operation routing (Op10 = NotLastOperation, Op20 = LastOperation)
[GIVEN] Location: Require Receive = false, Require Put-away = true
[WHEN]  Create Invt. Put-Away for Op10 (NotLastOperation), set Qty. to Handle, post
[WHEN]  Create Invt. Put-Away for Op20 (LastOperation), set Qty. to Handle, post
[THEN]  Two Purch. Rcpt. Header records exist (one per operation)
[THEN]  Two Output Item Ledger Entries exist
[THEN]  Production Order has output matching quantity
[THEN]  Both Purchase Lines fully received (Outstanding Quantity = 0)
[THEN]  Capacity Ledger Entries for both work centers
```

---

### TC-IPA-007: Undo Receipt – Not Blocked by Posted Invt. Put-away Line (Subscriber D)

**Purpose**: Validates Subscriber D (`OnBeforeTestPostedInvtPutAwayLine`).  
Without the subscriber, undoing a subcontracting receipt that was posted via Invt. Put-Away  
would error because `UndoPostingManagement` finds the `Posted Invt. Put-away Line`.

```
[GIVEN] LastOperation Inventory Put-Away created and posted
[GIVEN] Purch. Rcpt. Line exists for the subcontracting purchase line
[WHEN]  Call UndoReceiptLines on the Purch. Rcpt. Line (undo the receipt)
[THEN]  No error is raised (Subscriber D suppressed the TestPostedInvtPutAwayLine check)
[THEN]  Purch. Rcpt. Line is marked as Correction
[THEN]  Item Ledger Entry reversed
[THEN]  Purchase Line Outstanding Quantity restored
```

**Precondition**: Without Subscriber D, the test should fail with the error  
`'You must delete the related Posted Invt. Put-Away Lines first.'`  
This can be verified in a negative test variant.

---

### TC-IPA-008: CalcQty TestField Suppressed for NotLastOperation (Subscriber E)

**Purpose**: Validates Subscriber E (`OnBeforeCalcQty`) when `Qty. to Handle (Base)` 
is directly validated on a NotLastOperation activity line (edge case: direct edit or
programmatic validation of base field).

```
[GIVEN] Inventory Put-Away with a NotLastOperation line (Qty. per UoM = 0)
[WHEN]  Call WarehouseActivityLine.Validate("Qty. to Handle (Base)", 0)
         [internally calls CalcQty which would normally TestField("Qty. per Unit of Measure")]
[THEN]  No error raised (Subscriber E sets IsHandled = true before TestField)
[THEN]  Qty. to Handle remains 0
```

---

## Part 3 – Negative Tests (Optional but recommended)

### TC-IPA-NEG-001: Two-step location not affected
```
[GIVEN] Location with Require Receive = true, Require Put-away = true (full WMS)
[WHEN]  Subcontracting purchase order created
[THEN]  No Inventory Put-Away is created (Require Receive = true → Warehouse Receipt path)
[THEN]  Warehouse Receipt is created instead
```

### TC-IPA-NEG-002: Non-subcontracting Purchase Order – standard behavior unchanged
```
[GIVEN] Normal purchase order (no production order link)
[GIVEN] Location: Require Receive = false, Require Put-away = true
[WHEN]  Create Inventory Put-Away
[THEN]  Activity Line "Subc. Purchase Line Type" = None
[THEN]  Activity Line "Qty. per Unit of Measure" = real value (standard behavior unchanged)
```

---

## Part 4 – Implementation Notes

### Codeunit Structure

```al
codeunit 149908 "Subc. Invt. Put-away Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Invt. Put-away Test");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Invt. Put-away Test");
        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Invt. Put-away Test");
    end;
    ...
}
```

### SetQtyToHandleAndPostInvtPutAway (shared helper)

A local helper procedure should be extracted to reduce repetition:

```al
local procedure SetQtyToHandleAndPostInvtPutAway(var WarehouseActivityHeader: Record "Warehouse Activity Header")
var
    WarehouseActivityLine: Record "Warehouse Activity Line";
    WhseActivityPost: Codeunit "Whse.-Activity-Post";
begin
    WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
    WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
    if WarehouseActivityLine.FindSet() then
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. Outstanding");
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    WhseActivityPost.SetSuppressCommit(true);
    WhseActivityPost.Run(WarehouseActivityLine);
end;
```

### Using statements required

```al
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
```

---

## Part 5 – Test Coverage Matrix

| Scenario | Subscriber A | Subscriber B | Subscriber D | Subscriber E | Base App Change |
|---|:---:|:---:|:---:|:---:|:---:|
| TC-IPA-001 (LastOp qty correction) | ✅ | | | | |
| TC-IPA-002 (NotLastOp qty = 0) | ✅ | | | | |
| TC-IPA-003 (Post LastOp → ILE) | ✅ | | | | |
| TC-IPA-004 (Post NotLastOp → no Whse Entry) | | ✅ | | | |
| TC-IPA-005 (Bin Mandatory → no Whse Journal) | | ✅ | | | |
| TC-IPA-006 (Full flow both ops) | ✅ | ✅ | | | |
| TC-IPA-007 (Undo not blocked) | | | ✅ | | |
| TC-IPA-008 (CalcQty TestField suppressed) | | | | ✅ | ✅ (OnBeforeCalcQty) |
| TC-IPA-NEG-001 (Two-step unaffected) | | | | | |
| TC-IPA-NEG-002 (Non-subc unaffected) | ✅ | | | | |
