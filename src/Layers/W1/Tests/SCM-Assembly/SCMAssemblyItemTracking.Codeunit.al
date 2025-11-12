// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Warehouse.Tracking;
using System.TestLibraries.Utilities;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Assembly.History;
using Microsoft.Foundation.NoSeries;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Foundation.Navigate;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Journal;

codeunit 137926 "SCM Assembly Item Tracking"
{
    Permissions = TableData "Whse. Item Tracking Line" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Item Tracking] [SCM]
        WorkDate2 := LibraryPlanning.SetSafetyWorkDate();
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        WorkDate2: Date;
        Initialized: Boolean;

        SNMissingErr: Label 'You must assign a serial number for item', Comment = '%1 - Item No.';
        LNMissingErr: Label 'You must assign a lot number for item', Comment = '%1 - Item No.';
        WrongSNErr: Label 'SN different from what expected';
        WrongLNErr: Label 'LN different from what expected';
        MessageInvtMvmtCreatedMsg: Label 'Number of Invt. Movement activities created: 1 out of a total of 1.';
        WrongNoOfT337RecordsErr: Label 'Wrong no of T337 records';
        MessageWhsePickCreatedMsg: Label 'has been created';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Item Tracking");
        LibraryVariableStorage.Clear();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Item Tracking");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryPatterns.SetNoSeries();
        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Item Tracking");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteToOrderCompSN()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemParent: Record Item;
        ItemChild: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ATOLink: Record "Assemble-to-Order Link";
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        SalesOrderHeader: Record "Sales Header";
        BOMComponent: Record "BOM Component";
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";
        LibrarySales: Codeunit "Library - Sales";
        SNChild: Code[20];
    begin
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();

        // Create items
        CreateItemTrackingCode(ItemTrackingCode, true, false);
        CreateItems(ItemParent, ItemTrackingCode, ItemChild, ItemTrackingCode);
        ItemParent.Validate("Replenishment System", ItemParent."Replenishment System"::Assembly);
        ItemParent.Validate("Assembly Policy", ItemParent."Assembly Policy"::"Assemble-to-Order");
        ItemParent.Modify(true);

        // Add child to parent BOM
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ItemParent."No.", BOMComponent.Type::Item, ItemChild."No.", 1, '');

        // Add component to inventory
        SNChild := ItemChild."No.";
        AddItemToInventory(ItemChild, 1, SNChild, '');

        // Create Sales Quote
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '20000');
        SalesHeader.Validate("Shipment Date", WorkDate2);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemParent."No.", 1);

        // Add SN to Asm Quote Comp
        ATOLink.SetRange("Assembly Document Type", ATOLink."Assembly Document Type"::Quote);
        ATOLink.SetRange(Type, ATOLink.Type::Sale);
        ATOLink.SetRange("Document Type", ATOLink."Document Type"::Quote);
        ATOLink.SetRange("Document No.", SalesHeader."No.");
        ATOLink.FindFirst();
        AssemblyLine.Get(AssemblyLine."Document Type"::Quote, ATOLink."Assembly Document No.", 10000);
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservEntry, AssemblyLine, SNChild, '', 1);

        // Validate SN on asm order comp
        ValidateQuoteSN(ItemChild."No.", SNChild, -1, 0);

        // Make Sales Order from Quote
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesQuoteToOrder.Run(SalesHeader);
        SalesQuoteToOrder.GetSalesOrderHeader(SalesOrderHeader);

        // Validate SN on asm order comp
        ValidateQuoteSN(ItemChild."No.", SNChild, -1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullPostingWithSN()
    var
        ItemTrackingCodeSN: Record "Item Tracking Code";
    begin
        Initialize();
        CreateItemTrackingCode(ItemTrackingCodeSN, true, false);
        FullPosting(ItemTrackingCodeSN, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullPostingWithLot()
    var
        ItemTrackingCodeLot: Record "Item Tracking Code";
    begin
        Initialize();
        CreateItemTrackingCode(ItemTrackingCodeLot, false, true);
        FullPosting(ItemTrackingCodeLot, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostNotAllwdIfMissingLineSN()
    var
        ItemTrackingCodeSN: Record "Item Tracking Code";
        ItemParent: Record Item;
        ItemChild: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize();
        CreateItemTrackingCode(ItemTrackingCodeSN, true, false);

        MockItem(ItemParent);
        MockItem(ItemChild);
        ItemChild."Item Tracking Code" := ItemTrackingCodeSN.Code;
        ItemChild.Modify(true);

        AddItemToInventory(ItemChild, 1, 'SN0001', '');

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, ItemParent."No.", '', 1, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ItemChild."No.", ItemChild."Base Unit of Measure", 1, 1, '');

        asserterror LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        Assert.IsTrue(StrPos(GetLastErrorText, SNMissingErr) > 0, 'Wrong error: ' + GetLastErrorText + '; Expected: ' + SNMissingErr);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostNotAllwdIfMissingHeadSN()
    var
        ItemTrackingCodeSN: Record "Item Tracking Code";
        ItemParent: Record Item;
        ItemChild: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize();
        CreateItemTrackingCode(ItemTrackingCodeSN, true, false);

        MockItem(ItemParent);
        MockItem(ItemChild);
        ItemParent."Item Tracking Code" := ItemTrackingCodeSN.Code;
        ItemParent.Modify(true);

        AddItemToInventory(ItemChild, 1, '', '');

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, ItemParent."No.", '', 1, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ItemChild."No.", ItemChild."Base Unit of Measure", 1, 1, '');

        asserterror LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        Assert.IsTrue(StrPos(GetLastErrorText, SNMissingErr) > 0, 'Wrong error: ' + GetLastErrorText + '; Expected: ' + SNMissingErr);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostNotAllwdIfMissingLineLN()
    var
        ItemTrackingCodeLN: Record "Item Tracking Code";
        ItemParent: Record Item;
        ItemChild: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize();
        CreateItemTrackingCode(ItemTrackingCodeLN, false, true);

        MockItem(ItemParent);
        MockItem(ItemChild);
        ItemChild."Item Tracking Code" := ItemTrackingCodeLN.Code;
        ItemChild.Modify(true);

        AddItemToInventory(ItemChild, 1, '', 'LOT0001');

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, ItemParent."No.", '', 1, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ItemChild."No.", ItemChild."Base Unit of Measure", 1, 1, '');

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, LNMissingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostNotAllwdIfMissingHeadLN()
    var
        ItemTrackingCodeLN: Record "Item Tracking Code";
        ItemParent: Record Item;
        ItemChild: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize();
        CreateItemTrackingCode(ItemTrackingCodeLN, false, true);

        MockItem(ItemParent);
        MockItem(ItemChild);
        ItemParent."Item Tracking Code" := ItemTrackingCodeLN.Code;
        ItemParent.Modify(true);

        AddItemToInventory(ItemChild, 1, '', '');

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, ItemParent."No.", '', 1, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ItemChild."No.", ItemChild."Base Unit of Measure", 1, 1, '');

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, LNMissingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPostingWithLot()
    var
        ItemTrackingCodeLot: Record "Item Tracking Code";
    begin
        Initialize();
        CreateItemTrackingCode(ItemTrackingCodeLot, false, true);
        PartialPosting(ItemTrackingCodeLot, '', '', 'LOTA', 'LOT0001');
    end;

    [Test]
    [HandlerFunctions('MessagePickCreated')]
    [Scope('OnPrem')]
    procedure WMS_Pick_AssignITOnAsmLine()
    begin
        Initialize();
        WhseScenario(0, false, false, true, 0); // LN
        WhseScenario(0, false, true, false, 0); // SN
    end;

    [Test]
    [HandlerFunctions('MessagePickCreated')]
    [Scope('OnPrem')]
    procedure WMS_Pick_AssignITOnPick()
    begin
        Initialize();
        WhseScenario(0, false, false, true, 1); // LN
        WhseScenario(0, false, true, false, 1); // SN
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMS_PickWksh_AssingITOnAsmLine()
    begin
        Initialize();
        WhseScenario(0, true, false, true, 0);  // LN
        WhseScenario(0, true, true, false, 0);  // SN
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMS_PickWksh_AssingITOnWksh()
    begin
        Initialize();
        WhseScenario(0, true, false, true, 3);  // LN
        WhseScenario(0, true, true, false, 3);  // SN
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMS_PickWksh_AssingITOnPick()
    begin
        Initialize();
        WhseScenario(0, true, false, true, 1);  // LN
        WhseScenario(0, true, true, false, 1);  // SN
    end;

    [Test]
    [HandlerFunctions('MessageInvtMovementCreated')]
    [Scope('OnPrem')]
    procedure BW_AssignITOnAsmLine()
    begin
        Initialize();
        WhseScenario(1, false, false, true, 0); // LN
        WhseScenario(1, false, true, false, 0); // SN
    end;

    [Test]
    [HandlerFunctions('MessageInvtMovementCreated')]
    [Scope('OnPrem')]
    procedure BW_AssignITOnInvtMovement()
    begin
        Initialize();
        WhseScenario(1, false, false, true, 2); // LN
        WhseScenario(1, false, true, false, 2); // SN
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler')]
    procedure QuantityOnAsmCompItemTrackingAfterPartialPosting()
    var
        CompItem: Record Item;
        AsmItem: Record Item;
        BOMComponent: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[20];
        QtyPer: Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 414700] Quantity on item tracking for assembly component must not exceed quantity on assembly line.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        QtyPer := LibraryRandom.RandIntInRange(2, 5);
        Qty := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Lot-tracked assembly component "C".
        // [GIVEN] Assembly item "A", create assembly BOM, quantity per = 3.
        LibraryItemTracking.CreateLotItem(CompItem);
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Modify(true);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", QtyPer, CompItem."Base Unit of Measure");

        // [GIVEN] Post component "C" to inventory, note the item ledger entry no. = "X".
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, CompItem."No.", '', '', LibraryRandom.RandIntInRange(50, 100));
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        ItemLedgerEntry.SetRange("Item No.", CompItem."No.");
        ItemLedgerEntry.FindLast();

        // [GIVEN] Assembly order for 5 pcs of item "A", set "Quantity to Assemble" = 2.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, LibraryRandom.RandDate(30), AsmItem."No.", '', Qty, '');
        AssemblyHeader.Validate("Quantity to Assemble", Qty / 2);
        AssemblyHeader.Modify(true);

        // [GIVEN] Select lot no. for the assembly line, "Qty. to Handle" = 6 (2 * 3).
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservationEntry, AssemblyLine, '', LotNo, Qty * QtyPer);
        ReservationEntry.Validate("Qty. to Handle (Base)", Qty / 2 * QtyPer);
        ReservationEntry.Modify(true);

        // [GIVEN] Partially post the assembly order.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [GIVEN] Open item tracking lines for the assembly line, check that "Quantity (Base)" = 15 (5 * 3).
        // [GIVEN] Select "Applies-to Entry No." = "X", close the page.
        AssemblyLine.Find();
        LibraryVariableStorage.Enqueue(Qty * QtyPer);
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Entry No.");
        AssemblyLine.OpenItemTrackingLines();

        // [WHEN] Reopen the item tracking lines again.
        LibraryVariableStorage.Enqueue(Qty * QtyPer);
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Entry No.");
        AssemblyLine.OpenItemTrackingLines();

        // [THEN] Ensure "Quantity (Base)" in item tracking = 15. Verification is done in handler.

        // [THEN] The assembly order can be successfully posted.
        AssemblyHeader.Find();
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure VerifyConsumptionEntriesAreGroupedCorrectlyOnItemTracingForPostedAndUndoPostedAssemblyOrderWithLotTrackedItem()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        CompItem: Record Item;
        AsmItem: Record Item;
        ReservEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        ItemTracingPage: TestPage "Item Tracing";
        QtyPer, Qty : Decimal;
        LotNoCode, LotNo : Code[20];
    begin
        // [SCENARIO 453007] Verify Consumption Entries are grouped correctly on Item Tracing for Posted and Undo Posted Assembly Order with Lot Tracked Item         
        Initialize();

        // [GIVEN] Generate Random Qty.
        QtyPer := LibraryRandom.RandIntInRange(2, 5);
        Qty := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Create Lot No. no series
        LotNoCode := LibraryERM.CreateNoSeriesCode();
        LotNo := NoSeries.PeekNextNo(LotNoCode);

        // [GIVEN] Create Assembly Item, Component Item and BOM Component
        CreateAssemblyAndComponentItem(AsmItem, CompItem, QtyPer);

        // [GIVEN] Add Component Item on Inventory
        AddItemToInventory(CompItem, 100, '', '');

        // [GIVEN] Create Assembly Order and Line
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, LibraryRandom.RandDate(30), AsmItem."No.", '', Qty, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, CompItem."No.", CompItem."Base Unit of Measure", Qty, QtyPer, '');

        // [GIVEN] Create Item Tracking Line for Assembly Header
        LibraryItemTracking.CreateAssemblyHeaderItemTracking(ReservEntry, AssemblyHeader, '', LotNo, Qty);

        // [GIVEN] Post Assembly Order
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [GIVEN] Undo Posted Assembly Order
        FindPostedAssemblyHeaderNotReversed(PostedAssemblyHeader, AssemblyHeader."No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');

        // [WHEN] Open Item Tracing for Posted and Undo Posted Assembly Order
        OpenItemTracing(ItemTracingPage, AsmItem."No.", LotNo);

        // [THEN] Validate Item Tracing Lines
        ValidateItemTracingLine(ItemTracingPage, LotNo, AsmItem, CompItem, Qty, QtyPer);
    end;

    [Test]
    procedure SerialTrackedOnItemLedgerEntryForAssemblyOrder()
    var
        CompItem: Record Item;
        AsmItem: Record Item;
        BOMComponent: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SerialNo: Code[20];
    begin
        // [SCENARIO 496681] Serial Tracked component on Assembly Order where full Quantity to Assemble is Picked and 
        // partial quantity is posted gives the proper serial number on Item Ledger Entry 
        Initialize();

        // [GIVEN] Create Serial No.
        SerialNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create Component Item with serial Number
        LibraryItemTracking.CreateSerialItem(CompItem);

        // [GIVEN] Create Assembled Item
        LibraryInventory.CreateItem(AsmItem);

        // [GIVEN] Update Replenishment System as Assembly.
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Modify(true);

        // [GIVEN] Create Assembly BOM of assembled Item
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");

        // [GIVEN] Create Inventory of Componenty Item with Serial Number
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, CompItem."No.", '', '', 1);
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, SerialNo, '', ItemJournalLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Assembly Order 
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, LibraryRandom.RandDate(30), AsmItem."No.", '', 1, '');

        // [GIVEN] Create Assembly Line
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();

        // [GIVEN] Create Item Tracking of Assembly Line
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservationEntry, AssemblyLine, SerialNo, '', 1);

        // [WHEN] Post the Assembly Order
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] Filter the posted Item Ledger Entry
        ItemLedgerEntry.SetRange("Item No.", CompItem."No.");
        ItemLedgerEntry.FindLast();

        // [VERIFY] Serial No. should be same as assigned earlier on Item Tracking
        Assert.AreEqual(SerialNo, ItemLedgerEntry."Serial No.", '');
    end;

    local procedure ValidateItemTracingLine(var ItemTracingPage: TestPage "Item Tracing"; LNParent: Code[50]; ItemParent: Record Item; ItemChild: Record Item; Quantity: Decimal; QtyPer: Decimal)
    begin
        ItemTracingPage.Expand(true);
        ValidateItemTracingLine(ItemTracingPage, 'Assembly Output', '', LNParent, ItemParent."No.", Quantity * (-1));

        ItemTracingPage.Next();
        ItemTracingPage.Expand(true);
        ValidateItemTracingLine(ItemTracingPage, 'Assembly Consumption', '', '', ItemChild."No.", Quantity * QtyPer);

        ItemTracingPage.Next();
        ItemTracingPage.Expand(true);
        ValidateItemTracingLine(ItemTracingPage, 'Assembly Consumption', '', '', ItemChild."No.", Quantity * QtyPer);

        ItemTracingPage.Next();
        ItemTracingPage.Expand(true);
        ValidateItemTracingLine(ItemTracingPage, 'Assembly Output', '', LNParent, ItemParent."No.", Quantity);

        ItemTracingPage.Next();
        ItemTracingPage.Expand(true);
        ValidateItemTracingLine(ItemTracingPage, 'Assembly Consumption', '', '', ItemChild."No.", Quantity * QtyPer * (-1));

        ItemTracingPage.Next();
        ItemTracingPage.Expand(true);
        ValidateItemTracingLine(ItemTracingPage, 'Assembly Consumption', '', '', ItemChild."No.", Quantity * QtyPer * (-1));
    end;

    local procedure OpenItemTracing(var ItemTracingPage: TestPage "Item Tracing"; ItemNo: Code[20]; LotNo: Code[20])
    begin
        ItemTracingPage.OpenEdit();
        ItemTracingPage.ItemNoFilter.SetValue(ItemNo);
        ItemTracingPage.LotNoFilter.SetValue(LotNo);
        ItemTracingPage.TraceMethod.SetValue('Usage -> Origin');
        ItemTracingPage.ShowComponents.SetValue('All');
        ItemTracingPage.Trace.Invoke(); // Trace
    end;

    local procedure FindPostedAssemblyHeaderNotReversed(var PostedAssemblyHeader: Record "Posted Assembly Header"; SourceAssemblyHeaderNo: Code[20])
    begin
        Clear(PostedAssemblyHeader);
        PostedAssemblyHeader.SetRange("Order No.", SourceAssemblyHeaderNo);
        PostedAssemblyHeader.SetRange(Reversed, false);
        PostedAssemblyHeader.FindFirst();
    end;

    local procedure CreateAssemblyAndComponentItem(var AsmItem: Record Item; var CompItem: Record Item; QtyPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryItemTracking.CreateLotItem(AsmItem);
        LibraryInventory.CreateItem(CompItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Modify(true);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", QtyPer, CompItem."Base Unit of Measure");
    end;

    local procedure WhseScenario(WhseType: Option WMS,BW; UsePickWorksheet: Boolean; SN: Boolean; LN: Boolean; AssignITOn: Option AsmLine,Pick,InvtMovement,PickWorksheet)
    var
        WhseWkshTemplate: Record "Whse. Worksheet Template";
        AssemblyHeader: Record "Assembly Header";
        Location: Record Location;
        AssemblyLine: Record "Assembly Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemParent: Record Item;
        ItemChild: Record Item;
        ReservEntry: Record "Reservation Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WarehouseRequest: Record "Warehouse Request";
        CreatePick: Report "Create Pick";
        SerialNo: Code[50];
        LotNo: Code[50];
    begin
        // Create Location
        if WhseType = WhseType::WMS then
            MockLocation(Location, true, true, true, true)
        else
            MockLocation(Location, true, true, false, false);

        // Create Item Tracking Code
        CreateItemTrackingCode(ItemTrackingCode, SN, LN);

        // Create Items
        MockItem(ItemParent);
        MockItem(ItemChild);
        ItemChild."Item Tracking Code" := ItemTrackingCode.Code;
        ItemChild.Modify(true);

        // Add component to inventory
        if SN then
            SerialNo := 'SN0001';
        if LN then
            LotNo := 'LOT0001';

        AddItemToWhseLocation(ItemChild, Location, 'BIN1', 1, SerialNo, LotNo);

        // Create Asm order
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, ItemParent."No.", '', 1, '');
        AssemblyHeader.Validate("Location Code", Location.Code);
        AssemblyHeader.Modify(true);
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ItemChild."No.", ItemChild."Base Unit of Measure", 1, 1, '');
        AssemblyLine.Validate("Location Code", Location.Code);
        AssemblyLine.Validate("Bin Code", 'BIN3');
        AssemblyLine.Modify(true);

        // Assign IT on Line
        if AssignITOn = AssignITOn::AsmLine then
            LibraryItemTracking.CreateAssemblyLineItemTracking(ReservEntry, AssemblyLine, SerialNo, LotNo, 1);

        // Relase Asm Order
        LibraryAssembly.ReleaseAO(AssemblyHeader);
        if WhseType = WhseType::WMS then
            WhsePickRequest.Get(3, 1, AssemblyHeader."No.", Location.Code)
        else
            WarehouseRequest.Get(1, Location.Code, DATABASE::"Assembly Line", 1, AssemblyHeader."No.");

        if UsePickWorksheet then begin
            LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWkshLine, WhsePickRequest, Location.Code);
            if AssignITOn = AssignITOn::AsmLine then
                ValidateITOnPW(AssemblyHeader."No.", ItemChild."No.", SerialNo, LotNo, 1, true)
            else
                if AssignITOn = AssignITOn::PickWorksheet then begin
                    WhseWkshTemplate.SetRange(Type, WhseWkshTemplate.Type::Pick);
                    WhseWkshTemplate.FindFirst();
                    WhseWkshLine.Get(WhseWkshTemplate.Name, Location.Code, Location.Code, 10000);
                    LibraryItemTracking.CreateWhseWkshItemTracking(WhseItemTrackingLine, WhseWkshLine, SerialNo, LotNo, 1);
                end;
        end;

        // Create whse pick or invt movement
        if WhseType = WhseType::WMS then
            if UsePickWorksheet then begin
                CreatePick.SetWkshPickLine(WhseWkshLine);
                CreatePick.UseRequestPage(false);
                CreatePick.RunModal();
            end else
                LibraryAssembly.CreateWhsePick(AssemblyHeader, '', 0, false, false, false) // create pick
        else
            if WhseType = WhseType::BW then
                LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);

        // Validate IT on Pick/invt Movement
        if (AssignITOn = AssignITOn::PickWorksheet) or (AssignITOn = AssignITOn::AsmLine) then
            CheckPick(AssemblyHeader."No.", SerialNo, LotNo);

        // Choose IT on Pick
        if (AssignITOn = AssignITOn::Pick) or (AssignITOn = AssignITOn::InvtMovement) then
            AssignITToWhseActivity(AssemblyHeader."No.", SerialNo, LotNo);

        // Register pick/Invt movement
        if WhseType = WhseType::WMS then
            RegisterWhseActivity(WarehouseActivityLine."Activity Type"::Pick, AssemblyHeader."No.")
        else
            RegisterWhseActivity(WarehouseActivityLine."Activity Type"::"Invt. Movement", AssemblyHeader."No.");

        // Validate IT on asm line in T337
        ValidateT337(AssemblyLine."Document No.", ItemChild, SerialNo, LotNo, -1, true, 1);
    end;

    local procedure FullPosting(ItemTrackingCode: Record "Item Tracking Code"; SN: Boolean; LN: Boolean)
    var
        ItemParent: Record Item;
        ItemChild: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        ItemTracingPage: TestPage "Item Tracing";
        NavigatePage: TestPage Navigate;
        SNChild: Code[20];
        LNChild: Code[20];
        SNParent: Code[20];
        LNParent: Code[20];
    begin
        CreateItems(ItemParent, ItemTrackingCode, ItemChild, ItemTrackingCode);

        if SN then begin
            SNChild := ItemChild."No.";
            SNParent := ItemParent."No."
        end;
        if LN then begin
            LNChild := ItemChild."No.";
            LNParent := ItemParent."No."
        end;

        AddItemToInventory(ItemChild, 1, SNChild, LNChild);

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, ItemParent."No.", '', 1, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ItemChild."No.", ItemChild."Base Unit of Measure", 1, 1, '');
        LibraryItemTracking.CreateAssemblyHeaderItemTracking(ReservEntry, AssemblyHeader, SNParent, LNParent, 1);
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservEntry, AssemblyLine, SNChild, LNChild, 1);

        ValidateT337(AssemblyHeader."No.", ItemParent, SNParent, LNParent, 1, true, 1);
        ValidateT337(AssemblyLine."Document No.", ItemChild, SNChild, LNChild, -1, true, 1);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        ValidateT32(AssemblyHeader."No.", ItemParent, SNParent, LNParent, 1, true);
        ValidateT32(AssemblyLine."Document No.", ItemChild, SNChild, LNChild, -1, true);

        ValidateT337(AssemblyHeader."No.", ItemParent, SNParent, LNParent, 0, false, 0);
        ValidateT337(AssemblyLine."Document No.", ItemChild, SNChild, LNChild, 0, false, 0);

        // Validate Item Tracing
        ItemTracingPage.OpenEdit();
        ItemTracingPage.LotNoFilter.SetValue(LNParent);
        ItemTracingPage.SerialNoFilter.SetValue(SNParent);
        ItemTracingPage.TraceMethod.SetValue('Usage -> Origin');
        ItemTracingPage.ShowComponents.SetValue('All');

        ItemTracingPage.Trace.Invoke(); // Trace

        ItemTracingPage.Expand(true);
        ValidateItemTracingLine(ItemTracingPage, 'Assembly Output', SNParent, LNParent, ItemParent."No.", 1);

        ItemTracingPage.Next();
        ItemTracingPage.Expand(true);
        ValidateItemTracingLine(ItemTracingPage, 'Assembly Consumption', SNChild, LNChild, ItemChild."No.", -1);

        ItemTracingPage.Next();
        ValidateItemTracingLine(ItemTracingPage, 'Item Ledger Entry', SNChild, LNChild, ItemChild."No.", 1);

        ItemTracingPage.TraceOppositeFromLine.Invoke(); // Trace opposite from line
        ItemTracingPage.First();

        ItemTracingPage.Expand(true);
        ValidateItemTracingLine(ItemTracingPage, 'Item Ledger Entry', SNChild, LNChild, ItemChild."No.", 1);

        ItemTracingPage.Next();
        ItemTracingPage.Expand(true);
        ValidateItemTracingLine(ItemTracingPage, 'Assembly Consumption', SNChild, LNChild, ItemChild."No.", -1);

        ItemTracingPage.Next();
        ValidateItemTracingLine(ItemTracingPage, 'Assembly Output', SNParent, LNParent, ItemParent."No.", 1);

        // Validate Navigate result parent
        NavigatePage.OpenEdit();
        NavigatePage.SerialNoFilter.Value(SNParent);
        NavigatePage.LotNoFilter.Value(LNParent);
        NavigatePage.Find.Invoke();
        ValidateNavigateLine(NavigatePage, 'Item Ledger Entry', 1);
        NavigatePage.Next();
        ValidateNavigateLine(NavigatePage, 'Posted Assembly Header', 1);

        // Validate Navigate result child
        NavigatePage.SerialNoFilter.Value(SNChild);
        NavigatePage.LotNoFilter.Value(LNChild);
        NavigatePage.Find.Invoke();
        ValidateNavigateLine(NavigatePage, 'Item Ledger Entry', 2);
        NavigatePage.Next();
        ValidateNavigateLine(NavigatePage, 'Posted Assembly Header', 1);
    end;

    local procedure PartialPosting(ItemTrackingCode: Record "Item Tracking Code"; SNChild: Code[10]; SNParent: Code[10]; LNParent: Code[10]; LNChild: Code[10])
    var
        ItemParent: Record Item;
        ItemChild: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
    begin
        CreateItems(ItemParent, ItemTrackingCode, ItemChild, ItemTrackingCode);
        AddItemToInventory(ItemChild, 100, SNChild, LNChild);

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, ItemParent."No.", '', 3, '');
        AssemblyHeader.Validate("Quantity to Assemble", 2);
        AssemblyHeader.Modify(true);
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ItemChild."No.", ItemChild."Base Unit of Measure", 6, 1, '');
        AssemblyLine."Quantity to Consume" := 4;
        AssemblyLine.Modify(true);
        LibraryItemTracking.CreateAssemblyHeaderItemTracking(ReservEntry, AssemblyHeader, SNParent, LNParent, 3);
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservEntry, AssemblyLine, SNChild, LNChild, 4);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        ValidateT32(AssemblyHeader."No.", ItemParent, SNParent, LNParent, 2, true);
        ValidateT32(AssemblyLine."Document No.", ItemChild, SNChild, LNChild, -4, true);

        ValidateT337(AssemblyHeader."No.", ItemParent, SNParent, LNParent, 1, true, 1);
        ValidateT337(AssemblyLine."Document No.", ItemChild, SNChild, LNChild, 0, false, 0);
    end;

    [Normal]
    local procedure AssignITToWhseActivity(SourceNo: Code[20]; SN: Code[20]; LN: Code[20])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Assembly Consumption");
        WhseActivityLine.SetRange("Source No.", SourceNo);
        WhseActivityLine.FindSet();
        repeat
            WhseActivityLine.Validate("Lot No.", LN);
            WhseActivityLine.Validate("Serial No.", SN);
            WhseActivityLine.Modify();
        until WhseActivityLine.Next() = 0;
    end;

    [Normal]
    local procedure RegisterWhseActivity(ActivityType: Enum "Warehouse Activity Type"; SourceNo: Code[20])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Assembly Consumption");
        WhseActivityLine.SetRange("Source No.", SourceNo);
        WhseActivityLine.FindFirst();

        Clear(WhseActivityHeader);
        WhseActivityHeader.SetRange(Type, ActivityType);
        WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
        WhseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        if (ActivityType = ActivityType::"Put-away") or (ActivityType = ActivityType::Pick) then
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader)
        else
            WhseActivityRegister.Run(WhseActivityLine);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; SN: Boolean; Lot: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SN, Lot);
        ItemTrackingCode."SN Warehouse Tracking" := SN;
        ItemTrackingCode."Lot Warehouse Tracking" := Lot;
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItems(var ItemParent: Record Item; ItemTrackingCodeParent: Record "Item Tracking Code"; var ItemChild: Record Item; ItemTrackingCodeChild: Record "Item Tracking Code")
    begin
        MockItem(ItemParent);
        MockItem(ItemChild);
        ItemParent."Item Tracking Code" := ItemTrackingCodeParent.Code;
        ItemParent.Modify(true);
        ItemChild."Item Tracking Code" := ItemTrackingCodeChild.Code;
        ItemChild.Modify(true);
    end;

    local procedure MockLocation(var Location: Record Location; BinMandatory: Boolean; RequirePick: Boolean; RequireShipment: Boolean; DirectedPutPick: Boolean)
    var
        BinTypePick: Record "Bin Type";
        BinTypePutaway: Record "Bin Type";
        Zone: Record Zone;
        Bin: Record Bin;
        WhseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location.Code, true);
        if DirectedPutPick then
            BinMandatory := true;
        Location."Bin Mandatory" := BinMandatory;
        Location."Require Pick" := RequirePick;
        Location."Require Shipment" := RequireShipment;
        Location."Directed Put-away and Pick" := DirectedPutPick;
        Location.Modify(true);

        if DirectedPutPick then begin // create a zone and set bin type code
            BinTypePick.SetRange(Pick, true);
            BinTypePick.FindFirst();
            LibraryWarehouse.CreateZone(Zone, 'ZONE', Location.Code, BinTypePick.Code, '', '', 0, false);
            BinTypePutaway.SetRange("Put Away", true);
            BinTypePutaway.SetRange(Pick, false);
            BinTypePutaway.FindFirst();
            LibraryWarehouse.CreateBin(Bin, Location.Code, 'BINX', Zone.Code, BinTypePick.Code);
            Location.Validate("Adjustment Bin Code", 'BINX');
            Location.Modify(true);
        end;

        if Location."Require Pick" then
            if Location."Require Shipment" then begin
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
            end else begin
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
                Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Inventory Movement";
                Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Inventory Pick";
            end
        else begin
            Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)";
            Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)";
            Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (optional)";
        end;

        if Location."Require Put-away" and not Location."Require Receive" then
            Location."Prod. Output Whse. Handling" := Location."Prod. Output Whse. Handling"::"Inventory Put-away";
        Location.Modify(true);

        // create 4 bins - 2 for Picking and 2 for put-awaying
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'BIN1', Zone.Code, BinTypePick.Code);
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'BIN2', Zone.Code, BinTypePick.Code);
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'BIN3', Zone.Code, BinTypePutaway.Code);
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'BIN4', Zone.Code, BinTypePutaway.Code);
    end;

    local procedure AddItemToInventory(Item: Record Item; Quantity: Decimal; SN: Code[20]; LN: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ReservEntry: Record "Reservation Entry";
    begin
        // IF SN is used Quantity must be 1
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();

        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        if (SN <> '') or (LN <> '') then
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, SN, LN, Quantity);

        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure AddItemToWhseLocation(Item: Record Item; Location: Record Location; BinCode: Code[20]; Quantity: Decimal; SerialNo: Code[50]; LotNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        ReservEntry: Record "Reservation Entry";
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();

        if Location."Directed Put-away and Pick" then begin
            WarehouseJournalTemplate.SetRange(Type, WarehouseJournalTemplate.Type::Item);
            WarehouseJournalTemplate.FindFirst();
            WarehouseJournalBatch.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
            WarehouseJournalBatch.FindFirst();
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name,
              Location.Code, '', BinCode, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
            if (SerialNo <> '') or (LotNo <> '') then
                LibraryItemTracking.CreateWhseJournalLineItemTracking(WhseItemTrackingLine, WarehouseJournalLine, SerialNo, LotNo, Quantity);
            LibraryWarehouse.PostWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code);
            LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate2, '');
            LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
        end else begin
            LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
            ItemJournalLine.Validate("Location Code", Location.Code);
            ItemJournalLine.Validate("Bin Code", BinCode);
            ItemJournalLine.Modify(true);
            if (SerialNo <> '') or (LotNo <> '') then
                LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, SerialNo, LotNo, Quantity);
            LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
        end;
    end;

    local procedure ValidateT337(AssemblyOrderNo: Code[20]; Item: Record Item; SerialNo: Code[50]; LotNo: Code[50]; Quantity: Decimal; RecordsShouldExist: Boolean; ExpectedNumberOfRecords: Integer)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetRange("Source ID", AssemblyOrderNo);
        ReservEntry.SetRange("Item No.", Item."No.");
        ReservEntry.SetRange("Serial No.", SerialNo);
        ReservEntry.SetRange("Lot No.", LotNo);
        if RecordsShouldExist then
            ReservEntry.SetRange("Quantity (Base)", Quantity);

        Assert.AreEqual(ReservEntry.Count, ExpectedNumberOfRecords, WrongNoOfT337RecordsErr);
        Assert.AreEqual(RecordsShouldExist, ReservEntry.FindFirst(), 'T337 records are different from what expected :(');
    end;

    local procedure ValidateT32(AssemblyOrderNo: Code[20]; Item: Record Item; SN: Code[20]; LN: Code[20]; Quantity: Decimal; RecordsShouldExist: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Order No.", AssemblyOrderNo);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Serial No.", SN);
        ItemLedgerEntry.SetRange("Lot No.", LN);
        ItemLedgerEntry.SetRange(Quantity, Quantity);

        Assert.AreEqual(RecordsShouldExist, ItemLedgerEntry.FindFirst(), 'T32 records are different from what expected :(');
    end;

    local procedure ValidateITOnPW(AssemblyOrderNo: Code[20]; ItemNo: Code[20]; SN: Code[20]; LN: Code[20]; Quantity: Decimal; RecordsShouldExist: Boolean)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseItemTrackingLine.SetRange("Source ID", AssemblyOrderNo);
        WhseItemTrackingLine.SetRange("Item No.", ItemNo);
        WhseItemTrackingLine.SetRange("Serial No.", SN);
        WhseItemTrackingLine.SetRange("Lot No.", LN);
        WhseItemTrackingLine.SetRange("Quantity (Base)", Quantity);

        Assert.AreEqual(RecordsShouldExist, WhseItemTrackingLine.FindFirst(), 'T6550 records are different from what expected :(');
    end;

    [Normal]
    local procedure CheckPick(AsmOrderNo: Code[20]; ExpectedSN: Code[20]; ExpectedLN: Code[20])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Assembly Consumption");
        WhseActivityLine.SetRange("Source No.", AsmOrderNo);
        WhseActivityLine.FindFirst();
        if ExpectedSN <> '' then
            Assert.AreEqual(WhseActivityLine."Serial No.", ExpectedSN, WrongSNErr);
        if ExpectedLN <> '' then
            Assert.AreEqual(WhseActivityLine."Lot No.", ExpectedLN, WrongLNErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageInvtMovementCreated(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MessageInvtMvmtCreatedMsg) > 0, 'Wrong Message: ' + Message + '; Expected: ' + MessageInvtMvmtCreatedMsg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessagePickCreated(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MessageWhsePickCreatedMsg) > 0, 'Wrong Message: ' + Message + '; Expected: ' + MessageWhsePickCreatedMsg);
    end;

    local procedure MockItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
    end;

    local procedure ValidateItemTracingLine(ItemTracingPage: TestPage "Item Tracing"; Description: Text[1000]; SN: Code[20]; LN: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        Assert.IsTrue(StrPos(ItemTracingPage.Description.Value, Description) > 0, 'Wrong description');
        ItemTracingPage."Serial No.".AssertEquals(SN);
        ItemTracingPage."Lot No.".AssertEquals(LN);
        ItemTracingPage."Item No.".AssertEquals(ItemNo);
        ItemTracingPage.Quantity.AssertEquals(Quantity);
    end;

    local procedure ValidateNavigateLine(NavigatePage: TestPage Navigate; TableName: Text[1000]; NoOfRecords: Integer)
    begin
        NavigatePage."Table Name".AssertEquals(TableName);
        NavigatePage."No. of Records".AssertEquals(NoOfRecords);
    end;

    local procedure ValidateQuoteSN(ItemNo: Code[20]; SerialNo: Code[50]; Qty: Decimal; SourceSubType: Option)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetRange("Item No.", ItemNo);
        ReservEntry.SetRange("Serial No.", SerialNo);
        ReservEntry.SetRange("Quantity (Base)", Qty);
        ReservEntry.SetRange("Source Type", DATABASE::"Assembly Line");
        ReservEntry.SetRange("Source Subtype", SourceSubType);
        Assert.AreEqual(1, ReservEntry.Count, WrongNoOfT337RecordsErr);
        Assert.AreEqual(true, ReservEntry.FindFirst(), 'T337 records are different from what expected :(');
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Quantity (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines."Appl.-to Item Entry".SetValue(LibraryVariableStorage.DequeueInteger());
        ItemTrackingLines.OK().Invoke();
    end;
}

