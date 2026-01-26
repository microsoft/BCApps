codeunit 137305 "SCM Warehouse Reports"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Reports] [SCM]
        isInitialized := false;
    end;

    var
        LocationWhite: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        ValidationErr: Label '%1 must be %2 in %3.';
        CombineShipmentMsg: Label 'The shipments are now combined';
        JournalLineRegistered: Label 'The journal lines were successfully registered.';
        WantToRegisterConfirm: Label 'Do you want to register the journal lines?';
        ErrRecordMissing: Label 'The record count must match.';
        SHIP: Label 'SHIP';
        BULK: Label 'BULK';
        InvtPutAwayCreated: Label 'Number of Invt. Put-away activities created';
        CombineShipmentErr: Label 'Incorrect Sales Invoice Line Type';
        RequestPageMissingErr: Label 'RequestPage %1', Comment = '%1 - Report ID';
        TransferOrderCaptionLbl: Label 'Transfer Order No.';
        ConfirmChangeQst: Label 'Do you want to change';
        RecreateSalesLinesMsg: Label 'If you change';
        WhsePostAndPrintMsg: Label 'Number of source documents posted: 1 out of a total of 1.\\Number of put-away activities created: 1.';
        NumberOfDocPrintedMsg: Label 'Number of put-away activities printed: 1.';
        ReportExecutedErr: Label 'Report Executed should be true';
        WhseEntryItemNoElementName: Label 'WarehouseEntryItemNo';
        LocationErr: Label 'Location %1 should be %2 in %3.', comment = '%1= acutal location, %2= Location defined, %3 =table name';

    [Test]
    [HandlerFunctions('PickingListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PickingList()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseShipmentNo: Code[20];
    begin
        // Setup : Create Setup to generate Pick for a Item.
        Initialize();
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandDec(100, 2));
        RegisterPutAway(Location.Code, PurchaseHeader."No.");
        CreateAndReleaseSalesOrder(SalesHeader, Location.Code, Item."No.", LibraryRandom.RandDec(10, 2) + 5);
        CreateWhseShipmentAndPick(WarehouseShipmentNo, SalesHeader);

        // Exercise: Generate the Picking List. Value used is important for test.
        Commit();
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        ReportSelectionWarehouse.PrintWhseActivityHeader(WarehouseActivityHeader, ReportSelectionWarehouse.Usage::Pick, false);

        // Verify: Source No shown in Picking List Report is equal to the Source No shown in Warehouse Activity Line Table.
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_WhseActivHeader', WarehouseActivityLine."No.");
        LibraryReportDataset.SetRange('SourceNo_WhseActLine', SalesHeader."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemNo_WhseActLine', WarehouseActivityLine."Item No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('QtyBase_WhseActLine', WarehouseActivityLine."Qty. (Base)");

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetInboundSourceDocuments()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhsePutAwayRqst: Record "Whse. Put-away Request";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        // Setup: Create Warehouse Setup, Create and Release Purchase Order, Post Warehouse Receipt.
        Initialize();
        CreateWarehouseSetup(Location, WarehouseEmployee, true);
        CreateItem(Item);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandDec(100, 2));

        // Exercise: Run Get Inbound Source Documents Batch Report.
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::"Put-away");
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        WhsePutAwayRqst.SetRange("Completely Put Away", false);
        WhsePutAwayRqst.SetRange("Location Code", Location.Code);
        LibraryWarehouse.GetInboundSourceDocuments(WhsePutAwayRqst, WhseWorksheetName, Location.Code);

        // Verify: Check Warehouse Work Sheet Line have same Item No.
        FindWhseWorkSheetLine(WhseWorksheetLine, WhseWorksheetName);
        Assert.AreEqual(
          Item."No.", WhseWorksheetLine."Item No.",
          StrSubstNo(ValidationErr, WhseWorksheetLine.FieldCaption("Item No."), Item."No.", WhseWorksheetLine.TableCaption()));

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PutAwayListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayList()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
    begin
        // Setup: Create Warehouse Setup, Create and Release Purchase Order, Post Warehouse Receipt.
        Initialize();
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandDec(100, 2));

        // Exercise: Run Put-away List report.
        Commit();
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Put-away");
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        ReportSelectionWarehouse.PrintWhseActivityHeader(WarehouseActivityHeader, ReportSelectionWarehouse.Usage::"Put-away", false);

        // Verify.
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_WhseActivHeader', WarehouseActivityLine."No.");
        LibraryReportDataset.SetRange('ItemNo1_WhseActivLine', WarehouseActivityLine."Item No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('SrcNo_WhseActivLine', PurchaseHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('QtyBase_WhseActivLine', WarehouseActivityLine."Qty. (Base)");

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('InventoryPutAwayListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayList()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        // Setup:  Create Warehouse Setup, Create and Release Purchase Order.
        Initialize();
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandDec(10, 2));

        // Exercise: Run Inventory Put-away List report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Put-away List", true, false, Item);

        // Verify.
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo_PurchLine', PurchaseHeader."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('No_Item', Item."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('QtytoReceive_PurchLine', PurchaseLine."Qty. to Receive");
        LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_PurchLine', PurchaseLine."Location Code");

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('WhseReceiptListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhseReceipt()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseReceiptNo: Code[20];
        PurchaseQuantity: Decimal;
    begin
        // Setup: Create Warehouse Setup, Create and Release Purchase Order, Create Warehouse Receipt From Purchase Order.
        Initialize();
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        PurchaseQuantity := LibraryRandom.RandDec(10, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Location.Code, Item."No.", PurchaseQuantity);
        WarehouseReceiptNo := FindWarehouseReceiptNo();
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Exercise: Run Whse. - Receipt report.
        Commit();
        WarehouseReceiptHeader.SetRange("No.", WarehouseReceiptNo);
        ReportSelectionWarehouse.PrintWhseReceiptHeader(WarehouseReceiptHeader, false);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('SourceNo_WhseRcptLine', PurchaseHeader."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_WhseRcptLine', PurchaseQuantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_WhseRcptLine', WarehouseReceiptHeader."Bin Code");

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateBinReplenishment()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Zone: Record Zone;
        Quantity: Decimal;
    begin
        // Setup : Create Warehouse Setup, Zone, Bin, Bin Content And Update Inventory.
        Initialize();
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        UpdateRankingOnAllBins(Location.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        Zone.Get(Location.Code, 'PICK');
        CreateBinContentForBin(Zone, Item, Quantity);
        FindFirstBinRankingForZone(Bin, 'BULK', Location.Code);  // BULK Zone.
        CreateWhseJnlLine(
          WarehouseJournalLine,
          Location.Code, Bin."Zone Code",
          Bin.Code,
          Item."No.",
          Quantity,
          "Warehouse Journal Template Type"::Item);
        LibraryVariableStorage.Enqueue(WantToRegisterConfirm);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLineRegistered);  // Enqueue for MessageHandler.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, false);

        // Exercise : Run Calculate Bin Replenishment.
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        BinContent.SetRange("Location Code", Location.Code);
        LibraryWarehouse.CalculateBinReplenishment(BinContent, WhseWorksheetName, Location.Code, true, false, false);

        // Verify : Verify From Bin Code And To Bin code with Created Warehouse Worksheet Line.
        FindWhseWorkSheetLine(WhseWorksheetLine, WhseWorksheetName);
        FindBinContent(BinContent, Location.Code, Item."No.");
        Bin.Get(Location.Code, BinContent."Bin Code");
        Assert.AreEqual(
          Bin.Code, WhseWorksheetLine."From Bin Code", StrSubstNo(ValidationErr, Bin.FieldCaption(Code), Bin.Code, Bin.TableCaption()));
        FindLastRankingBin(Bin, Location.Code, Zone.Code);
        Assert.AreEqual(
          Bin.Code, WhseWorksheetLine."To Bin Code", StrSubstNo(ValidationErr, Bin.FieldCaption(Code), Bin.Code, Bin.TableCaption()));
        Assert.AreEqual(
          Quantity, WhseWorksheetLine."Qty. to Handle", StrSubstNo(ValidationErr, 'Quantity', Quantity, 'Movement Worksheet'));

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,WhseAdjustmentBinRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhseAdjustmentBin()
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        Location: Record Location;
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // Setup: Create Warehouse Setup, Zone, Bin, Bin Content And Update Inventory, Random Values Important.
        Initialize();
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(50, 2);
        CreateAndRegisterWhseJnlLine(Location, Item."No.", Quantity);

        // Exercise: Run Whse. Adjustment Bin Report.
        WarehouseEntry.SetRange("Location Code", Location.Code);
        REPORT.Run(REPORT::"Whse. Adjustment Bin", true, false, WarehouseEntry);

        // Verify: Check Item No. Exit On the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('WarehouseEntryItemNo', Item."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('WarehouseEntryLocCode', Location.Code);
        Bin.Get(Location.Code, Location."Adjustment Bin Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('WarehouseEntryBinCode', Bin.Code);
        LibraryReportDataset.AssertCurrentRowValueEquals('WhseEntryQtyBase', -Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('WhseEntryQuantity', -Quantity);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('WarehouseBinListReportHandler')]
    [Scope('OnPrem')]
    procedure WarehouseBinList()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
    begin
        // Setup: Create Warehouse Setup, Zone, Bin.
        Initialize();
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);
        UpdateRankingOnAllBins(Location.Code);

        // Exercise: Run Warehouse Bin List Report.
        Commit();
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Adjustment Bin", false);
        REPORT.Run(REPORT::"Warehouse Bin List", true, false, Bin);

        // Verify: Check Bin Ranking with generated report.
        LibraryReportDataset.LoadDataSetFile();
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Adjustment Bin", false);
        Bin.FindSet();
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange('Code_Bin', Bin.Code);
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_Bin', Location.Code);
            LibraryReportDataset.AssertCurrentRowValueEquals('BinRanking_Bin', Bin."Bin Ranking");
            LibraryReportDataset.AssertCurrentRowValueEquals('BinTypeCode_Code', Bin."Bin Type Code");
        until Bin.Next() = 0;

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOutboundSourceDocuments()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        // Setup: Create Warehouse Setup, Create and Release Sales Order, Release Warehouse Shipment.
        Initialize();
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        CreateAndReleaseSalesOrder(SalesHeader, Location.Code, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        ReleaseWarehouseShipment(Location.Code);

        // Exercise: Run Get Outbound Source Documents Batch Report.
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        WhsePickRequest.SetRange(Status, WhsePickRequest.Status::Released);
        WhsePickRequest.SetRange("Completely Picked", false);
        WhsePickRequest.SetRange("Location Code", Location.Code);
        LibraryWarehouse.GetOutboundSourceDocuments(WhsePickRequest, WhseWorksheetName, Location.Code);

        // Verify: Check Warehouse Worksheet Line have same Item No.
        FindWhseWorkSheetLine(WhseWorksheetLine, WhseWorksheetName);
        Assert.AreEqual(
          Item."No.", WhseWorksheetLine."Item No.",
          StrSubstNo(ValidationErr, WhseWorksheetLine.FieldCaption("Item No."), Item."No.", WhseWorksheetLine.TableCaption()));

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MovementListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseMovement()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Zone: Record Zone;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
    begin
        // Setup: Create Warehouse Setup, Zone, Bin, Bin Content And Update Inventory, Calculate Bin Replenishment and Create Movement.
        Initialize();
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Zone.Get(Location.Code, 'PICK');
        CreateBinContentForBin(Zone, Item, 100);
        UpdateRankingOnAllBins(Location.Code);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandDec(100, 2));
        RegisterPutAway(Location.Code, PurchaseHeader."No.");

        // Create Movement Worksheet with Movement.
        CreateMovementWorksheetLine(WhseWorksheetLine, Location.Code, Item."No.");
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::None, false, false, false);

        // Exercise: Run Movement List Report.
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::Movement);
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        ReportSelectionWarehouse.PrintWhseActivityHeader(WarehouseActivityHeader, ReportSelectionWarehouse.Usage::Movement, false);

        // Verify: Check Bin Code with Generated report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyWarehouseActivityLine(Item."No.", Location.Code, WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLine(Item."No.", Location.Code, WarehouseActivityLine."Action Type"::Place);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseCalculateInventory()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create Warehouse Setup, Zone, Bin, Bin Content And Update Inventory.
        Initialize();
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        UpdateRankingOnAllBins(Location.Code);
        Quantity := LibraryRandom.RandDec(10, 2) + 100;  // Value used for quantity more than maximum Bin Content quntity.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", Quantity);
        RegisterPutAway(Location.Code, PurchaseHeader."No.");

        // Exercise: Run Whse. Calculate Inventory Report.
        RunWhseCalculateInventoryReport(Location.Code, Item."No.");

        // Verify: Check Quantity with generated Warehouse Journal Line.
        FindAndVerifyWhseJnlLine(Location.Code, '', Quantity);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('TransferOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrder()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        IntransitLocation: Record Location;
        PurchaseHeader: Record "Purchase Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferQuantity: Decimal;
    begin
        // Setup: Create Item, Location and Transfer Order to New Location.
        Initialize();
        CreateTransferOrderLocations(FromLocation, ToLocation, IntransitLocation);
        CreateItem(Item);
        CreatePurchaseOrder(
          PurchaseHeader, FromLocation.Code, Item."No.", LibraryRandom.RandDec(10, 2) + 100, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        TransferQuantity := LibraryRandom.RandDec(5, 2);
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, IntransitLocation.Code, Item."No.", TransferQuantity);

        // Exercise: Run Transfer Order report.
        Commit();
        TransferHeader.SetRange("Transfer-to Code", TransferHeader."Transfer-to Code");
        REPORT.Run(REPORT::"Transfer Order", true, false, TransferHeader);

        // Verify: Check Transfer Order Quantity equals Quantity in report.
        // [THEN] "Transfer Order No." is printed
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('ItemNo_TransLine', Item."No.", 'Qty_TransLine', TransferQuantity);
        LibraryReportDataset.AssertElementTagWithValueExists('No_TransferHdr', TransferHeader."No.");
        LibraryReportDataset.AssertElementTagWithValueExists('TransferOrderNoCaption', TransferOrderCaptionLbl);
    end;

    [Test]
    [HandlerFunctions('TransferShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransferShipment()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        FromLocation: Record Location;
        TransferLine: Record "Transfer Line";
        ToLocation: Record Location;
        IntransitLocation: Record Location;
        PurchaseHeader: Record "Purchase Header";
        TransferQuantity: Decimal;
    begin
        // Setup: Create Item, Location and Transfer Order to New Location And Post Transfer Shipment.
        Initialize();
        CreateTransferOrderLocations(FromLocation, ToLocation, IntransitLocation);
        CreateItem(Item);
        CreatePurchaseOrder(
          PurchaseHeader, FromLocation.Code, Item."No.", LibraryRandom.RandDec(10, 2) + 100, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        TransferQuantity := LibraryRandom.RandDec(5, 2);
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, IntransitLocation.Code, Item."No.", TransferQuantity);

        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);  // Post Transfer Shipment.

        // Exercise: Run Transfer Shipment  report.
        TransferShipmentHeader.SetRange("Transfer-to Code", TransferHeader."Transfer-to Code");
        REPORT.Run(REPORT::"Transfer Shipment", true, false, TransferShipmentHeader);

        // Verify: Check Transfer Shipment Quantity equals Quantity in report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('ItemNo_TransShptLine', Item."No.", 'Qty_TransShptLine', TransferQuantity);
    end;

    [Test]
    [HandlerFunctions('TransferReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransferReceipt()
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        IntransitLocation: Record Location;
        PurchaseHeader: Record "Purchase Header";
        TransferQuantity: Decimal;
    begin
        // Setup: Create Item, Location and Transfer Order to New Location And Post Transfer Receipt.
        Initialize();
        CreateTransferOrderLocations(FromLocation, ToLocation, IntransitLocation);
        CreateItem(Item);
        CreatePurchaseOrder(
          PurchaseHeader, FromLocation.Code, Item."No.", LibraryRandom.RandDec(10, 2) + 100, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        TransferQuantity := LibraryRandom.RandDec(5, 2);
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, IntransitLocation.Code, Item."No.", TransferQuantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);  // Post Transfer Shipment And Transfer Receipt.

        // Exercise: Run Transfer Receipt report.
        TransferReceiptHeader.SetRange("Transfer-to Code", TransferHeader."Transfer-to Code");
        REPORT.Run(REPORT::"Transfer Receipt", true, false, TransferReceiptHeader);

        // Verify: Check Transfer Receipt Quantity equals Quantity in report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('ItemNo_TransRcpLine', Item."No.", 'Qty_TransRcpLine', TransferQuantity);
    end;

    [Test]
    [HandlerFunctions('WhsePostedReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedWarehouseReceipt()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseEmployee: Record "Warehouse Employee";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseReceiptNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Setup to generate Warehouse receipt;
        Initialize();
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Location.Code, Item."No.", Quantity);
        WarehouseReceiptNo := FindWarehouseReceiptNo();
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindAndUpdateWarehouseReceipt(WarehouseReceiptNo, Item."No.", Quantity / 2);
        PostWarehouseReceipt(WarehouseReceiptNo);
        FindPostedWarehouseReceiptHeader(PostedWhseReceiptHeader, WarehouseReceiptNo, Location.Code);

        // Exercise: Run Posted Receipt report.
        Commit();
        ReportSelectionWarehouse.PrintPostedWhseReceiptHeader(PostedWhseReceiptHeader, false);

        // Verify: Check Quantity To Receive, Item No. Quantity exist in Warehouse Posted Receipt Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('ItemNo_PostedWhseRcpLine', Item."No.", 'Qty_PostedWhseRcpLine', Quantity / 2);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('InventoryPickingListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickingList()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseShipmentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Setup to generate Pick for a Item.
        Initialize();
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", Quantity);
        RegisterPutAway(Location.Code, PurchaseHeader."No.");
        CreateAndReleaseSalesOrder(SalesHeader, Location.Code, Item."No.", Quantity / 2);
        CreateWhseShipmentAndPick(WarehouseShipmentNo, SalesHeader);

        // Exercise: Generate the Picking List. Value used is important for test.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Picking List", true, false, Item);

        // Verify: Source No ,ItemNo and Location shown in Inventory Picking List Report is equal to the Sales Order.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('No_Item', Item."No.", 'DocumentNo_SalesLine', SalesHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_SalesLine', Location.Code);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('WhseShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseShipment()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseEmployee: Record "Warehouse Employee";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseShipmentHeaderNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Setup to generate Pick for a Item.
        Initialize();
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2) + 5;
        CreateAndReleaseSalesOrder(SalesHeader, Location.Code, Item."No.", Quantity);
        WarehouseShipmentHeaderNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Exercise: Generate the Picking List. Value used is important for test.
        Commit();
        WarehouseShipmentHeader.SetRange("No.", WarehouseShipmentHeaderNo);
        ReportSelectionWarehouse.PrintWhseShipmentHeader(WarehouseShipmentHeader, false);

        // Verify: Item No, Quantity and Location shown in Warehouse Shipment Report is equal to the Sales Order.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('ItemNo_WhseShptLine', Item."No.", 'Qty_WhseShptLine', Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_WhseShptLine', Location.Code);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('WhseShipmentStatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhseShipmentStatus()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseShipmentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Setup to generate Pick for a Item.
        Initialize();
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2) + 5;
        CreateAndReleaseSalesOrder(SalesHeader, Location.Code, Item."No.", Quantity);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Exercise: Generate the Picking List. Value used is important for test.
        Commit();
        WarehouseShipmentHeader.SetRange("No.", WarehouseShipmentNo);
        REPORT.Run(REPORT::"Whse. Shipment Status", true, false, WarehouseShipmentHeader);

        // Verify: Source No, Item No and Location shown in Warehouse Shipment Status Report is equal to the Sales Order.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('ItemNo_WhseShipmentLine', Item."No.", 'SourceNo_WhseShipmentLine', SalesHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_WhseShipmentLine', Location.Code);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipment()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        "Count": Integer;
    begin
        // Setup : Create Customer, Item, Multiple Sales Order and Post Shipment.
        Initialize();
        CreateCustomer(Customer);
        CreateItem(Item);
        Count := LibraryRandom.RandInt(10);
        CreateAndPostSalesOrder(Customer."No.", Item."No.", Count, LibraryRandom.RandDec(10, 2));

        // Exercise : Run Combine Sales Shipments With Option Post Invoice FALSE.
        RunCombineShipments(Customer."No.", false, false, false, false);

        // Verify : Check That Sales Invoice Created after Run Batch Report with Option Post Sales FALSE.
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        Assert.AreEqual(Count, SalesLine.Count, ErrRecordMissing);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentPostInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        "Count": Integer;
    begin
        // Setup : Create Customer, Item, Multiple Sales Order and Post Shipment.
        Initialize();
        CreateCustomer(Customer);
        CreateItem(Item);
        Count := LibraryRandom.RandInt(10);
        CreateAndPostSalesOrder(Customer."No.", Item."No.", Count, LibraryRandom.RandDec(10, 2));
        // Exercise : Run Combine Sales Shipments With Option Post Invoice TRUE.
        RunCombineShipments(Customer."No.", false, true, false, false);

        // Verify : Check That Posted Sales Invoice Created after Run Batch Report with Option Post Invoice TRUE.
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        Assert.AreEqual(Count, SalesInvoiceLine.Count, ErrRecordMissing);
    end;

    [Test]
    [HandlerFunctions('WhsePhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePhysicalInventoryList()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Setup: Create and release Purchase Order. Create and Post Warehouse Receipt. Run Warehouse Calculate Inventory Report.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity);
        RunWhseCalculateInventoryReport(LocationWhite.Code, Item."No.");

        // Exercise: Run Warehouse Physical Inventory List report.
        Commit();
        WarehouseJournalLine.SetRange("Item No.", Item."No.");
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Whse. Phys. Inventory List", true, false, WarehouseJournalLine);

        // Verify: Verify Warehouse Physical Inventory List report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('ItemNo_WarehouseJournlLin', Item."No.", 'QtyCalculated_WhseJnlLine', Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,WhseRegisterQuantityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseRegisterQuantity()
    var
        WarehouseRegister: Record "Warehouse Register";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create and Register Warehouse Journal Line.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterWhseJnlLine(LocationWhite, Item."No.", Quantity);

        // Exercise: Run Warehouse Register Quantity report.
        Commit();
        WarehouseRegister.SetRange("From Entry No.", FindWarehouseEntryNo(Item."No."));
        REPORT.Run(REPORT::"Warehouse Register - Quantity", true, false, WarehouseRegister);

        // Verify: Verify Warehouse Register Quantity report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('ItemNo_WarehouseEntry', Item."No.", 'Quantity_WarehouseEntry', -Quantity);
    end;

    [Test]
    [HandlerFunctions('InventoryPostingTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPostingTest()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create and Post Item Journal. Run Calculate Inventory. Update Quantity Physical Inventory on Item Journal line.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", Quantity);
        RunCalculateInventory(Item."No.", false);
        UpdateQuantityPhysicalInventoryOnPhysicalInventoryJournal(Item."No.");

        // Exercise: Run Inventory Posting Test report.
        Commit();
        ItemJournalLine.SetRange("Item No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Posting - Test", true, false, ItemJournalLine);

        // Verify: Quantity and Invoiced Quantity on Inventory Posting Test report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('Item_Journal_Line__Item_No__', Item."No.", 'Item_Journal_Line_Quantity', Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderDetailReport()
    var
        Item: Record Item;
        Item2: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create two Items. Create two Sales Orders.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);
        CreateItem(Item2);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateSalesOrder(SalesHeader, '', Item."No.", Customer."No.", Quantity);
        CreateSalesOrder(SalesHeader2, '', Item2."No.", Customer."No.", Quantity);

        // Exercise.
        Commit();
        Customer.SetRange("No.", Customer."No.");
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Customer - Order Detail", true, false, Customer);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('No_SalesLine', Item."No.", 'Quantity_SalesLine', Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesHeaderNo', SalesHeader."No.");

        VerifyReportData('No_SalesLine', Item2."No.", 'Quantity_SalesLine', Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesHeaderNo', SalesHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('SalesReturnReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnReceiptReport()
    var
        Item: Record Item;
        Customer: Record Customer;
        ReturnReceiptHeader: Record "Return Receipt Header";
        Quantity: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Setup: Create and Post Sales Order. Create and Post Sales Return Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostSalesOrder(Customer."No.", Item."No.", 1, Quantity);  // Value 1 required for one Sales Order.
        PostedDocumentNo := CreateAndPostSalesReturnOrder(Customer."No.", Item."No.", Quantity, FindItemLedgerEntryNo(Item."No."));

        // Exercise.
        ReturnReceiptHeader.SetRange("No.", PostedDocumentNo);
        REPORT.Run(REPORT::"Sales - Return Receipt", true, false, ReturnReceiptHeader);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('No_ReturnReceiptLine', Item."No.", 'Qty_ReturnReceiptLine', Quantity);
    end;

    [Test]
    [HandlerFunctions('WorkOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WorkOrderReport()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesCommentLine: Record "Sales Comment Line";
        Quantity: Decimal;
    begin
        // Setup: Create Sales Order. Create and update Sales Comment Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateSalesOrder(SalesHeader, '', Item."No.", Customer."No.", Quantity);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", 0);  // Value 0 required for Document Line No.
        UpdateDateInSalesCommentLine(SalesCommentLine);

        // Exercise.
        Commit();
        SalesHeader.SetRange("No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Work Order", true, false, SalesHeader);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('No_SalesLine', Item."No.", 'Quantity_SalesLine', Quantity);
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists('Comment_SalesCommentLine', SalesCommentLine.Comment);
    end;

    [Test]
    [HandlerFunctions('InventoryAvailabilityPlanRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityPlanReport()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PeriodLength: DateFormula;
    begin
        // Setup: Create and refresh Planned Production Order.
        Initialize();
        CreateAndRefreshPlannedProductionOrder(ProductionOrder);
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');

        // Exercise.
        Commit();
        Item.SetRange("No.", ProductionOrder."Source No.");
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(PeriodLength);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Inventory - Availability Plan", true, false, Item);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('No_Item', ProductionOrder."Source No.", 'ScheduledReceipt', 0);
        // Regardless of the period length, last period always includes the prod. order
        // in the projected available balance.
        LibraryReportDataset.AssertCurrentRowValueEquals('ProjAvBalance8', ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('WarehouseBinListReportHandler')]
    [Scope('OnPrem')]
    procedure WarehouseBinListReport()
    var
        Item: Record Item;
        Bin: Record Bin;
        Quantity: Decimal;
    begin
        // Setup: Update Inventory using Warehouse Journal.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        FindPickBin(Bin, LocationWhite.Code);
        UpdateInventoryUsingWarehouseJournal(Bin, Item, Quantity);

        // Exercise.
        Bin.SetRange("Location Code", Bin."Location Code");
        Bin.SetRange(Code, Bin.Code);
        REPORT.Run(REPORT::"Warehouse Bin List", true, false, Bin);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('ItemNo_BinContent', Item."No.", 'Quantity_BinContent', Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('Code_Bin', Bin.Code);
        LibraryReportDataset.AssertCurrentRowValueEquals('BinTypeCode_Code', Bin."Bin Type Code");
    end;

    [Test]
    [HandlerFunctions('PickingListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PickingListWithSetBreakBulkAsTrue()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Bin: Record Bin;
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        Quantity: Decimal;
        WarehouseShipmentNo: Code[20];
    begin
        // Create and Register Pur away from Purchase Order. Create Pick from Warehouse Shipment.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemWithPurchaseUnitOfMesaure(ItemUnitOfMeasure);
        FindPickBin(Bin, LocationWhite.Code);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(
          PurchaseHeader, LocationWhite.Code, ItemUnitOfMeasure."Item No.", Quantity + LibraryRandom.RandDec(10, 2));  // Calculated value required for test.
        RegisterPutAway(LocationWhite.Code, PurchaseHeader."No.");
        CreateAndReleaseSalesOrder(SalesHeader, LocationWhite.Code, ItemUnitOfMeasure."Item No.", Quantity);
        CreateWhseShipmentAndPick(WarehouseShipmentNo, SalesHeader);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // Exercise.
        Commit();
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityLine."Activity Type");
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        ReportSelectionWarehouse.PrintWhseActivityHeader(WarehouseActivityHeader, ReportSelectionWarehouse.Usage::Pick, false);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('ItemNo_WhseActLine', WarehouseActivityLine."Item No.",
          'QtyBase_WhseActLine', WarehouseActivityLine."Qty. (Base)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,InventoryPutAwayListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayListWithBinCode()
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // Setup: Create Location with Bin. Create Bin Content. Create Inventory Put-away from Purchase Order.
        Initialize();
        CreateItem(Item);
        CreateLocation(Location, WarehouseEmployee, true);  // TRUE for Bin Mandatory.
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        CreateInventoryPutAwayFromPurchaseOrder(Location.Code, Item."No.");

        // Exercise.
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Inventory Put-away List", true, false, Item);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('No_Item', Item."No.", 'LocationCode_PurchLine', Location.Code);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;


    // Skip test for PriceListReport

    [Test]
    [HandlerFunctions('WhereUsedListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhereUsedListReport()
    var
        AssemblyItem: Record Item;
        ComponentItem: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create Assembly Item with Component.
        Initialize();
        Quantity := CreateAssemblyItemWithComponent(AssemblyItem, ComponentItem);

        // Exercise.
        ComponentItem.SetRange("No.", ComponentItem."No.");
        REPORT.Run(REPORT::"Where-Used List", true, false, ComponentItem);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('ParentItemNo_BOMComponent', AssemblyItem."No.", 'Quantityper_BOMComponent', Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PutAwayListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayListReportWithBinCode()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        BinCode: Code[20];
        PurchaseHeaderNo: Code[20];
    begin
        // Setup: Create Location with Bin Content and Inventory Put-away from Purchase.
        Initialize();
        CreateItem(Item);
        CreateLocation(Location, WarehouseEmployee, true);
        BinCode := CreateBinContent(Item, Location.Code);
        PurchaseHeaderNo := CreateInventoryPutAwayFromPurchaseOrder(Location.Code, Item."No.");

        // Exercise: Run the report Put-away List
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Put-away");
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Purchase Order");
        WarehouseActivityHeader.SetRange("Source No.", PurchaseHeaderNo);
        ReportSelectionWarehouse.PrintWhseActivityHeader(WarehouseActivityHeader, ReportSelectionWarehouse.Usage::"Put-away", false);

        // Verify: verify that Bin code is presented on report Put-away List
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData('SrcNo_WhseActivLine', PurchaseHeaderNo, 'BinCode_WhseActivLine', BinCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcInvtOnPhysInvtJnlWithExistingWhseEntry()
    var
        Item: Record Item;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Quantity: Decimal;
    begin
        // Setup: Create and register Warehouse Journal Line.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(50, 2);
        CreateAndRegisterWhseJnlLine2(
          LocationWhite, Item."No.", Quantity, WarehouseJournalBatch."Template Type"::"Physical Inventory");

        // Exercise: Run Calculate Inventory on Phys. Inventory Journal.
        RunCalculateInventory(Item."No.", true);

        // Verify: Verify Qty. (Calculated), Qty. (Phys. Inventory) and Quantity on Item Journal Line.
        VerifyPhysInvtJournalLine(Item."No.", 0, Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReplacingDescriptionOnlySalesLineBySalesLineWithItemTypeDoesNotPreventCombiningShipments()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDescription: Text[100];
        Quantity1: Decimal;
        Quantity2: Decimal;
    begin
        // [FEATURE] [Combine Shipments] [Description Sales Line]
        // [SCENARIO 363166] Replacing Description Only Sales Line (Type = 0) by Sales Line with Item type does not prevent Combining Shipment
        Quantity1 := LibraryRandom.RandDec(10, 2);
        Quantity2 := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Sales Order with two lines
        CreateItem(Item);
        CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Sales Line "L1", where "Type" = "Item", "No." = "X"
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity1);

        // [GIVEN] Sales Line "L2", where "Type" = " ", "No." = " ", Description = "D"
        CreateSalesLineDescriptionOnly(SalesHeader, SalesLine);
        SalesLineDescription := SalesLine.Description;

        // [GIVEN] Ship the Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Overwrite Sales Line "L2" with "Type" = "Item", "No." = "X"
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Find();
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", Item."No.");
        SalesLine.Validate(Quantity, Quantity2);
        SalesLine.Modify(true);

        // [GIVEN] Ship the Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Combine Shipment with "Post Invoices" and "Copy Text Lines" = YES
        RunCombineShipments(Customer."No.", false, true, false, true);

        // [THEN] Posted Sales Invoice contains 3 lines: "L1", "L2" and Description line
        VerifyPostedSalesInvoice(Item."No.", Quantity1, Quantity2, SalesLineDescription);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentsWithItemCharge()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        DummySalesInvoiceLine: Record "Sales Invoice Line";
        ItemCharge: Record "Item Charge";
    begin
        // [FEATURE] [Combine Shipments] [Item Charge]
        // [SCENARIO 378180] Shipment with Item Charge Line first should not prevent Combine Shipments
        Initialize();

        // [GIVEN] Sales Order with two lines: 1st - Item Charge, 2-nd - Item
        CreateCustomer(Customer);
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateSalesOrderWithItemCharge(SalesHeader, Customer."No.", ItemCharge."No.");

        // [GIVEN] Post Sales Order as Shipped
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Run Combine Shipment Report
        LibraryVariableStorage.Enqueue(CombineShipmentMsg);  // Enqueue for MessageHandler
        RunCombineShipments(Customer."No.", false, true, false, false);

        // [THEN] Sales Invoice is created with Item Charge Line
        DummySalesInvoiceLine.SetRange("No.", ItemCharge."No.");
        Assert.RecordIsNotEmpty(DummySalesInvoiceLine);
    end;

    [Test]
    [HandlerFunctions('WhseCalculateInventoryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseCalculateInventoryAssignsReasonCode()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Quantity: Decimal;
    begin
        // [SCENARIO 296916] Warehouse Journal Calculate Inventory report assigns Reason Code on the lines it generates
        Initialize();

        // [GIVEN] Warehouse setup
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);

        // [GIVEN] Item with quantity in location
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Location.Code, Item."No.", Quantity);

        // [GIVEN] Whse Physical Inventory Journal Batch with Reason Code = "X"
        FindWhseJnlTemplateAndBatch(WarehouseJournalBatch, Location.Code, WarehouseJournalBatch."Template Type"::"Physical Inventory");
        WarehouseJournalBatch."Reason Code" := LibraryUtility.GenerateGUID();
        WarehouseJournalBatch.Modify();

        // [WHEN] Calculate Inventory report (7390) is ran
        RunWhseCalculateInventoryReportWithBatchAndRequestPage(WarehouseJournalBatch, Location.Code);
        // UI Handled by WhseCalculateInventoryRequestPageHandler

        // [THEN] The Whse Journal Line has Reason Code = "X"
        FindAndVerifyWhseJnlLine(Location.Code, WarehouseJournalBatch."Reason Code", Quantity);

        // Clean-up
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentsDifferentSelltoBillto()
    var
        Customer: array[2] of Record Customer;
        Item: Record Item;
        "Count": array[2] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Combine Shipments]
        // [SCENARIO 312531] Combine Shipments creates invoice with correct "Sell-To Customer No." and "Bill-to Customer No." when they are not equal on the initial shipment
        Initialize();

        // [GIVEN] Customer "CU01"
        CreateCustomer(Customer[1]);

        // [GIVEN] Customer "CU02" with "Bill-to Customer No." = "CU01"
        CreateCustomer(Customer[2]);
        Customer[2].Validate("Bill-to Customer No.", Customer[1]."No.");
        Customer[2].Modify(true);

        // [GIVEN] Sales Orders Created for "CU01" and "CU02"
        LibraryInventory.CreateItem(Item);
        for i := 1 to ArrayLen(Customer) do begin
            Count[i] := LibraryRandom.RandInt(5);
            CreateAndPostSalesOrder(Customer[i]."No.", Item."No.", Count[i], LibraryRandom.RandDec(10, 2));
        end;

        // [WHEN] Run Combine Shipments for "Bill-to Customer No." = "CU01" without posting
        RunCombineShipmentsByBillToCustomer(Customer[1]."No.", false, false, false, false);

        // [THEN] Invoices created for "CU01" and "CU02" with "Bill-to Customer No." = "CU01"
        VerifySalesInvoice(Customer[1]."No.", Customer[1]."No.", Count[1]);
        VerifySalesInvoice(Customer[2]."No.", Customer[1]."No.", Count[2]);
    end;

    [Test]
    [HandlerFunctions('PutAwayListRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintInvtPutAwayHeaderWhseDocPrint()
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Put-away List]
        // [SCENARIO 312849] PrintInvtPutAwayHeader from codeunit Warehouse Document-Print prints report "Put-away List"
        Initialize();

        // [GIVEN] Inventory Put-away was created from Purchase Order
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Modify(true);
        CreateInventoryPutAwayFromPurchaseOrder(Location.Code, LibraryInventory.CreateItemNo());
        PurchaseHeader.SetRange("Location Code", Location.Code);
        PurchaseHeader.FindFirst();
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        Commit();

        // [WHEN] Call PrintInvtPutAwayHeader from codeunit Warehouse Document-Print
        WarehouseDocumentPrint.PrintInvtPutAwayHeader(WarehouseActivityHeader, false);

        // [THEN] Report "Put-away List" is printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_WhseActivHeader', WarehouseActivityLine."No.");
        LibraryReportDataset.SetRange('ItemNo1_WhseActivLine', WarehouseActivityLine."Item No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('SrcNo_WhseActivLine', PurchaseHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('QtyBase_WhseActivLine', WarehouseActivityLine."Qty. (Base)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RunningCombineShipmentsForSelectedOrders()
    var
        Customer: Record Customer;
        SalesHeader: array[2] of Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesOrder: TestPage "Sales Order";
        SalesShipmentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Combine Shipments]
        // [SCENARIO 335308] A user can select which sales orders will be included to a single invoice with Combine Shipments control on sales order page.
        Initialize();

        // [GIVEN] Customer with "Combine Shipments" = TRUE.
        CreateCustomer(Customer);

        // [GIVEN] Two sales orders "SO1", "SO2".
        // [GIVEN] Ship both sales orders.
        CreateSalesOrder(SalesHeader[1], '', LibraryInventory.CreateItemNo(), Customer."No.", LibraryRandom.RandInt(10));
        SalesShipmentNo[1] := LibrarySales.PostSalesDocument(SalesHeader[1], true, false);
        CreateSalesOrder(SalesHeader[2], '', LibraryInventory.CreateItemNo(), Customer."No.", LibraryRandom.RandInt(10));
        SalesShipmentNo[2] := LibrarySales.PostSalesDocument(SalesHeader[2], true, false);

        // [GIVEN] Open sales order page positioned on sales order "SO1".
        // [GIVEN] Uncheck "Combine Shipments".
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader[1]."No.");
        SalesOrder."Combine Shipments".SetValue(false);
        SalesOrder.Close();

        // [WHEN] Run "Combine Shipments" batch job for both shipped sales orders.
        SalesHeader[1].SetFilter("No.", '%1|%2', SalesHeader[1]."No.", SalesHeader[2]."No.");
        SalesShipmentHeader.SetFilter("No.", '%1|%2', SalesShipmentNo[1], SalesShipmentNo[2]);
        LibraryVariableStorage.Enqueue(CombineShipmentMsg);
        LibrarySales.CombineShipments(SalesHeader[1], SalesShipmentHeader, WorkDate(), WorkDate(), false, false, false, false);

        // [THEN] One sales invoice is created.
        SalesHeaderInvoice.SetRange("Document Type", SalesHeaderInvoice."Document Type"::Invoice);
        SalesHeaderInvoice.SetRange("Sell-to Customer No.", Customer."No.");
        Assert.RecordCount(SalesHeaderInvoice, 1);

        // [THEN] Only sales order "SO2" is included to the combined invoice.
        SalesHeader[2].Find();
        SalesHeader[2].CalcFields(Amount);
        SalesHeaderInvoice.FindFirst();
        SalesHeaderInvoice.CalcFields(Amount);
        SalesHeaderInvoice.TestField(Amount, SalesHeader[2].Amount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentsWithMixedSellToAndBillToCustomerCodes()
    var
        CustomerSell: Record Customer;
        CustomerBill: Record Customer;
        Item: Record Item;
    begin
        // [FEATURE] [Combine Shipments]
        // [SCENARIO 345197] Combine shipments for sales orders sorted in mixed order of sell-to and bill-to customer codes.
        Initialize();

        // [GIVEN] Customer "B".
        // [GIVEN] Customer "A" with bill-to customer "B".
        CreateCustomer(CustomerBill);
        CreateCustomer(CustomerSell);
        CustomerSell.Validate("Bill-to Customer No.", CustomerBill."No.");
        CustomerSell.Modify(true);

        // [GIVEN] 4 sales orders posted in the following order:
        // [GIVEN] 1st: Sell-to Customer "A", Bill-to Customer "B".
        // [GIVEN] 2nd: Sell-to Customer "B", Bill-to Customer "B".
        // [GIVEN] 3rd: Sell-to Customer "B", Bill-to Customer "B".
        // [GIVEN] 4th: Sell-to Customer "A", Bill-to Customer "B".
        LibraryInventory.CreateItem(Item);
        CreateAndPostSalesOrder(CustomerSell."No.", Item."No.", 1, LibraryRandom.RandInt(10));
        CreateAndPostSalesOrder(CustomerBill."No.", Item."No.", 1, LibraryRandom.RandInt(10));
        CreateAndPostSalesOrder(CustomerBill."No.", Item."No.", 1, LibraryRandom.RandInt(10));
        CreateAndPostSalesOrder(CustomerSell."No.", Item."No.", 1, LibraryRandom.RandInt(10));

        // [WHEN] Run Combine Shipments for customers "A" and "B".
        RunCombineShipments(StrSubstNo('%1|%2', CustomerSell."No.", CustomerBill."No."), false, false, false, false);

        // [THEN] Two sales invoices are generated, each for two shipment lines.
        VerifySalesInvoice(CustomerSell."No.", CustomerBill."No.", 2);
        VerifySalesInvoice(CustomerBill."No.", CustomerBill."No.", 2);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShptRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UsingReportSelectionForPrintingPickFromShipment()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibraryReportSelection: Codeunit "Library - Report Selection";
    begin
        // [FEATURE] [Report Selection] [Pick] [Warehouse Shipment]
        // [SCENARIO 346629] A report from Report Selection is used when you choose to print pick being created from warehouse shipment.
        Initialize();

        LibraryInventory.CreateItem(Item);
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);

        // [GIVEN] Post inventory to a location with directed put-away and pick.
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item."No.", LibraryRandom.RandIntInRange(50, 100), false);

        // [GIVEN] Create and release sales order.
        // [GIVEN] Create warehouse shipment from the sales order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create pick from the warehouse shipment with "Print Pick" = TRUE.
        BindSubscription(LibraryReportSelection);
        LibraryVariableStorage.Enqueue('Pick activity');
        CreateAndPrintWhsePickFromShipment(SalesHeader);

        // [THEN] The printing is maintained by "Warehouse Document-Print" codeunit that takes a report set up in Report Selection for Usage = Pick.
        Assert.AreEqual('HandleOnBeforePrintPickHeader', LibraryReportSelection.GetEventHandledName(), '');

        UnbindSubscription(LibraryReportSelection);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UsingReportSelectionForPrintingPickFromPickWorksheet()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        LibraryReportSelection: Codeunit "Library - Report Selection";
    begin
        // [FEATURE] [Report Selection] [Pick] [Pick Worksheet]
        // [SCENARIO 346629] A report from Report Selection is used when you choose to print pick being created from pick worksheet.
        Initialize();

        LibraryInventory.CreateItem(Item);
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);

        // [GIVEN] Post inventory to a location with directed put-away and pick.
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item."No.", LibraryRandom.RandIntInRange(50, 100), false);

        // [GIVEN] Create and release sales order.
        // [GIVEN] Create warehouse shipment from the sales order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Open pick worksheet and pull the warehouse shipment to generate a worksheet line.
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        CreateWhsePickWorksheetLine(WhseWorksheetLine, Location.Code);

        // [WHEN] Create pick from the pick worksheet with "Print Pick" = TRUE.
        BindSubscription(LibraryReportSelection);
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name,
          Location.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, true);

        // [THEN] The printing is maintained by "Warehouse Document-Print" codeunit that takes a report set up in Report Selection for Usage = Pick.
        Assert.AreEqual('HandleOnBeforePrintPickHeader', LibraryReportSelection.GetEventHandledName(), '');

        UnbindSubscription(LibraryReportSelection);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UsingReportSelectionForPrintingPickFromWhseSourceCreateDoc()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        Bin: Record Bin;
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
        LibraryReportSelection: Codeunit "Library - Report Selection";
    begin
        // [FEATURE] [Report Selection] [Pick]
        // [SCENARIO 358365] A report from Report Selection is used when you choose to print pick being created from warehouse internal pick.
        Initialize();

        LibraryInventory.CreateItem(Item);
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);

        // [GIVEN] Post inventory to bin "B2" at location with directed put-away and pick.
        Bin.Get(Location.Code, Location."Cross-Dock Bin Code");
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item."No.", LibraryRandom.RandIntInRange(50, 100), false);

        // [GIVEN] Create internal pick from bin "B2" to "B1".
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);
        LibraryWarehouse.CreateWhseInternalPickHeader(WhseInternalPickHeader, Location.Code);
        WhseInternalPickHeader.Validate("To Bin Code", Bin.Code);
        WhseInternalPickHeader.Modify(true);
        LibraryWarehouse.CreateWhseInternalPickLine(
          WhseInternalPickHeader, WhseInternalPickLine, Item."No.", LibraryRandom.RandInt(50));
        LibraryWarehouse.ReleaseWarehouseInternalPick(WhseInternalPickHeader);

        // [WHEN] Create pick from the internal pick with "Print document" = TRUE.
        BindSubscription(LibraryReportSelection);
        WhseSourceCreateDocument.SetWhseInternalPickLine(WhseInternalPickLine, '');
        WhseSourceCreateDocument.SetHideValidationDialog(true);
        WhseSourceCreateDocument.Initialize('', "Whse. Activity Sorting Method"::None, true, false, false);
        WhseSourceCreateDocument.UseRequestPage(false);
        WhseSourceCreateDocument.Run();

        // [THEN] The printing is maintained by "Warehouse Document-Print" codeunit that takes a report set up in Report Selection for Usage = Pick.
        Assert.AreEqual('HandleOnBeforePrintPickHeader', LibraryReportSelection.GetEventHandledName(), '');

        UnbindSubscription(LibraryReportSelection);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UsingReportSelectionForPrintingPutawayFromWhseSourceCreateDoc()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
        LibraryReportSelection: Codeunit "Library - Report Selection";
    begin
        // [FEATURE] [Report Selection] [Put-away]
        // [SCENARIO 358365] A report from Report Selection is used when you choose to print movement being created from movement worksheet.
        Initialize();

        LibraryInventory.CreateItem(Item);
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);

        // [GIVEN] Post inventory to bin "B2" at location with directed put-away and pick.
        Bin.Get(Location.Code, Location."Cross-Dock Bin Code");
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item."No.", LibraryRandom.RandIntInRange(50, 100), false);

        // [GIVEN] Create internal put-away from bin "B2" to "B1".
        LibraryWarehouse.CreateWhseInternalPutawayHdr(WhseInternalPutAwayHeader, Location.Code);
        WhseInternalPutAwayHeader.Validate("From Bin Code", Bin.Code);
        WhseInternalPutAwayHeader.Modify(true);
        LibraryWarehouse.CreateWhseInternalPutawayLine(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, Item."No.", LibraryRandom.RandInt(50));
        LibraryWarehouse.ReleaseWarehouseInternalPutAway(WhseInternalPutAwayHeader);

        // [WHEN] Create put-away from the internal put-away with "Print document" = TRUE.
        BindSubscription(LibraryReportSelection);
        WhseSourceCreateDocument.SetWhseInternalPutAway(WhseInternalPutAwayHeader);
        WhseSourceCreateDocument.SetHideValidationDialog(true);
        WhseSourceCreateDocument.Initialize('', "Whse. Activity Sorting Method"::None, true, false, false);
        WhseSourceCreateDocument.UseRequestPage(false);
        WhseSourceCreateDocument.Run();

        // [THEN] The printing is maintained by "Warehouse Document-Print" codeunit that takes a report set up in Report Selection for Usage = Put-away.
        Assert.AreEqual('HandleOnBeforePrintPutAwayHeader', LibraryReportSelection.GetEventHandledName(), '');

        UnbindSubscription(LibraryReportSelection);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UsingReportSelectionForPrintingMovementFromWhseSourceCreateDoc()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        BinFrom: Record Bin;
        BinTo: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        LibraryReportSelection: Codeunit "Library - Report Selection";
    begin
        // [FEATURE] [Report Selection] [Movement]
        // [SCENARIO 358365] A report from Report Selection is used when you choose to print put-away being created from warehouse internal put-away.
        Initialize();

        LibraryInventory.CreateItem(Item);
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);

        // [GIVEN] Post inventory to bin "B2" at location with directed put-away and pick.
        BinFrom.Get(Location.Code, Location."Cross-Dock Bin Code");
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(BinFrom, Item."No.", LibraryRandom.RandIntInRange(50, 100), false);

        // [GIVEN] Create movement worksheet line from bin "B2" to "B1".
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(BinTo, Location.Code, Zone.Code, 1);
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, BinFrom, BinTo, Item."No.", '', LibraryRandom.RandInt(50));

        // [WHEN] Create movement from movement worksheet with "Print document" = TRUE.
        BindSubscription(LibraryReportSelection);
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::None, true, false, false);

        // [THEN] The printing is maintained by "Warehouse Document-Print" codeunit that takes a report set up in Report Selection for Usage = Movement.
        Assert.AreEqual('HandleOnBeforePrintMovementHeader', LibraryReportSelection.GetEventHandledName(), '');

        UnbindSubscription(LibraryReportSelection);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintPickHeader()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Pick] [UT]
        // [SCENARIO 361099] Printing pick using "Warehouse Document-Print" codeunit shows request page of the report.

        asserterror WarehouseDocumentPrint.PrintPickHeader(WarehouseActivityHeader);

        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::Pick);
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintPutAwayHeader()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Put-away] [UT]
        // [SCENARIO 361099] Printing put-away using "Warehouse Document-Print" codeunit shows request page of the report.

        asserterror WarehouseDocumentPrint.PrintPutAwayHeader(WarehouseActivityHeader);

        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::"Put-away");
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintMovementHeader()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Movement] [UT]
        // [SCENARIO 361099] Printing movement using "Warehouse Document-Print" codeunit shows request page of the report.

        asserterror WarehouseDocumentPrint.PrintMovementHeader(WarehouseActivityHeader);

        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::Movement);
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintInvtPickHeader()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Inventory Pick] [UT]
        // [SCENARIO 361099] Printing inventory pick using "Warehouse Document-Print" codeunit shows request page of the report.

        asserterror WarehouseDocumentPrint.PrintInvtPickHeader(WarehouseActivityHeader, false);

        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::"Invt. Pick");
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintInvtPutAwayHeader()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Inventory Put-away] [UT]
        // [SCENARIO 361099] Printing inventory put-away using "Warehouse Document-Print" codeunit shows request page of the report.

        asserterror WarehouseDocumentPrint.PrintInvtPutAwayHeader(WarehouseActivityHeader, false);

        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::"Invt. Put-away");
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintInvtMovementHeader()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Inventory Movement] [UT]
        // [SCENARIO 361099] Printing inventory movement using "Warehouse Document-Print" codeunit shows request page of the report.

        asserterror WarehouseDocumentPrint.PrintInvtMovementHeader(WarehouseActivityHeader, false);

        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::"Invt. Movement");
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintRcptHeader()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Warehouse Receipt] [UT]
        // [SCENARIO 361099] Printing warehouse receipt using "Warehouse Document-Print" codeunit shows request page of the report.

        asserterror WarehouseDocumentPrint.PrintRcptHeader(WarehouseReceiptHeader);

        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::Receipt);
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintPostedRcptHeader()
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Warehouse Receipt] [UT]
        // [SCENARIO 361099] Printing posted warehouse receipt using "Warehouse Document-Print" codeunit shows request page of the report.

        asserterror WarehouseDocumentPrint.PrintPostedRcptHeader(PostedWhseReceiptHeader);

        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::"Posted Receipt");
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintShptHeader()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Warehouse Shipment] [UT]
        // [SCENARIO 361099] Printing warehouse shipment using "Warehouse Document-Print" codeunit shows request page of the report.

        asserterror WarehouseDocumentPrint.PrintShptHeader(WarehouseShipmentHeader);

        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::Shipment);
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintPostedShptHeader()
    var
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
    begin
        // [FEATURE] [Warehouse Shipment] [UT]
        // [SCENARIO 361099] Printing posted warehouse shipment using "Warehouse Document-Print" codeunit shows request page of the report.

        asserterror WarehouseDocumentPrint.PrintPostedShptHeader(PostedWhseShipmentHeader);

        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::"Posted Shipment");
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [HandlerFunctions('SalesShipmentXmlRequestPageHandler')]
    procedure PrintSeveralWhseShipmentsAtSinglePostAndPrintRun()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        FileManagement: Codeunit "File Management";
        SCMWarehouseReports: Codeunit "SCM Warehouse Reports";
        ReportSelectionUsage: Enum "Report Selection Usage";
        ItemNo: array[3] of Code[20];
        SourceNo: array[3] of Code[20];
        SourceNoFilter: Code[100];
        NoOfSales: Integer;
        Index: Integer;
        FilePath: Text;
    begin
        // [FEATURE] [Warehouse Shipment] [Pick] [Print]
        // [SCENARIO] Stan can post and print Warehouse Shipment with referenced multiple sales shipment documents. All referenced documents printed with single report output
        Initialize();
        SetupReportSelections(ReportSelectionUsage::"S.Shipment", Report::"Sales Shipment NA");
        NoOfSales := ArrayLen(ItemNo);

        // [GIVEN] Three items.
        for Index := 1 to NoOfSales do
            ItemNo[Index] := LibraryInventory.CreateItemNo();

        // [GIVEN] Location set up for directed put-away and pick.
        LibraryWarehouse.CreateFullWMSLocation(Location, NoOfSales);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);

        // [GIVEN] Post each item to separate bin.
        for Index := 1 to NoOfSales do begin
            LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, Index);
            LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, ItemNo[Index], LibraryRandom.RandInt(10), false);
        end;

        // [GIVEN] Three sales orders, one per each item.
        for Index := 1 to NoOfSales do begin
            CreateSalesOrder(SalesHeader, Location.Code, ItemNo[Index], '', 1);
            LibrarySales.ReleaseSalesDocument(SalesHeader);
            SourceNoFilter := SourceNoFilter + SalesHeader."No." + '|';
        end;
        SourceNoFilter := DelStr(SourceNoFilter, StrLen(SourceNoFilter));

        // [GIVEN] Create new warehouse shipment and pull all three orders to it.
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", Location.Code);
        WarehouseShipmentHeader.Modify(true);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Validate("Sales Orders", true);
        WarehouseSourceFilter.Validate("Source No. Filter", SourceNoFilter);
        WarehouseSourceFilter.Modify(true);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, Location.Code);

        // [GIVEN] Create and register pick for the warehouse shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        LibraryWarehouse.FindWhseActivityBySourceDoc(
            WarehouseActivityHeader, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        FilePath := FileManagement.ServerTempFileName('xml');
        LibraryVariableStorage.Enqueue(FilePath);

        // [WHEN] Set printing option and post warehouse shipment.
        WhsePostShipment.SetPrint(true);
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindSet();
        Index := 0;
        repeat
            Index += 1;
            SourceNo[Index] := WarehouseShipmentLine."Source No.";
        until WarehouseShipmentLine.Next() = 0;
        Assert.AreEqual(NoOfSales, Index, '');
        WarehouseShipmentLine.FindFirst();
        BindSubscription(SCMWarehouseReports); // force to Request Page to be show
        WhsePostShipment.Run(WarehouseShipmentLine);

        // [THEN] Report.Run has been called once. Three shipment documents printed within single report ouput.
        LibraryReportDataset.LoadDataSetFile();
        for Index := 1 to NoOfSales do begin
            LibraryReportDataset.AssertElementWithValueExists('OrderNo_SalesShptHeader', SourceNo[Index]);
            LibraryReportDataset.GetNextRow();
        end;
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintInvtPickViaCreateInvtDocsReport()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        CreateInvtPutAwayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
    begin
        // [FEATURE] [Inventory Pick]
        // [SCENARIO 370791] Printing inventory pick using "Create Invt Put-away/Pick/Mvmt" shows request page of the report.
        Initialize();

        // [GIVEN] Location "L" with required pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Post inventory on location "L".
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, '', LibraryRandom.RandIntInRange(50, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create and release sales order on location "L".
        CreateSalesOrder(SalesHeader, Location.Code, Item."No.", '', LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create and print inventory pick from the sales order.
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Sales Order");
        WarehouseRequest.SetRange("Source No.", SalesHeader."No.");
        CreateInvtPutAwayPickMvmt.SetTableView(WarehouseRequest);
        CreateInvtPutAwayPickMvmt.InitializeRequest(false, true, false, true, false);
        CreateInvtPutAwayPickMvmt.UseRequestPage(false);
        asserterror CreateInvtPutAwayPickMvmt.RunModal();

        // [THEN] Request page of the inventory pick report is shown.
        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::"Invt. Pick");
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintInvtPutAwayViaCreateInvtDocsReport()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseRequest: Record "Warehouse Request";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        CreateInvtPutAwayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
    begin
        // [FEATURE] [Inventory Put-away] [UT]
        // [SCENARIO 370791] Printing inventory put-away using "Create Invt Put-away/Pick/Mvmt" shows request page of the report.
        Initialize();

        // [GIVEN] Location "L" with required put-away.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and release purchase order on location "L".
        CreatePurchaseOrder(PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandInt(10), 0);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Create and print inventory put-away from the purchase order.
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        WarehouseRequest.SetRange("Source No.", PurchaseHeader."No.");
        CreateInvtPutAwayPickMvmt.SetTableView(WarehouseRequest);
        CreateInvtPutAwayPickMvmt.InitializeRequest(true, false, false, true, false);
        CreateInvtPutAwayPickMvmt.UseRequestPage(false);
        asserterror CreateInvtPutAwayPickMvmt.RunModal();

        // [THEN] Request page of the inventory put-away report is shown.
        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::"Invt. Put-away");
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowRequestPageOnPrintInvtMvmtViaCreateInvtDocsReport()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        CreateInvtPutAwayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
    begin
        // [FEATURE] [Inventory Movement] [UT]
        // [SCENARIO 370791] Printing inventory movement using "Create Invt Put-away/Pick/Mvmt" shows request page of the report.
        Initialize();

        // [GIVEN] Location "L" with required pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Post inventory on location "L".
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, '', LibraryRandom.RandIntInRange(50, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create and release sales order on location "L".
        CreateSalesOrder(SalesHeader, Location.Code, Item."No.", '', LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create and print inventory movement from the sales order.
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Sales Order");
        WarehouseRequest.SetRange("Source No.", SalesHeader."No.");
        CreateInvtPutAwayPickMvmt.SetTableView(WarehouseRequest);
        CreateInvtPutAwayPickMvmt.InitializeRequest(false, false, true, true, false);
        CreateInvtPutAwayPickMvmt.UseRequestPage(false);
        asserterror CreateInvtPutAwayPickMvmt.RunModal();

        // [THEN] Request page of the inventory movement report is shown.
        Assert.ExpectedErrorCode('MissingUIHandler');

        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::"Invt. Movement");
        ReportSelectionWarehouse.FindFirst();
        Assert.ExpectedError(StrSubstNo(RequestPageMissingErr, ReportSelectionWarehouse."Report ID"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure CombineShipmentsDifferentSelltoBilltoOnOrder()
    var
        Customer: array[2] of Record Customer;
        Item: Record Item;
        "Count": Integer;
    begin
        // [FEATURE] [Combine Shipments]
        // [SCENARIO 391232] Combine Shipments creates invoice with correct "Sell-To Customer No." and "Bill-to Customer No." when they are not equal on the initial Sales Order
        Initialize();

        // [GIVEN] Customers "CU01", "CU02"
        CreateCustomer(Customer[1]);
        CreateCustomer(Customer[2]);

        // [GIVEN] Sales Orders Created for "CU01" with "Bill-to Customer" = "CU02"
        Count := LibraryRandom.RandIntInRange(2, 5);
        CreateAndPostSalesOrderWithDiffBillToCustomer(Customer[1]."No.", Customer[2]."No.", Item."No.", Count, LibraryRandom.RandDec(10, 2));

        // [WHEN] Run Combine Shipments for "Sell-to Customer No." = "CU01" without posting
        LibraryVariableStorage.Enqueue(ConfirmChangeQst);
        RunCombineShipments(Customer[1]."No.", false, false, false, false);

        // [THEN] Confirmation dialog is shown "Do you want to change Bill-to Customer?"
        // [THEN] Invoice created for "CU01" with "Bill-to Customer No." = "CU02"
        VerifySalesInvoice(Customer[1]."No.", Customer[2]."No.", Count);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhsePostedShipmentRequestPageHandler')]
    procedure MultipleReportsInReportSelectionWarehouse()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
        NoOfRuns: Integer;
        i: Integer;
    begin
        // [FEATURE] [Warehouse Shipment] [Print]
        // [SCENARIO 404205] Printing several reports selected in "Report Selection - Warehouse".
        Initialize();
        NoOfRuns := 2;

        // [GIVEN] Two reports in Report Selection Warehouse for posted shipment.
        ReportSelectionWarehouse.SetRange(Usage, ReportSelectionWarehouse.Usage::"Posted Shipment");
        ReportSelectionWarehouse.DeleteAll();
        for i := 1 to NoOfRuns do begin
            ReportSelectionWarehouse.Init();
            ReportSelectionWarehouse.Validate(Usage, ReportSelectionWarehouse.Usage::"Posted Shipment");
            ReportSelectionWarehouse.Validate(Sequence, Format(i));
            ReportSelectionWarehouse.Validate("Report ID", REPORT::"Whse. - Posted Shipment");
            ReportSelectionWarehouse.Insert(true);
        end;

        // [GIVEN] Location with required shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Sales order, release.
        CreateSalesOrder(SalesHeader, Location.Code, LibraryInventory.CreateItemNo(), '', LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create warehouse shipment.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Post warehouse shipment.
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", WarehouseShipmentHeader."No.");
        PostedWhseShipmentHeader.FindFirst();

        // [WHEN] Print posted warehouse shipment.
        LibraryVariableStorage.Enqueue(0);
        WarehouseDocumentPrint.PrintPostedShptHeader(PostedWhseShipmentHeader);

        // [THEN] Two reports are printed.
        Assert.AreEqual(NoOfRuns, LibraryVariableStorage.DequeueInteger(), StrSubstNo('Report must be run %1 times', NoOfRuns));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PutAwayListReportHandler')]
    [Scope('OnPrem')]
    procedure PostAndPrintPutAwayListWithReportSelectionWhse()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        WhseRcptLine: Record "Warehouse Receipt Line";
        ReportExecuted: Boolean;
    begin
        // [SCENARIO 432367] To check if system using report selection warehouse to print put away when using post and print Put-away option

        // [GIVEN] Create a new Purchase order with a warehouse location
        Initialize();
        CreateWarehouseSetup(Location, WarehouseEmployee, false);
        CreateItem(Item);
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WhseRcptLine, Location.Code, Item."No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Post warehouse receipt with post and print put-away option
        Commit();
        LibraryVariableStorage.Enqueue(WhsePostAndPrintMsg);  // Enqueue for MessageHandler.
        LibraryVariableStorage.Enqueue(NumberOfDocPrintedMsg);
        PostAndPrintRcpt(WhseRcptLine);
        ReportExecuted := true;

        // [THEN] Report should be executed based on report configured on report selection warehouse.
        Assert.AreEqual(ReportExecuted, LibraryVariableStorage.DequeueBoolean(), ReportExecutedErr);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PutAwayListReportHandler')]
    [Scope('OnPrem')]
    procedure PostAndPrintWareHouseReceiptWithPostDimAnalysisRec()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        WhseRcptLine: Record "Warehouse Receipt Line";
        AnalysisView: Record "Analysis View";
        ReportExecuted: Boolean;
    begin
        // [SCENARIO 462800] Analysis View Update on Posting setup at true cause "Report.RunModal is allowed in write..." error during Warehouse Receipt Post and Print
        Initialize();

        // [GIVEN] Create Analysis View with Dimensions.
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account");

        // [GIVEn] Create WarehouseSetup
        CreateWarehouseSetup(Location, WarehouseEmployee, false);

        // [GIVEN] Create Item.
        CreateItem(Item);

        // [GIVEN] Create a Warehouse receipt by new Purchase order with a warehouse location
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WhseRcptLine, Location.Code, Item."No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Post warehouse receipt with post and print option
        LibraryVariableStorage.Enqueue(WhsePostAndPrintMsg);
        LibraryVariableStorage.Enqueue(NumberOfDocPrintedMsg);
        PostAndPrintRcpt(WhseRcptLine);
        ReportExecuted := true;

        // [THEN] Report should be executed based on report configured on report selection warehouse.
        Assert.AreEqual(ReportExecuted, LibraryVariableStorage.DequeueBoolean(), ReportExecutedErr);

        // Tear down.
        WarehouseEmployee.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,WhseAdjustmentBinRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhseAdjustmentBinReportShouldPrintAllItemsOfLocationWhenLocationFilterIsApplied()
    var
        Item: Record Item;
        Item2: Record Item;
        Zone: Record Zone;
        Zone2: Record Zone;
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        BinType: Record "Bin Type";
        BinType2: Record "Bin Type";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WhseJournalTemplate: Record "Warehouse Journal Template";
        WhseJournalBatch: Record "Warehouse Journal Batch";
        WhseJournalLine: Record "Warehouse Journal Line";
        WhseJournalLine2: Record "Warehouse Journal Line";
        WhseEntry: Record "Warehouse Entry";
    begin
        // [SCENARIO 488628] Warehouse adjustment bin report 7320 not printing results
        Initialize();

        // [GIVEN] Create Item.
        CreateItem(Item);

        // [GIVEN] Create Item 2.
        CreateItem(Item2);

        // [GIVEN] Create Full Warehouse Setup.
        CreateFullWarehouseSetup(Location, WarehouseEmployee, false);

        // [GIVEN] Create Location with Warehouse Employee Setup.
        CreateLocationWithWarehouseEmployeeSetup(Location, WarehouseEmployee);

        // [GIVEN] Find Pick & Put Away Bin Type.
        FindBinType(BinType, false, false, true, true);

        // [GIVEN] Find No Type Bin Type 2.
        FindBinType(BinType2, false, false, false, false);

        // [GIVEN] Create Zone.
        LibraryWarehouse.CreateZone(
            Zone,
            Zone.Code,
            Location.Code,
            BinType.Code,
            '',
            '',
            LibraryRandom.RandInt(0),
            false);

        // [GIVEN] Create Zone 2.
        LibraryWarehouse.CreateZone(
            Zone2,
            Zone2.Code,
            Location.Code,
            BinType2.Code,
            '',
            '',
            0,
            false);

        // [GIVEN] Create Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, Zone.Code, BinType.Code);

        // [GIVEN] Create Bin 2.
        LibraryWarehouse.CreateBin(Bin2, Location.Code, Bin2.Code, Zone.Code, BinType.Code);

        // [GIVEN] Create Bin 3.
        LibraryWarehouse.CreateBin(Bin3, Location.Code, Bin3.Code, Zone2.Code, BinType2.Code);

        // [GIVEN] Validate Assembly, Production & Adjustment Bin Codes in Location.
        ValidateAssemblyProdAndAdjmtBinCodesInLocation(Location, Bin.Code, Bin2.Code, Bin3.Code);

        // [GIVEN] Create Warehouse Journal Setup.
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WhseJournalTemplate, WhseJournalBatch);

        // [GIVEN] Create Warehouse Item Journal Line for Item.
        LibraryWarehouse.CreateWhseJournalLine(
            WhseJournalLine,
            WhseJournalBatch."Journal Template Name",
            WhseJournalBatch.Name,
            Bin2."Location Code",
            Bin2."Zone Code",
            Bin2.Code,
            WhseJournalLine."Entry Type"::"Positive Adjmt.",
            Item."No.",
            LibraryRandom.RandInt(2));

        // [GIVEN] Create Warehouse Item Journal Line 2 for Item 2.
        LibraryWarehouse.CreateWhseJournalLine(
            WhseJournalLine2,
            WhseJournalBatch."Journal Template Name",
            WhseJournalBatch.Name,
            Bin3."Location Code",
            Bin3."Zone Code",
            Bin3.Code,
            WhseJournalLine2."Entry Type"::"Positive Adjmt.",
            Item2."No.",
            LibraryRandom.RandInt(4));

        // [GIVEN] Register Warehouse Journal Lines.
        LibraryVariableStorage.Enqueue(WantToRegisterConfirm);
        LibraryVariableStorage.Enqueue(JournalLineRegistered);
        LibraryWarehouse.RegisterWhseJournalLine(WhseJournalTemplate.Name, WhseJournalBatch.Name, Location.Code, false);

        // [GIVEN] Run Warehouse Adjustment Bin Report with Location Code Filter.
        WhseEntry.SetRange("Location Code", Location.Code);
        REPORT.Run(REPORT::"Whse. Adjustment Bin", true, false, WhseEntry);

        // [GIVEN] Load Warehouse Adjustment Bin Report.
        LibraryReportDataset.LoadDataSetFile();

        // [WHEN] Find First Row of Warehouse Adjustment Bin Report.
        LibraryReportDataset.GetNextRow();

        // [VERIFY] Verify First Row has Item.
        LibraryReportDataset.AssertCurrentRowValueEquals(WhseEntryItemNoElementName, Item."No.");

        // [WHEN] Find Last Row of Warehouse Adjustment Bin Report.
        LibraryReportDataset.GetLastRow();

        // [VERIFY] Verify Last Row has Item 2.
        LibraryReportDataset.AssertCurrentRowValueEquals(WhseEntryItemNoElementName, Item2."No.");
    end;

    [Test]
    procedure CreateWarehouseShipmentUsingAmpersandInLocation()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [SCENARIO 502849] Error during direct creation of a warehouse receipt and warehouse shipment while using Ampersand (&) in the Location Code.
        Initialize();

        // [GIVEN] Warehouse setup ,Location and Warehouse Employee Created.
        CreateWarehouseSetup(Location, WarehouseEmployee, false);

        // [GIVEN] Location Code is renamed using & symbol.
        Location.Rename(LibraryRandom.RandText(2) + '&' + LibraryRandom.RandText(2));

        // [GIVEN] Create Item for Sales Order.
        CreateItem(Item);

        // [GIVEN] Create  Sales Order using Location and Item.
        CreateAndReleaseSalesOrder(SalesHeader, Location.Code, Item."No.", LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Warehouse Shipment from sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] Verify Warehouse shipment is created with Location.
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.SetRange("Item No.", Item."No.");
        WarehouseShipmentLine.FindFirst();
        Assert.AreEqual(
            WarehouseShipmentLine."Location Code",
            Location.Code,
            StrSubstNo(
                LocationErr,
                WarehouseShipmentLine."Location Code",
                Location.Code,
                WarehouseShipmentLine.TableCaption()));
    end;

    [Test]
    procedure CreateWarehouseReceiptUsingAmpersandInLocation()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // [SCENARIO 502849] Error during direct creation of a warehouse receipt and warehouse shipment while using Ampersand (&) in the Location Code.
        Initialize();

        // [GIVEN] Warehouse setup ,Location and Warehouse Employee Created.
        CreateWarehouseSetup(Location, WarehouseEmployee, false);

        // [GIVEN] Location Code is renamed using & symbol.
        Location.Rename(LibraryRandom.RandText(2) + '&' + LibraryRandom.RandText(2));

        // [GIVEN] Create Item for Purchase Order.
        CreateItem(Item);

        // [GIVEN] Create Vendor and Purchase Order using Vendor.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Create Purchase Line with Item.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(10));

        // [GIVEN] Validate Direct Unit Cost and Location in Purchase Line.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(50, 2));
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate(PurchaseLine."Qty. to Receive", PurchaseLine.Quantity);
        PurchaseLine.Modify(true);

        // [GIVEN] Validate Venodr Invocie No. and Release the Purchase Order.
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Recipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] Verify Warehouse Recipt is created with Location.
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseReceiptLine.SetRange("Item No.", Item."No.");
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual(
            WarehouseReceiptLine."Location Code",
            Location.Code,
            StrSubstNo(
                LocationErr,
                WarehouseReceiptLine."Location Code",
                Location.Code,
                WarehouseReceiptLine.TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse Reports");
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse Reports");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        CreateLocationSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse Reports");
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite, WarehouseEmployee, true);
    end;

    local procedure CreateWarehouseSetup(var Location: Record Location; var WarehouseEmployee: Record "Warehouse Employee"; UsePutawayWorksheet: Boolean)
    begin
        CreateLocation(Location, WarehouseEmployee, false);
        Location.Validate("Use Put-away Worksheet", UsePutawayWorksheet);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location; var WarehouseEmployee: Record "Warehouse Employee"; IsDefault: Boolean)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, IsDefault);
    end;

    local procedure CreateAssemblyItemWithComponent(var AssemblyItem: Record Item; var ComponentItem: Record Item) Quantity: Decimal
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryAssembly.CreateItem(AssemblyItem, AssemblyItem."Costing Method"::Standard,
          AssemblyItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(ComponentItem, ComponentItem."Costing Method"::FIFO,
          ComponentItem."Replenishment System"::Purchase, '', '');
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryAssembly.CreateAssemblyListComponent(BOMComponent.Type::Item, ComponentItem."No.",
          AssemblyItem."No.", '', BOMComponent."Resource Usage Type", Quantity, false);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(100, 2), Item."Reordering Policy",
          Item."Flushing Method", '', '');
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateItemWithPurchaseUnitOfMesaure(var ItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandInt(10) + 1);
    end;

    local procedure CreateBinContent(var Item: Record Item; LocationCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Fixed, true);
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        exit(Bin.Code);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Combine Shipments", true);
        Customer.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; CustomerNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        // Random values used are not important for test.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Qty. to Ship", Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineDescriptionOnly(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        RecRef: RecordRef;
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        RecRef.GetTable(SalesLine);
        SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
        SalesLine.Type := SalesLine.Type::" ";
        SalesLine.Description := LibraryUtility.GenerateGUID();
        SalesLine.Insert(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Order with One Item Line.Random values used are not important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."),
            DATABASE::"Purchase Header"));
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Qty. to Receive", Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure RegisterPutAway(LocationCode: Code[10]; SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure CreateWhseShipmentAndPick(var WarehouseShipmentNo: Code[20]; SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Create Warehouse Shipment. Run Create Pick.
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(WarehouseShipmentNo);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreateWhsePickWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhsePickRequest.SetRange(Status, WhsePickRequest.Status::Released);
        WhsePickRequest.SetRange("Completely Picked", false);
        WhsePickRequest.SetRange("Location Code", LocationCode);
        LibraryWarehouse.GetOutboundSourceDocuments(WhsePickRequest, WhseWorksheetName, LocationCode);
        FindWhseWorkSheetLine(WhseWorksheetLine, WhseWorksheetName);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Get(ItemJournalBatch."Journal Template Name");
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseReceiptNo: Code[20];
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        WarehouseReceiptNo := FindWarehouseReceiptNo();
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptNo);
    end;

    local procedure CreateAndRefreshPlannedProductionOrder(var ProductionOrder: Record "Production Order")
    var
        Item: Record Item;
    begin
        CreateItemWithReplenishmentSystemAsProdOrder(Item);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // True for CalcLines, CalcRoutings and CalcComponents.
    end;

    local procedure CreateInventoryPutAwayFromPurchaseOrder(LocationCode: Code[10]; ItemNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        WhseRequest: Record "Warehouse Request";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, LibraryRandom.RandDec(10, 2));
        LibraryVariableStorage.Enqueue(InvtPutAwayCreated);  // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WhseRequest."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);  // TRUE for PutAway.
        LibraryVariableStorage.AssertEmpty();
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateItemWithReplenishmentSystemAsProdOrder(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, LocationCode, ItemNo, '', Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndPostSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]; "Count": Integer; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        I: Integer;
    begin
        for I := 1 to Count do begin
            Clear(SalesHeader);
            CreateSalesOrder(SalesHeader, '', ItemNo, CustomerNo, Quantity);
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;
    end;

    local procedure CreateAndPostSalesOrderWithDiffBillToCustomer(SellToCustomerNo: Code[20]; BillToCustomerNo: Code[20]; ItemNo: Code[20]; "Count": Integer; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        I: Integer;
    begin
        for I := 1 to Count do begin
            Clear(SalesHeader);
            CreateSalesOrder(SalesHeader, '', ItemNo, SellToCustomerNo, Quantity);
            LibraryVariableStorage.Enqueue(ConfirmChangeQst);
            LibraryVariableStorage.Enqueue(RecreateSalesLinesMsg);
            SalesHeader.Validate("Bill-to Customer No.", BillToCustomerNo);
            SalesHeader.Modify(true);
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;
    end;

    local procedure CreateSalesOrderWithItemCharge(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemChargeNo: Code[20])
    var
        SalesLineItemCharge: Record "Sales Line";
        SalesLineItem: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLineItemCharge, SalesHeader, SalesLineItemCharge.Type::"Charge (Item)", ItemChargeNo, LibraryRandom.RandInt(10));
        SalesLineItemCharge.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLineItemCharge.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLineItem, SalesHeader, SalesLineItem.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineItemCharge, SalesLineItem."Document Type",
          SalesLineItem."Document No.", SalesLineItem."Line No.", SalesLineItem."No.");
    end;

    local procedure CreateAndPostSalesReturnOrder(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; ApplicationFromItemEntryNo: Integer) PostedDocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Appl.-from Item Entry", ApplicationFromItemEntryNo);
        SalesLine.Modify(true);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateLocation(var Location: Record Location; var WarehouseEmployee: Record "Warehouse Employee"; BinMandatory: Boolean)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, true, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateMovementWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        Zone: Record Zone;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
    begin
        WhseWorksheetLine.DeleteAll(true);

        // Select Bin Content with Quantity.
        FindBinContent(BinContent, LocationCode, ItemNo);
        Zone.Get(LocationCode, SHIP);
        FindFirstBinRankingForZone(Bin, Zone.Code, LocationCode);

        // Run Whse. Get Bin Content to populate the Whse. Worksheet Line.
        // Assigning Worksheet Template Name, Name and Location Code to Whse. Worksheet Line for the report.
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhseWorksheetLine."Worksheet Template Name" := WhseWorksheetName."Worksheet Template Name";
        WhseWorksheetLine.Name := WhseWorksheetName.Name;
        WhseWorksheetLine."Location Code" := LocationCode;
        WhseInternalPutAwayHeader.Init();
        LibraryWarehouse.WhseGetBinContent(
            BinContent, WhseWorksheetLine, WhseInternalPutAwayHeader, "Warehouse Destination Type 2"::MovementWorksheet);

        // Find and Update the created Whse. Worksheet Line.
        FindWhseWorkSheetLine(WhseWorksheetLine, WhseWorksheetName);
        WhseWorksheetLine.Validate("To Bin Code", Bin.Code);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure CreateAndPrintWhsePickFromShipment(SalesHeader: Record "Sales Header")
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange(
          "No.",
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        WarehouseShipmentLine.FindFirst();
        WhseShptLine.Copy(WarehouseShipmentLine);
        WhseShptHeader.Get(WhseShptLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WhseShptHeader);
        WarehouseShipmentLine.CreatePickDoc(WhseShptLine, WhseShptHeader);
    end;

    local procedure FindItemLedgerEntryNo(ItemNo: Code[20]) EntryNo: Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        EntryNo := ItemLedgerEntry."Entry No.";
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentNo(): Code[20]
    var
        WarehouseSetup: Record "Warehouse Setup";
        NoSeries: Codeunit "No. Series";
    begin
        WarehouseSetup.Get();
        exit(NoSeries.PeekNextNo(WarehouseSetup."Whse. Ship Nos."));
    end;

    local procedure FindWarehouseEntryNo(ItemNo: Code[20]) FromEntryNo: Integer
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.FindFirst();
        FromEntryNo := WarehouseEntry."Entry No.";
    end;

    local procedure FindWarehouseReceiptNo(): Code[20]
    var
        WarehouseSetup: Record "Warehouse Setup";
        NoSeries: Codeunit "No. Series";
    begin
        WarehouseSetup.Get();
        exit(NoSeries.PeekNextNo(WarehouseSetup."Whse. Receipt Nos."));
    end;

    local procedure FindWhseWorkSheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name")
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure FindLastRankingBin(var Bin: Record Bin; LocationCode: Code[10]; ZoneCode: Code[10])
    begin
        Bin.SetCurrentKey("Location Code", "Warehouse Class Code", "Bin Ranking");
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", ZoneCode);
        Bin.FindLast();
    end;

    local procedure FindFirstBinRankingForZone(var Bin: Record Bin; ZoneCode: Code[10]; LocationCode: Code[10])
    begin
        Bin.SetCurrentKey("Location Code", "Warehouse Class Code", "Bin Ranking");
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", ZoneCode);
        Bin.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; No: Code[20]; ItemNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("No.", No);
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindPostedWarehouseReceiptHeader(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; WhseReceiptNo: Code[20]; LocationCode: Code[10])
    begin
        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WhseReceiptNo);
        PostedWhseReceiptHeader.SetRange("Location Code", LocationCode);
        PostedWhseReceiptHeader.FindFirst();
    end;

    local procedure FindAndUpdateWarehouseReceipt(WarehouseReceiptNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptNo, ItemNo);
        WarehouseReceiptLine.Validate("Qty. to Receive", Quantity);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure FindPickBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindPickZone(Zone, LocationCode);
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, LibraryRandom.RandInt(Bin.Count));  // Find Random Bin.
    end;

    local procedure FindPickZone(var Zone: Record Zone; LocationCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));  // TRUE for Put-away and Pick.
        Zone.FindFirst();
    end;

    local procedure PostWarehouseReceipt(WarehouseReceiptNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(WarehouseReceiptNo);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure RunWhseCalculateInventoryReport(LocationCode: Code[10]; ItemNo: Code[20])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        BinContent: Record "Bin Content";
    begin
        FindWhseJnlTemplateAndBatch(WarehouseJournalBatch, LocationCode, WarehouseJournalBatch."Template Type"::"Physical Inventory");
        WarehouseJournalLine.Init();
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", LocationCode);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
        LibraryWarehouse.WhseCalculateInventory(WarehouseJournalLine, BinContent, WorkDate(), LibraryUtility.GenerateGUID(), false);
    end;

    local procedure RunWhseCalculateInventoryReportWithBatchAndRequestPage(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseCalculateInventory: Report "Whse. Calculate Inventory";
    begin
        WarehouseJournalLine.Init();
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", LocationCode);
        WhseCalculateInventory.SetWhseJnlLine(WarehouseJournalLine);
        WhseCalculateInventory.UseRequestPage(true);
        EnqueueValuesForWhseCalculateInventoryRequestPage(WorkDate(), LibraryUtility.GenerateGUID(), false);

        Commit();

        WhseCalculateInventory.Run();
    end;

    local procedure RunCalculateInventory(ItemNo: Code[20]; ItemsNotOnInvt: Boolean)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::"Phys. Inventory");
        ItemJournalTemplate.Get(ItemJournalBatch."Journal Template Name");
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CalculateInventoryForSingleItem(ItemJournalLine, ItemNo, WorkDate(), ItemsNotOnInvt, false);
    end;

    local procedure RunCombineShipments(CustomerNoFilter: Text; CalcInvDisc: Boolean; PostInvoices: Boolean; OnlyStdPmtTerms: Boolean; CopyTextLines: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetFilter("Sell-to Customer No.", CustomerNoFilter);
        SalesShipmentHeader.SetFilter("Sell-to Customer No.", CustomerNoFilter);
        LibraryVariableStorage.Enqueue(CombineShipmentMsg);  // Enqueue for MessageHandler.
        LibrarySales.CombineShipments(
          SalesHeader, SalesShipmentHeader, WorkDate(), WorkDate(), CalcInvDisc, PostInvoices, OnlyStdPmtTerms, CopyTextLines);
    end;

    local procedure RunCombineShipmentsByBillToCustomer(CustomerNo: Code[20]; CalcInvDisc: Boolean; PostInvoices: Boolean; OnlyStdPmtTerms: Boolean; CopyTextLines: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Bill-to Customer No.", CustomerNo);
        SalesShipmentHeader.SetRange("Bill-to Customer No.", CustomerNo);
        LibraryVariableStorage.Enqueue(CombineShipmentMsg);  // Enqueue for MessageHandler.
        LibrarySales.CombineShipments(
          SalesHeader, SalesShipmentHeader, WorkDate(), WorkDate(), CalcInvDisc, PostInvoices, OnlyStdPmtTerms, CopyTextLines);
    end;

    local procedure CreateTransferOrderLocations(var FromLocation: Record Location; var ToLocation: Record Location; var IntransitLocation: Record Location)
    begin
        CreateAndUpdateLocation(FromLocation, false);
        CreateAndUpdateLocation(ToLocation, false);
        CreateAndUpdateLocation(IntransitLocation, true);
    end;

    local procedure CreateAndRealeaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocation: Code[10]; ToLocation: Code[10]; IntransitLocation: Code[10]; ItemNo: Code[20]; TransferQuantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, IntransitLocation);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, TransferQuantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndRegisterWhseJnlLine(Location: Record Location; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateAndRegisterWhseJnlLine2(Location, ItemNo, Quantity, "Warehouse Journal Template Type"::Item);
    end;

    local procedure CreateAndRegisterWhseJnlLine2(Location: Record Location; ItemNo: Code[20]; Quantity: Decimal; TemplateType: Enum "Warehouse Journal Template Type")
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
        Zone: Record Zone;
    begin
        Zone.Get(Location.Code, BULK);
        FindFirstBinRankingForZone(Bin, Zone.Code, Location.Code);
        CreateWhseJnlLine(WarehouseJournalLine, Location.Code, Bin."Zone Code", Bin.Code, ItemNo, Quantity, TemplateType);
        Bin.Get(Location.Code, Location."Adjustment Bin Code");
        WarehouseJournalLine."From Zone Code" := Bin."Zone Code";
        WarehouseJournalLine."From Bin Code" := Bin.Code;
        WarehouseJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(WantToRegisterConfirm);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLineRegistered);  // Enqueue for MessageHandler.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, false);
    end;

    local procedure CreateWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal; TemplateType: Enum "Warehouse Journal Template Type")
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        FindWhseJnlTemplateAndBatch(WarehouseJournalBatch, LocationCode, TemplateType);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode,
          ZoneCode, BinCode, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; UseAsInTransit: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Use As In-Transit", UseAsInTransit);
        Location.Modify(true);
    end;

    local procedure EnqueueValuesForWhseCalculateInventoryRequestPage(RegisteringDate: Date; WhseDocumentNo: Code[20]; ItemNotOnInventory: Boolean)
    begin
        LibraryVariableStorage.Enqueue(RegisteringDate);
        LibraryVariableStorage.Enqueue(WhseDocumentNo);
        LibraryVariableStorage.Enqueue(ItemNotOnInventory);
    end;

    local procedure FindBinContent(var BinContent: Record "Bin Content"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetFilter(Quantity, '>%1', 0);
        BinContent.FindFirst();
    end;

    local procedure UpdateRankingOnAllBins(LocationCode: Code[10])
    var
        Bin: Record Bin;
        Zone: Record Zone;
        BinRanking: Integer;
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.FindSet();
        repeat
            BinRanking := 0;
            Bin.SetRange("Location Code", LocationCode);
            Bin.SetRange("Zone Code", Zone.Code);
            Bin.FindSet();
            repeat
                BinRanking += 10;  // Value Used for incrementing rank in Bin.
                Bin.Validate("Bin Ranking", BinRanking);
                Bin.Modify(true);
            until Bin.Next() = 0;
        until Zone.Next() = 0;
    end;

    local procedure CreateBinContentForBin(Zone: Record Zone; Item: Record Item; MaxQty: Decimal)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        Bin.SetRange("Location Code", Zone."Location Code");
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindSet();
        repeat
            LibraryWarehouse.CreateBinContent(
              BinContent, Zone."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");
            BinContent.Validate("Min. Qty.", 1);  // Value important For minimum quantity.
            BinContent.Validate("Max. Qty.", MaxQty);
            BinContent.Validate("Bin Ranking", Bin."Bin Ranking");
            BinContent.Validate("Bin Type Code", Bin."Bin Type Code");
            BinContent.Validate(Fixed, true);
            BinContent.Modify(true);
        until Bin.Next() = 0;
    end;

    local procedure FindWhseJnlTemplateAndBatch(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10]; TemplateType: Enum "Warehouse Journal Template Type")
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, TemplateType);
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, LocationCode);
    end;

    local procedure UpdateDateInSalesCommentLine(var SalesCommentLine: Record "Sales Comment Line")
    begin
        SalesCommentLine.Validate(Date, WorkDate());
        SalesCommentLine.Modify(true);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
    end;

    local procedure ReleaseWarehouseShipment(LocationCode: Code[10])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure FindAndVerifyWhseJnlLine(LocationCode: Code[10]; ReasonCode: Code[10]; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        FindWhseJnlTemplateAndBatch(WarehouseJournalBatch, LocationCode, WarehouseJournalBatch."Template Type"::"Physical Inventory");
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.SetRange("Location Code", LocationCode);
        WarehouseJournalLine.FindFirst();
        Assert.AreEqual(
          Quantity, WarehouseJournalLine."Qty. (Calculated)",
          StrSubstNo(ValidationErr, WarehouseJournalLine.FieldCaption("Qty. (Calculated)"), Quantity, WarehouseJournalLine.TableCaption()));
        WarehouseJournalLine.TestField("Reason Code", ReasonCode);
    end;

    local procedure SetupReportSelections(ReportSelectionUsage: Enum "Report Selection Usage"; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelectionUsage);
        ReportSelections.DeleteAll();
        ReportSelections.Init();
        ReportSelections.Validate(Usage, ReportSelectionUsage);
        ReportSelections.Validate(Sequence, '1');
        ReportSelections.Validate("Report ID", ReportId);
        ReportSelections.Insert(true);
    end;

    local procedure UpdateQuantityPhysicalInventoryOnPhysicalInventoryJournal(ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate(
          "Qty. (Phys. Inventory)", ItemJournalLine."Qty. (Calculated)" - (ItemJournalLine."Qty. (Calculated)" / 2));  // Value required for the test.
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateInventoryUsingWarehouseJournal(Bin: Record Bin; Item: Record Item; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        WarehouseJournalLine.DeleteAll(true);  // Delete existing Warehouse Journal Lines.
        CreateWhseJnlLine(
          WarehouseJournalLine,
          Bin."Location Code",
          Bin."Zone Code",
          Bin.Code,
          Item."No.",
          Quantity,
          WarehouseJournalBatch."Template Type"::Item);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", true);
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure VerifyReportData(RowCaption: Text; RowValue: Variant; ColumnCaption: Text; ColumnValue: Variant)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        if LibraryReportDataset.GetNextRow() then
            LibraryReportDataset.AssertCurrentRowValueEquals(ColumnCaption, ColumnValue);
    end;

    local procedure VerifyWarehouseActivityLine(ItemNo: Code[20]; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();

        LibraryReportDataset.SetRange('ActionType_WhseActivLine', Format(WarehouseActivityLine."Action Type"));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemNo_WhseActivLine', WarehouseActivityLine."Item No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_WhseActivHeader', WarehouseActivityLine."Location Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_WhseActivLine', WarehouseActivityLine."Bin Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('QtyBase_WhseActivLine', WarehouseActivityLine."Qty. (Base)");
    end;

    local procedure VerifyPhysInvtJournalLine(ItemNo: Code[20]; CalculatedQty: Decimal; PhysInvtQty: Decimal; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Qty. (Calculated)", CalculatedQty);
        ItemJournalLine.TestField("Qty. (Phys. Inventory)", PhysInvtQty);
        ItemJournalLine.TestField(Quantity, Qty);
    end;

    local procedure VerifyPostedSalesInvoice(ItemNo: Code[20]; Quantity1: Decimal; Quantity2: Decimal; SalesLineDescription: Text[100])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("No.", ItemNo);
        SalesInvoiceLine.SetRange(Quantity, Quantity1);
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(SalesInvoiceLine.Type::Item, SalesInvoiceLine.Type, CombineShipmentErr);
        SalesInvoiceLine.SetRange(Quantity, Quantity2);
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(SalesInvoiceLine.Type::Item, SalesInvoiceLine.Type, CombineShipmentErr);
        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange(Description, SalesLineDescription);
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(SalesInvoiceLine.Type::" ", SalesInvoiceLine.Type, CombineShipmentErr);
    end;

    local procedure VerifySalesInvoice(SellToCustomerNo: Code[20]; BillToCustomerNo: Code[20]; ExpectedCount: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        Assert.RecordCount(SalesLine, ExpectedCount);
    end;

    local procedure CreateWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var WhseRcptLine: Record "Warehouse Receipt Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseReceiptNo: Code[20];
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        WarehouseReceiptNo := FindWarehouseReceiptNo();
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseRcptLine.SetRange("No.", WarehouseReceiptNo);
        WhseRcptLine.FindFirst();
    end;

    local procedure PostAndPrintRcpt(var WhseRcptLine: Record "Warehouse Receipt Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt + Print", WhseRcptLine);
    end;

    local procedure CreateAnalysisViewWithDimensions(var AnalysisView: Record "Analysis View"; AccountSource: Enum "Analysis Source Type")
    var
        Dimension: Record Dimension;
        i: Integer;
    begin
        CreateAnalysisView(AnalysisView, AccountSource);
        AnalysisView."Update on Posting" := true;
        if Dimension.FindSet() then
            repeat
                i := i + 1;
                case i of
                    1:
                        AnalysisView."Dimension 1 Code" := Dimension.Code;
                    2:
                        AnalysisView."Dimension 2 Code" := Dimension.Code;
                    3:
                        AnalysisView."Dimension 3 Code" := Dimension.Code;
                    4:
                        AnalysisView."Dimension 4 Code" := Dimension.Code;
                end;
            until (i = 4) or (Dimension.Next() = 0);
        AnalysisView.Modify();
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);
    end;

    local procedure CreateAnalysisView(var AnalysisView: Record "Analysis View"; AccountSource: Enum "Analysis Source Type")
    begin
        AnalysisView.Init();
        AnalysisView.Code := Format(LibraryRandom.RandIntInRange(1, 10000));
        AnalysisView."Account Source" := AccountSource;
        AnalysisView.Insert();
    end;

    local procedure CreateLocationWithWarehouseEmployeeSetup(
        var Location: Record Location;
        var WarehouseEmployee: Record "Warehouse Employee")
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Validate("Asm. Consump. Whse. Handling", Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Modify(true);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure FindBinType(
        var BinType: Record "Bin Type";
        Receive: Boolean;
        Ship: Boolean;
        Pick: Boolean;
        PutAway: Boolean)
    begin
        BinType.SetRange("Put Away", PutAway);
        BinType.SetRange(Pick, Pick);
        BinType.SetRange(Receive, Receive);
        BinType.SetRange(Ship, Ship);
        BinType.FindFirst();
    end;

    local procedure ValidateAssemblyProdAndAdjmtBinCodesInLocation(
        var Location: Record Location;
        BinCode: Code[20];
        BinCode2: Code[20];
        Bincode3: Code[20])
    begin
        Location.Validate("To-Production Bin Code", BinCode3);
        Location.Validate("From-Production Bin Code", BinCode2);
        Location.Validate("To-Assembly Bin Code", BinCode3);
        Location.Validate("From-Assembly Bin Code", BinCode2);
        Location.Validate("Adjustment Bin Code", BinCode);
        Location.Modify(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforePrintDocument', '', false, false)]
    local procedure ChangeReportRunTypeOnBeforePrintDocument(TempReportSelections: Record "Report Selections"; IsGUI: Boolean; RecVarToPrint: Variant; var IsHandled: Boolean)
    begin
        if not IsGUI then begin
            IsHandled := true;
            REPORT.RunModal(TempReportSelections."Report ID", true, false, RecVarToPrint);
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(ConfirmMessage, LocalMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, LocalMessage) > 0, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WarehouseBinListReportHandler(var WarehouseBinListPage: TestRequestPage "Warehouse Bin List")
    begin
        WarehouseBinListPage.ShowBinContents.SetValue(true);
        WarehouseBinListPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedListRequestPageHandler(var WhereUsedList: TestRequestPage "Where-Used List")
    begin
        WhereUsedList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PickingListRequestPageHandler(var PickingListPage: TestRequestPage "Picking List")
    begin
        PickingListPage.Breakbulk.SetValue(true);
        PickingListPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PutAwayListRequestPageHandler(var PutawayListPage: TestRequestPage "Put-away List")
    begin
        PutawayListPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryPutAwayListRequestPageHandler(var InventoryPutawayListPage: TestRequestPage "Inventory Put-away List")
    begin
        InventoryPutawayListPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseReceiptListRequestPageHandler(var WhseReceiptPage: TestRequestPage "Whse. - Receipt")
    begin
        WhseReceiptPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseAdjustmentBinRequestPageHandler(var WhseAdjustmentBinPage: TestRequestPage "Whse. Adjustment Bin")
    begin
        WhseAdjustmentBinPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MovementListRequestPageHandler(var MovementListPage: TestRequestPage "Movement List")
    begin
        MovementListPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferOrderRequestPageHandler(var TransferOrderPage: TestRequestPage "Transfer Order")
    begin
        TransferOrderPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferShipmentRequestPageHandler(var TransferShipmentPage: TestRequestPage "Transfer Shipment")
    begin
        TransferShipmentPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferReceiptRequestPageHandler(var TransferReceiptPage: TestRequestPage "Transfer Receipt")
    begin
        TransferReceiptPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhsePostedReceiptRequestPageHandler(var WhsePostedReceipt: TestRequestPage "Whse. - Posted Receipt")
    begin
        WhsePostedReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryPickingListRequestPageHandler(var InventoryPickingListPage: TestRequestPage "Inventory Picking List")
    begin
        InventoryPickingListPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseShipmentRequestPageHandler(var WhseShipmentPage: TestRequestPage "Whse. - Shipment")
    begin
        WhseShipmentPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseShipmentStatusRequestPageHandler(var WhseShipmentStatusPage: TestRequestPage "Whse. Shipment Status")
    begin
        WhseShipmentStatusPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhsePhysInventoryListRequestPageHandler(var WhsePhysInventoryList: TestRequestPage "Whse. Phys. Inventory List")
    var
        ShowCalculatedQty: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowCalculatedQty);
        WhsePhysInventoryList.ShowCalculatedQty.SetValue(ShowCalculatedQty);
        WhsePhysInventoryList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseRegisterQuantityRequestPageHandler(var WarehouseRegisterQuantityPage: TestRequestPage "Warehouse Register - Quantity")
    begin
        WarehouseRegisterQuantityPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryPostingTestRequestPageHandler(var InventoryPostingTestPage: TestRequestPage "Inventory Posting - Test")
    begin
        InventoryPostingTestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOrderDetailRequestPageHandler(var CustomerOrderDetail: TestRequestPage "Customer - Order Detail")
    var
        ShowAmountInLCY: Variant;
        NewPagePerCustomer: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountInLCY);
        LibraryVariableStorage.Dequeue(NewPagePerCustomer);

        CustomerOrderDetail.ShowAmountsInLCY.SetValue(ShowAmountInLCY);
        CustomerOrderDetail.NewPagePerCustomer.SetValue(NewPagePerCustomer);
        CustomerOrderDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesReturnReceiptRequestPageHandler(var SalesReturnReceipt: TestRequestPage "Sales - Return Receipt")
    begin
        SalesReturnReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WorkOrderRequestPageHandler(var WorkOrder: TestRequestPage "Work Order")
    begin
        WorkOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityPlanRequestPageHandler(var InventoryAvailabilityPlan: TestRequestPage "Inventory - Availability Plan")
    var
        StartingDate: Variant;
        PeriodLength: Variant;
        UseStockkeepingUnit: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(PeriodLength);
        LibraryVariableStorage.Dequeue(UseStockkeepingUnit);

        InventoryAvailabilityPlan.StartingDate.SetValue(StartingDate);
        InventoryAvailabilityPlan.PeriodLength.SetValue(PeriodLength);
        InventoryAvailabilityPlan.UseStockkeepUnit.SetValue(UseStockkeepingUnit);
        InventoryAvailabilityPlan.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseCalculateInventoryRequestPageHandler(var WhseCalculateInventoryPage: TestRequestPage "Whse. Calculate Inventory")
    begin
        WhseCalculateInventoryPage.RegisteringDate.SetValue(LibraryVariableStorage.DequeueDate());
        WhseCalculateInventoryPage.WhseDocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        WhseCalculateInventoryPage.ZeroQty.SetValue(LibraryVariableStorage.DequeueBoolean());
        WhseCalculateInventoryPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickFromWhseShptRequestPageHandler(var WhseShipmentCreatePick: TestRequestPage "Whse.-Shipment - Create Pick")
    begin
        WhseShipmentCreatePick.PrintDoc.SetValue(true);
        WhseShipmentCreatePick.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentXmlRequestPageHandler(var SalesShipment: TestRequestPage "Sales Shipment NA")
    begin
        LibraryReportDataset.SetFileName(LibraryVariableStorage.DequeueText());
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure WhsePostedShipmentRequestPageHandler(var WhsePostedShipment: TestRequestPage "Whse. - Posted Shipment")
    begin
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger() + 1);
        WhsePostedShipment.Cancel().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure PutAwayListReportHandler(var PutAwayListPage: Report "Put-away List")
    var
        ReportExecuted: Boolean;
    begin
        PutAwayListPage.SaveAsXml(LibraryReportDataset.GetFileName());
        ReportExecuted := true;
        LibraryVariableStorage.Enqueue(ReportExecuted);
    end;
}

