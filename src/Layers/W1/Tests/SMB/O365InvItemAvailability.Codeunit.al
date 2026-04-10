codeunit 138048 "O365 Inv. Item Availability"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Availability] [Inventory]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        ItemNotFoundErr: Label 'Item not found.';

    [Test]
    [Scope('OnPrem')]
    procedure AvailabilityByPeriod()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByPeriod: TestPage "Item Availability by Periods";
        ExistingQuantity: Integer;
        DemandQuantity: Integer;
    begin
        // SETUP: Create an item and demand for the item on the workdate of the system.
        Initialize();
        ExistingQuantity := LibraryRandom.RandIntInRange(20, 100);
        DemandQuantity := LibraryRandom.RandInt(ExistingQuantity - 1);

        CreateItem(Item, ExistingQuantity);
        CreateSalesDemand(Item."No.", DemandQuantity);

        // EXECUTE: Open the Item Availability By Period page.
        ViewItemCard(ItemCard, Item);

        ItemAvailabilityByPeriod.Trap();
        ItemCard.Period.Invoke();
        SetDemandByPeriodFilters(ItemAvailabilityByPeriod, Item."No.", WorkDate());

        // VERIFY: The quantities in demand by period grid columns for the demand date
        AssertDemandByPeriodQuantities(ExistingQuantity - DemandQuantity, ItemAvailabilityByPeriod);
        ItemAvailabilityByPeriod.Close();
    end;

    [Test]
    [HandlerFunctions('ItemAvailByEventHandler')]
    [Scope('OnPrem')]
    procedure AvailabilityByEvent()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ExistingQuantity: Integer;
        DemandQuantity: Integer;
    begin
        // SETUP: Create an item and demand for the item on the workdate of the system.
        Initialize();
        ExistingQuantity := LibraryRandom.RandIntInRange(20, 100);
        DemandQuantity := LibraryRandom.RandInt(ExistingQuantity - 1);

        CreateItem(Item, ExistingQuantity);
        CreateSalesDemand(Item."No.", DemandQuantity);

        // SETUP: Enqueue value for ItemAvailByEventHandler.
        LibraryVariableStorage.Enqueue(ExistingQuantity - DemandQuantity);

        // EXECUTE: Open the Item Availability By Event page.
        ViewItemCard(ItemCard, Item);
        ItemCard."<Action110>".Invoke();

        // VERIFY: Verification is in the handler
    end;

    [Test]
    [HandlerFunctions('VendorListPickVendorModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchInvOpensVendorSelectionPageWhenVendorNoIsEmpty()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemAvailabilityCheck: TestPage "Item Availability Check";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        // [GIVEN] Item "ITEM" with empty Vendor No.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", '');
        Item.Modify(true);

        // [GIVEN] Vendor "VEND"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        ItemAvailabilityCheck.OpenEdit();
        ItemAvailabilityCheck.GotoRecord(Item);

        // [WHEN] Invoke 'Create Purchase Order' action and pick vendor VEND
        LibraryVariableStorage.Enqueue(Vendor."No.");
        PurchaseInvoice.Trap();
        ItemAvailabilityCheck."Purchase Invoice".Invoke();

        // [THEN] Purchase invoice created for vendor "VEND"
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        // [THEN] Purchase invoice has line with item "ITEM"
        PurchaseInvoice.PurchLines."No.".AssertEquals(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchInvUsesTheVendorNoFromItem()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemAvailabilityCheck: TestPage "Item Availability Check";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        // [GIVEN] Item "ITEM" with Vendor No. = "VEND"
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        ItemAvailabilityCheck.OpenEdit();
        ItemAvailabilityCheck.GotoRecord(Item);

        // [WHEN] Invoke 'Create Purchase Order' action
        PurchaseInvoice.Trap();
        ItemAvailabilityCheck."Purchase Invoice".Invoke();

        // [THEN] Purchase invoice created for vendor "VEND"
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        // [THEN] Purchase invoice has line with item "ITEM"
        PurchaseInvoice.PurchLines."No.".AssertEquals(Item."No.");
    end;

    [Test]
    [HandlerFunctions('VendorListPickVendorModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchOrderItemVendorNoIsEmptyVendorSelected()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemAvailabilityCheck: TestPage "Item Availability Check";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 264628] Create Purchase Order action for item with empty Vendor No after vendor selection creates and opens a new purchase order
        Initialize();

        // [GIVEN] Item "ITEM" with empty Vendor No.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", '');
        Item.Modify(true);

        // [GIVEN] Vendor "VEND"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        ItemAvailabilityCheck.OpenEdit();
        ItemAvailabilityCheck.GotoRecord(Item);

        // [WHEN] Invoke 'Create Purchase Order' action and pick vendor VEND
        LibraryVariableStorage.Enqueue(Vendor."No.");
        PurchaseOrder.Trap();
        ItemAvailabilityCheck."Purchase Order".Invoke();

        // [THEN] Purchase order created for vendor "VEND"
        PurchaseOrder."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        // [THEN] Purchase order has line with item "ITEM"
        PurchaseOrder.PurchLines."No.".AssertEquals(Item."No.");
    end;

    [Test]
    [HandlerFunctions('VendorListCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchOrderItemVendorNoIsEmptyVendorSelectionCanceled()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemAvailabilityCheck: TestPage "Item Availability Check";
        PurchDocQty: Integer;
    begin
        // [SCENARIO 264628] Create Purchase Order action for item with empty Vendor No and vendor selection canceled a new purchase order is not created
        Initialize();

        // [GIVEN] Item "ITEM" with empty Vendor No.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", '');
        Item.Modify(true);
        PurchDocQty := PurchaseHeader.Count();

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        ItemAvailabilityCheck.OpenEdit();
        ItemAvailabilityCheck.GotoRecord(Item);

        // [WHEN] Invoke 'Create Purchase Order' action and cancel vendor selection
        ItemAvailabilityCheck."Purchase Order".Invoke();

        // [THEN] Purchase order is not created
        Assert.AreEqual(PurchDocQty, PurchaseHeader.Count, 'Purchase document should not be created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchOrderUsesTheVendorNoFromItem()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemAvailabilityCheck: TestPage "Item Availability Check";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 264628] Create Purchase Order action for item with Vendor No makes a new purchase order
        Initialize();

        // [GIVEN] Item "ITEM" with Vendor No. = "VEND"
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        ItemAvailabilityCheck.OpenEdit();
        ItemAvailabilityCheck.GotoRecord(Item);

        // [WHEN] Invoke 'Create Purchase Order' action
        PurchaseOrder.Trap();
        ItemAvailabilityCheck."Purchase Order".Invoke();

        // [THEN] Purchase order created for vendor "VEND"
        PurchaseOrder."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        // [THEN] Purchase order has line with item "ITEM"
        PurchaseOrder.PurchLines."No.".AssertEquals(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByUoM_GrossRequirement()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemAvailabilityByUOM: TestPage "Item Availability by UOM";
        Quantity: array[2] of Decimal;
    begin
        // [FEATURE] [Gross Requirement] [UI]
        // [SCENARIO 292299] Page Item Availability by UoM shows "Gross Requirement" per Unit of Measure
        Initialize();

        // [GIVEN] Item "ITEM" with base unit of measure "UOM1" and additional one "UOM2"
        CreateItemWithUoMs(Item, ItemUnitOfMeasure);

        // [GIVEN] Create sales order line with "UOM1" and Quantity = "Q1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        Quantity[1] := CreateSalesLineWithUoM(SalesHeader, Item."No.", Item."Base Unit of Measure");
        // [GIVEN] Create sales order line with "UOM2" and Quantity = "Q2"
        Quantity[2] := CreateSalesLineWithUoM(SalesHeader, Item."No.", ItemUnitOfMeasure.Code);

        // [WHEN] Open Item Availability Check page for item "ITEM"
        OpenItemAvailabilityByUOMPage(ItemAvailabilityByUOM, Item."No.");

        // [THEN] "Item Availability by UOM" page has line "UOM1" with "Gross Requirement" = "Q1"
        ItemAvailabilityByUOM.ItemAvailUOMLines.Filter.SetFilter(Code, Item."Base Unit of Measure");
        ItemAvailabilityByUOM.ItemAvailUOMLines.GrossRequirement.AssertEquals(Quantity[1]);

        // [THEN] "Item Availability by UOM" page has line "UOM2" with "Gross Requirement" = "Q2"
        ItemAvailabilityByUOM.ItemAvailUOMLines.Filter.SetFilter(Code, ItemUnitOfMeasure.Code);
        ItemAvailabilityByUOM.ItemAvailUOMLines.GrossRequirement.AssertEquals(Quantity[2]);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityLineListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByUoM_GrossRequirementDrillDown()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemAvailabilityByUOM: TestPage "Item Availability by UOM";
        Quantity: array[2] of Decimal;
    begin
        // [FEATURE] [Gross Requirement] [UI]
        // [SCENARIO 292299] Drilldown "Gross Requirement" on page Item Availability by UoM shows quantity per Unit of Measure
        Initialize();

        // [GIVEN] Item "ITEM" with base unit of measure "UOM1" and additional one "UOM2"
        CreateItemWithUoMs(Item, ItemUnitOfMeasure);

        // [GIVEN] Create sales order line with "UOM1" and Quantity = "Q1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        Quantity[1] := CreateSalesLineWithUoM(SalesHeader, Item."No.", Item."Base Unit of Measure");
        // [GIVEN] Create sales order line with "UOM2" and Quantity = "Q2"
        Quantity[2] := CreateSalesLineWithUoM(SalesHeader, Item."No.", ItemUnitOfMeasure.Code);

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        OpenItemAvailabilityByUOMPage(ItemAvailabilityByUOM, Item."No.");

        // [WHEN] Drilldown "Gross Requirement" on line "UOM2"
        ItemAvailabilityByUOM.ItemAvailUOMLines.Filter.SetFilter(Code, ItemUnitOfMeasure.Code);
        ItemAvailabilityByUOM.ItemAvailUOMLines.GrossRequirement.Drilldown();

        // [THEN] Opened "Item Availability Line List" page shows Quantity = "Q2"
        Assert.AreEqual(Quantity[2], LibraryVariableStorage.DequeueDecimal(), 'Wrong Quantity');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByUoM_Inventory()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemAvailabilityByUOM: TestPage "Item Availability by UOM";
        Quantity: array[2] of Decimal;
    begin
        // [FEATURE] [Inventory] [UI]
        // [SCENARIO 292299] Page Item Availability by UoM shows "Inventory" per Unit of Measure
        Initialize();

        // [GIVEN] Item "ITEM" with base unit of measure "UOM1" and additional one "UOM2"
        CreateItemWithUoMs(Item, ItemUnitOfMeasure);

        // [GIVEN] Create Purchase order line with "UOM1" and Quantity = "Q1"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        Quantity[1] := CreatePurchaseLineWithUoM(PurchaseHeader, Item."No.", Item."Base Unit of Measure");
        // [GIVEN] Create Purchase order line with "UOM2" and Quantity = "Q2"
        Quantity[2] := CreatePurchaseLineWithUoM(PurchaseHeader, Item."No.", ItemUnitOfMeasure.Code);
        // [GIVEN] Post purchase order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Open Item Availability Check page for item "ITEM"
        OpenItemAvailabilityByUOMPage(ItemAvailabilityByUOM, Item."No.");

        // [THEN] "Item Availability by UOM" page has line "UOM1" with "Item.Inventory" = "Q1"
        ItemAvailabilityByUOM.ItemAvailUOMLines.Filter.SetFilter(Code, Item."Base Unit of Measure");
        ItemAvailabilityByUOM.ItemAvailUOMLines."Item.Inventory".AssertEquals(Quantity[1]);

        // [THEN] "Item Availability by UOM" page has line "UOM2" with "Item.Inventory" = "Q2"
        ItemAvailabilityByUOM.ItemAvailUOMLines.Filter.SetFilter(Code, ItemUnitOfMeasure.Code);
        ItemAvailabilityByUOM.ItemAvailUOMLines."Item.Inventory".AssertEquals(Quantity[2]);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityLineListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByUoM_ProjectedAvailableBalanceDrillDown()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemAvailabilityByUOM: TestPage "Item Availability by UOM";
        Quantity: Decimal;
    begin
        // [FEATURE] [Projected Available Balance] [UI]
        // [SCENARIO 292299] Drilldown from "Projected Available Balance" on page Item Availability by UoM shows quantity per Unit of Measure
        Initialize();

        // [GIVEN] Item "ITEM" with base unit of measure "UOM1" and additional one "UOM2"
        CreateItemWithUoMs(Item, ItemUnitOfMeasure);

        // [GIVEN] Create Post Purchase order line with "UOM1" and Quantity = "Q2"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        Quantity := CreatePurchaseLineWithUoM(PurchaseHeader, Item."No.", ItemUnitOfMeasure.Code);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        OpenItemAvailabilityByUOMPage(ItemAvailabilityByUOM, Item."No.");

        // [WHEN] Drilldown "Gross Requirement" on line "UOM2"
        ItemAvailabilityByUOM.ItemAvailUOMLines.Filter.SetFilter(Code, ItemUnitOfMeasure.Code);
        ItemAvailabilityByUOM.ItemAvailUOMLines.ProjAvailableBalance.Drilldown();

        // [THEN] Opened "Item Availability Line List" page shows Quantity = "Q2"
        Assert.AreEqual(Quantity, LibraryVariableStorage.DequeueDecimal(), 'Wrong Quantity');
    end;

    [Test]
    [HandlerFunctions('ItemLedgerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByUoM_InventoryDrillDown()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemAvailabilityByUOM: TestPage "Item Availability by UOM";
        Quantity: array[2] of Decimal;
    begin
        // [FEATURE] [Inventory] [UI]
        // [SCENARIO 292299] Drilldown from "Inventory" on page Item Availability by UoM shows item ledger entries filtered by Unit of Measure
        Initialize();

        // [GIVEN] Item "ITEM" with base unit of measure "UOM1" and additional one "UOM2"
        CreateItemWithUoMs(Item, ItemUnitOfMeasure);

        // [GIVEN] Create Post Purchase order line with "UOM1" and Quantity = "Q2"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        Quantity[1] := CreatePurchaseLineWithUoM(PurchaseHeader, Item."No.", Item."Base Unit of Measure");
        // [GIVEN] Create Purchase order line with "UOM2" and Quantity = "Q2"
        Quantity[2] := CreatePurchaseLineWithUoM(PurchaseHeader, Item."No.", ItemUnitOfMeasure.Code);
        // [GIVEN] Post purchase order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        OpenItemAvailabilityByUOMPage(ItemAvailabilityByUOM, Item."No.");

        // [WHEN] Drilldown "Inventory" on line "UOM2"
        ItemAvailabilityByUOM.ItemAvailUOMLines.Filter.SetFilter(Code, ItemUnitOfMeasure.Code);
        ItemAvailabilityByUOM.ItemAvailUOMLines."Item.Inventory".Drilldown();

        // [THEN] Opened "Item Ledger Entries" page shows only record with "UOM2" and Quantity = "Q2" 
        Assert.AreEqual(ItemUnitOfMeasure.Code, LibraryVariableStorage.DequeueText(), 'Wrong Unit of Measure filter');
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByUOMModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PickUnitOfMeasureCodeFromSalesOrderSubform()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales Order] [UI]
        // [SCENARIO 292299] Sales order subform allows user to select unit of measure code with action Line - Item Availability by - Unit of Measure
        Initialize();

        // [GIVEN] Item "ITEM" with base unit of measure "UOM1" and additional one "UOM2"
        CreateItemWithUoMs(Item, ItemUnitOfMeasure);

        // [GIVEN] Create sales order and line with Item "ITEM", unit of measure "UOM1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineWithUoM(SalesHeader, Item."No.", Item."Base Unit of Measure");

        // [GIVEN] Open Sales order card
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [WHEN] Action Line - Item Availability by - Unit of Measure is being hit and "UOM2" selected
        LibraryVariableStorage.Enqueue(ItemUnitOfMeasure.Code);
        SalesOrder.SalesLines.ItemAvailabilityByUnitOfMeasure.Invoke();

        // [THEN] Sales line has Unit of Measure Code = "UOM2"
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Inv. Item Availability");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Inv. Item Availability");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Inv. Item Availability");
    end;

    [Normal]
    local procedure CreateItem(var Item: Record Item; Quantity: Integer)
    var
        AdjustItemInventory: Codeunit "Adjust Item Inventory";
    begin
        // Creates a new item. Wrapper for the library method.
        LibraryInventory.CreateItem(Item);
        AdjustItemInventory.PostAdjustmentToItemLedger(Item, Quantity);
    end;

    local procedure CreateItemWithUoMs(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        UnitOfMeasure: Record "Unit Of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, item."No.", UnitOfMeasure.Code, LibraryRandom.RandInt(100));
    end;

    local procedure CreateSalesDemandBasis(ItemNo: Code[20]; ItemQty: Integer; NeededBy: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, NeededBy, ItemQty);
        SalesLine.Validate("Shipment Date", NeededBy);
        SalesLine.Modify(true);

        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDemand(ItemNo: Code[20]; Quantity: Integer): Code[20]
    begin
        exit(CreateSalesDemandBasis(ItemNo, Quantity, WorkDate()));
    end;

    local procedure CreateSalesLineWithUoM(SalesHeader: record "Sales Header"; ItemNo: Code[20]; UnitOfMeasureCode: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        SalesLine.Modify(true);

        exit(SalesLine.Quantity);
    end;

    local procedure CreatePurchaseLineWithUoM(PurchaseHeader: record "Purchase Header"; ItemNo: Code[20]; UnitOfMeasureCode: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);

        exit(PurchaseLine.Quantity);
    end;

    local procedure OpenItemAvailabilityByUOMPage(var ItemAvailabilityByUOM: TestPage "Item Availability by UOM"; ItemNo: code[20])
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", ItemNo);
        ItemAvailabilityByUOM.Trap();
        ItemCard."Unit of Measure".Invoke();
    end;

    [Normal]
    local procedure ViewItemCard(var ItemCard: TestPage "Item Card"; Item: Record Item)
    begin
        ItemCard.OpenView();

        if not ItemCard.GotoRecord(Item) then
            Error(ItemNotFoundErr);
    end;

    [Normal]
    local procedure SetDemandByPeriodFilters(ItemAvailabilityByPeriod: TestPage "Item Availability by Periods"; ItemNo: Code[20]; FilterDate: Date)
    var
        StartDate: Date;
    begin
        ItemAvailabilityByPeriod.FILTER.SetFilter("No.", ItemNo);
        ItemAvailabilityByPeriod.ItemAvailLines.FILTER.SetFilter("Period Start", Format(FilterDate));
        ItemAvailabilityByPeriod.PeriodType.Value := 'Day';
        ItemAvailabilityByPeriod.ItemAvailLines.First();
        StartDate := ItemAvailabilityByPeriod.ItemAvailLines."Period Start".AsDate();
        Assert.AreEqual(FilterDate, StartDate, 'SetFilter returned record with correct date');
    end;

    [Normal]
    local procedure AssertDemandByPeriodQuantities(Forecasted: Integer; var ItemAvailabilityByPeriod: TestPage "Item Availability by Periods")
    begin
        ItemAvailabilityByPeriod.ItemAvailLines.ProjAvailableBalance.AssertEquals(Forecasted);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailByEventHandler(var ItemAvailabilityByEvent: TestPage "Item Availability by Event")
    begin
        ItemAvailabilityByEvent.FILTER.SetFilter("Period Start", Format(WorkDate()));
        ItemAvailabilityByEvent.First();
        ItemAvailabilityByEvent."Projected Inventory".AssertEquals(LibraryVariableStorage.DequeueInteger());

        ItemAvailabilityByEvent.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorListPickVendorModalPageHandler(var VendorList: TestPage "Vendor List")
    begin
        VendorList.GotoKey(LibraryVariableStorage.DequeueText());
        VendorList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorListCancelModalPageHandler(var VendorList: TestPage "Vendor List")
    begin
        VendorList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityLineListModalPageHandler(var ItemAvailabilityLineList: TestPage "Item Availability Line List")
    begin
        LibraryVariableStorage.Enqueue(ItemAvailabilityLineList.Quantity.Value);
        ItemAvailabilityLineList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByUOMModalPageHandler(var ItemAvailabilityByUOM: TestPage "Item Availability by UOM")
    begin
        ItemAvailabilityByUOM.ItemAvailUOMLines.Filter.SetFilter(Code, LibraryVariableStorage.DequeueText());
        ItemAvailabilityByUOM.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesModalPageHandler(var ItemLedgerEntries: TestPage "Item Ledger Entries")
    begin
        LibraryVariableStorage.Enqueue(ItemLedgerEntries.Filter.GetFilter("Unit of Measure Code"));
        ItemLedgerEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

