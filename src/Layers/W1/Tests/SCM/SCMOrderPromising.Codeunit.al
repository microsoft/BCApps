codeunit 137044 "SCM Order Promising"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Availability] [Available to Promise] [SCM]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LocationCode: array[4] of Code[10];
        isInitialized: Boolean;
        ErrDateMustBeSame: Label 'Date Must Be Same.';
        ItemNo: Code[20];
        WrongNoOfAvailNotificationsRaisedErr: Label 'Wrong number of availability notifications is raised.';

    [Test]
    [Scope('OnPrem')]
    procedure EqualOrderPromising()
    begin
        // Creating Order Promising Document where Supply and Demand is equal.
        OrderPromising(0, false);  // Value Important For test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LessOrderPromising()
    begin
        // Creating Order Promising Document where Demand is less than the supply.
        OrderPromising(LibraryRandom.RandDec(100, 2), false);  // Value Important For test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GreatorOrderPromising()
    begin
        // Creating Order Promising Document where Demand is Greater than the supply.
        OrderPromising(-LibraryRandom.RandDec(100, 2) + 500, true);  // Value Important For test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookAheadSinglePurchOrder()
    begin
        // Create One Demand and One Supply Document.Run Available to Promise
        // Verify the Earliest Shipment date in Order Promising Table.
        LookAheadSetup(1, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookAhdTwoPurchOneSalesOrder()
    begin
        // Create One Demand and Two Supply Document.Run Available to Promise
        // Verify the Earliest Shipment date in Order Promising Table.
        LookAheadSetup(1, 2, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookAhTwoPurchTwoSalesOrder()
    begin
        // Create Two Demand and Two Supply Document.Run Available to Promise
        // Verify the Earliest Shipment date in Order Promising Table.
        LookAheadSetup(2, 2, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookAhdThreePurchTwoSalesOrder()
    begin
        // Create Two Demand and Three Supply Document.Run Available to Promise
        // Verify the Earliest Shipment date in Order Promising Table.
        LookAheadSetup(2, 3, true);
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckAvailabilityAfterUpdateShipmentDate()
    var
        CompanyInformation: Record "Company Information";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Test to verify the Total Quantity is correct in Check Availability page after changing Shipment Date on Sales Order.

        // Setup: Enable Stockout Warning In Sales & Receivables Setup.
        // Create two Sales Orders on Workdate.
        Initialize();
        LibrarySales.SetStockoutWarning(true);
        LibraryERM.SetEnableDataCheck(false);

        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";

        Quantity := LibraryRandom.RandInt(10);
        Quantity2 := LibraryRandom.RandInt(10);
        CreateSalesOrder(SalesHeader, WorkDate(), '', Item."No.", Quantity);
        CreateSalesOrder(SalesHeader, WorkDate(), '', Item."No.", Quantity2);

        // Update the Shipment Date later than WorkDate() + CompanyInformation."Check-Avail. Period Calc." on the 2nd Sales Order.
        // To trigger Check Availablity warning we need to modify it on page.
        CompanyInformation.Get();
        LibraryVariableStorage.Enqueue(false);
        UpdateShipmentDateOnSalesOrderPage(
          SalesHeader."No.", CalcDate('<' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>',
            CalcDate(CompanyInformation."Check-Avail. Period Calc.", WorkDate())));

        // Exercise & Verify: Change the Shipment Date back to the original date for the 2nd Sales Order.
        // The Check Availablity warning message would pop up.
        // Verify the Total Quantity in Check Availablity page by CheckAvailabilityHandler.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(-(Quantity + Quantity2));
        UpdateShipmentDateOnSalesOrderPage(SalesHeader."No.", WorkDate());
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AvailabilityWarningRisesAfterSetShipmentDateBeforeReceiptDate()
    var
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesQuantity: Decimal;
    begin
        // [FEATURE] [Sales Order] [Shipment Date] [Availability]
        // [SCENARIO 379282] Availability warning should be raised if Shipment Date in Sales Line is changed from the date after the Purchase Receipt to the date preceding it.
        Initialize();
        UpdateCompanyInformationCalcBucket(0);
        LibrarySales.SetStockoutWarning(true);
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Purchase Order with Expected Receipt Date (i.e. Date1 = 05-05-15).
        // [GIVEN] Sales Order with Shipment Date which is later than Receipt Date in Purchase Order (i.e. Date2 = 10-05-15).
        CreatePurchAndSalesOrder(SalesHeader, SalesQuantity, LibraryRandom.RandDate(10));

        // [WHEN] Update Shipment Date in Sales Line to an earlier date (i.e. Date3 = 01-05-15).
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(-SalesQuantity);
        UpdateShipmentDateOnSalesOrderPage(SalesHeader."No.", LibraryRandom.RandDate(-10));

        // [THEN] There is a lack of Inventory on Date3. Availability warning is raised.
        // Verification is done in CheckAvailabilityHandler.
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AvailabilityWarningRisesAfterShipmentDateIsSetAndUpdatedBeforeReceiptDate()
    var
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesQuantity: Decimal;
    begin
        // [FEATURE] [Sales Order] [Shipment Date] [Availability]
        // [SCENARIO 379282] Availability warning should be raised when Shipment Date in Sales Line is set and updated with a date preceding Purchase Receipt Date.
        Initialize();
        UpdateCompanyInformationCalcBucket(0);
        LibrarySales.SetStockoutWarning(true);
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Purchase Order with Expected Receipt Date (i.e. Date1 = 05-05-15).
        // [GIVEN] Sales Order with Shipment Date preceding Receipt Date in Purchase Order (i.e. Date2 = 01-05-15). Lack of Inventory on Date2.
        CreatePurchAndSalesOrder(SalesHeader, SalesQuantity, LibraryRandom.RandDate(-10));

        // [WHEN] Update Shipment Date in Sales Line so it stays before Expected Receipt Date (i.e. Date3 = 02-05-15).
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(-SalesQuantity);
        UpdateShipmentDateOnSalesOrderPage(SalesHeader."No.", LibraryRandom.RandDate(-10));

        // [THEN] There is a lack of Inventory on Date3. Availability warnings is raised.
        // Verification is done in CheckAvailabilityHandler.
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentDateInFactBoxIsUpdatedWhenShipmentDateInSalesLineIsUpdated()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        NewShipmentDate: Date;
    begin
        // [FEATURE] [Sales] [Shipment Date] [UI]
        // [SCENARIO 379282] Shipment Date in Factbox should be updated when Shipment Date in Sales Line is updated.
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales Order with Shipment Date = Date1.
        CreateSalesOrder(SalesHeader, WorkDate(), '', Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Update Shipment Date in Sales Line with Date2.
        NewShipmentDate := LibraryRandom.RandDate(10);
        LibraryVariableStorage.Enqueue(false);
        UpdateShipmentDateOnSalesOrderPage(SalesHeader."No.", NewShipmentDate);

        // [THEN] Sales Line Factbox in Sales Header page is updated and shows Shipment Date = Date2.
        Assert.AreEqual(NewShipmentDate, GetShipmentDateFromFactBox(SalesHeader."No."), ErrDateMustBeSame);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPromisingExpectedRcptDateAfterRequestedDeliveryDate()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
    begin
        // [SCENARIO 376713] Calculate order promising when expected receipt date is later than requested delivery date
        Initialize();
        UpdateCompanyInformationCalcBucket(0);
        CreateItem(Item, Item."Replenishment System"::Purchase);
        Qty := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Sales order with Shipment Date = "D", Requested Delivery Date = "D" + 1
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", Qty, WorkDate() + 1, WorkDate());

        // [GIVEN] Purchase order with Expected Receipt Date = "D" + 2
        CreatePurchaseOrder(PurchaseHeader, WorkDate() + 2, '', Item."No.", Qty);

        // [WHEN] Calculate order promising line for the sales order
        CalcSalesHeaderAvailableToPromise(TempOrderPromisingLine, SalesHeader);

        // [THEN] Earliest shipment date = "D" + 2
        TempOrderPromisingLine.TestField("Earliest Shipment Date", PurchaseHeader."Expected Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPromisingShipmentDateAfterExpectedReceipt()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
    begin
        // [SCENARIO 376713] Calculate order promising when expected receipt date is later than requested delivery date and shipment date is after expected receipt
        Initialize();
        UpdateCompanyInformationCalcBucket(0);
        CreateItem(Item, Item."Replenishment System"::Purchase);
        Qty := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Sales order with Requested Delivery Date = "D", Shipment Date = "D" + 2
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", Qty, WorkDate(), WorkDate() + 2);

        // [GIVEN] Purchase order with Expected Receipt Date = "D" + 1
        CreatePurchaseOrder(PurchaseHeader, WorkDate() + 1, '', Item."No.", Qty);

        // [WHEN] Calculate order promising line for the sales order
        CalcSalesHeaderAvailableToPromise(TempOrderPromisingLine, SalesHeader);

        // [THEN] Earliest shipment date = "D" + 1
        TempOrderPromisingLine.TestField("Earliest Shipment Date", WorkDate() + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPromisingRequestedDeliveryDateIsNonWorking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        BaseCalendar: Record "Base Calendar";
        Qty: Decimal;
    begin
        // [FEATURE] [Base Calendar]
        // [SCENARIO 376713] Calculate order promising when requested delivery date is a non-working day
        Initialize();
        UpdateCompanyInformationCalcBucket(0);
        CreateItem(Item, Item."Replenishment System"::Purchase);
        Qty := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Sales order with Shipment Date = "D", Requested Delivery Date = "D"
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", Qty, WorkDate() + 1, WorkDate() + 1);

        // [GIVEN] Create base calendar and mark date "D" as non-working
        LibraryService.CreateBaseCalendar(BaseCalendar);
        CreateNonWorkingDayInBaseCalendar(BaseCalendar.Code, SalesHeader."Shipment Date");
        UpdateCompanyInfoBaseCalendarCode(BaseCalendar.Code);

        // [GIVEN] Purchase order with Expected Receipt Date = "D" - 1
        CreatePurchaseOrder(PurchaseHeader, WorkDate(), '', Item."No.", Qty);

        // [WHEN] Calculate order promising line for the sales order
        CalcSalesHeaderAvailableToPromise(TempOrderPromisingLine, SalesHeader);

        // [THEN] Earliest shipment date = "D" + 1 (next working day)
        TempOrderPromisingLine.TestField("Earliest Shipment Date", SalesHeader."Shipment Date" + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPromisingRequestedDeliveryDateBeforeExpectedReceiptNonWorking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        BaseCalendar: Record "Base Calendar";
        Qty: Decimal;
    begin
        // [FEATURE] [Base Calendar]
        // [SCENARIO 376713] Calculate order promising when requested delivery date is before expected receipt, and both dates are non-working
        Initialize();
        UpdateCompanyInformationCalcBucket(0);
        CreateItem(Item, Item."Replenishment System"::Purchase);
        Qty := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Sales order with Requested Delivery Date = "D"
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", Qty, WorkDate(), WorkDate());

        // [GIVEN] Create base calendar and mark "D" and "D" + 2 days as non-working
        LibraryService.CreateBaseCalendar(BaseCalendar);
        CreateNonWorkingDayInBaseCalendar(BaseCalendar.Code, SalesHeader."Shipment Date");
        CreateNonWorkingDayInBaseCalendar(BaseCalendar.Code, SalesHeader."Shipment Date" + 2);
        UpdateCompanyInfoBaseCalendarCode(BaseCalendar.Code);

        // [GIVEN] Create purchase order with Expected Receipt Date = "D" + 2
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Shipment Date" + 2, '', Item."No.", Qty);

        // [WHEN] Calculate order promising line for the sales order
        CalcSalesHeaderAvailableToPromise(TempOrderPromisingLine, SalesHeader);

        // [THEN] Earliest shipment date = "D" + 3 (next working day after the expected receipt)
        TempOrderPromisingLine.TestField("Earliest Shipment Date", PurchaseHeader."Expected Receipt Date" + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrdersWithRequestedDeliveryOutsidePromisingPeriodNotIncluded()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
    begin
        // [SCENARIO 376713] When calculating order promising for a period, sales orders with requested delivery date outside of this period are not included
        Initialize();
        UpdateCompanyInformationCalcBucket(0);
        CreateItem(Item, Item."Replenishment System"::Purchase);
        Qty := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Sales order: Quantity = "X", Requested Delivery Date = "D" + 3 days
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", Qty, WorkDate() + 3, WorkDate());
        // [GIVEN] Sales order: Quantity = "X", Requested Delivery Date = "D" days
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", Qty, WorkDate(), WorkDate());

        // [GIVEN] Create purchase order: Quantity = "X", Expected Receipt Date = "D" + 2
        CreatePurchaseOrder(PurchaseHeader, WorkDate() + 2, '', Item."No.", Qty);

        // [WHEN] Calculate order promising line for the second sales order (date = "D")
        CalcSalesHeaderAvailableToPromise(TempOrderPromisingLine, SalesHeader);

        // [THEN] "Earliest Shipment Date" = "D" + 2
        TempOrderPromisingLine.TestField("Earliest Shipment Date", PurchaseHeader."Expected Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrdersWithRequestedDeliveryWithinPromisingPeriodIncluded()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
    begin
        // [SCENARIO 376713] When calculating order promising for a period, all sales orders with requested delivery date within this period are included
        Initialize();
        UpdateCompanyInformationCalcBucket(0);
        CreateItem(Item, Item."Replenishment System"::Purchase);
        Qty := LibraryRandom.RandDec(100, 2);
        // [GIVEN] Sales order: Quantity = "X", Requested Delivery Date = "D"
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", Qty, WorkDate(), WorkDate());
        // [GIVEN] Sales order: Quantity = "X", Requested Delivery Date = "D" + 2 days
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", Qty, WorkDate() + 2, WorkDate());

        // [GIVEN] Create purchase order: Quantity = "X", Expected Receipt Date = "D" + 1
        CreatePurchaseOrder(PurchaseHeader, WorkDate() + 1, '', Item."No.", 1);

        // [WHEN] Calculate order promising line for the second sales order (date = "D" + 2)
        CalcSalesHeaderAvailableToPromise(TempOrderPromisingLine, SalesHeader);

        // [THEN] "Earliest Shipment Date" = 0D (order cannot be fulfilled)
        TempOrderPromisingLine.TestField("Earliest Shipment Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutboundWhseHandlingTimeConsideredWhenCalculatingOrderPromising()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        DeliveryDate: Date;
        Qty: Decimal;
    begin
        // [SCENARIO 376713] "Outbound Whse. Handling Time" and "Shipping Time" are considered when calculating order promising
        Initialize();
        UpdateCompanyInformationCalcBucket(0);
        CreateItem(Item, Item."Replenishment System"::Purchase);
        Qty := LibraryRandom.RandDec(100, 2);
        DeliveryDate := CalcDate('<1M>', WorkDate());

        // [GIVEN] Sales order with Requested Delivery Date = "D"
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", Qty, DeliveryDate, DeliveryDate + 1);

        // [GIVEN] Set "Outbound Whse. Handling Time" = "1D" and "Shipping Time" = "1W" in the sales order
        UpdateSalesLineShippingCalculation(SalesHeader."Document Type", SalesHeader."No.", '<1D>', '<1W>');

        // [GIVEN] Purchase order with "Expected Receipt Date" = "D" - 1
        CreatePurchaseOrder(PurchaseHeader, WorkDate(), '', Item."No.", Qty);

        // [WHEN] Calculate order promising line for the sales order
        CalcSalesHeaderAvailableToPromise(TempOrderPromisingLine, SalesHeader);

        // [THEN] "Earliest Shipment Date" = "D" - 1W - 1D
        TempOrderPromisingLine.TestField("Earliest Shipment Date", CalcDate('<-1W-1D>', DeliveryDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingTimeConsideredInOrderPromisingCalculation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        ShipmentDate: Date;
        Qty: Decimal;
    begin
        // [SCENARIO] "Shipping Time" is considered in order promising calculation
        Initialize();
        UpdateCompanyInformationCalcBucket(0);
        CreateItem(Item, Item."Replenishment System"::Purchase);
        Qty := LibraryRandom.RandDec(100, 2);
        ShipmentDate := WorkDate() + 10;

        // [GIVEN] Sales order with Requested Delivery Date = "D"
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", Qty, ShipmentDate, ShipmentDate);
        // [GIVEN] Set shipping time = "5D" on the sales order, planned shipment date becomes "D" - 5
        UpdateSalesLineShippingCalculation(SalesHeader."Document Type", SalesHeader."No.", '', '<5D>');

        // [GIVEN] Second sales order with Requested Delivery Date = "D" - 2
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", Qty, ShipmentDate - 2, ShipmentDate - 2);

        // [GIVEN] Purchase order with expected delivery date = "D" - 10
        CreatePurchaseOrder(PurchaseHeader, WorkDate(), '', Item."No.", Qty);

        // [WHEN] Calculate order promising line for the second sales order (date = "D" - 2)
        CalcSalesHeaderAvailableToPromise(TempOrderPromisingLine, SalesHeader);

        // [THEN] Earliest shipment date = 0D, order cannot be fulfilled, because planned shipment date in both orders is within the promising period
        TempOrderPromisingLine.TestField("Earliest Shipment Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotInsertOrderPromisingForItemTypeNonInventoriableFromSales()
    var
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        AvailabilityManagement: Codeunit AvailabilityManagement;
        InventoryItemNo: Code[20];
        ServiceItemNo: Code[20];
        NonStockItemNo: Code[20];
    begin
        // [SCENARIO 380031] Sales Lines with Items of non-inventoriable type aren't applicable to order promising functional.
        Initialize();

        // [GIVEN] Sales order with three items - one of of each Item type
        InventoryItemNo := LibraryInventory.CreateItemNo(); // Item.Type::Inventory
        ServiceItemNo := CreateItemTypeService();           // Item.Type::Service
        NonStockItemNo := CreateItemTypeNonStock();         // Item.Type::Non-Inventory
        CreateSalesOrderForThreeItems(SalesHeader, InventoryItemNo, ServiceItemNo, NonStockItemNo);

        // [WHEN] Transferring Sales Lines to Order Promising Lines
        AvailabilityManagement.SetSourceRecord(TempOrderPromisingLine, SalesHeader);

        // [THEN] Order Promising Lines contain Item of Type Inventory
        TempOrderPromisingLine.SetRange("Item No.", InventoryItemNo);
        Assert.RecordIsNotEmpty(TempOrderPromisingLine);

        // [THEN] Order Promising Lines don't contain Item of Type Service
        TempOrderPromisingLine.SetRange("Item No.", ServiceItemNo);
        Assert.RecordIsEmpty(TempOrderPromisingLine);

        // [THEN] Order Promising Lines don't contain Item of Type Non-inventory
        TempOrderPromisingLine.SetRange("Item No.", NonStockItemNo);
        Assert.RecordIsEmpty(TempOrderPromisingLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotInsertOrderPromisingForItemTypeNonInventoriableFromJob()
    var
        Job: Record Job;
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        AvailabilityManagement: Codeunit AvailabilityManagement;
        InventoryItemNo: Code[20];
        ServiceItemNo: Code[20];
        NonStockItemNo: Code[20];
    begin
        // [SCENARIO 380031] Job Planning Lines with items of non-inventoriable types aren't applicable to order promising functional.
        Initialize();

        // [GIVEN] Job with three items - one of each type
        InventoryItemNo := LibraryInventory.CreateItemNo(); // Item.Type::Inventory
        ServiceItemNo := CreateItemTypeService();           // Item.Type::Service
        NonStockItemNo := CreateItemTypeNonStock();         // Item.Type::Non-Inventory

        CreateJobForThreeItems(Job, InventoryItemNo, ServiceItemNo, NonStockItemNo);

        // [WHEN] Transferring Job Planning Lines to Order Promising Lines
        AvailabilityManagement.SetSourceRecord(TempOrderPromisingLine, Job);

        // [THEN] Order Promising Lines contain Item of Type Inventory
        TempOrderPromisingLine.SetRange("Item No.", InventoryItemNo);
        Assert.RecordIsNotEmpty(TempOrderPromisingLine);

        // [THEN] Order Promising Lines don't contain Item of Type Service
        TempOrderPromisingLine.SetRange("Item No.", ServiceItemNo);
        Assert.RecordIsEmpty(TempOrderPromisingLine);

        // [THEN] Order Promising Lines don't contain Item of Type Non-Inventory
        TempOrderPromisingLine.SetRange("Item No.", NonStockItemNo);
        Assert.RecordIsEmpty(TempOrderPromisingLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailWarningNotRaisedWhenSupplyExistsAfterShipmentDateFirstSet()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        NoOfNotificationsRaised: Integer;
    begin
        // [FEATURE] [Sales] [Order] [Shipment Date] [Check-Avail. Time Bucket]
        // [SCENARIO 202032] Availability warning SHOULD NOT be raised if a supply exists AFTER the shipment date that covers all demands by the end of the time bucket.
        Initialize();

        // [GIVEN] 2-week long Check.-Avail Calc Period and 1-day long Check-Avail. Time Bucket in Company Information.
        // [GIVEN] Item "I" with "X" units in stock on workdate.
        // [GIVEN] Sales line for "X" units of "I" on the last date of the calc. period (WorkDate() + 13 days).
        // [GIVEN] Purchase order for "Y" units of "I" ("Y" << "X") on WorkDate() + 1 day.
        CreateInventoryDemandAndSupply(
          ItemNo, SalesHeader, LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandInt(10), WorkDate() + 1);
        NoOfNotificationsRaised := LibraryVariableStorage.DequeueInteger();

        // [WHEN] Insert new sales line for "Z" units of "I" on WORKDATE. "Z" is covered with inventory "X", but leaves the future demands uncovered.
        CreateSalesLineWithShipmentDateAndTriggerAvailCheck(
          SalesLine, SalesHeader, ItemNo, WorkDate(), LibraryRandom.RandIntInRange(50, 100));

        // [THEN] Availability warning is not raised.
        VerifyNoOfRaisedNotifications(NoOfNotificationsRaised, 0);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AvailWarningNotRaisedWhenSupplyExistsAfterShipmentDateChangedFromLaterDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemNo: Code[20];
        NoOfNotificationsRaised: Integer;
    begin
        // [FEATURE] [Sales] [Order] [Shipment Date] [Check-Avail. Time Bucket]
        // [SCENARIO 202032] Availability warning SHOULD NOT be raised if a supply exists AFTER the shipment date that covers all demands by the end of the time bucket, and the shipment date is changed from the supply date to the date preceding it.
        Initialize();

        // [GIVEN] 2-week long Check.-Avail Calc Period and 1-day long Check-Avail. Time Bucket in Company Information.
        // [GIVEN] Item "I" with "X" units in stock on workdate.
        // [GIVEN] Sales line for "X" units of "I" on the last date of the calc. period (WorkDate() + 13 days).
        // [GIVEN] Purchase order for "Y" units of "I" ("Y" << "X") on WorkDate() + 1 day.
        CreateInventoryDemandAndSupply(
          ItemNo, SalesHeader, LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandInt(10), WorkDate() + 1);

        // [GIVEN] Sales line "SL" for "Z" units of "I" on WorkDate() + 1 day. Overall demanded qty. ("X" + "Z") is not covered with "X" + "Y".
        CreateSalesLineWithShipmentDateAndTriggerAvailCheck(
          SalesLine, SalesHeader, ItemNo, WorkDate() + 1, LibraryRandom.RandIntInRange(50, 100));

        // [WHEN] Change the date on "SL" to WORKDATE.
        NoOfNotificationsRaised := LibraryVariableStorage.DequeueInteger();
        UpdateShipmentDateOnSalesLineAndTriggerAvailCheck(SalesLine, WorkDate());

        // [THEN] Availability warning is not raised.
        VerifyNoOfRaisedNotifications(NoOfNotificationsRaised, 0);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AvailWarningNotRaisedWhenSupplyExistsAfterShipmentDateChangedFromEarlierDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        NoOfNotificationRaised: Integer;
    begin
        // [FEATURE] [Sales] [Order] [Shipment Date] [Check-Avail. Time Bucket]
        // [SCENARIO 202032] Availability warning SHOULD NOT be raised if a supply exists AFTER the shipment date that covers all demands by the end of the time bucket, and the shipment date is changed from the earlier date to the date preceding the supply
        Initialize();

        // [GIVEN] 2-week long Check.-Avail Calc Period and 1-day long Check-Avail. Time Bucket in Company Information.
        // [GIVEN] Item "I" with "X" units in stock on workdate.
        // [GIVEN] Sales line for "X" units of "I" on the last date of the calc. period (WorkDate() + 13 days).
        // [GIVEN] Purchase order for "Y" units of "I" ("Y" << "X") on WorkDate() + 1 day.
        CreateInventoryDemandAndSupply(
          ItemNo, SalesHeader, LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandInt(10), WorkDate() + 1);

        // [GIVEN] Sales line "SL" for "Z" units of "I" on WorkDate() - 1 day. Overall demanded qty. ("X" + "Z") is not covered with "X" + "Y".
        CreateSalesLineWithShipmentDateAndTriggerAvailCheck(
          SalesLine, SalesHeader, ItemNo, WorkDate() - 1, LibraryRandom.RandIntInRange(50, 100));

        // [WHEN] Change the date on "SL" to WORKDATE.
        NoOfNotificationRaised := LibraryVariableStorage.DequeueInteger();
        UpdateShipmentDateOnSalesLineAndTriggerAvailCheck(SalesLine, WorkDate());

        // [THEN] Availability warning is not raised.
        VerifyNoOfRaisedNotifications(NoOfNotificationRaised, 0);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AvailWarningRaisedWhenInsufficientSupplyExistsOnShipmentDateFirstSet()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemNo: Code[20];
        NoOfWarningsRaised: Integer;
    begin
        // [FEATURE] [Sales] [Order] [Shipment Date] [Check-Avail. Time Bucket]
        // [SCENARIO 202032] Availability warning SHOULD be raised if a supply exists ON the shipment date that covers all demands by the end of the time bucket, but does not cover future demands within the calc. period.
        Initialize();

        // [GIVEN] 2-week long Check.-Avail Calc Period and 1-day long Check-Avail. Time Bucket in Company Information.
        // [GIVEN] Item "I" with "X" units in stock on workdate.
        // [GIVEN] Sales line for "X" units of "I" on the last date of the calc. period (WorkDate() + 13 days).
        // [GIVEN] Purchase order for "Y" units of "I" ("Y" << "X") on WorkDate() + 1 day.
        CreateInventoryDemandAndSupply(
          ItemNo, SalesHeader, LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandInt(10), WorkDate() + 1);
        NoOfWarningsRaised := LibraryVariableStorage.DequeueInteger();

        // [WHEN] Insert new sales line for "Z" units of "I" on supply date (WorkDate() + 1 day). "Z" is covered with inventory "X", but leaves the future demands uncovered.
        CreateSalesLineWithShipmentDateAndTriggerAvailCheck(
          SalesLine, SalesHeader, ItemNo, WorkDate() + 1, LibraryRandom.RandIntInRange(50, 100));

        // [THEN] Availability warning is raised.
        VerifyNoOfRaisedNotifications(NoOfWarningsRaised, 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AvailWarningRaisedWhenInsufficientSupplyExistsOnShipmentDateChangedFromLaterDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemNo: Code[20];
        NoOfWarningsRaised: Integer;
    begin
        // [FEATURE] [Sales] [Order] [Shipment Date] [Check-Avail. Time Bucket]
        // [SCENARIO 202032] Avail. warning SHOULD be raised if supply exists ON the shipment date that covers all demands by the end of the time bucket, but not all demands within the calc. period. Shipment date changed from later date to the supply date.
        Initialize();

        // [GIVEN] 2-week long Check.-Avail Calc Period and 1-day long Check-Avail. Time Bucket in Company Information.
        // [GIVEN] Item "I" with "X" units in stock on workdate.
        // [GIVEN] Sales line for "X" units of "I" on the last date of the calc. period (WorkDate() + 13 days).
        // [GIVEN] Purchase order for "Y" units of "I" ("Y" << "X") on WorkDate() + 1 day.
        CreateInventoryDemandAndSupply(
          ItemNo, SalesHeader, LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandInt(10), WorkDate() + 1);

        // [GIVEN] Sales line "SL" for "Z" units of "I" on WorkDate() + 2 days. Overall demanded qty. ("X" + "Z") is not covered with "X" + "Y".
        CreateSalesLineWithShipmentDateAndTriggerAvailCheck(
          SalesLine, SalesHeader, ItemNo, WorkDate() + 2, LibraryRandom.RandIntInRange(50, 100));

        // [WHEN] Change the date on "SL" to the supply date (WorkDate() + 1 day).
        NoOfWarningsRaised := LibraryVariableStorage.DequeueInteger();
        UpdateShipmentDateOnSalesLineAndTriggerAvailCheck(SalesLine, WorkDate() + 1);

        // [THEN] Availability warning is raised.
        VerifyNoOfRaisedNotifications(NoOfWarningsRaised, 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvailWarningRaisedWhenInsufficientSupplyExistsOnShipmentDateChangedFromEarlierDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemNo: Code[20];
        NoOfRaisedNotifications: Integer;
    begin
        // [FEATURE] [Sales] [Order] [Shipment Date] [Check-Avail. Time Bucket]
        // [SCENARIO 202032] Avail. warning SHOULD be raised if supply exists ON the shipment date that covers all demands by the end of the time bucket, but not all demands within the calc. period. Shipment date changed from earlier date to the supply dat
        Initialize();

        // [GIVEN] 2-week long Check.-Avail Calc Period and 1-day long Check-Avail. Time Bucket in Company Information.
        // [GIVEN] Item "I" with "X" units in stock on workdate.
        // [GIVEN] Sales line for "X" units of "I" on the last date of the calc. period (WorkDate() + 13 days).
        // [GIVEN] Purchase order for "Y" units of "I" ("Y" << "X") on WorkDate() + 1 day.
        CreateInventoryDemandAndSupply(
          ItemNo, SalesHeader, LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandInt(10), WorkDate() + 1);

        // [GIVEN] Sales line "SL" for "Z" units of "I" on WorkDate() - 1 day. Overall demanded qty. ("X" + "Z") is not covered with "X" + "Y".
        CreateSalesLineWithShipmentDateAndTriggerAvailCheck(
          SalesLine, SalesHeader, ItemNo, WorkDate() - 1, LibraryRandom.RandIntInRange(50, 100));

        // [WHEN] Change the date on "SL" to the supply date (WorkDate() + 1 day).
        NoOfRaisedNotifications := LibraryVariableStorage.DequeueInteger();
        UpdateShipmentDateOnSalesLineAndTriggerAvailCheck(SalesLine, WorkDate() + 1);

        // [THEN] Availability warning is raised.
        VerifyNoOfRaisedNotifications(NoOfRaisedNotifications, 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailWarningNotRaisedWhenSufficientSupplyExistsOnShipmentDateFirstSet()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        NoOfWarningsRaised: Integer;
    begin
        // [FEATURE] [Sales] [Order] [Shipment Date] [Check-Avail. Time Bucket]
        // [SCENARIO 202032] Availability warning SHOULD NOT be raised if a supply exists ON the shipment date that covers all demands within the calc. period.
        Initialize();

        // [GIVEN] 2-week long Check.-Avail Calc Period and 1-day long Check-Avail. Time Bucket in Company Information.
        // [GIVEN] Item "I" with "X" units in stock on workdate.
        // [GIVEN] Sales line for "X" units of "I" on the last date of the calc. period (WorkDate() + 13 days).
        // [GIVEN] Purchase order for "Y" units of "I" ("Y" > "X") on WorkDate() + 1 day.
        CreateInventoryDemandAndSupply(
          ItemNo, SalesHeader, LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandIntInRange(500, 1000), WorkDate() + 1);
        NoOfWarningsRaised := LibraryVariableStorage.DequeueInteger();

        // [WHEN] Insert new sales line for "Z" units of "I" on supply date (WorkDate() + 1 day). Overall demanded qty. ("X" + "Z") is covered with "X" + "Y".
        CreateSalesLineWithShipmentDateAndTriggerAvailCheck(
          SalesLine, SalesHeader, ItemNo, WorkDate() + 1, LibraryRandom.RandIntInRange(50, 100));

        // [THEN] Availability warning is not raised.
        VerifyNoOfRaisedNotifications(NoOfWarningsRaised, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailWarningNotRaisedWhenSufficientSupplyExistsOnShipmentDateChangedFromLaterDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        NoOfRaisedWarnings: Integer;
    begin
        // [FEATURE] [Sales] [Order] [Shipment Date] [Check-Avail. Time Bucket]
        // [SCENARIO 202032] Availability warning SHOULD NOT be raised if a supply exists ON the shipment date that covers all demands within the calc. period and the shipment date of one demand is changed from later date to the supply date.
        Initialize();

        // [GIVEN] 2-week long Check.-Avail Calc Period and 1-day long Check-Avail. Time Bucket in Company Information.
        // [GIVEN] Item "I" with "X" units in stock on workdate.
        // [GIVEN] Sales line for "X" units of "I" on the last date of the calc. period (WorkDate() + 13 days).
        // [GIVEN] Purchase order for "Y" units of "I" ("Y" > "X") on WorkDate() + 1 day.
        CreateInventoryDemandAndSupply(
          ItemNo, SalesHeader, LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandIntInRange(500, 1000), WorkDate() + 1);

        // [GIVEN] Sales line "SL" for "Z" units of "I" on WorkDate() + 2 days. Overall demanded qty. ("X" + "Z") is covered with "X" + "Y".
        CreateSalesLineWithShipmentDateAndTriggerAvailCheck(
          SalesLine, SalesHeader, ItemNo, WorkDate() + 2, LibraryRandom.RandIntInRange(50, 100));

        // [WHEN] Change the date on "SL" to the supply date (WorkDate() + 1 day).
        NoOfRaisedWarnings := LibraryVariableStorage.DequeueInteger();
        UpdateShipmentDateOnSalesLineAndTriggerAvailCheck(SalesLine, WorkDate() + 1);

        // [THEN] Availability warning is not raised.
        VerifyNoOfRaisedNotifications(NoOfRaisedWarnings, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AvailWarningNotRaisedWhenSufficientSupplyExistsOnShipmentDateChangedFromEarlierDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        NoOfWarningsRaised: Integer;
    begin
        // [FEATURE] [Sales] [Order] [Shipment Date] [Check-Avail. Time Bucket]
        // [SCENARIO 202032] Availability warning SHOULD NOT be raised if a supply exists ON the shipment date that covers all demands within the calc. period and the shipment date of one demand is changed from earlier date to the supply date.
        Initialize();

        // [GIVEN] 2-week long Check.-Avail Calc Period and 1-day long Check-Avail. Time Bucket in Company Information.
        // [GIVEN] Item "I" with "X" units in stock on workdate.
        // [GIVEN] Sales line for "X" units of "I" on the last date of the calc. period (WorkDate() + 13 days).
        // [GIVEN] Purchase order for "Y" units of "I" ("Y" > "X") on WorkDate() + 1 day.
        CreateInventoryDemandAndSupply(
          ItemNo, SalesHeader, LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandIntInRange(500, 1000), WorkDate() + 1);

        // [GIVEN] Sales line "SL" for "Z" units of "I" on WorkDate() - 1 day. Overall demanded qty. ("X" + "Z") is covered with "X" + "Y".
        CreateSalesLineWithShipmentDateAndTriggerAvailCheck(
          SalesLine, SalesHeader, ItemNo, WorkDate() - 1, LibraryRandom.RandIntInRange(50, 100));

        // [WHEN] Change the date on "SL" to the supply date (WorkDate() + 1 day).
        NoOfWarningsRaised := LibraryVariableStorage.DequeueInteger();
        UpdateShipmentDateOnSalesLineAndTriggerAvailCheck(SalesLine, WorkDate() + 1);

        // [THEN] Availability warning is not raised.
        VerifyNoOfRaisedNotifications(NoOfWarningsRaised, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailabilityWarningNotRaisedForBOMComponentAfterShipmentDateChangedToLaterDate()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        IsWarningRaised: Boolean;
    begin
        // [FEATURE] [Sales] [Order] [Shipment Date] [Assemble-to-Order]
        // [SCENARIO 234903] Availability warning for BOM component is not raised after shipment date of an assembled item is shifted to a later date.
        Initialize();

        // [GIVEN] Enable stockout warnings.
        LibraryAssembly.SetStockoutWarning(true);
        LibrarySales.SetStockoutWarning(true);

        // [GIVEN] Assembled item "I" with a component "C".
        CreateAssembleToOrderItemWithComponent(AsmItem, CompItem);

        // [GIVEN] 1 pc of component "C" is in stock on WorkDate(), 2 pcs are set to be purchased on WorkDate() + 1 month.
        // [GIVEN] Sales order for 2 pcs of assembled item "I" on WorkDate() + 2 months.
        // [GIVEN] The component "C" is now supplied by the inventory and the purchase.
        CreateSupplyForBOMComponentAndDemandForAssembledItem(
          AsmItem."No.", CompItem."No.", 1, 2, 2, WorkDate(), WorkDate() + 30, WorkDate() + 60);

        // [WHEN] Set "Shipment Date" on the sales line to a later date.
        SalesLine.SetRange("No.", AsmItem."No.");
        SalesLine.FindFirst();
        SalesLine."Shipment Date" := WorkDate() + 90;
        IsWarningRaised := ItemCheckAvail.SalesLineCheck(SalesLine);

        // [THEN] Assembly availability warning for component "C" is not raised.
        Assert.IsFalse(IsWarningRaised, 'Redundant assembly availability warning is raised.');
    end;

    [Test]
    [HandlerFunctions('SendAsmAvailNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AvailabilityWarningRaisedAfterDueDateOnLinkedAssemblyLineChangedFromLaterDate()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        // [FEATURE] [Sales] [Order] [Assemble-to-Order]
        // [SCENARIO 251877] Availability warning is raised on Assemble-to-Order line when you shift Due Date to an earlier date on which the component is lacking.
        Initialize();

        // [GIVEN] Enable stockout warnings.
        LibrarySales.SetStockoutWarning(true);
        LibraryAssembly.SetStockoutWarning(true);

        // [GIVEN] Assembled item "I" with a component "C".
        CreateAssembleToOrderItemWithComponent(AsmItem, CompItem);

        // [GIVEN] 2 pc of component "C" is in stock on WorkDate(), 1 pc is set to be purchased on WorkDate() + 10 days.
        // [GIVEN] Sales order "SO1" for 1 pc of assembled item "I" on WorkDate() + 20 days.
        CreateSupplyForBOMComponentAndDemandForAssembledItem(
          AsmItem."No.", CompItem."No.", 2, 1, 1, WorkDate(), WorkDate() + 20, WorkDate() + 10);

        // [GIVEN] Another sales order "SO2" for 2 pcs of assembled item "I" on WorkDate() + 30 days.
        CreateSalesOrder(SalesHeader, WorkDate() + 30, '', AsmItem."No.", 2);
        FindSalesline(SalesLine, SalesHeader, AsmItem."No.");

        // [GIVEN] Find Assembly Order linked to "SO2".
        LibraryAssembly.FindLinkedAssemblyOrder(
          AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        FindAssemblyLine(AssemblyLine, AssemblyHeader, CompItem."No.");

        // [WHEN] Set "Due Date" on the assembly line to the date earlier than the purchase date (e.g. WorkDate() + 15 days) and check the availability.
        AssemblyLine."Due Date" := WorkDate() + 15;
        ItemCheckAvail.AssemblyLineCheck(AssemblyLine);

        // [THEN] Availability notification for the component "C" is raised.
        Assert.AreEqual(
          CompItem."No.", LibraryVariableStorage.DequeueText(),
          'Availability notification for the component item is not raised');

        LibraryNotificationMgt.RecallNotificationsForRecord(AssemblyLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPromisingPlannedDeliveryDateDoesNotUpdateAssembly()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
        AssemblyHeader: Record "Assembly Header";
        AvailabilityManagement: Codeunit AvailabilityManagement;
        AsmStartingDate: Date;
    begin
        // [FEATURE] [Sales] [Assembly]
        // [SCENARIO 274185] Changing the planned delivery date in the order promising does not modify the starting date of the related assembly order

        // [GIVEN] Two items: "COMP" and "ASM". "COMP" is an assembly component of the "ASM" item
        CreateAssembleToOrderItemWithComponent(AsmItem, CompItem);

        // [GIVEN] Sales order for the item "ASM" with a linked assembly order (assemble-to-order), "Planned Delivery Date" is set to 25.01.2020
        CreateSalesOrder(SalesHeader, AdjustDateForDefaultSafetyLeadTime(WorkDate()), '', AsmItem."No.", LibraryRandom.RandInt(10));
        FindSalesline(SalesLine, SalesHeader, AsmItem."No.");
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine.Quantity);
        SalesLine.Modify(true);

        LibraryAssembly.FindLinkedAssemblyOrder(AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        AsmStartingDate := AssemblyHeader."Starting Date";

        // [WHEN] In the "Order Promising" window, set the "Planned Delivery Date" to 26.01.2020, do not accept the change
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, SalesHeader);
        OrderPromisingLine.Validate("Planned Delivery Date", SalesLine."Planned Delivery Date" + 1);

        // [THEN] "Starting Date" in the assembly order is 25.01.2020
        AssemblyHeader.Find();
        AssemblyHeader.TestField("Starting Date", AsmStartingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPromisingPlannedDeliveryDateAdjustedForNonWorkingDays()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
        BaseCalendar: Record "Base Calendar";
        AvailabilityManagement: Codeunit AvailabilityManagement;
    begin
        // [FEATURE] [Sales] [Base Calendar]
        // [SCENARIO 274185] "Planned Delivery Date" and "Earliest Shipment Date" in order promising are adjusted based on the active calendar when the the delivery date is set to a non-working day

        // [GIVEN] Sales order on 25.01.2020
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(SalesHeader, AdjustDateForDefaultSafetyLeadTime(WorkDate()), '', Item."No.", LibraryRandom.RandInt(10));

        FindSalesline(SalesLine, SalesHeader, Item."No.");

        // [GIVEN] 26.01.2020 is a non-working day
        LibraryService.CreateBaseCalendar(BaseCalendar);
        CreateNonWorkingDayInBaseCalendar(BaseCalendar.Code, SalesLine."Planned Delivery Date" + 1);
        UpdateCompanyInfoBaseCalendarCode(BaseCalendar.Code);

        // [WHEN] In the "Order Promising" window, set the "Planned Delivery Date" to 26.01.2020
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, SalesHeader);
        OrderPromisingLine.Validate("Planned Delivery Date", SalesLine."Planned Delivery Date" + 1);

        // [THEN] "Planned Delivery Date" and "Earliest Shipment Date" in the Order Promising are changed to 27.01.2020
        OrderPromisingLine.TestField("Planned Delivery Date", SalesLine."Planned Delivery Date" + 2);
        OrderPromisingLine.TestField("Earliest Shipment Date", SalesLine."Planned Delivery Date" + 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPromisingPlannedDeliveryDateDoesNotUpdateServiceReservation()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemJournalLine: Record "Item Journal Line";
        OrderPromisingLine: Record "Order Promising Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 274185] Changing the planned delivery date in the order promising does not modify the shipment date of service order reservation

        // [GIVEN] Service item linked to an inventory item
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo());
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Modify(true);

        // [GIVEN] Service order for the same service item on 25.01.2020
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Post item stock and reserve it for the service order
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ServiceItem."Item No.", '', '', ServiceLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryService.AutoReserveServiceLine(ServiceLine);

        // [WHEN] In the "Order Promising" window, set the "Planned Delivery Date" to 26.01.2020, do not accept the change
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, ServiceHeader);
        OrderPromisingLine.Validate("Planned Delivery Date", ServiceLine."Planned Delivery Date" + 1);

        // [THEN] "Shipment Date" in reservation entry is 25.01.2020
        VerifyReservEntryShipmentDate(DATABASE::"Service Line", Item."No.", ServiceLine."Planned Delivery Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPromisingPlannedDeliveryDateDoesNotUpdateJobReservation()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        OrderPromisingLine: Record "Order Promising Line";
        ItemJournalLine: Record "Item Journal Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
    begin
        // [FEATURE] [Job]
        // [SCENARIO 274185] Changing the planned delivery date in the order promising does not modify the shipment date of job planning reservation

        // [GIVEN] Item stock is reserved for a job planning line on 25.01.2020
        LibraryInventory.CreateItem(Item);
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLine(JobPlanningLine, JobTask, Item."No.", LibraryRandom.RandInt(10));

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', JobPlanningLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        JobPlanningLine.AutoReserve();

        // [WHEN] In the "Order Promising" window, set the "Planned Delivery Date" to 26.01.2020, do not accept the change
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, Job);
        OrderPromisingLine.Validate("Planned Delivery Date", JobPlanningLine."Planned Delivery Date" + 1);

        // [THEN] "Shipment Date" in reservation entry is 25.01.2020
        VerifyReservEntryShipmentDate(DATABASE::"Job Planning Line", Item."No.", JobPlanningLine."Planned Delivery Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UT_ReservedQtyOnProdOrderIsCalculatedAtAvailableToPromise()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        AvailableToPromise: Codeunit "Available to Promise";
        ExpectedQuantity: Integer;
    begin
        // [FEATURE] [UT] [Availability]
        // [SCENARIO 338140] Item."Reserved Qty. on Prod. Order" is calculated at COD5790.CalcAllItemFields function.
        Initialize();

        CreateItem(Item, Item."Replenishment System"::"Prod. Order");

        ExpectedQuantity := LibraryRandom.RandIntInRange(2, 4);
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", ExpectedQuantity, 0D, WorkDate() + 7);
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
          SalesHeader, ProductionOrder.Status::"Firm Planned", "Create Production Order Type"::ItemOrder);
        AvailableToPromise.CalcAvailableInventory(Item);

        Assert.AreEqual(
          ExpectedQuantity, Item."Reserved Qty. on Prod. Order", 'Expected "Reserved Qty. on Prod. Order" to match with ExpectedQuantity');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailToPromiseWhenRequestedShptDateBeforeShptDateOnSalesOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        SupplyDate: array[2] of Date;
        DemandDate: Date;
        Qty: Decimal;
    begin
        // [FEATURE] [Availability]
        // [SCENARIO 360654] Earliest shipment date calculation for sales order line having requested delivery date earlier than shipment date.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);
        DemandDate := WorkDate() + 10;
        SupplyDate[1] := WorkDate() + 20;
        SupplyDate[2] := WorkDate() + 40;

        LibraryInventory.CreateItem(Item);

        // [GIVEN] First purchase order for 20 pcs on 01/08/22 (DD/MM/YY).
        // [GIVEN] Second purchase order for 20 pcs on 01/10/22.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', SupplyDate[1]);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', SupplyDate[2]);

        // [GIVEN] Sales order for 40 pcs with Shipment Date = 01/10/22 and Requested Delivery Date = 01/07/22.
        CreateSalesOrderWithRequestedDeliveryDate(SalesHeader, Item."No.", 2 * Qty, DemandDate, SupplyDate[2]);

        // [WHEN] Calculate Available-to-Promise for the sales order.
        CalcSalesHeaderAvailableToPromise(TempOrderPromisingLine, SalesHeader);

        // [THEN] Earliest shipment date on the sales order is 01/10/22.
        TempOrderPromisingLine.TestField("Earliest Shipment Date", SupplyDate[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailToPromiseCalculationDoesNotIncludeFutureSuppliesWhenQtyIsAvailable()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        Qty: Decimal;
    begin
        // [FEATURE] [Availability]
        // [SCENARIO 364942] Available-to-Promise calculation does not include future supplies when quantity on the current date is available.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Three purchase orders - 20 pcs on 01/01, 10 pcs on 20/01, 10 pcs on 30/01 (DD/MM).
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", 2 * Qty, '', WorkDate());
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate() + 20);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate() + 40);

        // [GIVEN] Three sales orders - 10 pcs on 01/01, 10 pcs on 10/01, 10 pcs on 20/01
        CreateSalesOrder(SalesHeader, WorkDate(), '', Item."No.", Qty);
        CreateSalesOrder(SalesHeader, WorkDate() + 10, '', Item."No.", Qty);
        CreateSalesOrder(SalesHeader, WorkDate() + 20, '', Item."No.", Qty);

        // [WHEN] Calculate earliest shipment date for the third sales order.
        CalcSalesHeaderAvailableToPromise(TempOrderPromisingLine, SalesHeader);

        // [THEN] Earliest shipment date = 20/01. The supply on 30/01 is not considered.
        TempOrderPromisingLine.TestField("Earliest Shipment Date", WorkDate() + 20);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SendItemAvailNotificationHandler,RecallNotificationHandler')]
    procedure AvailWarningInSalesOrderForAlwaysReserveItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UT] [Reservation] [Sales] [Order]
        // [SCENARIO 396314] Show availability notification for always reserve item on sales line.
        Initialize();
        LibrarySales.SetStockoutWarning(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        LibraryVariableStorage.Enqueue('Automatic reservation is not possible');
        LibraryVariableStorage.Enqueue(false);

        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.Quantity.SetValue(1);

        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          SalesLine.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), true);

        SalesOrder.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SendItemAvailNotificationHandler,RecallNotificationHandler')]
    procedure AvailWarningInSalesBlanketOrderForAlwaysReserveItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        // [FEATURE] [UT] [Reservation] [Sales] [Blanket Order]
        // [SCENARIO 396314] Show availability notification for always reserve item when creating sales line from blanket order.
        Initialize();
        LibrarySales.SetStockoutWarning(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        LibraryVariableStorage.Enqueue('Full automatic reservation was not possible');
        LibraryVariableStorage.Enqueue(false);
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          SalesLine.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AssemblyAvailabilityModalPageHandler,SendAssemblyAvailabilityNotificationHandler')]
    procedure AvailWarningInAssemblyOrderForAlwaysReserveComponent()
    var
        CompItem: Record Item;
        AsmItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [UT] [Reservation] [Assembly] [Order]
        // [SCENARIO 396314] Show availability warning for always reserve item on assembly line.
        Initialize();
        LibraryAssembly.SetStockoutWarning(true);

        CreateAssembleToOrderItemWithComponent(AsmItem, CompItem);
        CompItem.Validate(Reserve, CompItem.Reserve::Always);
        CompItem.Modify(true);

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 1, AsmItem."No.", '', 1, '');

        Assert.AreEqual(CompItem."No.", LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(0, LibraryVariableStorage.DequeueDecimal(), '');

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SendItemAvailNotificationHandler,RecallNotificationHandler')]
    procedure AvailWarningInJobPlanningLineForAlwaysReserveItem()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [FEATURE] [UT] [Reservation] [Job Planning Line]
        // [SCENARIO 396314] Show availability notification for always reserve item on job planning line.
        Initialize();
        LibrarySales.SetStockoutWarning(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLine(JobPlanningLine, JobTask, Item."No.", 0);

        LibraryVariableStorage.Enqueue('Automatic reservation is not possible');
        LibraryVariableStorage.Enqueue(false);

        JobPlanningLines.OpenEdit();
        JobPlanningLines.FILTER.SetFilter("No.", Item."No.");
        JobPlanningLines.Quantity.SetValue(1);

        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          JobPlanningLine.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), true);

        JobPlanningLines.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceLinesModalPageHandler,ConfirmHandler,SendItemAvailNotificationHandler,RecallNotificationHandler')]
    procedure AvailWarningInServiceLineForAlwaysReserveItem()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [UT] [Reservation] [Service Line]
        // [SCENARIO 396314] Show availability notification for always reserve item on service line.
        Initialize();
        LibrarySales.SetStockoutWarning(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        LibraryService.CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo());

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue('Automatic reservation is not possible');
        LibraryVariableStorage.Enqueue(false);

        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", ServiceHeader."No.");
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        ServiceLine.SetRange("Service Item No.", ServiceItem."No.");
        ServiceLine.FindFirst();
        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          ServiceLine.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), true);

        ServiceOrder.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,ItemAvailabilityCheckHandler,RecallNotificationHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure AvailNotificationIsShownWithInventoryShortageWhenInventoryOfItemIsLowerThanQtyInSO()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 541881] Available Inventory in the Notification Shows the Inventory of Item and 
        // Inventory Shortage shows the difference between Inventory of Item and Quantity entered on Sales Order.
        Initialize();

        // [GIVEN] Setup: Enable Stockout Warning and Data Check.
        LibrarySales.SetStockoutWarning(true);
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Create an Item and Validate Reserve.
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        // [GIVEN] Save Item No. in a Variable.
        ItemNo := Item."No.";

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item."No.", '', LibraryRandom.RandIntInRange(15, 15));

        // [GIVEN] Create a Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [GIVEN] Create a Sales Line.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [GIVEN] Open Sales Order page and Validate Quantity.
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(16, 16));

        // [WHEN] Validate Quantity in Sales Order page.
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(17, 17));

        // [THEN] InventoryQty must be equal to Inventory of Item and TotalQuantity Must be equal to the
        // Difference of Inventory and Quantity of Sales Order in ItemAvailabilityCheckHandler.
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ShipOrReceiveTransferOrderStrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure EarliestShipmentDateIncorrectOnOrderPromising()
    var
        Item: Record Item;
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        TransferHeader: array[2] of Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemInventory: array[2] of Decimal;
    begin
        // [SCENARIO 549431] Check Earliest Shipment Date on Order Promising.
        Initialize();

        // [GIVEN] Created a Item and Locations.
        LibraryInventory.CreateItem(Item);
        CreateUpdateLocations();

        // [GIVEN] Generate a random inventory and save them in variable.
        ItemInventory[1] := LibraryRandom.RandDec(100, 2);
        ItemInventory[2] := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Create Inventory for generating Demand and Suply.
        CreateAndPostItemJournalLine(Item."No.", LocationCode[1], ItemInventory[1]);
        CreateAndPostItemJournalLine(Item."No.", LocationCode[2], ItemInventory[2]);

        // [GIVEN] Create and Release Transfer Order 1.
        CreateAndReleaseTransferOrder(
            TransferHeader[1],
            TransferLine,
            CalcDate('<-1M>', WorkDate()),
            LocationCode[1],
            LocationCode[3],
            LocationCode[4],
            Item."No.",
            ItemInventory[1]);

        // [GIVEN] Auto Reserve and Post Shipment for Transfer Order 1.
        AutoReserveTransferLine(TransferLine, TransferLine."Shipment Date");
        ShipTransferOrder(TransferHeader[1]."No.");

        // [GIVEN] Create and Release Transfer Order 2.
        CreateAndReleaseTransferOrder(
            TransferHeader[2],
            TransferLine,
            WorkDate(),
            LocationCode[2],
            LocationCode[3],
            LocationCode[4],
            Item."No.",
            ItemInventory[2]);

        // [GIVEN] Create and Release Sales Order 1.
        CreateSalesOrderWithLocAndShipmentDate(
            SalesHeader[1],
            LocationCode[3],
            Item."No.",
            ItemInventory[1],
            CalcDate('<-10D>', WorkDate()));
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);

        // [GIVEN] Auto Reserve Sales Order 1.
        GetSalesLine(SalesHeader[1], SalesLine);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Create and Release Sales Order 2.
        CreateSalesOrderWithLocAndShipmentDate(
            SalesHeader[2],
            LocationCode[3],
            Item."No.",
            ItemInventory[2],
            CalcDate('<-10D>', WorkDate()));
        LibrarySales.ReleaseSalesDocument(SalesHeader[2]);

        // [WHEN] Calculate order promising line for the sales order
        CalcSalesHeaderAvailableToPromise(TempOrderPromisingLine, SalesHeader[2]);

        // [THEN] Earliest shipment date = 'Shipment Date' of Transfer Order 2
        TempOrderPromisingLine.TestField("Earliest Shipment Date", WorkDate());
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Order Promising");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Order Promising");

        UpdateCompSalesManufPurchSetup();

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");
        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Order Promising");
    end;

    local procedure AdjustDateForDefaultSafetyLeadTime(OldDate: Date): Date
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        exit(CalcDate(InventorySetup."Default Safety Lead Time", OldDate));
    end;

    local procedure UpdateCompSalesManufPurchSetup()
    var
        DateFormula: DateFormula;
    begin
        Evaluate(DateFormula, '<3M>');  // Values used are important for test.
        UpdateCompanyInformationPeriodCalc(DateFormula);
        UpdateCompanyInformationCalcBucket(1);
        UpdateSalesReceivablesSetup();
        UpdateManufacturingSetup();
        UpdatePurchaseSetup();
    end;

    local procedure UpdateCompanyInfoBaseCalendarCode(BaseCalendarCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Base Calendar Code", BaseCalendarCode);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateManufacturingSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Normal Starting Time", 080000T);
        ManufacturingSetup.Validate("Normal Ending Time", 160000T);
        ManufacturingSetup.Validate("Planned Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure CalcSalesHeaderAvailableToPromise(var TempOrderPromisingLine: Record "Order Promising Line" temporary; SalesHeader: Record "Sales Header")
    var
        AvailabilityMgt: Codeunit AvailabilityManagement;
    begin
        AvailabilityMgt.SetSourceRecord(TempOrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcAvailableToPromise(TempOrderPromisingLine);
    end;

    local procedure CreateUpdateLocations()
    var
        Location: Record Location;
        k: Integer;
    begin
        // Values Used are important for Test.

        for k := 1 to 4 do begin
            LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
            LocationCode[k] := Location.Code;
        end;

        // Update Locations.
        UpdateLocation(Location, true);
    end;

    local procedure CreateProdOrderItemSetup(var Item: Record Item; NoBOMLine: Integer)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
    begin
        // Create Item, Routing and Production BOM with two lines.
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateRouting(RoutingHeader);
        CreateProdBOM(ProductionBOMHeader, Item."Replenishment System"::Purchase, Item."Base Unit of Measure", NoBOMLine);
        UpdateItem(Item, ProductionBOMHeader."No.", RoutingHeader."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        // Random values used are important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(50, 2), Item."Reordering Policy", Item."Flushing Method"::"Pick + Manual", '', '');
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateAssembleToOrderItemWithComponent(var AsmItem: Record Item; var CompItem: Record Item)
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateItem(CompItem, CompItem."Replenishment System"::Purchase);
        CreateItem(AsmItem, AsmItem."Replenishment System"::Assembly);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Modify(true);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");
    end;

    local procedure CreateNonWorkingDayInBaseCalendar(BaseCalendarCode: Code[10]; CalendarChangeDate: Date)
    var
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendarCode, BaseCalendarChange."Recurring System"::"Annual Recurring",
          CalendarChangeDate, BaseCalendarChange.Day::" ");
        BaseCalendarChange.Validate(Nonworking, true);
        BaseCalendarChange.Modify(true);
    end;

    local procedure CreateProdBOM(var ProductionBOMHeader: Record "Production BOM Header"; ReplenishmentSystem: Enum "Replenishment System"; BaseUnitOfMeasure: Code[10]; NoBOMLine: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        ItemNo: array[5] of Code[20];
        "Count": Integer;
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);

        for Count := 1 to NoBOMLine do begin
            CreateItem(Item, ReplenishmentSystem);
            ItemNo[Count] := Item."No.";
            LibraryManufacturing.CreateProductionBOMLine(
              ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo[Count], 1);
        end;

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateRouting(var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        CreateSetupWorkCenter(WorkCenter);
        CreateSetupMachineCenter(MachineCenter, WorkCenter."No.");

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");

        // Certify Routing after Routing lines creation.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random is used, values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateSetupWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Manual);
        WorkCenter.Modify(true);
    end;

    local procedure CreateSetupMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        // Random values used are important for test.Calculate calendar.
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, 105); // Value used is important for test.
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateOrderPromisingSetups(var Item: Record Item; var ShipmentDate: Date)
    begin
        // Create Locations and update Inventory Posting setups of these Locations.
        CreateUpdateLocations();
        CreateProdOrderItemSetup(Item, 3);

        // Create Inventory for Item. Create Documents for generating Demand and Suply.
        CreateAndPostItemJournalLine(Item."No.", LocationCode[1], LibraryRandom.RandDec(100, 2));
        CreateAndPostItemJournalLine(Item."No.", LocationCode[1], LibraryRandom.RandDec(100, 2));

        ShipmentDate := WorkDate();
        CreateSupplyDemandDocuments(Item, ShipmentDate);
    end;

    local procedure CreateSupplyDemandDocuments(var Item: Record Item; var ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        TransferHeader: Record "Transfer Header";
    begin
        // Create Sales Order.
        CreateSalesOrder(SalesHeader, ShipmentDate, '', Item."No.", LibraryRandom.RandDec(5, 2));

        // Create Purchase Order.
        CreatePurchaseOrder(
          PurchaseHeader, CalcDate('<' + Format(LibraryRandom.RandInt(10) + 5) + 'D>', ShipmentDate), LocationCode[1], Item."No.",
          LibraryRandom.RandDec(50, 2));

        // Create Sales Order.
        Clear(SalesHeader);
        CreateSalesOrder(
          SalesHeader, CalcDate('<' + Format(LibraryRandom.RandInt(10) + 5) + 'D>', ShipmentDate), '', Item."No.",
          LibraryRandom.RandDec(5, 2));

        // Create Production Order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(5));

        // Create Transfer Orders.
        CreateTransferOrder(
          TransferHeader, CalcDate('<' + Format(LibraryRandom.RandInt(10) + 5) + 'D>', ShipmentDate),
          LocationCode[1], LocationCode[2], LocationCode[4], Item."No.");
        CreateTransferOrder(
          TransferHeader, CalcDate('<' + Format(LibraryRandom.RandInt(10) + 5) + 'D>', ShipmentDate),
          LocationCode[2], LocationCode[3], LocationCode[4], Item."No.");
        ShipmentDate := TransferHeader."Shipment Date";
    end;

    local procedure CreateSupplyDocuments(ItemNo: Code[20]; ShipmentDate: Date; NoOfDocuments: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        i: Integer;
    begin
        for i := 1 to NoOfDocuments do
            CreatePurchaseOrder(
              PurchaseHeader, CalcDate('<' + Format(LibraryRandom.RandInt(10) + 5) + 'D>', ShipmentDate), LocationCode[1], ItemNo,
              LibraryRandom.RandDec(50, 2));
    end;

    local procedure CreateDemandDocuments(var Item: Record Item; var SalesHeader: Record "Sales Header"; ShipmentDate: Date; NoOfDocuments: Integer)
    var
        i: Integer;
        SalesOrderQty: Decimal;
    begin
        for i := 1 to NoOfDocuments do begin
            Clear(SalesHeader);
            Item.CalcFields(Inventory, "Qty. on Sales Order");
            SalesOrderQty := Item.Inventory - Item."Qty. on Sales Order";
            CreateSalesOrder(SalesHeader, ShipmentDate, LocationCode[1], Item."No.", SalesOrderQty);
        end;
    end;

    local procedure CreatePurchAndSalesOrder(var SalesHeader: Record "Sales Header"; var SalesQuantity: Decimal; ShipmentDate: Date)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";
        CreatePurchaseOrder(PurchaseHeader, WorkDate(), '', Item."No.", LibraryRandom.RandIntInRange(50, 100));

        SalesQuantity := LibraryRandom.RandInt(50); // no more than purchased to prevent availability warning for insufficient quantity
        CreateSalesOrder(SalesHeader, ShipmentDate, '', Item."No.", SalesQuantity);
    end;

    local procedure CreateInventoryDemandAndSupply(var ItemNo: Code[20]; var SalesHeader: Record "Sales Header"; InventoryQty: Decimal; SupplyQty: Decimal; SupplyDate: Date)
    var
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        AvailCalcPeriod: DateFormula;
        i: Integer;
    begin
        Evaluate(AvailCalcPeriod, '<2W>');
        UpdateCompanyInformationPeriodCalc(AvailCalcPeriod);
        UpdateCompanyInformationCalcBucket(0);
        LibrarySales.SetStockoutWarning(true);
        for i := 0 to 5 do
            LibraryVariableStorage.Enqueue(i); // this lets us see how many avail. warnings are raised during the test

        ItemNo := LibraryInventory.CreateItemNo();
        CreateAndPostItemJournalLine(ItemNo, '', InventoryQty);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineWithShipmentDateAndTriggerAvailCheck(
          SalesLine, SalesHeader, ItemNo, CalcDate(AvailCalcPeriod, WorkDate()) - 1, InventoryQty);

        CreatePurchaseOrder(PurchaseHeader, SupplyDate, '', ItemNo, SupplyQty);
    end;

    local procedure CreateSupplyForBOMComponentAndDemandForAssembledItem(AsmItemNo: Code[20]; CompItemNo: Code[20]; InvtQty: Decimal; ReceiptQty: Decimal; ShipmentQty: Decimal; InvtDate: Date; ReceiptDate: Date; ShipmentDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItemNo, '', '', InvtQty);
        ItemJournalLine.Validate("Posting Date", InvtDate);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreatePurchaseOrder(PurchaseHeader, ReceiptDate, '', CompItemNo, ReceiptQty);

        CreateSalesOrder(SalesHeader, ShipmentDate, '', AsmItemNo, ShipmentQty);
    end;

    local procedure GetShipmentDateFromFactBox(SalesHeaderNo: Code[20]) ShipmentDate: Date
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesHeaderNo);
        Evaluate(ShipmentDate, SalesOrder.Control1906127307."Shipment Date".Value);
        SalesOrder.Close();
    end;

    local procedure FindAssemblyLine(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20])
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange("No.", ItemNo);
        AssemblyLine.FindFirst();
    end;

    local procedure FindSalesline(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure OrderPromising(DemandQuantity: Decimal; DemandMoreThanSupply: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        AvailabilityMgt: Codeunit AvailabilityManagement;
        SalesOrderQty: Decimal;
        ShipmentDate: Date;
    begin
        Initialize();
        CreateOrderPromisingSetups(Item, ShipmentDate);

        // Create One Demand Documents.
        Item.CalcFields(Inventory, "Qty. on Sales Order");
        SalesOrderQty := Abs(Item.Inventory - Item."Qty. on Sales Order" - DemandQuantity);
        CreateSalesOrder(SalesHeader, ShipmentDate, LocationCode[1], Item."No.", SalesOrderQty);

        // Exercise: Run Available to Promise.
        AvailabilityMgt.SetSourceRecord(TempOrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcAvailableToPromise(TempOrderPromisingLine);

        // Verify: Verify the Earliest Shipment date in Order Promising Table.
        VerifyAvailableToPromise(SalesHeader, TempOrderPromisingLine."Earliest Shipment Date", DemandMoreThanSupply);
    end;

    local procedure LookAheadSetup(NoOfSupplyDocuments: Integer; NoOfDemandDocuments: Integer; DemandMoreThanSupply: Boolean)
    var
        SalesHeader: Record "Sales Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        Item: Record Item;
        AvailabilityMgt: Codeunit AvailabilityManagement;
        ShipmentDate: Date;
    begin
        // Create Demand Documents.
        Initialize();
        CreateOrderPromisingSetups(Item, ShipmentDate);

        CreateDemandDocuments(Item, SalesHeader, ShipmentDate, NoOfDemandDocuments);

        // Create Supply Documents.
        CreateSupplyDocuments(Item."No.", ShipmentDate, NoOfSupplyDocuments);

        // Exercise: Run Available to Promise.
        AvailabilityMgt.SetSourceRecord(TempOrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcAvailableToPromise(TempOrderPromisingLine);

        // Verify: Verify the Earliest Shipment date in Order Promising Table.
        VerifyAvailableToPromise(SalesHeader, TempOrderPromisingLine."Earliest Shipment Date", DemandMoreThanSupply);
    end;

    local procedure UpdateCompanyInformationPeriodCalc(CheckAvailPeriodCalc: DateFormula)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Check-Avail. Period Calc.", CheckAvailPeriodCalc);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateCompanyInformationCalcBucket(CheckAvailTimeBucket: Option Day,Week,Month,Quarter,Year)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Check-Avail. Time Bucket", CheckAvailTimeBucket);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateItem(var Item: Record Item; ProductionBOMHeaderNo: Code[20]; RoutingNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMHeaderNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateLocation(var Location: Record Location; UseAsInTransit: Boolean)
    begin
        Location.Validate("Use As In-Transit", UseAsInTransit);
        Location.Modify(true);
    end;

    local procedure UpdateSalesLineShippingCalculation(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; WhseHandlingTimeFormula: Text; ShippingTimeFormula: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        Evaluate(SalesLine."Outbound Whse. Handling Time", WhseHandlingTimeFormula);
        Evaluate(SalesLine."Shipping Time", ShippingTimeFormula);
        SalesLine.Modify(true);
    end;

    local procedure UpdateShipmentDateOnSalesOrderPage(SalesHeaderNo: Code[20]; ShipmentDate: Date)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeaderNo);
        SalesOrder.SalesLines."Shipment Date".SetValue(ShipmentDate); // Trigger the Check Availability warning.
        SalesOrder.Close();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ReceiptDate: Date; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Expected Receipt Date", ReceiptDate);
        PurchaseHeader.Validate("Due Date", ReceiptDate);
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ShipmentDate: Date; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesOrderWithRequestedDeliveryDate(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; RequestedDeliveryDate: Date; ShipmentDate: Date)
    begin
        CreateSalesOrder(SalesHeader, WorkDate(), '', ItemNo, Qty);
        SalesHeader.Validate("Requested Delivery Date", RequestedDeliveryDate);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; ShipmentDate: Date; FromLocation: Code[10]; ToLocation: Code[10]; InTransitCode: Code[10]; ItemNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, InTransitCode);
        TransferHeader.Validate("Shipment Date", ShipmentDate);
        TransferHeader.Modify(true);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, LibraryRandom.RandDec(5, 2));
    end;

    local procedure CreateItemTypeService(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemTypeNonStock(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);
        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateSalesOrderForThreeItems(var SalesHeader: Record "Sales Header"; ItemNo1: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        InsertSalesLineForItemToDoc(SalesHeader, ItemNo1, LibraryRandom.RandInt(10));
        InsertSalesLineForItemToDoc(SalesHeader, ItemNo2, LibraryRandom.RandInt(10));
        InsertSalesLineForItemToDoc(SalesHeader, ItemNo3, LibraryRandom.RandInt(10));
    end;

    [Scope('OnPrem')]
    procedure CreateJobForThreeItems(var Job: Record Job; ItemNo1: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20])
    var
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        InsertJobPlanningLineForItemToDoc(JobTask, ItemNo1, LibraryRandom.RandInt(10));
        InsertJobPlanningLineForItemToDoc(JobTask, ItemNo2, LibraryRandom.RandInt(10));
        InsertJobPlanningLineForItemToDoc(JobTask, ItemNo3, LibraryRandom.RandInt(10));
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesLineForItemToDoc(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    [Scope('OnPrem')]
    procedure InsertJobPlanningLineForItemToDoc(var JobTask: Record "Job Task"; ItemNo: Code[20]; Quantity: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        CreateJobPlanningLine(JobPlanningLine, JobTask, ItemNo, Quantity);
    end;

    local procedure CreateSalesLineWithShipmentDateAndTriggerAvailCheck(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ShipmentDate: Date; Qty: Decimal)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ShipmentDate, Qty);
        ItemCheckAvail.SalesLineCheck(SalesLine);
    end;

    local procedure UpdateShipmentDateOnSalesLineAndTriggerAvailCheck(var SalesLine: Record "Sales Line"; NewShipmentDate: Date)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        SalesLine.Find();
        SalesLine.Validate("Shipment Date", NewShipmentDate);
        ItemCheckAvail.SalesLineCheck(SalesLine);
    end;

    local procedure VerifyAvailableToPromise(SalesHeader: Record "Sales Header"; EarliestShipmentDate: Date; DemandMoreThanSupply: Boolean)
    var
        ActualEarliestShipmentDate: Date;
    begin
        if not DemandMoreThanSupply then
            if SalesHeader."Shipment Date" <> 0D then
                ActualEarliestShipmentDate := SalesHeader."Shipment Date"
            else
                ActualEarliestShipmentDate := SalesHeader."Order Date";

        Assert.AreEqual(EarliestShipmentDate, ActualEarliestShipmentDate, ErrDateMustBeSame);
    end;

    local procedure VerifyNoOfRaisedNotifications(NotificationsRaisedEarlier: Integer; NotificationsRaisedOnAction: Integer)
    begin
        Assert.AreEqual(
          NotificationsRaisedOnAction, LibraryVariableStorage.DequeueInteger() - NotificationsRaisedEarlier - 1,
          WrongNoOfAvailNotificationsRaisedErr);
    end;

    local procedure VerifyReservEntryShipmentDate(SourceType: Integer; ItemNo: Code[20]; ShipmentDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Shipment Date", ShipmentDate);
    end;

    local procedure GetSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesHeader.Find();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure CreateSalesOrderWithLocAndShipmentDate(var SalesHeader: Record "Sales Header"; LocCode: Code[10]; ItemNo: Code[20]; Qty: Decimal; ShipmentDate: Date)
    begin
        CreateSalesOrder(SalesHeader, WorkDate(), LocCode, ItemNo, Qty);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
    end;

    local procedure AutoReserveTransferLine(var TransferLine: Record "Transfer Line"; AvailabilityDate: Date)
    var
        ReservationManagement: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservationManagement.SetReservSource(TransferLine, Enum::"Transfer Direction"::Outbound);
        ReservationManagement.AutoReserve(FullAutoReservation, TransferLine.Description, AvailabilityDate, TransferLine.Quantity, TransferLine."Quantity (Base)");
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ShipmentDate: Date; FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
    begin
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitCode);
        TransferHeader.Validate("Shipment Date", ShipmentDate);
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure ShipTransferOrder(TransferOrderNo: Code[20])
    var
        TransferOrder: TestPage "Transfer Order";
    begin
        TransferOrder.OpenEdit();
        TransferOrder.GotoKey(TransferOrderNo);
        LibraryVariableStorage.Enqueue(1);
        TransferOrder.Post.Invoke();
    end;

    [ModalPageHandler]
    procedure ServiceLinesModalPageHandler(var ServiceLines: TestPage "Service Lines")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLines.Type.SetValue(ServiceLine.Type::Item);
        ServiceLines."No.".SetValue(LibraryVariableStorage.DequeueText());
        ServiceLines.Quantity.SetValue(1);
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AssemblyAvailabilityModalPageHandler(var AssemblyAvailability: TestPage "Assembly Availability Check")
    begin
        LibraryVariableStorage.Enqueue(AssemblyAvailability.AssemblyLineAvail."No.".Value);
        LibraryVariableStorage.Enqueue(AssemblyAvailability.AssemblyLineAvail.AbleToAssemble.Value);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendAssemblyAvailabilityNotificationHandler(var Notification: Notification): Boolean
    var
        AssemblyLineManagement: Codeunit "Assembly Line Management";
    begin
        AssemblyLineManagement.ShowNotificationDetails(Notification);
        Notification.Recall();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), ConfirmMessage);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RecallNotificationHandler]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    procedure SendItemAvailNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendAvailabilityNotificationHandler(var Notification: Notification): Boolean
    var
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        Assert.AreEqual(ItemNo, Notification.GetData('ItemNo'), 'Item No. was different than expected');
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        Assert.AreEqual(Format(Item.Inventory), Notification.GetData('InventoryQty'),
          'Available Inventory was different than expected');
        ItemCheckAvail.ShowNotificationDetails(Notification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendAsmAvailNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.GetData('ItemNo'));
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NotificationDetailsHandler(var ItemAvailabilityCheck: TestPage "Item Availability Check")
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        ItemAvailabilityCheck.AvailabilityCheckDetails."No.".AssertEquals(Item."No.");
        ItemAvailabilityCheck.AvailabilityCheckDetails.Description.AssertEquals(Item.Description);
        ItemAvailabilityCheck.InventoryQty.AssertEquals(Item.Inventory);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityCheckHandler(var ItemAvailabilityCheck: TestPage "Item Availability Check")
    var
        Item: Record Item;
        TotalQuantity: Decimal;
    begin
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        Item.CalcFields("Qty. on Sales Order");
        if Item."Qty. on Sales Order" <> 0 then
            TotalQuantity := Item."Qty. on Sales Order" + 1
        else
            TotalQuantity := Item.Inventory + 1;
        ItemAvailabilityCheck.AvailabilityCheckDetails."No.".AssertEquals(Item."No.");
        ItemAvailabilityCheck.AvailabilityCheckDetails.Description.AssertEquals(Item.Description);
        ItemAvailabilityCheck.InventoryQty.AssertEquals(Item.Inventory);
        ItemAvailabilityCheck.TotalQuantity.AssertEquals(Item.Inventory - TotalQuantity);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ShipOrReceiveTransferOrderStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;
}

