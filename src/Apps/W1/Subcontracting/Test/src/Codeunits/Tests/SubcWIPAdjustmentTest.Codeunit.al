// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Subcontracting;

codeunit 149914 "Subc. WIP Adjustment Test"
{
    // [FEATURE] WIP Adjustment for Subcontracting
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('WIPAdjustmentPageHandler')]
    procedure WIPAdjustment_PositiveAdjustment_CreatesCorrectEntry()
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WIPAdjustmentPage: Page "Subc. WIP Adjustment";
        ProdOrderNo: Code[20];
        InitialQty, NewQty : Decimal;
    begin
        // [SCENARIO] Entering a higher new quantity on the WIP Adjustment page creates a positive adjustment entry
        Initialize();

        // [GIVEN] A WIP ledger entry exists for a production order with an initial quantity of 5
        InitialQty := 5;
        CreateTestWIPSetup(WIPLedgerEntry, InitialQty, ProdOrderNo);

        // [GIVEN] The WIP Adjustment page handler will set the new quantity to 8 with a document reference and description
        NewQty := 8;
        SetHandlerValues(NewQty, 'ADJ-001', 'Positive Adjustment Test', 'Detail Info');

        // [WHEN] The WIP Adjustment page is opened and the new quantity of 8 is confirmed
        WIPAdjustmentPage.SetWIPLedgerEntry(WIPLedgerEntry);
        WIPAdjustmentPage.RunModal();

        // [THEN] The sum of all WIP ledger quantities for the production order equals the new target quantity (8)
        AssertWIPQuantitySum(ProdOrderNo, NewQty);

        // [THEN] A positive adjustment entry is created with the correct adjustment quantity (+3) and all header fields set
        AssertAdjustmentEntry(
            ProdOrderNo, NewQty - InitialQty,
            "WIP Ledger Entry Type"::"Positive Adjustment",
            'ADJ-001', 'Positive Adjustment Test', 'Detail Info');
    end;

    [Test]
    [HandlerFunctions('WIPAdjustmentPageHandler')]
    procedure WIPAdjustment_NegativeAdjustment_CreatesCorrectEntry()
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WIPAdjustmentPage: Page "Subc. WIP Adjustment";
        ProdOrderNo: Code[20];
        InitialQty, NewQty : Decimal;
    begin
        // [SCENARIO] Entering a lower new quantity on the WIP Adjustment page creates a negative adjustment entry
        Initialize();

        // [GIVEN] A WIP ledger entry exists for a production order with an initial quantity of 8
        InitialQty := 8;
        CreateTestWIPSetup(WIPLedgerEntry, InitialQty, ProdOrderNo);

        // [GIVEN] The WIP Adjustment page handler will set the new quantity to 3 (lower than current)
        NewQty := 3;
        SetHandlerValues(NewQty, 'ADJ-002', 'Negative Adjustment Test', '');

        // [WHEN] The WIP Adjustment page is opened and the new quantity of 3 is confirmed
        WIPAdjustmentPage.SetWIPLedgerEntry(WIPLedgerEntry);
        WIPAdjustmentPage.RunModal();

        // [THEN] The sum of all WIP ledger quantities for the production order equals the new target quantity (3)
        AssertWIPQuantitySum(ProdOrderNo, NewQty);

        // [THEN] A negative adjustment entry is created with the correct adjustment quantity (-5) and entry type
        AssertAdjustmentEntry(
            ProdOrderNo, NewQty - InitialQty,
            "WIP Ledger Entry Type"::"Negative Adjustment",
            'ADJ-002', 'Negative Adjustment Test', '');
    end;

    [Test]
    [HandlerFunctions('WIPAdjustmentPageHandler')]
    procedure WIPAdjustment_TwoEntriesSameKey_AggregatedBeforeAdjustment()
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WIPAdjustmentPage: Page "Subc. WIP Adjustment";
        ProdOrderNo: Code[20];
        Qty1, Qty2, AggregatedQty, NewQty : Decimal;
    begin
        // [SCENARIO] Two WIP ledger entries sharing the same routing key are aggregated on the WIP Adjustment
        // page into a single line, and the resulting adjustment entry reflects the difference from the
        // aggregated current quantity to the new target quantity
        Initialize();

        // [GIVEN] Two WIP ledger entries with the same production order and routing key, quantities 3 and 4
        Qty1 := 3;
        Qty2 := 4;
        AggregatedQty := Qty1 + Qty2;
        CreateTwoWIPEntriesSameKey(WIPLedgerEntry, Qty1, Qty2, ProdOrderNo);

        // [GIVEN] The WIP Adjustment page handler will set the new quantity to 10 (adjustment delta = 3 from aggregated 7)
        NewQty := 10;
        SetHandlerValues(NewQty, 'ADJ-003', 'Aggregation Test', '');

        // [WHEN] The WIP Adjustment page aggregates the two entries to a single line and the new quantity 10 is confirmed
        WIPAdjustmentPage.SetWIPLedgerEntry(WIPLedgerEntry);
        WIPAdjustmentPage.RunModal();

        // [THEN] The sum of all WIP ledger quantities for the production order equals the new target quantity (10)
        AssertWIPQuantitySum(ProdOrderNo, NewQty);

        // [THEN] A single positive adjustment entry is created with the correct adjustment quantity (+3)
        AssertAdjustmentEntry(
            ProdOrderNo, NewQty - AggregatedQty,
            "WIP Ledger Entry Type"::"Positive Adjustment",
            'ADJ-003', 'Aggregation Test', '');
    end;

    [ModalPageHandler]
    procedure WIPAdjustmentPageHandler(var WIPAdjustmentPage: TestPage "Subc. WIP Adjustment")
    begin
        WIPAdjustmentPage."New Quantity (Base)".SetValue(HandlerNewQuantity);
        WIPAdjustmentPage."Document No.".SetValue(HandlerDocumentNo);
        WIPAdjustmentPage.Description.SetValue(HandlerDescription);
        WIPAdjustmentPage."Description 2".SetValue(HandlerDescription2);
        WIPAdjustmentPage.OK().Invoke();
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        HandlerNewQuantity: Decimal;
        HandlerDocumentNo: Code[20];
        HandlerDescription: Text[100];
        HandlerDescription2: Text[50];

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. WIP Adjustment Test");
        LibrarySetupStorage.Restore();
        SubcontractingMgmtLibrary.Initialize();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. WIP Adjustment Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. WIP Adjustment Test");
    end;

    /// <summary>
    /// Creates a single WIP ledger entry with a unique production order and a fixed routing key.
    /// Returns the production order number and leaves WIPLedgerEntry filtered to that production order.
    /// </summary>
    local procedure CreateTestWIPSetup(var WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry"; QuantityBase: Decimal; var ProdOrderNo: Code[20])
    var
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        ProductionOrder."No." := CopyStr(
            LibraryUtility.GenerateRandomCode(ProductionOrder.FieldNo("No."), Database::"Production Order"),
            1, MaxStrLen(ProductionOrder."No."));
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine."Unit of Measure Code" := Item."Base Unit of Measure";
        ProdOrderRoutingLine."Routing No." := 'RTNG-001';
        ProdOrderRoutingLine."Routing Reference No." := 10000;
        ProdOrderRoutingLine."Operation No." := '10';

        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", Location.Code,
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            'WC-001', QuantityBase, false);

        ProdOrderNo := ProductionOrder."No.";
        WIPLedgerEntry.SetRange("Prod. Order No.", ProdOrderNo);
    end;

    /// <summary>
    /// Creates two WIP ledger entries with an identical 7-field aggregation key (same production order,
    /// routing reference, operation, and location). SetWIPLedgerEntry will combine them into a single line.
    /// Returns the production order number and leaves WIPLedgerEntry filtered to both entries.
    /// </summary>
    local procedure CreateTwoWIPEntriesSameKey(var WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry"; Quantity1: Decimal; Quantity2: Decimal; var ProdOrderNo: Code[20])
    var
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        ProductionOrder."No." := CopyStr(
            LibraryUtility.GenerateRandomCode(ProductionOrder.FieldNo("No."), Database::"Production Order"),
            1, MaxStrLen(ProductionOrder."No."));
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine."Unit of Measure Code" := Item."Base Unit of Measure";
        ProdOrderRoutingLine."Routing No." := 'RTNG-001';
        ProdOrderRoutingLine."Routing Reference No." := 10000;
        ProdOrderRoutingLine."Operation No." := '10';

        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", Location.Code,
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            'WC-001', Quantity1, false);
        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", Location.Code,
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            'WC-001', Quantity2, false);

        ProdOrderNo := ProductionOrder."No.";
        WIPLedgerEntry.SetRange("Prod. Order No.", ProdOrderNo);
    end;

    local procedure SetHandlerValues(NewQuantity: Decimal; DocumentNo: Code[20]; Description: Text[100]; Description2: Text[50])
    begin
        HandlerNewQuantity := NewQuantity;
        HandlerDocumentNo := DocumentNo;
        HandlerDescription := Description;
        HandlerDescription2 := Description2;
    end;

    local procedure AssertWIPQuantitySum(ProdOrderNo: Code[20]; ExpectedSum: Decimal)
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        WIPLedgerEntry.SetRange("Prod. Order No.", ProdOrderNo);
        WIPLedgerEntry.CalcSums("Quantity (Base)");
        Assert.AreEqual(
            ExpectedSum, WIPLedgerEntry."Quantity (Base)",
            'The sum of WIP Ledger Entry quantities should equal the expected new target quantity');
    end;

    local procedure AssertAdjustmentEntry(ProdOrderNo: Code[20]; ExpectedQuantity: Decimal; ExpectedEntryType: Enum "WIP Ledger Entry Type"; ExpectedDocumentNo: Code[20]; ExpectedDescription: Text[100]; ExpectedDescription2: Text[50])
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        WIPLedgerEntry.SetRange("Prod. Order No.", ProdOrderNo);
        WIPLedgerEntry.SetRange("Document Type", "WIP Document Type"::"Adjustment (Manual)");
        Assert.IsTrue(WIPLedgerEntry.FindFirst(), 'A WIP adjustment entry should have been created');
        Assert.AreEqual(1, WIPLedgerEntry.Count(), 'Exactly one adjustment entry should have been created');
        Assert.AreEqual(
            ExpectedQuantity, WIPLedgerEntry."Quantity (Base)",
            'The adjustment entry quantity should equal the difference between the new and current WIP quantity');
        Assert.AreEqual(
            ExpectedEntryType, WIPLedgerEntry."Entry Type",
            'The adjustment entry type should reflect whether the quantity increased or decreased');
        Assert.AreEqual(
            "WIP Document Type"::"Adjustment (Manual)", WIPLedgerEntry."Document Type",
            'The adjustment entry document type should be Adjustment (Manual)');
        Assert.AreEqual(
            WorkDate(), WIPLedgerEntry."Posting Date",
            'The adjustment entry posting date should equal WorkDate');
        Assert.AreEqual(
            ExpectedDocumentNo, WIPLedgerEntry."Document No.",
            'The adjustment entry document number should match the value entered on the page');
        Assert.AreEqual(
            ExpectedDescription, WIPLedgerEntry.Description,
            'The adjustment entry description should match the value entered on the page');
        Assert.AreEqual(
            ExpectedDescription2, WIPLedgerEntry."Description 2",
            'The adjustment entry description 2 should match the value entered on the page');
    end;
}