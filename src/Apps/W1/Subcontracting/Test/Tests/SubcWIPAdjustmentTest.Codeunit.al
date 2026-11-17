// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

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
    [HandlerFunctions('WIPAdjustmentPageHandler,SummaryTransferCreatedHandler')]
    procedure SummaryRealOrderAdjustmentRefresh()
    var
        ProductionOrder: Record "Production Order";
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] A negative adjustment refreshes the open Released card immediately after the dialog closes.
        Initialize();

        // [GIVEN] The card is open on an order with ten natively posted WIP units.
        CreateSummaryAdjustmentOrder(ProductionOrder, ReleasedOrder);
        SetHandlerValues(6, 'SUMMARY-6', 'Summary target six', '');

        // [WHEN] The real parent action adjusts the target to six.
        ReleasedOrder."WIP Adjustment".Invoke();

        // [THEN] The same card shows six without rereading the order, and the original ten is offset by a -4 delta.
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.AssertEquals(6);
        ReleasedOrder.SubcontractingSummary.WIPInTransit.AssertEquals(0);
        AssertAdjustmentEntry(ProductionOrder."No.", -4, "WIP Ledger Entry Type"::"Negative Adjustment", 'SUMMARY-6', 'Summary target six', '');
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        Assert.AreEqual(2, WIPEntry.Count(), 'The original and negative adjustment must remain.');
        ReleasedOrder.Close();
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 6, 0);
    end;

    [Test]
    [HandlerFunctions('WIPAdjustmentPageHandler,SummaryTransferCreatedHandler')]
    procedure SummaryRealOrderPositiveAdjustmentRefresh()
    var
        ProductionOrder: Record "Production Order";
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] A positive adjustment refreshes the open card without losing earlier signed ledger movements.
        Initialize();

        // [GIVEN] A ten-unit order has already been adjusted to six through its open card.
        CreateSummaryAdjustmentOrder(ProductionOrder, ReleasedOrder);
        SetHandlerValues(6, 'SUMMARY-6', 'Summary target six', '');
        ReleasedOrder."WIP Adjustment".Invoke();
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.AssertEquals(6);
        SetHandlerValues(8, 'SUMMARY-8', 'Summary target eight', '');

        // [WHEN] The real parent action raises the target to eight.
        ReleasedOrder."WIP Adjustment".Invoke();

        // [THEN] The same card immediately shows eight; the original ten and -4/+2 deltas remain.
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.AssertEquals(8);
        ReleasedOrder.SubcontractingSummary.WIPInTransit.AssertEquals(0);
        AssertAdjustmentEntry(ProductionOrder."No.", -4, "WIP Ledger Entry Type"::"Negative Adjustment", 'SUMMARY-6', 'Summary target six', '');
        AssertAdjustmentEntry(ProductionOrder."No.", 2, "WIP Ledger Entry Type"::"Positive Adjustment", 'SUMMARY-8', 'Summary target eight', '');
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        Assert.AreEqual(3, WIPEntry.Count(), 'One original plus two adjustment entries must remain.');
        ReleasedOrder.Close();
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 8, 0);
    end;

    [Test]
    [HandlerFunctions('WIPAdjustmentPageHandler,SummaryTransferCreatedHandler')]
    procedure SummaryRealOrderNegativeTargetRejected()
    var
        ProductionOrder: Record "Production Order";
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
        ReleasedOrder: TestPage "Released Production Order";
        EntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Rejecting a negative adjustment target preserves the real order's displayed and persisted balance.
        Initialize();

        // [GIVEN] An open real-order card already displays an adjusted balance of eight.
        CreateSummaryAdjustmentOrder(ProductionOrder, ReleasedOrder);
        SetHandlerValues(8, 'SUMMARY-8', 'Summary target eight', '');
        ReleasedOrder."WIP Adjustment".Invoke();
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.AssertEquals(8);
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        EntryCount := WIPEntry.Count();
        SetHandlerValues(-1, 'INVALID', 'Invalid negative target', '');
        // Preserve the accepted baseline across the expected validation rollback.
        Commit();

        // [WHEN] A negative target is attempted through the same actual dialog.
        asserterror ReleasedOrder."WIP Adjustment".Invoke();

        // [THEN] The native target guard rejects it without adding entries.
        Assert.ExpectedError('must not be negative');
        Assert.ExpectedErrorCode('TestValidation');
        Assert.AreEqual(EntryCount, WIPEntry.Count(), 'Rejected negative target must not append entries.');
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.AssertEquals(8);
        ReleasedOrder.Close();
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 8, 0);
    end;

    [Test]
    [HandlerFunctions('WIPAdjustmentPageHandler,SummaryTransferCreatedHandler')]
    procedure SummaryRealOrderExcessiveTargetRejected()
    var
        ProductionOrder: Record "Production Order";
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
        ReleasedOrder: TestPage "Released Production Order";
        EntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Rejecting a target above the real production quantity preserves the existing balance.
        Initialize();

        // [GIVEN] A ten-unit production order has an open card displaying an adjusted balance of eight.
        CreateSummaryAdjustmentOrder(ProductionOrder, ReleasedOrder);
        SetHandlerValues(8, 'SUMMARY-8', 'Summary target eight', '');
        ReleasedOrder."WIP Adjustment".Invoke();
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.AssertEquals(8);
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        EntryCount := WIPEntry.Count();
        SetHandlerValues(11, 'INVALID', 'Invalid excessive target', '');
        // Preserve the accepted baseline across the expected validation rollback.
        Commit();

        // [WHEN] A target above the real production line quantity is attempted.
        asserterror ReleasedOrder."WIP Adjustment".Invoke();

        // [THEN] The native upper guard rejects it and the persisted card balance stays eight.
        Assert.ExpectedError('must not exceed');
        Assert.ExpectedErrorCode('TestValidation');
        Assert.AreEqual(EntryCount, WIPEntry.Count(), 'Rejected excessive target must not append entries.');
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.AssertEquals(8);
        ReleasedOrder.Close();
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 8, 0);
    end;

    local procedure CreateSummaryAdjustmentOrder(var ProductionOrder: Record "Production Order"; var ReleasedOrder: TestPage "Released Production Order")
    var
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        DirectPost: Codeunit "TransferOrder-Post Transfer";
    begin
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        SubcWarehouseLibrary.CreateSummaryForward(ProductionOrder, WorkCenter, PurchaseHeader, TransferHeader);
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Direct Transfer");
        TransferHeader.Modify(true);
        DirectPost.SetHideValidationDialog(true);
        DirectPost.Run(TransferHeader);
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.AssertEquals(10);
        ReleasedOrder.SubcontractingSummary.WIPInTransit.AssertEquals(0);
    end;

    [PageHandler]
    procedure SummaryTransferCreatedHandler(var TransferOrder: TestPage "Transfer Order")
    begin
        TransferOrder.Close();
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

    [Test]
    [HandlerFunctions('WIPAdjustmentPageHandler')]
    procedure WIPAdjustment_NegativeQuantity_RaisesError()
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WIPAdjustmentPage: Page "Subc. WIP Adjustment";
        ProdOrderNo: Code[20];
    begin
        // [SCENARIO] Entering a negative new quantity on the WIP Adjustment page raises an error
        Initialize();

        // [GIVEN] A WIP ledger entry exists for a production order with an initial quantity of 10
        CreateTestWIPSetup(WIPLedgerEntry, 10, ProdOrderNo);

        // [GIVEN] The WIP Adjustment page handler will attempt to set the new quantity to -50
        SetHandlerValues(-50, '', '', '');

        // [WHEN] The WIP Adjustment page is opened and a negative quantity is entered
        WIPAdjustmentPage.SetWIPLedgerEntry(WIPLedgerEntry);

        // [THEN] An error is raised indicating that the new quantity must not be negative
        asserterror WIPAdjustmentPage.RunModal();
        Assert.ExpectedError('must not be negative');
    end;

    [Test]
    [HandlerFunctions('WIPAdjustmentPageHandler')]
    procedure WIPAdjustment_QuantityExceedsProdOrderQty_RaisesError()
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WIPAdjustmentPage: Page "Subc. WIP Adjustment";
        ProdOrderNo: Code[20];
    begin
        // [SCENARIO] Entering a new quantity exceeding the production order line quantity raises an error
        Initialize();

        // [GIVEN] A production order line with quantity 10 and a WIP ledger entry with initial quantity 5
        CreateTestWIPSetupWithProdOrderQty(WIPLedgerEntry, 5, 10, ProdOrderNo);

        // [GIVEN] The WIP Adjustment page handler will attempt to set the new quantity to 15 (exceeds prod order qty of 10)
        SetHandlerValues(15, '', '', '');

        // [WHEN] The WIP Adjustment page is opened and a quantity exceeding the production order is entered
        WIPAdjustmentPage.SetWIPLedgerEntry(WIPLedgerEntry);

        // [THEN] An error is raised indicating that the new quantity must not exceed the production order line quantity
        asserterror WIPAdjustmentPage.RunModal();
        Assert.ExpectedError('must not exceed the production order line quantity');
    end;

    [Test]
    [HandlerFunctions('WIPAdjustmentPageHandler')]
    procedure WIPAdjustment_ZeroNewQuantity_Succeeds()
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WIPAdjustmentPage: Page "Subc. WIP Adjustment";
        ProdOrderNo: Code[20];
        InitialQty: Decimal;
    begin
        // [SCENARIO] Entering zero as the new quantity succeeds (lower boundary: 0 is allowed, < 0 is not)
        Initialize();

        // [GIVEN] A WIP ledger entry with initial quantity 5 and a prod. order line quantity of 10
        InitialQty := 5;
        CreateTestWIPSetupWithProdOrderQty(WIPLedgerEntry, InitialQty, 10, ProdOrderNo);

        // [GIVEN] The WIP Adjustment page handler will set the new quantity to 0 (lower boundary)
        SetHandlerValues(0, 'ADJ-ZRO', 'Zero Qty Test', '');

        // [WHEN] The WIP Adjustment page is opened and a zero quantity is confirmed
        WIPAdjustmentPage.SetWIPLedgerEntry(WIPLedgerEntry);
        WIPAdjustmentPage.RunModal();

        // [THEN] A negative adjustment entry is created reducing the WIP quantity to zero
        AssertWIPQuantitySum(ProdOrderNo, 0);
        AssertAdjustmentEntry(
            ProdOrderNo, -InitialQty,
            "WIP Ledger Entry Type"::"Negative Adjustment",
            'ADJ-ZRO', 'Zero Qty Test', '');
    end;

    [Test]
    [HandlerFunctions('WIPAdjustmentPageHandler')]
    procedure WIPAdjustment_ExactProdOrderQuantity_Succeeds()
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WIPAdjustmentPage: Page "Subc. WIP Adjustment";
        ProdOrderNo: Code[20];
        InitialQty, ProdOrderQty : Decimal;
    begin
        // [SCENARIO] Entering exactly the production order line quantity succeeds (upper boundary: = is allowed, > is not)
        Initialize();

        // [GIVEN] A WIP ledger entry with initial quantity 3 and a prod. order line quantity of 10
        InitialQty := 3;
        ProdOrderQty := 10;
        CreateTestWIPSetupWithProdOrderQty(WIPLedgerEntry, InitialQty, ProdOrderQty, ProdOrderNo);

        // [GIVEN] The WIP Adjustment page handler will set the new quantity exactly equal to the prod. order line quantity
        SetHandlerValues(ProdOrderQty, 'ADJ-MAX', 'Exact Prod Order Qty Test', '');

        // [WHEN] The WIP Adjustment page is opened and the production order line quantity is confirmed
        WIPAdjustmentPage.SetWIPLedgerEntry(WIPLedgerEntry);
        WIPAdjustmentPage.RunModal();

        // [THEN] A positive adjustment entry is created raising the WIP quantity to the production order line quantity
        AssertWIPQuantitySum(ProdOrderNo, ProdOrderQty);
        AssertAdjustmentEntry(
            ProdOrderNo, ProdOrderQty - InitialQty,
            "WIP Ledger Entry Type"::"Positive Adjustment",
            'ADJ-MAX', 'Exact Prod Order Qty Test', '');
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
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
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
        ProdOrderLine.Status := "Production Order Status"::Released;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine."Quantity (Base)" := QuantityBase + 100;
        ProdOrderLine."Unit of Measure Code" := Item."Base Unit of Measure";
        ProdOrderLine.Insert(false);
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
        ProdOrderLine.Status := "Production Order Status"::Released;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine."Quantity (Base)" := Quantity1 + Quantity2 + 100;
        ProdOrderLine."Unit of Measure Code" := Item."Base Unit of Measure";
        ProdOrderLine.Insert(false);
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

    /// <summary>
    /// Creates a WIP ledger entry linked to a real Prod. Order Line with the specified quantity.
    /// The Prod. Order Line is inserted without running triggers to allow testing the
    /// exceeding-quantity validation without requiring a full production order setup.
    /// </summary>
    local procedure CreateTestWIPSetupWithProdOrderQty(var WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry"; WIPQuantityBase: Decimal; ProdOrderQty: Decimal; var ProdOrderNo: Code[20])
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

        ProdOrderLine.Status := "Production Order Status"::Released;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine."Quantity (Base)" := ProdOrderQty;
        ProdOrderLine."Unit of Measure Code" := Item."Base Unit of Measure";
        ProdOrderLine.Insert(false);

        ProdOrderRoutingLine."Routing No." := 'RTNG-001';
        ProdOrderRoutingLine."Routing Reference No." := 10000;
        ProdOrderRoutingLine."Operation No." := '10';

        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", Location.Code,
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            'WC-001', WIPQuantityBase, false);

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
        WIPLedgerEntry.SetRange("Document No.", ExpectedDocumentNo);
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