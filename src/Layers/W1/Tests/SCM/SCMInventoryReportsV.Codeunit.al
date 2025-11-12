codeunit 137352 "SCM Inventory Reports - V"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [SCM]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        ChangeBillToCustomerNo: Label 'Do you want to change';
        EndingDateError: Label 'Enter the ending date';
        LocationFilter: Label '%1|%2', Locked = true;
        PeriodLengthError: Label 'The minimum permitted value is 1D';
        UndoSalesShptMessage: Label 'Do you really want to undo the selected Shipment lines?';
        UndoSalesRetRcptMessage: Label 'Do you really want to undo the selected Return Receipt lines?';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        ItemMustNotBeReportedErr: Label 'Item %1 must not be included in the report.', Comment = '%1 = Item No.';
        WrongCustomerErr: Label 'Wrong Customer No. in the report.';
        CurrentSaveValuesId: Integer;
        CalcInvtReportInitializeErr: Label 'Calculate Inventory report is not correctly initialized.';
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixReportSalesQuote()
    var
        SalesLine: Record "Sales Line";
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
    begin
        // [SCENARIO] Lot No. on Item Tracking Appendix Report for Sales Quote.

        // [GIVEN] Create and post Purchase Order, create Sales Quote.
        Initialize();
        SalesDocumentForItemTrackingAppendixReport(SalesLine."Document Type"::Quote, DocType::"Sales Quote");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixReportSalesOrder()
    var
        SalesLine: Record "Sales Line";
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
    begin
        // [SCENARIO] Lot No. on Item Tracking Appendix Report for Sales Order.

        // [GIVEN] Create and post Purchase Order, create Sales Order.
        Initialize();
        SalesDocumentForItemTrackingAppendixReport(SalesLine."Document Type"::Order, DocType::"Sales Order");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixReportSalesInv()
    var
        SalesLine: Record "Sales Line";
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
    begin
        // [SCENARIO] Lot No. on Item Tracking Appendix Report for Sales Invoice.

        // [GIVEN] Create and post Purchase Order, create Sales Invoice.
        Initialize();
        SalesDocumentForItemTrackingAppendixReport(SalesLine."Document Type"::Invoice, DocType::"Sales Invoice");
    end;

    local procedure SalesDocumentForItemTrackingAppendixReport(DocumentType: Enum "Sales Document Type"; DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order")
    var
        SalesLine: Record "Sales Line";
        LotNo: Variant;
    begin
        // Create and post Purchase Order, create Sales Document.
        LotNo := PostPurchaseOrderAndCreateSalesDoc(SalesLine, DocumentType, TrackingOption::SelectEntries);
        EnqueueValuesForItemTrackingAppendixReport(DocType, SalesLine."Document No.", SalesLine."No.");

        // [WHEN] Run Item Tracking Appendix Report.
        RunItemTrackingAppendixReport();

        // [THEN] Lot No. on Item Tracking Appendix Report Report.
        VerifyLotNoOnItemTrackingAppendixReport(SalesLine."No.", LotNo, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixReportPstdSalesShpt()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        LotNo: Variant;
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Lot No. on Item Tracking Appendix Report for Posted Sales Shipment.

        // [GIVEN] Create and post Purchase Order, create and post Sales Order.
        Initialize();
        LotNo := PostPurchaseOrderAndCreateSalesDoc(SalesLine, SalesLine."Document Type"::Order, TrackingOption::SelectEntries);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        EnqueueValuesForItemTrackingAppendixReport(DocType::"Sales Post. Shipment", DocumentNo, SalesLine."No.");

        // [WHEN] Run Item Tracking Appendix Report.
        RunItemTrackingAppendixReport();

        // [THEN] Verify  Lot No. on Item Tracking Appendix Report.
        VerifyLotNoOnItemTrackingAppendixReport(SalesLine."No.", LotNo, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixReportSalesCrMemo()
    var
        SalesLine: Record "Sales Line";
        LotNo: Variant;
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
    begin
        // [SCENARIO] Lot No. on Item Tracking Appendix Report for Sales Credit Memo.

        // [GIVEN] Create and post Purchase Order, create Sales Credit Memo.
        Initialize();
        PostPurchaseOrderAndCreateSalesDoc(SalesLine, SalesLine."Document Type"::"Credit Memo", TrackingOption::AssignLotNo);
        LibraryVariableStorage.Dequeue(LotNo);
        EnqueueValuesForItemTrackingAppendixReport(DocType::"Sales Credit Memo", SalesLine."Document No.", SalesLine."No.");

        // [WHEN] Run Item Tracking Appendix Report.
        RunItemTrackingAppendixReport();

        // [THEN] Verify  Lot No. on Item Tracking Appendix Report.
        VerifyLotNoOnItemTrackingAppendixReport(SalesLine."No.", LotNo, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixReportSalesRetOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo: Variant;
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Lot No. on Item Tracking Appendix Report for Sales Return Order.

        // [GIVEN] Create and post Purchase Order, create and post Sales Order, Create Sales Return Order using copy document.
        Initialize();
        LotNo := PostPurchaseOrderAndCreateSalesDoc(SalesLine, SalesLine."Document Type"::Order, TrackingOption::SelectEntries);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);  // Set TRUE for Include Header and FALSE for Recalculate Lines.
        EnqueueValuesForItemTrackingAppendixReport(DocType::"Sales Return Order", SalesHeader."No.", SalesLine."No.");
        Commit();

        // [WHEN] Run Item Tracking Appendix Report.
        RunItemTrackingAppendixReport();

        // [THEN] Verify  Lot No. on Item Tracking Appendix Report.
        VerifyLotNoOnItemTrackingAppendixReport(SalesLine."No.", LotNo, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixReportPurchQuote()
    var
        PurchaseLine: Record "Purchase Line";
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
    begin
        // [SCENARIO] Serial No. and Lot No. on Item Tracking Appendix Report for Purchase Quote.

        // [GIVEN] Create Purchase Quote with Item Tracking.
        Initialize();
        PurchDocumentForItemTrackingAppendixReport(PurchaseLine."Document Type"::Quote, DocType::"Purch. Quote");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixReportPurchOrder()
    var
        PurchaseLine: Record "Purchase Line";
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
    begin
        // [SCENARIO] Serial No. and Lot No. on Item Tracking Appendix Report for Purchase Order.

        // [GIVEN] Create Purchase Order with Item Tracking.
        Initialize();
        PurchDocumentForItemTrackingAppendixReport(PurchaseLine."Document Type"::Order, DocType::"Purch. Order");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixReportPurchInv()
    var
        PurchaseLine: Record "Purchase Line";
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
    begin
        // [SCENARIO] Serial No. and Lot No. on Item Tracking Appendix Report for Purchase Invoice.

        // [GIVEN] Create Purchase Invoice with Item Tracking.
        Initialize();
        PurchDocumentForItemTrackingAppendixReport(PurchaseLine."Document Type"::Invoice, DocType::"Purch. Invoice");
    end;

    local procedure PurchDocumentForItemTrackingAppendixReport(DocumentType: Enum "Purchase Document Type"; DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order")
    var
        PurchaseLine: Record "Purchase Line";
        SerialNo: Variant;
        LotNo: Variant;
    begin
        // Create Purchase Document with Item Tracking.
        CreatePurchaseDocumentWithIT(PurchaseLine, DocumentType, TrackingOption::AssignSerialNo, true, '', '');
        LibraryVariableStorage.Dequeue(SerialNo);
        LibraryVariableStorage.Dequeue(LotNo);
        EnqueueValuesForItemTrackingAppendixReport(DocType, PurchaseLine."Document No.", PurchaseLine."No.");

        // [WHEN] Run Item Tracking Appendix Report.
        RunItemTrackingAppendixReport();

        // [THEN] Verify  Lot No. and Serial No. on Item Tracking Appendix Report.
        VerifyItemTrackingAppendixReport(PurchaseLine."No.", LotNo, SerialNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixReportPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
    begin
        // [SCENARIO] Serial No. and Lot No. on Item Tracking Appendix Report for Purchase Credit Memo.

        // [GIVEN] Create and post Purchase Order with Item Tracking, create Purchase Credit Memo using copy document.
        Initialize();
        PurchDocumentUsingCopyDocument(PurchaseHeader."Document Type"::"Credit Memo", DocType::"Purch. Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixReportPurchRetOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
    begin
        // [SCENARIO] Serial No. and Lot No. on Item Tracking Appendix Report for Purchase Return Order.

        // [GIVEN] Create and post Purchase Order with Item Tracking, create Purchase return Order using copy document.
        Initialize();
        PurchDocumentUsingCopyDocument(PurchaseHeader."Document Type"::"Return Order", DocType::"Purch. Return Order");
    end;

    local procedure PurchDocumentUsingCopyDocument(DocumentType: Enum "Purchase Document Type"; DocType: Option)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        LotNo: Variant;
        SerialNo: Variant;
    begin
        // Create and post Purchase Order with Item Tracking, create Purchase Document using copy document.
        CreatePurchaseDocumentWithIT(PurchaseLine, PurchaseLine."Document Type"::Order, TrackingOption::AssignSerialNo, true, '', '');
        LibraryVariableStorage.Dequeue(SerialNo);
        LibraryVariableStorage.Dequeue(LotNo);
        PostPurchaseOrder(PurchaseLine, false);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CopyPurchaseDocument(
            PurchaseHeader, "Purchase Document Type From"::Order, PurchaseLine."Document No.", true, false);  // Set TRUE for Include Header and FALSE for Recalculate Lines.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        EnqueueValuesForItemTrackingAppendixReport(DocType, PurchaseHeader."No.", PurchaseLine."No.");

        // [WHEN] Run Item Tracking Appendix Report.
        RunItemTrackingAppendixReport();

        // [THEN] Verify  Lot No. and Serial No. on Item Tracking Appendix Report.
        VerifyItemTrackingAppendixReport(PurchaseLine."No.", LotNo, SerialNo);
    end;

    [Test]
    [HandlerFunctions('ItemExpirationQuantityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemExpirationQuantityReportEndDateError()
    begin
        // [SCENARIO] error for blank Ending Date on Item Expiration Quantity report.
        ItemExpirationQuantityReportError(0D, '<1M>', EndingDateError);  // Use 1M for monthly Period 0D for Ending Date.
    end;

    [Test]
    [HandlerFunctions('ItemExpirationQuantityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemExpirationQuantityReportPeriodLengthError()
    begin
        // [SCENARIO] error for Period length less than 1M on Item Expiration Quantity report.
        ItemExpirationQuantityReportError(WorkDate(), '<0M>', PeriodLengthError);  // Use 0M for monthly Period.
    end;

    local procedure ItemExpirationQuantityReportError(EndingDate: Date; PeriodLength: Text; ExpectedError: Text[50])
    var
        ItemExpirationQuantity: Report "Item Expiration - Quantity";
        PeriodLength2: DateFormula;
    begin
        // [GIVEN] Clear Item Expiration Quantity Report. COMMIT to clear pending write transaction.
        Initialize();
        Commit();
        Evaluate(PeriodLength2, PeriodLength);
        EnqueueValuesForItemExpirationQuantityReport(EndingDate, PeriodLength2);
        Clear(ItemExpirationQuantity);

        // Exercise.
        asserterror ItemExpirationQuantity.Run();

        // Verify
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemExpirationQuantityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemExpirationQuantityReportWithSameLocation()
    var
        Location: Record Location;
    begin
        // [SCENARIO] Item Expiration Quantity Report with same Location.

        // [GIVEN] Create Location, create and post Purchase Order with Item Tracking.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ItemExpirationQuantityReportWithExpirDate(Location.Code, Location.Code)
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemExpirationQuantityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemExpirationQuantityReportWithMultipleLocation()
    var
        Location: Record Location;
        Location2: Record Location;
    begin
        // [SCENARIO] Item Expiration Quantity Report with multiple Locations.

        // [GIVEN] Create Locations, create and post Purchase Order with Item Tracking.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);
        ItemExpirationQuantityReportWithExpirDate(Location.Code, Location2.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentDocumentWithCorrectionLine()
    var
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // [SCENARIO] Sales Shipment Report, print with Show Correction Lines.

        // [GIVEN] Create Sales Order, Post and undo Shipment.
        Initialize();
        CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Order, LibraryInventory.CreateItemNo());
        UndoSalesShipment(SalesLine);
        FindShipmentLine(SalesShipmentLine, SalesLine."No.");

        // Exercise.
        Commit();
        SaveSalesShipment(SalesShipmentLine."Document No.");

        // [THEN] Verify Sales Shipment Report.
        VerifyPostedSalesReport(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReturnReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRetReceiptDocumentWithCorrectionLine()
    var
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        // [SCENARIO] Sales Return Receipt Report, print with Show Correction Lines.

        // [GIVEN] Create Sales Return Order, Post and undo Return Receipt.
        Initialize();
        CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", LibraryInventory.CreateItemNo());
        UndoReturnReceipt(SalesLine);
        FindReturnReceiptLine(ReturnReceiptLine, SalesLine);

        // Exercise.
        Commit();
        SaveSalesRetReceipt(ReturnReceiptLine."Document No.");

        // [THEN] Verify Sales Return Receipt Report.
        VerifyPostedSalesReport(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PhysInventoryListRequestPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PhysInvListRptWithShowQtyAsTrue()
    var
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] physical Inventory List Report for lot and serial item tracking with ShowTracking as false and ShowQuantity as true.
        Initialize();
        PhysInvListReport(PurchaseLine, '', '', true, false);  // Booleans value are respective to ShowQuantity and ShowTracking.
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::Purchase);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInventoryListReport(PurchaseLine."No.", PurchaseLine.Quantity, ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Serial No.", true, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PhysInventoryListRequestPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PhysInvListRptWithShowTrackingAsTrue()
    var
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] physical Inventory List Report for lot and serial item tracking with ShowTracking as false and ShowQuantity as true.
        Initialize();
        PhysInvListReport(PurchaseLine, '', '', false, true);  // Booleans value are respective to ShowQuantity and ShowTracking.
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::Purchase);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInventoryListReport(PurchaseLine."No.", PurchaseLine.Quantity,
          ItemLedgerEntry."Lot No.", ItemLedgerEntry."Serial No.", false, true, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PhysInventoryListRequestPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PhysInvListRptWithLocAndBin()
    var
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Bin: Record Bin;
    begin
        // [SCENARIO] physical Inventory List Report for Location and Bin with ShowTracking and ShowQuantity as False.
        Initialize();
        CreateLocationWithBin(Bin, true);
        PhysInvListReport(PurchaseLine, Bin."Location Code", Bin.Code, false, false);  // Booleans value are respective to ShowQuantity and ShowTracking.
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::Purchase);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInventoryListReport(PurchaseLine."No.", PurchaseLine.Quantity,
          ItemLedgerEntry."Lot No.", ItemLedgerEntry."Serial No.", false, false, false);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_ItemJournalLine', PurchaseLine."Location Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_ItemJournalLine', PurchaseLine."Bin Code");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PhysInventoryListRequestPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PhysInvListRptWithLocAndBinShowTrackingAsTrue()
    var
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Bin: Record Bin;
    begin
        // [SCENARIO] physical Inventory List Report for Location and Bin with ShowTracking as true.
        Initialize();
        CreateLocationWithBin(Bin, true);
        PhysInvListReport(PurchaseLine, Bin."Location Code", Bin.Code, false, true);  // Booleans value are respective to ShowQuantity and ShowTracking.
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::Purchase);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInventoryListReport(PurchaseLine."No.", PurchaseLine.Quantity,
          ItemLedgerEntry."Lot No.", ItemLedgerEntry."Serial No.", false, true, true);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_ItemJournalLine', PurchaseLine."Location Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_ItemJournalLine', PurchaseLine."Bin Code");
    end;

    local procedure PhysInvListReport(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; BinCode: Code[20]; ShowQuantity: Boolean; ShowTracking: Boolean)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [GIVEN] Create Item with lot and serial Tracking Code, create and post Purchase Order with Tracking Lines. Run Calculate Inventory on Phys. Inventory Journal.
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, TrackingOption::AssignSerialNo, LocationCode, BinCode, true);  // TRUE for SN Specific.
        RunCalculateInventoryReport(ItemJournalBatch, PurchaseLine."No.", false, false);  // False for Item not on inventory.
        EnqueueValuesForPhysInvListReport(ShowQuantity, ShowTracking);

        // [WHEN]
        RunPhysInventoryListReport(ItemJournalBatch);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,PhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PhysInvListRptWithDiffLocShowTrackingAndQtyAsTrue()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        SerialNo: array[2] of Code[50];
        LotNo: array[2] of Code[50];
    begin
        // [SCENARIO] physical Inventory List Report for different Location.
        Initialize();
        PhysInvListRptWithDiffLoc(PurchaseLine, PurchaseLine2, SerialNo, LotNo, true, true);  // Booleans value are respective to ShowQuantity and ShowTracking.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInventoryListReport(PurchaseLine."No.", PurchaseLine.Quantity, LotNo[1], SerialNo[1], true, true, true);
        VerifyPhysInventoryListReport(PurchaseLine2."No.", PurchaseLine2.Quantity, LotNo[2], SerialNo[2], true, true, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PhysInventoryListRequestPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PhysInvListRptWithDiffLocShowQtyAsFalse()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        SerialNo: array[2] of Code[20];
        LotNo: array[2] of Code[20];
    begin
        // [SCENARIO] physical Inventory List Report for different Location with ShowQuantity as False.
        Initialize();
        PhysInvListRptWithDiffLoc(PurchaseLine, PurchaseLine2, SerialNo, LotNo, false, true);  // Booleans value are respective to ShowQuantity and ShowTracking.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInventoryListReport(PurchaseLine."No.", PurchaseLine.Quantity, LotNo[1], SerialNo[1], false, true, true);
        VerifyPhysInventoryListReport(PurchaseLine2."No.", PurchaseLine2.Quantity, LotNo[2], SerialNo[2], false, true, true);
    end;

    local procedure PhysInvListRptWithDiffLoc(var PurchaseLine: Record "Purchase Line"; var PurchaseLine2: Record "Purchase Line"; var SerialNo: array[2] of Code[50]; var LotNo: array[2] of Code[50]; ShowQuantity: Boolean; ShowTracking: Boolean)
    var
        Bin: Record Bin;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [GIVEN] Create Item with Tracking Code, create and post Purchase Order with Tracking Lines.
        CreateLocationWithBin(Bin, true);
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, TrackingOption::AssignSerialNo, Bin."Location Code", Bin.Code, true);  // TRUE for SN Specific.
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::Purchase);
        SerialNo[1] := ItemLedgerEntry."Serial No.";
        LotNo[1] := ItemLedgerEntry."Lot No.";

        PostWarehouseReceiptWithPurchaseOrder(PurchaseLine2, SerialNo[2], LotNo[2]);
        RegisterWarehouseActivity(WarehouseActivityLine, PurchaseLine2."Document No.");

        // Create Physical Inventory and Run Calculate Inventory Report.
        RunCalculateInventoryReport(ItemJournalBatch, StrSubstNo('%1|%2', PurchaseLine."No.", PurchaseLine2."No."), false, false);   // False for Item not on inventory.
        EnqueueValuesForPhysInvListReport(ShowQuantity, ShowTracking);

        // Exercise.
        RunPhysInventoryListReport(ItemJournalBatch);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,PhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PhysInvListRptWithItemNotOnInv()
    var
        SalesLine: Record "Sales Line";
        ItemJournalBatch: Record "Item Journal Batch";
        LotNo: Variant;
    begin
        // [SCENARIO] physical Inventory List Report with item Not on inventory.

        // [GIVEN] Create Item with Tracking Code, create and post Purchase Order and sales order with Tracking Lines. Run Calculate Inventory on Phys. Inventory Journal and check Item not on inventory.
        Initialize();
        LotNo := PostPurchaseOrderAndCreateSalesDoc(SalesLine, SalesLine."Document Type"::Order, TrackingOption::SelectEntries);
        PostSalesOrder(SalesLine);
        RunCalculateInventoryReport(ItemJournalBatch, SalesLine."No.", true, false);  // True for Item not on inventory.
        EnqueueValuesForPhysInvListReport(true, true);   // Booleans value are respective to ShowQuantity and ShowTracking.

        // [WHEN]
        RunPhysInventoryListReport(ItemJournalBatch);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInventoryListReport(SalesLine."No.", 0, LotNo, '', true, true, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,PhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PhysInvListRptWithNoWarehouseTracking()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ItemJournalBatch: Record "Item Journal Batch";
        PurchaseLine: Record "Purchase Line";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        SerialNo: Code[50];
        LotNo: Code[50];
    begin
        // [SCENARIO] Whse. Phys. Inventory List report when "Show Serial/Lot No" option is checked, if warehouse tracking is defined for a specific Item Tracking Code.
        Initialize();
        PostWarehouseReceiptWithPurchaseOrder(PurchaseLine, SerialNo, LotNo);
        RegisterWarehouseActivity(WarehouseActivityLine, PurchaseLine."Document No.");

        // Create and Register Warehouse Entry.
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::"Physical Inventory");
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, PurchaseLine."Location Code");
        CalculateWarehouseInventory(WarehouseJournalBatch, PurchaseLine."No.", WorkDate());
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, PurchaseLine."Location Code", true);
        EnqueueValuesForPhysInvListReport(true, true);   // Booleans value are respective to ShowQuantity and ShowTracking.

        // Create Physical Inventory and Run Calculate Inventory Report.
        RunCalculateInventoryReport(ItemJournalBatch, PurchaseLine."No.", false, false);  // False for Item not on inventory.

        // [WHEN]
        RunPhysInventoryListReport(ItemJournalBatch);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInventoryListReport(PurchaseLine."No.", PurchaseLine.Quantity, LotNo, SerialNo, true, true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,InventoryCustomersSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvCustomerSalesReportAfterAdjustCost()
    var
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Inventory Customer Sales Report after running Adjust Cost Item Entries.

        // [GIVEN] Create and post Sales Order, create and post Purchase Order and  Adjust Cost Item Entries.
        Initialize();
        SetupForSalesReport(SalesLine);

        // [WHEN] Run Inventory Customer Sales Report.
        Commit();
        RunInventoryCustomerSalesReport(SalesLine."No.");

        // [THEN] Verify Sales Amount and Profit on Inventory Customer Sales Report.
        VerifySalesReportAfterPostSalesOrder(
          SalesLine."No.", SalesLine."Sell-to Customer No.", 'No_Item', 'CustName', 'SalesAmtActual_ItemLedgEntry', 'Profit_ItemLedgEntry');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,CustomerItemSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemSalesReportAfterAdjustCost()
    var
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Item Sales Report after running Adjust Cost Item Entries.

        // [GIVEN] Create and post Sales Order, create and post Purchase Order and  Adjust Cost Item Entries.
        Initialize();
        SetupForSalesReport(SalesLine);

        // [WHEN] Run Item Sales Report.
        Commit();
        RunItemSalesReport(SalesLine."Bill-to Customer No.");

        // [THEN] Verify Sales Amount and Profit on Item Sales Report.
        VerifySalesReportAfterPostSalesOrder(
          SalesLine."No.", SalesLine."Bill-to Customer No.", 'ValueEntryBuffer__Item_No__',
          'Customer_Name', 'ValueEntryBuffer__Sales_Amount__Actual___Control44', 'Profit_Control46');
    end;

    [Test]
    [HandlerFunctions('InventoryValuationRequestPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure InvValuationReportAfterPostInvtCostToGL()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
    begin
        // [SCENARIO] Inventory Valuation Report after running Post Inventory To G/L batch job.

        // [GIVEN] Create Item, create and post Purchase Order, create Sales Order, run Adjust Cost Item Entries and Post Inventory To G/L batch job.
        Initialize();
        ItemNo := CreateItem();
        CreateAndPostPurchaseOrder(ItemNo, false);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        ModifySalesLineAndPostSalesOrder(SalesLine, SalesHeader, ItemNo);
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [WHEN] Run Inventory Valuation Sales Report.
        Commit();
        RunInventoryValuationReport(ItemNo);

        // [THEN] Verify Decrease Quantity and Amount on Inventory Valuation Report.
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        VerifyInventoryValuationReport(SalesLine, ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('RevaluationPostingTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostRevaluationJournalWithLocationMandatory()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Revaluation Posting Report After Posting Revaluation Journal With Location Mandatory.

        // [GIVEN] Create Item, create and post Purchase Order,Create Revaluation Journal.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(Item."No.", true);
        UpdateInventorySetup(true);
        CreateItemJournalForRevaluation(ItemJournalLine, Item."No.");

        // [WHEN] Run Revaluation Posting Test Report.
        Commit();
        RunRevaluationPostingTestReport(Item."No.");

        // [THEN] Verify Quantity and Inventory Value Revaluated on Revaluation Posting Test Report.
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        VerifyRevaluationPostingTestReport(ItemJournalLine);

        // TearDown: TearDown Inventory Setup.
        UpdateInventorySetup(false);
    end;

    [Test]
    [HandlerFunctions('InventoryCostVarianceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithItemChargeAssign()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Document No and Cost per Unit in Inventory Cost variance Report After Posting Purchase Order With Item Charge Assignment.

        // [GIVEN] Create Purchase Order with Item Charge.
        Initialize();
        CreateAndModifyItem(Item, Item."Costing Method"::Standard);
        CreatePurchDocWithItemChargeAssign(PurchaseHeader, Item."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run Inventory Cost Variance Report.
        RunInventoryCostVarianceReport(Item."No.");

        // [THEN] Verify Run Inventory Cost Variance Report.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        VerifyInventoryCostVarianceReport(ItemLedgerEntry, Item."Standard Cost", DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryForItemsWithoutTransactions()
    var
        Item: array[3] of Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Qty: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Physical Inventory] [Calculate Inventory]
        // [SCENARIO 371783] "Calculate Inventory" Report sets "Qty. (Calculated)" to zero for Items without Transactions
        Initialize();

        // [GIVEN] Item "I1" with quantity on inventory = "Q1"
        LibraryInventory.CreateItem(Item[1]);
        Qty[1] := LibraryRandom.RandDec(10, 2);
        LibraryInventory.PostPositiveAdjustment(Item[1], '', '', '', Qty[1], WorkDate(), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Items "I2" and "I3" with zero inventory
        LibraryInventory.CreateItem(Item[2]);
        Qty[2] := 0;
        LibraryInventory.CreateItem(Item[3]);
        Qty[3] := 0;

        // [WHEN] Run "Calculate Inventory" Report with "Include Item without Transactions" and "Items Not on Inventory" option
        RunCalculateInventoryReport(ItemJournalBatch, StrSubstNo('%1|%2|%3', Item[1]."No.", Item[2]."No.", Item[3]."No."), true, true);

        // [THEN] Three Lines are created: "L1" with Qty = "Q1", "L2" with Qty = 0, "L3" with Qty = 0
        for i := 1 to 3 do begin
            ItemJournalLine.SetRange("Item No.", Item[i]."No.");
            ItemJournalLine.FindFirst();
            ItemJournalLine.TestField("Qty. (Calculated)", Qty[i]);
        end;
    end;

    [Test]
    [HandlerFunctions('StatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StatusReportIncludesOnlyOpenEntriesFIFOItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Inventory]
        // [SCENARIO 377883] Only open item ledger entries are included in "Status" report for an item with FIFO costing method

        // [GIVEN] Create item "I" with FIFO costing method
        CreateAndModifyItem(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Post first inbound inventory: Quantity = "Q", "Unit Cost" = "C"
        // [GIVEN] Post second inbound inventory: Quantity = "Q", "Unit Cost" = 2 * "C"
        // [GIVEN] Post outbound inventory: Quantity = "Q" * 1.5
        PostItemPurchaseAndSale(Item."No.");

        // [GIVEN] Run Adjust Cost - Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Run "Status" report
        RunStatusReport(Item."No.");

        // [THEN] First inbound entry is closed and not included in the report
        // [THEN] Second inbound entry is open and included in the report, reported quantity = "Q" / 2
        VerifyFIFOItemStatusReport(Item."No.");
    end;

    [Test]
    [HandlerFunctions('StatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StatusReportIncludesAllEntriesAverageItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Inventory]
        // [SCENARIO 377883] All item ledger entries are included in "Status" report for an item with Average costing method

        // [GIVEN] Create item "I" with Average costing method
        CreateAndModifyItem(Item, Item."Costing Method"::Average);

        // [GIVEN] Post first inbound inventory: Quantity = "Q", "Unit Cost" = "C"
        // [GIVEN] Post second inbound inventory: Quantity = "Q", "Unit Cost" = 2 * "C"
        // [GIVEN] Post outbound inventory: Quantity = "Q" * 1.5
        PostItemPurchaseAndSale(Item."No.");

        // [GIVEN] Run Adjust Cost - Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Run "Status" report
        RunStatusReport(Item."No.");

        // [THEN] All item ledger entries are included in the report, quantity = "Q"
        VerifyAverageItemStatusReport(Item."No.");
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesOnlyExpectedCost()
    var
        ItemNo: Code[20];
    begin
        // [FEATURE] [Customer/Item Sales] [Item Charge]
        // [SCENARIO 380354] An item is not included in the "Customer/Item Sales" report when the report is run on a period that includes only expected cost for the item

        // [GIVEN] Item "I" purchased. Unit cost is "C1"
        // [GIVEN] Sales order for "Q" pcs of item "I". Sales amount = "P1"
        // [GIVEN] Post shipment on WorkDate(), post invoice on WorkDate() + 1 day
        // [GIVEN] Apply purchase item charge to shipment, cost amount = "C2", posting date = WorkDate() + 2 days
        // [GIVEN] Apply sales item charge to shipment, sales amount = "P2", posting date = WorkDate() + 2 days
        Initialize();
        ItemNo := PostSalesShipAndInvoiceWithItemChargesOnDifferentDates();

        // [WHEN] Run "Customer/Item Sales" report filtered by item "I" and date = WORKDATE
        RunItemSalesReportFilterOnPostingDate(ItemNo, WorkDate(), WorkDate());

        // [THEN] Item is not shown in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ValueEntryBuffer__Item_No__', ItemNo);
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), StrSubstNo(ItemMustNotBeReportedErr, ItemNo));
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesActualCostNoCharge()
    var
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Customer/Item Sales] [Item Charge]
        // [SCENARIO 380354] An item is included in the "Customer/Item Sales" report with actual cost including item charges, despite their posting date out of the reporting period.

        // [GIVEN] Item "I" purchased. Cost amount is "C1"
        // [GIVEN] Sales order for "Q" pcs of item "I". Sales amount = "P1"
        // [GIVEN] Post shipment on WorkDate(), post invoice on WorkDate() + 1 day
        // [GIVEN] Apply purchase item charge to shipment, cost amount = "C2", posting date = WorkDate() + 2 days
        // [GIVEN] Apply sales item charge to shipment, sales amount = "P2", posting date = WorkDate() + 2 days
        Initialize();
        ItemNo := PostSalesShipAndInvoiceWithItemChargesOnDifferentDates();

        // [WHEN] Run "Customer/Item Sales" report filtered by item "I" and date = WorkDate() + 1
        RunItemSalesReportFilterOnPostingDate(ItemNo, WorkDate() + 1, WorkDate() + 1);

        // [THEN] Item "I" is present in the report. Quantity = "Q"; Sales amount = "P1" + "P2"; Profit = "P1" + "P2" - ("C1" + "C2").
        ValueEntry.SetRange("Item No.", ItemNo);
        VerifyReportItemLine(ItemNo, ValueEntry);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesExpectedAndActualCostNoCharge()
    var
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Customer/Item Sales] [Item Charge]
        // [SCENARIO 380354] An item is included in the "Customer/Item Sales" report with actual cost when the report is run on a period that includes both expected and actual cost for the item

        // [GIVEN] Item "I" purchased. Cost amount is "C1"
        // [GIVEN] Sales order for "Q" pcs of item "I". Sales amount = "P1"
        // [GIVEN] Post shipment on WorkDate(), post invoice on WorkDate() + 1 day
        // [GIVEN] Apply purchase item charge to shipment, cost amount = "C2", posting date = WorkDate() + 2 days
        // [GIVEN] Apply sales item charge to shipment, sales amount = "P2", posting date = WorkDate() + 2 days
        Initialize();
        ItemNo := PostSalesShipAndInvoiceWithItemChargesOnDifferentDates();

        // [WHEN] Run "Customer/Item Sales" report filtered by item "I" and date period from WORKDATE to WorkDate() + 1
        RunItemSalesReportFilterOnPostingDate(ItemNo, WorkDate(), WorkDate() + 1);

        // [THEN] Item "I" is present in the report. Quantity = "Q", Sales amount = "P1", Profit = "P1" - "C1"
        ValueEntry.SetRange("Item No.", ItemNo);
        VerifyReportItemLine(ItemNo, ValueEntry);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesActualAndChargeNoExpected()
    var
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Customer/Item Sales] [Item Charge]
        // [SCENARIO 380354] An item is included in the "Customer/Item Sales" report with actual cost and item charges when the report is run on a period that does not include expected cost

        // [GIVEN] Item "I" purchased. Cost amount is "C1"
        // [GIVEN] Sales order for "Q" pcs of item "I". Sales amount = "P1"
        // [GIVEN] Post shipment on WorkDate(), post invoice on WorkDate() + 1 day
        // [GIVEN] Apply purchase item charge to shipment, cost amount = "C2", posting date = WorkDate() + 2 days
        // [GIVEN] Apply sales item charge to shipment, sales amount = "P2", posting date = WorkDate() + 2 days
        Initialize();
        ItemNo := PostSalesShipAndInvoiceWithItemChargesOnDifferentDates();

        // [WHEN] Run "Customer/Item Sales" report filtered by item "I" and date period from WorkDate() + 1 to WorkDate() + 2
        RunItemSalesReportFilterOnPostingDate(ItemNo, WorkDate() + 1, WorkDate() + 2);

        // [THEN] Item "I" is present in the report. Quantity = "Q", Sales amount = "P1" + "P2", Profit = "P1" + "P2" - "C1" - "C2"
        ValueEntry.SetRange("Item No.", ItemNo);
        VerifyReportItemLine(ItemNo, ValueEntry);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesChargesOnly()
    var
        ItemNo: Code[20];
    begin
        // [FEATURE] [Customer/Item Sales] [Item Charge]
        // [SCENARIO 380354] An item is not included in the "Customer/Item Sales" report when the report is run on a period that includes only item charges and no item cost

        // [GIVEN] Item "I" purchased. Cost amount is "C1"
        // [GIVEN] Sales order for "Q" pcs of item "I". Sales amount = "P1"
        // [GIVEN] Post shipment on WorkDate(), post invoice on WorkDate() + 1 day
        // [GIVEN] Apply purchase item charge to shipment, cost amount = "C2", posting date = WorkDate() + 2 days
        // [GIVEN] Apply sales item charge to shipment, sales amount = "P2", posting date = WorkDate() + 2 days
        Initialize();
        ItemNo := PostSalesShipAndInvoiceWithItemChargesOnDifferentDates();

        // [WHEN] Run "Customer/Item Sales" report filtered by item "I" and date = WorkDate() + 2
        RunItemSalesReportFilterOnPostingDate(ItemNo, WorkDate() + 2, WorkDate() + 2);

        // [THEN] Item is not shown in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ValueEntryBuffer__Item_No__', ItemNo);
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), StrSubstNo(ItemMustNotBeReportedErr, ItemNo));
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesAllEntries()
    var
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Customer/Item Sales] [Item Charge]
        // [SCENARIO 380354] An item is included in the "Customer/Item Sales" report with actual cost and item charges when the report is run on a period that includes all item entries

        // [GIVEN] Item "I" purchased. Cost amount is "C1"
        // [GIVEN] Sales order for "Q" pcs of item "I". Sales amount = "P1"
        // [GIVEN] Post shipment on WorkDate(), post invoice on WorkDate() + 1 day
        // [GIVEN] Apply purchase item charge to shipment, cost amount = "C2", posting date = WorkDate() + 2 days
        // [GIVEN] Apply sales item charge to shipment, sales amount = "P2", posting date = WorkDate() + 2 days
        Initialize();
        ItemNo := PostSalesShipAndInvoiceWithItemChargesOnDifferentDates();

        // [WHEN] Run "Customer/Item Sales" report filtered by item "I" and date period from WORKDATE to WorkDate() + 2
        RunItemSalesReportFilterOnPostingDate(ItemNo, WorkDate(), WorkDate() + 2);

        // [THEN] Item "I" is present in the report. Quantity = "Q", Sales amount = "P1" + "P2", Profit = "P1" + "P2" - "C1" - "C2"
        ValueEntry.SetRange("Item No.", ItemNo);
        VerifyReportItemLine(ItemNo, ValueEntry);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesPartialInvoicing()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Customer/Item Sales] [Item Charge]
        // [SCENARIO 380354] When a sales order is partially invoiced on different dates, report "Customer/Item Sales" includes only the amount invoiced on given date

        // [GIVEN] Item "I" purchased. Cost amount is "C"
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(Item."No.", true);

        // [GIVEN] Sales order for "Q" pcs of item "I". Sales amount = "P". Post shipment on workdate
        CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.");

        // [GIVEN] Invoice "Q" / 2 pcs on WorkDate() + 1 day
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        UpdatePostingDateOnSalesHeader(SalesHeader, WorkDate() + 1);
        SalesLine.Find();
        SalesLine.Validate("Qty. to Invoice", SalesLine.Quantity / 2);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Invoice remaining "Q" / 2 pcs on WorkDate() + 2 days
        UpdatePostingDateOnSalesHeader(SalesHeader, WorkDate() + 2);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] Run "Customer/Item Sales" report filtered by item "I" and date = WorkDate() + 2
        RunItemSalesReportFilterOnPostingDate(Item."No.", WorkDate() + 2, WorkDate() + 2);

        // [THEN] Item "I" is present in the report. Quantity = "Q" / 2, Sales amount = "P" / 2, Profit = ("P" - "C") / 2
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Posting Date", WorkDate() + 2);
        VerifyReportItemLine(Item."No.", ValueEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesDifferentShipToAndBillToCustomers()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Customer/Item Sales] [Item Charge]
        // [SCENARIO 380354] When Bill-to Customer in a sales order is different from Sell-to Customer, Report "Customer/Item Sales" shows Bill-to Customer

        // [GIVEN] Item "I" purchased. Cost amount is "C"
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(Item."No.", true);

        // [GIVEN] Sales order for item "I". Sell-to customer "CU1", bill-to customer "CU2"
        // [GIVEN] Ship and invoice the order
        CreateAndModifySalesHeader(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        PostSalesInvoiceOnNewPostingDate(SalesLine."Document Type", SalesLine."Document No.", WorkDate() + 1);

        // [WHEN] Run "Customer/Item Sales" report filtered by item "I"
        RunItemSalesReportFilterOnPostingDate(Item."No.", WorkDate(), WorkDate() + 1);

        // [THEN] Customer "CU2" is present in the report
        // [THEN] Customer "CU1" is not reported
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('Customer__No__', SalesHeader."Bill-to Customer No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), WrongCustomerErr);

        LibraryReportDataset.SetRange('Customer__No__', SalesHeader."Sell-to Customer No.");
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), WrongCustomerErr);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesSeveralInvoicesSameCustomerReportedInOneEntry()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Customer/Item Sales]
        // [SCENARIO 380354] Several invoices for the same customer and item should be rolled up in one entry in "Customer/Item Sales" report

        // [GIVEN] Item "I" purchased.
        Initialize();
        LibraryInventory.CreateItem(Item);
        PostItemJournalLine(
          Item."No.", LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandInt(1000), ItemJournalLine."Entry Type"::"Positive Adjmt.");

        // [GIVEN] Sales invoice for item "I" in two lines. Line 1: quantity = "Q1", total sales amount = "P1", line 2: quantity = "Q2", total sales amount = "P2"
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, Item."No.", LibraryRandom.RandInt(10));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run "Customer/Item Sales" report filtered by item "I" and date = WorkDate() + 2
        RunItemSalesReportFilterOnPostingDate(Item."No.", WorkDate(), WorkDate());

        // [THEN] Report has one entry for item "I", quantity = "Q1" + "Q2", Sales amount = "P1" + "P2"
        ValueEntry.SetRange("Item No.", Item."No.");
        VerifyReportItemLine(Item."No.", ValueEntry);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesChargeToAllItemEntriesAreIncluded()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Customer/Item Sales] [Item Charge]
        // [SCENARIO 232388] When you post two sales item entries with item charges assigned to each, "Customer/Item Sales" report shows the full sales amount of these entries, including charges.
        Initialize();

        // [GIVEN] Item "I" is in inventory.
        ItemNo := CreateItem();
        CustomerNo := CreateCustomer();
        PostItemJournalLine(
          ItemNo, LibraryRandom.RandIntInRange(50, 100), LibraryRandom.RandDec(10, 2), ItemJournalLine."Entry Type"::"Positive Adjmt.");

        // [GIVEN] Two sales orders with item "I" and the same customer are shipped and invoiced. Sales amount of each document = "X1" and "X2" respectively.
        for i := 1 to 2 do begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
            ModifySalesLineAndPostSalesOrder(SalesLine, SalesHeader, ItemNo);

            // [GIVEN] Item Charge is assigned to each shipment. The amount of each invoice = "C1" and "C2" respectively.
            SalesShipmentLine.SetRange("Sell-to Customer No.", CustomerNo);
            SalesShipmentLine.SetRange("No.", ItemNo);
            SalesShipmentLine.FindLast();
            PostSalesItemChargeAssignedToShipment(CustomerNo, WorkDate(), SalesShipmentLine);
        end;

        // [WHEN] Run "Customer/Item Sales" report for "I".
        RunItemSalesReportFilterOnPostingDate(ItemNo, WorkDate(), WorkDate());

        // [THEN] The report shows the full posted sales amount including charges ("X1" + "C1" + "X2" + "C2").
        ValueEntry.SetRange("Item No.", ItemNo);
        VerifyReportItemLine(ItemNo, ValueEntry);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesItemChargesCalculatedSeparatelyForEachCustomer()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
        CustomerNo: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Customer/Item Sales] [Item Charge]
        // [SCENARIO 234508] Item charges assigned to item entries for different customers, are calculated separately for each customer in "Customer/Item Sales" report.
        Initialize();

        // [GIVEN] Item "I" is in inventory.
        ItemNo := CreateItem();
        PostItemJournalLine(
          ItemNo, LibraryRandom.RandIntInRange(50, 100), LibraryRandom.RandDec(10, 2), ItemJournalLine."Entry Type"::"Positive Adjmt.");

        // [GIVEN] A sales order with item "I" for each of the two customers "C1" and "C2". Sales amount of each document = "X1" and "X2" respectively.
        for i := 1 to ArrayLen(CustomerNo) do begin
            CustomerNo[i] := CreateCustomer();
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo[i]);
            ModifySalesLineAndPostSalesOrder(SalesLine, SalesHeader, ItemNo);

            // [GIVEN] Item Charge is assigned to each shipment. The amount of each charge = "Y1" and "Y2" respectively.
            SalesShipmentLine.SetRange("Sell-to Customer No.", CustomerNo[i]);
            FindShipmentLine(SalesShipmentLine, ItemNo);
            PostSalesItemChargeAssignedToShipment(CustomerNo[i], WorkDate(), SalesShipmentLine);
        end;

        // [WHEN] Run "Customer/Item Sales" report for "I".
        RunItemSalesReportFilterOnPostingDate(ItemNo, WorkDate(), WorkDate());

        // [THEN] The report shows sales for both "C1" and "C2" customers.
        // [THEN] Sales amount for customer "C1" is "X1" + "Y1".
        // [THEN] Sales amount for customer "C2" is "X2" + "Y2".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.Reset();
        for i := 1 to ArrayLen(CustomerNo) do begin
            ItemLedgerEntry.SetRange("Source No.", CustomerNo[i]);
            ItemLedgerEntry.FindFirst();
            ItemLedgerEntry.CalcFields("Sales Amount (Actual)");

            LibraryReportDataset.SetRange('Customer__No__', CustomerNo[i]);
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'ValueEntryBuffer__Sales_Amount__Actual___Control44', ItemLedgerEntry."Sales Amount (Actual)");
        end;
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesItemChargeCalculatedOnceForSaleWithMultipleInvoices()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Customer/Item Sales] [Item Charge]
        // [SCENARIO 234508] When a sale item entry contains more than one direct cost value entries, the value entry representing item charge is considered only once for the item entry in "Customer/Item Sales" report.
        Initialize();

        // [GIVEN] "X" pcs of item "I" are in stock.
        ItemNo := CreateItem();
        CustomerNo := CreateCustomer();
        for i := 1 to 2 do
            Qty[i] := LibraryRandom.RandIntInRange(20, 40);
        PostItemJournalLine(
          ItemNo, Qty[1] + Qty[2], LibraryRandom.RandDec(10, 2), ItemJournalLine."Entry Type"::"Positive Adjmt.");

        // [GIVEN] Sales order for "X" pcs of item "I" is posted only with Ship option.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, ItemNo, Qty[1] + Qty[2], '', WorkDate());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] The sales order is fully invoiced in two steps, for 1/2 * "X" pcs on each step. The total invoiced amount = "Y".
        for i := 1 to 2 do begin
            SalesLine.Find();
            SalesLine.Validate("Qty. to Invoice", Qty[i]);
            SalesLine.Modify(true);
            LibrarySales.PostSalesDocument(SalesHeader, false, true);
        end;

        // [GIVEN] Item Charge is assigned to the shipment. Item charge amount = "Z".
        SalesShipmentLine.SetRange("Sell-to Customer No.", CustomerNo);
        FindShipmentLine(SalesShipmentLine, ItemNo);
        PostSalesItemChargeAssignedToShipment(CustomerNo, WorkDate(), SalesShipmentLine);

        // [WHEN] Run "Customer/Item Sales" report for item "I".
        RunItemSalesReportFilterOnPostingDate(ItemNo, WorkDate(), WorkDate());

        // [THEN] The report shows the full posted sales amount that is equal to "Y" + "Z".
        ValueEntry.SetRange("Item No.", ItemNo);
        VerifyReportItemLine(ItemNo, ValueEntry);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestFilterOnPostingDatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesCostAdjustmentsAreCalculatedOnDateOfInitialPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Customer/Item Sales] [Adjust Cost Item Entries]
        // [SCENARIO 235162] Cost adjustment to sales item entry is included into the period when initial cost was posted in "Customer/Item Sales" report, although the cost adjustment is posted on a later date.
        Initialize();

        // [GIVEN] Item "I".
        // [GIVEN] Post a purchase order for "I" with receive and invoice option on WORKDATE. Cost amount = "C1".
        ItemNo := CreateItem();
        CreateAndPostPurchaseOrder(ItemNo, true);
        FindPurchRcptLine(PurchRcptLine, ItemNo);

        // [GIVEN] Post a sales order for "I" with ship and invoice option on WORKDATE.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        ModifySalesLineAndPostSalesOrder(SalesLine, SalesHeader, ItemNo);

        // [GIVEN] Create purchase invoice with item charge and assign it to posted receipt of "I".
        // [GIVEN] Cost amount of the item charge = "C2", Posting date = WorkDate() + 1 day.
        // [GIVEN] Post the purchase invoice.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Expected Receipt Date", LibraryRandom.RandDate(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Run "Adjust Cost - Item Entries" batch job for item "I".
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // [WHEN] Run "Customer/Item Sales" report for item "I" on WORKDATE.
        Commit();
        RunItemSalesReportFilterOnPostingDate(ItemNo, WorkDate(), WorkDate());

        // [THEN] The report shows the full cost amount of the sales ("C1" + "C2"), that includes the cost adjustment posted on the later date.
        ValueEntry.SetRange("Item No.", ItemNo);
        VerifyReportItemLine(ItemNo, ValueEntry);
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryReportItemsWithNoTransNotInclWhenItemsNotInInvtParamOff()
    begin
        // [FEATURE] [Calculate Inventory] [UT]
        // [SCENARIO 227249] Parameter "Include items with no transactions" in Calculate Inventory Report is reset to FALSE when "Items not in inventory" setting is FALSE.
        Initialize();

        // [WHEN] Set "Include items with no transactions" = TRUE and "Items not in inventory" = FALSE in Calculate Inventory report and open the request page.
        RunCalculateInventoryReportRequestPage(false, true);

        // [THEN] "Include items with no transactions" setting is reset to FALSE.
        Assert.AreEqual(Format(false), LibraryVariableStorage.DequeueText(), CalcInvtReportInitializeErr);
        Assert.AreEqual(Format(false), LibraryVariableStorage.DequeueText(), CalcInvtReportInitializeErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryReportItemWithNoTransInclWhenItemsNotInInvtParamOn()
    begin
        // [FEATURE] [Calculate Inventory] [UT]
        // [SCENARIO 227249] Parameter "Include items with no transactions" in Calculate Inventory Report can be TRUE when "Items not in inventory" setting is TRUE.
        Initialize();

        // [WHEN] Set "Include items with no transactions" = TRUE and "Items not in inventory" = TRUE in Calculate Inventory report and open the request page.
        RunCalculateInventoryReportRequestPage(true, true);

        // [THEN] "Include items with no transactions" setting remains TRUE.
        Assert.AreEqual(Format(true), LibraryVariableStorage.DequeueText(), CalcInvtReportInitializeErr);
        Assert.AreEqual(Format(true), LibraryVariableStorage.DequeueText(), CalcInvtReportInitializeErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryForItemsWithoutTransactionsInOneLocation()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Bin: array[2] of Record Bin;
        Location: Record Location;
        Qty: Decimal;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Physical Inventory] [Calculate Inventory]
        // [SCENARIO 296470] "Calculate Inventory" Report sets "Qty. (Calculated)" to zero for Items without Transactions
        Initialize();
        Location.DeleteAll();

        // [GIVEN] Item "I1" with quantity on inventory = "Q1"
        ItemNo := LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandDec(10, 2);
        // [GIVEN] Two Locations with bins. L1 with 'Bin Mandatory' = True, L2 with 'BinMandatory' = False
        CreateLocationWithBin(Bin[1], true);
        CreateLocationWithBin(Bin[2], false);
        // [GIVEN] Transaction with Item on L1
        LibraryInventory.PostPositiveAdjustment(Item, Bin[1]."Location Code", '', Bin[1].Code, Qty, WorkDate(), LibraryRandom.RandDec(10, 2));

        // [WHEN] Run "Calculate Inventory" Report with "Include Item without Transactions" and "Items Not on Inventory" option
        Item.SetRange("No.", ItemNo);
        Item.SetFilter("Location Filter", StrSubstNo('%1|%2', Bin[1]."Location Code", Bin[2]."Location Code"));
        RunCalculateInventoryReportWithItem(ItemJournalBatch, Item, true, true);

        // [THEN] Two Lines are created: on "L1" with Qty = "Q1", on "L2" with Qty = 0
        ItemJournalLine.SetRange("Item No.", ItemNo);
        Assert.AreEqual(2, ItemJournalLine.Count, '');
        ItemJournalLine.SetRange("Location Code", Bin[1]."Location Code");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Qty. (Calculated)", Qty);
        ItemJournalLine.SetRange("Location Code", Bin[2]."Location Code");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Qty. (Calculated)", 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,PhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PhysInventoryListDoesNotShowLotsWithZeroQty()
    var
        Bin: Record Bin;
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Physical Inventory] [Calculate Inventory]
        // [SCENARIO 374675] Phys. inventory list report does not show lots not in inventory when "Lot warehouse tracking" is enabled.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Location with bins.
        CreateLocationWithBin(Bin, true);

        // [GIVEN] Lot-tracked item with enabled warehouse tracking.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Post 1 pc of lot "L1" to inventory.
        // [GIVEN] Post 1 pc of lot "L2" to inventory.
        CreateAndPostItemJournalLineWithItemTracking(LotNos[1], Item."No.", Bin."Location Code", Bin.Code, Qty);
        CreateAndPostItemJournalLineWithItemTracking(LotNos[2], Item."No.", Bin."Location Code", Bin.Code, Qty);

        // [GIVEN] Write off 1 pc of lot "L1" from inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Bin."Location Code", Bin.Code, -Qty);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Open phys. inventory journal and calculate inventory.
        RunCalculateInventoryReport(ItemJournalBatch, Item."No.", false, false);

        // [WHEN] Run Phys. Inventory List report with "Show Lot/SN" option.
        EnqueueValuesForPhysInvListReport(true, true);
        RunPhysInventoryListReport(ItemJournalBatch);

        // [THEN] The report shows 1 pc of lot "L2".
        LibraryReportDataset.LoadDataSetFile();
        VerifyPhysInventoryListReport(Item."No.", Qty, LotNos[2], '', true, true, true);

        // [THEN] The report does not show lot "L1" that is not in inventory.
        asserterror VerifyPhysInventoryListReport(Item."No.", 0, LotNos[1], '', true, true, true);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('No row found');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        SalesHeader: Record "Sales Header";
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Reports - V");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports - V");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports - V");
    end;

    local procedure AssignItemTrackingOnPurchLine(DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        SerialNo: Variant;
        LotNo: Variant;
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
            PurchaseLine.OpenItemTrackingLines();
            LibraryVariableStorage.Dequeue(SerialNo);
            LibraryVariableStorage.Dequeue(LotNo);
        until PurchaseLine.Next() = 0
    end;

    local procedure CreateAndModifySalesHeader(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibraryVariableStorage.Enqueue(ChangeBillToCustomerNo);
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);
    end;

    local procedure CreateAndUpdateTrackedItem(): Code[20]
    var
        Item: Record Item;
        ExpirationDate: DateFormula;
    begin
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, true, true));  // Use blank value for Serial No.
        Evaluate(ExpirationDate, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        Item.Validate("Expiration Calculation", ExpirationDate);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, DocumentType, ItemNo, LibraryRandom.RandDec(10, 2));  // Use Random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateAndModifySalesHeader(SalesHeader);
        ModifySalesLineAndPostSalesOrder(SalesLine, SalesHeader, ItemNo);
    end;

    local procedure CreateAndPostPurchaseOrderWithIT(var PurchaseLine: Record "Purchase Line"; UseTrackingOption: Option; LocationCode: Code[10]; BinCode: Code[20]; SNSpecific: Boolean)
    var
        SerialNo: Variant;
        LotNo: Variant;
    begin
        CreatePurchaseDocumentWithIT(PurchaseLine, PurchaseLine."Document Type"::Order, UseTrackingOption, SNSpecific, LocationCode, BinCode);
        LibraryVariableStorage.Dequeue(SerialNo);
        LibraryVariableStorage.Dequeue(LotNo);
        PostPurchaseOrder(PurchaseLine, false);
    end;

    local procedure CreateAndPostPurchaseOrder(ItemNo: Code[20]; ToInvoice: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDoc(PurchaseLine, PurchaseLine."Document Type"::Order, ItemNo);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));  // Use random Value for Direct Unit Cost.
        PurchaseLine.Modify(true);
        PostPurchaseOrder(PurchaseLine, ToInvoice);
    end;

    local procedure CreateAndPostItemJournalLineWithItemTracking(var LotNo: Code[50]; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        LotNo := StrSubstNo(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreatePurchaseOrderWithMultipleLines(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader, CreateAndUpdateTrackedItem(), LocationCode);
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader, PurchaseLine."No.", LocationCode2);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateAndModifyItem(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        Item.Get(CreateItem());
        Item.Validate("Standard Cost", LibraryRandom.RandDec(100, 1));  // Using Random value for Standard Cost.
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    local procedure CreateItemJournalForRevaluation(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
        NoSeries: Codeunit "No. Series";
    begin
        Item.SetRange("No.", ItemNo);
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Revaluation);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, WorkDate(), NoSeries.PeekNextNo(ItemJournalBatch."No. Series"), "Inventory Value Calc. Per"::Item,
          false, false, false, "Inventory Value Calc. Base"::" ", false);
    end;

    local procedure CreateItemJournalForPhysInventory(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreatePhysInventoryJournalBatch(ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemTrackingCode(SNSpecific: Boolean; LOTSpecific: Boolean; UseExpirationDates: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if UseExpirationDates then
            LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(ItemTrackingCode, SNSpecific, LOTSpecific)
        else
            LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LOTSpecific);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateLocationWithBin(var Bin: Record Bin; BinMandatory: Boolean)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", BinMandatory);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
    end;

    local procedure CreatePurchaseDoc(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1 + LibraryRandom.RandInt(100));  // Use random value for Quantity and Quantity must be greater than 1.
    end;

    local procedure CreatePurchDocWithItemChargeAssign(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseLine: Record "Purchase Line";
        ChargePurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDoc(PurchaseLine, PurchaseLine."Document Type"::Order, ItemNo);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.CreatePurchaseLine(
          ChargePurchaseLine, PurchaseHeader, ChargePurchaseLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));
        ChargePurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        ChargePurchaseLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, ChargePurchaseLine, PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.",
          PurchaseLine."No.");
    end;

    local procedure CreatePurchaseDocumentWithIT(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; UseTrackingOption: Option; SNSpecific: Boolean; LocationCode: Code[10]; BinCode: Code[20])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(SNSpecific, true, false));  // Use blank value for Serial No.
        CreatePurchaseDoc(PurchaseLine, DocumentType, Item."No.");
        PurchaseLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(UseTrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseLineWithLocation(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));  // Use random value for Quantity.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithIT(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; Quantity: Decimal; UseTrackingOption: Option)
    begin
        CreateSalesDocument(SalesLine, DocumentType, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(UseTrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreatePhysInventoryJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::"Phys. Inventory");
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CalculateWarehouseInventory(WarehouseJournalBatch: Record "Warehouse Journal Batch"; ItemNo: Code[20]; RegisteringDate: Date)
    var
        BinContent: Record "Bin Content";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        BinContent.Init();  // To ignore precal error using INIT.
        WarehouseJournalLine.Init();
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", WarehouseJournalBatch."Location Code");
        BinContent.SetRange("Item No.", ItemNo);
        LibraryWarehouse.WhseCalculateInventory(WarehouseJournalLine, BinContent, RegisteringDate, LibraryUtility.GenerateGUID(), false);
    end;

    local procedure EnqueueValuesForItemTrackingAppendixReport(DocType: Option; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(DocType);
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(ItemNo);
    end;

    local procedure EnqueueValuesForItemExpirationQuantityReport(EndingDate: Date; PeriodLength: DateFormula)
    begin
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(PeriodLength);
    end;

    local procedure EnqueueValuesForPhysInvListReport(ShowQuantity: Boolean; ShowTracking: Boolean)
    begin
        LibraryVariableStorage.Enqueue(ShowQuantity);
        LibraryVariableStorage.Enqueue(ShowTracking);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line")
    begin
        ReturnReceiptLine.SetRange("Return Order No.", SalesLine."Document No.");
        ReturnReceiptLine.SetRange("No.", SalesLine."No.");
        ReturnReceiptLine.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type")
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindPutAwayLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; No: Code[20])
    begin
        SalesShipmentLine.SetRange("No.", No);
        SalesShipmentLine.FindFirst();
    end;

    local procedure ItemExpirationQuantityReportWithExpirDate(LocationCode: Code[10]; LocationCode2: Code[10])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        EndDate: Date;
        PeriodLength: DateFormula;
    begin
        // create and post Purchase Order with Item Tracking.
        CreatePurchaseOrderWithMultipleLines(PurchaseLine, LocationCode, LocationCode2);
        AssignItemTrackingOnPurchLine(PurchaseLine."Document No.");
        Item.Get(PurchaseLine."No.");
        EndDate := CalcDate(Item."Expiration Calculation", WorkDate());
        UpdateExpirationDateOnReservEntry(Item."No.", EndDate);
        PostPurchaseOrder(PurchaseLine, false);
        Evaluate(PeriodLength, '<1M>');  // Use 1M for monthly Period.

        // Exercise.
        RunItemExpirationQuantityReport(EndDate, PeriodLength, Item."No.", LocationCode, LocationCode2);

        // [THEN] Verify Inventory on Item Expiration Quantity report.
        Item.CalcFields(Inventory);
        VerifyItemExpirationQuantityReport(Item."No.", Item.Inventory);
    end;

    local procedure UpdateInventorySetup(LocationMandatory: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Location Mandatory", LocationMandatory);
        InventorySetup.Modify(true);
    end;

    local procedure ModifySalesLineAndPostSalesOrder(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Take random Unit Cost.
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostItemPurchaseAndSale(ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Integer;
    begin
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        PostItemJournalLine(ItemNo, Quantity, LibraryRandom.RandInt(100), ItemJournalLine."Entry Type"::Purchase);
        PostItemJournalLine(ItemNo, Quantity, LibraryRandom.RandInt(100), ItemJournalLine."Entry Type"::Purchase);
        PostItemJournalLine(
          ItemNo, Quantity + LibraryRandom.RandInt(Quantity div 2), LibraryRandom.RandInt(100), ItemJournalLine."Entry Type"::Sale);
    end;

    local procedure PostPurchaseOrder(PurchaseLine: Record "Purchase Line"; ToInvoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, ToInvoice);
    end;

    local procedure PostSalesInvoiceOnNewPostingDate(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; NewPostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        UpdatePostingDateOnSalesHeader(SalesHeader, NewPostingDate);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure PostSalesOrder(SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.
    end;

    local procedure PostSalesShipAndInvoiceWithItemChargesOnDifferentDates(): Code[20]
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        PostItemJournalLine(
          Item."No.", LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandInt(1000), ItemJournalLine."Entry Type"::"Positive Adjmt.");

        CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.");
        PostSalesInvoiceOnNewPostingDate(SalesLine."Document Type", SalesLine."Document No.", WorkDate() + 1);

        FindShipmentLine(SalesShipmentLine, Item."No.");
        PostPurchItemChargeAssignedToShipment(LibraryPurchase.CreateVendorNo(), WorkDate() + 2, SalesShipmentLine);
        PostSalesItemChargeAssignedToShipment(SalesLine."Sell-to Customer No.", WorkDate() + 2, SalesShipmentLine);

        exit(Item."No.");
    end;

    local procedure PostPurchaseOrderAndCreateSalesDoc(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; UseTrackingOption: Option): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        LotNo: Variant;
    begin
        CreatePurchaseDocumentWithIT(PurchaseLine, PurchaseLine."Document Type"::Order, TrackingOption::AssignLotNo, false, '', '');  // FALSE for SNSpecific.'
        PostPurchaseOrder(PurchaseLine, false);
        LibraryVariableStorage.Dequeue(LotNo);
        CreateSalesDocumentWithIT(SalesLine, DocumentType, PurchaseLine."No.", PurchaseLine.Quantity, UseTrackingOption);
        exit(LotNo);
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseReceiptWithPurchaseOrder(var PurchaseLine: Record "Purchase Line"; var SerialNo: Code[50]; var LotNo: Code[50])
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseEmployee: Record "Warehouse Employee";
        VarCode: Variant;
    begin
        // Create Warehouse Employee.
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);  // Use 1 for Bins per Zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // Create and Release Purchase Order with Item Tracking.
        CreatePurchaseDocumentWithIT(
          PurchaseLine, PurchaseLine."Document Type"::Order, TrackingOption::AssignSerialNo, true, Location.Code, '');  // Set True for SN Specific.
        LibraryVariableStorage.Dequeue(VarCode);
        SerialNo := VarCode;
        LibraryVariableStorage.Dequeue(VarCode);
        LotNo := VarCode;
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Create and Post Warehouse Receipt.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseLine."Document No.");
    end;

    local procedure RegisterWarehouseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindPutAwayLine(WarehouseActivityLine, SourceNo);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RunItemSalesReport(No: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("No.", No);
        REPORT.Run(REPORT::"Customer/Item Sales", true, false, Customer);
    end;

    local procedure RunItemSalesReportFilterOnPostingDate(ItemNo: Code[20]; StartDate: Date; EndDate: Date)
    begin
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(Format(StartDate) + '..' + Format(EndDate));
        REPORT.Run(REPORT::"Customer/Item Sales");
    end;

    local procedure RunCalculateInventoryReport(var ItemJournalBatch: Record "Item Journal Batch"; ItemFilter: Text; ItemNotOnInventory: Boolean; InclItemsWithNoTrans: Boolean)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreatePhysInventoryJournalBatch(ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        Item.SetFilter("No.", ItemFilter);
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, WorkDate(), ItemNotOnInventory, InclItemsWithNoTrans);
    end;

    local procedure RunCalculateInventoryReportRequestPage(ItemsNotInInvt: Boolean; ItemsWithNoTrans: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        CalculateInventory: Report "Calculate Inventory";
    begin
        CreateItemJournalForPhysInventory(ItemJournalLine);
        CalculateInventory.SetItemJnlLine(ItemJournalLine);
        CalculateInventory.InitializeRequest(WorkDate(), LibraryUtility.GenerateGUID(), ItemsNotInInvt, ItemsWithNoTrans);
        CalculateInventory.UseRequestPage(true);
        Commit();
        CalculateInventory.Run();
    end;

    local procedure RunInventoryCustomerSalesReport(No: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        REPORT.Run(REPORT::"Inventory - Customer Sales", true, false, Item);
    end;

    local procedure RunItemExpirationQuantityReport(EndDate: Date; PeriodLength: DateFormula; No: Code[20]; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        Item: Record Item;
        ItemExpirationQuantity: Report "Item Expiration - Quantity";
    begin
        Item.SetRange("No.", No);
        Item.SetFilter("Location Filter", StrSubstNo(LocationFilter, LocationCode, LocationCode2));
        EnqueueValuesForItemExpirationQuantityReport(EndDate, PeriodLength);
        Clear(ItemExpirationQuantity);
        ItemExpirationQuantity.SetTableView(Item);
        ItemExpirationQuantity.Run();
    end;

    local procedure RunInventoryValuationReport(No: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(CalcDate('<CY>', WorkDate())); // Calc. for the current year.
        LibraryVariableStorage.Enqueue(true);  // Include expected cost.
        REPORT.Run(REPORT::"Inventory Valuation", true, false, Item);
    end;

    local procedure RunInventoryCostVarianceReport(No: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        REPORT.Run(REPORT::"Inventory - Cost Variance", true, false, Item);
    end;

    local procedure RunPhysInventoryListReport(ItemJournalBatch: Record "Item Journal Batch")
    var
        PhysInventoryList: Report "Phys. Inventory List";
    begin
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalBatch.SetRange(Name, ItemJournalBatch.Name);
        Commit();  // Commit required before running this Report.
        Clear(PhysInventoryList);
        PhysInventoryList.SetTableView(ItemJournalBatch);
        PhysInventoryList.Run();
    end;

    local procedure RunItemTrackingAppendixReport()
    var
        ItemTrackingAppendix: Report "Item Tracking Appendix";
    begin
        Clear(ItemTrackingAppendix);
        ItemTrackingAppendix.UseRequestPage(true);
        ItemTrackingAppendix.Run();
    end;

    local procedure RunRevaluationPostingTestReport(ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        REPORT.Run(REPORT::"Revaluation Posting - Test", true, false, ItemJournalLine);
    end;

    local procedure RunStatusReport(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Commit();
        Item.SetRange("No.", ItemNo);
        REPORT.Run(REPORT::Status, true, false, Item);
    end;

    local procedure RunCalculateInventoryReportWithItem(var ItemJournalBatch: Record "Item Journal Batch"; var Item: Record Item; ItemNotOnInventory: Boolean; InclItemsWithNoTrans: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreatePhysInventoryJournalBatch(ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, WorkDate(), ItemNotOnInventory, InclItemsWithNoTrans);
    end;

    local procedure SaveSalesRetReceipt(No: Code[20])
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesReturnReceipt: Report "Sales - Return Receipt";
    begin
        ReturnReceiptHeader.SetRange("No.", No);
        LibraryVariableStorage.Enqueue(No);
        Commit();  // Commit required due to use of RUN.
        Clear(SalesReturnReceipt);
        SalesReturnReceipt.SetTableView(ReturnReceiptHeader);
        SalesReturnReceipt.Run();
    end;

    local procedure SaveSalesShipment(No: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("No.", No);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Sales - Shipment", true, false, SalesShipmentHeader);
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetupForSalesReport(var SalesLine: Record "Sales Line")
    begin
        // Create Item, create and post Sales Order.
        CreateAndPostSalesOrder(SalesLine, CreateItem());

        // Create and Post Purchase Order and run Adjust Cost Item Entries.
        CreateAndPostPurchaseOrder(SalesLine."No.", false);
        LibraryCosting.AdjustCostItemEntries(SalesLine."No.", '');
    end;

    local procedure UndoReturnReceipt(SalesLine: Record "Sales Line")
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        FindReturnReceiptLine(ReturnReceiptLine, SalesLine);
        LibraryVariableStorage.Enqueue(UndoSalesRetRcptMessage);
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);
    end;

    local procedure UndoSalesShipment(SalesLine: Record "Sales Line")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        FindShipmentLine(SalesShipmentLine, SalesLine."No.");
        LibraryVariableStorage.Enqueue(UndoSalesShptMessage);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UpdateExpirationDateOnReservEntry(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindSet();
        repeat
            ReservationEntry.Validate("Expiration Date", ExpirationDate);
            ReservationEntry.Modify(true);
        until ReservationEntry.Next() = 0;
    end;

    local procedure UpdatePostingDateOnSalesHeader(var SalesHeader: Record "Sales Header"; NewPostingDate: Date)
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesHeader.Validate("Posting Date", NewPostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure VerifyFIFOItemStatusReport(ItemNo: Code[20])
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        Item.Get(ItemNo);
        LibraryReportDataset.LoadDataSetFile();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.FindSet();
        repeat
            LibraryReportDataset.FindRow('DocumentNo_ItemLedgerEntry', ItemLedgerEntry."Document No.");
            LibraryReportDataset.AssertElementWithValueExists('RemainingQty', ItemLedgerEntry."Remaining Quantity");
            LibraryReportDataset.AssertElementWithValueExists('InvtValue2', ItemLedgerEntry."Remaining Quantity" * Item."Unit Cost");
        until ItemLedgerEntry.Next() = 0;

        LibraryReportDataset.Reset();
        ItemLedgerEntry.SetRange(Open, false);
        ItemLedgerEntry.FindSet();
        repeat
            LibraryReportDataset.AssertElementWithValueNotExist('DocumentNo_ItemLedgerEntry', ItemLedgerEntry."Document No.");
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyAverageItemStatusReport(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibraryReportDataset.LoadDataSetFile();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            LibraryReportDataset.FindRow('DocumentNo_ItemLedgerEntry', ItemLedgerEntry."Document No.");
            LibraryReportDataset.AssertElementWithValueExists('RemainingQty', ItemLedgerEntry.Quantity);
            LibraryReportDataset.AssertElementWithValueExists('InvtValue2', ItemLedgerEntry."Cost Amount (Actual)");
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyLotNoOnItemTrackingAppendixReport(No: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ItemTrackingLine', No);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('LotNo', LotNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_ItemTrackingLine', Quantity);
    end;

    local procedure VerifyItemTrackingAppendixReport(No: Code[20]; LotNo: Code[50]; SerialNo: Code[50])
    begin
        VerifyLotNoOnItemTrackingAppendixReport(No, LotNo, 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('SerialNo_ItemTrackingLine', SerialNo);
    end;

    local procedure VerifyItemExpirationQuantityReport(ItemNo: Code[20]; Inventory: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ItemNo);

        Assert.AreEqual(Inventory, LibraryReportDataset.Sum('InvtQty4'), 'Wrong end date qty in report.');
        Assert.AreEqual(Inventory, LibraryReportDataset.Sum('TotalInvtQty'), 'Wrong total qty in report.');
    end;

    local procedure VerifyInventoryValuationReport(SalesLine: Record "Sales Line"; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo', SalesLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DecreaseInvoicedQty', SalesLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('DecreaseInvoicedValue', -Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('EndingInvoicedValue', Amount);
    end;

    local procedure VerifyInventoryCostVarianceReport(ItemLedgerEntry: Record "Item Ledger Entry"; StandardCost: Decimal; DocumentNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocNo_ItemLedgerEntry', DocumentNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('PostDate_ItemLedgerEntry', Format(ItemLedgerEntry."Posting Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('StandardCost_Item', StandardCost);
    end;

    local procedure VerifyPhysInventoryListReport(ItemNo: Code[20]; Qty: Decimal; LotNo: Code[50]; SerialNo: Code[50]; ShowQty: Boolean; ShowLot: Boolean; ShowSerial: Boolean)
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('ItemNo_ItemJournalLine', ItemNo);
        LibraryReportDataset.AssertElementWithValueExists('ShowQtyCalculated', ShowQty);
        LibraryReportDataset.AssertElementWithValueExists('QtyCalculated_ItemJnlLin', Qty);

        if ShowLot then
            LibraryReportDataset.AssertElementWithValueExists('ReservEntryBufferLotNo', LotNo)
        else
            asserterror LibraryReportDataset.AssertElementWithValueExists('ReservEntryBufferLotNo', LotNo);

        if ShowSerial then
            LibraryReportDataset.AssertElementWithValueExists('ReservEntryBufferSerialNo', SerialNo)
        else
            asserterror LibraryReportDataset.AssertElementWithValueExists('ReservEntryBufferSerialNo', SerialNo);
    end;

    local procedure VerifyPostedSalesReport(SalesLine: Record "Sales Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        case SalesLine."Document Type" of
            SalesLine."Document Type"::Order:
                begin
                    LibraryReportDataset.SetRange('No_SalesShptLine', SalesLine."No.");
                    LibraryReportDataset.GetNextRow();
                    LibraryReportDataset.AssertCurrentRowValueEquals('Qty_SalesShptLine', SalesLine.Quantity);
                end;
            SalesLine."Document Type"::"Return Order":
                begin
                    LibraryReportDataset.SetRange('No_ReturnReceiptLine', SalesLine."No.");
                    LibraryReportDataset.GetNextRow();
                    LibraryReportDataset.AssertCurrentRowValueEquals('Qty_ReturnReceiptLine', SalesLine.Quantity);
                end;
        end;
    end;

    local procedure VerifyReportItemLine(ItemNo: Code[20]; var ValueEntry: Record "Value Entry")
    var
        PurchItemChargeAmt: Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('ValueEntryBuffer__Item_No__', ItemNo);
        LibraryReportDataset.GetNextRow();

        ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)");
        PurchItemChargeAmt := ValueEntry."Cost Amount (Non-Invtbl.)";

        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.CalcSums("Invoiced Quantity", "Sales Amount (Actual)", "Cost Amount (Actual)");
        LibraryReportDataset.AssertCurrentRowValueEquals('ValueEntryBuffer__Invoiced_Quantity_', -ValueEntry."Invoiced Quantity");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'ValueEntryBuffer__Sales_Amount__Actual___Control44', ValueEntry."Sales Amount (Actual)");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Profit_Control46', ValueEntry."Sales Amount (Actual)" + ValueEntry."Cost Amount (Actual)" + PurchItemChargeAmt);
    end;

    local procedure VerifyRevaluationPostingTestReport(ItemJournalLine: Record "Item Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Item_Journal_Line__Item_No__', ItemJournalLine."Item No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Item_Journal_Line_Quantity', ItemJournalLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('Item_Journal_Line__Inventory_Value__Revalued__',
          ItemJournalLine."Inventory Value (Revalued)");
    end;

    local procedure VerifySalesReportAfterPostSalesOrder(ItemNo: Code[20]; CustomerNo: Code[20]; ItemNoElementName: Text; CustNameElementName: Text; SalesAmtElementName: Text; ProfitElementName: Text)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.CalcFields("Sales Amount (Actual)", "Cost Amount (Actual)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ItemNoElementName, ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(CustNameElementName, CustomerNo);
        LibraryReportDataset.AssertCurrentRowValueEquals(SalesAmtElementName, ItemLedgerEntry."Sales Amount (Actual)");
        LibraryReportDataset.AssertCurrentRowValueEquals(ProfitElementName, ItemLedgerEntry."Sales Amount (Actual)" +
          ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateNewLotNo.SetValue(true);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            TrackingOption::AssignSerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    ItemTrackingLines.First();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Serial No.".Value);
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
                end;
            TrackingOption::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
                end;
            TrackingOption::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixRequestPageHandler(var ItemTrackingAppendix: TestRequestPage "Item Tracking Appendix")
    var
        Document: Variant;
        DocumentNo: Variant;
        FileName: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Item Tracking Appendix";
        LibraryVariableStorage.Dequeue(Document);
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(FileName);
        ItemTrackingAppendix.Document.SetValue(Document);
        ItemTrackingAppendix.DocumentNo.SetValue(DocumentNo);
        ItemTrackingAppendix.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemExpirationQuantityRequestPageHandler(var ItemExpirationQuantity: TestRequestPage "Item Expiration - Quantity")
    var
        EndingDate: Variant;
        PeriodLength: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Item Expiration - Quantity";
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(PeriodLength);
        ItemExpirationQuantity.EndingDate.SetValue(EndingDate);
        ItemExpirationQuantity.PeriodLength.SetValue(PeriodLength);
        ItemExpirationQuantity.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; UnitAmount: Decimal; EntryType: Enum "Item Ledger Document Type")
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostPurchItemChargeAssignedToShipment(VendorNo: Code[20]; PostingDate: Date; SalesShipmentLine: Record "Sales Shipment Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);

        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine,
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Sales Shipment", SalesShipmentLine."Document No.",
          SalesShipmentLine."Line No.", SalesShipmentLine."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostSalesItemChargeAssignedToShipment(CustomerNo: Code[20]; PostingDate: Date; SalesShipmentLine: Record "Sales Shipment Line")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);

        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine,
          ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment, SalesShipmentLine."Document No.",
          SalesShipmentLine."Line No.", SalesShipmentLine."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnReceiptRequestPageHandler(var SalesReturnReceipt: TestRequestPage "Sales - Return Receipt")
    var
        FileName: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Sales - Return Receipt";
        LibraryVariableStorage.Dequeue(FileName);
        SalesReturnReceipt.ShowCorrectionLines.SetValue(true);
        SalesReturnReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInventoryListRequestPageHandler(var PhysInventoryList: TestRequestPage "Phys. Inventory List")
    var
        ShowQtyCalculated: Variant;
        ShowSerialLotNumber: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Phys. Inventory List";
        LibraryVariableStorage.Dequeue(ShowQtyCalculated);
        LibraryVariableStorage.Dequeue(ShowSerialLotNumber);
        PhysInventoryList.ShowCalculatedQty.SetValue(ShowQtyCalculated);
        PhysInventoryList.ShowSerialLotNumber.SetValue(ShowSerialLotNumber);
        PhysInventoryList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentRequestPageHandler(var SalesShipment: TestRequestPage "Sales - Shipment")
    var
        NoOfCopies: Variant;
        ShowInternalInfo: Variant;
        LogInteraction: Variant;
        ShowCorrectionLines: Variant;
        ShowLotSN: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Sales - Shipment";
        LibraryVariableStorage.Dequeue(NoOfCopies);
        LibraryVariableStorage.Dequeue(ShowInternalInfo);
        LibraryVariableStorage.Dequeue(LogInteraction);
        LibraryVariableStorage.Dequeue(ShowCorrectionLines);
        LibraryVariableStorage.Dequeue(ShowLotSN);

        SalesShipment.NoOfCopies.SetValue(NoOfCopies);
        SalesShipment.ShowInternalInfo.SetValue(ShowInternalInfo);
        SalesShipment.LogInteraction.SetValue(LogInteraction);
        SalesShipment."Show Correction Lines".SetValue(ShowCorrectionLines);
        SalesShipment.ShowLotSN.SetValue(ShowLotSN);
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryCustomersSalesRequestPageHandler(var InventoryCustomerSales: TestRequestPage "Inventory - Customer Sales")
    begin
        CurrentSaveValuesId := REPORT::"Inventory - Customer Sales";
        InventoryCustomerSales.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerItemSalesRequestPageHandler(var CustomerItemSales: TestRequestPage "Customer/Item Sales")
    begin
        CurrentSaveValuesId := REPORT::"Customer/Item Sales";
        CustomerItemSales.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerItemSalesRequestFilterOnPostingDatePageHandler(var CustomerItemSales: TestRequestPage "Customer/Item Sales")
    begin
        CurrentSaveValuesId := REPORT::"Customer/Item Sales";
        CustomerItemSales."Value Entry".SetFilter("Item No.", LibraryVariableStorage.DequeueText());
        CustomerItemSales."Value Entry".SetFilter("Posting Date", LibraryVariableStorage.DequeueText());
        CustomerItemSales.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValuationRequestPageHandler(var InventoryValuation: TestRequestPage "Inventory Valuation")
    var
        StartDate: Variant;
        EndDate: Variant;
        InclExpCost: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Inventory Valuation";
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        LibraryVariableStorage.Dequeue(InclExpCost);

        InventoryValuation.StartingDate.SetValue(StartDate);
        InventoryValuation.EndingDate.SetValue(EndDate);
        InventoryValuation.IncludeExpectedCost.SetValue(InclExpCost);

        InventoryValuation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RevaluationPostingTestRequestPageHandler(var RevaluationPostingTest: TestRequestPage "Revaluation Posting - Test")
    begin
        CurrentSaveValuesId := REPORT::"Revaluation Posting - Test";
        RevaluationPostingTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryCostVarianceRequestPageHandler(var InventoryCostVariance: TestRequestPage "Inventory - Cost Variance")
    begin
        CurrentSaveValuesId := REPORT::"Inventory - Cost Variance";
        InventoryCostVariance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatusRequestPageHandler(var Status: TestRequestPage Status)
    begin
        CurrentSaveValuesId := REPORT::Status;
        Status.StatusDate.SetValue(WorkDate());
        Status.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateInventoryRequestPageHandler(var CalculateInventory: TestRequestPage "Calculate Inventory")
    begin
        LibraryVariableStorage.Enqueue(CalculateInventory.ItemsNotOnInventory.Value);
        LibraryVariableStorage.Enqueue(CalculateInventory.IncludeItemWithNoTransaction.Value);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;
}

