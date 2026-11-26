// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.TestLibraries.Utilities;

codeunit 149910 "Subc. WIP Transfer Post Test"
{
    // [FEATURE] Subcontracting Warehouse Combined Scenarios Tests
    Subtype = Test;
    TestType = IntegrationTest;

    [Test]
    [HandlerFunctions('HandleTransferOrder,SummaryWIPDetailHandler')]
    procedure SummaryWIPShipmentPartialAndFinalReceipt()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Actual shipment and partial/final receipts flow into the genuine card and exact ledger details.
        Initialize();

        // [GIVEN] A real first-operation subcontract transfer of ten.
        PrepareSummaryWIPOrder(10, ProductionOrder, WorkCenter, PurchaseHeader, TransferHeader);

        // [WHEN] Ten are shipped and four are received.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 0, 10);
        VerifySummaryWIPDetails(ProductionOrder);
        FindSummaryOriginal(TransferHeader, TransferLine);
        TransferLine.Validate("Qty. to Receive", 4);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] The card is 4/6, then 10/0 after the remaining receipt; all signed source keys agree.
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 4, 6);
        VerifySummaryWIPDetails(ProductionOrder);
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 10, 0);
        VerifySummaryWIPDetails(ProductionOrder);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder,SummaryWIPDetailHandler')]
    procedure SummaryWIPReturnTransit()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        ReturnHeader: Record "Transfer Header";
        ReturnLine: Record "Transfer Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] A native return includes negative subcontractor balances and both return-transit signs.
        Initialize();

        // [GIVEN] A real completed forward transfer has ten at the subcontractor and a still-existing PO.
        PrepareSummaryWIPOrder(10, ProductionOrder, WorkCenter, PurchaseHeader, TransferHeader);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
        SubcWarehouseLibrary.CreateSummaryReturn(PurchaseHeader, ReturnHeader);
        FindSummaryOriginal(ReturnHeader, ReturnLine);
        ReturnLine.Validate(Quantity, 3);
        ReturnLine.Modify(true);

        // [WHEN] The native return is shipped then received.
        LibraryWarehouse.PostTransferOrder(ReturnHeader, true, false);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 7, 3);
        VerifySummaryWIPDetails(ProductionOrder);
        LibraryWarehouse.PostTransferOrder(ReturnHeader, false, true);

        // [THEN] Seven remain at the subcontractor and transit nets to zero.
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 7, 0);
        VerifySummaryWIPDetails(ProductionOrder);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder,SummaryWIPDetailHandler')]
    procedure SummaryWIPDirectTransfer()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        DirectHeader: Record "Direct Trans. Header";
        DirectPost: Codeunit "TransferOrder-Post Transfer";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Native direct transfer contributes destination WIP without inventing transit entries.
        Initialize();

        // [GIVEN] A real linked transfer is validated into native direct-transfer mode before posting.
        PrepareSummaryWIPOrder(10, ProductionOrder, WorkCenter, PurchaseHeader, TransferHeader);
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Direct Transfer");
        TransferHeader.Modify(true);

        // [WHEN] The native direct-transfer posting codeunit persists the transfer.
        DirectPost.SetHideValidationDialog(true);
        DirectPost.Run(TransferHeader);

        // [THEN] A real direct document exists and the card/detail balance is 10/0.
        DirectHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordIsNotEmpty(DirectHeader);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 10, 0);
        VerifySummaryWIPDetails(ProductionOrder);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder,SummaryWIPDetailHandler')]
    procedure SummaryFamilyMixedUOMWIP()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Every real family contributor posts numeric base quantities, not just UOM labels.
        Initialize();

        // [GIVEN] A factor-six contributor and a base-unit contributor in real refreshed families.
        // [WHEN] Both are shipped and partially/finally received.
        // [THEN] Raw heterogeneous base sums and each persisted contributor match the approved arithmetic.
        RunSummaryFamilyWIP(0.06, 0.10, 0.02, 0.05);
        RunSummaryFamilyWIP(0.10, 0.20, 0.02, 0.05);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder,SummaryWIPDetailHandler')]
    procedure SummaryWIPIgnoresCurrentVendorLocation()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        Vendor: Record Vendor;
        Location: Record Location;
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
        OriginalLocation: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Current vendor setup never filters away historical WIP at its original location.
        Initialize();

        // [GIVEN] Ten were natively received at the original subcontractor location.
        PrepareSummaryWIPOrder(10, ProductionOrder, WorkCenter, PurchaseHeader, TransferHeader);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
        Vendor.Get(WorkCenter."Subcontractor No.");
        OriginalLocation := Vendor."Subc. Location Code";

        // [WHEN] The vendor is reconfigured to a different valid location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Validate("Subc. Location Code", Location.Code);
        Vendor.Modify(true);

        // [THEN] The real card and matching source keys still show the original ten.
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 10, 0);
        VerifySummaryWIPDetails(ProductionOrder);
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        WIPEntry.SetRange("In Transit", false);
        WIPEntry.SetRange("Location Code", OriginalLocation);
        WIPEntry.CalcSums("Quantity (Base)");
        Assert.AreEqual(10, WIPEntry."Quantity (Base)", 'Historical location balance must be retained.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SummaryWIPDetailHandler')]
    procedure SummarySignedWIPStatusAndOrderIsolation()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        FinishedIdentity: Record "Production Order";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Calculation-only signed WIP is isolated by both status and order, without a positivity floor.
        Initialize();

        // [GIVEN] Explicit persisted reader fixtures, not a status-transition or negative-target workflow.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryOrder(10, OtherOrder, WorkCenter);
        FinishedIdentity := ProductionOrder;
        FinishedIdentity.Status := FinishedIdentity.Status::Finished;
        InsertSummaryWIP(ProductionOrder, false, 5);
        InsertSummaryWIP(ProductionOrder, false, -7);
        InsertSummaryWIP(ProductionOrder, true, 3);
        InsertSummaryWIP(ProductionOrder, true, -4);
        InsertSummaryWIP(FinishedIdentity, false, 100);
        InsertSummaryWIP(OtherOrder, false, 200);

        // [WHEN] The actual Released consumer reads "A".
        // [THEN] Only its signed current-status rows contribute.
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, -2, -1);
        VerifySummaryWIPDetails(ProductionOrder);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder,SummaryReopenConfirmHandler,SummaryReopenedCardHandler')]
    procedure SummaryWIPLateStatusAndReopen()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        FinishedOrder: Record "Production Order";
        ReopenedOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        SummaryMgmt: Codeunit "Subc. Order Summary Mgmt.";
        StatusManagement: Codeunit "Prod. Order Status Management";
        FinishedCard: TestPage "Finished Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Real finish and one-time reopen move persisted WIP identity without changing balances or another order.
        Initialize();

        // [GIVEN] Real completed WIP ten and real purchase-receipt output; another order has WIP four.
        PrepareSummaryWIPOrder(10, ProductionOrder, WorkCenter, PurchaseHeader, TransferHeader);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PrepareSummaryWIPOrder(4, OtherOrder, WorkCenter, PurchaseHeader, TransferHeader);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

        // [WHEN] Native programmatic finish updates the actual resulting status and number.
        StatusManagement.ChangeProdOrderStatus(ProductionOrder, FinishedOrder, FinishedOrder.Status::Finished, WorkDate(), false);

        // [THEN] The old selection is empty; Finished has ten; the other order still has four.
        Assert.AreEqual(0, SummaryMgmt.GetWIPQuantity(ProductionOrder, false), 'Old Released identity must no longer match.');
        Assert.AreEqual(10, SummaryMgmt.GetWIPQuantity(FinishedOrder, false), 'New Finished identity must match all native relation updates.');
        SubcWarehouseLibrary.VerifySummaryWIP(OtherOrder, 4, 0);
        FinishedCard.OpenView();
        FinishedCard.GoToRecord(FinishedOrder);
        FinishedCard.ReopenFinishedProdOrder.Invoke();
        ReopenedOrder.Get(ReopenedOrder.Status::Released, FinishedOrder."No.");
        SubcWarehouseLibrary.VerifySummaryWIP(ReopenedOrder, 10, 0);
        Assert.AreEqual(0, SummaryMgmt.GetWIPQuantity(FinishedOrder, false), 'Old Finished identity must no longer match after native reopen.');
        SubcWarehouseLibrary.VerifySummaryWIP(OtherOrder, 4, 0);
        Assert.AreEqual(10, LibraryVariableStorage.DequeueDecimal(), 'Native reopen must open the genuine Released card with ten.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder')]
    procedure SummaryPreservesExistingFinishGate()
    var
        ProductionOrder: Record "Production Order";
        AllowedOrder: Record "Production Order";
        FinishedOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        StatusManagement: Codeunit "Prod. Order Status Management";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] The existing open-transfer finish guard remains; Fully Invoiced No adds no finish prohibition.
        Initialize();

        // [GIVEN] A real order with posted output and a native original transfer still open.
        PrepareSummaryWIPOrder(10, ProductionOrder, WorkCenter, PurchaseHeader, TransferHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Finish is attempted with that original transfer.
        asserterror StatusManagement.ChangeProdOrderStatus(ProductionOrder, FinishedOrder, FinishedOrder.Status::Finished, WorkDate(), false);

        // [THEN] The intended native guard, not an output/setup error, is raised.
        Assert.ExpectedError('There is an open transfer order');
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsTrue(ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrder."No."), 'Blocked order must remain Released.');

        // [GIVEN] Another order has real output and a partially invoiced PO but no transfer.
        SubcWarehouseLibrary.CreateSummaryOrder(10, AllowedOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(AllowedOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 4);
        SubcWarehouseLibrary.VerifySummaryCard(AllowedOrder, 1, 10, 10, 4, false, 0, 0, 0, 0);

        // [WHEN] The otherwise eligible order is finished.
        Clear(StatusManagement);
        StatusManagement.ChangeProdOrderStatus(AllowedOrder, FinishedOrder, FinishedOrder.Status::Finished, WorkDate(), false);

        // [THEN] The source No indicator has introduced no new finish gate.
        Assert.IsTrue(FinishedOrder.Get(FinishedOrder.Status::Finished, FinishedOrder."No."), 'Native finish must succeed with No alone.');
    end;

    local procedure PrepareSummaryWIPOrder(Quantity: Decimal; var ProductionOrder: Record "Production Order"; var WorkCenter: Record "Work Center"; var PurchaseHeader: Record "Purchase Header"; var TransferHeader: Record "Transfer Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SubcWarehouseLibrary.CreateSummaryOrder(Quantity, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        SubcWarehouseLibrary.CreateSummaryForward(ProductionOrder, WorkCenter, PurchaseHeader, TransferHeader);
    end;

    local procedure FindSummaryOriginal(TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    begin
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.FindFirst();
    end;

    local procedure RunSummaryFamilyWIP(FirstQuantity: Decimal; SecondQuantity: Decimal; FirstPartial: Decimal; SecondPartial: Decimal)
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        Items: array[2] of Record Item;
        ItemUOM: Record "Item Unit of Measure";
        ProductionLine: Record "Prod. Order Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        SubcWarehouseLibrary.CreateSummaryFamily(FirstQuantity * 6, SecondQuantity, ProductionOrder, WorkCenter, Items);
        ProductionLine.SetRange(Status, ProductionOrder.Status);
        ProductionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.AreEqual(2, ProductionLine.Count(), 'Both family contributors must be real refreshed lines.');
        ProductionLine.SetRange("Item No.", Items[1]."No.");
        ProductionLine.FindFirst();
        Assert.AreEqual(FirstQuantity * 6, ProductionLine."Quantity (Base)", 'First family output must support converted shipment.');
        ProductionLine.SetRange("Item No.", Items[2]."No.");
        ProductionLine.FindFirst();
        Assert.AreEqual(SecondQuantity, ProductionLine."Quantity (Base)", 'Second family output must support shipment.');
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Items[1]."No.", 6);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", Items[1]."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Unit of Measure Code", ItemUOM.Code);
        PurchaseLine.Validate(Quantity, FirstQuantity);
        PurchaseLine.Modify(true);
        SubcWarehouseLibrary.CreateSummaryForward(ProductionOrder, WorkCenter, PurchaseHeader, TransferHeader);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 0, FirstQuantity * 6 + SecondQuantity);
        VerifySummaryItemWIP(ProductionOrder, Items[1], true, FirstQuantity * 6);
        VerifySummaryItemWIP(ProductionOrder, Items[2], true, SecondQuantity);
        VerifySummaryWIPDetails(ProductionOrder);
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.SetRange("Item No.", Items[1]."No.");
        TransferLine.FindFirst();
        Assert.AreEqual(ItemUOM.Code, TransferLine."Unit of Measure Code", 'Forward creation must use purchase UOM.');
        TransferLine.Validate("Qty. to Receive", FirstPartial);
        TransferLine.Modify(true);
        TransferLine.SetRange("Item No.", Items[2]."No.");
        TransferLine.FindFirst();
        TransferLine.Validate("Qty. to Receive", SecondPartial);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, FirstPartial * 6 + SecondPartial, (FirstQuantity - FirstPartial) * 6 + SecondQuantity - SecondPartial);
        VerifySummaryItemWIP(ProductionOrder, Items[1], false, FirstPartial * 6);
        VerifySummaryItemWIP(ProductionOrder, Items[2], false, SecondPartial);
        VerifySummaryItemWIP(ProductionOrder, Items[1], true, (FirstQuantity - FirstPartial) * 6);
        VerifySummaryItemWIP(ProductionOrder, Items[2], true, SecondQuantity - SecondPartial);
        VerifySummaryWIPDetails(ProductionOrder);
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, FirstQuantity * 6 + SecondQuantity, 0);
        VerifySummaryItemWIP(ProductionOrder, Items[1], false, FirstQuantity * 6);
        VerifySummaryItemWIP(ProductionOrder, Items[2], false, SecondQuantity);
        VerifySummaryWIPDetails(ProductionOrder);
    end;

    local procedure VerifySummaryItemWIP(ProductionOrder: Record "Production Order"; Item: Record Item; InTransit: Boolean; Quantity: Decimal)
    var
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        WIPEntry.SetRange("Item No.", Item."No.");
#pragma warning disable AA0210 // WIP is already restricted to the test order and item.
        WIPEntry.SetRange("In Transit", InTransit);
#pragma warning restore AA0210
        WIPEntry.CalcSums("Quantity (Base)");
        Assert.AreEqual(Quantity, WIPEntry."Quantity (Base)", 'Every family contributor must have the expected numeric persisted balance.');
        WIPEntry.FindSet();
        repeat
            Assert.AreEqual(Item."Base Unit of Measure", WIPEntry."Base Unit of Measure", 'Each movement must retain the item base UOM.');
        until WIPEntry.Next() = 0;
    end;

    local procedure InsertSummaryWIP(ProductionOrder: Record "Production Order"; InTransit: Boolean; Quantity: Decimal)
    var
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
        ProductionLine: Record "Prod. Order Line";
        RoutingLine: Record "Prod. Order Routing Line";
    begin
        ProductionLine.SetRange(Status, ProductionLine.Status::Released);
        ProductionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProductionLine.FindFirst();
        RoutingLine.SetRange(Status, RoutingLine.Status::Released);
        RoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        RoutingLine.FindFirst();
        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPEntry, ProductionLine."Item No.", ProductionLine."Location Code",
            ProductionOrder, ProductionLine, RoutingLine, RoutingLine."Work Center No.", Quantity, InTransit);
        if WIPEntry."Prod. Order Status" <> ProductionOrder.Status then begin
            // The library creates Released entries; this reader fixture also exercises a same-number Finished identity.
            WIPEntry."Prod. Order Status" := ProductionOrder.Status;
            WIPEntry.Modify();
        end;
    end;

    local procedure VerifySummaryWIPDetails(ProductionOrder: Record "Production Order")
    var
        ReleasedOrder: TestPage "Released Production Order";
    begin
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.DrillDown();
        VerifySummaryWIPDetailRows(ProductionOrder, false);
        ReleasedOrder.SubcontractingSummary.WIPInTransit.DrillDown();
        VerifySummaryWIPDetailRows(ProductionOrder, true);
        ReleasedOrder.Close();
    end;

    local procedure VerifySummaryWIPDetailRows(ProductionOrder: Record "Production Order"; InTransit: Boolean)
    var
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        WIPEntry.SetRange("In Transit", InTransit);
        Assert.AreEqual(WIPEntry.Count(), LibraryVariableStorage.DequeueInteger(), 'Ledger detail count must match the exact population.');
        if WIPEntry.FindSet() then
            repeat
                Assert.AreEqual(WIPEntry."Entry No.", LibraryVariableStorage.DequeueInteger(), 'Ledger detail must return the exact persisted entry key.');
                Assert.AreEqual(WIPEntry."Quantity (Base)", LibraryVariableStorage.DequeueDecimal(), 'Ledger detail must retain the signed movement.');
            until WIPEntry.Next() = 0;
    end;

    [PageHandler]
    procedure SummaryWIPDetailHandler(var Entries: TestPage "Subc. WIP Ledger Entries")
    var
        EntryNumbers: List of [Integer];
        Quantities: List of [Decimal];
        EntryNo: Integer;
        Quantity: Decimal;
        RowIndex: Integer;
    begin
        if Entries.First() then
            repeat
                Evaluate(EntryNo, Entries."Entry No.".Value());
                EntryNumbers.Add(EntryNo);
                Evaluate(Quantity, Entries."Quantity (Base)".Value());
                Quantities.Add(Quantity);
            until not Entries.Next();
        LibraryVariableStorage.Enqueue(EntryNumbers.Count());
        for RowIndex := 1 to EntryNumbers.Count() do begin
            LibraryVariableStorage.Enqueue(EntryNumbers.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Quantities.Get(RowIndex));
        end;
        Entries.Close();
    end;

    [ConfirmHandler]
    procedure SummaryReopenConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    procedure SummaryReopenedCardHandler(var ReleasedOrder: TestPage "Released Production Order")
    var
        Quantity: Decimal;
    begin
        Evaluate(Quantity, ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.Value());
        LibraryVariableStorage.Enqueue(Quantity);
        ReleasedOrder.Close();
    end;

    [Test]
    procedure CreateTransferOrderWithWIPItemFlag_CreatesSimpleWIPTransferLine()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Create Transfer Order with WIP Item and validate Transfer Line fields
        Initialize();
        // [GIVEN] Valid From and To Locations, In-Transit Location, and WIP Item details
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(FromLocation);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        LibraryInventory.CreateItem(Item);
        Quantity := 5;

        // [WHEN] Create Transfer Order with WIP Item
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        // [THEN] Assert TransferLine has WIP flag and every base quantity field is 0 as expected for WIP Item
        Assert.AreEqual(TransferLine."Transfer-from Code", FromLocation.Code, 'Transfer Line should have correct From Location');
        Assert.AreEqual(TransferLine."Transfer-to Code", ToLocation.Code, 'Transfer Line should have correct To Location');
        Assert.IsTrue(TransferLine."Transfer WIP Item", 'Transfer Line should have WIP Item flag set');
        Assert.AreEqual(TransferLine.Quantity, Quantity, 'Transfer Line should have correct quantity');
        Assert.AreEqual(TransferLine."Qty. to Ship", Quantity, 'Transfer Line should have correct Qty. to Ship');
        Assert.AreEqual(TransferLine."Qty. to receive", 0, 'Transfer Line should have correct Qty. to receive');
        Assert.AreEqual(TransferLine."Outstanding Quantity", Quantity, 'Transfer Line should have correct Outstanding Quantity');

        Assert.AreEqual(TransferLine."Qty. per Unit of Measure", 0, 'Transfer Line should have 0 in Qty. per Unit of Measure for WIP Item');
        Assert.AreEqual(TransferLine."Quantity (Base)", 0, 'Transfer Line should have 0 in Quantity (Base) for WIP Item');
        Assert.AreEqual(TransferLine."Qty. to Ship (Base)", 0, 'Transfer Line should have 0 in Qty. to Ship (Base) for WIP Item');
        Assert.AreEqual(TransferLine."Qty. to Receive (Base)", 0, 'Transfer Line should have 0 in Qty. to Receive (Base) for WIP Item');
        Assert.AreEqual(TransferLine."Outstanding Qty. (Base)", 0, 'Transfer Line should have 0 in Outstanding Qty. (Base) for WIP Item');
    end;

    [Test]
    procedure ToggleWIPFlag_UpdatesBaseQuantitiesCorrectly()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        QtyPerUOM: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO] Set WIP-Flag, validate base quantities, then unset WIP-Flag and validate quantities again, and repeat to ensure consistent behavior
        Initialize();
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(FromLocation);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 7;

        // [GIVEN] Transfer order with WIP flag
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        // [WHEN] Remove WIP flag from Transfer Line
        TransferLine.Validate("Transfer WIP Item", false);
        TransferLine.Modify();

        // [THEN] Base quantity fields should be calculated based on Quantity and Qty. per Unit of Measure, and WIP flag should be false
        QtyPerUOM := 1; // Default value if not set
        Assert.IsFalse(TransferLine."Transfer WIP Item", 'Transfer Line should not have WIP Item flag set');
        Assert.AreEqual(TransferLine."Quantity (Base)", Quantity, 'Quantity (Base) should match Quantity');
        Assert.AreEqual(TransferLine."Qty. to Ship (Base)", Quantity, 'Qty. to Ship (Base) should match Quantity');
        Assert.AreEqual(TransferLine."Qty. to Receive (Base)", 0, 'Qty. to Receive (Base) should match Quantity');
        Assert.AreEqual(TransferLine."Outstanding Qty. (Base)", Quantity, 'Outstanding Qty. (Base) should match Quantity');

        // [WHEN] Set WIP flag back on Transfer Line
        TransferLine.Validate("Transfer WIP Item", true);
        TransferLine.Modify();

        // [THEN] Base quantity fields should be reset to 0 and WIP flag should be true again
        Assert.IsTrue(TransferLine."Transfer WIP Item", 'Transfer Line should have WIP Item flag set again');
        Assert.AreEqual(TransferLine."Qty. per Unit of Measure", 0, 'Qty. per Unit of Measure should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Quantity (Base)", 0, 'Quantity (Base) should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Qty. to Ship (Base)", 0, 'Qty. to Ship (Base) should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Qty. to Receive (Base)", 0, 'Qty. to Receive (Base) should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Outstanding Qty. (Base)", 0, 'Outstanding Qty. (Base) should be 0 for WIP again');
    end;

    [Test]
    procedure PostWIPTransferOrder_ShipPartialReceiveFullReceive()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        FromReceiveBin, FromPutAwayBin, ToReceiveBin, ToPutAwayBin : Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity, PartialQty : Decimal;
        ItemLedgerEntryCountBefore, WarehouseEntryCountBefore : Integer;
    begin
        // [SCENARIO] Post WIP Transfer Order: first shipment only, then partial receipt, then remaining receipt
        Initialize();

        // [GIVEN] Transfer Order with WIP Item and bin handling
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(FromLocation, FromReceiveBin, FromPutAwayBin);
        FromLocation."Require Pick" := false;
        FromLocation."Require Put-away" := false;
        FromLocation."Require Receive" := false;
        FromLocation."Require Shipment" := false;
        FromLocation.Modify();

        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(ToLocation, ToReceiveBin, ToPutAwayBin);
        ToLocation."Require Pick" := false;
        ToLocation."Require Put-away" := false;
        ToLocation."Require Receive" := false;
        ToLocation."Require Shipment" := false;
        ToLocation.Modify();
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 10;
        PartialQty := 4;

        LibraryInventory.CreateItem(Item);
        CreateInventory(Item, FromLocation, FromPutAwayBin, Quantity, '');

        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);
        TransferLine.Validate("Transfer-from Bin Code", FromPutAwayBin.Code);
        TransferLine.Validate("Transfer-to Bin Code", ToReceiveBin.Code);
        TransferLine.Modify();

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] Post shipment only
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [THEN] Transfer Shipment is created and Qty. in Transit equals full quantity. No ItemLedgerEntries should be created since it's a WIP transfer
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(Quantity, TransferLine."Qty. in Transit", 'Qty. in Transit should equal full quantity after shipment');
        Assert.AreEqual(0, TransferShipmentLine."Quantity (Base)", 'Quantity (Base) on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferShipmentLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after shipment of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after shipment of WIP transfer');

        // [WHEN] Post partial receipt
        TransferLine.Validate("Qty. to receive", PartialQty);
        TransferLine.Modify();
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] Partial Transfer Receipt is created, Quantity Received equals partial and remaining is still in transit
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.IsTrue(TransferReceiptHeader.FindFirst(), 'Partial Transfer Receipt should be posted');
        TransferReceiptLine.Get(TransferReceiptHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(PartialQty, TransferLine."Quantity Received", 'Quantity Received should equal partial quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. Shipped (Base)", 'Qty. Shipped (Base) should still be 0 after partial receipt of WIP transfer');
        Assert.AreEqual(0, TransferLine."Qty. Received (Base)", 'Qty. Received (Base) should be 0 after partial receipt of WIP transfer');
        Assert.AreEqual(Quantity - PartialQty, TransferLine."Qty. in Transit", 'Qty. in Transit should be remaining quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. in Transit (Base)", 'Qty. in Transit (Base) should be 0 after partial receipt of WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Quantity (Base)", 'Quantity (Base) on Receive Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Receive Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after receive of WIP transfer');

        // [WHEN] Post remaining receipt
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] Two Transfer Receipts exist and Transfer Order is deleted (completed)
        Assert.AreEqual(2, TransferReceiptHeader.Count(), 'Two Transfer Receipts should be posted');
        Assert.IsFalse(TransferHeader.Get(TransferHeader."No."), 'Transfer Order should be deleted after all receipts are posted');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after receive of WIP transfer');
    end;

    [Test]
    [HandlerFunctions('BinMessageHandler,DeleteWhseReceiptConfimHandler')]
    procedure PostWIPTransferOrder_FullWhseHandling_ShipPartialReceiveFullReceive()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        FromStorageBin, ToReceiveBin, ToPutAwayBin : Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        Quantity, PartialQty : Decimal;
        ItemLedgerEntryCountBefore, WarehouseEntryCountBefore : Integer;
    begin
        // [SCENARIO] Post WIP Transfer Order using warehouse documents (Require Shipment, Receive, Pick, Put-Away all true):
        // ship via warehouse shipment, partial receive and full receive via warehouse receipts.
        // No Warehouse Picks or Put-Aways must be created despite Require Pick and Require Put-Away being enabled.
        Initialize();

        // [GIVEN] From location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(FromLocation, 5);
        LibraryWarehouse.CreateBin(FromStorageBin, FromLocation.Code, 'STORAGE', 'BULK', '');
        FromLocation.Validate("Default Bin Code", FromStorageBin.Code);
        FromLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, false);

        // [GIVEN] To location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(ToLocation, 5);
        LibraryWarehouse.CreateBin(ToReceiveBin, ToLocation.Code, 'RECEIVE', 'BULK', '');
        LibraryWarehouse.CreateBin(ToPutAwayBin, ToLocation.Code, 'PUTAWAY', 'BULK', '');
        ToLocation.Validate("Receipt Bin Code", ToReceiveBin.Code);
        ToLocation.Validate("Default Bin Code", ToPutAwayBin.Code);
        ToLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ToLocation.Code, true);

        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 10;
        PartialQty := 4;

        LibraryInventory.CreateItem(Item);
        CreateInventory(Item, FromLocation, FromStorageBin, Quantity, '');

        // [GIVEN] Transfer Order with WIP Item and bin assignment
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] Release Transfer Order and create Warehouse Shipment
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [THEN] No Warehouse Pick is created despite Require Pick = true (WIP transfer bypasses pick creation)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Location Code", FromLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [WHEN] Post Warehouse Shipment
        WarehouseShipmentHeader.SetRange("Location Code", FromLocation.Code);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Transfer Shipment is created with WIP behavior: base quantities are 0, no item/warehouse ledger entries created
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(Quantity, TransferLine."Qty. in Transit", 'Qty. in Transit should equal full quantity after shipment');
        Assert.AreEqual(0, TransferShipmentLine."Quantity (Base)", 'Quantity (Base) on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferShipmentLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after shipment of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after shipment of WIP transfer');

        // [WHEN] Create Warehouse Receipt for To Location and post partial receive
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.Validate("Qty. to Receive", PartialQty);
        WarehouseReceiptLine.Modify(true);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Partial Transfer Receipt created with WIP behavior and remaining quantity still in transit
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.IsTrue(TransferReceiptHeader.FindFirst(), 'Partial Transfer Receipt should be posted');
        TransferReceiptLine.Get(TransferReceiptHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(PartialQty, TransferLine."Quantity Received", 'Quantity Received should equal partial quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. Shipped (Base)", 'Qty. Shipped (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferLine."Qty. Received (Base)", 'Qty. Received (Base) should be 0 for WIP transfer');
        Assert.AreEqual(Quantity - PartialQty, TransferLine."Qty. in Transit", 'Qty. in Transit should be remaining quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. in Transit (Base)", 'Qty. in Transit (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Quantity (Base)", 'Quantity (Base) on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after partial receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after partial receive of WIP transfer');

        // [THEN] No Warehouse Put-Away created despite Require Put-Away = true (WIP transfer bypasses put-away creation)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [WHEN] Create second Warehouse Receipt for remaining quantity and post
        WarehouseReceiptHeader.Find('=');
        WarehouseReceiptHeader.Delete(true);
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Two Transfer Receipts exist and Transfer Order is deleted (completed)
        Assert.AreEqual(2, TransferReceiptHeader.Count(), 'Two Transfer Receipts should be posted');
        Assert.IsFalse(TransferHeader.Get(TransferHeader."No."), 'Transfer Order should be deleted after all receipts are posted');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after full receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after full receive of WIP transfer');

        // [THEN] Still no Warehouse Put-Away after final receive
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);
    end;

    [Test]
    [HandlerFunctions('BinMessageHandler,DeleteWhseReceiptConfimHandler')]
    procedure PostWIPTransferOrder_FullWhseHandling_SerialTrackedItem()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        FromStorageBin, ToReceiveBin, ToPutAwayBin : Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        NewLotNo: Code[50];
        Quantity, PartialQty : Decimal;
        ItemLedgerEntryCountBefore, WarehouseEntryCountBefore : Integer;
        TransferOrder: TestPage "Transfer Order";
        WarehouseReceiptPage: TestPage "Warehouse Receipt";
        WarehouseShipment: TestPage "Warehouse Shipment";
    begin
        // [SCENARIO] Post WIP Transfer Order via full-WMS warehouse documents using a serial-tracked item.
        // The item tracking actions on the Transfer Order Subform and the Warehouse Receipt Subform
        // must be Enabled = false for WIP items. Posting succeeds without creating any item or warehouse
        // ledger/tracking entries, and no Warehouse Picks or Put-Aways are generated.
        Initialize();

        // [GIVEN] From location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(FromLocation, 5);
        LibraryWarehouse.CreateBin(FromStorageBin, FromLocation.Code, 'STORAGE', 'BULK', '');
        FromLocation.Validate("Default Bin Code", FromStorageBin.Code);
        FromLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, false);

        // [GIVEN] To location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(ToLocation, 5);
        LibraryWarehouse.CreateBin(ToReceiveBin, ToLocation.Code, 'RECEIVE', 'BULK', '');
        LibraryWarehouse.CreateBin(ToPutAwayBin, ToLocation.Code, 'PUTAWAY', 'BULK', '');
        ToLocation.Validate("Receipt Bin Code", ToReceiveBin.Code);
        ToLocation.Validate("Default Bin Code", ToPutAwayBin.Code);
        ToLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ToLocation.Code, true);

        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 10;
        PartialQty := 4;

        // [GIVEN] Create lot-tracked item (Lot Warehouse Tracking enabled; Lot Specific = false so that
        // a plain item-journal inventory adjustment can be posted without assigning lot numbers,
        // while warehouse activities still enforce lot numbers — which are skipped for WIP transfers)
        LibraryItemTracking.CreateLotItem(Item);
        NewLotNo := LibraryUtility.GetNextNoFromNoSeries(LibraryUtility.GetGlobalNoSeriesCode(), WorkDate());

        // [GIVEN] Create inventory at From Location
        CreateInventory(Item, FromLocation, FromStorageBin, Quantity, NewLotNo);

        // [GIVEN] Transfer Order with WIP Item flag
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        Commit();
        TransferOrder.OpenEdit();
        TransferOrder.GoToRecord(TransferHeader);
        Assert.IsFalse(TransferOrder.TransferLines.Shipment.Enabled(), 'Shipment action should be disabled on Transfer Order Subform for WIP item');
        Assert.IsFalse(TransferOrder.TransferLines.Receipt.Enabled(), 'Receipt action should be disabled on Transfer Order Subform for WIP item');
        Assert.IsFalse(TransferOrder.TransferLines.Reserve.Enabled(), 'Reserve action should be disabled on Transfer Order Subform for WIP item');
        TransferOrder.Close();

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] Release Transfer Order and create Warehouse Shipment
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [THEN] No Warehouse Pick is created despite Require Pick = true (WIP transfer bypasses pick creation)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Location Code", FromLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);
        Commit();

        // [THEN] Item Tracking Lines action on Warehouse Shipment Subform should be Enabled = false for WIP item (enforced by page extension Subc. Whse Rcpt Subform Ext.)
        WarehouseShipmentHeader.SetRange("Location Code", FromLocation.Code);
        WarehouseShipmentHeader.FindFirst();
        WarehouseShipment.OpenEdit();
        WarehouseShipment.GoToRecord(WarehouseShipmentHeader);
        Assert.IsFalse(WarehouseShipment.WhseShptLines.ItemTrackingLines.Enabled(), 'Item Tracking Lines action should be disabled on Warehouse Shipment Subform for WIP item');
        WarehouseShipment.Close();

        // [WHEN] Post Warehouse Shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Transfer Shipment created with WIP behavior: base quantities are 0, no item/warehouse ledger entries
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(Quantity, TransferLine."Qty. in Transit", 'Qty. in Transit should equal full quantity after shipment');
        Assert.AreEqual(0, TransferShipmentLine."Quantity (Base)", 'Quantity (Base) on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferShipmentLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after shipment of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after shipment of WIP transfer');

        // [WHEN] Create Warehouse Receipt for To Location
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();

        // [THEN] Verify via TestPage that ItemTrackingLines action is disabled on Warehouse Receipt Subform
        WarehouseReceiptPage.OpenView();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        Assert.IsFalse(WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Enabled(), 'Item Tracking Lines action should be disabled on Warehouse Receipt Subform for WIP item');
        WarehouseReceiptPage.Close();

        // [WHEN] Post partial receipt
        WarehouseReceiptLine.Validate("Qty. to Receive", PartialQty);
        WarehouseReceiptLine.Modify(true);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Partial Transfer Receipt created with WIP behavior and remaining qty still in transit
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.IsTrue(TransferReceiptHeader.FindFirst(), 'Partial Transfer Receipt should be posted');
        TransferReceiptLine.Get(TransferReceiptHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(PartialQty, TransferLine."Quantity Received", 'Quantity Received should equal partial quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. Shipped (Base)", 'Qty. Shipped (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferLine."Qty. Received (Base)", 'Qty. Received (Base) should be 0 for WIP transfer');
        Assert.AreEqual(Quantity - PartialQty, TransferLine."Qty. in Transit", 'Qty. in Transit should be remaining quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. in Transit (Base)", 'Qty. in Transit (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Quantity (Base)", 'Quantity (Base) on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after partial receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after partial receive of WIP transfer');

        // [THEN] No Warehouse Put-Away created despite Require Put-Away = true
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [WHEN] Delete consumed receipt and create second Warehouse Receipt for remaining quantity
        WarehouseReceiptHeader.Find('=');
        WarehouseReceiptHeader.Delete(true);
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Two Transfer Receipts exist and Transfer Order is deleted (completed)
        Assert.AreEqual(2, TransferReceiptHeader.Count(), 'Two Transfer Receipts should be posted');
        Assert.IsFalse(TransferHeader.Get(TransferHeader."No."), 'Transfer Order should be deleted after all receipts are posted');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after full receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after full receive of WIP transfer');

        // [THEN] No Warehouse Put-Away after final receipt
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);
    end;

    [Test]
    procedure CalcRegenPlanForPlanWksh_WIPTransferLine_NotConsideredAsDemandOrSupply()
    var
        Customer: Record Customer;
        FromLocation, ToLocation, InTransitCode : Record Location;
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Planning Worksheet (Regenerative Plan) does not consider WIP Transfer Lines as demand or supply
        // because all base quantity fields ("Quantity (Base)", "Outstanding Qty. (Base)", etc.) are 0.
        // The planning uses SKU-level configuration with Replenishment System = Transfer.
        Initialize();
        Quantity := 10;

        // [GIVEN] Locations with Transfer Route and In-Transit Location
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(FromLocation);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);

        // [GIVEN] An item with a SKU at ToLocation configured for Transfer replenishment from FromLocation
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A WIP Transfer Order for the item (base quantities = 0)
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, ToLocation.Code, Item."No.", '');
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::Transfer);
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        StockkeepingUnit.Validate("Transfer-from Code", FromLocation.Code);
        StockkeepingUnit.Modify(true);

        // [GIVEN] Verify the WIP Transfer Line has base quantities = 0 (precondition)
        Assert.AreEqual(0, TransferLine."Quantity (Base)", 'Precondition: WIP Transfer Line Quantity (Base) must be 0');
        Assert.AreEqual(0, TransferLine."Outstanding Qty. (Base)", 'Precondition: WIP Transfer Line Outstanding Qty. (Base) must be 0');
        Assert.AreEqual(0, TransferLine."Qty. per Unit of Measure", 'Precondition: WIP Transfer Line Qty. per Unit of Measure must be 0');

        // [GIVEN] A Sales Order creating real demand for the item at the To Location
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, Customer."No.", Item."No.", Quantity, ToLocation.Code, WorkDate());

        // [WHEN] Run Regenerative Plan for Planning Worksheet
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));
        Commit();

        // [THEN] Requisition Lines are created for the Sales Order demand (Replenishment System = Transfer via SKU)
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::Transfer);
        Assert.IsTrue(RequisitionLine.FindFirst(), 'Planning should create a Requisition Line for the Sales Order demand');

        // [THEN] The planned transfer has the full base quantity (from Sales demand), proving the WIP Transfer Line was NOT used as supply
        Assert.AreEqual(RequisitionLine.Quantity, Quantity, 'Requisition Line Quantity should equal Sales Order quantity');
        Assert.AreEqual(Quantity, RequisitionLine."Quantity (Base)", 'Requisition Line Quantity (Base) should equal Sales demand quantity, proving WIP Transfer was not counted as supply');

        // [WHEN] Delete the Planning Worksheet lines, remove the WIP flag from the transfer line and run planning again
        RequisitionLine.Reset();
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.DeleteAll(true);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        TransferLine.Validate("Transfer WIP Item", false);
        TransferLine.Modify(true);
        Commit();

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));
        Commit();

        // [THEN] The transfer line is now considered by planning because it carries non-zero base quantities. No new Requisition Line should be created since the existing transfer can cover the demand.
        RequisitionLine.Reset();
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure PostWIPTransfer_WhenTransferLineHasAlternativeUOM_WIPLedgerEntryHasBaseUOM()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] WIP Ledger Entries use the item's base unit of measure even when the
        // subcontracting purchase order line carries a different (alternative) unit of measure.
        Initialize();

        // [GIVEN] Work centers, machine centers, item with subcontracting routing and Transfer WIP Item flag
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Item has an additional alternative UOM (6 base units each) — different from the base UOM
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", 6);

        // [GIVEN] Released Production Order refreshed at the manufacturing components location
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Subcontracting Purchase Order created via the Prod. Order Routing page
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [GIVEN] Change the purchase line UOM to the alternative UOM to simulate a non-base-UOM document
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Unit of Measure Code", ItemUOM.Code);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Create Transfer Route from production order location to subcontractor location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        CreateAndUpdateTransferRoute(ProductionOrder."Location Code", Vendor."Subc. Location Code");

        // [WHEN] Create WIP Transfer Order to Subcontractor and post the shipment
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.FindFirst();
        TransferHeader.Get(TransferLine."Document No.");
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [THEN] WIP Ledger Entries carry the item base unit of measure, not the document UOM
        WIPLedgerEntry.SetRange("Item No.", Item."No.");
        Assert.IsTrue(WIPLedgerEntry.FindSet(), 'WIP Ledger Entries must be created after posting the WIP transfer shipment.');
        repeat
            Assert.AreEqual(Item."Base Unit of Measure", WIPLedgerEntry."Base Unit of Measure",
                'WIP Ledger Entry Base Unit of Measure must equal the item base UOM, not the document UOM.');
        until WIPLedgerEntry.Next() = 0;
    end;

    [Test]
    procedure PostWhseShipment_WIPTransferLineBlankBin_BinMandatoryLocation_Posts()
    var
        FromLocation: Record Location;
        InTransitLocation: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Warehouse shipment for a WIP transfer line with blank Bin Code posts at a bin-mandatory, non-directed location
        Initialize();

        // [GIVEN] Bin-mandatory, non-directed location "L" with Require Shipment and no shipment or default bin
        LibraryWarehouse.CreateLocationWMS(FromLocation, true, false, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, false);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Quantity := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Released WIP transfer order "TO" from "L" for item "I"
        LibraryInventory.CreateItem(Item);
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, Item, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Warehouse shipment "WS" created from "TO" with WIP line having blank Bin Code
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, TransferLine);
        Assert.IsTrue(WarehouseShipmentLine."Transfer WIP Item", 'Warehouse Shipment Line must be a WIP line.');
        Assert.AreEqual('', WarehouseShipmentLine."Bin Code", 'Warehouse Shipment Line must have blank Bin Code.');

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Item No.", Item."No.");

        // [WHEN] Post warehouse shipment "WS"
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Transfer shipment is posted, full quantity is in transit and no item ledger or warehouse entries are created
        VerifyWIPTransferShipmentPosted(TransferLine, Quantity);
        Assert.RecordIsEmpty(ItemLedgerEntry);
        Assert.RecordIsEmpty(WarehouseEntry);
    end;

    [ConfirmHandler]
    procedure DoNotConfirmShowCreatedPurchOrderForSubcontracting(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [PageHandler]
    procedure HandleTransferOrder(var TransfOrderPage: TestPage "Transfer Order")
    begin
        TransfOrderPage.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure DeleteWhseReceiptConfimHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if Question.Contains('Do you really want to delete the Whse. Receipt') then begin
            Reply := true;
            exit;
        end;
        Error('Unexpected confirmation message.');
    end;

    [MessageHandler]
    procedure BinMessageHandler(Message: Text[1024])
    begin
        if Message.Contains('Transfer order') and Message.Contains('was successfully posted') then
            exit;
        Error('Unexpected Message.');
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. WIP Transfer Post Test");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. WIP Transfer Post Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. WIP Transfer Post Test");
    end;

    procedure CreateInventory(Item: Record Item; Location: Record Location; Bin: Record Bin; Quantity: Decimal; LotNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
        ItemJournalLine, Item."No.", Location.Code, Bin.Code, Quantity);

        if LotNo <> '' then
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SetTransferWIPItemOnRoutingLine(RoutingNo: Code[20]; WorkCenterNo: Code[20]; TransferWIPItem: Boolean)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        RoutingHeader.Get(RoutingNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        RoutingLine.FindFirst();
        RoutingLine."Transfer WIP Item" := TransferWIPItem;
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure SetProdOrderLocationToCompSetupLocationAndRefresh(var ProductionOrder: Record "Production Order")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ProductionOrder.Validate("Location Code", ManufacturingSetup."Components at Location");
        ProductionOrder.Modify();
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndUpdateTransferRoute(FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        Location: Record Location;
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateInTransitLocation(Location);
        LibraryWarehouse.CreateAndUpdateTransferRoute(
            TransferRoute, FromLocationCode, ToLocationCode, Location.Code, '', '');
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; TransferLine: Record "Transfer Line")
    begin
        WarehouseShipmentLine.SetRange("Source Type", Database::"Transfer Line");
        WarehouseShipmentLine.SetRange("Source No.", TransferLine."Document No.");
        WarehouseShipmentLine.SetRange("Source Line No.", TransferLine."Line No.");
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure VerifyWIPTransferShipmentPosted(TransferLine: Record "Transfer Line"; ExpectedQuantity: Decimal)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferLine."Document No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", TransferLine."Line No.");
        Assert.AreEqual(ExpectedQuantity, TransferShipmentLine.Quantity, 'Transfer Shipment Line Quantity is incorrect.');
        Assert.AreEqual(0, TransferShipmentLine."Quantity (Base)", 'Transfer Shipment Line Quantity (Base) must be 0 for WIP transfer.');

        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(ExpectedQuantity, TransferLine."Qty. in Transit", 'Qty. in Transit is incorrect.');

        PostedWhseShipmentLine.SetRange("Source No.", TransferLine."Document No.");
        PostedWhseShipmentLine.SetRange("Source Line No.", TransferLine."Line No.");
        PostedWhseShipmentLine.FindFirst();
        Assert.AreEqual(ExpectedQuantity, PostedWhseShipmentLine.Quantity, 'Posted Whse. Shipment Line Quantity is incorrect.');
        Assert.AreEqual('', PostedWhseShipmentLine."Bin Code", 'Posted Whse. Shipment Line Bin Code must remain blank.');
    end;
}