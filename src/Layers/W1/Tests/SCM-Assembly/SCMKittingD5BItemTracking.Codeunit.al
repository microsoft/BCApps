// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Assembly.Setup;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.History;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Journal;
using Microsoft.Assembly.History;
using Microsoft.Inventory.BOM;

codeunit 137098 "SCM Kitting-D5B-ItemTracking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Item Tracking] [SCM]
        IsInitialized := false
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        GLB_ITPageHandler: Option AssignITSpec,SelectITSpec,AssignITSpecPartial,FromILEs;
        PAR_ITPage_AssignSerial: Boolean;
        PAR_ITPage_AssignLot: Boolean;
        PAR_ITPage_AssignPartial: Boolean;
        PAR_ITPage_AssignQty: Integer;
        PAR_ITSummaryPage_RowsExpected: Boolean;
        PAR_ITPage_ItemNo: Code[20];
        IsInitialized: Boolean;
        Tracking: Option Untracked,Lot,Serial,LotSerial;
        ErrorQtyHandle: Label 'Qty. to Handle (Base) in the item tracking';
        LotNoAvailabilityWarning: Label 'You have insufficient quantity of Item %1 on inventory.';
        SerialNoAvailabilityWarning: Label 'You have insufficient quantity of Item %1 on inventory.';
        WorkDate2: Date;
        SerialNoRequiredErr: Label 'You must assign a serial number for item %1.', Comment = '%1 - Item No.';
        ExiprationDateErr: Label 'Expiration Date must be editable or uneditable based on Use Expiration Date in Item Tracking Code.';

    local procedure Initialize()
    var
        AssemblySetup: Record "Assembly Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting-D5B-ItemTracking");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting-D5B-ItemTracking");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        WorkDate2 := LibraryPlanning.SetSafetyWorkDate(); // to avoid Due Date Before Work Date message.
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card",
          LibraryUtility.GetGlobalNoSeriesCode());
        LibrarySales.SetCreditWarningsToNoWarnings();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting-D5B-ItemTracking");
    end;

    local procedure PC1_ItemTrackingOnHeader(var AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        KitItem: Record Item;
        CompItem: Record Item;
    begin
        // Standard setup with LotSerial Kit and untracked Component items
        // with IT spec assigned on header.

        Initialize();

        CreateTrackedItem(CompItem, Tracking::Untracked);
        CreateTrackedItem(KitItem, Tracking::LotSerial);

        CreateAssemblyHeader(AssemblyHeader, KitItem, LibraryRandom.RandIntInRange(100, 200));
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, 1);
        AddToInventory(CompItem, AssemblyLine.Quantity);

        AssignItemTrackingToHeader(AssemblyHeader);
    end;

    local procedure PC2_ItemTracing(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var AssemblyLine2: Record "Assembly Line"; var SalesHeader: Record "Sales Header"; Sell: Boolean)
    var
        KitItem: Record Item;
        CompItem: Record Item;
        CompItemLot: Record Item;
    begin
        Initialize();

        // Item tracing for lot- and serial tracked components, and lotserial kit item
        // Post in Item Journal
        // Post Assembly Order
        // Post a Sales Order for assembled items
        // Validate Item Tracing lines from Usage to Origin

        CreateTrackedItem(KitItem, Tracking::LotSerial);
        CreateTrackedItem(CompItem, Tracking::LotSerial);
        CreateTrackedItem(CompItemLot, Tracking::Lot);

        CreateAssemblyHeader(AssemblyHeader, KitItem, 1);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, 3 + RandomQuantity(10));
        CreateAssemblyLine(AssemblyHeader, AssemblyLine2, CompItemLot, 3 + RandomQuantity(10));

        AddToInventory(CompItem, AssemblyLine.Quantity);
        AddToInventory(CompItemLot, AssemblyLine2.Quantity);

        AssignItemTrackingToHeader(AssemblyHeader);
        SelectItemTrackingOnLines(AssemblyHeader, true);
        PostAssemblyHeader(AssemblyHeader);

        if Sell then begin
            CreateSalesHeader(SalesHeader);
            CreateSalesLineWithITSpec(SalesHeader, AssemblyHeader."Item No.", 1);
            PostSalesHeader(SalesHeader);
        end;
    end;

    local procedure PC3_ItemTracingNonITComponents(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var AssemblyLine2: Record "Assembly Line")
    var
        KitItem: Record Item;
        CompItem: Record Item;
        CompItemUntracked: Record Item;
    begin
        Initialize();

        CreateTrackedItem(KitItem, Tracking::LotSerial);
        CreateTrackedItem(CompItem, Tracking::LotSerial);
        CreateTrackedItem(CompItemUntracked, Tracking::Untracked);

        CreateAssemblyHeader(AssemblyHeader, KitItem, 1);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, RandomQuantity(20));
        CreateAssemblyLine(AssemblyHeader, AssemblyLine2, CompItemUntracked, RandomQuantity(20));

        AddToInventory(CompItem, AssemblyLine.Quantity);
        AddToInventory(CompItemUntracked, AssemblyLine2.Quantity);

        AssignItemTrackingToHeader(AssemblyHeader);
        SelectItemTrackingOnLines(AssemblyHeader, true);
        PostAssemblyHeader(AssemblyHeader);
    end;

    local procedure PC4_PartialPostHeader(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var PartialQuantity: Integer)
    var
        KitItem: Record Item;
        CompItem: Record Item;
    begin
        Initialize();

        CreateTrackedItem(KitItem, Tracking::Lot);
        CreateTrackedItem(CompItem, Tracking::Untracked);

        CreateAssemblyHeader(AssemblyHeader, KitItem, LibraryRandom.RandIntInRange(3, 20));
        PartialQuantity := LibraryRandom.RandIntInRange(1, AssemblyHeader.Quantity - 1);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, 1);
        AssemblyHeader.Validate("Quantity to Assemble", PartialQuantity);
        AssemblyHeader.Modify(true);
        AddToInventory(CompItem, AssemblyHeader.Quantity);
        AssignItemTrackingToHeader(AssemblyHeader);

        PostAssemblyHeader(AssemblyHeader);
        Reopen(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITComp_UOM()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        KitItem: Record Item;
        CompItem: Record Item;
    begin
        // 1) Create kit item with UOM
        // 2) Create AO for kit item with that UOM
        // 3) Assert that item tracking applies header UOM when tracking kits

        Initialize();

        CreateTrackedItem(CompItem, Tracking::LotSerial);
        CreateTrackedItem(KitItem, Tracking::Untracked);

        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, CompItem."No.", LibraryRandom.RandInt(3));

        CreateAssemblyHeader(AssemblyHeader, KitItem, 1);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, 1);
        AssemblyLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        AssemblyLine.Modify(true);
        AddToInventory(CompItem, ItemUnitOfMeasure."Qty. per Unit of Measure" + 1);

        SelectItemTrackingOnLines(AssemblyHeader, true);

        ValidateResEntryCountLines(AssemblyHeader, ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITComp_ExcessQuantity()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        KitItem: Record Item;
        CompItem: Record Item;
    begin
        // 1) Create AO with excess quantity to consume
        // 2) Assign item tracking
        // 3) Post

        Initialize();

        CreateTrackedItem(CompItem, Tracking::Lot);
        CreateTrackedItem(KitItem, Tracking::Untracked);

        CreateAssemblyHeader(AssemblyHeader, KitItem, 2);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, RandomQuantity(10) * 2);
        AddToInventory(CompItem, AssemblyLine.Quantity * 2);

        AssemblyHeader.Validate("Quantity to Assemble", 1);
        AssemblyHeader.Modify(true);
        SelectItemTrackingOnLines(AssemblyHeader, true);
        PostAssemblyHeader(AssemblyHeader);
        Reopen(AssemblyHeader);

        AssemblyLine.Get(AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.");
        AssemblyLine.Validate("Quantity per", AssemblyLine."Quantity per" * 2);
        AssemblyLine.Modify(true);

        SelectItemTrackingOnLines(AssemblyHeader, true);
        PostAssemblyHeader(AssemblyHeader);

        ValidateResEntryCountLines(AssemblyHeader, 0);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITComp_DeficientQuantity()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        KitItem: Record Item;
        CompItem: Record Item;
    begin
        // 1) Create AO with deficient quantity to consume
        // 2) Assign item tracking
        // 3) Post

        Initialize();

        CreateTrackedItem(CompItem, Tracking::LotSerial);
        CreateTrackedItem(KitItem, Tracking::Untracked);

        CreateAssemblyHeader(AssemblyHeader, KitItem, 1);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, RandomQuantity(20));
        AssemblyLine.Validate("Quantity to Consume", RandomQuantity(AssemblyLine."Quantity to Consume" - 2));
        AssemblyLine.Modify(true);
        AddToInventory(CompItem, AssemblyLine."Quantity to Consume");

        SelectItemTrackingOnLines(AssemblyHeader, true);

        ValidateResEntryCountLines(AssemblyHeader, AssemblyLine."Quantity to Consume");

        PostAssemblyHeader(AssemblyHeader);

        ValidateResEntryCountLines(AssemblyHeader, 0);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITComp_NonspecOutbound()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        KitItem: Record Item;
        CompItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // 1) Create non-specific item tracking code
        // 2) Create kit & component items with non-specific item tracking code
        // 3) Try to post without inbound item tracking
        // 4) Post without outbound item tracking

        Initialize();

        CreateNonSpecOutBoundITCode(ItemTrackingCode);

        LibraryInventory.CreateItem(KitItem);
        LibraryInventory.CreateItem(CompItem);
        SetItemTrackingCode(CompItem, ItemTrackingCode);

        CreateAssemblyHeader(AssemblyHeader, KitItem, RandomQuantity(10));
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, RandomQuantity(10));
        AddToInventoryLocationVariant(CompItem, AssemblyLine.Quantity, Tracking::LotSerial, '', '');

        PostAssemblyHeader(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNDL_ConfirmYes')]
    [Scope('OnPrem')]
    procedure ITComp_Availability()
    var
        KitItem: Record Item;
        CompItemLot: Record Item;
        CompItemSerial: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
    begin
        // 1) Post two Assembly Orders with same ITSpec
        // 2) Make sure that Lot/Serial Nos. are unavailable posting of second AO

        Initialize();

        // Post AO with one Serial- and one Lot No. tracked item
        CreateTrackedItem(KitItem, Tracking::Untracked);
        CreateTrackedItem(CompItemLot, Tracking::Lot);
        CreateTrackedItem(CompItemSerial, Tracking::Serial);

        CreateAssemblyHeader(AssemblyHeader, KitItem, 1);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItemLot, RandomQuantity(20));
        CreateAssemblyLine(AssemblyHeader, AssemblyLine2, CompItemSerial, RandomQuantity(20));

        AddToInventory(CompItemLot, AssemblyLine.Quantity);
        AddToInventory(CompItemSerial, AssemblyLine2.Quantity);

        AssignItemTrackingToLines(AssemblyHeader);
        PostAssemblyHeader(AssemblyHeader);

        // Try to post with the same Lot No.
        CreateAssemblyHeader(AssemblyHeader, KitItem, 1);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItemLot, AssemblyLine.Quantity);
        // Assert there is an availability warning
        AssignItemTrackingToLines(AssemblyHeader);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader,
          StrSubstNo(LotNoAvailabilityWarning, CompItemLot."No."));

        // Try to post with the same Serial No.
        CreateAssemblyHeader(AssemblyHeader, KitItem, 1);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItemSerial, AssemblyLine2.Quantity);
        // Assert there is an availability warning
        AssignItemTrackingToLines(AssemblyHeader);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader,
          StrSubstNo(SerialNoAvailabilityWarning, CompItemSerial."No."));
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITAsm_Resource()
    var
        KitItem: Record Item;
        CompItemLot: Record Item;
        CompItemSerial: Record Item;
        CompItemLotSerial: Record Item;
        Resource: Record Resource;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLineLot: Record "Assembly Line";
        AssemblyLineSerial: Record "Assembly Line";
        AssemblyLineLotSerial: Record "Assembly Line";
    begin
        // Item tracking on header and lines, in combination with a resource line

        Initialize();

        CreateTrackedItem(KitItem, Tracking::LotSerial);
        CreateTrackedItem(CompItemLot, Tracking::Lot);
        CreateTrackedItem(CompItemSerial, Tracking::Serial);
        CreateTrackedItem(CompItemLotSerial, Tracking::LotSerial);

        CreateAssemblyHeader(AssemblyHeader, KitItem, 1);
        CreateAssemblyLine(AssemblyHeader, AssemblyLineLot, CompItemLot, RandomQuantity(20));
        CreateAssemblyLine(AssemblyHeader, AssemblyLineSerial, CompItemSerial, RandomQuantity(20));
        CreateAssemblyLine(AssemblyHeader, AssemblyLineLotSerial, CompItemLotSerial, RandomQuantity(20));
        Resource.Next(LibraryRandom.RandInt(Resource.Count));
        CreateAssemblyLineResource(AssemblyHeader, Resource, RandomQuantity(20));

        AddToInventory(CompItemLot, AssemblyLineLot.Quantity);
        AddToInventory(CompItemSerial, AssemblyLineSerial.Quantity);
        AddToInventory(CompItemLotSerial, AssemblyLineLotSerial.Quantity);

        AssignItemTrackingToHeader(AssemblyHeader);
        SelectItemTrackingOnLines(AssemblyHeader, true);

        PostAssemblyHeader(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITAsm_ExpiryDate()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemTrackingCode: Record "Item Tracking Code";
        KitItem: Record Item;
        CompItem: Record Item;
    begin
        Initialize();

        CreateTrackedItem(KitItem, Tracking::Untracked);
        CreateTrackedItem(CompItem, Tracking::Serial);

        ItemTrackingCode.Get(CompItem."Item Tracking Code");
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Validate("Strict Expiration Posting", true);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", true);
        ItemTrackingCode.Modify(true);

        CreateAssemblyHeader(AssemblyHeader, KitItem, 1);
        AssemblyHeader.Validate("Posting Date", WorkDate2 + 4);
        AssemblyHeader.Modify(true);

        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, 5);

        AddToInventoryExpiryDate(CompItem, 10, WorkDate2);

        SelectItemTrackingOnLines(AssemblyHeader, true);

        asserterror PostAssemblyHeader(AssemblyHeader);
        Assert.IsTrue(StrPos(GetLastErrorText, 'Expiration Date') > 0,
          'Unexpected error message');

        Reopen(AssemblyHeader);

        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        AssemblyHeader.Validate("Posting Date", WorkDate2);
        AssemblyHeader.Modify(true);
        PostAssemblyHeader(AssemblyHeader);

        ValidateResEntryCountHeader(AssemblyHeader, 0);
        ValidateResEntryCountLines(AssemblyHeader, 0);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITAsm_UOM()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        KitItem: Record Item;
        CompItem: Record Item;
    begin
        // 1) Create kit item with UOM
        // 2) Create AO for kit item with that UOM
        // 3) Assert that UOM is applied when assigning item tracking spec to header.

        Initialize();

        CreateTrackedItem(CompItem, Tracking::Untracked);
        CreateTrackedItem(KitItem, Tracking::LotSerial);

        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, KitItem."No.", LibraryRandom.RandInt(3));

        CreateAssemblyHeader(AssemblyHeader, KitItem, 1);
        AssemblyHeader.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        AssemblyHeader.Modify(true);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, 1);
        AddToInventory(CompItem, 4);

        AssignItemTrackingToHeader(AssemblyHeader);

        ValidateResEntryCountHeader(AssemblyHeader, ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary,HNDL_MessageOK,HNDL_ConfirmYes')]
    [Scope('OnPrem')]
    procedure ITQuote_Sunshine()
    var
        KitItem: Record Item;
        CompItemUntracked: Record Item;
        CompItemLot: Record Item;
        CompItemSerial: Record Item;
        CompItemLotSerial: Record Item;
        AssemblyHeaderQuote: Record "Assembly Header";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLineUntracked: Record "Assembly Line";
        AssemblyLineLot: Record "Assembly Line";
        AssemblyLineSerial: Record "Assembly Line";
        AssemblyLineLotSerial: Record "Assembly Line";
        SalesHeaderQuote: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        Resource: Record Resource;
        SalesQuotePage: TestPage "Sales Quote";
        SalesOrderPage: TestPage "Sales Order";
    begin
        // test item tracking with assembly quotes
        Initialize();

        CreateTrackedItem(KitItem, Tracking::LotSerial);
        CreateTrackedItem(CompItemUntracked, Tracking::Untracked);
        CreateTrackedItem(CompItemLot, Tracking::Lot);
        CreateTrackedItem(CompItemSerial, Tracking::Serial);
        CreateTrackedItem(CompItemLotSerial, Tracking::LotSerial);

        CreateSalesQuote(SalesHeaderQuote);
        CreateSalesLineATO(SalesHeaderQuote, KitItem."No.", RandomQuantity(20) + 1);

        AssemblyHeaderQuote.SetRange("Item No.", KitItem."No.");
        AssemblyHeaderQuote.FindFirst();

        CreateAssemblyLine(AssemblyHeaderQuote, AssemblyLineUntracked, CompItemUntracked, RandomQuantity(20));
        CreateAssemblyLine(AssemblyHeaderQuote, AssemblyLineLot, CompItemLot, RandomQuantity(20));
        CreateAssemblyLine(AssemblyHeaderQuote, AssemblyLineSerial, CompItemSerial, RandomQuantity(20));
        CreateAssemblyLine(AssemblyHeaderQuote, AssemblyLineLotSerial, CompItemLotSerial, RandomQuantity(20));
        Resource.Next(LibraryRandom.RandInt(Resource.Count));
        CreateAssemblyLineResource(AssemblyHeaderQuote, Resource, RandomQuantity(20));

        AddToInventory(CompItemUntracked, AssemblyLineUntracked.Quantity);
        AddToInventory(CompItemLot, AssemblyLineLot.Quantity);
        AddToInventory(CompItemSerial, AssemblyLineSerial.Quantity);
        AddToInventory(CompItemLotSerial, AssemblyLineLotSerial.Quantity);

        SelectItemTrackingOnQuoteLines(AssemblyHeaderQuote, true);

        SalesOrderPage.Trap();

        SalesQuotePage.OpenEdit();
        SalesQuotePage.FILTER.SetFilter("No.", SalesHeaderQuote."No.");
        SalesQuotePage.GotoRecord(SalesHeaderQuote);
        SalesQuotePage.MakeOrder.Invoke();

        SalesOrderPage.Close();

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("External Document No.", SalesHeaderQuote."External Document No.");
        SalesHeader.FindFirst();

        AssemblyHeader.SetRange("Item No.", KitItem."No.");
        AssemblyHeader.FindFirst();

        ValidateShadowAssemblyHeader(AssemblyHeader, AssemblyHeaderQuote);
        ValidateShadowAssemblyLine(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITPost_Header()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        // Sunshine scenario with IT on header.

        PC1_ItemTrackingOnHeader(AssemblyHeader);
        PostAssemblyHeader(AssemblyHeader);

        ValidateResEntryCountHeader(AssemblyHeader, 0);
        ValidateResEntryCountLines(AssemblyHeader, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ITPost_NoITSpecHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        KitItem: Record Item;
        CompItem: Record Item;
    begin
        // Error scenario with no IT on header.

        Initialize();

        CreateTrackedItem(KitItem, Tracking::LotSerial);
        CreateTrackedItem(CompItem, Tracking::Untracked);

        CreateAssemblyHeader(AssemblyHeader, KitItem, RandomQuantity(20));
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, 1);
        AddToInventory(CompItem, AssemblyLine.Quantity);

        asserterror PostAssemblyHeader(AssemblyHeader);
        Assert.AreEqual(StrSubstNo(SerialNoRequiredErr, KitItem."No."),
          GetLastErrorText, 'Serial Number error message expected.');

        ValidateResEntryCountHeader(AssemblyHeader, 0);
        ValidateResEntryCountLines(AssemblyHeader, 0);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ITPost_HeaderAndLines()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine1: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
        KitItem: Record Item;
        CompItemSerial: Record Item;
        CompItemLot: Record Item;
    begin
        // Sunshine scenario with IT on header and lines.

        Initialize();

        CreateTrackedItem(KitItem, Tracking::LotSerial);
        CreateTrackedItem(CompItemSerial, Tracking::Serial);
        CreateTrackedItem(CompItemLot, Tracking::Lot);

        CreateAssemblyHeader(AssemblyHeader, KitItem, 1);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine1, CompItemSerial, RandomQuantity(20));
        CreateAssemblyLine(AssemblyHeader, AssemblyLine2, CompItemLot, RandomQuantity(20));

        AddToInventory(CompItemSerial, AssemblyLine1.Quantity);
        AddToInventory(CompItemLot, AssemblyLine2.Quantity);

        AssignItemTrackingToHeader(AssemblyHeader);
        SelectItemTrackingOnLines(AssemblyHeader, true);

        PostAssemblyHeader(AssemblyHeader);

        ValidateResEntryCountHeader(AssemblyHeader, 0);
        ValidateResEntryCountLines(AssemblyHeader, 0);
        ValidateItemLedgerEntryCount(AssemblyHeader,
          AssemblyLine1.Quantity + 1,
          AssemblyHeader.Quantity);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage')]
    [Scope('OnPrem')]
    procedure ITPost_PartialPostHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        KitItem: Record Item;
        CompItem: Record Item;
        PartialQuantity: Integer;
    begin
        // 1) Create AO for quantity X
        // 2) Partially post for quantity < X
        // 4) Post remaining quantity
        // 5) Check Reservation Entries & ILEs

        PC4_PartialPostHeader(AssemblyHeader, AssemblyLine, PartialQuantity);

        KitItem.Get(AssemblyHeader."Item No.");
        CompItem.Get(AssemblyLine."No.");

        ValidateResEntryCountHeader(AssemblyHeader, 1);
        ValidateResEntryCountLines(AssemblyHeader, 0);
        ValidateItemLedgerEntryCount(AssemblyHeader, 1, 1);

        PostAssemblyHeader(AssemblyHeader);

        asserterror AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");

        ValidateResEntryCountHeader(AssemblyHeader, 0);
        ValidateResEntryCountLines(AssemblyHeader, 0);
        ValidateItemLedgerEntryCount(AssemblyHeader, 2, 2);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITPost_InsufficientITSpec()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        KitItem: Record Item;
        CompItem: Record Item;
        AssemblyOrderPage: TestPage "Assembly Order";
        PartialQuantity: Integer;
    begin
        // 1) Create AO, quantity X on header
        // 2) Assign IT Spec for quantity < X
        // 3) Assert posting disallowed

        Initialize();

        CreateTrackedItem(KitItem, Tracking::LotSerial);
        CreateTrackedItem(CompItem, Tracking::Untracked);

        CreateAssemblyHeader(AssemblyHeader, KitItem, RandomQuantity(20));
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, 1);
        AddToInventory(CompItem, AssemblyLine.Quantity);

        Commit();
        AssemblyOrderPage.OpenEdit();
        AssemblyOrderPage.FILTER.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrderPage.GotoRecord(AssemblyHeader);

        PartialQuantity := RandomQuantity(AssemblyHeader.Quantity - 1);
        AssemblyOrderPage."Quantity to Assemble".Value := Format(PartialQuantity, 5);

        PrepareHandleAssignPartial(PartialQuantity - 1, Tracking::LotSerial);
        AssemblyOrderPage."Item Tracking Lines".Invoke();

        AssemblyOrderPage.OK().Invoke();

        asserterror PostAssemblyHeader(AssemblyHeader);
        Assert.ExpectedError(ErrorQtyHandle);
    end;

    local procedure ATO_ItemTrackingOnSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemTracking: Option; PartialShipment: Boolean; PositiveTest: Boolean)
    var
        KitItem: Record Item;
        CompItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // Setup.
        Initialize();

        // 1. Create tracked assembly-to-order item, and untracked component.
        CreateTrackedItem(CompItem, Tracking::Untracked);
        CreateTrackedItem(KitItem, ItemTracking);
        KitItem.Validate("Replenishment System", KitItem."Replenishment System"::Assembly);
        KitItem.Validate("Assembly Policy", KitItem."Assembly Policy"::"Assemble-to-Order");
        KitItem.Modify(true);

        // 2. Create sales document.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipment Date", WorkDate2);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, KitItem."No.", WorkDate2, LibraryRandom.RandIntInRange(10, 100));  // Take Random Quantity.

        // 3. Set relation between Qty to ship, Qty to assemble to order and Qty tracked.
        if PartialShipment then
            SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(1, SalesLine."Qty. to Assemble to Order"));
        SalesLine.Modify(true);

        // 4. Make sure posting will go through by adding component line and inventory for it.
        LibraryAssembly.FindLinkedAssemblyOrder(
          AssemblyHeader, SalesHeader."Document Type"::Order, SalesLine."Document No.", SalesLine."Line No.");
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, 1);
        AddToInventory(CompItem, AssemblyLine.Quantity);

        // 5. Exercise: Assign item tracking, partially or fully.
        AssignITToShadowAssemblyLine(AssemblyHeader, SalesLine, ItemTracking, PositiveTest);

        // 6. Validate: Reservation entries.
        ValidateTrackedQty(900, AssemblyHeader."No.", PAR_ITPage_AssignQty);

        // 7. Create demand for the kit item, other than sales line.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, CompItem."No.", '', 1, '');
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, KitItem, LibraryRandom.RandInt(10));

        // 8. Validate: Select entries does not populate the Item tracking lines page.
        SelectItemTrackingOnLines(AssemblyHeader, false);
        ValidateTrackedQty(901, AssemblyHeader."No.", 0);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ATOPartialShipPositiveLot()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        ATO_ItemTrackingOnSalesLine(SalesHeader, SalesLine, Tracking::Lot, true, true);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ATOPartialShipPositiveSerial()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        ATO_ItemTrackingOnSalesLine(SalesHeader, SalesLine, Tracking::Serial, true, true);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure ATOFullyShipPositiveLot()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        ATO_ItemTrackingOnSalesLine(SalesHeader, SalesLine, Tracking::Lot, false, true);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ATOFullyShipPositiveSerial()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        ATO_ItemTrackingOnSalesLine(SalesHeader, SalesLine, Tracking::Serial, false, true);
    end;

    [Normal]
    local procedure ATO_PostITOnSalesLine(ItemTracking: Option; PartialShipment: Boolean; PositiveTest: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
    begin
        // 1. Setup: Assign item tracking.
        ATO_ItemTrackingOnSalesLine(SalesHeader, SalesLine, ItemTracking, PartialShipment, PositiveTest);

        // 2. Exercise: Post Sales Header.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // 3. Validate: Reservation entries for the posted Sales Line and shadow Assembly Header.
        LibraryAssembly.FindLinkedAssemblyOrder(
          AssemblyHeader, SalesHeader."Document Type"::Order, SalesLine."Document No.", SalesLine."Line No.");
        ValidateTrackedQty(900, AssemblyHeader."No.", 0);

        // 4. Create demand for the kit item, other than sales line.
        LibraryInventory.CreateItem(Item);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", '', 1, '');
        Item.Get(SalesLine."No.");
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, Item, LibraryRandom.RandInt(10));

        // 5. Validate: Select entries does not populate the Item tracking lines page.
        SelectItemTrackingOnLines(AssemblyHeader, false);
        ValidateTrackedQty(901, AssemblyHeader."No.", 0);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure PostATOPartialShipPositiveLot()
    begin
        ATO_PostITOnSalesLine(Tracking::Lot, true, true);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure PostATOPtlShipPositiveSerial()
    begin
        ATO_PostITOnSalesLine(Tracking::Serial, true, true);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure PostATOPtlShipNegativeLot()
    begin
        asserterror
          ATO_PostITOnSalesLine(Tracking::Lot, true, false);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorQtyHandle) > 0, 'Actual:' + GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure PostATOPtlShipNegativeSerial()
    begin
        asserterror
          ATO_PostITOnSalesLine(Tracking::Serial, true, false);
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorQtyHandle) > 0, 'Actual:' + GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary')]
    [Scope('OnPrem')]
    procedure PostATOFullyShipPositiveLot()
    begin
        ATO_PostITOnSalesLine(Tracking::Lot, false, true);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure PostATOFullyShipPositiveSerial()
    begin
        ATO_PostITOnSalesLine(Tracking::Serial, false, true);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITTrac_ItemTracingUTO()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
        SalesHeader: Record "Sales Header";
    begin
        PC2_ItemTracing(AssemblyHeader, AssemblyLine, AssemblyLine2, SalesHeader, true);

        ValidateItemTracingLinesUTO(true, false, false,
          AssemblyHeader, AssemblyLine, AssemblyLine2, SalesHeader);
        ValidateItemTracingLinesUTO(false, true, false,
          AssemblyHeader, AssemblyLine, AssemblyLine2, SalesHeader);
        ValidateItemTracingLinesUTO(false, false, true,
          AssemblyHeader, AssemblyLine, AssemblyLine2, SalesHeader);
        ValidateItemTracingLinesUTO(true, true, true,
          AssemblyHeader, AssemblyLine, AssemblyLine2, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITTrac_ItemTracingOTU()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
        SalesHeader: Record "Sales Header";
    begin
        PC2_ItemTracing(AssemblyHeader, AssemblyLine, AssemblyLine2, SalesHeader, true);

        ValidateItemTracingLineOTUKit(AssemblyHeader, SalesHeader);
        ValidateItemTracingLineOTUComp(AssemblyHeader, AssemblyLine, SalesHeader, Tracking::Serial);
        ValidateItemTracingLineOTUComp(AssemblyHeader, AssemblyLine2, SalesHeader, Tracking::Lot);
        ValidateItemTracingLineOTUComp(AssemblyHeader, AssemblyLine, SalesHeader, Tracking::LotSerial);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITTrac_SellTwice()
    var
        KitItem: Record Item;
        CompItem: Record Item;
        CompItemLot: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemTracingPage: TestPage "Item Tracing";
    begin
        Initialize();

        CreateTrackedItem(KitItem, Tracking::LotSerial);
        CreateTrackedItem(CompItem, Tracking::LotSerial);
        CreateTrackedItem(CompItemLot, Tracking::Lot);

        CreateAssemblyHeader(AssemblyHeader, KitItem, 2);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, 3 + RandomQuantity(10));
        CreateAssemblyLine(AssemblyHeader, AssemblyLine2, CompItemLot, 3 + RandomQuantity(10));

        AddToInventory(CompItem, AssemblyLine.Quantity);
        AddToInventory(CompItemLot, AssemblyLine2.Quantity);

        AssignItemTrackingToHeader(AssemblyHeader);
        SelectItemTrackingOnLines(AssemblyHeader, true);
        PostAssemblyHeader(AssemblyHeader);

        CreateSalesHeader(SalesHeader);
        CreateSalesLineWithITSpec(SalesHeader, KitItem."No.", 1);
        PostSalesHeader(SalesHeader);

        CreateSalesHeader(SalesHeader2);
        CreateSalesLineWithITSpec(SalesHeader2, KitItem."No.", 1);
        PostSalesHeader(SalesHeader2);

        // Trace Item No.
        Commit();
        ItemTracingPage.OpenEdit();
        ItemTracingPage.ItemNoFilter.SetValue(KitItem."No.");
        ItemTracingPage.ShowComponents.SetValue('Item-tracked Only');
        ItemTracingPage.TraceMethod.SetValue('Usage -> Origin');
        ItemTracingPage.Trace.Invoke();

        // Validate
        ExpectShippedSalesOrder(ItemTracingPage, SalesHeader2, AssemblyHeader."Item No.", 1, true);
        ExpectAssemblyOutput(ItemTracingPage, AssemblyHeader, 1, false);
        ExpectShippedSalesOrder(ItemTracingPage, SalesHeader, AssemblyHeader."Item No.", 1, true);
        ExpectAssemblyOutput(ItemTracingPage, AssemblyHeader, 1, false);
        Assert.IsFalse(ItemTracingPage.Next(),
          StrSubstNo('Unexpected Item Tracing entry: "%1"', ItemTracingPage.Description.Value));

        // Trace Serial No.
        ItemLedgerEntry.SetRange("Item No.", KitItem."No.");
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        ItemLedgerEntry.SetRange("Document No.", SalesShipmentHeader."No.");
        ItemLedgerEntry.FindSet();
        ItemLedgerEntry.Next(LibraryRandom.RandInt(ItemLedgerEntry.Count));

        ItemTracingPage.SerialNoFilter.SetValue(ItemLedgerEntry."Serial No.");
        ItemTracingPage.ItemNoFilter.SetValue('');
        ItemTracingPage.ShowComponents.SetValue('Item-tracked Only');
        ItemTracingPage.TraceMethod.SetValue('Usage -> Origin');
        ItemTracingPage.Trace.Invoke();
        ItemTracingPage.First();

        // Validate
        ExpectShippedSalesOrder(ItemTracingPage, SalesHeader, AssemblyHeader."Item No.", 1, true);
        ExpectAssemblyOutput(ItemTracingPage, AssemblyHeader, 1, false);
        Assert.IsFalse(ItemTracingPage.Next(),
          StrSubstNo('Unexpected Item Tracing entry: "%1"', ItemTracingPage.Description.Value));

        ItemTracingPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITTrac_AssemblyInAssembly()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyHeader2: Record "Assembly Header";
        AssemblyLineParentKit: Record "Assembly Line";
        AssemblyLine: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
        SalesHeader: Record "Sales Header";
        KitItem: Record Item;
        KitItemParent: Record Item;
        ItemTracingPage: TestPage "Item Tracing";
    begin
        PC2_ItemTracing(AssemblyHeader, AssemblyLine, AssemblyLine2, SalesHeader, false);

        KitItem.Get(AssemblyHeader."Item No.");
        CreateTrackedItem(KitItemParent, Tracking::LotSerial);

        CreateAssemblyHeader(AssemblyHeader2, KitItemParent, 1);
        CreateAssemblyLine(AssemblyHeader2, AssemblyLineParentKit, KitItem, 1);
        SelectItemTrackingOnLines(AssemblyHeader2, true);
        AssignItemTrackingToHeader(AssemblyHeader2);
        PostAssemblyHeader(AssemblyHeader2);

        Commit();
        ItemTracingPage.OpenEdit();
        ItemTracingPage.ItemNoFilter.SetValue(KitItemParent."No.");
        ItemTracingPage.TraceMethod.SetValue('Usage -> Origin');
        ItemTracingPage.ShowComponents.SetValue('All');
        ItemTracingPage.Trace.Invoke();

        ExpectAssemblyOutput(ItemTracingPage, AssemblyHeader2, 1, true);
        ExpectAssemblyConsumption(ItemTracingPage, AssemblyHeader2, AssemblyLineParentKit, 1, true);
        ExpectAssemblyOutput(ItemTracingPage, AssemblyHeader, 1, false);

        Assert.IsFalse(ItemTracingPage.Next(),
          StrSubstNo('Unexpected Item Tracing entry: "%1"', ItemTracingPage.Description.Value));

        ItemTracingPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITTrac_ShowComponentsAll()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
    begin
        PC3_ItemTracingNonITComponents(AssemblyHeader, AssemblyLine, AssemblyLine2);
        ValidateShowComponents(AssemblyHeader, AssemblyLine, AssemblyLine2, true, true);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITTrac_ShowComponentsITOnly()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
    begin
        PC3_ItemTracingNonITComponents(AssemblyHeader, AssemblyLine, AssemblyLine2);
        ValidateShowComponents(AssemblyHeader, AssemblyLine, AssemblyLine2, true, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITTrac_ShowComponentsNo()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
    begin
        PC3_ItemTracingNonITComponents(AssemblyHeader, AssemblyLine, AssemblyLine2);
        ValidateShowComponents(AssemblyHeader, AssemblyLine, AssemblyLine2, false, false);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNLD_ItemTrackingSummary,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITTrac_NavigatePostedAO()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
        SalesHeader: Record "Sales Header";
        NavigatePage: TestPage Navigate;
    begin
        PC2_ItemTracing(AssemblyHeader, AssemblyLine, AssemblyLine2, SalesHeader, true);

        NavigateFindSerial(NavigatePage, AssemblyHeader);
        NavigateExpect(NavigatePage, 'Item Ledger Entry', 2);
        NavigateExpect(NavigatePage, 'Sales Shipment Header', 1);
        NavigateExpect(NavigatePage, 'Sales Invoice Header', 1);
        NavigateExpect(NavigatePage, 'Posted Assembly Header', 1);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITTrac_NavigateUnpostedAO()
    var
        AssemblyHeader: Record "Assembly Header";
        NavigatePage: TestPage Navigate;
    begin
        PC1_ItemTrackingOnHeader(AssemblyHeader);

        NavigateFindLot(NavigatePage, AssemblyHeader);
        NavigateExpect(NavigatePage, 'Reservation Entry', AssemblyHeader.Quantity);
        NavigateExpect(NavigatePage, 'Assembly Header', 1);
    end;

    [Test]
    [HandlerFunctions('HNDL_ITPage,HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure ITTrac_NavigatePartialAO()
    var
        KitItem: Record Item;
        CompItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        NavigatePage: TestPage Navigate;
    begin
        Initialize();
        CreateTrackedItem(KitItem, Tracking::LotSerial);
        CreateTrackedItem(CompItem, Tracking::Untracked);

        CreateAssemblyHeader(AssemblyHeader, KitItem, RandomQuantity(10) + 1);
        CreateAssemblyLine(AssemblyHeader, AssemblyLine, CompItem, RandomQuantity(20));
        AddToInventory(CompItem, AssemblyLine.Quantity);

        AssemblyHeader.Validate("Quantity to Assemble", RandomQuantity(AssemblyHeader.Quantity - 1));
        AssemblyHeader.Modify(true);

        AssignPartItemTrackingToHeader(AssemblyHeader);
        PostAssemblyHeader(AssemblyHeader);

        NavigateFindLot(NavigatePage, AssemblyHeader);
        NavigateExpect(NavigatePage, 'Item Ledger Entry', AssemblyHeader."Quantity to Assemble");
        NavigateExpect(NavigatePage, 'Posted Assembly Header', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ITTrac_NavigateIllegalSN()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        NavigatePage: TestPage Navigate;
    begin
        Initialize();
        NavigatePage.OpenEdit();
        NavigatePage.SerialNoFilter.SetValue(
          LibraryUtility.GenerateRandomCode(ItemLedgerEntry.FieldNo("Serial No."), DATABASE::"Item Ledger Entry"));
        NavigatePage.Find.Invoke();
        Assert.IsFalse(NavigatePage.Next(),
          'Unexpected navigate entry');
    end;

    [Test]
    procedure ExiprationDateMustBeEditableConditionally()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournal: TestPage "Item Journal";
    begin
        // [SCENARIO 542207] Expiration dates for Item should be Editable Conditionally using Use Expiration Dates from Item Tracking Code.
        Initialize();

        // [GIVEN] Create Item Tracking Code and Validate Use Expiration Dates.
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Assign Item Tracking Code to Item.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Setup Item Journal.
        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);

        // [GIVEN] Clear all previous data.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        // [GIVEN] Validate Item Tracking on Lines in Item Journal Batch.
        ItemJournalBatch.Validate("Item Tracking on Lines", true);
        ItemJournalBatch.Modify(true);

        // [GIVEN] Create Item Journal Line.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase,
          Item."No.",
          LibraryRandom.RandInt(5));

        // [WHEN] Go to Item Journal.
        ItemJournal.OpenEdit();
        ItemJournal.GoToRecord(ItemJournalLine);

        // [THEN] Expiration Date must be Editable.
        Assert.IsTrue(ItemJournal."Expiration Date".Editable(), ExiprationDateErr);

        // [GIVEN] Close Item Journal and Validate Use Expiration Dates.
        ItemJournal.Close();
        ItemTrackingCode.Validate("Use Expiration Dates", false);
        ItemTrackingCode.Modify(true);

        // [WHEN] Go to Item Journal.
        ItemJournal.OpenEdit();
        ItemJournal.GoToRecord(ItemJournalLine);

        // [THEN] Expiration Date must be Uneditable.
        Assert.IsFalse(ItemJournal."Expiration Date".Editable(), ExiprationDateErr);
    end;

    local procedure CreateTrackedItem(var Item: Record Item; TrackingType: Option)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemTrackingCode(ItemTrackingCode, IsLot(TrackingType), IsSerial(TrackingType));
        SetItemTrackingCode(Item, ItemTrackingCode);
    end;

    local procedure SetItemTrackingCode(var Item: Record Item; ItemTrackingCode: Record "Item Tracking Code")
    begin
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure PrepareHandleSelectEntries(RowsExpected: Boolean)
    begin
        GLB_ITPageHandler := GLB_ITPageHandler::SelectITSpec;
        PAR_ITSummaryPage_RowsExpected := RowsExpected;
    end;

    local procedure PrepareHandleAssign(TrackingType: Option)
    begin
        GLB_ITPageHandler := GLB_ITPageHandler::AssignITSpec;
        PAR_ITPage_AssignLot := IsLot(TrackingType);
        PAR_ITPage_AssignSerial := IsSerial(TrackingType);
        PAR_ITPage_AssignPartial := false;
    end;

    local procedure PrepareHandleAssignPartial(Quantity: Integer; TrackingType: Option)
    begin
        GLB_ITPageHandler := GLB_ITPageHandler::AssignITSpecPartial;
        PAR_ITPage_AssignLot := IsLot(TrackingType);
        PAR_ITPage_AssignSerial := IsSerial(TrackingType);
        PAR_ITPage_AssignPartial := true;
        PAR_ITPage_AssignQty := Quantity;
    end;

    local procedure PrepareHandleITFromILEs(ItemNo: Code[20]; Quantity: Integer)
    begin
        GLB_ITPageHandler := GLB_ITPageHandler::FromILEs;
        PAR_ITPage_AssignQty := Quantity;
        PAR_ITPage_ItemNo := ItemNo;
    end;

    local procedure CreateAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; Item: Record Item; Quantity: Integer)
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", '', Quantity, '');
    end;

    local procedure CreateAssemblyLine(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; Item: Record Item; Quantity: Integer)
    begin
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.",
          LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Item, Item."No.", true),
          Quantity, 0, '');

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.FindLast();
    end;

    local procedure CreateAssemblyLineResource(var AssemblyHeader: Record "Assembly Header"; Resource: Record Resource; Quantity: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Resource, Resource."No.",
          LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Resource, Resource."No.", true),
          Quantity, 0, '');
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Lot: Boolean; Serial: Boolean)
    begin
        if not ItemTrackingCode.Get(Serial) then begin
            ItemTrackingCode.Init();
            ItemTrackingCode.Validate(Code,
              LibraryUtility.GenerateRandomCode(ItemTrackingCode.FieldNo(Code), DATABASE::"Item Tracking Code"));
            ItemTrackingCode.Insert(true);
            ItemTrackingCode.Validate("SN Specific Tracking", Serial);
            ItemTrackingCode.Validate("Lot Specific Tracking", Lot);
            ItemTrackingCode.Modify(true);
        end;
    end;

    local procedure PostAssemblyHeader(var AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    local procedure AssignItemTrackingToHeader(var AssemblyHeader: Record "Assembly Header")
    var
        AssemblyOrderPage: TestPage "Assembly Order";
    begin
        Commit();
        AssemblyOrderPage.OpenEdit();
        AssemblyOrderPage.FILTER.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrderPage.GotoRecord(AssemblyHeader);

        PrepareHandleAssign(ItemTrackingType(AssemblyHeader."Item No."));
        AssemblyOrderPage."Item Tracking Lines".Invoke();
        AssemblyOrderPage.OK().Invoke();
    end;

    local procedure AssignPartItemTrackingToHeader(var AssemblyHeader: Record "Assembly Header")
    var
        AssemblyOrderPage: TestPage "Assembly Order";
    begin
        Commit();
        AssemblyOrderPage.OpenEdit();
        AssemblyOrderPage.FILTER.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrderPage.GotoRecord(AssemblyHeader);

        PrepareHandleAssignPartial(AssemblyHeader."Quantity to Assemble", ItemTrackingType(AssemblyHeader."Item No."));
        AssemblyOrderPage."Item Tracking Lines".Invoke();
        AssemblyOrderPage.OK().Invoke();
    end;

    local procedure AssignITToShadowAssemblyLine(var AssemblyHeader: Record "Assembly Header"; var SalesLine: Record "Sales Line"; TrackingType: Option; PositiveTest: Boolean)
    var
        AssemblyOrderPage: TestPage "Assembly Order";
    begin
        if PositiveTest then
            PrepareHandleAssignPartial(SalesLine."Qty. to Ship", TrackingType)
        else
            PrepareHandleAssignPartial(LibraryRandom.RandIntInRange(1, SalesLine."Qty. to Ship"), TrackingType);

        AssemblyOrderPage.OpenEdit();
        AssemblyOrderPage.FILTER.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrderPage.GotoRecord(AssemblyHeader);
        AssemblyOrderPage."Item Tracking Lines".Invoke();
        AssemblyOrderPage.OK().Invoke();
    end;

    local procedure AssignItemTrackingToLines(var AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyOrderPage: TestPage "Assembly Order";
    begin
        Commit();
        AssemblyOrderPage.OpenEdit();
        AssemblyOrderPage.FILTER.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrderPage.GotoRecord(AssemblyHeader);

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.FindFirst();

        repeat
            if AssemblyOrderPage.Lines.Type.Value = 'Item' then begin
                PrepareHandleITFromILEs(
                  AssemblyOrderPage.Lines."No.".Value,
                  AssemblyOrderPage.Lines.Quantity.AsInteger());
                AssemblyOrderPage.Lines."Item Tracking Lines".Invoke();
            end;
        until not AssemblyOrderPage.Lines.Next();

        AssemblyOrderPage.Close();
    end;

    local procedure SelectItemTrackingOnLines(var AssemblyHeader: Record "Assembly Header"; RowsExpected: Boolean)
    var
        AssemblyOrderPage: TestPage "Assembly Order";
    begin
        Commit();
        AssemblyOrderPage.OpenEdit();
        AssemblyOrderPage.FILTER.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrderPage.GotoRecord(AssemblyHeader);

        repeat
            if (AssemblyOrderPage.Lines.Type.Value = 'Item') and (AssemblyOrderPage.Lines."No.".Value <> '') then
                if ItemTrackingType(AssemblyOrderPage.Lines."No.".Value) <> Tracking::Untracked then begin
                    PrepareHandleSelectEntries(RowsExpected);
                    AssemblyOrderPage.Lines."Item Tracking Lines".Invoke();
                end;
        until not AssemblyOrderPage.Lines.Next();
        AssemblyOrderPage.OK().Invoke();
    end;

    local procedure SelectItemTrackingOnQuoteLines(var AssemblyHeader: Record "Assembly Header"; RowsExpected: Boolean)
    var
        AssemblyQuotePage: TestPage "Assembly Quote";
    begin
        Commit();
        AssemblyQuotePage.OpenEdit();
        AssemblyQuotePage.FILTER.SetFilter("No.", AssemblyHeader."No.");
        AssemblyQuotePage.GotoRecord(AssemblyHeader);

        repeat
            if (AssemblyQuotePage.Lines.Type.Value = 'Item') and (AssemblyQuotePage.Lines."No.".Value <> '') then
                if ItemTrackingType(AssemblyQuotePage.Lines."No.".Value) <> Tracking::Untracked then begin
                    PrepareHandleSelectEntries(RowsExpected);
                    AssemblyQuotePage.Lines."Item Tracking Lines".Invoke();
                end;
        until not AssemblyQuotePage.Lines.Next();
        AssemblyQuotePage.OK().Invoke();
    end;

    local procedure SelectItemTrackingOnSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        SalesOrderPage: TestPage "Sales Order";
    begin
        Commit();
        SalesOrderPage.OpenEdit();
        SalesOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrderPage.GotoRecord(SalesHeader);

        while SalesOrderPage.SalesLines."No.".Value <> SalesLine."No." do
            SalesOrderPage.SalesLines.Next();

        PrepareHandleSelectEntries(true);
        SalesOrderPage.SalesLines.ItemTrackingLines.Invoke();
        SalesOrderPage.OK().Invoke();
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
    end;

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');
    end;

    local procedure CreateSalesLineWithITSpec(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SelectItemTrackingOnSalesLine(SalesHeader, SalesLine);
    end;

    local procedure CreateSalesLineATO(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Qty. to Assemble to Order", Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CreateNonSpecOutBoundITCode(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingCode.Init();
        ItemTrackingCode.Validate(Code,
          LibraryUtility.GenerateRandomCode(ItemTrackingCode.FieldNo(Code), DATABASE::"Item Tracking Code"));
        ItemTrackingCode.Insert(true);

        ItemTrackingCode.Validate("SN Specific Tracking", true);
        ItemTrackingCode.Validate("SN Specific Tracking", false);
        ItemTrackingCode.Validate("SN Assembly Outbound Tracking", false);

        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Validate("Lot Specific Tracking", false);
        ItemTrackingCode.Validate("Lot Assembly Outbound Tracking", false);

        ItemTrackingCode.Modify(true);
    end;

    local procedure PostSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure ItemTrackingType(ItemNo: Code[20]): Integer
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Lot: Boolean;
        Serial: Boolean;
    begin
        Item.Get(ItemNo);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        Serial := ItemTrackingCode."SN Specific Tracking";
        Lot := ItemTrackingCode."Lot Specific Tracking";

        if Lot and Serial then
            exit(Tracking::LotSerial);
        if (not Lot) and (not Serial) then
            exit(Tracking::Untracked);
        if Lot then
            exit(Tracking::Lot);
        exit(Tracking::Serial);
    end;

    local procedure IsLot(TrackingType: Option): Boolean
    begin
        exit((TrackingType = Tracking::LotSerial) or (TrackingType = Tracking::Lot));
    end;

    local procedure IsSerial(TrackingType: Option): Boolean
    begin
        exit((TrackingType = Tracking::LotSerial) or (TrackingType = Tracking::Serial));
    end;

    local procedure Reopen(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyOrderPage: TestPage "Assembly Order";
    begin
        Commit();
        AssemblyOrderPage.OpenEdit();
        AssemblyOrderPage.FILTER.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrderPage.GotoRecord(AssemblyHeader);
        AssemblyOrderPage."Re&open".Invoke();
        AssemblyOrderPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNDL_ITPage(var ItemTrackingLinesPage: TestPage "Item Tracking Lines")
    begin
        case GLB_ITPageHandler of
            GLB_ITPageHandler::AssignITSpec:
                if PAR_ITPage_AssignSerial then
                    HNDL_ITPage_AssignSerial(ItemTrackingLinesPage)
                else
                    HNDL_ITPage_AssignLot(ItemTrackingLinesPage);
            GLB_ITPageHandler::SelectITSpec:
                HNDL_ITPage_SelectEntries(ItemTrackingLinesPage);
            GLB_ITPageHandler::AssignITSpecPartial:
                if PAR_ITPage_AssignSerial then
                    HNDL_ITPage_AssignSerial(ItemTrackingLinesPage)
                else
                    HNDL_ITPage_AssignLotPartial(ItemTrackingLinesPage);
            GLB_ITPageHandler::FromILEs:
                HNDL_ITPage_FromILEs(ItemTrackingLinesPage);
        end
    end;

    [ModalPageHandler]
    [HandlerFunctions('HNDL_EnterQty')]
    [Scope('OnPrem')]
    procedure HNDL_ITPage_AssignSerial(var ItemTrackingLinesPage: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLinesPage."Assign Serial No.".Invoke();
        ItemTrackingLinesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNDL_ITPage_AssignLot(var ItemTrackingLinesPage: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLinesPage."Assign Lot No.".Invoke();
        ItemTrackingLinesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNDL_ITPage_AssignLotPartial(var ItemTrackingLinesPage: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLinesPage."Assign Lot No.".Invoke();
        ItemTrackingLinesPage."Quantity (Base)".SetValue(PAR_ITPage_AssignQty);
        ItemTrackingLinesPage."Qty. to Handle (Base)".SetValue(PAR_ITPage_AssignQty);
        ItemTrackingLinesPage."Qty. to Invoice (Base)".SetValue(PAR_ITPage_AssignQty);
        ItemTrackingLinesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNDL_ITPage_SelectEntries(var ItemTrackingLinesPage: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLinesPage."Select Entries".Invoke();
        ItemTrackingLinesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNDL_ITPage_FromILEs(var ItemTrackingLinesPage: TestPage "Item Tracking Lines")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        i: Integer;
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", PAR_ITPage_ItemNo);
        if not ItemLedgerEntry.FindSet() then
            exit;

        ItemTrackingLinesPage.New();

        if IsSerial(ItemTrackingType(PAR_ITPage_ItemNo)) then begin
            Assert.IsTrue(ItemLedgerEntry.Count >= PAR_ITPage_AssignQty,
              'To few available ILEs to assign item tracking');
            for i := 1 to PAR_ITPage_AssignQty do begin
                ItemTrackingLinesPage."Serial No.".SetValue(ItemLedgerEntry."Serial No.");
                ItemTrackingLinesPage."Lot No.".SetValue(ItemLedgerEntry."Lot No.");
                ItemTrackingLinesPage."Quantity (Base)".SetValue(1);
                ItemTrackingLinesPage.Next();
                ItemTrackingLinesPage.New();
                ItemLedgerEntry.Next();
            end
        end else
            if IsLot(ItemTrackingType(PAR_ITPage_ItemNo)) then begin
                ItemTrackingLinesPage."Lot No.".SetValue(ItemLedgerEntry."Lot No.");
                ItemTrackingLinesPage."Quantity (Base)".SetValue(PAR_ITPage_AssignQty);
            end;

        ItemTrackingLinesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNDL_EnterQty(var EnterQuantityPage: TestPage "Enter Quantity to Create")
    begin
        if PAR_ITPage_AssignLot then
            EnterQuantityPage.CreateNewLotNo.Value := 'yes';
        if PAR_ITPage_AssignPartial then
            EnterQuantityPage.QtyToCreate.Value := Format(PAR_ITPage_AssignQty, 5);
        EnterQuantityPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HNLD_ItemTrackingSummary(var ItemTrackingSummaryPage: TestPage "Item Tracking Summary")
    var
        "count": Integer;
    begin
        // Is there at least a line on the summary entry page?
        ItemTrackingSummaryPage.First();
        if ((ItemTrackingSummaryPage."Lot No.".Value <> '') or (ItemTrackingSummaryPage."Serial No.".Value <> '')) and
           (ItemTrackingSummaryPage."Total Quantity".AsInteger() <> 0)
        then
            count += 1;

        while ItemTrackingSummaryPage.Next() do
            if ItemTrackingSummaryPage."Total Quantity".AsInteger() <> 0 then
                count += 1;

        Assert.IsTrue(
          ((not PAR_ITSummaryPage_RowsExpected) and (count = 0)) or
          (PAR_ITSummaryPage_RowsExpected and (count <> 0)),
          StrSubstNo('Actual rows on entry summary: %1. Tracking info,Lot: %2 Serial: %3 Total: %4',
            count,
            ItemTrackingSummaryPage."Lot No.".Value,
            ItemTrackingSummaryPage."Serial No.".Value,
            ItemTrackingSummaryPage."Total Quantity".Value));

        if count > 0 then
            ItemTrackingSummaryPage.OK().Invoke()
        else
            ItemTrackingSummaryPage.Cancel().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HNDL_ConfirmYes(_: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HNDL_MessageOK(_: Text[1024])
    begin
    end;

    local procedure AddToInventory(Item: Record Item; Quantity: Integer)
    begin
        AddToInventoryLocationVariant(Item, Quantity, ItemTrackingType(Item."No."), '', '');
    end;

    local procedure AddToInventoryExpiryDate(Item: Record Item; Quantity: Integer; StartDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalPage: TestPage "Item Journal";
    begin
        ItemJournalLine.DeleteAll();
        Commit();

        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase,
          Item."No.",
          Quantity);

        Commit();

        ItemJournalPage.OpenEdit();

        PrepareHandleAssign(Tracking::Serial);

        ItemJournalPage.ItemTrackingLines.Invoke();
        ItemJournalPage.OK().Invoke();

        ReservationEntry.SetRange("Source Type", 83);
        ReservationEntry.SetRange("Source ID", ItemJournalLine."Journal Template Name");
        ReservationEntry.Find('-');

        Assert.AreEqual(Quantity, ReservationEntry.Count, '');

        repeat
            ReservationEntry.Validate("Expiration Date", StartDate);
            ReservationEntry.Modify(true);
            StartDate := StartDate + 1;
        until ReservationEntry.Next() = 0;

        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name",
          ItemJournalLine."Journal Batch Name");
    end;

    local procedure AddToInventoryLocationVariant(Item: Record Item; Quantity: Integer; TrackingType: Option; LocationCode: Code[10]; VariantCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalPage: TestPage "Item Journal";
    begin
        ItemJournalLine.DeleteAll();
        Commit();

        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name,
          ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          Item."No.",
          Quantity);

        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Modify(true);

        Commit();
        ItemJournalPage.OpenEdit();

        if TrackingType <> Tracking::Untracked then begin
            PrepareHandleAssign(TrackingType);
            ItemJournalPage.ItemTrackingLines.Invoke();
        end;

        ItemJournalPage.OK().Invoke();

        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name",
          ItemJournalLine."Journal Batch Name");
    end;

    local procedure RandomQuantity(Quantity: Integer): Integer
    begin
        exit(LibraryRandom.RandInt(Quantity - 1) + 1);
    end;

    local procedure ValidateResEntryCountHeader(AssemblyHeader: Record "Assembly Header"; ExpectedQty: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", 900);
        ReservationEntry.SetRange("Source ID", AssemblyHeader."No.");
        Assert.AreEqual(ExpectedQty, ReservationEntry.Count,
          'Missing or unexpected reservation entries on Assembly Header');
    end;

    local procedure ValidateResEntryCountLine(var AssemblyLine: Record "Assembly Line"; ExpectedQty: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", 901);
        ReservationEntry.SetRange("Source ID", AssemblyLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", AssemblyLine."Line No.");

        Assert.AreEqual(ExpectedQty, ReservationEntry.Count,
          StrSubstNo('Missing or unexpected reservation entries in Assembly line: %1', AssemblyLine));
    end;

    local procedure ValidateResEntryCountLines(AssemblyHeader: Record "Assembly Header"; ExpectedQty: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", 901);
        ReservationEntry.SetRange("Source ID", AssemblyHeader."No.");
        Assert.AreEqual(ExpectedQty, ReservationEntry.Count,
          'Missing or unexpected reservation entries');
    end;

    local procedure ValidateItemLedgerEntryCount(AssemblyHeader: Record "Assembly Header"; ExpectedConsumption: Integer; ExpectedOutput: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Assembly);
        ItemLedgerEntry.SetRange("Order No.", AssemblyHeader."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Assembly Consumption");
        Assert.AreEqual(ExpectedConsumption, ItemLedgerEntry.Count,
          'Missing or unexpected item ledger entries');

        Clear(ItemLedgerEntry);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Assembly);
        ItemLedgerEntry.SetRange("Order No.", AssemblyHeader."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Assembly Output");
        Assert.AreEqual(ExpectedOutput, ItemLedgerEntry.Count,
          'Missing or unexpected item ledger entries');
    end;

    local procedure ValidateTrackedQty(SourceType: Integer; SourceID: Code[20]; ExpectedQty: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
        ActualQty: Decimal;
    begin
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange(Positive, true);
        ReservationEntry.SetFilter("Item Tracking", '<>%1', ReservationEntry."Item Tracking"::None);
        ActualQty := 0;

        if ReservationEntry.FindSet() then
            repeat
                ActualQty += ReservationEntry."Quantity (Base)";
            until ReservationEntry.Next() = 0;

        Assert.AreEqual(ExpectedQty, ActualQty, 'Tracked Qty mismatch for ' + Format(SourceID));
    end;

    local procedure ValidateItemTracingLinesUTO(SetLotNo: Boolean; SetSerialNo: Boolean; SetItemNo: Boolean; AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line"; AssemblyLine2: Record "Assembly Line"; SalesHeader: Record "Sales Header")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTracingPage: TestPage "Item Tracing";
        KitItem: Code[20];
        i: Integer;
    begin
        KitItem := AssemblyHeader."Item No.";

        Commit();
        ItemTracingPage.OpenEdit();

        ItemLedgerEntry.SetRange("Item No.", KitItem);
        ItemLedgerEntry.FindFirst();

        if SetSerialNo then
            ItemTracingPage.SerialNoFilter.SetValue(ItemLedgerEntry."Serial No.");
        if SetLotNo then
            ItemTracingPage.LotNoFilter.SetValue(ItemLedgerEntry."Lot No.");
        if SetItemNo then
            ItemTracingPage.ItemNoFilter.SetValue(AssemblyHeader."Item No.");

        ItemTracingPage.Trace.Invoke();

        ExpectShippedSalesOrder(ItemTracingPage, SalesHeader, KitItem, 1, true);
        ExpectAssemblyOutput(ItemTracingPage, AssemblyHeader, 1, true);
        for i := 1 to AssemblyLine.Quantity do begin
            ExpectAssemblyConsumption(ItemTracingPage, AssemblyHeader, AssemblyLine, 1, true);
            ExpectILE(ItemTracingPage, AssemblyLine, 1, false);
        end;
        ExpectAssemblyConsumption(ItemTracingPage, AssemblyHeader, AssemblyLine2, AssemblyLine2.Quantity, true);
        ExpectILE(ItemTracingPage, AssemblyLine2, AssemblyLine2.Quantity, false);

        Assert.IsFalse(ItemTracingPage.Next(),
          'Unexpected Item Tracing entries');
    end;

    local procedure ValidateItemTracingLineOTUKit(AssemblyHeader: Record "Assembly Header"; SalesHeader: Record "Sales Header")
    var
        ItemTracingPage: TestPage "Item Tracing";
    begin
        Commit();
        ItemTracingPage.OpenEdit();
        ItemTracingPage.ItemNoFilter.SetValue(AssemblyHeader."Item No.");
        ItemTracingPage.ShowComponents.SetValue('All');
        ItemTracingPage.TraceMethod.SetValue('Origin -> Usage');
        ItemTracingPage.Trace.Invoke();

        ExpectAssemblyOutput(ItemTracingPage, AssemblyHeader, AssemblyHeader.Quantity, true);
        ExpectShippedSalesOrder(ItemTracingPage, SalesHeader, AssemblyHeader."Item No.", AssemblyHeader.Quantity, false);

        Assert.IsFalse(ItemTracingPage.Next(),
          'Unexpected Item Tracing entry');

        ItemTracingPage.OK().Invoke();
    end;

    local procedure ValidateItemTracingLineOTUComp(AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line"; SalesHeader: Record "Sales Header"; TrackingType: Option)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTracingPage: TestPage "Item Tracing";
        Quantity: Integer;
    begin
        Commit();
        ItemTracingPage.OpenEdit();
        ItemTracingPage.ShowComponents.SetValue('All');
        ItemTracingPage.TraceMethod.SetValue('Origin -> Usage');
        ItemTracingPage.ShowComponents.SetValue('No');

        ItemLedgerEntry.SetRange("Item No.", AssemblyLine."No.");
        ItemLedgerEntry.FindSet();
        ItemLedgerEntry.Next(LibraryRandom.RandInt(ItemLedgerEntry.Count));

        if IsSerial(TrackingType) then begin
            ItemTracingPage.SerialNoFilter.SetValue(ItemLedgerEntry."Serial No.");
            Quantity := 1;
        end else
            if IsLot(TrackingType) then begin
                ItemTracingPage.LotNoFilter.SetValue(ItemLedgerEntry."Lot No.");
                Quantity := AssemblyLine.Quantity;
            end;

        ItemTracingPage.Trace.Invoke();

        ExpectILE(ItemTracingPage, AssemblyLine, Quantity, true);
        ExpectAssemblyConsumption(ItemTracingPage, AssemblyHeader, AssemblyLine, Quantity, true);
        ExpectAssemblyOutput(ItemTracingPage, AssemblyHeader, 1, true);
        ExpectShippedSalesOrder(ItemTracingPage, SalesHeader, AssemblyHeader."Item No.", 1, false);

        Assert.IsFalse(ItemTracingPage.Next(),
          StrSubstNo('Unexpected Item Tracing entry %1', ItemTracingPage.Description.Value));

        ItemTracingPage.OK().Invoke();
    end;

    local procedure ValidateShowComponents(AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line"; AssemblyLine2: Record "Assembly Line"; ShowITComp: Boolean; ShowNonITComp: Boolean)
    var
        ItemTracingPage: TestPage "Item Tracing";
        i: Integer;
    begin
        Commit();
        ItemTracingPage.OpenEdit();

        if ShowITComp and ShowNonITComp then
            ItemTracingPage.ShowComponents.SetValue('All')
        else
            if (not ShowITComp) and (not ShowNonITComp) then
                ItemTracingPage.ShowComponents.SetValue('No')
            else
                ItemTracingPage.ShowComponents.SetValue('Item-tracked Only');

        ItemTracingPage.ItemNoFilter.SetValue(AssemblyHeader."Item No.");
        ItemTracingPage.TraceMethod.SetValue('Usage -> Origin');
        ItemTracingPage.Trace.Invoke();

        ExpectAssemblyOutput(ItemTracingPage, AssemblyHeader, 1, ShowITComp);
        if ShowITComp then
            for i := 1 to AssemblyLine.Quantity do
                ExpectAssemblyConsumption(ItemTracingPage, AssemblyHeader, AssemblyLine, 1, false);

        if ShowNonITComp then
            ExpectAssemblyConsumption(ItemTracingPage, AssemblyHeader, AssemblyLine2, AssemblyLine2.Quantity, false);

        Assert.IsFalse(ItemTracingPage.Next(),
          StrSubstNo('Unexpected Item Tracing entry %1', ItemTracingPage.Description.Value));

        ItemTracingPage.OK().Invoke();
    end;

    local procedure ValidateShadowAssemblyHeader(AssemblyHeader: Record "Assembly Header"; AssemblyHeaderQuote: Record "Assembly Header")
    begin
        Assert.AreEqual(AssemblyHeaderQuote."Item No.", AssemblyHeader."Item No.",
          'Mismatch in Item No. on Assembly Order created from Assembly Quote');
        Assert.AreEqual(AssemblyHeaderQuote.Description, AssemblyHeader.Description,
          'Mismatch in Description on Assembly Order created from Assembly Quote');
        Assert.AreEqual(AssemblyHeaderQuote.Quantity, AssemblyHeader.Quantity,
          'Mismatch in Quantity on Assembly Order created from Assembly Quote');
        Assert.AreEqual(AssemblyHeaderQuote."Quantity to Assemble", AssemblyHeader.Quantity,
          'Mismatch in Quantity to Assembly on Assembly Order created from Assembly Quote');
        Assert.AreEqual(AssemblyHeaderQuote."Assemble to Order", AssemblyHeader."Assemble to Order",
          'Mismatch in ''Assemble to Order'' on Assembly Order created from Assembly Quote');
    end;

    local procedure ValidateShadowAssemblyLine(var AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.FindSet();
        repeat
            Item.Get(AssemblyLine."No.");
            ItemTrackingCode.Get(Item."Item Tracking Code");
            if ItemTrackingCode."SN Specific Tracking" then
                ValidateResEntryCountLine(AssemblyLine, AssemblyLine.Quantity)
            else
                if ItemTrackingCode."Lot Specific Tracking" then
                    ValidateResEntryCountLine(AssemblyLine, 1);
        until AssemblyLine.Next() = 0;
    end;

    local procedure ExpectShippedSalesOrder(var ItemTracingPage: TestPage "Item Tracing"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Integer; Expand: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("External Document No.", SalesHeader."External Document No.");
        SalesShipmentHeader.FindFirst();

        Assert.AreEqual(
          ItemTracingPage.Description.Value,
          StrSubstNo('Sales Shipment Header %1', SalesShipmentHeader."No."),
          'Unexpected Item Tracing entry type.');

        ItemTracingPage."Item No.".AssertEquals(ItemNo);
        ItemTracingPage.Quantity.AssertEquals(-Quantity);

        if Expand then
            ItemTracingPage.Expand(true);
        ItemTracingPage.Next();
    end;

    local procedure ExpectAssemblyOutput(var ItemTracingPage: TestPage "Item Tracing"; AssemblyHeader: Record "Assembly Header"; Quantity: Integer; Expand: Boolean)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAssemblyHeader.FindFirst();

        Assert.AreEqual(
          ItemTracingPage.Description.Value,
          StrSubstNo('Assembly Output %1', PostedAssemblyHeader."No."),
          'Unexpected Item Tracing entry type.');
        ItemTracingPage."Item No.".AssertEquals(AssemblyHeader."Item No.");
        ItemTracingPage.Quantity.AssertEquals(Quantity);

        if Expand then
            ItemTracingPage.Expand(true);
        if (not Expand) and ItemTracingPage.IsExpanded then
            ItemTracingPage.Expand(false);
        ItemTracingPage.Next();
    end;

    local procedure ExpectAssemblyConsumption(var ItemTracingPage: TestPage "Item Tracing"; AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line"; Quantity: Integer; Expand: Boolean)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAssemblyHeader.FindFirst();

        Assert.AreEqual(
          ItemTracingPage.Description.Value,
          StrSubstNo('Assembly Consumption %1', PostedAssemblyHeader."No."),
          'Unexpected Item Tracing entry type.');

        ItemTracingPage."Item No.".AssertEquals(AssemblyLine."No.");
        ItemTracingPage.Quantity.AssertEquals(-Quantity);

        if Expand then
            ItemTracingPage.Expand(true);
        ItemTracingPage.Next();
    end;

    local procedure ExpectILE(var ItemTracingPage: TestPage "Item Tracing"; AssemblyLine: Record "Assembly Line"; Quantity: Integer; expand: Boolean)
    begin
        Assert.IsTrue(
          StrPos(ItemTracingPage.Description.Value, 'Item Ledger Entry') = 1,
          StrSubstNo('Unexpected Item Tracing entry type. Was %1. Expected Item Ledger Entry.', ItemTracingPage.Description.Value));

        ItemTracingPage."Item No.".AssertEquals(AssemblyLine."No.");
        ItemTracingPage.Quantity.AssertEquals(Quantity);

        if expand then
            ItemTracingPage.Expand(true);
        ItemTracingPage.Next();
    end;

    local procedure NavigateExpect(var NavigatePage: TestPage Navigate; TableName: Text[40]; Quantity: Integer)
    begin
        NavigatePage.First();
        repeat
            if (NavigatePage."Table Name".Value = TableName) and (NavigatePage."No. of Records".AsInteger() = Quantity) then
                exit;
        until not NavigatePage.Next();

        Assert.Fail(StrSubstNo('Navigate entry not found. Expected: %1 with qty. of %2', TableName, Quantity));
    end;

    local procedure NavigateFindSerial(var NavigatePage: TestPage Navigate; AssemblyHeader: Record "Assembly Header")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
    begin
        Commit();
        NavigatePage.OpenEdit();
        NavigatePage.LotNoFilter.SetValue('');

        ItemLedgerEntry.SetRange("Item No.", AssemblyHeader."Item No.");
        ReservationEntry.SetRange("Item No.", AssemblyHeader."Item No.");

        if ItemLedgerEntry.FindFirst() then
            NavigatePage.SerialNoFilter.SetValue(ItemLedgerEntry."Serial No.")
        else begin
            ReservationEntry.FindFirst();
            NavigatePage.SerialNoFilter.SetValue(ReservationEntry."Serial No.");
        end;

        NavigatePage.Find.Invoke();
    end;

    local procedure NavigateFindLot(var NavigatePage: TestPage Navigate; AssemblyHeader: Record "Assembly Header")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
    begin
        Commit();
        NavigatePage.OpenEdit();
        NavigatePage.SerialNoFilter.SetValue('');

        ItemLedgerEntry.SetRange("Item No.", AssemblyHeader."Item No.");
        ReservationEntry.SetRange("Item No.", AssemblyHeader."Item No.");

        if ItemLedgerEntry.FindFirst() then
            NavigatePage.LotNoFilter.SetValue(ItemLedgerEntry."Lot No.")
        else begin
            ReservationEntry.FindFirst();
            NavigatePage.LotNoFilter.SetValue(ReservationEntry."Lot No.");
        end;

        NavigatePage.Find.Invoke();
    end;
}

