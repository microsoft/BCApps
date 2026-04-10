codeunit 137157 "SCM Order Promising II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Order] [Sales] [Order Promising] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationBlue: Record Location;
        LocationIntransit: Record Location;
        LocationRed: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryJob: Codeunit "Library - Job";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        OrderPromising: Option CapableToPromise,AvailableToPromise;
        isInitialized: Boolean;
        PlannedDeliveryDateErr: Label 'Incorrect Planned Delivery Date on Order Promising Line.';
        OriginalShipmentDateErr: Label 'Incorrect Original Shipment Date on Order Promising Line.';
        EarliestShipmentDateErr: Label 'Incorrect Earliest Shipment Date on Order Promising Line.';
        QuantityErr: Label 'Incorrect Quantity on Order Promising Line.';
        NoAvailWarningErr: Label 'Expected availability warning was not shown';
        EarliestAvailDateErr: Label 'Incorrect earliest availability date';

    [Test]
    [Scope('OnPrem')]
    procedure ReceiptDateOnTransferOrderWithInboundWarehouseHandlingTime()
    begin
        // Setup.
        Initialize();
        SalesOrderWithAvailableToPromiseUsingTransferOrder(false);  // Use AvailableToPromise as False.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure AvailableToPromiseOnSalesOrderWithTransferOrderUsingBothWarehouseHandlingTime()
    begin
        // Setup.
        Initialize();
        SalesOrderWithAvailableToPromiseUsingTransferOrder(true);  // Use AvailableToPromise as True.
    end;

    local procedure SalesOrderWithAvailableToPromiseUsingTransferOrder(AvailableToPromise: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // Update both Warehouse Handling Times on Location. Create and post Item Journal Line.
        LibraryInventory.CreateItem(Item);
        UpdateInboundAndOutboundWarehouseHandlingTimeOnLocation(LocationRed);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostItemJournalLine(Item."No.", LocationBlue.Code, Quantity);

        // Exercise.
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, LocationBlue.Code, LocationRed.Code, Item."No.", Quantity);

        // Verify.
        TransferLine.TestField("Receipt Date", CalcDate(LocationRed."Inbound Whse. Handling Time", WorkDate()));

        if AvailableToPromise then begin
            // Exercise.
            LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);  // Post as Ship.
            CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), TransferLine."Receipt Date", Item."No.", LocationRed.Code, Quantity);
            RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::AvailableToPromise, true);  // Use True for Accept.

            // Verify: Verify Planned Delivery Date, Planned Shipment Date and Shipment Date on Sales Line.
            VerifySalesLine(
              SalesLine,
              CalcDate('<+' + Format(LocationRed."Outbound Whse. Handling Time") + '>', TransferLine."Receipt Date"),
              CalcDate('<+' + Format(LocationRed."Outbound Whse. Handling Time") + '>', TransferLine."Receipt Date"),
              TransferLine."Receipt Date");  // Value required for test.
        end;
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnChangingCurrencyCodeOnSalesOrderAfterCapableToPromise()
    var
        Currency: Record Currency;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Sales Order. Run Capable To Promise from Sales Order. Find Currency.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), 0D, Item."No.", LocationBlue.Code, LibraryRandom.RandDec(100, 2));  // Use 0D for Requested Delivery Date.
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, true);  // Use True for Accept.
        LibraryERM.FindCurrency(Currency);

        // Exercise.
        asserterror SalesHeader.Validate("Currency Code", Currency.Code);

        // Verify: Verify error message.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Reserved Qty. (Base)"), Format(0));
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CapableToPromiseOnSalesOrderWithLeadTimeCalculation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CalculatedDate: Date;
    begin
        // Setup: Create Item with Lead Time Calculation. Create Sales Order.
        Initialize();
        CreateItemWithLeadTimeCalculation(Item);
        CalculatedDate := GetEarliestDeliveryDate(Item, '', false);
        CreateSalesOrder(
          SalesHeader, SalesLine, CalculatedDate, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', CalculatedDate),
          Item."No.", '', LibraryRandom.RandDec(100, 2));  // Value required for test.

        // Exercise.
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, true);  // Use True for Accept.

        // Verify.
        VerifyOrderPromisingLine(GetEarliestDeliveryDate(Item, '', false), WorkDate(), SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CapableToPromiseOnSalesOrderWithOutboundWarehouseHandlingTimeAndLeadTimeCalculation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CalculatedDate: Date;
    begin
        // Setup: Create Item with Lead Time Calculation. Update Outbound Warehouse Handling Time on Location. Create Sales Order.
        Initialize();
        CreateItemWithLeadTimeCalculation(Item);
        UpdateOutboundWarehouseHandlingTimeOnLocation(LocationRed);
        CalculatedDate := GetEarliestDeliveryDate(Item, LocationRed.Code, false);
        CreateSalesOrder(
          SalesHeader, SalesLine, CalculatedDate, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', CalculatedDate),
          Item."No.", LocationRed.Code, LibraryRandom.RandDec(100, 2));  // Value required for test.

        // Exercise.
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, true);  // Use True for Accept.

        // Verify.
        VerifyOrderPromisingLine(
          SalesHeader."Requested Delivery Date",
          CalcDate('<-' + Format(LocationRed."Outbound Whse. Handling Time") + '>', SalesHeader."Requested Delivery Date"),
          SalesLine.Quantity);  // Value required for test.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure AvailableToPromiseOnSalesOrderWithRequestedDeliveryDate()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup: Update Outbound Warehouse Handling Time on Location. Create Purchase and Sales Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateOutboundWarehouseHandlingTimeOnLocation(LocationRed);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreatePurchaseOrder(
          PurchaseHeader,
          CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
          Item."No.", LocationRed.Code, Quantity);  // Value required for test.
        CreateSalesOrder(
          SalesHeader, SalesLine, WorkDate(),
          CalcDate(LocationRed."Outbound Whse. Handling Time", PurchaseHeader."Expected Receipt Date"),
          Item."No.", LocationRed.Code, Quantity);  // Value required for test.

        // Exercise.
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::AvailableToPromise, true);  // Use True for Accept.

        // Verify: Verify Planned Delivery Date, Planned Shipment Date and Shipment Date on Sales Line.
        VerifySalesLine(
          SalesLine,
          CalcDate(LocationRed."Outbound Whse. Handling Time", PurchaseHeader."Expected Receipt Date"),
          CalcDate(LocationRed."Outbound Whse. Handling Time", PurchaseHeader."Expected Receipt Date"),
          PurchaseHeader."Expected Receipt Date");  // Value required for test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderBeforeFullyAvailableToPromiseQuantity()
    begin
        // Setup.
        Initialize();
        SalesOrderWithFullyAvailableToPromiseQuantity(false);  // Use AvailableToPromise as False.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderAfterFullyAvailableToPromiseQuantity()
    begin
        // Setup.
        Initialize();
        SalesOrderWithFullyAvailableToPromiseQuantity(true);  // Use AvailableToPromise as True.
    end;

    local procedure SalesOrderWithFullyAvailableToPromiseQuantity(AvailableToPromise: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Create and post Purchase Order as Receive after update both Warehouse Handling Times on Location.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseOrderAsReceiveAfterUpdateBothWarehouseHandlingTimeOnLocation(LocationRed, Item."No.", Quantity);

        // Exercise.
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), 0D, Item."No.", LocationRed.Code, Quantity);  // Use 0D for Requested Delivery Date.

        // Verify: Verify Planned Delivery Date, Planned Shipment Date and Shipment Date on Sales Line.
        VerifySalesLine(
          SalesLine,
          CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
          CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
          WorkDate());  // Value required for test.

        if AvailableToPromise then begin
            // Exercise.
            RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::AvailableToPromise, true);  // Use True for Accept.

            // Verify: Verify Planned Delivery Date, Planned Shipment Date and Shipment Date on Sales Line.
            VerifySalesLine(
              SalesLine,
              CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
              CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
              WorkDate());  // Value required for test.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderBeforePartialAvailableToPromiseQuantity()
    begin
        // Setup.
        Initialize();
        SalesOrderWithPartialAvailableToPromiseQuantity(false);  // Use AvailableToPromise as False.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderAfterPartialAvailableToPromiseQuantity()
    begin
        // Setup.
        Initialize();
        SalesOrderWithPartialAvailableToPromiseQuantity(true);  // Use AvailableToPromise as True.
    end;

    local procedure SalesOrderWithPartialAvailableToPromiseQuantity(AvailableToPromise: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Create and post Purchase Order as Receive after update both Warehouse Handling Times on Location.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseOrderAsReceiveAfterUpdateBothWarehouseHandlingTimeOnLocation(LocationRed, Item."No.", Quantity);

        // Exercise.
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), 0D, Item."No.", LocationRed.Code, Quantity + LibraryRandom.RandDec(100, 2));  // Quantity must be greater than Available Quantity. Use 0D for Requested Delivery Date.

        // Verify: Verify Planned Delivery Date, Planned Shipment Date and Shipment Date on Sales Line.
        VerifySalesLine(
          SalesLine,
          CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
          CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
          WorkDate());  // Value required for test.

        if AvailableToPromise then begin
            // Exercise.
            RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::AvailableToPromise, true);  // Use True for Accept.

            // Verify: Verify Planned Delivery Date, Planned Shipment Date and Shipment Date on Sales Line.
            VerifySalesLine(
              SalesLine,
              CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
              CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
              WorkDate());  // Value required for test.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderBeforeFullyCapableToPromiseQuantity()
    begin
        // Setup.
        Initialize();
        SalesOrderWithFullyCapableToPromiseQuantity(false);  // Use CapableToPromise as False.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderAfterFullyCapableToPromiseQuantity()
    begin
        // Setup.
        Initialize();
        SalesOrderWithFullyCapableToPromiseQuantity(true);  // Use CapableToPromise as True.
    end;

    local procedure SalesOrderWithFullyCapableToPromiseQuantity(CapableToPromise: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Create and post Purchase Order as Receive after update both Warehouse Handling Times on Location.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseOrderAsReceiveAfterUpdateBothWarehouseHandlingTimeOnLocation(LocationRed, Item."No.", Quantity);

        // Exercise.
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), 0D, Item."No.", LocationRed.Code, Quantity);  // Use 0D for Requested Delivery Date.

        // Verify: Verify Planned Delivery Date, Planned Shipment Date and Shipment Date on Sales Line.
        VerifySalesLine(
          SalesLine,
          CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
          CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
          WorkDate());  // Value required for test.

        if CapableToPromise then begin
            // Exercise.
            RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, true);  // Use True for Accept.

            // Verify: Verify Planned Delivery Date, Planned Shipment Date and Shipment Date on Sales Line.
            VerifySalesLine(
              SalesLine,
              CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
              CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
              WorkDate());  // Value required for test.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderBeforePartialCapableToPromiseQuantity()
    begin
        // Setup.
        Initialize();
        SalesOrderWithPartialCapableToPromiseQuantity(false);  // Use CapableToPromise as False.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderAfterPartialCapableToPromiseQuantity()
    begin
        // Setup.
        Initialize();
        SalesOrderWithPartialCapableToPromiseQuantity(true);  // Use CapableToPromise as True.
    end;

    local procedure SalesOrderWithPartialCapableToPromiseQuantity(CapableToPromise: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
        ShipmentDate: Date;
    begin
        // Create and post Purchase Order as Receive after update both Warehouse Handling Times on Location.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseOrderAsReceiveAfterUpdateBothWarehouseHandlingTimeOnLocation(LocationRed, Item."No.", Quantity);

        // Exercise.
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), 0D, Item."No.", LocationRed.Code, Quantity + LibraryRandom.RandDec(100, 2));  // Quantity must be greater than Available Quantity. Use 0D for Requested Delivery Date.

        // Verify: Verify Planned Delivery Date, Planned Shipment Date and Shipment Date on Sales Line.
        VerifySalesLine(
          SalesLine,
          CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
          CalcDate(LocationRed."Outbound Whse. Handling Time", WorkDate()),
          WorkDate());  // Value required for test.

        if CapableToPromise then begin
            // Exercise.
            RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, true);  // Use True for Accept.

            // Verify: Verify Planned Delivery Date, Planned Shipment Date and Shipment Date on Sales Line.
            ShipmentDate :=
              CalcDate(
                '<' + GetDefaultSafetyLeadTime() + '>',
                CalcDate(
                  '<' + GetOffsetTime() + '>',
                  CalcDate(LocationRed."Inbound Whse. Handling Time", WorkDate())));

            VerifySalesLine(
              SalesLine,
              CalcDate(LocationRed."Outbound Whse. Handling Time", ShipmentDate),
              CalcDate(LocationRed."Outbound Whse. Handling Time", ShipmentDate),
              ShipmentDate);

            // Requisition Line must be created for Remaining Quantity with Due Date value required for test.
            VerifyRequisitionLine(
              Item."No.", LocationRed.Code, SalesLine.Quantity - Quantity,
              CalcDate(
                '<' + GetDefaultSafetyLeadTime() + '>',
                CalcDate('<' + GetOffsetTime() + '>', CalcDate(LocationRed."Inbound Whse. Handling Time", WorkDate()))));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithShippingTimeUsingShippingAgentAndBaseCalendar()
    var
        SalesLine: Record "Sales Line";
        ShippingTime: Integer;
    begin
        // [SCENARIO] Planned delivery date in sales order is adjusted to respect non-working days during the shipping time

        Initialize();

        // [GIVEN] Create a customer with a base calendar, set the date 23.01.26 as a non-working day
        // [WHEN] Create a sales order with shipping time 1 day and the shipment date 22.01.26
        ShippingTime := LibraryRandom.RandInt(5);
        CreateSalesOrderWithShipmentDate(SalesLine, WorkDate(), 0, ShippingTime, CreateCustomerWithBaseCalendar(), '');

        // [THEN] Planned shipment date in the sales order is 22.01.26, palnned delivery date 24.01.26 
        VerifySalesLine(SalesLine, WorkDate() + ShippingTime + 1, WorkDate(), WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithOutboundWarehouseHandlingTimeUsingShippingAgentAndBaseCalendar()
    var
        SalesLine: Record "Sales Line";
        OutboundWhseHandlingTime: Integer;
    begin
        // [SCENARIO] Planned shipment date and planned delivery date in sales order are adjusted to respect non-working days during the outbound warehouse handling time

        Initialize();

        // [GIVEN] Create a customer with a base calendar, set the date 23.01.26 as a non-working day
        // [WHEN] Create a sales order with outbound warehouse handling time 1 day and the shipment date 22.01.26
        OutboundWhseHandlingTime := LibraryRandom.RandInt(5);
        CreateSalesOrderWithShipmentDate(SalesLine, WorkDate(), OutboundWhseHandlingTime, 0, CreateCustomerWithBaseCalendar(), '');

        // [THEN] Both planned shipment date and planned delivery date in the sales order are 24.01.26
        VerifySalesLine(SalesLine, WorkDate() + OutboundWhseHandlingTime + 1, WorkDate() + OutboundWhseHandlingTime + 1, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithOutboundWarehouseHandlingTimeAndShipmentDateAsNonWorkingDateUsingShippingAgentAndBaseCalendar()
    var
        SalesLine: Record "Sales Line";
        OutboundWhseHandlingTime: Integer;
    begin
        // [SCENARIO] Planned shipment date and planned delivery date in sales order are adjusted to respect non-working days when the shipment date is non-working

        Initialize();

        // [GIVEN] Create a customer with a base calendar, set the date 23.01.26 as a non-working day
        // [WHEN] Create a sales order with outbound warehouse handling time 1 day and the shipment date 23.01.26
        OutboundWhseHandlingTime := LibraryRandom.RandInt(5);
        CreateSalesOrderWithShipmentDate(SalesLine, WorkDate() + 1, OutboundWhseHandlingTime, 0, CreateCustomerWithBaseCalendar(), '');

        // [THEN] Both planned shipment date and planned delivery date in the sales order are 24.01.26
        VerifySalesLine(SalesLine, WorkDate() + OutboundWhseHandlingTime + 1, WorkDate() + OutboundWhseHandlingTime + 1, WorkDate() + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithOutboundWarehouseHandlingTimeAndShippingTimeUsingShippingAgentAndBaseCalendar()
    var
        SalesLine: Record "Sales Line";
        ShippingTime: Integer;
        OutboundWhseHandlingTime: Integer;
    begin
        // [SCENARIO] Planned shipment date and planned delivery date in sales order are adjusted to respect non-working days with both shipment time and warehouse handling time

        Initialize();

        // [GIVEN] Create a customer with a base calendar, set the date 23.01.26 as a non-working day
        // [WHEN] Create a sales order with outbound warehouse handling time 1 day, shipping time 1 day, and the shipment date 23.01.26
        ShippingTime := LibraryRandom.RandInt(5);
        OutboundWhseHandlingTime := LibraryRandom.RandInt(5);

        CreateSalesOrderWithShipmentDate(SalesLine, WorkDate(), OutboundWhseHandlingTime, ShippingTime, CreateCustomerWithBaseCalendar(), '');

        // [THEN] Both planned shipment date and planned delivery date in the sales order are 25.01.26
        VerifySalesLine(SalesLine, WorkDate() + OutboundWhseHandlingTime + ShippingTime + 1, WorkDate() + OutboundWhseHandlingTime + 1, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithLocationUsingShippingAgentAndBaseCalendar()
    var
        SalesLine: Record "Sales Line";
        ShippingTime: Integer;
        OutboundWhseHandlingTime: Integer;
    begin
        // [SCENARIO] Planned shipment date and planned delivery date in sales order are adjusted to respect non-working days in a location calendar
        Initialize();

        // [GIVEN] Create a customer with a base calendar, set the date 23.01.26 as a non-working day
        // [GIVEN] Create a location "L" with a base calendar, set the date 24.01.26 as a non-working day
        ShippingTime := LibraryRandom.RandInt(5);
        OutboundWhseHandlingTime := LibraryRandom.RandInt(5);
        UpdateBaseCalendarOnLocation(LocationBlue, WorkDate() + 2);

        // [WHEN] Create a sales order on location "L", set outbound warehouse handling time 1 day, shipping time 1 day, and the shipment date 23.01.26
        CreateSalesOrderWithShipmentDate(SalesLine, WorkDate(), OutboundWhseHandlingTime, ShippingTime, CreateCustomerWithBaseCalendar(), LocationBlue.Code);

        // [THEN] Both planned shipment date and planned delivery date in the sales order are 26.01.26
        VerifySalesLine(SalesLine, WorkDate() + OutboundWhseHandlingTime + ShippingTime + 2, WorkDate() + OutboundWhseHandlingTime + 2, WorkDate());
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderPromisingWithoutCompanyBaseCalendar()
    begin
        // Setup.
        Initialize();
        OrderPromisingBySalesOrderWithCompanyBaseCalendar(false);  // Use False for Company Base Calendar.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderPromisingWithCompanyBaseCalendar()
    begin
        // Setup.
        Initialize();
        OrderPromisingBySalesOrderWithCompanyBaseCalendar(true);  // Use True for Company Base Calendar.
    end;

    local procedure OrderPromisingBySalesOrderWithCompanyBaseCalendar(CompanyBaseCalendar: Boolean)
    var
        BaseCalendar: Record "Base Calendar";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldBaseCalendarCode: Code[10];
    begin
        // Create Item with Lead Time Calculation. Create Sales Order.
        CreateItemWithLeadTimeCalculation(Item);
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), 0D, Item."No.", '', LibraryRandom.RandDec(100, 2));  // Use 0D for Requested Delivery Date and Blank for Location.

        // Exercise.
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, false);  // Use False for Accept.

        // Verify.
        VerifyOrderPromisingLine(GetEarliestDeliveryDate(Item, '', false), WorkDate(), SalesLine.Quantity);

        if CompanyBaseCalendar then begin
            // Exercise.
            CreateBaseCalendarWithBaseCalendarChange(BaseCalendar, WorkDate() + 1);
            OldBaseCalendarCode := UpdateBaseCalendarOnCompanyInformation(BaseCalendar.Code);
            RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, false);  // Use False for Accept.

            // Verify.
            VerifyOrderPromisingLine(GetEarliestDeliveryDate(Item, '', true), WorkDate(), SalesLine.Quantity);
        end;

        // Tear down.
        UpdateBaseCalendarOnCompanyInformation(OldBaseCalendarCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithoutShippingTime()
    begin
        // Setup.
        Initialize();
        SalesOrderWithShippingTimeAndRequestedDeliveryDate(0, false);  // Use 0 for Shipping Time and False for Update Requested DeliveryDate.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderRequestedDeliveryDateWithoutShippingTime()
    begin
        // Setup.
        Initialize();
        SalesOrderWithShippingTimeAndRequestedDeliveryDate(0, true);  // Use 0 for Shipping Time and True for Update Requested Delivery Date.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithShippingTime()
    begin
        // Setup.
        Initialize();
        SalesOrderWithShippingTimeAndRequestedDeliveryDate(LibraryRandom.RandInt(5), false);  // Use False for Update Requested Delivery Date.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderRequestedDeliveryDateWithShippingTime()
    begin
        // Setup.
        Initialize();
        SalesOrderWithShippingTimeAndRequestedDeliveryDate(LibraryRandom.RandInt(5), true);  // Use True for Update Requested Delivery Date.
    end;

    local procedure SalesOrderWithShippingTimeAndRequestedDeliveryDate(ShippingTime: Integer; UpdateRequestedDeliveryDate: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Item and Customer.
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);

        // Exercise.
        CreateSalesOrderWithShipmentDate(SalesHeader, SalesLine, WorkDate(), 0, ShippingTime, Customer."No.", Item."No.", '');  // Use 0 for Outbound Warehouse Handling Time and Blank for Location.

        // Verify.
        VerifySalesLine(SalesLine, CalcDate(SalesHeader."Shipping Time", WorkDate()), WorkDate(), WorkDate());

        if UpdateRequestedDeliveryDate then begin
            // Exercise.
            UpdateRequestedDeliveryDateOnSalesOrder(
              SalesHeader, CalcDate('<' + GetDefaultSafetyLeadTime() + '>', CalcDate(SalesHeader."Shipping Time", WorkDate())));

            // Verify.
            VerifySalesLine(
              SalesLine, SalesHeader."Requested Delivery Date", CalcDate('<-' + Format(SalesHeader."Shipping Time") + '>',
                SalesHeader."Requested Delivery Date"),
              CalcDate('<-' + Format(SalesHeader."Shipping Time") + '>', SalesHeader."Requested Delivery Date"));
        end;
    end;

    [Test]
    procedure SalesOrderWithBaseCalendarAndShippingTime()
    var
        BaseCalendar: Record "Base Calendar";
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShippingAgentServices: Record "Shipping Agent Services";
        PlannedDate: Date;
        PlannedShipmentDate: Date;
    begin
        Initialize();

        // Create Base Calendar with Base Calendar Change. Create Customer with Shipping Agent and Base Calendar.
        LibraryInventory.CreateItem(Item);
        CreateBaseCalendarWithBaseCalendarChange(BaseCalendar, WorkDate() + 1);
        CreateShippingAgentWithShippingAgentService(ShippingAgentServices, BaseCalendar.Code);
        CreateCustomerWithShippingAgentAndBaseCalendar(Customer, ShippingAgentServices, BaseCalendar.Code);

        // Exercise.
        CreateSalesOrderWithShipmentDate(SalesHeader, SalesLine, WorkDate(), 0, LibraryRandom.RandInt(5), Customer."No.", Item."No.", '');  // Use 0 for Outbound Warehouse Handling Time and Blank for Location.

        // Verify.
        PlannedShipmentDate := WorkDate();
        PlannedDate := CalcDate(SalesHeader."Shipping Time", PlannedShipmentDate) + 1;
        VerifySalesLine(SalesLine, PlannedDate, PlannedShipmentDate, WorkDate());

        // Exercise.
        UpdateRequestedDeliveryDateOnSalesOrder(SalesHeader, PlannedDate);

        // Verify.
        PlannedDate := CalcDate('<-' + Format(SalesHeader."Shipping Time") + '>', SalesHeader."Requested Delivery Date") - 1;
        VerifySalesLine(SalesLine, SalesHeader."Requested Delivery Date", PlannedDate, PlannedDate);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderSameItemWithAscendingShipmentDatesNoReservation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemNo: Code[20];
        ShipmentDate: array[2] of Date;
        Quantity: Decimal;
    begin
        // [SCENARIO 358897.1] Item availability on two Sales Lines with ascending Shipment Date

        // [GIVEN] Purchase Item = X of Quantity = Y
        // [GIVEN] Create Sales Order with two lines both with same Item = X and Quantity = Y
        // [GIVEN] Set Shipment Dates in ascending order
        ShipmentDate[1] := WorkDate();
        ShipmentDate[2] := CalcDate('<1M>', WorkDate());
        CreateSalesOrderWithTwoShipmentDates(SalesHeader, ItemNo, Quantity, ShipmentDate);

        // [WHEN] Calculate Available-To-Promise on the earlier line (don't Accept)
        FindSalesLineByShipmentDate(SalesLine, SalesHeader, ShipmentDate[1]);
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::AvailableToPromise, false);

        // [THEN] Verify 'Earliest Shipment Date' in the first line is equal to 'Shipment Date'
        VerifyEarliestShipmentDate(ShipmentDate[1]);

        // [THEN] Verify availability and available inventory in Sales Line Fact Box on the first line
        VerifySalesLineDetails(SalesOrder, SalesHeader."No.", ItemNo, ShipmentDate[1], 0, Quantity);
        // [THEN] Verify availability and available inventory in Sales Line Fact Box on the second line
        VerifySalesLineDetails(SalesOrder, SalesHeader."No.", ItemNo, ShipmentDate[2], -Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderSameItemWithDescendingShipmentDatesNoReservation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemNo: Code[20];
        ShipmentDate: array[2] of Date;
        Quantity: Decimal;
    begin
        // [SCENARIO 359702] Item availability on two Sales Lines with descending Shipment Date

        // [GIVEN] Purchase Item = X of Quantity = Y
        // [GIVEN] Create Sales Order with two lines both with same Item = X and Quantity = Y
        // [GIVEN] Set Shipment Dates in descending order
        ShipmentDate[1] := CalcDate('<1M>', WorkDate());
        ShipmentDate[2] := WorkDate();
        CreateSalesOrderWithTwoShipmentDates(SalesHeader, ItemNo, Quantity, ShipmentDate);

        // [WHEN] Calculate Available-To-Promise on the earlier line (don't Accept)
        FindSalesLineByShipmentDate(SalesLine, SalesHeader, ShipmentDate[2]);
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::AvailableToPromise, false);

        // [THEN] Verify 'Earliest Shipment Date' in the first line is equal to 'Shipment Date'
        VerifyEarliestShipmentDate(ShipmentDate[2]);

        // [THEN] Verify availability and available inventory in Sales Line Fact Box on the first line
        VerifySalesLineDetails(SalesOrder, SalesHeader."No.", ItemNo, ShipmentDate[1], -Quantity, Quantity);
        // [THEN] Verify availability and available inventory in Sales Line Fact Box on the second line
        VerifySalesLineDetails(SalesOrder, SalesHeader."No.", ItemNo, ShipmentDate[2], 0, Quantity);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderSameItemWithDifferentShipmentDatesWithAheadReservation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemNo: Code[20];
        ShipmentDate: array[2] of Date;
        Quantity: Decimal;
    begin
        // [SCENARIO 358897.2] Item availability on two Sales Lines with ascending Shipment Date and reservation

        // [GIVEN] Purchase Item = X of Quantity = Y
        // [GIVEN] Create Sales Order with two lines both with same Item = X and Quantity = Y
        // [GIVEN] Set Shipment Dates in ascending order
        ShipmentDate[1] := WorkDate();
        ShipmentDate[2] := CalcDate('<1M>', WorkDate());
        CreateSalesOrderWithTwoShipmentDates(SalesHeader, ItemNo, Quantity, ShipmentDate);
        // [GIVEN] Make reservation on the later line
        FindSalesLineByShipmentDate(SalesLine, SalesHeader, ShipmentDate[2]);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [WHEN] Calculate Available-To-Promise on the earlier line (don't Accept)
        FindSalesLineByShipmentDate(SalesLine, SalesHeader, ShipmentDate[1]);
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::AvailableToPromise, false);

        // [THEN] Verify 'Earliest Shipment Date' is empty
        VerifyEarliestShipmentDate(0D);

        // [THEN] Verify availability and available inventory in Sales Line Fact Box on the first line
        VerifySalesLineDetails(SalesOrder, SalesHeader."No.", ItemNo, ShipmentDate[1], -Quantity, 0);
        // [THEN] Verify availability and available inventory in Sales Line Fact Box on the second line
        VerifySalesLineDetails(SalesOrder, SalesHeader."No.", ItemNo, ShipmentDate[2], -Quantity, 0);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderItemWithSKUAndInterLocationTransfer()
    var
        Item: Record Item;
        SKURed: Record "Stockkeeping Unit";
        SKUBlue: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferRoute: Record "Transfer Route";
    begin
        // Verify Planned Delivery Date when Item with SKUs by locations and inter-location transfer
        Initialize();
        LocationBlue.Find();
        LocationRed.Find();

        // Create Critical Item, SKU by Location: RED, BLUE
        CreateItemCritical(Item);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKUBlue, LocationBlue.Code, Item."No.", '');
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKURed, LocationRed.Code, Item."No.", '');

        // Create Route Transfer from BLUE to RED
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, LocationBlue.Code, LocationRed.Code, LocationIntransit.Code, '', '');
        UpdateInboundAndOutboundWarehouseHandlingTimeOnLocation(LocationBlue);
        UpdateSKUReplenishmentSystemWithTransfer(SKURed, LocationBlue.Code);

        // Create Sales Order on RED
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), 0D, Item."No.", LocationRed.Code, LibraryRandom.RandDec(100, 2));
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, false);

        // Verify that Planned Delivery Date considering BLUE outbound time transfer
        VerifyOrderPromisingLine(GetEarliestDeliveryDate(Item, LocationBlue.Code, false), WorkDate(), SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderPromisingInvokedFromSalesLineBasedOnTemporaryTable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
    begin
        // [SCENARIO 381557] Order Promising page should have a temporary table as its source, no record should be saved to the database.
        Initialize();

        // [GIVEN] Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), WorkDate(), LibraryInventory.CreateItemNo(), '', 10);

        // [WHEN] Run "Order Promising" from the Sales Line.
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, true);

        // [THEN] Order Promising table remains empty.
        OrderPromisingLine.Init();
        OrderPromisingLine.SetRange("Item No.", SalesLine."No.");
        Assert.RecordIsEmpty(OrderPromisingLine);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PlannedProdOrdersInPlanningWkshtAreNumberedConsequently()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        ItemNo: array[3] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Capable to Promise] [Production Order] [No. Series]
        // [SCENARIO 205943] Planned production orders in Planning Worksheet should be numbered consequently when the requisition lines are created using Capable-to-Promise.
        Initialize();

        // [GIVEN] No. Series for planned production orders is created.
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '000000', '999999');
        UpdatePlannedOrderNosOnMfgSetup(NoSeries.Code);

        // [GIVEN] Sales Order "SO".
        CreateSalesHeader(SalesHeader, WorkDate(), WorkDate());

        // [GIVEN] Several lines for "SO" with manufacturing items.
        for i := 1 to ArrayLen(ItemNo) do begin
            ItemNo[i] := CreateManufacturingItem();
            CreateSalesLine(SalesHeader, SalesLine, ItemNo[i], '', LibraryRandom.RandInt(10));
        end;

        // [WHEN] Run Capable-to-Promise from "SO".
        RunOrderPromisingFromSalesHeader(SalesHeader, OrderPromising::CapableToPromise, true);

        // [THEN] Planned production orders in newly created requisition lines are numbered consequently.
        VerifyRefOnRequisitionLine(NoSeries.Code);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithDropShipmentNotReservedWhenReqLineCreatedViaCapableToPromise()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Drop Shipment] [Reservation]
        // [SCENARIO 231925] Sales line with drop shipment is not reserved from requisition line generated with Order Promising functionality.
        Initialize();

        // [GIVEN] Sales line set up for drop shipment.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(10), '', WorkDate());
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);

        // [WHEN] Run Capable-to-Promise from the sales line.
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, true);

        // [THEN] Requisition line is created.
        RequisitionLine.SetRange("No.", SalesLine."No.");
        Assert.RecordIsNotEmpty(RequisitionLine);

        // [THEN] The sales line is not reserved from requisition line.
        SalesLine.Find();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField(Reserve, SalesLine.Reserve::Never);
        SalesLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoLookaheadLimitWithBlankCheckAvailPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        // [FEATURE] [Check-Avail. Period]
        // [SCENARIO 269042] Blank "Check-Avail. Period Calc." does not limit lookahead period when calculating availability ate

        Initialize();

        // [GIVEN] Set "Check-Avail. Period Calc." in "Company Information" to blank
        UpdateCheckAvailPeriodCalculation('');

        // [GIVEN] Sales order for "X" pcs of item "I", shipment date = 23.01.2020
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), WorkDate(), Item."No.", '', LibraryRandom.RandInt(100));

        // [GIVEN] Purchase order for "X" pcs of item "I", expected receipt date = 02.02.2020
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), Item."No.",
          SalesLine.Quantity, '', GetDateOutsideOfAvailabilityTimeBucket(SalesLine."Planned Shipment Date"));

        // [WHEN] Calculate earliest availability date for item "I"
        Assert.IsTrue(ItemCheckAvail.SalesLineShowWarning(SalesLine), NoAvailWarningErr);

        // [THEN] Earliest availability date is 02.02.2020
        Assert.AreEqual(
          PurchaseLine."Expected Receipt Date", FetchItemAvailabilityCalculationEarliestAvailDate(ItemCheckAvail), EarliestAvailDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookaheadLimitedWithCheckAvailPeriod0D()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        // [FEATURE] [Check-Avail. Period]
        // [SCENARIO 269042] "Item-Check Avail." does not look ahead when calculating availability if "Check-Avail. Period Calc." is explicitly set to '0D'
        Initialize();

        // [GIVEN] Set "Check-Avail. Period Calc." in "Company Information" to '<0D>'
        UpdateCheckAvailPeriodCalculation('<0D>');

        // [GIVEN] Sales order for "X" pcs of item "I", shipment date = 23.01.2020
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), WorkDate(), Item."No.", '', LibraryRandom.RandInt(100));

        // [GIVEN] Purchase order for "X" pcs of item "I", expected receipt date = 02.02.2020
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), Item."No.",
          SalesLine.Quantity, '', GetDateOutsideOfAvailabilityTimeBucket(SalesLine."Planned Shipment Date"));

        // [WHEN] Calculate earliest availability date for item "I"
        Assert.IsTrue(ItemCheckAvail.SalesLineShowWarning(SalesLine), NoAvailWarningErr);

        // [THEN] Earliest availability date is 0D
        Assert.AreEqual(0D, FetchItemAvailabilityCalculationEarliestAvailDate(ItemCheckAvail), EarliestAvailDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAvailabilityFutureRequirementConsideredWhenCheckAvailPeriodBlank()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        ShipmentDate: Date;
    begin
        // [FEATURE] [Check-Avail. Period]
        // [SCENARIO 269042] Item availability warning considers future requirements when "Check-Avail. Period Calc." is blank

        Initialize();

        // [GIVEN] Set "Check-Avail. Period Calc." in "Company Information" to blank value
        UpdateCheckAvailPeriodCalculation('');

        // [GIVEN] Purchase order for "X" pcs of item "I" on 23.01.2020
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorNo(), Item."No.", LibraryRandom.RandInt(100), '', WorkDate());

        // [GIVEN] Sales order for "X" pcs of item "I" on 02.02.2020
        ShipmentDate := GetDateOutsideOfAvailabilityTimeBucket(PurchaseLine."Expected Receipt Date");
        CreateSalesOrder(
          SalesHeader, SalesLine, WorkDate(), ShipmentDate, Item."No.", '', LibraryRandom.RandInt(20));
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);

        // [WHEN] Create another sales line for "Y" pcs of item "I" on 23.02.2020
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", PurchaseLine.Quantity);

        // [THEN] Availability warning is raised
        Assert.IsTrue(ItemCheckAvail.SalesLineShowWarning(SalesLine), NoAvailWarningErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATPEarliestShipDateWhenSalesOrdersWithRequestedDeliveryDateAndPurchaseOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        OrderPromisingLine: Record "Order Promising Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
        ItemNo: Code[20];
        LocationCode: Code[10];
        BaseQty: Integer;
    begin
        // [FEATURE] [Available to Promise] [Earliest Shipment Date]
        // [SCENARIO 320770] When Requested Delivery Date is populated in Sales then ATP returns Earliest Shipment Date = Requested Shipment Date
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        LocationCode := CreateLocationCode();
        BaseQty := LibraryRandom.RandInt(10);

        // [GIVEN] Purchase Order with Expected Receipt Date = 31/1/2021 and 25 PCS of Item
        CreatePurchaseOrder(PurchaseHeader, CalcDate('<2D>', WorkDate()), ItemNo, LocationCode, BaseQty * 5);

        // [GIVEN] Sales Order with Requested Delivery Date = 5/2/2021 and 5 PCS of the Item (Planned Shipment Date was 4/2/2021)
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), CalcDate('<1W>', WorkDate()), ItemNo, LocationCode, BaseQty);

        // [GIVEN] Sales Order with same Requested Delivery Date and 10 PCS of the Item (Planned Shipment Date was the same)
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), CalcDate('<1W>', WorkDate()), ItemNo, LocationCode, BaseQty * 2);
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, SalesHeader);

        // [WHEN] Calculate Available to Promise for the 2nd Sales Order
        AvailabilityManagement.CalcAvailableToPromise(OrderPromisingLine);

        // [THEN] Order Promising Line has Earliest Shipment Date = Requested Shipment Date = 4/2/2021 for the Sales Order
        OrderPromisingLine.TestField("Earliest Shipment Date", SalesLine."Planned Shipment Date");
        OrderPromisingLine.TestField("Requested Shipment Date", SalesLine."Planned Shipment Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATPEarliestShipDateWhenServiceLinesWithRequestedDeliveryDateAndPurchaseOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        PurchaseHeader: Record "Purchase Header";
        OrderPromisingLine: Record "Order Promising Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
        ItemNo: Code[20];
        LocationCode: Code[10];
        BaseQty: Integer;
    begin
        // [FEATURE] [Available to Promise] [Earliest Shipment Date] [Service]
        // [SCENARIO 320770] When Requested Delivery Date is populated in Service then ATP returns Earliest Shipment Date = Requested Shipment Date
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        LocationCode := CreateLocationCode();
        BaseQty := LibraryRandom.RandInt(10);

        // [GIVEN] Purchase Order with Expected Receipt Date = 31/1/2021 and 25 PCS of Item
        CreatePurchaseOrder(PurchaseHeader, CalcDate('<2D>', WorkDate()), ItemNo, LocationCode, BaseQty * 5);

        // [GIVEN] Service Line with Requested Delivery Date = 5/2/2021 and 5 PCS of the Item (Needed by Date was 4/2/2021)
        CreateServiceOrder(ServiceHeader, ServiceLine, CalcDate('<1W>', WorkDate()), ItemNo, LocationCode, BaseQty);

        // [GIVEN] Service Line with same Requested Delivery Date and 10 PCS of the Item (Needed by Date was the same)
        CreateServiceOrder(ServiceHeader, ServiceLine, CalcDate('<1W>', WorkDate()), ItemNo, LocationCode, BaseQty * 2);
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, ServiceHeader);

        // [WHEN] Calculate Available to Promise for the 2nd Service Line
        AvailabilityManagement.CalcAvailableToPromise(OrderPromisingLine);

        // [THEN] Order Promising Line has Earliest Shipment Date = Requested Shipment Date = 4/2/2021 for the Service Line
        OrderPromisingLine.TestField("Earliest Shipment Date", ServiceLine."Needed by Date");
        OrderPromisingLine.TestField("Requested Shipment Date", ServiceLine."Needed by Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATPEarliestShipDateWhenJobLinesWithRequestedDeliveryDateAndPurchaseOrder()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        OrderPromisingLine: Record "Order Promising Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
        ItemNo: Code[20];
        LocationCode: Code[10];
        BaseQty: Integer;
    begin
        // [FEATURE] [Available to Promise] [Earliest Shipment Date] [Job Planning]
        // [SCENARIO 320770] When Requested Delivery Date is populated in Job Planning then ATP returns Earliest Shipment Date = Requested Shipment Date
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        LocationCode := CreateLocationCode();
        BaseQty := LibraryRandom.RandInt(10);

        // [GIVEN] Purchase Order with Expected Receipt Date = 31/1/2021 and 25 PCS of Item
        CreatePurchaseOrder(PurchaseHeader, CalcDate('<2D>', WorkDate()), ItemNo, LocationCode, BaseQty * 5);

        // [GIVEN] Job Planning Line with Requested Delivery Date = 5/2/2021 and 5 PCS of the Item (Needed by Date was 4/2/2021)
        CreateJobWithJobPlanningLine(Job, JobPlanningLine, CalcDate('<1W>', WorkDate()), ItemNo, LocationCode, BaseQty);

        // [GIVEN] Job Planning Line with same Requested Delivery Date and 10 PCS of the Item (Needed by Date was the same)
        CreateJobWithJobPlanningLine(Job, JobPlanningLine, CalcDate('<1W>', WorkDate()), ItemNo, LocationCode, BaseQty * 2);
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, Job);

        // [WHEN] Calculate Available to Promise for the 2nd Job Planning Line
        AvailabilityManagement.CalcAvailableToPromise(OrderPromisingLine);

        // [THEN] Order Promising Line has Earliest Shipment Date = Requested Shipment Date = 4/2/2021 for the Job Planning Line
        OrderPromisingLine.TestField("Earliest Shipment Date", JobPlanningLine."Requested Delivery Date");
        OrderPromisingLine.TestField("Requested Shipment Date", JobPlanningLine."Requested Delivery Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CTPJobDoNotDeleteLinesInRequisitionWorksheet()
    var
        Item: Record Item;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        OrderPromisingLine: Record "Order Promising Line";
        RequisitionLine: Record "Requisition Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
        LocationCode: Code[10];
        BaseQty: Integer;
    begin
        // [FEATURE] [Capable to Promise] [Job Planning] [Requisition Worksheet]
        // [SCENARIO 453491] Requisition Worksheet should not be deleted after running Capable to Promise on Job Planning Line
        Initialize();
        LocationCode := CreateLocationCode();
        BaseQty := LibraryRandom.RandInt(10);

        CreateItemWithReorderPoint(
          Item, Item."Reordering Policy"::"Maximum Qty.", Item."Replenishment System"::Purchase,
          LibraryRandom.RandInt(10), LibraryRandom.RandIntInRange(20, 40));

        // [GIVEN] Calculate Requsition Plan for this item
        Item.SetRange("No.", Item."No.");
        LibraryPlanning.CalcRequisitionPlanForReqWksh(Item, WorkDate(), WorkDate());
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();

        // [GIVEN] Create Job Planning Line
        CreateJobWithJobPlanningLine(Job, JobPlanningLine, CalcDate('<1W>', WorkDate()), Item."No.", LocationCode, BaseQty);

        // [WHEN] Calculate Capable to Promise for the Job Planning Line
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, Job);
        AvailabilityManagement.CalcCapableToPromise(OrderPromisingLine, Job."No.");

        // [THEN] Check Requsition Line is not deleted
        Assert.RecordIsNotEmpty(RequisitionLine);
    end;

    local procedure CreateItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateItemWithReorderPoint(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System"; ReorderPoint: Decimal; MaximumInventory: Decimal)
    begin
        CreateItem(Item, ReorderingPolicy, ReplenishmentSystem);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Modify(true);
    end;

    [Test]
    [HandlerFunctions('SalesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ATPEarliestShipDateEqualExpectedReceiptDateWhenSpecialOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OrderPromisingLine: Record "Order Promising Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
    begin
        // [FEATURE] [Available to Promise] [Earliest Shipment Date] [Special Order]
        // [SCENARIO 320770] When Special Order pair exists, then ATP shows Earliest Shipment Date = Expected Receipt Date
        Initialize();

        // [GIVEN] Special Order Sales Order with <blank> Requested Delivery Date
        CreateSpecialOrderSalesOrder(
          SalesHeader, SalesLine, WorkDate(), 0D, LibraryInventory.CreateItemNo(), CreateLocationCode(), LibraryRandom.RandInt(10));

        // [GIVEN] Special Order Purchase Order for the Sales Order with Expected Receipt Date = 10/1/2021
        CreateSpecialOrderPurchaseOrderForSalesOrder(PurchaseLine, SalesHeader."Sell-to Customer No.", CalcDate('<1W>', WorkDate()));

        // [GIVEN] Purchase Order with similar Purchase Line and with Expected Receipt Date = 1/1/2021
        CreatePurchaseOrder(PurchaseHeader, WorkDate(), PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, SalesHeader);

        // [WHEN] Calculate Available to Promise for the Sales Line
        AvailabilityManagement.CalcAvailableToPromise(OrderPromisingLine);

        // [THEN] Order Promising Line has Earliest Shipment Date = 10/1/2021
        OrderPromisingLine.TestField("Earliest Shipment Date", PurchaseLine."Expected Receipt Date");
    end;

    [Test]
    [HandlerFunctions('SalesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ATPEarliestShipDateWhenSpecialOrderWithRequestedDeliveryDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        OrderPromisingLine: Record "Order Promising Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
    begin
        // [FEATURE] [Available to Promise] [Earliest Shipment Date] [Special Order]
        // [SCENARIO 320770] Requested Delivery Date in Sales Special Order overrides Expected Receipt Date
        Initialize();

        // [GIVEN] Special Order Sales Order with Requested Delivery Date = 20/1/2021
        CreateSpecialOrderSalesOrder(
          SalesHeader, SalesLine, WorkDate(), CalcDate('<2W>', WorkDate()), LibraryInventory.CreateItemNo(), CreateLocationCode(),
          LibraryRandom.RandInt(10));

        // [GIVEN] Special Order Purchase Order for the Sales Order with Expected Receipt Date = 10/1/2021
        CreateSpecialOrderPurchaseOrderForSalesOrder(PurchaseLine, SalesHeader."Sell-to Customer No.", CalcDate('<1W>', WorkDate()));
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, SalesHeader);

        // [WHEN] Calculate Available to Promise for the Sales Line
        AvailabilityManagement.CalcAvailableToPromise(OrderPromisingLine);

        // [THEN] Order Promising Line has Earliest Shipment Date = 20/1/2021
        OrderPromisingLine.TestField("Earliest Shipment Date", SalesLine."Planned Shipment Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATPEarliestShipDateBlankWhenSpecialOrderNotLinked()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        OrderPromisingLine: Record "Order Promising Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
    begin
        // [FEATURE] [Available to Promise] [Earliest Shipment Date] [Special Order]
        // [SCENARIO 320770] When Special Order Sales is not linked to Purchase, then ATP shows <blank> Earliest Shipment Date
        Initialize();

        // [GIVEN] Special Order Sales Order
        CreateSpecialOrderSalesOrder(
          SalesHeader, SalesLine, WorkDate(), CalcDate('<2W>', WorkDate()), LibraryInventory.CreateItemNo(), CreateLocationCode(),
          LibraryRandom.RandInt(10));

        // [GIVEN] Purchase Order with same Item, Location, Qunatity and with Expected Receipt Date = 1/1/2021
        CreatePurchaseOrder(PurchaseHeader, WorkDate(), SalesLine."No.", SalesLine."Location Code", SalesLine.Quantity);
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, SalesHeader);

        // [WHEN] Calculate Available to Promise for the Sales Line
        AvailabilityManagement.CalcAvailableToPromise(OrderPromisingLine);

        // [THEN] Order Promising Line has <blank> Earliest Shipment Date
        OrderPromisingLine.TestField("Earliest Shipment Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure ShipmentDateOnReservEntriesNotUpdatedBeforeAccept()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
        ReservationEntry: Record "Reservation Entry";
        AvailabilityManagement: Codeunit AvailabilityManagement;
        Qty: Decimal;
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 395270] Shipment Date on reservation entries is not updated when Available to Promise is calculated but not accepted yet.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Post inventory for 1 pc.
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", '', Qty);

        // [GIVEN] Sales order for 2 pcs, shipment date = WORKDATE.
        // [GIVEN] Reserve 1 pc from the inventory.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 2 * Qty, '', WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Purchase order for 1 pc, receipt date = WorkDate() + 1 week.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', LibraryRandom.RandDate(30));

        // [WHEN] Calculate Available to Promise for the sales line.
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, SalesHeader);
        AvailabilityManagement.CalcAvailableToPromise(OrderPromisingLine);

        // [THEN] Shipment date on reservation entries for the sales line remains WORKDATE.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", true);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Shipment Date", WorkDate());
    end;

    [Test]
    procedure CapableToPromiseForSalesOrderWithTwoLinesSameItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
        Qty: Decimal;
        EarliestShipmentDate: Date;
    begin
        // [FEATURE] [Capable to Promise]
        // [SCENARIO 409705] Capable to Promise for sales order with two same item lines.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        CreateItemWithLeadTimeCalculation(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);

        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, SalesHeader);
        AvailabilityManagement.CalcCapableToPromise(OrderPromisingLine, SalesHeader."No.");

        EarliestShipmentDate := OrderPromisingLine."Earliest Shipment Date";
        OrderPromisingLine.SetRange("Earliest Shipment Date", EarliestShipmentDate);
        Assert.RecordCount(OrderPromisingLine, 2);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesCTPModalPageHandler')]
    procedure CancelingReservationForSalesLineOnClosingCTPWithoutAccepting()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        LotNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Capable to Promise] [Reservation] [Item Tracking]
        // [SCENARIO 417611] Cancel reservation for sales line with an item set up for Reserve = "Never" when closing Capable to Promise page without accepting dates.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Lot-tracked item set up for Reserve = "Never".
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate(Reserve, Item.Reserve::Never);
        Item.Modify(true);

        // [GIVEN] Post 20 pcs of the item to inventory, assign lot no. "L".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Qty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order for 40 pcs, select 20 pcs with lot "L" in item tracking.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 2 * Qty, '', WorkDate());
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNo, Qty);

        // [WHEN] Open Order Promising page, calculate "Capable to Promise" and close the page without accepting dates.
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesHeader."Document Type", SalesHeader."No.");
        SalesOrder.OrderPromising.Invoke();

        // [THEN] The sales line has Reserve = "Never" and Reserved Quantity = 0.
        SalesLine.Find();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", 0);
        SalesLine.TestField(Reserve, SalesLine.Reserve::Never);

        // [THEN] The item tracking for the sales line is in place.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", true);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Quantity (Base)", -Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,ServiceLinesModalPageHandler,OrderPromisingLinesCTPModalPageHandler')]
    procedure CancelingReservationForServiceLineOnClosingCTPWithoutAccepting()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        LotNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Service] [Capable to Promise] [Reservation] [Item Tracking]
        // [SCENARIO 417611] Cancel reservation for service line with an item set up for Reserve = "Never" when closing Capable to Promise page without accepting dates.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Lot-tracked item set up for Reserve = "Never".
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate(Reserve, Item.Reserve::Never);
        Item.Modify(true);

        // [GIVEN] Post 20 pcs of the item to inventory, assign lot no. "L".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Qty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Service order for 40 pcs, select 20 pcs of lot "L" in item tracking.
        CreateServiceOrder(ServiceHeader, ServiceLine, WorkDate(), Item."No.", '', 2 * Qty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ServiceLine.OpenItemTrackingLines();

        // [GIVEN] Open Order Promising page for the service line, calculate "Capable to Promise" and close the page without accepting dates.
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoKey(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        // [THEN] The service line has Reserve = "Never" and Reserved Quantity = 0.
        ServiceLine.Find();
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", 0);
        ServiceLine.TestField(Reserve, ServiceLine.Reserve::Never);

        // [THEN] The item tracking for the service line is in place.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", true);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Quantity (Base)", -Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesCTPModalPageHandler')]
    procedure CancelingReservationForJobPlanningLineOnClosingCTPWithoutAccepting()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobCard: TestPage "Job Card";
        JobPlanningLines: TestPage "Job Planning Lines";
        Qty: Decimal;
    begin
        // [FEATURE] [Job] [Capable to Promise] [Reservation] [Item Tracking]
        // [SCENARIO 417611] Cancel reservation for job planning line with an item set up for Reserve = "Never" when closing Capable to Promise page without accepting dates.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Item set up for Reserve = "Never".
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Never);
        Item.Modify(true);

        // [GIVEN] Post 20 pcs of the item to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Job, job task, and job planning line for 40 pcs.
        CreateJobWithJobPlanningLine(Job, JobPlanningLine, WorkDate(), Item."No.", '', 2 * Qty);

        JobPlanningLines.Trap();
        JobCard.OpenEdit();
        JobCard.FILTER.SetFilter("No.", Job."No.");
        JobCard.JobPlanningLines.Invoke();

        // [GIVEN] Open Order Promising page for the job planning line, calculate "Capable to Promise" and close the page without accepting dates.
        JobPlanningLines.OrderPromising.Invoke();

        // [THEN] The job planning line has Reserve = "Never" and Reserved Quantity = 0.
        JobPlanningLine.Find();
        JobPlanningLine.CalcFields("Reserved Quantity");
        JobPlanningLine.TestField("Reserved Quantity", 0);
        JobPlanningLine.TestField(Reserve, JobPlanningLine.Reserve::Never);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesPageHandler,ConfirmHandler')]
    procedure RecreateRequisitionLineForOrderPromising()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 523712] Recreate Requisition Line for Order Promising when the sales line is recreated.
        Initialize();

        // [GIVEN] Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), WorkDate(), LibraryInventory.CreateItemNo(), '', 10);

        // [GIVEN] Run "Order Promising" from the Sales Line.
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, true);

        // [THEN] Requisition Line with Order Promising link is created for the Sales Line.
        RequisitionLine.SetRange("Order Promising ID", SalesLine."Document No.");
        RequisitionLine.SetRange("Order Promising Line ID", SalesLine."Line No.");
        Assert.RecordIsNotEmpty(RequisitionLine);

        // [WHEN] Recreate the Sales Line.
        SalesHeader.RecreateSalesLines(SalesHeader.FieldCaption("Sell-to Customer Name"));

        // [THEN] The requisition Line is recreated for the sales Line.
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        RequisitionLine.SetRange("Order Promising ID", SalesLine."Document No.");
        RequisitionLine.SetRange("Order Promising Line ID", SalesLine."Line No.");
        Assert.RecordIsNotEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CapableToPromiseUpdatesAvailabilityValueToZeroInOrderPromisingWhenUOMIsDiffinSOAndPO()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        Customer: Record Customer;
        UnitOfMeasure: array[2] of Record "Unit of Measure";
        ItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 548751] When Stan runs Capable to Promise action from Order Promising page then Availability field value is 
        // Updated to 0 if Purchase Order and Sales Order are created with different Unit of Measure Codes of same Item.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Unit of Measure Code [1].
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[1]);

        // [GIVEN] Create Item Unit of Measure [1] and Validate Qty. Rounding Precision.
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure[1], Item."No.", UnitOfMeasure[1].Code, 1);
        ItemUnitOfMeasure[1].Validate("Qty. Rounding Precision", 0);
        ItemUnitOfMeasure[1].Modify(true);

        // [GIVEN] Create Unit of Measure Code [2].
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[2]);

        // [GIVEN] Create Item Unit of Measure [2] and Validate Qty. Rounding Precision.
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure[2], Item."No.", UnitOfMeasure[2].Code, 1.158);
        ItemUnitOfMeasure[2].Validate("Qty. Rounding Precision", 0.00001);
        ItemUnitOfMeasure[2].Modify(true);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Purchase Header and Validate Posting Date and Order Date.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Posting Date", CalcDate('<CY-7M>', WorkDate()));
        PurchaseHeader.Validate("Order Date", CalcDate('<CY-7M>', WorkDate()));
        PurchaseHeader.Modify(true);

        // [GIVEN] Create a Purchase Line and Validate Unit of Measure Code, Planned Receipt Date and Expected Receipt Date.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 0.8724);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasure[1].Code);
        PurchaseLine.Validate("Planned Receipt Date", CalcDate('<CY-7M>', WorkDate()));
        PurchaseLine.Validate("Expected Receipt Date", CalcDate('<CY-7M>', WorkDate()));
        PurchaseLine.Modify(true);

        // [GIVEN] Create a Sales Header and Validate Posting Date, Order Date and Shipment Date.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Posting Date", CalcDate('<CY-6M+30D>', WorkDate()));
        SalesHeader.Validate("Order Date", CalcDate('<CY-6M+30D>', WorkDate()));
        SalesHeader.Validate("Shipment Date", CalcDate('<CY-5M>', WorkDate()));
        SalesHeader.Modify(true);

        // [GIVEN] Create a Sales Line and Validate Unit of Measure Code, Planned Delivery Date and Planned Shipment Date.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 16);
        SalesLine.Validate("Unit of Measure Code", UnitOfMeasure[2].Code);
        SalesLine.Validate("Planned Delivery Date", CalcDate('<CY-5M>', WorkDate()));
        SalesLine.Validate("Planned Shipment Date", CalcDate('<CY-5M>', WorkDate()));
        SalesLine.Modify(true);

        // [WHEN] Run Order Promising from the Sales Line.
        RunOrderPromisingFromSalesLine(SalesLine, OrderPromising::CapableToPromise, false);

        // [THEN] Availibility field value is equal 0 in Order Promising page. // OrderPromisingLinesModalPageHandler
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Order Promising II");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        ResetLocationSetup(LocationBlue.Code);
        ResetLocationSetup(LocationRed.Code);

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Order Promising II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        NoSeriesSetup();
        LocationSetup();
        ItemJournalSetup();

        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Order Promising II");
    end;

    local procedure ItemJournalSetup()
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", '');
        ItemJournalBatch.Modify(true);
    end;

    local procedure LocationSetup()
    begin
        CreateAndUpdateLocation(LocationBlue);
        CreateAndUpdateLocation(LocationRed);
        LibraryWarehouse.CreateInTransitLocation(LocationIntransit);
    end;

    local procedure NoSeriesSetup()
    begin
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure CreateLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchaseOrderAsReceiveAfterUpdateBothWarehouseHandlingTimeOnLocation(var Location: Record Location; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        UpdateInboundAndOutboundWarehouseHandlingTimeOnLocation(Location);
        CreatePurchaseOrder(PurchaseHeader, 0D, ItemNo, Location.Code, Quantity);  // Use 0D for Expected Receipt Date.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationIntransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
    end;

    local procedure CreateBaseCalendarWithBaseCalendarChange(var BaseCalendar: Record "Base Calendar"; NonWorkingDate: Date)
    var
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryInventory.CreateBaseCalendarChange(BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::" ", NonWorkingDate, 0);
    end;

    local procedure CreateCustomerWithBaseCalendar(): Code[20]
    var
        Customer: Record Customer;
        BaseCalendar: Record "Base Calendar";
        ShippingAgentServices: Record "Shipping Agent Services";
    begin
        CreateBaseCalendarWithBaseCalendarChange(BaseCalendar, WorkDate() + 1);
        CreateShippingAgentWithShippingAgentService(ShippingAgentServices, BaseCalendar.Code);
        CreateCustomerWithShippingAgentAndBaseCalendar(Customer, ShippingAgentServices, BaseCalendar.Code);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithShippingAgentAndBaseCalendar(var Customer: Record Customer; ShippingAgentServices: Record "Shipping Agent Services"; BaseCalendarCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipping Agent Code", ShippingAgentServices."Shipping Agent Code");
        Customer.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        Customer.Validate("Base Calendar Code", BaseCalendarCode);
        Customer.Modify(true);
    end;

    local procedure CreateItemWithLeadTimeCalculation(var Item: Record Item)
    var
        LeadTimeCalculation: DateFormula;
    begin
        LibraryInventory.CreateItem(Item);
        Evaluate(LeadTimeCalculation, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        Item.Validate("Lead Time Calculation", LeadTimeCalculation);
        Item.Modify(true);
    end;

    local procedure CreateManufacturingItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSpecialOrderPurchaseOrderForSalesOrder(var PurchaseLine: Record "Purchase Line"; CustNo: Code[20]; ExpectedReceiptDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Sell-to Customer No.", CustNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.GetSpecialOrder(PurchaseHeader);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; ExpectedReceiptDate: Date)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ExpectedReceiptDate: Date; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreatePurchaseHeader(PurchaseHeader, ExpectedReceiptDate);
        CreatePurchaseLine(PurchaseHeader, ItemNo, LocationCode, Quantity);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; PostingDate: Date; RequestedDeliveryDate: Date)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);  // Use Order Date as Posting Date.
        UpdateRequestedDeliveryDateOnSalesOrder(SalesHeader, RequestedDeliveryDate);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        if LocationCode <> '' then
            SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSpecialOrderSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; PostingDate: Date; RequestedDeliveryDate: Date; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        Purchasing: Record Purchasing;
    begin
        CreateSalesOrder(SalesHeader, SalesLine, PostingDate, RequestedDeliveryDate, ItemNo, LocationCode, Quantity);
        LibraryPurchase.CreateSpecialOrderPurchasingCode(Purchasing);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; PostingDate: Date; RequestedDeliveryDate: Date; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateSalesHeader(SalesHeader, PostingDate, RequestedDeliveryDate);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, LocationCode, Quantity);
    end;

    local procedure CreateSalesOrderWithShipmentDate(var SalesLine: Record "Sales Line"; ShipmentDate: Date; OutboundWarehouseHandlingTime: Integer; ShippingTime: Integer; CustomerNo: Code[20]; LocationCode: Code[10])
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        LibraryInventory.CreateItem(Item);
        CreateSalesOrderWithShipmentDate(SalesHeader, SalesLine, ShipmentDate, OutboundWarehouseHandlingTime, ShippingTime, CustomerNo, Item."No.", LocationCode);
    end;

    local procedure CreateSalesOrderWithShipmentDate(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShipmentDate: Date; OutboundWarehouseHandlingTime: Integer; ShippingTime: Integer; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    var
        OutboundWarehouseHandlingTimeFormula: DateFormula;
        ShippingTimeFormula: DateFormula;
    begin
        Evaluate(OutboundWarehouseHandlingTimeFormula, '<' + Format(OutboundWarehouseHandlingTime) + 'D>');
        Evaluate(ShippingTimeFormula, '<' + Format(ShippingTime) + 'D>');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Outbound Whse. Handling Time", OutboundWarehouseHandlingTimeFormula);
        SalesHeader.Validate("Shipping Time", ShippingTimeFormula);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, '', LibraryRandom.RandDec(100, 2));  // Use blank for Location.
    end;

    local procedure CreateShippingAgentWithShippingAgentService(var ShippingAgentServices: Record "Shipping Agent Services"; BaseCalendarCode: Code[10])
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingTime: DateFormula;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        ShippingAgentServices.Validate("Base Calendar Code", BaseCalendarCode);
        ShippingAgentServices.Modify(true);
    end;

    local procedure CreateSalesOrderWithTwoShipmentDates(var SalesHeader: Record "Sales Header"; var ItemNo: Code[20]; var Quantity: Decimal; ShipmentDate: array[2] of Date)
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";
        Quantity := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);

        // Purchase item to inventory with Blank location code
        CreateAndPostItemJournalLine(Item."No.", '', Quantity);

        // Create Sales Order with two lines for same item and quantity but different shipment dates
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        for i := 1 to ArrayLen(ShipmentDate) do
            LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ShipmentDate[i], Quantity);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; RequestedDeliveryDate: Date; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        Clear(ServiceHeader);
        Clear(ServiceLine);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, Qty);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate("Requested Delivery Date", RequestedDeliveryDate);
        ServiceLine.Modify(true);
    end;

    local procedure CreateJobWithJobPlanningLine(var Job: Record Job; var JobPlanningLine: Record "Job Planning Line"; RequestedDeliveryDate: Date; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate("Requested Delivery Date", RequestedDeliveryDate);
        JobPlanningLine.Validate(Quantity, Qty);
        JobPlanningLine.Validate("Remaining Qty.", Qty);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateItemCritical(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Critical, true);
        Item.Modify();
    end;

    local procedure FetchItemAvailabilityCalculationEarliestAvailDate(ItemCheckAvail: Codeunit "Item-Check Avail."): Date
    var
        ItemNo: Code[20];
        UoMCode: Code[10];
        InventoryQty: Decimal;
        GrossReq: Decimal;
        ReservedReq: Decimal;
        ShedRcpt: Decimal;
        ReservedRcpt: Decimal;
        CurrentQty: Decimal;
        CurrentReservedQty: Decimal;
        TotalQty: Decimal;
        EarliestAvailDate: Date;
    begin
        ItemCheckAvail.FetchCalculation(
          ItemNo, UoMCode, InventoryQty, GrossReq, ReservedReq, ShedRcpt, ReservedRcpt, CurrentQty, CurrentReservedQty, TotalQty,
          EarliestAvailDate);

        exit(EarliestAvailDate);
    end;

    local procedure FindSalesLineByShipmentDate(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ShipmentDate: Date)
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Shipment Date", ShipmentDate);
        SalesLine.FindFirst();
    end;

    local procedure GetDateOutsideOfAvailabilityTimeBucket(AvailabilityDate: Date): Date
    var
        CompanyInformation: Record "Company Information";
        AvailableToPromise: Codeunit "Available to Promise";
    begin
        CompanyInformation.Get();
        exit(AvailableToPromise.GetPeriodEndingDate(AvailabilityDate, CompanyInformation."Check-Avail. Time Bucket") + 1);
    end;

    local procedure GetDefaultSafetyLeadTime() DefaultSafetyLeadTime: Code[10]
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        DefaultSafetyLeadTime := Format(InventorySetup."Default Safety Lead Time");
    end;

    local procedure GetOffsetTime() OffsetTime: Code[10]
    var
        OrderPromisingSetup: Record "Order Promising Setup";
    begin
        OrderPromisingSetup.Get();
        OffsetTime := Format(OrderPromisingSetup."Offset (Time)");
    end;

    local procedure GetEarliestDeliveryDate(Item: Record Item; LocationCode: Code[10]; UseBaseCalendar: Boolean) Result: Date
    var
        Location: Record Location;
    begin
        Result := CalcDate('<' + Format(Item."Lead Time Calculation") + '>', WorkDate());
        Result := CalcDate('<' + Format(GetDefaultSafetyLeadTime()) + '>', Result);
        Result := CalcDate('<' + Format(GetOffsetTime()) + '>', Result);

        if LocationCode <> '' then begin
            Location.Get(LocationCode);
            Result := CalcDate('<' + Format(Location."Inbound Whse. Handling Time") + '>', Result);
            Result := CalcDate('<' + Format(Location."Outbound Whse. Handling Time") + '>', Result);
        end;

        if UseBaseCalendar then
            Result := CalcDate('<1D>', Result);
    end;

    local procedure VerifySalesLineDetails(var SalesOrder: TestPage "Sales Order"; DocumentNo: Code[20]; ItemNo: Code[20]; ShipmentDate: Date; ItemAvailability: Decimal; AvailableInventory: Decimal)
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", DocumentNo);
        SalesOrder.SalesLines.FILTER.SetFilter("No.", ItemNo);
        SalesOrder.SalesLines.FILTER.SetFilter("Shipment Date", Format(ShipmentDate));
        VerifySalesLineFactBox(SalesOrder, ItemNo, ItemAvailability, AvailableInventory);
    end;

    local procedure RunOrderPromisingFromSalesHeader(SalesHeader: Record "Sales Header"; OrderPromisingValue: Option; Accept: Boolean)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        LibraryVariableStorage.Enqueue(OrderPromisingValue);
        LibraryVariableStorage.Enqueue(Accept);
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.OrderPromising.Invoke();
    end;

    local procedure RunOrderPromisingFromSalesLine(OrderSalesLine: Record "Sales Line"; OrderPromisingValue: Option; Accept: Boolean)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        LibraryVariableStorage.Enqueue(OrderPromisingValue);  // Enqueue for OrderPromisingLinesPageHandler.
        LibraryVariableStorage.Enqueue(Accept);  // Enqueue for OrderPromisingLinesPageHandler.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", OrderSalesLine."Document No.");
        SalesOrder.SalesLines.GotoRecord(OrderSalesLine);
        SalesOrder.SalesLines.OrderPromising.Invoke();
    end;

    local procedure UpdateBaseCalendarOnLocation(var Location: Record Location; NonWorkingDate: Date)
    var
        BaseCalendar: Record "Base Calendar";
    begin
        CreateBaseCalendarWithBaseCalendarChange(BaseCalendar, NonWorkingDate);
        Location.Validate("Base Calendar Code", BaseCalendar.Code);
        Location.Modify(true);
    end;

    local procedure UpdateBaseCalendarOnCompanyInformation(NewBaseCalendarCode: Code[10]) OldBaseCalendarCode: Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        OldBaseCalendarCode := CompanyInformation."Base Calendar Code";
        CompanyInformation.Validate("Base Calendar Code", NewBaseCalendarCode);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateCheckAvailPeriodCalculation(CheckAvailPeriodFormula: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        Evaluate(CompanyInformation."Check-Avail. Period Calc.", CheckAvailPeriodFormula);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateInboundAndOutboundWarehouseHandlingTimeOnLocation(var Location: Record Location)
    begin
        UpdateInboundWarehouseHandlingTimeOnLocation(Location);
        UpdateOutboundWarehouseHandlingTimeOnLocation(Location);
    end;

    local procedure UpdateInboundWarehouseHandlingTimeOnLocation(var Location: Record Location)
    var
        InboundWarehouseHandlingTime: DateFormula;
    begin
        Evaluate(InboundWarehouseHandlingTime, '<' + Format(LibraryRandom.RandInt(5) + 10) + 'D>');  // Value required for test.
        Location.Validate("Inbound Whse. Handling Time", InboundWarehouseHandlingTime);
        Location.Modify(true);
    end;

    local procedure UpdateOutboundWarehouseHandlingTimeOnLocation(var Location: Record Location)
    var
        OutboundWarehouseHandlingTime: DateFormula;
    begin
        Evaluate(OutboundWarehouseHandlingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        Location.Validate("Outbound Whse. Handling Time", OutboundWarehouseHandlingTime);
        Location.Modify(true);
    end;

    local procedure UpdateRequestedDeliveryDateOnSalesOrder(var SalesHeader: Record "Sales Header"; RequestedDeliveryDate: Date)
    begin
        SalesHeader.Validate("Requested Delivery Date", RequestedDeliveryDate);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSKUReplenishmentSystemWithTransfer(var SKU: Record "Stockkeeping Unit"; TransferFromCode: Code[10])
    begin
        SKU.Validate("Replenishment System", SKU."Replenishment System"::Transfer);
        SKU.Validate("Transfer-from Code", TransferFromCode);
        SKU.Modify();
    end;

    local procedure UpdatePlannedOrderNosOnMfgSetup(NoSeriesCode: Code[20])
    var
        MfgSetup: Record "Manufacturing Setup";
    begin
        MfgSetup.Get();
        MfgSetup.Validate("Planned Order Nos.", NoSeriesCode);
        MfgSetup.Modify(true);
    end;

    local procedure ResetLocationSetup(LocationCode: Code[10])
    var
        Location: Record Location;
        WhseHandlingTime: DateFormula;
    begin
        if LocationCode = '' then
            exit;
        Location.Get(LocationCode);
        Evaluate(WhseHandlingTime, '');
        Location.Validate("Outbound Whse. Handling Time", WhseHandlingTime);
        Location.Validate("Inbound Whse. Handling Time", WhseHandlingTime);
        Location.Validate("Base Calendar Code", '');
        Location.Modify(true);
    end;

    local procedure VerifyOrderPromisingLine(PlannedDeliveryDate: Date; OriginalShipmentDate: Date; Quantity: Decimal)
    begin
        Assert.AreEqual(PlannedDeliveryDate, LibraryVariableStorage.DequeueDate(), PlannedDeliveryDateErr);
        Assert.AreEqual(OriginalShipmentDate, LibraryVariableStorage.DequeueDate(), OriginalShipmentDateErr);
        LibraryVariableStorage.DequeueDate();
        Assert.AreEqual(Quantity, LibraryVariableStorage.DequeueDecimal(), QuantityErr);
    end;

    local procedure VerifyRequisitionLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; DueDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Due Date", DueDate);
    end;

    local procedure VerifyRefOnRequisitionLine(NoSeriesCode: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        RefOrderNo: Code[20];
        ReqLineCount: Integer;
        i: Integer;
    begin
        RequisitionLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::"Prod. Order");
        RequisitionLine.SetRange("Ref. Order Status", RequisitionLine."Ref. Order Status"::Planned);
        RequisitionLine.SetRange("No. Series", NoSeriesCode);
        ReqLineCount := RequisitionLine.Count;

        RequisitionLine.Find('-');
        RefOrderNo := RequisitionLine."Ref. Order No.";
        for i := 1 to ReqLineCount - 1 do begin
            RequisitionLine.Next();
            RefOrderNo := IncStr(RefOrderNo);
            RequisitionLine.TestField("Ref. Order No.", RefOrderNo);
        end;
    end;

    local procedure VerifySalesLine(SalesLine: Record "Sales Line"; PlannedDeliveryDate: Date; PlannedShipmentDate: Date; ShipmentDate: Date)
    begin
        SalesLine.Find();
        SalesLine.TestField("Shipment Date", ShipmentDate);
        SalesLine.TestField("Planned Shipment Date", PlannedShipmentDate);
        SalesLine.TestField("Planned Delivery Date", PlannedDeliveryDate);
    end;

    local procedure VerifySalesLineFactBox(SalesOrder: TestPage "Sales Order"; ItemNo: Code[20]; Availability: Decimal; AvailableInventory: Decimal)
    begin
        SalesOrder.Control1906127307.ItemNo.AssertEquals(ItemNo);
        SalesOrder.Control1906127307."Item Availability".AssertEquals(Availability);
        SalesOrder.Control1906127307."Available Inventory".AssertEquals(AvailableInventory);
        SalesOrder.Close();
    end;

    local procedure VerifyEarliestShipmentDate(EarliestShipmentDate: Date)
    begin
        LibraryVariableStorage.DequeueDate();
        LibraryVariableStorage.DequeueDate();
        Assert.AreEqual(EarliestShipmentDate, LibraryVariableStorage.DequeueDate(), EarliestShipmentDateErr);
        LibraryVariableStorage.DequeueDecimal();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderPromisingLinesPageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    var
        Accept: Boolean;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            OrderPromising::CapableToPromise:
                OrderPromisingLines.CapableToPromise.Invoke();
            OrderPromising::AvailableToPromise:
                OrderPromisingLines.AvailableToPromise.Invoke();
        end;
        Accept := LibraryVariableStorage.DequeueBoolean();

        OrderPromisingLines.First();
        LibraryVariableStorage.Enqueue(OrderPromisingLines."Planned Delivery Date".AsDate());
        LibraryVariableStorage.Enqueue(OrderPromisingLines."Original Shipment Date".AsDate());
        LibraryVariableStorage.Enqueue(OrderPromisingLines."Earliest Shipment Date".AsDate());
        LibraryVariableStorage.Enqueue(OrderPromisingLines.Quantity.AsDecimal());

        if Accept then
            OrderPromisingLines.AcceptButton.Invoke()
        else
            OrderPromisingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure OrderPromisingLinesCTPModalPageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.CapableToPromise.Invoke();
        OrderPromisingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ServiceLinesModalPageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines."Order &Promising".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListModalPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure OrderPromisingLinesModalPageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.CapableToPromise.Invoke();
        OrderPromisingLines.First();
        OrderPromisingLines.CalcAvailability.AssertEquals(0);
        OrderPromisingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

