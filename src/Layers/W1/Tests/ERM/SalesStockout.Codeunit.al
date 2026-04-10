codeunit 136132 "Sales Stockout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Availability] [Sales]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SalesOrder: TestPage "Sales Order";
        IsInitialized: Boolean;
        ZeroQuantity: Integer;
        SaleQuantity: Integer;
        ReceiptDateDocumentErr: Label 'No Purchase Line found with sales order no %1.', Comment = '%1 - document number';
        ShipmentDateDocumentErr: Label 'No Sales Line found with sales order no %1.', Comment = '%1 - document number';
        ValidateQuantityDocumentErr: Label 'DocNo %1 not found in following objects: Sales Header.', Comment = '%1 - document number';

    [Normal]
    local procedure Initialize()
    var
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales Stockout");
        // Clear the needed globals
        ClearGlobals();
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales Stockout");

        SalesAndReceivablesSetup.Get();
        SalesAndReceivablesSetup.Validate("Stockout Warning", true);
        SalesAndReceivablesSetup.Modify();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales Stockout");
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesDemandHigherThanSupply()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NbNotifs: Integer;
        PurchaseQuantity: Integer;
        PurchaseOrderNo: Code[20];
        SalesOrderNo: Code[20];
    begin
        // Test availability warning for Sales Demand higher than Supply.

        // SETUP: Create Supply with Purchase Order for Item X, Quantity = Y.
        // SETUP: Create Sales Demand for Item X,with zero quantity .
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        PurchaseQuantity := LibraryRandom.RandInt(10);
        SaleQuantity := PurchaseQuantity + 1;
        CreateItem(Item);
        PurchaseOrderNo := CreatePurchaseSupply(Item."No.", PurchaseQuantity);
        SalesOrderNo := CreateSalesDemandAfter(Item."No.", ZeroQuantity, GetReceiptDate(PurchaseOrderNo));
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // EXECUTE: Open the sales order page, Change Demand Quantity on Sales Order Through UI to Quantity = Y + 1.
        EditSalesOrderQuantity(SalesOrderNo, SaleQuantity);

        // VERIFY: Quantity on sales order after warning is Y + 1.
        ValidateQuantity(SalesOrderNo, SaleQuantity);

        // WHEN we decrease the quantity so the item is available (0 items ordered)
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        NbNotifs := TempNotificationContext.Count();
        EditSalesOrderQuantity(SalesOrderNo, 0);

        // THEN the item availability notification is recalled
        Assert.AreEqual(NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after decreasing the Quantity.');

        // WHEN we change the type of sales line to Resource
        EditSalesOrderQuantity(SalesOrderNo, SaleQuantity);
        Assert.AreEqual(NbNotifs, TempNotificationContext.Count, 'Unexpected number of notifications after increasing the Quantity back.');
        EditSalesOrderType(SalesOrderNo, Format(SalesLine.Type::Resource));

        // THEN the item availability notification is recalled
        Assert.AreEqual(
          NbNotifs - 1, TempNotificationContext.Count,
          'Unexpected number of notifications after changing the Sales Line type from Item to Resource.');

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDemandLowerThanSupply()
    var
        Item: Record Item;
        PurchaseQuantity: Integer;
        PurchaseOrderNo: Code[20];
        SalesOrderNo: Code[20];
    begin
        // Test supply cover Sales Order demand and therefore no warning.

        // SETUP: Create Supply for Item X.
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10);
        SaleQuantity := PurchaseQuantity - 1;
        CreateItem(Item);
        PurchaseOrderNo := CreatePurchaseSupply(Item."No.", PurchaseQuantity);
        SalesOrderNo := CreateSalesDemandAfter(Item."No.", ZeroQuantity, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Open sales order page, Create Sales Demand for Item X at a date after Supply has arrived and quantity < supply.

        EditSalesOrderQuantity(SalesOrderNo, SaleQuantity);

        // VERIFY: that quantity change is reflected when availability warning is ignored
        ValidateQuantity(SalesOrderNo, SaleQuantity);
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesDemandBeforeSupplyArrive()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseQuantity: Integer;
        SalesOrderNo: Code[20];
    begin
        // Test availability warning if Sales Demand is at a date before Supply arrives.

        // SETUP: Create Sales Demand for Item X,with zero quantity.
        // SETUP: Create Supply with Purchase Order for Item X, Quantity=Y, at a date after Sales Demand.
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        PurchaseQuantity := LibraryRandom.RandInt(10) * 2;  // Taking Minimum Value as 2 as the Sale Quantity should not be zero.
        SaleQuantity := PurchaseQuantity - 1;
        CreateItem(Item);
        SalesOrderNo := CreateSalesDemand(Item."No.", ZeroQuantity);
        CreatePurchaseSupplyAfter(Item."No.", PurchaseQuantity, GetShipmentDate(SalesOrderNo));

        // EXECUTE: Open the sales order page, Change Demand Quantity on Sales Order Through UI to Quantity = Y - 1.
        EditSalesOrderQuantity(SalesOrderNo, SaleQuantity);

        // VERIFY: Verify Quantity on sales order after warning is Y - 1.
        ValidateQuantity(SalesOrderNo, SaleQuantity);
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesLocationDifferent()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseQuantity: Integer;
        PurchaseOrderNo: Code[20];
        SalesOrderNo: Code[20];
        LocationB: Code[10];
        LocationA: Code[10];
    begin
        // Test availability warning if Sales Demand is at a different Location than a supply from purchase.

        // SETUP: Create Supply with Purchase Order for Item X, Qantity=Y, Location = Z.
        // SETUP: Create Sales Demand for Item X, Quantity=0, Location = M .
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        PurchaseQuantity := LibraryRandom.RandInt(10) * 2;  // Taking Minimum Value as 2 as the Sale Quantity should not be zero.
        SaleQuantity := PurchaseQuantity - 1;
        CreateItem(Item);
        LocationA := CreateLocation();
        LocationB := CreateLocation();
        PurchaseOrderNo := CreatePurchaseSupplyAtLocation(Item."No.", PurchaseQuantity, LocationA);
        SalesOrderNo := CreateSalesLocationDemandAfter(Item."No.", ZeroQuantity, LocationB, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Open the sales order page, Change Demand Quantity on Sales Order Through UI to Quantity = Y - 1.
        EditSalesOrderQuantity(SalesOrderNo, SaleQuantity);

        // VERIFY: Quantity on sales order after warning is Y - 1.
        ValidateQuantity(SalesOrderNo, SaleQuantity);
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesChangeLocation()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseQuantity: Integer;
        PurchaseOrderNo: Code[20];
        SalesOrderNo: Code[20];
        LocationA: Code[10];
        LocationB: Code[10];
    begin
        // Test availability warning if the location for Sales Demand modified to a location where demand cannot be met

        // SETUP: Create Supply with Purchase Order for Item X, Qantity=Y, Location = Z.
        // SETUP: Create Sales Demand for Item X, Quantity=Y, Location = Z
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        PurchaseQuantity := LibraryRandom.RandInt(10) * 2;  // Taking Minimum Value as 2 as the Sale Quantity should not be zero.
        SaleQuantity := PurchaseQuantity - 1;
        CreateItem(Item);
        LocationA := CreateLocation();
        LocationB := CreateLocation();
        PurchaseOrderNo := CreatePurchaseSupplyAtLocation(Item."No.", PurchaseQuantity, LocationA);
        SalesOrderNo := CreateSalesLocationDemandAfter(Item."No.", SaleQuantity, LocationA, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Open the sales order page, Change Location on Sales Order Through UI to location M.
        OpenSalesOrderPageByNo(SalesOrderNo, SalesOrder);
        SalesOrder.SalesLines."Location Code".Value(LocationB);
        SalesOrder.Close();

        // VERIFY: Quantity on sales order after warning is Y and location M.
        ValidateQuantity(SalesOrderNo, SaleQuantity);
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesChangeDate()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseQuantity: Integer;
        PurchaseOrderNo: Code[20];
        SalesOrderNo: Code[20];
    begin
        // Test availability warning if the date of Sales Demand is modified to a date where demand cannot be met

        // SETUP: Create Supply with Purchase Order for Item X, Qantity=Y, Date = Workdate.
        // SETUP: Create Sales Demand for Item X, Quantity=Y, Date = WorkDate() + 1
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        PurchaseQuantity := LibraryRandom.RandInt(10);
        SaleQuantity := PurchaseQuantity;
        CreateItem(Item);
        SalesOrderNo := CreateSalesDemand(Item."No.", PurchaseQuantity);
        PurchaseOrderNo := CreatePurchaseSupplyAfter(Item."No.", PurchaseQuantity * 2, GetShipmentDate(SalesOrderNo));
        SalesOrderNo := CreateSalesDemandAfter(Item."No.", PurchaseQuantity, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Open the sales order page, Change Date on Sales Order Through UI to Date = WorkDate() - 1.
        OpenSalesOrderPageByNo(SalesOrderNo, SalesOrder);
        SalesOrder.SalesLines."Planned Shipment Date".Value(Format(WorkDate()));
        SalesOrder.Close();

        // VERIFY: Quantity on sales order after warning is Y and Date is WorkDate() - 1.
        ValidateQuantity(SalesOrderNo, SaleQuantity);
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesChangeUOMAvailWarning()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        QtyPerUOM: Decimal;
        SalesOrderNo: Code[20];
        LocationCode: Code[10];
        PcsUOM: Code[10];
        BoxUOM: Code[10];
        StockAvailSupplyDate: Date;
    begin
        // [SCENARIO 118221.1] Verify Availability Warning's Earliest Date when changing UOM from PCS to BOX
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        QtyPerUOM := 3;
        LocationCode := CreateLocation();

        // [GIVEN] Item with two UOMs: 1 BOX = 3 PCS
        CreateItem(Item);
        PcsUOM := GetPcsUOM(Item."No.");
        BoxUOM := CreateItemUOM(Item."No.", QtyPerUOM);

        // [GIVEN] Create Purchase Order with 2 PCS on WorkDate
        CreatePurchSupplyWithUOMAtLocation(Item."No.", LocationCode, PcsUOM, 2, WorkDate());

        // [GIVEN] Create Purchase Order with 1 BOX on SupplyDate = WorkDate() + 1Day
        StockAvailSupplyDate := WorkDate() + 1;
        CreatePurchSupplyWithUOMAtLocation(Item."No.", LocationCode, BoxUOM, 1, StockAvailSupplyDate);

        // [GIVEN] Create Sales Order with 1 PCS on WorkDate
        SalesOrderNo := CreateSalesDemandAtLocation(Item."No.", 1, LocationCode);

        // [WHEN] Change Sales Order Line's UOM from PCS to BOX
        // [THEN] Availability Warning is shown with Earliest Date = SupplyDate
        LibraryVariableStorage.Enqueue(StockAvailSupplyDate);
        SetSalesUOMPageTestability(SalesOrderNo, BoxUOM);
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,ItemAvailabilityCheckModalPageHandler,RecallNotificationHandler')]
    procedure VariantCodeIsTransferredFromSalesToPurchaseViaItemAvailCheckPage()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseOrder: TestPage "Purchase Order";
        SalesOrderNo: Code[20];
    begin
        // [SCENARIO 426688] Variant Code and Unit of Measure Code are transferred from sales order to purchase order via Item Availability Check page.
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        SaleQuantity := LibraryRandom.RandInt(10);

        // [GIVEN] Item "I" with vendor, Item Variant "V" and alternate unit of measure "UOM".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Sales order for item "I", select item variant = "V", unit of measure code = "UOM", quantity = 0.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 0, '', WorkDate());
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        SalesLine.Modify(true);

        // [GIVEN] Update quantity on the sales line to 10.
        // [GIVEN] Stockout notification is raised.
        // [WHEN] Click on "Show Details" and then "Create Purchase Order" on the Item Availability Check page.
        SalesOrderNo := SalesHeader."No.";
        PurchaseOrder.Trap();
        EditSalesOrderQuantity(SalesOrderNo, SaleQuantity);
        PurchaseOrder.Close();

        // [THEN] Purchase order has been created.
        // [THEN] Item No. = "I", Variant Code = "V", Unit of Measure Code = "UOM", Quantity = 10 on the new purchase line.
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Variant Code", ItemVariant.Code);
        PurchaseLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.TestField(Quantity, SaleQuantity);

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityCheckModalPageHandler,RecallNotificationHandler')]
    procedure UnitOfMeasureWhenCreatePurchaseOrderFromAssemblyOrderViaItemAvailCheckPage()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseLine: Record "Purchase Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        AssemblyOrder: TestPage "Assembly Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Assembly Order]
        // [SCENARIO 449322] Unit of Measure Code is copied from Assembly Order line to Purchase Order line via Item Availability Check page.
        Initialize();

        // [GIVEN] Item "I" with Vendor and alternate Unit of Measure "UOM".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Assembly Order with line containing Item "I" with Unit of Measure "UOM" and Quantity Per 0.
        LibraryAssembly.CreateAssemblyHeader(
            AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), '', LibraryRandom.RandIntInRange(10, 20), '');
        LibraryAssembly.CreateAssemblyLine(
            AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", ItemUnitOfMeasure.Code, AssemblyHeader.Quantity, 0, '');

        // [GIVEN] Opened Assembly Order page. Quantity Per is updated on Assembly Line to 10.
        // [GIVEN] Availability Warning is shown for Assembly Line.
        // [WHEN] Drill down field "Avail. Warning" of Assembly Line and then "Create Purchase Order" on the Item Availability Check page.
        PurchaseOrder.Trap();
        AssemblyOrder.OpenEdit();
        AssemblyOrder.Filter.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrder.Lines."Quantity per".SetValue(10);
        AssemblyOrder.Lines."Avail. Warning".Drilldown();
        PurchaseOrder.Close();

        // [THEN] Purchase Order was created.
        // [THEN] It has Purchase Line with Item No. = "I", Unit of Measure Code = "UOM".
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure ClearGlobals()
    begin
        // Clear all global variables
        ZeroQuantity := 0;
        Clear(SalesOrder);
        SaleQuantity := 0;
    end;

    [Normal]
    local procedure CreateItem(var Item: Record Item)
    begin
        // Creates a new item. Wrapper for the library method.
        LibraryInventory.CreateItem(Item);
        // Item.VALIDATE("Unit Price",10);
    end;

    local procedure CreateItemUOM(ItemNo: Code[20]; QtyPerUOM: Decimal): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, QtyPerUOM);
        exit(ItemUnitOfMeasure.Code);
    end;

    [Normal]
    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        // Creates a new Location. Wrapper for the library method.
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    local procedure CreatePurchaseSupplyBasis(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]; ReceiptDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Creates a Purchase order for the given item.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Expected Receipt Date", ReceiptDate);
        PurchaseLine.Modify();
        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseSupply(ItemNo: Code[20]; ItemQuantity: Integer): Code[20]
    begin
        // Creates a Purchase order for the given item.
        exit(CreatePurchaseSupplyBasis(ItemNo, ItemQuantity, '', WorkDate()));
    end;

    local procedure CreatePurchaseSupplyAtLocation(ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Code[20]
    begin
        // Creates a Purchase order for the given item at the specified location.
        exit(CreatePurchaseSupplyBasis(ItemNo, ItemQuantity, LocationCode, WorkDate()));
    end;

    local procedure CreatePurchaseSupplyAfter(ItemNo: Code[20]; Quantity: Integer; ReceiptDate: Date): Code[20]
    begin
        // Creates a Purchase order for the given item After a source document date.
        exit(CreatePurchaseSupplyBasis(ItemNo, Quantity, '', CalcDate('<+1D>', ReceiptDate)));
    end;

    local procedure CreatePurchSupplyWithUOMAtLocation(ItemNo: Code[20]; LocationCode: Code[10]; UOMCode: Code[10]; Quantity: Decimal; ReceiptDate: Date) DocumentNo: Code[20]
    begin
        DocumentNo := CreatePurchaseSupplyAtLocation(ItemNo, Quantity, LocationCode);
        UpdatePurchLineUOMAndReceiptDate(DocumentNo, UOMCode, ReceiptDate);
    end;

    local procedure CreateSalesDemandBasis(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]; ShipDate: Date): Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // Creates a sales order for the given item.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipDate);
        SalesLine.Modify();
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDemand(ItemNo: Code[20]; ItemQuantity: Integer): Code[20]
    begin
        // Creates a sales order for the given item.
        exit(CreateSalesDemandBasis(ItemNo, ItemQuantity, '', WorkDate()));
    end;

    local procedure CreateSalesDemandAtLocation(ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Code[20]
    var
        SalesOrderNo: Code[20];
    begin
        SalesOrderNo := CreateSalesDemand(ItemNo, ItemQuantity);
        SetSalesDemandLocation(SalesOrderNo, LocationCode);
        exit(SalesOrderNo);
    end;

    local procedure CreateSalesDemandAfter(ItemNo: Code[20]; Quantity: Integer; ShipDate: Date): Code[20]
    begin
        // Creates sales order after a source document date.
        exit(CreateSalesDemandBasis(ItemNo, Quantity, '', CalcDate('<+1D>', ShipDate)));
    end;

    local procedure CreateSalesLocationDemandAfter(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]; ShipDate: Date): Code[20]
    begin
        // Creates sales order for a specific item at a specified date.
        exit(CreateSalesDemandBasis(ItemNo, Quantity, LocationCode, CalcDate('<+1D>', ShipDate)));
    end;

    local procedure UpdatePurchLineUOMAndReceiptDate(PurchaseOrderNo: Code[20]; UOMCode: Code[10]; ReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrderNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Unit of Measure Code", UOMCode);
        PurchaseLine.Validate("Expected Receipt Date", ReceiptDate);
        PurchaseLine.Modify(true);
    end;

    [Normal]
    local procedure EditSalesOrderType(SalesOrderNo: Code[20]; SaleType: Code[20])
    begin
        // Method Edits Sales Order Type.
        OpenSalesOrderPageByNo(SalesOrderNo, SalesOrder);

        // EXECUTE: Change Demand Type on Sales Order Through UI.
        SalesOrder.SalesLines.Type.Value(SaleType);
        SalesOrder.Close();
    end;

    [Normal]
    local procedure EditSalesOrderQuantity(SalesOrderNo: Code[20]; SalesQuantity: Integer)
    begin
        // Method Edits Sales Order Quantity.
        OpenSalesOrderPageByNo(SalesOrderNo, SalesOrder);

        // EXECUTE: Change Demand Quantity on Sales Order Through UI.
        SalesOrder.SalesLines.Quantity.Value(Format(SalesQuantity));
        SalesOrder.Close();
    end;

    local procedure GetShipmentDate(SalesHeaderNo: Code[20]): Date
    var
        SalesLine: Record "Sales Line";
    begin
        // Method returns the shipment date from a sales order.
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.FindFirst();
        if SalesLine.Count > 0 then
            exit(SalesLine."Shipment Date");
        Error(ShipmentDateDocumentErr, SalesHeaderNo);
    end;

    local procedure GetReceiptDate(PurchaseHeaderNo: Code[20]): Date
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Method returns the expected receipt date from a purchase order.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeaderNo);
        PurchaseLine.FindFirst();
        if PurchaseLine.Count > 0 then
            exit(PurchaseLine."Expected Receipt Date");
        Error(ReceiptDateDocumentErr, PurchaseHeaderNo);
    end;

    [Normal]
    local procedure OpenSalesOrderPageByNo(SalesOrderNoToFind: Code[20]; SalesOrderToReturn: TestPage "Sales Order")
    var
        SalesHeader: Record "Sales Header";
    begin
        // Method Opens sales order page for the sales order no.
        SalesOrderToReturn.OpenEdit();
        Assert.IsTrue(
          SalesOrderToReturn.GotoKey(SalesHeader."Document Type"::Order, SalesOrderNoToFind),
          'Unable to locate sales order with order no');
    end;

    local procedure ValidateQuantity(DocumentNo: Code[20]; Quantity: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Method verifies the quantity on a sales order.
        if SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo) then begin
            SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.FindFirst();
            Assert.AreEqual(Quantity, SalesLine.Quantity, 'Verify Sales Line Quantity matches expected');
            exit;
        end;

        Error(ValidateQuantityDocumentErr, DocumentNo);
    end;

    local procedure SetSalesUOMPageTestability(SalesOrderNo: Code[20]; UOM: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        Clear(SalesOrder);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        Evaluate(SaleQuantity, SalesOrder.SalesLines.Quantity.Value);
        SalesOrder.SalesLines."Unit of Measure Code".SetValue(UOM);  // Should trigger the avail.warning
        SalesOrder.Close();
    end;

    local procedure GetPcsUOM(ItemNo: Code[20]): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        ItemUnitOfMeasure.SetRange("Qty. per Unit of Measure", 1);
        ItemUnitOfMeasure.FindFirst();
        exit(ItemUnitOfMeasure.Code);
    end;

    local procedure SetSalesDemandLocation(SalesOrderNo: Code[20]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get("Sales Document Type"::Order, SalesOrderNo, 10000);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendAvailabilityNotificationHandler(var Notification: Notification): Boolean
    var
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        Quantity: Integer;
        Inventory: Decimal;
        TotalQuantity: Decimal;
        SchedRcpt: Decimal;
        ReservedRcpt: Decimal;
        GrossReq: Decimal;
        ReservedReq: Decimal;
    begin
        Item.Get(SalesOrder.SalesLines."No.".Value);
        Assert.AreEqual(Notification.GetData('ItemNo'), Item."No.", 'Item No. was different than expected');
        Item.CalcFields(Inventory);
        Evaluate(Inventory, Notification.GetData('InventoryQty'));
        Assert.AreEqual(Inventory, Item.Inventory, 'Available Inventory was different than expected');
        Evaluate(Quantity, Notification.GetData('CurrentQuantity'));
        Evaluate(TotalQuantity, Notification.GetData('TotalQuantity'));
        Evaluate(ReservedReq, Notification.GetData('ReservedReq'));
        Evaluate(SchedRcpt, Notification.GetData('SchedRcpt'));
        Evaluate(GrossReq, Notification.GetData('GrossReq'));
        Evaluate(ReservedRcpt, Notification.GetData('ReservedRcpt'));
        Assert.AreEqual(TotalQuantity, Inventory - Quantity + (SchedRcpt - ReservedRcpt) - (GrossReq - ReservedReq),
          'Total quantity different than expected');
        Assert.AreEqual(Quantity, SaleQuantity, 'Quantity was different than expected');
        ItemCheckAvail.ShowNotificationDetails(Notification);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NotificationDetailsHandler(var ItemAvailabilityCheck: TestPage "Item Availability Check")
    var
        Item: Record Item;
    begin
        Item.Get(SalesOrder.SalesLines."No.".Value);
        Item.CalcFields(Inventory);
        ItemAvailabilityCheck.AvailabilityCheckDetails."No.".AssertEquals(Item."No.");
        ItemAvailabilityCheck.AvailabilityCheckDetails.Description.AssertEquals(Item.Description);
        ItemAvailabilityCheck.AvailabilityCheckDetails.CurrentQuantity.AssertEquals(SaleQuantity);
        ItemAvailabilityCheck.InventoryQty.AssertEquals(Item.Inventory);
    end;

    [ModalPageHandler]
    procedure ItemAvailabilityCheckModalPageHandler(var ItemAvailabilityCheck: TestPage "Item Availability Check")
    begin
        ItemAvailabilityCheck."Purchase Order".Invoke();
    end;
}

