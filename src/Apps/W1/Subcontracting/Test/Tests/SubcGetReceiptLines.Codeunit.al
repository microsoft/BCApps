// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;

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
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
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
        LibrarySetupStorage.Save(Database::"Manufacturing Setup");

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
    procedure CancelSeparateSubcontractingInvoiceIsBlocked()
    var
        PostedInvoiceHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 649862] Cancel is blocked for a separate subcontracting invoice
        CreatePostedSeparateSubcontractingInvoice(PostedInvoiceHeader);

        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PostedInvoiceHeader);

        Assert.ExpectedError('You cannot automatically reverse this posted purchase invoice because it contains lines copied from a subcontracting order receipt.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CancelSeparateSubcontractingInvoiceAfterReceiptDeletionIsBlocked()
    var
        PostedInvoiceHeader: Record "Purch. Inv. Header";
        PostedInvoiceLine: Record "Purch. Inv. Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 649862] Cancel remains blocked after the invoiced subcontracting receipt is deleted
        CreatePostedSeparateSubcontractingInvoice(PostedInvoiceHeader);
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        PostedInvoiceLine.SetRange("Document No.", PostedInvoiceHeader."No.");
#pragma warning disable AA0210
        PostedInvoiceLine.SetFilter("Receipt No.", '<>%1', '');
#pragma warning restore AA0210
        PostedInvoiceLine.FindFirst();
        PurchRcptHeader.Get(PostedInvoiceLine."Receipt No.");
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(PurchRcptHeader."Posting Date" + 1);
        PurchRcptHeader.Delete(true);

        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PostedInvoiceHeader);

        Assert.ExpectedError('You cannot automatically reverse this posted purchase invoice because it contains lines copied from a subcontracting order receipt.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CorrectSeparateSubcontractingInvoiceIsBlocked()
    var
        PostedInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 649862] Correct is blocked for a separate subcontracting invoice
        CreatePostedSeparateSubcontractingInvoice(PostedInvoiceHeader);

        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PostedInvoiceHeader, PurchaseHeader);

        Assert.ExpectedError('You cannot automatically reverse this posted purchase invoice because it contains lines copied from a subcontracting order receipt.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure CreateCorrectiveCreditMemoForSeparateSubcontractingInvoiceIsBlocked()
    var
        PostedInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 649862] Create Corrective Credit Memo is blocked for a separate subcontracting invoice
        CreatePostedSeparateSubcontractingInvoice(PostedInvoiceHeader);
        Assert.IsTrue(PostedInvoiceHeader.IsFullyOpen(), 'The posted invoice must be fully open before creating a corrective credit memo.');

        asserterror CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PostedInvoiceHeader, PurchaseHeader);

        Assert.ExpectedError('You cannot automatically reverse this posted purchase invoice because it contains lines copied from a subcontracting order receipt.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GetReceiptLinesForTrackedLastOperationSubcontractingReceiptIsBlockedBeforeMutation()
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
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CapacityLedgerEntryCount: Integer;
        CapacityLedgerEntryNo: Integer;
        OutputItemLedgerEntryCount: Integer;
        InvoiceLineCountBefore: Integer;
        ReservationEntryCountBefore: Integer;
        CapacityInvoicedQtyBefore: Decimal;
        OutputInvoicedQtyBefore: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO 649862] A tracked last-operation subcontracting receipt is blocked before any invoice-line or ledger mutation
        // [GIVEN] A fully received, uninvoiced, serial-tracked, last-operation subcontracting receipt
        Quantity := 1;
        CreateSubcontractingReceiptForSeparateInvoiceWithTrackingAndCosts(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
            Quantity, true, false, 'BLOCKED-SN1', Quantity, '', 0, true, 0, 0);

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        InvoiceLine.SetRange("Document Type", InvoiceHeader."Document Type");
        InvoiceLine.SetRange("Document No.", InvoiceHeader."No.");
        InvoiceLineCountBefore := InvoiceLine.Count();
        ReservationEntry.SetSourceFilter(
            Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", false);
        ReservationEntryCountBefore := ReservationEntry.Count();
        CapacityLedgerEntry.Get(CapacityLedgerEntryNo);
        CapacityInvoicedQtyBefore := CapacityLedgerEntry."Invoiced Quantity";
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.FindFirst();
        OutputInvoicedQtyBefore := ItemLedgerEntry."Invoiced Quantity";

        // [WHEN] Get Receipt Lines is run for the tracked last-operation receipt
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);

        // [THEN] The copy is rejected and nothing is mutated
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        Assert.ExpectedError('You cannot copy tracked subcontracting receipt lines into this document.');
        InvoiceLine.SetRange("Document Type", InvoiceHeader."Document Type");
        InvoiceLine.SetRange("Document No.", InvoiceHeader."No.");
        Assert.AreEqual(InvoiceLineCountBefore, InvoiceLine.Count(), 'A blocked tracked last-operation receipt must not create an invoice line.');
        ReservationEntry.SetSourceFilter(
            Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", false);
        Assert.AreEqual(ReservationEntryCountBefore, ReservationEntry.Count(), 'A blocked tracked last-operation receipt must not create a reservation entry.');
        CapacityLedgerEntry.Get(CapacityLedgerEntryNo);
        Assert.AreEqual(
            CapacityInvoicedQtyBefore, CapacityLedgerEntry."Invoiced Quantity",
            'A blocked tracked last-operation receipt must not change the capacity ledger entry invoiced quantity.');
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(
            OutputInvoicedQtyBefore, ItemLedgerEntry."Invoiced Quantity",
            'A blocked tracked last-operation receipt must not change the output item ledger entry invoiced quantity.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GetReceiptLinesForTrackedLastOperationIsBlockedWithExpectedCostPosting()
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
        CapacityInvoicedQtyBefore: Decimal;
        OutputInvoicedQtyBefore: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO 649862] A tracked last-operation subcontracting receipt stays blocked even with Expected Cost Posting to G/L enabled
        // [GIVEN] Expected Cost Posting to G/L is enabled and a fully received, uninvoiced, serial-tracked, last-operation subcontracting receipt exists
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(true);

        Quantity := 1;
        CreateSubcontractingReceiptForSeparateInvoiceWithTrackingAndCosts(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
            Quantity, true, false, 'EXPCOST-SN1', Quantity, '', 0, true, 0, 0);

        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        CapacityLedgerEntry.Get(CapacityLedgerEntryNo);
        CapacityInvoicedQtyBefore := CapacityLedgerEntry."Invoiced Quantity";
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.FindFirst();
        OutputInvoicedQtyBefore := ItemLedgerEntry."Invoiced Quantity";

        // [WHEN] Get Receipt Lines is run for the tracked last-operation receipt
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);

        // [THEN] The copy is rejected, no invoice line or Value Entry is created, and ledger state is unchanged
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        Assert.ExpectedError('You cannot copy tracked subcontracting receipt lines into this document.');
        InvoiceLine.SetRange("Document Type", InvoiceHeader."Document Type");
        InvoiceLine.SetRange("Document No.", InvoiceHeader."No.");
        Assert.RecordIsEmpty(InvoiceLine);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", InvoiceHeader."No.");
        Assert.RecordIsEmpty(ValueEntry);
        CapacityLedgerEntry.Get(CapacityLedgerEntryNo);
        Assert.AreEqual(
            CapacityInvoicedQtyBefore, CapacityLedgerEntry."Invoiced Quantity",
            'Expected Cost Posting must not let a blocked tracked last-operation receipt change the capacity ledger entry invoiced quantity.');
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(
            OutputInvoicedQtyBefore, ItemLedgerEntry."Invoiced Quantity",
            'Expected Cost Posting must not let a blocked tracked last-operation receipt change the output item ledger entry invoiced quantity.');
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
            2, true, false, 'NON-LAST-SN1', 1, 'NON-LAST-SN2', 1, false);

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

    local procedure CreatePostedSeparateSubcontractingInvoice(var PostedInvoiceHeader: Record "Purch. Inv. Header")
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
                2, true, false, 'REV-SN1', 1, 'REV-SN2', 1, true)
        else
            CreateSubcontractingReceiptForSeparateInvoiceWithTracking(
                Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
                CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
                LibraryRandom.RandIntInRange(5, 10), false, false, '', 0, '', 0, true);
        Quantity := PurchaseLine.Quantity;
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
        LastOperation: Boolean)
    begin
        CreateSubcontractingReceiptForSeparateInvoiceWithTrackingAndCosts(
            Item, Vendor, ProductionOrder, PurchRcptLine, PurchaseHeader, PurchaseLine,
            CapacityLedgerEntryNo, CapacityLedgerEntryCount, OutputItemLedgerEntryCount,
            Quantity, TrackSerialOutput, TrackLotOutput, TrackingNo1, TrackingQuantity1,
            TrackingNo2, TrackingQuantity2, LastOperation, 0, 0);
    end;

    local procedure CreateSubcontractingReceiptForSeparateInvoiceWithTrackingAndCosts(
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
        LastOperation: Boolean;
        StandardSubcontractedCost: Decimal;
        DirectUnitCost: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WorkCenter: array[2] of Record "Work Center";
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
        if StandardSubcontractedCost <> 0 then begin
            Item.Validate("Costing Method", Item."Costing Method"::Standard);
            Item.Validate("Standard Cost", StandardSubcontractedCost);
            Item.Validate("Unit Cost", StandardSubcontractedCost);
            Item."Single-Level Subcontrd. Cost" := StandardSubcontractedCost;
            Item."Rolled-up Subcontracted Cost" := StandardSubcontractedCost;
            Item.Modify(true);
        end;
        SubcontractingWorkCenterIndex := 2;
        if not LastOperation then
            SubcontractingWorkCenterIndex := 1;
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[SubcontractingWorkCenterIndex]."No.");
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
        if DirectUnitCost = 0 then
            DirectUnitCost := LibraryRandom.RandDecInRange(10, 25, 2);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
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
                if TrackingQuantity2 <> 0 then begin
                    WarehouseActivityLine.Next();
                    WarehouseActivityLine.Validate("Qty. to Handle", TrackingQuantity2);
                    WarehouseActivityLine.Validate("Serial No.", TrackingNo2);
                    WarehouseActivityLine.Modify(true);
                end;
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

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
