// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;

codeunit 136121 "Service Reservation"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reservation] [Service]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        isInitialized: Boolean;
        ItemNo: Code[20];
        QuantityOnServiceLine: Decimal;
        OriginalQuantity: Decimal;
        QuantityReserved: Decimal;
        ItemTrackingAction: Option SelectEntries,AssignSerialNo,Verification;
        ServiceLineAction: Option ItemTracking,Reserve;
        ReserveFromCurrentLine: Boolean;
        ItemNotOnInventoryError: Label 'Reserved item %1 is not on inventory.';
        ReserveQuantityError: Label '%1 must not be changed when a quantity is reserved in %2 %3=''%4'',%5=''%6'',%7=''%8''.';
        NoOfEntriesError: Label 'Wrong no. of entries found in %1.';
        ServiceLineExistError: Label '%1 must not exist.';
        ReserveError: Label 'There is nothing available to reserve.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Reservation");
        // Lazy Setup.
        InitializeGlobalVariables();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Reservation");

        LibraryService.SetupServiceMgtNoSeries();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateVATData();
        isInitialized := true;
        Commit();
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Reservation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveIfNoSourceToReserveFrom()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-R-02 - refer to TFS ID 20927.
        // Test that the application shows an error message if the Reserve field on the Service Line has value as 'Never' and the
        // user tries to make a Reservation.

        // 1. Setup: Create a new Item with Reserve as Never, Service Order - Service Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Never);
        CreateServiceDocument(ServiceLine, '', Item."No.", ServiceLine."Document Type"::Order);

        // 2. Exercise: Try to Reserve from Service Line.
        Commit();  // Commit is required to save values to match error message.
        asserterror ServiceLine.ShowReservation();

        // 3. Verify: Check that the application generates an error on trying to Reserve if the Service Line has value as 'Never' in
        // the field Reserve.
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption(Reserve), Format(ServiceLine.Reserve));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoReserveIfQuantityLess()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-03 - refer to TFS ID 20927.
        // Test that the application makes an automatic reservation of an Item from Inventory if the Reserve field on Service Line has
        // value as 'Always' and Quantity to Reserve is less than available Quantity.

        // Setup: Create a new Item with Reserve as Always, new Purchase Order - Purchase Header, Purchase Line and Post it as Receive.
        // Create a new Service Order - Service Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateAndPostPurchaseOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyLessQuantityAuto(ServiceLine, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseAutoIfQuantityLess()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-07 - refer to TFS ID 20927.
        // Test that the application makes an automatic reservation of an Item from Purchase Line if the Reserve field on Service Line has
        // value as 'Always' and Quantity to Reserve is less than available Quantity.

        // Setup: Create a new Item with Reserve as Always, new Purchase Order - Purchase Header, Purchase Line and release it.
        // Create a new Service Order - Service Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateAndReleasePurchaseOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyLessQuantityAuto(ServiceLine, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionAutoIfQuantityLess()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-11 - refer to TFS ID 20927.
        // Test that the application makes an automatic reservation of an Item from Firm Planned Production Order Line if the Reserve field
        // on Service Line has value as 'Always' and Quantity to Reserve is less than available Quantity.

        // Setup: Create a new Item with Reserve as Always, new Production Order and refresh it. Create a new Service Order - Service
        // Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateFirmPlannedOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyLessQuantityAuto(ServiceLine, Quantity);
    end;

    local procedure UpdateVerifyLessQuantityAuto(var ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        // Exercise: Input a Quantity in Service Line that is less than Quantity in Order and Auto Reserve.
        ServiceLine.Validate(Quantity, Quantity - 1);
        ServiceLine.Modify(true);
        LibraryService.AutoReserveServiceLine(ServiceLine);

        // Verify: Check that the Reserved Quantity field in Service Line is updated with the correct Quantity and Reservation Entry is
        // created.
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", Quantity - 1);
        VerifyReservationEntry(ServiceLine, Quantity - 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure AutoReserveIfQuantityMore()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-04 - refer to TFS ID 20927.
        // Test that the application makes an automatic reservation of an Item from Inventory if the Reserve field on Service Line has
        // value as 'Always' and Quantity to Reserve is greater than available Quantity.

        // Setup: Create a new Item with Reserve as Always, new Purchase Order - Purchase Header, Purchase Line and Post it as Receive.
        // Create a new Service Order - Service Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateAndPostPurchaseOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyMoreQuantityAuto(ServiceLine, Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure PurchaseAutoIfQuantityMore()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-08 - refer to TFS ID 20927.
        // Test that the application makes an automatic reservation of an Item from Purchase Line if the Reserve field on Service Line has
        // value as 'Always' and Quantity to Reserve is greater than available Quantity.

        // Setup: Create a new Item with Reserve as Always, new Purchase Order - Purchase Header, Purchase Line and release it.
        // Create a new Service Order - Service Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateAndReleasePurchaseOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyMoreQuantityAuto(ServiceLine, Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure ProductionAutoIfQuantityMore()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-12 - refer to TFS ID 20927.
        // Test that the application makes an automatic reservation of an Item from Firm Planned Production Order Line if the Reserve
        // field on Service Line has value as 'Always' and Quantity to Reserve is greater than available Quantity.

        // Setup: Create a new Item with Reserve as Always, new Production Order and refresh it. Create a new Service Order - Service
        // Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateFirmPlannedOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyMoreQuantityAuto(ServiceLine, Quantity);
    end;

    local procedure UpdateVerifyMoreQuantityAuto(var ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        // Exercise: Input a Quantity in Service Line that is greater than Quantity in Purchase Order and Auto Reserve.
        ServiceLine.Validate(Quantity, Quantity + 1);
        ServiceLine.Modify(true);
        LibraryService.AutoReserveServiceLine(ServiceLine);

        // Verify: Check that the Reserved Quantity field in Service Line is updated with the correct Quantity and Reservation Entry is
        // created.
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", Quantity);
        VerifyReservationEntry(ServiceLine, Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationModalFormHandler')]
    [Scope('OnPrem')]
    procedure OptionalReserveIfQuantityLess()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-05 - refer to TFS ID 20927.
        // Test that is possible to make a reservation of Item from Inventory if the Reserve field on Service Line has value as
        // 'Optional' and Quantity to Reserve is less than available Quantity.

        // Setup: Create a new Item with Reserve as Optional, new Purchase Order - Purchase Header, Purchase Line and Post it as Receive.
        // Create a new Service Order - Service Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Optional);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateAndPostPurchaseOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyLessQuantityOption(ServiceLine, Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationModalFormHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOptionalIfQuantityLess()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-09 - refer to TFS ID 20927.
        // Test that is possible to make a reservation of Item from Purchase Line if the Reserve field on Service Line has value as
        // 'Optional' and Quantity to Reserve is less than available Quantity.

        // Setup: Create a new Item with Reserve as Optional, new Purchase Order - Purchase Header, Purchase Line and release it.
        // Create a new Service Order - Service Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Optional);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateAndReleasePurchaseOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyLessQuantityOption(ServiceLine, Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationModalFormHandler')]
    [Scope('OnPrem')]
    procedure ProductionOptionalQuantityLess()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-13 - refer to TFS ID 20927.
        // Test that is possible to make a reservation of Item from Firm Planned Production Order Line if the Reserve field on Service
        // Line has value as 'Optional' and Quantity to Reserve is less than available Quantity.

        // Setup: Create a new Item with Reserve as Optional, new Production Order and refresh it. Create a new Service Order - Service
        // Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Optional);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateFirmPlannedOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyLessQuantityOption(ServiceLine, Quantity);
    end;

    local procedure UpdateVerifyLessQuantityOption(var ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        // Exercise: Input a Quantity in Service Line that is less than Quantity in Purchase Order and run Reserve.
        ServiceLine.Validate(Quantity, Quantity - 1);
        ServiceLine.Modify(true);
        ServiceLine.ShowReservation();

        // Verify: Check that the Reserved Quantity field in Service Line is updated with the correct Quantity and Reservation Entry is
        // created.
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", Quantity - 1);
        VerifyReservationEntry(ServiceLine, Quantity - 1);
    end;

    [Test]
    [HandlerFunctions('ReservationModalFormHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OptionalReserveQuantityMore()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-06 - refer to TFS ID 20927.
        // Test that is possible to make a reservation of Item from Inventory if the Reserve field on Service Line has value as
        // 'Optional' and Quantity to Reserve is greater than available Quantity.

        // Setup: Create a new Item with Reserve as Optional, new Purchase Order - Purchase Header, Purchase Line and Post it as Receive.
        // Create a new Service Order - Service Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Optional);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateAndPostPurchaseOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyMoreQuantityOption(ServiceLine, Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationModalFormHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOptionalQuantityMore()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-10 - refer to TFS ID 20927.
        // Test that is possible to make a reservation of Item from Purchase Line if the Reserve field on Service Line has value as
        // 'Optional' and Quantity to Reserve is greater than available Quantity.

        // Setup: Create a new Item with Reserve as Optional, new Purchase Order - Purchase Header, Purchase Line and release it.
        // Create a new Service Order - Service Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Optional);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateAndReleasePurchaseOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyMoreQuantityOption(ServiceLine, Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationModalFormHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOptionalQuantityMore()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-14 - refer to TFS ID 20927.
        // Test that is possible to make a reservation of Item from Firm Planned Production Order Line if the Reserve field on Service
        // Line has value as 'Optional' and Quantity to Reserve is greater than available Quantity.

        // Setup: Create a new Item with Reserve as Optional, new Production Order and refresh it. Create a new Service Order -
        // Service Header and Service Line.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Optional);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateFirmPlannedOrder(Item."No.", Quantity);
        CreateServiceDocument(ServiceLine, LocationCode, Item."No.", ServiceLine."Document Type"::Order);

        // Exercise and Verify:
        UpdateVerifyMoreQuantityOption(ServiceLine, Quantity);
    end;

    local procedure UpdateVerifyMoreQuantityOption(var ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        // Exercise: Input a Quantity in Service Line that is greater than Quantity in Purchase Order and run Reserve.
        ServiceLine.Validate(Quantity, Quantity + 1);
        ServiceLine.Modify(true);
        ServiceLine.ShowReservation();

        // Verify: Check that the Reserved Quantity field in Service Line is updated with the correct Quantity and Reservation Entry is
        // created.
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", Quantity);
        VerifyReservationEntry(ServiceLine, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOrderReserveFromInventory()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-21 - refer to TFS ID 20927.
        // Test that the application allows posting a Service Order while Item is reserved from Inventory properly.

        // Setup: Create a new Item with Reserve as Always, new Purchase Order - Purchase Header, Purchase Line and Post it as Receive.
        // Create a new Service Order - Service Header, Service Item Line and Service Line. Input a Quantity in Service Line that is
        // less than Quantity in Purchase Order and Auto Reserve.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateAndPostPurchaseOrder(Item."No.", Quantity);

        CreateDocumentWithServiceItem(ServiceLine, LocationCode, Item."No.", Quantity - 1, ServiceLine."Document Type"::Order);
        LibraryService.AutoReserveServiceLine(ServiceLine);

        // Exercise and Verify:
        PostAndVerifyServiceOrder(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOrderReserveFromPurchase()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-22 - refer to TFS ID 20927.
        // Test that the application allows posting a Service Order while Item is reserved from Purchase Line properly.

        // Setup: Create a new Item with Reserve as Always, new Purchase Order - Purchase Header, Purchase Line and release it.
        // Create a new Service Order - Service Header, Service Item Line and Service Line. Input a Quantity in Service Line that is
        // less than Quantity in Purchase Order and Auto Reserve.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateReleasePostPurchaseOrder(Item."No.", Quantity);

        CreateDocumentWithServiceItem(ServiceLine, LocationCode, Item."No.", Quantity - 1, ServiceLine."Document Type"::Order);
        LibraryService.AutoReserveServiceLine(ServiceLine);

        // Exercise and Verify:
        PostAndVerifyServiceOrder(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostOrderReserveFirmProduction()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-23 - refer to TFS ID 20927.
        // Test that the application allows posting a Service Order while Item is reserved from Purchase Line properly.

        // Setup: Create a new Item with Reserve as Always, new Purchase Order - Purchase Header, Purchase Line and release it.
        // Create a new Service Order - Service Header, Service Item Line and Service Line. Input a Quantity in Service Line that is
        // less than Quantity in Purchase Order and Auto Reserve.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateReleaseFirmPlannedOrder(Item."No.", Quantity);

        CreateDocumentWithServiceItem(ServiceLine, LocationCode, Item."No.", Quantity - 1, ServiceLine."Document Type"::Order);
        LibraryService.AutoReserveServiceLine(ServiceLine);

        // Exercise and Verify:
        PostAndVerifyServiceOrder(ServiceLine);
    end;

    local procedure PostAndVerifyServiceOrder(ServiceLine: Record "Service Line")
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentNo: Code[20];
    begin
        // Exercise: Post the Service Order as Ship.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceShipmentNo := GetServiceShipmentNo(ServiceHeader."No.");

        // Verify: Check that the Ledger Entries are created correctly.
        VerifyValueEntry(ServiceLine);
        VerifyServiceLedgerEntry(ServiceLine, "Service Ledger Entry Document Type"::Shipment, ServiceShipmentNo, ServiceLine.Quantity);
        VerifyItemLedgerEntry(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOrderReservePurchaseError()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-22 - refer to TFS ID 20927.
        // Test that the application generates an error on posting a Service Order while Item is reserved from Purchase Line properly but is
        // not on Inventory.

        // Setup: Create a new Item with Reserve as Always, new Purchase Order - Purchase Header, Purchase Line and release it.
        // Create a new Service Order - Service Header, Service Item Line and Service Line. Input a Quantity in Service Line that is
        // less than Quantity in Purchase Order and Auto Reserve.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateAndReleasePurchaseOrder(Item."No.", Quantity);

        CreateDocumentWithServiceItem(ServiceLine, LocationCode, Item."No.", Quantity - 1, ServiceLine."Document Type"::Order);
        LibraryService.AutoReserveServiceLine(ServiceLine);

        // Exercise and Verify:
        PostAndVerifyServiceOrderError(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOrderReserveFirmPlanError()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Covers document number TC-R-23 - refer to TFS ID 20927.
        // Test that the application generates an error on posting a Service Order while Item is reserved from Firm Planned Production Order
        // Line properly but is not on Inventory.

        // Setup: Create a new Item with Reserve as Always, new Firm Planned Production Order and refresh it. Create a new Service
        // Order - Service Header, Service Item Line and Service Line. Input a Quantity in Service Line that is less than Quantity in
        // Production Order and Auto Reserve.
        Initialize();
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        LocationCode := CreateFirmPlannedOrder(Item."No.", Quantity);

        CreateDocumentWithServiceItem(ServiceLine, LocationCode, Item."No.", Quantity - 1, ServiceLine."Document Type"::Order);
        LibraryService.AutoReserveServiceLine(ServiceLine);

        // Exercise and Verify:
        PostAndVerifyServiceOrderError(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ServiceLinesPageHandler,NoQuantityOnReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationNoSourceToReserve()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        // Check that no Entry to Reserve available when there is no source to reserve from.

        // 1. Setup: Create Item with Reserve Optional, Create Service Order with Service Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItemWithReserve(Item, Item.Reserve::Optional);
        ItemNo := Item."No.";  // Assign Item No. to global variable.
        CreateServiceOrder(ServiceHeader, Customer."No.", ItemNo);
        Commit();

        // 2. Exercise: Open Service Lines page.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Check that no Quantity available on Reservation Page. Verification done in Reservation Page Handler.
    end;

    [Test]
    [HandlerFunctions('ReserveLinePageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationWithSourceToReserve()
    var
        Customer: Record Customer;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
    begin
        // Check Quantities on Reservation Page of Service Lines after posting Purchase Order and reservation is optional.

        // 1. Setup: Find Customer, Create Item with Reserve Optional, Create and post Purchase Order, Create Service Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItemWithReserve(Item, Item.Reserve::Optional);
        AssignGlobalVariables(Item."No.");
        CreatePurchaseOrderNoLocation(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateServiceOrder(ServiceHeader, Customer."No.", ItemNo);
        Commit();

        // 2. Exercise: Open Service Lines page.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify that Quantities exists on Reservation Page. Verification done in Reservation Page Handler.
    end;

    [Test]
    [HandlerFunctions('ReserveLinePageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationWithAutoReserve()
    var
        Customer: Record Customer;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO 218302] Cassie can't change item from "X" to "Y" in service line when "X" has been reserved

        // Check Quantities on Reservation Page of Service Lines after posting Purchase Order and reservation is Always.

        // 1. Setup: Find a Customer, Create Item, Create and post Purchase Order.
        // [GIVEN] Service order with service line for item "X" and "X" has been reserved
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItemWithReserve(Item, Item.Reserve::Always);
        AssignGlobalVariables(Item."No.");
        QuantityReserved := QuantityOnServiceLine;
        CreatePurchaseOrderNoLocation(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateServiceOrder(ServiceHeader, Customer."No.", ItemNo);
        Commit();

        // 2. Exercise: Open Service Lines page.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify that Quantity on Service Line is Automatically Reserved. Verification done on Reservation Handler.
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        // [WHEN] Cassie changes item from "X" to "Y"
        asserterror ServiceLine.Validate("No.", LibraryInventory.CreateItemNo());

        // [THEN] Error 'No. must not be changed when a quantity is reserved in Service Line...' has been thrown
        Assert.ExpectedError('No. must not be changed when a quantity is reserved in Service Line');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ReservationLinePageHandler,ReservationEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryForAutoReserve()
    var
        Customer: Record Customer;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        ServiceHeader: Record "Service Header";
        Vendor: Record Vendor;
    begin
        // Check Quantities on Reservation Entries Page of Service Lines after posting Purchase Order and reservation is Always.

        // 1. Setup: Create Item, Purchase Order with Item Tracking assigned and post it. Create Service Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryPurchase.CreateVendor(Vendor);
        QuantityOnServiceLine := LibraryRandom.RandInt(5);  // Taking random integer value.
        OriginalQuantity := QuantityOnServiceLine + LibraryRandom.RandInt(10);  // Taking Value greater than QuantityOnServiceLine.
        ItemNo := CreateItemWithItemTracking(Item.Reserve::Always);  // Assign Item No. to global variable.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, OriginalQuantity);
        OpenPurchaseOrderPage(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateServiceOrder(ServiceHeader, Customer."No.", ItemNo);
        Commit();

        // 2. Exercise: Open Service Lines page.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verification Done in Reservation Entry Page Handler and in Reservation Entry table.
        FindReservationEntry(ReservationEntry, ReservationEntry."Item Tracking"::"Lot No.");
        ReservationEntry.TestField("Lot No.", FindLotNoFromItemLedgerEntry());
    end;

    [Test]
    [HandlerFunctions('ReserveLinePageHandler,AutoReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationWithReserveOptional()
    var
        Customer: Record Customer;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
    begin
        // Check Quantities on Reservation Page of Service Lines after posting Purchase Order and Auto Reserving from Reservation.

        // 1. Setup: Find Customer, Create Item, Create and post Purchase Order, Create Service Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItemWithReserve(Item, Item.Reserve::Optional);
        AssignGlobalVariables(Item."No.");
        CreatePurchaseOrderNoLocation(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateServiceOrder(ServiceHeader, Customer."No.", ItemNo);
        Commit();

        // 2. Exercise: Open Service Lines Page and Invoke Auto Reserve action on Reservation Page.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Quantities after doing auto reservation. Verification Done in Reservation Entry Page Handler.
    end;

    [Test]
    [HandlerFunctions('QuantityToCreatePageHandler,ServiceQuoteLinePageHandler,ServiceLineActionsPageHandler,ItemTrackingActionsPageHandler,TrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithTracking()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
        OrderNo: Code[20];
    begin
        // Check Item Tracking Quantity on Item Tracking Lines Page after creating Service Order from Service Quote.

        // 1. Setup: Create Item with Serial No, Create and post Item Journal Line, Create Service Quote with Item Tracking.
        Initialize();
        QuantityOnServiceLine := LibraryRandom.RandInt(5);  // Assigning random integer value.
        Quantity := QuantityOnServiceLine + LibraryRandom.RandInt(10);  // Taking Value greater than QuantityOnServiceLine.

        // Assigning global variables as required in Page Handler.
        ItemNo := CreateItemWithSerialAndLotNo(Item.Reserve::Optional, '');
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;
        ServiceLineAction := ServiceLineAction::ItemTracking;

        CreateJournalLine(ItemJournalLine, ItemNo, Quantity);
        OpenItemTrackingPageForJournal(ItemJournalLine."Journal Batch Name");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateDocumentWithServiceItem(ServiceLine, '', ItemNo, QuantityOnServiceLine, ServiceLine."Document Type"::Quote);
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        OpenServiceQuoteLinesPage(ServiceLine."Document No.");

        // 2. Exercise: Convert Service Quote into Service Order and Find Service Order No.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.CreateOrderFromQuote(ServiceHeader);
        OrderNo := FindServiceOrder(ServiceHeader."No.");

        // 3. Verify: Item Tracking on Service Order is same as Service Quote. Verification done in ItemTrackingActionsPageHandler.
        ItemTrackingAction := ItemTrackingAction::Verification;
        OpenServiceLinesPage(OrderNo);
    end;

    [Test]
    [HandlerFunctions('QuantityToCreatePageHandler,ServiceLineActionsPageHandler,ItemTrackingActionsPageHandler,TrackingSummaryPageHandler,ItemTrackingListHandler,ReserveFromCurrentLineHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReservationWithTracking()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
    begin
        // Check Quantities on Reservation Page after doing Reservation From Current Line on Service Order of the Item having Item Tracking.

        // 1. Setup: Create Item with Serial No, Create and post Item Journal Line, Create Service Order with Item Tracking.
        Initialize();
        QuantityOnServiceLine := 1;  // Taking Quantity as 1 to reserve specific serial no.
        Quantity := QuantityOnServiceLine + LibraryRandom.RandInt(10);  // Taking Value greater than QuantityOnServiceLine.

        // Assigning global variables as required in Page Handler.
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;
        ServiceLineAction := ServiceLineAction::ItemTracking;
        ItemNo := CreateItemWithSerialAndLotNo(Item.Reserve::Optional, '');

        CreateJournalLine(ItemJournalLine, ItemNo, Quantity);
        OpenItemTrackingPageForJournal(ItemJournalLine."Journal Batch Name");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateDocumentWithServiceItem(ServiceLine, '', ItemNo, QuantityOnServiceLine, ServiceLine."Document Type"::Order);
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        OpenServiceLinesPage(ServiceLine."Document No.");
        ServiceLineAction := ServiceLineAction::Reserve;

        // 2. Exercise: Open Service Lines Page and do Reservation in ServiceLinesPageHandler.
        OpenServiceLinesPage(ServiceLine."Document No.");

        // 3. Verify: Verify Quantities after doing Reservation From Current Line. Verification Done in ReserveFromCurrentLineHandler.
    end;

    [Test]
    [HandlerFunctions('QuantityToCreatePageHandler,ServiceLineActionsPageHandler,ItemTrackingActionsPageHandler,TrackingSummaryPageHandler,ItemTrackingListHandler,ReserveFromCurrentLineHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure InvoiceReservationWithTracking()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
    begin
        // Check Quantity Invoiced after posting a Service Order with Reservation From Current Line and Item has Item Tracking.

        // 1. Setup: Create Item with Serial No, Create and post Item Journal Line, Create Service Order with Item Tracking and Reservation.
        Initialize();
        QuantityOnServiceLine := 1;  // Taking Quantity as 1 to reserve specific serial no.
        Quantity := QuantityOnServiceLine + LibraryRandom.RandInt(10);  // Taking Value greater than QuantityOnServiceLine.

        // Assigning global variables as required in Page Handler.
        ItemNo := CreateItemWithSerialAndLotNo(Item.Reserve::Optional, '');
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;
        ServiceLineAction := ServiceLineAction::ItemTracking;

        CreateJournalLine(ItemJournalLine, ItemNo, Quantity);
        OpenItemTrackingPageForJournal(ItemJournalLine."Journal Batch Name");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateDocumentWithServiceItem(ServiceLine, '', ItemNo, QuantityOnServiceLine, ServiceLine."Document Type"::Order);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        OpenServiceLinesPage(ServiceHeader."No.");
        ServiceLineAction := ServiceLineAction::Reserve;
        OpenServiceLinesPage(ServiceHeader."No.");

        // 2. Exercise: Ship and Invoice Service Order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verification done for Quantity in Service Invoice Line.
        VerifyServiceInvoiceLine(GetServiceInvoiceNoForOrder(ServiceLine."Document No."), ServiceLine."Line No.", QuantityOnServiceLine);
    end;

    [Test]
    [HandlerFunctions('QuantityToCreatePageHandler,ServiceLineActionsPageHandler,ItemTrackingActionsPageHandler,TrackingSummaryPageHandler,ItemTrackingListHandler,ReserveFromCurrentLineHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ConsumeReservationWithTracking()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
    begin
        // Check Quantity Consumed after posting a Service Order with Reservation From Current Line and Item has Item Tracking.

        // 1. Setup: Create Item with Serial No, Create and post Item Journal Line, Create Service Order with Item Tracking and Reservation.
        Initialize();
        QuantityOnServiceLine := 1;  // Taking Quantity as 1 to reserve specific serial no.
        Quantity := QuantityOnServiceLine + LibraryRandom.RandInt(10);  // Taking Value greater than QuantityOnServiceLine.

        // Assigning global variables as required in Page Handler.
        ItemNo := CreateItemWithSerialAndLotNo(Item.Reserve::Optional, '');
        ServiceLineAction := ServiceLineAction::ItemTracking;
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;

        CreateJournalLine(ItemJournalLine, ItemNo, Quantity);
        OpenItemTrackingPageForJournal(ItemJournalLine."Journal Batch Name");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateDocumentWithServiceItem(ServiceLine, '', ItemNo, QuantityOnServiceLine, ServiceLine."Document Type"::Order);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        OpenServiceLinesPage(ServiceHeader."No.");
        ServiceLineAction := ServiceLineAction::Reserve;
        OpenServiceLinesPage(ServiceHeader."No.");

        // 2. Exercise: Ship and Consume Service Order.
        ServiceLine.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.");
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verification done for Quantity Consumed in Service Shipment Line.
        VerifyShipmentLineAfterConsume(ServiceLine."Document No.", ServiceLine."Line No.", QuantityOnServiceLine);
    end;

    [Test]
    [HandlerFunctions('ServiceLinePageLocationHandler')]
    [Scope('OnPrem')]
    procedure ModifyLocationOnReservedLine()
    var
        Item: Record Item;
        Customer: Record Customer;
        ItemJournalLine: Record "Item Journal Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
    begin
        // Check that application generates an error on changing Location on Service Lines when Reservation is Always.

        // 1. Setup: Find Customer, Create Item with Reserve as Always, Create and post Item Journal Line, Create Service Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        AssignGlobalVariableForHandler(Item."No.", Quantity);
        CreateJournalLine(ItemJournalLine, ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateServiceOrder(ServiceHeader, Customer."No.", ItemNo);
        Commit();

        // 2. Exercise: Set values on Service Line Page in ServiceLinePageLocationHandler, Find Service Line and change Location.
        OpenServiceLinesPage(ServiceHeader."No.");
        FindServiceLine(ServiceLine, ServiceHeader."Document Type", ServiceHeader."No.", ServiceHeader."Bill-to Customer No.");
        asserterror ServiceLine.Validate("Location Code", FindLocation());

        // 3. Verify: Verify that application generates an error on changing Location.
        Assert.ExpectedError(
          StrSubstNo(
            ReserveQuantityError, ServiceLine.FieldCaption("Location Code"), ServiceLine.TableCaption(),
            ServiceLine.FieldCaption("Document Type"), ServiceLine."Document Type", ServiceLine.FieldCaption("Document No."),
            ServiceLine."Document No.", ServiceLine.FieldCaption("Line No."), ServiceLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ServiceLinePageTypeHandler')]
    [Scope('OnPrem')]
    procedure ModifyTypeOnReservedLine()
    var
        Item: Record Item;
        Customer: Record Customer;
        ItemJournalLine: Record "Item Journal Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
    begin
        // Check that application generates an error on changing Type on Service Lines when Reservation is Always.

        // 1. Setup: Find Customer, Create Item with Reserve as Always, Create and post Item Journal Line, Create Service Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        AssignGlobalVariableForHandler(Item."No.", Quantity);
        CreateJournalLine(ItemJournalLine, ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateServiceOrder(ServiceHeader, Customer."No.", ItemNo);
        Commit();

        // 2. Exercise: Set values on Service Line Page in ServiceLinePageTypeHandler, Find Service Line and change Type
        OpenServiceLinesPage(ServiceHeader."No.");
        FindServiceLine(ServiceLine, ServiceHeader."Document Type", ServiceHeader."No.", ServiceHeader."Bill-to Customer No.");
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::Resource);

        // 3. Verify: Verify that application generates an error on changing Type.
        Assert.ExpectedError(
          StrSubstNo(
            ReserveQuantityError, ServiceLine.FieldCaption(Type), ServiceLine.TableCaption(),
            ServiceLine.FieldCaption("Document Type"), ServiceLine."Document Type",
            ServiceLine.FieldCaption("Document No."), ServiceLine."Document No.",
            ServiceLine.FieldCaption("Line No."), ServiceLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ServiceLinePageSetValueHandler')]
    [Scope('OnPrem')]
    procedure DeleteReservedLine()
    var
        Item: Record Item;
        Customer: Record Customer;
        ItemJournalLine: Record "Item Journal Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
    begin
        // Check that application allows deletion of Service Lines when Reservation is Always.

        // 1. Setup: Find Customer, Create Item with Reserve as Always, Create and post Item Journal Line, Create Service Order and
        // set values on Service Line in ServiceLinePageSetValueHandler.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItemWithReserve(Item, Item.Reserve::Always);
        Quantity := LibraryRandom.RandDec(10, 2);
        AssignGlobalVariableForHandler(Item."No.", Quantity);
        CreateJournalLine(ItemJournalLine, ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateServiceOrder(ServiceHeader, Customer."No.", ItemNo);
        Commit();
        OpenServiceLinesPage(ServiceHeader."No.");

        // 2. Exercise: Delete all service lines.
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.DeleteAll(true);

        // 3. Verify: Verify that all lines has been deleted.
        Assert.IsFalse(ServiceLine.FindFirst(), StrSubstNo(ServiceLineExistError, ServiceLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('QuantityToCreatePageHandler,ServiceLineTrackingPageHandler,ItemTrackingActionsPageHandler,TrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ShipReservationWithTracking()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ValueEntry: Record "Value Entry";
        Quantity: Decimal;
        ServiceLineQuantity: Decimal;
        ServiceShipmentNo: Code[20];
    begin
        // Test that the application allows Shipping the Service Order for item having Reserve as Always and Item Tracking.

        // 1. Setup: Create Item with Serial No, Create and post Item Journal Line, Create Service Order with Item Tracking.
        Initialize();
        ServiceLineQuantity := LibraryRandom.RandInt(5);  // Assigning random integer value.
        Quantity := ServiceLineQuantity + LibraryRandom.RandInt(10);  // Taking Value greater than ServiceLineQuantity.

        // Assigning global variables as required in Page Handler
        ItemNo := CreateItemWithSerialAndLotNo(Item.Reserve::Always, '');
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;

        CreateJournalLine(ItemJournalLine, ItemNo, Quantity);
        OpenItemTrackingPageForJournal(ItemJournalLine."Journal Batch Name");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateDocumentWithServiceItem(ServiceLine, '', ItemNo, ServiceLineQuantity, ServiceLine."Document Type"::Order);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        OpenServiceLinesPage(ServiceLine."Document No.");

        // 2. Exercise: Ship Service Order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceShipmentNo := GetServiceShipmentNo(ServiceHeader."No.");

        // 3. Verify: Verify that Correct Ledger Entries have been created.
        VerifyShipmentLineAfterShip(ServiceLine."Document No.", ServiceLine."Line No.", ServiceLine.Quantity);
        VerifyItemLedgerEntryCount(ServiceShipmentNo, ServiceLine.Quantity);
        VerifyValueEntryCount(ServiceLine, ValueEntry."Document Type"::"Service Shipment", ServiceShipmentNo);
    end;

    [Test]
    [HandlerFunctions('QuantityToCreatePageHandler,ServiceLineTrackingPageHandler,ItemTrackingActionsPageHandler,TrackingSummaryPageHandler,GetServiceShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure PostInvoiceFromGetShipmentLine()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ValueEntry: Record "Value Entry";
        Quantity: Decimal;
        ServiceLineQuantity: Decimal;
        ServiceInvoiceNo: Code[20];
    begin
        // Test that the application allows posting Service Invoice created from Get Shipment for item having Reservation and Item Tracking.

        // 1. Setup: Create Item with Serial No, Create and post Item Journal Line, Create and Ship Service Order with Item Tracking.
        Initialize();
        ServiceLineQuantity := LibraryRandom.RandInt(5);  // Assigning random integer value.
        Quantity := ServiceLineQuantity + LibraryRandom.RandInt(10);  // Taking Value greater than ServiceLineQuantity.

        // Assigning global variables as required in Page Handler
        ItemNo := CreateItemWithSerialAndLotNo(Item.Reserve::Always, '');
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;

        CreateJournalLine(ItemJournalLine, ItemNo, Quantity);
        OpenItemTrackingPageForJournal(ItemJournalLine."Journal Batch Name");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateDocumentWithServiceItem(ServiceLine, '', ItemNo, ServiceLineQuantity, ServiceLine."Document Type"::Order);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        OpenServiceLinesPage(ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Clear(ServiceHeader);

        // 2. Exercise: Create Serive Invoice From Get Shipment Lines in GetServiceShipmentLinesHandler and Post.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceLine."Customer No.");
        OpenServiceInvoicePage(ServiceHeader."No.");
        FindServiceLine(ServiceLine, ServiceHeader."Document Type", ServiceHeader."No.", ServiceHeader."Bill-to Customer No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceNo := GetServiceInvoiceNo(ServiceHeader."No.");

        // 3. Verify: Verify that Correct Ledger Entries have been created.
        VerifyServiceInvoiceLine(ServiceInvoiceNo, ServiceLine."Line No.", ServiceLineQuantity);
        VerifyServiceLedgerEntry(ServiceLine, ServiceLine."Document Type"::Invoice, ServiceInvoiceNo, -ServiceLineQuantity);
        VerifyValueEntryCount(ServiceLine, ValueEntry."Document Type"::"Service Invoice", ServiceInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('QuantityToCreatePageHandler,ItemTrackingActionsPageHandler')]
    [Scope('OnPrem')]
    procedure PostCreditMemoWithTracking()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ValueEntry: Record "Value Entry";
        ServiceCreditMemoNo: Code[20];
        Quantity: Decimal;
    begin
        // Test that the application allows posting Service Credit Memo for item having Item Tracking.

        // 1. Setup: Create Item with Serial No, Create Service Credit Memo with Item Tracking.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Assigning random integer value.
        Item.Get(CreateItemWithSerialAndLotNo(Item.Reserve::Optional, ''));
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;  // Assigning global variables as required in Page Handler
        CreateServiceDocument(ServiceLine, '', Item."No.", ServiceLine."Document Type"::"Credit Memo");
        UpdateServiceLineQuantity(ServiceLine, Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        OpenServiceCreditMemoPage(ServiceHeader."No.");

        // 2. Exercise: Post Service Credit Memo.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceCreditMemoNo := GetServiceCreditMemoNo(ServiceHeader."No.");

        // 3. Verify: Verification done for Posted Entries.
        VerifyServiceCreditMemoLine(ServiceCreditMemoNo, ServiceLine."Line No.", Item."No.", Quantity);
        VerifyServiceLedgerEntry(ServiceLine, ServiceLine."Document Type"::"Credit Memo", ServiceCreditMemoNo, Quantity);
        VerifyValueEntryCount(ServiceLine, ValueEntry."Document Type"::"Service Credit Memo", ServiceCreditMemoNo)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveColumnIsNotValidatedInSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Purchasing: array[2] of Record Purchasing;
    begin
        // [FEATURE] [Sales Order]
        // [SCENARIO 379722] The Reserve column in Sales Line is not changing when switching the Purchasing Code from one with Drop Shipment to another one without it.
        Initialize();

        // [GIVEN] Item with Reserve field = "Always".
        ItemNo := CreateItemWithItemTracking(Item.Reserve::Always);

        // [GIVEN] Sales Order with one Sales Line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(5));

        // [GIVEN] Create Purchasing Code With Drop Shipment and set in Sales Line.
        CreatePurchasingCodeWithDropShipment(Purchasing[1]);
        SalesLine.Validate("Purchasing Code", Purchasing[1].Code);
        SalesLine.Modify(true);

        // [GIVEN] Create Purchasing Code without Drop Shipment.
        LibraryPurchase.CreatePurchasingCode(Purchasing[2]);

        // [WHEN] Set Purchasing Code in Sales Line.
        SalesLine.Validate("Purchasing Code", Purchasing[2].Code);
        SalesLine.Modify(true);

        // [THEN] Reserve field = "Always" In Sales Line.
        SalesLine.TestField(Reserve, Item.Reserve::Always);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,SetValuesOnServiceLinePageHandler')]
    [Scope('OnPrem')]
    procedure ReserveLotWhenReserveAlways()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Check Reservation of an Item on Service Line after creating Purchase Order when Reserve type is Always.

        // 1. Setup: Create Item with Reserve Always, Create a Purchase Order, Service Order.
        Initialize();
        ItemNo := CreateItemWithItemTracking(Item.Reserve::Always);
        OriginalQuantity := 1 + LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        QuantityOnServiceLine := OriginalQuantity - 1;  // Take Quantity for Service Line lesser than Purchased Quantity, Assign Value to Global Variable.

        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader);
        OpenPurchaseOrderPage(PurchaseHeader."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Open Service Lines Page from Service Order and assign values to Service Line.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Reserved Quantity on Service Lines.
        FindServiceLine(ServiceLine, ServiceHeader."Document Type", ServiceHeader."No.", ServiceHeader."Bill-to Customer No.");
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", QuantityOnServiceLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,OpenReservationFromServiceLinesPageHandler,ReservationEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryForLotWhenReserveAlways()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Check Reservation Entry of an Item on Service Line while reserving from Purchase Order and Reserve type is Always.

        // 1. Setup: Create Item with Reserve Always, Create a Purchase Order, Service Order.
        Initialize();
        ItemNo := CreateItemWithItemTracking(Item.Reserve::Always);
        OriginalQuantity := 1 + LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        QuantityOnServiceLine := OriginalQuantity - 1;  // Take Quantity for Service Line lesser than Purchased Quantity, Assign Value to Global Variable.

        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader);
        OpenPurchaseOrderPage(PurchaseHeader."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Fill values on Service Lines Page opened through Service Order Page.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Reservation Entries on Reservation Entries Page. Verification Done in ReservationEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ReserveFromServiceLinePageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntrySummaryBeforeReserve()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Check different quantities before Reserving Item in Reservation Page when Reserve is optional.

        // 1. Setup: Create Item with Reserve optional, Create Purchase Order and assign Lot No., create Service Order.
        Initialize();
        ItemNo := CreateItemWithItemTracking(Item.Reserve::Optional);  // Assign Item No. to Global Variable.
        OriginalQuantity := 1 + LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        QuantityOnServiceLine := OriginalQuantity - 1;  // Take Quantity for Service Line lesser than Purchased Quantity, Assign Value to Global Variable.
        QuantityReserved := 0;  // Setting value 0 because reservation is optional so Quantities are not reserved automatically.

        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader);
        OpenPurchaseOrderPage(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Open Service Lines Page from Service Order.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Quantity Before Reserve on Reservation Page. Verification done on ReservationPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ReserveFromServiceLinePageHandler,AvailableToReserveReservationPageHandler,AvailableItemLedgEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveLotFromAvailableItemLedgerEntries()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Check Reserverd Quantity after reserving Item from Available Item Ledger Entries Page opened from Service Line and Item Reserve Policy is Optional.

        // 1. Setup: Create Item with Reserve Optional, Create a Purchase Order, Service Order.
        Initialize();
        ItemNo := CreateItemWithItemTracking(Item.Reserve::Optional);  // Assign Item No. to Global Variable.
        OriginalQuantity := 1 + LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        QuantityOnServiceLine := OriginalQuantity - 1;  // Take Quantity for Service Line lesser than Purchased Quantity, Assign Value to Global Variable.

        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader);
        OpenPurchaseOrderPage(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Open Service Lines Page from Service Order.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Reserved Quantity on Available Item Ledger Entries Page. Verification Done in AvailableItemLedgEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ReserveFromServiceLinePageHandler,AvailableToReserveReservationPageHandler,ReserveFromAvailableItemLedgEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveLotWhenReserveOptional()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Check Lot No. and Reservation Entry for an Item Reserved from Available Item Ledger Entries Page opened from Service Line.

        // 1. Setup: Create Item with Reserve Optional, Create a Purchase Order, Service Order.
        Initialize();
        ItemNo := CreateItemWithItemTracking(Item.Reserve::Optional);  // Assign Item No. to global variable.
        OriginalQuantity := 1 + LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        QuantityOnServiceLine := OriginalQuantity - 1;  // Take Quantity for Service Line lesser than Purchased Quantity, Assign Value to Global Variable.

        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader);
        OpenPurchaseOrderPage(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Open Service Lines Page from Service Order.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Reservation Entry after Reserving the Item.
        FindReservationEntry(ReservationEntry, ReservationEntry."Item Tracking"::"Lot No.");
        ReservationEntry.TestField("Lot No.", FindLotNoFromItemLedgerEntry());
        ReservationEntry.TestField("Quantity (Base)", QuantityOnServiceLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingActionsPageHandler,CreateLotFromQuantityToCreatePageHandler,SetValuesOnServiceLinePageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSerialAndLotWhenReserveAlways()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Check Reservation of an Item with Serial No. and Reserve Always on Service Line after creating Purchase Order.

        // 1. Setup: Create Item with Reserve Always, Find a Customer and Vendor, Create a Purchase Order, Service Order.
        Initialize();
        ItemNo := CreateItemWithSerialAndLotNo(Item.Reserve::Always, LibraryUtility.GetGlobalNoSeriesCode());  // Assign Item No. to Global Variable.
        OriginalQuantity := 1 + LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        QuantityOnServiceLine := OriginalQuantity - 1;  // Take Quantity for Service Line lesser than Purchased Quantity, Assign Value to Global Variable.

        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader);
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;
        OpenPurchaseOrderPage(PurchaseHeader."No.");

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Open Service Lines Page from Service Order.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Reserved Quantity on Service Lines and corresponding Reservation Entries.
        FindServiceLine(ServiceLine, ServiceHeader."Document Type", ServiceHeader."No.", ServiceHeader."Bill-to Customer No.");
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", QuantityOnServiceLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingActionsPageHandler,CreateLotFromQuantityToCreatePageHandler,OpenReservationFromServiceLinesPageHandler,ReservationEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryForSerialAndLotWhenReserveAlways()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Check Reservation of an Item with Serial No. and Reserve Always on Service Line after creating Purchase Order.

        // 1. Setup: Create Item with Reserve Always, Find a Customer and Vendor, Create a Purchase Order, Service Order.
        Initialize();
        ItemNo := CreateItemWithSerialAndLotNo(Item.Reserve::Always, LibraryUtility.GetGlobalNoSeriesCode());  // Assign Item No. to Global Variable.
        OriginalQuantity := LibraryRandom.RandInt(10);  // Random Integer value. Assign it to Global Variable.
        QuantityOnServiceLine := 1;  // Take Quantity as 1 to avoid Serial No Reservation issue, Assign Value to Global Variable.

        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader);
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;
        OpenPurchaseOrderPage(PurchaseHeader."No.");

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Open Service Lines Page from Service Order.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Reservation Entries on Reservation Entries Page. Verification Done in ReservationEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingActionsPageHandler,CreateLotFromQuantityToCreatePageHandler,ReserveFromServiceLinePageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntrySummaryForSerialAndLotBeforeReserve()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Check Reserverd Quantity on Available Item Ledger Entries Page opened from Service Line and Item with Serial And Lot Nos. and Reserve Optional.

        // 1. Setup: Create Item with Reserve Optional, Create a Purchase Order, Service Order.
        Initialize();
        ItemNo := CreateItemWithSerialAndLotNo(Item.Reserve::Optional, LibraryUtility.GetGlobalNoSeriesCode());  // Assign Item No. to Global Variable.
        OriginalQuantity := LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        QuantityOnServiceLine := 1;  // Take Quantity as 1 to avoid Serial No Reservation issue, Assign Value to Global Variable.

        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader);
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;
        OpenPurchaseOrderPage(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Open Service Lines Page from Service Order.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Quantity Before Reserve on Reservation Page. Verification done on ReservationPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingActionsPageHandler,CreateLotFromQuantityToCreatePageHandler,ReserveFromServiceLinePageHandler,AvailableToReserveReservationPageHandler,AvailableItemLedgEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSerialAndLotFromAvailableItemLedgerEntries()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Check Reserverd Quantity on Available Item Ledger Entries Page opened from Service Line and Item with Serial And Lot Nos. and Reserve Optional.

        // 1. Setup: Create Item with Reserve Optional, Find a Customer and Vendor, Create a Purchase Order, Service Order.
        Initialize();
        ItemNo := CreateItemWithSerialAndLotNo(Item.Reserve::Optional, LibraryUtility.GetGlobalNoSeriesCode());  // Assign Item No. to Global Variable.
        OriginalQuantity := LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        QuantityOnServiceLine := 1;  // Take Quantity as 1 to avoid Serial No Reservation issue, Assign Value to Global Variable.

        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader);
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;
        OpenPurchaseOrderPage(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Open Service Lines Page from Service Order.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Reserved Quantity on Available Item Ledger Entries Page.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingActionsPageHandler,CreateLotFromQuantityToCreatePageHandler,ReserveFromServiceLinePageHandler,AvailableToReserveReservationPageHandler,ReserveFromAvailableItemLedgEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSerialNoWhenReserveOptional()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Check Serial No., Lot No., Reservation Entry for an Item Reserved from Available Item Ledger Entries Page opened from Service Line.

        // 1. Setup: Create Item with Reserve Optional and Serial No and Lot No Series attached, Create a Purchase Order, Service Order.
        Initialize();
        ItemNo := CreateItemWithSerialAndLotNo(Item.Reserve::Optional, LibraryUtility.GetGlobalNoSeriesCode());  // Assign Item No. to global variable.
        OriginalQuantity := LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        QuantityOnServiceLine := 1;  // Take Quantity as 1 to avoid Serial No Reservation issue, Assign Value to Global Variable.

        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader);
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;

        OpenPurchaseOrderPage(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Open Service Lines Page from Service Order.
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Reservation Entry after Reserving the Item.
        FindReservationEntry(ReservationEntry, ReservationEntry."Item Tracking"::"Lot and Serial No.");
        ReservationEntry.TestField("Serial No.", FindSerialNoFromItemLedgerEntry(ItemNo));
        ReservationEntry.TestField("Lot No.", FindLotNoFromItemLedgerEntry());
        ReservationEntry.TestField("Quantity (Base)", QuantityOnServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderReservationWithResourceShouldFail()
    var
        Resource: Record Resource;
        ServiceLine: Record "Service Line";
    begin
        // Verify the error message while reserving the Item from Purchase Order to Service Order when Type is Resource on Service Line.

        // 1. Setup: Create Purchase Order and Service Order and update Service Line with Type Resource.
        Initialize();
        CreatePurchaseOrderAndServiceOrder(ServiceLine);
        Resource.Init();
        Resource."No." := ServiceLine."No.";
        if Resource.Insert() then;
        ServiceLine.Validate(Type, ServiceLine.Type::Resource);
        ServiceLine.Modify(true);

        // 2. Exercise: Reserve the Item from Service Line.
        asserterror OpenReservationPage(ServiceLine."Service Item No.");

        // 3. Verify: Verify error message.
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption(Type), Format(ServiceLine.Type::Item));
    end;

    [Test]
    [HandlerFunctions('ServiceLinesPageHandler,NoQuantityOnReservePageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderReservationWithEarlierNeededByDate()
    begin
        // Verify reservation lines when Needed By Date is earlier than Expected Receipt Date on Service Line.

        Initialize();
        ServiceOrderReservationWithNeededByDate(-1);  // Take -1 as SignFactor.

        // 3. Verify: Verify Reservation window for available Quantity. Verification done in 'NoQuantityOnReservePageHandler'.
    end;

    [Test]
    [HandlerFunctions('ServiceLinesPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderReservationWithLaterNeededByDate()
    begin
        // Verify reservation lines when Needed By Date is later than Expected Receipt Date on Service Line.

        Initialize();
        ServiceOrderReservationWithNeededByDate(1);  // Take 1 as SignFactor.

        // 3. Verify: Verify Reservation window for available Quantity. Verification done in 'ReservationPageHandler'.
    end;

    local procedure ServiceOrderReservationWithNeededByDate(SignFactor: Integer)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ExpectedReceiptDate: Date;
    begin
        // 1. Setup: Create Purchase Order and Service Order and update Service Line with Needed by Date.
        Initialize();
        ExpectedReceiptDate := CreatePurchaseOrderAndServiceOrder(ServiceLine);
        ServiceLine.Validate("Needed by Date", CalcDate('<' + Format(SignFactor * LibraryRandom.RandInt(5)) + 'D>', ExpectedReceiptDate));  // Use Random to calculate Needed by Date earlier than Expected Receipt Date.
        ServiceLine.Modify(true);
        QuantityOnServiceLine := ServiceLine.Quantity;  // Assign in global variable.
        QuantityReserved := OriginalQuantity - QuantityOnServiceLine;  // Assign in global variable.

        // 2. Exercise: Reserve the Item from Service Line.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        OpenServiceLinesPage(ServiceHeader."No.")
    end;

    [Test]
    [HandlerFunctions('ServiceLinesPageHandler,NoQuantityOnReservePageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderReservationWithWrongLocation()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify reservation lines when Location is wrong on Service Line.

        // 1. Setup: Create Purchase Order and Service Order and update Service Line with a new location.
        Initialize();
        CreatePurchaseOrderAndServiceOrder(ServiceLine);
        ServiceLine.Validate("Location Code", FindLocation());
        ServiceLine.Modify(true);

        // 2. Exercise: Reserve the Item from Service Line.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Reservation window for available Quantity. Verification done in 'NoQuantityOnReservePageHandler'.
    end;

    [Test]
    [HandlerFunctions('ServiceLinesPageHandler,ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ReserveItemFromServiceOrderToInventory()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Reserved Quantity on Reservation window when reserve Item from Service Order to Inventory.

        // 1. Setup: Create Item, create and post Item Journal Line for Inventory and create Service Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";  // Assign in global variable.
        OriginalQuantity := LibraryRandom.RandInt(10);  // Assign Random Quantity in global variable.
        CreateJournalLine(ItemJournalLine, ItemNo, OriginalQuantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateDocumentWithServiceItem(
          ServiceLine, ItemJournalLine."Location Code", ItemNo, OriginalQuantity, ServiceLine."Document Type"::Order);
        ServiceLine.Modify(true);
        QuantityOnServiceLine := ServiceLine.Quantity;  // Assign in global variable.

        // 2. Exercise: Reserve the Item from Service Line.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verify: Verify Reservation window for available Quantity. Verification done in 'ReserveFromCurrentLineHandler'.
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure ReservationErrorOnPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Reservation error on the Purchase Order page.

        // 1. Setup.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandDec(10, 2));  // Taken Random value for Quantity.
        ReserveFromCurrentLine := true;  // Assign in global variable.

        // 2. Exercise.
        asserterror OpenReserveFromPurchaseOrderPage(PurchaseHeader."No.");

        // 3. Verfiy: Verify Reservation Error.
        Assert.ExpectedError(ReserveError);
    end;

    [Test]
    [HandlerFunctions('ServiceLinesPageHandler,ReservationHandler')]
    [Scope('OnPrem')]
    procedure ReservationErrorOnServiceLines()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        ServiceLine: Record "Service Line";
    begin
        // Check Reservation error on the Service Lines page.

        // 1. Setup: Create and post Purchase Order create Transfer Order and Service Line.
        Initialize();
        CreatePurchaseOrder(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateTransferOrder(TransferHeader, PurchaseHeader."Location Code");
        CreateDocumentWithServiceItem(
          ServiceLine, TransferHeader."Transfer-to Code", PurchaseLine."No.", PurchaseLine.Quantity, ServiceLine."Document Type"::Order);
        ReserveFromCurrentLine := true;  // Assign in global variable.

        // 2. Exercise: Open Service Lines page.
        asserterror OpenServiceLinesPage(ServiceLine."Document No.");

        // 3. Verfiy: Verify Reservation Error.
        Assert.ExpectedError(ReserveError);
    end;

    [Test]
    [HandlerFunctions('ServiceLinesPageHandler,ReservationHandler')]
    [Scope('OnPrem')]
    procedure ReservationAfterPostingServiceLines()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        ServiceItemLine: Record "Service Item Line";
    begin
        // Check Reservation on Service Order with Purchase Order and Transfer Order.

        // 1. Setup: Create and post Purchase Order, Transfer Order and Service Line.
        Initialize();
        CreatePurchaseOrder(PurchaseLine);
        OriginalQuantity := PurchaseLine.Quantity;  // Assign in global variable.
        ItemNo := PurchaseLine."No.";  // Assign in global variable.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateTransferOrder(TransferHeader, PurchaseHeader."Location Code");
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        UpdateServiceLine(ServiceLine, TransferHeader."Transfer-to Code", ServiceItemLine."Line No.");
        QuantityOnServiceLine := ServiceLine.Quantity;

        ReserveFromCurrentLine := true;  // Assign in global variable.
        OpenServiceLinesPage(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ReserveFromCurrentLine := false;  // Assign in global variable.

        // 2. Exercise:
        OpenServiceLinesPage(ServiceHeader."No.");

        // 3. Verfiy: Verify Reservation page values.
        // Verification done in 'ReservationHandler'.
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure ReservationOnPurchaseOrderErrorWithServiceOrder()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        ServiceLine: Record "Service Line";
    begin
        // Check Reservation error on Purchase Order with Service Order.

        // 1. Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreateDocumentWithServiceItem(
          ServiceLine, PurchaseHeader."Location Code", PurchaseLine."No.", PurchaseLine.Quantity, ServiceLine."Document Type"::Order);

        // 2. Exercise.
        ReserveFromCurrentLine := true;  // Assign in global variable.
        asserterror OpenReserveFromPurchaseOrderPage(PurchaseHeader."No.");

        // 3. Verfiy: Verify Reservation Error.
        Assert.ExpectedError(ReserveError);
    end;

    [Test]
    [HandlerFunctions('ServiceLinesPageHandler,ReserveServiceLinesHandler')]
    [Scope('OnPrem')]
    procedure ReservationOnServiceLinesWithPurchaseOrder()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        ServiceLine: Record "Service Line";
    begin
        // Check Reservation without posting of Service Order with Purchase Order.

        // 1. Setup: Create and post Purchase Order, Transfer Order and Service Order.
        Initialize();
        CreatePurchaseOrder(PurchaseLine);
        OriginalQuantity := PurchaseLine.Quantity;  // Assign in global variable.
        ItemNo := PurchaseLine."No.";  // Assign in global variable.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateTransferOrder(TransferHeader, PurchaseHeader."Location Code");
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
        CreateDocumentWithServiceItem(
          ServiceLine, TransferHeader."Transfer-to Code", ItemNo, OriginalQuantity, ServiceLine."Document Type"::Order);
        QuantityOnServiceLine := ServiceLine.Quantity;

        // 2. Exercise: Open Service Lines page.
        OpenServiceLinesPage(ServiceLine."Document No.");

        // 3. Verfiy: Verify Reservation values. Verification done in 'ReserveServiceLinesHandler'.
    end;

    local procedure CreatePurchaseOrderAndServiceOrder(var ServiceLine: Record "Service Line") ExpectedReceiptDate: Date
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";  // Assign in global variable.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);  // Assign Random Quantity in global variable.
        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader);
        ExpectedReceiptDate := PurchaseHeader."Expected Receipt Date";
        CreateDocumentWithServiceItem(
          ServiceLine, PurchaseHeader."Location Code", ItemNo, OriginalQuantity, ServiceLine."Document Type"::Order);
    end;

    local procedure AssignGlobalVariables(ItemNumber: Code[20])
    begin
        // Take Random Quantity for Document and Less Qunatity for Service Line.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        QuantityOnServiceLine := OriginalQuantity / 2;
        ItemNo := ItemNumber;
    end;

    local procedure AssignGlobalVariableForHandler(ItemNumber: Code[20]; Quantity: Decimal)
    begin
        ItemNo := ItemNumber;
        QuantityOnServiceLine := Quantity / 2; // Taking Random Quantity for Purchase and Less Qunatity for Service Line.
    end;

    local procedure CreatePurchaseOrderNoLocation(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, OriginalQuantity);
    end;

    local procedure CreatePurchaseOrderWithExpectedReceiptDate(var PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseOrderNoLocation(PurchaseHeader);
        PurchaseHeader.Validate("Expected Receipt Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Update Receipt Date earlier than WORKDATE. Use Random to calculate Date.
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateItemWithItemTracking(Reserve: Enum "Reserve Method"): Code[20]
    var
        Item: Record Item;
    begin
        CreateItemWithReserve(Item, Reserve);
        Item.Validate("Item Tracking Code", FindItemTrackingCode(true, false));
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure OpenPurchaseOrderPage(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchLines."Item Tracking Lines".Invoke();
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedQuantityOnSalesOrderSubformIsSetAutomaticallyForAutomaticReservation()
    var
        Item: Record Item;
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Automatic Reservation] [Sales Order]
        // [SCENARIO 363178] Reserved Quantity on Sales Order Subform is set automatically for Automatic Reservation
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Item on Inventory with Reserve = Optional
        CreateItemWithReserve(Item, Item.Reserve::Optional);
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Quantity, WorkDate(), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Sales Order for Customer with Reserve = Always
        CreateSalesOrderLineByPage(SalesOrder, CreateCustomerWithReserveAlways(), Item."No.");

        // [WHEN] Set Quantity on Sales Order Subform to "Q"
        SalesOrder.SalesLines.Quantity.SetValue(Quantity);

        // [THEN] Reserved Quantity on Sales Order Subform is "Q"
        SalesOrder.SalesLines."Reserved Quantity".AssertEquals(Quantity);
    end;

    local procedure InitializeGlobalVariables()
    begin
        // Clear all Global Variables.
        Clear(ItemNo);
        QuantityOnServiceLine := 0;
        OriginalQuantity := 0;
        QuantityReserved := 0;
        Clear(ItemTrackingAction);
        Clear(ServiceLineAction);
        ReserveFromCurrentLine := false;
    end;

    local procedure FindItemTrackingCode(LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.SetRange("Man. Expir. Date Entry Reqd.", false);
        ItemTrackingCode.SetRange("Lot Specific Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("Lot Sales Inbound Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("Lot Sales Outbound Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("SN Specific Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.SetRange("SN Sales Inbound Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.SetRange("SN Sales Outbound Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.FindFirst();
        exit(ItemTrackingCode.Code);
    end;

    local procedure FindLotNoFromItemLedgerEntry(): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        exit(ItemLedgerEntry."Lot No.");
    end;

    local procedure FindReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemTracking: Enum "Item Tracking Entry Type")
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Item Tracking", ItemTracking);
        ReservationEntry.FindFirst();
    end;

    local procedure FindSerialNoFromItemLedgerEntry(ItemNo: Code[20]): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        exit(ItemLedgerEntry."Serial No.");
    end;

    local procedure FindLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetRange("Use As In-Transit", false);
        Location.SetRange("Bin Mandatory", false);
        Location.Next(LibraryRandom.RandInt(Location.Count));
        exit(Location.Code);
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; BilltoCustomerNo: Code[20])
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetFilter("Document No.", DocumentNo);
        ServiceLine.SetFilter("Bill-to Customer No.", BilltoCustomerNo);  // Do not include lines having only Description.
        ServiceLine.FindFirst();
    end;

    local procedure GetServiceInvoiceNo(ServiceHeaderNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeaderNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure GetServiceInvoiceNoForOrder(ServiceHeaderNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeaderNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure GetServiceCreditMemoNo(ServiceHeaderNo: Code[20]): Code[20]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceHeaderNo);
        ServiceCrMemoHeader.FindFirst();
        exit(ServiceCrMemoHeader."No.");
    end;

    local procedure GetServiceShipmentNo(ServiceHeaderNo: Code[20]): Code[20]
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeaderNo);
        ServiceShipmentHeader.FindFirst();
        exit(ServiceShipmentHeader."No.");
    end;

    local procedure OpenServiceLinesPage(No: Code[20])
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Close();
        Commit();
    end;

    local procedure OpenServiceInvoicePage(No: Code[20])
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", No);
        ServiceInvoice.ServLines.GetShipmentLines.Invoke();
        ServiceInvoice.OK().Invoke();
    end;

    local procedure OpenServiceCreditMemoPage(No: Code[20])
    var
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("No.", No);
        ServiceCreditMemo.ServLines.ItemTrackingLines.Invoke();
        ServiceCreditMemo.OK().Invoke();
    end;

    local procedure OpenReservationPage(ServiceItemNo: Code[20])
    var
        ServiceLines: TestPage "Service Lines";
    begin
        ServiceLines.OpenView();
        ServiceLines.FILTER.SetFilter("Service Item No.", ServiceItemNo);
        ServiceLines.Reserve.Invoke();
    end;

    local procedure PostAndVerifyServiceOrderError(ServiceLine: Record "Service Line")
    var
        ServiceHeader: Record "Service Header";
    begin
        // Exercise: Try to post the Service Order as Ship.
        Commit();  // Commit is required to match error message.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Verify: Check that the application generates an error on Posting as Reserved Item not on Inventory.
        Assert.ExpectedError(StrSubstNo(ItemNotOnInventoryError, ServiceLine."No."));
    end;

    local procedure CreateCustomerWithReserveAlways(): Text
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Reserve := Customer.Reserve::Always;
        Customer.Modify();
        exit(Customer.Name);
    end;

    local procedure CreatePurchasingCodeWithDropShipment(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
    end;

    local procedure CreateSalesOrderLineByPage(var SalesOrder: TestPage "Sales Order"; CustomerName: Text; ItemNo: Code[20])
    begin
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(CustomerName);
        SalesOrder.SalesLines.Type.SetValue(SalesOrder.SalesLines.Type.GetOption(3));
        // Option 3 is used for "Item" type.
        SalesOrder.SalesLines."No.".SetValue(ItemNo);
    end;

    local procedure CreateFirmPlannedOrder(ItemNo: Code[20]; Quantity: Decimal): Code[10]
    var
        ProductionOrder: Record "Production Order";
        RefreshProductionOrder: Report "Refresh Production Order";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.SetRange(Status, ProductionOrder.Status);
        ProductionOrder.SetRange("No.", ProductionOrder."No.");
        RefreshProductionOrder.SetTableView(ProductionOrder);
        Commit();
        RefreshProductionOrder.UseRequestPage(false);
        RefreshProductionOrder.RunModal();
        exit(ProductionOrder."Location Code");
    end;

    local procedure CreateItemWithSerialAndLotNo(Reserve: Enum "Reserve Method"; LotNos: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", FindItemTrackingCode(false, true));
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Lot Nos.", LotNos);
        Item.Validate(Reserve, Reserve);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateReleaseFirmPlannedOrder(ItemNo: Code[20]; Quantity: Decimal) LocationCode: Code[10]
    var
        ProductionOrder: Record "Production Order";
    begin
        LocationCode := CreateFirmPlannedOrder(ItemNo, Quantity);
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ItemNo);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate(), false);

        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ItemNo);
        PostProductionJournal(ProductionOrder);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);
    end;

    local procedure CreateItemWithReserve(var Item: Record Item; Reserve: Enum "Reserve Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandInt(100));
        Item.Validate(Reserve, Reserve);
        Item.Modify(true);
    end;

    local procedure CreateJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase,
          ItemNo, Quantity);
        Commit();
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; LocationCode: Code[10]; ItemNo: Code[20]; DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        ServiceHeader.Validate("Location Code", LocationCode);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithItemAndQuantityUsingPage(var ServiceLines: TestPage "Service Lines")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLines.Type.SetValue(ServiceLine.Type::Item);
        ServiceLines."No.".SetValue(ItemNo);
        ServiceLines.Quantity.SetValue(QuantityOnServiceLine);
    end;

    local procedure CreateDocumentWithServiceItem(var ServiceLine: Record "Service Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        CreateServiceDocument(ServiceLine, LocationCode, ItemNo, DocumentType);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrder(ItemNo: Code[20]; Quantity: Decimal): Code[10]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseHeader, ItemNo, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        exit(PurchaseHeader."Location Code");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
    begin
        Location.SetRange("Use As In-Transit", false);
        Location.SetRange("Bin Mandatory", false);
        Location.FindFirst();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Validate("Expected Receipt Date", WorkDate());
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateAndReleasePurchaseOrder(ItemNo: Code[20]; Quantity: Decimal): Code[10]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseHeader, ItemNo, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        exit(PurchaseHeader."Location Code");
    end;

    local procedure CreateReleasePostPurchaseOrder(ItemNo: Code[20]; Quantity: Decimal): Code[10]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseHeader, ItemNo, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        exit(PurchaseHeader."Location Code");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        exit(LibraryInventory.CreateItem(Item));
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDecInRange(2, 10, 2));  // Taken Random value for Quantity.
        PurchaseLine.Validate("Expected Receipt Date", WorkDate());
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Used Random value for Direct Unit Cost.
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10])
    var
        TransferLine: Record "Transfer Line";
        Location: Record Location;
        Location2: Record Location;
    begin
        Location2.SetRange("Use As In-Transit", true);
        Location2.FindFirst();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, Location.Code, Location2.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, OriginalQuantity);
        TransferLine.Validate("Receipt Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));  // Used Random to calculate Receipt Date.
        TransferLine.Validate("Qty. to Ship", OriginalQuantity);
        TransferLine.Modify(true);
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; LocationCode: Code[10]; ServiceItemLineNo: Integer)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate(Reserve, ServiceLine.Reserve::Optional);
        ServiceLine.Validate(Quantity, OriginalQuantity - 1);  // Taken 1 because value is important.
        ServiceLine.Validate("Unit Price", 10);  // Used Random values for Unit Price.
        ServiceLine.Modify(true);
    end;

    local procedure UpdateServiceLineQuantity(var ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure OpenItemTrackingPageForJournal(JnlBatchName: Code[10])
    var
        ItemJournal: TestPage "Item Journal";
    begin
        // Open Item Tracking Lines Page from Item Journal.
        ItemJournal.OpenEdit();
        ItemJournal.CurrentJnlBatchName.SetValue(JnlBatchName);
        ItemJournal.ItemTrackingLines.Invoke();
    end;

    local procedure OpenServiceQuoteLinesPage(No: Code[20])
    var
        ServiceQuote: TestPage "Service Quote";
    begin
        ServiceQuote.OpenEdit();
        ServiceQuote.FILTER.SetFilter("No.", No);
        ServiceQuote.ServItemLine.ServiceLines.Invoke();
    end;

    local procedure OpenReserveFromPurchaseOrderPage(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchLines.Reserve.Invoke();
        Commit();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindServiceOrder(QuoteNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Reset();
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("Quote No.", QuoteNo);
        ServiceHeader.FindFirst();
        exit(ServiceHeader."No.");
    end;

    local procedure FindProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; ItemNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", ItemNo);
        ProductionOrder.FindFirst();
    end;

    local procedure PostProductionJournal(var ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProductionJournalMgt.InitSetupValues();
        ProductionJournalMgt.SetTemplateAndBatchName();
        ProductionJournalMgt.CreateJnlLines(ProductionOrder, ProdOrderLine."Line No.");
        ItemJournalLine.SetRange("Item No.", ProductionOrder."Source No.");
        ItemJournalLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post", ItemJournalLine);
    end;

    local procedure SetValuesOnServiceLine(var ServiceLines: TestPage "Service Lines")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLines.Type.SetValue(ServiceLine.Type::Item);
        ServiceLines."No.".SetValue(ItemNo);
        ServiceLines."Location Code".SetValue('');
        ServiceLines.Quantity.SetValue(QuantityOnServiceLine);
        Commit();
    end;

    local procedure VerifyReservationEntry(ServiceLine: Record "Service Line"; Quantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", DATABASE::"Service Line");
        ReservationEntry.SetRange("Source Subtype", ServiceLine."Document Type");
        ReservationEntry.SetRange("Source ID", ServiceLine."Document No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Item No.", ServiceLine."No.");
        ReservationEntry.TestField("Location Code", ServiceLine."Location Code");
        ReservationEntry.TestField("Quantity (Base)", -Quantity);
    end;

    local procedure VerifyValueEntry(ServiceLine: Record "Service Line")
    var
        ValueEntry: Record "Value Entry";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", ServiceLine."Document No.");
        ServiceShipmentHeader.FindFirst();
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Service Shipment");
        ValueEntry.SetRange("Document No.", ServiceShipmentHeader."No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Item No.", ServiceLine."No.");
        ValueEntry.TestField("Posting Date", ServiceLine."Posting Date");
        ValueEntry.TestField("Source No.", ServiceLine."Customer No.");
        ValueEntry.TestField("Location Code", ServiceLine."Location Code");
    end;

    local procedure VerifyServiceLedgerEntry(ServiceLine: Record "Service Line"; DocumentType: Enum "Service Ledger Entry Document Type"; DocumentNo: Code[20]; Quantity: Decimal)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Document Type", DocumentType);
        ServiceLedgerEntry.SetRange("Document No.", DocumentNo);
        ServiceLedgerEntry.SetRange("Document Line No.", ServiceLine."Line No.");
        ServiceLedgerEntry.FindFirst();
        ServiceLedgerEntry.TestField("No.", ServiceLine."No.");
        ServiceLedgerEntry.TestField("Posting Date", ServiceLine."Posting Date");
        ServiceLedgerEntry.TestField("Bill-to Customer No.", ServiceLine."Bill-to Customer No.");
        ServiceLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemLedgerEntry(ServiceLine: Record "Service Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Service);
        ItemLedgerEntry.SetRange("Order No.", ServiceLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", ServiceLine."Line No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, -ServiceLine."Qty. to Ship");
    end;

    local procedure VerifyServiceInvoiceLine(DocumentNo: Code[20]; LineNo: Integer; Quantity: Decimal)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Document No.", DocumentNo);
        ServiceInvoiceLine.SetRange("Line No.", LineNo);
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyShipmentLineAfterConsume(DocumentNo: Code[20]; LineNo: Integer; Quantity: Decimal)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", DocumentNo);
        ServiceShipmentLine.SetRange("Line No.", LineNo);
        ServiceShipmentLine.FindFirst();
        ServiceShipmentLine.TestField(Quantity, Quantity);
        ServiceShipmentLine.TestField("Quantity Consumed", Quantity);
    end;

    local procedure VerifyShipmentLineAfterShip(DocumentNo: Code[20]; LineNo: Integer; Quantity: Decimal)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", DocumentNo);
        ServiceShipmentLine.SetRange("Line No.", LineNo);
        ServiceShipmentLine.FindFirst();
        ServiceShipmentLine.TestField(Quantity, Quantity);
        ServiceShipmentLine.TestField("Qty. Shipped Not Invoiced", Quantity);
    end;

    local procedure VerifyItemLedgerEntryCount(DocumentNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(Quantity, ItemLedgerEntry.Count, StrSubstNo(NoOfEntriesError, ItemLedgerEntry.TableCaption()));
    end;

    local procedure VerifyValueEntryCount(ServiceLine: Record "Service Line"; DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(ServiceLine.Quantity, ValueEntry.Count, StrSubstNo(NoOfEntriesError, ValueEntry.TableCaption()));
        ValueEntry.FindFirst();
        ValueEntry.TestField("Item No.", ServiceLine."No.");
        ValueEntry.TestField("Posting Date", ServiceLine."Posting Date");
        ValueEntry.TestField("Source No.", ServiceLine."Customer No.");
    end;

    local procedure VerifyServiceCreditMemoLine(DocumentNo: Code[20]; LineNo: Integer; ItemNumber: Code[20]; Quantity: Decimal)
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoLine.SetRange("Document No.", DocumentNo);
        ServiceCrMemoLine.SetRange("Line No.", LineNo);
        ServiceCrMemoLine.FindFirst();
        ServiceCrMemoLine.TestField("No.", ItemNumber);
        ServiceCrMemoLine.TestField(Quantity, Quantity);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AutoReservePageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
        Reservation."Total Quantity".AssertEquals(OriginalQuantity);
        Reservation.QtyToReserveBase.AssertEquals(QuantityOnServiceLine);
        Reservation.QtyReservedBase.AssertEquals(QuantityOnServiceLine);
        Reservation."Current Reserved Quantity".AssertEquals(QuantityOnServiceLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableItemLedgEntriesPageHandler(var AvailableItemLedgEntries: TestPage "Available - Item Ledg. Entries")
    begin
        // Invoke Reserve Action from Available Item Ledger Entries Page.
        AvailableItemLedgEntries.Reserve.Invoke();

        // Verify: Verify Reserved Quantity.
        AvailableItemLedgEntries."Reserved Quantity".AssertEquals(QuantityOnServiceLine);
        Commit();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableToReserveReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.AvailableToReserve.Invoke();
        Reservation.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateLotFromQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateNewLotNo.SetValue(true);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoQuantityOnReservePageHandler(var Reservation: TestPage Reservation)
    begin
        // Verify that no Qunatity available when there is no source available to Reserve from.
        Reservation."Total Quantity".AssertEquals(0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationEntriesPageHandler(var ReservationEntries: TestPage "Reservation Entries")
    begin
        ReservationEntries."Item No.".AssertEquals(ItemNo);
        ReservationEntries."Quantity (Base)".AssertEquals(-QuantityOnServiceLine);
        ReservationEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationModalFormHandler(var Reservation: Page Reservation; var Reply: Action)
    begin
        Reservation.AutoReserve();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationLinePageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        SetValuesOnServiceLine(ServiceLines);
        ServiceLines.ReservationEntries.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.ItemNo.AssertEquals(ItemNo);
        Reservation.QtyToReserveBase.AssertEquals(QuantityOnServiceLine);
        Reservation.QtyReservedBase.AssertEquals(QuantityReserved);
        Reservation."Total Quantity".AssertEquals(OriginalQuantity);
        Reservation."Current Reserved Quantity".AssertEquals(QuantityReserved);
        Reservation.TotalAvailableQuantity.AssertEquals(OriginalQuantity - QuantityReserved);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveLinePageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        SetValuesOnServiceLine(ServiceLines);
        ServiceLines.Reserve.Invoke();
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesPageHandler(var ServiceLines: TestPage "Service Lines")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLines.FILTER.SetFilter(Type, Format(ServiceLine.Type::Item));
        ServiceLines.FILTER.SetFilter("No.", ItemNo);
        ServiceLines.Reserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingActionsPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case ItemTrackingAction of
            ItemTrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingAction::Verification:
                ItemTrackingLines.Quantity_ItemTracking.AssertEquals(QuantityOnServiceLine);
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingListHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveFromAvailableItemLedgEntriesPageHandler(var AvailableItemLedgEntries: TestPage "Available - Item Ledg. Entries")
    begin
        // Invoke Reserve Action from Available Item Ledger Entries Page.
        AvailableItemLedgEntries.Reserve.Invoke();
        Commit();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveFromCurrentLineHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.ItemNo.AssertEquals(ItemNo);
        Reservation.QtyToReserveBase.AssertEquals(QuantityOnServiceLine);
        Reservation.QtyReservedBase.AssertEquals(QuantityOnServiceLine);
        Reservation."Total Quantity".AssertEquals(QuantityOnServiceLine);
        Reservation."Current Reserved Quantity".AssertEquals(QuantityOnServiceLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveFromServiceLinePageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        CreateServiceLineWithItemAndQuantityUsingPage(ServiceLines);
        Commit();
        ServiceLines.Reserve.Invoke();
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OpenReservationFromServiceLinesPageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        CreateServiceLineWithItemAndQuantityUsingPage(ServiceLines);
        Commit();
        ServiceLines.ReservationEntries.Invoke();
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetValuesOnServiceLinePageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        CreateServiceLineWithItemAndQuantityUsingPage(ServiceLines);
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLineActionsPageHandler(var ServiceLines: TestPage "Service Lines")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLines.FILTER.SetFilter(Type, Format(ServiceLine.Type::Item));
        ServiceLines.FILTER.SetFilter("No.", ItemNo);
        case ServiceLineAction of
            ServiceLineAction::ItemTracking:
                ServiceLines.ItemTrackingLines.Invoke();
            ServiceLineAction::Reserve:
                ServiceLines.Reserve.Invoke();
        end;
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteLinePageHandler(var ServiceQuoteLines: TestPage "Service Quote Lines")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceQuoteLines.FILTER.SetFilter(Type, Format(ServiceLine.Type::Item));
        ServiceQuoteLines.FILTER.SetFilter("No.", ItemNo);
        ServiceQuoteLines.ItemTrackingLines.Invoke();
        ServiceQuoteLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinePageLocationHandler(var ServiceLines: TestPage "Service Lines")
    begin
        SetValuesOnServiceLine(ServiceLines);
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinePageTypeHandler(var ServiceLines: TestPage "Service Lines")
    begin
        SetValuesOnServiceLine(ServiceLines);
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinePageSetValueHandler(var ServiceLines: TestPage "Service Lines")
    begin
        SetValuesOnServiceLine(ServiceLines);
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLineTrackingPageHandler(var ServiceLines: TestPage "Service Lines")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLines.FILTER.SetFilter(Type, Format(ServiceLine.Type::Item));
        ServiceLines.FILTER.SetFilter("No.", ItemNo);
        ServiceLines.ItemTrackingLines.Invoke();
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetServiceShipmentLinesHandler(var GetServiceShipmentLines: TestPage "Get Service Shipment Lines")
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        GetServiceShipmentLines.FILTER.SetFilter(Type, Format(ServiceShipmentLine.Type::Item));
        GetServiceShipmentLines.FILTER.SetFilter("No.", ItemNo);
        GetServiceShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveServiceLinesHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.ItemNo.AssertEquals(ItemNo);
        Reservation.QtyToReserveBase.AssertEquals(QuantityOnServiceLine);
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var Reservation: TestPage Reservation)
    begin
        if ReserveFromCurrentLine then  // ReserveFromCurrentLine used as global variable.
            Reservation."Reserve from Current Line".Invoke()
        else
            Reservation.QtyToReserveBase.AssertEquals(0);  // After posting of Service Order Quantity to Reserve becomes 0.
        Reservation.OK().Invoke();
    end;
}

