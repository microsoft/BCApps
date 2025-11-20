codeunit 137077 "SCM Supply Planning -IV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationSilver: Record Location;
        LocationBlue: Record Location;
        LocationRed: Record Location;
        LocationInTransit: Record Location;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ShopCalendarMgt: Codeunit "Shop Calendar Management";
        isInitialized: Boolean;
        VendorNoErr: Label 'Vendor No. must have a value in Requisition Line';
        RequisitionLinesQuantityErr: Label 'Quantity value must match.';
        AvailabilityWarningConfirmationErr: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        ReleasedProdOrderCreatedMsg: Label 'Released Prod. Order';
        SalesLineQtyChangedMsg: Label 'This Sales Line is currently planned. Your changes will not cause any replanning.';
        RequisitionLineQtyErr: Label 'The Quantity of component Item on Requisition Line is not correct.';
        RequisitionLineExistenceErr: Label 'Requisition Line expected to %1 for Item %2 and Location %3', Comment = '%1 = "Exist/Not exist", %2 = Item No., %3 = Location code';
        ReqLineExpectedTo: Option "Not Exist",Exist;
        RequisitionLineProdOrderErr: Label '"Prod Order No." should be same as Released Production Order';
        CloseBOMVersionsQst: Label 'All versions attached to the BOM will be closed';
        NotAllItemsPlannedMsg: Label 'Not all items were planned. A total of %1 items were not planned.', Comment = '%1 = count of items not planned';
        PeriodType: Option Day,Week,Month,Quarter,Year,Period;
        AmountType: Option "Net Change","Balance at Date";
        AppliesToEntryMissingErr: Label 'Applies-to Entry must have a value';
        ItemNoErr: Label 'Item No. must be equal';

    [Test]
    [Scope('OnPrem')]
    procedure ProductionBOMNoRoutingNoOnSKUUsedWhileManualCreationOfLinesOnPlanningWorksheet()
    var
        Item: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        Initialize();

        // Create a Cerfitied Routing 
        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader);

        // Create Requisition Line
        RequisitionLine.Init();
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate(Quantity, 1);

        // Setting the Location Code and Variant Code selects the Routing No. and Produciton BOM No. from SKU
        RequisitionLine.Validate("Location Code", Location.Code);
        RequisitionLine.Validate("Variant Code", ItemVariant.Code);
        RequisitionLine.TestField("Location Code", Location.Code); // Make sure Location Code is not reset to ''

        Assert.AreEqual(RoutingHeader."No.", RequisitionLine."Routing No.", 'Routing No. is not set correctly');
        Assert.AreEqual(ProductionBOMHeader."No.", RequisitionLine."Production BOM No.", 'Production BOM No. is not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionBOMNoRoutingNoOnSKUUsedWhenCalculatePlanOnOrderPlanningPageIsInvoked()
    var
        Item: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM and Routing
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader);

        // Create SalesOrder
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);

        // CalculatePlan on OrderPlanning
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // The requisition Line has the information defined on SKU.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        Assert.RecordIsNotEmpty(RequisitionLine);
        Assert.RecordCount(RequisitionLine, 1);

        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", Location.Code);
        RequisitionLine.TestField("Variant Code", ItemVariant.Code);
        RequisitionLine.TestField("Production BOM No.", ProductionBOMHeader."No.");
        RequisitionLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionBOMNoRoutingNoOnSKUUsedWhenCalculateRegPlanOnPlanningWorksheetIsInvoked()
    var
        Item: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();

        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM and Routing
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader);

        // Create SalesOrder
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);

        StartDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", -1);  // Start Date less than Shipment Date.
        EndDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", 1);  // End Date more than Shipment Date.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);

        // The requisition Line has the information defined on SKU.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        Assert.RecordIsNotEmpty(RequisitionLine);
        Assert.RecordCount(RequisitionLine, 1);

        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", Location.Code);
        RequisitionLine.TestField("Variant Code", ItemVariant.Code);
        RequisitionLine.TestField("Production BOM No.", ProductionBOMHeader."No.");
        RequisitionLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('OrderPromisingLinesAcceptCapableToPromisePageHandler')]
    procedure ProductionBOMNoRoutingNoOnSKUUsedWhenCapableToPromiseOnSalesOrderIsInvoked()
    var
        Item: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        Initialize();

        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM and Routing
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader);

        // Create SalesOrder
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);

        // Run Order Promising and accept suggestions
        RunOrderPromisingFromSalesHeader(SalesHeader);

        // The requisition Line has the information defined on SKU.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        Assert.RecordIsNotEmpty(RequisitionLine);
        Assert.RecordCount(RequisitionLine, 1);

        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", Location.Code);
        RequisitionLine.TestField("Variant Code", ItemVariant.Code);
        RequisitionLine.TestField("Production BOM No.", ProductionBOMHeader."No.");
        RequisitionLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMNoFromItemUsedWhenEmptyOnSKUWhileManualCreationOfLinesOnPlanningWorksheet()
    var
        Item: Record Item;
        Item2: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMHeader2: Record "Production BOM Header";
    begin
        Initialize();

        // Create a Cerfitied Routing 
        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader, true, false);

        // Create a new certified Produciton BOM and set it on Item
        CreateChildItemAsProdBOM(Item2, ProductionBOMHeader2, Item2."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader2."No.");

        // Create Requisition Line
        RequisitionLine.Init();
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate(Quantity, 1);

        // Setting the Location Code and Variant Code selects the Routing No. and Produciton BOM No. from SKU
        RequisitionLine.Validate("Location Code", Location.Code);
        RequisitionLine.Validate("Variant Code", ItemVariant.Code);

        Assert.AreEqual(RoutingHeader."No.", RequisitionLine."Routing No.", 'Routing No. is not set correctly');
        Assert.AreEqual(ProductionBOMHeader2."No.", RequisitionLine."Production BOM No.", 'Production BOM No. is not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMNoFromItemUsedWhenEmptyOnSKUWhenCalculatePlanOnOrderPlanningPageIsInvoked()
    var
        Item: Record Item;
        Item2: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMHeader2: Record "Production BOM Header";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM and Routing
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader, true, false);

        // Create a new certified Produciton BOM and set it on Item
        CreateChildItemAsProdBOM(Item2, ProductionBOMHeader2, Item2."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader2."No.");

        // Create SalesOrder
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);

        // CalculatePlan on OrderPlanning
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // The requisition Line has the information defined on SKU.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        Assert.RecordIsNotEmpty(RequisitionLine);
        Assert.RecordCount(RequisitionLine, 1);

        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", Location.Code);
        RequisitionLine.TestField("Variant Code", ItemVariant.Code);
        RequisitionLine.TestField("Production BOM No.", ProductionBOMHeader2."No.");
        RequisitionLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMNoFromItemUsedWhenEmptyOnSKUWhenCalculateRegPlanOnPlanningWorksheetIsInvoked()
    var
        Item: Record Item;
        Item2: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMHeader2: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();

        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM and Routing
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader, true, false);

        // Create a new certified Produciton BOM and set it on Item
        CreateChildItemAsProdBOM(Item2, ProductionBOMHeader2, Item2."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader2."No.");

        // Create SalesOrder
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);

        StartDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", -1);  // Start Date less than Shipment Date.
        EndDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", 1);  // End Date more than Shipment Date.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);

        // The requisition Line has the information defined on SKU.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        Assert.RecordIsNotEmpty(RequisitionLine);
        Assert.RecordCount(RequisitionLine, 1);

        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", Location.Code);
        RequisitionLine.TestField("Variant Code", ItemVariant.Code);
        RequisitionLine.TestField("Production BOM No.", ProductionBOMHeader2."No.");
        RequisitionLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('OrderPromisingLinesAcceptCapableToPromisePageHandler')]
    procedure ProdBOMNoFromItemUsedWhenEmptyOnSKUWhenCapableToPromiseOnSalesOrderIsInvoked()
    var
        Item: Record Item;
        Item2: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMHeader2: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        Initialize();

        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM and Routing
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader, true, false);

        // Create a new certified Produciton BOM and set it on Item
        CreateChildItemAsProdBOM(Item2, ProductionBOMHeader2, Item2."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader2."No.");

        // Create SalesOrder
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);

        // Run Order Promising and accept suggestions
        RunOrderPromisingFromSalesHeader(SalesHeader);

        // The requisition Line has the information defined on SKU.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        Assert.RecordIsNotEmpty(RequisitionLine);
        Assert.RecordCount(RequisitionLine, 1);

        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", Location.Code);
        RequisitionLine.TestField("Variant Code", ItemVariant.Code);
        RequisitionLine.TestField("Production BOM No.", ProductionBOMHeader2."No.");
        RequisitionLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingNoFromItemUsedWhenEmptyOnSKUWhileManualCreationOfLinesOnPlanningWorksheet()
    var
        Item: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        Initialize();

        // Create a Cerfitied Routing 
        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader, false, true);

        // Create a new certified routing and set it on Item
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CertifyRouting(RoutingHeader);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // Create Requisition Line
        RequisitionLine.Init();
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate(Quantity, 1);

        // Setting the Location Code and Variant Code selects the Routing No. and Produciton BOM No. from SKU
        RequisitionLine.Validate("Location Code", Location.Code);
        RequisitionLine.Validate("Variant Code", ItemVariant.Code);

        Assert.AreEqual(RoutingHeader."No.", RequisitionLine."Routing No.", 'Routing No. is not set correctly');
        Assert.AreEqual(ProductionBOMHeader."No.", RequisitionLine."Production BOM No.", 'Production BOM No. is not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingNoFromItemUsedWhenEmptyOnSKUWhenCalculatePlanOnOrderPlanningPageIsInvoked()
    var
        Item: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM and Routing
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader, false, true);

        // Create a new certified routing and set it on Item
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CertifyRouting(RoutingHeader);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // Create SalesOrder
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);

        // CalculatePlan on OrderPlanning
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // The requisition Line has the information defined on SKU.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        Assert.RecordIsNotEmpty(RequisitionLine);
        Assert.RecordCount(RequisitionLine, 1);

        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", Location.Code);
        RequisitionLine.TestField("Variant Code", ItemVariant.Code);
        RequisitionLine.TestField("Production BOM No.", ProductionBOMHeader."No.");
        RequisitionLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingNoFromItemUsedWhenEmptyOnSKUWhenCalculateRegPlanOnPlanningWorksheetIsInvoked()
    var
        Item: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();

        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM and Routing
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader, false, true);

        // Create a new certified routing and set it on Item
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CertifyRouting(RoutingHeader);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // Create SalesOrder
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);

        StartDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", -1);  // Start Date less than Shipment Date.
        EndDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", 1);  // End Date more than Shipment Date.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);

        // The requisition Line has the information defined on SKU.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        Assert.RecordIsNotEmpty(RequisitionLine);
        Assert.RecordCount(RequisitionLine, 1);

        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", Location.Code);
        RequisitionLine.TestField("Variant Code", ItemVariant.Code);
        RequisitionLine.TestField("Production BOM No.", ProductionBOMHeader."No.");
        RequisitionLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('OrderPromisingLinesAcceptCapableToPromisePageHandler')]
    procedure RoutingNoFromItemUsedWhenEmptyOnSKUWhenCapableToPromiseOnSalesOrderIsInvoked()
    var
        Item: Record Item;
        StockKeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        Initialize();

        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        // Create a certified Produciton BOM and Routing
        // Set the Produciton BOM No. and Routing No. on the SKU
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader, false, true);

        // Create a new certified routing and set it on Item
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CertifyRouting(RoutingHeader);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // Create SalesOrder
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);

        // Run Order Promising and accept suggestions
        RunOrderPromisingFromSalesHeader(SalesHeader);

        // The requisition Line has the information defined on SKU.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        Assert.RecordIsNotEmpty(RequisitionLine);
        Assert.RecordCount(RequisitionLine, 1);

        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", Location.Code);
        RequisitionLine.TestField("Variant Code", ItemVariant.Code);
        RequisitionLine.TestField("Production BOM No.", ProductionBOMHeader."No.");
        RequisitionLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Exercise: Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Subcontracting Worksheet for Production Order, Quantity and WorkCenter Subcontractor.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLine(RequisitionLine, ProductionOrder, WorkCenter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Exercise: After carry out, Post Purchase Order as Receive and invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, true);

        // Verify: Verify Inventory of Item is updated after Purchase Order posting for Item.
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, PurchaseLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubcontractCreditMemoSkipBaseQtyBalCheck()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        PurchInvoiceHeader: Record "Purch. Inv. Header";
        PurchCreditMemo: Record "Purchase Header";
        ReasonCode: Record "Reason Code";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO] Bug 420029 - Validation for quantity and base quantity balance should be skipped for subcontract credit memo
        // [GIVEN] Item, routing, work center.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");
        LibraryERM.CreateReasonCode(ReasonCode);

        // [GIVEN] Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // [GIVEN] Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [WHEN] After carry out, Post Purchase Order as Receive and invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, true);

        // [WHEN] Create corrective credit memo
        PurchInvoiceHeader.SetRange("Order No.", PurchaseLine."Document No.");
        PurchInvoiceHeader.FindFirst();
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvoiceHeader, PurchCreditMemo);

        // [THEN] Validation of base qty balanced should not be triggered when Updating Qty. to Invoice in credit memo lines
        // [THEN] Instead, missing applies-to entry error is thrown
        PurchCreditMemo.Validate("Vendor Cr. Memo No.", PurchCreditMemo."No.");
        PurchCreditMemo.Validate("Reason Code", ReasonCode.Code);
        PurchCreditMemo.Modify(true);
        asserterror LibraryPurchase.PostPurchaseDocument(PurchCreditMemo, true, true);
        Assert.ExpectedError(AppliesToEntryMissingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProdOrderWithBinAndCarryOutForPurchase()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order with Location and Bin.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", LocationSilver.Code, Bin.Code);

        // Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Exercise: Carry Out Action Message for Subcontracting worksheet.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Verify: Verify Location and Bin of Released Production order is also updated on Purchase Order created after carry out.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField("Location Code", ProductionOrder."Location Code");
        PurchaseLine.TestField("Bin Code", ProductionOrder."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutWithNewDueDateAndQuantity()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Calculate Subcontracts from Subcontracting worksheet. Update new Quantity and Due Date on Requisition Line.
        CalculateSubcontractOrder(WorkCenter);
        UpdateRequisitionLineDueDateAndQuantity(
          RequisitionLine, Item."No.", ProductionOrder.Quantity + LibraryRandom.RandDec(10, 2));  // Quantity more than Production Order Quantity.

        // Exercise: Carry Out Action Message for Subcontracting worksheet.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Verify: Verify updated Due Date and quantity of Requisition Line is also updated on Purchase Order created after carry out.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField(Quantity, RequisitionLine.Quantity);
        PurchaseLine.TestField("Expected Receipt Date", RequisitionLine."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutForReleasedProdOrderWithUpdatedUOM()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // Setup: Create Item. Create Routing and update on Item. Create additional Base Unit of Measure for Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);

        // Create and refresh Released Production Order. Update new Unit Of Measure on Production Order Line.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.
        UpdateProdOrderLineUnitOfMeasureCode(Item."No.", ItemUnitOfMeasure.Code);

        // Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Exercise: Carry Out Action Message for Subcontracting worksheet.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Verify: Verify updated Unit of Measure of Released Production Order is also updated on Purchase Order created after carry out.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField("Unit of Measure", ItemUnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderWithProdOrderRoutingLineForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Exercise: Calculate Subcontracts from Subcontracting worksheet With Production Order Routing Line.
        CalculateSubcontractsWithProdOrderRoutingLine(ProductionOrder."No.", WorkDate());

        // Verify: Verify that no Requisition line is created for Subcontracting Worksheet.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderWithMultiLineRoutingForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
    begin
        // Setup: Create Item. Create Multi Line Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateAndCertifyMultiLineRoutingSetup(WorkCenter, RoutingHeader, RoutingLine, RoutingLine2);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Exercise: Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Subcontracting Worksheet for Production Order, Quantity, WorkCenter Subcontractor and Operation No.
        VerifyRequisitionLineWithOperationNoForSubcontractingWorksheet(
          ProductionOrder, WorkCenter, Item."No.", RoutingLine."Operation No.");
        VerifyRequisitionLineWithOperationNoForSubcontractingWorksheet(
          ProductionOrder, WorkCenter, Item."No.", RoutingLine2."Operation No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshWithCarryOutOrderItemVendorNoError()
    var
        Item: Record Item;
    begin
        // Setup: Create Order Item without updating Vendor No on it.
        Initialize();
        CreateOrderItem(Item);

        // Create Sales Order.
        CreateSalesOrder(Item."No.", '');

        // Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Exercise: Carry Out Action Message for Planning worksheet.
        asserterror CarryOutActionMessage(Item."No.");

        // Verify: Verify error - Vendor No. must have a value in Requisition Line for carry out.
        Assert.ExpectedError(VendorNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithCarryOutOrderItemVendorNoError()
    var
        Item: Record Item;
    begin
        // Setup: Create Order Item without updating Vendor No on it.
        Initialize();
        CreateOrderItem(Item);

        // Create Sales Order.
        CreateSalesOrder(Item."No.", '');

        // Calculate Plan for Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Exercise: Carry Out Action Message for Requisition Worksheet.
        asserterror CarryOutActionMessage(Item."No.");

        // Verify: Verify error - Vendor No. must have a value in Requisition Line for carry Out.
        Assert.ExpectedError(VendorNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseShippingDetailsWithDropShipmentAndCarryOutOnReqWksh()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item.
        Initialize();
        CreateItem(Item);

        // Create Sales Order with Ship to Address and Purchasing Code Drop Shipment.
        CreateSalesOrder(Item."No.", CreateCustomerWithLocation());
        UpdateSalesLineWithDropShipmentPurchasingCode(SalesLine, Item."No.", LocationSilver.Code);

        // Exercise: Get Sales Order From Drop Shipment on Requisition Worksheet and Carry out.
        GetSalesOrderForDropShipmentAndCarryOutReqWksh(SalesLine);

        // Verify: Verify Ship to Address and Ship to Code of Sales Order is also updated on Purchase Order created after Carry Out.
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        VerifyPurchaseShippingDetails(Item."No.", SalesHeader."Ship-to Code", SalesHeader."Ship-to Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseShippingDetailsWithSpecialOrderAndCarryOutOnReqWksh()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item.
        Initialize();
        CreateItem(Item);

        // Create Sales Order with Ship to Address and Purchasing Code Special Order.
        CreateSalesOrder(Item."No.", CreateCustomerWithLocation());
        UpdateSalesLineWithSpecialOrderPurchasingCode(SalesLine, Item."No.", LocationBlue.Code);

        // Exercise: Get Sales Order From Special Order on Requisition Worksheet and Carry out.
        GetSalesOrderForSpecialOrderAndCarryOutReqWksh(Item."No.");

        // Verify: Verify Ship to Address and Ship to Code of Sales Order is also updated on Purchase Order created after Carry Out.
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        VerifyPurchaseShippingDetails(Item."No.", '', LocationBlue.Address);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForTranferShipWithoutReorderingPolicy()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item without Reordering Policy.
        Initialize();
        CreateItem(Item);

        // Update Inventory.
        Quantity := LibraryRandom.RandDec(10, 2);
        UpdateInventory(Item."No.", Quantity, LocationBlue.Code);

        // Create and Post Transfer Order.
        CreateTransferOrderWithReceiptDate(TransferHeader, Item."No.", LocationBlue.Code, LocationRed.Code, Quantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);  // Ship -TRUE.

        // Exercise: Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Verify: Verify that no Requisition line is created for Requisition Worksheet.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionLineWhenCalculateCapableToPromiseReplenishProdOrderLFLItem()
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        OrderPromisingSetup: Record "Order Promising Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        OldReqTemplateType: Enum "Req. Worksheet Template Type";
    begin
        // Setup: Create Lot for Lot Item with Replenishment System Production Order.
        Initialize();
        OrderPromisingSetup.Get();
        ReqWkshTemplate.Get(OrderPromisingSetup."Order Promising Template");
        OldReqTemplateType := ReqWkshTemplate.Type;
        if ReqWkshTemplate.Type <> ReqWkshTemplate.Type::Planning then begin
            ReqWkshTemplate.Type := ReqWkshTemplate.Type::Planning;
            ReqWkshTemplate.Modify();
        end;

        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order");

        // Create Sales Order.
        CreateSalesOrder(Item."No.", '');

        // Exercise: Open Order Promising Lines Page and Invoke Capable to Promise to create Requisition Worksheet Line.
        FindSalesLine(SalesLine, Item."No.");
        OpenOrderPromisingPage(SalesLine."Document No.");  // Using Page to avoid Due Date error - OrderPromisingPageHandler.

        // Verify: Verify Requisition Line with Action Message,Quantity and Due Date after Calculating Capable To Promise.
#pragma warning disable AA0181
        SalesLine.Find();  // Required to maintain the instance of Sales Line.
#pragma warning restore
        VerifyRequisitionLineEntries(
          Item."No.", '', RequisitionLine."Action Message"::New, SalesLine."Shipment Date", 0, SalesLine.Quantity,
          RequisitionLine."Ref. Order Type"::"Prod. Order");

        // Restore Order Promising Setup
        if ReqWkshTemplate.Type <> OldReqTemplateType then begin
            ReqWkshTemplate.Type := OldReqTemplateType;
            ReqWkshTemplate.Modify();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshForTransferLFLItem()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // Setup: Create Lot For Lot Item.
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);

        // Update Inventory.
        Quantity := LibraryRandom.RandDec(10, 2);
        UpdateInventory(Item."No.", Quantity, LocationBlue.Code);

        // Create Transfer Order.
        CreateTransferOrderWithReceiptDate(TransferHeader, Item."No.", LocationBlue.Code, LocationRed.Code, Quantity);

        // Exercise: Calculate Plan for Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Verify: Verify Planning Worksheet for Location, Due Date, Action Message and Quantity.
        SelectTransferLine(TransferLine, TransferHeader."No.", Item."No.");
        VerifyRequisitionLineEntries(
          Item."No.", LocationRed.Code, RequisitionLine."Action Message"::Cancel, TransferLine."Receipt Date", TransferLine.Quantity, 0,
          RequisitionLine."Ref. Order Type"::Transfer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanTwiceCarryOutAndNewShipmentDateOnDemand()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        EndDate: Date;
        StartDate: Date;
        NewShipmentDate: Date;
        NewStartDate: Date;
        NewEndDate: Date;
    begin
        // Setup: Create Order Item with Vendor No. Create Sales Order.
        Initialize();
        CreateOrderItem(Item);
        UpdateItemVendorNo(Item);
        CreateSalesOrder(Item."No.", '');

        // Calculate Plan for Planning Worksheet and Carry Out.
        FindSalesLine(SalesLine, Item."No.");
        StartDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", -1);  // Start Date less than Shipment Date.
        EndDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", 1);  // End Date more than Shipment Date.
        CalcRegenPlanAndCarryOut(Item, StartDate, EndDate);

        // Update Shipment Date of Sales Order after Carry Out.
        NewShipmentDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", 1);  // End Date relative to Workdate.
        UpdateSalesLineShipmentDate(Item."No.", NewShipmentDate);

        // Exercise: Calculate Plan for Planning Worksheet again after Carry Out.
        NewStartDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Start date more than old Shipment Date of Sales Line.
        NewEndDate := GetRequiredDate(10, 10, NewShipmentDate, 1);  // End Date more than New Shipment Date of Sales Line.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, NewStartDate, NewEndDate);

        // Verify: Verify Requisition Line is created with Reschedule Action Message.
        VerifyRequisitionLineEntries(
          Item."No.", '', RequisitionLine."Action Message"::Reschedule, NewShipmentDate, 0, SalesLine.Quantity,
          RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanAndCarryOutOrderItemWithVendorHavingCurrency()
    var
        Item: Record Item;
        VendorCurrencyCode: Code[10];
        EndDate: Date;
    begin
        // Setup: Create Order Item. Create Vendor with Currency Code. Update Vendor on Item.
        Initialize();
        CreateOrderItem(Item);
        VendorCurrencyCode := UpdateItemWithVendor(Item);

        // Create Sales Order.
        CreateSalesOrder(Item."No.", '');

        // Exercise: Calculate Regenerative Plan and Carry Out for Planning Worksheet.
        EndDate := GetRequiredDate(10, 30, WorkDate(), 1);  // End Date more WORKDATE.
        CalcRegenPlanAndCarryOut(Item, WorkDate(), EndDate);

        // Verify: Verify after Carry Out, Purchase Order is created successfully with Vendor having same Currency Code.
        VerifyPurchaseLineCurrencyCode(Item."No.", VendorCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanAndCarryOutReqWkshOrderItemWithVendorHavingCurrency()
    var
        Item: Record Item;
        VendorCurrencyCode: Code[10];
    begin
        // Setup: Create Order Item. Create Vendor with Currency Code. Update Vendor on Item.
        Initialize();
        CreateOrderItem(Item);
        VendorCurrencyCode := UpdateItemWithVendor(Item);

        // Create Sales Order.
        CreateSalesOrder(Item."No.", '');

        // Calculate Plan for Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Exercise: Carry Out Action Message for Requisition Worksheet.
        CarryOutActionMessage(Item."No.");

        // Verify: Verify after Carry Out, Purchase Order is created successfully with Vendor having same Currency Code.
        VerifyPurchaseLineCurrencyCode(Item."No.", VendorCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksReqWkshMakeOrder()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Vendor: Record "Vendor";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplateName: Code[10];
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia creates a purchase order for an item with variants using Requisition Worksheet,
        // the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        LibraryInventory.CreateItem(Item);
        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Yes);
        Item.Modify();
        LibraryInventory.CreateVariant(ItemVariant, Item);

        // [GIVEN] Default vendor specified for the item
        LibraryPurchase.CreateVendor(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify();

        // [GIVEN] Requisition worksheet with line
        ReqWkshTemplateName := Libraryplanning.SelectRequisitionTemplateName();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplateName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplateName, RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate(Quantity, 1);
        RequisitionLine.Modify();
        Commit();

        // [WHEN] action message is attempted to be carried out
        asserterror LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [THEN] Error is thrown indicating the Variant Code is missing
        Assert.ExpectedError(RequisitionLine.FieldCaption(RequisitionLine."Variant Code"));

        RequisitionLine.Get(ReqWkshTemplateName, RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");

        // [GIVEN] Variant is specified
        LibraryInventory.CreateVariant(ItemVariant, Item);
        RequisitionLine.Validate("Variant Code", ItemVariant.Code);
        RequisitionLine.Modify();

        // [WHEN] User carries out the action message
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [THEN] No error is thrown 
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseShipmentMethodForSpecialSalesOrderAndCarryOutReqWksh()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item.
        Initialize();
        CreateItem(Item);

        // Create Sales Order and Purchasing Code Special Order.
        CreateSalesOrder(Item."No.", '');
        UpdateSalesLineWithSpecialOrderPurchasingCode(SalesLine, Item."No.", '');

        // Exercise: Get Sales Order From Special Order on Requisition Worksheet and Carry out.
        GetSalesOrderForSpecialOrderAndCarryOutReqWksh(Item."No.");

        // Verify: Verify Shipment Method Code of Sales Order is also updated on Purchase Order created after Carry Out.
        VerifyPurchaseShipmentMethod(SalesLine."Document No.", Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanAndCarryOutWithGetSalesOrderAndDropShipmentFRQItem()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        // Setup: Create multiple Fixed Reorder Quantity Items.
        Initialize();
        CreateFRQItem(Item);
        CreateFRQItem(Item2);
        UpdateItemVendorNo(Item2);

        // Create Sales Order with Purchasing Code Drop Shipment.
        CreateSalesOrder(Item2."No.", '');
        UpdateSalesLineWithDropShipmentPurchasingCode(SalesLine, Item2."No.", LocationBlue.Code);

        // Calculate Plan and Get Sales Order for Drop Shipment for same Requisition Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalculatePlanForReqWksh(Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        GetSalesOrderDropShipment(SalesLine, RequisitionLine, RequisitionWkshName);

        // Exercise: Carry Out for second Item created after Get Sales Order.
        CarryOutActionMessage(Item2."No.");

        // Verify: Verify after Carry Out for second Item, Lines for first Items are still on same Worksheet.
        VerifyRequisitionLineBatchAndTemplateForItem(Item."No.", RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoOnRequisitionWorksheetWithVendorNo()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Verify Requisition Worksheet is automatically updated with Vendor Item No. when Vendor No populated on Requisition Line.
        // Setup.
        Initialize();
        RequisitionLineWithVendorItemNoOfVendor(ReqWkshTemplate.Type::"Req.");  // Requisition Worksheet.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoOnPlanningWorksheetWithVendorNo()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Verify Planning Worksheet is automatically updated with Vendor Item No. when Vendor No populated on Requisition Line.
        // Setup.
        Initialize();
        RequisitionLineWithVendorItemNoOfVendor(ReqWkshTemplate.Type::Planning);  // Planning Worksheet.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoOnSKUHasHigherPriorityOnRequsitionLine()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // [FEATURE] [Requisition Worksheet] [Stockkeeping Unit]
        // [SCENARIO 223035] If stockkeeping unit exists for given item and location, vendor item no. on requisition line should be populated from SKU card.
        Initialize();

        // [GIVEN] Item "I" with stockkeeping unit "SKU" on location "L1". Vendor Item No. on the item = "VIN1", on the SKU = "VIN2".
        CreateItemWithSKU(Item, SKU, LocationBlue.Code);

        // [WHEN] Create requisition line with item "I", location "L1" and populated Vendor No. from the item card.
        CreateRequisitionLine(RequisitionLine, Item."No.", ReqWkshTemplate.Type::"Req.");
        RequisitionLine.Validate("Location Code", SKU."Location Code");
        RequisitionLine.Validate("Vendor No.", Item."Vendor No.");

        // [THEN] Stockkeeping unit exists for item "I" and location "L1".
        // [THEN] Vendor Item No. on the requisition line is equal to "VIN2".
        RequisitionLine.TestField("Vendor Item No.", SKU."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoOnItemHasLowerPriorityOnRequisitionLine()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // [FEATURE] [Requisition Worksheet] [Item]
        // [SCENARIO 223035] If stockkeeping unit does not exist for given item and location, vendor item no. on requisition line should be populated from item card.
        Initialize();

        // [GIVEN] Item "I" with stockkeeping unit "SKU" on location "L1". Vendor Item No. on the item = "VIN1", on the SKU = "VIN2".
        CreateItemWithSKU(Item, SKU, LocationRed.Code);

        // [WHEN] Create requisition line with item "I", location "L2" and populated Vendor No. from the item card.
        CreateRequisitionLine(RequisitionLine, Item."No.", ReqWkshTemplate.Type::"Req.");
        RequisitionLine.Validate("Location Code", LocationBlue.Code);
        RequisitionLine.Validate("Vendor No.", Item."Vendor No.");

        // [THEN] Stockkeeping unit does not exist for item "I" and location "L2".
        // [THEN] Vendor Item No. on the requisition line is equal to "VIN1".
        RequisitionLine.TestField("Vendor Item No.", Item."Vendor Item No.");
    end;

    local procedure RequisitionLineWithVendorItemNoOfVendor(Type: Enum "Req. Worksheet Template Type")
    var
        Item: Record Item;
        ItemVendor: Record "Item Vendor";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Item. Update Item Vendor of Item with Vendor Item No.
        CreateItem(Item);
        CreateItemVendorWithVendorItemNo(ItemVendor, Item);

        // Create Requisition Line for Planning or Requisition Worksheet as required.
        CreateRequisitionLine(RequisitionLine, Item."No.", Type);

        // Exercise: Update Requisition Line with Vendor No.
        UpdateRequisitionLineVendorNo(RequisitionLine, ItemVendor."Vendor No.");

        // Verify: Verify Requisition Line is automatically updated with Vendor Item No. of Item Vendor.
        RequisitionLine.TestField("Vendor Item No.", ItemVendor."Vendor Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanForSalesWithLotTrackingLFLItem()
    var
        ItemTrackingMode: Option " ","Assign Lot No.","Assign Serial No.";
    begin
        // Verify Lot specific tracking with Net Change Plan report.
        // Setup.
        Initialize();
        NetChangePlanWithTrackingLFLItem(ItemTrackingMode::"Assign Lot No.", false);  // SN Specific Tracking - FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanForSalesWithSerialTrackingLFLItem()
    var
        ItemTrackingMode: Option " ","Assign Lot No.","Assign Serial No.";
    begin
        // Verify Serial specific tracking with Net Change Plan report.
        // Setup.
        Initialize();
        NetChangePlanWithTrackingLFLItem(ItemTrackingMode::"Assign Serial No.", true);  // SN Specific Tracking - TRUE.
    end;

    local procedure NetChangePlanWithTrackingLFLItem(ItemTrackingMode: Option; SerialSpecific: Boolean)
    var
        Item: Record Item;
        ItemTrackingCodeSerialLotSpecific: Record "Item Tracking Code";
        SalesLine: Record "Sales Line";
    begin
        // Create Lot For Lot Item with Lot or Serial specific tracking.
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        if SerialSpecific then begin
            LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeSerialLotSpecific, true, false);
            LibraryItemTracking.AddSerialNoTrackingInfo(Item);
        end else begin
            LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeSerialLotSpecific, false, true);
            LibraryItemTracking.AddLotNoTrackingInfo(Item);
        end;

        // Create Sales Order. Assign SN or Lot specific Tracking to Sales Line. Page Handler - ItemTrackingPageHandler.
        CreateSalesOrder(Item."No.", '', 1);
        AssignTrackingOnSalesLine(SalesLine, Item."No.", ItemTrackingMode);

        // Exercise: Calculate Net Change Plan from Planning Worksheet.
        CalcNetChangePlanForPlanWksh(Item);

        // Verify: Verify Quantity and Tracking is assigned on Requisition Line. Verified in ItemTrackingPageHandler.
        VerifyRequisitionWithTracking(ItemTrackingMode, Item."No.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler')]
    [Scope('OnPrem')]
    procedure ReservedQuantityOnSalesAfterCapableToPromiseLFLItem()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Lot For Lot Item. Create Sales Order.
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        CreateSalesOrder(Item."No.", '');

        // Exercise: Open Order Promising Lines Page and Invoke Capable to Promise Action.
        FindSalesLine(SalesLine, Item."No.");
        OpenOrderPromisingPage(SalesLine."Document No.");  // Using Page to avoid Due Date error - OrderPromisingPageHandler.

        // Verify: Verify Reserved Quantity is updated on Sales Line.
        SalesLine.Find();  // Required to maintain the instance of Sales Line.
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler')]
    [Scope('OnPrem')]
    procedure DueDateOnReqWkshWithCapableToPromiseMakeToStockLFLItem()
    begin
        // Setup: Verify Due Date on Requisition Line created after Capable to promise for Manufacturing Policy Make-to-Stock on Item.
        Initialize();
        DueDateOnReqWkshWithCapableToPromiseManufPolicyLFLItem(false);  // FALSE- Manufacturing Policy Make-to-Stock.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler')]
    [Scope('OnPrem')]
    procedure DueDateOnReqWkshWithCapableToPromiseMakeToOrderLFLItem()
    begin
        // Setup: Verify Due Date on Requisition Line created after Capable to promise for Manufacturing Policy Make-to-Order on Item.
        Initialize();
        DueDateOnReqWkshWithCapableToPromiseManufPolicyLFLItem(true);  // TRUE- Manufacturing Policy Make-to-Order.
    end;

    local procedure DueDateOnReqWkshWithCapableToPromiseManufPolicyLFLItem(MakeToOrder: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Lot For Lot Item and Update Lead Time Calculation. Create Sales Order.
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        if MakeToOrder then
            UpdateItemManufacturingPolicy(Item, Item."Manufacturing Policy"::"Make-to-Order");
        UpdateItemLeadTimeCalculation(Item, '<' + Format(LibraryRandom.RandInt(5) + 10) + 'D>');  // Random Lead Time Calculation.
        CreateSalesOrder(Item."No.", '');

        // Exercise: Open Order Promising Lines Page and Invoke Capable to Promise Action.
        FindSalesLine(SalesLine, Item."No.");
        OpenOrderPromisingPage(SalesLine."Document No.");  // Using Page to avoid Due Date error - OrderPromisingPageHandler.

        // Verify: Verify Due Date on Requisition Line.
#pragma warning disable AA0181
        SalesLine.Find();
#pragma warning restore
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Due Date", SalesLine."Planned Shipment Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithSalesShipForStartingEndingTimeLFLItems()
    var
        WorkCenter: Record "Work Center";
        ParentItem: Record Item;
        RoutingHeader: Record "Routing Header";
        RequisitionLine: Record "Requisition Line";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        ChildItemNo: Code[20];
    begin
        // Setup: Create Lot For Lot Parent and Child Item. Create Routing and update on Item.
        Initialize();
        ChildItemNo := CreateLotForLotItemSetup(ParentItem);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(ParentItem, RoutingHeader."No.");

        // Create and Post Sales Order as Ship.
        CreateAndPostSalesOrderAsShip(ParentItem."No.");

        // Exercise: Calculate Plan for Planning Worksheet for Parent and child Item.
        CalcRegenPlanForPlanWkshForMultipleItems(ParentItem."No.", ChildItemNo);

        // Verify: Verify Starting Time and Ending Time on Planning Worksheet is according to Shop Calendar and Manufacturing Setup.
        FindShopCalendarWorkingDays(ShopCalendarWorkingDays, WorkCenter."Shop Calendar Code");
        VerifyRequisitionLineStartingAndEndingTime(ChildItemNo);
        VerifyRequisitionLineEndingTime(RequisitionLine, ParentItem."No.", ShopCalendarWorkingDays."Ending Time");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithProdOrderFromSalesForStartingEndingTimeLFLItems()
    var
        WorkCenter: Record "Work Center";
        ParentItem: Record Item;
        RoutingHeader: Record "Routing Header";
        ChildItemNo: Code[20];
    begin
        // Setup: Create Lot For Lot Parent and Child Item. Create Routing and update on Item.
        Initialize();
        ChildItemNo := CreateLotForLotItemSetup(ParentItem);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(ParentItem, RoutingHeader."No.");

        // Create Released Production Order from Sales Order.
        CreateReleasedProdOrderFromSalesOrder(ParentItem."No.");

        // Exercise: Calculate Plan for Planning Worksheet for Parent and child Item.
        CalcRegenPlanForPlanWkshForMultipleItems(ParentItem."No.", ChildItemNo);

        // Verify: Verify Starting Time and Ending Time on Planning Worksheet is according to Manufacturing Setup.
        VerifyRequisitionLineStartingAndEndingTime(ChildItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutForReleasedProdOrderWithLocation()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        PurchLine: Record "Purchase Line";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create Location, Create and refresh Released Production Order with Location.
        LibraryWarehouse.CreateLocation(Location);
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", Location.Code, '');

        // Exercise: Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Re-validate the Quantity on the purchase line created by Subcontracting worksheet.
        FindPurchLine(PurchLine, Item."No.");
        PurchLine.Validate(Quantity, ProductionOrder.Quantity);
        PurchLine.Modify(true);

        // Verify: Verify "Qty. on Purch. Order" on Item Card.
        Item.CalcFields("Qty. on Purch. Order");
        Item.TestField("Qty. on Purch. Order", 0);

        // Verify the value of Projected Available Balance on Item Availability By Location Page.
        VerifyItemAvailabilityByLocation(Item, Location.Code, ProductionOrder.Quantity);

        // Verify Scheduled Receipt and Projected Available Balance on Item Availability By Period Page.
        // the value of Scheduled Receipt equal to 0 on the line that Period Start is a day before WORKDATE
        // and the value of Scheduled Receipt equal to ProductionOrder.Quantity on the line that Period Start is WORKDATE
        // the value of Projected Available Balance equal to ProductionOrder.Quantity on the line that Period Start is WORKDATE
        VerifyItemAvailabilityByPeriod(Item, 0, ProductionOrder.Quantity, ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CheckProdOrderStatusPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanAfterUpdateQtyOnSalesOrderLineWithProdItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
        QuantityPer: Decimal;
    begin
        // Test and verify Quantity for production component Item on Requisition Line is correct after replanning.

        // Setup: Create Item with planning parameters and Prod. BOM.
        Initialize();
        QuantityPer := CreateItemWithProdBOM(Item, ChildItem);

        // Create Released Production Order from Sales Order. Then Update Sales Line Quantity.
        CreateReleasedProdOrderFromSalesOrder(Item."No.");
        LibraryVariableStorage.Enqueue(SalesLineQtyChangedMsg);
        Quantity := LibraryRandom.RandInt(100);
        UpdateSalesLineQuantity(Item."No.", Quantity);

        // Exercise: Calculate Plan for Planning Worksheet for parent and child Item.
        CalcRegenPlanForPlanWkshForMultipleItems(Item."No.", ChildItem."No.");

        // Verify: Verify Quantity of child Item on Resuisition Line is correct.
        VerifyRequisitionLineQuantity(
          ChildItem."No.", RequisitionLine."Action Message"::"Change Qty.", Quantity * QuantityPer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanAfterUpdateQtyOnSalesOrderLineWithAssemblyItem()
    var
        Item: Record Item;
        CompItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
        QuantityPer: Decimal;
    begin
        // Test and verify Quantity for assembly component Item on Requisition Line is correct after replanning.

        // Setup: Create Item with planning parameters and Asm. BOM.
        Initialize();
        QuantityPer := CreateAssemblyItemWithBOM(Item, CompItem);
        CreateSalesOrder(Item."No.", '');

        // Generate an Assembly Order for Sales Line by Planning Worksheet. Then Update Sales Line Quantity.
        CalcRegenPlanAndCarryOut(Item, WorkDate(), WorkDate());
        CalcRegenPlanAndCarryOut(CompItem, WorkDate(), WorkDate());
        Quantity := LibraryRandom.RandInt(100);
        UpdateSalesLineQuantity(Item."No.", Quantity);

        // Exercise: Calculate Plan for Planning Worksheet for parent and child Item.
        CalcRegenPlanForPlanWkshForMultipleItems(Item."No.", CompItem."No.");

        // Verify: Verify Quantity of child Item on Resuisition Line is correct.
        VerifyRequisitionLineQuantity(
          CompItem."No.", RequisitionLine."Action Message"::New, QuantityPer * Quantity);
    end;

    [Test]
    procedure MakeAssemblyOrdersFromPlanningWorksheet()
    var
        Item: Record Item;
        CompItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        AssemblyHeader: Record "Assembly Header";
        PlanningCreateAsmOrder: Enum "Planning Create Assembly Order";
    begin
        // [SCENARIO] Carry out action on planning worksheet with Make and Print assembly orders should be able to print multiple assembly orders. 
        // [GIVEN] Create Item with planning parameters and Asm. BOM.
        Initialize();
        CreateAssemblyItemWithBOM(Item, CompItem);
        CreateSalesOrder(Item."No.", '');

        // [GIVEN] Calculate the plan in Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);
        AcceptActionMessage(RequisitionLine, Item."No.");

        // [WHEN]  Carry out action to create Assembly Order for Sales Lines with Option: Make Assembly Orders'
        LibraryPlanning.CarryOutPlanWksh(RequisitionLine, 0, 0, 0, PlanningCreateAsmOrder::"Make Assembly Orders".AsInteger(), '', '', '', '');

        // [THEN] Assembly Order is created but no document is printed. 
        AssemblyHeader.SetRange("Item No.", Item."No.");
        Assert.AreEqual(1, AssemblyHeader.Count(), 'There should be only 1 assembly order created.');
    end;

    [Test]
    [HandlerFunctions('AssemblyOrderSaveAsXML')]
    procedure MakeAndPrintAssemblyOrdersFromPlanningWorksheet()
    var
        Item: Record Item;
        CompItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        AssemblyHeader: Record "Assembly Header";
        PlanningCreateAsmOrder: Enum "Planning Create Assembly Order";
        ReqLineCount: Decimal;
    begin
        // [SCENARIO] Carry out action on planning worksheet with Make and Print assembly orders should be able to print multiple assembly orders. 
        // [GIVEN] Create Item with planning parameters and Asm. BOM.
        Initialize();
        CreateAssemblyItemWithBOM(Item, CompItem);
        CreateSalesOrder(Item."No.", '');
        CreateSalesOrder(Item."No.", '');
        CreateSalesOrder(Item."No.", '');
        CreateSalesOrder(Item."No.", '');

        // [GIVEN] Calculate the plan in Planning Worksheet which should result in multiple assembly orders.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // [WHEN]  Carry out action to create 1 Assembly Order for Sales Lines with Option: Make Assembly Orders & Print'
        AcceptActionMessage(RequisitionLine, Item."No."); //This will accept the message for First Line.
        LibraryPlanning.CarryOutPlanWksh(RequisitionLine, 0, 0, 0, PlanningCreateAsmOrder::"Make Assembly Orders & Print".AsInteger(), '', '', '', ''); //ReportHandler AssemblyOrderSaveAsXML is used to intercept the print request.

        // [THEN] 1 Assembly Order is created and the report is contains the right order.
        AssemblyHeader.SetRange("Item No.", Item."No.");
        Assert.AreEqual(1, AssemblyHeader.Count(), 'There should be only 1 assembly order created.');
        VerifyPrintedAsmOrders(AssemblyHeader);
        AssemblyHeader.Delete(); //Delete the assembly order for next test.

        // [WHEN] Carry out action to create multiple Assembly Order for Sales Lines with Option: Make Assembly Orders & Print'
        RequisitionLine.SetRange("Accept Action Message", false);
        repeat
            AcceptActionMessage(RequisitionLine, Item."No.");
        until RequisitionLine.Next() = 0;
        RequisitionLine.Reset();
        RequisitionLine.SetRange("No.", Item."No.");
        ReqLineCount := RequisitionLine.Count();
        LibraryPlanning.CarryOutPlanWksh(RequisitionLine, 0, 0, 0, PlanningCreateAsmOrder::"Make Assembly Orders & Print".AsInteger(), '', '', '', ''); //ReportHandler AssemblyOrderSaveAsXML is used to intercept the print request.

        // [THEN] Rest of the Assembly Orders are created and all of them are printed.
        AssemblyHeader.SetRange("Item No.", Item."No.");
        Assert.AreEqual(ReqLineCount, AssemblyHeader.Count(), StrSubstNo('There should be %1 number of assembly orders created.', ReqLineCount));
        VerifyPrintedAsmOrders(AssemblyHeader);
    end;

    local procedure VerifyPrintedAsmOrders(var AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyHeader.FindSet();
        repeat
            LibraryReportDataset.AssertElementWithValueExists('No_AssemblyHeader', AssemblyHeader."No.");
            LibraryReportDataset.GetNextRow();
        until AssemblyHeader.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithMixedLocationsAndNoSKU()
    var
        Item: Record Item;
        PrevLocMandatory: Boolean;
        PrevComponentsAtLocation: Code[10];
    begin
        // [SCENARIO 354463] When Item does not have SKUs and Location Mandatory is FALSE and Components at Location is empty, Item is replenished as Lot-for-Lot and other planning parameters are ignored for non-empty Location.

        // [GIVEN] Location Mandatory = FALSE, Components at Location = ''.
        Initialize();
        PrevLocMandatory := UpdInvSetupLocMandatory(false);
        PrevComponentsAtLocation := UpdateSetupComponentsAtLocation('');
        // [GIVEN] Item with no SKUs and some planning Quantities.
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        SetReplenishmentQuantities(Item, LibraryRandom.RandDecInDecimalRange(100, 10000, 0));
        // [GIVEN] Inventory is both on empty and non-empty Location.
        UpdateInventory(Item."No.", LibraryRandom.RandDecInDecimalRange(10, 100, 0), '');
        UpdateInventory(Item."No.", LibraryRandom.RandDecInDecimalRange(10, 100, 0), LocationBlue.Code);

        // [WHEN] Calculating Regeneration Plan
        CalculateRegenPlanForPlanningWorksheet(Item);

        // [THEN] For non-empty location used planning parameters: Lot-for-Lot, include inventory, other values are blank.
        VerifyRequisitionLineExistenceWithLocation(Item."No.", LocationBlue.Code, ReqLineExpectedTo::"Not Exist");
        // [THEN] For empty location used planning parameters from Item.
        VerifyRequisitionLineExistenceWithLocation(Item."No.", '', ReqLineExpectedTo::Exist);

        // Teardown.
        UpdInvSetupLocMandatory(PrevLocMandatory);
        UpdateSetupComponentsAtLocation(PrevComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineIsDeletedWhileCalculatingWorksheetForDifferentBatch()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionWkshName2: Record "Requisition Wksh. Name";
    begin
        // [FEATURE] [Subcontracting Worksheet]
        // [SCENARIO 363390] Requisition Line is deleted in Batch "A" while Calculating Worksheet for same Line for Batch "B"
        Initialize();

        // [GIVEN] Released Production Order for Item with Routing
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Requisition Worksheet Batch "A"
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // [GIVEN] Requisition Worksheet Batch "B"
        CreateRequisitionWorksheetName(RequisitionWkshName2);

        // [GIVEN] Calculate Worksheet for Batch "A". Requisition Worksheet Line "X" is created.
        CalculateSubcontractingWorksheetForBatch(RequisitionWkshName, WorkCenter);

        // [WHEN] Calculate Worksheet for Batch "B".
        CalculateSubcontractingWorksheetForBatch(RequisitionWkshName2, WorkCenter);

        // [THEN] Requisition Worksheet Line "Y" = "X" is created. Line "X" is deleted from Batch "A".
        VerifyRequisitionLineForTwoBatches(RequisitionWkshName.Name, RequisitionWkshName2.Name, Item."No.", ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationDeletedWhenDeletingProdOrderLine()
    var
        TopLevelItem: Record Item;
        MidLevelItem: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        RequisitionLine: Record "Requisition Line";
        ProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
    begin
        // [FEATURE] [Reservation] [Manufacturing] [Planning Worksheet]
        // [SCENARIO 363718] Reservation linking two prod. order lines in the same prod. order is deleted when top-level line is deleted

        Initialize();

        // [GIVEN] Item "I1" replenished through manufacturing with order tracking
        // [GIVEN] Item "I2" replenished through manufacturing with order tracking, used as a component for item "I1"
        CreateItemWithProdBOM(TopLevelItem, MidLevelItem);
        UpdateOrderTrackingPolicy(TopLevelItem);
        UpdateOrderTrackingPolicy(MidLevelItem);

        // [GIVEN] Sales order for item "I1"
        CreateSalesOrder(TopLevelItem."No.", LibrarySales.CreateCustomerNo());
        TopLevelItem.SetFilter("No.", '%1|%2', TopLevelItem."No.", MidLevelItem."No.");

        // [GIVEN] Calculate requisition plan for items "I1" and "I2"
        CalculateRegenPlanForPlanningWorksheet(TopLevelItem);
        AcceptActionMessage(RequisitionLine, TopLevelItem."No.");
        AcceptActionMessage(RequisitionLine, MidLevelItem."No.");

        // [GIVEN] Carry out requisition plan - one production order with 2 lines is created. Item "I2" is reserved as a component for the item "I1"
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");
        LibraryPlanning.CarryOutPlanWksh(RequisitionLine, ProdOrderChoice::"Firm Planned", 0, 0, 0, '', '', '', '');

        // [WHEN] Delete production order line for item "I1"
        ProdOrderLine.SetRange("Item No.", TopLevelItem."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Delete(true);

        // [THEN] All reservation entries linked to this line are deleted
        VerifyReservationEntryIsEmpty(DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoSequentialProdOrdersPlannedOnCapacityContrainedMachineAndWorkCenters()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
        Item: array[2] of Record Item;
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        StartingDateTime: DateTime;
    begin
        // [FEATURE] [Manufacturing] [Capacity Constrained Resource] [Planning Worksheet]
        // [SCENARIO] Two sequential prod. orders are planned when both machine center and its work center are capacity constrained

        // [GIVEN] Work center with 2 machine centers - "MC1" and "MC2"
        CreateWorkCenterWith2MachineCenters(WorkCenter, MachineCenter);

        // [GIVEN] All manufacturing capacities registered as capacity constrained resources
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Machine Center", MachineCenter[1]."No.");
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Machine Center", MachineCenter[2]."No.");

        // [GIVEN] Item "I1" with routing involving machine centers "MC1", then "MC2"
        CreateLotForLotItemWithRouting(Item[1], MachineCenter[1], MachineCenter[2]);
        // [GIVEN] Item "I1" with routing involving machine centers "MC2", then "MC1"
        CreateLotForLotItemWithRouting(Item[2], MachineCenter[2], MachineCenter[1]);

        // [GIVEN] Sales order with 2 lines: 300 pcs of item "I1" and 300 pcs of item "I2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[1]."No.", 300);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[2]."No.", 300);

        // [WHEN] Calculate regenerative plan for both items
        Item[1].SetFilter("No.", '%1|%2', Item[1]."No.", Item[2]."No.");
        CalculateRegenPlanForPlanningWorksheet(Item[1]);

        // [THEN] 2 sequential manufacturing orders are planned: P1."Ending Date-Time" = P2."Starting Date-Time"
        SelectRequisitionLine(RequisitionLine, Item[1]."No.");
        StartingDateTime := RequisitionLine."Starting Date-Time";

        SelectRequisitionLine(RequisitionLine, Item[2]."No.");
        RequisitionLine.TestField("Ending Date-Time", StartingDateTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoParallelProdOrdersPlannedOnConstrainedMachCentersWithUnlimitedWorkCenter()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
        Item: array[2] of Record Item;
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: array[2] of Record "Requisition Line";
    begin
        // [FEATURE] [Manufacturing] [Capacity Constrained Resource] [Planning Worksheet]
        // [SCENARIO] Two parallel prod. orders are planned when machine centers are capacity contrained, but the work center is not constrained

        CreateWorkCenterWith2MachineCenters(WorkCenter, MachineCenter);

        // [GIVEN] Machine centers are registered as capacity constrained resources, work center is not constrained
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Machine Center", MachineCenter[1]."No.");
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Machine Center", MachineCenter[2]."No.");

        // [GIVEN] Item "I1" with routing involving machine centers "MC1", then "MC2"
        CreateLotForLotItemWithRouting(Item[1], MachineCenter[1], MachineCenter[2]);
        // [GIVEN] Item "I1" with routing involving machine centers "MC2", then "MC1"
        CreateLotForLotItemWithRouting(Item[2], MachineCenter[2], MachineCenter[1]);

        // [GIVEN] Sales order with 2 lines: 300 pcs of item "I1" and 300 pcs of item "I2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[1]."No.", 300);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[2]."No.", 300);

        // [WHEN] Calculate regenerative plan for both items
        Item[1].SetFilter("No.", '%1|%2', Item[1]."No.", Item[2]."No.");
        CalculateRegenPlanForPlanningWorksheet(Item[1]);

        // [THEN] 2 parallel production orders are planned: P1."Starting Date-Time" = P2."Starting Date-Time", P1."Ending Date-Time" = P2."Ending Date-Time"
        SelectRequisitionLine(RequisitionLine[1], Item[1]."No.");
        SelectRequisitionLine(RequisitionLine[2], Item[2]."No.");
        RequisitionLine[2].TestField("Starting Date-Time", RequisitionLine[1]."Starting Date-Time");
        RequisitionLine[2].TestField("Ending Date-Time", RequisitionLine[1]."Ending Date-Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcChangeSubcontractOrderWithExistingPurchase()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RequisitionLine: Record "Requisition Line";
        NewQty: Decimal;
    begin
        // [FEATURE] [Subcontracting Worksheet] [Requisition Line]
        // [SCENARIO] Can change Quantity in Subcontracting Worksheet if replenishment already exists.

        // [GIVEN] Item with subcontracting routing, create Released Production Order.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Calculate Subcontracts, accept and Carry Out Action.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [GIVEN] Update Quantity, Calculate Subcontracts.
        UpdateProdOrderLineQty(Item."No.", ProductionOrder.Quantity + LibraryRandom.RandIntInRange(1, 5));
        CalculateSubcontractOrder(WorkCenter);

        // [WHEN] In Subcontracting Worksheet, change Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        NewQty := RequisitionLine.Quantity + LibraryRandom.RandIntInRange(1, 5);
        RequisitionLine.Validate(Quantity, NewQty);

        // [THEN] Quantity changed.
        RequisitionLine.TestField(Quantity, NewQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegenerativePlanWithFixedReorderQtyConsidersLeadTimeCalculation()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        InventorySetup: Record "Inventory Setup";
        ExpectedDueDate: Date;
    begin
        // [FEATURE] [Requisition Worksheet] [Lead Time Calculation]
        // [SCENARIO] Lead Time Calculation should be considered when calculating requisition plan for an item with fixed reorder quantity

        // [GIVEN] Item "I" with Lead Time Calculation = "1M" and reordering policy "Fixed Reorder Qty."
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(10, 2));
        Evaluate(Item."Lead Time Calculation", '<1M>');
        Item.Modify(true);

        // [WHEN] Calculate regenerative plan for item "I" on WORKDATE
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate(), WorkDate());

        // [THEN] "Due Date" in requisition line is WorkDate() + 1M
        InventorySetup.Get();
        SelectRequisitionLine(ReqLine, Item."No.");
        ExpectedDueDate := CalcDate(StrSubstNo('<1M+%1>', InventorySetup."Default Safety Lead Time"), WorkDate());
        ReqLine.TestField("Due Date", ExpectedDueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAvailabilityForPeriodWithDropShipmentOrders()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByPeriod: TestPage "Item Availability by Periods";
    begin
        // [FEATURE] [Item Availability] [Drop Shipment]
        // [SCENARIO 377096] Item Availability for Period should not consider Drop Shipment Orders for Sheduled Receipt
        Initialize();

        // [GIVEN] Drop Shipment Sales Order of Quantity = "X"
        CreateItem(Item);
        CreateSalesOrder(Item."No.", CreateCustomerWithLocation());
        UpdateSalesLineWithDropShipmentPurchasingCode(SalesLine, Item."No.", LocationSilver.Code);

        // [GIVEN] Purchase Order for Drop Shipment Sales Order
        GetSalesOrderForDropShipmentAndCarryOutReqWksh(SalesLine);

        // [WHEN] Run Item Availability for Period
        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);
        ItemAvailabilityByPeriod.Trap();
        ItemCard.Period.Invoke();

        // [THEN] Sheduled Receipt = 0 on Item Availability Line
        ItemAvailabilityByPeriod.ItemAvailLines.ScheduledRcpt.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,CalcRegenPlanReqPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionPlanManufacturedItemWithClosedBOMAndCertifiedVersion()
    var
        Item: Record Item;
        ProdBomVersion: Record "Production BOM Version";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Planning Worksheet] [Planning Resiliency] [Production BOM]
        // [SCENARIO 381546] Requisition plan should be calculated correctly for a manufactured item having closed BOM and certified BOM version
        Initialize();

        // [GIVEN] Item "I" with closed production BOM "B"
        // [GIVEN] Create and certify a version of BOM "B"
        CreateItemWithClosedBOMAndVersion(Item, ProdBomVersion);
        UpdateProdBOMVersionStatus(ProdBomVersion, ProdBomVersion.Status::Certified);

        // [GIVEN] Sales order for item "I" to create unfulfilled demand
        CreateSalesOrder(Item."No.", LibrarySales.CreateCustomerNo());

        // [WHEN] Run "Calculate Regenerative Plan" from planning worksheet
        PlanningWorksheet.OpenEdit();
        Commit();
        LibraryVariableStorage.Enqueue(false);  // Stop and Show First Error = FALSE
        LibraryVariableStorage.Enqueue(Item."No.");
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();

        // [THEN] Requisition line for item "I" is created
        PlanningWorksheet."No.".AssertEquals(Item."No.");
        PlanningWorksheet."Ref. Order Type".AssertEquals(RequisitionLine."Ref. Order Type"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,CalcRegenPlanReqPageHandler,MessageHandler,PlanningErrorLogPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionPlanManufacturedItemWithClosedBOMPlanningResiliencyOn()
    var
        Item: Record Item;
        ProdBomVersion: Record "Production BOM Version";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Planning Worksheet] [Planning Resiliency] [Production BOM]
        // [SCENARIO 381546] Requisition worksheet should show a planning error list when planning a manufactured item wihout certified BOM, planning resiliency is on
        Initialize();

        // [GIVEN] Item "I" with closed production BOM "B"
        // [GIVEN] Create a version of production BOM "B", leave it in "New" status
        CreateItemWithClosedBOMAndVersion(Item, ProdBomVersion);

        // [GIVEN] Sales order for item "I" to create unfulfilled demand
        CreateSalesOrder(Item."No.", LibrarySales.CreateCustomerNo());

        // [WHEN] Run "Calculate Regenerative Plan" from planning worksheet with option "Stop and Show First Error" = FALSE
        PlanningWorksheet.OpenEdit();
        Commit();
        LibraryVariableStorage.Enqueue(false);  // Stop and Show First Error = FALSE
        LibraryVariableStorage.Enqueue(Item."No.");  // Enqueue item no. for MessageHandler
        LibraryVariableStorage.Enqueue(StrSubstNo(NotAllItemsPlannedMsg, 1));
        LibraryVariableStorage.Enqueue(Item."No.");  // Enqueue item no. again for PlanningErrorLogPageHandler
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();

        // [THEN] "Planning Error Log" page is shown
        // Verified in PlanningErrorLogPageHandler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,CalcRegenPlanReqPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionPlanManufacturedItemWithClosedBOMPlanningResiliencyOff()
    var
        Item: Record Item;
        ProdBomVersion: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Planning Worksheet] [Planning Resiliency] [Production BOM]
        // [SCENARIO 381546] Requisition worksheet should throw an error when planning a manufactured item wihout certified BOM, planning resiliency is off
        Initialize();

        // [GIVEN] Item "I" with closed production BOM "B"
        // [GIVEN] Create a version of production BOM "B", leave it in "New" status
        CreateItemWithClosedBOMAndVersion(Item, ProdBomVersion);

        // [GIVEN] Sales order for item "I" to create unfulfilled demand
        CreateSalesOrder(Item."No.", LibrarySales.CreateCustomerNo());

        // [WHEN] Run "Calculate Regenerative Plan" from planning worksheet with option "Stop and Show First Error" = TRUE
        PlanningWorksheet.OpenEdit();
        Commit();
        LibraryVariableStorage.Enqueue(true);  // Stop and Show First Error = TRUE
        LibraryVariableStorage.Enqueue(Item."No.");

        // [THEN] Planning is terminated with an error: "Status must be equal to 'Certified' in Production BOM Header"
        asserterror PlanningWorksheet.CalculateRegenerativePlan.Invoke();
        Assert.ExpectedTestFieldError(ProductionBOMHeader.FieldCaption(Status), Format(ProductionBOMHeader.Status::Certified));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubcontractPurchHeaderNotSavedWhenLineCreationFails()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Subcontracting Worksheet]
        // [SCENARIO 382090] Purchase header created from the subcontracting worksheet should not be saved when lines cannot be generated due to erroneous setup

        Initialize();

        // [GIVEN] Work center "W" with linked subcontractor, routing "R" includes an operation on the work center "W"
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Work center "W" is not properly configured, because its Gen. Prod. Posting Group does not exist
        WorkCenter."Gen. Prod. Posting Group" := LibraryUtility.GenerateGUID();
        WorkCenter.Modify();

        // [GIVEN] Create a production order involving the usage of the work center "W"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Calculate subcontrat orders
        CalculateSubcontractOrder(WorkCenter);

        // [WHEN] Carry out subcontracting worksheet
        asserterror CarryOutActionMessageSubcontractWksh(Item."No.");

        // [THEN] Creation of a subcontracting purchase order fails, purchase header is not saved
        PurchaseHeader.Init();
        PurchaseHeader.SetRange("Buy-from Vendor No.", WorkCenter."Subcontractor No.");
        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValueEntryExpectedCostForReceivedNotInvoicedSubcontrPurchaseOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Subcontracting] [Production] [Expected Cost]
        // [SCENARIO 381570] Expected cost of production output posted via purchase order for subcontracting should be calculated as "Unit Cost" on production order line multiplied by output quantity.
        Initialize();

        // [GIVEN] Item "I" with routing with subcontractor "S" for workcenter "W".
        CreateItemWithChildReplenishmentPurchaseAsProdBOM(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Refreshed released production order for "Q" pcs of item "I".
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Set "Unit Cost" = "X" on the prod. order line.
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ProdOrderLine.Modify(true);

        // [GIVEN] Calculate subcontracts for "W".
        CalculateSubcontractOrder(WorkCenter);

        // [GIVEN] Update unit cost on subcontracting worksheet line to "Y".
        // [GIVEN] Carry out action messages for Subcontracting Worksheet with creation of purchase order with vendor "S".
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [WHEN] Post the purchase order as Receive but not as Invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, false);

        // [THEN] In related Value Entry expected cost amount is equal to "Q" * "X".
        FindValueEntry(ValueEntry, Item."No.");
        ValueEntry.TestField(
          "Cost Amount (Expected)",
          Round(ProdOrderLine."Unit Cost" * PurchaseLine.Quantity, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanWorksheetCarryOutActionSeveralLinesWithSamePurchasingCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
        Purchasing: Record Purchasing;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Planning Worksheet]
        // [SCENARIO 213568] Carry out action message in planning woeksheet should combine purchase lines with the same purchasing code under one purchase header

        Initialize();

        // [GIVEN] Item "I" with the default vendor "V"
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::Order, Item."Manufacturing Policy"::"Make-to-Stock",
          LibraryPurchase.CreateVendor(Vendor));

        // [GIVEN] Create two sales orders for item "I" with the same customer
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(Item."No.", Customer."No.");
        CreateSalesOrder(Item."No.", Customer."No.");

        // [GIVEN] Calculate regenerative plan for item "I"
        CalculateRegenPlanForPlanningWorksheet(Item);
        SelectRequisitionLine(RequisitionLine, Item."No.");

        // [GIVEN] Create purchasing code "P" and set it in all planning worksheet lines generated for the item "I"
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        RequisitionLine.ModifyAll("Purchasing Code", Purchasing.Code);
        RequisitionLine.ModifyAll("Accept Action Message", true);

        // [WHEN] Carry out action message from the planning worksheet
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] One purchase order with two lines is created for the vendor "V"
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        Assert.RecordCount(PurchaseHeader, 1);

        PurchaseHeader.FindFirst();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyReplenishedSKUAreNotPlannedWithRequisitionWorksheet()
    var
        Item: Record Item;
        CompItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Stockkeeping Unit] [Assembly] [Requisition Worksheet]
        // [SCENARIO 215219] Assembly replenished SKU cannot be planned with Requisition Worksheet.
        Initialize();

        // [GIVEN] Assembly Item "I".
        // [GIVEN] Stockkeeping unit "SKU-T" for "I" at location "T" and with Replenishment System = "Transfer".
        // [GIVEN] Stockkeeping unit "SKU-A" for "I" at location "A" and with Replenishment System = "Assembly".
        CreateAssemblyItemWithBOM(Item, CompItem);
        SelectTransferRoute(LocationRed.Code, LocationBlue.Code);
        CreateStockkeepingUnit(
          StockkeepingUnit, Item."No.", LocationBlue.Code, StockkeepingUnit."Replenishment System"::Transfer,
          StockkeepingUnit."Reordering Policy"::Order, LocationRed.Code);
        CreateStockkeepingUnit(
          StockkeepingUnit, Item."No.", LocationRed.Code, StockkeepingUnit."Replenishment System"::Assembly,
          StockkeepingUnit."Reordering Policy"::Order, '');

        // [GIVEN] Sales Order with item "I" at location "T".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.",
          LibraryRandom.RandInt(10), LocationBlue.Code, WorkDate());

        // [WHEN] Calculate plan for "I" in Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // [THEN] Planning line for Assembly at location "A" is not created.
        VerifyRequisitionLineExistenceWithLocation(Item."No.", LocationRed.Code, ReqLineExpectedTo::"Not Exist");

        // [THEN] Planning line for Transfer at location "T" is created.
        VerifyRequisitionLineExistenceWithLocation(Item."No.", LocationBlue.Code, ReqLineExpectedTo::Exist);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanWorksheetCarryOutActionSeveralLinesWithSameShipToCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        // [FEATURE] [Requisition Worksheet] [Drop Shipment]
        // [SCENARIO 224262] Carry out action message in planning worksheet should combine purchase lines for drop shipment with the same ship-to code and location code under one purchase header.
        Initialize();

        // [GIVEN] Item "I" with the default vendor "V".
        // [GIVEN] The default location for vendor "V" is "Blue".
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::Order, Item."Manufacturing Policy"::"Make-to-Stock",
          LibraryPurchase.CreateVendor(Vendor));
        Vendor.Validate("Location Code", LocationBlue.Code);
        Vendor.Modify(true);

        // [GIVEN] Customer "C" with alternate ship-to address code "A".
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        // [GIVEN] Sales order with Ship-to Address Code = "A".
        // [GIVEN] The order contains two lines with item "I" and purchasing code for drop shipment.
        // [GIVEN] Location code on both lines is "Red".
        CreatePurchasingCodeWithDropShipment(Purchasing);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        for i := 1 to 2 do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
            SetPurchasingAndLocationOnSalesLine(SalesLine, LocationRed.Code, Purchasing.Code);
        end;

        // [WHEN] Run "Drop Shipment - Get Sales Orders" in requisition worksheet and carry out action message.
        GetSalesOrderForDropShipmentAndCarryOutReqWksh(SalesLine);

        // [THEN] One purchase order is created for vendor "V".
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        Assert.RecordCount(PurchaseHeader, 1);

        // [THEN] The purchase contains two lines.
        PurchaseHeader.FindFirst();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine, 2);

        // [THEN] The location code on both lines is "Red".
        PurchaseLine.SetRange("Location Code", LocationRed.Code);
        Assert.RecordCount(PurchaseLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationIsNotDeletedOnCalcRegenPlanForPurchasedItem()
    var
        Item: Record Item;
        SKU: array[2] of Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 276098] Existing reservation of a non-manufacturing item is not deleted when you calculate regenerative plan.
        Initialize();

        SelectTransferRoute(LocationBlue.Code, LocationRed.Code);

        // [GIVEN] Item "I" replenished with purchase.
        // [GIVEN] "I"."Manufacturing Policy" is set to "Make-to-Stock", this setting should be insignificant for a non-prod. item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] Two stockkeeping units - "SKU_Purch" with replenishment system = "Purchase" on location "L_Purch", "SKU_Trans" with replenishment system = "Transfer" on location "L_Trans".
        CreateStockkeepingUnit(
          SKU[1], Item."No.", LocationBlue.Code, SKU[1]."Replenishment System"::Purchase, SKU[1]."Reordering Policy"::Order, '');
        CreateStockkeepingUnit(
          SKU[2], Item."No.", LocationRed.Code, SKU[2]."Replenishment System"::Transfer, SKU[2]."Reordering Policy"::"Lot-for-Lot",
          LocationBlue.Code);

        // [GIVEN] Create a demand on location "L_Trans".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), LocationRed.Code, WorkDate());

        // [GIVEN] Calculate regenerative plan for item "I" and accept action message.
        // [GIVEN] The planning engine has created a purchase order on location "L_Purch" and a transfer order from "L_Purch" to "L_Trans".
        // [GIVEN] The transfer is reserved from the purchase with "Order-to-Order" binding.
        CalcRegenPlanAndCarryOutActionMessage(Item);

        // [GIVEN] Delete the demand.
        SalesHeader.Delete(true);

        // [WHEN] Calculate regenerative plan for item "I", do not accept action message so far.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // [THEN] The reservation between the purchase and the transfer order has not been deleted.
        VerifyReservationBetweenSources(Item."No.", DATABASE::"Purchase Line", DATABASE::"Transfer Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialInventoryAdjustedForSafetyStockOnceOnReorderPointPlanning()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        InitialInventory: Decimal;
        OrderedQty: Decimal;
        ProjectedInventory: Decimal;
    begin
        // [FEATURE] [Safety Stock] [Maximum Inventory] [Reorder Point]
        // [SCENARIO 284376] If initial inventory is less than safety stock, but the full supply at planning date is greater than safety stock, the safety stock demand should not be taken into account.
        Initialize();

        InitialInventory := LibraryRandom.RandIntInRange(50, 100);
        OrderedQty := LibraryRandom.RandIntInRange(20, 40);
        ProjectedInventory := InitialInventory + OrderedQty;

        // [GIVEN] Item with "Maximum Qty." reordering policy.
        // [GIVEN] "Maximum Inventory" = 180 pcs, "Reorder Point" = 110 pcs, "Safety Stock" = 60 pcs.
        CreateAndUpdateItem(
            Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Maximum Qty.",
            "Manufacturing Policy"::"Make-to-Stock", '');
        Item.Validate("Maximum Inventory", LibraryRandom.RandIntInRange(500, 1000));
        Item.Validate("Reorder Point", ProjectedInventory + LibraryRandom.RandIntInRange(20, 40));
        Item.Validate("Safety Stock Quantity", InitialInventory + LibraryRandom.RandInt(10));
        Item.Modify(true);

        // [GIVEN] The initial inventory at WORKDATE is 55 pcs, which is less than the safety stock 60 pcs.
        UpdateInventory(Item."No.", InitialInventory, '');

        // [GIVEN] Purchase order for 35 pcs at date "D" = WorkDate() + 1 day.
        // [GIVEN] The overall supply at date "D" is thus 90 pcs (55 initial inventory + 35 purchase), so the safety stock is covered.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", OrderedQty, '', LibraryRandom.RandDate(10));

        // [WHEN] Calculate regenerative plan starting from date "D". The current supply 90 pcs is less than the reorder point 110, so a new supply will be planned.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, PurchaseLine."Expected Receipt Date", CalcDate('<CY>', PurchaseLine."Expected Receipt Date"));

        // [THEN] Planned quantity = 90 pcs (180 max. inventory - 90 current supply).
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, Item."Maximum Inventory" - ProjectedInventory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanningTransferDoesNotInterfereWithOtherItemsReservation()
    var
        ReservedItem: Record Item;
        PlannedItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Reservation] [Transfer]
        // [SCENARIO 287817] Replanning a transfer-replenished item does not affect reservation entries unrelated to the transfer being replanned.
        Initialize();

        // [GIVEN] Item "A" with an inventory reserved for a demand.
        LibraryInventory.CreateItem(ReservedItem);
        CreateReservedStock(ReservedItem."No.", LocationBlue.Code);

        // [GIVEN] Item "B" set up for replenishment by Transfer.
        LibraryInventory.CreateItem(PlannedItem);
        SelectTransferRoute(LocationRed.Code, LocationBlue.Code);
        CreateStockkeepingUnit(
          StockkeepingUnit, PlannedItem."No.", LocationBlue.Code, StockkeepingUnit."Replenishment System"::Transfer,
          StockkeepingUnit."Reordering Policy"::"Lot-for-Lot", LocationRed.Code);

        // [GIVEN] Sales order "SO" for item "B".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), PlannedItem."No.",
          LibraryRandom.RandInt(50), LocationBlue.Code, WorkDate());

        // [GIVEN] Calculate regenerative plan and carry out action in order to create a transfer order to fulfill "SO".
        PlannedItem.SetRecFilter();
        PlannedItem.SetRange("Location Filter", LocationBlue.Code);
        CalcRegenPlanAndCarryOutActionMessage(PlannedItem);

        // [GIVEN] Double the quantity in "SO".
        UpdateSalesLineQuantity(PlannedItem."No.", SalesLine.Quantity * 2);

        // [WHEN] Replan item "B" and carry out action to adjust the quantity to transfer.
        CalcRegenPlanAndCarryOutActionMessage(PlannedItem);

        // [THEN] Expected receipt date on reservation entries for item "A" has not changed.
        ReservationEntry.SetRange("Item No.", ReservedItem."No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Expected Receipt Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanningAssemblyDoesNotInterfereWithOtherItemsReservation()
    var
        ReservedItem: Record Item;
        PlannedItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Reservation] [Assembly]
        // [SCENARIO 287817] Replanning an assembly-replenished item does not affect reservation entries unrelated to the assembly being replanned.
        Initialize();

        // [GIVEN] Item "A" with an inventory reserved for a demand.
        LibraryInventory.CreateItem(ReservedItem);
        CreateReservedStock(ReservedItem."No.", LocationBlue.Code);

        // [GIVEN] Item "B" set up for replenishment by Assembly.
        LibraryInventory.CreateItem(PlannedItem);
        CreateStockkeepingUnit(
          StockkeepingUnit, PlannedItem."No.", LocationBlue.Code, StockkeepingUnit."Replenishment System"::Assembly,
          StockkeepingUnit."Reordering Policy"::"Lot-for-Lot", '');

        // [GIVEN] Sales order "SO" for item "B".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), PlannedItem."No.",
          LibraryRandom.RandInt(50), LocationBlue.Code, WorkDate());

        // [GIVEN] Calculate regenerative plan and carry out action in order to create an assembly order to fulfill "SO".
        PlannedItem.SetRecFilter();
        PlannedItem.SetRange("Location Filter", LocationBlue.Code);
        CalcRegenPlanAndCarryOutActionMessage(PlannedItem);

        // [GIVEN] Double the quantity in "SO".
        UpdateSalesLineQuantity(PlannedItem."No.", SalesLine.Quantity * 2);

        // [WHEN] Replan item "B" and carry out action to adjust the quantity to assemble.
        CalcRegenPlanAndCarryOutActionMessage(PlannedItem);

        // [THEN] Expected receipt date on reservation entries for item "A" has not changed.
        ReservationEntry.SetRange("Item No.", ReservedItem."No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Expected Receipt Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScrapPctIgnoredForAssembledItem()
    var
        ItemProduct: Record Item;
        ItemComponent: Record Item;
        BOMComponent: Record "BOM Component";
        FullWSLocation: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        PlanningComponent: Record "Planning Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Scrap: Decimal;
        DemandQty: Integer;
    begin
        // [FEATURE] [Item] [Planning Component] [Scrap%]
        // [SCENARIO 303068] Calculation of PlanningComponent ignore the scrap% if the replenishment system is Assembly
        Initialize();
        Scrap := 6.66;
        DemandQty := 52;

        // [Given] Full warehouse location
        LibraryWarehouse.CreateFullWMSLocation(FullWSLocation, 10);

        // [Given] Create Item Component. PCS. Base UoM rounding = 1.
        LibraryInventory.CreateItem(ItemComponent);

        ItemUnitOfMeasure.Get(ItemComponent."No.", ItemComponent."Base Unit of Measure");
        ItemUnitOfMeasure.Validate("Qty. Rounding Precision", 1);
        ItemUnitOfMeasure.Modify(true);

        // [Given] Create Item Product. Scrap % = 6.66
        LibraryInventory.CreateItem(ItemProduct);
        ItemProduct.Validate("Scrap %", Scrap);
        ItemProduct.Validate("Replenishment System", ItemProduct."Replenishment System"::Assembly);
        ItemProduct.Modify(true);

        // [Given] Choose "Assembly BOM" and add Item Component = 1.
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ItemProduct."No.", BOMComponent.Type::Item, ItemComponent."No.",
          1, ItemComponent."Base Unit of Measure");

        // [Given] Create Planning line to reflect a demand for ItemProduct
        CreateRequisitionLine(RequisitionLine, ItemProduct."No.", ReqWkshTemplate.Type::Planning);

        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate(Quantity, DemandQty);
        RequisitionLine.Validate("Location Code", FullWSLocation.Code);
        RequisitionLine.Modify(true);

        // [When] Refresh Planning
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, 0, false, true);

        // [Then] Expected Quantity on PlanningComponent ignores scrap %
        PlanningComponent.SetRange("Item No.", ItemComponent."No.");
        PlanningComponent.FindFirst();
        PlanningComponent.TestField("Expected Quantity", DemandQty);

        // [When] Carry out suggested action, in this case create Assembly Order
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [Then] Verify that the Quantity is set to demand quantity and does not include scrap
        AssemblyHeader.SetRange("Item No.", ItemProduct."No.");
        AssemblyHeader.FindFirst();

        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        Assert.RecordCount(AssemblyLine, 1);

        AssemblyLine.FindFirst();
        AssemblyLine.TestField(Quantity, DemandQty);
        AssemblyLine.TestField("Quantity to Consume", DemandQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForProductionItemWithBOMWithNonInventoryItem()
    var
        ProductionItem: Record Item;
        SalesLine: Record "Sales Line";
        NonInventoryItemNo: Code[20];
        InventoryItemNo: Code[20];
    begin
        // [FEATURE] [Item] [Item Type] [Planning Component]
        // [SCENARIO 303068] Calculate Regenerative plan for Production Item whose production BOM contains Item with Type::Non-Inventory
        Initialize();

        // [GIVEN] Production Item with Production BOM containing InventoryItem and NonInventoryItem
        CreateItemWithProdBOMWithNonInventoryItemType(ProductionItem, NonInventoryItemNo, InventoryItemNo);

        // [GIVEN] Sales Order with Production Item as a demand for LocationSilver
        CreateSalesOrder(ProductionItem."No.", '');
        FindSalesLine(SalesLine, ProductionItem."No.");
        SalesLine.Validate("Location Code", LocationSilver.Code);
        SalesLine.Modify(true);

        // [WHEN] Calc. Regenerative Plan for Production Item
        CalculateRegenPlanForPlanningWorksheet(ProductionItem);

        // [THEN] Requisition Line created for ProductionItem
        VerifyRequisitionLineItemExist(ProductionItem."No.");

        // [THEN] Planning Component table contains InventoryItem for LocationSilver
        VerifyPlanningComponentExistForItemLocation(InventoryItemNo, LocationSilver.Code);

        // [THEN] Planning Component table contains NonInventoryItem with blank Location Code
        VerifyPlanningComponentExistForItemLocation(NonInventoryItemNo, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForAssemblyItemWithBOMWithNonInventoryItem()
    var
        AssemblyItem: Record Item;
        SalesLine: Record "Sales Line";
        NonInventoryItemNo: Code[20];
        InventoryItemNo: Code[20];
    begin
        // [FEATURE] [Item] [Item Type] [Planning Component]
        // [SCENARIO 303068] Calculate Regenerative plan for Assembly Item whose assembly BOM contains Item with Type::Non-Inventory
        Initialize();

        // [GIVEN] AssemblyItme with Assembly BOM containing InventoryItem and NonInventoryItem
        CreateItemWithAssemblyBOMWithNonInventoryItemType(AssemblyItem, NonInventoryItemNo, InventoryItemNo);

        // [GIVEN] Sales Order with Production Item as a demand for LocationSilver
        CreateSalesOrder(AssemblyItem."No.", '');
        FindSalesLine(SalesLine, AssemblyItem."No.");
        SalesLine.Validate("Location Code", LocationSilver.Code);
        SalesLine.Modify(true);

        // [WHEN] Calc. Regenerative Plan for AssemblyItem
        CalculateRegenPlanForPlanningWorksheet(AssemblyItem);

        // [THEN] Requisition Line created for AssemblyItem
        VerifyRequisitionLineItemExist(AssemblyItem."No.");

        // [THEN] Planning Component table contains InventoryItem for LocationSilver
        VerifyPlanningComponentExistForItemLocation(InventoryItemNo, LocationSilver.Code);

        // [THEN] Planning Component table contains NonInventoryItem with blank Location Code
        VerifyPlanningComponentExistForItemLocation(NonInventoryItemNo, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithProdOrderFromSalesForStartingEndingTimeLFLItemsWhenBlankDefaultSafetyLeadTime()
    var
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItemNo: Code[20];
        ParentStartingTime: Time;
        ParentStartingDate: Date;
    begin
        // [FEATURE] [Default Safety Lead Time] [Lot-for-Lot] [Production]
        // [SCENARIO 322927] When Safety Lead Times are 0D in Manufacturing Setup and the component Item, then Planning respects Starting/Ending Times
        // [SCENARIO 322927] in scenario when two items are planned, and one of those ones is production component of the other one
        Initialize();

        // [GIVEN] Manufacturing Setup had Default Safety Lead Time = '0D'
        LibraryPlanning.SetDefaultSafetyLeadTime('<0D>');

        // [GIVEN] Parent Item had Production BOM with Child Item as Component, Reordering Policy was Lot-for-Lot for both
        // [GIVEN] Child Item had Production BOM as well and Safety Lead Time = '0D'
        ChildItemNo := CreateLotForLotItemSetup(ParentItem);
        UpdateItemSafetyLeadTime(ChildItemNo, '<0D>');

        // [GIVEN] Sales Order with Parent Item
        CreateSalesOrder(ParentItem."No.", '');

        // [WHEN] Calculate Regenerative Plan for both Items
        CalcRegenPlanForPlanWkshForMultipleItems(ParentItem."No.", ChildItemNo);

        // [THEN] Ending Time in Child Requsition Line matches Starting Time in Parent Requisition Line
        SelectRequisitionLine(RequisitionLine, ParentItem."No.");
        ParentStartingTime := RequisitionLine."Starting Time";
        ParentStartingDate := RequisitionLine."Starting Date";
        SelectRequisitionLine(RequisitionLine, ChildItemNo);
        RequisitionLine.TestField("Ending Date", ParentStartingDate);
        RequisitionLine.TestField("Ending Time", ParentStartingTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithProdOrderFromSalesForStartingEndingTimeLFLItemsWhenComponentSafetyLeadTime()
    var
        ParentItem: Record Item;
        ChildItemNo: Code[20];
    begin
        // [FEATURE] [Safety Lead Time] [Lot-for-Lot] [Production]
        // [SCENARIO 322927] When Component Item has Safety Lead Time <> 0D, then Starting/Ending Times are taken from Manufacturing Setup
        // [SCENARIO 322927] in scenario when two items are planned, and one of those ones is production component of the other one
        Initialize();

        // [GIVEN] Parent Item had Production BOM with Child Item as Component, Reordering Policy was Lot-for-Lot for both
        // [GIVEN] Child Item had Production BOM as well and Safety Lead Time = '1D'
        ChildItemNo := CreateLotForLotItemSetup(ParentItem);
        UpdateItemSafetyLeadTime(ChildItemNo, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));

        // [GIVEN] Sales Order with Parent Item
        CreateSalesOrder(ParentItem."No.", '');

        // [WHEN] Calculate Regenerative Plan for both Items
        CalcRegenPlanForPlanWkshForMultipleItems(ParentItem."No.", ChildItemNo);

        // [THEN] Starting Time and Ending Time in Child Requsition Line is matching Manufacturing Setup Normal Times
        VerifyRequisitionLineStartingAndEndingTime(ChildItemNo);
    end;

    [Test]
    [HandlerFunctions('GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAssemblyWithExistingOrderToOrderPlannedComponent()
    var
        Item: array[3] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Assembly] [Assemble-to-Order] [Order-to-Order Binding] [Reservation]
        // [SCENARIO 338018] Planning a supply for a new assembly does not interfere with already planned order-to-order sales order for the component.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Set up components at location = "BLUE"
        LibraryManufacturing.SetComponentsAtLocation(LocationBlue.Code);

        // [GIVEN] Create assembly structure: item "COMP" is a component of item "INTERMD", which is a component of item "FINAL".
        // [GIVEN] All items are set up for "Order" reordering policy.
        CreateAssemblyStructure(Item);

        // [GIVEN] Sales order for item "INTERMD" on location "BLUE". Creating a sales order generates an assembly in the background.
        // [GIVEN] Calculate regenerative plan for items "COMP" and "INTERMD" and carry out action message.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item[2]."No.", Qty, LocationBlue.Code, WorkDate());
        CalcRegenPlanForPlanWkshForMultipleItems(Item[1]."No.", Item[2]."No.");
        AcceptActionMessage(RequisitionLine, Item[1]."No.");
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [GIVEN] Purchase order to supply "COMP" is created.
        // [GIVEN] Post the purchase order.
        FindPurchLine(PurchaseLine, Item[1]."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Sales order for item "COMP" on location "BLUE".
        // [GIVEN] Calculate regenerative plan and carry out action message.
        // [GIVEN] The sales order becomes order-to-order bound to a new purchase.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item[1]."No.", Qty, LocationBlue.Code, WorkDate());
        CalcRegenPlanForPlanWkshForMultipleItems(Item[1]."No.", Item[2]."No.");
        AcceptActionMessage(RequisitionLine, Item[1]."No.");
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [GIVEN] Sales order for item "FINAL" on location "BLUE".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item[3]."No.", Qty, LocationBlue.Code, WorkDate());

        // [WHEN] Calculate regenerative plan.
        CalcRegenPlanForPlanWkshForMultipleItems(Item[1]."No.", Item[2]."No.");

        // [THEN] Only one planning line for item "COMP" is created.
        SelectRequisitionLine(RequisitionLine, Item[1]."No.");
        Assert.RecordCount(RequisitionLine, 1);

        // [THEN] The reserved quantity on the sales line for item "COMP" has not changed.
        FindSalesLine(SalesLine, Item[1]."No.");
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningComponentIsReservedFromReqLineAfterPlanningViaCTP()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Capable to Promise] [Reservation] [Planning Component]
        // [SCENARIO 375636] Planning component is reserved from requisition line for critical component when the planning is carried out with Capable-to-Promise.
        Initialize();

        // [GIVEN] Critical component item "C".
        // [GIVEN] A critical component will be planned together with the parent item.
        CreateOrderItem(CompItem);
        CompItem.Validate(Critical, true);
        CompItem.Modify(true);

        // [GIVEN] Production BOM that includes component "C".
        CreateAndCertifyProductionBOM(ProductionBOMHeader, CompItem."No.");

        // [GIVEN] Manufacturing item "P", select the created production BOM.
        CreateOrderItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Sales order for item "P".
        CreateSalesOrder(ProdItem."No.", '');

        // [WHEN] Open Order Promising and accept "Capable to Promise".
        FindSalesLine(SalesLine, ProdItem."No.");
        OpenOrderPromisingPage(SalesLine."Document No.");

        // [THEN] The planning component "C" is reserved from a planning line.
        VerifyReservationBetweenSources(CompItem."No.", DATABASE::"Requisition Line", DATABASE::"Planning Component");

        // [THEN] The sales line for item "P" is reserved from a planning line.
        VerifyReservationBetweenSources(ProdItem."No.", DATABASE::"Requisition Line", DATABASE::"Sales Line");
    end;

    [Scope('OnPrem')]
    procedure AvailableInventoryOnItemAvailabilityLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InventoryQty: Decimal;
    begin
        // [FEATURE] [Item Availability]
        // [SCENARIO 361176] "Available Inventory" on Item Availability by Location Lines is calculated as Inventory - Reserved Quantity on Inventory
        Initialize();

        // [GIVEN] Item with Inventory = 10 PCS on Location "BLUE"
        CreateItem(Item);
        InventoryQty := LibraryRandom.RandIntInRange(10, 100);
        UpdateInventory(Item."No.", InventoryQty, LocationBlue.Code);

        // [GIVEN] Purchase Order Line with Quantity = 5 PCS with Expected Receipt Date = 10.01.2021 on Location "BLUE"
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Expected Receipt Date", WorkDate());
        PurchaseLine.Validate("Location Code", LocationBlue.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Sales Order Line with Quantity = 2 PCS on Location "BLUE", reserved on inventory
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(InventoryQty - 1));
        SalesLine.Validate("Location Code", LocationBlue.Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [WHEN] Run Item Availability for Location
        // [THEN] Available Inventory = 8 on Item Availability by Location Line for Location "BLUE" on 11.01.2021
        // [THEN] Available Inventory doesn't include Quantity on the Purchase Order
        Item.SetRange("Date Filter", WorkDate() + 1);
        Item.SetRange("Location Filter", LocationBlue.Code);
        VerifyAvailableInventoryOnCalcAvailQuantities(
            Item, InventoryQty - SalesLine.Quantity);
    end;

    [Scope('OnPrem')]
    procedure PlanningComponentIsNotReservedFromReqLineOnDifferentLocation()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        TrackingSpecification: Record "Tracking Specification";
        PlngComponentReserve: Codeunit "Plng. Component-Reserve";
        Qty: Decimal;
    begin
        // [FEATURE] [Reservation] [Planning Component] [Requisition Line] [Location]
        // [SCENARIO 375636] Planning component cannot be reserved from requisition line at different location.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Set up "Components at Location" = "Blue" on the Manufacturing Setup.
        UpdateSetupComponentsAtLocation(LocationBlue.Code);

        // [GIVEN] Component item "C".
        CreateOrderItem(CompItem);

        // [GIVEN] Production BOM that includes component "C".
        CreateAndCertifyProductionBOM(ProductionBOMHeader, CompItem."No.");

        // [GIVEN] Manufacturing item "P", select just created production BOM.
        CreateOrderItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Create and refresh planning line for "P".
        CreateRequisitionLine(RequisitionLine, ProdItem."No.", ReqWkshTemplate.Type::Planning);
        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate(Quantity, Qty);
        RequisitionLine.Modify(true);
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, 0, false, true);

        // [GIVEN] The planning component "C" is at location "Blue".
        PlanningComponent.SetRange("Item No.", CompItem."No.");
        PlanningComponent.FindFirst();
        PlanningComponent.TestField("Location Code", LocationBlue.Code);

        // [GIVEN] Create a new planning line on location "Red" to supply component "C".
        LibraryPlanning.CreateRequisitionLine(
          RequisitionLine, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name");
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", CompItem."No.");
        RequisitionLine.Validate("Location Code", LocationRed.Code);
        RequisitionLine.Validate(Quantity, Qty);
        RequisitionLine.Modify(true);

        // [WHEN] Reserve the planning component from the planning line.
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Requisition Line", 0,
          RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", 0, RequisitionLine."Line No.",
          RequisitionLine."Variant Code", RequisitionLine."Location Code", RequisitionLine."Qty. per Unit of Measure");
        PlngComponentReserve.BindToTracking(
            PlanningComponent, TrackingSpecification, RequisitionLine.Description, RequisitionLine."Ending Date", Qty, Qty);

        // [THEN] The planning component is not reserved.
        // [THEN] No error is thrown.
        PlanningComponent.CalcFields("Reserved Quantity");
        PlanningComponent.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningComponentIsPartiallyReservedFromReqLineAfterPlanningViaCTP()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        QtyPer: Decimal;
    begin
        // [FEATURE] [Capable to Promise] [Reservation] [Planning Component]
        // [SCENARIO 383039] When running Capable-to-Promise, a planning component that is available in inventory, is partially reserved from requisition line.
        Initialize();

        // [GIVEN] Critical component item "C".
        // [GIVEN] A critical component will be planned together with the parent item.
        CreateOrderItem(CompItem);
        CompItem.Validate(Critical, true);
        CompItem.Modify(true);

        // [GIVEN] We have 20 pcs of item "C" on hand.
        UpdateInventory(CompItem."No.", LibraryRandom.RandIntInRange(20, 40), '');
        CompItem.CalcFields(Inventory);

        // [GIVEN] Production BOM that includes 3 pcs of component "C".
        QtyPer := CreateAndCertifyProductionBOM(ProductionBOMHeader, CompItem."No.");

        // [GIVEN] Manufacturing item "P", select the created production BOM.
        CreateOrderItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Sales order for 50 pcs of item "P".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ProdItem."No.", LibraryRandom.RandIntInRange(50, 100), '', WorkDate());

        // [WHEN] Open Order Promising and accept "Capable to Promise".
        OpenOrderPromisingPage(SalesLine."Document No.");

        // [THEN] 130 pcs of planning component "C" are reserved from a planning line (150 total need - 20 on hand).
        VerifyReservedQtyBetweenSources(
          CompItem."No.", DATABASE::"Requisition Line", DATABASE::"Planning Component", SalesLine.Quantity * QtyPer - CompItem.Inventory);

        // [THEN] 50 pcs of item "P" are reserved from a planning line for the sales line.
        VerifyReservedQtyBetweenSources(
          ProdItem."No.", DATABASE::"Requisition Line", DATABASE::"Sales Line", SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedReorderQtyItemPlanningWithBlankSafetyLeadTime()
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        StartingDate: Date;
        Qty: Decimal;
    begin
        // [FEATURE] [Fixed Reorder Quantity] [Safety Lead Time]
        // [SCENARIO 380947] Item set up for Fixed Reorder Qty. planning policy and blank Safety Lead Time is not suggested to be produced before starting date of the planning period.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);
        StartingDate := CalcDate('<WD3>', WorkDate());

        // [GIVEN] Set "Safety Lead Time" = <blank> in Manufacturing Setup.
        LibraryPlanning.SetDefaultSafetyLeadTime('<0D>');

        // [GIVEN] Create manufacturing item with routing.
        // [GIVEN] Set up Reordering Policy = "Fixed Reorder Qty." on the item.
        // [GIVEN] Reorder Point = 6, Reorder Quantity = 12.
        CreateRouting(RoutingHeader);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Validate("Reorder Point", Qty);
        Item.Validate("Reorder Quantity", 2 * Qty);
        Item.Modify(true);

        // [GIVEN] Post 6 pcs of the item to inventory. Posting Date = 01/01/22 (MM/DD/YY).
        UpdateInventory(Item."No.", Qty, '');

        // [GIVEN] Create sales order for 3 pcs on 01/05/22 to bring the remaining qty. below reorder point.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty / 2, '', StartingDate);

        // [WHEN] Calculate regenerative plan from 01/05/22 to 02/05/22.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartingDate, LibraryRandom.RandDateFrom(StartingDate, 30));

        // [THEN] Starting Date = Due Date = 01/05/22 on the planning line.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Starting Date", StartingDate);
        RequisitionLine.TestField("Due Date", StartingDate);
    end;

    [Test]
    procedure DoNotCopyDimensionSetIDFromReqLineToTransferHeader()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        GlobalDimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        // [FEATURE] [Dimension] [Transfer]
        // [SCENARIO 407898] Dimension Set ID is not copied from planning worksheet to a new transfer header.
        Initialize();

        // [GIVEN] Item with dimension.
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create SKU for the item at location "Red" with replenishment system Transfer from location "Blue".
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationRed.Code, Item."No.", '');
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::Transfer);
        StockkeepingUnit.Validate("Transfer-from Code", LocationBlue.Code);
        StockkeepingUnit.Modify(true);

        // [GIVEN] Create a line in planning worksheet for future transfer order.
        // [GIVEN] Dimension Set ID = "X" on the requisition line.
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate("Location Code", LocationRed.Code);
        RequisitionLine.Validate(Quantity, LibraryRandom.RandInt(10));
        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.Validate("Accept Action Message", true);
        LibraryDimension.GetGlobalDimCodeValue(1, GlobalDimensionValue);
        RequisitionLine.Validate("Shortcut Dimension 1 Code", GlobalDimensionValue.Code);
        LibraryDimension.GetGlobalDimCodeValue(2, GlobalDimensionValue);
        RequisitionLine.Validate("Shortcut Dimension 2 Code", GlobalDimensionValue.Code);
        RequisitionLine.Modify(true);
        DimensionSetID := RequisitionLine."Dimension Set ID";

        // [WHEN] Carry out action message.
        RequisitionLine.SetRecFilter();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] Transfer order has been created.
        // [THEN] Dimension Set ID = "X" on the transfer line.
        TransferLine.SetRange("Item No.", Item."No.");
        TransferLine.FindFirst();
        TransferLine.TestField("Dimension Set ID", DimensionSetID);

        // [THEN] Dimension Set ID = 0 on the transfer header.
        TransferHeader.Get(TransferLine."Document No.");
        TransferHeader.TestField("Dimension Set ID", 0);
        TransferHeader.TestField("Shortcut Dimension 1 Code", '');
        TransferHeader.TestField("Shortcut Dimension 2 Code", '');
    end;

    [Test]
    procedure CurrencyCodeOnPlanningLineForCancelPurchase()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency Code] [Purchase]
        // [SCENARIO 393765] Currency Code on planning line for cancel purchase is inherited from the purchase line.
        Initialize();

        // [GIVEN] Item with vendor, set up Currency Code = "FCY" for the vendor.
        CreateOrderItem(Item);
        CurrencyCode := UpdateItemWithVendor(Item);

        // [GIVEN] Create sales order.
        CreateSalesOrder(Item."No.", '');

        // [GIVEN] Calculate plan and carry out action message to create a purchase order.
        CalcRegenPlanAndCarryOut(Item, WorkDate(), WorkDate());

        // [GIVEN] Delete the sales order.
        FindSalesOrderHeader(SalesHeader, Item."No.");
        SalesHeader.Delete(true);

        // [WHEN] Calculate plan again.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] A planning line for cancel has been created.
        // [THEN] Currency Code on the planning line = "FCY".
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Action Message", RequisitionLine."Action Message"::Cancel);
        RequisitionLine.TestField("Currency Code", CurrencyCode);
    end;

    [Test]
    procedure PlanningWontTryToRescheduleReleasedProdOrderWithPostedOutput()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        DatePeriod: DateFormula;
        Qty: Decimal;
    begin
        // [FEATURE] [Production Order] [Reschedule]
        // [SCENARIO 413877] The planning system won't try to reschedule released production order with posted output.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(500, 1000);

        // [GIVEN] Manufacturing item with "Lot Accumulation Period" = 1 month, and "Maximum Order Quantity" = 1000.
        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order");
        Evaluate(DatePeriod, '<1M>');
        Item.Validate("Lot Accumulation Period", DatePeriod);
        Item.Validate("Maximum Order Quantity", Qty);
        Item.Modify(true);

        // [GIVEN] Sales order for 1000 pcs, shipment date = WorkDate() + 2 weeks.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Shipment Date", LibraryRandom.RandDate(20));
        SalesLine.Modify(true);

        // [GIVEN] Calculate regerenative plan and carry out action message.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.ModifyAll("Accept Action Message", true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [GIVEN] Firm planned production order is created. Change the status to "Released".
        ProductionOrder.SetRange("Source No.", Item."No.");
        ProductionOrder.FindFirst();
        LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProductionOrder."No.");

        // [GIVEN] Post output for 200 pcs, this production order can't be rescheduled any more.
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();
        CreateAndPostOutputJournal(ProdOrderLine, Qty / 5);

        // [GIVEN] Another sales order for 1000 pcs, shipment date = WORKDATE.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Shipment Date", WorkDate());
        SalesLine.Modify(true);

        // [WHEN] Calculate regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] The system suggests to plan 1000 pcs.
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.CalcSums(Quantity);
        RequisitionLine.TestField(Quantity, Qty);

        // [THEN] The planning system does not suggest rescheduling the released production order.
        RequisitionLine.SetRange("Ref. Order No.", ProdOrderLine."Prod. Order No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderValueEntryRelatedGLProdOrderNo()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        ValueEntry: Record "Value Entry";
        GLItemLedgerRelation: Record "G/L - Item Ledger Relation";
    begin
        // [SCENARIO 415833] G/L entries related to Value Entry should contain 'Prod. Order No.' 
        // [GIVEN] Create Item. Create Routing and update on Item.
        Initialize();
        LibraryInventory.SetAutomaticCostPosting(true);
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN]  Create and refresh Released Production Order. 'Order No.' = 'RPON'
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // [GIVEN] Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [WHEN] After carry out, Post Purchase Order as Receive and invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, true);
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
        PurchInvHeader.FindFirst();

        // [THEN] G/L Entry related to Value Entry have 'Prod. Order No.' = 'RPON'
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProductionOrder."No.");
        ValueEntry.FindSet();
        repeat
            GLItemLedgerRelation.SetRange("Value Entry No.", ValueEntry."Entry No.");
            if GLItemLedgerRelation.FindSet() then
                repeat
                    GLEntry.Get(GLItemLedgerRelation."G/L Entry No.");
                    GLEntry.TestField("Prod. Order No.", ProductionOrder."No.");
                until GLItemLedgerRelation.Next() = 0;
        until ValueEntry.Next() = 0;
    end;

    [Test]
    procedure DirectUnitCostInPlannedPurchaseOrderCorrespondsOrderDate()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PriceListLine: Record "Price List Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PriceCalculationSetup: Record "Price Calculation Setup";
        LeadTime: DateFormula;
        OldPrice: Decimal;
        NewPrice: Decimal;
    begin
        // [FEATURE] [Purchase Price]
        // [SCENARIO 405461] Direct Unit Cost on purchase line created by planning corresponds to Order Date in the purchase header.
        Initialize();
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.AddSetup(
          PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Purchase,
          "Price Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        OldPrice := LibraryRandom.RandDecInRange(10, 20, 2);
        NewPrice := LibraryRandom.RandDecInRange(30, 60, 2);
        Evaluate(LeadTime, '<14D>');

        // [GIVEN] Lot-for-lot item with vendor and Lead Time Calculation = 14D.
        LibraryPurchase.CreateVendor(Vendor);
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate("Lead Time Calculation", LeadTime);
        Item.Modify(true);

        // [GIVEN] Purchase price "X" ending yesterday (WorkDate() - 1).
        LibraryPriceCalculation.CreatePurchPriceLine(
          PriceListLine, '', "Price Source Type"::Vendor, Vendor."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Direct Unit Cost", OldPrice);
        PriceListLine.Validate("Ending Date", WorkDate() - 1);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [GIVEN] Purchase price "Y" starting today (Workdate).
        LibraryPriceCalculation.CreatePurchPriceLine(
          PriceListLine, '', "Price Source Type"::Vendor, Vendor."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Direct Unit Cost", NewPrice);
        PriceListLine.Validate("Starting Date", WorkDate());
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [GIVEN] Sales order.
        CreateSalesOrder(Item."No.", '');

        // [WHEN] Calculate regenerative plan and carry out action message.
        CalcRegenPlanAndCarryOut(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] "Direct Unit Cost" on the supplying purchase line = "Y".
        FindPurchLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField("Direct Unit Cost", NewPrice);

        // [THEN] "Order Date" on the purchase header = Workdate.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.TestField("Order Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineDimensionsAfterDirectTransferHeaderValidate()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        InventorySetup: Record "Inventory Setup";
        GlobalDimensionValue: Record "Dimension Value";
        DimSetId: Integer;
    begin
        Initialize();

        // [GIVEN] Transfer header, transfer line with filled shortcut dimensions
        InventorySetup.Get();
        InventorySetup."Direct Transfer Posting" := InventorySetup."Direct Transfer Posting"::"Direct Transfer";
        InventorySetup.Modify();

        CreateItem(Item);
        UpdateInventory(Item."No.", 10, LocationBlue.Code);
        CreateTransferOrderWithReceiptDate(TransferHeader, Item."No.", LocationBlue.Code, LocationRed.Code, 10);
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        LibraryDimension.GetGlobalDimCodeValue(1, GlobalDimensionValue);
        TransferLine.Validate("Shortcut Dimension 1 Code", GlobalDimensionValue.Code);
        LibraryDimension.GetGlobalDimCodeValue(2, GlobalDimensionValue);
        TransferLine.Validate("Shortcut Dimension 2 Code", GlobalDimensionValue.Code);
        TransferLine.Modify(true);
        DimSetId := TransferLine."Dimension Set ID";

        // [WHEN] Validate "Direct Transfer" in transfer header
        TransferHeader.Validate("Direct Transfer", true);

        // [THEN] "Dimension Set ID" in transfer line remains the same
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        TransferLine.TestField("Dimension Set ID", DimSetId);
    end;

    [Test]
    procedure DirectUnitCostSetOnPlanningLineGoesToPOUnlessPurchPricesAreSet()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 425945] Direct Unit Cost on planning line goes to a new purchase order unless purchase prices are set.
        Initialize();

        // [GIVEN] Lot-for-lot item with vendor, unit cost = "X".
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] Sales order.
        CreateSalesOrder(Item."No.", '');

        // [GIVEN] Calculate regenerative plan.
        // [GIVEN] Set Direct Unit Cost = "Y" on the planning line.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(20, 40, 2));
        RequisitionLine.Modify(true);
        AcceptActionMessage(RequisitionLine, Item."No.");

        // [WHEN] Carry out action message.
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] "Direct Unit Cost" on a new purchase line = "Y".
        FindPurchLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField("Direct Unit Cost", RequisitionLine."Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgReqWkshtRequestPageHandler')]
    procedure ExpectedReceiptDateBlankOnPurchaseHeaderPlannedInReqWksht()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        // [FEATURE] [Purchase] [Requisition Worksheet]
        // [SCENARIO 438980] "Expected Receipt Date" is blank on purchase order header created from requisition worksheet.
        Initialize();

        CreateFRQItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        LibraryPlanning.CalcRequisitionPlanForReqWkshAndGetLines(RequisitionLine, Item, WorkDate(), WorkDate());
        AcceptActionMessage(RequisitionLine, Item."No.");

        Commit();
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(true);
        CarryOutActionMsgReq.Run();

        FindPurchLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.TestField("Expected Receipt Date", 0D);
    end;

    [Test]
    procedure ExpectedReceiptDateBlankOnPurchaseHeaderPlannedInPlanWksht()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Planning Worksheet]
        // [SCENARIO 438980] "Expected Receipt Date" is blank on purchase order header created from planning worksheet.
        Initialize();

        CreateFRQItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        AcceptActionMessage(RequisitionLine, Item."No.");

        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        FindPurchLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.TestField("Expected Receipt Date", 0D);
    end;

    [Test]
    [HandlerFunctions('GenericMessageHandler')]
    procedure KeepOriginalItemTrackingInDemandInFrozenZone()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        LotNos: array[2] of Code[20];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 443870] Keep original item tracking in a demand in frozen zone (period before planning start date).
        Initialize();
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Lot-tracked item set up for "lot-for-lot" planning.
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Modify(true);

        // [GIVEN] Post 5 pcs of the item to inventory, assign lot no. "L1".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, '', LotNos[1], ItemJournalLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for 15 pcs, assign lot no. "L2".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandIntInRange(11, 20), '', CalcDate('<-1W>', WorkDate()));
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNos[2], SalesLine.Quantity);

        // [WHEN] Calculate regenerative plan in planning worksheet.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));

        // [THEN] The program suggests purchasing 10 pcs.
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, SalesLine.Quantity - ItemJournalLine.Quantity);

        // [THEN] Item tracking for the sales line stays intact - Lot "L2" for 15 pcs.
        ReservationEntry.Reset();
        ReservationEntry.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", true);
        ReservationEntry.SetRange("Lot No.", LotNos[2]);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, -SalesLine.Quantity);
    end;

    [Test]
    procedure PlanningTwoSKUEachCrossesReorderPoint()
    var
        Item: Record Item;
        ItemVariant: array[2] of Record "Item Variant";
        SKU: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ReorderQty: Decimal;
        SalesQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Reorder Point] [SKU]
        // [SCENARIO 444268] Separate exception planning lines must be created for each SKU that crosses reorder point.
        Initialize();
        ReorderQty := LibraryRandom.RandInt(10);
        SalesQty := LibraryRandom.RandInt(10);

        // [GIVEN] Item with "Reordering Policy" = "Fixed Qty." and "Reorder Quantity" = 1.
        CreateAndUpdateItem(
            Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Fixed Reorder Qty.", "Manufacturing Policy"::"Make-to-Order", '');
        Item.Validate("Reorder Quantity", ReorderQty);
        Item.Modify(true);

        // [GIVEN] Create two item variants.
        // [GIVEN] Create two stockkeeping units.
        // [GIVEN] Create sales order with two lines, one per each variant. Quantity = 4.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        for i := 1 to ArrayLen(ItemVariant) do begin
            LibraryInventory.CreateItemVariant(ItemVariant[i], Item."No.");
            CreateSKUFromItem(SKU, Item, '', ItemVariant[i].Code);

            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", SalesQty);
            SalesLine.Validate("Variant Code", ItemVariant[i].Code);
            SalesLine.Modify(true);
        end;

        // [WHEN] Calculate regenerative plan.
        Item.Reset();
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Two planning lines have been created for each variant -
        // [THEN] one for 4 pcs that fulfills the sales demand,
        // [THEN] one for 1 pc to respect the reorder quantity.
        for i := 1 to ArrayLen(ItemVariant) do begin
            RequisitionLine.SetRange("Variant Code", ItemVariant[i].Code);
            SelectRequisitionLine(RequisitionLine, Item."No.");
            RequisitionLine.CalcSums(Quantity);

            Assert.RecordCount(RequisitionLine, 2);
            RequisitionLine.TestField(Quantity, SalesQty + ReorderQty);
        end;
    end;

    [Test]
    procedure DoNotPlanComponentsAtLocationSKUWithBlankReorderingPolicy()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Components at Location] [SKU]
        // [SCENARIO 456929] Planning must not include item with Reordering Policy = <blank> when it creates SKU at location defined in "Components at Location" setting.
        Initialize();
        UpdateSetupComponentsAtLocation(LocationBlue.Code);

        LibraryInventory.CreateItem(Item);

        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, LocationRed.Code, Item."No.", '');
        SKU.Validate("Reordering Policy", SKU."Reordering Policy"::"Fixed Reorder Qty.");
        SKU.Validate("Reorder Point", LibraryRandom.RandInt(10));
        SKU.Validate("Reorder Quantity", LibraryRandom.RandIntInRange(20, 40));
        SKU.Modify(true);

        CreateSalesOrderAtLocation(Item."No.", LocationRed.Code);
        CreateSalesOrderAtLocation(Item."No.", LocationBlue.Code);

        CalculateRegenPlanForPlanningWorksheet(Item);

        RequisitionLine.SetRange("Location Code", LocationRed.Code);
        SelectRequisitionLine(RequisitionLine, Item."No.");

        RequisitionLine.SetRange("Location Code", LocationBlue.Code);
        asserterror SelectRequisitionLine(RequisitionLine, Item."No.");
    end;

    [Test]
    procedure DoubledDemandPlanningToSupplyWithTransfer()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        RequisitionLine: Record "Requisition Line";
        i: Integer;
    begin
        //avd
        // [FEATURE] [Stockkeeping Unit] [Transfer]
        // [SCENARIO 455484] Planning doubled component demand on location "A" to be supplied with a series of transfers from locations "B" and "C".
        Initialize();

        // [GIVEN] Transfer routes "SILVER" -> "RED" and "RED" -> "BLUE".
        SelectTransferRoute(LocationSilver.Code, LocationRed.Code);
        SelectTransferRoute(LocationRed.Code, LocationBlue.Code);

        // [GIVEN] Item "I" with stockkeeping units on locations "SILVER", "RED", and "BLUE".
        // [GIVEN] SKU for "BLUE" is replenished by transfer from "RED".
        // [GIVEN] SKU for "RED" is replenished by transfer from "SILVER".
        LibraryInventory.CreateItem(Item);
        CreateStockkeepingUnit(
          SKU, Item."No.", LocationBlue.Code, SKU."Replenishment System"::Transfer, SKU."Reordering Policy"::Order, LocationRed.Code);
        CreateStockkeepingUnit(
          SKU, Item."No.", LocationRed.Code, SKU."Replenishment System"::Transfer, SKU."Reordering Policy"::"Lot-for-Lot", LocationSilver.Code);
        CreateStockkeepingUnit(
          SKU, Item."No.", LocationSilver.Code, SKU."Replenishment System"::Purchase, SKU."Reordering Policy"::"Lot-for-Lot", '');

        // [GIVEN] Released production order, refresh.
        // [GIVEN] Add two component lines with item "I" on location "BLUE".
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(
          ProductionOrder, LibraryInventory.CreateItemNo(), LocationBlue.Code, '');
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        for i := 1 to 2 do begin
            LibraryManufacturing.CreateProductionOrderComponent(
              ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
            ProdOrderComponent.Validate("Item No.", Item."No.");
            ProdOrderComponent.Validate("Location Code", LocationBlue.Code);
            ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandInt(10));
            ProdOrderComponent.Modify(true);
        end;

        // [GIVEN] Total quantity on component lines = "X".
        Item.CalcFields("Qty. on Component Lines");

        // [WHEN] Calculate regenerative plan for item "I".
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] Quantity to be purchased on "SILVER" = "X".
        RequisitionLine.SetRange("Location Code", LocationSilver.Code);
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, Item."Qty. on Component Lines");

        // [THEN] Quantity to be transferred to "RED" = "X".
        RequisitionLine.SetRange("Location Code", LocationRed.Code);
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, Item."Qty. on Component Lines");
    end;

    [Test]
    [HandlerFunctions('GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure S465262_DueDatesForProductionOrdersCreatedFromSalesOrderAreEqualToShipmentDates()
    var
        Location: Record Location;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ChildItem: Record Item;
        Item: array[5] of Record Item;
        ItemVariant: array[3] of Record "Item Variant";
        StockkeepingUnit: array[3] of Record "Stockkeeping Unit";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        DateFormulaAsDateFormula: DateFormula;
    begin
        // [FEATURE] [Manufacturing] [Item] [Item Variant] [Stockkeeping Unit] [Safety Lead Time]
        // [SCENARIO 465262] Due dates for production orders created from sales order are equal to shipment dates.
        // [SCENARIO 465263] Create items with variants and various "Safety Lead Time" setup and then create production order from sales order.
        Initialize();

        // [GIVEN] Set "Default Safety Lead Time" = <1D> in Manufacturing Setup.
        LibraryPlanning.SetDefaultSafetyLeadTime('<1D>');

        // [GIVEN] Create Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Routing.
        CreateRoutingSetup(WorkCenter, RoutingHeader);

        // [GIVEN] Create Production BOM.
        LibraryInventory.CreateItem(ChildItem);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ChildItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ChildItem."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Create Item[1] with "Safety Lead Time" = blank and then Variants for Item[1].
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Base Unit of Measure", ChildItem."Base Unit of Measure");
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Validate("Manufacturing Policy", Item[1]."Manufacturing Policy"::"Make-to-Stock");
        Item[1].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[1].Validate("Routing No.", RoutingHeader."No.");
        Item[1].Validate("Reordering Policy", Item[1]."Reordering Policy"::"Lot-for-Lot");
        Evaluate(DateFormulaAsDateFormula, '');
        Item[1].Validate("Safety Lead Time", DateFormulaAsDateFormula);
        Evaluate(DateFormulaAsDateFormula, '<2W>');
        Item[1].Validate("Lot Accumulation Period", DateFormulaAsDateFormula);
        Item[1].Modify(true);

        // [GIVEN] Create 3 Variants for Item[1].
        LibraryInventory.CreateVariant(ItemVariant[1], Item[1]);
        LibraryInventory.CreateVariant(ItemVariant[2], Item[1]);
        LibraryInventory.CreateVariant(ItemVariant[3], Item[1]);

        // [GIVEN] Create Stockkeeping Unit[1] for (Item[1], Item Variant[1], Location) with "Safety Lead Time" = <0D>.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit[1], Location.Code, Item[1]."No.", ItemVariant[1]."Code");
        Evaluate(DateFormulaAsDateFormula, '<0D>');
        StockkeepingUnit[1].Validate("Safety Lead Time", DateFormulaAsDateFormula);
        StockkeepingUnit[1].Modify(true);

        // [GIVEN] Create Stockkeeping Unit[2] for (Item[1], Item Variant[2], Location) with "Safety Lead Time" = <3D>.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit[2], Location.Code, Item[1]."No.", ItemVariant[2]."Code");
        Evaluate(DateFormulaAsDateFormula, '<3D>');
        StockkeepingUnit[2].Validate("Safety Lead Time", DateFormulaAsDateFormula);
        StockkeepingUnit[2].Modify(true);

        // [GIVEN] Create Stockkeeping Unit[3] for (Item[1], Item Variant[3], Location) with "Safety Lead Time" = <5D>.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit[3], Location.Code, Item[1]."No.", ItemVariant[3]."Code");
        Evaluate(DateFormulaAsDateFormula, '<5D>');
        StockkeepingUnit[3].Validate("Safety Lead Time", DateFormulaAsDateFormula);
        StockkeepingUnit[3].Modify(true);

        // [GIVEN] Create Item[2] with "Safety Lead Time" = blank and then Variants for this Item.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Base Unit of Measure", ChildItem."Base Unit of Measure");
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Stock");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Validate("Routing No.", RoutingHeader."No.");
        Item[2].Validate("Reordering Policy", Item[2]."Reordering Policy"::"Lot-for-Lot");
        Evaluate(DateFormulaAsDateFormula, '');
        Item[2].Validate("Safety Lead Time", DateFormulaAsDateFormula);
        Evaluate(DateFormulaAsDateFormula, '<2W>');
        Item[2].Validate("Lot Accumulation Period", DateFormulaAsDateFormula);
        Item[2].Modify(true);

        // [GIVEN] Create Item[3] with "Safety Lead Time" = <3D> and then Variants for this Item.
        LibraryInventory.CreateItem(Item[3]);
        Item[3].Validate("Base Unit of Measure", ChildItem."Base Unit of Measure");
        Item[3].Validate("Replenishment System", Item[3]."Replenishment System"::"Prod. Order");
        Item[3].Validate("Manufacturing Policy", Item[3]."Manufacturing Policy"::"Make-to-Stock");
        Item[3].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[3].Validate("Routing No.", RoutingHeader."No.");
        Item[3].Validate("Reordering Policy", Item[3]."Reordering Policy"::"Lot-for-Lot");
        Evaluate(DateFormulaAsDateFormula, '<3D>');
        Item[3].Validate("Safety Lead Time", DateFormulaAsDateFormula);
        Evaluate(DateFormulaAsDateFormula, '<2W>');
        Item[3].Validate("Lot Accumulation Period", DateFormulaAsDateFormula);
        Item[3].Modify(true);

        // [GIVEN] Create Item[4] with "Safety Lead Time" = <5D> and then Variants for this Item.
        LibraryInventory.CreateItem(Item[4]);
        Item[4].Validate("Base Unit of Measure", ChildItem."Base Unit of Measure");
        Item[4].Validate("Replenishment System", Item[4]."Replenishment System"::"Prod. Order");
        Item[4].Validate("Manufacturing Policy", Item[4]."Manufacturing Policy"::"Make-to-Stock");
        Item[4].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[4].Validate("Routing No.", RoutingHeader."No.");
        Item[4].Validate("Reordering Policy", Item[4]."Reordering Policy"::"Lot-for-Lot");
        Evaluate(DateFormulaAsDateFormula, '<3D>');
        Item[4].Validate("Safety Lead Time", DateFormulaAsDateFormula);
        Evaluate(DateFormulaAsDateFormula, '<2W>');
        Item[4].Validate("Lot Accumulation Period", DateFormulaAsDateFormula);
        Item[4].Modify(true);

        // [GIVEN] Create Item[5] with "Safety Lead Time" = <0D> and then Variants for this Item.
        LibraryInventory.CreateItem(Item[5]);
        Item[5].Validate("Base Unit of Measure", ChildItem."Base Unit of Measure");
        Item[5].Validate("Replenishment System", Item[5]."Replenishment System"::"Prod. Order");
        Item[5].Validate("Manufacturing Policy", Item[5]."Manufacturing Policy"::"Make-to-Stock");
        Item[5].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[5].Validate("Routing No.", RoutingHeader."No.");
        Item[5].Validate("Reordering Policy", Item[5]."Reordering Policy"::"Lot-for-Lot");
        Evaluate(DateFormulaAsDateFormula, '<0D>');
        Item[5].Validate("Safety Lead Time", DateFormulaAsDateFormula);
        Evaluate(DateFormulaAsDateFormula, '<2W>');
        Item[5].Validate("Lot Accumulation Period", DateFormulaAsDateFormula);
        Item[5].Modify(true);

        // [GIVEN] Create Sales Order Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [GIVEN] Create Sales Order Line for Item[1] without variant with "Shipment Date" = WorkDate() + 1M.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[1]."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Shipment Date", CalcDate('<1M>', WorkDate()));
        SalesLine.Modify(true);

        // [GIVEN] Create Sales Order Line for Item[1] with Item Variant[1] with "Shipment Date" = WorkDate() + 1M + 1D.
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[1]."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Variant Code", ItemVariant[1]."Code");
        SalesLine.Validate("Shipment Date", CalcDate('<1M + 1D>', WorkDate()));
        SalesLine.Modify(true);

        // [GIVEN] Create Sales Order Line for Item[1] with Item Variant[2] with "Shipment Date" = WorkDate() + 1M + 2D.
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[1]."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Variant Code", ItemVariant[2]."Code");
        SalesLine.Validate("Shipment Date", CalcDate('<1M + 2D>', WorkDate()));
        SalesLine.Modify(true);

        // [GIVEN] Create Sales Order Line for Item[1] with Item Variant[3] with "Shipment Date" = WorkDate() + 1M + 3D.
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[1]."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Variant Code", ItemVariant[3]."Code");
        SalesLine.Validate("Shipment Date", CalcDate('<1M + 3D>', WorkDate()));
        SalesLine.Modify(true);

        // [GIVEN] Create Sales Order Line for Item[2] with "Shipment Date" = WorkDate() + 1M + 4D.
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[2]."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Shipment Date", CalcDate('<1M + 4D>', WorkDate()));
        SalesLine.Modify(true);

        // [GIVEN] Create Sales Order Line for Item[3] with "Shipment Date" = WorkDate() + 1M + 5D.
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[3]."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Shipment Date", CalcDate('<1M + 5D>', WorkDate()));
        SalesLine.Modify(true);

        // [GIVEN] Create Sales Order Line for Item[4] with "Shipment Date" = WorkDate() + 1M + 6D.
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[4]."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Shipment Date", CalcDate('<1M + 6D>', WorkDate()));
        SalesLine.Modify(true);

        // [GIVEN] Create Sales Order Line for Item[5] with "Shipment Date" = WorkDate() + 1M + 7D.
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[5]."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Shipment Date", CalcDate('<1M + 7D>', WorkDate()));
        SalesLine.Modify(true);

        // [WHEN] Create Firm Planned Production Orders from Sales Order.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(SalesHeader, "Production Order Status"::"Firm Planned", "Create Production Order Type"::ItemOrder); // Uses GenericMessageHandler.

        // [THEN] Verify 8 Firm Planned Production Orders are created from Sales Order Lines with "Due Date" = WorkDate() + 1M + XD.
        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", Item[1]."No.");
        ProductionOrder.SetRange("Variant Code", '');
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Due Date", CalcDate('<1M>', WorkDate()));

        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", Item[1]."No.");
        ProductionOrder.SetRange("Variant Code", ItemVariant[1]."Code");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Due Date", CalcDate('<1M + 1D>', WorkDate()));

        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", Item[1]."No.");
        ProductionOrder.SetRange("Variant Code", ItemVariant[2]."Code");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Due Date", CalcDate('<1M + 2D>', WorkDate()));

        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", Item[1]."No.");
        ProductionOrder.SetRange("Variant Code", ItemVariant[3]."Code");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Due Date", CalcDate('<1M + 3D>', WorkDate()));

        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", Item[2]."No.");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Due Date", CalcDate('<1M + 4D>', WorkDate()));

        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", Item[3]."No.");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Due Date", CalcDate('<1M + 5D>', WorkDate()));

        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", Item[4]."No.");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Due Date", CalcDate('<1M + 6D>', WorkDate()));

        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", Item[5]."No.");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Due Date", CalcDate('<1M + 7D>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,GenericMessageHandler')]
    procedure S464697_PostPartialWarehouseShipmentForTransferOrderReplenishedViaProduction_WithReservations()
    var
        Location: Record Location;
        ComponentStoringBin: Record Bin;
        ToProductionBin: Record Bin;
        FromProductionBin: Record Bin;
        PickBin: Record Bin;
        ShipmentBin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        ComponentItem: Record Item;
        ProducedItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PrevComponentsAtLocation: Code[10];
    begin
        // [FEATURE] [Components at Location] [Planning Worksheet] [Calculate Regenerative Plan] [Production BOM] [Released Production Order] [Warehouse Pick] [Inventory Movement] [Transfer Order] [Warehouse Shipment]
        // [SCENARIO 464697] Create Transfer Order and replenish via Production Orders. Create Warehouse Shipment for Transfer Order and post partial Shipment.
        Initialize();

        // [GIVEN] Create and setup Location with basic WMS.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        Location.Validate("Default Bin Selection", Location."Default Bin Selection"::"Fixed Bin");

        // [GIVEN] Create Bin "Shipment Bin" and set it as "Shipment Bin Code" at Location.
        LibraryWarehouse.CreateBin(ShipmentBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Shipment Bin Code", ShipmentBin.Code);

        // [GIVEN] Create Bin "To-Production Bin" and set it as "To-Production Bin Code" at Location.
        LibraryWarehouse.CreateBin(ToProductionBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("To-Production Bin Code", ToProductionBin.Code);

        // [GIVEN] Create Bin "From-Production Bin" and set it as "From-Production Bin Code" at Location.
        LibraryWarehouse.CreateBin(FromProductionBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("From-Production Bin Code", FromProductionBin.Code);
        Location.Modify(true);

        // [GIVEN] Create Bin "Pick Bin".
        LibraryWarehouse.CreateBin(PickBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Create Bin "Component Storing Bin".
        LibraryWarehouse.CreateBin(ComponentStoringBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Set Warehouse Employee for Location as default.
        WarehouseEmployee.SetRange("User ID", UserId());
        WarehouseEmployee.DeleteAll();
        WarehouseEmployee.Reset();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create Component Item.
        LibraryInventory.CreateItem(ComponentItem);
        ComponentItem.Validate("Replenishment System", ComponentItem."Replenishment System"::"Purchase");
        ComponentItem.Validate("Manufacturing Policy", ComponentItem."Manufacturing Policy"::"Make-to-Stock");
        ComponentItem.Modify(true);

        // [GIVEN] Create Produced Item.
        LibraryInventory.CreateItem(ProducedItem);
        ProducedItem.Validate("Replenishment System", ProducedItem."Replenishment System"::"Prod. Order");
        ProducedItem.Validate("Manufacturing Policy", ProducedItem."Manufacturing Policy"::"Make-to-Order");
        ProducedItem.Validate("Reordering Policy", ProducedItem."Reordering Policy"::Order);
        ProducedItem.Validate("Reserve", ProducedItem."Reserve"::Always);
        ProducedItem.Modify(true);

        // [GIVEN] Create and setup Routing and assign to Produced Item.
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(ProducedItem, RoutingHeader."No.");
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify(true);

        // [GIVEN] Create and cerfity production BOM with Component Item in lines.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProducedItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", 1);
        ProductionBOMLine.Validate("Unit of Measure Code", ComponentItem."Base Unit of Measure");
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Assign Prod. BOM No. to Produced Item.
        ProducedItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProducedItem.Modify(true);

        // [GIVEN] Post a Positive Adjustment for "Component Item".
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ComponentItem."No.", 3);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", ComponentStoringBin.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Set "Manufacturing Setup"."Components at Location" to Location.
        PrevComponentsAtLocation := UpdateSetupComponentsAtLocation(Location.Code);

        // [GIVEN] Create other locations for Transfer Order.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] Create Transfer Order with two Produced Item Lines with "Shipment Date" to one day after Work Date and End of Month.
        LibraryWarehouse.CreateTransferHeader(TransferHeader, Location.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine[1], ProducedItem."No.", 1);
        TransferLine[1].Validate("Shipment Date", CalcDate('<+1D>', WorkDate()));
        TransferLine[1].Modify(true);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine[2], ProducedItem."No.", 2);
        TransferLine[2].Validate("Shipment Date", CalcDate('<+1D+CM>', WorkDate()));
        TransferLine[2].Modify(true);

        // [GIVEN] Calculate Regenerative Plan for Produced Item and Location.
        ProducedItem.SetRange("No.", ProducedItem."No.");
        ProducedItem.SetFilter("Location Filter", '%1', Location.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(ProducedItem, WorkDate(), CalcDate('<+1D+CM>', WorkDate()));
        ProducedItem.SetRange("No.");
        ProducedItem.SetRange("Location Filter");

        // [GIVEN] Carry out Action Message to create two Firm Planned Production Orders.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ProducedItem."No.");
        if RequisitionLine.FindSet() then
            repeat
                if RequisitionLine."Action Message" <> RequisitionLine."Action Message"::New then begin
                    RequisitionLine.Validate("Action Message", RequisitionLine."Action Message"::New);
                    RequisitionLine.Modify(true);
                end;
                if not RequisitionLine."Accept Action Message" then begin
                    RequisitionLine.Validate("Accept Action Message", true);
                    RequisitionLine.Modify(true);
                end;
            until RequisitionLine.Next() = 0;
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [GIVEN] Find first Firm Planned Production Order for Produced Item.
        FindProductionOrderNo(ProductionOrder, ProductionOrder."Source Type"::Item, ProducedItem."No.", 1);

        // [GIVEN] Move Production Order from Firm Planned to Released.
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate(), false);
        FindProductionOrderNo(ProductionOrder, ProductionOrder."Source Type"::Item, ProducedItem."No.", 1);

        // [GIVEN] Create Warehouse Pick for Released Production Order to move Component Item from ComponentStoringBin to ToProductionBin.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [GIVEN] Register create Warehouse Pick.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Post Consumption and Output.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        PostProductionOrderConsumption(ProdOrderLine, ComponentItem, Location.Code, ToProductionBin.Code, '', 1, WorkDate(), 0);
        PostProductionOrderOutput(ProdOrderLine, 1, WorkDate(), 0);

        // [GIVEN] Move Production Order from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] Create Internal Movement of one Produced Item from Production Bin to Pick Bin.
        CreateInternalMovement(InternalMovementHeader, Location, PickBin, ProducedItem, FromProductionBin, 1);

        // [GIVEN] Create Inventory Movement for Internal Movement.
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader); // Uses handler ConfirmHandlerYes and GenericMessageHandler.

        // [GIVEN] Auto Fill Qty. to Handle.
        WarehouseActivityHeader.SetCurrentKey("Location Code");
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindLast();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // [GIVEN] Register created Inventory Movement.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Release Transfer Order.
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Create Warehouse Shipment for Transfer Order.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, Location.Code);

        // [GIVEN] Create Warehouse Pick for Warehouse Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] Register Warehouse Pick.
        RegisterWarehouseActivity(TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [WHEN] Post Warehouse Shipment for the first picked line.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Verify last Item Ledger Entry moved to In-Transit Location.
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.TestField("Location Code", InTransitLocation.Code);
        ItemLedgerEntry.TestField("Entry Type", ItemLedgerEntry."Entry Type"::"Transfer");
        ItemLedgerEntry.TestField(Quantity, 1);

        // Teardown: Return "Manufacturing Setup"."Components at Location".
        UpdateSetupComponentsAtLocation(PrevComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNoErrorWhenReceivingSubContractingPurchaseOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        RoutingHeader: Record "Routing Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 490899] Receiving a purchase order for Subcontracting results in No error
        Initialize();

        // [GIVEN] Create Item
        CreateItem(Item);

        // [GIVEN] Create Routing Setup
        CreateRoutingSetup(WorkCenter, RoutingHeader);

        // [GIVEN] Update Item Routing
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh Released Production Order with Location and Bin.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", LocationSilver.Code, Bin.Code);

        // [GIVEN] Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // [GIVEN] Carry Out Action Message for Subcontracting worksheet.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [WHEN] Post and Receive Purchase Order
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify Purchase Order is received with warehouse entry.
        VerifyWareHouseEntry(PurchaseLine."No.")
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure UndoReceiptFromPostedPurchaseReceiptForSubcontractPurchaseOrderOnAverageCosting()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        PurchRcptLine: array[2] of Record "Purch. Rcpt. Line";
    begin
        // [SCENARIO 579253] Undoing Receipt from a Posted Purchase Receipt for a Subcontract Purchase Order Using Average Costing.
        Initialize();

        // [GIVEN] Create Item with routing with Subcontractor and Workcenter.
        CreateItemWithChildReplenishmentPurchaseAsProdBOM(Item);

        // [GIVEN] Validate Costing Method into Item.
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        // [GIVEN] Create Routing Setup.
        CreateRoutingSetup(WorkCenter, RoutingHeader);

        // [GIVEN] Update an Item Routing No.
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Refreshed released production order for "Q" pcs of item "I".
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Set "Unit Cost" = "X" on the Production Order Line.
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ProdOrderLine.Modify(true);

        // [GIVEN] Calculate subcontracts for "W".
        CalculateSubcontractOrder(WorkCenter);

        // [GIVEN] Carry out action messages for Subcontracting Worksheet with creation of Purchase Order.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [GIVEN] Post the Purchase Order as Receive but not as Invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, false);

        // [GIVEN] Find Purchase Recipt Line.
        PurchRcptLine[1].SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine[1].FindFirst();

        // [WHEN] Undo Purchase Receipt Line.
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine[1]);

        // [THEN] New Purchase Recipt Line with Negative Quantity is created.
        PurchRcptLine[2].SetRange("Document No.", PurchRcptLine[1]."Document No.");
        PurchRcptLine[2].SetRange(Quantity, -PurchRcptLine[1].Quantity);
        Assert.RecordIsNotEmpty(PurchRcptLine[2]);
    end;

    local procedure Initialize()
    var
        RequisitionLine: Record "Requisition Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Supply Planning -IV");
        RequisitionLine.DeleteAll();
        ReservationEntry.DeleteAll();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        LibraryApplicationArea.EnableEssentialSetup();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Supply Planning -IV");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        CreateLocationSetup();
        ItemJournalSetup();
        LibrarySetupStorage.SaveManufacturingSetup();
        LibrarySetupStorage.Save(Database::"Inventory Setup");
        ShopCalendarMgt.ClearInternals(); // clear single instance codeunit vars to avoid influence of other test codeunits

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Supply Planning -IV");
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure CreateLocationSetup()
    begin
        CreateAndUpdateLocation(LocationSilver);  // Location Silver: Bin Mandatory TRUE.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationRed);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Random Integer value required for Number of Bins.
    end;

    local procedure ItemJournalSetup()
    begin
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
    end;

    local procedure UpdateItemSafetyLeadTime(ItemNo: Code[20]; SafetyLeadTimeText: Text)
    var
        Item: Record Item;
        SafetyLeadTime: DateFormula;
    begin
        Evaluate(SafetyLeadTime, SafetyLeadTimeText);
        Item.Get(ItemNo);
        Item.Validate("Safety Lead Time", SafetyLeadTime);
        Item.Modify(true);
    end;

    local procedure UpdInvSetupLocMandatory(NewValue: Boolean) Result: Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        Result := InventorySetup."Location Mandatory";
        InventorySetup.Validate("Location Mandatory", NewValue);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateSetupComponentsAtLocation(NewValue: Code[10]) Result: Code[10]
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        Result := ManufacturingSetup."Components at Location";
        ManufacturingSetup.Validate("Components at Location", NewValue);
        ManufacturingSetup.Modify(true);
    end;

    local procedure SetReplenishmentQuantities(var Item: Record Item; NewQuantity: Decimal)
    begin
        Item.Validate("Safety Stock Quantity", NewQuantity);
        Item.Validate("Minimum Order Quantity", NewQuantity);
        Item.Validate("Maximum Order Quantity", NewQuantity);
        Item.Validate("Order Multiple", NewQuantity);
        Item.Validate("Include Inventory", true);
        Item.Modify(true);
    end;

    local procedure CalculateSubcontractingWorksheetForBatch(RequisitionWkshName: Record "Requisition Wksh. Name"; WorkCenter: Record "Work Center")
    var
        RequisitionLine: Record "Requisition Line";
        CalculateSubcontracts: Report "Calculate Subcontracts";
    begin
        RequisitionLine.Init();
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        Clear(CalculateSubcontracts);
        CalculateSubcontracts.SetWkShLine(RequisitionLine);
        CalculateSubcontracts.SetTableView(WorkCenter);
        CalculateSubcontracts.UseRequestPage(false);
        CalculateSubcontracts.RunModal();
    end;

    local procedure CertifyRouting(var RoutingHeader: Record "Routing Header")
    begin
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateItemWithProdBOM(var Item: Record Item; var ChildItem: Record Item) QuantityPer: Decimal
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::Order,
          Item."Manufacturing Policy"::"Make-to-Order", '');
        QuantityPer := CreateChildItemAsProdBOM(ChildItem, ProductionBOMHeader, ChildItem."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemWithChildReplenishmentPurchaseAsProdBOM(var Item: Record Item) QuantityPer: Decimal
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItem: Record Item;
    begin
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::Order,
          Item."Manufacturing Policy"::"Make-to-Order", '');
        QuantityPer := CreateChildItemAsProdBOM(ChildItem, ProductionBOMHeader, ChildItem."Replenishment System"::Purchase);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemWithSKU(var Item: Record Item; var SKU: Record "Stockkeeping Unit"; LocationCode: Code[10])
    begin
        CreateItem(Item);
        Item.Validate("Vendor Item No.", LibraryUtility.GenerateGUID());
        Item.Modify(true);

        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, LocationCode, Item."No.", '');
        SKU.Validate("Vendor Item No.", LibraryUtility.GenerateGUID());
        SKU.Validate("Reordering Policy", SKU."Reordering Policy"::Order);
        SKU.Modify(true);
    end;

    local procedure CreateItemWithSKU(var Item: Record Item; var StockKeepingUnit: Record "Stockkeeping Unit"; var Location: Record Location; var ItemVariant: Record "Item Variant"; var ProductionBOMHeader: Record "Production BOM Header"; var RoutingHeader: Record "Routing Header"; SkipProductionBOM: Boolean; SkipRouting: Boolean)
    begin
        // Create Item, Location, Variant and create a SKU with the created item, variant and location
        LibraryWarehouse.CreateLocation(Location);
        CreateItemWithSKU(Item, StockKeepingUnit, Location.Code);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // Set the Produciton BOM No. and Routing No. on the SKU
        StockKeepingUnit.Rename(Location.Code, Item."No.", ItemVariant.Code);

        // Create and set a Cerfitied Routing 
        if not SkipRouting then begin
            LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
            CertifyRouting(RoutingHeader);
            StockKeepingUnit.Validate("Routing No.", RoutingHeader."No.");
        end;

        // Create and set a certified Produciton BOM
        if not SkipProductionBOM then begin
            LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, Item."No.", 1);
            StockKeepingUnit.Validate("Production BOM No.", ProductionBOMHeader."No.");
        end;
        StockKeepingUnit.Validate("Replenishment System", "Replenishment System"::"Prod. Order");
        StockKeepingUnit.Modify(true);
    end;

    local procedure CreateItemWithSKU(var Item: Record Item; var StockKeepingUnit: Record "Stockkeeping Unit"; var Location: Record Location; var ItemVariant: Record "Item Variant"; var ProductionBOMHeader: Record "Production BOM Header"; var RoutingHeader: Record "Routing Header")
    begin
        CreateItemWithSKU(Item, StockKeepingUnit, Location, ItemVariant, ProductionBOMHeader, RoutingHeader, false, false);
    end;

    local procedure CreateStockkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20]; LocationCode: Code[10]; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; TransferFromCode: Code[10])
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Validate("Reordering Policy", ReorderingPolicy);
        StockkeepingUnit.Validate("Transfer-from Code", TransferFromCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateSKUFromItem(var SKU: Record "Stockkeeping Unit"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, LocationCode, Item."No.", VariantCode);
        SKU.CopyFromItem(Item);
        SKU.Modify(true);
    end;

    local procedure RunOrderPromisingFromSalesHeader(SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.OrderPromising.Invoke();
    end;

    local procedure CreateChildItemAsProdBOM(var ChildItem: Record Item; var ProductionBOMHeader: Record "Production BOM Header"; ReplenishmentSystem: Enum "Replenishment System") QuantityPer: Decimal
    begin
        CreateAndUpdateItem(
          ChildItem, ReplenishmentSystem, ChildItem."Reordering Policy"::Order,
          ChildItem."Manufacturing Policy"::"Make-to-Order", '');
        QuantityPer := CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
    end;

    local procedure CreateCustomerWithLocation(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LocationBlue.Validate(Address, LocationBlue.Name);
        LocationBlue.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(LocationBlue);
        Customer.Validate("Location Code", LocationBlue.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateOrderItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItemWithRouting(var Item: Record Item; MachineCenter1: Record "Machine Center"; MachineCenter2: Record "Machine Center")
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, MachineCenter1."No.", '10', 0, 1);
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, MachineCenter2."No.", '20', 0, 1);
        CertifyRouting(RoutingHeader);

        UpdateItemRoutingNo(Item, RoutingHeader."No.");
    end;

    local procedure CreateRouting(var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        CertifyRouting(RoutingHeader);
    end;

    local procedure CreateRoutingSetup(var WorkCenter: Record "Work Center"; var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        CertifyRouting(RoutingHeader);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateAssemblyItemWithBOM(var Item: Record Item; var CompItem: Record Item) QuantityPer: Decimal
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::Assembly, Item."Reordering Policy"::Order,
          Item."Manufacturing Policy", '');
        CreateAndUpdateItem(
          CompItem, CompItem."Replenishment System"::Purchase, CompItem."Reordering Policy"::Order,
          CompItem."Manufacturing Policy", LibraryPurchase.CreateVendorNo());
        QuantityPer := LibraryRandom.RandInt(5);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompItem."No.", Item."No.", '',
          BOMComponent."Resource Usage Type", QuantityPer, true); // Use Base Unit of Measure as True and Variant Code as blank.
    end;

    local procedure CreateAssemblyStructure(var Item: array[3] of Record Item)
    var
        BOMComponent: Record "BOM Component";
        i: Integer;
    begin
        CreateAndUpdateItem(
          Item[1], Item[1]."Replenishment System"::Purchase, Item[1]."Reordering Policy"::Order,
          Item[1]."Manufacturing Policy", LibraryPurchase.CreateVendorNo());

        for i := 2 to ArrayLen(Item) do begin
            CreateAndUpdateItem(
              Item[i], Item[i]."Replenishment System"::Assembly, Item[i]."Reordering Policy"::Order,
              Item[i]."Manufacturing Policy", '');
            Item[i].Validate("Assembly Policy", Item[i]."Assembly Policy"::"Assemble-to-Order");
            Item[i].Modify(true);

            LibraryAssembly.CreateAssemblyListComponent(
              BOMComponent.Type::Item, Item[i - 1]."No.", Item[i]."No.", '', 0, 1, true);
        end;
    end;

    local procedure CreateReservedStock(ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        UpdateInventory(ItemNo, LibraryRandom.RandIntInRange(50, 100), LocationCode);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), ItemNo,
          LibraryRandom.RandInt(50), LocationCode, WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure CreateItemWithProdBOMWithNonInventoryItemType(var ProductionItem: Record Item; var NonInventoryItemNo: Code[20]; var InventoryItemNo: Code[20])
    var
        InventoryItem: Record Item;
        NonInventoryItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(InventoryItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);
        InventoryItemNo := InventoryItem."No.";
        NonInventoryItemNo := NonInventoryItem."No.";

        LibraryInventory.CreateItemManufacturing(ProductionItem);
        ProductionItem.Validate("Replenishment System", ProductionItem."Replenishment System"::"Prod. Order");
        ProductionItem.Validate("Reordering Policy", ProductionItem."Reordering Policy"::"Maximum Qty.");
        ProductionItem.Validate("Maximum Inventory", LibraryRandom.RandInt(10));
        ProductionItem.Modify(true);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProductionItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item,
          InventoryItem."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item,
          NonInventoryItem."No.", LibraryRandom.RandInt(10));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        ProductionItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductionItem.Modify(true);
    end;

    local procedure CreateItemWithAssemblyBOMWithNonInventoryItemType(var AssemblyItem: Record Item; var NonInventoryItemNo: Code[20]; var InventoryItemNo: Code[20])
    var
        NonInventoryItem: Record Item;
        InventoryItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateItem(InventoryItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);
        InventoryItemNo := InventoryItem."No.";
        NonInventoryItemNo := NonInventoryItem."No.";

        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Validate("Reordering Policy", AssemblyItem."Reordering Policy"::"Maximum Qty.");
        AssemblyItem.Validate("Maximum Inventory", LibraryRandom.RandInt(10));
        AssemblyItem.Modify(true);

        LibraryInventory.CreateBOMComponent(
          BOMComponent, AssemblyItem."No.", BOMComponent.Type::Item, InventoryItem."No.",
          LibraryRandom.RandDec(10, 2), InventoryItem."Base Unit of Measure");
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AssemblyItem."No.", BOMComponent.Type::Item, NonInventoryItem."No.",
          LibraryRandom.RandDec(10, 2), NonInventoryItem."Base Unit of Measure");
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure UpdateItemRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateSalesLineQuantity(ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, ItemNo);
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrderWithLocationAndBin(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LoactionCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate("Location Code", LoactionCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
    end;

    local procedure PostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; ToInvoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, ToInvoice);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryPurchase.CreateSubcontractor(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);

        // Calculate calendar.
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
    end;

    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInDecimalRange(10, 20, 2));
        RequisitionLine.Modify(true);
    end;

    local procedure SelectPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure CalculateSubcontractOrder(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.SetRange("No.", WorkCenter."No.");
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
    end;

    local procedure CarryOutActionMessageSubcontractWksh(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        Location.Validate("Pick According to FEFO", false);
        Location.Modify(true);
    end;

    local procedure CreateAndUpdateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; ManufacturingPolicy: Enum "Manufacturing Policy"; VendorNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
    end;

    local procedure CreateItemWithClosedBOMAndVersion(var Item: Record Item; var ProdBOMVersion: Record "Production BOM Version")
    var
        ChildItem: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithProdBOM(Item, ChildItem);
        ProdBOMHeader.Get(Item."Production BOM No.");
        UpdateProductionBOMStatus(ProdBOMHeader, ProdBOMHeader.Status::Closed);

        CreateProductionBOMVersion(ProdBOMVersion, ProdBOMHeader, ChildItem."No.", ProdBOMHeader."Unit of Measure Code", 1);
    end;

    local procedure GetRequiredDate(Days: Integer; IncludeAdditionalPeriod: Integer; RelativeDate: Date; SignFactor: Integer) NewDate: Date
    begin
        // Calculating a New Date relative to WorkDate.
        NewDate :=
          CalcDate('<' + Format(SignFactor * LibraryRandom.RandInt(Days) + IncludeAdditionalPeriod) + 'D>', RelativeDate);
    end;

    local procedure UpdateProdOrderLineUnitOfMeasureCode(ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateProdOrderLineQty(ItemNo: Code[20]; NewQty: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, NewQty);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateRequisitionLineDueDateAndQuantity(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        NewDate: Date;
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        NewDate := GetRequiredDate(10, 0, RequisitionLine."Due Date", 1);  // Due Date more than current Due Date on Requisition Line.
        RequisitionLine.Validate("Due Date", NewDate);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Modify(true);
    end;

    local procedure CreateAndCertifyMultiLineRoutingSetup(var WorkCenter: Record "Work Center"; var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; var RoutingLine2: Record "Routing Line")
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        CreateRoutingLine(RoutingLine2, RoutingHeader, WorkCenter."No.");
        CertifyRouting(RoutingHeader);
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
    end;

    local procedure CalculateSubcontractsWithProdOrderRoutingLine(ProductionOrderNo: Code[20]; StartingDate: Date)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange("Starting Date", StartingDate);
        LibraryManufacturing.CalculateSubcontractOrderWithProdOrderRoutingLine(ProdOrderRoutingLine);
    end;

    local procedure CreateSalesOrder(ItemNo: Code[20]; CustomerNo: Code[20])
    begin
        CreateSalesOrder(ItemNo, CustomerNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesOrder(ItemNo: Code[20]; CustomerNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesOrderAtLocation(ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
            ItemNo, LibraryRandom.RandInt(10), LocationCode, WorkDate());
    end;

    local procedure CarryOutActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CalculatePlanForRequisitionWorksheet(Item: Record Item)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name)
    end;

    local procedure CreateProductionBOMVersion(var ProductionBomVersion: Record "Production BOM Version"; ProdBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; UoMCode: Code[10]; QtyPer: Decimal)
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBomVersion, ProdBOMHeader."No.", LibraryUtility.GenerateGUID(), UoMCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProdBOMHeader, ProdBOMLine, ProductionBomVersion."Version Code", ProdBOMLine.Type::Item, ItemNo, QtyPer);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::Planning);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
    end;

    local procedure FindPurchLine(var PurchLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("No.", ItemNo);
        PurchLine.FindFirst();
    end;

    local procedure UpdateSalesLineWithDropShipmentPurchasingCode(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        Purchasing: Record Purchasing;
    begin
        CreatePurchasingCodeWithDropShipment(Purchasing);
        FindSalesLine(SalesLine, ItemNo);
        SetPurchasingAndLocationOnSalesLine(SalesLine, LocationCode, Purchasing.Code);
    end;

    local procedure UpdateSalesLineWithSpecialOrderPurchasingCode(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        Purchasing: Record Purchasing;
    begin
        CreatePurchasingCodeWithSpecialOrder(Purchasing);
        FindSalesLine(SalesLine, ItemNo);
        SetPurchasingAndLocationOnSalesLine(SalesLine, LocationCode, Purchasing.Code);
    end;

    local procedure SetPurchasingAndLocationOnSalesLine(var SalesLine: Record "Sales Line"; LocationCode: Code[10]; PurchasingCode: Code[10])
    begin
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchasingCodeWithDropShipment(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
    end;

    local procedure CreatePurchasingCodeWithSpecialOrder(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
    end;

    local procedure GetSalesOrderForDropShipmentAndCarryOutReqWksh(var SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName);
        GetSalesOrderDropShipment(SalesLine, RequisitionLine, RequisitionWkshName);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure GetSalesOrderForSpecialOrderAndCarryOutReqWksh(ItemNo: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
    end;

    local procedure UpdateInventory(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostOutputJournal(ProdOrderLine: Record "Prod. Order Line"; OutputQty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ProdOrderLine."Item No.", ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Output Quantity", OutputQty);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateTransferOrderWithReceiptDate(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; TransferFrom: Code[10]; TransferTo: Code[10]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
        ReceiptDate: Date;
    begin
        SelectTransferRoute(TransferFrom, TransferTo);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, TransferFrom, TransferTo, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        ReceiptDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Transfer Line Receipt Date more than WORKDATE.
        TransferLine.Validate("Receipt Date", ReceiptDate);
        TransferLine.Modify(true);
    end;

    local procedure SelectTransferRoute(TransferFrom: Code[10]; TransferTo: Code[10])
    var
        TransferRoute: Record "Transfer Route";
    begin
        // If Transfer Not Found then Create it.
        if not TransferRoute.Get(TransferFrom, TransferTo) then begin
            LibraryWarehouse.CreateTransferRoute(TransferRoute, TransferFrom, TransferTo);
            TransferRoute.Validate("In-Transit Code", LocationInTransit.Code);
            TransferRoute.Modify(true);
        end;
    end;

    local procedure CalculateRegenPlanForPlanningWorksheet(var Item: Record Item)
    var
        EndDate: Date;
    begin
        EndDate := GetRequiredDate(10, 30, WorkDate(), 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);
    end;

    local procedure CalcRegenPlanAndCarryOutActionMessage(var Item: Record Item)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        CalculateRegenPlanForPlanningWorksheet(Item);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.ModifyAll("Accept Action Message", true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure SelectTransferLine(var TransferLine: Record "Transfer Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst();
    end;

    local procedure OpenOrderPromisingPage(SalesHeaderNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesHeaderNo);
        SalesOrder.SalesLines.OrderPromising.Invoke();  // Open OrderPromisingPageHandler.
    end;

    local procedure UpdateSalesLineShipmentDate(ItemNo: Code[20]; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, ItemNo);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure UpdateItemVendorNo(Item: Record Item)
    begin
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure UpdateProductionBOMStatus(var ProductionBOMHeader: Record "Production BOM Header"; NewStatus: Enum "BOM Status")
    begin
        LibraryVariableStorage.Enqueue(CloseBOMVersionsQst);
        ProductionBOMHeader.Validate(Status, NewStatus);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateProdBOMVersionStatus(var ProductionBOMVersion: Record "Production BOM Version"; NewStatus: Enum "BOM Status")
    begin
        ProductionBOMVersion.Validate(Status, NewStatus);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure CalcRegenPlanAndCarryOut(Item: Record Item; StartDate: Date; EndDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);
        SelectRequisitionLine(RequisitionLine, Item."No.");
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure CreateVendorFCY(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        Vendor.Modify(true);
    end;

    local procedure UpdateItemWithVendor(var Item: Record Item): Code[10]
    var
        Vendor: Record Vendor;
    begin
        CreateVendorFCY(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);
        exit(Vendor."Currency Code");
    end;

    local procedure CreateFRQItem(var Item: Record Item)
    begin
        // Create Fixed Reorder Quantity Item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Safety Stock Quantity", LibraryRandom.RandDec(10, 2));
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CalculatePlanForReqWksh(Item: Record Item; ReqWkshTemplateName: Code[10]; RequisitionWkshNameName: Code[10])
    var
        StartDate: Date;
        EndDate: Date;
    begin
        StartDate := GetRequiredDate(10, 0, WorkDate(), -1);  // Start Date less than WORKDATE.
        EndDate := GetRequiredDate(10, 0, WorkDate(), 1);  // End Date more than WORKDATE.
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplateName, RequisitionWkshNameName, StartDate, EndDate);
    end;

    local procedure GetSalesOrderDropShipment(var SalesLine: Record "Sales Line"; var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
    end;

    local procedure CreateItemVendorWithVendorItemNo(var ItemVendor: Record "Item Vendor"; Item: Record Item)
    begin
        LibraryInventory.CreateItemVendor(ItemVendor, Item."Vendor No.", Item."No.");
        ItemVendor.Validate("Vendor Item No.", Item."No.");
        ItemVendor.Modify(true);
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; Type: Enum "Req. Worksheet Template Type")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, Type);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Modify(true);
    end;

    local procedure UpdateRequisitionLineVendorNo(RequisitionLine: Record "Requisition Line"; VendorNo: Code[20])
    begin
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure AssignTrackingOnSalesLine(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; ItemTrackingMode: Option)
    begin
        LibraryVariableStorage.Enqueue(true);  // Boolean - TRUE used inside ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(ItemTrackingMode);  // Enqueue for Page Handler - ItemTrackingPageHandler.
        FindSalesLine(SalesLine, ItemNo);
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Sales Line using page - Item Tracking Lines.
    end;

    local procedure CalcNetChangePlanForPlanWksh(Item: Record Item)
    var
        EndDate: Date;
    begin
        EndDate := GetRequiredDate(10, 30, WorkDate(), 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate(), EndDate, false);
    end;

    local procedure UpdateItemManufacturingPolicy(var Item: Record Item; ManufacturingPolicy: Enum "Manufacturing Policy")
    begin
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateItemLeadTimeCalculation(var Item: Record Item; LeadTimeCalculation: Text[30])
    var
        LeadTimeCalculation2: DateFormula;
    begin
        Evaluate(LeadTimeCalculation2, LeadTimeCalculation);
        Item.Validate("Lead Time Calculation", LeadTimeCalculation2);
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItemSetup(var ParentItem: Record Item): Code[20]
    var
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        Item: Record Item;
    begin
        CreateItem(Item);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item."No.");
        CreateLotForLotItem(ChildItem, ChildItem."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(ChildItem, ProductionBOMHeader."No.");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateLotForLotItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(ParentItem, ProductionBOMHeader."No.");
        exit(ChildItem."No.");
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]) QuantityPer: Decimal
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        QuantityPer := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateOrderTrackingPolicy(var Item: Record Item)
    begin
        Item."Order Tracking Policy" := Item."Order Tracking Policy"::"Tracking Only";
        Item.Modify(true);
    end;

    local procedure UpdateProductionBOMNoOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CalcRegenPlanForPlanWkshForMultipleItems(ItemNo: Code[20]; ItemNo2: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", '%1|%2', ItemNo, ItemNo2);
        CalculateRegenPlanForPlanningWorksheet(Item);
    end;

    local procedure CreateAndPostSalesOrderAsShip(ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(ItemNo, '');
        FindSalesOrderHeader(SalesHeader, ItemNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure FindShopCalendarWorkingDays(var ShopCalendarWorkingDays: Record "Shop Calendar Working Days"; ShopCalendarCode: Code[10])
    begin
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", ShopCalendarCode);
        ShopCalendarWorkingDays.FindFirst();
    end;

    local procedure FindSalesOrderHeader(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, ItemNo);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemNo: Code[20])
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
    end;

    local procedure CreateReleasedProdOrderFromSalesOrder(ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
    begin
        CreateSalesOrder(ItemNo, '');
        FindSalesOrderHeader(SalesHeader, ItemNo);
        LibraryVariableStorage.Enqueue(ReleasedProdOrderCreatedMsg);
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ItemOrder);
    end;

    local procedure CreateWorkCenterWith2MachineCenters(var WorkCenter: Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter[1], WorkCenter."No.", 1);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[1], CalcDate('<-1W>', WorkDate()), WorkDate());
        LibraryManufacturing.CreateMachineCenter(MachineCenter[2], WorkCenter."No.", 1);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[2], CalcDate('<-1W>', WorkDate()), WorkDate());
    end;

    local procedure VerifyItemAvailabilityByPeriod(Item: Record Item; ScheduledRcpt: Decimal; ScheduledRcpt2: Decimal; ProjAvailableBalance: Decimal)
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByPeriod: TestPage "Item Availability by Periods";
    begin
        ItemCard.OpenView();
        ItemCard.Filter.SetFilter("No.", Item."No.");
        ItemAvailabilityByPeriod.Trap();
        ItemCard.Period.Invoke();

        ItemAvailabilityByPeriod.PeriodType.SetValue(PeriodType::Day);
        ItemAvailabilityByPeriod.AmountType.SetValue(AmountType::"Balance at Date");
        ItemAvailabilityByPeriod.ItemAvailLines.Filter.SetFilter("Period Start", StrSubstNo('%1..%2', WorkDate() - 1, WorkDate()));
        ItemAvailabilityByPeriod.ItemAvailLines.First();
        ItemAvailabilityByPeriod.ItemAvailLines.ScheduledRcpt.AssertEquals(ScheduledRcpt);
        ItemAvailabilityByPeriod.ItemAvailLines.Next();
        ItemAvailabilityByPeriod.ItemAvailLines.ScheduledRcpt.AssertEquals(ScheduledRcpt2);
        ItemAvailabilityByPeriod.ItemAvailLines.ProjAvailableBalance.AssertEquals(ProjAvailableBalance);
        ItemAvailabilityByPeriod.Close();
    end;

    local procedure VerifyItemAvailabilityByLocation(Item: Record Item; LocationCode: Code[10]; ProjAvailableBalance: Decimal)
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByLocation: TestPage "Item Availability by Location";
    begin
        // Quantity assertions for the Item availability by location window
        ItemCard.OpenView();
        ItemCard.Filter.SetFilter("No.", Item."No.");
        ItemAvailabilityByLocation.Trap();
        ItemCard.Location.Invoke();

        ItemAvailabilityByLocation.ItemPeriodLength.SetValue(PeriodType::Day);
        ItemAvailabilityByLocation.AmountType.SetValue(AmountType::"Balance at Date");
        ItemAvailabilityByLocation.FILTER.SetFilter("No.", Item."No.");
        ItemAvailabilityByLocation.ItemAvailLocLines.FILTER.SetFilter(Code, LocationCode);
        ItemAvailabilityByLocation.ItemAvailLocLines.First();

        ItemAvailabilityByLocation.ItemAvailLocLines.ProjAvailableBalance.AssertEquals(ProjAvailableBalance);
        ItemAvailabilityByLocation.Close();
    end;

    local procedure VerifyRequisitionLine(RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; WorkCenter: Record "Work Center")
    begin
        RequisitionLine.TestField("Prod. Order No.", ProductionOrder."No.");
        RequisitionLine.TestField(Quantity, ProductionOrder.Quantity);
        RequisitionLine.TestField("Work Center No.", WorkCenter."No.");
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
    end;

    local procedure VerifyRequisitionLineWithOperationNoForSubcontractingWorksheet(ProductionOrder: Record "Production Order"; WorkCenter: Record "Work Center"; No: Code[20]; OperationNo: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Operation No.", OperationNo);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("No.", No);
        VerifyRequisitionLine(RequisitionLine, ProductionOrder, WorkCenter);
    end;

    local procedure VerifyPurchaseShippingDetails(ItemNo: Code[20]; ShipToCode: Code[10]; ShipToAddress: Text[100])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.TestField("Ship-to Address", ShipToAddress);
        PurchaseHeader.TestField("Ship-to Code", ShipToCode);
    end;

    local procedure VerifyRequisitionLineEntries(ItemNo: Code[20]; LocationCode: Code[10]; ActionMessage: Enum "Action Message Type"; DueDate: Date; OriginalQuantity: Decimal; Quantity: Decimal; RefOrderType: Enum "Requisition Ref. Order Type")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField("Location Code", LocationCode);
        RequisitionLine.TestField("Action Message", ActionMessage);
        RequisitionLine.TestField("Original Quantity", OriginalQuantity);
        RequisitionLine.TestField("Due Date", DueDate);
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Ref. Order Type", RefOrderType);
    end;

    local procedure VerifyPurchaseLineCurrencyCode(ItemNo: Code[20]; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseLine.TestField("Currency Code", CurrencyCode);
    end;

    local procedure VerifyPurchaseShipmentMethod(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        SelectPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.TestField("Shipment Method Code", Vendor."Shipment Method Code");
    end;

    local procedure VerifyRequisitionLineBatchAndTemplateForItem(ItemNo: Code[20]; WorksheetTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Worksheet Template Name", WorksheetTemplateName);
        RequisitionLine.TestField("Journal Batch Name", JournalBatchName);
    end;

    local procedure VerifyTrackingOnRequisitionLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryVariableStorage.Enqueue(false);  // Boolean - FALSE used inside ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue Quantity(Base) for Item Tracking Lines Page.
        SelectRequisitionLine(RequisitionLine, ItemNo);
        repeat
            RequisitionLine.TestField(Quantity, Quantity);
            RequisitionLine.OpenItemTrackingLines();
        until RequisitionLine.Next() = 0;
    end;

    local procedure VerifyItemTrackingLineQty(ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingQuantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(TrackingQuantity);
        ItemTrackingLines."Quantity (Base)".AssertEquals(TrackingQuantity);
    end;

    local procedure VerifyRequisitionLineWithSerialTracking(ItemNo: Code[20]; TotalQuantity: Integer)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        VerifyTrackingOnRequisitionLine(ItemNo, 1);  // Quantity value required on Item Tracking Lines because Serial No tracking assigned on Requisition Lines.
        Assert.AreEqual(TotalQuantity, RequisitionLine.Count, RequisitionLinesQuantityErr);  // When Serial No. Tracking is assigned then total No of Requisition Lines equals Total Quantity.
    end;

    local procedure VerifyRequisitionWithTracking(ItemTrackingMode: Option " ","Assign Lot No.","Assign Serial No."; ItemNo: Code[20]; Quantity: Integer)
    begin
        if ItemTrackingMode = ItemTrackingMode::"Assign Lot No." then
            VerifyTrackingOnRequisitionLine(ItemNo, Quantity) // Lot Tracking.
        else
            VerifyRequisitionLineWithSerialTracking(ItemNo, 1);  // Quantity Value required for Serial Tracking.
    end;

    local procedure VerifyRequisitionLineEndingTime(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; EndingTime: Time)
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField("Ending Time", EndingTime);
    end;

    local procedure VerifyRequisitionLineStartingAndEndingTime(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        VerifyRequisitionLineEndingTime(RequisitionLine, ItemNo, ManufacturingSetup."Normal Ending Time");
        RequisitionLine.TestField("Starting Time", ManufacturingSetup."Normal Starting Time");
    end;

    local procedure VerifyRequisitionLineQuantity(ItemNo: Code[20]; ActionMessage: Enum "Action Message Type"; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.SetRange("Action Message", ActionMessage);
        RequisitionLine.FindFirst();
        Assert.AreEqual(Quantity, RequisitionLine.Quantity, RequisitionLineQtyErr);
    end;

    local procedure VerifyRequisitionLineExistenceWithLocation(ItemNo: Code[20]; LocationCode: Code[10]; ReqLineExists: Option "Not Exist",Exist)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.SetRange("Location Code", LocationCode);
        Assert.AreEqual(
          ReqLineExists = ReqLineExpectedTo::"Not Exist", RequisitionLine.IsEmpty,
          StrSubstNo(RequisitionLineExistenceErr, ReqLineExists, ItemNo, LocationCode));
    end;

    local procedure VerifyRequisitionLineForTwoBatches(RequisitionWkshName: Code[10]; RequisitionWkshName2: Code[10]; ItemNo: Code[20]; ProductionOrderNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName2);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        Assert.AreEqual(ProductionOrderNo, RequisitionLine."Prod. Order No.", RequisitionLineProdOrderErr);

        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName);
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    local procedure VerifyRequisitionLineItemExist(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        Assert.RecordIsNotEmpty(RequisitionLine);
    end;

    local procedure VerifyReservationEntryIsEmpty(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20])
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetRange("Source Type", SourceType);
        ReservEntry.SetRange("Source Subtype", SourceSubtype);
        ReservEntry.SetRange("Source ID", SourceID);
        Assert.RecordIsEmpty(ReservEntry);
    end;

    local procedure VerifyReservationBetweenSources(ItemNo: Code[20]; SourceTypeFrom: Integer; SourceTypeFor: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceTypeFrom);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Reservation);

        ReservationEntry.Reset();
        ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        ReservationEntry.TestField("Source Type", SourceTypeFor);
        ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
    end;

    local procedure VerifyReservedQtyBetweenSources(ItemNo: Code[20]; SourceTypeFrom: Integer; SourceTypeFor: Integer; Qty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceTypeFrom);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, Qty);

        ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        ReservationEntry.TestField("Source Type", SourceTypeFor);
        ReservationEntry.TestField(Quantity, -Qty);
    end;

    local procedure VerifyPlanningComponentExistForItemLocation(ItemNo: Code[20]; LocationCode: Code[10])
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetFilter("Item No.", ItemNo);
        PlanningComponent.SetFilter("Location Code", LocationCode);
        Assert.RecordIsNotEmpty(PlanningComponent);
    end;

    local procedure VerifyAvailableInventoryOnCalcAvailQuantities(var Item: Record Item; ExpectedAvailableInventory: Decimal)
    var
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        AvailableInventory: Decimal;
        GrossRequirement: Decimal;
        PlannedOrderRcpt: Decimal;
        ScheduledRcpt: Decimal;
        PlannedOrderReleases: Decimal;
        ProjAvailableBalance: Decimal;
        ExpectedInventory: Decimal;
        QtyAvailable: Decimal;
    begin
        ItemAvailabilityFormsMgt.CalcAvailQuantities(
          Item, false, GrossRequirement, PlannedOrderRcpt, ScheduledRcpt, PlannedOrderReleases,
          ProjAvailableBalance, ExpectedInventory, QtyAvailable, AvailableInventory);
        Assert.AreEqual(ExpectedAvailableInventory, AvailableInventory, 'Unexpected Available Inventory value');
    end;

    local procedure PostProductionOrderConsumption(ProdOrderLine: Record "Prod. Order Line"; ComponentItem: Record Item; LocationCode: Code[10]; BinCode: Code[20]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitCost: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        EntryType: Enum "Item Ledger Entry Type";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption);
        EntryType := ItemJournalLine."Entry Type"::"Negative Adjmt.";
        if ComponentItem.IsNonInventoriableType() then
            EntryType := ItemJournalLine."Entry Type"::Consumption;

        LibraryInventory.MakeItemJournalLine(ItemJournalLine, ItemJournalBatch, ComponentItem, PostingDate, EntryType, Qty);
        ItemJournalLine."Variant Code" := VariantCode;
        ItemJournalLine.Insert();

        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        if ItemJournalLine."Location Code" <> LocationCode then
            ItemJournalLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostProductionOrderOutput(ProdOrderLine: Record "Prod. Order Line"; Qty: Decimal; PostingDate: Date; UnitCost: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        RoutingLine: Record "Routing Line";
    begin
        Item.Get(ProdOrderLine."Item No.");

        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Output);
        LibraryInventory.MakeItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, PostingDate, ItemJournalLine."Entry Type"::"Positive Adjmt.", Qty);
        ItemJournalLine."Location Code" := ProdOrderLine."Location Code";
        ItemJournalLine."Variant Code" := ProdOrderLine."Variant Code";
        ItemJournalLine.Insert();

        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Output);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJournalLine.Validate("Item No.", ProdOrderLine."Item No.");
        if ProdOrderLine."Bin Code" <> '' then
            ItemJournalLine.Validate("Bin Code", ProdOrderLine."Bin Code");
        RoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        if RoutingLine.FindFirst() then
            ItemJournalLine.Validate("Operation No.", RoutingLine."Operation No.");
        ItemJournalLine.Validate("Output Quantity", Qty);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify();

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure FindProductionOrderNo(var ProductionOrder: Record "Production Order"; ProdOrderSourceType: Enum "Prod. Order Source Type"; ItemNo: Code[20]; QtyToFind: Decimal)
    var
        SearchProductionOrder: Record "Production Order";
    begin
        SearchProductionOrder.SetRange("Source Type", ProdOrderSourceType);
        SearchProductionOrder.SetRange("Source No.", ItemNo);
        SearchProductionOrder.SetRange(Quantity, QtyToFind);
        SearchProductionOrder.FindFirst();
        ProductionOrder.Get(SearchProductionOrder.Status, SearchProductionOrder."No.");
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, Type);
        WarehouseActivityHeader.Get(Type, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
    end;

    local procedure CreateInternalMovement(var InternalMovementHeader: Record "Internal Movement Header"; Location: Record Location; ToBin: Record Bin; Item: Record Item; FromBin: Record Bin; Quantity: Decimal)
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, ToBin.Code);
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, Item."No.", FromBin.Code, ToBin.Code, Quantity);
        InternalMovementLine.Validate("From Bin Code", FromBin.Code);
        InternalMovementLine.Validate("To Bin Code", ToBin.Code);
        InternalMovementLine.Modify(true);
    end;

    local procedure VerifyWareHouseEntry(ItemNo: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.FindLast();
        Assert.AreEqual(WarehouseEntry."Item No.", ItemNo, ItemNoErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcRegenPlanReqPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    begin
        CalculatePlanPlanWksh.MPS.SetValue(true);
        CalculatePlanPlanWksh.MRP.SetValue(true);
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.NoPlanningResiliency.SetValue(LibraryVariableStorage.DequeueBoolean());
        CalculatePlanPlanWksh.Item.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CarryOutActionMsgReqWkshtRequestPageHandler(var CarryOutActionMsgReq: TestRequestPage "Carry Out Action Msg. - Req.")
    begin
        CarryOutActionMsgReq.OK().Invoke();
    end;

    [ReportHandler]
    procedure AssemblyOrderSaveAsXML(var AsmOrder: Report "Assembly Order")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        LibraryReportDataset.RunReportAndLoad(Report::"Assembly Order", AssemblyHeader, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderPromisingPageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.CapableToPromise.Invoke();  // Capable To Promise will generate a new Requisition Line for the demand.
        OrderPromisingLines.AcceptButton.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        AssignTracking: Variant;
        TrackingMode: Variant;
        ItemTrackingMode: Option " ","Assign Lot No.","Assign Serial No.";
        AssignTracking2: Boolean;
    begin
        LibraryVariableStorage.Dequeue(AssignTracking);
        AssignTracking2 := AssignTracking;  // Required for variant to boolean.
        if AssignTracking2 then begin
            LibraryVariableStorage.Dequeue(TrackingMode);
            ItemTrackingMode := TrackingMode;
            case ItemTrackingMode of
                ItemTrackingMode::"Assign Lot No.":
                    ItemTrackingLines."Assign Lot No.".Invoke();
                ItemTrackingMode::"Assign Serial No.":
                    ItemTrackingLines."Assign Serial No.".Invoke();
            end;
            LibraryVariableStorage.Enqueue(AvailabilityWarningConfirmationErr);  // Required inside ConfirmHandlerTRUE.
        end else
            VerifyItemTrackingLineQty(ItemTrackingLines);  // Verify Quantity(Base) on Tracking Line.
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PlanningErrorLogPageHandler(var PlanningErrorLog: TestPage "Planning Error Log")
    begin
        PlanningErrorLog."Item No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateNewLotNo.SetValue(false);
        EnterQuantityToCreate.OK().Invoke();  // Assign Serial Tracking on Enter Quantity to Create page.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMsg);
        Assert.IsTrue(AreSameMessages(Message, ExpectedMsg), Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure GenericMessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(ConfirmMessage, ExpectedMessage), ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckProdOrderStatusPageHandler(var CheckProdOrderStatus: TestPage "Check Prod. Order Status")
    begin
        CheckProdOrderStatus.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderPromisingLinesAcceptCapableToPromisePageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.CapableToPromise.Invoke();
        OrderPromisingLines.AcceptButton.Invoke();
    end;
}

