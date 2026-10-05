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
    [HandlerFunctions('MessageHandler')]
    procedure CancelSeparateSubcontractingInvoiceReversesCapacityCost()
    var
        PostedCreditMemoNo: Code[20];
    begin
        VerifySeparateSubcontractingInvoiceReversal(true, false, PostedCreditMemoNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure CorrectiveCreditMemoForSeparateSubcontractingInvoiceReversesCapacityCost()
    var
        PostedCreditMemoNo: Code[20];
    begin
        VerifySeparateSubcontractingInvoiceReversal(false, false, PostedCreditMemoNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure CopyPostedCorrectiveCreditMemoForSeparateSubcontractingInvoiceCopiesLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        PostedCreditMemoNo: Code[20];
    begin
        // [SCENARIO 649862] A posted corrective credit memo for a separate subcontracting invoice can be copied
        VerifySeparateSubcontractingInvoiceReversal(false, false, PostedCreditMemoNo);

        // [WHEN] The posted credit memo is copied to a purchase invoice
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Insert(true);
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.CopyPurchDoc("Purchase Document Type From"::"Posted Credit Memo", PostedCreditMemoNo, PurchaseHeader);

        // [THEN] The item line is copied without attempting to load an Item Ledger Entry for the capacity-only value entry
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        Assert.RecordIsNotEmpty(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure QuantityLimitedTrackedSubcontractingReceiptCopyIsBlockedBeforeMutation()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        InvoiceHeader: Record "Purchase Header";
        InvoiceLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
    begin
        // [SCENARIO 649862] A quantity-limited tracked subcontracting receipt copy is blocked before changing the invoice line
        CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
            2, true, false, 'LIMIT-SN1', 1, 'LIMIT-SN2', 1, false, true);
        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
            InvoiceLine, InvoiceHeader, InvoiceLine.Type::Item, Item."No.", 1);
        InvoiceLine."Receipt No." := PurchRcptLine."Document No.";
        InvoiceLine."Receipt Line No." := PurchRcptLine."Line No.";
        InvoiceLine.Modify();
        Commit();

        asserterror ItemTrackingMgt.CopyHandledItemTrkgToPurchLineWithLineQty(PurchaseLine, InvoiceLine);

        Assert.ExpectedError('You cannot copy tracked subcontracting receipt lines into this document.');
        InvoiceLine.Get(InvoiceLine."Document Type", InvoiceLine."Document No.", InvoiceLine."Line No.");
        Assert.AreEqual(1, InvoiceLine.Quantity, 'The quantity-limited copy must not change the requested invoice quantity.');
        ReservationEntry.SetSourceFilter(
            Database::"Purchase Line", InvoiceLine."Document Type".AsInteger(),
            InvoiceLine."Document No.", InvoiceLine."Line No.", false);
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure QuantityLimitedTrackedSubcontractingReceiptCopyIsBlockedBeforeMutation()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        InvoiceHeader: Record "Purchase Header";
        InvoiceLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
    begin
        // [SCENARIO 649862] A quantity-limited tracked subcontracting receipt copy is blocked before changing the invoice line
        CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
            2, true, false, 'LIMIT-SN1', 1, 'LIMIT-SN2', 1, false, true);
        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
            InvoiceLine, InvoiceHeader, InvoiceLine.Type::Item, Item."No.", 1);
        InvoiceLine."Receipt No." := PurchRcptLine."Document No.";
        InvoiceLine."Receipt Line No." := PurchRcptLine."Line No.";
        InvoiceLine.Modify();
        Commit();

        asserterror ItemTrackingMgt.CopyHandledItemTrkgToPurchLineWithLineQty(PurchaseLine, InvoiceLine);

        Assert.ExpectedError('You cannot copy tracked subcontracting receipt lines into this document.');
        InvoiceLine.Get(InvoiceLine."Document Type", InvoiceLine."Document No.", InvoiceLine."Line No.");
        Assert.AreEqual(1, InvoiceLine.Quantity, 'The quantity-limited copy must not change the requested invoice quantity.');
        ReservationEntry.SetSourceFilter(
            Database::"Purchase Line", InvoiceLine."Document Type".AsInteger(),
            InvoiceLine."Document No.", InvoiceLine."Line No.", false);
        Assert.RecordIsEmpty(ReservationEntry);
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
    procedure GetReceiptLinesForNonLastOperationTrackedSubcontractingReceiptPostsInvoice()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO 649862] A non-last-operation subcontracting receipt for a tracked item can be invoiced through Get Receipt Lines
        CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
            2, true, false, 'NON-LAST-SN1', 1, 'NON-LAST-SN2', 1, false, false);

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(InvoiceHeader, false, true);

        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'The non-last-operation receipt must be fully invoiced.');
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", PostedInvoiceNo);
        Assert.RecordCount(ValueEntry, 1);
        ValueEntry.FindFirst();
        Assert.AreEqual(0, ValueEntry."Item Ledger Entry No.", 'A non-last-operation invoice must not reference an item ledger entry.');
        Assert.AreNotEqual(0, ValueEntry."Capacity Ledger Entry No.", 'A non-last-operation invoice must reference a capacity ledger entry.');
        CapacityLedgerEntry.Get(ValueEntry."Capacity Ledger Entry No.");
        Assert.AreEqual(ProductionOrder."No.", CapacityLedgerEntry."Order No.", 'The invoice cost must reference the correct production order.');
        Assert.AreEqual(PurchRcptLine."Work Center No.", CapacityLedgerEntry."Work Center No.", 'The invoice cost must reference the correct work center.');

        CapacityLedgerEntry.Reset();
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.SetRange("Work Center No.", PurchRcptLine."Work Center No.");
        Assert.AreEqual(CapacityLedgerEntryCount, CapacityLedgerEntry.Count(), 'Separate invoicing must not duplicate capacity output.');
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        Assert.AreEqual(OutputItemLedgerEntryCount, ItemLedgerEntry.Count(), 'Separate invoicing must not create item output for a non-last operation.');
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

    local procedure VerifySeparateSubcontractingInvoiceReversal(CancelInvoice: Boolean; TrackOutput: Boolean; var PostedCreditMemoNo: Code[20])
    var
        CancelledDocument: Record "Cancelled Document";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostedCreditMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PostedInvoiceHeader: Record "Purch. Inv. Header";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReasonCode: Record "Reason Code";
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        InvoiceHeader: Record "Purchase Header";
        InvoiceLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
        PostedInvoiceNo: Code[20];
        ExpectedCost: Decimal;
        Quantity: Decimal;
    begin
        CreateSubcontractingReceiptForSeparateInvoice(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount, Quantity, TrackOutput);

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        InvoiceLine.SetRange("Document Type", InvoiceHeader."Document Type");
        InvoiceLine.SetRange("Document No.", InvoiceHeader."No.");
        InvoiceLine.SetRange("Receipt No.", PurchRcptLine."Document No.");
        InvoiceLine.SetRange("Receipt Line No.", PurchRcptLine."Line No.");
        InvoiceLine.FindFirst();
        ExpectedCost := Round(Quantity * InvoiceLine."Direct Unit Cost");
        Assert.AreNotEqual(0, ExpectedCost, 'The reversal scenario must use a nonzero subcontracting cost.');
        LibraryERM.CreateReasonCode(ReasonCode);
        InvoiceHeader.Validate("Reason Code", ReasonCode.Code);
        InvoiceHeader.Modify(true);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(InvoiceHeader, false, true);
        PostedInvoiceHeader.Get(PostedInvoiceNo);
        Commit();

        if CancelInvoice then begin
            Assert.IsTrue(
                CorrectPostedPurchInvoice.CancelPostedInvoice(PostedInvoiceHeader),
                'The separate subcontracting invoice cancellation must post its corrective credit memo.');
            CancelledDocument.Get(Database::"Purch. Inv. Header", PostedInvoiceNo);
            PostedCreditMemoNo := CancelledDocument."Cancelled By Doc. No.";
        end
        else begin
            CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PostedInvoiceHeader, InvoiceHeader);
            InvoiceLine.Reset();
            InvoiceLine.SetRange("Document Type", InvoiceHeader."Document Type");
            InvoiceLine.SetRange("Document No.", InvoiceHeader."No.");
            InvoiceLine.SetRange(Type, InvoiceLine.Type::Item);
            InvoiceLine.SetRange("No.", Item."No.");
            InvoiceLine.FindFirst();
            Assert.AreEqual(PurchRcptLine."Prod. Order No.", InvoiceLine."Prod. Order No.", 'The corrective line must retain the production order.');
            Assert.AreEqual(PurchRcptLine."Prod. Order Line No.", InvoiceLine."Prod. Order Line No.", 'The corrective line must retain the production order line.');
            Assert.AreEqual(PurchRcptLine."Routing No.", InvoiceLine."Routing No.", 'The corrective line must retain the routing.');
            Assert.AreEqual(PurchRcptLine."Routing Reference No.", InvoiceLine."Routing Reference No.", 'The corrective line must retain the routing reference.');
            Assert.AreEqual(PurchRcptLine."Operation No.", InvoiceLine."Operation No.", 'The corrective line must retain the operation.');
            Assert.AreEqual(PurchRcptLine."Work Center No.", InvoiceLine."Work Center No.", 'The corrective line must retain the work center.');
            Assert.AreEqual(PurchRcptLine."Location Code", InvoiceLine."Location Code", 'The corrective line must retain the subcontracting output location.');
            if TrackOutput then begin
                ReservationEntry.SetSourceFilter(
                    Database::"Purchase Line", InvoiceLine."Document Type".AsInteger(), InvoiceLine."Document No.", InvoiceLine."Line No.", false);
                Assert.RecordCount(ReservationEntry, 2);
                ReservationEntry.FindSet();
                repeat
                    Assert.AreNotEqual(0, ReservationEntry."Item Ledger Entry No.", 'The corrective credit memo must create an invoice tracking specification.');
                    Assert.IsTrue(TrackingSpecification.Get(ReservationEntry."Item Ledger Entry No."), 'The corrective credit memo invoice tracking specification must exist.');
                    Assert.AreEqual(
                        ReservationEntry."Appl.-to Item Entry", TrackingSpecification."Appl.-to Item Entry",
                        'The invoice tracking specification must preserve the exact output application.');
                    Assert.IsTrue(ItemLedgerEntry.Get(ReservationEntry."Appl.-to Item Entry"), 'The corrective credit memo must apply to an existing Item Ledger Entry.');
                    VerifyCorrectiveApplication(ItemLedgerEntry, ProductionOrder, PurchRcptLine);
                until ReservationEntry.Next() = 0;
            end else begin
                Assert.IsTrue(ItemLedgerEntry.Get(InvoiceLine."Appl.-to Item Entry"), 'The corrective credit memo must apply to an existing Item Ledger Entry.');
                VerifyCorrectiveApplication(ItemLedgerEntry, ProductionOrder, PurchRcptLine);
            end;
            InvoiceHeader.Validate(
                "Vendor Cr. Memo No.",
                CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(InvoiceHeader."Vendor Cr. Memo No.")));
            InvoiceHeader.Modify(true);
            PostedCreditMemoNo := LibraryPurchase.PostPurchaseDocument(InvoiceHeader, true, true);
        end;

        PostedCreditMemoHeader.Get(PostedCreditMemoNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Credit Memo");
        ValueEntry.SetRange("Document No.", PostedCreditMemoHeader."No.");
        ValueEntry.SetRange("Capacity Ledger Entry No.", CapacityLedgerEntryNo);
        Assert.RecordIsNotEmpty(ValueEntry);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreEqual(-ExpectedCost, Round(ValueEntry."Cost Amount (Actual)"), 'The reversed invoice cost must remain assigned to the original capacity ledger entry.');

        CapacityLedgerEntry.Reset();
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.SetRange("Work Center No.", PurchRcptLine."Work Center No.");
        Assert.AreEqual(CapacityLedgerEntryCount, CapacityLedgerEntry.Count(), 'Reversing the invoice must not create capacity entries.');
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        Assert.AreEqual(OutputItemLedgerEntryCount, ItemLedgerEntry.Count(), 'Reversing the invoice must not create output entries.');
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
                2, true, false, 'REV-SN1', 1, 'REV-SN2', 1, false, true)
        else
            CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
                Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
                CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
                LibraryRandom.RandIntInRange(5, 10), false, false, '', 0, '', 0, false, true);
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
            Quantity, false, true, LotNo1, LotQuantity1, LotNo2, LotQuantity2, false, true);
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
                1, true, false, 'WHSE-SERIAL', 1, '', 0, true, true)
        else
            CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
                Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
                CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
                5, false, true, 'WHSE-LOT', 5, '', 0, true, true);
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
        UseWarehouseReceipt: Boolean;
        LastOperation: Boolean)
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
        SubcontractingWorkCenterIndex: Integer;
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
        SubcontractingWorkCenterIndex := 2;
        if not LastOperation then
            SubcontractingWorkCenterIndex := 1;
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[SubcontractingWorkCenterIndex]."No.");
        if UseWarehouseReceipt then
            SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location)
        else
            SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[SubcontractingWorkCenterIndex]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(
            Item."Routing No.", WorkCenter[SubcontractingWorkCenterIndex]."No.", PurchaseLine);
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
            if not LastOperation then
                LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader)
            else
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
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenter[SubcontractingWorkCenterIndex]."No.");
        CapacityLedgerEntryCount := CapacityLedgerEntry.Count();
        CapacityLedgerEntry.FindFirst();
        CapacityLedgerEntryNo := CapacityLedgerEntry."Entry No.";
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        OutputItemLedgerEntryCount := ItemLedgerEntry.Count();
    end;

    local procedure VerifyCorrectiveApplication(ItemLedgerEntry: Record "Item Ledger Entry"; ProductionOrder: Record "Production Order"; PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
#pragma warning disable AA0210
        CapacityLedgerEntry.SetRange(Subcontracting, true);
        CapacityLedgerEntry.SetRange("Document No.", PurchRcptLine."Document No.");
        CapacityLedgerEntry.SetRange("Item No.", PurchRcptLine."No.");
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", PurchRcptLine."Prod. Order No.");
        CapacityLedgerEntry.SetRange("Order Line No.", PurchRcptLine."Prod. Order Line No.");
        CapacityLedgerEntry.SetRange("Subc. Purch. Order No.", PurchRcptLine."Order No.");
        CapacityLedgerEntry.SetRange("Subc. Purch. Order Line No.", PurchRcptLine."Order Line No.");
        CapacityLedgerEntry.FindFirst();
#pragma warning restore AA0210

        Assert.AreEqual("Item Ledger Entry Type"::Output, ItemLedgerEntry."Entry Type", 'The corrective credit memo must apply to an original output Item Ledger Entry.');
        Assert.AreEqual(CapacityLedgerEntry."Item Register No.", ItemLedgerEntry."Item Register No.", 'The applied output Item Ledger Entry must belong to the exact subcontracting receipt posting.');
        Assert.AreEqual(PurchRcptLine."Order No.", ItemLedgerEntry."Subc. Purch. Order No.", 'The applied output Item Ledger Entry must belong to the subcontracting purchase order.');
        Assert.AreEqual(PurchRcptLine."Order Line No.", ItemLedgerEntry."Subc. Purch. Order Line No.", 'The applied output Item Ledger Entry must belong to the exact subcontracting purchase order line.');
        Assert.AreEqual(ProductionOrder."No.", ItemLedgerEntry."Order No.", 'The applied output Item Ledger Entry must belong to the subcontracting production order.');
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
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
