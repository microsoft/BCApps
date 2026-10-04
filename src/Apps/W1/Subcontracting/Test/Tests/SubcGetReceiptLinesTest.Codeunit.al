// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Setup;

#pragma warning disable AA0215
codeunit 149927 "Subc. Get Receipt Lines"
#pragma warning restore AA0215
{
    // [FEATURE] Subcontracting Get Receipt Lines
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcLibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;
        WarehouseTrackingSerialNo: Code[50];
        WarehouseTrackingLotNo: Code[50];
        WarehouseTrackingQuantity: Decimal;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Get Receipt Lines");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Get Receipt Lines");

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Get Receipt Lines");
    end;

#if not CLEAN30
    [Test]
    [HandlerFunctions('MessageHandler')]
    [Obsolete('Use GetReceiptLinesFromInvtPutAwayReceiptPostsSeparateInvoice instead.', '30.0')]
    procedure GetReceiptLinesFromInvtPutAwayReceiptIsCurrentlyBlocked()
    begin
        GetReceiptLinesFromInvtPutAwayReceiptPostsSeparateInvoice();
    end;
#endif

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GetReceiptLinesFromInvtPutAwayReceiptPostsSeparateInvoice()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        InvoiceLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WorkCenter: array[2] of Record "Work Center";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryNo: Integer;
        CapacityLedgerEntryCount: Integer;
        OutputItemLedgerEntryCount: Integer;
        PostedInvoiceNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 649862] TC-GAP-I01 A subcontracting inventory put-away receipt can be invoiced through Get Receipt Lines

        // [GIVEN] LastOperation purchase line fully received via Inventory Put-Away with one output and linked capacity cost
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenter[2]."No.");
        CapacityLedgerEntryCount := CapacityLedgerEntry.Count();
        CapacityLedgerEntry.FindFirst();
        CapacityLedgerEntryNo := CapacityLedgerEntry."Entry No.";
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        OutputItemLedgerEntryCount := ItemLedgerEntry.Count();

        // [WHEN] Get Receipt Lines is run for a new purchase invoice and the separate invoice is posted
        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        InvoiceLine.SetRange("Document Type", InvoiceHeader."Document Type");
        InvoiceLine.SetRange("Document No.", InvoiceHeader."No.");
        InvoiceLine.SetRange("Receipt No.", PurchRcptLine."Document No.");
        InvoiceLine.SetRange("Receipt Line No.", PurchRcptLine."Line No.");
        InvoiceLine.FindFirst();
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(InvoiceHeader, false, true);

        // [THEN] The receipt is fully invoiced and the invoice cost remains linked to the original capacity entry
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'The subcontracting receipt must be fully invoiced.');
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", PostedInvoiceNo);
        ValueEntry.SetRange("Capacity Ledger Entry No.", CapacityLedgerEntryNo);
        Assert.RecordIsNotEmpty(ValueEntry);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreEqual(
            Round(Quantity * InvoiceLine."Direct Unit Cost"), Round(ValueEntry."Cost Amount (Actual)"),
            'The separate invoice cost must remain assigned to the original capacity ledger entry.');

        // [THEN] Posting the separate invoice does not create duplicate capacity or output entries
        CapacityLedgerEntry.Reset();
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.SetRange("Work Center No.", PurchRcptLine."Work Center No.");
        Assert.AreEqual(CapacityLedgerEntryCount, CapacityLedgerEntry.Count(), 'Separate invoicing must not duplicate capacity output.');
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        Assert.AreEqual(OutputItemLedgerEntryCount, ItemLedgerEntry.Count(), 'Separate invoicing must not duplicate item output.');
    end;

    [Test]
    procedure CancelSeparateSubcontractingInvoiceIsBlocked()
    var
        PostedInvoiceHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 649862] Cancel is blocked for a separate subcontracting invoice
        CreatePostedSeparateSubcontractingInvoiceAndDeleteReceipt(PostedInvoiceHeader);

        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PostedInvoiceHeader);

        Assert.ExpectedError('You cannot automatically reverse this posted purchase invoice because it contains lines copied from a subcontracting order receipt.');
    end;

    [Test]
    procedure CorrectSeparateSubcontractingInvoiceIsBlocked()
    var
        PostedInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 649862] Correct is blocked for a separate subcontracting invoice
        CreatePostedSeparateSubcontractingInvoiceAndDeleteReceipt(PostedInvoiceHeader);

        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PostedInvoiceHeader, PurchaseHeader);

        Assert.ExpectedError('You cannot automatically reverse this posted purchase invoice because it contains lines copied from a subcontracting order receipt.');
    end;

    [Test]
    procedure CreateCorrectiveCreditMemoForSeparateSubcontractingInvoiceIsBlocked()
    var
        PostedInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 649862] Create Corrective Credit Memo is blocked for a separate subcontracting invoice
        CreatePostedSeparateSubcontractingInvoiceAndDeleteReceipt(PostedInvoiceHeader);

        asserterror CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PostedInvoiceHeader, PurchaseHeader);

        Assert.ExpectedError('You cannot automatically reverse this posted purchase invoice because it contains lines copied from a subcontracting order receipt.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GetReceiptLinesForPartiallyInvoicedTrackedSubcontractingReceiptIsBlocked()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO 649862] A partially invoiced serial-tracked subcontracting receipt remains blocked
        CreateSubcontractingReceiptForSeparateInvoice(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount, Quantity, true);
        PurchRcptLine."Quantity Invoiced" := 1;
        PurchRcptLine."Qty. Invoiced (Base)" := 1;
        PurchRcptLine."Qty. Rcd. Not Invoiced" := PurchRcptLine.Quantity - 1;
        PurchRcptLine.Modify();

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        Assert.ExpectedError('You cannot copy tracked subcontracting receipt lines into this document.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GetReceiptLinesForAlternateUOMTrackedSubcontractingReceiptIsBlocked()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO 649862] An alternate-UOM tracked subcontracting receipt remains blocked
        CreateSubcontractingReceiptForSeparateInvoice(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount, Quantity, true);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 2);
        PurchRcptLine."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        PurchRcptLine."Qty. per Unit of Measure" := 2;
        PurchRcptLine.Quantity := 1;
        PurchRcptLine."Qty. Rcd. Not Invoiced" := 1;
        PurchRcptLine."Quantity (Base)" := 2;
        PurchRcptLine.Modify();

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        Assert.ExpectedError('You cannot copy tracked subcontracting receipt lines into this document.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GetReceiptLinesForPackageTrackedSubcontractingReceiptIsBlocked()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO 649862] A package-tracked subcontracting receipt remains blocked
        CreateSubcontractingReceiptForSeparateInvoice(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount, Quantity, true);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        Item.Get(Item."No.");
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify();

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        Assert.ExpectedError('You cannot copy tracked subcontracting receipt lines into this document.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GetReceiptLinesForCombinedSerialAndLotTrackedSubcontractingReceiptIsBlocked()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO 649862] A combined serial-and-lot-tracked subcontracting receipt remains blocked
        CreateSubcontractingReceiptForSeparateInvoice(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount, Quantity, true);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, false);
        Item.Get(Item."No.");
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify();

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        Assert.ExpectedError('You cannot copy tracked subcontracting receipt lines into this document.');
    end;

    [Test]
    [HandlerFunctions('WarehouseItemTrackingLinesPageHandler')]
    procedure GetReceiptLinesForSerialTrackedWarehouseReceiptIsBlocked()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
    begin
        // [SCENARIO 649862] A serial-tracked subcontracting warehouse receipt remains blocked
        CreateTrackedWarehouseReceiptForSeparateInvoice(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount, true);

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        Assert.ExpectedError('You cannot copy tracked subcontracting receipt lines into this document.');
    end;

    [Test]
    [HandlerFunctions('WarehouseItemTrackingLinesPageHandler')]
    procedure GetReceiptLinesForLotTrackedWarehouseReceiptIsBlocked()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
    begin
        // [SCENARIO 649862] A lot-tracked subcontracting warehouse receipt remains blocked
        CreateTrackedWarehouseReceiptForSeparateInvoice(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount, false);

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        Assert.ExpectedError('You cannot copy tracked subcontracting receipt lines into this document.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GetReceiptLinesForFullLotTrackedSubcontractingReceiptPostsInvoice()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        InvoiceLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
        LotNo1: Code[50];
        LotNo2: Code[50];
        PostedInvoiceNo: Code[20];
        LotQuantity1: Decimal;
        LotQuantity2: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO 649862] A full lot-tracked subcontracting receipt can be invoiced through Get Receipt Lines
        Quantity := 5;
        LotNo1 := 'GET-RCPT-LOT-A';
        LotNo2 := 'GET-RCPT-LOT-B';
        LotQuantity1 := 3;
        LotQuantity2 := 2;
        CreateLotTrackedSubcontractingReceiptForSeparateInvoice(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
            Quantity, LotNo1, LotQuantity1, LotNo2, LotQuantity2);

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        InvoiceLine.SetRange("Document Type", InvoiceHeader."Document Type");
        InvoiceLine.SetRange("Document No.", InvoiceHeader."No.");
        InvoiceLine.SetRange("Receipt No.", PurchRcptLine."Document No.");
        InvoiceLine.SetRange("Receipt Line No.", PurchRcptLine."Line No.");
        InvoiceLine.FindFirst();
        VerifyInvoiceLotApplication(InvoiceLine, ProductionOrder, LotNo1, LotQuantity1);
        VerifyInvoiceLotApplication(InvoiceLine, ProductionOrder, LotNo2, LotQuantity2);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(InvoiceHeader, false, true);

        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'The tracked subcontracting receipt must be fully invoiced.');

        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", PostedInvoiceNo);
        ValueEntry.SetRange("Capacity Ledger Entry No.", CapacityLedgerEntryNo);
        Assert.RecordIsNotEmpty(ValueEntry);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreEqual(
            Round(Quantity * InvoiceLine."Direct Unit Cost"), Round(ValueEntry."Cost Amount (Actual)"),
            'The tracked separate invoice cost must remain assigned to the original capacity ledger entry.');

        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.SetRange("Work Center No.", PurchRcptLine."Work Center No.");
        Assert.AreEqual(CapacityLedgerEntryCount, CapacityLedgerEntry.Count(), 'Separate invoicing must not create capacity entries.');
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        Assert.AreEqual(OutputItemLedgerEntryCount, ItemLedgerEntry.Count(), 'Separate invoicing must not create output entries.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GetReceiptLinesForDuplicateLotOutputEntriesIsBlocked()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
        LotNo1: Code[50];
        LotNo2: Code[50];
        LotQuantity1: Decimal;
        LotQuantity2: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO 649862] A lot split across multiple output entries remains blocked
        Quantity := 5;
        LotNo1 := 'GET-RCPT-LOT-A';
        LotNo2 := 'GET-RCPT-LOT-B';
        LotQuantity1 := 3;
        LotQuantity2 := 2;
        CreateLotTrackedSubcontractingReceiptForSeparateInvoice(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
            Quantity, LotNo1, LotQuantity1, LotNo2, LotQuantity2);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.FindSet();
        ItemLedgerEntry.Next();
        ItemLedgerEntry."Lot No." := LotNo1;
        ItemLedgerEntry.Modify();

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        Assert.ExpectedError('You cannot copy tracked subcontracting receipt lines into this document.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GetReceiptLinesForFullSerialTrackedSubcontractingReceiptPostsInvoice()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        InvoiceLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
        PostedInvoiceNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO 649862] A full serial-tracked subcontracting receipt can be invoiced through Get Receipt Lines
        CreateSubcontractingReceiptForSeparateInvoice(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount, Quantity, true);

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        InvoiceLine.SetRange("Document Type", InvoiceHeader."Document Type");
        InvoiceLine.SetRange("Document No.", InvoiceHeader."No.");
        InvoiceLine.SetRange("Receipt No.", PurchRcptLine."Document No.");
        InvoiceLine.SetRange("Receipt Line No.", PurchRcptLine."Line No.");
        InvoiceLine.FindFirst();
        VerifyInvoiceSerialApplication(InvoiceLine, ProductionOrder, 'REV-SN1');
        VerifyInvoiceSerialApplication(InvoiceLine, ProductionOrder, 'REV-SN2');
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(InvoiceHeader, false, true);

        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'The tracked subcontracting receipt must be fully invoiced.');

        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", PostedInvoiceNo);
        ValueEntry.SetRange("Capacity Ledger Entry No.", CapacityLedgerEntryNo);
        Assert.RecordIsNotEmpty(ValueEntry);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreEqual(
            Round(Quantity * InvoiceLine."Direct Unit Cost"), Round(ValueEntry."Cost Amount (Actual)"),
            'The tracked separate invoice cost must remain assigned to the original capacity ledger entry.');

        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.SetRange("Work Center No.", PurchRcptLine."Work Center No.");
        Assert.AreEqual(CapacityLedgerEntryCount, CapacityLedgerEntry.Count(), 'Separate invoicing must not create capacity entries.');
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        Assert.AreEqual(OutputItemLedgerEntryCount, ItemLedgerEntry.Count(), 'Separate invoicing must not create output entries.');
    end;

    local procedure VerifyInvoiceSerialApplication(InvoiceLine: Record "Purchase Line"; ProductionOrder: Record "Production Order"; SerialNo: Code[50])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
    begin
        ReservationEntry.SetSourceFilter(
            Database::"Purchase Line", InvoiceLine."Document Type".AsInteger(), InvoiceLine."Document No.", InvoiceLine."Line No.", false);
        ReservationEntry.SetRange("Serial No.", SerialNo);
        ReservationEntry.FindFirst();
        Assert.AreNotEqual(0, ReservationEntry."Appl.-to Item Entry", 'The invoice serial number must apply to an output Item Ledger Entry.');

        ItemLedgerEntry.Get(ReservationEntry."Appl.-to Item Entry");
        Assert.AreEqual(ItemLedgerEntry."Entry Type"::Output, ItemLedgerEntry."Entry Type", 'The invoice serial number must apply to an output entry.');
        Assert.AreEqual(ProductionOrder."No.", ItemLedgerEntry."Order No.", 'The invoice serial number must apply to the production order output.');
        Assert.AreEqual(SerialNo, ItemLedgerEntry."Serial No.", 'The invoice serial number must match the applied output entry.');

        TrackingSpecification.Get(ReservationEntry."Item Ledger Entry No.");
        Assert.AreEqual(
            ItemLedgerEntry."Entry No.", TrackingSpecification."Item Ledger Entry No.",
            'The invoice tracking specification must preserve the exact output application.');
    end;

    local procedure VerifyInvoiceLotApplication(
        InvoiceLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        LotNo: Code[50];
        ExpectedQuantityBase: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
    begin
        ReservationEntry.SetSourceFilter(
            Database::"Purchase Line", InvoiceLine."Document Type".AsInteger(),
            InvoiceLine."Document No.", InvoiceLine."Line No.", false);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.FindFirst();
        Assert.AreEqual(
            ExpectedQuantityBase, Abs(ReservationEntry."Quantity (Base)"),
            'The invoice lot must retain its source output quantity.');
        Assert.AreNotEqual(
            0, ReservationEntry."Appl.-to Item Entry",
            'The invoice lot must apply to an output Item Ledger Entry.');

        ItemLedgerEntry.Get(ReservationEntry."Appl.-to Item Entry");
        Assert.AreEqual(
            ItemLedgerEntry."Entry Type"::Output, ItemLedgerEntry."Entry Type",
            'The invoice lot must apply to an output entry.');
        Assert.AreEqual(
            ProductionOrder."No.", ItemLedgerEntry."Order No.",
            'The invoice lot must apply to the production order output.');
        Assert.AreEqual(LotNo, ItemLedgerEntry."Lot No.", 'The invoice lot must match the applied output entry.');
        Assert.AreEqual(
            ExpectedQuantityBase, Abs(ItemLedgerEntry.Quantity),
            'The applied output entry must contain the complete lot quantity.');

        TrackingSpecification.Get(ReservationEntry."Item Ledger Entry No.");
        Assert.AreEqual(
            ItemLedgerEntry."Entry No.", TrackingSpecification."Item Ledger Entry No.",
            'The invoice lot tracking specification must preserve the exact output application.');
    end;

    local procedure CreatePostedSeparateSubcontractingInvoiceAndDeleteReceipt(var PostedInvoiceHeader: Record "Purch. Inv. Header")
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
        PostedInvoiceNo: Code[20];
        Quantity: Decimal;
    begin
        CreateSubcontractingReceiptForSeparateInvoice(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount, Quantity, false);

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(InvoiceHeader, false, true);
        PostedInvoiceHeader.Get(PostedInvoiceNo);
        PurchRcptHeader.Get(PurchRcptLine."Document No.");
        PurchRcptHeader.Delete(true);
        Commit();
    end;

    local procedure CreateSubcontractingReceiptForSeparateInvoice(
        var Item: Record Item;
        var Vendor: Record Vendor;
        var ProductionOrder: Record "Production Order";
        var PurchRcptLine: Record "Purch. Rcpt. Line";
        var PurchaseHeader: Record "Purchase Header";
        var PurchaseLine: Record "Purchase Line";
        var CapacityLedgerEntryNo: Integer;
        var CapacityLedgerEntryCount: Integer;
        var OutputItemLedgerEntryCount: Integer;
        var Quantity: Decimal;
        TrackOutput: Boolean)
    begin
        if TrackOutput then
            CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
                Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
                CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
                2, true, false, 'REV-SN1', 1, 'REV-SN2', 1, false)
        else
            CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
                Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
                CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
                LibraryRandom.RandIntInRange(5, 10), false, false, '', 0, '', 0, false);
        Quantity := PurchaseLine.Quantity;
    end;

#pragma warning disable AA0228
    local procedure CreateLotTrackedSubcontractingReceiptForSeparateInvoice(
        var Item: Record Item;
        var Vendor: Record Vendor;
        var ProductionOrder: Record "Production Order";
        var PurchRcptLine: Record "Purch. Rcpt. Line";
        var PurchaseHeader: Record "Purchase Header";
        var PurchaseLine: Record "Purchase Line";
        var CapacityLedgerEntryNo: Integer;
        var CapacityLedgerEntryCount: Integer;
        var OutputItemLedgerEntryCount: Integer;
        Quantity: Decimal;
        LotNo1: Code[50];
        LotQuantity1: Decimal;
        LotNo2: Code[50];
        LotQuantity2: Decimal)
    begin
        CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
            Quantity, false, true, LotNo1, LotQuantity1, LotNo2, LotQuantity2, false);
    end;
#pragma warning restore AA0228

    local procedure CreateTrackedWarehouseReceiptForSeparateInvoice(
        var Item: Record Item;
        var Vendor: Record Vendor;
        var ProductionOrder: Record "Production Order";
        var PurchRcptLine: Record "Purch. Rcpt. Line";
        var PurchaseHeader: Record "Purchase Header";
        var PurchaseLine: Record "Purchase Line";
        var CapacityLedgerEntryNo: Integer;
        var CapacityLedgerEntryCount: Integer;
        var OutputItemLedgerEntryCount: Integer;
        TrackSerialOutput: Boolean)
    begin
        if TrackSerialOutput then
            CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
                Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
                CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
                1, true, false, 'WHSE-SERIAL', 1, '', 0, true)
        else
            CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
                Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
                CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
                5, false, true, 'WHSE-LOT', 5, '', 0, true);
    end;

    local procedure CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
        var Item: Record Item;
        var Vendor: Record Vendor;
        var ProductionOrder: Record "Production Order";
        var PurchRcptLine: Record "Purch. Rcpt. Line";
        var PurchaseHeader: Record "Purchase Header";
        var PurchaseLine: Record "Purchase Line";
        var CapacityLedgerEntryNo: Integer;
        var CapacityLedgerEntryCount: Integer;
        var OutputItemLedgerEntryCount: Integer;
        Quantity: Decimal;
        TrackSerialOutput: Boolean;
        TrackLotOutput: Boolean;
        TrackingNo1: Code[50];
        TrackingQuantity1: Decimal;
        TrackingNo2: Code[50];
        TrackingQuantity2: Decimal;
        UseWarehouseReceipt: Boolean)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        ProdOrderLine: Record "Prod. Order Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        WarehouseReceiptPage: TestPage "Warehouse Receipt";
    begin
        Assert.IsFalse(
            TrackSerialOutput and TrackLotOutput,
            'The test fixture accepts either serial or lot tracking, not both.');
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        if TrackSerialOutput then
            SubcWarehouseLibrary.CreateSerialTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter)
        else
            if TrackLotOutput then
                SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter)
            else
                SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        if UseWarehouseReceipt then
            SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location)
        else
            SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 25, 2));
        PurchaseLine.Modify(true);
        if TrackSerialOutput or TrackLotOutput then begin
            ProdOrderLine.SetRange(Status, ProductionOrder.Status);
            ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderLine.FindFirst();
        end;
        if TrackSerialOutput then begin
            LibraryManufacturing.CreateProdOrderItemTracking(
                ReservationEntry, ProdOrderLine, TrackingNo1, '', TrackingQuantity1);
            if TrackingQuantity2 <> 0 then
                LibraryManufacturing.CreateProdOrderItemTracking(
                    ReservationEntry, ProdOrderLine, TrackingNo2, '', TrackingQuantity2);
        end else
            if TrackLotOutput then begin
                LibraryManufacturing.CreateProdOrderItemTracking(
                    ReservationEntry, ProdOrderLine, '', TrackingNo1, TrackingQuantity1);
                if TrackingQuantity2 <> 0 then
                    LibraryManufacturing.CreateProdOrderItemTracking(
                        ReservationEntry, ProdOrderLine, '', TrackingNo2, TrackingQuantity2);
            end;
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        if UseWarehouseReceipt then begin
            SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);
            WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
            WarehouseReceiptLine.FindFirst();
            WarehouseTrackingSerialNo := TrackingNo1;
            WarehouseTrackingLotNo := '';
            if TrackLotOutput then begin
                WarehouseTrackingSerialNo := '';
                WarehouseTrackingLotNo := TrackingNo1;
            end;
            WarehouseTrackingQuantity := TrackingQuantity1;
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
            WarehouseReceiptPage.OpenView();
            WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
            WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
            WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Invoke();
            WarehouseReceiptPage.Close();
            SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);
            SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);
            LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        end else begin
            SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
            if TrackSerialOutput then begin
                WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
                WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
                WarehouseActivityLine.FindSet();
                WarehouseActivityLine.Validate("Qty. to Handle", TrackingQuantity1);
                WarehouseActivityLine.Validate("Serial No.", TrackingNo1);
                WarehouseActivityLine.Modify(true);
                WarehouseActivityLine.Next();
                WarehouseActivityLine.Validate("Qty. to Handle", TrackingQuantity2);
                WarehouseActivityLine.Validate("Serial No.", TrackingNo2);
                WarehouseActivityLine.Modify(true);
            end else
                if TrackLotOutput then begin
                    WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
                    WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
                    WarehouseActivityLine.SetRange("Lot No.", TrackingNo1);
                    WarehouseActivityLine.FindFirst();
                    Assert.AreEqual(TrackingQuantity1, WarehouseActivityLine.Quantity, 'The first lot must retain its production tracking quantity.');
                    WarehouseActivityLine.Validate("Qty. to Handle", TrackingQuantity1);
                    WarehouseActivityLine.Modify(true);

                    WarehouseActivityLine.SetRange("Lot No.", TrackingNo2);
                    WarehouseActivityLine.FindFirst();
                    Assert.AreEqual(TrackingQuantity2, WarehouseActivityLine.Quantity, 'The second lot must retain its production tracking quantity.');
                    WarehouseActivityLine.Validate("Qty. to Handle", TrackingQuantity2);
                    WarehouseActivityLine.Modify(true);
                end else
                    LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
            LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        end;

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenter[2]."No.");
        CapacityLedgerEntryCount := CapacityLedgerEntry.Count();
        CapacityLedgerEntry.FindFirst();
        CapacityLedgerEntryNo := CapacityLedgerEntry."Entry No.";
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        OutputItemLedgerEntryCount := ItemLedgerEntry.Count();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        if Message.Contains('Number of Invt. Put-away activities created') then
            exit;
        if Message.Contains('Number of Invt. Pick activities created') then
            exit;
        if Message.Contains('successfully posted and is now deleted') then
            exit;
        Error('Unexpected Message: %1', Message);
    end;

    [ModalPageHandler]
    procedure WarehouseItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.First();
        if WarehouseTrackingSerialNo <> '' then
            Assert.AreEqual(
                WarehouseTrackingSerialNo, Format(ItemTrackingLines."Serial No.".Value),
                'The serial number must be available on the warehouse receipt.');
        if WarehouseTrackingLotNo <> '' then
            Assert.AreEqual(
                WarehouseTrackingLotNo, Format(ItemTrackingLines."Lot No.".Value),
                'The lot number must be available on the warehouse receipt.');
        Assert.AreEqual(
            WarehouseTrackingQuantity, ItemTrackingLines."Quantity (Base)".AsDecimal(),
            'The warehouse receipt tracking quantity must match the production output tracking.');
        ItemTrackingLines.OK().Invoke();
    end;
}
