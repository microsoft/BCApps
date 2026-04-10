codeunit 137204 "SCM Whse Get Source Inbound"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        IsInitialized := false;
    end;

    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        ProcessTypeGlobal: Option Location,WarehousePutAway,Register,PutAwayQuantity,TransferQuantity,PurchaseQuantity,WarehouseShipmentQty,TransferBlank,RequestBlank;
        DocumentTypeGlobal: Option Sales,Purchase,Warehouse;
        LocationCodeHandler: Code[10];
        PutAwayNo: Code[20];
        PutawayRequestDocumentNo: Code[20];
        IsInitialized: Boolean;
        DocumentNoErr: Label '%1 must be %2 in %3';

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,PutAwayPageHandler')]
    [Scope('OnPrem')]
    procedure InboundPurchPutAwayLocation()
    begin
        // Check Put Away Selection Page Have Selected data For Receipt Created From Purchase Order.
        Initialize();
        CreateInboundSalesPurchase(ProcessTypeGlobal::Location, DocumentTypeGlobal::Purchase);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,PutAwayPageHandler')]
    [Scope('OnPrem')]
    procedure InboundPurchWarehousePutAway()
    begin
        // Check Warehouse Activity Line Have Same Purchase Source Document No., Item And Quantity, For Receipt Created Form
        // Purchase Order.
        Initialize();
        CreateInboundSalesPurchase(ProcessTypeGlobal::WarehousePutAway, DocumentTypeGlobal::Purchase);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,PutAwayPageHandler')]
    [Scope('OnPrem')]
    procedure InboundPurchRegistered()
    begin
        // Check That There is No Request Remain For Said Location After Register Put Away For Receipt Created From Purchase Order.
        Initialize();
        CreateInboundSalesPurchase(ProcessTypeGlobal::Register, DocumentTypeGlobal::Purchase);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,PutAwayPageHandler')]
    [Scope('OnPrem')]
    procedure InboundReturnPutAwayLocation()
    begin
        // Check Put Away Selection Page Have Selected data For Receipt Created From Sales Return Order.
        Initialize();
        CreateInboundSalesPurchase(ProcessTypeGlobal::Location, DocumentTypeGlobal::Sales);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,PutAwayPageHandler')]
    [Scope('OnPrem')]
    procedure InboundReturnWarehousePutAway()
    begin
        // Check Warehouse Activity Line Have Same Sales Return Source Document No., Item And Quantity,For Receipt Created From
        // Sales Return Order.
        Initialize();
        CreateInboundSalesPurchase(ProcessTypeGlobal::WarehousePutAway, DocumentTypeGlobal::Sales);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,PutAwayPageHandler')]
    [Scope('OnPrem')]
    procedure InboundReturnRegistered()
    begin
        // Check That There is No Request Remain For Said Location After Register Put Away For Receipt Created From Sales Return.
        Initialize();
        CreateInboundSalesPurchase(ProcessTypeGlobal::Register, DocumentTypeGlobal::Sales);
    end;

    local procedure CreateInboundSalesPurchase(ProcessType: Option; DocumentType: Option)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
        ItemNo: Code[20];
        WarehouseReceiptNo: Code[20];
        DocumentNo: Code[20];
        WhseWorksheetName: Code[10];
        WhseWorksheetTemplateName: Code[10];
        LocationCode: Code[10];
    begin
        // Setup.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        WarehouseReceiptNo := CreatePutAwaySetup(PurchaseHeader, SalesHeader, ItemNo, Quantity, DocumentType, false, false, true);
        DocumentNo := SalesHeader."No.";
        LocationCode := SalesHeader."Location Code";

        if DocumentType = DocumentTypeGlobal::Purchase then begin
            DocumentNo := PurchaseHeader."No.";
            LocationCode := PurchaseHeader."Location Code";
            WarehouseReceiptNo := CreateFromPurchOrder(PurchaseHeader);  // Create warehouse Receipt from Purchase Order.
        end;
        PostWarehouseReceipt(WarehouseReceiptNo);
        CreatePutAway(WhseWorksheetName, WhseWorksheetTemplateName, LocationCode);
        FindWorksheetLine(WhseWorksheetLine, WhseWorksheetName, WhseWorksheetTemplateName, LocationCode);

        // Exercise And Verify.
        case ProcessType of
            ProcessTypeGlobal::Location:  // Check that Request is created for particular location.
                VerifyPutawayRequest(WhseWorksheetLine."Location Code");
            ProcessTypeGlobal::WarehousePutAway:  // Check That Warehouse Activity Line created after creating put away.
                begin
                    GetWarehouseSourceDocument(WhseWorksheetLine);
                    VerifyWarehousePutaway(ItemNo, Quantity, LocationCode, DocumentNo);
                end;
            ProcessTypeGlobal::Register:  // Check that no request pending after register put away.
                begin
                    RegisterPutAway(WhseWorksheetLine, LocationCode);
                    asserterror VerifyPutawayRequest(LocationCode);
                end;
        end;

        // Teardown.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,SourcePageHandler,PutAwayPageHandler')]
    [Scope('OnPrem')]
    procedure PurchPutAwayLocation()
    begin
        // Check Put Away Selection Page has selected data For Receipt created from Warehouse Receipt Header.
        Initialize();
        CreateInboundPurchWhseReceipt(ProcessTypeGlobal::Location);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,SourcePageHandler,PutAwayPageHandler')]
    [Scope('OnPrem')]
    procedure PurchWarehousePutAway()
    begin
        // Check Warehouse Activity Line has same Purchase Source Document No., Item And Quantity, for Receipt Created
        // from Warehouse Receipt Header.
        Initialize();
        CreateInboundPurchWhseReceipt(ProcessTypeGlobal::WarehousePutAway);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,SourcePageHandler,PutAwayPageHandler')]
    [Scope('OnPrem')]
    procedure PurchRegistered()
    begin
        // Check that there is no Request remaining for said Location After Register Put Away for Receipt created from
        // Warehouse Receipt Header.
        Initialize();
        CreateInboundPurchWhseReceipt(ProcessTypeGlobal::Register);
    end;

    local procedure CreateInboundPurchWhseReceipt(ProcessType: Option)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
        DocumentType: Option Sales,Purchase,Warehouse;
        Quantity: Decimal;
        ItemNo: Code[20];
        WarehouseReceiptNo: Code[20];
        WhseWorksheetName: Code[10];
        WhseWorksheetTemplateName: Code[10];
    begin
        // Setup.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        WarehouseReceiptNo := CreatePutAwaySetup(PurchaseHeader, SalesHeader, ItemNo, Quantity, DocumentType::Purchase, false, false, true);
        CreateWarehouseReceiptHeader(WarehouseReceiptHeader, PurchaseHeader."Location Code");
        WarehouseReceiptNo := WarehouseReceiptHeader."No.";
        GetSourceDocInbound.GetSingleInboundDoc(WarehouseReceiptHeader);  // Create Receipt from warehouse Receipt Header.
        PostWarehouseReceipt(WarehouseReceiptNo);
        CreatePutAway(WhseWorksheetName, WhseWorksheetTemplateName, PurchaseHeader."Location Code");
        FindWorksheetLine(WhseWorksheetLine, WhseWorksheetName, WhseWorksheetTemplateName, PurchaseHeader."Location Code");

        // Exercise And Verify.
        case ProcessType of
            ProcessTypeGlobal::Location:  // Check that Request is Created for paticular location.
                VerifyWhseRequest(WhseWorksheetLine."Location Code", PurchaseHeader."No.");
            ProcessTypeGlobal::WarehousePutAway:  // Check that Warehouse Activity Line create after creating put away.
                begin
                    GetWarehouseSourceDocument(WhseWorksheetLine);
                    VerifyWarehousePutaway(ItemNo, Quantity, PurchaseHeader."Location Code", PurchaseHeader."No.")
                end;
            ProcessTypeGlobal::Register:  // Check that no request pending after register put away.
                begin
                    RegisterPutAway(WhseWorksheetLine, PurchaseHeader."Location Code");
                    asserterror VerifyPutawayRequest(PurchaseHeader."Location Code");
                end;
        end;
        // Teardown.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InboundWhsePutAwayQty()
    begin
        // Check That Put Away Quantity To Handle is equal to Receipt Quantity, For Transfer Order.
        Initialize();
        CreateInboundTransferWarehouse(ProcessTypeGlobal::PutAwayQuantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InboundWhsePutAwayTransferQty()
    begin
        // Check That Put Away Quantity To Handle is equal to Transfer Quantity, For Transfer Order.
        Initialize();
        CreateInboundTransferWarehouse(ProcessTypeGlobal::TransferQuantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InboundWhsePutAwayPurchLineQty()
    begin
        // Check That Purchase Line Received Quantity is equal to Put Away Register Quantity.
        Initialize();
        CreateInboundTransferWarehouse(ProcessTypeGlobal::PurchaseQuantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InboundPutAwayWhseShipQty()
    begin
        // Check Warehouse Shipment Quantity after Pick and Register.
        Initialize();
        CreateInboundTransferWarehouse(ProcessTypeGlobal::WarehouseShipmentQty);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InboundPutAwayTransferBlank()
    begin
        // Check No Transfer Order Exist After Post Shipment And Register Pick , Post Receipt and Register Put Away.
        Initialize();
        CreateInboundTransferWarehouse(ProcessTypeGlobal::TransferBlank);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,SourceDocumentHandler')]
    [Scope('OnPrem')]
    procedure InboundPutAwayWhseRequestBlank()
    begin
        // Check No Request  After Posting and Put Away Register.
        Initialize();
        CreateInboundTransferWarehouse(ProcessTypeGlobal::RequestBlank);
    end;

    local procedure CreateInboundTransferWarehouse(ProcessType: Option)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        PurchaseLine: Record "Purchase Line";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
        DocumentType: Option Sales,Purchase,Warehouse;
        Quantity: Decimal;
        ItemNo: Code[20];
        WarehouseReceiptNo: Code[20];
        TransferQuantity: Decimal;
        WarehouseShipmentHeaderNo: Code[20];
        TransferHeaderNo: Code[20];
        LocationCode: Code[10];
        LocationCode2: Code[10];
    begin
        // Setup.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        WarehouseReceiptNo := CreatePutAwaySetup(PurchaseHeader, SalesHeader, ItemNo, Quantity, DocumentType::Purchase, true, true, false);
        LocationCode := PurchaseHeader."Location Code";
        WarehouseReceiptNo := CreateFromPurchOrder(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptNo);

        // Exercise And Verify.
        case ProcessType of
            ProcessTypeGlobal::PutAwayQuantity:  // Check put away quantity with purchase order quantity.
                begin
                    FindWarehouseActivityLine(WarehouseActivityLine, LocationCode);
                    WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
                    VerifyWarehousePutaway(ItemNo, Quantity, PurchaseHeader."Location Code", PurchaseHeader."No.");
                end;
            ProcessTypeGlobal::TransferQuantity: // Check Transfer quantity with Warehouse Activity Line quantity.
                begin
                    TransferQuantity :=
                      CreatePickForWhseShipment(
                        WarehouseShipmentHeaderNo, TransferHeaderNo, LocationCode2, PurchaseHeader, ItemNo);
                    FindWarehouseActivityLine(WarehouseActivityLine, LocationCode);
                    WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
                    VerifyWarehousePutaway(ItemNo, TransferQuantity, LocationCode, TransferHeaderNo);
                end;
            ProcessTypeGlobal::PurchaseQuantity:  // Check that received quantity on Purchase Line is updated after Register Put Away.
                begin
                    RegisterWhseActivityLine(PurchaseHeader."Location Code");
                    PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                    PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                    PurchaseLine.FindFirst();
                    PurchaseLine.TestField("Quantity Received", Quantity);
                end;
            ProcessTypeGlobal::WarehouseShipmentQty:  // Check warehouse shipment quantity with transfer quantity.
                begin
                    TransferQuantity :=
                      CreatePickForWhseShipment(
                        WarehouseShipmentHeaderNo, TransferHeaderNo, LocationCode2, PurchaseHeader, ItemNo);
                    RegisterWhseActivityLine(LocationCode);
                    VerifyShipmentQuantity(TransferQuantity, WarehouseShipmentHeaderNo);
                end;
            ProcessTypeGlobal::TransferBlank:  // Check no Transfer Order exist after Warehouse shipment and receipt for Transfer Order.
                begin
                    CreateAndPostWarehouseReceipt(PurchaseHeader, TransferHeaderNo, LocationCode2, ItemNo);
                    TransferHeader.SetRange("No.", TransferHeaderNo);
                    Assert.RecordIsEmpty(TransferHeader);
                end;
            ProcessTypeGlobal::RequestBlank:  // Check no request pending after register Warehouse Activity line.
                begin
                    CreateAndPostWarehouseReceipt(PurchaseHeader, TransferHeaderNo, LocationCode2, ItemNo);
                    CreateWarehouseReceiptHeader(WarehouseReceiptHeader, LocationCode2);
                    GetSourceDocInbound.GetSingleInboundDoc(WarehouseReceiptHeader);
                    asserterror VerifyWhseRequest(WarehouseReceiptHeader."Location Code", '');
                end;
        end;

        // Teardown.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Whse Get Source Inbound");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Whse Get Source Inbound");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Whse Get Source Inbound");
    end;

    local procedure UpdateSalesReceivablesSetup(var TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary)
    begin
        SalesReceivablesSetup.Get();
        TempSalesReceivablesSetup := SalesReceivablesSetup;
        TempSalesReceivablesSetup.Insert();
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", false);
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreatePutAwaySetup(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var ItemNo: Code[20]; var Quantity: Decimal; DocumentType: Option Sales,Purchase,Warehouse; RequirePick: Boolean; RequireShipment: Boolean; UsePutawayWorksheet: Boolean) WarehouseReceiptNo: Code[20]
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        LocationCode: Code[10];
    begin
        // Create Location, Warehouse Employee And Inventory Posting Setup.
        SetupWarehouseLocation(LocationCode, true, RequirePick, true, RequireShipment, UsePutawayWorksheet);
        ItemNo := CreateItem();
        Quantity := LibraryRandom.RandDecInRange(10, 20, 2);

        case DocumentType of
            DocumentType::Sales:
                begin
                    CreateAndReleaseSalesReturns(SalesHeader, ItemNo, LocationCode, Quantity);
                    // Create Warehouse Receipt From Sales Return Document.
                    LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);

                    WhseRcptHeader.SetRange("Location Code", SalesHeader."Location Code");
                    WhseRcptHeader.FindLast();
                    WarehouseReceiptNo := WhseRcptHeader."No.";
                end;
            DocumentType::Purchase:
                CreateAndReleasePurchaseOrder(PurchaseHeader, ItemNo, LocationCode, Quantity);
        end;
    end;

    local procedure CreateTransferDocWhseShipment(var TransferHeaderNo: Code[20]; LocationCode: Code[10]; LocationCode2: Code[10]; IntransitCode: Code[10]; ItemNo: Code[20]) TransferQuantity: Decimal
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
    begin
        // Create And Release Transfer Document And Create Warehouse Shipment Line From Transfer Document.
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationCode, LocationCode2, IntransitCode);
        TransferHeaderNo := TransferHeader."No.";
        TransferQuantity := LibraryRandom.RandDec(5, 2);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, TransferQuantity);
        ReleaseTransferDocument.Run(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);  // Creating Warehouse Shipment from Transfer Header.
    end;

    local procedure CreateAndUpdateLocIntransit(var LocationCode2: Code[10]; var LocationCode3: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location2: Record Location;
    begin
        // Create Location, Update Inventory Posting Setup And Intransit Location for Transfer .
        CreateAndUpdateLocation(Location2, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location2.Code, false);
        LocationCode2 := Location2.Code;
        CreateAndUpdateLocation(Location2, false, true);
        LocationCode3 := Location2.Code;
    end;

    local procedure CreateAndUpdateLocation(var Location2: Record Location; RequireReceive: Boolean; UseAsInTransit: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);
        Location2.Validate("Require Receive", RequireReceive);
        Location2.Validate("Use As In-Transit", UseAsInTransit);
        Location2.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(20, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateWarehouseEmployee(LocationCode: Code[10]; IsDefault: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SetRange("User ID", UserId);
        if WarehouseEmployee.FindFirst() then
            WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, IsDefault);
    end;

    local procedure SetupWarehouseLocation(var LocationCode: Code[10]; RequirePutaway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; UsePutawayWorksheet: Boolean)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Use Put-away Worksheet", UsePutawayWorksheet);
        Location.Validate("Require Put-away", RequirePutaway);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Pick", RequirePick);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Modify(true);

        CreateWarehouseEmployee(Location.Code, true);
        LocationCode := Location.Code;
        LocationCodeHandler := Location.Code;
    end;

    local procedure RegisterWhseActivityLine(LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseActRegisterYesNo: Codeunit "Whse.-Act.-Register (Yes/No)";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, LocationCode);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WhseActRegisterYesNo.Run(WarehouseActivityLine);
    end;

    local procedure CreatePickForWhseShipment(var WarehouseShipmentHeaderNo: Code[20]; var TransferHeaderNo: Code[20]; var LocationCode: Code[10]; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]) TransferQuantity: Decimal
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
        WhseShipmentRelease: Codeunit "Whse.-Shipment Release";
        LocationCode2: Code[10];
    begin
        // Create And Register Put Away.
        RegisterWhseActivityLine(PurchaseHeader."Location Code");  // Register Put Away For Receipt Created from Purchase.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        CreateAndUpdateLocIntransit(LocationCode, LocationCode2);

        // Create Transfer Document And Create Warehouse Shipment From Transfer Order.
        TransferQuantity :=
          CreateTransferDocWhseShipment(TransferHeaderNo, PurchaseHeader."Location Code", LocationCode, LocationCode2, ItemNo);

        // Creating Pick For Warehouse Shipment.
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, WarehouseShipmentLine, PurchaseHeader."Location Code");
        WhseShipmentRelease.Release(WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetHideValidationDialog(false);
        WhseShipmentCreatePick.UseRequestPage(false);
        WhseShipmentCreatePick.Run();
        WarehouseShipmentHeaderNo := WarehouseShipmentHeader."No.";
    end;

    local procedure CreateAndPostWarehouseReceipt(var PurchaseHeader: Record "Purchase Header"; var TransferHeaderNo: Code[20]; var LocationCode: Code[10]; ItemNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
        WarehouseReceiptNo: Code[20];
        WarehouseShipmentHeaderNo: Code[20];
    begin
        CreatePickForWhseShipment(
          WarehouseShipmentHeaderNo, TransferHeaderNo, LocationCode, PurchaseHeader, ItemNo);
        RegisterWhseActivityLine(PurchaseHeader."Location Code");  // Register Warehouse Activity Line Created by creating pick.
        PostWarehouseShipment(WarehouseShipmentHeaderNo);

        // Create Warehouse Receipt And Post Warehouse Receipt.
        TransferHeader.Get(TransferHeaderNo);
        WarehouseReceiptNo := FindWarehouseReceiptNo();
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);  // Create Warehouse Receipt From Transfer Order.
        PostWarehouseReceipt(WarehouseReceiptNo);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode2: Code[10])
    begin
        WarehouseReceiptHeader.Init();
        WarehouseReceiptHeader.Insert(true);
        WarehouseReceiptHeader.Validate("Location Code", LocationCode2);
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreatePutAway(var WhseWorksheetNameName: Code[10]; var WhseWorksheetTemplateName: Code[10]; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::"Put-away");
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhseWorksheetNameName := WhseWorksheetName.Name;
        WhseWorksheetTemplateName := WhseWorksheetTemplate.Name;
        GetSourceDocInbound.GetSingleWhsePutAwayDoc(WhseWorksheetTemplate.Name, WhseWorksheetName.Name, LocationCode);
    end;

    local procedure PostWarehouseReceipt(WarehouseReceiptNo: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhsePostReceiptYesNo: Codeunit "Whse.-Post Receipt (Yes/No)";
    begin
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptNo);
        WarehouseReceiptLine.FindFirst();
        WhsePostReceiptYesNo.Run(WarehouseReceiptLine);
    end;

    local procedure PostWarehouseShipment(WarehouseShipmentHeaderNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeaderNo);
        WarehouseShipmentLine.FindFirst();
        WhsePostShipment.Run(WarehouseShipmentLine);
    end;

    local procedure FindWarehouseReceiptNo(): Code[20]
    var
        WarehouseSetup: Record "Warehouse Setup";
        NoSeries: Codeunit "No. Series";
    begin
        WarehouseSetup.Get();
        exit(NoSeries.PeekNextNo(WarehouseSetup."Whse. Receipt Nos."));
    end;

    local procedure FindWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Code[10]; WhseWorksheetTemplateName: Code[10]; LocationCode: Code[10])
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplateName);
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure GetWarehouseSourceDocument(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    var
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
    begin
        WhseSourceCreateDocument.SetWhseWkshLine(WhseWorksheetLine);
        WhseSourceCreateDocument.Initialize(UserId, "Whse. Activity Sorting Method"::None, false, false, false);
        WhseSourceCreateDocument.UseRequestPage(false);
        WhseSourceCreateDocument.Run();
    end;

    local procedure CreateAndReleaseSalesReturns(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; LocationCode: Code[10])
    begin
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure RestoreSalesReceivableSetup(TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", TempSalesReceivablesSetup."Credit Warnings");
        SalesReceivablesSetup.Validate("Stockout Warning", TempSalesReceivablesSetup."Stockout Warning");
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", TempSalesReceivablesSetup."Exact Cost Reversing Mandatory");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure RegisterPutAway(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseActRegisterYesNo: Codeunit "Whse.-Act.-Register (Yes/No)";
    begin
        GetWarehouseSourceDocument(WhseWorksheetLine);
        FindWarehouseActivityLine(WarehouseActivityLine, LocationCode);
        WhseActRegisterYesNo.Run(WarehouseActivityLine);
    end;

    local procedure VerifyPutawayRequest(LocationCode: Code[10])
    var
        WhsePutAwayRequest: Record "Whse. Put-away Request";
    begin
        WhsePutAwayRequest.SetRange("Location Code", LocationCode);
        WhsePutAwayRequest.FindFirst();
        WhsePutAwayRequest.TestField("Document Type", WhsePutAwayRequest."Document Type"::Receipt);
        WhsePutAwayRequest.TestField(Status, WhsePutAwayRequest.Status::Open);
        Assert.AreEqual(
          PutawayRequestDocumentNo, WhsePutAwayRequest."Document No.",
          StrSubstNo(DocumentNoErr, WhsePutAwayRequest.FieldCaption("Document No."), PutawayRequestDocumentNo,
            WhsePutAwayRequest.TableCaption()));
    end;

    local procedure VerifyWhseRequest(LocationCode: Code[10]; SourceNo: Code[20])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Location Code", LocationCode);
        WarehouseRequest.FindFirst();
        WarehouseRequest.TestField("Source No.", SourceNo);
        Assert.AreEqual(
          PutAwayNo, WarehouseRequest."Put-away / Pick No.",
          StrSubstNo(DocumentNoErr, WarehouseRequest.FieldCaption("Put-away / Pick No."), PutAwayNo, WarehouseRequest.TableCaption()));
    end;

    local procedure VerifyShipmentQuantity(Quantity: Decimal; No: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", No);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehousePutaway(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, LocationCode);
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField("Source No.", SourceNo);
        WarehouseActivityLine.TestField("Qty. to Handle", Quantity);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PutAwayPageHandler(var PutAwaySelection: Page "Put-away Selection"; var Response: Action)
    var
        WhsePutAwayRequest: Record "Whse. Put-away Request";
    begin
        WhsePutAwayRequest.SetRange("Location Code", LocationCodeHandler);
        WhsePutAwayRequest.SetRange("Completely Put Away", false);
        WhsePutAwayRequest.FindFirst();
        PutawayRequestDocumentNo := WhsePutAwayRequest."Document No.";
        PutAwaySelection.SetRecord(WhsePutAwayRequest);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SourcePageHandler(var SourceDocuments: Page "Source Documents"; var Response: Action)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Location Code", LocationCodeHandler);
        WarehouseRequest.FindFirst();
        PutAwayNo := WarehouseRequest."Put-away / Pick No.";
        SourceDocuments.SetRecord(WarehouseRequest);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SourceDocumentHandler(var SourceDocuments: Page "Source Documents"; var Response: Action)
    begin
        Response := ACTION::OK;
    end;

    local procedure CreateFromPurchOrder(PurchHeader: Record "Purchase Header"): Code[20]
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchHeader);
        WhseRcptHeader.SetRange("Location Code", PurchHeader."Location Code");
        WhseRcptHeader.FindLast();
        exit(WhseRcptHeader."No.");
    end;
}

