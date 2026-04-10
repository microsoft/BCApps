codeunit 137411 "SCM Stockout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Availability] [SCM]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        Stockoutwarning: Boolean;
        ItemStockOutWarningTestType: Option Default,No,Yes;
        NoWarningExpectedErr: Label 'There is sufficient stock of item %1. No availability warning is expected', Comment = '%1 = Item No. (There is sufficient stock of item 70061)';
        StockoutWarningExpectedErr: Label 'Insufficient stock of item %1. Availability warning is expected', Comment = '%1 = Item No. (Insufficient stock of item 70061)';

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Stockout");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Stockout");
        SalesSetup.Get();
        Stockoutwarning := SalesSetup."Stockout Warning";
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Stockout");
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestStockoutWarningItemYes()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        TestStockoutWarning(ItemStockOutWarningTestType::Yes, false);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStockoutWarningItemNo()
    begin
        TestStockoutWarning(ItemStockOutWarningTestType::No, false);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestStockoutWarningItemDefaultGlobalYes()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        TestStockoutWarning(ItemStockOutWarningTestType::Default, true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStockoutWarningItemDefaultGlobalNo()
    begin
        TestStockoutWarning(ItemStockOutWarningTestType::Default, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoStockoutWarningWhenQuantityRaisedWithReservAndSufficientStock()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        SalesOrderQty: Integer;
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 372286] No availability warning is raised when quantity on sales line is changed if item is reserved for the same line

        // [GIVEN] Item with stockout warning
        CreateItemSetStockoutWarning(Item, Item."Stockout Warning"::Yes);
        SalesOrderQty := LibraryRandom.RandIntInRange(10, 50);
        // [GIVEN] Quantity on inventory is "X"
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', SalesOrderQty * 2, WorkDate(), Item."Unit Cost");

        // [GIVEN] Sales order with quantity = "X / 2", item is reserved
        CreateSalesOrderWithAutoReservation(SalesLine, Item, SalesOrderQty);

        // [WHEN] Change quantity in the sales order line. New quantity = "X"
        SalesLine.Validate(Quantity, SalesOrderQty * 2);

        // [THEN] No availability warning
        Assert.IsFalse(ItemCheckAvail.SalesLineShowWarning(SalesLine), StrSubstNo(NoWarningExpectedErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoStockoutWarningWhenQuantityRaisedWithReservTwoOrdersAndSufficientStock()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        SalesOrderQty: Integer;
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 372286] No availability warning is raised when quantity on sales line is changed if item is reserved for different sales order, but total availability is sufficient

        // [GIVEN] Item with stockout warning
        CreateItemSetStockoutWarning(Item, Item."Stockout Warning"::Yes);
        SalesOrderQty := LibraryRandom.RandIntInRange(10, 50);
        // [GIVEN] Quantity on inventory is "X"
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', SalesOrderQty * 2, WorkDate(), Item."Unit Cost");

        // [GIVEN] Sales order "SO1": Quantity = "X / 2", all reserved
        CreateSalesOrderWithAutoReservation(SalesLine, Item, SalesOrderQty);
        // [GIVEN] Sales order "SO2": Quantity = "X / 2" - 1. All stock except 1 item is reserved
        CreateSalesOrderWithAutoReservation(SalesLine, Item, SalesOrderQty - 1);

        // [WHEN] Change quantity in the sales order "SO2". New quantity = "X"
        SalesLine.Validate(Quantity, SalesOrderQty);

        // [THEN] No availability warning
        Assert.IsFalse(ItemCheckAvail.SalesLineShowWarning(SalesLine), StrSubstNo(NoWarningExpectedErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StockoutWarningWhenQuantityRaisedAboveAvailWithReservation()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        SalesOrderQty: Integer;
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 372286] Availability warning is when creating a sales order if total stock is sufficient, but it is reserved for another order

        // [GIVEN] Item with stockout warning
        CreateItemSetStockoutWarning(Item, Item."Stockout Warning"::Yes);
        SalesOrderQty := LibraryRandom.RandIntInRange(10, 50);
        // [GIVEN] Quantity on inventory is "X"
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', SalesOrderQty * 2, WorkDate(), Item."Unit Cost");

        // [GIVEN] Sales order with quantity = "X / 2", item is reserved
        CreateSalesOrderWithAutoReservation(SalesLine, Item, SalesOrderQty);

        // [WHEN] Create new sales order with quantity = "X / 2" + 1
        CreateSalesOrder(SalesLine, Item, SalesOrderQty + 1);

        // [THEN] Availability warning is raised
        Assert.IsTrue(ItemCheckAvail.SalesLineShowWarning(SalesLine), StrSubstNo(StockoutWarningExpectedErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StockoutWarningWhenItemTypeIsService()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // [Scenario] When Item type is Service, Stockout warning should be No and Editable=False
        // Setup
        Initialize();
        LibraryInventory.CreateItem(Item);

        // Excercise
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard.Type.Value := Format(Item.Type::Service);

        // Verify
        Assert.IsFalse(ItemCard.StockoutWarningDefaultYes.Editable(),
          'Stockout Warning should NOT be EDITABLE when Item Type is Service');
        ItemCard.StockoutWarningDefaultYes.AssertEquals(Item."Stockout Warning"::No);

        // Excercise
        ItemCard.GotoRecord(Item);
        ItemCard.Type.Value := Format(Item.Type::"Non-Inventory");

        // Verify
        Assert.IsFalse(ItemCard.StockoutWarningDefaultYes.Editable(),
          'Stockout Warning should NOT be EDITABLE when Item Type is Non-Inventory');
        ItemCard.StockoutWarningDefaultYes.AssertEquals(Item."Stockout Warning"::No);
    end;

    local procedure CreateItemSetStockoutWarning(var Item: Record Item; StockoutWarning: Option)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Stockout Warning" := StockoutWarning;
        Item.Modify();
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; Item: Record Item; Quantity: Decimal)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
    end;

    local procedure CreateSalesOrderWithAutoReservation(var SalesLine: Record "Sales Line"; Item: Record Item; SalesOrderQty: Decimal)
    begin
        CreateSalesOrder(SalesLine, Item, SalesOrderQty);
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure TestStockoutWarning(ItemStockOutWarning: Option Default,No,Yes; SalesSetupStockOutWarning: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        ItemInventoryQty: Decimal;
    begin
        Initialize();
        LibrarySales.SetStockoutWarning(SalesSetupStockOutWarning);
        CreateItemSetStockoutWarning(Item, ItemStockOutWarning);
        ItemInventoryQty := LibraryRandom.RandInt(100);
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', ItemInventoryQty, WorkDate(), Item."Unit Cost");
        CreateSalesOrder(SalesLine, Item, 2 * ItemInventoryQty);
        Assert.IsFalse(ItemCheckAvail.SalesLineCheck(SalesLine), '');
        LibrarySales.SetStockoutWarning(Stockoutwarning);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

