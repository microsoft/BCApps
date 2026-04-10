codeunit 137929 "SCM Orders UI"
{
    // Time-consuming test functions for small UI bugfixes.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        isInitialized: Boolean;
        ConfirmChangeMsg: Label 'Do you want to change';
        ResetItemChargeAssignMsg: Label 'The amount of the item charge assignment will be reset to 0.';
        WhseRequiredErr: Label 'Warehouse %1 is required for this line. The entered information may be disregarded by warehouse activities.';
        ItemTrackingMode: Option SetLotAndQty,OpenItemTrackingSummary,OpenItemTrackingSummaryTwice;
        CannotValidateSelectedQtyErr: Label 'You cannot select more than %1 units.';
        DialogCodeErr: Label 'Dialog';
        WrongSelectedQuantityMsg: Label 'Wrong Selected Quantity';

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LongCaptionTextOnReservationPage()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        LotNo: Text;
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,AssignGivenLotNo;
    begin
        // [FEATURE] [Reservation] [Item Tracking]
        // [SCENARIO 213778] When prod. order component line of firm planned order is reserved for specific lot tracking, the long caption on Reservation page should not cause an overflow error. It should be possible to carry out the reservation.
        Initialize();
        UpdateManufacturingSetup();

        // [GIVEN] Lot-tracked item "C".
        LibraryItemTracking.CreateLotItem(CompItem);

        // [GIVEN] Positive adjustment of "C" with lot no. "L" is posted. Length of assigned lot no. = maximum allowed value (20).
        LotNo := LibraryUtility.GenerateRandomText(MaxStrLen(ItemJournalLine."Lot No."));
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItem."No.", '', '', LibraryRandom.RandIntInRange(50, 100));
        LibraryVariableStorage.Enqueue(TrackingOption::AssignGivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        ItemJournalLine.OpenItemTrackingLines(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Production Item "P" with a component "C".
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);
        CreateManufacturingItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Firm Planned production order for "P".
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, ProdItem."No.",
          LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Lot "L" is assigned to the prod. order component (item "C").
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();
        LibraryVariableStorage.Enqueue(TrackingOption::AssignGivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ProdOrderComponent.Quantity);
        ProdOrderComponent.OpenItemTrackingLines();

        // [WHEN] Reserve the prod. order component.
        LibraryVariableStorage.Enqueue(true); // reserve specific lot nos.
        LibraryVariableStorage.Enqueue(false); // do not skip caption length verification on Reservation page
        ReserveProdOrderComponent(CompItem."No.");

        // [THEN] The caption of Reservation page is longer than 80 chars.
        // The verification is done in ReservationPageHandler.

        // [THEN] The prod. order component is reserved.
        ProdOrderComponent.CalcFields("Reserved Quantity");
        ProdOrderComponent.TestField("Reserved Quantity", ProdOrderComponent.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForMessageVerification')]
    [Scope('OnPrem')]
    procedure WarningOfResetItemChargeAssgntOnRecreateSalesLines()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Item Charge]
        // [SCENARIO 264120] A confirmation message that warns a user that sales line will be re-created, should inform them that amount of existing item charge assignment will be cleared.
        Initialize();
        ClearCustBusRelationCode();

        // [GIVEN] Sales order with two lines - for an item and an item charge, assigned to the item line.
        CreateSalesOrderWithItemAndItemChargeLines(SalesHeader, LibraryRandom.RandDec(10, 2));

        // [WHEN] Change "Sell-to Customer No." on the sales header.
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());

        // [THEN] The warning of re-creating lines includes a message about cleared charge assignment amount.
        Assert.ExpectedMessage(ConfirmChangeMsg, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(ConfirmChangeMsg, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(ResetItemChargeAssignMsg, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForMessageVerification')]
    [Scope('OnPrem')]
    procedure NoWarningOfResetItemChargeAssgntOnRecreateSalesLines()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Item Charge]
        // [SCENARIO 264120] A confirmation message that warns a user that sales line will be re-created, should not include information of cleared item charge assignments, if there isn't any.
        Initialize();
        ClearCustBusRelationCode();

        // [GIVEN] Sales order with two lines - for an item and an item charge, that is not assigned yet.
        CreateSalesOrderWithItemAndItemChargeLines(SalesHeader, 0);

        // [WHEN] Change "Sell-to Customer No." on the sales header.
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());

        // [THEN] The warning of re-creating lines does not mention charge assignment.
        Assert.ExpectedMessage(ConfirmChangeMsg, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(ConfirmChangeMsg, LibraryVariableStorage.DequeueText());
        Assert.IsFalse(StrPos(LibraryVariableStorage.DequeueText(), ResetItemChargeAssignMsg) > 0, 'Redundant warning is raised.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForMessageVerification')]
    [Scope('OnPrem')]
    procedure WarningOfResetItemChargeAssgntOnRecreatePurchLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Item Charge]
        // [SCENARIO 264120] A confirmation message that warns a user that purchase line will be re-created, should inform them that amount of existing item charge assignment will be cleared.
        Initialize();

        // [GIVEN] Purchase order with two lines - for an item and an item charge, assigned to the item line.
        CreatePurchaseOrderWithItemAndItemChargeLines(PurchaseHeader, LibraryRandom.RandDec(10, 2));

        // [WHEN] Change "Buy-from Vendor No." on the purchase header.
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());

        // [THEN] The warning of re-creating lines includes a message about cleared charge assignment amount.
        Assert.ExpectedMessage(ConfirmChangeMsg, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(ConfirmChangeMsg, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(ResetItemChargeAssignMsg, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForMessageVerification')]
    [Scope('OnPrem')]
    procedure NoWarningOfResetItemChargeAssgntOnRecreatePurchLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Item Charge]
        // [SCENARIO 264120] A confirmation message that warns a user that purchase line will be re-created, should not include information of cleared item charge assignments, if there isn't any.
        Initialize();

        // [GIVEN] Purchase order with two lines - for an item and an item charge, that is not assigned yet.
        CreatePurchaseOrderWithItemAndItemChargeLines(PurchaseHeader, 0);

        // [WHEN] Change "Buy-from Vendor No." on the purchase header.
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());

        // [THEN] The warning of re-creating lines does not mention charge assignment.
        Assert.ExpectedMessage(ConfirmChangeMsg, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(ConfirmChangeMsg, LibraryVariableStorage.DequeueText());
        Assert.IsFalse(StrPos(LibraryVariableStorage.DequeueText(), ResetItemChargeAssignMsg) > 0, 'Redundant warning is raised.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandlerWithEqueue')]
    [Scope('OnPrem')]
    procedure MsgWhenValidateQtyToReceivePurchLineAndRequireReceiptEnabledForLocation()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        Quantity: Integer;
    begin
        // [FEATURE] [Location] [Require Receive] [Purchase Order]
        // [SCENARIO] Stan receives message when tries to validate Qty. to Receive in Purchase Line and Require Receipt is enabled in Location
        Initialize();
        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Location with Require Receive = TRUE
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Receive", true);
        Location.Modify(true);

        // [GIVEN] Purchase Order with Location and 10 PCS of Item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Stan opened Purchase Order page
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.FILTER.SetFilter("Document Type", Format(PurchaseHeader."Document Type"));
        PurchaseOrder.First();

        // [WHEN] Stan set Qty. to Receive = 10 in Purchase Order Subform
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(Quantity);

        // [THEN] Message 'Warehouse Receive is required for this line.'
        Assert.AreEqual(
          StrSubstNo(WhseRequiredErr, Location.GetRequirementText(Location.FieldNo("Require Receive"))),
          LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandlerWithEqueue')]
    [Scope('OnPrem')]
    procedure MsgWhenValidateQtyToShipSalesLineAndRequireShipEnabledForLocation()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Integer;
    begin
        // [FEATURE] [Location] [Require Shipment] [Sales Order]
        // [SCENARIO] Stan receives message when tries to validate Qty. to Ship in Sales Line and Require Shipment is enabled in Location
        Initialize();
        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Location with Require Shipment = TRUE
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);

        // [GIVEN] Sales Order with Location and 10 PCS of Item
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [GIVEN] Stan opened Sales Order page
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.FILTER.SetFilter("Document Type", Format(SalesHeader."Document Type"));
        SalesOrder.First();

        // [WHEN] Stan set Qty. to Ship = 10 in Sales Order Subform
        SalesOrder.SalesLines."Qty. to Ship".SetValue(Quantity);

        // [THEN] Message 'Warehouse Shipment is required for this line.'
        Assert.AreEqual(
          StrSubstNo(WhseRequiredErr, Location.GetRequirementText(Location.FieldNo("Require Shipment"))),
          LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandlerWithEqueue')]
    [Scope('OnPrem')]
    procedure MsgWhenValidateQtyToShipServiceLineAndRequireShipEnabledForLocation()
    var
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLines: TestPage "Service Lines";
        Quantity: Integer;
    begin
        // [FEATURE] [Location] [Require Shipment] [Service Order]
        // [SCENARIO] Stan receives message when he tries to validate Qty. to Ship in Service Line and Require Shipment is enabled in Location
        Initialize();
        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Location with Require Shipment = TRUE
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);

        // [GIVEN] Service Order with Location and 10 PCS of Item in Service Line
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo(), Quantity);
        ServiceLine.Validate("Location Code", Location.Code);
        ServiceLine.Modify(true);

        // [GIVEN] Stan opened Service Lines page
        ServiceLines.OpenEdit();
        ServiceLines.FILTER.SetFilter("Document No.", ServiceLine."Document No.");
        ServiceLines.FILTER.SetFilter("Document Type", Format(ServiceLine."Document Type"));
        ServiceLines.First();

        // [WHEN] Stan set Qty. to Ship = 10 on Service Lines page
        ServiceLines."Qty. to Ship".SetValue(Quantity);

        // [THEN] Message 'Warehouse Shipment is required for this line.'
        Assert.AreEqual(
          StrSubstNo(WhseRequiredErr, Location.GetRequirementText(Location.FieldNo("Require Shipment"))),
          LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutofillQtyToHandleDoesNotChangeOtherWhseShip()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WhseShipmentLines: TestPage "Whse. Shipment Lines";
        WarehouseShipment: TestPage "Warehouse Shipment";
    begin
        // [FEATURE] [UI] [Autofill Qty. to Handle] [Warehouse] [Shipment]
        // [SCENARIO 317618] When Stan pushes Autofill Qty. to Ship on Warehouse Shipment page then other Whse Shipments are not affected
        // [SCENARIO 317618] when Warehouse Shipment is opened from Whse Shipment Lines Page and Whse Employee has location
        Initialize();

        // [GIVEN] Warehouse Shipment Line "L1" with Qty. Outstanding = 10 and Qty to Ship = <zero>
        MockWhseShipmentLineWithQtyToShip(WarehouseShipmentLine, LibraryRandom.RandInt(10), 0);

        // [GIVEN] Released Sales Order for other Location with Require Shipment enabled and created Warehouse Shipment
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);

        // [GIVEN] Warehouse Employee with Location
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        CreateSalesOrderWithLocationAndItem(SalesHeader, Location.Code, LibraryInventory.CreateItemNo());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Stan opened Whse. Shipment Lines page, selected Line "L2" and pushed "Show Whse. Document" on page ribbon
        // [GIVEN] Warehouse Shipment page opened showing Card
        WarehouseShipment.Trap();
        WhseShipmentLines.OpenEdit();
        WhseShipmentLines.FILTER.SetFilter(
          "No.", LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        WhseShipmentLines.ShowDocument.Invoke();

        // [WHEN] Stan pushes "Autofill Qty. to Ship" on the page ribbon
        WarehouseShipment."Autofill Qty. to Ship".Invoke();

        // [THEN] Warehouse Shipment Line "L1" has Qty to Ship = <zero> (unchanged)
        WarehouseShipmentLine.Get(WarehouseShipmentLine."No.", WarehouseShipmentLine."Line No.");
        WarehouseShipmentLine.TestField("Qty. to Ship", 0);
        WarehouseShipmentLine.TestField("Qty. to Ship (Base)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteQtyToHandleDoesNotChangeOtherWhseShip()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WhseShipmentLines: TestPage "Whse. Shipment Lines";
        WarehouseShipment: TestPage "Warehouse Shipment";
        QtyToShip: Decimal;
    begin
        // [FEATURE] [UI] [Autofill Qty. to Handle] [Warehouse] [Shipment]
        // [SCENARIO 317618] When Stan pushes Delete Qty. to Ship on Warehouse Shipment page then other Whse Shipments are not affected
        // [SCENARIO 317618] when Warehouse Shipment is opened from Whse Shipment Lines Page and Whse Employee has location
        Initialize();
        QtyToShip := LibraryRandom.RandInt(10);

        // [GIVEN] Warehouse Shipment Line "L1" with Qty. Outstanding = Qty. to Ship = 10
        MockWhseShipmentLineWithQtyToShip(WarehouseShipmentLine, QtyToShip, QtyToShip);

        // [GIVEN] Released Sales Order for other Location with Require Shipment enabled and created Warehouse Shipment
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);

        // [GIVEN] Warehouse Employee with Location
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        CreateSalesOrderWithLocationAndItem(SalesHeader, Location.Code, LibraryInventory.CreateItemNo());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Stan opened Whse. Shipment Lines page, selected Line "L2" and pushed "Show Whse. Document" on page ribbon
        // [GIVEN] Warehouse Shipment page opened showing <blank> Card
        WarehouseShipment.Trap();
        WhseShipmentLines.OpenEdit();
        WhseShipmentLines.FILTER.SetFilter(
          "No.", LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        WhseShipmentLines.ShowDocument.Invoke();

        // [WHEN] Stan pushes "Delete Qty. to Ship" on the page ribbon
        WarehouseShipment."Delete Qty. to Ship".Invoke();

        // [THEN] Warehouse Shipment Line "L1" has Qty to Ship = 10 (unchanged)
        WarehouseShipmentLine.Get(WarehouseShipmentLine."No.", WarehouseShipmentLine."Line No.");
        WarehouseShipmentLine.TestField("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.TestField("Qty. to Ship (Base)", QtyToShip);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutofillQtyToHandleDoesNotChangeOtherWhseReceipt()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WhseReceiptLines: TestPage "Whse. Receipt Lines";
        WarehouseReceipt: TestPage "Warehouse Receipt";
    begin
        // [FEATURE] [UI] [Autofill Qty. to Handle] [Warehouse] [Receipt]
        // [SCENARIO 317618] When Stan pushes Autofill Qty. to Receive on Warehouse Receipt page then other Whse Receipts are not affected
        // [SCENARIO 317618] when Warehouse Receipt is opened from Whse Receipt Lines Page and Whse Employee has location
        Initialize();

        // [GIVEN] Warehouse Receipt Line "L1" with Qty. Outstanding = 10 and Qty to Receive = <zero>
        MockWhseReceiptLineWithQtyToReceive(WarehouseReceiptLine, LibraryRandom.RandInt(10), 0);

        // [GIVEN] Released Sales Order for other Location with Require Receive enabled and created Warehouse Receipt
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Receive", true);
        Location.Modify(true);

        // [GIVEN] Warehouse Employee with Location
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        CreatePurchOrderWithLocationAndItem(PurchaseHeader, Location.Code, LibraryInventory.CreateItemNo());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Stan opened Whse. Receipt Lines page, selected Line "L2" and pushed "Show Whse. Document" on page ribbon
        // [GIVEN] Warehouse Receipt page opened showing Card
        WarehouseReceipt.Trap();
        WhseReceiptLines.OpenEdit();
        WhseReceiptLines.FILTER.SetFilter(
          "No.", LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        WhseReceiptLines.ShowDocument.Invoke();

        // [WHEN] Stan pushes "Autofill Qty. to Receive" on the page ribbon
        WarehouseReceipt."Autofill Qty. to Receive".Invoke();

        // [THEN] Warehouse Receipt Line "L1" has Qty to Ship = <zero> (unchanged)
        WarehouseReceiptLine.Get(WarehouseReceiptLine."No.", WarehouseReceiptLine."Line No.");
        WarehouseReceiptLine.TestField("Qty. to Receive", 0);
        WarehouseReceiptLine.TestField("Qty. to Receive (Base)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteQtyToHandleDoesNotChangeOtherWhseReceipt()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WhseReceiptLines: TestPage "Whse. Receipt Lines";
        WarehouseReceipt: TestPage "Warehouse Receipt";
        QtyToReceive: Decimal;
    begin
        // [FEATURE] [UI] [Autofill Qty. to Handle] [Warehouse] [Receipt]
        // [SCENARIO 317618] When Stan pushes Delete Qty. to Receive on Warehouse Receipt page then other Whse Receipts are not affected
        // [SCENARIO 317618] when Warehouse Receipt is opened from Whse Receipt Lines Page and Whse Employee has location
        Initialize();
        QtyToReceive := LibraryRandom.RandInt(10);

        // [GIVEN] Warehouse Receipt Line "L1" with Qty. Outstanding = Qty to Receive = 10
        MockWhseReceiptLineWithQtyToReceive(WarehouseReceiptLine, QtyToReceive, QtyToReceive);

        // [GIVEN] Released Sales Order for other Location with Require Receive enabled and created Warehouse Receipt
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Receive", true);
        Location.Modify(true);

        // [GIVEN] Warehouse Employee with Location
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        CreatePurchOrderWithLocationAndItem(PurchaseHeader, Location.Code, LibraryInventory.CreateItemNo());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Stan opened Whse. Receipt Lines page, selected Line "L2" and pushed "Show Whse. Document" on page ribbon
        // [GIVEN] Warehouse Receipt page opened showing Card
        WarehouseReceipt.Trap();
        WhseReceiptLines.OpenEdit();
        WhseReceiptLines.FILTER.SetFilter(
          "No.", LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        WhseReceiptLines.ShowDocument.Invoke();

        // [WHEN] Stan pushes "Delete Qty. to Receive" on the page ribbon
        WarehouseReceipt."Delete Qty. to Receive".Invoke();

        // [THEN] Warehouse Receipt Line "L1" has Qty to Receive = 10 (unchanged)
        WarehouseReceiptLine.Get(WarehouseReceiptLine."No.", WarehouseReceiptLine."Line No.");
        WarehouseReceiptLine.TestField("Qty. to Receive", QtyToReceive);
        WarehouseReceiptLine.TestField("Qty. to Receive (Base)", QtyToReceive);
    end;

    [Test]
    [HandlerFunctions('WarehousePickModalPageHandlerWithAutofillQty')]
    [Scope('OnPrem')]
    procedure AutofillQtyToHandleDoesNotChangeOtherPick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipment: TestPage "Warehouse Shipment";
        WarehouseActivityLines: TestPage "Warehouse Activity Lines";
    begin
        // [FEATURE] [UI] [Autofill Qty. to Handle] [Warehouse] [Pick]
        // [SCENARIO 317618] When Stan pushes Autofill Qty. to Handle on <blank> Pick page then other Picks are not affected
        // [SCENARIO 317618] when Pick is opened from Pick Lines Page and Pick has not yet been created from this Shipment
        Initialize();

        // [GIVEN] Warehouse Activity Line "L1" with Qty Outstanding = 10 and Qty. to Handle = <zero>
        MockWhseActivLineWithQtyToHandle(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LibraryRandom.RandInt(10), 0);

        // [GIVEN] Warehouse Employee for Location having Require Shipment enabled
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Released Sales Order with the Location and created Warehouse Shipment
        CreateSalesOrderWithLocationAndItem(SalesHeader, Location.Code, LibraryInventory.CreateItemNo());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Stan opened Warehouse Shipment page and navigated to Warehouse Activity Lines page and opened it (<blank> page opened)
        // [GIVEN] Stan ran Card action on Warehouse Activity Lines page ribbon (Warehouse Pick modal <blank> page opened)
        WarehouseActivityLines.Trap();
        WarehouseShipment.OpenEdit();
        WarehouseShipment.FILTER.SetFilter(
          "No.", LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        WarehouseShipment."Pick Lines".Invoke();
        WarehouseActivityLines.ShowDocument.Invoke();

        // [WHEN] Stan pushes "Autofill Qty. to Handle" on Warehouse Pick page ribbon
        // done in WarehousePickModalPageHandlerWithAutofillQty

        // [THEN] Line "L1" has Qty. to Handle = <zero> (unchanged)
        WarehouseActivityLine.Get(
          WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.", WarehouseActivityLine."Line No.");
        WarehouseActivityLine.TestField("Qty. to Handle", 0);
        WarehouseActivityLine.TestField("Qty. to Handle (Base)", 0);
    end;

    [Test]
    [HandlerFunctions('WarehousePickModalPageHandlerWithDeleteQty')]
    [Scope('OnPrem')]
    procedure DeleteQtyToHandleDoesNotChangeOtherPick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipment: TestPage "Warehouse Shipment";
        WarehouseActivityLines: TestPage "Warehouse Activity Lines";
        QtyToHandle: Decimal;
    begin
        // [FEATURE] [UI] [Autofill Qty. to Handle] [Warehouse] [Pick]
        // [SCENARIO 317618] When Stan pushes Delete Qty. to Handle on <blank> Pick page then other Picks are not affected
        // [SCENARIO 317618] when Pick is opened from Pick Lines Page and Pick has not yet been created from this Shipment
        Initialize();
        QtyToHandle := LibraryRandom.RandInt(10);

        // [GIVEN] Warehouse Activity Line "L1" with Qty Outstanding = Qty. to Handle = 10
        MockWhseActivLineWithQtyToHandle(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, QtyToHandle, QtyToHandle);

        // [GIVEN] Warehouse Employee for Location having Require Shipment enabled
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Released Sales Order with the Location and created Warehouse Shipment
        CreateSalesOrderWithLocationAndItem(SalesHeader, Location.Code, LibraryInventory.CreateItemNo());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Stan opened Warehouse Shipment page and navigated to Warehouse Activity Lines page and opened it (<blank> page opened)
        // [GIVEN] Stan ran Card action on Warehouse Activity Lines page ribbon (Warehouse Pick modal <blank> page opened)
        WarehouseActivityLines.Trap();
        WarehouseShipment.OpenEdit();
        WarehouseShipment.FILTER.SetFilter(
          "No.", LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        WarehouseShipment."Pick Lines".Invoke();
        WarehouseActivityLines.ShowDocument.Invoke();

        // [WHEN] Stan pushes "Delete Qty. to Handle" on Warehouse Pick page ribbon
        // done in WarehousePickModalPageHandlerWithDeleteQty

        // [THEN] Line "L1" has Qty. to Handle = 10 (unchanged)
        WarehouseActivityLine.Get(
          WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.", WarehouseActivityLine."Line No.");
        WarehouseActivityLine.TestField("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.TestField("Qty. to Handle (Base)", QtyToHandle);
    end;

    [Test]
    [HandlerFunctions('WarehousePutAwayModalPageHandlerWithAutofillQty')]
    [Scope('OnPrem')]
    procedure AutofillQtyToHandleDoesNotChangeOtherPutAway()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLines: TestPage "Warehouse Activity Lines";
        PostedWhseReceipt: TestPage "Posted Whse. Receipt";
    begin
        // [FEATURE] [UI] [Autofill Qty. to Handle] [Warehouse] [Put-away]
        // [SCENARIO 317618] When Stan pushes Autofill Qty. to Handle on <blank> Put-away page then other Put-aways are not affected
        // [SCENARIO 317618] when Put-away is opened from Put-away Lines Page and Whse Employee has <blank> location
        Initialize();

        // [GIVEN] Warehouse Activity Line "L1" with Qty Outstanding = 10 and Qty. to Handle = <zero>
        MockWhseActivLineWithQtyToHandle(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LibraryRandom.RandInt(10), 0);

        // [GIVEN] Warehouse Employee for Location having Require Receive enabled
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Receive", true);
        Location.Modify(true);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Released Purchase Order with the Location and posted Warehouse Receipt
        CreatePurchOrderWithLocationAndItem(PurchaseHeader, Location.Code, LibraryInventory.CreateItemNo());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [GIVEN] Stan opened Posted Whse. Receipt page and navigated to Warehouse Activity Lines page and opened it (<blank> page opened)
        // [GIVEN] Stan ran Card action on Warehouse Activity Lines page ribbon (Warehouse Put-away modal <blank> page opened)
        WarehouseActivityLines.Trap();
        PostedWhseReceipt.OpenEdit();
        PostedWhseReceipt.FILTER.SetFilter("Location Code", Location.Code);
        PostedWhseReceipt."Put-away Lines".Invoke();
        WarehouseActivityLines.ShowDocument.Invoke();

        // [WHEN] Stan pushes "Autofill Qty. to Handle" on Warehouse Put-away page ribbon
        // done in WarehousePutAwayModalPageHandlerWithAutofillQty

        // [THEN] Line "L1" has Qty. to Handle = <zero> (unchanged)
        WarehouseActivityLine.Get(
          WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.", WarehouseActivityLine."Line No.");
        WarehouseActivityLine.TestField("Qty. to Handle", 0);
        WarehouseActivityLine.TestField("Qty. to Handle (Base)", 0);
    end;

    [Test]
    [HandlerFunctions('WarehousePutAwayModalPageHandlerWithDeleteQty')]
    [Scope('OnPrem')]
    procedure DeleteQtyToHandleDoesNotChangeOtherPutAway()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLines: TestPage "Warehouse Activity Lines";
        PostedWhseReceipt: TestPage "Posted Whse. Receipt";
        QtyToHandle: Decimal;
    begin
        // [FEATURE] [UI] [Autofill Qty. to Handle] [Warehouse] [Put-away]
        // [SCENARIO 317618] When Stan pushes Autofill Qty. to Handle on <blank> Put-away page then other Put-aways are not affected
        // [SCENARIO 317618] when Put-away is opened from Put-away Lines Page and Whse Employee has <blank> location
        Initialize();
        QtyToHandle := LibraryRandom.RandInt(10);

        // [GIVEN] Warehouse Activity Line "L1" with Qty Outstanding = Qty. to Handle = 10
        MockWhseActivLineWithQtyToHandle(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", QtyToHandle, QtyToHandle);

        // [GIVEN] Warehouse Employee for Location having Require Receive enabled
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Receive", true);
        Location.Modify(true);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Released Purchase Order with the Location and posted Warehouse Receipt
        CreatePurchOrderWithLocationAndItem(PurchaseHeader, Location.Code, LibraryInventory.CreateItemNo());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [GIVEN] Stan opened Posted Whse. Receipt page and navigated to Warehouse Activity Lines page and opened it (<blank> page opened)
        // [GIVEN] Stan ran Card action on Warehouse Activity Lines page ribbon (Warehouse Put-away modal <blank> page opened)
        WarehouseActivityLines.Trap();
        PostedWhseReceipt.OpenEdit();
        PostedWhseReceipt.FILTER.SetFilter("Location Code", Location.Code);
        PostedWhseReceipt."Put-away Lines".Invoke();
        WarehouseActivityLines.ShowDocument.Invoke();

        // [WHEN] Stan pushes "Delete Qty. to Handle" on Warehouse Put-away page ribbon
        // done in WarehousePutAwayModalPageHandlerWithDeleteQty

        // [THEN] Line "L1" has Qty. to Handle = 10 (unchanged)
        WarehouseActivityLine.Get(
          WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.", WarehouseActivityLine."Line No.");
        WarehouseActivityLine.TestField("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.TestField("Qty. to Handle (Base)", QtyToHandle);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BomStructureItemFilterWhenCalledFromItemList();
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: array[2] of Record Item;
        ItemList: TestPage "Item List";
        BOMStructure: TestPage "BOM Structure";
        Index: Integer;
    begin
        // [FEATURE] [Item] [BOM Structure]
        // [SCENARIO 319980] When BOM Structure is opened from filtered Item List, these filters do not impact BOM Structure.
        Initialize();

        // [GIVEN] Items "I1" had Description "X", Item "I2" had Description "Y", both had Production BOMs
        for Index := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[Index]);
            LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[Index]."Base Unit of Measure");
            LibraryManufacturing.CreateProductionBOMLine(
              ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, LibraryInventory.CreateItemNo(),
              LibraryRandom.RandInt(10));
            Item[Index].Validate("Production BOM No.", ProductionBOMHeader."No.");
            Item[Index].Validate(Description, LibraryUtility.GenerateGUID());
            Item[Index].Modify(true);
        end;

        // [GIVEN] Stan opened page Item List filtered by Description "X"
        ItemList.OpenEdit();
        ItemList.FILTER.SetFilter(Description, Item[1].Description);
        ItemList.First();

        // [GIVEN] Stan opened page BOM Structure for Item "I1"
        BOMStructure.Trap();
        ItemList.Structure.Invoke();

        // [WHEN] Stan changes Item Filter to "I3" on page BOM Structure
        BOMStructure.ItemFilter.SetValue(Item[2]."No.");

        // [THEN] BOM for Item "I3" is shown
        BOMStructure.First();
        BOMStructure."No.".AssertEquals(Item[2]."No.");
        BOMStructure.Description.AssertEquals(Item[2].Description);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandlerWithMultipleUIAction,ItemTrackingSummaryModalPageHandlerWithUpdateSelectedQuantity')]
    [Scope('OnPrem')]
    procedure SelectEntriesSelectedQtyWhenSelectAfterSomeQtyRequested()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Bin: Record Bin;
        LotNo: Code[50];
        Index: Integer;
        BaseQty: Integer;
        NumberOfBins: Integer;
    begin
        // [FEATURE] [Item Tracking] [Bin] [Select Entries]
        // [SCENARIO 322926] When Stan selected quantity on Item Tracking Summary page, closed and reopened Item Tracking
        // [SCENARIO 322926] and reopened Item Tracking Summary, then residual quantity is suggested to select in Selected Quantity tab
        LotNo := LibraryUtility.GenerateGUID();
        BaseQty := LibraryRandom.RandInt(10);
        NumberOfBins := 2;
        Initialize();

        // [GIVEN] Item with Lot Tracking Enabled
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Location with Bins B1 and B2
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NumberOfBins, false);

        // [GIVEN] Positive Adjustment for 99 PCS of the Item stored in Bin B1 with Lot
        // [GIVEN] Positive Adjustment for 200 PCS of the Item stored in Bin B2 with the same Lot
        for Index := 1 to NumberOfBins do begin
            LibraryWarehouse.FindBin(Bin, Location.Code, '', Index);
            LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin.Code, 3 * BaseQty * Index);
            LibraryVariableStorage.Enqueue(ItemTrackingMode::SetLotAndQty);
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
            ItemJournalLine.OpenItemTrackingLines(false);
            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        end;

        // [GIVEN] Negative Adjustment Item Journal Line for 299 PCS and Bin B1
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin.Code, -BaseQty * 9);

        // [GIVEN] Stan opened page Item Tracking Lines
        LibraryVariableStorage.Enqueue(ItemTrackingMode::OpenItemTrackingSummary);
        LibraryVariableStorage.Enqueue(BaseQty);
        ItemJournalLine.OpenItemTrackingLines(false);

        // [GIVEN] Stan pushed Select Entries on the page ribbon (Item Tracking Summary page opened showing Selected Quantity 99)
        // done in ItemTrackingLinesModalPageHandlerWithMultipleAction
        Assert.AreEqual(BaseQty * 3, LibraryVariableStorage.DequeueInteger(), WrongSelectedQuantityMsg);

        // [GIVEN] Stan specified Selected Quantity = 33 on page Item Tracking Summary and pushed OK
        // done in ItemTrackingSummaryModalPageHandlerWithUpdateSelectedQuantity

        // [GIVEN] Stan reopened page Item Tracking Lines
        LibraryVariableStorage.Enqueue(ItemTrackingMode::OpenItemTrackingSummary);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandInt(BaseQty * 2));
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Stan pushes Select Entries on the page again
        // done in ItemTrackingLinesModalPageHandlerWithMultipleAction

        // [THEN] Item Tracking Summary page opens showing Selected Quantity 66
        Assert.AreEqual(BaseQty * 2, LibraryVariableStorage.DequeueInteger(), WrongSelectedQuantityMsg);
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        ItemJournalLine.Delete();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandlerWithMultipleUIAction,ItemTrackingSummaryModalPageHandlerWithUpdateSelectedQuantity')]
    [Scope('OnPrem')]
    procedure SelectEntriesSelectedQtyWhenSelectTwiceSequently()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Bin: Record Bin;
        LotNo: Code[50];
        Index: Integer;
        BaseQty: Integer;
        NumberOfBins: Integer;
    begin
        // [FEATURE] [Item Tracking] [Bin] [Select Entries]
        // [SCENARIO 322926] When Stan selected quantity on Item Tracking Summary page and reopened page
        // [SCENARIO 322926] then residual quantity is suggested for selection in the Selected Quantity field
        LotNo := LibraryUtility.GenerateGUID();
        BaseQty := LibraryRandom.RandInt(10);
        NumberOfBins := 2;
        Initialize();

        // [GIVEN] Item with Lot Tracking Enabled
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Location with Bins B1 and B2
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NumberOfBins, false);

        // [GIVEN] Positive Adjustment for 99 PCS of the Item stored in Bin B1 with Lot
        // [GIVEN] Positive Adjustment for 200 PCS of the Item stored in Bin B2 with the same Lot
        for Index := 1 to NumberOfBins do begin
            LibraryWarehouse.FindBin(Bin, Location.Code, '', Index);
            LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin.Code, 3 * BaseQty * Index);
            LibraryVariableStorage.Enqueue(ItemTrackingMode::SetLotAndQty);
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue(ItemJournalLine."Quantity (Base)");
            ItemJournalLine.OpenItemTrackingLines(false);
            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        end;

        // [GIVEN] Negative Adjustment Item Journal Line for 299 PCS and Bin B1
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin.Code, -BaseQty * 9);

        // [GIVEN] Stan opened page Item Tracking Lines
        LibraryVariableStorage.Enqueue(ItemTrackingMode::OpenItemTrackingSummaryTwice);
        LibraryVariableStorage.Enqueue(BaseQty);
        LibraryVariableStorage.Enqueue(BaseQty * 2);
        ItemJournalLine.OpenItemTrackingLines(false);

        // [GIVEN] Stan pushed Select Entries on the page ribbon (Item Tracking Summary page opened showing Selected Quantity 99)
        // done in ItemTrackingLinesModalPageHandlerWithMultipleAction

        // [GIVEN] Stan specified Selected Quantity = 33 on page Item Tracking Summary and pushed OK
        // done in ItemTrackingSummaryModalPageHandlerWithUpdateSelectedQuantity

        // [WHEN] Stan pushes Select Entries on the page again
        // done in ItemTrackingLinesModalPageHandlerWithMultipleAction

        // [THEN] Item Tracking Summary page opens showing Selected Quantity 66
        Assert.AreEqual(BaseQty * 2, LibraryVariableStorage.DequeueInteger(), WrongSelectedQuantityMsg);
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        ItemJournalLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenSelectedQtyMoreThanBinContentWithoutPendingQtys()
    var
        EntrySummary: Record "Entry Summary";
    begin
        // [FEATURE] [UT] [Bin] [Select Entries]
        // [SCENARIO 322926] Cannot Validate Selected Quantity more than Bin Content excluding current pending qtys in Entry Summary
        Initialize();
        // [GIVEN] Entry Summary had Bin Content 100 and Bin Active and Total Available Quantity 200
        // [GIVEN] Entry Summary had Current Pending Quantity 50 and Current Requested Quantity 30
        EntrySummary.Init();
        EntrySummary.Validate("Bin Active", true);
        EntrySummary.Validate("Bin Content", 2 * LibraryRandom.RandInt(10));
        EntrySummary.Validate("Current Pending Quantity", EntrySummary."Bin Content" / 2);
        EntrySummary.Validate("Current Requested Quantity", EntrySummary."Bin Content" / 4);
        EntrySummary.Validate("Total Available Quantity", EntrySummary."Bin Content" * 2);
        // [WHEN] Validate Selected Quantity = 101
        asserterror EntrySummary.Validate("Selected Quantity", EntrySummary."Bin Content" + 1);
        // [THEN] Error 'You cannot select more than 20 units.'
        Assert.ExpectedError(
          StrSubstNo(CannotValidateSelectedQtyErr, EntrySummary."Bin Content" - EntrySummary."Current Pending Quantity" - EntrySummary."Current Requested Quantity"));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [HandlerFunctions('BinContentsListModalPageHandlerWithEnqueueItem')]
    [Scope('OnPrem')]
    procedure BinContentListWhenInternalMovementLineWithoutItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        BinContent: Record "Bin Content";
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovement: TestPage "Internal Movement";
        LocationCode: Code[10];
        BinCode: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Bin Content] [Internal Movement]
        // [SCENARIO 330767] When Stan looks up From-Bin Code in Internal Movement Line, then he can see all Items and Variants on Bin Content List page
        // [GIVEN] Location with Bin
        CreateLocationWithBin(LocationCode, BinCode);

        // [GIVEN] Item "I1" with two Variants had Bin Content for each Variant in the Bin
        LibraryInventory.CreateItem(Item);
        for Index := 1 to 2 do begin
            LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
            LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', BinCode, Item."No.", ItemVariant.Code, Item."Base Unit of Measure");
        end;

        // [GIVEN] Item "I2" had Bin Content in the Bin
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', BinCode, Item."No.", '', Item."Base Unit of Measure");

        // [GIVEN] Internal Movement for the Location
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, LocationCode, '');
        InternalMovement.OpenEdit();
        InternalMovement.FILTER.SetFilter("No.", InternalMovementHeader."No.");

        // [WHEN] Stan looks up From-Bin Code in Internal Movement Line
        InternalMovement.InternalMovementLines."From Bin Code".Lookup();

        // [THEN] Page Bin Content List opens showing 3 entries: two for Item "I1" and one for Item "I2"
        Assert.AreEqual(ItemVariant."Item No.", LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(ItemVariant."Item No.", LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(Item."No.", LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BinContentsListModalPageHandlerWithEnqueueItem')]
    [Scope('OnPrem')]
    procedure BinContentListWhenInternalMovementLineWithItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        BinContent: Record "Bin Content";
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        InternalMovement: TestPage "Internal Movement";
        LocationCode: Code[10];
        BinCode: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Bin Content] [Internal Movement]
        // [SCENARIO 330767] When Stan looks up From-Bin Code in Internal Movement Line with Item, then he can see all Variants for this Item on Bin Content List page
        // [GIVEN] Location with Bin
        CreateLocationWithBin(LocationCode, BinCode);

        // [GIVEN] Item "I1" with two Variants had Bin Content for each Variant in the Bin
        LibraryInventory.CreateItem(Item);
        for Index := 1 to 2 do begin
            LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
            LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', BinCode, Item."No.", ItemVariant.Code, Item."Base Unit of Measure");
        end;

        // [GIVEN] Item "I2" had Bin Content in the Bin
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', BinCode, Item."No.", '', Item."Base Unit of Measure");

        // [GIVEN] Internal Movement for the Location with Item "I1" in Internal Movement Line
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, LocationCode, '');
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, ItemVariant."Item No.", '', '', 0);
        InternalMovement.OpenEdit();
        InternalMovement.FILTER.SetFilter("No.", InternalMovementHeader."No.");

        // [WHEN] Stan looks up From-Bin Code in the Internal Movement Line
        InternalMovement.InternalMovementLines."From Bin Code".Lookup();

        // [THEN] Page Bin Content List opens showing two entries for Item "I1"
        Assert.AreEqual(ItemVariant."Item No.", LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(ItemVariant."Item No.", LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BinContentsListModalPageHandlerWithEnqueueItem')]
    [Scope('OnPrem')]
    procedure BinContentListWhenInternalMovementLineWithItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        BinContent: Record "Bin Content";
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        InternalMovement: TestPage "Internal Movement";
        LocationCode: Code[10];
        BinCode: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Bin Content] [Internal Movement]
        // [SCENARIO 330767] When Stan looks up From-Bin Code in Internal Movement Line with Item and Variant, then he can see only this Variant for this Item on Bin Content List page
        // [GIVEN] Location with Bin
        CreateLocationWithBin(LocationCode, BinCode);

        // [GIVEN] Item "I1" with two Variants had Bin Content for each Variant in the Bin
        LibraryInventory.CreateItem(Item);
        for Index := 1 to 2 do begin
            LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
            LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', BinCode, Item."No.", ItemVariant.Code, Item."Base Unit of Measure");
        end;

        // [GIVEN] Item "I2" had Bin Content in the Bin
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', BinCode, Item."No.", '', Item."Base Unit of Measure");

        // [GIVEN] Internal Movement for the Location with Item "I1" and Variant selected in Internal Movement Line
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, LocationCode, '');
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, ItemVariant."Item No.", '', '', 0);
        InternalMovementLine.Validate("Variant Code", ItemVariant.Code);
        InternalMovementLine.Modify(true);
        InternalMovement.OpenEdit();
        InternalMovement.FILTER.SetFilter("No.", InternalMovementHeader."No.");

        // [WHEN] Stan looks up From-Bin Code in the Line
        InternalMovement.InternalMovementLines."From Bin Code".Lookup();

        // [THEN] Page Bin Content List opens showing just one entry for Item "I1"
        Assert.AreEqual(ItemVariant."Item No.", LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ChangeQtyToShipOnBlanketSalesOrderLineWhenLocationRequireShptAndBinDedicaded()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        DocumentType: Enum "Sales Document Type";
        QtyToShip: Decimal;
    begin
        // [FEATURE] [UI] [Blanket Sales Order] [Location] [Require Shipment]
        // [SCENARIO 387693] Change "Qty to Ship" in Blanket Sales Order line when Location with "Require Shipment" and Bin with "Dedicated" are set.
        Initialize();

        // [GIVEN] Location "L" with "Require Shipment" set.
        // [GIVEN] Bin "B" with Location Code = "L" and Dedicated set, it is Default for Item "I".
        LibraryInventory.CreateItem(Item);
        CreateBinAndBinContent(Bin, Item);
        UpdateRequireShipmentOnLocation(Bin."Location Code", true);
        UpdateDedicatedOnBin(Bin."Location Code", Bin.Code, true);

        // [GIVEN] Blanket Sales Order with a line for Item "I".
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType::"Blanket Order", LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [GIVEN] Order Line is selected on page "Blanket Sales Order". Location is set to "L" and Quantity is set to 10.
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        BlanketSalesOrder.SalesLines."Location Code".SetValue(Bin."Location Code");
        BlanketSalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandDecInRange(10, 20, 2));

        // [WHEN] Change "Qty. to Ship" from 10 to 5.
        QtyToShip := LibraryRandom.RandDecInRange(3, 5, 2);
        BlanketSalesOrder.SalesLines."Qty. to Ship".SetValue(QtyToShip);
        BlanketSalesOrder.Close();

        // [THEN] "Qty. to Ship" value was set to 5. There are no any warning dialogs.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Qty. to Ship", QtyToShip);
    end;

    [Test]
    procedure SetLocationOnSalesOrderLineWhenLocationRequireShptAndShptBinCodeSet()
    var
        DefaultBin: Record Bin;
        ShipmentBin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        DocumentType: Enum "Sales Document Type";
    begin
        // [FEATURE] [UI] [Sales Order] [Location] [Require Shipment]
        // [SCENARIO 387693] Set Location in Sales Order line when Location has "Require Shipment" and "Shipment Bin Code" set.
        Initialize();

        // [GIVEN] Location "L" with "Require Shipment" set, it has two Bins "B1" and "B2".
        // [GIVEN] Bin "B1" is default for Item "I".
        // [GIVEN] Bin "B2" is set as "Shipment Bin Code" for Location "L".
        LibraryInventory.CreateItem(Item);
        CreateBinAndBinContent(DefaultBin, Item);
        LibraryWarehouse.CreateBin(ShipmentBin, DefaultBin."Location Code", LibraryUtility.GenerateGUID(), '', '');
        UpdateRequireShipmentOnLocation(DefaultBin."Location Code", true);
        UpdateShipmentBinCodeOnLocation(ShipmentBin."Location Code", ShipmentBin.Code);

        // [GIVEN] Sales Order with a line for Item "I".
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [GIVEN] Order Line is selected on page "Sales Order".
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [WHEN] Set Location to "L".
        SalesOrder.SalesLines."Location Code".SetValue(DefaultBin."Location Code");
        SalesOrder.Close();

        // [THEN] "Bin Code" value remains blank for order line.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Bin Code", '');
    end;

    [Test]
    procedure SetLocationOnSalesOrderLineWhenLocationRequireShpt()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        DocumentType: Enum "Sales Document Type";
    begin
        // [FEATURE] [UI] [Sales Order] [Location] [Require Shipment]
        // [SCENARIO 387693] Set Location in Sales Order line when Location has "Require Shipment" = true and blank "Shipment Bin Code".
        Initialize();

        // [GIVEN] Location "L" with "Require Shipment" set and with blank "Shipment Bin Code", "L" has one Bin "B".
        // [GIVEN] Bin "B" is default for Item "I".
        LibraryInventory.CreateItem(Item);
        CreateBinAndBinContent(Bin, Item);
        UpdateRequireShipmentOnLocation(Bin."Location Code", true);
        UpdateShipmentBinCodeOnLocation(Bin."Location Code", '');

        // [GIVEN] Sales Order with a line for Item "I".
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [GIVEN] Order Line is selected on page "Sales Order".
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [WHEN] Set Location to "L".
        SalesOrder.SalesLines."Location Code".SetValue(Bin."Location Code");
        SalesOrder.Close();

        // [THEN] "Bin Code" was set to "B" for order line.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    procedure SetLocationOnSalesOrderLineWhenLocationHasShipmentBinCodeSet()
    var
        DefaultBin: Record Bin;
        ShipmentBin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        DocumentType: Enum "Sales Document Type";
    begin
        // [FEATURE] [UI] [Sales Order] [Location]
        // [SCENARIO 387693] Set Location in Sales Order line when Location has "Shipment Bin Code" set and "Require Shipment" = false.
        Initialize();

        // [GIVEN] Location "L" with "Require Shipment" NOT set, it has two Bins "B1" and "B2".
        // [GIVEN] Bin "B1" is default for Item "I".
        // [GIVEN] Bin "B2" is set as "Shipment Bin Code" for Location "L".
        LibraryInventory.CreateItem(Item);
        CreateBinAndBinContent(DefaultBin, Item);
        LibraryWarehouse.CreateBin(ShipmentBin, DefaultBin."Location Code", LibraryUtility.GenerateGUID(), '', '');
        UpdateRequireShipmentOnLocation(DefaultBin."Location Code", false);
        UpdateShipmentBinCodeOnLocation(ShipmentBin."Location Code", ShipmentBin.Code);

        // [GIVEN] Sales Order with a line for Item "I".
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [GIVEN] Order Line is selected on page "Sales Order".
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [WHEN] Set Location to "L".
        SalesOrder.SalesLines."Location Code".SetValue(DefaultBin."Location Code");
        SalesOrder.Close();

        // [THEN] "Bin Code" was set to "B1" for order line.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Bin Code", DefaultBin.Code);
    end;

    [Test]
    procedure ReceiptDateEditableOnShippedTransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 413185] Receipt Date is editable on shipped transfer order with status = Open.
        Initialize();

        TransferHeader.Init();
        TransferHeader."No." := LibraryUtility.GenerateGUID();
        TransferHeader.Insert();

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := LibraryUtility.GetNewRecNo(TransferLine, TransferLine.FieldNo("Line No."));
        TransferLine."Quantity Shipped" := LibraryRandom.RandInt(10);
        TransferLine.Insert();

        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        Assert.IsTrue(TransferOrder."Receipt Date".Editable(), '');
        TransferOrder.Close();

        TransferHeader.Status := TransferHeader.Status::Released;
        TransferHeader.Modify();

        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        Assert.IsFalse(TransferOrder."Receipt Date".Editable(), '');
        TransferOrder.Close();
    end;

    [Test]
    [HandlerFunctions('ReservationFromCurrentLinePageHandler')]
    procedure ProdOrderComponentReservationWithWarehousePick()
    var
        Location: Record Location;
        Bin: array[5] of Record Bin;
        Item: array[2] of Record Item;
        ProdItem: Record Item;
        ProductionOrder: array[2] of Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        NoOfBins: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO 598638] Component reservation should work for second production order when first has warehouse pick created
        Initialize();

        // [GIVEN] Location with Require Pick, Bin Mandatory, and warehouse employee
        CreateLocationWithRequirePick(Location);

        // [GIVEN] Five bins created for the location
        for NoOfBins := 1 to 5 do
            LibraryWarehouse.CreateBin(Bin[NoOfBins], Location.Code, '', '', '');

        // [GIVEN] Set special bin roles for the location.
        Location.Validate("Shipment Bin Code", Bin[1].Code);
        Location.Validate("To-Production Bin Code", Bin[2].Code);
        Location.Validate("From-Production Bin Code", Bin[3].Code);
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee for the Location.
        CreateWarehouseEmployee(Location.Code);

        // [GIVEN] Two Component items with Manual flushing and one Production item.
        CreateComponentItem(Item[1], "Flushing Method"::Manual);
        CreateComponentItem(Item[2], "Flushing Method"::Manual);
        CreateProductionItem(ProdItem, "Manufacturing Policy"::"Make-to-Stock", "Flushing Method"::Manual);

        // [GIVEN] Production BOM with both components
        CreateProductionBOMWithComponents(ProductionBOMHeader, Item[1]."No.", Item[2]."No.");

        // [GIVEN] Assign Production BOM to Production item.
        UpdateItemProductionBOM(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Post inventory for both components in the bin
        Qty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Post inventory for both Components in the Bin.
        PostItemInventoryInBin(Item[1]."No.", Location.Code, Bin[4].Code, '', Qty);
        PostItemInventoryInBin(Item[2]."No.", Location.Code, Bin[4].Code, '', Qty);

        // [GIVEN] Create and refresh first production order
        LibraryManufacturing.CreateProductionOrder(ProductionOrder[1], ProductionOrder[1].Status::Released, ProductionOrder[1]."Source Type"::Item, ProdItem."No.", LibraryRandom.RandIntInRange(1, 1));
        ProductionOrder[1].Validate("Location Code", Location.Code);
        ProductionOrder[1].Modify(true);

        // [GIVEN] Refresh first Production order to create Component lines.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[1], false, true, true, true, false);

        // [GIVEN] Reserve components for first production order
        ReserveProductionOrderComponents(ProductionOrder[1]);

        // [GIVEN] Create warehouse pick for first production order
        CreateWarehousePickFromProdOrder(ProductionOrder[1]);

        // [GIVEN] Create and refresh second production order
        LibraryManufacturing.CreateProductionOrder(ProductionOrder[2], ProductionOrder[2].Status::Released, ProductionOrder[2]."Source Type"::Item, ProdItem."No.", LibraryRandom.RandIntInRange(1, 1));
        ProductionOrder[2].Validate("Location Code", Location.Code);
        ProductionOrder[2].Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[2], false, true, true, true, false);

        // [WHEN] Try to reserve components for second production order
        // [THEN] Reservation should succeed without error
        ReserveProductionOrderComponents(ProductionOrder[2]);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Orders UI");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Orders UI");

        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");
        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Orders UI");
    end;

    local procedure CreateLocationWithBin(var LocationCode: Code[10]; var BinCode: Code[20])
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LocationCode := Location.Code;
        BinCode := Bin.Code;
    end;

    local procedure CreateBinAndBinContent(var Bin: Record Bin; Item: Record Item)
    var
        Location: Record Location;
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure MockWhseShipmentLineWithQtyToShip(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; QtyOutstd: Decimal; QtyToShip: Decimal)
    begin
        WarehouseShipmentLine.Init();
        WarehouseShipmentLine."No." := LibraryUtility.GenerateGUID();
        WarehouseShipmentLine."Line No." := LibraryRandom.RandInt(10);
        WarehouseShipmentLine."Qty. Outstanding (Base)" := QtyOutstd;
        WarehouseShipmentLine."Qty. Outstanding" := WarehouseShipmentLine."Qty. Outstanding (Base)";
        WarehouseShipmentLine."Qty. to Ship (Base)" := QtyToShip;
        WarehouseShipmentLine."Qty. to Ship" := WarehouseShipmentLine."Qty. to Ship (Base)";
        WarehouseShipmentLine.Insert();
    end;

    local procedure MockWhseReceiptLineWithQtyToReceive(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; QtyOutstd: Decimal; QtyToReceive: Decimal)
    begin
        WarehouseReceiptLine.Init();
        WarehouseReceiptLine."No." := LibraryUtility.GenerateGUID();
        WarehouseReceiptLine."Line No." := LibraryRandom.RandInt(10);
        WarehouseReceiptLine."Qty. Outstanding (Base)" := QtyOutstd;
        WarehouseReceiptLine."Qty. Outstanding" := WarehouseReceiptLine."Qty. Outstanding (Base)";
        WarehouseReceiptLine."Qty. to Receive (Base)" := QtyToReceive;
        WarehouseReceiptLine."Qty. to Receive" := WarehouseReceiptLine."Qty. to Receive (Base)";
        WarehouseReceiptLine.Insert();
    end;

    local procedure MockWhseActivLineWithQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; QtyOutst: Decimal; QtyToHandle: Decimal)
    begin
        WarehouseActivityLine.Init();
        WarehouseActivityLine."Activity Type" := ActivityType;
        WarehouseActivityLine."No." := LibraryUtility.GenerateGUID();
        WarehouseActivityLine."Line No." := LibraryRandom.RandInt(10);
        WarehouseActivityLine."Qty. Outstanding (Base)" := QtyOutst;
        WarehouseActivityLine."Qty. Outstanding" := WarehouseActivityLine."Qty. Outstanding (Base)";
        WarehouseActivityLine."Qty. to Handle (Base)" := QtyToHandle;
        WarehouseActivityLine."Qty. to Handle" := WarehouseActivityLine."Qty. to Handle (Base)";
        WarehouseActivityLine.Insert();
    end;

    local procedure CreateSalesOrderWithLocationAndItem(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), ItemNo,
          LibraryRandom.RandInt(10), LocationCode, WorkDate());
    end;

    local procedure CreatePurchOrderWithLocationAndItem(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), ItemNo,
          LibraryRandom.RandInt(10), LocationCode, WorkDate());
    end;

    local procedure ClearCustBusRelationCode()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup."Bus. Rel. Code for Customers" := '';
        MarketingSetup.Modify();
    end;

    local procedure CreateManufacturingItem(var Item: Record Item; ProductionBOMHeaderNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMHeaderNo);
        Item.Modify(true);
    end;

    local procedure CreateSalesOrderWithItemAndItemChargeLines(var SalesHeader: Record "Sales Header"; AmountToAssign: Decimal)
    var
        ItemCharge: Record "Item Charge";
        SalesLine: Record "Sales Line";
        SalesLineForItemCharge: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        LibraryNotificationMgt.DisableMyNotification(SalesHeader.GetModifyCustomerAddressNotificationId());
        LibraryNotificationMgt.DisableMyNotification(SalesHeader.GetModifyBillToCustomerAddressNotificationId());

        LibraryInventory.CreateItemCharge(ItemCharge);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        LibrarySales.CreateSalesLine(
          SalesLineForItemCharge, SalesHeader, SalesLineForItemCharge.Type::"Charge (Item)", ItemCharge."No.", 1);
        SalesLineForItemCharge.Validate("Unit Price", AmountToAssign);
        SalesLineForItemCharge.Modify(true);
        LibrarySales.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineForItemCharge, ItemCharge,
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.", SalesLine."No.",
          SalesLineForItemCharge.Quantity, AmountToAssign);
        ItemChargeAssignmentSales.Insert(true);
    end;

    local procedure CreatePurchaseOrderWithItemAndItemChargeLines(var PurchaseHeader: Record "Purchase Header"; AmountToAssign: Decimal)
    var
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineForItemCharge: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryNotificationMgt.DisableMyNotification(PurchaseHeader.GetModifyVendorAddressNotificationId());
        LibraryNotificationMgt.DisableMyNotification(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());

        LibraryInventory.CreateItemCharge(ItemCharge);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineForItemCharge, PurchaseHeader, PurchaseLineForItemCharge.Type::"Charge (Item)", ItemCharge."No.", 1);
        PurchaseLineForItemCharge.Validate("Direct Unit Cost", AmountToAssign);
        PurchaseLineForItemCharge.Modify(true);
        LibraryPurchase.CreateItemChargeAssignment(
          ItemChargeAssignmentPurch, PurchaseLineForItemCharge, ItemCharge,
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.", PurchaseLine."No.",
          PurchaseLineForItemCharge.Quantity, AmountToAssign);
        ItemChargeAssignmentPurch.Insert(true);
    end;

    local procedure ReserveProdOrderComponent(ItemNo: Code[20])
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.OpenView();
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo);
        ProdOrderComponents.Reserve.Invoke();
        ProdOrderComponents.Close();
    end;

    local procedure UpdateManufacturingSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Normal Starting Time", 080000T);
        ManufacturingSetup.Validate("Normal Ending Time", 160000T);
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateRequireShipmentOnLocation(LocationCode: Code[10]; RequireShipment: Boolean)
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Modify(true);
    end;

    local procedure UpdateShipmentBinCodeOnLocation(LocationCode: Code[10]; ShipmentBinCode: Code[20])
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        Location.Validate("Shipment Bin Code", ShipmentBinCode);
        Location.Modify(true);
    end;

    local procedure UpdateDedicatedOnBin(LocationCode: Code[10]; BinCode: Code[20]; DedicatedValue: Boolean)
    var
        Bin: Record Bin;
    begin
        Bin.Get(LocationCode, BinCode);
        Bin.Validate(Dedicated, DedicatedValue);
        Bin.Modify(true);
    end;

    local procedure CreateLocationWithRequirePick(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Modify(true);
    end;

    local procedure CreateWarehouseEmployee(LocationCode: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);
    end;

    local procedure CreateComponentItem(var Item: Record Item; FlushingMethod: Enum "Flushing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ManufacturingPolicy: Enum "Manufacturing Policy"; FlushingMethod: Enum "Flushing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
    end;

    local procedure CreateProductionBOMWithComponents(var ProductionBOMHeader: Record "Production BOM Header"; Component1No: Code[20]; Component2No: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        Item.Get(Component1No);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");

        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Component1No, 50);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Component2No, 50);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateItemProductionBOM(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure PostItemInventoryInBin(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Quantity);
        if VariantCode <> '' then
            ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure ReserveProductionOrderComponents(var ProductionOrder: Record "Production Order")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        if ProdOrderComponent.FindSet() then
            repeat
                Clear(ProdOrderComponents);
                ProdOrderComponents.OpenEdit();
                ProdOrderComponents.GoToRecord(ProdOrderComponent);
                ProdOrderComponents.Reserve.Invoke();
            until ProdOrderComponent.Next() = 0;
    end;

    local procedure CreateWarehousePickFromProdOrder(var ProductionOrder: Record "Production Order")
    begin
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WarehousePickModalPageHandlerWithAutofillQty(var WarehousePick: TestPage "Warehouse Pick")
    begin
        WarehousePick."Autofill Qty. to Handle".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WarehousePickModalPageHandlerWithDeleteQty(var WarehousePick: TestPage "Warehouse Pick")
    begin
        WarehousePick."Delete Qty. to Handle".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WarehousePutAwayModalPageHandlerWithAutofillQty(var WarehousePutaway: TestPage "Warehouse Put-away")
    begin
        WarehousePutaway."Autofill Qty. to Handle".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WarehousePutAwayModalPageHandlerWithDeleteQty(var WarehousePutaway: TestPage "Warehouse Put-away")
    begin
        WarehousePutaway."Delete Qty. to Handle".Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerForMessageVerification(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(ConfirmMessage);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandlerWithMultipleUIAction(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Qty: array[2] of Integer;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingMode::SetLotAndQty:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueInteger());
                end;
            ItemTrackingMode::OpenItemTrackingSummary:
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::OpenItemTrackingSummaryTwice:
                begin
                    Qty[1] := LibraryVariableStorage.DequeueInteger();
                    Qty[2] := LibraryVariableStorage.DequeueInteger();
                    LibraryVariableStorage.Enqueue(Qty[1]);
                    ItemTrackingLines."Select Entries".Invoke();
                    LibraryVariableStorage.DequeueInteger();
                    LibraryVariableStorage.Enqueue(Qty[2]);
                    ItemTrackingLines."Select Entries".Invoke();
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandlerWithUpdateSelectedQuantity(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    var
        SelectedQty: Integer;
    begin
        SelectedQty := LibraryVariableStorage.DequeueInteger();
        LibraryVariableStorage.Enqueue(ItemTrackingSummary."Selected Quantity".AsInteger());
        ItemTrackingSummary."Selected Quantity".SetValue(SelectedQty);
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        OptionValue: Variant;
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,AssignGivenLotNo;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);
        TrackingOption := OptionValue;
        case TrackingOption of
            TrackingOption::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            TrackingOption::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingOption::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            TrackingOption::AssignGivenLotNo:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Assert.IsTrue(
          (StrLen(Reservation.Caption) > 80) or LibraryVariableStorage.DequeueBoolean(),
          'Caption text on Reservation page is not long enough for the test.');
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerWithEqueue(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BinContentsListModalPageHandlerWithEnqueueItem(var BinContentsList: TestPage "Bin Contents List")
    begin
        BinContentsList.First();
        repeat
            LibraryVariableStorage.Enqueue(Format(BinContentsList."Item No."));
        until not BinContentsList.Next();
    end;

    [ModalPageHandler]
    procedure ReservationFromCurrentLinePageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;
}