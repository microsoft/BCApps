// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Setup;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;

codeunit 136142 "Service Warehouse Integration"
{
    Permissions = TableData "Whse. Item Tracking Line" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Service]
    end;

    var
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ItemNo: array[4] of Code[20];
        SerialItem: Code[20];
        LotItem: Code[20];
        LotItemReservation: Code[20];
        SerialLotItem: Code[20];
        ServiceItemNo: Code[20];
        CustomerNo: Code[20];
        ResourceNo: Code[20];
        GLAccountNo: Code[20];
        UsedVariantCode: array[2] of Code[10];
        WhiteLocationCode: Code[10];
        UsedBinCode: Code[20];
        WhseTemplate: Code[10];
        WhseBatch: Code[10];
        NoSeriesName: Code[20];
        OldServiceOrderNoSeriesName: Code[20];
        OldServiceInvoiceNoSeriesName: Code[20];
        OldServiceShipmentNumbers: Code[20];
        WhseSourceFilter: array[10] of Code[10];
        OldWhsePostingSetting: Integer;
        OldRequireShipmentSetting: Boolean;
        OldOutboundWhseHandlingTime: DateFormula;
        BasicDataInitialized: Boolean;
        SetupDataInitialized: Boolean;
        DefaultLocationCodeForUser: Code[20];
        OldStockoutWarning: Boolean;
        OldCreditWarning: Option;
        ItemJournalTemplateName: Code[10];
        ItemJournalBatchName: Code[10];
        Text002: Label 'The entered information may be disregarded by warehouse activities.';
        ShipmentMethodCode: Code[10];
        ShippingAgentCode: Code[10];
        ShippingAgentServicesCode: Code[10];
        LocationOutboundWhseHandlingTime: array[2] of DateFormula;
        InvSetupOutboundWhseHandlingTime: array[2] of DateFormula;
        ServiceHeaderShippingTime: array[2] of DateFormula;
        SerialNoCode: Code[10];
        LotNoCode: Code[10];
        SerialLotCode: Code[10];
        ServiceLineNo: Integer;
        ItemTrackingOption: Integer;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentFromOpenOrder()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] Try to create whse shipment from an open service order. Error expected.
        Initialize();
        CreateServiceOrder(ServiceHeader, 2, WhiteLocationCode, 0, 0, 0, 0, false);
        CreateWhseShipment(ServiceHeader, false);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentFromReleased()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] Try to create whse shipment from existing released service order. Message expected. Possible to navigate to Whse shipment lines with correct contents.
        Initialize();
        CreateServiceOrder(ServiceHeader, 3, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);
        VerifyWhseShipmentLinesAgainstServiceOrder(ServiceHeader."No.", false); // No date check because the whse shipment header does not have a blank shipment date.
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenFieldsNotModifiable()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] Reopen service order and verify that certain fields cannot be modified.
        Initialize();
        CreateServiceOrder(ServiceHeader, 4, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);
        LibraryService.ReopenServiceDocument(ServiceHeader);
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.FindFirst();

        // Verification contains several consequent error assertions, hence need to commit to avoid rollback after the first error
        Commit();
        CheckServiceLineNoModification(ServiceLine);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenLinesWithWhseRefCannotBeDeleted()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] Reopen service order and verify that lines with reference to whse shipment cannot be deleted.
        Initialize();
        CreateServiceOrder(ServiceHeader, 5, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);
        LibraryService.ReopenServiceDocument(ServiceHeader);
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.FindFirst();
        asserterror ServiceLine.Delete(true);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickFromWhseShipmentVerifyPickLines()
    var
        ServiceHeader: Record "Service Header";
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
    begin
        // [SCENARIO] Try to create pick from Whse shipment. Verify pick lines
        Initialize();
        CreateServiceOrder(ServiceHeader, 6, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);
        CollectWarehouseShipmentLines(ServiceHeader."No.", TempWarehouseShipmentLine);
        TempWarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(TempWarehouseShipmentLine."No.");
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WhseShipmentCreatePick.SetWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetHideValidationDialog(true);
        WhseShipmentCreatePick.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        WhseShipmentCreatePick.UseRequestPage(false);
        WhseShipmentCreatePick.RunModal();
        Clear(WhseShipmentCreatePick);
        VerifyWhseShptLinesAgainstPick(ServiceHeader."No.", TempWarehouseShipmentLine."No.");
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickVerifyRegisteredPick()
    var
        ServiceHeader: Record "Service Header";
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
    begin
        // [SCENARIO] Try to register pick. Verify that registered pick exists.
        Initialize();
        CreateServiceOrder(ServiceHeader, 7, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);
        CollectWarehouseShipmentLines(ServiceHeader."No.", TempWarehouseShipmentLine);
        TempWarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(TempWarehouseShipmentLine."No.");
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WhseShipmentCreatePick.SetWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetHideValidationDialog(true);
        WhseShipmentCreatePick.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        WhseShipmentCreatePick.UseRequestPage(false);
        WhseShipmentCreatePick.RunModal();
        Clear(WhseShipmentCreatePick);
        RegisterPick(TempWarehouseShipmentLine."No.");
        VerifyWhseShptLinesAgainstRegisteredPick(ServiceHeader."No.", TempWarehouseShipmentLine."No.");
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWhseShipmentAsShip()
    var
        ServiceHeader: Record "Service Header";
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        // [SCENARIO] Post warehouse shipment as ship and verify that:
        // [SCENARIO] Non-posted whse shipment is deleted; Posted whse shipment is created; Service Shipment is created
        Initialize();
        CreateServiceOrder(ServiceHeader, 8, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);
        CollectWarehouseShipmentLines(ServiceHeader."No.", TempWarehouseShipmentLine);
        TempWarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(TempWarehouseShipmentLine."No.");
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WhseShipmentCreatePick.SetWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetHideValidationDialog(true);
        WhseShipmentCreatePick.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        WhseShipmentCreatePick.UseRequestPage(false);
        WhseShipmentCreatePick.RunModal();
        Clear(WhseShipmentCreatePick);
        RegisterPick(TempWarehouseShipmentLine."No.");
        VerifyWhseShptLinesAgainstRegisteredPick(ServiceHeader."No.", TempWarehouseShipmentLine."No.");
        WhsePostShipment.SetPostingSettings(false); // Post as ship: Invoice = FALSE
        WhsePostShipment.Run(WarehouseShipmentLine);
        // Verify: Non-posted whse shipment is deleted
        Assert.IsFalse(WarehouseShipmentHeader.Get(TempWarehouseShipmentLine."No."), 'Whse Shipment Header has not been deleted');
        // Verify: Posted whse shipment is created
        VerifyPostedWhseShipmentHeaderExists(ServiceHeader."No.");
        // Verify: Posted Service Shipment is created
        VerifyPostedServiceShipmentExists(ServiceHeader."No.");
        // Verify that service lines are correct regarding Qty shipped on the service lines
        VerifyServiceLinesAreShipped(ServiceHeader."No.");
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWhseShipmentAsInvoice()
    var
        ServiceHeader: Record "Service Header";
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        TempServiceLine: Record "Service Line" temporary;
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        // [SCENARIO] Post warehouse shipment as ship and invoice and verify that: Non-posted whse shipment is deleted;
        // [SCENARIO] Posted whse shipment is created; Service Shipment is created; Service Invoice is created.
        Initialize();
        CreateServiceOrder(ServiceHeader, 9, WhiteLocationCode, 0, 0, 0, 0, false);
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Modify(true);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);
        CollectServiceLines(ServiceHeader."No.", TempServiceLine);
        CollectWarehouseShipmentLines(ServiceHeader."No.", TempWarehouseShipmentLine);
        TempWarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(TempWarehouseShipmentLine."No.");
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WhseShipmentCreatePick.SetWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetHideValidationDialog(true);
        WhseShipmentCreatePick.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        WhseShipmentCreatePick.UseRequestPage(false);
        WhseShipmentCreatePick.RunModal();
        Clear(WhseShipmentCreatePick);
        RegisterPick(TempWarehouseShipmentLine."No.");
        VerifyWhseShptLinesAgainstRegisteredPick(ServiceHeader."No.", TempWarehouseShipmentLine."No.");
        WhsePostShipment.SetPostingSettings(true); // Post as ship: Invoice = TRUE
        WhsePostShipment.Run(WarehouseShipmentLine);
        // Verify that service lines are correct regarding Qty invoiced on the service lines
        VerifyServiceLinesAreInvoiced(ServiceHeader."No.", 0);
        // Verify that a service invoice exists with correct quantities
        VerifyServiceInvoice(ServiceHeader."No.", TempServiceLine, 0);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWhseShipmentLessQtyToShip()
    var
        ServiceHeader: Record "Service Header";
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        TempServiceLine: Record "Service Line" temporary;
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        // [SCENARIO] Post whse shipment (ship & invoice) with qty to ship < qty and verify that:
        // [SCENARIO] Posted whse shipment: Qty = Qty to ship on the whse shipment; Posted service shipment: Qty = Qty to ship on the whse shipment
        // [SCENARIO] Posted service invoice: Qty = Qty to ship on the whse shipment; Service order: Qty to ship = 0 and Qty to invoice = 0.
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        CollectServiceLines(ServiceHeader."No.", TempServiceLine);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);
        CollectWarehouseShipmentLines(ServiceHeader."No.", TempWarehouseShipmentLine);
        TempWarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(TempWarehouseShipmentLine."No.");
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WhseShipmentCreatePick.SetWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetHideValidationDialog(true);
        WhseShipmentCreatePick.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        WhseShipmentCreatePick.UseRequestPage(false);
        WhseShipmentCreatePick.RunModal();
        Clear(WhseShipmentCreatePick);
        RegisterPick(TempWarehouseShipmentLine."No.");
        ReduceWhseShipmentLineQtyToShip(TempWarehouseShipmentLine, 7);  // For all lines: Reduce quantity to ship by 7
        WhsePostShipment.SetPostingSettings(true); // Post as ship: Invoice = TRUE
        WhsePostShipment.Run(WarehouseShipmentLine);
        // Verify that service lines are correct regarding Qty invoiced on the service lines
        VerifyServiceLinesAreInvoiced(ServiceHeader."No.", 7);
        // Verify that a service invoice exists with correct quantities
        VerifyServiceInvoice(ServiceHeader."No.", TempServiceLine, 7);
        // Posted whse shipment header:
        VerifyPostedWhseShipmentHeaderExists(ServiceHeader."No.");
        // Posted whse shipment lines:
        VerifyPostedWhseShipmentLines(ServiceHeader."No.");
        CleanSetupData();
    end;

    [Test]
    [HandlerFunctions('ServiceLinesModalFormHandler,MsgHandlerWhseOperationsRequired')]
    [Scope('OnPrem')]
    procedure ServiceLineBlankLocationCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrderTP: TestPage "Service Order";
    begin
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, '', 0, 0, 0, 0, false);
        ServiceOrderTP.OpenNew();
        ServiceOrderTP.GotoRecord(ServiceHeader);
        ServiceOrderTP.ServItemLines."Service Lines".Invoke();
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PullReleasedServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] Create service order and release to ship. Create warehouse shipment. Select "Get Source Documents".
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader."Shipment Date" := 0D;
        WarehouseShipmentHeader.Modify();
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        PullScenarioVerifyWhseRqst(ServiceHeader."No.", WarehouseShipmentHeader);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PullReleasedServiceOrderVerifyShipmentLines()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] Create service order and release to ship. Create warehouse shipment. Select "Get Source Documents".
        // [SCENARIO] Service Order is displayed in the overview
        CleanSetupData();
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader."Shipment Date" := 0D;
        WarehouseShipmentHeader.Modify();
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        PullScenarioVerifyWhseRqst(ServiceHeader."No.", WarehouseShipmentHeader);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseFiltersToGetSourceDocsWithoutService()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] (Customer filter) Create service order and release to ship. Create empty warehouse shipment. Select "Use filters to get source documents".
        // [SCENARIO] Select WhseSourceFilter[1] (without service orders).
        // [SCENARIO] Run and verify that whse shipment lines for the service order are NOT added to the whse shipment
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        asserterror RunGetSourceBatch(WhseSourceFilter[1], WarehouseShipmentHeader); // Expected error: "There are no Warehouse Shipment Lines created."
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseFiltersToGetSourceDocsWithService1()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] (Customer filter) Create service order and release to ship. Create empty warehouse shipment. Select "Use filters to get source documents".
        // [SCENARIO] Select WhseSourceFilter[2] (with service orders and Customer no set to the used customer).
        // [SCENARIO] Run and verify that whse shipment lines for the service order are added to the whse shipment
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        // Get source documents with source filter 2 (incl services):
        RunGetSourceBatch(WhseSourceFilter[2], WarehouseShipmentHeader);
        // Verify that line exists:
        VerifyWhseShptLineExistence(ServiceHeader."No.");
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseFiltersToGetSourceDocsWithService2()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] (Customer filter) Create service order and release to ship. Create empty warehouse shipment. Select "Use filters to get source documents".
        // [SCENARIO] Select WhseSourceFilter[3] (with service orders and Customer no <> the used customer).
        // [SCENARIO] Run and verify that whse shipment lines for the service order are NOT added to the whse shipment
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        // Get source documents with source filter 3 (incl services but without customer no. in range):
        asserterror RunGetSourceBatch(WhseSourceFilter[3], WarehouseShipmentHeader); // Expected error: "There are no Warehouse Shipment Lines created."
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseFiltersToGetSourceDocsWithService3()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] (Customer filter) Create service order and release to ship. Create empty warehouse shipment. Select "Use filters to get source documents".
        // [SCENARIO] Select WhseSourceFilter[4] (with service orders and Customer filter blank).
        // [SCENARIO] Run and verify that whse shipment lines for the service order are added to the whse shipment
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        // Get source documents with source filter 4 (incl services, with customer no. filter CustomerNo..):
        RunGetSourceBatch(WhseSourceFilter[4], WarehouseShipmentHeader);
        // Verify that line exists:
        VerifyWhseShptLineExistence(ServiceHeader."No.");
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentMethodCodeFilterWithoutLines()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] (Shipment Method Code filter) Create service order and release to ship. Create empty warehouse shipment. Select "Use filters to get source documents".
        // [SCENARIO] Select WhseSourceFilter[5] (with service orders and Shipping method code Filter <> the shipping method code for the order).
        // [SCENARIO] Run and verify that whse shipment lines for the service order are NOT added to the whse shipment
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        ServiceHeader."Shipment Method Code" := ShipmentMethodCode;
        ServiceHeader.Modify();
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        // Get source documents with source filter 5
        asserterror RunGetSourceBatch(WhseSourceFilter[5], WarehouseShipmentHeader); // Expected error: "There are no Warehouse Shipment Lines created."
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentMethodCodeFilterWithLines()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] (Shipment Method Code filter) Create service order and release to ship. Create empty warehouse shipment. Select "Use filters to get source documents".
        // [SCENARIO] Select WhseSourceFilter[6] (with service orders and Shipping method code Filter = the shipping method code for the order).
        // [SCENARIO] Run and verify that whse shipment lines for the service order are added to the whse shipment
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        // Get source documents with source filter 6
        RunGetSourceBatch(WhseSourceFilter[6], WarehouseShipmentHeader);
        // Verify that line exists:
        VerifyWhseShptLineExistence(ServiceHeader."No.");
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingAgentCodeFilterWithoutLines()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] (Shipping agent code filter) Create service order and release to ship. Create empty warehouse shipment. Select "Use filters to get source documents".
        // [SCENARIO] Select WhseSourceFilter[7] (with service orders and Shipping method code Filter = the shipping method code for the order).
        // [SCENARIO] Run and verify that whse shipment lines for the service order are added to the whse shipment
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        // Get source documents with source filter 7
        asserterror RunGetSourceBatch(WhseSourceFilter[7], WarehouseShipmentHeader); // Expected error: "There are no Warehouse Shipment Lines created."
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingAgentCodeFilterWithLines()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] (Shipping agent code filter) Create service order and release to ship. Create empty warehouse shipment. Select "Use filters to get source documents".
        // [SCENARIO] Select WhseSourceFilter[8] (with service orders and Shipping method code Filter = the shipping method code for the order).
        // [SCENARIO] Run and verify that whse shipment lines for the service order are added to the whse shipment
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        // Get source documents with source filter 8
        RunGetSourceBatch(WhseSourceFilter[8], WarehouseShipmentHeader);
        // Verify that line exists:
        VerifyWhseShptLineExistence(ServiceHeader."No.");
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingAgentServiceFilterWithoutLines()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] (Shipping agent services code filter) Create service order and release to ship. Create empty warehouse shipment. Select "Use filters to get source documents".
        // [SCENARIO] Select WhseSourceFilter[9] (with service orders and Shipping method code Filter = the shipping method code for the order).
        // [SCENARIO] Run and verify that whse shipment lines for the service order are added to the whse shipment
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        // Get source documents with source filter 9
        asserterror RunGetSourceBatch(WhseSourceFilter[9], WarehouseShipmentHeader); // Expected error: "There are no Warehouse Shipment Lines created."
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingAgentServiceFilterWithLines()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] (Shipping agent services code filter) Create service order and release to ship. Create empty warehouse shipment. Select "Use filters to get source documents".
        // [SCENARIO] Select WhseSourceFilter[10] (with service orders and Shipping method code Filter = the shipping method code for the order).
        // [SCENARIO] Run and verify that whse shipment lines for the service order are added to the whse shipment
        Initialize();
        CreateServiceOrder(ServiceHeader, 10, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        // Create empty shipment:
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", WhiteLocationCode);
        WarehouseShipmentHeader.Modify();
        // Get source documents with source filter 10
        RunGetSourceBatch(WhseSourceFilter[10], WarehouseShipmentHeader);
        // Verify that line exists:
        VerifyWhseShptLineExistence(ServiceHeader."No.");
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateShipmentDateCheckHandlingTimeWithoutLocation()
    var
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] Create service order and release to ship. Set ServiceOrder.Shipping Time = 2D. Create empty warehouse shipment. Blank the shipping date on the whse header.
        // [SCENARIO] Select "Get Source Documents". Verify:
        // [SCENARIO] Whse shipment: Due Date = ServiceLine."Needed by date" - Service Line.Shipping Time
        // [SCENARIO] Whse shipment: Shipping Date = ServiceLine."Needed by date" - ServiceLine.Shipping Time - Location."Whse Outbound handling time"(7D)
        Initialize();
        Evaluate(ServiceHeaderShippingTime[1], '<2D>');
        Evaluate(InvSetupOutboundWhseHandlingTime[2], '<-7D>');
        ServiceLine.SuspendStatusCheck(true);
        ServiceLine."Needed by Date" := WorkDate();
        ServiceLine."Shipping Time" := ServiceHeaderShippingTime[1];
        Assert.AreEqual(
          CalcDate(InvSetupOutboundWhseHandlingTime[2], ServiceLine.GetDueDate()), ServiceLine.GetShipmentDate(),
          'Service Line shipment date calculation without location code');
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitTestTabf5900Field27()
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Init();
        ServiceHeader."Release Status" := ServiceHeader."Release Status"::"Released to Ship";
        asserterror ServiceHeader.Validate("Shipment Method Code", '');
    end;

    [Test]
    [HandlerFunctions('ServiceLinesOpenItemTracking,ServiceLinesSelectItemTracking,ServiceLinesAcceptSelectedItemTracking')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithItemTracking()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        TempReservationEntryT5902: Record "Reservation Entry" temporary;
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        WhseShipmentNo: Code[20];
    begin
        Initialize();
        CreateServiceOrder(ServiceHeader, 0, WhiteLocationCode, 10, 10, 10, 0, true);
        ServiceHeader.Find();
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);
        WhseShipmentNo := GetWhseShipmentNo(ServiceHeader."No.");
        // Check whse shipment:
        // Check item tracking on the whse shipment lines:
        CollectItemTrackingReservationEntries(ServiceHeader."No.", TempReservationEntryT5902);
        CompareItemTrackingT5900vsT7321(WhseShipmentNo, TempReservationEntryT5902);

        WarehouseShipmentHeader.Get(WhseShipmentNo);
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WhseShipmentCreatePick.SetWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetHideValidationDialog(true);
        WhseShipmentCreatePick.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        WhseShipmentCreatePick.UseRequestPage(false);
        WhseShipmentCreatePick.RunModal();
        Clear(WhseShipmentCreatePick);
        VerifyServiceOrderLinesAgainstPickItemTracking(WhseShipmentNo, TempReservationEntryT5902);
        // Register pick, validate whse entries:
        RegisterPick(WhseShipmentNo);
        // Validate item tracking for whse entries:
        VerifyT6550T337(WhseShipmentNo, TempReservationEntryT5902);
        WhsePostShipment.SetPostingSettings(false); // Post as ship: Invoice = FALSE
        WhsePostShipment.Run(WarehouseShipmentLine);
        // Verify item ledger entries:
        VerifyT32T337(ServiceHeader."No.", TempReservationEntryT5902);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithoutItemTracking()
    var
        ServiceHeader: Record "Service Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        TempWhseActivityLine: Record "Warehouse Activity Line" temporary;
        TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        WhseShipmentNo: Code[20];
    begin
        Initialize();
        CreateServiceOrder(ServiceHeader, 0, WhiteLocationCode, 5, 5, 5, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);
        WhseShipmentNo := GetWhseShipmentNo(ServiceHeader."No.");
        WarehouseShipmentHeader.Get(WhseShipmentNo);
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WhseShipmentCreatePick.SetWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetHideValidationDialog(true);
        WhseShipmentCreatePick.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        WhseShipmentCreatePick.UseRequestPage(false);
        WhseShipmentCreatePick.RunModal();
        Clear(WhseShipmentCreatePick);
        // Fill out whse pick lines:
        GetPick(WhseShipmentNo, TempWhseActivityLine);
        // Assign serial and lot numbers to the pick
        AssignSerialAndLotToPick(TempWhseActivityLine, 5, 5);
        RegisterPick(WhseShipmentNo);
        // Verify whse shipment lines item tracking (TAB6550) against registered pick lines (TAB5773)
        CollectWhseShipmentItemTrackingLines(WhseShipmentNo, TempWhseItemTrackingLine);
        VerifyT6550T5773(ServiceHeader."No.", TempWhseItemTrackingLine);
        // Verify service order item tracking:
        VerifyT337T6550(ServiceHeader."No.", TempWhseItemTrackingLine);
        // Post whse shipment:
        WhsePostShipment.SetPostingSettings(false); // Post as ship: Invoice = FALSE
        WhsePostShipment.Run(WarehouseShipmentLine);
        // Verify posted service shipment item tracking
        VerifyT32T6550(ServiceHeader."No.", TempWhseItemTrackingLine);
    end;

    [Test]
    [HandlerFunctions('ServiceLinesOpenItemTracking2,ServiceLinesSelectItemTracking,ServiceLinesAcceptSelectedItemTracking,ServiceLinesReserveConfirm,ServiceLinesReserveCurrentLine')]
    [Scope('OnPrem')]
    procedure ServiceOrderItemTrackingReservation()
    var
        ServiceHeader: Record "Service Header";
        ReservationEntry: Record "Reservation Entry";
        ServiceOrderTP: TestPage "Service Order";
        WhseShipmentNo: Code[20];
    begin
        Initialize();
        ItemTrackingOption := 1;
        // Create order
        CreateServiceOrder(ServiceHeader, 0, WhiteLocationCode, 0, 0, 0, 5, true);
        // Reserve against item ledger entry:
        ItemTrackingOption := 2;
        ServiceOrderTP.OpenNew();
        ServiceOrderTP.GotoRecord(ServiceHeader);
        ServiceOrderTP.ServItemLines."Service Lines".Invoke();
        // Try to create pick for another order - error expected;
        Clear(ServiceHeader);
        CreateServiceOrder(ServiceHeader, 0, WhiteLocationCode, 0, 0, 0, 5, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);
        WhseShipmentNo := GetWhseShipmentNo(ServiceHeader."No.");
        TryCreatePick(WhseShipmentNo, true);
        // Unreserve:
        ReservationEntry.FindLast();
        ReservationEntry.Delete();
        ReservationEntry.FindLast();
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
        ReservationEntry.Modify();
        // Now it should be possible to pick:
        TryCreatePick(WhseShipmentNo, false);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrdersFieldTest()
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        ValidateWhseSourceFilterField(WarehouseSourceFilter.Type::Inbound, 1, true, false);
        ValidateWhseSourceFilterField(WarehouseSourceFilter.Type::Inbound, 1, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrdersFieldTest()
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        ValidateWhseSourceFilterField(WarehouseSourceFilter.Type::Inbound, 2, true, false);
        ValidateWhseSourceFilterField(WarehouseSourceFilter.Type::Inbound, 2, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrdersFieldTest()
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        ValidateWhseSourceFilterField(WarehouseSourceFilter.Type::Outbound, 3, true, false);
        ValidateWhseSourceFilterField(WarehouseSourceFilter.Type::Outbound, 3, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InboundTransfersFieldTest()
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        ValidateWhseSourceFilterField(WarehouseSourceFilter.Type::Inbound, 4, true, false);
        ValidateWhseSourceFilterField(WarehouseSourceFilter.Type::Inbound, 4, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutboundTransfersFieldTest()
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        ValidateWhseSourceFilterField(WarehouseSourceFilter.Type::Outbound, 5, true, false);
        ValidateWhseSourceFilterField(WarehouseSourceFilter.Type::Outbound, 5, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPostedSourceDocumentServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        TempPostedWhseShipmentLine: Record "Posted Whse. Shipment Line" temporary;
        ServiceShipmentHeader: Record "Service Shipment Header";
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        // [FEATURE] [Warehouse] [Service] [Posted Source Document]
        // [SCENARIO 597197] Verify that Posted Source Document action from Posted Whse. Shipment Line correctly navigates to Posted Service Shipment for Service Orders
        Initialize();

        // [GIVEN] Create service order and process through warehouse shipment
        CreateServiceOrder(ServiceHeader, 5, WhiteLocationCode, 0, 0, 0, 0, false);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWhseShipment(ServiceHeader, true);

        // [GIVEN] Create pick, register it and post warehouse shipment
        CollectWarehouseShipmentLines(ServiceHeader."No.", TempWarehouseShipmentLine);
        TempWarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(TempWarehouseShipmentLine."No.");
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WhseShipmentCreatePick.SetWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetHideValidationDialog(true);
        WhseShipmentCreatePick.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        WhseShipmentCreatePick.UseRequestPage(false);
        WhseShipmentCreatePick.RunModal();
        Clear(WhseShipmentCreatePick);
        RegisterPick(TempWarehouseShipmentLine."No.");
        WhsePostShipment.SetPostingSettings(false); // Post as ship only: Invoice = FALSE
        WhsePostShipment.Run(WarehouseShipmentLine);

        // [WHEN] Get Posted Whse. Shipment Line for the Service Order
        CollectPostedWarehouseShipmentLines(ServiceHeader."No.", TempPostedWhseShipmentLine);
        TempPostedWhseShipmentLine.FindFirst();

        // [THEN] Verify that Posted Service Shipment exists for this order
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        Assert.IsTrue(ServiceShipmentHeader.FindFirst(), 'Posted Service Shipment should exist');

        // [THEN] Verify that ShowPostedSourceDocument works correctly for Service Order
        // This validates that the Source Document is "Service Order" and routes to Service Shipment
        Assert.AreEqual(TempPostedWhseShipmentLine."Source Document", TempPostedWhseShipmentLine."Source Document"::"Service Order", 'Source Document should be Service Order');
        Assert.AreEqual(TempPostedWhseShipmentLine."Posted Source No.", ServiceShipmentHeader."No.", 'Posted Source No. should match Service Shipment No.');
        CleanSetupData();
    end;

    local procedure ValidateWhseSourceFilterField(InbOutb: Option Inbound,Outbound; FieldToValidate: Integer; ValidateWithValue: Boolean; ErrorExpected: Boolean)
    var
        MyRecRef: RecordRef;
        MyFieldRef: FieldRef;
        i: Integer;
    begin
        MyRecRef.Open(DATABASE::"Warehouse Source Filter");
        MyFieldRef := MyRecRef.Field(GetFieldNo(0));
        MyFieldRef.Value(InbOutb);
        for i := 1 to 7 do begin
            MyFieldRef := MyRecRef.Field(GetFieldNo(i));
            if i = FieldToValidate then
                MyFieldRef.Value(ValidateWithValue)
            else
                MyFieldRef.Value(false)
        end;
        MyFieldRef := MyRecRef.Field(GetFieldNo(FieldToValidate));
        if ErrorExpected then
            asserterror MyFieldRef.Validate()
        else
            MyFieldRef.Validate();
        MyRecRef.Close();
    end;

    local procedure GetFieldNo(EnumVal: Integer): Integer
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        case EnumVal of
            0:
                exit(WarehouseSourceFilter.FieldNo(Type));
            1:
                exit(WarehouseSourceFilter.FieldNo("Sales Return Orders"));
            2:
                exit(WarehouseSourceFilter.FieldNo("Purchase Orders"));
            3:
                exit(WarehouseSourceFilter.FieldNo("Purchase Return Orders"));
            4:
                exit(WarehouseSourceFilter.FieldNo("Inbound Transfers"));
            5:
                exit(WarehouseSourceFilter.FieldNo("Outbound Transfers"));
            6:
                exit(WarehouseSourceFilter.FieldNo("Service Orders"));
            7:
                exit(WarehouseSourceFilter.FieldNo("Sales Orders"));
        end;
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; Qty: Decimal; LocCode: Code[10]; QtySerial: Decimal; QtyLot: Decimal; QtySerialLot: Decimal; QtyLotReserv: Decimal; InsertTrackingInfo: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        i: Integer;
        UOMCode: Code[10];
        UOMDescription: Text[50];
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        Commit();
        ServiceHeader."Shipment Method Code" := ShipmentMethodCode;
        ServiceHeader."Shipping Agent Code" := ShippingAgentCode;
        ServiceHeader."Shipping Agent Service Code" := ShippingAgentServicesCode;
        ServiceHeader."Shipping Time" := ServiceHeaderShippingTime[1];
        ServiceHeader.Modify();

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
        if Qty <> 0 then begin // Item without item tracking
            for i := 1 to ArrayLen(ItemNo) do begin
                LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo[i]);
                ServiceLine."Service Item Line No." := ServiceItemLine."Line No.";
                ValidateLocationCode(ServiceLine, LocCode);
                ServiceLine.Validate(Quantity, Qty + i);
                ServiceLine.Validate("Variant Code", UsedVariantCode[1]);
                ServiceLine.Modify();
            end;
            UOMCode := ServiceLine."Unit of Measure Code";
            UOMDescription := ServiceLine."Unit of Measure";
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
            ValidateLocationCode(ServiceLine, LocCode);
            ServiceLine.Validate(Quantity, Qty);
            ServiceLine.Modify();
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccountNo);
            ValidateLocationCode(ServiceLine, LocCode);
            ServiceLine.Validate(Quantity, Qty);
            ServiceLine."Unit of Measure Code" := UOMCode;
            ServiceLine."Unit of Measure" := UOMDescription;
            ServiceLine.Modify();
        end;

        if QtySerial <> 0 then begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, SerialItem);
            ServiceLine."Service Item Line No." := ServiceItemLine."Line No.";
            ValidateLocationCode(ServiceLine, LocCode);
            ServiceLine.Validate(Quantity, QtySerial);
            ServiceLine.Modify();
            if InsertTrackingInfo then begin
                ServiceLineNo := 1;
                AddItemTrackingForServiceLine(ServiceLine);
            end;
        end;
        if QtyLot <> 0 then begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LotItem);
            ServiceLine."Service Item Line No." := ServiceItemLine."Line No.";
            ValidateLocationCode(ServiceLine, LocCode);
            ServiceLine.Validate(Quantity, QtyLot);
            ServiceLine.Modify();
            if InsertTrackingInfo then begin
                ServiceLineNo := 2;
                AddItemTrackingForServiceLine(ServiceLine);
            end;
        end;
        if QtySerialLot <> 0 then begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, SerialLotItem);
            ServiceLine."Service Item Line No." := ServiceItemLine."Line No.";
            ValidateLocationCode(ServiceLine, LocCode);
            ServiceLine.Validate(Quantity, QtySerialLot);
            ServiceLine.Modify();
            if InsertTrackingInfo then begin
                ServiceLineNo := 3;
                AddItemTrackingForServiceLine(ServiceLine);
            end;
        end;
        if QtyLotReserv <> 0 then begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LotItemReservation);
            ServiceLine."Service Item Line No." := ServiceItemLine."Line No.";
            ValidateLocationCode(ServiceLine, LocCode);
            ServiceLine.Validate(Quantity, QtyLotReserv);
            ServiceLine.Modify();
            if InsertTrackingInfo then begin
                ServiceLineNo := 1;
                AddItemTrackingForServiceLine(ServiceLine);
            end;
        end;
    end;

    local procedure CreateWhseShipment(ServiceHeader: Record "Service Header"; CreateWhseShpmntAllowed: Boolean)
    begin
        if CreateWhseShpmntAllowed then
            LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader)
        else
            asserterror LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);
    end;

    local procedure VerifyWhseShipmentLinesAgainstServiceOrder(ServiceOrderNo: Code[20]; DateCheck: Boolean)
    var
        TempServiceLine: Record "Service Line" temporary;
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
    begin
        CollectServiceLines(ServiceOrderNo, TempServiceLine);
        CollectWarehouseShipmentLines(ServiceOrderNo, TempWarehouseShipmentLine);
        CompareLineSets(TempServiceLine, TempWarehouseShipmentLine);
        if DateCheck then
            VerifyWhseShipmentDueDateShipmentDate(TempServiceLine, TempWarehouseShipmentLine);
    end;

    local procedure CollectServiceLines(ServiceOrderNo: Code[20]; var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        TempServiceLine.DeleteAll();
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceOrderNo);
        Assert.IsFalse(ServiceLine.IsEmpty, 'No Service lines created on the service order');
        ServiceLine.FindSet();
        repeat
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
        until ServiceLine.Next() = 0;
    end;

    local procedure CollectWarehouseShipmentLines(ServiceOrderNo: Code[20]; var TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        TempWarehouseShipmentLine.DeleteAll();
        WarehouseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseShipmentLine.SetRange("Source Subtype", 1); // 1 = Order
        WarehouseShipmentLine.SetRange("Source No.", ServiceOrderNo);
        Assert.IsFalse(WarehouseShipmentLine.IsEmpty, 'No warehouse lines exist for the service order');
        WarehouseShipmentLine.FindSet();
        repeat
            TempWarehouseShipmentLine := WarehouseShipmentLine;
            TempWarehouseShipmentLine.Insert();
        until WarehouseShipmentLine.Next() = 0;
    end;

    local procedure GetWhseShipmentNo(ServiceOrderNo: Code[20]): Code[20]
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseShipmentLine.SetRange("Source Subtype", 1); // 1 = Order
        WarehouseShipmentLine.SetRange("Source No.", ServiceOrderNo);
        Assert.IsTrue(WarehouseShipmentLine.FindFirst(), 'No Whse shipment lines found for the serviceorder.');
        exit(WarehouseShipmentLine."No.");
    end;

    local procedure CollectPostedWarehouseShipmentLines(ServiceOrderNo: Code[20]; var TempPostedWhseShipmentLine: Record "Posted Whse. Shipment Line" temporary)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        TempPostedWhseShipmentLine.DeleteAll();
        PostedWhseShipmentLine.SetRange("Source Type", DATABASE::"Service Line");
        PostedWhseShipmentLine.SetRange("Source Subtype", 1);
        PostedWhseShipmentLine.SetRange("Source No.", ServiceOrderNo);
        if PostedWhseShipmentLine.FindSet() then
            repeat
                TempPostedWhseShipmentLine := PostedWhseShipmentLine;
                TempPostedWhseShipmentLine.Insert();
            until PostedWhseShipmentLine.Next() = 0;
    end;

    local procedure CompareLineSets(var TempServiceLine: Record "Service Line" temporary; var TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary)
    begin
        TempServiceLine.SetRange(Type, TempServiceLine.Type::Item);
        Assert.AreEqual(
          TempWarehouseShipmentLine.Count, TempServiceLine.Count,
          'The numbers of service lines of type Item and warehouse shipment lines do not match');
        TempServiceLine.FindSet();
        TempWarehouseShipmentLine.FindSet();
        repeat
            CompareLineFields(TempServiceLine, TempWarehouseShipmentLine);
        until (TempServiceLine.Next() = 0) and (TempWarehouseShipmentLine.Next() = 0);
    end;

    local procedure CompareLineFields(TempServiceLine: Record "Service Line" temporary; TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary)
    begin
        Assert.AreEqual(
          TempServiceLine.Quantity, TempWarehouseShipmentLine.Quantity, GetErrMsg('Service line quantity', 'Warehouse Line Quantity'));
        Assert.AreEqual(
          TempServiceLine."Location Code",
          TempWarehouseShipmentLine."Location Code",
          GetErrMsg(TempServiceLine.FieldCaption("Location Code"), TempWarehouseShipmentLine.FieldCaption("Location Code")));
    end;

    local procedure GetErrMsg(FieldName1: Text[30]; FieldName2: Text[30]): Text[100]
    begin
        exit(StrSubstNo('%1 and %2 do not match', FieldName1, FieldName2));
    end;

    local procedure CleanSetupData()
    var
        InventorySetup: Record "Inventory Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        WhseJournalBatch: Record "Warehouse Journal Batch";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        WhseSetup: Record "Warehouse Setup";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        i: Integer;
    begin
        if not SetupDataInitialized then
            exit;

        InventorySetup.Get();
        InventorySetup."Outbound Whse. Handling Time" := OldOutboundWhseHandlingTime;
        InventorySetup.Modify();

        SalesSetup.Get();
        SalesSetup."Stockout Warning" := OldStockoutWarning;
        SalesSetup."Credit Warnings" := OldCreditWarning;
        SalesSetup.Modify();

        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Service Order Nos.", OldServiceOrderNoSeriesName);
        ServiceMgtSetup.Validate("Posted Service Invoice Nos.", OldServiceInvoiceNoSeriesName);
        ServiceMgtSetup.Validate("Posted Service Shipment Nos.", OldServiceShipmentNumbers);
        ServiceMgtSetup.Modify();

        if WhseJournalBatch.Get(WhseTemplate, WhseBatch) then
            WhseJournalBatch.Delete(true);

        if ItemJournalBatch.Get(ItemJournalTemplateName, ItemJournalBatchName) then
            ItemJournalBatch.Delete(true);

        if TempVATPostingSetup.FindSet() then
            repeat
                VATPostingSetup.Get(TempVATPostingSetup."VAT Bus. Posting Group", '');
                VATPostingSetup.Delete(true);
            until TempVATPostingSetup.Next() = 0;
        TempVATPostingSetup.DeleteAll();

        WhseSetup.Get();
        WhseSetup."Shipment Posting Policy" := OldWhsePostingSetting;
        WhseSetup."Require Shipment" := OldRequireShipmentSetting;
        WhseSetup.Modify();

        for i := 1 to ArrayLen(WhseSourceFilter) do
            if WarehouseSourceFilter.Get(WarehouseSourceFilter.Type::Outbound, WhseSourceFilter[i]) then
                WarehouseSourceFilter.Delete(true);

        HandleShippingData(ShipmentMethodCode, ShippingAgentCode, ShippingAgentServicesCode, false);  // Delete

        SetupDataInitialized := false;
        Commit();
    end;

    local procedure CreateCustomer()
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
    end;

    local procedure CreateTestNoSeriesBackupData()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        InventorySetup: Record "Inventory Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        WarehouseEmployee: Record "Warehouse Employee";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        TempVATPostingSetup2: Record "VAT Posting Setup" temporary;
        WhseSetup: Record "Warehouse Setup";
        i: Integer;
    begin
        // No. series
        NoSeriesName := 'SERVWHSE';
        Clear(NoSeries);
        NoSeries.Init();
        NoSeries.Code := NoSeriesName;
        NoSeries.Description := NoSeriesName;
        NoSeries."Default Nos." := true;
        if NoSeries.Insert() then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := NoSeriesName;
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := 'SW00001';
            NoSeriesLine."Ending No." := 'SW99999';
            NoSeriesLine."Increment-by No." := 1;
            NoSeriesLine.Insert();
        end;

        // Setup data
        Evaluate(ServiceHeaderShippingTime[1], '<2D>');
        Evaluate(LocationOutboundWhseHandlingTime[1], '<3D>');
        Evaluate(InvSetupOutboundWhseHandlingTime[1], '<7D>');
        Evaluate(ServiceHeaderShippingTime[2], '<-2D>');
        Evaluate(LocationOutboundWhseHandlingTime[2], '<-3D>');
        Evaluate(InvSetupOutboundWhseHandlingTime[2], '<-7D>');

        InventorySetup.Get();
        OldOutboundWhseHandlingTime := InventorySetup."Outbound Whse. Handling Time";
        InventorySetup."Outbound Whse. Handling Time" := InvSetupOutboundWhseHandlingTime[1];
        InventorySetup.Modify();

        ServiceMgtSetup.Get();
        OldServiceOrderNoSeriesName := ServiceMgtSetup."Service Order Nos.";
        OldServiceInvoiceNoSeriesName := ServiceMgtSetup."Posted Service Invoice Nos.";
        OldServiceShipmentNumbers := ServiceMgtSetup."Posted Service Shipment Nos.";
        ServiceMgtSetup."Service Order Nos." := NoSeriesName;
        ServiceMgtSetup."Posted Service Invoice Nos." := NoSeriesName;
        ServiceMgtSetup."Posted Service Shipment Nos." := NoSeriesName;
        ServiceMgtSetup.Modify();

        SalesSetup.Get();
        OldStockoutWarning := SalesSetup."Stockout Warning";
        SalesSetup."Stockout Warning" := false;
        OldCreditWarning := SalesSetup."Credit Warnings";
        SalesSetup."Credit Warnings" := SalesSetup."Credit Warnings"::"No Warning";
        SalesSetup.Modify();

        if DefaultLocationCodeForUser <> '' then begin
            WarehouseEmployee.SetRange("User ID", UserId);
            WarehouseEmployee.ModifyAll(Default, false);
            WarehouseEmployee.Get(UserId, DefaultLocationCodeForUser);
            WarehouseEmployee.Default := true;
            WarehouseEmployee.Modify();
        end;

        TempVATPostingSetup.DeleteAll();
        TempVATPostingSetup2.DeleteAll();
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
        if VATPostingSetup.FindFirst() then begin
            TempVATPostingSetup2 := VATPostingSetup;
            TempVATPostingSetup2.Insert();
            Clear(VATPostingSetup);
            if VATBusinessPostingGroup.FindSet() then
                repeat
                    VATPostingSetup := TempVATPostingSetup2;
                    VATPostingSetup."VAT Bus. Posting Group" := VATBusinessPostingGroup.Code;
                    VATPostingSetup."VAT Prod. Posting Group" := '';
                    if VATPostingSetup.Insert() then begin
                        TempVATPostingSetup := VATPostingSetup;
                        TempVATPostingSetup.Insert();
                    end;
                until VATBusinessPostingGroup.Next() = 0;
        end;
        WhseSetup.Get();
        OldWhsePostingSetting := WhseSetup."Shipment Posting Policy";
        OldRequireShipmentSetting := WhseSetup."Require Shipment";
        WhseSetup."Require Shipment" := true;
        WhseSetup."Shipment Posting Policy" := WhseSetup."Shipment Posting Policy"::"Stop and show the first posting error";
        WhseSetup.Modify();

        // Source filter data
        for i := 1 to ArrayLen(WhseSourceFilter) do
            WhseSourceFilter[i] := 'C136142_' + Format(i);

        // Shipping Agent code (TAB105), Shipping Agent Services Code (TAB5794), Shipment Method (TAB10):
        ShipmentMethodCode := 'SMC001';
        ShippingAgentCode := 'SAC001';
        ShippingAgentServicesCode := 'SASC001';
        HandleShippingData(ShipmentMethodCode, ShippingAgentCode, ShippingAgentServicesCode, true);  // Insert

        // Customer,Shipment Method Code,Shipping Agent Code,Shipping Agent Service
        CreateWhseSourceFilter(WhseSourceFilter[1], false, '', 0);
        CreateWhseSourceFilter(WhseSourceFilter[2], true, CustomerNo, 0);
        CreateWhseSourceFilter(WhseSourceFilter[3], true, StrSubstNo('<>%1', CustomerNo), 0);
        CreateWhseSourceFilter(WhseSourceFilter[4], true, '', 0);
        CreateWhseSourceFilter(WhseSourceFilter[5], true, StrSubstNo('<>%1', ShipmentMethodCode), 1); // Shipping Method Code, 5.7
        CreateWhseSourceFilter(WhseSourceFilter[6], true, ShipmentMethodCode, 1); // Shipping Method Code, 5.8
        CreateWhseSourceFilter(WhseSourceFilter[7], true, StrSubstNo('<>%1', ShippingAgentCode), 2); // Shipping Agent Code, 5.9
        CreateWhseSourceFilter(WhseSourceFilter[8], true, ShippingAgentCode, 2); // Shipping Agent Code, 5.10
        CreateWhseSourceFilter(WhseSourceFilter[9], true, StrSubstNo('<>%1', ShippingAgentServicesCode), 3); // Shipping Agent Services Code, 5.11
        CreateWhseSourceFilter(WhseSourceFilter[10], true, ShippingAgentServicesCode, 3); // Shipping Agent Service Code, 5.12

        // Item Tracking:
        CreateSerialLotCode();
    end;

    local procedure CreateTestItems()
    var
        Item: Record Item;
        LibraryAssembly: Codeunit "Library - Assembly";
        i: Integer;
        j: Integer;
    begin
        for i := 1 to ArrayLen(ItemNo) do begin
            LibraryAssembly.CreateItem(Item, "Costing Method"::FIFO, "Replenishment System"::Assembly, '', '');
            ItemNo[i] := Item."No.";
        end;
        for i := 1 to ArrayLen(ItemNo) do
            for j := 1 to ArrayLen(UsedVariantCode) do
                CreateVariant(i, j);

        // Serial no item:
        LibraryAssembly.CreateItem(Item, "Costing Method"::FIFO, "Replenishment System"::" ", '', '');
        SerialItem := Item."No.";
        Item.Validate("Item Tracking Code", SerialNoCode);
        Item.Modify();
        // Lot no item:
        LibraryAssembly.CreateItem(Item, "Costing Method"::FIFO, "Replenishment System"::" ", '', '');
        LotItem := Item."No.";
        Item.Validate("Item Tracking Code", LotNoCode);
        Item.Modify();
        // Serial and lot item:
        LibraryAssembly.CreateItem(Item, "Costing Method"::FIFO, "Replenishment System"::" ", '', '');
        SerialLotItem := Item."No.";
        Item.Validate("Item Tracking Code", SerialLotCode);
        Item.Modify();
        // Lot Item for reservation check:
        LibraryAssembly.CreateItem(Item, "Costing Method"::FIFO, "Replenishment System"::" ", '', '');
        LotItemReservation := Item."No.";
        Item.Validate("Item Tracking Code", LotNoCode);
        Item.Modify();
    end;

    local procedure CreateVariant(ItNo: Integer; VarNo: Integer)
    var
        ItemVariant: Record "Item Variant";
    begin
        UsedVariantCode[VarNo] := 'TESTVAR_ ' + Format(VarNo);
        ItemVariant.Init();
        ItemVariant."Item No." := ItemNo[ItNo];
        ItemVariant.Code := UsedVariantCode[VarNo];
        ItemVariant.Description := 'Item' + Format(ItNo) + '_' + UsedVariantCode[VarNo];
        if ItemVariant.Insert() then;
    end;

    local procedure ProvideTestItemSupply()
    var
        WhseJournalTemplate: Record "Warehouse Journal Template";
        WhseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        i: Integer;
        j: Integer;
    begin
        WhseJournalTemplate.SetRange(Type, WhseJournalTemplate.Type::Item);
        WhseJournalTemplate.FindFirst();
        WhseTemplate := WhseJournalTemplate.Name;
        Clear(WhseJournalBatch);
        WhseJournalBatch."Journal Template Name" := WhseTemplate;
        i := 1;
        while WhseJournalBatch.Get(WhseTemplate, 'W' + Format(i), WhiteLocationCode) do
            i += 1;
        WhseJournalBatch.Name := 'W' + Format(i);
        WhseJournalBatch."Location Code" := WhiteLocationCode;
        WhseBatch := WhseJournalBatch.Name;
        WhseJournalBatch.Insert(true);
        for i := 1 to ArrayLen(ItemNo) do
            for j := 1 to ArrayLen(UsedVariantCode) do begin
                LibraryWarehouse.CreateWhseJournalLine(
                  WarehouseJournalLine, WhseTemplate, WhseBatch, WhiteLocationCode, GetZoneCode(), UsedBinCode, 1, ItemNo[i], 500);  // 1 = pos.adjmt.
                WarehouseJournalLine.Validate("Variant Code", UsedVariantCode[j]);
                WarehouseJournalLine.Modify();
            end;
        // Serial no item:
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WhseTemplate, WhseBatch, WhiteLocationCode, GetZoneCode(), UsedBinCode, 1, SerialItem, 50);  // 1 = pos.adjmt.
        AddItemTrackingToWhseJnlLine(WarehouseJournalLine, true, false, 50);
        // Lot no item:
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WhseTemplate, WhseBatch, WhiteLocationCode, GetZoneCode(), UsedBinCode, 1, LotItem, 50);  // 1 = pos.adjmt.
        AddItemTrackingToWhseJnlLine(WarehouseJournalLine, false, true, 50);
        // Serial and lot item:
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WhseTemplate, WhseBatch, WhiteLocationCode, GetZoneCode(), UsedBinCode, 1, SerialLotItem, 50);  // 1 = pos.adjmt.
        AddItemTrackingToWhseJnlLine(WarehouseJournalLine, true, true, 50);
        // Lot Reservation Check item:
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WhseTemplate, WhseBatch, WhiteLocationCode, GetZoneCode(), UsedBinCode, 1, LotItemReservation, 5);  // 1 = pos.adjmt.
        AddItemTrackingToWhseJnlLine(WarehouseJournalLine, false, true, 5);

        LibraryWarehouse.RegisterWhseJournalLine(WhseTemplate, WhseBatch, WhiteLocationCode, true);
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        ItemJournalTemplateName := ItemJournalTemplate.Name;
        Clear(ItemJournalBatch);
        ItemJournalBatch."Journal Template Name" := ItemJournalTemplateName;
        i := 1;
        while ItemJournalBatch.Get(ItemJournalTemplateName, 'WH' + Format(i)) do
            i += 1;
        ItemJournalBatch.Name := 'WH' + Format(i);
        ItemJournalBatchName := ItemJournalBatch.Name;
        ItemJournalBatch.Insert(true);
        CalcWhseAdjmnt();
    end;

    local procedure CalcWhseAdjmnt()
    var
        ItemJnlLine: Record "Item Journal Line";
        CalculateWhseAdjustment: Report "Calculate Whse. Adjustment";
        LibraryInventory: Codeunit "Library - Inventory";
        KeepItemJnlLine: Boolean;
        i: Integer;
    begin
        ItemJnlLine.SetRange("Journal Template Name", ItemJournalTemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", ItemJournalBatchName);
        ItemJnlLine."Journal Template Name" := ItemJournalTemplateName;
        ItemJnlLine."Journal Batch Name" := ItemJournalBatchName;
        CalculateWhseAdjustment.SetItemJnlLine(ItemJnlLine);
        CalculateWhseAdjustment.UseRequestPage(false);
        CalculateWhseAdjustment.SetHideValidationDialog(true);
        CalculateWhseAdjustment.InitializeRequest(WorkDate(), 'COD136142');
        CalculateWhseAdjustment.Run();
        if ItemJnlLine.FindSet() then
            repeat
                KeepItemJnlLine := false;
                i := 0;
                repeat
                    i += 1;
                    if ItemJnlLine."Item No." in [ItemNo[i], SerialItem, LotItem, SerialLotItem, LotItemReservation] then
                        KeepItemJnlLine := true;
                until KeepItemJnlLine or (i = ArrayLen(ItemNo));
                if not KeepItemJnlLine then
                    ItemJnlLine.Delete(true);
            until ItemJnlLine.Next() = 0;
        LibraryInventory.PostItemJournalLine(ItemJournalTemplateName, ItemJournalBatchName);
    end;

    local procedure GetWhiteLocation()
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 10);
        Location.Validate("Outbound Whse. Handling Time", LocationOutboundWhseHandlingTime[1]);
        Location.Modify();
        WhiteLocationCode := Location.Code;
    end;

    local procedure Initialize()
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Service Warehouse Integration");

        if not SetupDataInitialized then begin
            CreateTestNoSeriesBackupData();
            LibraryERMCountryData.CreateVATData();
            LibraryERMCountryData.UpdateSalesReceivablesSetup();
            LibraryERMCountryData.UpdateGeneralPostingSetup();
            SetupDataInitialized := true;
        end;

        if not BasicDataInitialized then begin
            CreateCustomer();
            LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
            ServiceItemNo := ServiceItem."No.";
            GetWhiteLocation();
            CreateWhseEmployee();
            GetBinCode();
            CreateTestItems();
            ProvideTestItemSupply();
            GetResource();
            GetGLAcc();
            BasicDataInitialized := true;
        end;
    end;

    local procedure GetZoneCode(): Code[10]
    begin
        exit('PICK');
    end;

    local procedure GetBinCode()
    var
        Bin: Record Bin;
    begin
        Bin.SetRange("Location Code", WhiteLocationCode);
        Bin.SetRange("Zone Code", GetZoneCode());
        Bin.FindFirst();
        UsedBinCode := Bin.Code;
    end;

    local procedure CreateWhseEmployee()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.SetRange(Default, true);
        DefaultLocationCodeForUser := '';
        if WarehouseEmployee.FindFirst() then begin
            DefaultLocationCodeForUser := WarehouseEmployee."Location Code";
            WarehouseEmployee.Default := false;
            WarehouseEmployee.Modify();
        end;
        if not WarehouseEmployee.Get(UserId, WhiteLocationCode) then
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, WhiteLocationCode, true);
    end;

    local procedure GetResource()
    begin
        ResourceNo := LibraryResource.CreateResourceNo();
    end;

    local procedure GetGLAcc()
    begin
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
    end;

    local procedure CheckServiceLineNoModification(var ServiceLine: Record "Service Line")
    begin
        asserterror ServiceLine.Validate(Type, NewType(ServiceLine.Type.AsInteger()));
        asserterror ServiceLine.Validate("No.", ItemNo[2]);
        asserterror ServiceLine.Validate(Quantity, ServiceLine.Quantity + 1);
        asserterror ServiceLine.Validate("Variant Code", UsedVariantCode[2]);
        asserterror ServiceLine.Validate("Unit of Measure Code", '');
        asserterror ServiceLine.Validate("Location Code", NewLocationCode(ServiceLine."Location Code"));
    end;

    local procedure NewType(InType: Integer): Integer
    begin
        if InType > 1 then
            exit(InType - 1);
        exit(InType + 1);
    end;

    local procedure NewLocationCode(LocCode: Code[10]): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetFilter(Code, '<>%1', LocCode);
        Location.FindFirst();
        exit(Location.Code);
    end;

    local procedure GetPick(WarehouseShipmentNo: Code[20]; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        TempWarehouseActivityLine.DeleteAll();
        WarehouseActivityLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
        WarehouseActivityLine.SetRange("Whse. Document No.", WarehouseShipmentNo);
        WarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type"::Shipment);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        if WarehouseActivityLine.FindSet() then
            repeat
                TempWarehouseActivityLine := WarehouseActivityLine;
                TempWarehouseActivityLine.Insert();
            until WarehouseActivityLine.Next() = 0;
    end;

    local procedure GetRegisteredPick(WSHNo: Code[20]; var TempRegisteredWhseActivityLine: Record "Registered Whse. Activity Line" temporary)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        TempRegisteredWhseActivityLine.DeleteAll();
        RegisteredWhseActivityLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        RegisteredWhseActivityLine.SetRange("Whse. Document No.", WSHNo);
        RegisteredWhseActivityLine.SetRange("Whse. Document Type", RegisteredWhseActivityLine."Whse. Document Type"::Shipment);
        if RegisteredWhseActivityLine.FindSet() then
            repeat
                TempRegisteredWhseActivityLine := RegisteredWhseActivityLine;
                TempRegisteredWhseActivityLine.Insert();
            until RegisteredWhseActivityLine.Next() = 0;
    end;

    local procedure RegisterPick(WSHNo: Code[20])
    var
        TempWhseActivityLine: Record "Warehouse Activity Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        GetPick(WSHNo, TempWhseActivityLine);
        TempWhseActivityLine.FindFirst();
        WarehouseActivityLine := TempWhseActivityLine;
        CODEUNIT.Run(CODEUNIT::"Whse.-Activity-Register", WarehouseActivityLine);
    end;

    local procedure VerifyWhseShptLinesAgainstPick(ServiceOrderNo: Code[20]; WhseShptNo: Code[20])
    var
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
    begin
        CollectWarehouseShipmentLines(ServiceOrderNo, TempWarehouseShipmentLine);
        GetPick(WhseShptNo, TempWarehouseActivityLine);
        CompareLineSets2(TempWarehouseShipmentLine, TempWarehouseActivityLine, 1); // Take lines
        CompareLineSets2(TempWarehouseShipmentLine, TempWarehouseActivityLine, 2); // Place lines
    end;

    local procedure CompareLineSets2(var TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; TakePlace: Integer)
    begin
        // Compares whse shipment lines and whse activity lines one by one. Only to be used without item tracking.
        Assert.IsTrue(TempWarehouseShipmentLine.FindSet(), 'No warehouse shipment lines in CompareLineSets2');
        if TakePlace = 1 then
            TempWarehouseActivityLine.SetRange("Action Type", TempWarehouseActivityLine."Action Type"::Take)
        else
            TempWarehouseActivityLine.SetRange("Action Type", TempWarehouseActivityLine."Action Type"::Place);
        Assert.AreEqual(
          TempWarehouseShipmentLine.Count, TempWarehouseActivityLine.Count, 'WhseShpt and Pick lines, action ' + Format(TakePlace));
        Assert.IsTrue(
          TempWarehouseActivityLine.FindSet(), 'No warehouse activity lines in CompareLineSets2 ActionType ' + Format(TakePlace));
        repeat
            CompareLineFields2(TempWarehouseShipmentLine, TempWarehouseActivityLine);
        until (TempWarehouseActivityLine.Next() = 0) and (TempWarehouseShipmentLine.Next() = 0);
    end;

    local procedure CompareLineFields2(var TempWhseShipmentLine: Record "Warehouse Shipment Line" temporary; var TempWhseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
        Assert.AreEqual(TempWhseShipmentLine."Item No.", TempWhseActivityLine."Item No.", 'Item No.');
        Assert.AreEqual(TempWhseShipmentLine.Quantity, TempWhseActivityLine.Quantity, 'Quantity');
        Assert.AreEqual(TempWhseShipmentLine."Qty. (Base)", TempWhseActivityLine."Qty. (Base)", 'Qty. (Base)');
        Assert.AreEqual(TempWhseShipmentLine."Qty. Outstanding", TempWhseActivityLine."Qty. Outstanding", 'Qty. Outstanding');
        Assert.AreEqual(
          TempWhseShipmentLine."Qty. Outstanding (Base)", TempWhseActivityLine."Qty. Outstanding (Base)", 'Qty Outstanding(Base)');
        Assert.AreEqual(TempWhseShipmentLine.Quantity, TempWhseActivityLine."Qty. to Handle", 'Quantity / Qty to handle');
        Assert.AreEqual(TempWhseShipmentLine."Qty. (Base)", TempWhseActivityLine."Qty. to Handle (Base)", 'Qty (base)/QtyToHandle(Base)');
        Assert.AreEqual(TempWhseShipmentLine."Unit of Measure Code", TempWhseActivityLine."Unit of Measure Code", 'Unit of Measure Code');
        Assert.AreEqual(TempWhseShipmentLine."Variant Code", TempWhseActivityLine."Variant Code", 'Variant Code');
        Assert.AreEqual(TempWhseShipmentLine.Description, TempWhseActivityLine.Description, 'Description');
    end;

    local procedure VerifyServiceOrderLinesAgainstPickItemTracking(WhseShptNo: Code[20]; var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        TempWhseActivityLine: Record "Warehouse Activity Line" temporary;
    begin
        GetPick(WhseShptNo, TempWhseActivityLine);
        Assert.IsTrue(TempWhseActivityLine.FindSet(), 'No warehouse pick lines found for whse shipment with item tracking.');
        CompareLineSets4(TempReservationEntry, TempWhseActivityLine, 1); // Take lines
        CompareLineSets4(TempReservationEntry, TempWhseActivityLine, 2); // Place lines
    end;

    local procedure VerifyWhseShptLinesAgainstRegisteredPick(ServiceOrderNo: Code[20]; WhseShptNo: Code[20])
    var
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        TempRegisteredWhseActivityLine: Record "Registered Whse. Activity Line" temporary;
    begin
        CollectWarehouseShipmentLines(ServiceOrderNo, TempWarehouseShipmentLine);
        GetRegisteredPick(WhseShptNo, TempRegisteredWhseActivityLine);
        CompareLineSets3(TempWarehouseShipmentLine, TempRegisteredWhseActivityLine, 1); // Take lines
        CompareLineSets3(TempWarehouseShipmentLine, TempRegisteredWhseActivityLine, 2); // Place lines
    end;

    local procedure CompareLineSets3(var TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary; var TempRegisteredWhseActivityLine: Record "Registered Whse. Activity Line" temporary; TakePlace: Integer)
    begin
        // Compare whse shipment and registered pick
        Assert.IsTrue(TempWarehouseShipmentLine.FindSet(), 'No warehouse shipment lines in CompareLineSets2');
        if TakePlace = 1 then
            TempRegisteredWhseActivityLine.SetRange("Action Type", TempRegisteredWhseActivityLine."Action Type"::Take)
        else
            TempRegisteredWhseActivityLine.SetRange("Action Type", TempRegisteredWhseActivityLine."Action Type"::Place);
        Assert.AreEqual(
          TempWarehouseShipmentLine.Count, TempRegisteredWhseActivityLine.Count, 'WhseShpt and Reg.pick lines, action ' +
          Format(TakePlace));
        Assert.IsTrue(
          TempRegisteredWhseActivityLine.FindSet(),
          'No registered warehouse activity lines in CompareLineSets3 ActionType ' + Format(TakePlace));
        repeat
            CompareLineFields3(TempWarehouseShipmentLine, TempRegisteredWhseActivityLine);
        until (TempRegisteredWhseActivityLine.Next() = 0) and (TempWarehouseShipmentLine.Next() = 0);
    end;

    local procedure CompareLineFields3(var TempWhseShipmentLine: Record "Warehouse Shipment Line" temporary; var TempRegisteredWhseActivityLine: Record "Registered Whse. Activity Line" temporary)
    begin
        Assert.AreEqual(TempWhseShipmentLine."Item No.", TempRegisteredWhseActivityLine."Item No.", 'Item No.');
        Assert.AreEqual(TempWhseShipmentLine.Quantity, TempRegisteredWhseActivityLine.Quantity, 'Quantity');
        Assert.AreEqual(TempWhseShipmentLine."Qty. (Base)", TempRegisteredWhseActivityLine."Qty. (Base)", 'Qty. (Base)');
        Assert.AreEqual(
          TempWhseShipmentLine."Unit of Measure Code", TempRegisteredWhseActivityLine."Unit of Measure Code", 'Unit of Measure Code');
        Assert.AreEqual(TempWhseShipmentLine."Variant Code", TempRegisteredWhseActivityLine."Variant Code", 'Variant Code');
        Assert.AreEqual(TempWhseShipmentLine.Description, TempRegisteredWhseActivityLine.Description, 'Description');
    end;

    local procedure CompareLineSets4(var TempReservationEntry: Record "Reservation Entry" temporary; var TempWhseActivityLine: Record "Warehouse Activity Line" temporary; TakePlace: Integer)
    begin
        // Compare whse shipment and non-registered pick with item tracking lines
        if TakePlace = 1 then
            TempWhseActivityLine.SetRange("Action Type", TempWhseActivityLine."Action Type"::Take)
        else
            TempWhseActivityLine.SetRange("Action Type", TempWhseActivityLine."Action Type"::Place);
        Assert.IsTrue(TempWhseActivityLine.FindSet(), 'No warehouse pick lines for pick with item tracking');
        Assert.AreEqual(
          TempReservationEntry.Count, TempWhseActivityLine.Count, 'WhseShpt and Reg.pick lines, action ' + Format(TakePlace));
        TempReservationEntry.FindSet();
        repeat
            CompareLineFields4(TempReservationEntry, TempWhseActivityLine);
        until (TempReservationEntry.Next() = 0) or (TempWhseActivityLine.Next() = 0);
    end;

    local procedure CompareLineFields4(var TempReservationEntry: Record "Reservation Entry" temporary; var TempWhseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
        Assert.AreEqual(
          TempReservationEntry."Quantity (Base)", -TempWhseActivityLine."Qty. (Base)", 'Quantity (Base) for pick with item tracking');
        Assert.AreEqual(TempReservationEntry."Serial No.", TempWhseActivityLine."Serial No.", 'Serial no for pick with item tracking');
        Assert.AreEqual(TempReservationEntry."Lot No.", TempWhseActivityLine."Lot No.", 'Lot no for pick with item tracking');
        Assert.AreEqual(TempReservationEntry."Item No.", TempWhseActivityLine."Item No.", 'Item no. for pick with item tracking');
        Assert.AreEqual(TempReservationEntry."Location Code", TempWhseActivityLine."Location Code", '');
    end;

    local procedure VerifyPostedWhseShipmentHeaderExists(ServiceHeaderNo: Code[20])
    var
        TempPostedWhseShipmentLine: Record "Posted Whse. Shipment Line" temporary;
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
    begin
        CollectPostedWarehouseShipmentLines(ServiceHeaderNo, TempPostedWhseShipmentLine);
        Assert.IsTrue(TempPostedWhseShipmentLine.FindFirst(), 'No posted whse shipment line found after shipping the service order');
        Assert.IsTrue(
          PostedWhseShipmentHeader.Get(TempPostedWhseShipmentLine."No."),
          'No posted whse shipment header found after shipping the service order');
    end;

    local procedure VerifyPostedServiceShipmentExists(ServiceOrderNo: Code[20])
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", ServiceOrderNo);
        Assert.AreEqual(1, ServiceShipmentHeader.Count, 'Number of service shipments after shipping service order');
    end;

    local procedure VerifyServiceLinesAreShipped(ServiceOrderNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceOrderNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.FindSet();
        repeat
            Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Quantity Shipped", 'Wrong shipped quantity on service line');
            Assert.AreEqual(0, ServiceLine."Qty. to Ship", 'Wrong Qty. to ship on service line');
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLinesAreInvoiced(ServiceOrderNo: Code[20]; Delta: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceOrderNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.FindSet();
        repeat
            Assert.AreEqual(ServiceLine.Quantity - Delta, ServiceLine."Quantity Invoiced", 'Wrong invoiced quantity on service line');
            Assert.AreEqual(0, ServiceLine."Qty. to Ship", 'Wrong Qty. to ship on service line');
            Assert.AreEqual(0, ServiceLine."Qty. to Invoice", 'Wrong qty. to invoice on service line');
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceInvoice(ServiceOrderNo: Code[20]; var TempServiceLine: Record "Service Line" temporary; Delta: Decimal)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", ServiceOrderNo);
        Assert.AreEqual(1, ServiceInvoiceHeader.Count, 'Number of service invoices after invoicing service order');
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        TempServiceLine.SetRange(Type, TempServiceLine.Type::Item);
        Assert.AreEqual(TempServiceLine.Count, ServiceInvoiceLine.Count, 'Number of service invoice lines after invoicing service order');
        TempServiceLine.FindSet();
        ServiceInvoiceLine.FindSet();
        repeat
            Assert.AreEqual(TempServiceLine."No.", ServiceInvoiceLine."No.",
              StrSubstNo('%1 , %2', ServiceInvoiceLine.TableCaption(), ServiceInvoiceLine.FieldCaption("No.")));
            Assert.AreEqual(TempServiceLine.Quantity - Delta, ServiceInvoiceLine.Quantity,
              StrSubstNo('%1 , %2', ServiceInvoiceLine.TableCaption(), ServiceInvoiceLine.FieldCaption(Quantity)));
            if Delta = 0 then
                Assert.AreEqual(TempServiceLine.Amount, ServiceInvoiceLine.Amount,
                  StrSubstNo('%1 , %2', ServiceInvoiceLine.TableCaption(), ServiceInvoiceLine.FieldCaption(Amount)));
        until (TempServiceLine.Next() = 0) or (ServiceInvoiceLine.Next() = 0);
    end;

    local procedure VerifyWhseShptLineExistence(ServiceOrderNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseShipmentLine.SetRange("Source Subtype", 1); // 1 = Order
        WarehouseShipmentLine.SetRange("Source No.", ServiceOrderNo);
        Assert.AreEqual(
          4, WarehouseShipmentLine.Count, 'No. of whse shipment lines when service is a part of the filter for getting source documents.');
    end;

    local procedure VerifyWhseShipmentDueDateShipmentDate(var TempServiceLine: Record "Service Line" temporary; var TempWhseShipmentLine: Record "Warehouse Shipment Line" temporary)
    begin
        TempServiceLine.FindSet();
        TempWhseShipmentLine.FindSet();
        Assert.AreEqual(TempServiceLine.Count, TempWhseShipmentLine.Count, 'No. of TempServiceLines and TempWhseShpmntLines differ');
        repeat
            Assert.AreEqual(
              CalcDate(ServiceHeaderShippingTime[2], TempServiceLine."Needed by Date"), TempServiceLine.GetDueDate(),
              'Due date on service line');
            Assert.AreEqual(TempServiceLine.GetDueDate(), TempWhseShipmentLine."Due Date", 'Due date on whse shipment line');
            Assert.AreEqual(
              CalcDate(LocationOutboundWhseHandlingTime[2], TempServiceLine.GetDueDate()), TempServiceLine.GetShipmentDate(),
              'Shipment date on service line');
            Assert.AreEqual(TempServiceLine.GetShipmentDate(), TempWhseShipmentLine."Shipment Date", 'Shipment date on whse shipment line');
        until (TempServiceLine.Next() = 0) and (TempWhseShipmentLine.Next() = 0);
    end;

    local procedure ReduceWhseShipmentLineQtyToShip(var TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary; Delta: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if Delta = 0 then
            exit;
        if not TempWarehouseShipmentLine.FindSet() then
            exit;
        repeat
            WarehouseShipmentLine.Get(TempWarehouseShipmentLine."No.", TempWarehouseShipmentLine."Line No.");
            WarehouseShipmentLine.Validate("Qty. to Ship", WarehouseShipmentLine."Qty. to Ship" - Delta);
            WarehouseShipmentLine.Modify();
        until TempWarehouseShipmentLine.Next() = 0;
    end;

    local procedure VerifyPostedWhseShipmentLines(ServiceOrderNo: Code[20])
    var
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        TempPostedWhseShipmentLine: Record "Posted Whse. Shipment Line" temporary;
    begin
        CollectWarehouseShipmentLines(ServiceOrderNo, TempWarehouseShipmentLine);
        CollectPostedWarehouseShipmentLines(ServiceOrderNo, TempPostedWhseShipmentLine);
        Assert.AreEqual(TempWarehouseShipmentLine.Count, TempPostedWhseShipmentLine.Count, 'Number of posted warehouse shipment lines');
        TempWarehouseShipmentLine.FindSet();
        TempPostedWhseShipmentLine.FindSet();
        repeat
            Assert.AreEqual(
              TempWarehouseShipmentLine."Qty. Shipped", TempPostedWhseShipmentLine.Quantity, 'Quantity on posted whse shipment line');
        until (TempWarehouseShipmentLine.Next() = 0) or (TempPostedWhseShipmentLine.Next() = 0);
    end;

    local procedure PullScenarioVerifyWhseRqst(ServiceOrderNo: Code[20]; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseRequest: Record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        WarehouseRequest.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseRequest.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseRequest.SetRange("Source Subtype", 1);
        WarehouseRequest.SetRange("Source No.", ServiceOrderNo);
        Assert.AreEqual(1, WarehouseRequest.Count, 'Number of warehouse requests');
        // Get the whse shipment lines on the whse shipment:
        WarehouseRequest.FindFirst();
        GetSourceDocuments.SetOneCreatedShptHeader(WarehouseShipmentHeader);
        GetSourceDocuments.SetSkipBlocked(true);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.RunModal();
        // Verify the fields of the shipment lines:
        VerifyWhseShipmentLinesAgainstServiceOrder(ServiceOrderNo, true);
    end;

    local procedure ValidateLocationCode(var ServiceLine: Record "Service Line"; LocCode: Code[10])
    begin
        if LocCode <> '' then
            ServiceLine.Validate("Location Code", LocCode);
    end;

    local procedure CreateWhseSourceFilter(Name: Code[10]; ServiceIncluded: Boolean; FilterText: Text[100]; Category: Option Customer,"Shipment Method Code","Shipping Agent Code","Shipping Agent Service")
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        WarehouseSourceFilter.Init();
        WarehouseSourceFilter.Validate(Type, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Code := Name;
        WarehouseSourceFilter."Service Orders" := ServiceIncluded;
        if FilterText <> '' then
            case Category of
                Category::Customer:
                    WarehouseSourceFilter."Customer No. Filter" := FilterText;
                Category::"Shipment Method Code":
                    WarehouseSourceFilter."Shipment Method Code Filter" := FilterText;
                Category::"Shipping Agent Code":
                    WarehouseSourceFilter."Shipping Agent Code Filter" := FilterText;
                Category::"Shipping Agent Service":
                    WarehouseSourceFilter."Shipping Agent Service Filter" := FilterText;
            end;
        if not WarehouseSourceFilter.Insert() then
            WarehouseSourceFilter.Modify();
    end;

    local procedure HandleShippingData(ShipmentMethodCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10]; InsertRecords: Boolean)
    var
        ShippingAgent: Record "Shipping Agent";
        ShipmentMethod: Record "Shipment Method";
        ShippingAgentServices: Record "Shipping Agent Services";
    begin
        if InsertRecords then begin
            ShippingAgent.Init();
            ShippingAgent.Code := ShippingAgentCode;
            if ShippingAgent.Insert() then;
            ShipmentMethod.Init();
            ShipmentMethod.Code := ShipmentMethodCode;
            if ShipmentMethod.Insert() then;
            ShippingAgentServices.Init();
            ShippingAgentServices."Shipping Agent Code" := ShippingAgentCode;
            ShippingAgentServices.Code := ShippingAgentServiceCode;
            Evaluate(ShippingAgentServices."Shipping Time", '<7D>');
            if ShippingAgentServices.Insert() then;
            exit;
        end;
        if ShippingAgentServices.Get(ShippingAgentCode, ShippingAgentServiceCode) then
            ShippingAgentServices.Delete(true);
        if ShippingAgent.Get(ShippingAgentCode) then
            ShippingAgent.Delete(true);
        if ShipmentMethod.Get(ShipmentMethodCode) then
            ShipmentMethod.Delete(true);
    end;

    local procedure RunGetSourceBatch(WarehouseSourceFilterCode: Code[10]; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        WarehouseSourceFilter.Get(WarehouseSourceFilter.Type::Outbound, WarehouseSourceFilterCode);
        GetSourceDocuments.SetOneCreatedShptHeader(WarehouseShipmentHeader);
        WarehouseSourceFilter.SetFilters(GetSourceDocuments, WarehouseShipmentHeader."Location Code");
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.RunModal();
    end;

    local procedure CreateSerialLotCode()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCode2: Record "Item Tracking Code";
    begin
        // SN Warehouse tracking:
        ItemTrackingCode.SetRange("SN Specific Tracking", true);
        ItemTrackingCode.SetRange("Lot Specific Tracking", false);
        ItemTrackingCode.FindFirst();
        ItemTrackingCode2 := ItemTrackingCode;
        ItemTrackingCode2.Code := GetFreeCode(ItemTrackingCode.Code);
        ItemTrackingCode2."SN Warehouse Tracking" := true;
        ItemTrackingCode2."Man. Expir. Date Entry Reqd." := false;
        ItemTrackingCode2.Insert();
        SerialNoCode := ItemTrackingCode2.Code;

        // Serial And Lot Whse Tracking:
        Clear(ItemTrackingCode2);
        ItemTrackingCode2.Code := GetFreeCode(ItemTrackingCode.Code);
        ItemTrackingCode2.Validate("SN Specific Tracking", true);
        ItemTrackingCode2.Validate("Lot Specific Tracking", true);
        ItemTrackingCode2.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode2.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode2."Man. Expir. Date Entry Reqd." := false;
        ItemTrackingCode2.Insert();
        SerialLotCode := ItemTrackingCode2.Code;

        // Lot Warehouse Tracking:
        ItemTrackingCode.SetRange("SN Specific Tracking", false);
        ItemTrackingCode.SetRange("Lot Specific Tracking", true);
        ItemTrackingCode.FindFirst();
        ItemTrackingCode2 := ItemTrackingCode;
        ItemTrackingCode2.Code := GetFreeCode(ItemTrackingCode.Code);
        ItemTrackingCode2."Lot Warehouse Tracking" := true;
        ItemTrackingCode2."Man. Expir. Date Entry Reqd." := false;
        ItemTrackingCode2.Insert();
        LotNoCode := ItemTrackingCode2.Code;
    end;

    local procedure GetFreeCode(InCode: Code[10]): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
        i: Integer;
    begin
        i := 1;
        while ItemTrackingCode.Get(CopyStr(InCode, 1, StrLen(InCode) - StrLen(Format(i))) + Format(i)) do
            i += 1;
        exit(CopyStr(InCode, 1, StrLen(InCode) - StrLen(Format(i))) + Format(i));
    end;

    local procedure AddItemTrackingToWhseJnlLine(WarehouseJournalLine: Record "Warehouse Journal Line"; AddSN: Boolean; AddLot: Boolean; Qty: Decimal)
    var
        SN: Code[5];
        Lot: Code[5];
        i: Integer;
        LotSize: Integer;
        NoOfLots: Integer;
    begin
        SN := 'S0000';
        Lot := 'L0000';
        LotSize := 5;
        if AddSN then begin
            SN := 'S0000';
            for i := 1 to Qty do begin
                SN := IncStr(SN);
                if AddLot then begin
                    if (i - 1) mod LotSize = 0 then
                        Lot := IncStr(Lot);
                    InsertWhseItemTrkgLine(WarehouseJournalLine, 1, SN, Lot);
                end else
                    InsertWhseItemTrkgLine(WarehouseJournalLine, 1, SN, '');
            end;
        end;
        if AddLot and not AddSN then begin
            NoOfLots := Round(Qty / LotSize, 1, '>');
            for i := 1 to NoOfLots do begin
                Lot := IncStr(Lot);
                InsertWhseItemTrkgLine(WarehouseJournalLine, GetLotQty(Qty, LotSize, i), '', Lot);
            end;
        end;
    end;

    local procedure InsertWhseItemTrkgLine(WarehouseJournalLine: Record "Warehouse Journal Line"; Qty: Decimal; SerialNo: Code[5]; LotNo: Code[5])
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        NextEntryNo: Integer;
    begin
        NextEntryNo := 1;
        if WhseItemTrackingLine.FindLast() then
            NextEntryNo := WhseItemTrackingLine."Entry No." + 1;
        WhseItemTrackingLine.Init();
        WhseItemTrackingLine."Entry No." := NextEntryNo;
        WhseItemTrackingLine."Item No." := WarehouseJournalLine."Item No.";
        WhseItemTrackingLine."Location Code" := WarehouseJournalLine."Location Code";
        WhseItemTrackingLine.Validate("Quantity (Base)", Qty);
        WhseItemTrackingLine."Source Type" := DATABASE::"Warehouse Journal Line";
        WhseItemTrackingLine."Source ID" := WarehouseJournalLine."Journal Batch Name";
        WhseItemTrackingLine."Source Batch Name" := WarehouseJournalLine."Journal Template Name";
        WhseItemTrackingLine."Source Ref. No." := WarehouseJournalLine."Line No.";
        WhseItemTrackingLine."Serial No." := SerialNo;
        WhseItemTrackingLine."Lot No." := LotNo;
        WhseItemTrackingLine.Insert();
    end;

    local procedure GetLotQty(Qty: Decimal; LotSize: Integer; i: Integer): Decimal
    var
        Remaining: Decimal;
    begin
        Remaining := Qty - (i - 1) * LotSize;
        if Remaining < LotSize then
            exit(Remaining);
        exit(LotSize);
    end;

    [HandlerFunctions('ServiceLinesOpenItemTracking')]
    local procedure AddItemTrackingForServiceLine(var ServiceLine: Record "Service Line")
    var
        ServiceHeader: Record "Service Header";
        ServiceOrderTP: TestPage "Service Order";
    begin
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ServiceOrderTP.OpenNew();
        ServiceOrderTP.GotoRecord(ServiceHeader);
        ServiceOrderTP.ServItemLines."Service Lines".Invoke();
    end;

    local procedure CompareItemTrackingT5900vsT7321(WhseShipmentNo: Code[20]; var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
    begin
        // Compare item tracking lines btw. service lines (item tracking in T337) and whse shipment lines (item tracking in T6550)
        TempWhseItemTrackingLine.DeleteAll();
        WhseItemTrackingLine.SetCurrentKey("Source ID", "Source Type", "Source Subtype");
        WhseItemTrackingLine.SetRange("Source ID", WhseShipmentNo);
        WhseItemTrackingLine.SetRange("Source Type", DATABASE::"Warehouse Shipment Line");
        WhseItemTrackingLine.SetRange("Source Subtype", 0);
        Assert.IsTrue(WhseItemTrackingLine.Count > 0, 'No item tracking found for warehouse shipment');
        WhseItemTrackingLine.FindSet();
        repeat
            TempWhseItemTrackingLine := WhseItemTrackingLine;
            TempWhseItemTrackingLine.Insert();
        until WhseItemTrackingLine.Next() = 0;
        CompareItemTrackingT5900vsT7321_2(TempReservationEntry, TempWhseItemTrackingLine);
        TempWhseItemTrackingLine.DeleteAll();
    end;

    local procedure CompareItemTrackingT5900vsT7321_2(var TempReservationEntry: Record "Reservation Entry" temporary; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
        Assert.AreEqual(
          TempReservationEntry.Count, TempWhseItemTrackingLine.Count,
          'The numbers of service order item tracking lines and whse shipment item tracking lines do not match');
        TempReservationEntry.FindSet();
        TempWhseItemTrackingLine.FindSet();
        repeat
            Assert.AreEqual(
              TempReservationEntry."Quantity (Base)", -TempWhseItemTrackingLine."Quantity (Base)", 'Item Tracking Quantity (Base)');
            Assert.AreEqual(TempReservationEntry."Serial No.", TempWhseItemTrackingLine."Serial No.", 'Item Tracking Serial No');
            Assert.AreEqual(
              TempReservationEntry."Qty. to Handle (Base)", -TempWhseItemTrackingLine."Qty. to Handle (Base)",
              'Item Tracking Qty to handle (base)');
        // Assert.AreEqual(TempReservationEntry."Qty. to Invoice (Base)",-TempWhseItemTrackingLine."Qty. to Invoice (Base)",'Item Tracking Qty to Invoice (base)');  Are not equal - by design
        until (TempReservationEntry.Next() = 0) or (TempWhseItemTrackingLine.Next() = 0);
    end;

    local procedure CollectItemTrackingReservationEntries(ServiceOrderNo: Code[20]; var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        TempReservationEntry.DeleteAll();
        ReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
        ReservationEntry.SetRange("Source ID", ServiceOrderNo);
        ReservationEntry.SetRange("Source Type", DATABASE::"Service Line");
        ReservationEntry.SetRange("Source Subtype", 1);
        Assert.IsTrue(ReservationEntry.Count > 0, 'No item tracking found for service order');
        ReservationEntry.FindSet();
        repeat
            TempReservationEntry := ReservationEntry;
            TempReservationEntry.Insert();
        until ReservationEntry.Next() = 0;
    end;

    local procedure AssignSerialAndLotToPick(var TempWhseActivityLine: Record "Warehouse Activity Line" temporary; SerialQty: Decimal; BothQty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SN: Code[5];
        Lot: Code[5];
        i: Integer;
        j: Integer;
    begin
        // SerialNo
        TempWhseActivityLine.FindSet();
        SN := 'S0010';
        for i := 1 to SerialQty do begin
            SN := IncStr(SN);
            for j := 1 to 2 do begin
                WarehouseActivityLine.Get(TempWhseActivityLine."Activity Type", TempWhseActivityLine."No.", TempWhseActivityLine."Line No.");
                WarehouseActivityLine.Validate("Serial No.", SN);
                WarehouseActivityLine.Modify();
                TempWhseActivityLine.Next();
            end;
        end;
        // LotNo
        Lot := 'L0003';
        for i := 1 to 2 do begin // There are 2 Lot lines in this case
            WarehouseActivityLine.Get(TempWhseActivityLine."Activity Type", TempWhseActivityLine."No.", TempWhseActivityLine."Line No.");
            WarehouseActivityLine.Validate("Lot No.", Lot);
            WarehouseActivityLine.Modify();
            TempWhseActivityLine.Next();
        end;
        // Both
        SN := 'S0010';
        Lot := 'L0003';
        for i := 1 to BothQty do begin
            SN := IncStr(SN);
            for j := 1 to 2 do begin
                WarehouseActivityLine.Get(TempWhseActivityLine."Activity Type", TempWhseActivityLine."No.", TempWhseActivityLine."Line No.");
                WarehouseActivityLine.Validate("Serial No.", SN);
                WarehouseActivityLine.Validate("Lot No.", Lot);
                WarehouseActivityLine.Modify();
                if TempWhseActivityLine.Next() = 0 then;
            end;
        end;
    end;

    local procedure VerifyT6550T5773(ServiceOrderNo: Code[20]; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        // TAB6550: whse shipment item tracking, TAB5773: Registered pick line
        RegisteredWhseActivityLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        RegisteredWhseActivityLine.SetRange("Source Type", DATABASE::"Service Line");
        RegisteredWhseActivityLine.SetRange("Source Subtype", 1);
        RegisteredWhseActivityLine.SetRange("Source No.", ServiceOrderNo);
        Assert.IsTrue(RegisteredWhseActivityLine.FindSet(), 'No lines on registered pick');
        Assert.AreEqual(
          RegisteredWhseActivityLine.Count / 2, TempWhseItemTrackingLine.Count, 'Number of item tracking lines on whse shipment lines');
        TempWhseItemTrackingLine.FindSet();
        repeat
            VerifyT6550T5773Fields(RegisteredWhseActivityLine, TempWhseItemTrackingLine);
            RegisteredWhseActivityLine.Next();
            VerifyT6550T5773Fields(RegisteredWhseActivityLine, TempWhseItemTrackingLine);
        until (TempWhseItemTrackingLine.Next() = 0) or (RegisteredWhseActivityLine.Next() = 0);
    end;

    local procedure VerifyT6550T5773Fields(RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        Assert.AreEqual(RegisteredWhseActivityLine."Item No.", WhseItemTrackingLine."Item No.", 'Whse item tracking line Item no.');
        Assert.AreEqual(
          RegisteredWhseActivityLine."Location Code", WhseItemTrackingLine."Location Code", 'Whse item tracking line Location Code');
        Assert.AreEqual(
          RegisteredWhseActivityLine."Qty. (Base)", WhseItemTrackingLine."Quantity (Base)", 'Whse item tracking line Quantity (Base)');
        Assert.AreEqual(RegisteredWhseActivityLine."Serial No.", WhseItemTrackingLine."Serial No.", 'Whse item tracking line Serial No.');
        Assert.AreEqual(RegisteredWhseActivityLine."Lot No.", WhseItemTrackingLine."Lot No.", 'Whse item tracking line Lot No.');
    end;

    local procedure VerifyT337T6550(ServiceOrderNo: Code[20]; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        Assert.IsTrue(TempWhseItemTrackingLine.FindSet(), 'No item tracking lines found for whse shipment');
        ReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
        ReservationEntry.SetRange("Source ID", ServiceOrderNo);
        ReservationEntry.SetRange("Source Type", DATABASE::"Service Line");
        ReservationEntry.SetRange("Source Subtype", 1);
        Assert.AreEqual(TempWhseItemTrackingLine.Count, ReservationEntry.Count, 'Number of item tracking lines for service order');
        ReservationEntry.FindSet();
        repeat
            Assert.AreEqual(-TempWhseItemTrackingLine."Quantity (Base)", ReservationEntry."Quantity (Base)", 'Service Line Item Tracking Quantity (Base');
            Assert.AreEqual(TempWhseItemTrackingLine."Item No.", ReservationEntry."Item No.", 'Service Line Item Tracking Item No.');
            Assert.AreEqual(TempWhseItemTrackingLine."Serial No.", ReservationEntry."Serial No.", 'Service Line Item Tracking Serial No.');
            Assert.AreEqual(TempWhseItemTrackingLine."Lot No.", ReservationEntry."Lot No.", 'Service Line Item Tracking Lot No.');
            Assert.AreEqual(TempWhseItemTrackingLine."Location Code", ReservationEntry."Location Code", 'Service Line Item Tracking Location Code');
        until (ReservationEntry.Next() = 0) or (TempWhseItemTrackingLine.Next() = 0);
    end;

    local procedure VerifyT32T6550(ServiceOrderNo: Code[20]; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ServiceShipmentHeader.SetRange("Order No.", ServiceOrderNo);
        Assert.IsTrue(ServiceShipmentHeader.FindFirst(), 'No posted service shipment found.');
        ItemLedgerEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgerEntry.SetRange("Document No.", ServiceShipmentHeader."No.");
        Assert.IsTrue(ItemLedgerEntry.FindSet(), 'No item tracking entries found for posted service shipment.');
        Assert.AreEqual(TempWhseItemTrackingLine.Count, ItemLedgerEntry.Count, 'Number of item tracking lines for posted service shipment');
        TempWhseItemTrackingLine.FindSet();
        repeat
            Assert.AreEqual(-TempWhseItemTrackingLine."Quantity (Base)", ItemLedgerEntry.Quantity, 'Service Line Item Tracking Quantity (Base');
            Assert.AreEqual(TempWhseItemTrackingLine."Item No.", ItemLedgerEntry."Item No.", 'Service Line Item Tracking Item No.');
            Assert.AreEqual(TempWhseItemTrackingLine."Serial No.", ItemLedgerEntry."Serial No.", 'Service Line Item Tracking Serial No.');
            Assert.AreEqual(TempWhseItemTrackingLine."Lot No.", ItemLedgerEntry."Lot No.", 'Service Line Item Tracking Lot No.');
            Assert.AreEqual(TempWhseItemTrackingLine."Location Code", ItemLedgerEntry."Location Code", 'Service Line Item Tracking Location Code');
        until (ItemLedgerEntry.Next() = 0) or (TempWhseItemTrackingLine.Next() = 0);
    end;

    local procedure VerifyT6550T337(WhseShipmentNo: Code[20]; var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        // Compare item tracking from service order vs. warehouse entries (TAB7312)
        WhseItemTrackingLine.SetCurrentKey("Source ID", "Source Type", "Source Subtype");
        WhseItemTrackingLine.SetRange("Source ID", WhseShipmentNo);
        WhseItemTrackingLine.SetRange("Source Type", DATABASE::"Warehouse Shipment Line");
        Assert.IsTrue(WhseItemTrackingLine.FindSet(), 'No whse item tracking information found for whse shipment');
        Assert.AreEqual(TempReservationEntry.Count, WhseItemTrackingLine.Count, 'Wrong number of item tracking lines for whse shipment');
        TempReservationEntry.FindSet();
        repeat
            Assert.AreEqual(TempReservationEntry."Location Code", WhseItemTrackingLine."Location Code", 'Whse item tracking location code');
            Assert.AreEqual(-TempReservationEntry."Quantity (Base)", WhseItemTrackingLine."Quantity (Base)", 'Whse item tracking Quantity (base)');
            Assert.AreEqual(TempReservationEntry."Serial No.", WhseItemTrackingLine."Serial No.", 'Whse item tracking serial no.');
            Assert.AreEqual(TempReservationEntry."Lot No.", WhseItemTrackingLine."Lot No.", 'Whse item tracking Lot No.');
            Assert.AreEqual(TempReservationEntry."Item No.", WhseItemTrackingLine."Item No.", 'Whse item tracking Item No');
        until (WhseItemTrackingLine.Next() = 0) and (TempReservationEntry.Next() = 0);
    end;

    local procedure VerifyT32T337(ServiceOrderNo: Code[20]; var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Service);
        ItemLedgerEntry.SetRange("Order No.", ServiceOrderNo);
        Assert.IsTrue(ItemLedgerEntry.FindSet(), 'No item ledger entries found after posting whse shipment');
        Assert.AreEqual(TempReservationEntry.Count, ItemLedgerEntry.Count, 'Wrong number of item ledger entries after posting of whse shipment.');
        TempReservationEntry.FindSet();
        repeat
            Assert.AreEqual(TempReservationEntry."Item No.", ItemLedgerEntry."Item No.", 'Item ledger entry Item no');
            Assert.AreEqual(TempReservationEntry."Location Code", ItemLedgerEntry."Location Code", 'Item Ledger Entry Location Code');
            Assert.AreEqual(TempReservationEntry."Quantity (Base)", ItemLedgerEntry.Quantity, 'item Ledger Entry Quantity (Base)');
            Assert.AreEqual(TempReservationEntry."Serial No.", ItemLedgerEntry."Serial No.", 'Item ledger entry serial no.');
            Assert.AreEqual(TempReservationEntry."Lot No.", ItemLedgerEntry."Lot No.", 'Item LEdger Entry Lot No.');
        until (ItemLedgerEntry.Next() = 0) or (TempReservationEntry.Next() = 0);
    end;

    local procedure CollectWhseShipmentItemTrackingLines(WhseShipmentNo: Code[20]; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        TempWhseItemTrackingLine.DeleteAll();
        WhseItemTrackingLine.SetCurrentKey("Source ID", "Source Type", "Source Subtype");
        WhseItemTrackingLine.SetRange("Source ID", WhseShipmentNo);
        WhseItemTrackingLine.SetRange("Source Type", DATABASE::"Warehouse Shipment Line");
        WhseItemTrackingLine.SetRange("Source Subtype", 0);
        if not WhseItemTrackingLine.FindSet() then
            exit;
        repeat
            TempWhseItemTrackingLine := WhseItemTrackingLine;
            TempWhseItemTrackingLine.Insert();
        until WhseItemTrackingLine.Next() = 0;
    end;

    local procedure TryCreatePick(WhseShptNo: Code[20]; ErrExpected: Boolean)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
    begin
        WarehouseShipmentHeader.Get(WhseShptNo);
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WhseShipmentCreatePick.SetWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetHideValidationDialog(true);
        WhseShipmentCreatePick.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        WhseShipmentCreatePick.UseRequestPage(false);
        Commit();
        if ErrExpected then
            asserterror WhseShipmentCreatePick.RunModal()
        else
            WhseShipmentCreatePick.RunModal();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandlerWhseOperationsRequired(Msg: Text[1024])
    begin
        Assert.IsTrue(StrPos(Msg, Text002) <> 0, StrSubstNo('Wrong message when entering Qty to Ship for blank location: %1', Msg));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesModalFormHandler(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines."Qty. to Ship".SetValue(ServiceLines.Quantity.Value);
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesOpenItemTracking(var ServiceLines: TestPage "Service Lines")
    var
        i: Integer;
    begin
        ServiceLines.First();
        for i := 1 to ServiceLineNo - 1 do
            ServiceLines.Next();
        ServiceLines.ItemTrackingLines.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesOpenItemTracking2(var ServiceLines: TestPage "Service Lines")
    var
        i: Integer;
    begin
        if ItemTrackingOption = 1 then begin
            ServiceLines.First();
            for i := 1 to ServiceLineNo - 1 do
                ServiceLines.Next();
            ServiceLines.ItemTrackingLines.Invoke();
        end;
        if ItemTrackingOption = 2 then
            ServiceLines.Reserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesSelectItemTracking(var ItemTrackingLinesTP: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLinesTP."Select Entries".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesAcceptSelectedItemTracking(var ItemTrackingSummaryTP: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummaryTP.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesReserveConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesReserveCurrentLine(var ReservationTP: TestPage Reservation)
    begin
        ReservationTP."Reserve from Current Line".Invoke();
        ReservationTP.OK().Invoke();
    end;
}

