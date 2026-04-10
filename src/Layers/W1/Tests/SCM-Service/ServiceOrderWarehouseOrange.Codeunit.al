// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Posting;
using Microsoft.Service.Pricing;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

codeunit 136148 "Service Order Warehouse Orange"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Service]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        OrangeLocation: Code[10];
        WkshName: Code[10];
        isInitialized: Boolean;
        ERR_ShipmentAndWorksheetLinesNotEqual: Label 'Number of shipment lines are not equal to number of worksheet lines added for warehouse shipment';
        ERR_SourceLineNoMismatchedInShipmentLineAndWorksheetLine: Label '"Source Line No." of shipment line is different from that of worksheet line for warehouse shipment';
        ERR_NoWorksheetLinesCreated: Label 'There are no Warehouse Worksheet Lines created.';
        ErrorMessage: Text[1024];
        ERR_MultipleWhseWorksheetTemplate: Label 'There exist multiple warehouse worksheet templates for page %1.';
        ERR_Unexpected: Label 'Unexpected error.';
        PickWorksheetPage: Label 'Pick Worksheet';
        REC: Label 'REC';
        SHIP: Label 'SHIP';
        PICKPUT: Label 'PICKPUT';
        QuantityInsufficientErrorTxt: Label 'Quantity (Base) is not sufficient to complete this action. The quantity in the bin is';

    [Test]
    [HandlerFunctions('HandleRequestPageCreatePick,HandleConfirm,HandleMessage,HandlePickSelectionPage,HandleModalWhsWkshName')]
    [Scope('OnPrem')]
    procedure TestPickWorksheetCreatePick()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // Setup
        Initialize();
        DeleteExistingWhsWorksheetPickLines();
        // execute
        CreatePickWorksheet(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, 1);
        // setup
        ReceiveItemStockInWarehouse(ServiceLine);
        Commit();
        GetLatestWhseWorksheetLines(WarehouseShipmentHeader, WhseWorksheetLine);
        // verify
        repeat
            WhseWorksheetLine.Validate("Qty. to Handle", WhseWorksheetLine.Quantity);
            WhseWorksheetLine.Modify(true);
        until WhseWorksheetLine.Next() <= 0;
        Commit();
        // execute
        GetLatestWhseWorksheetLines(WarehouseShipmentHeader, WhseWorksheetLine);
        if not WhseWorksheetLine.IsEmpty() then
            CODEUNIT.Run(CODEUNIT::"Whse. Create Pick", WhseWorksheetLine);
    end;

    [Test]
    [HandlerFunctions('HandlePickSelectionPage,HandleModalWhsWkshName')]
    [Scope('OnPrem')]
    procedure TestErrorOnRecreatingPickWorksheet()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreatePickWorksheet(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, 3);
        // Verify
        asserterror InvokeGetWarehouseDocument();
        ErrorMessage := ERR_NoWorksheetLinesCreated;
        Assert.AreEqual(ErrorMessage, GetLastErrorText, ERR_Unexpected);
    end;

    [Test]
    [HandlerFunctions('HandlePickSelectionPage,HandleModalWhsWkshName')]
    [Scope('OnPrem')]
    procedure TestPickWorksheetGetWarehouseDocuments()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreatePickWorksheet(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, 3);
        // verify
        ValidateWorksheetLinesWithShipmentLines(WarehouseShipmentHeader, WarehouseShipmentLine);
    end;

    [Test]
    [HandlerFunctions('HandlePickSelectionPage,HandleModalWhsWkshName')]
    [Scope('OnPrem')]
    procedure TestPickWkshtGetWhseDocumentsOnReopenEditRelease()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        Item: Record Item;
        ServiceItem: Record "Service Item";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShptRelease: Codeunit "Whse.-Shipment Release";
    begin
        // Setup
        Initialize();
        CreatePickWorksheet(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, 4);
        // reopen service order, add new lines and release again
        LibraryService.ReopenServiceDocument(ServiceHeader);
        LibraryInventory.CreateItem(Item);
        CreateServiceItem(ServiceItem, ServiceHeader."Customer No.", Item."No.");
        Clear(ServiceItemLine);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem);
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // execute
        // release warehouse shipment and create pick worksheet again
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);
        WarehouseShipmentHeader.FindLast();
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WhseShptRelease.Release(WarehouseShipmentHeader);
        InvokeGetWarehouseDocument();
        // Validate result
        ValidateWorksheetLinesWithShipmentLines(WarehouseShipmentHeader, WarehouseShipmentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWhsePickRequestOnReleaseWhseShipment()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        // Setup
        Initialize();
        // execute
        CreateAndReleaseWhseShipment(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, 3);
        // validate
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Shipment, WhsePickRequest."Document Subtype"::"0", WarehouseShipmentHeader."No.", OrangeLocation);
    end;

    [Normal]
    local procedure ValidateWorksheetLinesWithShipmentLines(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        GetLatestWhseWorksheetLines(WarehouseShipmentHeader, WhseWorksheetLine);
        Assert.AreEqual(WhseWorksheetLine.Count, WarehouseShipmentLine.Count,
          ERR_ShipmentAndWorksheetLinesNotEqual + ' ' + WarehouseShipmentHeader."No.");
        repeat
            Assert.AreEqual(WhseWorksheetLine."Source Line No.", WarehouseShipmentLine."Source Line No.",
              ERR_SourceLineNoMismatchedInShipmentLineAndWorksheetLine + ' ' + WarehouseShipmentHeader."No.");
            WarehouseShipmentLine.Next();
        until WhseWorksheetLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('HandleStrMenu')]
    [Scope('OnPrem')]
    procedure AssertErrorPostAfterRelease()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServHeader, ServiceLine, ServiceItemLine, 1);
        // validate
        asserterror ServPostYesNo.PostDocumentWithLines(ServHeader, ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineGeneralProductPostingGroup()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServiceHeader, ServiceLine, ServiceItemLine, 1);
        // validate
        asserterror ServiceLine.Validate("Gen. Prod. Posting Group", CreateNewGenProductPostingGroup());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineJobRemainQuantity()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServHeader, ServiceLine, ServiceItemLine, 1);
        // validate
        asserterror ServiceLine.Validate("Job Remaining Qty.", (ServiceLine."Job Remaining Qty." - 1.0));
        asserterror ServiceLine.Validate("Job Remaining Qty.", (ServiceLine."Job Remaining Qty." + 1.0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineAllowInvoiceDiscount()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServHeader, ServiceLine, ServiceItemLine, 1);
        // validate
        asserterror ServiceLine.Validate("Allow Invoice Disc.", (not ServiceLine."Allow Invoice Disc."));
    end;

    [Test]
    [HandlerFunctions('HandleServiceLinePageLineDiscountPct')]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineLineDiscountPercent()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceOrderTestPage: TestPage "Service Order";
    begin
        // Setup
        Initialize();
        CreateAndReleaseServiceOrder(ServHeader, ServiceLine, ServiceItemLine, 1);
        // Execute
        ServiceOrderTestPage.OpenEdit();
        ServiceOrderTestPage.GotoRecord(ServHeader);
        // validate
        ServiceOrderTestPage.ServItemLines."Service Lines".Invoke();
        ServiceOrderTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineLineDiscountAmount()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServHeader, ServiceLine, ServiceItemLine, 1);
        // validate
        asserterror ServiceLine.Validate("Line Discount Amount", (10 + ServiceLine."Line Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineLocation()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Location: Record Location;
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServiceHeader, ServiceLine, ServiceItemLine, 1);
        Location.SetFilter(Code, '<>%1', ServiceLine."Location Code");
        Location.FindFirst();
        // validate
        asserterror ServiceLine.Validate("Location Code", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineNeedByDate()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        NeedDate: Date;
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServHeader, ServiceLine, ServiceItemLine, 1);
        NeedDate := ServiceLine."Needed by Date";
        // validate
        if NeedDate <> 0D then
            asserterror
              ServiceLine.Validate("Needed by Date", CalcDate('<+6M>', NeedDate))
        else
            asserterror ServiceLine.Validate("Needed by Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineNo()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServiceHeader, ServiceLine, ServiceItemLine, 1);
        // validate
        asserterror ServiceLine.Validate("No.", LibraryInventory.CreateItemNo());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLinePlanDeliveryDate()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        PlanDate: Date;
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServHeader, ServiceLine, ServiceItemLine, 1);
        PlanDate := ServiceLine."Planned Delivery Date";
        // validate
        if PlanDate <> 0D then
            asserterror
              ServiceLine.Validate("Planned Delivery Date", CalcDate('<+6M>', PlanDate))
        else
            asserterror ServiceLine.Validate("Planned Delivery Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineQuantity()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServHeader, ServiceLine, ServiceItemLine, 1);
        // validate
        asserterror ServiceLine.Validate(Quantity, (ServiceLine.Quantity + 1.0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineQuantityWarehouseShipment()
    var
        ServHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreateWhseShptReopenOrder(ServHeader, ServiceLine);
        // validate
        asserterror ServiceLine.Validate(Quantity, (ServiceLine.Quantity + 1.0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineQuantityInvoice()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServHeader, ServiceLine, ServiceItemLine, 1);
        // validate
        asserterror ServiceLine.Validate("Qty. to Invoice", (ServiceLine."Qty. to Invoice" + 1.0));
    end;

    [Test]
    [HandlerFunctions('HandleServiceLinePageQtyToShip')]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineQuantityShip()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceOrderTestPage: TestPage "Service Order";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServHeader, ServiceLine, ServiceItemLine, 1);
        ServiceOrderTestPage.OpenNew();
        ServiceOrderTestPage.GotoRecord(ServHeader);
        // validate
        ServiceOrderTestPage.ServItemLines."Service Lines".Invoke();
        ServiceOrderTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineType()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServHeader, ServiceLine, ServiceItemLine, 1);
        Commit();
        // validate
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::Resource);
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::Cost);
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::"G/L Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineTypeWarehouseShipment()
    var
        ServHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Setup
        Initialize();
        // Execute
        CreateWhseShptReopenOrder(ServHeader, ServiceLine);
        Commit();
        // validate
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::Resource);
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::Cost);
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::"G/L Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineUOMCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServiceHeader, ServiceLine, ServiceItemLine, 1);
        ItemUOM.SetRange("Item No.", ServiceLine."No.");
        ItemUOM.SetFilter(Code, '<>%1', ServiceLine."Unit of Measure Code");
        // validate
        if ItemUOM.FindFirst() then
            asserterror ServiceLine.Validate("Unit of Measure Code", ItemUOM.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineCodeWarehouseShipment()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
    begin
        // Setup
        Initialize();
        // Execute
        CreateWhseShptReopenOrder(ServiceHeader, ServiceLine);
        ItemUOM.SetRange("Item No.", ServiceLine."No.");
        ItemUOM.SetFilter(Code, '<>%1', ServiceLine."Unit of Measure Code");
        // validate
        if ItemUOM.FindFirst() then
            asserterror ServiceLine.Validate("Unit of Measure Code", ItemUOM.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineVariantCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemVariant: Record "Item Variant";
    begin
        // Setup
        Initialize();
        // Execute
        CreateAndReleaseServiceOrder(ServiceHeader, ServiceLine, ServiceItemLine, 1);
        ItemVariant.SetRange("Item No.", ServiceLine."No.");
        ItemVariant.SetFilter(Code, '<>%1', ServiceLine."Variant Code");
        // validate
        if ItemVariant.FindFirst() then
            asserterror ServiceLine.Validate("Variant Code", ItemVariant.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineVariantCodeWarehouseShipment()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemVariant: Record "Item Variant";
    begin
        // Setup
        Initialize();
        // Execute
        CreateWhseShptReopenOrder(ServiceHeader, ServiceLine);
        ItemVariant.SetRange("Item No.", ServiceLine."No.");
        ItemVariant.SetFilter(Code, '<>%1', ServiceLine."Variant Code");
        // validate
        if ItemVariant.FindFirst() then
            asserterror ServiceLine.Validate("Variant Code", ItemVariant.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOrangeNonItemLines()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post a Service Invoice on ORANGE Location with lines of type not item.
        TestPostServiceDocumentWithNonItemLines(OrangeLocation, ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoOrangeNonItemLines()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post a Service Credit Memo on ORANGE Location with lines of type not item.
        TestPostServiceDocumentWithNonItemLines(OrangeLocation, ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOrangeWithItemEmptyBinCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // Post service invoice for an Item with empty bin code for an item in stock
        asserterror TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::Invoice, 1, true);
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Bin Code"), '');
    end;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOrangeWithItemInStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service invoice for an Item with empty bin code
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::Invoice, 1, false);
    end;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOrangeWithItemOutOfStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service invoice for an Item with empty bin code
        asserterror TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::Invoice, -1, false);
        Assert.IsTrue(StrPos(GetLastErrorText, QuantityInsufficientErrorTxt) > 0, QuantityInsufficientErrorTxt);
    end;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [Scope('OnPrem')]
    procedure PostServiceCrMemoOrangeWithItemEmptyBinCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // Post service Credit Memo for an Item with empty bin code for an item in stock
        asserterror TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::"Credit Memo", 1, true);
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Bin Code"), '');
    end;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [Scope('OnPrem')]
    procedure PostServiceCrMemoOrangeWithItemInStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service Credit Memo for an Item with empty bin code
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::"Credit Memo", 1, false);
    end;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [Scope('OnPrem')]
    procedure PostServiceCrMemoOrangeWithItemOutOfStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service Credit Memo for an Item with empty bin code
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::"Credit Memo", -1, false);
    end;

    [Normal]
    local procedure AddItemServiceLinesToHeader(var ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer; ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Integer
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        UpdateServiceLine(ServiceLine, ServiceItemLineNo, ItemQuantity);
        ServiceLine.SetHideReplacementDialog(true);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Modify();
        exit(ServiceLine."Line No.");
    end;

    [Normal]
    local procedure AddNonItemServiceLinesToDocument(var ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
    begin
        CreateAndUpdateServiceLines(ServiceLine, ServiceHeader, ServiceItemLineNo,
          ServiceLine.Type::Resource, LibraryResource.CreateResourceNo(), LibraryRandom.RandInt(100));

        CreateAndUpdateServiceLines(ServiceLine, ServiceHeader, ServiceItemLineNo,
          ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));

        LibraryService.FindServiceCost(ServiceCost);
        CreateAndUpdateServiceLines(ServiceLine, ServiceHeader, ServiceItemLineNo,
          ServiceLine.Type::Cost, ServiceCost.Code, LibraryRandom.RandInt(100));
    end;

    [Normal]
    local procedure CreateAndUpdateServiceLines(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer; ServiceLineType: Enum "Service Line Type"; No: Code[20]; LineQuantity: Integer)
    begin
        Clear(ServiceLine);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLineType, No);
        UpdateServiceLine(ServiceLine, ServiceItemLineNo, LineQuantity);
    end;

    [Normal]
    local procedure CreateBin(var Bin: Record Bin; Locationcode: Code[10]; "Code": Code[10])
    begin
        Clear(Bin);
        Bin.Init();
        Bin.Validate("Location Code", Locationcode);
        Bin.Validate(Code, Code);
        Bin.Validate(Empty, true);
        Bin.Insert(true);
    end;

    local procedure CreateOrangeLocation(): Code[10]
    var
        Location: Record Location;
        Bin: Record Bin;
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        Location.Validate("Use Put-away Worksheet", false);
        Location.Validate("Directed Put-away and Pick", false);
        Location.Validate("Use ADCS", false);
        Location.Validate("Default Bin Selection", Location."Default Bin Selection"::"Fixed Bin");

        CreateBin(Bin, Location.Code, REC);
        Location.Validate("Receipt Bin Code", Bin.Code);
        CreateBin(Bin, Location.Code, SHIP);
        Location.Validate("Shipment Bin Code", Bin.Code);
        CreateBin(Bin, Location.Code, PICKPUT);
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        CreateWhseWorksheetName(WhseWorksheetName, Location.Code);
        WkshName := WhseWorksheetName.Name;
        exit(Location.Code);
    end;

    [Normal]
    local procedure CreateNewGenProductPostingGroup(): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VatProductPostingGroup: Record "VAT Product Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        VatProductPostingGroup.FindFirst();
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := VatProductPostingGroup.Code;
        GenProductPostingGroup."Auto Insert Default" := true;
        GenProductPostingGroup.Modify(true);
        exit(GenProductPostingGroup.Code);
    end;

    [Normal]
    local procedure CreatePickWorksheet(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; NumberOfServLines: Integer)
    begin
        // release warehouse shipment and create pick worksheet again
        CreateAndReleaseWhseShipment(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, NumberOfServLines);
        InvokeGetWarehouseDocument();
    end;

    [Normal]
    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceItemLine: Record "Service Item Line"; NumberOfServLines: Integer)
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        CustomerNo: Code[20];
        LineCount: Integer;
    begin
        if NumberOfServLines <= 0 then
            exit;
        LibraryInventory.CreateItem(Item);
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateServiceItem(ServiceItem, CustomerNo, Item."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem);
        // creating multiple service lines
        if NumberOfServLines > 1 then begin
            CreateServiceItem(ServiceItem, CustomerNo, Item."No.");
            Clear(ServiceItemLine);
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
            for LineCount := 2 to NumberOfServLines do
                CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem);
        end;
        Clear(ServiceLine);
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.Find('-');
    end;

    local procedure CreateAndReleaseServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceItemLine: Record "Service Item Line"; NumberOfServLines: Integer)
    begin
        CreateServiceOrder(ServiceHeader, ServiceLine, ServiceItemLine, NumberOfServLines);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
    end;

    [Normal]
    local procedure CreateAndReleaseWhseShipment(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; NumberOfServLines: Integer)
    var
        WhseShptRelease: Codeunit "Whse.-Shipment Release";
    begin
        CreateWarehouseShipment(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, NumberOfServLines);
        WhseShptRelease.Release(WarehouseShipmentHeader);
    end;

    [Normal]
    local procedure CreateWarehouseShipment(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; NumberOfServLines: Integer)
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        CreateAndReleaseServiceOrder(ServiceHeader, ServiceLine, ServiceItemLine, NumberOfServLines);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);
        WarehouseShipmentHeader.FindLast();
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
    end;

    [Normal]
    local procedure CreateWhseShptReopenOrder(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        CreateAndReleaseServiceOrder(ServiceHeader, ServiceLine, ServiceItemLine, 2);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);
        LibraryService.ReopenServiceDocument(ServiceHeader);
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        Clear(ServiceItem);
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", ItemNo);
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceDocumentWithServiceLine(var ServiceHeader: Record "Service Header"; ServiceDocumentType: Enum "Service Document Type"; ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10])
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceDocumentType, Customer."No.");
        ServiceHeader.Validate("Location Code", LocationCode);
        ServiceHeader.Modify(true);
        AddItemServiceLinesToHeader(ServiceHeader, 0, ItemNo, ItemQuantity, LocationCode);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item")
    var
        Item: Record Item;
    begin
        Clear(ServiceLine);
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random For Quantity and Quantity to Consume.
        ServiceLine.Validate("Location Code", OrangeLocation);
        ServiceLine.Modify(true);
    end;

    local procedure CreateWhseWorksheetName(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Pick);
        WhseWorksheetTemplate.FindFirst();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    [Normal]
    local procedure DeleteExistingWhsWorksheetPickLines()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange("Page ID", PAGE::"Pick Worksheet");
        Assert.AreEqual(1, WhseWorksheetTemplate.Count, StrSubstNo(ERR_MultipleWhseWorksheetTemplate, PickWorksheetPage));
        if WhseWorksheetTemplate.FindFirst() then begin
            WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplate.Name);
            WhseWorksheetLine.DeleteAll();
        end;
    end;

    [Normal]
    local procedure FindFirstServiceLineByServiceHeader(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
    end;

    local procedure FindServiceCreditMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; PreAssignedNo: Code[20])
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
    end;

    local procedure FindServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; PreAssignedNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceInvoiceHeader.FindFirst();
    end;

    [Normal]
    local procedure GetWarehouseEntries(var ServiceLine: Record "Service Line"; var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option)
    begin
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"Serv. Order");
        WarehouseEntry.SetRange("Source No.", ServiceLine."Document No.");
        WarehouseEntry.SetRange("Source Line No.", ServiceLine."Line No.");
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.FindSet();
    end;

    [Normal]
    local procedure GetLatestWhseWorksheetLines(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
        WhseWorksheetLine.SetRange("Whse. Document Type", WhseWorksheetLine."Whse. Document Type"::Shipment);
        WhseWorksheetLine.SetRange("Whse. Document No.", WarehouseShipmentHeader."No.");
        WhseWorksheetLine.Find('-');
    end;

    [Normal]
    local procedure RANDOMRANGE(RangeMin: Integer; RangeMax: Integer): Integer
    begin
        // Method returns a random value within a range
        Assert.IsTrue(RangeMax >= RangeMin, 'Range is Valid');
        exit(LibraryRandom.RandIntInRange(RangeMin, RangeMax));
    end;

    local procedure SaveServiceLineInTempTable(var TempServiceLine: Record "Service Line" temporary; ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer; ItemQuantity: Integer)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, ItemQuantity);  // Use Random to select Random Quantity.
        ServiceLine.Modify(true);
    end;

    [Normal]
    local procedure TestPostServiceDocumentWithNonItemLines(LocationCode: Code[10]; ServiceDocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        Customer: Record Customer;
    begin
        // Setup: Create a service invoice with service lines of type resource, gl and cost
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceDocumentType, Customer."No.");
        ServiceHeader.Validate("Location Code", LocationCode);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        AddNonItemServiceLinesToDocument(ServiceHeader, 0);

        // EXECUTE: Post the Service Header
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // VERIFY: The Header has been posted
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::Invoice then
            FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.")
        else
            FindServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
    end;

    [Normal]
    local procedure TestPostServiceDocumentWithItem(ServiceDocumentType: Enum "Service Document Type"; LineQuantityDelta: Integer; IsBlankBincode: Boolean)
    var
        Item: Record Item;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseEntry: Record "Warehouse Entry";
        TempServiceLine: Record "Service Line" temporary;
        Quantity: Integer;
        LineQuantity: Integer;
        LocationCode: Code[10];
        BinCode: Code[20];
    begin
        // PARAM: LineQuantityDelta: Quantity to subtract from the supply quantity set on the line
        // PARAM: IsBlankBincode: Set Bin code ot blank in the service line

        // SETUP: Create an new location, create a new item.
        // SETUP: Create Supply for that item in the specific location and bin.
        Quantity := RANDOMRANGE(2, 100);
        LineQuantity := Quantity - LineQuantityDelta;

        LocationCode := OrangeLocation;
        BinCode := '';
        if not IsBlankBincode then begin
            Location.Get(LocationCode);
            BinCode := Location."Default Bin Code";
        end;

        LibraryInventory.CreateItem(Item);

        // EXECUTE: Create Service Document on the Location.
        CreateServiceDocumentWithServiceLine(ServiceHeader, ServiceDocumentType, Item."No.", Quantity, LocationCode);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        ReceiveItemStockInWarehouse(ServiceLine);
        ServiceLine.Validate(Quantity, LineQuantity);
        ServiceLine.Validate("Bin Code", BinCode);
        ServiceLine.Modify(true);

        // VERIFY: Service Document has been posted
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        if ServiceDocumentType = ServiceHeader."Document Type"::Invoice then begin
            VerifyQtyOnItemLedgerEntry(TempServiceLine, LineQuantity);
            GetAndVerifyWarehouseEntry(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.", -ServiceLine.Quantity);
        end else begin
            VerifyQtyOnItemLedgerEntry(TempServiceLine, -LineQuantity);
            GetAndVerifyWarehouseEntry(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.", ServiceLine.Quantity);
        end;
        Assert.AreEqual(WarehouseEntry.Count, 1, 'No. of warehouse entries created');
        WarehouseEntry.TestField("Bin Code", BinCode);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HandleMessage(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandlePickSelectionPage(var PickSelectionTestPage: TestPage "Pick Selection")
    begin
        PickSelectionTestPage.Last();
        PickSelectionTestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure HandleRequestPageCreatePick(var CreatePickTestPage: TestRequestPage "Create Pick")
    begin
        CreatePickTestPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleModalWhsWkshName(var WorksheetNames: TestPage "Worksheet Names List")
    begin
        WorksheetNames.FILTER.SetFilter("Location Code", OrangeLocation);
        WorksheetNames.FILTER.SetFilter(Name, WkshName);
        WorksheetNames.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure HandleStrMenu(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        // Select the ship option
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleServiceLinePageLineDiscountPct(var ServiceLinesPage: TestPage "Service Lines")
    var
        Disc: Decimal;
    begin
        if ServiceLinesPage."Line Discount %".Value = '' then
            Disc := 0
        else
            Evaluate(Disc, ServiceLinesPage."Line Discount %".Value);
        asserterror ServiceLinesPage."Line Discount %".SetValue(99.55 - Disc);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleServiceLinePageQtyToShip(var ServiceLinesPage: TestPage "Service Lines")
    var
        QtyToShip: Decimal;
    begin
        if ServiceLinesPage."Qty. to Ship".Value = '' then
            QtyToShip := 0
        else
            Evaluate(QtyToShip, ServiceLinesPage."Qty. to Ship".Value);
        asserterror ServiceLinesPage."Qty. to Ship".SetValue(1 + QtyToShip);
    end;

    local procedure Initialize()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Order Warehouse Orange");
        Clear(ErrorMessage);
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Order Warehouse Orange");

        LibraryERMCountryData.CreateVATData();
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        OrangeLocation := CreateOrangeLocation();
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.SetRange(Default, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, OrangeLocation, (not WarehouseEmployee.FindFirst()));
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Order Warehouse Orange");
    end;

    [Normal]
    local procedure InvokeGetWarehouseDocument()
    var
        PickWorksheetTestPage: TestPage "Pick Worksheet";
    begin
        PickWorksheetTestPage.Trap();
        PickWorksheetTestPage.OpenEdit();
        PickWorksheetTestPage.CurrentWkshName.Lookup();
        PickWorksheetTestPage."Get Warehouse Documents".Invoke();
        PickWorksheetTestPage.Close();
    end;

    [Normal]
    local procedure ReceiveItemStockInWarehouse(var ServiceLine: Record "Service Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        repeat
            Clear(PurchaseLine);
            if ServiceLine.Type = ServiceLine.Type::Item then begin
                LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ServiceLine."No.", ServiceLine.Quantity);
                PurchaseLine.Validate("Location Code", ServiceLine."Location Code");
                PurchaseLine.Modify(true);
            end;
        until ServiceLine.Next() <= 0;

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WhseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Put-away");
        WhseActivityLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseActivityLine.Find('-');
        Location.Get(OrangeLocation);
        repeat
            if WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Place then begin
                WhseActivityLine.Validate("Bin Code", Location."Default Bin Code");
                WhseActivityLine.Modify(true);
            end;
        until WhseActivityLine.Next() <= 0;
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Register (Yes/No)", WhseActivityLine);
    end;

    local procedure VerifyQtyOnItemLedgerEntry(var TempServiceLineBeforePosting: Record "Service Line" temporary; QuantityShipped: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify that the value of the field Quantity of the Item Ledger Entry is equal to the value of the field Qty. to Ship of the
        // relevant Service Line.
        TempServiceLineBeforePosting.FindSet();
        if TempServiceLineBeforePosting."Document Type"::"Credit Memo" = TempServiceLineBeforePosting."Document Type" then
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Credit Memo")
        else
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");

        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Service);
        ItemLedgerEntry.SetRange("Order No.", TempServiceLineBeforePosting."Document No.");
        repeat
            ItemLedgerEntry.SetRange("Document Line No.", TempServiceLineBeforePosting."Line No.");
            ItemLedgerEntry.FindLast();  // Find the Item Ledger Entry for the second action.
            ItemLedgerEntry.TestField(Quantity, -QuantityShipped);
        until TempServiceLineBeforePosting.Next() = 0;
    end;

    local procedure GetAndVerifyWarehouseEntry(var ServiceLine: Record "Service Line"; var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option; QuantityPosted: Decimal)
    begin
        Clear(WarehouseEntry);
        GetWarehouseEntries(ServiceLine, WarehouseEntry, EntryType);
        VerifyWarehouseEntry(ServiceLine, WarehouseEntry, EntryType, QuantityPosted);
    end;

    local procedure VerifyWarehouseEntry(var ServiceLine: Record "Service Line"; var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option; QuantityPosted: Decimal)
    begin
        WarehouseEntry.TestField("Location Code", ServiceLine."Location Code");
        WarehouseEntry.TestField("Item No.", ServiceLine."No.");
        WarehouseEntry.TestField(Quantity, QuantityPosted);
        WarehouseEntry.TestField("Qty. (Base)", QuantityPosted);
        WarehouseEntry.TestField("Entry Type", EntryType);
    end;
}

