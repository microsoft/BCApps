codeunit 137124 "Cost Adjust Action Msg. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item] [Cost Adjustment] [Action Message]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [Scope('OnPrem')]
    procedure SignalLoggingDisabledThroughSetting()
    var
        InventorySetup: Record "Inventory Setup";
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
    begin
        // [SCENARIO] CheckCostingEnabled adds a signal if no signal exists
        Initialize();

        // [GIVEN] Inventory Setup is not set to require automatic cost adjustment
        InventorySetup.GetRecordOnce();
        InventorySetup."Disable Cost Adjmt. Signals" := true;
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Never;
        InventorySetup.Modify();

        // [WHEN] A sales order is created and posted
        CreateSalesOrderAndPost();

        // [THEN] Verify that the Signal is logged and has expected values
        CostAdjmtActionMessage.SetRange(Type, CostAdjmtActionMessage.Type::"Cost Adjustment Not Running");
        Assert.RecordIsEmpty(CostAdjmtActionMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCostingEnabledLogsSignalIfNoSignalExists()
    var
        InventorySetup: Record "Inventory Setup";
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
    begin
        // [SCENARIO] CheckCostingEnabled adds a signal if no signal exists
        Initialize();

        // [GIVEN] Inventory Setup is not set to require automatic cost adjustment
        InventorySetup.GetRecordOnce();
        if InventorySetup.AutomaticCostAdjmtRequired() then begin
            InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Never;
            InventorySetup.Modify();
        end;

        // [WHEN] A sales order is created and posted
        CreateSalesOrderAndPost();

        // [THEN] Verify that the Signal is logged and has expected values
        CostAdjmtActionMessage.SetRange(Type, CostAdjmtActionMessage.Type::"Cost Adjustment Not Running");
        Assert.RecordCount(CostAdjmtActionMessage, 1);

        CostAdjmtActionMessage.FindFirst();
        CostAdjmtActionMessage.TestField("Type", CostAdjmtActionMessage.Type::"Cost Adjustment Not Running");
        CostAdjmtActionMessage.TestField(Active, true);

        // [WHEN] A sales order is created and posted
        CreateSalesOrderAndPost();

        // [THEN] Verify that the Signal is not logged again
        Assert.RecordCount(CostAdjmtActionMessage, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCostingEnabledLogsInactiveSignalCostingIsEnabled()
    var
        InventorySetup: Record "Inventory Setup";
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
    begin
        // [SCENARIO] CheckCostingEnabled adds a signal with active = false if CheckCostingEnabled returns true
        Initialize();

        // [GIVEN] Inventory Setup is not set to require automatic cost adjustment
        InventorySetup.GetRecordOnce();
        if not InventorySetup.AutomaticCostAdjmtRequired() then begin
            InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Month;
            InventorySetup.Modify();
        end;

        // [WHEN] A sales order is created and posted
        CreateSalesOrderAndPost();

        // [THEN] Verify that the Signal is logged and has expected values
        CostAdjmtActionMessage.SetRange(Type, CostAdjmtActionMessage.Type::"Cost Adjustment Not Running");
        Assert.RecordCount(CostAdjmtActionMessage, 1);

        CostAdjmtActionMessage.FindFirst();
        CostAdjmtActionMessage.TestField("Type", CostAdjmtActionMessage.Type::"Cost Adjustment Not Running");
        CostAdjmtActionMessage.TestField(Active, false);
    end;

    [Test]
    procedure ItemsExcludedfromCostAdjustmentLoggedAfterCostAdjustment()
    var
        Item: Record Item;
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
    begin
        // [SCENARIO] Cost adjust logs items excluded from cost adjustment
        Initialize();

        // [GIVEN] Enable automatic cost posting
        EnableAutomaticCostPosting();

        // [GIVEN] Create an item, mark 'Cost is Adjusted' as false and 'Excluded from Cost Adjustment' as true
        CreateItem(Item);
        Item."Excluded from Cost Adjustment" := true;
        Item."Cost is Adjusted" := false;
        Item.Modify(true);

        // [WHEN] Create a sales order and post
        CreateSalesOrderAndPost();

        // [THEN] Verify that the item is excluded from cost adjustment signal is logged
        CostAdjmtActionMessage.SetRange(Type, CostAdjmtActionMessage.Type::"Item Excluded from Cost Adjustment");
        Assert.RecordCount(CostAdjmtActionMessage, 1);
    end;

    [Test]
    [HandlerFunctions('AdjustCostItemEntriesRequestPageHandler')]
    procedure SuboptimalAvgCostSettingsLoggedAfterCostAdjustmentIfMoreUnadjustedAvgCostEntryPtsExist()
    var
        Item: Record Item;
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
    begin
        // [SCENARIO] Cost adjust logs suboptimal average cost settings
        Initialize();

        // [GIVEN] Enable automatic cost posting
        DisableAutomaticCostPosting();

        // [GIVEN] Create an item and create "many" unadjusted average cost adjmt entry points
        CreateItem(Item);

        CreateAvgCostAdjmtEntryPoint(30, Item."No.", false);

        // [WHEN] "Adjust Cost - Item Entries" report is run
        Commit();
        Report.Run(Report::"Adjust Cost - Item Entries");

        // [THEN] Verify that "Suboptimal Avg. Cost Settings" signal is logged
        CostAdjmtActionMessage.SetRange(Type, CostAdjmtActionMessage.Type::"Suboptimal Avg. Cost Settings");
        Assert.RecordCount(CostAdjmtActionMessage, 1);
    end;

    [Test]
    procedure DataDiscrepancyLoggedAfterCostAdjustmentIfThereAreResidualCosts()
    var
        Item: Record Item;
        ValueEntry: Record "Value Entry";
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
        CostAdjmtSignals: Codeunit "Cost Adjmt. Signals";
    begin
        // [SCENARIO] Run all tests logs data discrepancy signal
        Initialize();

        // [GIVEN] Enable automatic cost posting
        DisableAutomaticCostPosting();

        // [GIVEN] Create an item and create value entries where there is residual cost
        CreateItem(Item);
        ValueEntry.Init();
        ValueEntry."Item No." := Item."No.";
        ValueEntry."Cost Amount (Actual)" := 1;
        ValueEntry.Insert();

        // [WHEN] Run all checks
        CostAdjmtSignals.RunAllTests();

        // [THEN] Verify that "Data Discrepancy" signal is logged
        CostAdjmtActionMessage.SetRange(Type, CostAdjmtActionMessage.Type::"Data Discrepancy");
        Assert.RecordCount(CostAdjmtActionMessage, 1);
    end;

    local procedure Initialize()
    var
        CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Cost Adjust Action Msg. Tests");

        // Enable cost adjustment signal logging
        InventorySetup.GetRecordOnce();
        InventorySetup."Disable Cost Adjmt. Signals" := false;
        InventorySetup.Modify();

        // Delete all signals
        CostAdjmtActionMessage.DeleteAll();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Cost Adjust Action Msg. Tests");
    end;

    local procedure CreateAvgCostAdjmtEntryPoint(NoOfEntries: Integer; ItemNo: Code[20]; CostIsAdjusted: Boolean)
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        Index: Integer;
        ValuationDate: Date;
    begin
        ValuationDate := WorkDate() - NoOfEntries;
        for Index := 1 to NoOfEntries do begin
            AvgCostAdjmtEntryPoint.Init();
            AvgCostAdjmtEntryPoint."Item No." := ItemNo;
            AvgCostAdjmtEntryPoint."Valuation Date" := ValuationDate;
            AvgCostAdjmtEntryPoint."Cost Is Adjusted" := CostIsAdjusted;
            AvgCostAdjmtEntryPoint.Insert();
            ValuationDate := ValuationDate + 1;
        end;
    end;

    local procedure EnableAutomaticCostPosting()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.GetRecordOnce();
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Always;
        InventorySetup.Modify();
    end;

    local procedure DisableAutomaticCostPosting()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.GetRecordOnce();
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Never;
        InventorySetup.Modify();
    end;

    local procedure CreateSalesOrderAndPost(): Code[20]
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateCustomer(Customer, false, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateItem(Item);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2)); // Use Random Quantity.
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));  // Post Shipment.
    end;

    local procedure CreateCustomer(var Customer: Record Customer; CombineShipments: Boolean; CustomerPriceGroupCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Combine Shipments", CombineShipments);
        Customer.Validate("Customer Price Group", CustomerPriceGroupCode);
        Customer.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use random Unit Price.
        Item.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal): Code[20]
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2)); // Use random Unit Price.
        SalesLine.Modify(true);
        exit(SalesLine."No.");
    end;

    [RequestPageHandler]
    procedure AdjustCostItemEntriesRequestPageHandler(var RequestPage: TestRequestPage "Adjust Cost - Item Entries")
    begin
        RequestPage.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

