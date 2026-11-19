// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;
using System.Reflection;
using System.TestLibraries.Environment.Configuration;
using System.TestLibraries.Utilities;

codeunit 139990 "Subc. Subcontracting UI Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('SummaryReadTransferCreatedHandler,SummaryTransferLinesHandler')]
    procedure SummaryOriginalTransferLinesDrilldown()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        OtherWorkCenter: Record "Work Center";
        Items: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        OtherPurchaseHeader: Record "Purchase Header";
        OtherPurchaseLine: Record "Purchase Line";
        ForwardHeader: Record "Transfer Header";
        ReturnHeader: Record "Transfer Header";
        OtherTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Original-line counts and detail exclude native derived lines and disappear after actual completion.
        InitializeSummaryPurchasing();

        // [GIVEN] Two real family WIP lines share one native forward header; another order has an unrelated transfer.
        SubcWarehouseLibrary.CreateSummaryFamily(10, 10, ProductionOrder, WorkCenter, Items);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);
        SubcWarehouseLibrary.CreateSummaryForward(ProductionOrder, WorkCenter, PurchaseHeader, ForwardHeader);
        SubcWarehouseLibrary.CreateSummaryOrder(5, OtherOrder, OtherWorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(OtherOrder, OtherWorkCenter, OtherPurchaseHeader, OtherPurchaseLine);
        SubcWarehouseLibrary.CreateSummaryForward(OtherOrder, OtherWorkCenter, OtherPurchaseHeader, OtherTransferHeader);
        TransferLine.SetRange("Document No.", ForwardHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        Assert.AreEqual(2, TransferLine.Count(), 'Family forward must contain two originals, not two headers.');
        TransferLine.FindSet();
        repeat
            TransferLine.Validate("Qty. to Ship", 4);
            TransferLine.Modify(true);
        until TransferLine.Next() = 0;

        // [WHEN] Native partial shipment creates derived lines, then receipt makes real WIP available for native return creation.
        LibraryWarehouse.PostTransferOrder(ForwardHeader, true, false);
        TransferLine.SetFilter("Derived From Line No.", '<>0');
        Assert.RecordIsNotEmpty(TransferLine);
        LibraryWarehouse.PostTransferOrder(ForwardHeader, false, true);
        SubcWarehouseLibrary.CreateSummaryReturn(PurchaseHeader, ReturnHeader);

        // [THEN] Each field counts two originals on one header and drills to its own exact source population.
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.TransferCount.AssertEquals(2);
        ReleasedOrder.SubcontractingSummary.ReturnTransferCount.AssertEquals(2);
        ReleasedOrder.Close();
        VerifySummaryTransferDetails(ProductionOrder, false);
        VerifySummaryTransferDetails(ProductionOrder, true);

        // [WHEN] All remaining forward quantities and then the available return quantities are actually completed.
        LibraryWarehouse.PostTransferOrder(ForwardHeader, true, true);
        LibraryWarehouse.PostTransferOrder(ReturnHeader, true, true);

        // [THEN] Completed source rows and both detail populations are empty, without a cached header count.
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.TransferCount.AssertEquals(0);
        ReleasedOrder.SubcontractingSummary.ReturnTransferCount.AssertEquals(0);
        ReleasedOrder.Close();
        VerifySummaryTransferDetails(ProductionOrder, false);
        VerifySummaryTransferDetails(ProductionOrder, true);
        Assert.IsTrue(OtherTransferHeader.Get(OtherTransferHeader."No."), 'Unrelated original transfer must remain untouched.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SummaryReadTransferCreatedHandler,SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler,SummaryTransferLinesHandler,SummaryConformanceWIPHandler,SummaryConformanceRoutingHandler')]
    procedure SummaryFeatureWideConformance()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ForwardHeader: Record "Transfer Header";
        ReturnHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] The actual Released card consumes the complete approved worked purchasing and forward/return WIP request.
        InitializeSummaryPurchasing();

        // [GIVEN] A real order of ten, another order sharing routing, and a native purchase order still available for transfer creation.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            OtherOrder, OtherOrder.Status::Released, OtherOrder."Source Type"::Item, ProductionOrder."Source No.", 4, ProductionOrder."Location Code");
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        SubcWarehouseLibrary.CreateSummaryForward(ProductionOrder, WorkCenter, PurchaseHeader, ForwardHeader);

        // [WHEN] Ten are shipped and received in two native stages, then three are returned before invoicing deletes the PO.
        LibraryWarehouse.PostTransferOrder(ForwardHeader, true, false);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 0, 10);
        TransferLine.SetRange("Document No.", ForwardHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.FindFirst();
        TransferLine.Validate("Qty. to Receive", 4);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(ForwardHeader, false, true);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 4, 6);
        LibraryWarehouse.PostTransferOrder(ForwardHeader, false, true);
        SubcWarehouseLibrary.CreateSummaryReturn(PurchaseHeader, ReturnHeader);
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", ReturnHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.FindFirst();
        TransferLine.Validate(Quantity, 3);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(ReturnHeader, true, false);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 7, 3);
        LibraryWarehouse.PostTransferOrder(ReturnHeader, false, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 4);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 6);

        // [THEN] All nine final card values, source details and the untouched other order agree.
        SubcWarehouseLibrary.VerifySummaryCard(ProductionOrder, 1, 0, 10, 10, true, 7, 0, 0, 0);
        SubcWarehouseLibrary.VerifySummaryCard(OtherOrder, 1, 0, 0, 0, true, 0, 0, 0, 0);
        VerifySummaryPurchaseDetails(ProductionOrder);
        VerifySummaryTransferDetails(ProductionOrder, false);
        VerifySummaryTransferDetails(ProductionOrder, true);
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.RoutingCount.DrillDown();
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'Exactly the current subcontract operation must be returned.');
        Assert.AreEqual(ProductionOrder."No.", LibraryVariableStorage.DequeueText(), 'Routing detail must retain the current order.');
        Assert.AreEqual('10', LibraryVariableStorage.DequeueText(), 'Routing detail must retain the operation key.');
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.DrillDown();
        VerifySummaryConformanceWIPRows(ProductionOrder, false);
        ReleasedOrder.SubcontractingSummary.WIPInTransit.DrillDown();
        VerifySummaryConformanceWIPRows(ProductionOrder, true);
        ReleasedOrder.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler')]
    procedure SummaryPurchasingLifecycle()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Actual purchase persistence and all three card drilldowns agree at each lifecycle boundary.
        InitializeSummaryPurchasing();

        // [GIVEN] A real subcontract order and its native purchase order.
        // [WHEN] Receipt and two invoices are posted.
        // [THEN] The genuine card and details follow all four persisted states.
        RunSummaryPurchaseLifecycle();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler')]
    procedure SummaryFullyInvoicedLifecycle()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Exact receipt equality alone is insufficient until the linked quantity is invoiced.
        InitializeSummaryPurchasing();

        // [GIVEN] A real ten-unit open purchase line, initially with equal empty history.
        // [WHEN] Native posting receives ten and invoices four then six.
        // [THEN] The card is No, No, No, then Yes after native purchase-order deletion.
        RunSummaryPurchaseLifecycle();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler')]
    procedure SummaryFamilyRawQuantities()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Every real family contributor posts in its document unit; raw totals are not base totals.
        InitializeSummaryPurchasing();

        // [GIVEN] Two family outputs with factor-six and base document units.
        // [WHEN] Both contributors are received and invoiced through native purchasing.
        // [THEN] Card and detail show .16 and .30, not converted .46 and .80.
        RunSummaryFamilyPurchasing(0.06, 0.10);
        RunSummaryFamilyPurchasing(0.10, 0.20);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler')]
    procedure SummaryMultipleOperationsAndIsolation()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        SecondWorkCenter: Record "Work Center";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        OtherHeader: Record "Purchase Header";
        OtherLine: Record "Purchase Line";
        OrdinaryLine: Record "Purchase Line";
        OrdinaryItem: Record Item;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Multiple purchased operations aggregate once per source row and exclude other orders and ancillary links.
        InitializeSummaryPurchasing();

        // [GIVEN] "A" and "B" share two real subcontract operations.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        AddSummarySecondOperation(ProductionOrder, SecondWorkCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            OtherOrder, OtherOrder.Status::Released, OtherOrder."Source Type"::Item, ProductionOrder."Source No.", 7, ProductionOrder."Location Code");
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader[1], PurchaseLine[1]);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, SecondWorkCenter, PurchaseHeader[2], PurchaseLine[2]);
        LibraryInventory.CreateItem(OrdinaryItem);
        LibraryPurchase.CreatePurchaseLine(OrdinaryLine, PurchaseHeader[1], OrdinaryLine.Type::Item, OrdinaryItem."No.", 3);
        OrdinaryLine.Validate("Qty. to Receive", 0);
        OrdinaryLine.Validate("Qty. to Invoice", 0);
        OrdinaryLine.Modify(true);

        // [WHEN] Both operations of both orders are received, but only "A"'s first is invoiced.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, false);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader[1], PurchaseLine[1], 10);
        SubcWarehouseLibrary.CreateSummaryPurchase(OtherOrder, WorkCenter, OtherHeader, OtherLine);
        LibraryPurchase.PostPurchaseDocument(OtherHeader, true, false);
        Clear(OtherLine);
        SubcWarehouseLibrary.CreateSummaryPurchase(OtherOrder, SecondWorkCenter, OtherHeader, OtherLine);
        LibraryPurchase.PostPurchaseDocument(OtherHeader, true, false);
        CreateSummaryAncillaryLine(ProductionOrder);

        // [THEN] Raw operation totals are 20, not unique output 10; other and ancillary lines do not leak.
        VerifySummaryPurchaseCard(ProductionOrder, 20, 20, 10, false);
        VerifySummaryPurchaseCard(OtherOrder, 14, 14, 0, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        VerifySummaryPurchaseDetails(OtherOrder);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SummaryRetainedLineUsesQuantityPredicate()
    var
        ProductionOrder: Record "Production Order";
        PartialOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OrdinaryLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Retained fully invoiced lines do not count as open; editable quantities and header status do not decide.
        InitializeSummaryPurchasing();

        // [GIVEN] A mixed purchase order retains the fully posted subcontract line.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(OrdinaryLine, PurchaseHeader, OrdinaryLine.Type::Item, Item."No.", 3);
        OrdinaryLine.Validate("Qty. to Receive", 0);
        OrdinaryLine.Validate("Qty. to Invoice", 0);
        OrdinaryLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Only the subcontract line is fully invoiced.
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 10);

        // [THEN] The retained linked line is not open, irrespective of header status.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(10, PurchaseLine."Quantity Invoiced", 'The retained linked quantity must be posted, not assigned.');
        VerifySummaryPurchaseCard(ProductionOrder, 10, 10, 10, true);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        VerifySummaryPurchaseCard(ProductionOrder, 10, 10, 10, true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        VerifySummaryPurchaseCard(ProductionOrder, 10, 10, 10, true);

        // [GIVEN] Another order is only partially invoiced, with editable Qty. to Invoice zero.
        Clear(PurchaseLine);
        SubcWarehouseLibrary.CreateSummaryOrder(10, PartialOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(PartialOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 4);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Invoice", 0);
        PurchaseLine.Modify(true);

        // [THEN] Posted inequality still makes the card No.
        VerifySummaryPurchaseCard(PartialOrder, 10, 10, 4, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        VerifySummaryPurchaseCard(PartialOrder, 10, 10, 4, false);
    end;

    [Test]
#pragma warning disable AA0210 // Bounded receipt and correction fixtures.
    [HandlerFunctions('SummaryConfirmHandler,SummaryReceiptLinesHandler')]
    procedure SummaryReceiptUndoSigned()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Native receipt undo appends signed history, while its reopened purchase line prevents Yes.
        InitializeSummaryPurchasing();

        // [GIVEN] An uninvoiced, unapplied real subcontract receipt of ten.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        ReceiptLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ReceiptLine.FindFirst();

        // [WHEN] Native undo is performed before any application or invoice.
        LibraryPurchase.UndoPurchaseReceiptLine(ReceiptLine);

        // [THEN] Both correction rows appear and net to zero, but the original quantity remains open.
        ReceiptLine.Reset();
        ReceiptLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.AreEqual(2, ReceiptLine.Count(), 'Undo must retain original and negative correction.');
        ReceiptLine.CalcSums(Quantity);
        Assert.AreEqual(0, ReceiptLine.Quantity, 'Signed receipt history must net to zero.');
        ReceiptLine.SetFilter(Quantity, '>0');
        ReceiptLine.CalcSums(Quantity);
        Assert.AreEqual(10, ReceiptLine.Quantity, 'The original positive receipt must remain.');
        ReceiptLine.SetFilter(Quantity, '<0');
        ReceiptLine.CalcSums(Quantity);
        Assert.AreEqual(-10, ReceiptLine.Quantity, 'Native undo must append the negative correction.');
        VerifySummaryPurchaseCard(ProductionOrder, 10, 0, 0, false);
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.ReceiptQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        VerifySummaryReceiptDetailRows(ProductionOrder);
        ReleasedOrder.Close();
        LibraryVariableStorage.AssertEmpty();
    end;
#pragma warning restore AA0210

    [Test]
    procedure SummaryEmptyQuantityProxy()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Empty real eligible orders have equal empty history and no open linked purchase lines.
        InitializeSummaryPurchasing();

        // [GIVEN] Real routing exists, but no purchase creator has run.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);

        // [WHEN] The real Released card is read.
        // [THEN] The complete empty summary has Fully Invoiced Yes.
        SubcWarehouseLibrary.VerifySummaryCard(ProductionOrder, 1, 0, 0, 0, true, 0, 0, 0, 0);
    end;

    [Test]
    [HandlerFunctions('SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler')]
    procedure SummaryNamedSourcesAndCorrections()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseLine: Record "Purchase Line";
        CreditLine: Record "Purch. Cr. Memo Line";
        ReturnLine: Record "Return Shipment Line";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] The actual card and drilldowns retain signed named sources and exclude credit and return populations.
        InitializeSummaryPurchasing();

        // [GIVEN] Named signed receipt/invoice rows net to four; excluded sources have unmatched quantities.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.InsertSummaryReceipt(ProductionOrder."No.", 5);
        SubcWarehouseLibrary.InsertSummaryReceipt(ProductionOrder."No.", -1);
        SubcWarehouseLibrary.InsertSummaryInvoice(ProductionOrder."No.", 5);
        SubcWarehouseLibrary.InsertSummaryInvoice(ProductionOrder."No.", -1);
        SubcWarehouseLibrary.InsertSummaryPurchase(ProductionOrder."No.", PurchaseLine."Document Type"::"Return Order", 100, 0, PurchaseLine);
        SubcWarehouseLibrary.InsertSummaryPurchase(ProductionOrder."No.", PurchaseLine."Document Type"::"Credit Memo", 200, 0, PurchaseLine);
        CreditLine."Document No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(CreditLine."Document No."));
        CreditLine."Line No." := 10000;
        CreditLine."Prod. Order No." := ProductionOrder."No.";
        CreditLine.Quantity := 300;
        CreditLine.Insert();
        ReturnLine."Document No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ReturnLine."Document No."));
        ReturnLine."Line No." := 10000;
        ReturnLine."Prod. Order No." := ProductionOrder."No.";
        ReturnLine.Quantity := 400;
        ReturnLine.Insert();
        SubcWarehouseLibrary.VerifySummaryCard(ProductionOrder, 1, 0, 4, 4, true, 0, 0, 0, 0);
        VerifySummaryPurchaseDetails(ProductionOrder);

        // [WHEN] A further correction is added to the named invoice source.
        SubcWarehouseLibrary.InsertSummaryInvoice(ProductionOrder."No.", -0.5);

        // [THEN] Its sign is retained and exact equality is lost.
        SubcWarehouseLibrary.VerifySummaryCard(ProductionOrder, 1, 0, 4, 3.5, false, 0, 0, 0, 0);
        VerifySummaryPurchaseDetails(ProductionOrder);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifySummaryTransferDetails(ProductionOrder: Record "Production Order"; ReturnOrder: Boolean)
    var
        TransferLine: Record "Transfer Line";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        if ReturnOrder then
            ReleasedOrder.SubcontractingSummary.ReturnTransferCount.DrillDown()
        else
            ReleasedOrder.SubcontractingSummary.TransferCount.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.SetRange("Subc. Return Order", ReturnOrder);
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(TransferLine.Count());
        Assert.AreEqual(TransferLine.Count(), LibraryVariableStorage.DequeueInteger(), 'Transfer detail must count original lines, not headers.');
        if TransferLine.FindSet() then
            repeat
                SubcWarehouseLibrary.VerifySummaryDetailRecord(TransferLine.RecordId());
                Assert.AreEqual(TransferLine."Document No.", LibraryVariableStorage.DequeueText(), 'Transfer document must match the filtered original.');
                Assert.AreEqual(TransferLine."Item No.", LibraryVariableStorage.DequeueText(), 'Every original family item must appear.');
                Assert.AreEqual(TransferLine."Outstanding Quantity", LibraryVariableStorage.DequeueDecimal(), 'Transfer detail quantity must match.');
            until TransferLine.Next() = 0;
        ReleasedOrder.Close();
    end;

    local procedure VerifySummaryConformanceWIPRows(ProductionOrder: Record "Production Order"; InTransit: Boolean)
    var
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        WIPEntry.SetRange("In Transit", InTransit);
        Assert.AreEqual(WIPEntry.Count(), LibraryVariableStorage.DequeueInteger(), 'Worked request WIP detail count must agree.');
        if WIPEntry.FindSet() then
            repeat
                Assert.AreEqual(WIPEntry."Entry No.", LibraryVariableStorage.DequeueInteger(), 'Worked request must return every exact ledger key.');
                Assert.AreEqual(WIPEntry."Quantity (Base)", LibraryVariableStorage.DequeueDecimal(), 'Worked request detail must preserve signed movements.');
            until WIPEntry.Next() = 0;
    end;

    [PageHandler]
    procedure SummaryTransferLinesHandler(var Lines: TestPage "Transfer Lines")
    var
        Documents: List of [Text];
        Items: List of [Text];
        Quantities: List of [Decimal];
        RowIndex: Integer;
        Quantity: Decimal;
    begin
        if Lines.First() then
            repeat
                Documents.Add(Lines."Document No.".Value());
                Items.Add(Lines."Item No.".Value());
                Evaluate(Quantity, Lines."Outstanding Quantity".Value());
                Quantities.Add(Quantity);
            until not Lines.Next();
        LibraryVariableStorage.Enqueue(Documents.Count());
        for RowIndex := 1 to Documents.Count() do begin
            LibraryVariableStorage.Enqueue(Documents.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Items.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Quantities.Get(RowIndex));
        end;
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryConformanceWIPHandler(var Entries: TestPage "Subc. WIP Ledger Entries")
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

    [PageHandler]
    procedure SummaryConformanceRoutingHandler(var Routing: TestPage "Prod. Order Routing")
    var
        Orders: List of [Text];
        Operations: List of [Text];
        RowIndex: Integer;
    begin
        if Routing.First() then
            repeat
                Orders.Add(Routing."Prod. Order No.".Value());
                Operations.Add(Routing."Operation No.".Value());
            until not Routing.Next();
        LibraryVariableStorage.Enqueue(Orders.Count());
        for RowIndex := 1 to Orders.Count() do begin
            LibraryVariableStorage.Enqueue(Orders.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Operations.Get(RowIndex));
        end;
        Routing.Close();
    end;

    local procedure RunSummaryPurchaseLifecycle()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        VerifySummaryPurchaseCard(ProductionOrder, 10, 0, 0, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VerifySummaryPurchaseCard(ProductionOrder, 10, 10, 0, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 4);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(4, PurchaseLine."Quantity Invoiced", 'Partial quantity must be persisted by posting.');
        VerifySummaryPurchaseCard(ProductionOrder, 10, 10, 4, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 6);
        Assert.IsFalse(PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No."), 'Native final posting must delete the simple order.');
        VerifySummaryPurchaseCard(ProductionOrder, 0, 10, 10, true);
        VerifySummaryPurchaseDetails(ProductionOrder);
    end;

    local procedure RunSummaryFamilyPurchasing(FirstQuantity: Decimal; SecondQuantity: Decimal)
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        Items: array[2] of Record Item;
        ItemUOM: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        InvoiceLine: Record "Purch. Inv. Line";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        SubcWarehouseLibrary.CreateSummaryFamily(FirstQuantity * 6, SecondQuantity, ProductionOrder, WorkCenter, Items);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Items[1]."No.", 6);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", Items[1]."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Unit of Measure Code", ItemUOM.Code);
        PurchaseLine.Validate(Quantity, FirstQuantity);
        PurchaseLine.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        ItemUOM.Get(PurchaseLine."No.", PurchaseLine."Unit of Measure Code");
        Assert.AreEqual(6, ItemUOM."Qty. per Unit of Measure", 'First contributor must use the factor-six item UOM conversion.');
        PurchaseLine.SetRange("No.", Items[2]."No.");
        PurchaseLine.FindFirst();
        Assert.AreEqual(SecondQuantity, PurchaseLine.Quantity, 'Second contributor must exist with its raw quantity.');
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifySummaryPurchaseCard(ProductionOrder, FirstQuantity + SecondQuantity, 0, 0, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VerifySummaryPurchaseCard(ProductionOrder, FirstQuantity + SecondQuantity, FirstQuantity + SecondQuantity, 0, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(PurchaseHeader."Vendor Invoice No.")));
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        VerifySummaryPurchaseCard(ProductionOrder, 0, FirstQuantity + SecondQuantity, FirstQuantity + SecondQuantity, true);
        VerifySummaryPurchaseDetails(ProductionOrder);
#pragma warning disable AA0210 // Filters inspect only the documents created by this family fixture.
        ReceiptLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ReceiptLine.SetRange("No.", Items[1]."No.");
        ReceiptLine.FindFirst();
        Assert.AreEqual(FirstQuantity, ReceiptLine.Quantity, 'First family receipt must retain document quantity.');
        Assert.AreEqual(ItemUOM.Code, ReceiptLine."Unit of Measure Code", 'First family receipt must retain document UOM.');
        ReceiptLine.SetRange("No.", Items[2]."No.");
        ReceiptLine.FindFirst();
        Assert.AreEqual(SecondQuantity, ReceiptLine.Quantity, 'Second family receipt must be posted.');
        InvoiceLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        InvoiceLine.SetRange("No.", Items[1]."No.");
        InvoiceLine.FindFirst();
        Assert.AreEqual(FirstQuantity, InvoiceLine.Quantity, 'First family invoice must be posted.');
        Assert.AreEqual(ItemUOM.Code, InvoiceLine."Unit of Measure Code", 'First family invoice must retain document UOM.');
        InvoiceLine.SetRange("No.", Items[2]."No.");
#pragma warning restore AA0210
        InvoiceLine.FindFirst();
        Assert.AreEqual(SecondQuantity, InvoiceLine.Quantity, 'Second family invoice must be posted.');
    end;

    local procedure VerifySummaryPurchaseCard(ProductionOrder: Record "Production Order"; PurchaseQuantity: Decimal; ReceiptQuantity: Decimal; InvoiceQuantity: Decimal; FullyInvoiced: Boolean)
    var
        ReleasedOrder: TestPage "Released Production Order";
    begin
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.PurchaseQuantity.AssertEquals(PurchaseQuantity);
        ReleasedOrder.SubcontractingSummary.ReceiptQuantity.AssertEquals(ReceiptQuantity);
        ReleasedOrder.SubcontractingSummary.InvoiceQuantity.AssertEquals(InvoiceQuantity);
        ReleasedOrder.SubcontractingSummary.FullyInvoiced.AssertEquals(Format(FullyInvoiced));
        ReleasedOrder.Close();
    end;

    local procedure VerifySummaryPurchaseDetails(ProductionOrder: Record "Production Order")
    var
        PurchaseLine: Record "Purchase Line";
        InvoiceLine: Record "Purch. Inv. Line";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.PurchaseQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(PurchaseLine.Count());
        Assert.AreEqual(PurchaseLine.Count(), LibraryVariableStorage.DequeueInteger(), 'Purchase detail row count must match.');
        if PurchaseLine.FindSet() then
            repeat
                SubcWarehouseLibrary.VerifySummaryDetailRecord(PurchaseLine.RecordId());
                Assert.AreEqual(PurchaseLine."Document No.", LibraryVariableStorage.DequeueText(), 'Purchase document key must match.');
                Assert.AreEqual(PurchaseLine.Quantity, LibraryVariableStorage.DequeueDecimal(), 'Raw purchase detail quantity must match.');
            until PurchaseLine.Next() = 0;
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.ReceiptQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        VerifySummaryReceiptDetailRows(ProductionOrder);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.InvoiceQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        InvoiceLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(InvoiceLine.Count());
        Assert.AreEqual(InvoiceLine.Count(), LibraryVariableStorage.DequeueInteger(), 'Invoice detail row count must match.');
        if InvoiceLine.FindSet() then
            repeat
                SubcWarehouseLibrary.VerifySummaryDetailRecord(InvoiceLine.RecordId());
                Assert.AreEqual(InvoiceLine."Document No.", LibraryVariableStorage.DequeueText(), 'Invoice document must match.');
                Assert.AreEqual(InvoiceLine."No.", LibraryVariableStorage.DequeueText(), 'Invoice item must match.');
                Assert.AreEqual(InvoiceLine.Quantity, LibraryVariableStorage.DequeueDecimal(), 'Raw signed invoice quantity must match.');
            until InvoiceLine.Next() = 0;
        ReleasedOrder.Close();
    end;

    local procedure VerifySummaryReceiptDetailRows(ProductionOrder: Record "Production Order")
    var
        ReceiptLine: Record "Purch. Rcpt. Line";
    begin
        ReceiptLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(ReceiptLine.Count());
        if ReceiptLine.FindSet() then
            repeat
                SubcWarehouseLibrary.VerifySummaryDetailRecord(ReceiptLine.RecordId());
            until ReceiptLine.Next() = 0;
    end;

    local procedure CreateSummaryAncillaryLine(ProductionOrder: Record "Production Order")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 99);
        PurchaseLine."Subc. Prod. Order No." := ProductionOrder."No.";
        PurchaseLine.Modify(true);
    end;

    local procedure AddSummarySecondOperation(var ProductionOrder: Record "Production Order"; var WorkCenter: Record "Work Center")
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        Item.Get(ProductionOrder."Source No.");
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);
        LibraryMfgManagement.CreateSubcontractingWorkCenterWithCalendar(WorkCenter);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter."Subcontractor No.");
        Vendor.Validate("Subc. Location Code", Location.Code);
        Vendor.Modify(true);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    [ConfirmHandler]
    procedure SummaryConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    procedure SummaryPurchaseLinesHandler(var Lines: TestPage "Purchase Lines")
    var
        Documents: List of [Text];
        Quantities: List of [Decimal];
        RowIndex: Integer;
        Quantity: Decimal;
    begin
        if Lines.First() then
            repeat
                Documents.Add(Lines."Document No.".Value());
                Evaluate(Quantity, Lines.Quantity.Value());
                Quantities.Add(Quantity);
            until not Lines.Next();
        LibraryVariableStorage.Enqueue(Documents.Count());
        for RowIndex := 1 to Documents.Count() do begin
            LibraryVariableStorage.Enqueue(Documents.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Quantities.Get(RowIndex));
        end;
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryReceiptLinesHandler(var Lines: TestPage "Purch. Receipt Lines")
    var
        HasRecord: Boolean;
    begin
        HasRecord := Lines.First();
        while HasRecord do
            HasRecord := Lines.Next();
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryInvoiceLinesHandler(var Lines: TestPage "Subc. Summary Invoice Lines")
    var
        Documents: List of [Text];
        Items: List of [Text];
        Quantities: List of [Decimal];
        RowIndex: Integer;
        Quantity: Decimal;
    begin
        if Lines.First() then
            repeat
                Documents.Add(Lines."Document No.".Value());
                Items.Add(Lines."No.".Value());
                Evaluate(Quantity, Lines.Quantity.Value());
                Quantities.Add(Quantity);
            until not Lines.Next();
        LibraryVariableStorage.Enqueue(Documents.Count());
        for RowIndex := 1 to Documents.Count() do begin
            LibraryVariableStorage.Enqueue(Documents.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Items.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Quantities.Get(RowIndex));
        end;
        Lines.Close();
    end;

    local procedure InitializeSummaryPurchasing()
    begin
        Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
    end;

    [Test]
    [HandlerFunctions('SummaryRoutingHandler')]
    procedure SummaryCardRoutingAndEligibility()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        ReleasedOrders: TestPage "Released Production Orders";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] The genuine card aggregates current subcontract operations, not internal or other-order lines.
        Initialize();

        // [GIVEN] Order "A" has two subcontract operations and one internal operation; "B" shares its routing.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        AddSummaryRoutingOperations(ProductionOrder, true);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            OtherOrder, OtherOrder.Status::Released, OtherOrder."Source Type"::Item, ProductionOrder."Source No.", 7, ProductionOrder."Location Code");

        // [WHEN] The real Released list opens its card and the routing detail is invoked.
        ReleasedOrders.OpenView();
        ReleasedOrders.GoToRecord(ProductionOrder);
        ReleasedOrder.Trap();
        ReleasedOrders.Edit().Invoke();
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(2);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.RoutingCount.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);

        // [THEN] Only "A"'s subcontract operation keys are returned.
        VerifySummaryRoutingDetails(ProductionOrder);
        ReleasedOrder.Close();
        ReleasedOrders.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SummaryCardNavigationAndBlankGuard()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        OtherWorkCenter: Record "Work Center";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Navigation clears hidden and blank records instead of retaining another order's values.
        Initialize();

        // [GIVEN] Eligible "A" and internal-only "B".
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        AddSummaryRoutingOperations(ProductionOrder, true);
        SubcWarehouseLibrary.CreateSummaryOrder(7, OtherOrder, OtherWorkCenter);
        OtherWorkCenter.Validate("Subcontractor No.", '');
        OtherWorkCenter.Modify(true);

        // [WHEN] The actual card navigates "A" -> "B" -> "A".
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(2);
        ReleasedOrder.GoToRecord(OtherOrder);

        // [THEN] "B" is ineligible and does not inherit "A"; "A" is recomputed on return.
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.Visible(), 'Internal-only order must hide the summary.');
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(2);
        ReleasedOrder.Close();
        ReleasedOrder.OpenNew();
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.Visible(), 'Blank card must hide the summary.');
        ReleasedOrder.Close();
    end;

    [Test]
    [HandlerFunctions('SummaryRefreshProductionOrderHandler')]
    procedure SummaryRefreshActionUpdatesWithoutReselection()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Refresh Production Order updates the open summary without reselecting the order.
        Initialize();

        // [GIVEN] The open card has one operation, while its certified master routing now has two subcontract operations.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(1);
        AddSummaryRoutingOperations(ProductionOrder, false);
        Commit();

        // [WHEN] The real parent action recalculates the order from its changed master routing.
        ReleasedOrder.RefreshProductionOrder.Invoke();

        // [THEN] The same card immediately shows both subcontract operations without GoToRecord or reopening.
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(2);
        ReleasedOrder.Close();
    end;

    [RequestPageHandler]
    procedure SummaryRefreshProductionOrderHandler(var RefreshOrder: TestRequestPage "Refresh Production Order")
    begin
        RefreshOrder.CalcLines.SetValue(true);
        RefreshOrder.CalcRoutings.SetValue(true);
        RefreshOrder.CalcComponents.SetValue(true);
        RefreshOrder.CreateInbRqst.SetValue(false);
        RefreshOrder.OK().Invoke();
    end;

    [Test]
    procedure SummaryOrdinaryRefreshAndMembership()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasedOrder: TestPage "Released Production Order";
        VendorNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Persisted work-center membership is recalculated by the parent even while the part is hidden.
        Initialize();

        // [GIVEN] Eligible "A" has one current subcontract operation.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        VendorNo := WorkCenter."Subcontractor No.";
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(1);

        // [WHEN] The work center's subcontractor is cleared and the current record is reread.
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify(true);
        ReleasedOrder.GoToRecord(ProductionOrder);

        // [THEN] The parent hides the part, then restores it after the persisted vendor is restored.
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.Visible(), 'Cleared membership must hide the summary.');
        WorkCenter.Validate("Subcontractor No.", VendorNo);
        WorkCenter.Modify(true);
        ReleasedOrder.GoToRecord(ProductionOrder);
        Assert.IsTrue(ReleasedOrder.SubcontractingSummary.Visible(), 'Hidden part must become eligible again.');
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(1);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.PurchaseQuantity.AssertEquals(10);
        ReleasedOrder.SubcontractingSummary.ReceiptQuantity.AssertEquals(10);
        ReleasedOrder.SubcontractingSummary.InvoiceQuantity.AssertEquals(0);
        ReleasedOrder.SubcontractingSummary.FullyInvoiced.AssertEquals(Format(false));
        ReleasedOrder.Close();
    end;

    [Test]
    procedure SummaryVisibilityAndPersonalizationContract()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Eligible cards expose all nine read-only summary values by default; client personalization needs a client trace.
        Initialize();

        // [GIVEN] An eligible order without purchasing history.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);

        // [WHEN] Its actual card is opened for editing.
        ReleasedOrder.OpenEdit();
        ReleasedOrder.GoToRecord(ProductionOrder);

        // [THEN] The summary is visible, but none of its nine fields is editable.
        Assert.IsTrue(ReleasedOrder.SubcontractingSummary.Visible(), 'Eligible summary must be visible by default.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.RoutingCount.Editable(), 'Routing count is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.PurchaseQuantity.Editable(), 'Purchase quantity is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.ReceiptQuantity.Editable(), 'Receipt quantity is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.InvoiceQuantity.Editable(), 'Invoice quantity is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.FullyInvoiced.Editable(), 'Indicator is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.Editable(), 'WIP balance is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.WIPInTransit.Editable(), 'Transit balance is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.TransferCount.Editable(), 'Forward count is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.ReturnTransferCount.Editable(), 'Return count is read-only.');
        ReleasedOrder.SubcontractingSummary.FullyInvoiced.AssertEquals(Format(true));
        ReleasedOrder.Close();
    end;

    [Test]
    [HandlerFunctions('SummaryReadTransferCreatedHandler,SummaryReadPurchaseHandler,SummaryReadReceiptHandler,SummaryReadInvoiceHandler,SummaryReadWIPHandler,SummaryReadTransferHandler,SummaryRoutingHandler')]
    procedure SummaryReadPermissionsContract()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OtherPurchaseHeader: Record "Purchase Header";
        OtherPurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        InvoiceLine: Record "Purch. Inv. Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        RoutingLine: Record "Prod. Order Routing Line";
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        DirectPost: Codeunit "TransferOrder-Post Transfer";
        ReleasedOrder: TestPage "Released Production Order";
        OrderSystemModifiedAt: DateTime;
        WIPEntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Record actual card read permission use without treating this Disabled suite as an effective-user permission test.
        Initialize();

        // [GIVEN] A real production order is prepared before the read-only permission recording phase.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        SubcWarehouseLibrary.CreateSummaryForward(ProductionOrder, WorkCenter, PurchaseHeader, TransferHeader);
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Direct Transfer");
        TransferHeader.Modify(true);
        DirectPost.SetHideValidationDialog(true);
        DirectPost.Run(TransferHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        OrderSystemModifiedAt := ProductionOrder.SystemModifiedAt;
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        WIPEntryCount := WIPEntry.Count();

        // [GIVEN] A different order has a real posted invoice, while the current order has none.
        SubcWarehouseLibrary.CreateSummaryOrder(3, OtherOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(OtherOrder, WorkCenter, OtherPurchaseHeader, OtherPurchaseLine);
        LibraryPurchase.PostPurchaseDocument(OtherPurchaseHeader, true, false);
        SubcWarehouseLibrary.PostSummaryInvoice(OtherPurchaseHeader, OtherPurchaseLine, 3);
#pragma warning disable AA0210 // Bounded foreign-order invoice fixture.
        InvoiceLine.SetRange("Prod. Order No.", OtherOrder."No.");
#pragma warning restore AA0210
        Assert.RecordIsNotEmpty(InvoiceLine);

        // [WHEN] The real consumer reads with Base Application read permissions and the owning extension role.
        LibraryLowerPermissions.StartLoggingNAVPermissions('Subcontract. - Read');
        LibraryLowerPermissions.AddeRead();
        SubcWarehouseLibrary.VerifySummaryCard(ProductionOrder, 1, 10, 10, 0, false, 10, 0, 0, 0);
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.PurchaseQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(1);
        SubcWarehouseLibrary.VerifySummaryDetailRecord(PurchaseLine.RecordId());
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.ReceiptQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
#pragma warning disable AA0210 // Bounded receipt fixture.
        ReceiptLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        ReceiptLine.FindFirst();
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(1);
        SubcWarehouseLibrary.VerifySummaryDetailRecord(ReceiptLine.RecordId());
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.InvoiceQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(0);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        WIPEntry.FindFirst();
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(1);
        SubcWarehouseLibrary.VerifySummaryDetailRecord(WIPEntry.RecordId());
        ReleasedOrder.SubcontractingSummary.WIPInTransit.DrillDown();
        ReleasedOrder.SubcontractingSummary.TransferCount.DrillDown();
        ReleasedOrder.SubcontractingSummary.ReturnTransferCount.DrillDown();
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.RoutingCount.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        RoutingLine.SetRange(Status, ProductionOrder.Status);
        RoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        RoutingLine.FindFirst();
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(1);
        SubcWarehouseLibrary.VerifySummaryDetailRecord(RoutingLine.RecordId());
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'Read-role routing detail must contain one operation.');
        Assert.AreEqual(ProductionOrder."No.", LibraryVariableStorage.DequeueText(), 'Read-role routing detail must retain current order.');
        Assert.AreEqual('10', LibraryVariableStorage.DequeueText(), 'Read-role routing detail must retain operation.');
        ReleasedOrder.Close();

        // [THEN] Reading has not modified the header. Actual non-SUPER access remains a separate client obligation.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(OrderSystemModifiedAt, ProductionOrder.SystemModifiedAt, 'Summary reads must not write the production order.');
        Assert.AreEqual(WIPEntryCount, WIPEntry.Count(), 'Summary details must not write WIP history.');
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        Assert.RecordIsEmpty(TransferLine);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure AddSummaryRoutingOperations(var ProductionOrder: Record "Production Order"; RefreshOrder: Boolean)
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        SecondWorkCenter: Record "Work Center";
        InternalWorkCenter: Record "Work Center";
    begin
        Item.Get(ProductionOrder."Source No.");
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);
        LibraryMfgManagement.CreateSubcontractingWorkCenterWithCalendar(SecondWorkCenter);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", SecondWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingWorkCenterWithCalendar(InternalWorkCenter);
        InternalWorkCenter.Validate("Subcontractor No.", '');
        InternalWorkCenter.Modify(true);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '30', RoutingLine.Type::"Work Center", InternalWorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        if RefreshOrder then
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure VerifySummaryRoutingDetails(ProductionOrder: Record "Production Order")
    var
        RoutingLine: Record "Prod. Order Routing Line";
    begin
        RoutingLine.SetRange(Status, ProductionOrder.Status);
        RoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210 // Subcontracting is a FlowField; routing is already scoped to one order.
        RoutingLine.SetRange(Subcontracting, true);
#pragma warning restore AA0210
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(RoutingLine.Count());
        Assert.AreEqual(2, LibraryVariableStorage.DequeueInteger(), 'Exactly two qualifying operations must be shown.');
        RoutingLine.FindSet();
        repeat
            SubcWarehouseLibrary.VerifySummaryDetailRecord(RoutingLine.RecordId());
            Assert.AreEqual(ProductionOrder."No.", LibraryVariableStorage.DequeueText(), 'Detail must be scoped to current order.');
            Assert.AreEqual(RoutingLine."Operation No.", LibraryVariableStorage.DequeueText(), 'Detail operation must match the filtered routing.');
        until RoutingLine.Next() = 0;
    end;

    [PageHandler]
    procedure SummaryRoutingHandler(var Routing: TestPage "Prod. Order Routing")
    var
        OrderNumbers: List of [Text];
        OperationNumbers: List of [Text];
        RowIndex: Integer;
    begin
        if Routing.First() then
            repeat
                OrderNumbers.Add(Routing."Prod. Order No.".Value());
                OperationNumbers.Add(Routing."Operation No.".Value());
            until not Routing.Next();
        LibraryVariableStorage.Enqueue(OrderNumbers.Count());
        for RowIndex := 1 to OrderNumbers.Count() do begin
            LibraryVariableStorage.Enqueue(OrderNumbers.Get(RowIndex));
            LibraryVariableStorage.Enqueue(OperationNumbers.Get(RowIndex));
        end;
        Routing.Close();
    end;

    [PageHandler]
    procedure SummaryReadTransferCreatedHandler(var TransferOrder: TestPage "Transfer Order")
    begin
        TransferOrder.Close();
    end;

    [PageHandler]
    procedure SummaryReadPurchaseHandler(var Lines: TestPage "Purchase Lines")
    var
        HasRecord: Boolean;
    begin
        HasRecord := Lines.First();
        while HasRecord do
            HasRecord := Lines.Next();
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryReadReceiptHandler(var Lines: TestPage "Purch. Receipt Lines")
    var
        HasRecord: Boolean;
    begin
        HasRecord := Lines.First();
        while HasRecord do
            HasRecord := Lines.Next();
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryReadInvoiceHandler(var Lines: TestPage "Subc. Summary Invoice Lines")
    var
        HasRecord: Boolean;
    begin
        HasRecord := Lines.First();
        while HasRecord do
            HasRecord := Lines.Next();
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryReadWIPHandler(var Entries: TestPage "Subc. WIP Ledger Entries")
    var
        HasRecord: Boolean;
    begin
        HasRecord := Entries.First();
        while HasRecord do
            HasRecord := Entries.Next();
        Entries.Close();
    end;

    [PageHandler]
    procedure SummaryReadTransferHandler(var Lines: TestPage "Transfer Lines")
    begin
        Lines.Close();
    end;

    local procedure Initialize()
    begin
        Clear(SubcWarehouseLibrary);
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Subcontracting UI Test");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Subcontracting UI Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Subcontracting UI Test");
    end;

    [Test]
    procedure SubcontractingAssistedSetupIsRegistered()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        // [SCENARIO 642233] The Subcontracting assisted setup is registered with Guided Experience.
        Initialize();

        // [GIVEN] The Subcontracting assisted setup registration does not exist
        AssistedSetupTestLibrary.Delete(Page::"Subcontracting Setup Wizard");

        // [WHEN] Assisted setups are registered
        AssistedSetupTestLibrary.CallOnRegister();

        // [THEN] The Subcontracting setup wizard is registered
        Assert.IsTrue(AssistedSetupTestLibrary.Exists(Page::"Subcontracting Setup Wizard"), 'The Subcontracting assisted setup should be registered.');
    end;

    [Test]
    [HandlerFunctions('SetupNotCompletedConfirmHandler')]
    procedure SubcontractingSetupWizardShowsCompanyDefaultsAndConfigurationLinks()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcCompTransferLeadTime: DateFormula;
        SubcontractingSetupWizard: TestPage "Subcontracting Setup Wizard";
        SubcontractingBatchName: Code[10];
        SubcontractingTemplateName: Code[10];
        ComponentDirectUnitCost: Option Standard,"Prod. Order Component";
        CreateProdOrderInfoLine: Boolean;
        SubcDefaultCompLocation: Enum "Components at Location";
    begin
        // [SCENARIO 642233] The setup wizard displays the installed company defaults and the next configuration links.
        Initialize();

        // [GIVEN] The company has Subcontracting defaults
        ManufacturingSetup.Get();
        SubcontractingTemplateName := ManufacturingSetup."Subcontracting Template Name";
        SubcontractingBatchName := ManufacturingSetup."Subcontracting Batch Name";
        CreateProdOrderInfoLine := ManufacturingSetup."Create Prod. Order Info Line";
        ComponentDirectUnitCost := ManufacturingSetup."Component Direct Unit Cost";
        SubcCompTransferLeadTime := ManufacturingSetup."Subc. Comp. Transfer Lead Time";
        SubcDefaultCompLocation := ManufacturingSetup."Subc. Default Comp. Location";

        // [WHEN] The setup wizard is opened
        SubcontractingSetupWizard.OpenEdit();

        // [THEN] The welcome step is shown
        Assert.IsFalse(SubcontractingSetupWizard.ActionBack.Enabled(), 'Back should be disabled on the welcome step.');
        Assert.IsTrue(SubcontractingSetupWizard.ActionNext.Enabled(), 'Next should be enabled on the welcome step.');
        Assert.IsFalse(SubcontractingSetupWizard.ActionFinish.Enabled(), 'Finish should be disabled on the welcome step.');

        // [WHEN] The user continues to company defaults
        SubcontractingSetupWizard.ActionNext.Invoke();

        // [THEN] The defaults created during installation are displayed
        SubcontractingSetupWizard."Subcontracting Template Name".AssertEquals(SubcontractingTemplateName);
        SubcontractingSetupWizard."Subcontracting Batch Name".AssertEquals(SubcontractingBatchName);
        SubcontractingSetupWizard."Create Prod. Order Info Line".AssertEquals(CreateProdOrderInfoLine);
        SubcontractingSetupWizard."Component Direct Unit Cost".AssertEquals(ComponentDirectUnitCost);
        SubcontractingSetupWizard."Subc. Comp. Transfer Lead Time".AssertEquals(SubcCompTransferLeadTime);
        SubcontractingSetupWizard."Subc. Default Comp. Location".AssertEquals(SubcDefaultCompLocation);
        Assert.IsTrue(SubcontractingSetupWizard.ActionBack.Enabled(), 'Back should be enabled on the company defaults step.');
        Assert.IsTrue(SubcontractingSetupWizard.ActionNext.Enabled(), 'Next should be enabled on the company defaults step.');

        // [WHEN] The user continues to the final step
        SubcontractingSetupWizard.ActionNext.Invoke();

        // [THEN] Links to the remaining Subcontracting configuration are displayed
        Assert.IsTrue(SubcontractingSetupWizard.WorkCentersLink.Visible(), 'The work centers link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.VendorsLink.Visible(), 'The vendors link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.LocationsLink.Visible(), 'The locations link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.SubcontractorPricesLink.Visible(), 'The subcontractor prices link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.ComponentSupplyMethodsLink.Visible(), 'The component supply methods link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.DocumentationLink.Visible(), 'The documentation link should be visible.');
        Assert.IsFalse(SubcontractingSetupWizard.ActionNext.Enabled(), 'Next should be disabled on the final step.');
        Assert.IsTrue(SubcontractingSetupWizard.ActionFinish.Enabled(), 'Finish should be enabled on the final step.');

        // [WHEN] The user closes the guide without finishing the setup
        LibraryVariableStorage.Enqueue(SetupNotCompletedQst);
        LibraryVariableStorage.Enqueue(true);
        SubcontractingSetupWizard.Close();

        // [THEN] The expected confirmation was handled
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Opening and navigating the guide did not replace the installed defaults
        ManufacturingSetup.Get();
        Assert.AreEqual(SubcontractingTemplateName, ManufacturingSetup."Subcontracting Template Name", 'The Subcontracting template default should be preserved.');
        Assert.AreEqual(SubcontractingBatchName, ManufacturingSetup."Subcontracting Batch Name", 'The Subcontracting batch default should be preserved.');
        Assert.AreEqual(CreateProdOrderInfoLine, ManufacturingSetup."Create Prod. Order Info Line", 'The production order information line default should be preserved.');
        Assert.AreEqual(ComponentDirectUnitCost, ManufacturingSetup."Component Direct Unit Cost", 'The component direct unit cost default should be preserved.');
        Assert.AreEqual(SubcCompTransferLeadTime, ManufacturingSetup."Subc. Comp. Transfer Lead Time", 'The component transfer lead time default should be preserved.');
        Assert.AreEqual(SubcDefaultCompLocation, ManufacturingSetup."Subc. Default Comp. Location", 'The default component location source should be preserved.');
    end;

    [Test]
    procedure FinishingSubcontractingSetupWizardSavesDefaultsAndCompletesAssistedSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        GuidedExperience: Codeunit "Guided Experience";
        CreateProdOrderInfoLine: Boolean;
        OriginalCreateProdOrderInfoLine: Boolean;
        SubcontractingSetupWizard: TestPage "Subcontracting Setup Wizard";
    begin
        // [SCENARIO 642233] Finishing the setup guide saves changes and marks the assisted setup as completed.
        Initialize();

        // [GIVEN] The Subcontracting assisted setup is registered and incomplete
        AssistedSetupTestLibrary.Delete(Page::"Subcontracting Setup Wizard");
        AssistedSetupTestLibrary.CallOnRegister();
        AssistedSetupTestLibrary.SetStatusToNotCompleted(Page::"Subcontracting Setup Wizard");
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Subcontracting Setup Wizard"), 'The assisted setup should initially be incomplete.');

        // [GIVEN] A changed company default in the setup wizard
        ManufacturingSetup.Get();
        OriginalCreateProdOrderInfoLine := ManufacturingSetup."Create Prod. Order Info Line";
        CreateProdOrderInfoLine := not OriginalCreateProdOrderInfoLine;
        SubcontractingSetupWizard.OpenEdit();
        SubcontractingSetupWizard.ActionNext.Invoke();
        SubcontractingSetupWizard."Create Prod. Order Info Line".SetValue(CreateProdOrderInfoLine);
        SubcontractingSetupWizard.ActionNext.Invoke();

        // [WHEN] The user finishes the setup wizard
        SubcontractingSetupWizard.ActionFinish.Invoke();

        // [THEN] The company default is saved and the assisted setup is completed
        ManufacturingSetup.Get();
        Assert.AreEqual(CreateProdOrderInfoLine, ManufacturingSetup."Create Prod. Order Info Line", 'The changed company default should be saved.');
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Subcontracting Setup Wizard"), 'The assisted setup should be completed.');

        ManufacturingSetup."Create Prod. Order Info Line" := OriginalCreateProdOrderInfoLine;
        ManufacturingSetup.Modify();
    end;

    [Test]
    procedure ManufacturingSetupContainsDefaultComponentLocationSource()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        PageControl: Record "Page Control Field";
    begin
        // [SCENARIO 642233] Manufacturing Setup remains available for maintaining all Subcontracting company defaults.
        Initialize();

        // [WHEN] Controls on Manufacturing Setup are inspected
        PageControl.SetRange(TableNo, Database::"Manufacturing Setup");
        PageControl.SetRange(PageNo, Page::"Manufacturing Setup");
        PageControl.SetRange(FieldNo, ManufacturingSetup.FieldNo("Subc. Default Comp. Location"));

        // [THEN] Default Component Location Source is available for later maintenance
        Assert.IsFalse(PageControl.IsEmpty(), StrSubstNo(ControlNotExistMsg, ManufacturingSetup.FieldCaption("Subc. Default Comp. Location")));
    end;

    [Test]
    procedure ProdOrderCompLinesExposeTransferQuantities()
    var
        PageControl: Record "Page Control Field";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [SCENARIO 650391] Prod. Order Comp. Lines exposes subcontracting transfer quantities.
        Initialize();

        // [WHEN] Controls on Prod. Order Comp. Lines are inspected
        // [THEN] Transfer quantities are available with the requested default visibility
        AssertPageControlExists(
            Database::"Prod. Order Component", Page::"Prod. Order Comp. Line List",
            ProdOrderComponent.FieldNo("Subc. Qty.on TransOrder (Base)"), 'Subc. Qty.on TransOrder (Base)');
        AssertPageControlIsInitiallyHidden(
            PageControl, Database::"Prod. Order Component", Page::"Prod. Order Comp. Line List",
            ProdOrderComponent.FieldNo("Subc. Qty. in Transit (Base)"), 'Qty. in Transit (Base)');
        AssertPageControlExists(
            Database::"Prod. Order Component", Page::"Prod. Order Comp. Line List",
            ProdOrderComponent.FieldNo("Subc. Qty. transf. to Subcontr"), 'Subc. Qty. transf. to Subcontractor');
    end;

    [Test]
    procedure CommentPagesExposeOperationKeysAndFields()
    var
        PageAction: Record "Page Action";
        PageControl: Record "Page Control Field";
        SubcProdOrderRoutingComment: Record "Subc. Prod. Rtng. Comment";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
    begin
        // [SCENARIO TP-001] Dedicated subcontracting comment pages expose their source operation keys and editable fields.
        Initialize();

        // [WHEN] Source pages expose navigation to dedicated subcontracting comments
        AssertPageActionRunsPage(PageAction, Page::"Standard Tasks", 'Subc. Subcontracting Comments', Page::"Subc. Standard Task Comments");
        AssertPageActionRunsPage(PageAction, Page::"Routing Lines", 'Subc. Subcontracting Comments', Page::"Subc. Routing Comments");
        AssertPageActionRunsPage(PageAction, Page::"Routing Version Lines", 'Subc. Subcontracting Comments', Page::"Subc. Routing Comments");
        AssertPageActionRunsPage(PageAction, Page::"Prod. Order Routing", 'Subc. Subcontracting Comments', Page::"Subc. Prod. Rtng. Comments");

        // [WHEN] Controls on each dedicated comment page are inspected
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Standard Task Code"), 'Standard Task Code');
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Line No."), 'Line No.');
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo(Description), 'Description');
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Description 2"), 'Description 2');

        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Routing No."), 'Routing No.');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Version Code"), 'Version Code');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Operation No."), 'Operation No.');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Line No."), 'Line No.');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo(Description), 'Description');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Description 2"), 'Description 2');

        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo(Status), 'Status');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Prod. Order No."), 'Prod. Order No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Routing Reference No."), 'Routing Reference No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Routing No."), 'Routing No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Operation No."), 'Operation No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Line No."), 'Line No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo(Description), 'Description');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Description 2"), 'Description 2');

        // [THEN] Ordinary routing comments are not a source for the dedicated page surface
        PageControl.SetRange(TableNo, Database::"Routing Comment Line");
        PageControl.SetRange(PageNo, Page::"Subc. Routing Comments");
        Assert.IsTrue(PageControl.IsEmpty(), 'The dedicated subcontracting routing comment page must not use ordinary routing comments.');
    end;

    [Test]
    procedure SubcontractingCommentDescription2IsHiddenInitially()
    var
        SubcProdOrderRoutingComment: Record "Subc. Prod. Rtng. Comment";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
        PageControl: Record "Page Control Field";
    begin
        // [SCENARIO TP-031] Description 2 is initially hidden on each dedicated subcontracting comment page.
        Initialize();

        // [WHEN] The Description 2 control metadata is inspected on each dedicated comment page
        AssertPageControlIsInitiallyHidden(
            PageControl, Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Description 2"), SubcStandardTaskComment.FieldCaption("Description 2"));
        AssertPageControlIsInitiallyHidden(
            PageControl, Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Description 2"), SubcRoutingCommentLine.FieldCaption("Description 2"));
        AssertPageControlIsInitiallyHidden(
            PageControl, Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Description 2"), SubcProdOrderRoutingComment.FieldCaption("Description 2"));
    end;

    [Test]
    procedure SubcontractingCommentsEnabledOnlyForSubcontractingLines()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        NonSubcontractingProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NonSubcontractingRoutingLine: Record "Routing Line";
        NonSubcontractingRoutingVersionLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        SubcontractingProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcontractingRoutingLine: Record "Routing Line";
        SubcontractingRoutingVersionLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        RoutingPage: TestPage Routing;
        RoutingVersionPage: TestPage "Routing Version";
        ProdOrderRouting: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO TP-029] Dedicated subcontracting comments are enabled only for subcontracting operations.
        Initialize();

        // [GIVEN] A regular work center and a subcontracting work center
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, false);
        WorkCenter[2].Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter[2].Modify(true);

        // [GIVEN] A routing and routing version containing both work center types
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, NonSubcontractingRoutingLine, '', '10', NonSubcontractingRoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, SubcontractingRoutingLine, '', '20', SubcontractingRoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", 'V1');
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, NonSubcontractingRoutingVersionLine, RoutingVersion."Version Code", '10', NonSubcontractingRoutingVersionLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, SubcontractingRoutingVersionLine, RoutingVersion."Version Code", '20', SubcontractingRoutingVersionLine.Type::"Work Center", WorkCenter[2]."No.");
        RoutingVersion.Validate(Status, RoutingVersion.Status::Certified);
        RoutingVersion.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // [WHEN] Routing Lines is inspected for each operation type
        RoutingPage.OpenEdit();
        RoutingPage.GotoRecord(RoutingHeader);
        RoutingPage.RoutingLine.GotoRecord(NonSubcontractingRoutingLine);

        // [THEN] Subcontracting comments are disabled for a regular routing line
        Assert.IsFalse(RoutingPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be disabled for a regular routing line.');

        RoutingPage.RoutingLine.GotoRecord(SubcontractingRoutingLine);

        // [THEN] Subcontracting comments are enabled for a subcontracting routing line
        Assert.IsTrue(RoutingPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be enabled for a subcontracting routing line.');
        RoutingPage.Close();

        // [WHEN] Routing Version Lines is inspected for each operation type
        RoutingVersionPage.OpenEdit();
        RoutingVersionPage.GotoRecord(RoutingVersion);
        RoutingVersionPage.RoutingLine.GotoRecord(NonSubcontractingRoutingVersionLine);

        // [THEN] Subcontracting comments are disabled for a regular routing version line
        Assert.IsFalse(RoutingVersionPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be disabled for a regular routing version line.');

        RoutingVersionPage.RoutingLine.GotoRecord(SubcontractingRoutingVersionLine);

        // [THEN] Subcontracting comments are enabled for a subcontracting routing version line
        Assert.IsTrue(RoutingVersionPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be enabled for a subcontracting routing version line.');
        RoutingVersionPage.Close();

        // [GIVEN] A released production order with regular and subcontracting operations
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 1);
        NonSubcontractingProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        NonSubcontractingProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        NonSubcontractingProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[1]."No.");
        NonSubcontractingProdOrderRoutingLine.FindFirst();
        SubcontractingProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        SubcontractingProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        SubcontractingProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        SubcontractingProdOrderRoutingLine.FindFirst();

        // [WHEN] Prod. Order Routing is inspected for each operation type
        ProdOrderRouting.OpenView();
        ProdOrderRouting.GotoRecord(NonSubcontractingProdOrderRoutingLine);

        // [THEN] Subcontracting comments are disabled for a regular production operation
        Assert.IsFalse(ProdOrderRouting."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be disabled for a regular production operation.');

        ProdOrderRouting.GotoRecord(SubcontractingProdOrderRoutingLine);

        // [THEN] Subcontracting comments are enabled for a subcontracting production operation
        Assert.IsTrue(ProdOrderRouting."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be enabled for a subcontracting production operation.');
        ProdOrderRouting.Close();
    end;


    [Test]
    procedure V1DoesNotExposeUnsupportedCommentOrAttachmentSetup()
    var
        PageControl: Record "Page Control Field";
        TableField: Record Field;
    begin
        // [SCENARIO TP-025] V1 comment and attachment surfaces do not expose unsupported metadata.
        Initialize();

        // [WHEN] Dedicated comment tables are inspected for unsupported translation and date metadata
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Vendor No.');
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Language Code');
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Starting Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Ending Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Vendor No.');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Language Code');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Starting Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Ending Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Vendor No.');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Language Code');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Starting Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Ending Date');

        // [THEN] Routing Lines do not expose operation-specific attachment selection
        AssertTableFieldMissing(TableField, Database::"Routing Line", 'Document Flow Production');
        AssertTableFieldMissing(TableField, Database::"Routing Line", 'Document Flow Purchase');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Lines", 'Document Flow Production');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Lines", 'Document Flow Purchase');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Version Lines", 'Document Flow Production');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Version Lines", 'Document Flow Purchase');
    end;

    [Test]
    procedure CheckCustCtrl_PagePurchaseOrderSubContractingLocationCode()
    var
        PageControl: Record "Page Control Field";
        PurchHeader: Record "Purchase Header";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Purchase Header"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Purchase Header");
        PageControl.SetRange(PageNo, Page::"Purchase Order");
        PageControl.SetRange(FieldNo, PurchHeader.FieldNo("Subc. Location Code"));
        ControlExist := not PageControl.IsEmpty();
        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, PurchHeader.FieldCaption("Subc. Location Code")));
    end;

    [Test]
    procedure CheckCustCtrl_PagePurchaseOrderSubContractingOrder()
    var
        PageControl: Record "Page Control Field";
        PurchHeader: Record "Purchase Header";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Purchase Header"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Purchase Header");
        PageControl.SetRange(PageNo, Page::"Purchase Order");
        PageControl.SetRange(FieldNo, PurchHeader.FieldNo("Subc. Order"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, PurchHeader.FieldCaption("Subc. Order")));
    end;

    [Test]
    procedure CheckCustCtrl_PageVendorCardSubContractingLocationCode()
    var
        PageControl: Record "Page Control Field";
        Vendor: Record Vendor;
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Vendor Card"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::Vendor);
        PageControl.SetRange(PageNo, Page::"Vendor Card");
        PageControl.SetRange(FieldNo, Vendor.FieldNo("Subc. Location Code"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, Vendor.FieldCaption("Subc. Location Code")));
    end;

    [Test]
    procedure CheckCustCtrl_PageVendorCardLinkedToWorkCenter()
    var
        PageControl: Record "Page Control Field";
        Vendor: Record Vendor;
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Vendor Card"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::Vendor);
        PageControl.SetRange(PageNo, Page::"Vendor Card");
        PageControl.SetRange(FieldNo, Vendor.FieldNo("Subc. Linked to Work Center"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, Vendor.FieldCaption("Subc. Linked to Work Center")));
    end;

    [Test]
    procedure CheckCustCtrl_PageSubcontractingWorksheetStandardTaskCode()
    var
        PageControl: Record "Page Control Field";
        ReqLine: Record "Requisition Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Subcontracting Worksheet"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Requisition Line");
        PageControl.SetRange(PageNo, Page::"Subc. Subcontracting Worksheet");
        PageControl.SetRange(FieldNo, ReqLine.FieldNo("Subc. Standard Task Code"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ReqLine.FieldCaption("Subc. Standard Task Code")));
    end;

    [Test]
    procedure CheckCustCtrl_PageProductionBOMLinesComponentSupplyMethod()
    var
        PageControl: Record "Page Control Field";
        ProdBOMLine: Record "Production BOM Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Production BOM Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Production BOM Line");
        PageControl.SetRange(PageNo, Page::"Production BOM Lines");
        PageControl.SetRange(FieldNo, ProdBOMLine.FieldNo("Component Supply Method"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ProdBOMLine.FieldCaption("Component Supply Method")));
    end;

    [Test]
    procedure CheckCustCtrl_PageProductionBOMVersionLinesComponentSupplyMethod()
    var
        PageControl: Record "Page Control Field";
        ProdBOMLine: Record "Production BOM Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Production BOM Version Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Production BOM Line");
        PageControl.SetRange(PageNo, Page::"Production BOM Version Lines");
        PageControl.SetRange(FieldNo, ProdBOMLine.FieldNo("Component Supply Method"));
        ControlExist := not PageControl.IsEmpty();
        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ProdBOMLine.FieldCaption("Component Supply Method")));
    end;

    [Test]
    procedure CheckCustCtrl_PagePlanningComponentComponentSupplyMethod()
    var
        PageControl: Record "Page Control Field";
        PlanComp: Record "Planning Component";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Planning Components"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Planning Component");
        PageControl.SetRange(PageNo, Page::"Planning Components");
        PageControl.SetRange(FieldNo, PlanComp.FieldNo("Component Supply Method"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, PlanComp.FieldCaption("Component Supply Method")));
    end;

    [Test]
    procedure WorkCenterCardSubcontractingActionsHiddenWhenNotSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontracting action group is not visible on Work Center Card when Work Center has no Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center without a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is not enabled
        Assert.IsFalse(WorkCenterCard."Subcontractor Prices".Enabled(), SubcontractingActionsVisibleErr);
        WorkCenterCard.Close();
    end;

    [Test]
    procedure WorkCenterCardSubcontractingActionsVisibleWhenSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontracting action group is visible on Work Center Card when Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is enabled
        Assert.IsTrue(WorkCenterCard."Subcontractor Prices".Enabled(), SubcontractingActionsNotVisibleErr);
        WorkCenterCard.Close();
    end;

    [Test]
    procedure WorkCenterCardDispatchListDisabledWhenNotSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontractor - Dispatch List action is disabled on Work Center Card when Work Center has no Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center without a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor - Dispatch List action is not enabled
        Assert.IsFalse(WorkCenterCard."Subcontractor Dispatch List".Enabled(), SubcontractingActionsEnabledErr);
        WorkCenterCard.Close();
    end;

    [Test]
    procedure WorkCenterCardDispatchListEnabledWhenSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontractor - Dispatch List action is enabled on Work Center Card when Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor - Dispatch List action is enabled
        Assert.IsTrue(WorkCenterCard."Subcontractor Dispatch List".Enabled(), SubcontractingActionsNotEnabledErr);
        WorkCenterCard.Close();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardPersistsPendingChangesWhenSubcontractorIsValidated()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 651344] Pending Work Center changes are persisted when Subcontractor No. is validated.
        Initialize();

        // [GIVEN] Work Center "WC" with time-based unit costs and configured subcontractor "V"
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Time);
        WorkCenter.Modify(true);
        CreateVendorWithSubcontractingLocation(Vendor);

        // [WHEN] Unit Cost Calculation is changed to Units and "V" is selected on the Work Center Card
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Unit Cost Calculation".SetValue(WorkCenter."Unit Cost Calculation"::Units);
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");
        VerifySubcontractorLocationNotification('');

        // [THEN] Both changes remain on the page and are persisted
        WorkCenterCard."Unit Cost Calculation".AssertEquals(WorkCenter."Unit Cost Calculation"::Units);
        WorkCenterCard."Subcontractor No.".AssertEquals(Vendor."No.");
        WorkCenterCard.Close();
        WorkCenter.Get(WorkCenter."No.");
        Assert.AreEqual(WorkCenter."Unit Cost Calculation"::Units, WorkCenter."Unit Cost Calculation", 'Unit Cost Calculation should be persisted.');
        Assert.AreEqual(Vendor."No.", WorkCenter."Subcontractor No.", 'Subcontractor No. should be persisted.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardEnablesSubcontractingActionsAfterSettingSubcontractor()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637771] Subcontracting actions are enabled immediately after setting Subcontractor No.
        Initialize();

        // [GIVEN] Work Center "WC" without a subcontractor and configured subcontractor "V"
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        CreateVendorWithSubcontractingLocation(Vendor);
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);

        // [WHEN] "V" is selected as the subcontractor
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");
        VerifySubcontractorLocationNotification('');

        // [THEN] Subcontracting actions are enabled without reopening the card
        Assert.IsTrue(WorkCenterCard."Subcontractor Prices".Enabled(), SubcontractingActionsNotEnabledErr);
        Assert.IsTrue(WorkCenterCard."Subcontractor Dispatch List".Enabled(), SubcontractingActionsNotEnabledErr);
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardDisablesSubcontractingActionsAfterClearingSubcontractor()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637771] Subcontracting actions are disabled immediately after clearing Subcontractor No.
        Initialize();

        // [GIVEN] Work Center "WC" with configured subcontractor "V" and time-based unit costs
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        CreateVendorWithSubcontractingLocation(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Time);
        WorkCenter.Modify(true);
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);

        // [WHEN] Unit Cost Calculation is changed to Units and the subcontractor is cleared
        WorkCenterCard."Unit Cost Calculation".SetValue(WorkCenter."Unit Cost Calculation"::Units);
        WorkCenterCard."Subcontractor No.".SetValue('');
        VerifySubcontractorLocationNotification('');

        // [THEN] Subcontracting actions are disabled and the pending unit-cost change is persisted
        Assert.IsFalse(WorkCenterCard."Subcontractor Prices".Enabled(), SubcontractingActionsEnabledErr);
        Assert.IsFalse(WorkCenterCard."Subcontractor Dispatch List".Enabled(), SubcontractingActionsEnabledErr);
        WorkCenterCard."Unit Cost Calculation".AssertEquals(WorkCenter."Unit Cost Calculation"::Units);
        WorkCenterCard.Close();
        WorkCenter.Get(WorkCenter."No.");
        Assert.AreEqual(WorkCenter."Unit Cost Calculation"::Units, WorkCenter."Unit Cost Calculation", 'Unit Cost Calculation should be persisted.');
        Assert.AreEqual('', WorkCenter."Subcontractor No.", 'Subcontractor No. should be cleared.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationHandler,SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardNotifiesWhenSubcontractorHasNoLocation()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] A notification identifies a subcontractor vendor that has no subcontracting location.
        Initialize();

        // [GIVEN] A Work Center and a vendor without a Subcontracting Location Code
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));

        // [WHEN] The vendor is selected as the subcontractor on the Work Center Card
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");

        // [THEN] Any previous notification is recalled before one notification is sent for that vendor
        VerifySubcontractorLocationNotification(Vendor."No.");
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationHandler,SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardDoesNotStackSubcontractorLocationNotifications()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] Revalidating an unconfigured subcontractor replaces the existing notification.
        Initialize();

        // [GIVEN] A Work Center Card showing a notification for a vendor without a subcontracting location
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");
        VerifySubcontractorLocationNotification(Vendor."No.");

        // [WHEN] The same vendor is validated again
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");

        // [THEN] The previous notification is recalled before its replacement is sent with the same notification ID
        VerifySubcontractorLocationNotification(Vendor."No.");
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationHandler,SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardRecallsSubcontractorLocationNotificationWhenNoLongerNeeded()
    var
        Location: Record Location;
        ConfiguredVendor: Record Vendor;
        UnconfiguredVendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] A previous notification is removed when the subcontractor is configured or cleared.
        Initialize();

        // [GIVEN] An unconfigured vendor, a configured vendor, and a Work Center Card showing the notification
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        UnconfiguredVendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        ConfiguredVendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ConfiguredVendor.Validate("Subc. Location Code", Location.Code);
        ConfiguredVendor.Modify(true);
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(UnconfiguredVendor."No.");
        VerifySubcontractorLocationNotification(UnconfiguredVendor."No.");

        // [WHEN] The configured vendor is selected
        WorkCenterCard."Subcontractor No.".SetValue(ConfiguredVendor."No.");

        // [THEN] The previous notification is recalled and no notification is sent for the configured vendor
        VerifySubcontractorLocationNotification('');

        // [WHEN] The unconfigured vendor is selected again
        WorkCenterCard."Subcontractor No.".SetValue(UnconfiguredVendor."No.");

        // [THEN] The previous notification is recalled before a new notification is sent
        VerifySubcontractorLocationNotification(UnconfiguredVendor."No.");

        // [WHEN] The subcontractor is cleared
        WorkCenterCard."Subcontractor No.".SetValue('');

        // [THEN] The notification is recalled without sending another one
        VerifySubcontractorLocationNotification('');
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationActionHandler,SubcontractorLocationRecallHandler,VendorCardHandler')]
    procedure WorkCenterCardSubcontractorLocationNotificationActionOpensVendorCard()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] The notification action opens the selected subcontractor vendor.
        Initialize();

        // [GIVEN] A Work Center and a vendor without a Subcontracting Location Code
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));

        // [WHEN] The vendor is selected as the subcontractor and the notification action is invoked
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");

        // [THEN] The notification is sent for the vendor and the Vendor Card opens for that vendor
        VerifySubcontractorLocationNotification(Vendor."No.");
        Assert.AreEqual(Vendor."No.", LibraryVariableStorage.DequeueText(), VendorCardNoErr);
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure WorkCenterListSubcontractingActionsDisabledWhenNotSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterList: TestPage "Work Center List";
    begin
        // [SCENARIO 633206] Subcontractor Prices action is disabled on Work Center List when Work Center has no Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center without a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);

        // [WHEN] The Work Center List page is opened and navigated to the Work Center
        WorkCenterList.OpenEdit();
        WorkCenterList.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is not enabled
        Assert.IsFalse(WorkCenterList."Subcontractor Prices".Enabled(), SubcontractingActionsEnabledErr);
        WorkCenterList.Close();
    end;

    [Test]
    procedure WorkCenterListSubcontractingActionsEnabledWhenSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterList: TestPage "Work Center List";
    begin
        // [SCENARIO 633206] Subcontractor Prices action is enabled on Work Center List when Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [WHEN] The Work Center List page is opened and navigated to the Work Center
        WorkCenterList.OpenEdit();
        WorkCenterList.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is enabled
        Assert.IsTrue(WorkCenterList."Subcontractor Prices".Enabled(), SubcontractingActionsNotEnabledErr);
        WorkCenterList.Close();
    end;

    [Test]
    [HandlerFunctions('HandlePostedPurchaseReceiptPage')]
    procedure CapLedgerEntriesShowDocumentOpensPostedReceipt()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 620656] Show Document action opens Posted Purchase Receipt when Document No. matches a receipt
        Initialize();

        // [GIVEN] A Posted Purchase Receipt
        PurchRcptHeader.Init();
        PurchRcptHeader."No." := 'TEST-RCPT-001';
        if not PurchRcptHeader.Insert() then
            PurchRcptHeader.Modify();

        // [GIVEN] A Capacity Ledger Entry with Document No. pointing to the receipt
        CapacityLedgerEntry.Init();
        CapacityLedgerEntry."Entry No." := GetNextCapLedgerEntryNo();
        CapacityLedgerEntry."Document No." := PurchRcptHeader."No.";
        CapacityLedgerEntry.Insert();

        // [WHEN] The Show Document action is invoked
        CapacityLedgerEntries.OpenView();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        CapacityLedgerEntries.ShowDocument.Invoke();

        // [THEN] The Posted Purchase Receipt page is opened (verified by PageHandler)
        CapacityLedgerEntries.Close();
    end;

    [Test]
    [HandlerFunctions('HandlePostedPurchaseInvoicePage')]
    procedure CapLedgerEntriesShowDocumentOpensPostedInvoice()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 620656] Show Document action opens Posted Purchase Invoice when Document No. matches an invoice
        Initialize();

        // [GIVEN] A Posted Purchase Invoice (no matching receipt)
        PurchInvHeader.Init();
        PurchInvHeader."No." := 'TEST-INV-001';
        if not PurchInvHeader.Insert() then
            PurchInvHeader.Modify();

        // [GIVEN] A Capacity Ledger Entry with Document No. pointing to the invoice
        CapacityLedgerEntry.Init();
        CapacityLedgerEntry."Entry No." := GetNextCapLedgerEntryNo();
        CapacityLedgerEntry."Document No." := PurchInvHeader."No.";
        CapacityLedgerEntry.Insert();

        // [WHEN] The Show Document action is invoked
        CapacityLedgerEntries.OpenView();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        CapacityLedgerEntries.ShowDocument.Invoke();

        // [THEN] The Posted Purchase Invoice page is opened (verified by PageHandler)
        CapacityLedgerEntries.Close();

        // Cleanup
        CapacityLedgerEntry.Delete();
        PurchInvHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('HandlePurchaseOrderPage')]
    procedure CapLedgerEntriesShowDocumentOpensPurchaseOrder()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 620656] Show Document action opens Purchase Order when no posted document exists
        Initialize();

        // [GIVEN] A Purchase Order
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := 'TEST-PO-001';
        if not PurchaseHeader.Insert() then
            PurchaseHeader.Modify();

        // [GIVEN] A Capacity Ledger Entry with Subc. Purch. Order No. but no matching posted document
        CapacityLedgerEntry.Init();
        CapacityLedgerEntry."Entry No." := GetNextCapLedgerEntryNo();
        CapacityLedgerEntry."Document No." := '';
        CapacityLedgerEntry."Subc. Purch. Order No." := PurchaseHeader."No.";
        CapacityLedgerEntry.Insert();

        // [WHEN] The Show Document action is invoked
        CapacityLedgerEntries.OpenView();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        CapacityLedgerEntries.ShowDocument.Invoke();

        // [THEN] The Purchase Order page is opened (verified by PageHandler)
        CapacityLedgerEntries.Close();

        // Cleanup
        CapacityLedgerEntry.Delete();
        PurchaseHeader.Delete();
    end;

    [Test]
    procedure CheckCustCtrl_PageRoutingVersionLinesTransferWIPItem()
    var
        PageControl: Record "Page Control Field";
        RoutingLine: Record "Routing Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO 638530] Check if Transfer WIP Item control exists on Page "Routing Version Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Routing Line");
        PageControl.SetRange(PageNo, Page::"Routing Version Lines");
        PageControl.SetRange(FieldNo, RoutingLine.FieldNo("Transfer WIP Item"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, RoutingLine.FieldCaption("Transfer WIP Item")));
    end;

    [Test]
    procedure CheckCustCtrl_PageRoutingVersionLinesTransferDescription()
    var
        PageControl: Record "Page Control Field";
        RoutingLine: Record "Routing Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO 638530] Check if Transfer Description control exists on Page "Routing Version Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Routing Line");
        PageControl.SetRange(PageNo, Page::"Routing Version Lines");
        PageControl.SetRange(FieldNo, RoutingLine.FieldNo("Transfer Description"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, RoutingLine.FieldCaption("Transfer Description")));
    end;

    local procedure AssertPageControlExists(ControlTableNo: Integer; ControlPageNo: Integer; ControlFieldNo: Integer; ControlNameValue: Text)
    var
        PageControl: Record "Page Control Field";
    begin
        PageControl.SetRange(TableNo, ControlTableNo);
        PageControl.SetRange(PageNo, ControlPageNo);
        PageControl.SetRange(FieldNo, ControlFieldNo);
        PageControl.SetRange(ControlName, ControlNameValue);
        Assert.IsFalse(PageControl.IsEmpty(), StrSubstNo(ControlNotExistMsg, ControlNameValue));
    end;

    local procedure AssertPageControlIsInitiallyHidden(var PageControl: Record "Page Control Field"; ControlTableNo: Integer; ControlPageNo: Integer; ControlFieldNo: Integer; ControlFieldCaption: Text)
    begin
        PageControl.Reset();
        PageControl.SetRange(TableNo, ControlTableNo);
        PageControl.SetRange(PageNo, ControlPageNo);
        PageControl.SetRange(FieldNo, ControlFieldNo);
        Assert.IsFalse(PageControl.IsEmpty(), StrSubstNo(ControlNotExistMsg, ControlFieldCaption));
        PageControl.FindFirst();
        Assert.AreEqual('false', LowerCase(PageControl.Visible), StrSubstNo(ControlShouldBeHiddenErr, ControlFieldCaption, ControlPageNo));
    end;

    local procedure AssertPageActionRunsPage(var PageAction: Record "Page Action"; SourcePageNo: Integer; ActionName: Text; TargetPageNo: Integer)
    begin
        PageAction.Reset();
        PageAction.SetRange("Page ID", SourcePageNo);
        PageAction.SetRange(Name, ActionName);
        Assert.IsFalse(PageAction.IsEmpty(), StrSubstNo(ActionNotExistMsg, ActionName, SourcePageNo));
        PageAction.FindFirst();
        Assert.AreEqual(TargetPageNo, PageAction.RunObjectID, StrSubstNo(ActionTargetUnexpectedMsg, ActionName, TargetPageNo));
    end;

    local procedure AssertPageControlMissing(var PageControl: Record "Page Control Field"; ControlTableNo: Integer; ControlPageNo: Integer; ControlNameValue: Text)
    begin
        PageControl.Reset();
        PageControl.SetRange(TableNo, ControlTableNo);
        PageControl.SetRange(PageNo, ControlPageNo);
        PageControl.SetRange(ControlName, ControlNameValue);
        Assert.IsTrue(PageControl.IsEmpty(), StrSubstNo(UnsupportedControlExistsMsg, ControlNameValue, ControlPageNo));
    end;

    local procedure AssertTableFieldMissing(var TableField: Record Field; TableNumber: Integer; FieldNameValue: Text)
    begin
        TableField.Reset();
        TableField.SetRange(TableNo, TableNumber);
        TableField.SetRange(FieldName, FieldNameValue);
        Assert.IsTrue(TableField.IsEmpty(), StrSubstNo(UnsupportedFieldExistsMsg, FieldNameValue, TableNumber));
    end;

    local procedure GetNextCapLedgerEntryNo(): Integer
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        if CapacityLedgerEntry.FindLast() then
            exit(CapacityLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure VerifySubcontractorLocationNotification(VendorNo: Code[20])
    begin
        Assert.AreEqual(RecallNotificationTok, LibraryVariableStorage.DequeueText(), NotificationOrderErr);
        Assert.AreEqual(Format(GetMissingSubcontractingLocationNotificationId()), LibraryVariableStorage.DequeueText(), NotificationIdErr);
        if VendorNo <> '' then begin
            Assert.AreEqual(SendNotificationTok, LibraryVariableStorage.DequeueText(), NotificationOrderErr);
            Assert.AreEqual(Format(GetMissingSubcontractingLocationNotificationId()), LibraryVariableStorage.DequeueText(), NotificationIdErr);
            Assert.AreEqual(StrSubstNo(MissingSubcontractingLocationMsg, VendorNo), LibraryVariableStorage.DequeueText(), NotificationMessageErr);
            Assert.AreEqual(VendorNo, LibraryVariableStorage.DequeueText(), NotificationVendorErr);
        end;
    end;

    local procedure GetMissingSubcontractingLocationNotificationId(): Guid
    begin
        exit('{8A4B9A58-21EC-49DD-A3A5-C7E81F745B6D}');
    end;

    [SendNotificationHandler]
    procedure SubcontractorLocationNotificationHandler(var SubcontractorLocationNotification: Notification): Boolean
    begin
        if SubcontractorLocationNotification.Id <> GetMissingSubcontractingLocationNotificationId() then
            exit(false);

        CaptureSubcontractorLocationNotification(SubcontractorLocationNotification);
        exit(true);
    end;

    [SendNotificationHandler]
    procedure SubcontractorLocationNotificationActionHandler(var SubcontractorLocationNotification: Notification): Boolean
    var
        SubcNotificationMgmt: Codeunit "Subc. Notification Mgmt.";
    begin
        if SubcontractorLocationNotification.Id <> GetMissingSubcontractingLocationNotificationId() then
            exit(false);

        CaptureSubcontractorLocationNotification(SubcontractorLocationNotification);
        // Simulate choosing the Open Vendor Card notification action.
        SubcNotificationMgmt.OpenVendorCard(SubcontractorLocationNotification);
        exit(true);
    end;

    local procedure CaptureSubcontractorLocationNotification(SubcontractorLocationNotification: Notification)
    begin
        LibraryVariableStorage.Enqueue(SendNotificationTok);
        LibraryVariableStorage.Enqueue(Format(SubcontractorLocationNotification.Id));
        LibraryVariableStorage.Enqueue(SubcontractorLocationNotification.Message);
        LibraryVariableStorage.Enqueue(SubcontractorLocationNotification.GetData(VendorNoTok));
    end;

    [RecallNotificationHandler]
    procedure SubcontractorLocationRecallHandler(var SubcontractorLocationNotification: Notification): Boolean
    begin
        if SubcontractorLocationNotification.Id <> GetMissingSubcontractingLocationNotificationId() then
            exit(false);

        LibraryVariableStorage.Enqueue(RecallNotificationTok);
        LibraryVariableStorage.Enqueue(Format(SubcontractorLocationNotification.Id));
        exit(true);
    end;

    [PageHandler]
    procedure VendorCardHandler(var VendorCard: TestPage "Vendor Card")
    begin
        LibraryVariableStorage.Enqueue(VendorCard."No.".Value());
        VendorCard.Close();
    end;

    [PageHandler]
    procedure HandlePostedPurchaseReceiptPage(var PostedPurchaseReceipt: TestPage "Posted Purchase Receipt")
    begin
        PostedPurchaseReceipt.Close();
    end;

    [PageHandler]
    procedure HandlePostedPurchaseInvoicePage(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    begin
        PostedPurchaseInvoice.Close();
    end;

    [PageHandler]
    procedure HandlePurchaseOrderPage(var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.Close();
    end;

    [Test]
    procedure ItemLedgerEntriesSubcActionsDisabledWhenNotSubcontracting()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 638458] Subcontracting actions on Item Ledger Entries are disabled when the entry has no subcontracting production order or purchase order.
        Initialize();

        // [GIVEN] An Item Ledger Entry that is NOT related to subcontracting (no production order or Subc. Purch. Order No.)
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := 'TEST-ITEM';
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Purchase;
        ItemLedgerEntry."Order No." := '';
        ItemLedgerEntry."Subc. Purch. Order No." := '';
        ItemLedgerEntry.Insert();

        // [WHEN] The Item Ledger Entries page is opened for that entry
        ItemLedgerEntries.OpenView();
        ItemLedgerEntries.GoToRecord(ItemLedgerEntry);

        // [THEN] The Production Order action is disabled
        Assert.IsFalse(ItemLedgerEntries."Production Order".Enabled(), ILEProdActionsEnabledErr);
        // [THEN] The Production Order Routing action is disabled
        Assert.IsFalse(ItemLedgerEntries."Production Order Routing".Enabled(), ILEProdActionsEnabledErr);
        // [THEN] The Production Order Components action is disabled
        Assert.IsFalse(ItemLedgerEntries."Production Order Components".Enabled(), ILEProdActionsEnabledErr);
        // [THEN] The Purchase Order action is disabled
        Assert.IsFalse(ItemLedgerEntries."Purchase Order".Enabled(), ILEPurchActionsEnabledErr);

        ItemLedgerEntries.Close();

        // Cleanup
        ItemLedgerEntry.Delete();
    end;

    [Test]
    procedure ItemLedgerEntriesSubcActionsEnabledWhenSubcontracting()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 638458] Subcontracting actions on Item Ledger Entries are enabled when the entry is related to a subcontracting production order and purchase order.
        Initialize();

        // [GIVEN] An Item Ledger Entry that IS related to subcontracting
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := 'TEST-ITEM';
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Purchase;
        ItemLedgerEntry."Order Type" := ItemLedgerEntry."Order Type"::Production;
        ItemLedgerEntry."Order No." := 'PO-SUBC-001';
        ItemLedgerEntry."Order Line No." := 10000;
        ItemLedgerEntry."Subc. Purch. Order No." := 'PURCH-SUBC-001';
        ItemLedgerEntry."Subc. Purch. Order Line No." := 10000;
        ItemLedgerEntry.Insert();

        // [WHEN] The Item Ledger Entries page is opened for that entry
        ItemLedgerEntries.OpenView();
        ItemLedgerEntries.GoToRecord(ItemLedgerEntry);

        // [THEN] The Production Order action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Routing action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Routing".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Components action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Components".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Purchase Order action is enabled
        Assert.IsTrue(ItemLedgerEntries."Purchase Order".Enabled(), ILEPurchActionsNotEnabledErr);

        ItemLedgerEntries.Close();

        // Cleanup
        ItemLedgerEntry.Delete();
    end;

    [Test]
    procedure ItemLedgerEntriesSubcProdActionsEnabledForTransferViaSubcProdOrder()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 641405] Subcontracting production actions on Item Ledger Entries are enabled for a Transfer-type entry
        // [SCENARIO 641405] whose production order is referenced only through the Subc. Prod. Order fields (the base Order No. holds the transfer order).
        Initialize();

        // [GIVEN] A Transfer-type Item Ledger Entry whose base Order fields point at a transfer order,
        //         while the production order is only referenced through the Subc. Prod. Order fields
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := 'TEST-ITEM';
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Transfer;
        ItemLedgerEntry."Order Type" := ItemLedgerEntry."Order Type"::Transfer;
        ItemLedgerEntry."Order No." := 'TRANSFER-001';
        ItemLedgerEntry."Order Line No." := 10000;
        ItemLedgerEntry."Subc. Prod. Order No." := 'PO-SUBC-001';
        ItemLedgerEntry."Subc. Prod. Order Line No." := 10000;
        ItemLedgerEntry.Insert();

        // [WHEN] The Item Ledger Entries page is opened for that entry
        ItemLedgerEntries.OpenView();
        ItemLedgerEntries.GoToRecord(ItemLedgerEntry);

        // [THEN] The Production Order action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Routing action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Routing".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Components action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Components".Enabled(), ILEProdActionsNotEnabledErr);

        ItemLedgerEntries.Close();

        // Cleanup
        ItemLedgerEntry.Delete();
    end;

    [Test]
    procedure RoutingLinesTransferWIPItemDisabledForMachineCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLines: TestPage "Routing Lines";
        MachineCenterNo: Code[20];
    begin
        // [SCENARIO] Transfer WIP Item field is disabled on Routing Lines page for a Machine Center routing line,
        // even when the parent Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Machine Center belonging to that Work Center
        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenter."No.", 0);

        // [GIVEN] A Routing with a Machine Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryMfgManagement.CreateRoutingLineForMachineCenter(RoutingLine, RoutingHeader, MachineCenterNo);

        // [WHEN] The Routing Lines page is opened for that line
        RoutingLines.OpenEdit();
        RoutingLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is not enabled (Machine Center type is not eligible for Transfer WIP Item)
        Assert.IsFalse(RoutingLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPEnabledErr);
        RoutingLines.Close();
    end;

    [Test]
    procedure RoutingLinesTransferWIPItemEnabledForSubcontractingWorkCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLines: TestPage "Routing Lines";
    begin
        // [SCENARIO] Transfer WIP Item field is enabled on Routing Lines page for a Work Center routing line
        // when the Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Routing with a Work Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryMfgManagement.CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");

        // [WHEN] The Routing Lines page is opened for that line
        RoutingLines.OpenEdit();
        RoutingLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is enabled (subcontracting Work Center type)
        Assert.IsTrue(RoutingLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPNotEnabledErr);
        RoutingLines.Close();
    end;

    [Test]
    procedure RoutingVersionLinesTransferWIPItemDisabledForMachineCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersionLines: TestPage "Routing Version Lines";
        MachineCenterNo: Code[20];
        VersionCode: Code[20];
    begin
        // [SCENARIO] Transfer WIP Item field is disabled on Routing Version Lines page for a Machine Center
        // routing line, even when the parent Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Machine Center belonging to that Work Center
        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenter."No.", 0);

        // [GIVEN] A Routing Version with a Machine Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        VersionCode := '1';
        CreateRoutingVersionAndMachineCenterLine(RoutingHeader."No.", VersionCode, MachineCenterNo, RoutingLine);

        // [WHEN] The Routing Version Lines page is opened for that line
        RoutingVersionLines.OpenEdit();
        RoutingVersionLines.Filter.SetFilter("Routing No.", RoutingHeader."No.");
        RoutingVersionLines.Filter.SetFilter("Version Code", VersionCode);
        RoutingVersionLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is not enabled (Machine Center type is not eligible for Transfer WIP Item)
        Assert.IsFalse(RoutingVersionLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPEnabledErr);
        RoutingVersionLines.Close();
    end;

    [Test]
    procedure RoutingVersionLinesTransferWIPItemEnabledForSubcontractingWorkCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersionLines: TestPage "Routing Version Lines";
        VersionCode: Code[20];
    begin
        // [SCENARIO] Transfer WIP Item field is enabled on Routing Version Lines page for a Work Center routing line
        // when the Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Routing Version with a Work Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        VersionCode := '1';
        CreateRoutingVersionAndWorkCenterLine(RoutingHeader."No.", VersionCode, WorkCenter."No.", RoutingLine);

        // [WHEN] The Routing Version Lines page is opened for that line
        RoutingVersionLines.OpenEdit();
        RoutingVersionLines.Filter.SetFilter("Routing No.", RoutingHeader."No.");
        RoutingVersionLines.Filter.SetFilter("Version Code", VersionCode);
        RoutingVersionLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is enabled (subcontracting Work Center type)
        Assert.IsTrue(RoutingVersionLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPNotEnabledErr);
        RoutingVersionLines.Close();
    end;

    [Test]
    procedure RoutingLineTransferWIPItemValidationFailsForMachineCenterType()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        MachineCenterNo: Code[20];
    begin
        // [SCENARIO] Validating Transfer WIP Item = true on a Machine Center routing line fails
        // with an error because the Type must be Work Center.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Machine Center belonging to that Work Center
        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenter."No.", 0);

        // [GIVEN] A Routing with a Machine Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryMfgManagement.CreateRoutingLineForMachineCenter(RoutingLine, RoutingHeader, MachineCenterNo);

        // [WHEN] Transfer WIP Item is set to true on the Machine Center routing line
        // [THEN] An error is raised because the line type must be Work Center
        asserterror RoutingLine.Validate("Transfer WIP Item", true);
        Assert.ExpectedTestFieldError(RoutingLine.FieldCaption(Type), Format(RoutingLine.Type::"Work Center"));
    end;

    local procedure CreateRoutingVersionAndWorkCenterLine(RoutingNo: Code[20]; VersionCode: Code[20]; WorkCenterNo: Code[20]; var RoutingLine: Record "Routing Line")
    var
        RoutingVersion: Record "Routing Version";
        CapacityUoM: Record "Capacity Unit of Measure";
    begin
        RoutingVersion.Init();
        RoutingVersion.Validate("Routing No.", RoutingNo);
        RoutingVersion."Version Code" := VersionCode;
        RoutingVersion.Insert(true);

#pragma warning disable AA0210
        CapacityUoM.SetRange(Type, CapacityUoM.Type::Minutes);
#pragma warning restore AA0210
        CapacityUoM.FindFirst();

        RoutingLine.Init();
        RoutingLine.Validate("Routing No.", RoutingNo);
        RoutingLine.Validate("Version Code", VersionCode);
        RoutingLine.Validate("Operation No.", '10');
        RoutingLine.Validate(Type, RoutingLine.Type::"Work Center");
        RoutingLine.Validate("No.", WorkCenterNo);
        RoutingLine.Validate("Setup Time", 1);
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Insert(true);
    end;

    local procedure CreateRoutingVersionAndMachineCenterLine(RoutingNo: Code[20]; VersionCode: Code[20]; MachineCenterNo: Code[20]; var RoutingLine: Record "Routing Line")
    var
        RoutingVersion: Record "Routing Version";
        CapacityUoM: Record "Capacity Unit of Measure";
    begin
        RoutingVersion.Init();
        RoutingVersion.Validate("Routing No.", RoutingNo);
        RoutingVersion."Version Code" := VersionCode;
        RoutingVersion.Insert(true);

#pragma warning disable AA0210
        CapacityUoM.SetRange(Type, CapacityUoM.Type::Minutes);
#pragma warning restore AA0210
        CapacityUoM.FindFirst();

        RoutingLine.Init();
        RoutingLine.Validate("Routing No.", RoutingNo);
        RoutingLine.Validate("Version Code", VersionCode);
        RoutingLine.Validate("Operation No.", '10');
        RoutingLine.Validate(Type, RoutingLine.Type::"Machine Center");
        RoutingLine.Validate("No.", MachineCenterNo);
        RoutingLine.Validate("Setup Time", 1);
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Insert(true);
    end;

    local procedure CreateVendorWithSubcontractingLocation(var Vendor: Record Vendor)
    var
        Location: Record Location;
    begin
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Validate("Subc. Location Code", Location.Code);
        Vendor.Modify(true);
    end;

    local procedure GetNextItemLedgerEntryNo(): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ItemLedgerEntry.FindLast() then
            exit(ItemLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    [ConfirmHandler]
    procedure SetupNotCompletedConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;
        ActionNotExistMsg: Label 'Action %1 does not exist on page %2.', Comment = '%1 = action name, %2 = page number';
        ActionTargetUnexpectedMsg: Label 'Action %1 does not run page %2.', Comment = '%1 = action name, %2 = target page number';
        ControlNotExistMsg: Label 'Control %1 does not exist.', Comment = '%1 = field caption';
        ControlShouldBeHiddenErr: Label 'The %1 control on page %2 should be initially hidden.', Comment = '%1 = field caption, %2 = page number';
        UnsupportedControlExistsMsg: Label 'Unsupported control %1 exists on page %2.', Comment = '%1 = control name, %2 = page number';
        UnsupportedFieldExistsMsg: Label 'Unsupported field %1 exists on table %2.', Comment = '%1 = field name, %2 = table number';
        SubcontractingActionsVisibleErr: Label 'Subcontractor Prices action should not be visible for a non-subcontracting Work Center.';
        SubcontractingActionsEnabledErr: Label 'Subcontractor Prices action should not be enabled for a non-subcontracting Work Center.';
        SubcontractingActionsNotVisibleErr: Label 'Subcontractor Prices action should be visible for a subcontracting Work Center.';
        SubcontractingActionsNotEnabledErr: Label 'Subcontractor Prices action should be enabled for a subcontracting Work Center.';
        ILEProdActionsEnabledErr: Label 'Production actions should not be enabled for a non-subcontracting Item Ledger Entry.';
        ILEProdActionsNotEnabledErr: Label 'Production actions should be enabled for a subcontracting Item Ledger Entry.';
        ILEPurchActionsEnabledErr: Label 'Purchase Order action should not be enabled for a non-subcontracting Item Ledger Entry.';
        ILEPurchActionsNotEnabledErr: Label 'Purchase Order action should be enabled for a subcontracting Item Ledger Entry.';
        RoutingLineTransferWIPEnabledErr: Label 'Transfer WIP Item should not be enabled for a Machine Center routing line.';
        RoutingLineTransferWIPNotEnabledErr: Label 'Transfer WIP Item should be enabled for a subcontracting Work Center routing line.';
        SetupNotCompletedQst: Label 'The Subcontracting setup is not complete. Are you sure you want to exit?';
        MissingSubcontractingLocationMsg: Label 'Vendor %1 has no subcontracting location. This location is used to track components and work-in-process (WIP) items at the subcontractor. Choose a Subcontracting Location Code on the vendor before using this work center for subcontracting.', Comment = '%1 = Vendor No.';
        NotificationIdErr: Label 'The subcontractor location notification ID is unexpected.';
        NotificationMessageErr: Label 'The subcontractor location notification message is unexpected.';
        NotificationOrderErr: Label 'The subcontractor location notification interactions occurred in an unexpected order.';
        NotificationVendorErr: Label 'The vendor in the subcontractor location notification is unexpected.';
        RecallNotificationTok: Label 'Recall', Locked = true;
        SendNotificationTok: Label 'Send', Locked = true;
        VendorCardNoErr: Label 'The Vendor Card opened for an unexpected vendor.';
        VendorNoTok: Label 'VendorNo', Locked = true;
}