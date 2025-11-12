codeunit 137801 "SCM - Planning UT"
{
    Permissions = TableData "Requisition Line" = i;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        UnexpectedRequisitionLineErr: Label 'Requisition line is unexpected.';
        LeadTimeCalcNegativeErr: Label 'The amount of time to replenish the item must not be negative.';
        WrongQuantityInReqLine: Label 'The quantity %1 is wrong. It must be either %2 or %3.', Comment = 'Example: The quantity 11 is wrong. It must be either 12 or 8.';

    [Test]
    [Scope('OnPrem')]
    procedure VSTF325404()
    begin
        PlanUnitTestScenario(2, 5, 10, PAGE::"Planning Worksheet");
    end;

    [Test]
    [HandlerFunctions('ReqWorkheetMPH')]
    [Scope('OnPrem')]
    procedure OpenReqWorksheetOnRequisitionLine()
    var
        RequisitionWorksheetTemplateName: Code[10];
    begin
        // Setup
        RequisitionWorksheetTemplateName := InitOpenWorksheetFromRequisitionLineScenario(PAGE::"Req. Worksheet");

        // Execute and Verify
        // We call ShowDocument function (codeunit 5530) and expect defined Worksheet Page to be opened
        // If ShowDocument opens another page test fails due to test's Page Handler is not passed
        VerifyShowDocumentOnRequisitionLine(RequisitionWorksheetTemplateName);
    end;

    [Test]
    [HandlerFunctions('PlanningWorkheetMPH,ReqWorksheetTemplateListMPH')]
    [Scope('OnPrem')]
    procedure OpenPlanningWorksheetOnRequisitionLine()
    var
        RequisitionWorksheetTemplateName: Code[10];
    begin
        // Setup
        RequisitionWorksheetTemplateName := InitOpenWorksheetFromRequisitionLineScenario(PAGE::"Planning Worksheet");

        // Execute and Verify
        // We call ShowDocument function (codeunit 5530) and expect defined Worksheet Page to be opened
        // If ShowDocument opens another page then test fails due to test's Page Handler is not passed
        VerifyShowDocumentOnRequisitionLine(RequisitionWorksheetTemplateName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOpenWorksheetOnRequisitionLine()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWorksheetTemplateName: Code[10];
    begin
        // Setup
        RequisitionWorksheetTemplateName := InitOpenWorksheetFromRequisitionLineScenario(0);

        // Execute: Error should be thrown due to Page ID is not set in Req. Worksheet Template
        asserterror VerifyShowDocumentOnRequisitionLine(RequisitionWorksheetTemplateName);

        // Verify
        Assert.ExpectedTestFieldError(ReqWkshTemplate.FieldCaption("Page ID"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnWithNegativeQty()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting";
    begin
        // [SCENARIO 360985] Verify planning system doesn't generate plan for Purchase Return with negative quantity
        // [GIVEN] Purchase Return Order with negative Quantity
        CreateItem(Item, LibraryRandom.RandInt(10), 0, LibraryRandom.RandIntInRange(10, 20));
        MockPurchaseLine(PurchaseLine, Item."No.");
        CreateReqWkshTemplate(ReqWkshTemplate, PAGE::"Req. Worksheet");

        // [WHEN] Calc. Regenerative plan
        InventoryProfileOffsetting.CalculatePlanFromWorksheet(Item, ReqWkshTemplate.Name, '', WorkDate(), WorkDate(), true, false);

        // [THEN] There is no generated planning lines
        RequisitionLine.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
        Assert.IsTrue(RequisitionLine.IsEmpty, UnexpectedRequisitionLineErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLeadTimeCalculationCanBeSetPositive()
    var
        Item: Record Item;
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Item] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation can be updated on Item if the resulting replenishment time is non-negative.
        Initialize();

        // [GIVEN] Item "X".
        LibraryInventory.CreateItem(Item);

        // [WHEN] Update Lead Time Calculation formula on "X" with a non-negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(5)));
        Item.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Lead Time Calculation field is updated.
        Item.TestField("Lead Time Calculation", LeadTimeCalcFormula);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLeadTimeCalculationCannotBeSetNegative()
    var
        Item: Record Item;
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Item] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation cannot be updated on Item if the resulting replenishment time is negative.
        Initialize();

        // [GIVEN] Item "X".
        LibraryInventory.CreateItem(Item);

        // [WHEN] Update Lead Time Calculation formula on "X" with a negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(6, 10)));
        asserterror Item.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Error is thrown.
        Assert.ExpectedError(LeadTimeCalcNegativeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SKULeadTimeCalculationCanBeSetPositive()
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Stockkeeping Unit] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation can be updated on Stockkeeping Unit if the resulting replenishment time is non-negative.
        Initialize();

        // [GIVEN] Stockkeeping Unit "X".
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, '', '');

        // [WHEN] Update Lead Time Calculation formula on "X" with a non-negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(5)));
        StockkeepingUnit.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Lead Time Calculation field is updated.
        StockkeepingUnit.TestField("Lead Time Calculation", LeadTimeCalcFormula);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SKULeadTimeCalculationCannotBeSetNegative()
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Stockkeeping Unit] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation cannot be updated on Stockkeeping Unit if the resulting replenishment time is negative.
        Initialize();

        // [GIVEN] Stockkeeping Unit "X".
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, '', '');

        // [WHEN] Update Lead Time Calculation formula on "X" with a negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(6, 10)));
        asserterror StockkeepingUnit.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Error is thrown.
        Assert.ExpectedError(LeadTimeCalcNegativeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVendorLeadTimeCalculationCanBeSetPositive()
    var
        ItemVendor: Record "Item Vendor";
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Item Vendor] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation can be updated on Item Vendor if the resulting replenishment time is non-negative.
        Initialize();

        // [GIVEN] Item Vendor "X".
        LibraryInventory.CreateItemVendor(ItemVendor, LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo());

        // [WHEN] Update Lead Time Calculation formula on "X" with a non-negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(5)));
        ItemVendor.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Lead Time Calculation field is updated.
        ItemVendor.TestField("Lead Time Calculation", LeadTimeCalcFormula);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVendorLeadTimeCalculationCannotBeSetNegative()
    var
        ItemVendor: Record "Item Vendor";
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Item Vendor] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation cannot be updated on Item Vendor if the resulting replenishment time is negative.
        Initialize();

        // [GIVEN] Item Vendor "X".
        LibraryInventory.CreateItemVendor(ItemVendor, LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo());

        // [WHEN] Update Lead Time Calculation formula on "X" with a negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(6, 10)));
        asserterror ItemVendor.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Error is thrown.
        Assert.ExpectedError(LeadTimeCalcNegativeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLeadTimeCalculationCanBeSetPositive()
    var
        Vendor: Record Vendor;
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Vendor] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation can be updated on Vendor if the resulting replenishment time is non-negative.
        Initialize();

        // [GIVEN] Vendor "X".
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Update Lead Time Calculation formula on "X" with a non-negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(5)));
        Vendor.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Lead Time Calculation field is updated.
        Vendor.TestField("Lead Time Calculation", LeadTimeCalcFormula);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLeadTimeCalculationCannotBeSetNegative()
    var
        Vendor: Record Vendor;
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Vendor] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation cannot be updated on Vendor if the resulting replenishment time is negative.
        Initialize();

        // [GIVEN] Vendor "X".
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Update Lead Time Calculation formula on "X" with a negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(6, 10)));
        asserterror Vendor.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Error is thrown.
        Assert.ExpectedError(LeadTimeCalcNegativeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseHeaderLeadTimeCalculationCanBeSetPositive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Purchase] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation can be updated on Purchase Header if the resulting replenishment time is non-negative.
        Initialize();

        // [GIVEN] Purchase Header "X".
        MockPurchaseOrder(PurchaseHeader, PurchaseLine);

        // [WHEN] Update Lead Time Calculation formula on "X" with a non-negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(5)));
        PurchaseHeader.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Lead Time Calculation field is updated.
        PurchaseHeader.TestField("Lead Time Calculation", LeadTimeCalcFormula);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseHeaderLeadTimeCalculationCannotBeSetNegative()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Purchase] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation cannot be updated on Purchase Header if the resulting replenishment time is negative.
        Initialize();

        // [GIVEN] Purchase Header "X".
        MockPurchaseOrder(PurchaseHeader, PurchaseLine);

        // [WHEN] Update Lead Time Calculation formula on "X" with a negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(6, 10)));
        asserterror PurchaseHeader.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Error is thrown.
        Assert.ExpectedError(LeadTimeCalcNegativeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineLeadTimeCalculationCanBeSetPositive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Purchase] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation can be updated on Purchase Line if the resulting replenishment time is non-negative.
        Initialize();

        // [GIVEN] Purchase Line "X".
        MockPurchaseOrder(PurchaseHeader, PurchaseLine);

        // [WHEN] Update Lead Time Calculation formula on "X" with a non-negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(5)));
        PurchaseLine.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Lead Time Calculation field is updated.
        PurchaseLine.TestField("Lead Time Calculation", LeadTimeCalcFormula);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineLeadTimeCalculationCannotBeSetNegative()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LeadTimeCalcFormula: DateFormula;
    begin
        // [FEATURE] [Purchase] [Lead Time Calculation]
        // [SCENARIO 202530] Lead Time Calculation cannot be updated on Purchase Line if the resulting replenishment time is negative.
        Initialize();

        // [GIVEN] Purchase Line "X".
        MockPurchaseOrder(PurchaseHeader, PurchaseLine);

        // [WHEN] Update Lead Time Calculation formula on "X" with a negative time span.
        Evaluate(LeadTimeCalcFormula, StrSubstNo('<%1M-%2M>', LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(6, 10)));
        asserterror PurchaseLine.Validate("Lead Time Calculation", LeadTimeCalcFormula);

        // [THEN] Error is thrown.
        Assert.ExpectedError(LeadTimeCalcNegativeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManufacturerCodeCannotBeBlank()
    var
        Manufacturers: TestPage Manufacturers;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 235022] You cannot create Manufacturer with blank Code.
        Initialize();

        Manufacturers.OpenNew();
        asserterror Manufacturers.Code.SetValue('');

        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('SalesOrderPlanningModalPageHandler,StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ExpectedDeliveryDateEqualsShipmentDateOnSalesOrderPlanning()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales Order Planning] [Shipment Date] [UT]
        // [SCENARIO 289838] Expected Delivery Date on sales order planning line is equal to Shipment Date for a sales line reserved from inventory.
        Initialize();

        // [GIVEN] Item "I" is in stock.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(20, 40));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order reserved from the inventory.
        // [GIVEN] "Shipment Date" = WORKDATE on the sales line.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [WHEN] Open Sales Order Planning page, invoke "Update Shipment Dates" and close the page.
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesHeader."Document Type", SalesHeader."No.");
        SalesOrder."Pla&nning".Invoke();

        // [THEN] "Expected Delivery Date" on the planning line is WORKDATE.
        Assert.AreEqual(
          WorkDate(), LibraryVariableStorage.DequeueDate(),
          'Wrong expected delivery date on Sales Order Planning line.');

        // [THEN] "Shipment Date" on the sales line is WORKDATE.
        SalesLine.Find();
        SalesLine.TestField("Shipment Date", WorkDate());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderPlanningPageHandler')]
    [Scope('OnPrem')]
    procedure AvailableItemsOtherThanItemTypeInventory()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Qty: Integer;
    begin
        Initialize();

        // [GIVEN] Sales Order with Non-Inventory item with 100 quantity.
        Qty := 100;
        LibraryInventory.CreateItem(Item);
        Item.Type := Item.Type::"Non-Inventory";
        Item.Modify(true);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());

        // [WHEN] Open Sales Order Planning Page.        
        // [THEN] Available items should be equal to 0 on Page Handler SalesOrderPlanningPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."No.");  // Enqueue value for Verifying Item No on Planning Page.
        LibraryVariableStorage.Enqueue(0);  // Enqueue value for Verifying Available on Planning Page.
        OpenSalesOrderPlanning(SalesLine."Document No.");

        // [GIVEN] Sales Order with Service item with 100 quantity.
        Qty := 100;
        LibraryInventory.CreateItem(Item);
        Item.Type := Item.Type::Service;
        Item.Modify(true);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());

        // [WHEN] Open Sales Order Planning Page.        
        // [THEN] Available items should be equal to 0 on Page Handler SalesOrderPlanningPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."No.");  // Enqueue value for Verifying Item No on Planning Page.
        LibraryVariableStorage.Enqueue(0);  // Enqueue value for Verifying Available on Planning Page.
        OpenSalesOrderPlanning(SalesLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManufacturingSetupWithEssentialUserExperience()
    var
        Location: Record Location;
        InventorySetup: TestPage "Inventory Setup";
        ManufacturingSetup: TestPage "Manufacturing Setup";
        SafetyLeadTime: DateFormula;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 300072] "Planned Order Nos.", "Components at Location" and "Default Safety Lead Time" settings in setup are related to planning process and are available with Essential user experience.
        Initialize();

        LibraryWarehouse.CreateLocation(Location);
        Evaluate(SafetyLeadTime, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));

        InventorySetup.OpenEdit();
        InventorySetup."Default Safety Lead Time".SetValue(SafetyLeadTime);
        InventorySetup.Close();

        ManufacturingSetup.OpenEdit();
        ManufacturingSetup."Planned Order Nos.".SetValue(LibraryUtility.GetGlobalNoSeriesCode());
        ManufacturingSetup."Components at Location".SetValue(Location.Code);
        ManufacturingSetup.Close();
    end;

    [Test]
    procedure TransferLevelCodesInChainOfSKU()
    var
        Item: Record Item;
        Location: array[4] of Record Location;
        TransferRoute: Record "Transfer Route";
        SKU: array[4] of Record "Stockkeeping Unit";
        TempSKU: Record "Stockkeeping Unit" temporary;
        i: Integer;
    begin
        // [FEATURE] [Stockkeeping Unit] [Transfer]
        // [SCENARIO 414455] Correct transfer level codes in stockkeeping units that make up a transfer chain.
        Initialize();

        // [GIVEN] Create 4 stockkeeping units (SKU) "A", "B", "C", "D" at locations with the same codes.
        LibraryInventory.CreateItem(Item);
        for i := 1 to ArrayLen(Location) do begin
            LibraryWarehouse.CreateLocation(Location[i]);
            LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU[i], Location[i].Code, Item."No.", '');
        end;

        // [GIVEN] Create transfer routes between locations.
        LibraryInventory.CreateTransferRoute(TransferRoute, Location[1].Code, Location[2].Code);
        LibraryInventory.CreateTransferRoute(TransferRoute, Location[2].Code, Location[3].Code);
        LibraryInventory.CreateTransferRoute(TransferRoute, Location[2].Code, Location[4].Code);

        // [GIVEN] SKU "B" is replenished by transfer from "A", SKUs "C" and "D" are replenished by transfer from "B", see the schema:
        // [GIVEN]   "A"
        // [GIVEN]    |
        // [GIVEN]   "B"
        // [GIVEN]   / \
        // [GIVEN] "C" "D"
        SKU[2].Validate("Replenishment System", SKU[2]."Replenishment System"::Transfer);
        SKU[2].Validate("Transfer-from Code", SKU[1]."Location Code");
        SKU[2].Modify(true);

        SKU[3].Validate("Replenishment System", SKU[3]."Replenishment System"::Transfer);
        SKU[3].Validate("Transfer-from Code", SKU[2]."Location Code");
        SKU[3].Modify(true);

        SKU[4].Validate("Replenishment System", SKU[4]."Replenishment System"::Transfer);
        SKU[4].Validate("Transfer-from Code", SKU[2]."Location Code");
        SKU[4].Modify(true);

        // [GIVEN] Copy SKUs to temporary table.
        for i := 1 to ArrayLen(SKU) do begin
            TempSKU := SKU[i];
            TempSKU.Insert();
        end;

        // [GIVEN] Set up "Transfer-Level Code" = -1 on the SKU "A".
        TempSKU.FindFirst();
        TempSKU."Transfer-Level Code" := -1;
        TempSKU.Modify();

        // [WHEN] Invoke UpdateTempSKUTransferLevels function for the temporary table.
        TempSKU.UpdateTempSKUTransferLevels(TempSKU, TempSKU, TempSKU."Location Code");

        // [THEN] Verify Transfer-level codes.
        // [THEN] SKU's "A" = -1.
        TempSKU.Get(SKU[1]."Location Code", SKU[1]."Item No.", SKU[1]."Variant Code");
        TempSKU.TestField("Transfer-Level Code", -1);

        // [THEN] SKU's "B" = -2.
        TempSKU.Get(SKU[2]."Location Code", SKU[2]."Item No.", SKU[2]."Variant Code");
        TempSKU.TestField("Transfer-Level Code", -2);

        // [THEN] SKUs' "C" and "D" = -3.
        TempSKU.Get(SKU[3]."Location Code", SKU[3]."Item No.", SKU[3]."Variant Code");
        TempSKU.TestField("Transfer-Level Code", -3);
        TempSKU.Get(SKU[4]."Location Code", SKU[4]."Item No.", SKU[4]."Variant Code");
        TempSKU.TestField("Transfer-Level Code", -3);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM - Planning UT");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        LibraryApplicationArea.EnableEssentialSetup();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM - Planning UT");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM - Planning UT");
    end;

    local procedure InitOpenWorksheetFromRequisitionLineScenario(PageID: Integer): Code[10]
    begin
        exit(
          PlanUnitTestScenario(
            LibraryRandom.RandInt(5),
            LibraryRandom.RandInt(5),
            LibraryRandom.RandIntInRange(10, 20),
            PageID));
    end;

    local procedure PlanUnitTestScenario(SafetyStockQty: Decimal; ReorderPoint: Decimal; MaxInventory: Decimal; PageID: Integer): Code[10]
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        ManufacturingSetup: Record "Manufacturing Setup";
        InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting";
    begin
        // Make item
        CreateItem(Item, SafetyStockQty, ReorderPoint, MaxInventory);

        // Make demand
        CreateSalesLine(SalesLine, Item);

        // create template
        CreateReqWkshTemplate(ReqWkshTemplate, PageID);

        // EXERCISE
        ManufacturingSetup.Init();
        InventoryProfileOffsetting.CalculatePlanFromWorksheet(
          Item, ReqWkshTemplate.Name, '', SalesLine."Shipment Date", SalesLine."Shipment Date" + 30, true, false);

        // VERIFY
        VerifyReqLines(Item, ReqWkshTemplate.Name, SalesLine."Outstanding Qty. (Base)");

        exit(ReqWkshTemplate.Name);
    end;

    local procedure CreateItem(var Item: Record Item; SafetyStockQty: Decimal; ReorderPoint: Decimal; MaxInventory: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Item."No." := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), DATABASE::Item);

        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");

        Item."Reordering Policy" := Item."Reordering Policy"::"Maximum Qty.";
        Item."Safety Stock Quantity" := SafetyStockQty;
        Item."Reorder Point" := ReorderPoint;
        Item."Maximum Inventory" := MaxInventory;
        Item."Base Unit of Measure" := ItemUnitOfMeasure.Code;
        Item."Purch. Unit of Measure" := Item."Base Unit of Measure";
        Item.Insert();
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        ItemUnitOfMeasure."Item No." := ItemNo;
        ItemUnitOfMeasure.Code := LibraryUtility.GenerateRandomCode(ItemUnitOfMeasure.FieldNo(Code), DATABASE::"Item Unit of Measure");
        ItemUnitOfMeasure.Insert();
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; var Item: Record Item)
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := LibraryUtility.GenerateRandomCode(SalesLine.FieldNo("Document No."), DATABASE::"Sales Line");
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine."Shipment Date" := WorkDate();
        SalesLine."Outstanding Qty. (Base)" := Item."Maximum Inventory";
        SalesLine.Insert();
    end;

    local procedure MockPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("No."), DATABASE::"Purchase Header");
        PurchaseHeader.Insert();

        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := LibraryInventory.CreateItemNo();
        PurchaseLine.Insert();
    end;

    local procedure MockPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::"Return Order";
        PurchaseLine."Document No." := LibraryUtility.GenerateRandomCode(PurchaseLine.FieldNo("Document No."), DATABASE::"Purchase Line");
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := ItemNo;
        PurchaseLine."Expected Receipt Date" := WorkDate();
        PurchaseLine."Outstanding Qty. (Base)" := -LibraryRandom.RandDec(100, 2);
        PurchaseLine.Insert();
    end;

    local procedure CreateReqWkshTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; PageID: Integer)
    begin
        ReqWkshTemplate.Name := LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), DATABASE::"Req. Wksh. Template");
        ReqWkshTemplate.Type := ReqWkshTemplate.Type::Planning;
        ReqWkshTemplate."Page ID" := PageID;
        ReqWkshTemplate.Insert();
    end;

    local procedure VerifyReqLines(var Item: Record Item; ReqWkshTempName: Code[10]; SalesLineQuantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Requisition worksheet should contain 2 lines:
        // 1 line has quantity Item."Safety Stock Quantity" + SalesLine."Outstanding Qty. (Base)"
        // 1 line has quantity Item."Maximum Inventory" - Item."Safety Stock Quantity"
        RequisitionLine.SetRange("Worksheet Template Name", ReqWkshTempName);
        RequisitionLine.FindSet();
        repeat
            if not (RequisitionLine.Quantity in [Item."Safety Stock Quantity" + SalesLineQuantity,
                                 Item."Maximum Inventory" - Item."Safety Stock Quantity"])
            then
                Error(
                  WrongQuantityInReqLine, RequisitionLine.Quantity,
                  Item."Safety Stock Quantity" + SalesLineQuantity,
                  Item."Maximum Inventory" - Item."Safety Stock Quantity");
        until RequisitionLine.Next() = 0;
    end;

    local procedure VerifyShowDocumentOnRequisitionLine(RequisitionWorksheetTemplateName: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
        CalcItemAvailability: Codeunit "Calc. Item Availability";
        RecRef: RecordRef;
    begin
        // Will open Planning Worksheet for Requisuition Line.
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWorksheetTemplateName);
        RequisitionLine.FindFirst();
        RecRef.GetTable(RequisitionLine);
        CalcItemAvailability.ShowDocument(RecRef.RecordId);
    end;

    local procedure OpenSalesOrderPlanning(No: Code[20])
    var
        SalesOrderPlanning: Page "Sales Order Planning";
    begin
        // Open Sales Order Planning page for required Sales Order.
        SalesOrderPlanning.SetSalesOrder(No);
        SalesOrderPlanning.RunModal();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningPageHandler(var SalesOrderPlanning: TestPage "Sales Order Planning")
    var
        DequeuedVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeuedVar); // Dequeue Code or Text type variable.
        SalesOrderPlanning."Item No.".AssertEquals(Format(DequeuedVar));
        LibraryVariableStorage.Dequeue(DequeuedVar); // Dequeue Integer or Decimal type variable.
        SalesOrderPlanning.Available.AssertEquals(DequeuedVar);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PlanningWorkheetMPH(var PlanningWorksheet: TestPage "Planning Worksheet")
    begin
        // Just close page
        PlanningWorksheet.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReqWorkheetMPH(var ReqWorksheet: TestPage "Req. Worksheet")
    begin
        // Just close page
        ReqWorksheet.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReqWorksheetTemplateListMPH(var ReqWorksheetTemplateList: TestPage "Req. Worksheet Template List")
    begin
        // Just close page
        ReqWorksheetTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningModalPageHandler(var SalesOrderPlanning: TestPage "Sales Order Planning")
    begin
        LibraryVariableStorage.Enqueue(SalesOrderPlanning."Expected Delivery Date".AsDate());
        SalesOrderPlanning."Update &Shipment Dates".Invoke();
        SalesOrderPlanning.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Option: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 1;
    end;
}

