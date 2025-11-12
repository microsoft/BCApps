// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Warehouse.Request;
using Microsoft.Service.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Service.Item;
using Microsoft.Service.History;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.History;
using System.TestLibraries.Utilities;

codeunit 136144 "Service Order Warehouse Pick"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Pick] [Service]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        ERR_ShipmentAndWorksheetLinesNotEqual: Label 'Number of shipment lines are not equal to number of worksheet lines added for warehouse shipment';
        ERR_SourceLineNoMismatchedInShipmentLineAndWorksheetLine: Label '"Source Line No." of shipment line is different from that of worksheet line for warehouse shipment';
        ERR_NoWorksheetLinesCreated: Label 'There are no Warehouse Worksheet Lines created.';
        ErrorMessage: Text[1024];
        ERR_MultipleWhseWorksheetTemplate: Label 'There exist multiple warehouse worksheet templates for page %1.';
        ERR_Unexpected: Label 'Unexpected error.';
        PickWorksheetPage: Label 'Pick Worksheet';

    [Test]
    [HandlerFunctions('HandleRequestPageCreatePick,HandleConfirm,HandleMessage,HandlePickSelectionPage')]
    [Scope('OnPrem')]
    procedure TestPickWorksheetCreatePick()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        DeleteExistingWhsWorksheetPickLines();
        CreatePickWorksheet(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, 1);
        ReceiveItemStockInWarehouse(ServiceLine, GetWhiteLocation());
        Commit();
        GetLatestWhseWorksheetLines(WarehouseShipmentHeader, WhseWorksheetLine);
        repeat
            WhseWorksheetLine.Validate("Qty. to Handle", WhseWorksheetLine.Quantity);
            WhseWorksheetLine.Modify(true);
        until WhseWorksheetLine.Next() <= 0;
        Commit();
        CODEUNIT.Run(CODEUNIT::"Whse. Create Pick", WhseWorksheetLine);
    end;

    [Test]
    [HandlerFunctions('HandlePickSelectionPage')]
    [Scope('OnPrem')]
    procedure TestErrorOnRecreatingPickWorksheet()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreatePickWorksheet(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, 3);
        asserterror InvokeGetWarehouseDocument();
        ErrorMessage := ERR_NoWorksheetLinesCreated;
        Assert.AreEqual(ErrorMessage, GetLastErrorText, ERR_Unexpected);
    end;

    [Test]
    [HandlerFunctions('HandlePickSelectionPage')]
    [Scope('OnPrem')]
    procedure TestPickWorksheetGetWarehouseDocuments()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreatePickWorksheet(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, 3);
        ValidateWorksheetLinesWithShipmentLines(WarehouseShipmentHeader, WarehouseShipmentLine);
    end;

    [Test]
    [HandlerFunctions('HandlePickSelectionPage')]
    [Scope('OnPrem')]
    procedure TestPickWkshtGetWhseDocumentsOnReopenEditRelease()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShptRelease: Codeunit "Whse.-Shipment Release";
    begin
        CreatePickWorksheet(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, 4);
        // reopen service order, add new lines and release again
        LibraryService.ReopenServiceDocument(ServiceHeader);
        CreateServiceItem(ServiceItem, ServiceHeader."Customer No.", LibraryInventory.CreateItemNo());
        Clear(ServiceItemLine);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem);
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
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
        CreateAndReleaseWhseShipment(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, 3);
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Shipment, WhsePickRequest."Document Subtype"::"0", WarehouseShipmentHeader."No.", GetWhiteLocation());
    end;

    [Test]
    [HandlerFunctions('HandleRequestPageCreatePick,HandleConfirm,HandleMessage,HandlePickSelectionPage,ServiceShipmentModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSourceDocumentLinksToServiceShipment()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShipment: TestPage "Posted Whse. Shipment";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        // [SCENARIO 582403] Posted Source Document of a Service Order incorrectly links to a blank Posted Sales Shipment instead of the expected Posted Service Shipment

        // [GIVEN] A service order is created with warehouse location
        DeleteExistingWhsWorksheetPickLines();
        CreatePickWorksheet(ServiceHeader, ServiceLine, WarehouseShipmentHeader, WarehouseShipmentLine, 1);
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        ReceiveItemStockInWarehouse(ServiceLine, GetWhiteLocation());
        Commit();
        GetLatestWhseWorksheetLines(WarehouseShipmentHeader, WhseWorksheetLine);
        repeat
            WhseWorksheetLine.Validate("Qty. to Handle", WhseWorksheetLine.Quantity);
            WhseWorksheetLine.Modify(true);
        until WhseWorksheetLine.Next() <= 0;
        Commit();

        // [GIVEN] Create Warehouse pick document.
        Codeunit.Run(Codeunit::"Whse. Create Pick", WhseWorksheetLine);

        // [GIVEN] The warehouse pick is registered from the page
        RegisterWarehousePickFromPage(ServiceHeader."No.", GetWhiteLocation(), true);

        // [WHEN] The warehouse shipment is posted as ship
        WhsePostShipment.SetPostingSettings(false); // Post as ship: Invoice = FALSE
        WhsePostShipment.Run(WarehouseShipmentLine);

        // [THEN] A posted warehouse shipment header is created
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", WarehouseShipmentLine."No.");
        Assert.IsTrue(PostedWhseShipmentHeader.FindFirst(), 'Posted Whse Shipment Header should exist');

        // [THEN] Verify A posted warehouse shipment source document is opening the Posted Service Shipment page
        // Verification is done in ModalPageHandler
        PostedWhseShipment.OpenView();
        PostedWhseShipment.GoToRecord(PostedWhseShipmentHeader);
        PostedWhseShipment.WhseShptLines."Posted Source Document".Invoke();
    end;

    local procedure RegisterWarehousePickFromPage(ServiceOrderNo: Code[20]; LocationCode: Code[10]; AutoFillQtyToHandle: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePickPage: TestPage "Warehouse Pick";
    begin
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Service Order");
        WarehouseActivityLine.SetRange("Source No.", ServiceOrderNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        WarehousePickPage.OpenEdit();
        WarehousePickPage.GoToRecord(WarehouseActivityHeader);
        if AutoFillQtyToHandle then
            WarehousePickPage."Autofill Qty. to Handle".Invoke();
        WarehousePickPage.RegisterPick.Invoke(); //Needs confirmation handler
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
        LineCount: Integer;
    begin
        if NumberOfServLines <= 0 then
            exit;
        LibraryInventory.CreateItem(Item);
        CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo(), Item."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem);
        // creating multiple service lines
        if NumberOfServLines > 1 then begin
            CreateServiceItem(ServiceItem, ServiceItem."Customer No.", Item."No.");
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
        Initialize();
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

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        Clear(ServiceItem);
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", ItemNo);
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item")
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        Clear(ServiceLine);
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random For Quantity and Quantity to Consume.
        ServiceLine.Validate("Location Code", GetWhiteLocation());
        ServiceLine.Modify(true);
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
    local procedure GetLatestWhseWorksheetLines(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
        WhseWorksheetLine.SetRange("Whse. Document Type", WhseWorksheetLine."Whse. Document Type"::Shipment);
        WhseWorksheetLine.SetRange("Whse. Document No.", WarehouseShipmentHeader."No.");
        WhseWorksheetLine.Find('-');
    end;

    [Normal]
    local procedure GetWhiteLocation(): Code[10]
    var
        LocationWhite: Record Location;
    begin
        LocationWhite.SetRange("Directed Put-away and Pick", true);
        LocationWhite.FindFirst();
        exit(LocationWhite.Code);
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
    procedure ServiceShipmentModalPageHandler(var PostedServiceShipment: TestPage "Posted Service Shipment")
    var
        ServiceOrderNo: Code[20];
    begin
        ServiceOrderNo := LibraryVariableStorage.DequeueText();
        PostedServiceShipment."Order No.".AssertEquals(ServiceOrderNo);
    end;

    local procedure Initialize()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Order Warehouse Pick");
        Clear(ErrorMessage);
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Order Warehouse Pick");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, GetWhiteLocation(), true);
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Order Warehouse Pick");
    end;

    [Normal]
    local procedure InvokeGetWarehouseDocument()
    var
        PickWorksheetTestPage: TestPage "Pick Worksheet";
    begin
        PickWorksheetTestPage.Trap();
        PickWorksheetTestPage.OpenEdit();
        PickWorksheetTestPage."Get Warehouse Documents".Invoke();
        PickWorksheetTestPage.Close();
    end;

    [Normal]
    local procedure ReceiveItemStockInWarehouse(var ServiceLine: Record "Service Line"; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
        WarehouseReceipt: TestPage "Warehouse Receipt";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        repeat
            Clear(PurchaseLine);
            if ServiceLine.Type = ServiceLine.Type::Item then begin
                LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ServiceLine."No.", ServiceLine.Quantity);
                PurchaseLine.Validate("Location Code", LocationCode);
                PurchaseLine.Modify(true);
            end;
        until ServiceLine.Next() <= 0;

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        WarehouseReceipt.Trap();
        GetSourceDocInbound.CreateFromPurchOrder(PurchaseHeader);
        WarehouseReceipt."Post Receipt".Invoke();
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Put-away");
        WhseActivityLine.FindLast();
        WhseActivityLine.SetRange("No.", WhseActivityLine."No.");
        WhseActivityLine.SetRange(Breakbulk);
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Register (Yes/No)", WhseActivityLine);
    end;
}

