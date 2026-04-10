// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Setup;
using System.TestLibraries.Utilities;

codeunit 136143 "Service Reservation II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reservation] [Service]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        ExpectedDateError: Label 'The change leads to a date conflict with existing reservations.';
        ErrorMustBeSame: Label 'Error must be same.';
        FieldChangedError: Label '%1 must not be changed when a quantity is reserved in %2 %3=''%4'',%5=''%6'',%7=''%8''.', Comment = ' Field Caption,Table Caption, Document Type  Field Caption,Document Type Field Value,Document No. Field Caption,Document No. Field Value,Line No. Field Caption,Line No. Field Value';
        ReserveFromCurrentLine: Boolean;
        QuantityOnServiceLine: Decimal;
        ItemTrackingOption: Option AssignSerialNo,SelectEntries;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ReservationBetweenPurchaseAndServiceOrder()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify that the Quantity for an existing reservation between Purchase Order and Service Order can be modified and make a new reservation.

        // 1. Setup: Create Purchase Order and Service Order. Reserve the Item partially from Service Line.
        Initialize();
        CreatePurchaseOrderAndServiceOrder(ServiceLine);
        ServiceLine.Validate("Needed by Date", LibraryRandom.RandDate(5));  // Update Needed by Date later than WORKDATE. Use Random to calculate Date.
        UpdateServiceLineQuantity(ServiceLine, ServiceLine.Quantity / 2);  // Update Quantity by half.
        QuantityOnServiceLine := ServiceLine.Quantity;  // Assign in global variable.
        ServiceLine.ShowReservation();

        // 2. Exercise: Update Quantity on Service Line and Reserve again.
        ServiceLine.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.");
        UpdateServiceLineQuantity(ServiceLine, ServiceLine.Quantity + LibraryRandom.RandInt(10));  // Take Random to update the Quantity.
        QuantityOnServiceLine := ServiceLine.Quantity;  // Assign in global variable.
        ServiceLine.ShowReservation();

        // 3. Verify: Verify Service Line for updated Reserved Quantity.
        VerifyServiceLine(ServiceLine, QuantityOnServiceLine);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationFromServiceOrderWithPartialQuantity()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify Reservation Line and Service Line after Reservation with Inventory as supply and Service Order as demand with partial quantity.

        // 1. Setup: Create Item, create and post Item Journal Line for Inventory and create Service Order.
        Initialize();
        SetupReservationFromServOrderScenario(ServiceLine);

        // 2. Exercise: Reserve the Item from Service Line.
        ServiceLine.ShowReservation();

        // 3. Verify: Verify Reservation Line. Verification done in 'ReservationPageHandler' and Verify Service Line for Reserved Quantity.
        VerifyServiceLine(ServiceLine, QuantityOnServiceLine);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CancelReservationFromServiceOrderWithPartialQuantity()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify Reservation Line and Service Line after cancelled the Reservation when Inventory as supply and Service Order as demand with partial quantity.

        // 1. Setup: Create Item, create and post Item Journal Line for Inventory and create Service Order. Reserve the Item from Service Line
        Initialize();
        SetupReservationFromServOrderScenario(ServiceLine);
        ServiceLine.ShowReservation();
        ReserveFromCurrentLine := false;  // Assign in global variable.
        LibraryVariableStorage.Enqueue(ServiceLine."No.");
        LibraryVariableStorage.Enqueue(QuantityOnServiceLine);

        // 2. Exercise: Cancel the reservation from Service Line.
        ServiceLine.ShowReservation();

        // 3. Verify: Verify Reservation Line. Verification done in 'ReserveFromCurrentLineHandler' and Verify Service Line for Reserved Quantity.
        VerifyServiceLine(ServiceLine, 0);  // After cancelled the Reservation, Reserved Quantity must be zero.
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeItemNoOnSupplyAfterReservation()
    var
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify error message when change Item No. on Sales Line which is reserved against Service Order.

        // 1. Setup: Create Sales Return Order and Service Order. Reserve Service Order against Sales return Order.
        Initialize();
        CreateSalesReturnOrder(SalesLine);
        CreateDocumentWithServiceItem(
          ServiceLine, SalesLine."Sell-to Customer No.", SalesLine."No.", SalesLine."Location Code", SalesLine."Variant Code",
          SalesLine.Quantity - 1, ServiceLine."Document Type"::Order);
        ServiceLine.ShowReservation();

        // 2. Exercise: Change Item No. on Sales Line.
        asserterror SalesLine.Validate("No.", LibraryInventory.CreateItemNo());

        // 3. Verify: Verify error message.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Reserved Qty. (Base)"), Format(0));
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeVariantCodeOnSupplyAfterReservation()
    var
        ItemVariant: Record "Item Variant";
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify error message when change Variant Code on Sales Line which is reserved against Service Order.

        // 1. Setup: Create Sales Return Order and Service Order. Reserve Service Order against Sales return Order.
        Initialize();
        CreateSalesReturnOrder(SalesLine);
        CreateDocumentWithServiceItem(
          ServiceLine, SalesLine."Sell-to Customer No.", SalesLine."No.", SalesLine."Location Code", SalesLine."Variant Code",
          SalesLine.Quantity - 1, ServiceLine."Document Type"::Order);
        ServiceLine.ShowReservation();

        // 2. Exercise: Change Variant Code on Sales Line.
        asserterror SalesLine.Validate("Variant Code", LibraryInventory.CreateItemVariant(ItemVariant, SalesLine."No."));

        // 3. Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(
            FieldChangedError, SalesLine.FieldCaption("Variant Code"), SalesLine.TableCaption(), SalesLine.FieldCaption("Document Type"),
            SalesLine."Document Type", SalesLine.FieldCaption("Document No."), SalesLine."Document No.",
            SalesLine.FieldCaption("Line No."), SalesLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeLocationCodeOnSupplyAfterReservation()
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify error message when change Location Code on Sales Line which is reserved against Service Order.

        // 1. Setup: Create Sales Return Order and Service Order. Reserve Service Order against Sales return Order.
        Initialize();
        CreateSalesReturnOrder(SalesLine);
        CreateDocumentWithServiceItem(
          ServiceLine, SalesLine."Sell-to Customer No.", SalesLine."No.", SalesLine."Location Code", SalesLine."Variant Code",
          SalesLine.Quantity - 1, ServiceLine."Document Type"::Order);
        ServiceLine.ShowReservation();

        // 2. Exercise: Change Location Code on Sales Line.
        asserterror SalesLine.Validate("Location Code", LibraryWarehouse.CreateLocation(Location));

        // 3. Verify: Verify error message.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Reserved Qty. (Base)"), Format(0));
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeItemNoOnDemandAfterReservation()
    var
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify error message when change Item No. on Service Line which is reserved against Sales Return Order.

        // 1. Setup: Create Sales Return Order and Service Order. Reserve Service Order against Sales return Order.
        Initialize();
        CreateSalesReturnOrder(SalesLine);
        CreateDocumentWithServiceItem(
          ServiceLine, SalesLine."Sell-to Customer No.", SalesLine."No.", SalesLine."Location Code", SalesLine."Variant Code",
          SalesLine.Quantity - 1, ServiceLine."Document Type"::Order);
        ServiceLine.ShowReservation();

        // 2. Exercise: Change Item No. on Service Line.
        asserterror ServiceLine.Validate("No.", LibraryInventory.CreateItemNo());

        // 3. Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(
            FieldChangedError, ServiceLine.FieldCaption("No."), ServiceLine.TableCaption(), ServiceLine.FieldCaption("Document Type"),
            ServiceLine."Document Type", ServiceLine.FieldCaption("Document No."), ServiceLine."Document No.",
            ServiceLine.FieldCaption("Line No."), ServiceLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeVariantCodeOnDemandAfterReservation()
    var
        ItemVariant: Record "Item Variant";
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify error message when change Variant Code on Service Line which is reserved against Sales Return Order.

        // 1. Setup: Create Sales Return Order and Service Order. Reserve Service Order against Sales return Order.
        Initialize();
        CreateSalesReturnOrder(SalesLine);
        CreateDocumentWithServiceItem(
          ServiceLine, SalesLine."Sell-to Customer No.", SalesLine."No.", SalesLine."Location Code", SalesLine."Variant Code",
          SalesLine.Quantity - 1, ServiceLine."Document Type"::Order);
        ServiceLine.ShowReservation();

        // 2. Exercise: Change Variant Code on Service Line.
        asserterror ServiceLine.Validate("Variant Code", LibraryInventory.CreateItemVariant(ItemVariant, SalesLine."No."));

        // 3. Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(
            FieldChangedError, ServiceLine.FieldCaption("Variant Code"), ServiceLine.TableCaption(),
            ServiceLine.FieldCaption("Document Type"), ServiceLine."Document Type", ServiceLine.FieldCaption("Document No."),
            ServiceLine."Document No.",
            ServiceLine.FieldCaption("Line No."), ServiceLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeLocationCodeOnDemandAfterReservation()
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify error message when change Location Code on Service Line which is reserved against Sales Return Order.

        // 1. Setup: Create Sales Return Order and Service Order. Reserve Service Order against Sales return Order.
        Initialize();
        CreateSalesReturnOrder(SalesLine);
        CreateDocumentWithServiceItem(
          ServiceLine, SalesLine."Sell-to Customer No.", SalesLine."No.", SalesLine."Location Code", SalesLine."Variant Code",
          SalesLine.Quantity - 1, ServiceLine."Document Type"::Order);
        ServiceLine.ShowReservation();

        // 2. Exercise: Change Location Code on Service Line.
        asserterror ServiceLine.Validate("Location Code", LibraryWarehouse.CreateLocation(Location));

        // 3. Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(
            FieldChangedError, ServiceLine.FieldCaption("Location Code"), ServiceLine.TableCaption(),
            ServiceLine.FieldCaption("Document Type"), ServiceLine."Document Type", ServiceLine.FieldCaption("Document No."),
            ServiceLine."Document No.",
            ServiceLine.FieldCaption("Line No."), ServiceLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeNeededByDateOnDemandAfterReservation()
    var
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify error message when change Needed by Date on Service Line which is reserved against Sales Return Order.

        // 1. Setup: Create Sales Return Order and Service Order. Reserve Service Order against Sales return Order.
        Initialize();
        CreateSalesReturnOrder(SalesLine);
        CreateDocumentWithServiceItem(
          ServiceLine, SalesLine."Sell-to Customer No.", SalesLine."No.", SalesLine."Location Code", SalesLine."Variant Code",
          SalesLine.Quantity - 1, ServiceLine."Document Type"::Order);
        ServiceLine.ShowReservation();

        // 2. Exercise: Change Needed by Date on Service Line with Random years.
        asserterror ServiceLine.Validate("Needed by Date", LibraryRandom.RandDateFrom(SalesLine."Shipment Date", -10));

        // Because Actual Error too long, not possible to verify complete error using Assert.ExepctedError.
        // 3. Verify: Verify error message.
        Assert.IsTrue(StrPos(GetLastErrorText, ExpectedDateError) > 0, ErrorMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeReserveOptionOnDemandAfterReservation()
    var
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify error message when change Reserve option on Service Line which is reserved against Sales Return Order.

        // 1. Setup: Create Sales Return Order and Service Order. Reserve Service Order against Sales return Order.
        Initialize();
        CreateSalesReturnOrder(SalesLine);
        CreateDocumentWithServiceItem(
          ServiceLine, SalesLine."Sell-to Customer No.", SalesLine."No.", SalesLine."Location Code", SalesLine."Variant Code",
          SalesLine.Quantity - 1, ServiceLine."Document Type"::Order);
        ServiceLine.ShowReservation();

        // 2. Exercise: Change Reserve option on Service Line.
        asserterror ServiceLine.Validate(Reserve, ServiceLine.Reserve::Never);

        // 3. Verify: Verify error message.
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Reserved Qty. (Base)"), Format(0));
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ModifyFactorsFromServiceOrderToProductionOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ServiceLine: Record "Service Line";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
    begin
        // Verify Reserved Quantity Service Line after modifying the various field on Supply and Demand after Reservation.

        // 1. Setup: Create Release Production Order and Service Order and Reserve Quantity from Production Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item,
          CreateItemWithReserveOption(Item.Reserve::Optional), LibraryRandom.RandDec(10, 2));  // Take Random for Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        CreateDocumentWithServiceItem(
          ServiceLine, Customer."No.", ProductionOrder."Source No.", '', '', ProductionOrder.Quantity, ServiceLine."Document Type"::Order);
        ServiceLine.ShowReservation();
        UpdateProdOrderLine(ProductionOrder.Status, ProductionOrder."No.", ServiceLine."Needed by Date");

        // 2. Exercise.
        ServiceLine.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.");
        UpdateServiceLineQuantity(ServiceLine, ServiceLine.Quantity - LibraryUtility.GenerateRandomFraction());  // Using Random to modify Quantity.

        // 3. Verify: Verify Service Line for updated Reserved Quantity.
        VerifyServiceLine(ServiceLine, 0);  // Reserved Quantity must be zero.
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryWhenReserveIsOptional()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify the Reservation entry created by a Purchase Order and Service Order while Reserve type is Optional.

        // 1. Setup: Create Purchase Order and Service Order.
        Initialize();
        CreatePurchaseOrderAndServiceOrder(ServiceLine);
        ServiceLine.Validate("Needed by Date", LibraryRandom.RandDate(10));  // Update Needed by Date later than WORKDATE. Use Random to calculate Date.
        ServiceLine.Validate(Reserve, ServiceLine.Reserve::Optional);
        ServiceLine.Modify(true);

        // 2. Exercise: Reserve Quantity on Service Line.
        ServiceLine.ShowReservation();

        // 3. Verify: Verify Reservation Entry.
        VerifyReservationEntry(ServiceLine, -ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ShipmentLinePageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceWithItemReserveAlways()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        ItemNo: Code[20];
    begin
        // Verify Service Invoice has been posted using Get Shipment Line with Item Reserve Always without any error message .

        // Setup: Create Item, create and post Purchase Order and Service Order, create Service Invoice using Get shipment Lines.
        Initialize();
        ItemNo := CreateItemWithReserveOption(Item.Reserve::Always);  // Assign in global variable.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateServiceOrder(ServiceLine, ItemNo, PurchaseLine.Quantity, ServiceLine."Document Type"::Order);
        PostServiceOrder(ServiceLine, false, false);
        LibraryVariableStorage.Enqueue(ServiceLine."Document No.");  // Enqueue value for 'ShipmentLinePageHandler'.
        CreateServiceInvoiceFromGetShipmentLines(ServiceLine, ServiceLine."Customer No.");

        // Exercise: Post Service Invoice.
        PostServiceOrder(ServiceLine, false, true);

        // Verify: Verify Quantity and Item No on Posted Service Invoice.
        VerifyPostedServiceInvoice(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure DateConflictRaisedWhenPlanningDeliveryDateInServOrderReservedFromPurchOrderIsChanged()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Date conflict]
        // [SCENARIO 381251] The date conflict is raised when "Planning Delivery Date" in Service Order reserved from Purchase Order is changed

        Initialize();

        // [GIVEN] Purchase Order with "Expected Receipt Date" = 10.01
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LibraryInventory.CreateItemNo());

        // [GIVEN] Service Order with "Needed By Date" and "Planning Delivery Date" equal 10.01 and reserved from Purchase Order
        CreateServiceOrder(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity, ServiceLine."Document Type"::Order);
        ServiceLine.Validate("Needed by Date", PurchaseLine."Expected Receipt Date");
        ServiceLine.Modify(true);
        QuantityOnServiceLine := ServiceLine.Quantity;
        ServiceLine.ShowReservation();

        // [WHEN] Change "Planning Delivery Date" of Service Order to 01.01
        ServiceLine.Find();
        asserterror ServiceLine.Validate("Planned Delivery Date", LibraryRandom.RandDate(-5));

        // [THEN] Error message "The change leads to a date conflict with existing reservations" is raised
        Assert.ExpectedError(ExpectedDateError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler,ItemTrackingSummaryModalPageHandler,ServiceLinesModalPageHandler,ServiceItemReplacementModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemReplacementForItemWithReserveAlwaysAndItemTracking()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceItemGroup: Record "Service Item Group";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        ServiceOrder: TestPage "Service Order";
        LastSerialNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Service Line] [Service Item Replacement]
        // [SCENARIO 318234] Automatic reservation of serial no.-tracked item on service line.
        Initialize();

        // [GIVEN] Service item group with "Create Service Item" setting = TRUE.
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroup.Validate("Create Service Item", true);
        ServiceItemGroup.Modify(true);

        // [GIVEN] Serial-no. tracked item. Select the new service item group.
        LibraryItemTracking.CreateSerialItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Validate("Service Item Group", ServiceItemGroup.Code);
        Item.Modify(true);

        // [GIVEN] Post 5 pcs to the inventory. Serial nos. = "S1","S2","S3","S4","S5".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(3, 6));
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignSerialNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();
        LastSerialNo := ItemLedgerEntry."Serial No.";

        // [GIVEN] Create sales order for 1 pc. Assign serial no. "S1" and post the order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 1, '', WorkDate());
        LibraryVariableStorage.Enqueue(ItemTrackingOption::SelectEntries);
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] A new service item with serial no. "S1" is automatically created.
        ServiceItem.SetRange("Item No.", Item."No.");
        ServiceItem.FindFirst();

        // [GIVEN] Create service order, select the new service item.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [WHEN] Open service lines page, set item no. equal to the service item and select new serial no. "S5" on the Service Item Replacement page.
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoKey(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(LastSerialNo);
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        // [THEN] Serial no. "S5" is reserved from the inventory for the service line.
        ServiceLine.SetRange("No.", Item."No.");
        ServiceLine.FindFirst();
        ReservationEntry.SetSourceFilter(
          DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", true);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Serial No.", LastSerialNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderWithVendorNoModalPageHandler,ItemTrackingPageHandler,StrMenuHandler,MessageHandler')]
    procedure CheckSerialNumberInServiceItemWhenPostingShipment()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceItemGroup: Record "Service Item Group";
        Vendor: Record Vendor;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
        WarehouseShipment: TestPage "Warehouse Shipment";
    begin
        // [SCENARIO 592530] Check that Serial numbers are not missing on automatically created Service Items when posting partial shipment with Item Tracking set for 
        // Serial Specific Tracking on a Warehouse Shipment.
        Initialize();

        // [GIVEN] create service item group with "Create Service Item" setting = TRUE.
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroup.Validate("Create Service Item", true);
        ServiceItemGroup.Modify(true);

        // [GIVEN] create serial-no. tracked item with "Service Item Group" = Service Item Group created above.
        LibraryItemTracking.CreateSerialItem(Item);
        Item.Validate("Service Item Group", ServiceItemGroup.Code);
        Item.Validate("Serial Nos.", '');
        Item.Modify(true);

        // [GIVEN] create item tracking code with "Create SN Info on Posting" = TRUE and "Use Expiration Dates" = TRUE.
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("Create SN Info on Posting", true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create Location with "Require Receive" = TRUE, "Require Shipment" = TRUE and "Require Pick" = FALSE.
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Validate(Location."Require Pick", false);
        Location.Modify(true);

        // [GIVEN] Create warehouse employee with "Location Code" = Location created above.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create vendor.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."No.");

        // [GIVEN] Create sales order for 5 pcs. of the item, reserve from the inventory.
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
            Item."No.", 5, Location.Code, WorkDate());

        // [GIVEN] Create purchase order from sales order with vendor created above.
        PurchaseOrder.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder.CreatePurchaseOrder.Invoke();
        LibraryVariableStorage.Enqueue(10);
        SalesOrder.Close();
        PurchaseOrder.Close();

        // [GIVEN] modify purchase order and create item tracking lines with serial no. "SN001" to "SN010".
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(0);
        PurchaseOrder.PurchLines."Qty. to Invoice".SetValue(0);
        PurchaseOrder.PurchLines."Item Tracking Lines".Invoke();
        PurchaseOrder.Close();
        PurchaseOrder.Trap();
        Commit();

        // [GIVEN] release purchase order and create warehouse receipt.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] find warehouse receipt header by source document and post warehouse receipt.
        WarehouseReceiptHeader.Get(LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        CreateInventoryPostingSetup(Location, Item);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [WHEN] Auto Reserve sales line and create warehouse shipment.
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."Location Code");

        // [WHEN] open warehouse shipment, set "Qty. to Ship" = 3 and open item tracking lines.
        WarehouseShipment.OpenEdit();
        WarehouseShipment.Filter.SetFilter("No.", WarehouseShipmentHeader."No.");
        WarehouseShipment.WhseShptLines."Qty. to Ship".SetValue(3);
        LibraryVariableStorage.Enqueue(3);
        WarehouseShipment.WhseShptLines.ItemTrackingLines.Invoke();

        // [WHEN] post shipment.
        WarehouseShipment."P&ost Shipment".Invoke();
        WarehouseShipment.Close();

        // [THEN] verify that service item must have Serial No.
        AssertServiceItemCountForBlankSerialNo(Item, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Reservation II");
        LibraryVariableStorage.Clear();
        Clear(LibraryService);
        // Lazy Setup.
        QuantityOnServiceLine := 0;
        ReserveFromCurrentLine := false;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Reservation II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryService.SetupServiceMgtNoSeries();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Reservation II");
    end;

    local procedure SetupReservationFromServOrderScenario(var ServiceLine: Record "Service Line")
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        ItemNo := CreateItemWithReserveOption(Item.Reserve::Optional);  // Assign in global variable.
        Quantity := LibraryRandom.RandDec(10, 2);  // Assign Random Quantity in global variable.
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(Quantity);
        CreateJournalLine(ItemJournalLine, ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateServiceOrder(ServiceLine, ItemNo, Quantity / 2, ServiceLine."Document Type"::Order);
        QuantityOnServiceLine := ServiceLine.Quantity;  // Assign in global variable.
        ReserveFromCurrentLine := true;  // Assign in global variable.
    end;

    local procedure CreateDocumentWithServiceItem(var ServiceLine: Record "Service Line"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Quantity: Decimal; DocumentType: Enum "Service Document Type")
    begin
        CreateServiceDocument(ServiceLine, CustomerNo, ItemNo, DocumentType);
        ServiceLine.Validate("Variant Code", VariantCode);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Needed by Date", LibraryRandom.RandDate(10));  // Update Needed by Date later than WORKDATE. Use Random to calculate Date.
        ServiceLine.Modify(true);
    end;

    local procedure CreateItemWithReserveOption(Reserve: Enum "Reserve Method"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Reserve);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryUtility.GenerateGUID();  // To heal the 'Item Journal Batch already existing' issue.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          Quantity);
    end;

    local procedure CreatePurchaseOrderAndServiceOrder(var ServiceLine: Record "Service Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LibraryInventory.CreateItemNo());
        CreateServiceOrder(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity, ServiceLine."Document Type"::Order);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo,
          LibraryRandom.RandDecInRange(50, 100, 2));
    end;

    local procedure CreateSalesReturnOrder(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", Customer."No.", LibraryWarehouse.CreateLocation(Location),
          CreateItemWithReserveOption(Item.Reserve::Optional));
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LocationCode: Code[10]; No: Code[20])
    var
        ItemVariant: Record "Item Variant";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandDec(100, 2) + LibraryUtility.GenerateRandomFraction());
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Variant Code", LibraryInventory.CreateItemVariant(ItemVariant, No));
        SalesLine.Validate("Shipment Date", LibraryRandom.RandDate(-10));  // Update Shipment Date earlier than WORKDATE. Use Random to calculate Date.
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; CustomerNo: Code[20]; ItemNo: Code[20]; DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceInvoiceFromGetShipmentLines(var ServiceLine: Record "Service Line"; CustomerNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Service-Get Shipment", ServiceLine);
    end;

    local procedure CreateServiceOrder(var ServiceLine: Record "Service Line"; ItemNo: Code[20]; Quantity: Decimal; DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateServiceDocument(ServiceLine, Customer."No.", ItemNo, DocumentType);
        UpdateServiceLineQuantity(ServiceLine, Quantity);
    end;

    local procedure PostServiceOrder(ServiceLine: Record "Service Line"; Consume: Boolean; Invoice: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, Consume, Invoice);
    end;

    local procedure UpdateProdOrderLine(Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; DueDate: Date)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, 0);  // Set quantity to zero as per test.
        ProdOrderLine.Validate("Due Date", DueDate);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateServiceLineQuantity(var ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure VerifyPostedServiceInvoice(ServiceLine: Record "Service Line")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetFilter("No.", '<>''''');
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField("No.", ServiceLine."No.");
        ServiceInvoiceLine.TestField(Quantity, ServiceLine.Quantity);
    end;

    local procedure VerifyReservationEntry(ServiceLine: Record "Service Line"; ExpectedQuantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", DATABASE::"Service Line");
        ReservationEntry.SetRange("Source Subtype", ServiceLine."Document Type");
        ReservationEntry.SetRange("Source ID", ServiceLine."Document No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Item No.", ServiceLine."No.");
        ReservationEntry.TestField("Location Code", ServiceLine."Location Code");
        ReservationEntry.TestField("Quantity (Base)", ExpectedQuantity);
    end;

    local procedure VerifyServiceLine(ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", Quantity);
    end;

    local procedure AssertServiceItemCountForBlankSerialNo(Item: Record Item; ExpectedCount: Integer)
    var
        ServiceItem: Record "Service Item";
    begin
        ServiceItem.SetRange("Item No.", Item."No.");
        ServiceItem.SetRange("Serial No.", '');
        Assert.RecordCount(ServiceItem, ExpectedCount);
    end;

    local procedure CreateInventoryPostingSetup(Location: Record Location; Item: Record Item)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if not InventoryPostingSetup.Get(Location.Code, Item."Inventory Posting Group") then begin
            LibraryInventory.CreateInventoryPostingSetup(
                InventoryPostingSetup,
                Location.Code,
                Item."Inventory Posting Group");
            InventoryPostingSetup.Validate("Inventory Account", LibraryERM.CreateGLAccountNo());
            InventoryPostingSetup.Modify(true);
        end else begin
            InventoryPostingSetup.Validate("Inventory Account", LibraryERM.CreateGLAccountNo());
            InventoryPostingSetup.Modify(true);
        end;
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
    end;

    local procedure FindPurchaseDocumentByItemNo(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveFromCurrentLineHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    var
        ExpectedQty: Decimal;
    begin
        if ReserveFromCurrentLine then
            Reservation."Reserve from Current Line".Invoke()
        else begin
            Reservation.CancelReservationCurrentLine.Invoke();
            Reservation.ItemNo.AssertEquals(LibraryVariableStorage.DequeueText());
            Reservation.QtyReservedBase.AssertEquals(0);
            Reservation."Current Reserved Quantity".AssertEquals(0);
            Reservation.OK().Invoke();
            exit;
        end;
        Reservation.ItemNo.AssertEquals(LibraryVariableStorage.DequeueText());
        Reservation.QtyToReserveBase.AssertEquals(QuantityOnServiceLine);
        Reservation.QtyReservedBase.AssertEquals(QuantityOnServiceLine);
        ExpectedQty := LibraryVariableStorage.DequeueDecimal();
        Reservation."Total Quantity".AssertEquals(ExpectedQty);
        Reservation."Current Reserved Quantity".AssertEquals(QuantityOnServiceLine);
        Reservation.TotalAvailableQuantity.AssertEquals(ExpectedQty - QuantityOnServiceLine);
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShipmentLinePageHandler(var GetServiceShipmentLines: Page "Get Service Shipment Lines"; var Response: Action)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        OrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(OrderNo);
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        ServiceShipmentLine.FindFirst();

        GetServiceShipmentLines.SetRecord(ServiceShipmentLine);
        GetServiceShipmentLines.GetShipmentLines();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemReplacementModalPageHandler(var ServiceItemReplacement: TestPage "Service Item Replacement")
    begin
        ServiceItemReplacement.NewSerialNo.SetValue(LibraryVariableStorage.DequeueText());
        ServiceItemReplacement.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesModalPageHandler(var ServiceLines: TestPage "Service Lines")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLines.Type.SetValue(ServiceLine.Type::Item);
        ServiceLines."No.".SetValue(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingOption::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingOption::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateModalPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        SNNo: Code[50];
        i: Integer;
        x: Integer;
    begin
        Commit();
        x := LibraryVariableStorage.DequeueInteger();
        if x = 3 then
            SNNo := 'SN006'
        else
            SNNo := 'SN000';
        for i := 1 to x do begin

            SNNo := IncStr(SNNo);
            ItemTrackingLines."Serial No.".SetValue(SNNo);
            ItemTrackingLines."Quantity (Base)".SetValue(1);
            ItemTrackingLines.Next();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PurchOrderFromSalesOrderWithVendorNoModalPageHandler(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        PurchOrderFromSalesOrder.Vendor.SetValue(LibraryVariableStorage.DequeueText());
        PurchOrderFromSalesOrder.Quantity.SetValue(10);
        PurchOrderFromSalesOrder.OK().Invoke();
    end;

    [StrMenuHandler]
    procedure StrMenuHandler(Options: Text; var Choice: Integer; Instructions: Text)
    begin
        Choice := 1;
    end;
}

