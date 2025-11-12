// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Pricing;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Utilities;

codeunit 136140 "Service Order Release"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Order] [Status] [Service]
        IsInitialized := false;
    end;

    var
        NothingToReleaseErr: Label 'There is nothing to release for Order %1.';
        WarehouseShipmentMsg: Label '%1 Warehouse Shipment Header has been created.';
        NoWarehouseShipmentsErr: Label 'There are no warehouse shipment lines created.';
        WarehouseshipmentExistsErr: Label 'The Service Line cannot be deleted when a related Warehouse Shipment Line exists.';
        ServiceOrderInGridTxt: Label 'Service Order';
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ShipmentConfirmationMessage: Text[1024];
        WMSFullLocation: Code[10];
        SourceDocumentNo: Code[20];
        SourceDocumentType: Text[200];
        YellowLocationCode: Code[10];
        QuantityInsufficientErrorTxt: Label 'Quantity (Base) is not sufficient to complete this action. The quantity in the bin is';
        ServiceOrderShipmentErr: Label 'This order must be a complete Shipment.';
        DescriptionTxt: Label 'Test Description.';
        VerifyDisplayedErrorMsg: Label 'Verify displayed error message';

    local procedure ClearGlobals()
    begin
        ShipmentConfirmationMessage := '';
        SourceDocumentNo := '';
        SourceDocumentType := '';
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReReleaseServiceOrder()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Setup: Create a Released service order with service lines
        CreateServiceOrderWithServiceLines(ServiceHeader);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // Execute: Release to Ship a service order released to hip
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // Verify: Status for relased orders are set properly.
        VerifyServiceHeaderReleaseStatus(ServiceHeader, ServiceHeader."Release Status"::"Released to Ship", ServiceHeader.Status::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteReleaseServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceHeaderNo: Code[20];
    begin
        Initialize();

        // Setup: Create a service order with service lines
        CreateServiceOrderWithServiceLines(ServiceHeader);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        LibraryService.ReopenServiceDocument(ServiceHeader);

        // Execute: Delete a Released Order
        ServiceHeaderNo := ServiceHeader."No.";
        ServiceHeader.Delete();

        // Verify: Delete has succeeded.
        Assert.AreEqual(false, ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeaderNo), 'Unable to fetch record after delete');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteReopenedServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceHeaderNo: Code[20];
    begin
        Initialize();

        // Setup: Create a service order with service lines
        CreateServiceOrderWithServiceLines(ServiceHeader);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // Execute: Delete a Released Order
        ServiceHeaderNo := ServiceHeader."No.";
        ServiceHeader.Delete();

        // Verify: Delete has succeeded.
        Assert.AreEqual(false, ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeaderNo), 'Unable to fetch record after delete');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseServiceOrderNoServiceLines()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Setup: Create a service order with service lines
        CreateServiceOrder(ServiceHeader);

        // Execute: Release service order to Ship
        asserterror LibraryService.ReleaseServiceDocument(ServiceHeader);

        // Verify: Status for relased orders are set properly, error messages are set correctly
        Assert.AreEqual(
          StrSubstNo(NothingToReleaseErr, ServiceHeader."No."),
          GetLastErrorText, 'Verify that error message is displayed when no service lines have been created');
        VerifyServiceHeaderReleaseStatus(ServiceHeader, ServiceHeader."Release Status"::Open, ServiceHeader.Status::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseServiceOrderMixedServiceLines()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLineNo: Integer;
    begin
        Initialize();

        // Setup: Create a service order with service lines of type, Item, Resource and G/L entry
        ServiceItemLineNo := CreateServiceOrderWithServiceLines(ServiceHeader);
        AddResourceGLServiceLinesToOrder(ServiceHeader, ServiceItemLineNo);

        // Execute: Release service order to Ship
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // Verify: Status for relased orders are set properly, error messages are set correctly
        VerifyServiceHeaderReleaseStatus(ServiceHeader, ServiceHeader."Release Status"::"Released to Ship", ServiceHeader.Status::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseServiceOrderNoItemServiceLines()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLineNo: Integer;
    begin
        Initialize();

        // Setup: Create a service order with only service lines of type, Resource and G/L entry
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader);
        AddResourceGLServiceLinesToOrder(ServiceHeader, ServiceItemLineNo);

        // Execute: Release service order to Ship
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // Verify: Status for relased orders are set properly, error messages are set correctly
        VerifyServiceHeaderReleaseStatus(ServiceHeader, ServiceHeader."Release Status"::"Released to Ship", ServiceHeader.Status::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseServiceOrderToShipZeroQuantity()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // Setup: Create a service order with service lines with quantity set to 0
        CreateServiceOrderWithServiceLines(ServiceHeader);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        ServiceLine.Validate(Quantity, 0);  // Use Random to select Random Quantity.
        ServiceLine.Modify(true);

        // Execute: Release service order to Ship verify error message is thrown.
        asserterror LibraryService.ReleaseServiceDocument(ServiceHeader);

        // Verify: Correct error message is thrown and Release Status are set properly.
        Assert.AreEqual(
          StrSubstNo(NothingToReleaseErr, ServiceHeader."No."), GetLastErrorText,
          'Verify that error message is displayed when no service lines have been created');
        VerifyServiceHeaderReleaseStatus(ServiceHeader, ServiceHeader."Release Status"::Open, ServiceHeader.Status::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditReopenedServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // Setup: Create a Released service order with service lines
        CreateServiceOrderWithServiceLines(ServiceHeader);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        LibraryService.ReopenServiceDocument(ServiceHeader);

        // EXECUTE: Modify quantity on the service lines
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        ServiceLine.Validate(Quantity, ServiceLine.Quantity - 1);  // Use Random to select Random Quantity.
        ServiceLine.Modify(true);

        // Verify: Status for relased orders are set properly.
        VerifyServiceHeaderReleaseStatus(ServiceHeader, ServiceHeader."Release Status"::Open, ServiceHeader.Status::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostReleasedServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        QuantityPosted: Integer;
    begin
        Initialize();

        // Setup: Create a service order with service lines and partially post it
        CreateServiceOrderWithServiceLines(ServiceHeader);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        ServiceLine.Validate(Quantity, LibraryRandom.RandIntInRange(2, 100));  // Use Random to select Random Quantity.

        QuantityPosted := LibraryRandom.RandIntInRange(1, ServiceLine.Quantity - 1);
        ServiceLine.Validate("Qty. to Ship", QuantityPosted);
        ServiceLine.Validate("Qty. to Invoice", ServiceLine."Qty. to Ship");
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Execute: Release service order to Ship.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // Verify: Status for relased orders are set properly.
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        Assert.AreEqual(QuantityPosted, ServiceLine."Quantity Shipped", 'Quantity shipped is not altered by release');
        Assert.AreEqual(QuantityPosted, ServiceLine."Quantity Invoiced", 'Quantity shipped is not altered by release');
        VerifyServiceHeaderReleaseStatus(ServiceHeader, ServiceHeader."Release Status"::"Released to Ship", ServiceHeader.Status::Pending);
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage')]
    [Scope('OnPrem')]
    procedure CreateWarehouseShipment()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        WarehouseShipment: TestPage "Warehouse Shipment";
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), WMSFullLocation);

        // EXECUTE: Create Warehouse shipment on this order
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        WarehouseShipment.Trap();

        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);

        // Verify: All service lines are present in warehouse shipment and the quantities match
        Assert.AreEqual(
          StrSubstNo(WarehouseShipmentMsg, 1), ShipmentConfirmationMessage, 'Confirmation message displayed on whse shpmnt creation');
        Assert.IsTrue(
          WarehouseShipmentHeader.Get(Format(WarehouseShipment."No.".Value())), 'Displayed warehouse shipment can be located');
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage')]
    [Scope('OnPrem')]
    procedure CreateWarehouseShipmentAllLineTypes()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        WarehouseShipment: TestPage "Warehouse Shipment";
        ServiceItemLineNo: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location
        LibraryInventory.CreateItem(Item);
        ServiceItemLineNo := CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), WMSFullLocation);
        AddResourceGLServiceLinesToOrder(ServiceHeader, ServiceItemLineNo);

        // EXECUTE: Create Warehouse shipment on this order
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        WarehouseShipment.Trap();
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);

        // Verify: All service lines are present in warehouse shipment and the quantities match
        Assert.IsTrue(
          WarehouseShipmentHeader.Get(Format(WarehouseShipment."No.".Value())), 'Displayed warehouse shipment can be located');
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWarehouseShipmentOpenOrder()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        Initialize();
        // SETUP: Create Service order on WHITE Location
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), WMSFullLocation);

        // EXECUTE: Create Warehouse shipment on this order
        asserterror CreateWarehouseShipmentFromServiceHeader(ServiceHeader);

        // VERIFY: Error is thrown when the order is not released
        Assert.ExpectedTestFieldError(ServiceHeader.FieldCaption("Release Status"), Format(ServiceHeader."Release Status"::Open));
        VerifyServiceHeaderReleaseStatus(ServiceHeader, ServiceHeader."Release Status"::Open, ServiceHeader.Status::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWarehouseShipmentTwice()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location, release and Create warehouse shipment
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), WMSFullLocation);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);

        // EXECUTE: Create Warehouse shipment again on this order
        asserterror CreateWarehouseShipmentFromServiceHeader(ServiceHeader);

        // VERIFY: No new shipments are created if no lines have been added
        Assert.AreEqual(Format(NoWarehouseShipmentsErr), GetLastErrorText, VerifyDisplayedErrorMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteEditAndReCreateWarehouseShipment()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        WarehouseShipmentHeaderNo: Code[20];
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location, release and Create warehouse shipment
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), WMSFullLocation);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);
        WarehouseShipmentHeaderNo :=
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
            DATABASE::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.");

        // EXECUTE: Delete and re-create Warehouse shipment on this order
        WarehouseShipmentHeader.Get(WarehouseShipmentHeaderNo);
        WarehouseShipmentHeader.Delete(true);
        Clear(WarehouseShipmentHeader);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);

        // VERIFY: new Warehouse shipments have been created
        WarehouseShipmentHeaderNo :=
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
            DATABASE::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.");
        Assert.IsTrue(
          WarehouseShipmentHeader.Get(WarehouseShipmentHeaderNo), 'Displayed warehouse shipment can be located');
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteServiceLineAfterCreateWarehouseShipment()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and create a whse shipment
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), WMSFullLocation);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);

        // EXECUTE: Delete the Service Line and Service Header
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);

        // VERIFY: Error message is thrown
        asserterror ServiceLine.Delete(true);
        Assert.ExpectedTestFieldError(ServiceHeader.FieldCaption("Release Status"), Format(ServiceHeader."Release Status"::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWarehouseShipmentReopenDeleteServiceLine()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and create a whse shipment
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), WMSFullLocation);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);

        // EXECUTE: Reopen the order and Delete the Service Line.
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        LibraryService.ReopenServiceDocument(ServiceHeader);
        asserterror ServiceLine.Delete(true);

        // VERIFY: Error message is thrown
        Assert.AreEqual(Format(WarehouseshipmentExistsErr),
          GetLastErrorText, 'Verify that error message is displayed when service line is deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteServiceHeaderAfterCreateWarehouseShipment()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and create a whse shipment
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), WMSFullLocation);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);

        // EXECUTE: Delete the Service Line
        asserterror ServiceHeader.Delete(true);

        // VERIFY: Error message is thrown
        Assert.ExpectedTestFieldError(ServiceHeader.FieldCaption("Release Status"), Format(ServiceHeader."Release Status"::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseSourceFilterForServiceLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        Initialize();

        // SETUP: Create Service order and Sales order on WHITE Location
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), WMSFullLocation);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", WMSFullLocation, LibraryRandom.RandInt(100), false);

        // EXECUTE: Create Warehouse shipment on this order
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, WMSFullLocation);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Validate("Service Orders", true);
        WarehouseSourceFilter.Validate("Sales Orders", false);
        WarehouseSourceFilter.Validate("Source No. Filter", ServiceHeader."No." + '|' + SalesHeader."No.");
        WarehouseSourceFilter.Modify(true);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, WMSFullLocation);

        // Verify: Whse shipments have been created and only service line has been pulled in
        GetWarehouseShipmentLinesByShipmentHeader(WarehouseShipmentLine, WarehouseShipmentHeader);
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        Assert.AreEqual(1, WarehouseShipmentLine.Count, 'Only one line has been pulled into the warehouse shipment');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure CreateWarehouseShipmentFromGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and Release Service Order
        LocationCode := WMSFullLocation;
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // EXECUTE: Create Warehouse shipment on this order using the get source document functionality.
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, WMSFullLocation);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // Verify: All service lines are present in warehouse shipment and the quantities match
        Assert.IsTrue(
          WarehouseShipmentHeader.Get(WarehouseShipmentHeader."No."), 'Displayed warehouse shipment can be located');
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullMultipleServiceOrdersUsingGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        ServiceHeaderNo: Code[20];
        LocationCode: Code[10];
    begin
        Initialize();

        // SETUP: Create 2 Service orders on WHITE Location and Release them.
        LocationCode := WMSFullLocation;
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        ServiceHeaderNo := ServiceHeader."No.";
        Clear(ServiceHeader);
        Clear(ServiceLine);
        Clear(Item);
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // EXECUTE: Create Warehouse shipment on both the orders
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeaderNo, ServiceOrderInGridTxt);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // VERIFY: Service lines from both orders are present in warehouse shipment and the quantities match.
        Assert.IsTrue(
          WarehouseShipmentHeader.Get(WarehouseShipmentHeader."No."), 'Displayed warehouse shipment can be located');
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);

        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeaderNo);
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);

        // VERIFY: Only 2 shipment lines have been added to the header.
        GetWarehouseShipmentLinesByShipmentHeader(WarehouseShipmentLine, WarehouseShipmentHeader);
        Assert.AreEqual(2, WarehouseShipmentLine.Count, 'No. of lines added to whse shipment is 2');
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullMultipleServiceLinesOn1OrderUsingGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        ServiceItemLineNo: Integer;
        LocationCode: Code[10];
        I: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location with several service lines(of Item) and Release Service Order
        LocationCode := WMSFullLocation;
        LibraryInventory.CreateItem(Item);
        ServiceItemLineNo := CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), LocationCode);
        AddResourceGLServiceLinesToOrder(ServiceHeader, ServiceItemLineNo);
        for I := 1 to 5 do begin
            Clear(Item);
            LibraryInventory.CreateItem(Item);
            AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LibraryRandom.RandInt(100), LocationCode);
        end;
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // EXECUTE: Create Warehouse shipment on this order using the get source document functionality.
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, WMSFullLocation);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // VERIFY: All service lines are present in warehouse shipment and the quantities match
        Assert.IsTrue(
          WarehouseShipmentHeader.Get(WarehouseShipmentHeader."No."), 'Displayed warehouse shipment can be located');
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullServiceLinesAddLinePullAgainUsingGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        ServiceItemLineNo: Integer;
        LocationCode: Code[10];
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location, Release and Pull the line into a new whse shipment
        LocationCode := WMSFullLocation;
        LibraryInventory.CreateItem(Item);
        ServiceItemLineNo := CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // EXECUTE: Reopen Service Order, Add Extra Service Line release and pull into same shipment again.
        Clear(Item);
        LibraryInventory.CreateItem(Item);
        LibraryService.ReopenServiceDocument(ServiceHeader);
        AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LibraryRandom.RandInt(100), LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // VERIFY: All service lines are present in warehouse shipment and the quantities match and the first line is not repeated
        Assert.IsTrue(
          WarehouseShipmentHeader.Get(WarehouseShipmentHeader."No."), 'Displayed warehouse shipment can be located');
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullServiceLinesToMultipleHeadersUsingGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        ServiceItemLineNo: Integer;
        LocationCode: Code[10];
        ServiceLineNo: Integer;
        WarehouseShipmentHeaderNo: Code[20];
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location, Release and Pull the line into a new whse shipment
        LocationCode := WMSFullLocation;
        LibraryInventory.CreateItem(Item);
        ServiceItemLineNo := CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        WarehouseShipmentHeaderNo := CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // EXECUTE: Reopen Service Order, Add Extra Service Line release and pull into a different shipment header.
        Clear(Item);
        Clear(WarehouseShipmentHeader);
        LibraryInventory.CreateItem(Item);
        LibraryService.ReopenServiceDocument(ServiceHeader);
        ServiceLineNo :=
          AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LibraryRandom.RandInt(100), LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // VERIFY: Second Shipment header has only the second service line pulled in.
        Assert.IsTrue(
          WarehouseShipmentHeader.Get(WarehouseShipmentHeader."No."), 'Displayed warehouse shipment can be located');
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        ServiceLine.SetFilter("Line No.", Format(ServiceLineNo));
        ServiceLine.FindSet();
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);

        // VERIFY: First shipment has only one line and has not been modifed.
        WarehouseShipmentHeader.Get(WarehouseShipmentHeaderNo);
        GetWarehouseShipmentLinesByShipmentHeader(WarehouseShipmentLine, WarehouseShipmentHeader);
        Assert.AreEqual(1, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match for the first shipment');
        ServiceLine.SetFilter("Line No.", '<>%1', ServiceLineNo);
        ServiceLine.FindSet();
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure Pull1ServiceLineToMultipleHeadersUsingGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LocationCode: Code[10];
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location, Release and Pull the line into a new whse shipment
        LocationCode := WMSFullLocation;
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // EXECUTE: Create new whse shipment header and try to pull the old service header.
        Clear(WarehouseShipmentHeader);
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        asserterror AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // VERIFY: Error message is displayed.
        Assert.AreEqual(Format(NoWarehouseShipmentsErr), GetLastErrorText, VerifyDisplayedErrorMsg);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullServiceLineDeleteAndPullWithGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location, Release and Pull the line into a new whse shipment
        LocationCode := WMSFullLocation;
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // EXECUTE: Delete The Warehouse shipment line and re-pull again.
        GetWarehouseShipmentLinesByShipmentHeader(WarehouseShipmentLine, WarehouseShipmentHeader);
        WarehouseShipmentLine.Delete(true);
        Clear(WarehouseShipmentLine);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // VERIFY: Warehouse shipment line is created again.
        WarehouseShipmentHeader.Get(WarehouseShipmentHeader."No.");
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullServiceHeaderNonWMSLocationWithGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        NonWMSLocationCode: Code[10];
        WMSLocationCode: Code[10];
        ServiceItemLineNo: Integer;
    begin
        Initialize();

        // SETUP: Create Service order with header on BLUE Location and service lines on WHITE, Release
        NonWMSLocationCode := CreateLocation();
        WMSLocationCode := WMSFullLocation;
        LibraryInventory.CreateItem(Item);
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader);
        ServiceHeader."Location Code" := NonWMSLocationCode;
        ServiceHeader.Modify(true);
        AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LibraryRandom.RandInt(100), WMSLocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // EXECUTE: Pull service header with BLUE location code into whse shipment with WHITE.
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, WMSLocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // VERIFY: Warehouse shipment line is created with the service lines.
        WarehouseShipmentHeader.Get(WarehouseShipmentHeader."No.");
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullServiceLinesOnNonWMSLocationWithGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        NonWMSLocationCode: Code[10];
        WMSLocationCode: Code[10];
        ServiceItemLineNo: Integer;
        ServiceLineNo: Integer;
    begin
        Initialize();

        // SETUP: Create Service order with service lines on WHITE and new BLUE Location, Release
        NonWMSLocationCode := CreateLocation();
        WMSLocationCode := WMSFullLocation;
        LibraryInventory.CreateItem(Item);
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader);
        AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LibraryRandom.RandInt(100), NonWMSLocationCode);
        ServiceLineNo :=
          AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LibraryRandom.RandInt(100), WMSLocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // EXECUTE: Pull service lines into shipment header with WHITE location code.
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, WMSLocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // VERIFY: Warehouse shipment line is created with only WHITE service Line.
        WarehouseShipmentHeader.Get(WarehouseShipmentHeader."No.");
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        ServiceLine.SetFilter("Line No.", Format(ServiceLineNo));
        ServiceLine.FindSet();
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullServiceLinesOnManyWMSLocationsWithGetSourceDocument()
    var
        Location: Record Location;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        NewWMSLocationCode: Code[10];
        DefaultWMSLocationCode: Code[10];
        ServiceItemLineNo: Integer;
        ServiceLineNo: Integer;
    begin
        Initialize();

        // SETUP: Create Service order with service  WHITE Location and a new full WMS location and Release order.
        CreateFullWarehouseLocation(Location);
        NewWMSLocationCode := Location.Code;
        DefaultWMSLocationCode := WMSFullLocation;
        LibraryInventory.CreateItem(Item);
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader);
        AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LibraryRandom.RandInt(100), DefaultWMSLocationCode);
        ServiceLineNo :=
          AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LibraryRandom.RandInt(100), NewWMSLocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // EXECUTE: Pull service lines into shipment header with new WMS Location.
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, NewWMSLocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // VERIFY: Warehouse shipment line is created with only WHITE service Line.
        WarehouseShipmentHeader.Get(WarehouseShipmentHeader."No.");
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        ServiceLine.SetFilter("Line No.", Format(ServiceLineNo));
        ServiceLine.FindSet();
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        VerifyWarehouseShipmentLines(WarehouseShipmentLine, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('VerifyNoDocumentInGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullUnreleasedServiceOrderWithGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        DefaultWMSLocationCode: Code[10];
    begin
        Initialize();

        // SETUP: Create Service order with service  WHITE Location and a new full WMS location and Release order.
        DefaultWMSLocationCode := WMSFullLocation;
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), DefaultWMSLocationCode);

        // EXECUTE: Pull service lines into shipment header with new WMS Location.
        // VERIFY: The document is not displayed when get source document is invoked.
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, DefaultWMSLocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullAndPostWarehouseShipmentUsingGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and Release Service Order, Create Whse Shpment header using Get Source Doc
        LocationCode := WMSFullLocation;
        Quantity := LibraryRandom.RandInt(100);
        CreateItemAndSupply(Item, LocationCode, Quantity);

        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // EXECUTE: Create Pick, Register Pick and post Warehouse shipment with ship option.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: All service lines are present in warehouse shipment and the quantities match
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        Assert.AreEqual(Quantity, ServiceLine."Quantity Shipped", ServiceLine.FieldCaption("Quantity Shipped"));
        Assert.AreEqual(Quantity, ServiceLine."Qty. Shipped Not Invoiced", ServiceLine.FieldCaption("Qty. Shipped Not Invoiced"));
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullAndPostMulitpleServiceLinesUsingGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ServiceLine: Record "Service Line";
        LineQuantity: Integer;
        Delta: Integer;
        Index: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location with multiple service lines,Release Service Order with multiple service items
        // One line should have not enough supply
        // Create Whse Shpment header using Get Source Doc and pull all lines in
        PrepareShipmentMultipleLines(Item, ServiceHeader, WarehouseShipmentHeader, LineQuantity, Delta, true);

        // EXECUTE: Create Pick, Register Pick and post Warehouse shipment with ship option.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // VERIFY: All service lines are present in warehouse shipment and the quantities match
        // VERIFY: The last Service line is only partially fulfilled.
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        ServiceLine.SetFilter("No.", '<>%1', Item."No.");
        ServiceLine.FindSet();

        Assert.AreEqual(5, ServiceLine.Count, 'The right number of rows are returned by the filter');
        Index := 0;
        repeat
            Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Quantity Shipped", StrSubstNo('Service line %1: %2', Index, ServiceLine.FieldCaption("Quantity Shipped")));
            Assert.AreEqual(
              ServiceLine.Quantity, ServiceLine."Qty. Shipped Not Invoiced", StrSubstNo('Service line %1: %2', Index, ServiceLine.FieldCaption("Qty. Shipped Not Invoiced")));
            GetAndVerifyWarehouseEntry(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.", -ServiceLine."Quantity Shipped");
            Assert.RecordCount(WarehouseEntry, 1);
            Index += 1;
        until ServiceLine.Next() = 0;

        ServiceLine.SetFilter("No.", Item."No.");
        ServiceLine.FindSet();
        Assert.AreEqual(ServiceLine.Quantity - Delta, ServiceLine."Quantity Shipped", 'Service Line 6: ' + ServiceLine.FieldCaption("Quantity Shipped"));
        Assert.AreEqual(ServiceLine.Quantity - Delta, ServiceLine."Qty. Shipped Not Invoiced", 'Service Line 6: ' + ServiceLine.FieldCaption("Qty. Shipped Not Invoiced"));
        GetAndVerifyWarehouseEntry(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.", -ServiceLine."Quantity Shipped");
        Assert.RecordCount(WarehouseEntry, 1);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullAndPostMulitpleServiceHeadersUsingGetSourceDocument()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        LineQuantity: Integer;
        ServiceItemLineNo: Integer;
        I: Integer;
        ServiceHeaderNo: array[6] of Code[20];
        NumberOfServiceHeaders: Integer;
    begin
        Initialize();
        // SETUP: Create Multiple Service orders on WHITE Location,Release Service Order.
        // Create Whse Shpment header using Get Source Doc and pull all headers in.
        LocationCode := WMSFullLocation;
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        NumberOfServiceHeaders := LibraryRandom.RandIntInRange(2, 6);

        for I := 1 to NumberOfServiceHeaders do begin
            LineQuantity := LibraryRandom.RandInt(100);
            Clear(Item);
            Clear(ServiceHeader);
            CreateItemAndSupply(Item, LocationCode, LineQuantity);
            ServiceItemLineNo := CreateServiceOrder(ServiceHeader);
            AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LineQuantity, LocationCode);
            ServiceHeaderNo[I] := ServiceHeader."No.";
            LibraryService.ReleaseServiceDocument(ServiceHeader);
            AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);
        end;

        // EXECUTE: Create Pick, Register Pick and post Warehouse shipment with ship option.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // VERIFY: All service lines are present in warehouse shipment and the quantities match
        for I := 1 to NumberOfServiceHeaders do begin
            ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeaderNo[I]);
            Clear(ServiceLine);
            GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
            repeat
                Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Quantity Shipped", ServiceLine.FieldCaption("Quantity Shipped"));
                Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Qty. Shipped Not Invoiced", ServiceLine.FieldCaption("Qty. Shipped Not Invoiced"));
            until ServiceLine.Next() = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PullAndPostMixedHeadersUsingUseFilters()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LocationCode: Code[10];
        LineQuantity: Integer;
        ServiceItemLineNo: Integer;
        I: Integer;
        ServiceHeaderNo: array[6] of Code[20];
        SalesHeaderNo: array[6] of Code[20];
        NumberOfHeaders: Integer;
    begin
        Initialize();

        // SETUP: Create and Release Service orders and sales orders on WHITE Location with multiple service lines
        // Create Whse Shpment header using Get Source Doc and pull all lines in
        LocationCode := WMSFullLocation;
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        NumberOfHeaders := LibraryRandom.RandIntInRange(2, 6);

        LibrarySales.CreateCustomer(Customer);
        for I := 1 to NumberOfHeaders do begin
            LineQuantity := LibraryRandom.RandInt(100);
            Clear(Item);
            Clear(ServiceHeader);
            Clear(SalesHeader);
            CreateItemAndSupply(Item, LocationCode, 2 * LineQuantity);
            LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
            ServiceItemLineNo := AddNewServiceItemLinesToOrder(ServiceHeader);
            AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LineQuantity, LocationCode);
            ServiceHeaderNo[I] := ServiceHeader."No.";
            LibraryService.ReleaseServiceDocument(ServiceHeader);
            CreateAndReleaseSalesOrder(SalesHeader, Item."No.", LocationCode, LineQuantity, false);
            SalesHeaderNo[I] := SalesHeader."No.";
        end;

        // EXECUTE: Create Pick, Register Pick and post Warehouse shipment with ship option.
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Validate("Service Orders", true);
        WarehouseSourceFilter.Validate("Sales Orders", true);
        WarehouseSourceFilter.Validate("Customer No. Filter", Customer."No.");
        WarehouseSourceFilter.Modify(true);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, WMSFullLocation);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // VERIFY: All service lines and Sales Lines have been posted and the quantities match
        for I := 1 to NumberOfHeaders do begin
            ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeaderNo[I]);
            Clear(ServiceLine);
            Clear(SalesLine);
            GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
            SalesHeader.Get(SalesHeader."Document Type", SalesHeaderNo[I]);
            GetSalesLinesOfTypeItem(SalesLine, SalesHeader);
            repeat
                Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Quantity Shipped", ServiceLine.FieldCaption("Quantity Shipped"));
                Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Qty. Shipped Not Invoiced", ServiceLine.FieldCaption("Qty. Shipped Not Invoiced"));
            until ServiceLine.Next() = 0;

            repeat
                Assert.AreEqual(SalesLine.Quantity, SalesLine."Quantity Shipped", SalesLine.FieldCaption("Quantity Shipped"));
                Assert.AreEqual(SalesLine.Quantity, SalesLine."Qty. Shipped Not Invoiced", SalesLine.FieldCaption("Qty. Shipped Not Invoiced"));
            until SalesLine.Next() = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PullServiceLineNoShipmentUsingUseFilter()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        LocationCode: Code[10];
        ServiceItemLineNo: Integer;
        Quantity: Integer;
    begin
        Initialize();

        // SETUP: Create new customer, service item, Service order on WHITE Location, Release
        LocationCode := WMSFullLocation;
        Quantity := LibraryRandom.RandInt(100);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceItemLineNo := AddNewServiceItemLinesToOrder(ServiceHeader);
        AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", Quantity, LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // EXECUTE: Try to Pull using filters on a customer with no orders.
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        Clear(Customer);
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Validate("Service Orders", true);
        WarehouseSourceFilter.Validate("Sales Orders", false);
        WarehouseSourceFilter.Validate("Customer No. Filter", Customer."No.");
        WarehouseSourceFilter.Modify(true);
        asserterror LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, WMSFullLocation);

        // VERIFY: Error message is displayed.
        Assert.AreEqual(Format(NoWarehouseShipmentsErr), GetLastErrorText, VerifyDisplayedErrorMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PullServiceLineTwiceUsingUseFilter()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        LocationCode: Code[10];
        Quantity: Integer;
    begin
        Initialize();

        // SETUP: Create new customer, service item, Service order on WHITE Location, Release
        LocationCode := WMSFullLocation;
        Quantity := LibraryRandom.RandInt(100);
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, WMSFullLocation);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // EXECUTE: Try to Pull Twice using the same filters
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Validate("Service Orders", true);
        WarehouseSourceFilter.Validate("Sales Orders", false);
        WarehouseSourceFilter.Validate("Source No. Filter", ServiceHeader."No.");
        WarehouseSourceFilter.Modify(true);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, WMSFullLocation);
        asserterror LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, WMSFullLocation);

        // VERIFY: Error message is displayed.
        Assert.AreEqual(Format(NoWarehouseShipmentsErr), GetLastErrorText, VerifyDisplayedErrorMsg);
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoWarehouseShipmentFullyShippedOrder()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        WarehouseShipment: TestPage "Warehouse Shipment";
        LocationCode: Code[10];
        Quantity: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and Release Service Order, Create Whse Shpment header.
        // SETUP: Create and Register Pick. Post the Whse Shpment with The Ship option.
        LocationCode := WMSFullLocation;
        Quantity := LibraryRandom.RandInt(100);
        CreateItemAndSupply(Item, LocationCode, Quantity);

        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        WarehouseShipment.Trap();
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);
        WarehouseShipmentHeader.Get(Format(WarehouseShipment."No.".Value()));

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // EXECUTE: Undo the Posted Service Shipment.
        LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // VERIFY: Ledger entries are created correctly.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine, Quantity);
        VerifyQtyOnItemLedgerEntry(TempServiceLine, Quantity);
        VerifyValueEntry(TempServiceLine, Quantity);
        VerifyServiceLedgerEntry(TempServiceLine, Quantity);

        GetAndVerifyWarehouseEntry(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.", ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentMulitpleServiceLines()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        LineQuantity: Integer;
        Delta: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location with multiple service lines,Release Service Order with multiple service items
        // SETUP: One line should have not enough supply
        // SETUP: Create Whse Shpment header using Get Source Doc and pull all lines in
        PrepareShipmentMultipleLines(Item, ServiceHeader, WarehouseShipmentHeader, LineQuantity, Delta, false);

        // EXECUTE: Create Pick, Register Pick and post Warehouse shipment with ship option.
        // EXECUTE: Undo the posted shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);

        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // VERIFY: Ledger entries are created correctly.
        // VERIFY: Quantities in shipments are revereed correctly.
        // VERIFY: Service Lines have quantities set correctly.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine, LineQuantity);
        VerifyQtyOnItemLedgerEntry(TempServiceLine, LineQuantity);
        VerifyValueEntry(TempServiceLine, LineQuantity);
        VerifyServiceLedgerEntry(TempServiceLine, LineQuantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoWarehouseShipmentMixedHeaders()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LocationCode: Code[10];
        LineQuantity: Integer;
        ServiceItemLineNo: Integer;
        I: Integer;
        ServiceHeaderNo: array[6] of Code[20];
        SalesHeaderNo: array[6] of Code[20];
        NumberOfHeaders: Integer;
    begin
        Initialize();

        // SETUP: Create and Release Service orders and sales orders on WHITE Location with multiple service lines
        // Create Whse Shpment header using Get Source Doc and pull all lines in
        LocationCode := WMSFullLocation;
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        NumberOfHeaders := LibraryRandom.RandIntInRange(2, 6);

        LibrarySales.CreateCustomer(Customer);
        LineQuantity := LibraryRandom.RandInt(100);
        for I := 1 to NumberOfHeaders do begin
            Clear(Item);
            Clear(ServiceHeader);
            Clear(ServiceLine);
            Clear(SalesHeader);
            CreateItemAndSupply(Item, LocationCode, 2 * LineQuantity);
            LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
            ServiceItemLineNo := AddNewServiceItemLinesToOrder(ServiceHeader);
            AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LineQuantity, LocationCode);
            ServiceHeaderNo[I] := ServiceHeader."No.";
            LibraryService.ReleaseServiceDocument(ServiceHeader);
            GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
            SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
            CreateAndReleaseSalesOrder(SalesHeader, Item."No.", LocationCode, LineQuantity, false);
            SalesHeaderNo[I] := SalesHeader."No.";
        end;

        // EXECUTE: Create Pick, Register Pick and post Warehouse shipment with ship option.
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Validate("Service Orders", true);
        WarehouseSourceFilter.Validate("Sales Orders", true);
        WarehouseSourceFilter.Validate("Customer No. Filter", Customer."No.");
        WarehouseSourceFilter.Modify(true);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, WMSFullLocation);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // VERIFY: All service lines and Sales Lines have been posted and the quantities match
        for I := 1 to NumberOfHeaders do begin
            Clear(ServiceLine);
            Clear(SalesLine);

            TempServiceLine.SetFilter("Document No.", ServiceHeaderNo[I]);
            LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeaderNo[I]);

            SalesHeader.Get(SalesHeader."Document Type", SalesHeaderNo[I]);
            UndoAllShipmentsForSalesHeader(SalesHeader."No.");
            GetSalesLinesOfTypeItem(SalesLine, SalesHeader);

            VerifyUpdatedShipQtyAfterShip(TempServiceLine);
            VerifyQtyOnServiceShipmentLine(TempServiceLine, LineQuantity);
            VerifyQtyOnItemLedgerEntry(TempServiceLine, LineQuantity);
            VerifyValueEntry(TempServiceLine, LineQuantity);
            VerifyServiceLedgerEntry(TempServiceLine, LineQuantity);

            repeat
                Assert.AreEqual(0, SalesLine."Quantity Shipped", SalesLine.FieldCaption("Quantity Shipped"));
                Assert.AreEqual(0, SalesLine."Qty. Shipped Not Invoiced", SalesLine.FieldCaption("Qty. Shipped Not Invoiced"));
            until SalesLine.Next() = 0;
        end;
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoWarehouseShipmentFullyShippedOrderMultipleshipments()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        WarehouseShipment: TestPage "Warehouse Shipment";
        LocationCode: Code[10];
        ServiceShipmentHeaderNo: Code[20];
        Quantity: Integer;
        FirstShipmentQuantity: Integer;
        DeltaQuantity: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and Release Service Order, Create Whse Shpment header.
        LocationCode := WMSFullLocation;
        Quantity := LibraryRandom.RandIntInRange(2, 100);
        CreateItemAndSupply(Item, LocationCode, Quantity);

        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        WarehouseShipment.Trap();
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);
        WarehouseShipmentHeader.Get(Format(WarehouseShipment."No.".Value()));

        // EXECUTE: Create and Register Pick. Post the whse shpmnt twice with the ship option.
        // EXECUTE: Undo the Second posted service shipment only.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        GetWarehouseShipmentLinesByShipmentHeader(WarehouseShipmentLine, WarehouseShipmentHeader);
        FirstShipmentQuantity := LibraryRandom.RandIntInRange(1, Quantity - 1);
        DeltaQuantity := Quantity - FirstShipmentQuantity;
        WarehouseShipmentLine.Validate("Qty. to Ship", FirstShipmentQuantity);
        WarehouseShipmentLine.Modify(true);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentHeaderNo := ServiceShipmentHeader."No.";

        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        GetAndVerifyWarehouseEntry(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.", -FirstShipmentQuantity);

        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        Clear(WarehouseEntry);
        GetWarehouseEntries(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.");
        WarehouseEntry.FindLast();
        VerifyWarehouseEntry(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.", -DeltaQuantity);

        ServiceShipmentHeader.SetFilter("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.SetFilter("No.", '<>%1', ServiceShipmentHeaderNo);
        ServiceShipmentHeader.FindFirst();
        LibraryService.UndoShipmentLinesByServiceDocNo(ServiceShipmentHeader."No.");

        // VERIFY: Ledger entries are created correctly.
        // VERIFY: Quantity shipped in the first shipment is not affected  by undoing the second shipment.
        // VERIFY: Warehouse entries are created correctly
        Assert.AreEqual(
          ServiceLine."Quantity Shipped", FirstShipmentQuantity,
          'Verify undoing one shipment returns Quantity Shipped field to values prior to undo');
        Assert.AreEqual(ServiceLine."Qty. to Ship", 0, 'Verify undoing one shipment returns Qty. to Ship field to values prior to undo');
        Assert.AreEqual(
          ServiceLine."Quantity Invoiced", 0, 'Verify undoing one shipment returns Quantity Invoiced field to values prior to undo');
        Assert.AreEqual(
          ServiceLine."Qty. to Invoice", FirstShipmentQuantity,
          'Verify undoing one shipment returns Qty. to Invoice field to values prior to undo');

        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine, DeltaQuantity);
        VerifyQtyOnItemLedgerEntry(TempServiceLine, DeltaQuantity);
        VerifyValueEntry(TempServiceLine, DeltaQuantity);
        VerifyServiceLedgerEntry(TempServiceLine, DeltaQuantity);

        GetAndVerifyWarehouseEntry(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.", DeltaQuantity);
        Assert.AreEqual(1, WarehouseEntry.Count, 'Only one warehouse reverse entry is created');

        Clear(WarehouseEntry);
        GetWarehouseEntries(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.");
        Assert.AreEqual(2, WarehouseEntry.Count, '2 warehouse entries are created');
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoWarehouseShipmentPartiallyShippedOrder()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        WarehouseShipment: TestPage "Warehouse Shipment";
        LocationCode: Code[10];
        Quantity: Integer;
        FirstShipmentQuantity: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and Release Service Order, Create Whse Shpment header.
        LocationCode := WMSFullLocation;
        Quantity := LibraryRandom.RandIntInRange(2, 100);
        CreateItemAndSupply(Item, LocationCode, Quantity);

        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        WarehouseShipment.Trap();
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);
        WarehouseShipmentHeader.Get(Format(WarehouseShipment."No.".Value()));

        // EXECUTE: Create and Register Pick. Post the whse shpmnt twice with the ship option.
        // EXECUTE: Undo the Second posted service shipment only.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        GetWarehouseShipmentLinesByShipmentHeader(WarehouseShipmentLine, WarehouseShipmentHeader);
        FirstShipmentQuantity := LibraryRandom.RandIntInRange(1, Quantity - 1);
        WarehouseShipmentLine.Validate("Qty. to Ship", FirstShipmentQuantity);
        WarehouseShipmentLine.Modify(true);

        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // VERIFY: Ledger entries are created correctly.
        // VERIFY: Quantity shipped in the first shipment is not affected  by undoing the second shipment.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine, FirstShipmentQuantity);
        VerifyQtyOnItemLedgerEntry(TempServiceLine, FirstShipmentQuantity);
        VerifyValueEntry(TempServiceLine, FirstShipmentQuantity);
        VerifyServiceLedgerEntry(TempServiceLine, FirstShipmentQuantity);
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoWarehouseShipmentFullyShippedOrderOnBlockedItem()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipment: TestPage "Warehouse Shipment";
        LocationCode: Code[10];
        Quantity: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and Release Service Order, Create Whse Shpment header.
        // SETUP: Create and Register Pick. Post the Whse Shpment with The Ship option.
        LocationCode := WMSFullLocation;
        Quantity := LibraryRandom.RandInt(100);
        CreateItemAndSupply(Item, LocationCode, Quantity);

        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        WarehouseShipment.Trap();
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);
        WarehouseShipmentHeader.Get(Format(WarehouseShipment."No.".Value()));

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // EXECUTE: Block the Item and Undo the Posted Service Shipment.
        Item.Get(Item."No.");
        Item.Validate(Blocked, true);
        Item.Modify(true);
        asserterror LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // VERIFY: Error Message is thrown.
        // Verify: Quantity shipped on the Service Lien is not affected.
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        Assert.AreEqual(Quantity, ServiceLine."Quantity Shipped", 'Quantity Shipped is not affected when undo fails');
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoWarehouseShipmentPartailyInvoicedSingleShipment()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        WarehouseShipment: TestPage "Warehouse Shipment";
        LocationCode: Code[10];
        ServiceShipmentHeaderNo: Code[20];
        ServiceShipmentLineNo: Integer;
        Quantity: Integer;
        InvoiceQuantity: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and Release Service Order, Create Whse Shpment header using Get Source Doc
        LocationCode := WMSFullLocation;
        Quantity := LibraryRandom.RandIntInRange(2, 100);
        CreateItemAndSupply(Item, LocationCode, Quantity);

        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        WarehouseShipment.Trap();
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);
        WarehouseShipmentHeader.Get(Format(WarehouseShipment."No.".Value()));

        // EXECUTE: Create Pick, Register Pick and post Warehouse shipment with ship option, Invoice Service order partialy.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        InvoiceQuantity := LibraryRandom.RandIntInRange(1, Quantity - 1);
        ServiceLine."Qty. to Invoice" := InvoiceQuantity;
        ServiceLine.Modify(true);

        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentHeaderNo := ServiceShipmentHeader."No.";

        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeaderNo);
        ServiceShipmentLine.FindFirst();
        ServiceShipmentLineNo := ServiceShipmentLine."Line No.";

        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
        asserterror LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // VERIFY: Error Message is thrown when an invoiced line is undone.
        Assert.ExpectedTestFieldError(ServiceShipmentLine.FieldCaption("Qty. Shipped Not Invoiced"), Format(Quantity));
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoAndReShipWarehouseShipmentFullyShippedOrder()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ServiceLine: Record "Service Line";
        WarehouseShipment: TestPage "Warehouse Shipment";
        LocationCode: Code[10];
        Quantity: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and Release Service Order, Create Whse Shpment header
        // SETUP: Create Registe Pick, Post Whse Shpmnt, Undo the posted service shipment
        LocationCode := WMSFullLocation;
        Quantity := LibraryRandom.RandInt(100);
        CreateItemAndSupply(Item, LocationCode, 2 * Quantity);

        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        WarehouseShipment.Trap();
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);
        WarehouseShipmentHeader.Get(Format(WarehouseShipment."No.".Value()));
        WarehouseShipment.Close();

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // EXECUTE: Re-Open, Release order, create Whse Shipment again, Create Pick, Register Pick
        // EXECUTE: Post the new Warehouse shipment with ship option.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.ReopenServiceDocument(ServiceHeader);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        WarehouseShipment.Trap();
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);
        WarehouseShipmentHeader.Get(Format(WarehouseShipment."No.".Value()));
        WarehouseShipment.Close();

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // VERIFY: All service lines are present in warehouse shipment and the quantities match
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        Assert.AreEqual(Quantity, ServiceLine."Quantity Shipped", ServiceLine.FieldCaption("Quantity Shipped"));
        Assert.AreEqual(Quantity, ServiceLine."Qty. Shipped Not Invoiced", ServiceLine.FieldCaption("Qty. Shipped Not Invoiced"));
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage')]
    [Scope('OnPrem')]
    procedure DueDateCalculationAllBlankShippingTime()
    var
        Customer: Record Customer;
        ShippingAgent: Record "Shipping Agent";
        LocationCode: Code[10];
        ShippingAgentServicesCode: array[6] of Code[10];
    begin
        Initialize();

        // SETUP: Create Customer with blank shipping details
        LibrarySales.CreateCustomer(Customer);
        CreateShippingAgentServices(ShippingAgent, ShippingAgentServicesCode);
        LocationCode := WMSFullLocation;

        // VERIFY: Create Service ORder with blank shipping time and blank set shipping age service code
        TestCreateWarehouseShipmentDueDateCalculation(
          Customer,
          ShippingAgent.Code,// ServiceHeaderShippingAgentCode
          '',// ServiceHeaderShippingServiceCode
          LocationCode,// ServiceLineLocationCode
          '',// ServiceheaderShippingTime
          '',// ExpectedServiceLineShippingTimeOffset
          '<0D>');// ExpectedWarehouseLineDueDateOffset
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage')]
    [Scope('OnPrem')]
    procedure DueDateCalculationZeroShippingTime()
    var
        Customer: Record Customer;
        ShippingAgent: Record "Shipping Agent";
        LocationCode: Code[10];
        ShippingAgentServicesCode: array[6] of Code[10];
        DateOffset: Integer;
    begin
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        CreateShippingAgentServices(ShippingAgent, ShippingAgentServicesCode);
        LocationCode := WMSFullLocation;

        DateOffset := LibraryRandom.RandIntInRange(1, 6);
        TestCreateWarehouseShipmentDueDateCalculation(
          Customer,
          ShippingAgent.Code,// ServiceHeaderShippingAgentCode
          ShippingAgentServicesCode[DateOffset],// ServiceHeaderShippingServiceCode
          LocationCode,// ServiceLineLocationCode
          '<0D>',// ServiceheaderShippingTime
          '<0D>',// ExpectedServiceLineShippingTimeOffset
          '<0D>');// ExpectedWarehouseLineDueDateOffset
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage')]
    [Scope('OnPrem')]
    procedure DueDateCalculationShippingTimeFlowsFromAgentService()
    var
        Customer: Record Customer;
        ShippingAgent: Record "Shipping Agent";
        LocationCode: Code[10];
        ShippingAgentServicesCode: array[6] of Code[10];
        DateOffset: Integer;
    begin
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        CreateShippingAgentServices(ShippingAgent, ShippingAgentServicesCode);
        LocationCode := WMSFullLocation;

        DateOffset := LibraryRandom.RandIntInRange(1, 6);
        TestCreateWarehouseShipmentDueDateCalculation(
          Customer,
          ShippingAgent.Code,// ServiceHeaderShippingAgentCode
          ShippingAgentServicesCode[DateOffset],// ServiceHeaderShippingServiceCode
          LocationCode,// ServiceLineLocationCode
          '',// ServiceheaderShippingTime
          StrSubstNo('<%1D>', DateOffset),// ExpectedServiceLineShippingTimeOffset
          StrSubstNo('<-%1D>', DateOffset));// ExpectedWarehouseLineDueDateOffset
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage')]
    [Scope('OnPrem')]
    procedure DueDateCalculationBlankServiceHeaderAgentCode()
    var
        Customer: Record Customer;
        LocationCode: Code[10];
        ShippingTime: DateFormula;
    begin
        Initialize();

        // SETUP: Create Customer with blank shipping details
        CreateCustomerWithShippingDetails(Customer, '');
        Customer.Validate("Shipping Agent Code", '');
        Customer.Validate("Shipping Agent Service Code", '');
        Evaluate(ShippingTime, '');
        Customer.Validate("Shipping Time", ShippingTime);
        Customer.Modify(true);

        LocationCode := WMSFullLocation;

        // VERIFY: Create Service Order with blank shipping time and blank set shipping age service code
        TestCreateWarehouseShipmentDueDateCalculation(
          Customer,
          '',// ServiceHeaderShippingAgentCode
          '',// ServiceHeaderShippingServiceCode
          LocationCode,// ServiceLineLocationCode
          '',// ServiceheaderShippingTime
          '',// ExpectedServiceLineShippingTimeOffset
          '<0D>');// ExpectedWarehouseLineDueDateOffset
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage')]
    [Scope('OnPrem')]
    procedure DueDateCalculationFlowsFromCustomerNonZeroShipTime()
    var
        Customer: Record Customer;
        ShippingAgent: Record "Shipping Agent";
        LocationCode: Code[10];
        ShippingAgentServicesCode: array[6] of Code[10];
        DateOffset: Integer;
    begin
        Initialize();

        // SETUP: Create Customer with blank shipping details
        DateOffset := LibraryRandom.RandIntInRange(10, 20);
        CreateCustomerWithShippingDetails(Customer, StrSubstNo('<%1D>', DateOffset));
        CreateShippingAgentServices(ShippingAgent, ShippingAgentServicesCode);
        LocationCode := WMSFullLocation;

        // VERIFY: Create Service Order with blank shipping time and blank set shipping age service code
        TestCreateWarehouseShipmentDueDateCalculation(
          Customer,
          ShippingAgent.Code,// ServiceHeaderShippingAgentCode
          '',// ServiceHeaderShippingServiceCode
          LocationCode,// ServiceLineLocationCode
          '',// ServiceheaderShippingTime
          StrSubstNo('<%1D>', DateOffset),// ExpectedServiceLineShippingTimeOffset
          StrSubstNo('<-%1D>', DateOffset));// ExpectedWarehouseLineDueDateOffset
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage')]
    [Scope('OnPrem')]
    procedure DueDateCalculationAllShippingTimeSet()
    var
        Customer: Record Customer;
        ShippingAgent: Record "Shipping Agent";
        LocationCode: Code[10];
        ShippingAgentServicesCode: array[6] of Code[10];
        DateOffset: Integer;
    begin
        Initialize();

        // SETUP: Create Customer with blank shipping details
        DateOffset := LibraryRandom.RandIntInRange(10, 20);
        CreateCustomerWithShippingDetails(Customer, StrSubstNo('<%1D>', DateOffset));
        CreateShippingAgentServices(ShippingAgent, ShippingAgentServicesCode);
        LocationCode := WMSFullLocation;

        // VERIFY: Create Service Order with blank shipping time and blank set shipping age service code
        DateOffset := LibraryRandom.RandIntInRange(1, 10);
        TestCreateWarehouseShipmentDueDateCalculation(
          Customer,
          ShippingAgent.Code,// ServiceHeaderShippingAgentCode
          ShippingAgentServicesCode[LibraryRandom.RandIntInRange(1, 6)],// ServiceHeaderShippingServiceCode
          LocationCode,// ServiceLineLocationCode
          StrSubstNo('<%1M>', DateOffset),// ServiceheaderShippingTime
          StrSubstNo('<%1M>', DateOffset),// ExpectedServiceLineShippingTimeOffset
          StrSubstNo('<-%1M>', DateOffset));// ExpectedWarehouseLineDueDateOffset
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure DueDateWithtMulitpleServiceHeaders()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ShippingAgent: Record "Shipping Agent";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        ShippingTime: DateFormula;
        ShippingAgentServicesCode: array[6] of Code[10];
        LocationCode: Code[10];
        LineQuantity: Integer;
        ServiceItemLineNo: Integer;
        I: Integer;
        ServiceHeaderNo: array[6] of Code[20];
        NumberOfServiceHeaders: Integer;
    begin
        Initialize();

        // SETUP: Create Multiple Service orders on WHITE Location,Release Service Order.

        LocationCode := WMSFullLocation;
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        NumberOfServiceHeaders := LibraryRandom.RandIntInRange(2, 6);

        // EXECUTE: Modify the shipping time on service header.
        // EXECUTE: Create a warehouse shipment and add all the created orders.
        for I := 1 to NumberOfServiceHeaders do begin
            Clear(ShippingAgent);
            Clear(ShippingAgentServicesCode);
            CreateShippingAgentServices(ShippingAgent, ShippingAgentServicesCode);
            LineQuantity := LibraryRandom.RandInt(100);
            Clear(Item);
            Clear(ServiceHeader);
            CreateItemAndSupply(Item, LocationCode, LineQuantity);
            ServiceItemLineNo := CreateServiceOrder(ServiceHeader);
            ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
            ServiceHeader.Validate("Shipping Agent Code", ShippingAgent.Code);
            ServiceHeader.Validate("Shipping Agent Service Code", ShippingAgentServicesCode[LibraryRandom.RandIntInRange(1, 6)]);
            Evaluate(ShippingTime, StrSubstNo('<%1D>', I));
            ServiceHeader.Validate("Shipping Time", ShippingTime);
            ServiceHeader.Modify(true);

            AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LineQuantity, LocationCode);
            ServiceHeaderNo[I] := ServiceHeader."No.";
            LibraryService.ReleaseServiceDocument(ServiceHeader);
            AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);
        end;

        // VERIFY: Due Dates on all the service lines
        for I := 1 to NumberOfServiceHeaders do begin
            ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeaderNo[I]);
            Clear(ServiceLine);
            Clear(WarehouseShipmentLine);
            GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
            FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);
            Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');

            Evaluate(ShippingTime, StrSubstNo('<-%1D>', I));
            Assert.AreEqual(CalcDate(ShippingTime, ServiceLine."Needed by Date"), WarehouseShipmentLine."Due Date", 'Due date matches');
        end;
    end;

    local procedure TestCreateWarehouseShipmentDueDateCalculation(var Customer: Record Customer; ServiceHeaderShippingAgentCode: Code[10]; ServiceHeaderShippingServiceCode: Code[10]; ServiceLineLocationCode: Code[10]; ServiceheaderShippingTime: Text[10]; ExpectedServiceLineShippingTimeOffset: Text[10]; ExpectedWarehouseLineDueDateOffset: Text[10])
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        WarehouseShipment: TestPage "Warehouse Shipment";
        ShippingTime: DateFormula;
        ServiceItemLineNo: Integer;
    begin
        // SETUP: Create Service order on a location with Specified Customer, Shipping Agent and Shipping agent services Service order and Shipping Time
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // EXECUTE: Add the service line and set the needed properties
        // EXECUTE: Create Warehouse shipment on this order
        if ServiceHeaderShippingAgentCode <> '' then begin
            ServiceHeader.Validate("Shipping Agent Code", ServiceHeaderShippingAgentCode);
            if ServiceHeaderShippingServiceCode <> '' then
                ServiceHeader.Validate("Shipping Agent Service Code", ServiceHeaderShippingServiceCode);
        end;
        if ServiceheaderShippingTime <> '' then begin
            Evaluate(ShippingTime, ServiceheaderShippingTime);
            ServiceHeader.Validate("Shipping Time", ShippingTime);
        end;
        ServiceHeader.Modify(true);
        ServiceItemLineNo := AddNewServiceItemLinesToOrder(ServiceHeader);
        AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LibraryRandom.RandInt(100), ServiceLineLocationCode);

        LibraryService.ReleaseServiceDocument(ServiceHeader);
        WarehouseShipment.Trap();

        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);

        // VERIFY: warehouse shipment Line:Due Date = ServiceLine."Needed by date" - Service Line.Shipping Time
        // VERIFY: Shipping time on service line matches the expected offset
        // VERIFY: WHSe Shipment Line.Shipping date= = ServiceLine."Needed by date" - ServiceLine.Shipping Time - Location."Whse Outbound handling time"
        WarehouseShipmentHeader.Get(Format(WarehouseShipment."No.".Value()));
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        FindWarehouseShipmentLinesByServiceOrder(WarehouseShipmentLine, ServiceHeader, WarehouseShipmentHeader);

        Assert.AreEqual(ServiceLine.Count, WarehouseShipmentLine.Count, 'Count of Lines in Whse shipment and service lines match');
        repeat
            Evaluate(ShippingTime, ExpectedWarehouseLineDueDateOffset);
            WarehouseShipmentLine.SetFilter("Source Line No.", Format(ServiceLine."Line No."));
            WarehouseShipmentLine.FindFirst();
            Assert.AreEqual(CalcDate(ShippingTime, ServiceLine."Needed by Date"), WarehouseShipmentLine."Due Date", 'Due date matches');

            Evaluate(ShippingTime, ExpectedServiceLineShippingTimeOffset);
            Assert.AreEqual(Format(ShippingTime), Format(ServiceLine."Shipping Time"), 'Service Line Shipping Time matches');
        until ServiceLine.Next() = 0;
    end;

    local procedure CheckQuantityAvailabilityCalculationsWithMixedOrders(LocationCode: Code[10]; IsYellowLocation: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        SalesHeaderNo: Code[20];
        LineQuantity: Integer;
        ServiceItemLineNo: Integer;
    begin
        // SETUP: Create an item and create a supply of quantity = 2X
        // SETUP: Create and Release Service orders on WHITE Location with Quantity = x
        // SETUP: Create Whse Shpment, Create Pick, Register pick of qty X
        // SETUP: Post Whse Shipment  and verify that the Qty X was shipped successfully.
        LibrarySales.CreateCustomer(Customer);
        LineQuantity := LibraryRandom.RandInt(100);
        if IsYellowLocation then
            CreateItemAndSupplyForYellowLocation(Item, LocationCode, 2 * LineQuantity)
        else
            CreateItemAndSupply(Item, LocationCode, 2 * LineQuantity);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceItemLineNo := AddNewServiceItemLinesToOrder(ServiceHeader);
        AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LineQuantity, LocationCode);
        ReleaseServiceHeaderAndCreateWarehouseShipment(ServiceHeader, WarehouseShipmentHeader);
        CreateAndRegisterWarehousePick(WarehouseShipmentHeader, ServiceHeader."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        Assert.AreEqual(LineQuantity, ServiceLine."Quantity Shipped", 'Verify that qty has been shipped');

        // EXECUTE: Create and Release Sales order on WHITE Location with Quantity = x
        // EXECUTE: Create Whse shipment, create Pick, Register Pick and post Warehouse shipment with ship option.
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", LocationCode, LineQuantity, false);
        CreateWarehouseShipmentFromSalesOrder(SalesHeader, WarehouseShipmentHeader);
        SalesHeaderNo := SalesHeader."No.";
        CreateAndRegisterWarehousePick(WarehouseShipmentHeader, SalesHeaderNo);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // VERIFY: Sales Lines have been posted and the quantities match
        SalesHeader.Get(SalesHeader."Document Type", SalesHeaderNo);
        GetSalesLinesOfTypeItem(SalesLine, SalesHeader);
        Assert.AreEqual(SalesLine.Quantity, SalesLine."Qty. Shipped Not Invoiced", SalesLine.FieldCaption("Qty. Shipped Not Invoiced"));
        Assert.AreEqual(LineQuantity, SalesLine."Quantity Shipped", SalesLine.FieldCaption("Quantity Shipped"));
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage')]
    [Scope('OnPrem')]
    procedure QuantityAvailabilityCalculationsMixedOrdersOnWhiteLocation()
    begin
        Initialize();
        // VERIFY: Quantity Availability Calculations with WHITE Location
        CheckQuantityAvailabilityCalculationsWithMixedOrders(WMSFullLocation, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostShipmentAndConsumeOnSilverLocation()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Quantity: Integer;
        LineQuantity: Integer;
    begin
        Initialize();

        // [GIVEN] Create an new Silver location, create a new item.
        Quantity := LibraryRandom.RandIntInRange(2, 100);
        LineQuantity := Quantity - 1;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateSilverLocation(Location, Bin);

        // [GIVEN] Create Supply for that item in the specific location and bin.
        CreateItemAndSupplyForSilverLocation(Item, Location, Bin, Quantity);

        // [GIVEN] Create Service order on the new SILVER Location.
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, Location.Code);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Bin Code", Bin.Code);
        ServiceLine.Validate("Qty. to Ship", LineQuantity);
        ServiceLine.Validate("Qty. to Invoice", 0);
        ServiceLine.Validate("Qty. to Consume", LineQuantity);
        ServiceLine.Modify(true);

        // [GIVEN] Release the service order.        
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        Commit();

        // [WHEN] Try to create a Warehouse shipment on this order.
        asserterror CreateWarehouseShipmentFromServiceHeader(ServiceHeader);

        // [THEN] No shipments are created since SERVICE ORDER on silver locations can not have warehouse shipment
        Assert.ExpectedError(NoWarehouseShipmentsErr);

        // [THEN] After dismissing the message service order can be posted with consume
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        ServiceLine.TestField("Quantity Shipped", LineQuantity);
        ServiceLine.TestField("Quantity Consumed", LineQuantity);
        ServiceLine.TestField("Qty. to Ship", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostShipmentOnBlueLocation()
    var
        Item: Record Item;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        Quantity: Integer;
    begin
        Initialize();

        // [GIVEN]  Create an new BLUE location, create a new item.
        Quantity := LibraryRandom.RandInt(100);
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Service order on the new BLUE Location.
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, Location.Code);

        // [GIVEN] Release the service order.
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        Commit();

        // [WHEN] Try to create a Warehouse shipment on this order.
        asserterror CreateWarehouseShipmentFromServiceHeader(ServiceHeader);

        // [THEN] No shipments are created since SERVICE ORDER on BLUE locations can not have warehouse shipment
        Assert.ExpectedError(NoWarehouseShipmentsErr);

        // [THEN] After dismissing the message service order can be posted.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentOnSilverLocation()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        LineQuantity: Integer;
    begin
        Initialize();

        // SETUP: Create an new Silver location, create a new item.
        // SETUP: Create Supply for that item in the specific location and bin.
        // SETUP: Create Service order on the new SILVER Location.
        // SETUP: Release the service order.
        LineQuantity := LibraryRandom.RandInt(100);
        CreateSilverLocation(Location, Bin);
        CreateItemAndSupplyForSilverLocation(Item, Location, Bin, LineQuantity);

        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LineQuantity, Location.Code);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Bin Code", Bin.Code);
        ServiceLine.Modify(true);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // EXECUTE: Post Service Order.
        // EXECUTE: Undo the Posted Service Shipment.
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // VERIFY: Shipment is undone.
        // VERIFY: Ledger entries are created correctly.
        Clear(ServiceLine);
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        VerifyServiceLineAfterFullUndoShipment(ServiceLine, LineQuantity);
        VerifyServiceShipmentLineAfterFullUndo(TempServiceLine, LineQuantity);
        VerifyQtyOnItemLedgerEntry(TempServiceLine, LineQuantity);
        VerifyValueEntry(TempServiceLine, LineQuantity);
        VerifyServiceLedgerEntry(TempServiceLine, LineQuantity);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullAndPostUsingGetSourceDocumentOnYellowLocation()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on WHITE Location and Release Service Order, Create Whse Shpment header using Get Source Doc
        LocationCode := YellowLocationCode;
        Quantity := LibraryRandom.RandInt(100);
        CreateItemAndSupplyForYellowLocation(Item, LocationCode, Quantity);

        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // EXECUTE: Create Pick, Register Pick and post Warehouse shipment with ship option.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // VERIFY: All service lines are present in warehouse shipment and the quantities match
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        VerifyServiceLineAfterOnlyShip(ServiceLine, 0);
        VerifyQtyOnServiceShipmentLineAfterShip(ServiceLine, Quantity);
        VerifyQtyOnItemLedgerEntryAfterShip(ServiceLine, Quantity);
        VerifyValueEntryAfterShip(ServiceLine, Quantity);
        VerifyServiceLedgerEntryAfterShip(ServiceLine, Quantity);
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoWarehouseShipmentOnYellowLocation()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        LocationCode: Code[10];
        Quantity: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on YELLOW Location and Release Service Order, Create Whse Shpment header.
        // SETUP: Create and Register Pick. Post the Whse Shpment with The Ship option.
        LocationCode := YellowLocationCode;
        Quantity := LibraryRandom.RandInt(100);
        CreateItemAndSupplyForYellowLocation(Item, LocationCode, Quantity);
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);
        ReleaseServiceHeaderAndCreateWarehouseShipment(ServiceHeader, WarehouseShipmentHeader);
        CreateAndRegisterWarehousePick(WarehouseShipmentHeader, ServiceHeader."No.");
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // EXECUTE: Undo the Posted Service Shipment.
        LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // VERIFY: Ledger entries are created and reversed correctly.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine, Quantity);
        VerifyQtyOnItemLedgerEntry(TempServiceLine, Quantity);
        VerifyValueEntry(TempServiceLine, Quantity);
        VerifyServiceLedgerEntry(TempServiceLine, Quantity);
        VerifyNoWarehouseEntriesCreated(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage')]
    [Scope('OnPrem')]
    procedure QuantityAvailabilityCalculationsOnYellowOrders()
    begin
        Initialize();
        // VERIFY: Quantity Availability Calculations with YELLOW Location
        CheckQuantityAvailabilityCalculationsWithMixedOrders(YellowLocationCode, true);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure PullAndPostMulitpleServiceLinesonYellowLocation()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Delta: Integer;
        LineQuantity: Integer;
        ServiceItemLineNo: Integer;
        I: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on YELLOW Location with multiple service lines,Release Service Order with multiple service items
        // One line should have not enough supply
        // Create Whse Shpment header using Get Source Doc and pull all lines in
        LocationCode := YellowLocationCode;

        ServiceItemLineNo := CreateServiceOrder(ServiceHeader);
        for I := 1 to 5 do begin
            LineQuantity := LibraryRandom.RandInt(100);
            Clear(Item);
            CreateItemAndSupplyForYellowLocation(Item, LocationCode, LineQuantity);
            AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LineQuantity, LocationCode);
        end;

        ServiceItemLineNo := AddNewServiceItemLinesToOrder(ServiceHeader);
        Delta := LibraryRandom.RandInt(10);
        LineQuantity := LibraryRandom.RandInt(100);
        Clear(Item);
        CreateItemAndSupplyForYellowLocation(Item, LocationCode, LineQuantity);
        AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LineQuantity + Delta, LocationCode);

        ServiceHeader.Find();
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // EXECUTE: Create Pick, Register Pick and post Warehouse shipment with ship option.
        CreateAndRegisterWarehousePick(WarehouseShipmentHeader, ServiceHeader."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // VERIFY: All service lines are present in warehouse shipment and the quantities match
        // VERIFY: The last Service line is only partially fulfilled.
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        ServiceLine.SetFilter("No.", '<>%1', Item."No.");
        ServiceLine.FindSet();

        Assert.AreEqual(5, ServiceLine.Count, 'The right number of rows are returned by the filter');
        I := 0;
        repeat
            VerifyServiceLineAfterOnlyShip(ServiceLine, 0);
            I := I + 1;
        until ServiceLine.Next() = 0;

        ServiceLine.SetFilter("No.", Item."No.");
        ServiceLine.FindSet();
        VerifyServiceLineAfterOnlyShip(ServiceLine, Delta);
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoWarehouseShipmentPartiallyShippedOrderYellowLocation()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        LocationCode: Code[10];
        Quantity: Integer;
        FirstShipmentQuantity: Integer;
    begin
        Initialize();

        // SETUP: Create Service order on YELLOW Location and Release Service Order, Create Whse Shpment header.
        LocationCode := YellowLocationCode;
        Quantity := LibraryRandom.RandIntInRange(2, 100);
        CreateItemAndSupplyForYellowLocation(Item, LocationCode, Quantity);

        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);
        ReleaseServiceHeaderAndCreateWarehouseShipment(ServiceHeader, WarehouseShipmentHeader);

        // EXECUTE: Create and Register Pick. Post the whse shpmnt twice with the ship option.
        // EXECUTE: Undo the Second posted service shipment only.
        CreateAndRegisterWarehousePick(WarehouseShipmentHeader, ServiceHeader."No.");
        GetWarehouseShipmentLinesByShipmentHeader(WarehouseShipmentLine, WarehouseShipmentHeader);
        FirstShipmentQuantity := LibraryRandom.RandIntInRange(1, Quantity - 1);
        WarehouseShipmentLine.Validate("Qty. to Ship", FirstShipmentQuantity);
        WarehouseShipmentLine.Modify(true);

        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // VERIFY: Ledger entries are created correctly.
        // VERIFY: Quantity shipped in the first shipment is not affected  by undoing the second shipment.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine, FirstShipmentQuantity);
        VerifyQtyOnItemLedgerEntry(TempServiceLine, FirstShipmentQuantity);
        VerifyValueEntry(TempServiceLine, FirstShipmentQuantity);
        VerifyServiceLedgerEntry(TempServiceLine, FirstShipmentQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostUnreleasedOrderOnYellowLocation()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        Quantity: Integer;
        LocationCode: Code[10];
    begin
        Initialize();
        // SETUP: Create an new YELLOW location, create a new item.

        LocationCode := YellowLocationCode;
        Quantity := LibraryRandom.RandInt(100);
        CreateItemAndSupplyForYellowLocation(Item, LocationCode, Quantity);

        // EXECUTE: Create Service order on the new YELLOW Location.
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);

        // VERIFY: Posting service order throws an error.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.AreEqual(
          Format(DocumentErrorsMgt.GetNothingToPostErrorMsg()),
          GetLastErrorText, 'Verify that error message is displayed when Posting without releasing');
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoServiceShipmentWithNoWarehouseShipmentOnYellow()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        LineQuantity: Integer;
        LocationCode: Code[10];
    begin
        Initialize();
        // SETUP: Create an new YELLOW location, create a new item.

        LocationCode := YellowLocationCode;
        LineQuantity := LibraryRandom.RandInt(100);
        CreateItemAndSupplyForYellowLocation(Item, LocationCode, LineQuantity);

        // EXECUTE: Create Service order on the new YELLOW Location.
        // EXECUTE: Undo shipment
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LineQuantity, LocationCode);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        LineQuantity -= 1;
        ServiceLine.Validate("Qty. to Ship", LineQuantity);
        ServiceLine.Modify(true);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // VERIFY: Posting order doesn't throw an error.
        Clear(ServiceLine);
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        VerifyServiceLineAfterFullUndoShipment(ServiceLine, LineQuantity + 1);
        VerifyServiceShipmentLineAfterFullUndo(TempServiceLine, LineQuantity);

        VerifyQtyOnItemLedgerEntry(TempServiceLine, LineQuantity);
        VerifyValueEntry(TempServiceLine, LineQuantity);
        VerifyServiceLedgerEntry(TempServiceLine, LineQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditQtyToShipUnreleasedOrderOnYellowLocation()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        LineQuantity: Integer;
        LocationCode: Code[10];
    begin
        Initialize();
        // SETUP: Create an new YELLOW location, create a new item.

        LocationCode := YellowLocationCode;
        LineQuantity := LibraryRandom.RandInt(100);
        CreateItemAndSupplyForYellowLocation(Item, LocationCode, LineQuantity);

        // EXECUTE: Create Service order on the new BLUE Location.
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LineQuantity, LocationCode);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        LineQuantity -= 1;
        ServiceLine.Validate("Qty. to Ship", LineQuantity);
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // VERIFY: Posting order doesn't throw an error.
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        Assert.AreEqual(LineQuantity, ServiceLine."Qty. Shipped Not Invoiced", 'Qty. Shipped Not Invoiced matches');
        Assert.AreEqual(LineQuantity, ServiceLine."Quantity Shipped", 'Quantity Shipped matches');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckQuantitiesOnYellowLocation()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        LocationCode: Code[10];
        LineQuantity: Integer;
    begin
        Initialize();
        // SETUP: Create an new YELLOW location, create a new item.
        LocationCode := YellowLocationCode;
        LineQuantity := LibraryRandom.RandInt(100);
        CreateItemAndSupplyForYellowLocation(Item, LocationCode, LineQuantity);

        // EXECUTE: Create Service order on the new BLUE Location.
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LineQuantity, LocationCode);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity);
        // VERIFY: Quantities are correct on service line
        Assert.AreEqual(ServiceLine."Quantity (Base)", ServiceLine."Qty. to Invoice (Base)", 'Quantity to Invoice (Base) matches');
        Assert.AreEqual(ServiceLine."Quantity (Base)", ServiceLine."Qty. to Ship (Base)", 'Quantity to Ship (Base) matches');
        Assert.AreEqual(ServiceLine."Qty. to Consume (Base)", 0, 'Quantity to Consume (Base) matches 0');
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        Assert.AreEqual(ServiceLine."Quantity (Base)", ServiceLine."Qty. to Consume (Base)", 'Quantity to Consume (Base) matches Quantity');
        Assert.AreEqual(ServiceLine."Qty. to Invoice (Base)", 0, 'Quantity to Invoice (Base) matches 0');
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage')]
    [Scope('OnPrem')]
    procedure PostPartialWarehouseShipmentWithCompleteShippingAdvice()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipment: TestPage "Warehouse Shipment";
        LocationCode: Code[10];
        Quantity: Integer;
        FirstShipmentQuantity: Integer;
    begin
        Initialize();
        WarehouseSetup.Get();
        WarehouseSetup.Validate(
          "Shipment Posting Policy", WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify(true);

        // SETUP: Create Service order on WHITE Location and Release Service Order, Create Whse Shpment header.
        LocationCode := WMSFullLocation;
        Quantity := LibraryRandom.RandIntInRange(2, 100);
        CreateItemAndSupply(Item, LocationCode, Quantity);

        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", Quantity, LocationCode);
        ServiceHeader.Validate("Shipping Advice", ServiceHeader."Shipping Advice"::Complete);
        ServiceHeader.Modify(true);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        WarehouseShipment.Trap();
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);
        WarehouseShipmentHeader.Get(Format(WarehouseShipment."No.".Value()));

        // EXECUTE: Create an warehouse shipment with the release service order.
        // EXECUTE: Create and register pick for the full quantity.
        // EXECUTE: Edit the whse. shipment lines to ship partially.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        GetWarehouseShipmentLinesByShipmentHeader(WarehouseShipmentLine, WarehouseShipmentHeader);
        FirstShipmentQuantity := LibraryRandom.RandIntInRange(1, Quantity - 1);
        WarehouseShipmentLine.Validate("Qty. to Ship", FirstShipmentQuantity);
        WarehouseShipmentLine.Modify(true);

        // VERIFY: Error is thrown when shipping a partial warehouse shipment with full shipping advice.
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        Assert.AreEqual(ServiceOrderShipmentErr, GetLastErrorText,
          'Error when shipping partially with fully shipping advice');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuspendStatusCheckReleasedServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // Setup: Create a service order with service lines
        CreateServiceOrderWithServiceLines(ServiceHeader);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // Execute: Suspend status check
        GetAllServiceLinesOfTypeItem(ServiceLine, ServiceHeader);
        ServiceLine.SuspendStatusCheck(true);

        // Verify that service line can be edited with status check suspended.
        ServiceLine.Validate(Quantity, ServiceLine.Quantity + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOnWhiteWithNonItemLines()
    begin
        Initialize();

        // Post a Service Invoice on WHITE Location with lines of type not item.
        TestPostServiceInvoiceWithNonItemLines(WMSFullLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOnYellowWithNonItemLines()
    begin
        Initialize();

        // Post a Service Invoice on Yellow Location with lines of type not item.
        TestPostServiceInvoiceWithNonItemLines(YellowLocationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOnSilverWithNonItemLines()
    var
        SilverLocation: Record Location;
        Bin: Record Bin;
    begin
        Initialize();

        // Post a Service Invoice on Silver Location with lines of type not item.
        CreateSilverLocation(SilverLocation, Bin);
        TestPostServiceInvoiceWithNonItemLines(SilverLocation.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoOnWhiteWithNonItemLines()
    begin
        Initialize();

        // Post a Service Credit Memo on WHITE Location with lines of type not item.
        TestPostServiceCreditMemoWithNonItemLines(WMSFullLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoOnYellowWithNonItemLines()
    begin
        Initialize();

        // Post a Service Credit Memo on Yellow Location with lines of type not item.
        TestPostServiceCreditMemoWithNonItemLines(YellowLocationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoOnSilverWithNonItemLines()
    var
        SilverLocation: Record Location;
        Bin: Record Bin;
    begin
        Initialize();

        // Post a Service Credit Memo on Silver Location with lines of type not item.
        CreateSilverLocation(SilverLocation, Bin);
        TestPostServiceCreditMemoWithNonItemLines(SilverLocation.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOnSilverWithItemEmptyBinCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // Post service invoice for an Item with quantity in STOCK with empty bin code
        asserterror TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::Invoice, 1, 1, true);
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Bin Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOnSilverWithItemInStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service invoice for an Item with quantity in STOCK
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::Invoice, 1, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOnSilverWithItemOutOfStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service invoice for an Item with quantity out of STOCK
        asserterror TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::Invoice, 1, -1, false);
        Assert.IsTrue(StrPos(GetLastErrorText, QuantityInsufficientErrorTxt) > 0, QuantityInsufficientErrorTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoOnSilverWithItemInStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service Credit Memo for an Item with quantity in STOCK
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::"Credit Memo", 1, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoOnSilverWithItemOutOfStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service Credit Memo for an Item with quantity out of STOCK
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::"Credit Memo", 1, -1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoOnSilverWithItemEmptyBinCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // Post service Credit Memo for an Item with quantity in Stock and use empty Bin code
        asserterror TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::"Credit Memo", 1, 1, true);
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Bin Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOnYellowWithItemInStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service invoice for an Item with quantity in STOCK
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::Invoice, 2, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOnYellowWithItemOutOfStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service invoice for an Item with quantity in STOCK
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::Invoice, 2, -1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoOnYellowWithItemInStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service Credit Memo for an Item with quantity in STOCK
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::"Credit Memo", 2, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoOnYellowWithItemOutOfStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service Credit memo for an Item with quantity in STOCK
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::"Credit Memo", 2, -1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOnWhiteWithItemEmptyBinCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // Post service invoice for an Item with quantity in STOCK
        asserterror TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::Invoice, 3, 1, true);
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Bin Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOnWhiteWithItemInStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service invoice for an Item with quantity in STOCK
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::Invoice, 3, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceOnWhiteWithItemOutOfStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service invoice for an Item with quantity out of stock.
        asserterror TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::Invoice, 3, -1, false);
        Assert.IsTrue(StrPos(GetLastErrorText, QuantityInsufficientErrorTxt) > 0, QuantityInsufficientErrorTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCrMemoOnWhiteWithItemEmptyBinCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // Post service Credit Memo for an Item with quantity in STOCK with empty bin code
        asserterror TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::"Credit Memo", 3, 1, true);
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Bin Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCrMemoOnWhiteWithItemInStock()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Post service Credit Memo for an Item with quantity in STOCK
        TestPostServiceDocumentWithItem(ServiceHeader."Document Type"::"Credit Memo", 3, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceDocumentOnWhiteWithNonPickableBin()
    var
        Bin: Record Bin;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Zone: Record Zone;
        BinType: Record "Bin Type";
        Quantity: Integer;
        LineQuantity: Integer;
        LocationCode: Code[10];
        BinCode: Code[20];
    begin
        Initialize();

        // SETUP: Create Supply for that item in the specific location and bin.
        Quantity := LibraryRandom.RandIntInRange(2, 100);
        LineQuantity := Quantity - 1;

        LocationCode := WMSFullLocation;
        CreateItemAndSupply(Item, LocationCode, Quantity);

        // Find the non pickable zone and bin with quantity content.
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Location Code");
        FindPickableNonPickableZone(Zone, LocationCode, false, false); // We find a non-pickable zone
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, 2);  // Find Bin for Zone for Index 2.

        BinCode := Bin.Code;

        // EXECUTE: Create Service Invoice on the Location and use a non-pickable bin.
        // VERIFY: Error is displayed when a non-pickable bin is used.
        CreateServiceDocumentWithServiceLine(ServiceHeader, ServiceHeader."Document Type"::Invoice, Item."No.", LineQuantity, LocationCode);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        asserterror ServiceLine.Validate("Bin Code", BinCode);
        Assert.ExpectedTestFieldError(BinType.FieldCaption(Pick), Format(true));

        // EXECUTE: Create Service Credit memo on the Location and use a non-pickable bin.
        Clear(ServiceLine);
        Clear(ServiceHeader);
        CreateServiceDocumentWithServiceLine(ServiceHeader,
          ServiceHeader."Document Type"::"Credit Memo", Item."No.",
          LineQuantity, LocationCode);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Bin Code", BinCode);
        ServiceLine.Modify(true);

        // VERIFY: Service Document can be posted
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TryToShipServiceOrderWithCompleteShptAdvice()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Integer;
        FirstShipmentQuantity: Integer;
        ServLineNo: Integer;
    begin
        // Try to partially ship an order with 'Complete' shipping advice and last service line contains only description.

        // Setup: Create Service Order.
        Initialize();
        LocationCode := WMSFullLocation;
        Quantity := LibraryRandom.RandIntInRange(2, 100);
        CreateItemAndUpdateInventory(Item, LocationCode, Quantity);

        ServLineNo := CreateServiceOrderAndServiceLinesGetLineNo(ServiceHeader, Item."No.", Quantity, LocationCode);
        ServiceHeader.Validate("Shipping Advice", ServiceHeader."Shipping Advice"::Complete);
        ServiceHeader.Modify(true);
        ServiceLine.Get(ServiceLine."Document Type"::Order, ServiceHeader."No.", ServLineNo);
        AddDescriptionServiceLineToOrder(ServiceHeader, ServiceLine."Service Item Line No.", DescriptionTxt); // Descr. doesn't matter.

        // Execute: Edit the order service lines to ship partially.
        FirstShipmentQuantity := LibraryRandom.RandIntInRange(1, Quantity - 1);
        ServiceLine.Validate("Qty. to Ship", FirstShipmentQuantity);
        ServiceLine.Modify(true);

        // Verify: Error is thrown when shipping a partial service order with full shipping advice.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.ExpectedError(ServiceOrderShipmentErr);
    end;

    [Test]
    [HandlerFunctions('HandleGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure ResGLCostQtyToShipAfterItemWhseShipment()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        LocationCode: Code[10];
        ItemQty: Decimal;
        ServiceItemLineNo: Integer;
    begin
        // [FEATURE] [Warehouse]
        // [SCENARIO 123577] Resource, G/L Acount, Cost "Qty. to Ship" remains after post Item's Warehouse Shipment
        Initialize();

        // [GIVEN] Supply item on WHITE location
        LocationCode := WMSFullLocation;
        ItemQty := LibraryRandom.RandInt(100);
        CreateItemAndSupply(Item, LocationCode, ItemQty);

        // [GIVEN] Service Order with Item, Resource ("A" qty.), G/L Account ("B" qty.), Cost ("C" qty.)
        ServiceItemLineNo := CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", ItemQty, LocationCode);
        AddResourceGLServiceLinesToOrder(ServiceHeader, ServiceItemLineNo);

        // [GIVEN] Create warehouse shipment from Service Order, register Pick for item
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [WHEN] Post warehouse shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Resource "Qty. to Ship" = "A"
        // [THEN] G/L Account "Qty. to Ship" = "B"
        // [THEN] Cost "Qty. to Ship" = "C"
        VerifyResGLCostQtyToShip(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountAfterServiceOrderReopen()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        AmountIncludingVAT: Decimal;
    begin
        // [FEATURE] [Reopen]
        // [SCENARIO 378451] VAT Amount remains after reopen Service Order
        Initialize();

        // [GIVEN] Released service order with service lines
        CreateServiceOrderWithServiceLines(ServiceHeader);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        AmountIncludingVAT := ServiceLine."Amount Including VAT";

        // [WHEN] Re-open the service order
        LibraryService.ReopenServiceDocument(ServiceHeader);

        // [THEN] Service Line Amount Including VAT remains
        ServiceLine.Find();
        ServiceLine.TestField("Amount Including VAT", AmountIncludingVAT);
    end;

    [Test]
    [HandlerFunctions('HandleWarehouseShipmentCreatedMessage,VerifyNoDocumentInGetSourceDocuments')]
    [Scope('OnPrem')]
    procedure NoSourceDocToWhseShpmtWhenServLinesCompletelyShipped()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Warehouse Shipment] [Get Source Documents]
        // [SCENARIO 379395] "Get Source Documents" should not find Source Document when Sevice Lines with Items are completely shipped.
        Initialize();

        // [GIVEN] Location with "Require Shipment".
        CreateLocationWithRequireShip(LocationCode);
        // [GIVEN] Service Order with Service Lines as Item, Resourse, Cost and G/L Account.
        CreateSeviceOrderWithSeviceLinesAsItemResCostGL(ServiceHeader, LocationCode);
        // [GIVEN] Release Service Order and post Warehouse Shipment as ship.
        ReleaseServiceHeaderAndCreateWarehouseShipment(ServiceHeader, WarehouseShipmentHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        // [GIVEN] Create Warehouse Shipment.
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);

        // [WHEN] Run the procedure "Get Source Documents"
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);

        // [THEN] Source Document is not found.
        // Checked on PageHandler named VerifyNoDocumentInGetSourceDocuments.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingAgentServiceCodeFromWhseShpmtToServiceOrder()
    var
        Location: Record Location;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ShippingAgentCode: array[2] of Code[10];
        ShippingAgentServiceCode: array[2] of Code[10];
    begin
        // [FEATURE] [Service Order] [Service Shipment] [Shipping Agent Service]
        // [SCENARIO 267371] Empty value of Shipping Agent Service Code must be transferred from Warehouse Shipment to Service Order when Warehouse Shipment is being posted

        Initialize();

        // [GIVEN] Create Location which is set up for Whse Shipment
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);

        // [GIVEN] Create Item with stock
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJrnlWithLocationAndCost(Item."No.", LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(100), Location.Code);

        // [GIVEN] Create Shipping Agent with service code
        CreateShippingAgentServiceCodeWith1YShippingTime(ShippingAgentCode[1], ShippingAgentServiceCode[1]);

        // [GIVEN] Create another Shipping Agent with empty service code
        CreateShippingAgentServiceCodeWith1YShippingTime(ShippingAgentCode[2], ShippingAgentServiceCode[2]);
        ShippingAgentServiceCode[2] := '';

        // [GIVEN] Create Service Order with Shipping Agent, Shipping Agent Service Code and single line
        CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(5), Location.Code);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.Validate("Shipping Agent Code", ShippingAgentCode[1]);
        ServiceHeader.Validate("Shipping Agent Service Code", ShippingAgentServiceCode[1]);
        ServiceHeader.Modify(true);

        // [GIVEN] Release Service Order and create whse. shipment
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);

        // [GIVEN] Find and modify "Shipping Agent Service Code" in whse. shipment using void value
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Service Line", 1, ServiceHeader."No."));
        WarehouseShipmentHeader.Validate("Shipping Agent Code", ShippingAgentCode[2]);
        WarehouseShipmentHeader.Validate("Shipping Agent Service Code", ShippingAgentServiceCode[2]);
        WarehouseShipmentHeader.Modify(true);

        // [WHEN] Post whse. shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Void value of Shipping Agent Service Code field is inherited from whse. shipment to Service Header
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.TestField("Shipping Agent Service Code", ShippingAgentServiceCode[2]);
    end;

    local procedure Initialize()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Order Release");
        ClearGlobals();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Order Release");

        LibraryERMCountryData.CreateVATData();
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        LibrarySetupStorage.Save(DATABASE::"Warehouse Setup");

        IsInitialized := true;
        WMSFullLocation := GetWhiteLocation();
        YellowLocationCode := CreateYellowLocation(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, WMSFullLocation, true);
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Order Release");
    end;

    local procedure AddResourceGLServiceLinesToOrder(var ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer)
    var
        Resource: Record Resource;
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        LibraryERM: Codeunit "Library - ERM";
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        UpdateServiceLine(ServiceLine, ServiceItemLineNo, LibraryRandom.RandInt(100));
        Clear(ServiceLine);
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        UpdateServiceLine(ServiceLine, ServiceItemLineNo, LibraryRandom.RandInt(100));
        Clear(ServiceLine);
        LibraryService.FindServiceCost(ServiceCost);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
        UpdateServiceLine(ServiceLine, ServiceItemLineNo, LibraryRandom.RandInt(100));
        Clear(ServiceLine);
    end;

    local procedure AddItemServiceLinesToOrder(var ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer; ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Integer
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        UpdateServiceLine(ServiceLine, ServiceItemLineNo, ItemQuantity);
        ServiceLine.SetHideReplacementDialog(true);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify();
        exit(ServiceLine."Line No.");
    end;

    local procedure AddNewServiceItemLinesToOrder(var ServiceHeader: Record "Service Header"): Integer
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        exit(ServiceItemLine."Line No.");
    end;

    local procedure AddDescriptionServiceLineToOrder(var ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer; LineDescription: Text[50]): Integer
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::" ", '');
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Description, LineDescription);
        ServiceLine.Modify();
        exit(ServiceLine."Line No.");
    end;

    local procedure AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocumentNoToSelect: Code[20]; SourceDocumentTypeToSelect: Text[200])
    var
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        SourceDocumentNo := SourceDocumentNoToSelect;
        SourceDocumentType := SourceDocumentTypeToSelect;
        GetSourceDocOutbound.GetSingleOutboundDoc(WarehouseShipmentHeader);
    end;

    local procedure CalculateAndPostWhseAdjustment(Item: Record Item; LocationCode: Code[10])
    begin
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, true);
        ItemJournalSetup();
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateCustomerWithShippingDetails(var Customer: Record Customer; CustomerShippingTime: Text[10])
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingTime: DateFormula;
        ShippingAgentServicesCode: array[6] of Code[10];
    begin
        LibrarySales.CreateCustomer(Customer);

        CreateShippingAgentServices(ShippingAgent, ShippingAgentServicesCode);
        Customer.Validate("Shipping Agent Code", ShippingAgent.Code);
        Customer.Validate("Shipping Agent Service Code", ShippingAgentServicesCode[LibraryRandom.RandIntInRange(1, 6)]);

        if CustomerShippingTime <> '' then begin
            Evaluate(ShippingTime, CustomerShippingTime);
            Customer.Validate("Shipping Time", ShippingTime);
        end;

        Customer.Modify(true);
    end;

    local procedure CreateItemAndSupply(var Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateItemAndUpdateInventory(Item, LocationCode, Quantity);
        CreatePutAwayForPurchaseOrder(LocationCode, Item."No.", Quantity);
    end;

    local procedure CreateItemAndUpdateInventory(var Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        Location: Record Location;
        FirstZone: Record Zone;
        FirstBin: Record Bin;
    begin
        LibraryInventory.CreateItem(Item);
        FindZonesAndBins(FirstZone, FirstBin, LocationCode);
        FindLocationByCode(Location, LocationCode);
        UpdateInventoryUsingWhseAdjustmentForTwoZone(Location, Item, Quantity, FirstZone.Code, FirstBin.Code);  // For large Quantity.
    end;

    local procedure CreateItemAndSupplyForYellowLocation(var Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        CreatePutAwayForPurchaseOrder(LocationCode, Item."No.", Quantity);
    end;

    local procedure CreateItemAndSupplyForSilverLocation(var Item: Record Item; Location: Record Location; Bin: Record Bin; Quantity: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBinContent(
          BinContent, Location.Code, '', Bin.Code, LibraryInventory.CreateItem(Item), '', Item."Base Unit of Measure");
        CreateQuantityForLocationWithBin(Location, Bin, Item, Quantity);
    end;

    local procedure CreateAndPostItemJrnlWithLocationAndCost(ItemNo: Code[20]; Qty: Decimal; Cost: Decimal; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Qty);
        ItemJournalLine.Validate("Unit Cost", Cost);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        // Creates a new Location. Wrapper for the library method.
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    local procedure CreateLocationWithRequireShip(var LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        LocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
    end;

    local procedure CreateFullWarehouseLocation(var Location: Record Location)
    begin
        LibraryService.CreateFullWarehouseLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreateSeviceOrderWithSeviceLinesAsItemResCostGL(var ServiceHeader: Record "Service Header"; LocationCode: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
        ServiceLine: Record "Service Line";
        ServiceItemLineNo: Integer;
    begin
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);
        ServiceItemLineNo :=
          CreateServiceOrderAndServiceLines(
            ServiceHeader, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100), LocationCode);
        AddResourceGLServiceLinesToOrder(ServiceHeader, ServiceItemLineNo);
        SetLocationCodeOnServiceLines(ServiceLine, ServiceHeader, LocationCode, ServiceItemLineNo);
    end;

    local procedure CreateYellowLocation(var Location: Record Location): Code[10]
    begin
        exit(LibraryService.CreateDefaultYellowLocation(Location));
    end;

    local procedure CreateSilverLocation(var Location: Record Location; var Bin: Record Bin): Code[10]
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        exit(Location.Code);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // Create Purchase Order with One Item Line. Random values used are not important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationCode, ItemNo, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndPostWhseReceiptFromPO(var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure CreatePutAwayForPurchaseOrder(LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateQuantityForLocationWithBin(Location: Record Location; Bin: Record Bin; Item: Record Item; Quantity: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalSetup();
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine,
          ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          Item."No.",
          Quantity);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateShippingAgentServices(var ShippingAgent: Record "Shipping Agent"; var ShippingAgentServicesCode: array[6] of Code[10])
    var
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
        j: Integer;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);

        for j := 1 to 6 do begin
            Evaluate(ShippingTime, '<' + Format(j) + 'D>');
            LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
            ShippingAgentServicesCode[j] := ShippingAgentServices.Code;
        end;
    end;

    local procedure CreateShippingAgentServiceCodeWith1YShippingTime(var ShippingAgentCode: Code[10]; var ShippingAgentServiceCode: Code[10])
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        Evaluate(ShippingTime, '<+1Y>');
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        ShippingAgentCode := ShippingAgentServices."Shipping Agent Code";
        ShippingAgentServiceCode := ShippingAgentServices.Code;
    end;

    local procedure CreateServiceDocumentWithServiceLine(var ServiceHeader: Record "Service Header"; ServiceDocumentType: Enum "Service Document Type"; ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10])
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceDocumentType, Customer."No.");
        ServiceHeader.Validate("Location Code", LocationCode);
        ServiceHeader.Modify(true);
        AddItemServiceLinesToOrder(ServiceHeader, 0, ItemNo, ItemQuantity, LocationCode);
    end;

    local procedure CreateServiceOrderAndServiceLines(var ServiceHeader: Record "Service Header"; ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Integer
    var
        ServiceItemLineNo: Integer;
    begin
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader);
        AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, ItemNo, ItemQuantity, LocationCode);
        exit(ServiceItemLineNo);
    end;

    local procedure CreateServiceOrderAndServiceLinesGetLineNo(var ServiceHeader: Record "Service Header"; ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Integer
    var
        ServiceItemLineNo: Integer;
    begin
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader);
        exit(AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, ItemNo, ItemQuantity, LocationCode));
    end;

    local procedure CreateServiceOrderWithServiceLines(var ServiceHeader: Record "Service Header"): Integer
    var
        Item: Record Item;
        ServiceItemLineNo: Integer;
    begin
        LibraryInventory.CreateItem(Item);
        ServiceItemLineNo := CreateServiceOrderAndServiceLines(ServiceHeader, Item."No.", LibraryRandom.RandInt(100), '');
        exit(ServiceItemLineNo);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"): Integer
    var
        Customer: Record Customer;
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        UpdateAccountsInCustPostingGroup(ServiceItem."Customer No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        exit(ServiceItemLine."Line No.");
    end;

    local procedure CreateWarehouseShipmentFromServiceHeader(ServiceHeader: Record "Service Header")
    var
        ServGetSourceDocOutbound: Codeunit "Serv. Get Source Doc. Outbound";
    begin
        ServGetSourceDocOutbound.CreateFromServiceOrder(ServiceHeader);
    end;

    local procedure CreateWarehouseShipmentFromSalesOrder(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseShipmentHeaderNo: Code[20];
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeaderNo :=
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
            DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentHeaderNo);
    end;

    local procedure CreateWareHouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10]): Code[20]
    begin
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", LocationCode);
        WarehouseShipmentHeader.Modify(true);
        exit(WarehouseShipmentHeader."No.");
    end;

    local procedure CreateAndRegisterWarehousePick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(SourceNo, WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure FindLocationByCode(var Location: Record Location; LocationCode: Code[10])
    begin
        Location.SetRange(Code, LocationCode);
        Location.FindFirst();
    end;

    local procedure FindFirstServiceLineByServiceHeader(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
    end;

    local procedure FindServiceLinesByHeaderNo(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    local procedure FindWarehouseActivityNo(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"): Code[20]
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
        exit(WarehouseActivityLine."No.");
    end;

    local procedure FindWarehouseReceiptNo(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
        exit(WarehouseReceiptLine."No.");
    end;

    local procedure FindWarehouseShipmentLinesByServiceOrder(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; ServiceHeader: Record "Service Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        Clear(WarehouseShipmentLine);
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseShipmentLine.SetRange("Source Subtype", 1);
        WarehouseShipmentLine.SetRange("Source No.", ServiceHeader."No.");
        WarehouseShipmentLine.FindSet();
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

    local procedure FindZonesAndBins(var FirstZone: Record Zone; var FirstBin: Record Bin; LocationCode: Code[10])
    begin
        FindPickableNonPickableZone(FirstZone, LocationCode, false, true);
        LibraryWarehouse.FindBin(FirstBin, LocationCode, FirstZone.Code, 2);  // Find Bin for Zone for Index 2.
    end;

    local procedure FindPickableNonPickableZone(var Zone: Record Zone; LocationCode: Code[10]; NewZone: Boolean; FindPickable: Boolean)
    var
        Step: Integer;
    begin
        Zone.SetRange("Location Code", LocationCode);
        if NewZone then begin
            Zone.FindLast();
            Step := -1;
        end else begin
            Zone.FindFirst();
            Step := 1;
        end;
        while not ZoneIsPickableNonPickable(Zone, FindPickable) do
            Zone.Next(Step);
    end;

    local procedure ZoneIsPickableNonPickable(Zone: Record Zone; TakePickable: Boolean): Boolean
    var
        BinType: Record "Bin Type";
    begin
        BinType.Get(Zone."Bin Type Code");
        if TakePickable then
            exit(BinType.Pick);
        exit(not BinType.Pick);
    end;

    local procedure GetWarehouseShipmentLinesByShipmentHeader(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        Clear(WarehouseShipmentLine);
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindSet();
    end;

    local procedure GetSalesLinesOfTypeItem(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindSet();
    end;

    local procedure GetAllServiceLinesOfTypeItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        FindServiceLinesByHeaderNo(ServiceLine, ServiceHeader);
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.FindSet();
    end;

    local procedure GetWarehouseEntries(var ServiceLine: Record "Service Line"; var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option)
    begin
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"Serv. Order");
        WarehouseEntry.SetRange("Source No.", ServiceLine."Document No.");
        WarehouseEntry.SetRange("Source Line No.", ServiceLine."Line No.");
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.FindSet();
    end;

    local procedure GetWhiteLocation(): Code[10]
    var
        LocationWhite: Record Location;
    begin
        LocationWhite.SetRange("Directed Put-away and Pick", true);
        LocationWhite.FindFirst();
        exit(LocationWhite.Code);
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(FindWarehouseReceiptNo(SourceDocument, SourceNo));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange(Type, Type);
        WarehouseActivityHeader.SetRange("No.", FindWarehouseActivityNo(SourceNo, Type));
        WarehouseActivityHeader.FindFirst();
        if Type = Type::"Put-away" then
            PlaceInNonPickableZones(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure PlaceInNonPickableZones(WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        FirstZone: Record Zone;
        FirstBin: Record Bin;
    begin
        FirstZone.SetRange("Location Code", WarehouseActivityHeader."Location Code");
        if FirstZone.IsEmpty() then
            exit;
        FirstZone.SetRange("Location Code");
        FindPickableNonPickableZone(FirstZone, WarehouseActivityHeader."Location Code", false, false); // We find a non-pickable zone
        LibraryWarehouse.FindBin(FirstBin, WarehouseActivityHeader."Location Code", FirstZone.Code, 2);  // Find Bin for Zone for Index 2.
        ModifyPutAwayLinesToNonPickableZoneBin(WarehouseActivityHeader, FirstZone.Code, FirstBin.Code);
    end;

    local procedure PrepareShipmentMultipleLines(var Item: Record Item; var ServiceHeader: Record "Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var LineQuantity: Integer; var Delta: Integer; RandomQuantity: Boolean)
    var
        LocationCode: Code[10];
        ServiceItemLineNo: Integer;
        Index: Integer;
    begin
        LocationCode := WMSFullLocation;

        ServiceItemLineNo := CreateServiceOrder(ServiceHeader);
        if not RandomQuantity then
            LineQuantity := LibraryRandom.RandInt(100);

        for Index := 1 to 5 do begin
            if RandomQuantity then
                LineQuantity := LibraryRandom.RandInt(100);
            Clear(Item);
            CreateItemAndSupply(Item, LocationCode, LineQuantity);
            AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LineQuantity, LocationCode);
        end;

        ServiceItemLineNo := AddNewServiceItemLinesToOrder(ServiceHeader);
        Delta := LibraryRandom.RandInt(10);
        if RandomQuantity then
            LineQuantity := LibraryRandom.RandInt(100);
        Clear(Item);
        CreateItemAndSupply(Item, LocationCode, LineQuantity);
        AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, Item."No.", LineQuantity + Delta, LocationCode);

        ServiceHeader.Find();
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWareHouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        AddWarehouseShipmentLineUsingGetSourceDocument(WarehouseShipmentHeader, ServiceHeader."No.", ServiceOrderInGridTxt);
    end;

    local procedure ModifyPutAwayLinesToNonPickableZoneBin(WarehouseActivityHeader: Record "Warehouse Activity Header"; ZoneCode: Code[10]; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Zone Code", ZoneCode);
                WarehouseActivityLine.Validate("Bin Code", BinCode);
                WarehouseActivityLine.Modify();
            until WarehouseActivityLine.Next() = 0;
    end;

    local procedure ReleaseServiceHeaderAndCreateWarehouseShipment(var ServiceHeader: Record "Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseShipment: TestPage "Warehouse Shipment";
        WarehouseShipmentHeaderNo: Code[20];
    begin
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        WarehouseShipment.Trap();
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);
        WarehouseShipmentHeaderNo := WarehouseShipment."No.".Value();
        WarehouseShipment.Close();
        Clear(WarehouseShipment);
        WarehouseShipmentHeader.Get(WarehouseShipmentHeaderNo);
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

    local procedure SetLocationCodeOnServiceLines(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; LocationCode: Code[10]; ServiceItemLineNo: Integer)
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::Resource, ServiceLine.Type::"G/L Account");
        ServiceLine.FindSet(true);
        repeat
            ServiceLine.Validate("Location Code", LocationCode);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure TestPostServiceDocumentWithItem(ServiceDocumentType: Enum "Service Document Type"; LocationType: Integer; LineQuantityDelta: Integer; IsBlankBincode: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Zone: Record Zone;
        WarehouseEntry: Record "Warehouse Entry";
        TempServiceLine: Record "Service Line" temporary;
        Quantity: Integer;
        LineQuantity: Integer;
        LocationCode: Code[10];
        BinCode: Code[20];
    begin
        // PARAM: LocationType Indicates the tyep of warehouse location that should be used, 1 - Silver, 2 - Yellow, 3 - White
        // PARAM: LineQuantityDelta: Quantity to subtract from the supply quantity set on the line
        // IsBlankBincode: Set Bin code ot blank in the service line

        // SETUP: Create an new location, create a new item.
        // SETUP: Create Supply for that item in the specific location and bin.
        Quantity := LibraryRandom.RandIntInRange(2, 100);
        LineQuantity := Quantity - LineQuantityDelta;

        BinCode := '';

        case LocationType of
            1: // SILVER
                begin
                    LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
                    CreateSilverLocation(Location, Bin);
                    CreateItemAndSupplyForSilverLocation(Item, Location, Bin, Quantity);
                    LocationCode := Location.Code;
                    BinCode := Bin.Code;
                end;
            2: // YELLOW
                begin
                    LocationCode := YellowLocationCode;
                    CreateItemAndSupplyForYellowLocation(Item, LocationCode, Quantity);
                end;
            3: // WHITE
                begin
                    LocationCode := WMSFullLocation;
                    CreateItemAndSupply(Item, LocationCode, Quantity);
                    FindZonesAndBins(Zone, Bin, LocationCode); // This the pickable zone
                    BinCode := Bin.Code;
                end;
        end;

        if IsBlankBincode then
            BinCode := '';

        // EXECUTE: Create Service Document on the Location.
        CreateServiceDocumentWithServiceLine(ServiceHeader, ServiceDocumentType, Item."No.", LineQuantity, LocationCode);
        FindFirstServiceLineByServiceHeader(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Bin Code", BinCode);
        ServiceLine.Modify(true);

        // VERIFY: Service Document has been posted
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        if ServiceDocumentType = ServiceHeader."Document Type"::"Credit Memo" then
            LineQuantity := -LineQuantity;
        VerifyQtyOnItemLedgerEntry(TempServiceLine, LineQuantity);

        // No Warehouse entries are created by yellow location.
        if LocationType = 2 then
            exit;

        if ServiceDocumentType = ServiceHeader."Document Type"::Invoice then
            GetAndVerifyWarehouseEntry(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.", -ServiceLine.Quantity)
        else
            GetAndVerifyWarehouseEntry(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.", ServiceLine.Quantity);

        Assert.AreEqual(WarehouseEntry.Count, 1, 'No. of warehouse entries created');
        WarehouseEntry.TestField("Bin Code", BinCode);
    end;

    local procedure TestPostServiceInvoiceWithNonItemLines(LocationCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        TestPostServiceDocumentWithNonItemLines(LocationCode, ServiceHeader."Document Type"::Invoice);
    end;

    local procedure TestPostServiceCreditMemoWithNonItemLines(LocationCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        TestPostServiceDocumentWithNonItemLines(LocationCode, ServiceHeader."Document Type"::"Credit Memo");
    end;

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
        AddResourceGLServiceLinesToOrder(ServiceHeader, 0);

        // EXECUTE: Post the Service Header
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // VERIFY: The Header has been posted and the posted documents can be found
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::Invoice then
            FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.")
        else
            FindServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
    end;

    local procedure UndoAllShipmentsForSalesHeader(SalesOrderNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Order No.", SalesOrderNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer; ItemQuantity: Integer)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, ItemQuantity);  // Use Random to select Random Quantity.
        ServiceLine.Modify(true);
    end;

    local procedure UpdateInventoryUsingWhseAdjustmentForTwoZone(Location: Record Location; Item: Record Item; Quantity: Decimal; ZoneCode: Code[10]; BinCode: Code[20])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, ZoneCode, BinCode,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        CalculateAndPostWhseAdjustment(Item, Location.Code);
    end;

    local procedure UpdateAccountsInCustPostingGroup(CustNo: Code[20])
    var
        Customer: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustNo);
        CustPostingGroup.Get(Customer."Customer Posting Group");
        if CustPostingGroup."Payment Disc. Debit Acc." = '' then
            CustPostingGroup.Validate("Payment Disc. Debit Acc.", LibraryERM.CreateGLAccountNo());
        if CustPostingGroup."Payment Disc. Credit Acc." = '' then
            CustPostingGroup.Validate("Payment Disc. Credit Acc.", LibraryERM.CreateGLAccountNo());
        CustPostingGroup.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        // Random values used are not important for test.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure ReserveFromSalesOrder(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines.Reserve.Invoke();
        SalesOrder.Close();
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Reserve: Boolean)
    begin
        CreateSalesOrder(SalesHeader, LocationCode, ItemNo, Quantity, WorkDate());
        if Reserve then
            ReserveFromSalesOrder(SalesHeader."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HandleWarehouseShipmentCreatedMessage(Message: Text[1024])
    begin
        ShipmentConfirmationMessage := Message;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleGetSourceDocuments(var SourceDocuments: TestPage "Source Documents")
    begin
        SourceDocuments.FILTER.SetFilter("Source No.", SourceDocumentNo);
        SourceDocuments.FILTER.SetFilter("Source Document", SourceDocumentType);
        Assert.AreEqual(SourceDocumentNo, SourceDocuments."Source No.".Value, 'Source Document no is found in the list');
        Assert.AreEqual(SourceDocumentType, SourceDocuments."Source Document".Value, 'Source Document Type found in the list');
        SourceDocuments.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyNoDocumentInGetSourceDocuments(var SourceDocuments: TestPage "Source Documents")
    begin
        SourceDocuments.FILTER.SetFilter("Source No.", SourceDocumentNo);
        SourceDocuments.FILTER.SetFilter("Source Document", SourceDocumentType);
        Assert.AreEqual('', SourceDocuments."Source No.".Value, 'Source Document no is found in the list');
        SourceDocuments.Cancel().Invoke();
    end;

    local procedure VerifyWarehouseShipmentLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ServiceLine: Record "Service Line")
    begin
        repeat
            WarehouseShipmentLine.SetRange("Source Line No.", ServiceLine."Line No.");
            WarehouseShipmentLine.FindSet();
            Assert.AreEqual(1, WarehouseShipmentLine.Count, 'Only one warehouse shipment line per service line is present');
            Assert.AreEqual(ServiceLine.Quantity, WarehouseShipmentLine.Quantity, 'Whse shpmt Quantity matches service line');
            Assert.AreEqual(
              ServiceLine."Location Code", WarehouseShipmentLine."Location Code", 'Whse shpmt location code matches service line');
            Assert.AreEqual(
              ServiceLine."Document No.", WarehouseShipmentLine."Source No.", 'Whse shpmt Source No matches service document no');
        until (ServiceLine.Next() = 0);
    end;

    local procedure VerifyServiceHeaderReleaseStatus(ServiceHeader: Record "Service Header"; ReleaseStatus: Enum "Service Doc. Release Status"; ServiceHeaderStatus: Enum "Service Document Status")
    begin
        Assert.AreEqual(ReleaseStatus, ServiceHeader."Release Status", 'Verify Release Status');
        Assert.AreEqual(ServiceHeaderStatus, ServiceHeader.Status, 'Verify Status of Service Header');
    end;

    local procedure VerifyUpdatedShipQtyAfterShip(var TempServiceLineBeforePosting: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify that the value of the field Quantity Shipped of the new Service Line is equal to the value of the field
        // Qty. to Ship of the relevant old Service Line.
        TempServiceLineBeforePosting.FindSet();
        repeat
            ServiceLine.Get(
              TempServiceLineBeforePosting."Document Type", TempServiceLineBeforePosting."Document No.",
              TempServiceLineBeforePosting."Line No.");
            ServiceLine.TestField("Quantity Shipped", TempServiceLineBeforePosting."Quantity Shipped");
            ServiceLine.TestField("Qty. to Ship", 0);
        until TempServiceLineBeforePosting.Next() = 0;
    end;

    local procedure VerifyQtyOnServiceShipmentLine(var TempServiceLineBeforePosting: Record "Service Line" temporary; QuantityShipped: Decimal)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Verify that the values of the fields Qty. Shipped Not Invoiced and Quantity of Service Shipment Line are equal to the value of
        // the field Qty. to Ship of the relevant Service Line.
        TempServiceLineBeforePosting.FindSet();
        ServiceShipmentLine.SetRange("Order No.", TempServiceLineBeforePosting."Document No.");
        repeat
            ServiceShipmentLine.SetRange("Order Line No.", TempServiceLineBeforePosting."Line No.");
            ServiceShipmentLine.FindLast();  // Find the Shipment Line for the second shipment.
            ServiceShipmentLine.TestField("Qty. Shipped Not Invoiced", TempServiceLineBeforePosting."Qty. to Ship");
            ServiceShipmentLine.TestField(Quantity, -QuantityShipped);
        until TempServiceLineBeforePosting.Next() = 0;
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

    local procedure VerifyValueEntry(var TempServiceLineBeforePosting: Record "Service Line" temporary; QuantityShipped: Decimal)
    var
        ValueEntry: Record "Value Entry";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // Verify that the value ofthe field Valued Quantity of the Value Entry is equal to the value of the field Qty. to Ship of
        // the relevant Service Line.
        TempServiceLineBeforePosting.FindSet();
        ServiceShipmentHeader.SetRange("Order No.", TempServiceLineBeforePosting."Document No.");
        ServiceShipmentHeader.FindLast();  // Find the second shipment.
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Service Shipment");
        ValueEntry.SetRange("Document No.", ServiceShipmentHeader."No.");
        repeat
            ValueEntry.SetRange("Document Line No.", TempServiceLineBeforePosting."Line No.");
            ValueEntry.FindLast();
            ValueEntry.TestField("Valued Quantity", -QuantityShipped);
        until TempServiceLineBeforePosting.Next() = 0;
    end;

    local procedure VerifyServiceLedgerEntry(var TempServiceLineBeforePosting: Record "Service Line" temporary; QuantityShipped: Decimal)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // Verify that the Service Ledger Entry created corresponds with the relevant Service Line by matching the fields No., Posting Date
        // and Bill-to Customer No.
        TempServiceLineBeforePosting.FindSet();
        ServiceShipmentHeader.SetRange("Order No.", TempServiceLineBeforePosting."Document No.");
        ServiceShipmentHeader.FindLast();  // Find the second shipment.
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Document No.", ServiceShipmentHeader."No.");
        repeat
            ServiceLedgerEntry.SetRange("Document Line No.", TempServiceLineBeforePosting."Line No.");
            ServiceLedgerEntry.FindLast();
            ServiceLedgerEntry.TestField("No.", TempServiceLineBeforePosting."No.");
            ServiceLedgerEntry.TestField("Posting Date", TempServiceLineBeforePosting."Posting Date");
            ServiceLedgerEntry.TestField("Bill-to Customer No.", TempServiceLineBeforePosting."Bill-to Customer No.");
            ServiceLedgerEntry.TestField(Quantity, -QuantityShipped);
            ServiceLedgerEntry.TestField("Charged Qty.", -QuantityShipped);
        until TempServiceLineBeforePosting.Next() = 0;
    end;

    local procedure VerifyWarehouseEntry(var ServiceLine: Record "Service Line"; var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option; QuantityPosted: Decimal)
    begin
        WarehouseEntry.TestField("Location Code", ServiceLine."Location Code");
        WarehouseEntry.TestField("Item No.", ServiceLine."No.");
        WarehouseEntry.TestField(Quantity, QuantityPosted);
        WarehouseEntry.TestField("Qty. (Base)", QuantityPosted);
        WarehouseEntry.TestField("Entry Type", EntryType);
    end;

    local procedure GetAndVerifyWarehouseEntry(var ServiceLine: Record "Service Line"; var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option; QuantityPosted: Decimal)
    begin
        Clear(WarehouseEntry);
        GetWarehouseEntries(ServiceLine, WarehouseEntry, EntryType);
        VerifyWarehouseEntry(ServiceLine, WarehouseEntry, EntryType, QuantityPosted);
    end;

    local procedure VerifyNoWarehouseEntriesCreated(var ServiceLine: Record "Service Line")
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"Serv. Order");
        WarehouseEntry.SetRange("Source No.", ServiceLine."Document No.");
        WarehouseEntry.SetRange("Source Line No.", ServiceLine."Line No.");
        Assert.AreEqual(false, WarehouseEntry.Find(), 'No Ware house entries are created');
    end;

    local procedure VerifyQtyOnItemLedgerEntryAfterShip(var ServiceLine: Record "Service Line"; QuantityShipped: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify that the value of the field Quantity of the Item Ledger Entry is equal to the value of the field Qty. to Ship of the
        // relevant Service Line after a shipment has been posted and not invoiced
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Service);
        ItemLedgerEntry.SetRange("Order No.", ServiceLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", ServiceLine."Line No.");
        ItemLedgerEntry.FindLast();  // Find the Item Ledger Entry for the second shipment.
        ItemLedgerEntry.TestField(Quantity, -QuantityShipped);
    end;

    local procedure VerifyValueEntryAfterShip(var ServiceLine: Record "Service Line"; QuantityShipped: Decimal)
    var
        ValueEntry: Record "Value Entry";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // Verify that the value ofthe field Valued Quantity of the Value Entry is equal to the value of the Quantity shipped of
        // the relevant Service Line after a shipment has been posted and not invoiced
        ServiceShipmentHeader.SetRange("Order No.", ServiceLine."Document No.");
        ServiceShipmentHeader.FindLast();  // Find the second shipment.
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Service Shipment");
        ValueEntry.SetRange("Document No.", ServiceShipmentHeader."No.");
        ValueEntry.SetRange("Document Line No.", ServiceLine."Line No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Valued Quantity", -QuantityShipped);
    end;

    local procedure VerifyServiceLedgerEntryAfterShip(var ServiceLine: Record "Service Line"; QuantityShipped: Decimal)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // Verify that the Service Ledger Entry created corresponds with the relevant Service Line by matching the fields No., Posting Date
        // and Bill-to Customer No. after a shipment has been posted and not invoiced
        ServiceShipmentHeader.SetRange("Order No.", ServiceLine."Document No.");
        ServiceShipmentHeader.FindLast();  // Find the second shipment.
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Document No.", ServiceShipmentHeader."No.");

        ServiceLedgerEntry.SetRange("Document Line No.", ServiceLine."Line No.");
        ServiceLedgerEntry.FindLast();
        ServiceLedgerEntry.TestField("No.", ServiceLine."No.");
        ServiceLedgerEntry.TestField("Posting Date", ServiceLine."Posting Date");
        ServiceLedgerEntry.TestField("Bill-to Customer No.", ServiceLine."Bill-to Customer No.");
        ServiceLedgerEntry.TestField(Quantity, QuantityShipped);
        ServiceLedgerEntry.TestField("Charged Qty.", QuantityShipped);
    end;

    local procedure VerifyQtyOnServiceShipmentLineAfterShip(var ServiceLine: Record "Service Line"; QuantityShipped: Decimal)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Verify that the values of the fields Qty. Shipped Not Invoiced and Quantity of Service Shipment Line are equal to the value of
        // the field Qty. to Ship of the relevant Service Line.
        ServiceLine.FindSet();
        ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
        ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
        ServiceShipmentLine.FindLast();  // Find the Shipment Line for the second shipment.
        ServiceShipmentLine.TestField("Qty. Shipped Not Invoiced", QuantityShipped);
        ServiceShipmentLine.TestField(Quantity, QuantityShipped);
    end;

    local procedure VerifyServiceLineAfterFullUndoShipment(var ServiceLine: Record "Service Line"; LineQuantity: Integer)
    var
        Location: Record Location;
        QuantityToCheck: Integer;
    begin
        // Verify that service line has all quantites set to correct values after a complete undo
        ServiceLine.TestField("Quantity Shipped", 0);
        ServiceLine.TestField("Quantity Invoiced", 0);
        ServiceLine.TestField(Quantity, LineQuantity);
        QuantityToCheck := LineQuantity;
        if '' <> ServiceLine."Location Code" then begin
            FindLocationByCode(Location, ServiceLine."Location Code");
            if Location."Require Shipment" then
                QuantityToCheck := 0
        end;
        ServiceLine.TestField("Qty. to Ship", QuantityToCheck);
        ServiceLine.TestField("Qty. to Invoice", QuantityToCheck);
    end;

    local procedure VerifyServiceShipmentLineAfterFullUndo(var TempServiceLine: Record "Service Line" temporary; QuantityShipped: Decimal)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Verify service shipment line quantities match after all shipments are undone
        ServiceShipmentLine.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceShipmentLine.SetRange("Order Line No.", TempServiceLine."Line No.");
        ServiceShipmentLine.FindLast();
        ServiceShipmentLine.TestField("Qty. Shipped Not Invoiced", TempServiceLine."Quantity Shipped");
        ServiceShipmentLine.TestField(Quantity, -QuantityShipped);
    end;

    local procedure VerifyServiceLineAfterOnlyShip(var ServiceLine: Record "Service Line"; Delta: Integer)
    begin
        // Verify that service line has all quantites set to correct values after a complete undo
        Assert.AreEqual(
          ServiceLine.Quantity - Delta, ServiceLine."Quantity Shipped", StrSubstNo('Service line Field %1: Matches', ServiceLine.FieldCaption("Quantity Shipped")));
        Assert.AreEqual(
          ServiceLine.Quantity - Delta, ServiceLine."Qty. Shipped Not Invoiced",
          StrSubstNo('Service line Field %1: Matches', ServiceLine.FieldCaption("Qty. Shipped Not Invoiced")));
    end;

    local procedure VerifyResGLCostQtyToShip(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange(Type, ServiceLine.Type::Resource, ServiceLine.Type::"G/L Account");
        FindServiceLinesByHeaderNo(ServiceLine, ServiceHeader);
        repeat
            Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Qty. to Ship", ServiceLine.FieldCaption("Qty. to Ship"));
        until ServiceLine.Next() = 0;
    end;
}

