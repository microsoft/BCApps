codeunit 137262 "SCM Invt Item Tracking III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Tracking] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryResource: Codeunit "Library - Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        TrackingOption: Option AssignSerialLot,AssignLotNo,SelectEntries,SetLotNo,SetQuantity,SetLotNoAndQty,SetSerialNoAndQty,SelectAndApplyToItemEntry,SetEntriesToInvoice,InvokeOK,AssignLotNoManual;
        isInitialized: Boolean;
        TrackingOptionWithTwoLots: Option AssignLotNoWithQtyToHandle,ChangeQtyToInvoice,OrderDocument,ReturnOrderDocument;
        LotNoWithTwoLots: array[2] of Code[20];
        ItemTrackingExistErr: Label 'You must delete the existing item tracking before modifying';
        ItemTrackingQuantityErr: Label 'Item tracking defined for item %1 in the %2 accounts for more than the quantity you have entered.';
        DescriptionErr: Label 'Description must match.';
        ReleasedProductionOrderOutputLbl: Label 'Released Production Order Output';
        QuantityErr: Label 'Quantity is Incorrect';
        WrongSerialNoErr: Label 'Wrong Serial No. in Pick Line.';
        SalesLineBinCodeErr: Label 'Incorrect Bin Code';
        WrongFieldValueErr: Label 'Incorrect value of %1 in %2';
        TransferReceiptLineNotExistsErr: Label 'Transfer Receipt Line not exists.';
        ClearApplEntryErr: Label 'Incorrect Appl. Item Entry clearing.';
        WrongInvoicedQtyErr: Label 'Quantity Invoiced is incorrect in %1.', Comment = '%1=Purch. Rcpt. Line table caption';
        WrongNoOfComponentEntriesErr: Label 'Wrong number of assembly component entries is shown in Item Tracing.';
        WrongQtyForItemErr: Label '%1 in the item tracking assigned to the document line for item %2 is currently %3. It must be %4.\\Check the assignment for serial number %5, lot number %6, package number %7.', Comment = '%1 - Qty. to Handle or Qty. to Invoice, %2 - Item No., %3 - actual value, %4 - expected value, %5 - Serial No., %6 - Lot No., %7 - Package No.';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateBinCodeFromSalesLineWhenProdOrderIsCreated()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        BinContent: Record "Bin Content";
        BinContent2: Record "Bin Content";
        ItemNo: Code[20];
    begin
        // [SCENARIO 360930] It is allowed to change Bin Code from Sales Line When Production Order is Created from Sales Order
        Initialize();

        // [GIVEN] Tracked Item "X" with two Bin Contents "B1", "B2". Warehouse Item Tracking enabled
        ItemNo := CreateTrackedItemWithTwoBinContents(BinContent, BinContent2);

        // [GIVEN] Sales Order Line for Item "X" with "Bin Code" = "B1"
        CreateSalesOrderWithRandomQty(SalesHeader, SalesLine, BinContent."Location Code", BinContent."Bin Code", ItemNo);

        // [GIVEN] Released Production Order created from Sales Order with Positive and Negative Reservation Entry
        CreateReleasedProdOrderWithReservEntry(SalesHeader, SalesLine);

        // [WHEN] Change Sales Line's "Bin Code" to "B2"
        ChangeBinCodeInSalesLine(SalesLine, BinContent2."Bin Code");

        // [THEN] Sales Line's "Bin Code" = "B2"
        Assert.AreEqual(BinContent2."Bin Code", SalesLine."Bin Code", SalesLineBinCodeErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoPstdPurchDocumentWithOriginUsage()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward (Origin -> Usage) with Item Tracking for Posted Purchase Document.

        // Setup.
        Initialize();
        SetupTrackingEntryForSalesAndPurchase(ItemLedgerEntry, TrackingOption::AssignLotNo, false, true);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', '', ItemLedgerEntry."Lot No.", TraceMethod::"Origin -> Usage");

        // Verify: Verify Item Tracing Page for Posted Document.
        VerifyItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          ItemLedgerEntry."Location Code", ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoPstdPurchDocumentWithUsageOrigin()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Backward (Usage -> Origin) with Item Tracking for Posted Purchase Document.

        // Setup.
        Initialize();
        SetupTrackingEntryForSalesAndPurchase(ItemLedgerEntry, TrackingOption::AssignLotNo, false, true);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', '', ItemLedgerEntry."Lot No.", TraceMethod::"Usage -> Origin");

        // Verify: Verify Item Tracing Page for Posted Document.
        VerifyNextItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          ItemLedgerEntry."Location Code", ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoPstdSalesDocumentWithUsageOrigin()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward (Origin -> Usage) with Item Tracking for Posted Sales Document.

        // Setup.
        Initialize();
        SetupTrackingEntryForSalesAndPurchase(ItemLedgerEntry, TrackingOption::AssignLotNo, false, true);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', '', ItemLedgerEntry."Lot No.", TraceMethod::"Usage -> Origin");

        // Verify: Verify Item Tracing Page for Posted Document.
        VerifyItemTracingLine(
          ItemTracing, SalesShipmentHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          ItemLedgerEntry."Location Code", -ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoPstdSalesDocumentWithOriginUsage()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward (Origin -> Usage) with Item Tracking for Long Chain Posted Documents (Purchase Order,Transfer Order,Sales Order).

        // Setup.
        Initialize();
        SetupTrackingEntryForSalesAndPurchase(ItemLedgerEntry, TrackingOption::AssignLotNo, false, true);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', '', ItemLedgerEntry."Lot No.", TraceMethod::"Origin -> Usage");

        // Verify: Verify Item Tracing Page for Posted Document.
        VerifyNextItemTracingLine(
          ItemTracing, SalesShipmentHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          ItemLedgerEntry."Location Code", -ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoForLongChainPstdDocumentWithOriginUsage()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward (Usage -> Origin) with Item Tracking for Long Chain Posted Documents (Purchase Order,Transfer Order,Sales Order).
        SetupLOTNoForLongChainPstdDocument(ItemLedgerEntry, TransferLine, TrackingOption::AssignLotNo, false, true);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', '', ItemLedgerEntry."Lot No.", TraceMethod::"Origin -> Usage");

        // Verify: Verify Item Tracing Page for different Posted Documents.
        VerifyItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."Transfer-from Code", ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferShipmentHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."Transfer-from Code", -ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferShipmentHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."In-Transit Code", ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferReceiptHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."In-Transit Code", -ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferReceiptHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."Transfer-to Code", ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, SalesShipmentHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."Transfer-to Code", -ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoForLongChainPstdDocumentWithUsageOrigin()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Opposite from Line using Trace Method with Item Tracking for Posted Purchase Document.
        SetupLOTNoForLongChainPstdDocument(ItemLedgerEntry, TransferLine, TrackingOption::AssignLotNo, false, true);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', '', ItemLedgerEntry."Lot No.", TraceMethod::"Usage -> Origin");

        // Verify: Verify Item Tracing Page for different Posted Documents.
        VerifyItemTracingLine(
          ItemTracing, SalesShipmentHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."Transfer-to Code", -ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferReceiptHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."Transfer-to Code", ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferReceiptHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."In-Transit Code", -ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferShipmentHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."In-Transit Code", ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferShipmentHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."Transfer-from Code", -ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."Transfer-from Code", ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure TraceOppositeFromLineForPstdPurchDocument()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Opposite from Line using Trace Method with Item Tracking for Posted Purchase Document.

        // Setup.
        Initialize();
        SetupTrackingEntryForSalesAndPurchase(ItemLedgerEntry, TrackingOption::AssignLotNo, false, true);
        OpenItemTracingPage(ItemTracing, '', '', ItemLedgerEntry."Lot No.", TraceMethod::"Origin -> Usage");

        // Exercise.
        ItemTracing.TraceOppositeFromLine.Invoke();

        // Verify: Verify Item Tracing Page with Trace Opposite From Line Option.
        VerifyItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          ItemLedgerEntry."Location Code", ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoForRlsdProdOrder()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward with Item Tracking for Released Production Order.

        // Setup.
        Initialize();
        Item.Get(CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true)));
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);

        // Create Released Production Order and Post Output.
        CreateAndRefreshProductionOrderWithIT(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), TrackingOption::AssignLotNo);
        CreateAndPostOutputJournal(ProductionOrder."No.");
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.");

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', '', ItemLedgerEntry."Lot No.", TraceMethod::"Usage -> Origin");

        // Verify: Verify Item Tracing Page for Posted Document.
        VerifyItemTracingLine(
          ItemTracing, ReleasedProductionOrderOutputLbl, '', ItemLedgerEntry."Lot No.", Item."No.", ProductionOrder."Location Code",
          ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoForReclassJouranl()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        NewLocation: Record Location;
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method with Item Tracking for Reclass Journal.

        // Setup.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(NewLocation);

        Item.Get(CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true)));
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, Item."No.", Location.Code, TrackingOption::AssignLotNo);
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.");

        // Create Reclass Journal and Using Post Transfer Inventory From One Location to Another Location.
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer,
          Item."No.", PurchaseLine.Quantity);  // Use Random value for Quantity.
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("New Location Code", NewLocation.Code);
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateAndPostSalesOrderWithIT(SalesLine, Item."No.", NewLocation.Code, PurchaseLine.Quantity, false);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', '', ItemLedgerEntry."Lot No.", TraceMethod::"Usage -> Origin");

        // Verify: Verify Item Tracing Page for different Posted Documents.
        VerifyItemTracingLine(
          ItemTracing, SalesShipmentHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", Item."No.", NewLocation.Code, -PurchaseLine.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, ItemLedgerEntry.TableCaption(), '', ItemLedgerEntry."Lot No.", Item."No.", NewLocation.Code, PurchaseLine.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, ItemLedgerEntry.TableCaption(), '', ItemLedgerEntry."Lot No.", Item."No.", Location.Code, -PurchaseLine.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), '', ItemLedgerEntry."Lot No.", Item."No.", Location.Code, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoForPositiveAdjmtJouranlWithUsageOrigin()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Quantity: Decimal;
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Backward with Item Tracking for Positive Adjustment from Item Journal.
        Quantity := LibraryRandom.RandInt(10);
        SlAndLOTNoForPositiveAdjmt(
          TraceMethod::"Usage -> Origin", SalesShipmentHeader.TableCaption(), ItemLedgerEntry.TableCaption(), Quantity, -Quantity, Quantity,
          false, true, TrackingOption::AssignLotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoForPositiveAdjmtJouranlWithOriginUsage()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Quantity: Decimal;
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward with Item Tracking for Positive Adjustment from Item Journal.
        Quantity := LibraryRandom.RandInt(10);
        SlAndLOTNoForPositiveAdjmt(
          TraceMethod::"Origin -> Usage", ItemLedgerEntry.TableCaption(), SalesShipmentHeader.TableCaption(), Quantity, Quantity, -Quantity,
          false, true, TrackingOption::AssignLotNo);
    end;

    local procedure SlAndLOTNoForPositiveAdjmt(TraceMethod: Option; Description: Text; Description2: Text; Quantity: Decimal; Quantity2: Decimal; Quantity3: Decimal; SNSpecific: Boolean; LOTSpecific: Boolean; TrackingOption: Option)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        ItemTracing: TestPage "Item Tracing";
        ItemNo: Code[20];
    begin
        // Setup.
        Initialize();
        ItemNo :=
          CreateTrackedItem(
            LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(SNSpecific, LOTSpecific));
        CreateItemJournalLineWithIT(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", TrackingOption, ItemNo, Quantity);
        PostOutputJournal(ItemJournalLine);
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        CreateAndPostSalesOrderWithIT(SalesLine, ItemNo, '', ItemJournalLine.Quantity, false);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", TraceMethod);

        // Validate Item Tracing
        VerifyItemTracingLine(ItemTracing, Description, ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", ItemNo, '', Quantity2);
        VerifyNextItemTracingLine(ItemTracing, Description2, ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", ItemNo, '', Quantity3);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoForNegativeAdjmtJouranlWithUsageOrigin()
    var
        Quantity: Decimal;
        Quantity2: Decimal;
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Backward with Item Tracking for Negative Adjustment from Item Journal.
        Quantity := 5 + LibraryRandom.RandInt(10);
        Quantity2 := LibraryRandom.RandInt(5);
        SlAndLOTNoForNegativeAdjmt(
          TraceMethod::"Usage -> Origin", Quantity, Quantity2, -Quantity2, Quantity, false, true, TrackingOption::AssignLotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTNoForNegativeAdjmtJouranlWithOriginUsage()
    var
        Quantity: Integer;
        Quantity2: Integer;
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward with Item Tracking for Negative Adjustment from Item Journal.
        Quantity := 5 + LibraryRandom.RandInt(10);
        Quantity2 := LibraryRandom.RandInt(5);
        SlAndLOTNoForNegativeAdjmt(
          TraceMethod::"Origin -> Usage", Quantity, Quantity2, Quantity, -Quantity2, false, true, TrackingOption::AssignLotNo);
    end;

    local procedure SlAndLOTNoForNegativeAdjmt(TraceMethod: Option; Quantity: Decimal; Quantity2: Decimal; Quantity3: Decimal; Quantity4: Decimal; SNSpecific: Boolean; LOTSpecific: Boolean; TrackingOption2: Option)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTracing: TestPage "Item Tracing";
        ItemNo: Code[20];
    begin
        // Setup.
        Initialize();
        ItemNo :=
          CreateTrackedItem(
            LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(SNSpecific, LOTSpecific));
        CreateItemJournalLineWithIT(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", TrackingOption2, ItemNo, Quantity);
        PostOutputJournal(ItemJournalLine);
        CreateItemJournalLineWithIT(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", TrackingOption::SelectEntries, ItemNo, Quantity2);
        PostOutputJournal(ItemJournalLine);
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", TraceMethod);

        // Validate Item Tracing
        VerifyItemTracingLine(
          ItemTracing, ItemLedgerEntry.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", ItemNo, '', Quantity3);
        VerifyNextItemTracingLine(
          ItemTracing, ItemLedgerEntry.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", ItemNo, '', Quantity4);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputJournalWithReleasedProductionOrder()
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Routing Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalQuantity: Decimal;
    begin
        // Verify Item Ledger Entry for Posted Output Journal with Released Production Order.

        // Setup: Create Production BOM,Create Routing,Create Production Order with Auto Reserve,Create Output Journal.
        Initialize();
        CreateAndModifyItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateAndModifyItem(Item2, Item2."Replenishment System"::Purchase);
        CreateProductionBOM(ProductionBOMLine, Item2."No.", Item."Base Unit of Measure");
        CreateRouting(RoutingLine, ProductionBOMLine."Routing Link Code");

        // Add Production BOM No. and Routing No. to Item.
        UpdateItem(Item, ProductionBOMLine."Production BOM No.", RoutingLine."Routing No.");
        CreateLocationWithBin(Bin, Item2."No.");
        ItemJournalQuantity := (LibraryRandom.RandInt(10) + 10) * ProductionBOMLine."Quantity per";  // Take Random Value greater than OutputJournal Quantity.
        CreateItemJournalLineWithIT(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", TrackingOption::AssignLotNo, Item2."No.", ItemJournalQuantity);
        ModifyAndPostItemJournal(ItemJournalLine, Bin);
        CreateProductionOrderWithAutoReserve(ProductionOrder, Item."No.", ItemJournalQuantity, Bin."Location Code");
        CreateAndModifyOutputJournal(
          ItemJournalLine, ProductionOrder."No.", RoutingLine."Operation No.", Item."Gen. Prod. Posting Group", Item2."No.");
        ItemJournalQuantity := ItemJournalLine.Quantity;

        // Exercise: Post Output Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Item Ledger Entry.
        VerifyItemLedgerEntry(Item."No.", Bin."Location Code", ItemLedgerEntry."Entry Type"::Output, ItemJournalQuantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ILEAfterUpdateQtyMultipleTimes()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        Quantity: Decimal;
    begin
        // Verify Item Ledger Entry after posting Transfer Order as Ship for an Item with Item Tracking when Quantity updated multiple times for a Lot No.

        // Setup: Create Item, create Transfer Order and update Quantity on Item Tracking Line for same Lot No.
        Initialize();
        Item.Get(CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true)));  // TRUE for Lot Specific.
        CreateLocationWithBin(Bin, Item."No.");
        CreateItemJournalLineWithIT(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", TrackingOption::AssignLotNo, Item."No.",
          2 * LibraryRandom.RandInt(100));  // Use Random value for Quantity.
        ModifyAndPostItemJournal(ItemJournalLine, Bin);
        CreateTransferOrder(TransferLine, Bin."Location Code", Item."No.", ItemJournalLine.Quantity / 2);
        Quantity := LibraryRandom.RandDec(TransferLine.Quantity, 2);  // Use random value for Quantity less than Quantity on Transfer Line.
        UpdateQuantityOnItemTrackingLines(TransferLine, TransferLine.Quantity - Quantity);
        UpdateQuantityOnItemTrackingLines(TransferLine, TransferLine.Quantity);
        TransferHeader.Get(TransferLine."Document No.");

        // Exercise: Post Transfer Order as Ship.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // Verify: Verify Quantity on Item Ledger Entry.
        VerifyItemLedgerEntry(
          Item."No.", TransferLine."Transfer-from Code", ItemLedgerEntry."Entry Type"::Transfer, -TransferLine.Quantity);
        VerifyItemLedgerEntry(Item."No.", TransferLine."In-Transit Code", ItemLedgerEntry."Entry Type"::Transfer, TransferLine.Quantity);
    end;

    [Normal]
    local procedure LOTNoForLongTransferChain(TraceMethod: Option; CostingMethod: Enum "Costing Method")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTracing: TestPage "Item Tracing";
    begin
        SetupLongChainWithTransferAndLot(ItemLedgerEntry, CostingMethod);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', '', ItemLedgerEntry."Lot No.", TraceMethod);

        // Verify: Verify Item Tracing Page for different Posted Documents.
        ItemLedgerEntry.SetFilter("Entry Type", '<>%1', ItemLedgerEntry."Entry Type"::Sale);
        VerifyItemTracingLinesForLongChain(ItemLedgerEntry, ItemTracing, false);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        VerifyItemTracingLinesForLongChain(ItemLedgerEntry, ItemTracing, true);

        VerifyAlreadyTraced(ItemTracing);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LOTLongTransferChainUsageOriginFIFO()
    var
        Item: Record Item;
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        LOTNoForLongTransferChain(TraceMethod::"Usage -> Origin", Item."Costing Method"::FIFO);
    end;

    [Normal]
    local procedure SNLOTForLongProdChain(TraceMethod: Option)
    var
        CompItemLedgerEntry: Record "Item Ledger Entry";
        SubItemLedgerEntry: Record "Item Ledger Entry";
        TopItemLedgerEntry: Record "Item Ledger Entry";
        ItemTracing: TestPage "Item Tracing";
    begin
        SetupProdChainWithSN(CompItemLedgerEntry, SubItemLedgerEntry, TopItemLedgerEntry);

        // Check a random top item tracing entry.
        TopItemLedgerEntry.FindSet();
        TopItemLedgerEntry.Next(LibraryRandom.RandInt(TopItemLedgerEntry.Count));
        OpenItemTracingPage(
          ItemTracing, TopItemLedgerEntry."Item No.", TopItemLedgerEntry."Serial No.", TopItemLedgerEntry."Lot No.", TraceMethod);
        VerifySingleItemTracingLine(ItemTracing, TopItemLedgerEntry, 1);

        // Check a random subassembly item tracing entry - consumption and output.
        SubItemLedgerEntry.SetRange("Entry Type", SubItemLedgerEntry."Entry Type"::Consumption);
        SubItemLedgerEntry.FindSet();
        SubItemLedgerEntry.Next(LibraryRandom.RandInt(SubItemLedgerEntry.Count));
        VerifySingleItemTracingLine(ItemTracing, SubItemLedgerEntry, 1);

        SubItemLedgerEntry.SetRange("Entry Type", SubItemLedgerEntry."Entry Type"::Output);
        SubItemLedgerEntry.FindSet();
        SubItemLedgerEntry.Next(LibraryRandom.RandInt(SubItemLedgerEntry.Count));
        VerifySingleItemTracingLine(ItemTracing, SubItemLedgerEntry, 1);

        // Check consumption entries for component item.
        CompItemLedgerEntry.SetRange("Entry Type", CompItemLedgerEntry."Entry Type"::Consumption);
        CompItemLedgerEntry.FindSet();
        repeat
            VerifySingleItemTracingLine(ItemTracing, CompItemLedgerEntry, CompItemLedgerEntry.Count);
        until CompItemLedgerEntry.Next() = 0;

        // Check purchase entries for component item - should only be traced once per serial/lot/item.
        CompItemLedgerEntry.SetRange("Entry Type", CompItemLedgerEntry."Entry Type"::Purchase);
        CompItemLedgerEntry.SetRange("Remaining Quantity", 0);
        CompItemLedgerEntry.FindSet();
        repeat
            VerifySingleItemTracingLine(ItemTracing, CompItemLedgerEntry, 1);
        until CompItemLedgerEntry.Next() = 0;

        ItemTracing.Close();
        OpenItemTracingPage(ItemTracing, TopItemLedgerEntry."Item No.", '', '', TraceMethod);
        VerifyAlreadyTraced(ItemTracing);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SNLOTLongProdChainUsageOrigin()
    var
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        SNLOTForLongProdChain(TraceMethod::"Usage -> Origin");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoPstdPurchDocumentWithOriginUsage()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward (Origin -> Usage) with Item Tracking for Posted Purchase Document.

        // Setup.
        Initialize();
        SetupTrackingEntryForSalesAndPurchase(ItemLedgerEntry, TrackingOption::AssignSerialLot, true, false);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', ItemLedgerEntry."Serial No.", '', TraceMethod::"Origin -> Usage");

        // Verify: Verify Item Tracing Page for Posted Document.
        VerifyItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          ItemLedgerEntry."Location Code", ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoPstdPurchDocumentWithUsageOrigin()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Backward (Usage -> Origin) with Item Tracking for Posted Purchase Document.

        // Setup.
        Initialize();
        SetupTrackingEntryForSalesAndPurchase(ItemLedgerEntry, TrackingOption::AssignSerialLot, true, false);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', ItemLedgerEntry."Serial No.", '', TraceMethod::"Usage -> Origin");

        // Verify: Verify Item Tracing Page for Posted Document.
        VerifyNextItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          ItemLedgerEntry."Location Code", ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoPstdSalesDocumentWithUsageOrigin()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward (Origin -> Usage) with Item Tracking for Posted Sales Document.

        // Setup.
        Initialize();
        SetupTrackingEntryForSalesAndPurchase(ItemLedgerEntry, TrackingOption::AssignSerialLot, true, false);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', ItemLedgerEntry."Serial No.", '', TraceMethod::"Usage -> Origin");

        // Verify: Verify Item Tracing Page for Posted Document.
        VerifyItemTracingLine(
          ItemTracing, SalesShipmentHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", ItemLedgerEntry."Location Code", -ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoPstdSalesDocumentWithOriginUsage()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward (Origin -> Usage) with Item Tracking for Long Chain Posted Documents (Purchase Order,Transfer Order,Sales Order).

        // Setup.
        Initialize();
        SetupTrackingEntryForSalesAndPurchase(ItemLedgerEntry, TrackingOption::AssignSerialLot, true, false);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', ItemLedgerEntry."Serial No.", '', TraceMethod::"Origin -> Usage");

        // Verify: Verify Item Tracing Page for Posted Document.
        VerifyNextItemTracingLine(
          ItemTracing, SalesShipmentHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", ItemLedgerEntry."Location Code", -ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoForLongChainPstdDocumentWithOriginUsage()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward (Usage -> Origin) with Item Tracking for Long Chain Posted Documents (Purchase Order,Transfer Order,Sales Order).
        SetupLOTNoForLongChainPstdDocument(ItemLedgerEntry, TransferLine, TrackingOption::AssignSerialLot, true, false);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', ItemLedgerEntry."Serial No.", '', TraceMethod::"Origin -> Usage");

        // Verify: Verify Item Tracing Page for different Posted Documents.
        VerifyItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."Transfer-from Code", ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferShipmentHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", TransferLine."Transfer-from Code", -ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferShipmentHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", TransferLine."In-Transit Code", ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferReceiptHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", TransferLine."In-Transit Code", -ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferReceiptHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", TransferLine."Transfer-to Code", ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, SalesShipmentHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", TransferLine."Transfer-to Code", -ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoForLongChainPstdDocumentWithUsageOrigin()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Opposite from Line using Trace Method with Item Tracking for Posted Purchase Document.
        SetupLOTNoForLongChainPstdDocument(ItemLedgerEntry, TransferLine, TrackingOption::AssignSerialLot, true, false);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', ItemLedgerEntry."Serial No.", '', TraceMethod::"Usage -> Origin");

        // Verify: Verify Item Tracing Page for different Posted Documents.
        VerifyItemTracingLine(
          ItemTracing, SalesShipmentHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", TransferLine."Transfer-to Code", -ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferReceiptHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", TransferLine."Transfer-to Code", ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferReceiptHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", TransferLine."In-Transit Code", -ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferShipmentHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", TransferLine."In-Transit Code", ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, TransferShipmentHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.",
          ItemLedgerEntry."Item No.", TransferLine."Transfer-from Code", -ItemLedgerEntry.Quantity);
        VerifyNextItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          TransferLine."Transfer-from Code", ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure TraceOppositeFromLineForPstdPurchDocumentSlNo()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Opposite from Line using Trace Method with Item Tracking for Posted Purchase Document.

        // Setup.
        Initialize();
        SetupTrackingEntryForSalesAndPurchase(ItemLedgerEntry, TrackingOption::AssignSerialLot, true, false);
        OpenItemTracingPage(ItemTracing, '', ItemLedgerEntry."Serial No.", '', TraceMethod::"Origin -> Usage");

        // Exercise.
        ItemTracing.TraceOppositeFromLine.Invoke();

        // Verify: Verify Item Tracing Page with Trace Opposite From Line Option.
        VerifyItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", ItemLedgerEntry."Item No.",
          ItemLedgerEntry."Location Code", ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoForRlsdProdOrder()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward with Item Tracking for Released Production Order.

        // Setup.
        Initialize();
        Item.Get(
          CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, false)));
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);

        // Create Released Production Order and Post Output.
        CreateAndRefreshProductionOrderWithIT(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), TrackingOption::AssignSerialLot);
        CreateAndPostOutputJournal(ProductionOrder."No.");
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.");

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', ItemLedgerEntry."Serial No.", '', TraceMethod::"Usage -> Origin");

        // Verify: Verify Item Tracing Page for Posted Document.
        VerifyItemTracingLine(
          ItemTracing, ReleasedProductionOrderOutputLbl, ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", Item."No.",
          ProductionOrder."Location Code", 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoForReclassJouranl()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        NewLocation: Record Location;
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method with Item Tracking for Reclass Journal.

        // Setup.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(NewLocation);

        Item.Get(
          CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, false)));
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, Item."No.", Location.Code, TrackingOption::AssignSerialLot);
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.");

        // Create Reclass Journal and Using Post Transfer Inventory From One Location to Another Location.
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer,
          Item."No.", PurchaseLine.Quantity);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("New Location Code", NewLocation.Code);
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateAndPostSalesOrderWithIT(SalesLine, Item."No.", NewLocation.Code, PurchaseLine.Quantity, false);

        // Exercise.
        OpenItemTracingPage(ItemTracing, '', ItemLedgerEntry."Serial No.", '', TraceMethod::"Usage -> Origin");

        // Verify: Verify Item Tracing Page for different Posted Documents.
        VerifyItemTracingLine(
          ItemTracing, SalesShipmentHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", Item."No.",
          NewLocation.Code, -1);
        VerifyNextItemTracingLine(
          ItemTracing, ItemLedgerEntry.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", Item."No.", NewLocation.Code, 1);
        VerifyNextItemTracingLine(
          ItemTracing, ItemLedgerEntry.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", Item."No.", Location.Code, -1);
        VerifyNextItemTracingLine(
          ItemTracing, PurchRcptHeader.TableCaption(), ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", Item."No.", Location.Code, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoForPositiveAdjmtJouranlWithUsageOrigin()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Quantity: Decimal;
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Backward with Item Tracking for Positive Adjustment from Item Journal.
        Quantity := LibraryRandom.RandInt(10);
        SlAndLOTNoForPositiveAdjmt(
          TraceMethod::"Usage -> Origin", SalesShipmentHeader.TableCaption(), ItemLedgerEntry.TableCaption(), Quantity, -1, 1,
          true, false, TrackingOption::AssignSerialLot);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoForPositiveAdjmtJouranlWithOriginUsage()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Quantity: Decimal;
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward with Item Tracking for Positive Adjustment from Item Journal.
        Quantity := LibraryRandom.RandInt(10);
        SlAndLOTNoForPositiveAdjmt(
          TraceMethod::"Origin -> Usage", ItemLedgerEntry.TableCaption(), SalesShipmentHeader.TableCaption(), Quantity, 1, -1,
          true, false, TrackingOption::AssignSerialLot);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoForNegativeAdjmtJouranlWithUsageOrigin()
    var
        Quantity: Decimal;
        Quantity2: Decimal;
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Backward with Item Tracking for Negative Adjustment from Item Journal.
        Quantity := 5 + LibraryRandom.RandInt(10);
        Quantity2 := LibraryRandom.RandInt(5);
        SlAndLOTNoForNegativeAdjmt(TraceMethod::"Usage -> Origin", Quantity, Quantity2, -1, 1, true, false, TrackingOption::AssignSerialLot);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SlNoForNegativeAdjmtJouranlWithOriginUsage()
    var
        Quantity: Integer;
        Quantity2: Integer;
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // Verify Item Tracing Line using Trace Method Forward with Item Tracking for Negative Adjustment from Item Journal.
        Quantity := 5 + LibraryRandom.RandInt(10);
        Quantity2 := LibraryRandom.RandInt(5);
        SlAndLOTNoForNegativeAdjmt(TraceMethod::"Origin -> Usage", Quantity, Quantity2, 1, -1, true, false, TrackingOption::AssignSerialLot);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderWithLessQtyError()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Verify error while posting Sales Return Order with less Quantity as compared to quantity for same Lot No. using Get Posted Document Line to Reverse.

        // Setup: Create and post Item Journal Line, create and post Sales Order, create Sales Return Order using Get Posted Document Lines To Reverse.
        Initialize();
        CreateAndPostItemJournalLine(ItemJournalLine);
        DocumentNo := CreateAndPostSalesOrderWithIT(SalesLine, ItemJournalLine."Item No.", '', ItemJournalLine.Quantity / 2, true);  // Take partial Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesLine."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue value for PostedSalesDocumentLinesPageHandler.
        GetPostedDocToReverseOnSalesReturnOrder(SalesHeader."No.");

        // Exercise: Update Quantity on Sales Line.
        asserterror FindAndUpdateSalesLine(SalesHeader."No.", SalesHeader."Document Type");

        // Verify: Verify error while posting Sales Return Order with less quantity.
        Assert.ExpectedError(StrSubstNo(ItemTrackingQuantityErr, SalesLine."No.", SalesLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithLessQtyQtyError()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Verify error while posting Sales Credit Memo with less Quantity as compared to quantity for same Lot No. using Get Posted Document Line to Reverse.

        // Setup: Create and post Item Journal Line, create and post Sales Order, create Sales Credit Memo using Get Posted Document Lines To Reverse.
        Initialize();
        CreateAndPostItemJournalLine(ItemJournalLine);
        DocumentNo := CreateAndPostSalesOrderWithIT(SalesLine, ItemJournalLine."Item No.", '', ItemJournalLine.Quantity / 2, true);  // Take partial Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesLine."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue value for PostedSalesDocumentLinesPageHandler.
        GetPostedDocToReverseOnSalesCreditMemo(SalesHeader."No.");

        // Exercise: Update Quantity on Sales Line.
        asserterror FindAndUpdateSalesLine(SalesHeader."No.", SalesHeader."Document Type");

        // Verify: Verify error while posting Sales Credit Memo with less quantity.
        Assert.ExpectedError(StrSubstNo(ItemTrackingQuantityErr, SalesLine."No.", SalesLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnOrderWithLessQtyQtyError()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Verify error while posting Purchase Return Order with less Quantity as compared to quantity for same Lot No. using Get Posted Document Line to Reverse.

        // Setup: Create Item, create and post Purchase Order, create Purchase Return Order using Get Posted Document Lines To Reverse.
        Initialize();
        DocumentNo :=
          CreateAndPostPurchaseOrderWithIT(
            PurchaseLine, CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true)), '',
            TrackingOption::AssignLotNo);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseLine."Buy-from Vendor No.");
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue value for PostedPurchaseDocumentLinesPageHandler.
        GetPostedDocToReverseOnPurchReturnOrder(PurchaseHeader."No.");

        // Exercise: Update Quantity on Sales Line.
        asserterror FindAndUpdatePurchaseLine(PurchaseHeader."No.", PurchaseHeader."Document Type");

        // Verify: Verify error while posting Purchase Return Order with less quantity.
        Assert.ExpectedError(StrSubstNo(ItemTrackingQuantityErr, PurchaseLine."No.", PurchaseLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithLessQtyQtyError()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Verify error while posting Purchase Credit Memo with less Quantity as compared to quantity for same Lot No. using Get Posted Document Line to Reverse.

        // Setup: Create Item, create and post Purchase Order, create Purchase Return Order using Get Posted Document Lines To Reverse.
        Initialize();
        DocumentNo :=
          CreateAndPostPurchaseOrderWithIT(
            PurchaseLine, CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true)), '',
            TrackingOption::AssignLotNo);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.");
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue value for PostedPurchaseDocumentLinesPageHandler.
        GetPostedDocToReverseOnPurchCreditMemo(PurchaseHeader."No.");

        // Exercise: Update Quantity on Sales Line.
        asserterror FindAndUpdatePurchaseLine(PurchaseHeader."No.", PurchaseHeader."Document Type");

        // Verify: Verify error while posting Purchase Credit Memo with less quantity.
        Assert.ExpectedError(StrSubstNo(ItemTrackingQuantityErr, PurchaseLine."No.", PurchaseLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnItemJournalTC1()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: Existing Error
        ChangeBinWithLotITOnItemJournalS1(true, 1, ItemJournalLine."Entry Type"::"Negative Adjmt.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnItemJournalTC2()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnItemJournalS1(false, 1, ItemJournalLine."Entry Type"::"Negative Adjmt.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnItemJournalTC3()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnItemJournalS1(true, -1, ItemJournalLine."Entry Type"::Sale);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnItemJournalTC4()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnItemJournalS2(true, 1, ItemJournalLine."Entry Type"::Sale);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnItemJournalTC5()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnItemJournalS2(false, 1, ItemJournalLine."Entry Type"::"Negative Adjmt.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnItemJournalTC6()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnItemJournalS2(true, -1, ItemJournalLine."Entry Type"::Sale);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnItemJournalTC7()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: Existing Error
        ChangeBinWithLotITOnItemJournalS3(true, 1, ItemJournalLine."Entry Type"::Sale);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnItemJournalTC8()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnItemJournalS3(false, 1, ItemJournalLine."Entry Type"::"Negative Adjmt.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnItemJournalTC9()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnItemJournalS3(true, -1, ItemJournalLine."Entry Type"::"Negative Adjmt.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnItemJournalTC10()
    var
        ItemJournalLine: Record "Item Journal Line";
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        Initialize();
        SetupLotTrackingItemJournalLineForChangeBin(
          ItemJournalLine, 1, true, ItemJournalLine."Entry Type"::"Negative Adjmt.", SetNoOption::QtyNotEnoughNo);

        // Exercise: Change Bin, Bin code is blank
        // Verify: No Error
        ItemJournalLine.Validate("Bin Code", '');
    end;

    local procedure ChangeBinWithLotITOnItemJournalS1(WhseTracking: Boolean; SignFactor: Integer; EntryType: Enum "Item Ledger Document Type")
    var
        ItemJournalLine: Record "Item Journal Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking, create an item journal line with Bin code and
        // do item tracking with setting a Lot No. that the other Bin has no enough quantity
        Initialize();
        BinCode := SetupLotTrackingItemJournalLineForChangeBin(
            ItemJournalLine, SignFactor, WhseTracking, EntryType, SetNoOption::QtyNotEnoughNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnItemJournalLine(ItemJournalLine, BinCode, WhseTracking, SignFactor);
    end;

    local procedure ChangeBinWithLotITOnItemJournalS2(WhseTracking: Boolean; SignFactor: Integer; EntryType: Enum "Item Ledger Document Type")
    var
        ItemJournalLine: Record "Item Journal Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking, create an item journal line with Bin code and
        // do item tracking with setting a Lot No. that the other Bin has enough quantity
        Initialize();
        BinCode := SetupLotTrackingItemJournalLineForChangeBin(
            ItemJournalLine, SignFactor, WhseTracking, EntryType, SetNoOption::QtyEnoughNo);

        // Excercise and Verify: No error is expected here when changing the bin code
        ItemJournalLine.Validate("Bin Code", BinCode);
    end;

    local procedure ChangeBinWithLotITOnItemJournalS3(WhseTracking: Boolean; SignFactor: Integer; EntryType: Enum "Item Ledger Document Type")
    var
        ItemJournalLine: Record "Item Journal Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking, create an item journal line with Bin code and
        // do item tracking with setting a Lot No. that can cause unavailablity warning
        Initialize();
        BinCode := SetupLotTrackingItemJournalLineForChangeBin(
            ItemJournalLine, SignFactor, WhseTracking, EntryType, SetNoOption::UnavailableNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnItemJournalLine(ItemJournalLine, BinCode, WhseTracking, SignFactor);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnItemJournalTC1()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: Existing Error
        ChangeBinWithSerialITOnItemJournalS1(true, 1, ItemJournalLine."Entry Type"::"Negative Adjmt.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnItemJournalTC2()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnItemJournalS1(false, 1, ItemJournalLine."Entry Type"::"Negative Adjmt.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnItemJournalTC3()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnItemJournalS1(true, -1, ItemJournalLine."Entry Type"::Sale);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnItemJournalTC4()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnItemJournalS2(true, 1, ItemJournalLine."Entry Type"::Sale);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnItemJournalTC5()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnItemJournalS2(false, 1, ItemJournalLine."Entry Type"::"Negative Adjmt.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnItemJournalTC6()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnItemJournalS2(true, -1, ItemJournalLine."Entry Type"::Sale);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnItemJournalTC7()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: Existing Error
        ChangeBinWithSerialITOnItemJournalS3(true, 1, ItemJournalLine."Entry Type"::Sale);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnItemJournalTC8()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnItemJournalS3(false, 1, ItemJournalLine."Entry Type"::Sale);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnItemJournalTC9()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnItemJournalS3(true, -1, ItemJournalLine."Entry Type"::"Negative Adjmt.");
    end;

    local procedure ChangeBinWithSerialITOnItemJournalS1(WhseTracking: Boolean; SignFactor: Integer; EntryType: Enum "Item Ledger Document Type")
    var
        ItemJournalLine: Record "Item Journal Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking, create an item journal line with Bin code and
        // do item tracking with setting a Lot No. that the other Bin has no enough quantity
        Initialize();
        BinCode := SetupSerialTrackingItemJournalLineForChangeBin(
            ItemJournalLine, SignFactor, WhseTracking, EntryType, SetNoOption::QtyNotEnoughNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnItemJournalLine(ItemJournalLine, BinCode, WhseTracking, SignFactor);
    end;

    local procedure ChangeBinWithSerialITOnItemJournalS2(WhseTracking: Boolean; SignFactor: Integer; EntryType: Enum "Item Ledger Document Type")
    var
        ItemJournalLine: Record "Item Journal Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking, create an item journal line with Bin code and
        // do item tracking with setting a Lot No. that the other Bin has enough quantity
        Initialize();
        BinCode := SetupSerialTrackingItemJournalLineForChangeBin(
            ItemJournalLine, SignFactor, WhseTracking, EntryType, SetNoOption::QtyEnoughNo);

        // Excercise and Verify: No error is expected here when changing the bin code
        ItemJournalLine.Validate("Bin Code", BinCode);
    end;

    local procedure ChangeBinWithSerialITOnItemJournalS3(WhseTracking: Boolean; SignFactor: Integer; EntryType: Enum "Item Ledger Document Type")
    var
        ItemJournalLine: Record "Item Journal Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking, create an item journal line with Bin code and
        // do item tracking with setting a Lot No. that can cause unavailablity warning
        Initialize();
        BinCode := SetupSerialTrackingItemJournalLineForChangeBin(
            ItemJournalLine, SignFactor, WhseTracking, EntryType, SetNoOption::UnavailableNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnItemJournalLine(ItemJournalLine, BinCode, WhseTracking, SignFactor);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnJobJournalTC1()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: Existing Error
        ChangeBinWithLotITOnJobJournalS1(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnJobJournalTC2()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnJobJournalS1(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnJobJournalTC3()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnJobJournalS1(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnJobJournalTC4()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnJobJournalS2(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnJobJournalTC5()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnJobJournalS2(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnJobJournalTC6()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnJobJournalS2(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobJournalTemplateListHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnJobJournalTC7()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: Existing Error
        ChangeBinWithLotITOnJobJournalS3(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobJournalTemplateListHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnJobJournalTC8()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnJobJournalS3(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnJobJournalTC9()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnJobJournalS3(true, -1);
    end;

    local procedure ChangeBinWithLotITOnJobJournalS1(WhseTracking: Boolean; SignFactor: Integer)
    var
        JobJournalLine: Record "Job Journal Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create job journal line
        Initialize();
        BinCode := SetupLotTrackingJobJournalLineForChangeBin(
            JobJournalLine, SignFactor, WhseTracking, SetNoOption::QtyNotEnoughNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnJobJournal(JobJournalLine, BinCode, WhseTracking, SignFactor);
    end;

    local procedure ChangeBinWithLotITOnJobJournalS2(WhseTracking: Boolean; SignFactor: Integer)
    var
        JobJournalLine: Record "Job Journal Line";
        JobJournal: TestPage "Job Journal";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create job journal line
        Initialize();
        BinCode := SetupLotTrackingJobJournalLineForChangeBin(
            JobJournalLine, SignFactor, WhseTracking, SetNoOption::QtyEnoughNo);

        // Exercise
        ChangeBinOnJobJournal(JobJournal, JobJournalLine, BinCode);

        // Verify
        Assert.AreEqual('', JobJournal.GetValidationError(), 'Validation Error should not exist');
    end;

    local procedure ChangeBinWithLotITOnJobJournalS3(WhseTracking: Boolean; SignFactor: Integer)
    var
        JobJournalLine: Record "Job Journal Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create job journal line
        Initialize();
        BinCode := SetupLotTrackingJobJournalLineForChangeBin(
            JobJournalLine, SignFactor, WhseTracking, SetNoOption::UnavailableNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnJobJournal(JobJournalLine, BinCode, WhseTracking, SignFactor);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnJobJournalTC1()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: Existing Error
        ChangeBinWithSerialITOnJobJournalS1(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnJobJournalTC2()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnJobJournalS1(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnJobJournalTC3()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnJobJournalS1(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnJobJournalTC4()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnJobJournalS2(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnJobJournalTC5()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnJobJournalS2(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnJobJournalTC6()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnJobJournalS2(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,JobJournalTemplateListHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnJobJournalTC7()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: Existing Error
        ChangeBinWithSerialITOnJobJournalS3(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,JobJournalTemplateListHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnJobJournalTC8()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnJobJournalS3(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,JobJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnJobJournalTC9()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnJobJournalS3(true, -1);
    end;

    local procedure ChangeBinWithSerialITOnJobJournalS1(WhseTracking: Boolean; SignFactor: Integer)
    var
        JobJournalLine: Record "Job Journal Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create job journal line
        Initialize();
        BinCode := SetupSerialTrackingJobJournalLineForChangeBin(
            JobJournalLine, SignFactor, WhseTracking, SetNoOption::QtyNotEnoughNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnJobJournal(JobJournalLine, BinCode, WhseTracking, SignFactor);
    end;

    local procedure ChangeBinWithSerialITOnJobJournalS2(WhseTracking: Boolean; SignFactor: Integer)
    var
        JobJournalLine: Record "Job Journal Line";
        JobJournal: TestPage "Job Journal";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create job journal line
        Initialize();
        BinCode := SetupSerialTrackingJobJournalLineForChangeBin(
            JobJournalLine, SignFactor, WhseTracking, SetNoOption::QtyEnoughNo);

        // Exercise
        ChangeBinOnJobJournal(JobJournal, JobJournalLine, BinCode);

        // Verify
        Assert.AreEqual('', JobJournal.GetValidationError(), 'Validation Error should not exist');
    end;

    local procedure ChangeBinWithSerialITOnJobJournalS3(WhseTracking: Boolean; SignFactor: Integer)
    var
        JobJournalLine: Record "Job Journal Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create job journal line
        Initialize();
        BinCode := SetupSerialTrackingJobJournalLineForChangeBin(
            JobJournalLine, SignFactor, WhseTracking, SetNoOption::UnavailableNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnJobJournal(JobJournalLine, BinCode, WhseTracking, SignFactor);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnPurchLineTC1()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: Existing Error
        ChangeBinWithLotITOnPurchLineS1(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnPurchLineTC2()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Negative
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnPurchLineS1(false, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnPurchLineTC3()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnPurchLineS1(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnPurchLineTC4()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnPurchLineS2(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnPurchLineTC5()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Negative
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnPurchLineS2(false, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnPurchLineTC6()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnPurchLineS2(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnPurchLineTC7()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: Existing Error
        ChangeBinWithLotITOnPurchLineS3(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnPurchLineTC8()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Negative
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnPurchLineS3(false, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnPurchLineTC9()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnPurchLineS3(true, 1);
    end;

    local procedure ChangeBinWithLotITOnPurchLineS1(WhseTracking: Boolean; SignFactor: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Purchase Line
        Initialize();
        BinCode := SetupLotTrackingPurchaseLineForChangeBin(PurchaseLine, SignFactor, WhseTracking, SetNoOption::QtyNotEnoughNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnPurchaseLine(PurchaseLine."Document No.", BinCode, WhseTracking, SignFactor);
    end;

    local procedure ChangeBinWithLotITOnPurchLineS2(WhseTracking: Boolean; SignFactor: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Purchase Line
        Initialize();
        BinCode := SetupLotTrackingPurchaseLineForChangeBin(PurchaseLine, SignFactor, WhseTracking, SetNoOption::QtyEnoughNo);

        // Exercise
        ChangeBinOnPurchaseLine(PurchaseOrder, PurchaseLine."Document No.", BinCode);

        // Verify
        Assert.AreEqual('', PurchaseOrder.GetValidationError(), 'Validation Error should not exist');
    end;

    local procedure ChangeBinWithLotITOnPurchLineS3(WhseTracking: Boolean; SignFactor: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Purchase Line
        Initialize();
        BinCode := SetupLotTrackingPurchaseLineForChangeBin(PurchaseLine, SignFactor, WhseTracking, SetNoOption::UnavailableNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnPurchaseLine(PurchaseLine."Document No.", BinCode, WhseTracking, SignFactor);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnPurchLineTC1()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: Existing Error
        ChangeBinWithSerialITOnPurchLineS1(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnPurchLineTC2()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Negative
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnPurchLineS1(false, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnPurchLineTC3()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnPurchLineS1(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnPurchLineTC4()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnPurchLineS2(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnPurchLineTC5()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Negative
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnPurchLineS2(false, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnPurchLineTC6()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnPurchLineS2(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnPurchLineTC7()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: Existing Error
        ChangeBinWithSerialITOnPurchLineS3(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnPurchLineTC8()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Negative
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnPurchLineS3(false, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnPurchLineTC9()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnPurchLineS3(true, 1);
    end;

    local procedure ChangeBinWithSerialITOnPurchLineS1(WhseTracking: Boolean; SignFactor: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Purchase Line
        Initialize();
        BinCode := SetupSerialTrackingPurchaseLineForChangeBin(PurchaseLine, SignFactor, WhseTracking, SetNoOption::QtyNotEnoughNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnPurchaseLine(PurchaseLine."Document No.", BinCode, WhseTracking, SignFactor);
    end;

    local procedure ChangeBinWithSerialITOnPurchLineS2(WhseTracking: Boolean; SignFactor: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Purchase Line
        Initialize();
        BinCode := SetupSerialTrackingPurchaseLineForChangeBin(PurchaseLine, SignFactor, WhseTracking, SetNoOption::QtyEnoughNo);

        // Exercise
        ChangeBinOnPurchaseLine(PurchaseOrder, PurchaseLine."Document No.", BinCode);

        // Verify
        Assert.AreEqual('', PurchaseOrder.GetValidationError(), 'Validation Error should not exist');
    end;

    local procedure ChangeBinWithSerialITOnPurchLineS3(WhseTracking: Boolean; SignFactor: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Purchase Line
        Initialize();
        BinCode := SetupSerialTrackingPurchaseLineForChangeBin(PurchaseLine, SignFactor, WhseTracking, SetNoOption::UnavailableNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnPurchaseLine(PurchaseLine."Document No.", BinCode, WhseTracking, SignFactor);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnProdOrderCompTC1()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: Existing Error
        ChangeBinWithLotITOnProdOrderCompS1(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnProdOrderCompTC2()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnProdOrderCompS1(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnProdOrderCompTC3()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnProdOrderCompS1(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnProdOrderCompTC4()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnProdOrderCompS2(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnProdOrderCompTC5()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnProdOrderCompS2(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnProdOrderCompTC6()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnProdOrderCompS2(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnProdOrderCompTC7()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: Existing Error
        ChangeBinWithLotITOnProdOrderCompS3(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnProdOrderCompTC8()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnProdOrderCompS3(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinWithLotITOnProdOrderCompTC9()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithLotITOnProdOrderCompS3(true, -1);
    end;

    local procedure ChangeBinWithLotITOnProdOrderCompS1(WhseTracking: Boolean; SignFactor: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Prod. Order Components
        Initialize();
        BinCode := SetupLotTrackingProdCompForChangeBin(
            ProdOrderComp, SignFactor, WhseTracking, SetNoOption::QtyNotEnoughNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnProdOrderComponents(ProdOrderComp."Item No.", BinCode, WhseTracking, SignFactor);
    end;

    local procedure ChangeBinWithLotITOnProdOrderCompS2(WhseTracking: Boolean; SignFactor: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComponents: TestPage "Prod. Order Components";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Prod. Order Components
        Initialize();
        BinCode := SetupLotTrackingProdCompForChangeBin(
            ProdOrderComp, SignFactor, WhseTracking, SetNoOption::QtyEnoughNo);

        // Exercise
        ChangeBinOnProdOrderComponents(ProdOrderComponents, ProdOrderComp."Item No.", BinCode);

        // Verify
        Assert.AreEqual('', ProdOrderComponents.GetValidationError(), 'Validation Error should not exist');
    end;

    local procedure ChangeBinWithLotITOnProdOrderCompS3(WhseTracking: Boolean; SignFactor: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Prod. Order Components
        Initialize();
        BinCode := SetupLotTrackingProdCompForChangeBin(
            ProdOrderComp, SignFactor, WhseTracking, SetNoOption::UnavailableNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnProdOrderComponents(ProdOrderComp."Item No.", BinCode, WhseTracking, SignFactor);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnProdOrderCompTC1()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: Existing Error
        ChangeBinWithSerialITOnProdOrderCompS1(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnProdOrderCompTC2()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnProdOrderCompS1(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnProdOrderCompTC3()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has no enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnProdOrderCompS1(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnProdOrderCompTC4()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnProdOrderCompS2(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnProdOrderCompTC5()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnProdOrderCompS2(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnProdOrderCompTC6()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, the Bin has enough quantity for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnProdOrderCompS2(true, -1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnProdOrderCompTC7()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: Existing Error
        ChangeBinWithSerialITOnProdOrderCompS3(true, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnProdOrderCompTC8()
    begin
        // Setup: Warehouse tracked = FALSE, Quantity is Positive
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnProdOrderCompS3(false, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ChangeBinWithSerialITOnProdOrderCompTC9()
    begin
        // Setup: Warehouse tracked = TRUE, Quantity is Negative
        // Exercise: Change Bin, causing Availability warning for the tracking No.
        // Verify: No Error
        ChangeBinWithSerialITOnProdOrderCompS3(true, -1);
    end;

    local procedure ChangeBinWithSerialITOnProdOrderCompS1(WhseTracking: Boolean; SignFactor: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Prod. Order Components
        Initialize();
        BinCode := SetupSerialTrackingProdCompForChangeBin(ProdOrderComp, SignFactor, WhseTracking, SetNoOption::QtyNotEnoughNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnProdOrderComponents(ProdOrderComp."Item No.", BinCode, WhseTracking, SignFactor);
    end;

    local procedure ChangeBinWithSerialITOnProdOrderCompS2(WhseTracking: Boolean; SignFactor: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComponents: TestPage "Prod. Order Components";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Prod. Order Components
        Initialize();
        BinCode := SetupSerialTrackingProdCompForChangeBin(ProdOrderComp, SignFactor, WhseTracking, SetNoOption::QtyEnoughNo);

        // Exercise
        ChangeBinOnProdOrderComponents(ProdOrderComponents, ProdOrderComp."Item No.", BinCode);

        // Verify
        Assert.AreEqual('', ProdOrderComponents.GetValidationError(), 'Validation Error should not exist');
    end;

    local procedure ChangeBinWithSerialITOnProdOrderCompS3(WhseTracking: Boolean; SignFactor: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        BinCode: Code[20];
        SetNoOption: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        // Setup: Add Item in Bins with item tracking and create Prod. Order Components
        Initialize();
        BinCode := SetupSerialTrackingProdCompForChangeBin(ProdOrderComp, SignFactor, WhseTracking, SetNoOption::UnavailableNo);

        // Excercise and Verify
        ChangeBinAndVerifyOnProdOrderComponents(ProdOrderComp."Item No.", BinCode, WhseTracking, SignFactor);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,PostedSalesDocumentLinesPageHandler,ReservationHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderWithReserveFromPurchaseReturnOrder()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Purchase Order, create and post Sales Order, create Sales Return Order using Get Posted Document Lines To Reverse.
        Initialize();
        CreateAndPostPurchaseOrderWithIT(
          PurchaseLine, CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true)), '',
          TrackingOption::AssignLotNo);

        DocumentNo := CreateAndPostSalesOrderWithIT(SalesLine, PurchaseLine."No.", '', PurchaseLine.Quantity, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesLine."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(DocumentNo); // Enqueue value for PostedSalesDocumentLinesPageHandler.
        GetPostedDocToReverseOnSalesReturnOrder(SalesHeader."No.");

        // Exercise: Create Purchase Return Order and Reserve from Sales Return Order.
        CreatePurchaseOrderWithReservation(
          PurchaseLine, PurchaseLine."Document Type"::"Return Order", CreateVendor(),
          PurchaseLine."No.", '', PurchaseLine.Quantity, true); // TRUE for Reserve.

        // Verify: Verify that Sales Return Order can be posted and verify the Posted Credit Memo.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyPostedSalesCreditMemo(PurchaseLine."No.", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCopyDocumentWithItemTracking()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        SalesHeaderNo: Code[20];
        OldExactCostReversingMandatory: Boolean;
    begin
        // Test that Sales Order can copy document from posted Credit Memo correctly when 'Exact Cost Reversing Mandatory' is enabled.

        // Setup: Create and post Purchase Order with item tracking, Sales Order and Sales Return Order by getting posted sales document.
        Initialize();
        OldExactCostReversingMandatory := UpdateSalesReceivablesSetup(true); // Check the 'Exact Cost Reversing Mandatory' field.
        CreateAndPostPurchaseOrderWithIT(
          PurchaseLine, CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true)), '',
          TrackingOption::AssignLotNo);
        DocumentNo := CreateAndPostSalesOrderWithIT(SalesLine, PurchaseLine."No.", '', PurchaseLine.Quantity, true);
        DocumentNo := CreateAndPostSaleReturnOrderByGetPostedDoc(SalesLine."Sell-to Customer No.", DocumentNo);

        // Exercise: Create Sales Order copy document from posted Sales Credit Memo.
        SalesHeaderNo := CreateAndCopyDocFromPostedSalesDoc(SalesLine."Sell-to Customer No.", DocumentNo);

        // Verify: Verify the quantity on Sales Line.
        VerifyQtyOnSalesLine(SalesHeaderNo, SalesLine."No.", PurchaseLine.Quantity);

        // Tear Down: Set default value of 'Exact Cost Reversing Mandatory' on Sales & Receivables Setup.
        UpdateSalesReceivablesSetup(OldExactCostReversingMandatory);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCopyDocumentWithItemTracking()
    var
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        PurchHeaderNo: Code[20];
        OldExactCostReversingMandatory: Boolean;
    begin
        // Test that Purchase Order can copy document from posted Credit Memo correctly when 'Exact Cost Reversing Mandatory' is enabled.

        // Setup: Create and post Purchase Order with item tracking, Purchase Return Order by getting posted document.
        Initialize();
        OldExactCostReversingMandatory := UpdatePurchasesPayablesSetup(true); // check the 'Exact Cost Reversing Mandatory' field.
        DocumentNo :=
          CreateAndPostPurchaseOrderWithIT(
            PurchaseLine, CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true)), '',
            TrackingOption::AssignLotNo);
        DocumentNo := CreateAndPostPurchReturnOrderByGetPostedDoc(PurchaseLine."Buy-from Vendor No.", DocumentNo);

        // Exercise: Create Purchase Order copy document from posted Purchase Credit Memo.
        PurchHeaderNo := CreateAndCopyDocFromPostedPurchDoc(PurchaseLine."Buy-from Vendor No.", DocumentNo);

        // Verify: Verify the quantity on Purchase Line.
        VerifyQtyOnPurchaseLine(PurchHeaderNo, PurchaseLine."No.", PurchaseLine.Quantity);

        // Tear Down: Set default value of 'Exact Cost Reversing Mandatory' on Purchases & Payables Setup
        UpdatePurchasesPayablesSetup(OldExactCostReversingMandatory);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure PickExpiringItemFromFEFOLocation()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        BinType: Record "Bin Type";
        SerialNo: Code[50];
    begin
        // Verify that warehouse pick created from sales shipment gets first expiring item if location is set to process picks according to FEFO.
        Initialize();

        DeleteDefaultReceiptBinType(BinType);
        CreateTrackedItemWithWhseTracking(Item);
        CreateFEFOLocation(Location);

        SerialNo := PostPositiveAdjustmentWithExpiryTracking(Item, Location.Code, Location."Receipt Bin Code");

        CreateAndReleaseSalesDocument(SalesHeader, Item."No.", Location.Code, 1);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        FindAndReleaseWhseShipment(WhseShptHeader, Location.Code);
        CreatePickFromWhseShipimentLine(WhseActivityLine, WhseShptHeader);
        BinType.Insert(); // Restore the deleted bin type

        Assert.AreEqual(SerialNo, WhseActivityLine."Serial No.", WrongSerialNoErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceFromPostedRcptGetsQtyPerUomFromRcpt()
    var
        ItemUOM: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        LotQty: Integer;
    begin
        // [FEATURE] [Item Tracking] [Get Receipt Lines] [Qty. per Unit of Measure]
        // [SCENARIO 361867] Qty. per UoM in tracking specification when purchasing item in additional unit of measure with tracking by lot number
        Initialize();
        LotQty := LibraryRandom.RandInt(100);

        // [GIVEN] Item "I" with base unit of measure "U1"
        // [GIVEN] Additional item unit of measure "U2", qty. per unit of measure = "X"
        CreateItemWithAdditionalUOM(Item, ItemUOM, false, true);
        // [GIVEN] Purchase order for item "I" with lot tracking and unit of measure = "U2"
        CreatePurchaseInAdditionalUoM(PurchaseHeader, PurchaseLine, Item, LotQty * 2, ItemUOM.Code);
        AssignPurchaseLotNos(PurchaseLine, LotQty * ItemUOM."Qty. per Unit of Measure");

        // [GIVEN] Post purchase receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Create purchase invoice from posted purchase receipt
        CreatePurchInvoiceFromReceipt(PurchaseHeader, PurchaseHeader."No.");

        // [THEN] "Quantity per Unit of Measure" in purchase invoice tracking lines is "X"
        VerifyQtyPerUoMOnReservation(PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", ItemUOM."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderWithItemTrackingApplication()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Inventory Transfer] [Fixed Application]
        // [SCENARIO] Verify that transfer order can be received when Item Tracking is applied to Item Ledger Entry.

        // [GIVEN] Transfer Order with Lot Tracked Item, apply to Item Entry when assigning Lot No.
        Initialize();
        ItemNo :=
          CreateTrackedItem(
            LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(false, true));
        CreateItemJournalLineWithIT(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", TrackingOption::AssignLotNo, ItemNo,
          LibraryRandom.RandIntInRange(10, 100));
        ItemJournalLine.Validate("Location Code", LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location));
        ItemJournalLine.Modify(true);
        PostOutputJournal(ItemJournalLine);
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        CreateTransferOrderApplyToItemEntry(TransferLine, ItemJournalLine."Location Code", ItemNo, ItemJournalLine.Quantity, ItemLedgerEntry."Entry No.");

        // [GIVEN] Ship Transfer Order.
        TransferHeader.Get(TransferLine."Document No.");
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Receive Transfer Order.
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] Transfer Receipt Line is created.
        VerifyPostedTransferReceipt(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTPositiveClearApplItemEntry()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Reservation Entry]
        // [SCENARIO] "Appl.-to Item Entry" zeroed after call to 'ClearApplFromToItemEntry' for positive Reservation Entry.
        // [GIVEN] Positive Reservation Entry with non-zero "Appl.-to Item Entry" and "Appl.-from Item Entry".
        ReservationEntry.Init();
        SetApplFromToItemEntry(ReservationEntry, true);
        // [WHEN] ClearApplFromToItemEntry called.
        ReservationEntry.ClearApplFromToItemEntry();
        // [THEN] "Appl.-to Item Entry" set to zero, "Appl.-from Item Entry" rest as is.
        Assert.AreEqual(0, ReservationEntry."Appl.-to Item Entry", ClearApplEntryErr);
        Assert.AreEqual(1, ReservationEntry."Appl.-from Item Entry", ClearApplEntryErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTNegativeClearApplItemEntry()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Reservation Entry]
        // [SCENARIO] "Appl.-from Item Entry" zeroed after call to 'ClearApplFromToItemEntry' for negative Reservation Entry.
        // [GIVEN] Negative Reservation Entry with non-zero "Appl.-to Item Entry" and "Appl.-from Item Entry".
        ReservationEntry.Init();
        SetApplFromToItemEntry(ReservationEntry, false);
        // [WHEN] ClearApplFromToItemEntry called.
        ReservationEntry.ClearApplFromToItemEntry();
        // [THEN] "Appl.-from Item Entry" set to zero, "Appl.-to Item Entry" rest as is.
        Assert.AreEqual(1, ReservationEntry."Appl.-to Item Entry", ClearApplEntryErr);
        Assert.AreEqual(0, ReservationEntry."Appl.-from Item Entry", ClearApplEntryErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateChangeQtyPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicedQtyRoundedTwoReceiptsOneInvoice()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QtyPerUoM: Decimal;
    begin
        // [FEATURE] [Purchase] [Partial Receipt] [Item Tracking] [Qty. per Unit of Measure] [Rounding]
        // [SCENARIO 364284] Invoiced quantity is rounded correctly when one invoice is applied to several receipts

        // [GIVEN] Item with serial no. tracking and an additional unit of measure (Box): Qty. per base UoM = 12
        QtyPerUoM := 12;
        CreateItemWithSalesPurchUOM(Item, true, false, QtyPerUoM);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create purchase order with 5 boxes, assign 60 serial numbers
        CreatePurchaseOrderWithITSetTrackingQty(
          PurchaseHeader, PurchaseLine, Item."No.", Location.Code, 5, TrackingOption::AssignSerialLot, 3 * QtyPerUoM);
        // [GIVEN] Receive 3 Boxes (36 base UoM)
        SetPurchaseLineQtyToReceive(PurchaseLine, 3);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Receive 2 Boxes (24 base UoM)
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialLot);
        LibraryVariableStorage.Enqueue(2 * QtyPerUoM);
        PurchaseLine.OpenItemTrackingLines();
        PurchaseLine.Find();
        SetPurchaseLineQtyToReceive(PurchaseLine, 2);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Post invoice on 5 boxes
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Invoice", 5);
        PurchaseLine.Modify(true);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Quantity invoiced is equal to quantity received in all posted receipts
        VerifyInvoicedQtyOnPurchRcptLine(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateChangeQtyPageHandler,ItemTrackingSummarySelectEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicedQtyRoundedTwoShipmentsOneInvoice()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        QtyPerUoM: Decimal;
    begin
        // [FEATURE] [Purchase] [Partial Shipment] [Item Tracking] [Qty. per Unit of Measure] [Rounding]
        // [SCENARIO 364284] Invoiced quantity is rounded correctly when one invoice is applied to several shipments

        // [GIVEN] Item with serial no. tracking and an additional unit of measure (Box): Qty. per base UoM = 12
        QtyPerUoM := 12;
        CreateItemWithSalesPurchUOM(Item, true, false, QtyPerUoM);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post purchase order (receive only) with 5 boxes, assign 60 serial numbers
        CreatePurchaseOrderWithITSetTrackingQty(
          PurchaseHeader, PurchaseLine, Item."No.", Location.Code, 5, TrackingOption::AssignSerialLot, 5 * QtyPerUoM);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create sales order with 5 boxes
        CreateSalesOrder(SalesHeader, SalesLine, Location.Code, '', Item."No.", 5);

        // [GIVEN] Ship 3 boxes (36 base UoM)
        SetSalesLineQtyToShip(SalesLine, 3);
        PostSalesShipmentWithTracking(SalesHeader, SalesLine, TrackingOption::SelectEntries, 3 * QtyPerUoM);

        // [GIVEN] Ship 2 boxes (24 base UoM)
        SalesLine.Find();
        SetSalesLineQtyToShip(SalesLine, 2);
        PostSalesShipmentWithTracking(SalesHeader, SalesLine, TrackingOption::SelectEntries, 2 * QtyPerUoM);

        // [WHEN] Invoice 5 boxes
        SalesLine.Find();
        SalesLine.Validate("Qty. to Invoice", 5);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Quantity invoiced is equal to quantity received in all posted shipments
        VerifyInvoicedQtyOnSalesShptLine(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateChangeQtyPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicedQtyRoundedOneReceiptTwoInvoices()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QtyPerUoM: Decimal;
    begin
        // [FEATURE] [Purchase] [Partial Invoice] [Item Tracking] [Qty. per Unit of Measure] [Rounding]
        // [SCENARIO 364284] Invoiced quantity is rounded correctly when several invoices are applied to one receipt

        // [GIVEN] Item with serial no. tracking and an additional unit of measure (Box): Qty. per base UoM = 12
        QtyPerUoM := 12;
        CreateItemWithSalesPurchUOM(Item, true, false, QtyPerUoM);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post purchase order (receive only) with 6 boxes, assign 72 serial numbers
        CreatePurchaseOrderWithITSetTrackingQty(
          PurchaseHeader, PurchaseLine, Item."No.", Location.Code, 6, TrackingOption::AssignSerialLot, 6 * QtyPerUoM);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Invoice 3 boxes (36 base UoM)
        PurchaseLine.Find();
        PostPurchaseInvoiceWithTracking(PurchaseHeader, PurchaseLine, 3, 3 * QtyPerUoM);

        // [GIVEN] Invoice 2 boxes (24 base UoM)
        PurchaseLine.Find();
        PostPurchaseInvoiceWithTracking(PurchaseHeader, PurchaseLine, 2, 2 * QtyPerUoM);

        // [WHEN] Invoice the last 1 box
        PurchaseLine.Find();
        PostPurchaseInvoiceWithTracking(PurchaseHeader, PurchaseLine, 1, QtyPerUoM);

        // [THEN] Quantity invoiced is equal to quantity received in the receipt
        VerifyInvoicedQtyOnPurchRcptLine(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateChangeQtyPageHandler,ItemTrackingSummarySelectEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicedQtyRoundedOneShipmentTwoInvoices()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        QtyPerUoM: Integer;
    begin
        // [FEATURE] [Sales] [Partial Invoice] [Item Tracking] [Qty. per Unit of Measure] [Rounding]
        // [SCENARIO 364284] Invoiced quantity is rounded correctly when several invoices are applied to one shipment

        // [GIVEN] Item with serial no. tracking and an additional unit of measure (Box): Qty. per base UoM = 12
        QtyPerUoM := 12;
        CreateItemWithSalesPurchUOM(Item, true, false, QtyPerUoM);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post purchase order with 6 boxes, assign 72 serial numbers
        CreatePurchaseOrderWithITSetTrackingQty(
          PurchaseHeader, PurchaseLine, Item."No.", Location.Code, 6, TrackingOption::AssignSerialLot, 6 * QtyPerUoM);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create sales order with 6 boxes
        CreateSalesOrder(SalesHeader, SalesLine, Location.Code, '', Item."No.", 6);

        // [GIVEN] Post sales shipment
        PostSalesShipmentWithTracking(SalesHeader, SalesLine, TrackingOption::SelectEntries, 6 * QtyPerUoM);

        // [GIVEN] Invoice 3 boxes (36 base UoM)
        SalesLine.Find();
        PostSalesInvoiceWithTracking(SalesHeader, SalesLine, 3, 3 * QtyPerUoM);

        // [GIVEN] Invoice 2 boxes (24 base UoM)
        SalesLine.Find();
        PostSalesInvoiceWithTracking(SalesHeader, SalesLine, 2, 2 * QtyPerUoM);

        // [WHEN] Invoice the last box
        SalesLine.Find();
        PostSalesInvoiceWithTracking(SalesHeader, SalesLine, 1, QtyPerUoM);

        // [THEN] Quantity invoiced is equal to quantity received in the shipment
        VerifyInvoicedQtyOnSalesShptLine(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure RunTimeNotResetWhenPostOutputWithUntrackedQtyLessThanPrecision()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        RunTime: Decimal;
    begin
        // [FEATURE] [Item Unit of Measure] [Rounding] [Output]
        // [SCENARIO 269838] "Run Time" should not be zeroed out on capacity entry when a user posts output with item tracking, and untracked quantity is less than the precision value (0.00001).
        Initialize();

        // [GIVEN] Lot-tracked item with base unit of measure "KG" and alternate unit of measure "GR". 1 "GR" = 0.001 "KG".
        CreateItemWithAddUOMFixedQty(Item, ItemUnitOfMeasure, false, true, 0.001);
        CreateRouting(RoutingLine, '');
        UpdateItem(Item, '', RoutingLine."Routing No.");

        // [GIVEN] Released production order for the item.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Open output journal and explode routing of the production order.
        // [GIVEN] Set "Output Quantity" on the output journal line to 1.00001 "GR". That is equal to 0.00100001 "KG".
        // [GIVEN] Set "Run Time" = "X".
        RunTime := LibraryRandom.RandInt(10);
        CreateOutputJournal(ItemJournalBatch, ProductionOrder."No.");
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Operation No.", RoutingLine."Operation No.");
        ItemJournalLine.Validate("Output Quantity", 1.00001);
        ItemJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Modify(true);

        // [GIVEN] Open item tracking on the output journal line and assign lot no.
        // [GIVEN] "Qty. to Handle" on the item tracking is now 0.001 "KG" (0.00100001 rounded to 5 digits).
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Post the output.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] "Run Time" on the capacity ledger entry is equal to "X".
        CapacityLedgerEntry.SetRange("Item No.", Item."No.");
        CapacityLedgerEntry.FindFirst();
        CapacityLedgerEntry.TestField("Run Time", RunTime);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerFalse')]
    [Scope('OnPrem')]
    procedure MatchAssemblyOutputAndConsumptionOnItemTracing()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
        SerialNo: array[2] of Code[50];
        i: Integer;
    begin
        // [FEATURE] [Item Tracing] [Assembly]
        // [SCENARIO 280738] When an assembly order is posted in several steps, item tracing should show consumption entries separately for each assembly output.
        Initialize();

        // [GIVEN] Serial no.-tracked assembled item "A" with one component "C".
        LibraryItemTracking.CreateSerialItem(AsmItem);
        LibraryInventory.CreateItem(CompItem);
        LibraryAssembly.CreateAssemblyListComponent(BOMComponent.Type::Item, CompItem."No.", AsmItem."No.", '', 0, 1, true);

        // [GIVEN] Component "C" is in stock.
        PostItemStock(CompItem."No.");

        // [GIVEN] Assembly order for item "A".
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, LibraryRandom.RandDate(10), AsmItem."No.", '', LibraryRandom.RandIntInRange(5, 10), '');
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialLot);
        AssemblyHeader.OpenItemTrackingLines();

        // [GIVEN] Set "Quantity to Assemble" to 1 pc in the assembly order and post it. The first assembled serial no. = "S1".
        // [GIVEN] Set "Quantity to Assemble" to 1 pc in the assembly order again and post it. The second assembled serial no. = "S2".
        for i := 1 to 2 do begin
            AssemblyHeader.Find();
            AssemblyHeader.Validate("Quantity to Assemble", 1);
            AssemblyHeader.Modify(true);
            LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
            SerialNo[i] := GetSerialNoFromLastPostedItemLedgerEntry(AsmItem."No.");
        end;

        for i := 1 to 2 do begin
            // [WHEN] Trace item "A", serial no. "S1" from usage to origin. On the second run, trace serial no. "S2".
            OpenItemTracingPage(ItemTracing, AsmItem."No.", SerialNo[i], '', TraceMethod::"Usage -> Origin");

            // [THEN] Tracing shows the consumption of 1 pc of component "C" for the assembly.
            ItemTracing.Expand(true);
            ItemTracing.Next();
            ItemTracing."Item No.".AssertEquals(CompItem."No.");
            ItemTracing.Quantity.AssertEquals(-1);

            // [THEN] No more component consumption entries are displayed.
            Assert.IsFalse(ItemTracing.Next(), WrongNoOfComponentEntriesErr);

            ItemTracing.Close();
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PostedItemTrackingLinesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpeningItemTrackingEntriesOnPostedInvoiceSkipsNonItemValueEntries()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Assembly] [Assembly-to-Order]
        // [SCENARIO 293452] Opening item tracking entries on posted invoice shows the invoiced lots or serials that were inherited from a linked assembly-to-order having a resource as a component.
        Initialize();

        // [GIVEN] Lot-tracked item "I" replenished via assembly-to-order.
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);

        // [GIVEN] The assembly BOM for item "I" includes a resource as a component.
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Resource, LibraryResource.CreateResourceNo(), Item."No.", '', 0, LibraryRandom.RandInt(10), true);

        // [GIVEN] Sales order for item "I". Quantity = "Qty. to Assemble to Order" = "X".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate());

        // [GIVEN] Open linked assembly order and assign lot no.
        LibraryAssembly.FindLinkedAssemblyOrder(
          AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        AssemblyHeader.OpenItemTrackingLines();

        // [GIVEN] Ship and invoice the sales order.
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Find the posted invoice and open item tracking lines.
        SalesInvoiceLine.SetRange("Document No.", PostedInvoiceNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.ShowItemTrackingLines();

        // [THEN] The item tracking entries are opened without an error.
        // [THEN] The quantity in the lot = "X".
        Assert.AreEqual(SalesInvoiceLine.Quantity, LibraryVariableStorage.DequeueDecimal(), '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateChangeQtyPageHandler')]
    procedure ClosingItemTrackingLinesPageFromWarehouseShipmentSkipsItemTrackingRecreation()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Location: Record Location;
        ShipmentBin: Record Bin;
        PickFromBin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemJournalLine: Record "Item Journal Line";
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[50];
    begin
        // [FEATURE] [UI] [Serial Item Tracking]
        // [SCENARIO 307444] When Location has no Require Pick option and Warehouse Shipment has Warehouse Pick registered, Item Tracking Lines page closure is not causing Item Tracking Lines to be recreated
        Initialize();

        // [GIVEN] Location with Bin Mandatory and Require Shipment options with Shipment Bin Code
        // [GIVEN] Warehouse Employee for Location
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, true);
        LibraryWarehouse.CreateBin(ShipmentBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Shipment Bin Code", ShipmentBin.Code);
        Location.Modify(true);
        CreateWarehouseEmployee(Location.Code);

        // [GIVEN] Item with Item Tracking Code populated with enabled SN Warehouse Tracking
        LibraryItemTracking.CreateSerialItem(Item);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        SerialNo := NoSeries.PeekNextNo(Item."Serial Nos.");

        // [GIVEN] Bin for Location PickFromBin
        LibraryWarehouse.CreateBin(PickFromBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Positive adjustment for Item with quantity = 1 and serial no. = SN posted into PickFromBin at Location
        CreateItemJournalLineWithBin(ItemJournalLine, PickFromBin, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialLot);
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales Order for Location with Item quantity = 1
        CreateAndReleaseSalesDocument(SalesHeader, Item."No.", Location.Code, ItemJournalLine.Quantity);
        SalesHeader.SetRecFilter();

        // [GIVEN] Warehouse Shipment created from Sales Header
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindAndReleaseWhseShipment(WarehouseShipmentHeader, Location.Code);

        // [GIVEN] Warehouse Pick created from Warehouse Shipment
        CreatePickFromWhseShipimentLine(WarehouseActivityLine, WarehouseShipmentHeader);

        // [GIVEN] Warehouse Pick Line is updated with serial no. = SN and registered
        WarehouseActivityLine.ModifyAll("Serial No.", SerialNo, true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Item Tracking Line page opened from Warehouse Shipment
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", WarehouseActivityLine."Source Line No.");
        LibraryVariableStorage.Enqueue(TrackingOption::InvokeOK);
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Item Tracking Lines page closed at ItemTrackingLinesPageHandler
        // [THEN] Item Tracking Lines page closed with no errors
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure RoundingPrecisionIsLostWhenItemTrackingLinesIsReopened()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Lot no. Item Tracking]
        // [SCENARIO] When Item tracking page is reopened from a purchase order, the rounding precision is lost and allows quantity to be set that violates the rounding precision
        Initialize();

        // [GIVEN] Item with Item Tracking Code populated with enabled Lot Warehouse Tracking.
        // [GIVEN] Base item unit of measure has the rounding precision set to 1.
        CreateItemWithAdditionalUOM(Item, ItemUnitOfMeasure, false, true);
        BaseItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
        BaseItemUnitOfMeasure.Validate("Qty. Rounding Precision", 1);
        BaseItemUnitOfMeasure.Modify(true);

        // [GIVEN] Purchase Order is created.
        CreatePurchaseOrder(PurchaseLine, Item."No.", '', LibraryRandom.RandInt(20));
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GoToRecord(PurchaseHeader);

        // [GIVEN] Open Item Tracking Lines page and assign lot no.s
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        PurchaseOrder.PurchLines."Item Tracking Lines".Invoke();

        // [WHEN] Quantity is set to a value that is not supported by the quantity rounding precision
        LibraryVariableStorage.Enqueue(TrackingOption::SetQuantity);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity - 1 / LibraryRandom.RandInt(10));

        // [THEN] Error is thrown
        asserterror PurchaseOrder.PurchLines."Item Tracking Lines".Invoke();
        Assert.ExpectedError('is of lower precision than expected');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandlerWithSpecificTwoLots,PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure S458041_ItemTrackingIsSetToInvoicedQuantities_PurchaseReturnOrder_GetPostedDocumentLinesToReverse()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        ItemNo: Code[20];
        LocationCode: Code[10];
        VendorNo: Code[20];
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase Order] [Item Tracking] [Partial Receipt] [Partial Invoice] [Purchase Return Order] [Get Posted Document Lines to Reverse]
        // [SCENARIO 458041] Item Tracking lines in Purchase Return Order are set as to invoiced quantities when using function 'Get Posted Document Lines to Reverse'.
        // [SCENARIO 458041] Purchase Order with Item Tracking is created and partially received. Then part of recevied quantitiy is invoiced.
        // [SCENARIO 458041] Then Purchase Return Order is created and action 'Get Posted Document Lines to Reverse' is used.
        Initialize();

        // [GIVEN] Create Item "I" with Lot Tracking
        ItemNo := CreateTrackedItem('', '', CreateItemTrackingCode(false, true));

        // [GIVEN] Create Location "L"
        LocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Vendor "V"
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create Purchase Order for Vendor "V", Location "L", Item "I" with "Quantity" 10
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, LocationCode, 10);

        // [GIVEN] Define two lots with "Quantity (Base)" 6/4 and "Qty. to Handle (Base)" 5/3
        LibraryVariableStorage.Enqueue(TrackingOptionWithTwoLots::AssignLotNoWithQtyToHandle); // Enqueue value for ItemTrackingLinesPageHandlerWithSpecificTwoLots.
        PurchaseLine.OpenItemTrackingLines();

        // [GIVEN] Set "Qty. to Receive" to 8
        PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
        PurchaseLine.Validate("Qty. to Receive", 8);
        PurchaseLine.Modify();

        // [GIVEN] Receive Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Update two lots with "Qty. to Invoice (Base)" 4/2
        LibraryVariableStorage.Enqueue(TrackingOptionWithTwoLots::ChangeQtyToInvoice); // Enqueue value for ItemTrackingLinesPageHandlerWithSpecificTwoLots.
        PurchaseLine.OpenItemTrackingLines();

        // [GIVEN] Set "Qty. to Invoice" to 6
        PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
        PurchaseLine.Validate("Qty. to Invoice", 6);
        PurchaseLine.Modify();

        // [GIVEN] Invoice Purchase Order
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Create Purchase Return Order for Vendor "V"
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);

        // [WHEN] Run "Get Posted Document Lines to Reverse" for PostedPurchaseInvoiceNo
        LibraryVariableStorage.Enqueue(PostedPurchaseInvoiceNo); // Enqueue value for PostedPurchaseDocumentLinesPageHandler.
        GetPostedDocToReverseOnPurchReturnOrder(PurchaseHeader."No.");

        // [THEN] Verify that Item Tracking values copied for Purchase Return Order have two lots and "Quantity (Base)" values 4/2
        Clear(PurchaseLine);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Quantity, 6);

        ReservationEntry.SetRange("Source Type", Database::"Purchase Line");
        ReservationEntry.SetRange("Source Subtype", 5);
        ReservationEntry.SetRange("Source ID", PurchaseHeader."No.");
        ReservationEntry.SetRange("Source Ref. No.", PurchaseLine."Line No.");
        Assert.RecordCount(ReservationEntry, 2);

        ReservationEntry.SetFilter("Lot No.", LotNoWithTwoLots[1]);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Quantity (Base)", -4);

        ReservationEntry.SetFilter("Lot No.", LotNoWithTwoLots[2]);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Quantity (Base)", -2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandlerWithSpecificTwoLots')]
    [Scope('OnPrem')]
    procedure S458801_PreventPartialPurchaseQtyReturn_OverhandledItemTracking_PurchaseReturnOrder()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemNo: Code[20];
        LocationCode: Code[10];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase Order] [Item Tracking] [Purchase Receipt] [Purchase Return Order] [Partial Return]
        // [SCENARIO 458801] Prevent posting Purchase Return Order if "Qty. to Handle" in Item Tracking is over Qty. to be returned.
        Initialize();

        // [GIVEN] Create Item "I" with Lot Tracking
        ItemNo := CreateTrackedItem('', '', CreateItemTrackingCode(false, true));

        // [GIVEN] Create Location "L"
        LocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Vendor "V"
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create Purchase Order for Vendor "V", Location "L", Item "I" with "Quantity" 20
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, LocationCode, 20);

        // [GIVEN] Define two lots with "Quantity (Base)" 10/10
        LibraryVariableStorage.Enqueue(TrackingOptionWithTwoLots::OrderDocument); // Enqueue value for ItemTrackingLinesPageHandlerWithSpecificTwoLots.
        PurchaseLine.OpenItemTrackingLines();

        // [GIVEN] Receive Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create Purchase Return Order for Vendor "V", Location "L", Item "I" with "Quantity" 10
        Clear(PurchaseHeader);
        Clear(PurchaseLine);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, LocationCode, 10);

        // [GIVEN] Set two lots with "Quantity (Base)" 6/4
        LibraryVariableStorage.Enqueue(TrackingOptionWithTwoLots::ReturnOrderDocument); // Enqueue value for ItemTrackingLinesPageHandlerWithSpecificTwoLots.
        PurchaseLine.OpenItemTrackingLines();

        // [GIVEN] Set "Return Qty. to Ship" to 2
        PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
        PurchaseLine.Validate("Return Qty. to Ship", 2);
        PurchaseLine.Modify();

        // [WHEN] Ship Purchase Return Order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify that Error is thrown
        Assert.ExpectedError(StrSubstNo(WrongQtyForItemErr,
          TrackingSpecification.FieldCaption("Qty. to Handle (Base)"), PurchaseLine."No.", 10, 2, '', LotNoWithTwoLots[2], ''));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandlerWithSpecificTwoLots')]
    [Scope('OnPrem')]
    procedure S458801_PreventPartialSalesQtyReturn_OverhandledItemTracking_SalesReturnOrder()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TrackingSpecification: Record "Tracking Specification";
        ItemNo: Code[20];
        LocationCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales Order] [Item Tracking] [Sales Shipment] [Sales Return Order] [Partial Return]
        // [SCENARIO 458801] Prevent posting Sales Return Order if "Qty. to Handle" in Item Tracking is over Qty. to be returned.
        Initialize();

        // [GIVEN] Create Item "I" with Lot Tracking
        ItemNo := CreateTrackedItem('', '', CreateItemTrackingCode(false, true));

        // [GIVEN] Create Location "L"
        LocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Put Item "I" on Inventory with "Quantity" 20 in two lots with "Quantity (Base)" 10/10
        PostPositiveAdjustmentWithLotNo(ItemNo, LocationCode, '', 20);

        // [GIVEN] Create Customer "C"
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Create Sales Order for Customer "C", Location "L", Item "I" with "Quantity" 20
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, CustomerNo, LocationCode);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 20);

        // [GIVEN] Define two lots with "Quantity (Base)" 10/10
        LibraryVariableStorage.Enqueue(TrackingOptionWithTwoLots::OrderDocument); // Enqueue value for ItemTrackingLinesPageHandlerWithSpecificTwoLots.
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Ship Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create Sales Return Order for Customer "C", Location "L", Item "I" with "Quantity" 10
        Clear(SalesHeader);
        Clear(SalesLine);
        LibrarySales.CreateSalesReturnOrderWithLocation(SalesHeader, CustomerNo, LocationCode);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 10);

        // [GIVEN] Set two lots with "Quantity (Base)" 6/4
        LibraryVariableStorage.Enqueue(TrackingOptionWithTwoLots::ReturnOrderDocument); // Enqueue value for ItemTrackingLinesPageHandlerWithSpecificTwoLots.
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Set "Return Qty. to Receive" to 2
        SalesLine.GetBySystemId(SalesLine.SystemId);
        SalesLine.Validate("Return Qty. to Receive", 2);
        SalesLine.Modify();

        // [WHEN] Receive Sales Return Order
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Verify that Error is thrown
        Assert.ExpectedError(StrSubstNo(WrongQtyForItemErr,
          TrackingSpecification.FieldCaption("Qty. to Handle (Base)"), SalesLine."No.", 10, 2, '', LotNoWithTwoLots[2], ''));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandlerTrackingOption')]
    procedure RunPlanningWorksheetBetweenPartialConsumptionInConsumptionJournalWithIT()
    var
        CompItem: Record Item;
        FGItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LotNoInfo: Record "Lot No. Information";
        CompItemCode: Code[20];
        TrackingCode: Code[10];
        ProdOrderQty: Decimal;
        PartialQty: array[4] of Decimal;
        LotNo: Code[20];
    begin
        // [SCENARIO] Post partial consumption in consumption journal with item tracking and run planning worksheet.
        Initialize();

        // [GIVEN] Create Item "I" with Lot Tracking
        TrackingCode := CreateItemTrackingCode(false, true);
        UpdateItemTrackingExpiry(TrackingCode);
        CompItemCode := CreateTrackedItem('', '', TrackingCode);
        CompItem.get(CompItemCode);
        UpdateItemReOrderPolicyForLot(CompItem);

        //[GIVEN] Create Item "J" with Production BOM
        LibraryInventory.CreateItem(FGItem);
        CreateProdBOMWithOneComp(FGItem, CompItem);
        UpdateParentItemForProduction(FGItem);

        // [GIVEN] Generate Lot and Quantity.
        LotNo := LibraryUtility.GenerateRandomCode(LotNoInfo.FieldNo("Lot No."), Database::"Lot No. Information");
        PartialQty[1] := LibraryRandom.RandInt(20);
        PartialQty[2] := LibraryRandom.RandInt(20);
        PartialQty[3] := LibraryRandom.RandInt(20);
        PartialQty[4] := LibraryRandom.RandInt(20);
        ProdOrderQty := PartialQty[1] + PartialQty[2] + PartialQty[3] + PartialQty[4];

        // [GIVEN] Create and Refresh Production Order for FGItem.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, FGItem."No.", ProdOrderQty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Create and Update Item Journal Batch.
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        ItemJournalBatch.Validate("Item Tracking on Lines", true);
        ItemJournalBatch.Modify(true);

        // [GIVEN] Create and Post Item Journal.
        CreateItemJournalLineWithItemTracking(ItemJournalLine, ItemJournalBatch, ProductionOrder."Location Code", CompItem."No.", PartialQty[1], LotNo);
        CreateItemJournalLineWithItemTracking(ItemJournalLine, ItemJournalBatch, ProductionOrder."Location Code", CompItem."No.", (PartialQty[2] + PartialQty[3]), LotNo);
        CreateItemJournalLineWithItemTracking(ItemJournalLine, ItemJournalBatch, ProductionOrder."Location Code", CompItem."No.", PartialQty[4], LotNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Run Planning Worksheet and Create.
        RunCalculateRegenerativePlan(CompItem."No.");

        // [WHEN] Create and Post Partial Consumption Journal.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", CompItem."No.", LotNo, (PartialQty[1] + PartialQty[2]));

        // [THEN] Run Planning Worksheet expecting no error.
        RunCalculateRegenerativePlan(CompItem."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ItemTrackingLinesPageHandlerTrackingOption,ItemTracingSpecificationRequestPageHandler')]
    procedure ItemDescWithMoreThan50CharactersIsPrintedInItemTracingReport()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTracingBuffer: Record "Item Tracing Buffer";
        ItemTracing: TestPage "Item Tracing";
        TraceMethod: Option "Origin -> Usage","Usage -> Origin";
    begin
        // [SCENARIO 591447] Item Description more than 50 characters is displayed in 
        // Item Tracing Specification report.
        Initialize();

        // [GIVEN] Create and Post Purchase Order with Tracked Item.
        CreateAndPostPurchOrderWithTrackedItem(ItemLedgerEntry, Item, TrackingOption::AssignLotNo, false, true);

        // [GIVEN] Open Item Tracing page.
        OpenItemTracingPage(ItemTracing, '', '', ItemLedgerEntry."Lot No.", TraceMethod::"Origin -> Usage");

        // [WHEN] Run Print action from Item Tracing page.
        ItemTracing."Item Description".AssertEquals(Item.Description);
        LibraryVariableStorage.Enqueue(ItemTracingBuffer.FieldNo("Item Description"));
        ItemTracing.Print.Invoke();

        // [THEN] Item Description is displayed in BodyText1 column of Item Tracing Specification report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BodyText1', Item.Description);
    end;

    local procedure Initialize()
    var
        AllProfile: Record "All Profile";
        InventorySetup: Record "Inventory Setup";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Invt Item Tracking III");
        LibraryVariableStorage.Clear();
        Clear(LotNoWithTwoLots);

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Invt Item Tracking III");

        AllProfile.SetRange("Profile ID", 'ORDER PROCESSOR');
        AllProfile.FindFirst();
        ConfPersonalizationMgt.SetCurrentProfile(AllProfile);

        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Invt Item Tracking III");
    end;

    local procedure AssignPurchaseLotNos(var PurchaseLine: Record "Purchase Line"; LotQtyBase: Integer)
    var
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        LotNo: array[2] of Code[20];
        Qty: array[2] of Integer;
    begin
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        Qty[1] := LotQtyBase;
        Qty[2] := LotQtyBase;

        SetNoAndQtyOnItemTrackingLines(LotNo, Qty, 2, TrackingOption::SetLotNoAndQty);
        PurchLineReserve.CallItemTracking(PurchaseLine);
    end;

    local procedure ChangeBinAndVerifyOnItemJournalLine(ItemJournalLine: Record "Item Journal Line"; BinCode: Code[20]; WhseTracking: Boolean; SignFactor: Integer)
    begin
        if WhseTracking and (SignFactor > 0) then begin
            asserterror ItemJournalLine.Validate("Bin Code", BinCode);
            Assert.IsTrue(StrPos(GetLastErrorText, ItemTrackingExistErr) > 0, 'Actual:' + GetLastErrorText);
            ClearLastError();
        end else
            ItemJournalLine.Validate("Bin Code", BinCode);
    end;

    local procedure ChangeBinOnJobJournal(var JobJournal: TestPage "Job Journal"; JobJournalLine: Record "Job Journal Line"; BinCode: Code[20])
    begin
        LibraryVariableStorage.Enqueue(JobJournalLine."Journal Template Name");
        JobJournal.OpenEdit();
        JobJournal.CurrentJnlBatchName.SetValue(JobJournalLine."Journal Batch Name");
        JobJournal.FILTER.SetFilter("No.", JobJournalLine."No.");
        JobJournal."Bin Code".SetValue(BinCode);
        JobJournal.Next(); // Trigger the item existing error
    end;

    local procedure ChangeBinAndVerifyOnJobJournal(JobJournalLine: Record "Job Journal Line"; BinCode: Code[20]; WhseTracking: Boolean; SignFactor: Integer)
    var
        JobJournal: TestPage "Job Journal";
    begin
        ChangeBinOnJobJournal(JobJournal, JobJournalLine, BinCode);

        if WhseTracking and (SignFactor > 0) then
            Assert.IsTrue(StrPos(JobJournal.GetValidationError(), ItemTrackingExistErr) > 0, 'Actual:' + JobJournal.GetValidationError())
        else
            Assert.AreEqual('', JobJournal.GetValidationError(), 'Validation Error should not exist');
    end;

    local procedure ChangeBinOnPurchaseLine(var PurchaseOrder: TestPage "Purchase Order"; DocNo: Code[20]; BinCode: Code[20])
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", DocNo);
        PurchaseOrder.PurchLines."Bin Code".SetValue(BinCode);
        PurchaseOrder.PurchLines.Next(); // Trigger the item existing error
    end;

    local procedure ChangeBinAndVerifyOnPurchaseLine(DocNo: Code[20]; BinCode: Code[20]; WhseTracking: Boolean; SignFactor: Integer)
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        ChangeBinOnPurchaseLine(PurchaseOrder, DocNo, BinCode);

        if WhseTracking and (SignFactor < 0) then
            Assert.IsTrue(StrPos(PurchaseOrder.GetValidationError(), ItemTrackingExistErr) > 0, 'Actual:' + PurchaseOrder.GetValidationError())
        else
            Assert.AreEqual('', PurchaseOrder.GetValidationError(), 'Validation Error should not exist');
    end;

    local procedure ChangeBinOnProdOrderComponents(var ProdOrderComponents: TestPage "Prod. Order Components"; ItemNo: Code[20]; BinCode: Code[20])
    begin
        ProdOrderComponents.OpenEdit();
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo);
        ProdOrderComponents."Bin Code".SetValue(BinCode);
        ProdOrderComponents.Next(); // Trigger the item existing error
    end;

    local procedure ChangeBinAndVerifyOnProdOrderComponents(ItemNo: Code[20]; BinCode: Code[20]; WhseTracking: Boolean; SignFactor: Integer)
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ChangeBinOnProdOrderComponents(ProdOrderComponents, ItemNo, BinCode);

        if WhseTracking and (SignFactor > 0) then
            Assert.IsTrue(
              StrPos(ProdOrderComponents.GetValidationError(), ItemTrackingExistErr) > 0, 'Actual:' + ProdOrderComponents.GetValidationError())
        else
            Assert.AreEqual('', ProdOrderComponents.GetValidationError(), 'Validation Error should not exist');
    end;

    local procedure CreateAndModifyItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Flushing Method", Item."Flushing Method"::"Pick + Backward");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateAndModifyOutputJournal(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20]; OperationNo: Code[10]; GenProdPostingGroup: Code[20]; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateOutputJournal(ItemJournalBatch, ProductionOrderNo);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        ItemJournalLine.Validate("Output Quantity", LibraryRandom.RandInt(10));  // Use Random value for Output Quantity.
        ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        ItemJournalLine.Validate("Bin Code", ItemNo);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateBin(LocationCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), '', '');
        exit(Bin.Code);
    end;

    local procedure CreateFEFOLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Receive", true);
        Location.Validate("Pick According to FEFO", true);
        Location.Validate("Receipt Bin Code", CreateBin(Location.Code));
        Location.Validate("Shipment Bin Code", CreateBin(Location.Code));
        Location.Modify(true);

        CreateWarehouseEmployee(Location.Code);
    end;

    local procedure CreateItemWithAdditionalUOM(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; SNTracking: Boolean; LotNoTracking: Boolean)
    begin
        CreateItemWithAddUOMFixedQty(Item, ItemUnitOfMeasure, SNTracking, LotNoTracking, LibraryRandom.RandIntInRange(2, 10));
    end;

    local procedure CreateItemWithAddUOMFixedQty(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; SNTracking: Boolean; LotNoTracking: Boolean; QtyPerUOM: Decimal)
    begin
        Item.Get(
          CreateTrackedItem(
            LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(SNTracking, LotNoTracking)));
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPerUOM);
    end;

    local procedure CreateItemWithSalesPurchUOM(var Item: Record Item; SNTracking: Boolean; LotNoTracking: Boolean; QtyPerUOM: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        CreateItemWithAddUOMFixedQty(Item, ItemUnitOfMeasure, SNTracking, LotNoTracking, QtyPerUOM);
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateLocationWithBin(var Bin: Record Bin; ItemNo: Code[20])
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, ItemNo, '', '');  // Use blank Zone Code and Bin Type Code.
    end;

    local procedure CreatePurchInvoiceFromReceipt(var PurchaseHeader: Record "Purchase Header"; PurchOrderNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        FindPurchaseReceiptLine(PurchRcptLine, PurchOrderNo);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderWithReservation(
          PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, LocationCode, Qty, false);
    end;

    local procedure CreatePurchaseOrderWithReservation(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; Reserve: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, LocationCode, Qty);
        if Reserve then
            PurchaseLine.ShowReservation();
    end;

    [Normal]
    local procedure CreateProdBOMWithOneComp(var ParentItem: Record Item; CompItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        ParentItem.Get(ParentItem."No.");
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateItemJournalLineWithIT(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; TrackingOption: Option; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryVariableStorage.Enqueue(TrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);  // Using Random value for Quantity.
    end;

    local procedure CreateItemJournalLineWithBin(var ItemJournalLine: Record "Item Journal Line"; Bin: Record Bin; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", Bin."Location Code");
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobJournalLineWithBin(var JobJournalLine: Record "Job Journal Line"; Bin: Record Bin; Type: Enum "Job Journal Line Type"; No: Code[20]; Quantity: Decimal)
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, Type);
        JobJournalLine.Validate("No.", No);
        JobJournalLine.Validate("Location Code", Bin."Location Code");
        JobJournalLine.Validate("Bin Code", Bin.Code);
        JobJournalLine.Validate(Quantity, Quantity);
        JobJournalLine.Modify(true);
    end;

    local procedure CreatePickFromWhseShipimentLine(var WhseActivityLine: Record "Warehouse Activity Line"; WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseShptCreatePick: Report "Whse.-Shipment - Create Pick";
    begin
        WhseShptLine.SetRange("No.", WhseShptHeader."No.");
        WhseShptLine.FindFirst();

        WhseShptCreatePick.SetWhseShipmentLine(WhseShptLine, WhseShptHeader);
        WhseShptCreatePick.SetHideValidationDialog(true);
        WhseShptCreatePick.UseRequestPage(false);
        WhseShptCreatePick.RunModal();

        FindWhseActivityLineForLocation(WhseActivityLine, WhseShptHeader."Location Code");
    end;

    local procedure CreatePurchaseLineWithBin(var PurchaseLine: Record "Purchase Line"; Bin: Record Bin; No: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseOrder(PurchaseLine, No, Bin."Location Code", LibraryRandom.RandIntInRange(50, 100));
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateProdOrderCompWithBin(var ProdOrderComp: Record "Prod. Order Component"; Bin: Record Bin; No: Code[20]; Quantity: Decimal)
    var
        ProdItem: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Routing Line";
    begin
        LibraryInventory.CreateItem(ProdItem);
        CreateProductionBOM(ProductionBOMLine, No, ProdItem."Base Unit of Measure");

        ProductionBOMHeader.Get(ProductionBOMLine."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMHeader.Modify(true);
        ProductionBOMLine.Validate("Quantity per", 1); // Set 1 here to make sure component's Quantity would equal the Quantity passed as parameter
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        CreateRouting(RoutingLine, ProductionBOMLine."Routing Link Code");

        // Add Production BOM No. and Routing No. to Production Item.
        UpdateItem(ProdItem, ProductionBOMLine."Production BOM No.", RoutingLine."Routing No.");
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderComp.SetRange(Status, ProductionOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComp.SetRange("Item No.", No);
        ProdOrderComp.FindFirst();
        ProdOrderComp.Validate("Location Code", Bin."Location Code");
        ProdOrderComp.Validate("Bin Code", Bin.Code);
        ProdOrderComp.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithIT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; TrackingOption: Option)
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo, LocationCode, Qty);
        UpdateGeneralPostingSetup(PurchaseLine);
        LibraryVariableStorage.Enqueue(TrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
    end;

    local procedure CreatePurchaseOrderWithITSetTrackingQty(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; TrackingOption: Option; QtyToTrack: Decimal)
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo, LocationCode, Qty);
        LibraryVariableStorage.Enqueue(TrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(QtyToTrack);
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
    end;

    local procedure CreateAndPostPurchaseOrderWithIT(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; TrackingOption: Option): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderWithIT(
          PurchaseHeader, PurchaseLine, ItemNo, LocationCode, LibraryRandom.RandIntInRange(50, 100), TrackingOption);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostOutputJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateOutputJournal(ItemJournalBatch, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption, ItemJournalTemplate.Name);
        LibraryManufacturing.CalculateConsumption(ProductionOrderNo, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries); // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndRefreshProductionOrderWithIT(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; TrackingOption: Option)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        LibraryVariableStorage.Enqueue(TrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.OpenItemTrackingLines();
    end;

    local procedure CreateItemTrackingCode(SNSpecific: Boolean; LOTSpecific: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LOTSpecific);
        ItemTrackingCode.Validate("SN Specific Tracking", SNSpecific);
        ItemTrackingCode.Validate("Lot Specific Tracking", LOTSpecific);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LOTSpecific);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateOutputJournal(var ItemJournalBatch: Record "Item Journal Batch"; ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, '', ProductionOrderNo);  // Use Blank Value for Item No.
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure CreateProductionBOM(var ProductionBOMLine: Record "Production BOM Line"; ItemNo: Code[20]; BaseUnitofMeasure: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingLink: Record "Routing Link";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitofMeasure);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, LibraryRandom.RandInt(5));  // Use Random value for Quantity Per and blank value for Version Code.
        RoutingLink.FindFirst();
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateProductionOrderWithAutoReserve(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.AutoReserve();
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        ProdOrderComponent.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Using Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateRouting(var RoutingLine: Record "Routing Line"; "Code": Code[10])
    var
        RoutingHeader: Record "Routing Header";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);

        // Use Random value for Operation No and blank value for Version Code.
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"),
          RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Routing Link Code", Code);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Backward);
        WorkCenter.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostSalesOrderWithIT(var SalesLine: Record "Sales Line"; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, No, LocationCode, Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));
    end;

    local procedure CreateAndReleaseSalesDocument(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesLine, ItemNo, LocationCode, Quantity);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);
    end;

    local procedure CreateTrackedItem(LotNos: Code[20]; SerialNos: Code[20]; ItemTrackingCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, ItemTrackingCode);
        exit(Item."No.");
    end;

    local procedure CreateTrackedItemWithWhseTracking(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.Get(CreateTrackedItem('', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, false)));
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure PrepareTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; LocationFromCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        LocationTo: Record Location;
        LocationInTransit: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFromCode, LocationTo.Code, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
    end;

    local procedure CreateTransferOrder(var TransferLine: Record "Transfer Line"; LocationFromCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferHeader: Record "Transfer Header";
    begin
        PrepareTransferOrder(TransferHeader, TransferLine, LocationFromCode, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure CreateTransferOrderApplyToItemEntry(var TransferLine: Record "Transfer Line"; LocationFromCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ItemLedgEntryNo: Integer)
    var
        TransferHeader: Record "Transfer Header";
    begin
        PrepareTransferOrder(TransferHeader, TransferLine, LocationFromCode, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectAndApplyToItemEntry);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(ItemLedgEntryNo); // Enqueue value for SelectApplyToItemEntry.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure CreateAndPostTransferOrderWithIT(var TransferLine: Record "Transfer Line"; LocationFromCode: Code[10]; LocationToCode: Code[10]; InTransitCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferHeader: Record "Transfer Header";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFromCode, LocationToCode, InTransitCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
    end;

    local procedure CreateAndCopyDocFromPostedSalesDoc(CustomerNo: Code[20]; DocNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeaderCopySalesDoc(SalesHeader, "Sales Document Type From"::"Posted Credit Memo", DocNo, true, true);
        exit(SalesHeader."No.");
    end;

    local procedure CreateAndCopyDocFromPostedPurchDoc(VendorNo: Code[20]; DocNo: Code[20]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        PurchaseHeaderCopyPurchDoc(PurchHeader, "Purchase Document Type From"::"Posted Credit Memo", DocNo, true, true);
        exit(PurchHeader."No.");
    end;

    local procedure CreateAndPostSaleReturnOrderByGetPostedDoc(CustomerNo: Code[20]; DocNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        LibraryVariableStorage.Enqueue(DocNo); // Enqueue value for PostedSalesDocumentLinesPageHandler.
        GetPostedDocToReverseOnSalesReturnOrder(SalesHeader."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchReturnOrderByGetPostedDoc(VendorNo: Code[20]; DocNo: Code[20]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", VendorNo);
        UpdatePurchHeader(PurchHeader);
        LibraryVariableStorage.Enqueue(DocNo); // Enqueue value for PostedPurchaseDocumentLinesPageHandler.
        GetPostedDocToReverseOnPurchReturnOrder(PurchHeader."No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure ChangeBinCodeInSalesLine(var NewSalesLine: Record "Sales Line"; BinCode: Code[20])
    var
        OldSalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        // Can not use Modify trigger on SalesLine because xRec will be equal to Rec in that way for Sales Line.
        // Can not use TestPage Prod Order because TestTool doesn't show error in OnModify Triggerwhile running from Page (created Bug 360986).
        OldSalesLine := NewSalesLine;
        NewSalesLine.Validate("Bin Code", BinCode);
        SalesLineReserve.VerifyChange(NewSalesLine, OldSalesLine);
    end;

    local procedure CreatePurchaseInAdditionalUoM(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; Quantity: Decimal; UoMCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Unit of Measure Code", UoMCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateReleasedProdOrderWithReservEntry(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        ProductionOrder: Record "Production Order";
        ReservationEntry: Record "Reservation Entry";
        EntryNo: Integer;
    begin
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ProjectOrder);
        if ReservationEntry.FindLast() then;
        EntryNo := ReservationEntry."Entry No." + 1;
        CreateReservationEntry(SalesLine, EntryNo, DATABASE::"Sales Line", false);
        CreateReservationEntry(SalesLine, EntryNo, DATABASE::"Purchase Line", true);
    end;

    local procedure CreateReservationEntry(SalesLine: Record "Sales Line"; EntryNo: Integer; SourceType: Integer; IsPositive: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Init();
        ReservationEntry."Entry No." := EntryNo;
        ReservationEntry.Validate("Source Type", SourceType);
        ReservationEntry.Validate("Source Subtype", SalesLine."Document Type");
        ReservationEntry.Validate("Source ID", SalesLine."Document No.");
        ReservationEntry.Validate("Source Batch Name", '');
        ReservationEntry.Validate("Source Prod. Order Line", 0);
        ReservationEntry.Validate("Source Ref. No.", SalesLine."Line No.");
        ReservationEntry.Validate(Positive, IsPositive);
        ReservationEntry.Validate("Quantity (Base)", 1);
        ReservationEntry.Insert();
    end;

    local procedure CreateBinMandatoryLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify();
    end;

    local procedure CreateFixedBinContent(var BinContent: Record "Bin Content"; Item: Record Item; LocationCode: Code[10]; IsDefault: Boolean)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, IsDefault);
        BinContent.Validate(Fixed, true);
        BinContent.Modify();
    end;

    local procedure CreateItemWithTrackingCode(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode."Lot Specific Tracking" := true;
        ItemTrackingCode."Lot Warehouse Tracking" := true;
        ItemTrackingCode.Modify();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Bin Code", BinCode);
        SalesLine.Modify();
    end;

    local procedure CreateSalesOrderWithRandomQty(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20])
    begin
        CreateSalesOrder(SalesHeader, SalesLine, LocationCode, BinCode, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateTrackedItemWithTwoBinContents(var BinContent: Record "Bin Content"; var BinContent2: Record "Bin Content"): Code[20]
    var
        Item: Record Item;
        Location: Record Location;
    begin
        CreateItemWithTrackingCode(Item);
        CreateBinMandatoryLocation(Location);
        CreateFixedBinContent(BinContent, Item, Location.Code, true);
        CreateFixedBinContent(BinContent2, Item, Location.Code, false);
        exit(Item."No.");
    end;

    local procedure CreateWarehouseEmployee(LocationCode: Code[10])
    var
        WhseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, LocationCode, true);
    end;

    local procedure DeleteDefaultReceiptBinType(var BinTypeBuf: Record "Bin Type")
    var
        BinType: Record "Bin Type";
    begin
        // Save bin type before deleting to restore it after completing the test
        BinType.SetRange(Receive, true);
        if BinType.FindFirst() then begin
            BinTypeBuf := BinType;
            BinType.Delete();
        end;
    end;

    local procedure EnqueueVariablesForSetLotTrackingNo(LotNo: array[2] of Code[20]; Qty: array[2] of Integer; SignFactor: Integer; SetNoOption: Option)
    var
        OptionString: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
    begin
        case SetNoOption of
            OptionString::QtyNotEnoughNo:
                SetLotNoAndQtyOnItemTrackingLine(LotNo[1], SignFactor * Qty[1]);
            OptionString::QtyEnoughNo:
                SetLotNoAndQtyOnItemTrackingLine(LotNo[1], SignFactor * Qty[2]);
            OptionString::UnavailableNo:
                SetLotNoAndQtyOnItemTrackingLine(LotNo[2], SignFactor * LibraryRandom.RandIntInRange(Qty[1] - Qty[2] + 1, Qty[1]));
        end;
    end;

    local procedure EnqueueVariablesForSetSerialTrackingNo(ItemJournalDocNo: array[10] of Code[20]; ItemNo: Code[20]; Quantity: Integer; SignFactor: Integer; SetNoOption: Option)
    var
        SerialNos: array[10] of Code[20];
        OptionString: Option QtyNotEnoughNo,QtyEnoughNo,UnavailableNo;
        TrackingOption: Option Serial,Lot;
    begin
        case SetNoOption of
            OptionString::QtyNotEnoughNo:
                GetNosFromItemTrackingEntries(SerialNos, ItemNo, ItemJournalDocNo[1], TrackingOption::Serial);
            OptionString::QtyEnoughNo:
                GetNosFromItemTrackingEntries(SerialNos, ItemNo, ItemJournalDocNo[2], TrackingOption::Serial);
            OptionString::UnavailableNo:
                begin
                    GetNosFromItemTrackingEntries(SerialNos, ItemNo, ItemJournalDocNo[2], TrackingOption::Serial);
                    SerialNos[Abs(Quantity)] := LibraryUtility.GenerateGUID();
                end;
        end;
        SetSerialNosAndQtyOnItemTrackingLine(SerialNos, SignFactor, Abs(Quantity));
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindAndReleaseWhseShipment(var WhseShptHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    var
        WhseShipmentRelease: Codeunit "Whse.-Shipment Release";
    begin
        WhseShptHeader.SetRange("Location Code", LocationCode);
        WhseShptHeader.FindFirst();
        WhseShipmentRelease.Release(WhseShptHeader);
    end;

    local procedure FindAndUpdateSalesLine(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, SalesLine.Quantity / 2);  // Take Partial Quantity.
    end;

    local procedure FindAndUpdatePurchaseLine(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetFilter("No.", '<>%1', '');
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate(Quantity, PurchaseLine.Quantity / 2);  // Take Partial Quantity.
    end;

    local procedure FindPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.FindFirst();
    end;

    local procedure FindPurchLine(var PurchLine: Record "Purchase Line"; PurchHeaderNo: Code[20]; ItemNo: Code[20])
    begin
        PurchLine.SetRange("Document No.", PurchHeaderNo);
        PurchLine.SetRange("No.", ItemNo);
        PurchLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeaderNo: Code[20]; ItemNo: Code[20])
    begin
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
    end;

    local procedure FindWhseActivityLineForLocation(var WhseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10])
    begin
        WhseActivityLine.SetRange("Location Code", LocationCode);
        WhseActivityLine.FindFirst();
    end;

    local procedure GetLotNoFromItemTrackingEntries(ItemNo: Code[20]; DocumentNo: Code[20]): Code[50]
    var
        ItemTrackingEntries: TestPage "Item Tracking Entries";
    begin
        ItemTrackingEntries.OpenEdit();
        ItemTrackingEntries.FILTER.SetFilter("Item No.", ItemNo);
        ItemTrackingEntries.FILTER.SetFilter("Document No.", DocumentNo);
        exit(ItemTrackingEntries."Lot No.".Value);
    end;

    local procedure GetNosFromItemTrackingEntries(var Nos: array[10] of Code[50]; ItemNo: Code[20]; DocumentNo: Code[20]; TrackingOption: Option)
    var
        ItemTrackingEntries: TestPage "Item Tracking Entries";
        I: Integer;
        OptionString: Option Serial,Lot;
    begin
        ItemTrackingEntries.OpenEdit();
        ItemTrackingEntries.FILTER.SetFilter("Item No.", ItemNo);
        ItemTrackingEntries.FILTER.SetFilter("Document No.", DocumentNo);
        I := 1;
        repeat
            case TrackingOption of
                OptionString::Serial:
                    Nos[I] := ItemTrackingEntries."Serial No.".Value();
                OptionString::Lot:
                    Nos[I] := ItemTrackingEntries."Lot No.".Value();
            end;
            I := I + 1;
        until ItemTrackingEntries.Next() = false;
    end;

    local procedure GetSerialNoFromLastPostedItemLedgerEntry(ItemNo: Code[20]): Code[50]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindLast();
        exit(ItemLedgerEntry."Serial No.");
    end;

    local procedure GetPostedDocToReverseOnSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetPostedDocToReverseOnSalesCreditMemo(No: Code[20])
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", No);
        SalesCreditMemo.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetPostedDocToReverseOnPurchReturnOrder(No: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", No);
        PurchaseReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetPostedDocToReverseOnPurchCreditMemo(No: Code[20])
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", No);
        PurchaseCreditMemo.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure IncreaseItemInventoryWithBin(Bin: Record Bin; ItemNo: Code[20]; Quantity: Integer; TrackingOption: Option): Code[20]
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLineWithBin(ItemJournalLine, Bin, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption);
        PostOutputJournal(ItemJournalLine);
        exit(ItemJournalLine."Document No.");
    end;

    local procedure ModifyAndPostItemJournal(ItemJournalLine: Record "Item Journal Line"; Bin: Record Bin)
    begin
        ItemJournalLine.Validate("Location Code", Bin."Location Code");
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);
        PostOutputJournal(ItemJournalLine);
    end;

    local procedure PostItemStock(ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', LibraryRandom.RandIntInRange(50, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostOutputJournal(ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostPositiveAdjustmentWithExpiryTracking(Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]): Code[50]
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[50];
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          Item."No.", 1);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);

        SerialNo := NoSeries.PeekNextNo(Item."Serial Nos.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialLot);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJnlLineReserve.CallItemTracking(ItemJournalLine, false);

        ReservationEntry.SetRange("Serial No.", SerialNo);
        ReservationEntry.FindFirst();
        ReservationEntry.Validate("Expiration Date", CalcDate('<+1M>', WorkDate()));
        ReservationEntry.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        exit(SerialNo);
    end;

    local procedure PostPurchaseInvoiceWithTracking(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyToInvoice: Decimal; QtyToInvoiceBase: Decimal)
    begin
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(TrackingOption::SetEntriesToInvoice);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(PurchaseLine."No.");
        LibraryVariableStorage.Enqueue(QtyToInvoiceBase);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure PostSalesInvoiceWithTracking(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; QtyToInvoice: Decimal; QtyToInvoiceBase: Decimal)
    begin
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingOption::SetEntriesToInvoice);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(SalesLine."No.");
        LibraryVariableStorage.Enqueue(QtyToInvoiceBase);
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure PostSalesShipmentWithTracking(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesTrackingOption: Option; QtyToTrack: Decimal)
    begin
        LibraryVariableStorage.Enqueue(SalesTrackingOption);
        LibraryVariableStorage.Enqueue(QtyToTrack);
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetupLOTNoForLongChainPstdDocument(var ItemLedgerEntry: Record "Item Ledger Entry"; var TransferLine: Record "Transfer Line"; TrackingOption: Option; SNSpecific: Boolean; LotSpecific: Boolean)
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
    begin
        // Setup: Create Purchase Order with Item Tracking and Post.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Item.Get(
          CreateTrackedItem(
            LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(SNSpecific, LotSpecific)));
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, Item."No.", Location.Code, TrackingOption);

        // Create and Post Transfer Order and Sales Order.
        CreateTransferOrder(TransferLine, Location.Code, Item."No.", PurchaseLine.Quantity);
        TransferHeader.Get(TransferLine."Document No.");
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
        CreateAndPostSalesOrderWithIT(SalesLine, PurchaseLine."No.", TransferLine."Transfer-to Code", PurchaseLine.Quantity, false);
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.");
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
    begin
        // Create and post Item Journal Line with random Quantity, create and post Sales Order.
        CreateItemJournalLineWithIT(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", TrackingOption::AssignLotNo,
          CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true)),
          LibraryRandom.RandDec(10, 2));
        PostOutputJournal(ItemJournalLine);
    end;

    local procedure SelectTrackingEntriesToInvoice()
    var
        TrackingSpec: Record "Tracking Specification";
        QueuedVariable: Variant;
        SourceID: Code[20];
        ItemNo: Code[20];
        I: Integer;
    begin
        LibraryVariableStorage.Dequeue(QueuedVariable);
        SourceID := QueuedVariable;
        LibraryVariableStorage.Dequeue(QueuedVariable);
        ItemNo := QueuedVariable;

        TrackingSpec.SetRange("Source ID", SourceID);
        TrackingSpec.SetRange("Item No.", ItemNo);
        TrackingSpec.ModifyAll("Qty. to Invoice (Base)", 0);
        TrackingSpec.SetRange("Quantity Invoiced (Base)", 0);
        TrackingSpec.FindSet(true);
        for I := 1 to LibraryVariableStorage.DequeueInteger() do begin
            TrackingSpec.Validate("Qty. to Invoice (Base)", TrackingSpec."Quantity (Base)");
            TrackingSpec.Modify(true);
            if TrackingSpec.Next() = 0 then
                exit;
        end;
    end;

    local procedure SetupLotTrackingItemJournalLineForChangeBin(var ItemJournalLine: Record "Item Journal Line"; SignFactor: Integer; WhseTracking: Boolean; EntryType: Enum "Item Ledger Document Type"; SetNoOption: Option): Code[20]
    var
        Bin: array[2] of Record Bin;
        ItemNo: Code[20];
        LotNo: array[2] of Code[20];
        Qty: array[2] of Integer;
    begin
        // General Setup: Add Item in Bins with item tracking
        SetupLotTrackingEntryForChangeBin(Bin, ItemNo, LotNo, WhseTracking, Qty);

        // Create item journal line and add Lot No for tracking
        CreateItemJournalLineWithBin(ItemJournalLine, Bin[1], EntryType, ItemNo, SignFactor * Qty[1]);
        EnqueueVariablesForSetLotTrackingNo(LotNo, Qty, SignFactor, SetNoOption);
        ItemJournalLine.OpenItemTrackingLines(false);
        exit(Bin[2].Code);
    end;

    local procedure SetupLotTrackingJobJournalLineForChangeBin(var JobJournalLine: Record "Job Journal Line"; SignFactor: Integer; WhseTracking: Boolean; SetNoOption: Option): Code[20]
    var
        Bin: array[2] of Record Bin;
        ItemNo: Code[20];
        LotNo: array[2] of Code[20];
        Qty: array[2] of Integer;
    begin
        // General Setup: Add Item in Bins with item tracking
        SetupLotTrackingEntryForChangeBin(Bin, ItemNo, LotNo, WhseTracking, Qty);

        // Create job journal line and add Lot No for tracking
        CreateJobJournalLineWithBin(JobJournalLine, Bin[1], JobJournalLine.Type::Item, ItemNo, SignFactor * Qty[1]);
        EnqueueVariablesForSetLotTrackingNo(LotNo, Qty, SignFactor, SetNoOption);
        JobJournalLine.OpenItemTrackingLines(false);
        exit(Bin[2].Code);
    end;

    local procedure SetupLotTrackingPurchaseLineForChangeBin(var PurchaseLine: Record "Purchase Line"; SignFactor: Integer; WhseTracking: Boolean; SetNoOption: Option): Code[20]
    var
        Bin: array[2] of Record Bin;
        ItemNo: Code[20];
        LotNo: array[2] of Code[20];
        Qty: array[2] of Integer;
    begin
        // General Setup: Add Item in Bins with item tracking
        SetupLotTrackingEntryForChangeBin(Bin, ItemNo, LotNo, WhseTracking, Qty);

        // Create purchase line and add Lot No for tracking
        CreatePurchaseLineWithBin(PurchaseLine, Bin[1], ItemNo, SignFactor * Qty[1]);
        EnqueueVariablesForSetLotTrackingNo(LotNo, Qty, SignFactor, SetNoOption);
        PurchaseLine.OpenItemTrackingLines();
        exit(Bin[2].Code);
    end;

    local procedure SetupLotTrackingProdCompForChangeBin(var ProdOrderComp: Record "Prod. Order Component"; SignFactor: Integer; WhseTracking: Boolean; SetNoOption: Option): Code[20]
    var
        Bin: array[2] of Record Bin;
        ItemNo: Code[20];
        LotNo: array[2] of Code[20];
        Qty: array[2] of Integer;
    begin
        // General Setup: Add Item in Bins with item tracking
        SetupLotTrackingEntryForChangeBin(Bin, ItemNo, LotNo, WhseTracking, Qty);

        // Create Prod. Order Component line and add Lot No for tracking
        CreateProdOrderCompWithBin(ProdOrderComp, Bin[1], ItemNo, SignFactor * Qty[1]);
        EnqueueVariablesForSetLotTrackingNo(LotNo, Qty, SignFactor, SetNoOption);
        ProdOrderComp.OpenItemTrackingLines();
        exit(Bin[2].Code);
    end;

    local procedure SetupLotTrackingEntryForChangeBin(var Bin: array[2] of Record Bin; var ItemNo: Code[20]; var LotNo: array[2] of Code[50]; WhseTracking: Boolean; var Qty: array[2] of Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.Get(CreateItemTrackingCode(false, true));
        ItemTrackingCode.Validate("Lot Warehouse Tracking", WhseTracking);
        ItemTrackingCode.Modify(true);

        ItemNo := CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);
        CreateLocationWithBin(Bin[1], ItemNo);
        LibraryWarehouse.CreateBin(Bin[2], Bin[1]."Location Code", LibraryUtility.GenerateGUID(), '', ''); // Use blank values for Unit Of Measure Code and Zone Code.

        Qty[1] := LibraryRandom.RandIntInRange(10, 20);
        Qty[2] := LibraryRandom.RandInt(9);

        // Add Qty[1] of Item into Bin1 with Lot1 by clicking Assign Lot No.
        LotNo[1] := GetLotNoFromItemTrackingEntries(
            ItemNo, IncreaseItemInventoryWithBin(Bin[1], ItemNo, Qty[1], TrackingOption::AssignLotNo));

        // Add Qty[2] of Item into Bin2 with Lot1 by setting the Lot No. manually
        CreateItemJournalLineWithBin(ItemJournalLine, Bin[2], ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty[2]);
        SetLotNoAndQtyOnItemTrackingLine(LotNo[1], Qty[2]);
        PostOutputJournal(ItemJournalLine);

        // Add Qty[1]-Qty[2] of Item into Bin2 with Lot2 by clicking Assign Lot No.
        LotNo[2] := GetLotNoFromItemTrackingEntries(
            ItemNo, IncreaseItemInventoryWithBin(Bin[2], ItemNo, Qty[1] - Qty[2], TrackingOption::AssignLotNo));
    end;

    local procedure SetupSerialTrackingItemJournalLineForChangeBin(var ItemJournalLine: Record "Item Journal Line"; SignFactor: Integer; WhseTracking: Boolean; EntryType: Enum "Item Ledger Document Type"; SetNoOption: Option): Code[20]
    var
        Bin: array[2] of Record Bin;
        ItemJournalDocNo: array[2] of Code[20];
        ItemNo: Code[20];
        Qty: Integer;
    begin
        // General Setup: Add Item in Bins with item tracking
        SetupSerialTrackingEntryForChangeBin(Bin, ItemNo, ItemJournalDocNo, WhseTracking, Qty);

        // Create item journal line and add Serial No for tracking
        CreateItemJournalLineWithBin(ItemJournalLine, Bin[1], EntryType, ItemNo, SignFactor * Qty);
        EnqueueVariablesForSetSerialTrackingNo(ItemJournalDocNo, ItemNo, ItemJournalLine.Quantity, SignFactor, SetNoOption);
        ItemJournalLine.OpenItemTrackingLines(false);
        exit(Bin[2].Code);
    end;

    local procedure SetupSerialTrackingJobJournalLineForChangeBin(var JobJournalLine: Record "Job Journal Line"; SignFactor: Integer; WhseTracking: Boolean; SetNoOption: Option): Code[20]
    var
        Bin: array[2] of Record Bin;
        ItemJournalDocNo: array[2] of Code[20];
        ItemNo: Code[20];
        Qty: Integer;
    begin
        // General Setup: Add Item in Bins with item tracking
        SetupSerialTrackingEntryForChangeBin(Bin, ItemNo, ItemJournalDocNo, WhseTracking, Qty);

        // Create job journal line and add Serial No for tracking
        CreateJobJournalLineWithBin(JobJournalLine, Bin[1], JobJournalLine.Type::Item, ItemNo, SignFactor * Qty);
        EnqueueVariablesForSetSerialTrackingNo(ItemJournalDocNo, ItemNo, JobJournalLine.Quantity, SignFactor, SetNoOption);
        JobJournalLine.OpenItemTrackingLines(false);
        exit(Bin[2].Code);
    end;

    local procedure SetupSerialTrackingPurchaseLineForChangeBin(var PurchaseLine: Record "Purchase Line"; SignFactor: Integer; WhseTracking: Boolean; SetNoOption: Option): Code[20]
    var
        Bin: array[2] of Record Bin;
        ItemJournalDocNo: array[2] of Code[20];
        ItemNo: Code[20];
        Qty: Integer;
    begin
        // General Setup: Add Item in Bins with item tracking
        SetupSerialTrackingEntryForChangeBin(Bin, ItemNo, ItemJournalDocNo, WhseTracking, Qty);

        // Create purchase line and add Serial No for tracking
        CreatePurchaseLineWithBin(PurchaseLine, Bin[1], ItemNo, SignFactor * Qty);
        EnqueueVariablesForSetSerialTrackingNo(ItemJournalDocNo, ItemNo, PurchaseLine.Quantity, SignFactor, SetNoOption);
        PurchaseLine.OpenItemTrackingLines();
        exit(Bin[2].Code);
    end;

    local procedure SetupSerialTrackingProdCompForChangeBin(var ProdOrderComp: Record "Prod. Order Component"; SignFactor: Integer; WhseTracking: Boolean; SetNoOption: Option): Code[20]
    var
        Bin: array[2] of Record Bin;
        ItemJournalDocNo: array[2] of Code[20];
        ItemNo: Code[20];
        Qty: Integer;
    begin
        // General Setup: Add Item in Bins with item tracking
        SetupSerialTrackingEntryForChangeBin(Bin, ItemNo, ItemJournalDocNo, WhseTracking, Qty);

        // Create Prod. Order component and add Serial No for tracking
        CreateProdOrderCompWithBin(ProdOrderComp, Bin[1], ItemNo, SignFactor * Qty);
        EnqueueVariablesForSetSerialTrackingNo(ItemJournalDocNo, ItemNo, ProdOrderComp.Quantity, SignFactor, SetNoOption);
        ProdOrderComp.OpenItemTrackingLines();
        exit(Bin[2].Code);
    end;

    local procedure SetupSerialTrackingEntryForChangeBin(var Bin: array[2] of Record Bin; var ItemNo: Code[20]; var ItemJournalDocNo: array[2] of Code[20]; WhseTracking: Boolean; var Qty: Integer)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.Get(CreateItemTrackingCode(true, false));
        ItemTrackingCode.Validate("SN Warehouse Tracking", WhseTracking);
        ItemTrackingCode.Modify(true);

        ItemNo := CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);
        CreateLocationWithBin(Bin[1], ItemNo);
        LibraryWarehouse.CreateBin(Bin[2], Bin[1]."Location Code", LibraryUtility.GenerateGUID(), '', '');  // Use blank values for Unit Of Measure Code and Zone Code.

        Qty := LibraryRandom.RandInt(10);

        // Add Qty of Item into Bin[1] with serial code
        ItemJournalDocNo[1] := IncreaseItemInventoryWithBin(Bin[1], ItemNo, Qty, TrackingOption::AssignSerialLot);

        // Add Qty of Item into Bin[2] with new serial code
        ItemJournalDocNo[2] := IncreaseItemInventoryWithBin(Bin[2], ItemNo, Qty, TrackingOption::AssignSerialLot);
    end;

    local procedure SetupTrackingEntryForSalesAndPurchase(var ItemLedgerEntry: Record "Item Ledger Entry"; TrackingOption: Option; SNSpecific: Boolean; LotSpecific: Boolean)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        Item.Get(
          CreateTrackedItem(
            LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(SNSpecific, LotSpecific)));
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, Item."No.", '', TrackingOption);
        CreateAndPostSalesOrderWithIT(SalesLine, PurchaseLine."No.", '', PurchaseLine.Quantity, false);
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.");
    end;

    local procedure SetupLongChainWithTransferAndLot(var ItemLedgerEntry: Record "Item Ledger Entry"; CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferLine1: Record "Transfer Line";
        TransferQty: Decimal;
        SalesOrderQty: Decimal;
    begin
        // Setup: Create Purchase Order with Item Tracking and Post.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Item.Get(CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true)));
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, Item."No.", Location.Code, TrackingOption::AssignLotNo);

        // Create and Post Transfer Order Location A -> Location B.
        TransferQty := LibraryRandom.RandIntInRange(PurchaseLine.Quantity - 10, PurchaseLine.Quantity);
        CreateTransferOrder(TransferLine, Location.Code, Item."No.", TransferQty);
        TransferHeader.Get(TransferLine."Document No.");
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

        // Create and Post Transfer Order Location B -> Location A.
        CreateAndPostTransferOrderWithIT(
          TransferLine, TransferLine."Transfer-to Code", TransferLine."Transfer-from Code", TransferLine."In-Transit Code", Item."No.",
          LibraryRandom.RandIntInRange(TransferQty - 10, TransferQty - 1));

        // Create and Post Transfer Order Location A -> Location B.
        CreateAndPostTransferOrderWithIT(
          TransferLine1, Location.Code, TransferLine."Transfer-from Code", TransferLine."In-Transit Code", Item."No.",
          LibraryRandom.RandIntInRange(TransferLine.Quantity - 10, TransferLine.Quantity - 1));

        // Post SO with IT.
        SalesOrderQty := LibraryRandom.RandInt(TransferQty - TransferLine.Quantity);
        CreateAndPostSalesOrderWithIT(SalesLine, PurchaseLine."No.", TransferLine."Transfer-from Code", SalesOrderQty, false);
        CreateAndPostSalesOrderWithIT(
          SalesLine, PurchaseLine."No.", TransferLine."Transfer-from Code",
          TransferQty - TransferLine.Quantity + TransferLine1.Quantity - SalesOrderQty, false);

        FindItemLedgerEntry(ItemLedgerEntry, Item."No.");
    end;

    local procedure SetupProdChainWithSN(var CompItemLedgerEntry: Record "Item Ledger Entry"; var SubItemLedgerEntry: Record "Item Ledger Entry"; var TopItemLedgerEntry: Record "Item Ledger Entry")
    var
        Item: Record Item;
        Item1: Record Item;
        Item2: Record Item;
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create BOM structure 2 levels deep.
        Initialize();
        Item.Get(
          CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, true)));
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);

        Item1.Get(
          CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, true)));
        Item1.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item1.Modify(true);
        CreateProdBOMWithOneComp(Item, Item1);

        Item2.Get(
          CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, true)));
        CreateProdBOMWithOneComp(Item1, Item2);

        // Purchase component with IT.
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, Item2."No.", '', TrackingOption::AssignSerialLot);

        // Create Released Production Orders and Post Output for first 2 levels.
        CreateAndRefreshProductionOrderWithIT(
          ProductionOrder, ProductionOrder.Status::Released, Item1."No.", PurchaseLine.Quantity div 10, TrackingOption::AssignSerialLot);
        CreateAndPostConsumptionJournal(ProductionOrder."No.");
        CreateAndPostOutputJournal(ProductionOrder."No.");

        CreateAndRefreshProductionOrderWithIT(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", PurchaseLine.Quantity div 10, TrackingOption::AssignSerialLot);
        CreateAndPostConsumptionJournal(ProductionOrder."No.");
        CreateAndPostOutputJournal(ProductionOrder."No.");

        FindItemLedgerEntry(CompItemLedgerEntry, Item2."No.");
        FindItemLedgerEntry(SubItemLedgerEntry, Item1."No.");
        FindItemLedgerEntry(TopItemLedgerEntry, Item."No.");
    end;

    local procedure SetLotNoAndQtyOnItemTrackingLine(LotNo: Code[50]; Qty: Integer)
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::SetLotNoAndQty);
        LibraryVariableStorage.Enqueue(1); // Enqueue the line count
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
    end;

    local procedure SetPurchaseLineQtyToReceive(var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    begin
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure SetSalesLineQtyToShip(var SalesLine: Record "Sales Line"; QtyToShip: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure SetSerialNosAndQtyOnItemTrackingLine(SerialNos: array[10] of Code[20]; Qty: Integer; "Count": Integer)
    var
        Qtys: array[10] of Integer;
        I: Integer;
    begin
        for I := 1 to Count do
            Qtys[I] := Qty;
        SetNoAndQtyOnItemTrackingLines(SerialNos, Qtys, Count, TrackingOption::SetSerialNoAndQty);
    end;

    local procedure SetNoAndQtyOnItemTrackingLines(No: array[10] of Code[20]; Qty: array[10] of Integer; "Count": Integer; TrackingOption: Option)
    var
        I: Integer;
    begin
        LibraryVariableStorage.Enqueue(TrackingOption);
        LibraryVariableStorage.Enqueue(Count); // Enqueue the line count
        for I := 1 to Count do begin
            LibraryVariableStorage.Enqueue(No[I]);
            LibraryVariableStorage.Enqueue(Qty[I]);
        end;
    end;

    local procedure SetTrackingNoAndQty(ItemTrackingLines: TestPage "Item Tracking Lines"; ItemTrackingMethod: Option)
    var
        "Count": Variant;
        No: Variant;
        Quantity: Variant;
        I: Integer;
        Count2: Integer;
    begin
        LibraryVariableStorage.Dequeue(Count);
        Count2 := Count;
        for I := 1 to Count2 do begin
            LibraryVariableStorage.Dequeue(No);
            LibraryVariableStorage.Dequeue(Quantity);
            case ItemTrackingMethod of
                TrackingOption::SetLotNoAndQty:
                    ItemTrackingLines."Lot No.".SetValue(No);
                TrackingOption::SetSerialNoAndQty:
                    ItemTrackingLines."Serial No.".SetValue(No);
            end;
            ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
            ItemTrackingLines.Next();
        end;
    end;

    local procedure SelectApplyToItemEntry(ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        EntryNo: Integer;
        EntryNoVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntryNoVar);
        EntryNo := EntryNoVar;
        ItemLedgEntry.Get(EntryNo);
        ItemTrackingLines."Lot No.".SetValue(ItemLedgEntry."Lot No.");
        ItemTrackingLines."Quantity (Base)".SetValue(ItemLedgEntry.Quantity);
        ItemTrackingLines."Appl.-to Item Entry".SetValue(EntryNo);
    end;

    local procedure SalesHeaderCopySalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type From"; DocNo: Code[20]; IncludeHeader: Boolean; RecalcLines: Boolean)
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(DocType, DocNo, IncludeHeader, RecalcLines);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();
    end;

    local procedure PurchaseHeaderCopyPurchDoc(var PurchHeader: Record "Purchase Header"; DocType: Enum "Sales Document Type From"; DocNo: Code[20]; IncludeHeader: Boolean; RecalcLines: Boolean)
    var
        CopyPurchDocument: Report "Copy Purchase Document";
    begin
        CopyPurchDocument.SetPurchHeader(PurchHeader);
        CopyPurchDocument.SetParameters(DocType, DocNo, IncludeHeader, RecalcLines);
        CopyPurchDocument.UseRequestPage(false);
        CopyPurchDocument.Run();
    end;

    local procedure OpenItemTracingPage(var ItemTracing: TestPage "Item Tracing"; ItemNoFilter: Code[20]; SerialNoFilter: Code[50]; LotNoFilter: Code[50]; TraceMethod: Option)
    var
        ShowComponents: Option No,"Item-tracked Only",All;
    begin
        ItemTracing.OpenEdit();
        ItemTracing.ItemNoFilter.SetValue(ItemNoFilter);
        ItemTracing.SerialNoFilter.SetValue(SerialNoFilter);
        ItemTracing.LotNoFilter.SetValue(LotNoFilter);
        ItemTracing.TraceMethod.SetValue(TraceMethod);
        ItemTracing.ShowComponents.SetValue(ShowComponents::All);
        ItemTracing.Trace.Invoke();
    end;

    local procedure UpdateItem(Item: Record Item; ProductionBOMHeaderNo: Code[20]; RoutingHeaderNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMHeaderNo);
        Item.Validate("Routing No.", RoutingHeaderNo);
        Item.Modify(true);
    end;

    local procedure UpdateQuantityOnItemTrackingLines(var TransferLine: Record "Transfer Line"; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::SetQuantity);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure UpdateGeneralPostingSetup(PurchaseLine: Record "Purchase Line")
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        if GeneralPostingSetup."Purch. Account" = '' then begin
            GeneralPostingSetup.Validate("Purch. Account", GLAccount."No.");
            GeneralPostingSetup.Modify(true);
        end;
    end;

    local procedure UpdateSalesReceivablesSetup(ExactCostReversingMandatory: Boolean) OldExactCostReversingMandatory: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldExactCostReversingMandatory := SalesReceivablesSetup."Exact Cost Reversing Mandatory";
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayablesSetup(ExactCostReversingMandatory: Boolean) OldExactCostReversingMandatory: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldExactCostReversingMandatory := PurchasesPayablesSetup."Exact Cost Reversing Mandatory";
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdatePurchHeader(var PurchHeader: Record "Purchase Header")
    begin
        PurchHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchHeader.Modify(true);
    end;

    local procedure VerifyPostedSalesCreditMemo(No: Code[20]; Quantity: Decimal)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("No.", No);
        SalesCrMemoLine.FindFirst();
        Assert.AreEqual(Quantity, SalesCrMemoLine.Quantity, QuantityErr);
    end;

    local procedure VerifyPostedTransferReceipt(ItemNo: Code[20])
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        TransferReceiptLine.SetRange("Item No.", ItemNo);
        Assert.IsFalse(TransferReceiptLine.IsEmpty, TransferReceiptLineNotExistsErr);
    end;

    local procedure VerifyInvoicedQtyOnPurchRcptLine(ItemNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindSet();
        repeat
            Assert.AreEqual(PurchRcptLine.Quantity, PurchRcptLine."Quantity Invoiced", StrSubstNo(WrongInvoicedQtyErr, PurchRcptLine.TableCaption));
        until PurchRcptLine.Next() = 0;
    end;

    local procedure VerifyInvoicedQtyOnSalesShptLine(ItemNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.FindSet();
        repeat
            Assert.AreEqual(SalesShipmentLine.Quantity, SalesShipmentLine."Quantity Invoiced", StrSubstNo(WrongInvoicedQtyErr, SalesShipmentLine.TableCaption));
        until SalesShipmentLine.Next() = 0;
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10]; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemTracingLine(ItemTracing: TestPage "Item Tracing"; Description: Text; SerialNo: Code[50]; LotNo: Code[50]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        Assert.IsTrue(StrPos(ItemTracing.Description.Value, Description) > 0, DescriptionErr);
        ItemTracing."Serial No.".AssertEquals(SerialNo);
        ItemTracing."Lot No.".AssertEquals(LotNo);
        ItemTracing."Item No.".AssertEquals(ItemNo);
        ItemTracing.Quantity.AssertEquals(Quantity);
        ItemTracing."Location Code".AssertEquals(LocationCode);
    end;

    local procedure VerifyNextItemTracingLine(ItemTracing: TestPage "Item Tracing"; Description: Text; SerialNo: Code[50]; LotNo: Code[50]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        ItemTracing.Expand(true);
        ItemTracing.Next();
        VerifyItemTracingLine(ItemTracing, Description, SerialNo, LotNo, ItemNo, LocationCode, Quantity);
    end;

    local procedure VerifyItemTracingLinesForLongChain(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemTracing: TestPage "Item Tracing"; IsFirstLevel: Boolean)
    begin
        ItemTracing.Expand(true);

        if ItemLedgerEntry.FindSet() then
            repeat
                if IsFirstLevel then
                    VerifySingleItemTracingLine(ItemTracing, ItemLedgerEntry, 1)
                else
                    VerifySingleItemTracingLine(ItemTracing, ItemLedgerEntry, GetApplications(ItemLedgerEntry))
            until ItemLedgerEntry.Next() = 0;
    end;

    [Normal]
    local procedure VerifySingleItemTracingLine(ItemTracing: TestPage "Item Tracing"; ItemLedgerEntry: Record "Item Ledger Entry"; ExpCount: Integer)
    var
        ActCount: Integer;
    begin
        ActCount := 0;
        ItemTracing.FILTER.SetFilter(Description, '*' + ItemLedgerEntry."Document No." + '*');
        ItemTracing.FILTER.SetFilter("Serial No.", ItemLedgerEntry."Serial No.");
        ItemTracing.FILTER.SetFilter("Lot No.", ItemLedgerEntry."Lot No.");
        ItemTracing.FILTER.SetFilter("Item No.", ItemLedgerEntry."Item No.");
        ItemTracing.FILTER.SetFilter("Location Code", ItemLedgerEntry."Location Code");
        ItemTracing.FILTER.SetFilter(Quantity, Format(ItemLedgerEntry.Quantity));

        if ItemTracing.First() then
            ActCount := 1;

        while ItemTracing.Next() do begin
            ActCount += 1;
            ItemTracing."Already Traced".AssertEquals(true); // If there are multiple occurences of the same inbound, the subsequent ones should be already traced.
        end;

        Assert.AreEqual(ExpCount, ActCount, 'Unexpected no. of tracing entries for ILE ' + Format(ItemLedgerEntry."Entry No."))
    end;

    local procedure VerifyAlreadyTraced(ItemTracing: TestPage "Item Tracing")
    var
        Description: Text;
    begin
        ItemTracing.Expand(true);
        ItemTracing.First();

        while ItemTracing.Next() do
            if ItemTracing."Already Traced".AsBoolean() then begin
                Description := Format(ItemTracing.Description);
                ItemTracing."Go to Already-Traced History".Invoke();
                ItemTracing."Already Traced".AssertEquals(false);
                ItemTracing.Description.AssertEquals(Description);
                exit;
            end;
    end;

    local procedure VerifyQtyOnPurchaseLine(PurchHeaderNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        FindPurchLine(PurchLine, PurchHeaderNo, ItemNo);
        Assert.AreEqual(Qty, PurchLine.Quantity, QuantityErr);
    end;

    local procedure VerifyQtyOnSalesLine(SalesHeaderNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeaderNo, ItemNo);
        Assert.AreEqual(Qty, SalesLine.Quantity, QuantityErr);
    end;

    local procedure VerifyQtyPerUoMOnReservation(DocumentType: Option; DocumentNo: Code[20]; ExpectedQtyPerUoM: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetRange("Source Type", DATABASE::"Purchase Line");
        ReservEntry.SetRange("Source Subtype", DocumentType);
        ReservEntry.SetRange("Source ID", DocumentNo);
        ReservEntry.FindSet();
        repeat
            Assert.AreEqual(
              ExpectedQtyPerUoM, ReservEntry."Qty. per Unit of Measure",
              StrSubstNo(WrongFieldValueErr, ReservEntry.FieldCaption("Qty. per Unit of Measure"), ReservEntry.TableCaption()));
        until ReservEntry.Next() = 0;
    end;

    local procedure GetApplications(ItemLedgerEntry: Record "Item Ledger Entry"): Integer
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.Reset();
        if ItemLedgerEntry.Positive then begin
            ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
        end else
            ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgerEntry."Entry No.");

        ItemApplicationEntry.SetRange("Transferred-from Entry No.", 0);
        exit(ItemApplicationEntry.Count);
    end;

    local procedure SetApplFromToItemEntry(var ReservationEntry: Record "Reservation Entry"; SetPositive: Boolean)
    begin
        ReservationEntry.Positive := SetPositive;
        ReservationEntry."Appl.-to Item Entry" := 1;
        ReservationEntry."Appl.-from Item Entry" := 1;
    end;

    local procedure PostPositiveAdjustmentWithLotNo(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; PositiveAdjustmentQuantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, PositiveAdjustmentQuantity);
        LibraryVariableStorage.Enqueue(TrackingOptionWithTwoLots::OrderDocument); // Enqueue value for ItemTrackingLinesPageHandlerWithSpecificTwoLots.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateItemTrackingExpiry(TrackingCode: Code[10])
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.Get(TrackingCode);
        ItemTrackingCode.Validate("Use Expiration Dates", false);
        ItemTrackingCode.Modify(true);
    end;

    local procedure UpdateItemReOrderPolicyForLot(var Item: Record Item)
    begin
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);
    end;

    local procedure UpdateParentItemForProduction(var Item: Record Item)
    begin
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");
        Item.Modify(true);
    end;

    local procedure CreateItemJournalLineWithItemTracking(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; LocationCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNoManual);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name",
            ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
            ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Lot No.", LotNo);
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure RunCalculateRegenerativePlan(ItemFilter: Text)
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", ItemFilter);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));  // Dates based on WORKDATE.
    end;

    local procedure CreateAndPostConsumptionJournalWithItemTracking(ProdOrderNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
    begin
        ConsumptionJournalSetup(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ConsumptionItemJournalTemplate.Name,
            ConsumptionItemJournalBatch.Name, ItemJournalLine."Entry Type"::Consumption,
            ItemNo, Qty);
        ItemJournalLine.Validate("Order No.", ProdOrderNo);
        ItemJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOption::SetLotNoAndQty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure ConsumptionJournalSetup(var ConsumptionItemJournalTemplate: Record "Item Journal Template"; var ConsumptionItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type, ConsumptionItemJournalTemplate.Name);
    end;

    local procedure CreateAndPostPurchOrderWithTrackedItem(var ItemLedgerEntry: Record "Item Ledger Entry"; var Item: Record Item; TrackingOption: Option; SNSpecific: Boolean; LotSpecific: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        Item.Get(
            CreateTrackedItem(
                LibraryUtility.GetGlobalNoSeriesCode(),
                LibraryUtility.GetGlobalNoSeriesCode(),
                CreateItemTrackingCode(SNSpecific, LotSpecific)));

        Item.Validate(Description, LibraryUtility.GenerateRandomText(LibraryRandom.RandIntInRange(60, 60)));
        Item.Modify(true);

        CreateAndPostPurchaseOrderWithIT(PurchaseLine, Item."No.", '', TrackingOption);
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Quantity: Variant;
        TrackingOptionValue: Option;
    begin
        TrackingOptionValue := LibraryVariableStorage.DequeueInteger();
        case TrackingOptionValue of
            TrackingOption::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingOption::AssignSerialLot:
                ItemTrackingLines."Assign Serial No.".Invoke();
            TrackingOption::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            TrackingOption::SetQuantity:
                begin
                    LibraryVariableStorage.Dequeue(Quantity);
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
            TrackingOption::SetLotNoAndQty, TrackingOption::SetSerialNoAndQty:
                SetTrackingNoAndQty(ItemTrackingLines, TrackingOptionValue);
            TrackingOption::SelectAndApplyToItemEntry:
                SelectApplyToItemEntry(ItemTrackingLines);
            TrackingOption::SetEntriesToInvoice:
                SelectTrackingEntriesToInvoice();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandlerWithSpecificTwoLots(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingOptionWithTwoLotsValue: Option;
    begin
        TrackingOptionWithTwoLotsValue := LibraryVariableStorage.DequeueInteger();
        case TrackingOptionWithTwoLotsValue of
            TrackingOptionWithTwoLots::AssignLotNoWithQtyToHandle:
                begin
                    if LotNoWithTwoLots[1] = '' then
                        LotNoWithTwoLots[1] := LibraryUtility.GenerateGUID();
                    if LotNoWithTwoLots[2] = '' then
                        LotNoWithTwoLots[2] := LibraryUtility.GenerateGUID();

                    ItemTrackingLines."Lot No.".SetValue(LotNoWithTwoLots[1]);
                    ItemTrackingLines."Quantity (Base)".SetValue(6);
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(5);
                    ItemTrackingLines.Next();
                    ItemTrackingLines."Lot No.".SetValue(LotNoWithTwoLots[2]);
                    ItemTrackingLines."Quantity (Base)".SetValue(4);
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(3);
                end;
            TrackingOptionWithTwoLots::ChangeQtyToInvoice:
                begin
                    ItemTrackingLines.First();
                    case ItemTrackingLines."Lot No.".Value() of
                        LotNoWithTwoLots[1]:
                            ItemTrackingLines."Qty. to Invoice (Base)".SetValue(4);
                        LotNoWithTwoLots[2]:
                            ItemTrackingLines."Qty. to Invoice (Base)".SetValue(2);
                    end;
                    ItemTrackingLines.Next();
                    case ItemTrackingLines."Lot No.".Value() of
                        LotNoWithTwoLots[1]:
                            ItemTrackingLines."Qty. to Invoice (Base)".SetValue(4);
                        LotNoWithTwoLots[2]:
                            ItemTrackingLines."Qty. to Invoice (Base)".SetValue(2);
                    end;
                end;
            TrackingOptionWithTwoLots::OrderDocument:
                begin
                    if LotNoWithTwoLots[1] = '' then
                        LotNoWithTwoLots[1] := LibraryUtility.GenerateGUID();
                    if LotNoWithTwoLots[2] = '' then
                        LotNoWithTwoLots[2] := LibraryUtility.GenerateGUID();

                    ItemTrackingLines."Lot No.".SetValue(LotNoWithTwoLots[1]);
                    ItemTrackingLines."Quantity (Base)".SetValue(10);
                    ItemTrackingLines.New();
                    ItemTrackingLines."Lot No.".SetValue(LotNoWithTwoLots[2]);
                    ItemTrackingLines."Quantity (Base)".SetValue(10);
                end;
            TrackingOptionWithTwoLots::ReturnOrderDocument:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LotNoWithTwoLots[1]);
                    ItemTrackingLines."Quantity (Base)".SetValue(6);
                    ItemTrackingLines.New();
                    ItemTrackingLines."Lot No.".SetValue(LotNoWithTwoLots[2]);
                    ItemTrackingLines."Quantity (Base)".SetValue(4);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
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
    procedure EnterQuantityToCreatePageHandlerFalse(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateNewLotNo.SetValue(false);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesModalPageHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
        LibraryVariableStorage.Enqueue(PostedItemTrackingLines.Quantity.AsDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PostedSalesDocumentLines.PostedInvoices.FILTER.SetFilter("Document No.", DocumentNo);
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PostedPurchaseDocumentLines.PostedInvoices.FILTER.SetFilter("Document No.", DocumentNo);
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobJournalTemplateListHandler(var JobJournalTemplateList: TestPage "Job Journal Template List")
    var
        Name: Variant;
    begin
        LibraryVariableStorage.Dequeue(Name);
        JobJournalTemplateList.FILTER.SetFilter(Name, Name);
        JobJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
        Reservation.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateChangeQtyPageHandler(var EnterQtyToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQtyToCreate.QtyToCreate.SetValue(LibraryVariableStorage.DequeueDecimal());
        EnterQtyToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummarySelectEntriesPageHandler(var ItemTrackingSummaryPage: TestPage "Item Tracking Summary")
    var
        I: Integer;
        TotalQtyToAssign: Integer;
    begin
        ItemTrackingSummaryPage.First();
        TotalQtyToAssign := LibraryVariableStorage.DequeueInteger();
        repeat
            I += 1;
            ItemTrackingSummaryPage."Selected Quantity".SetValue(I <= TotalQtyToAssign);
        until not ItemTrackingSummaryPage.Next();

        ItemTrackingSummaryPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandlerTrackingOption(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
    begin
        case LibraryVariableStorage.DequeueInteger() of
            TrackingOption::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingOption::AssignLotNoManual:
                begin
                    ItemTrackingLines.New();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            TrackingOption::SetLotNoAndQty:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
        end;

        ItemTrackingLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemTracingSpecificationRequestPageHandler(var ItemTracingSpecification: TestRequestPage "Item Tracing Specification")
    begin
        ItemTracingSpecification."FldNo[1]".SetValue(LibraryVariableStorage.DequeueInteger());
        ItemTracingSpecification.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

