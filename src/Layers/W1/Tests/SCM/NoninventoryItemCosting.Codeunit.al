codeunit 137120 "Non-inventory Item Costing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item] [Non-Inventory]
        isInitialized := false;
    end;

    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        Assert: Codeunit Assert;
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryService: Codeunit "Library - Service";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssemblyOrderWithNonInventoryItem()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLineNonInventory: Record "Assembly Line";
        Item: Record Item;
        ItemNonInventory: Record Item;
    begin
        Initialize();

        // Use False for Update Unit Cost and blank for Variant Code.
        LibraryAssembly.SetupAssemblyItem(
          Item, Item."Costing Method"::Standard, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', false,
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalcDate('<+14D>', WorkDate()), Item."No.", '', LibraryRandom.RandInt(10), '');

        LibraryInventory.CreateNonInventoryTypeItem(ItemNonInventory);
        ItemNonInventory.Validate("Unit Cost", 15);
        ItemNonInventory.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 10);
        Item.Validate(Inventory, 10000); // Inserts item ledger entry
        Item.Modify(true);
        SequenceNoMgt.ClearState();

        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.",
          LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Item, Item."No.", true),
          1, 1, '');
        AssemblyLine.Validate(Quantity, 1);
        AssemblyLine.Modify();

        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLineNonInventory, "BOM Component Type"::Item, ItemNonInventory."No.",
          LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Item, ItemNonInventory."No.", true),
          1, 1, '');
        AssemblyLineNonInventory.Validate(Quantity, 1);
        AssemblyLineNonInventory.Modify();

        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), 1);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        VerifyEntries(Item, ItemNonInventory, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestProductionOrderWithNonInventoryItem()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionItem: Record Item;
        Item: Record Item;
        ItemNonInventory: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LocationBlue: Record Location;
    begin
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryInventory.CreateItem(ProductionItem);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProductionItem."No.", 2);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 10);
        Item.Validate(Inventory, 10000); // Inserts an Item Ledger Entry.
        Item.Modify(true);
        SequenceNoMgt.ClearState();
        LibraryPatterns.POSTItemJournalLineWithApplication(
          ItemJournalBatch."Template Type"::Item, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item, '', '',
          10, WorkDate(), 0, ItemLedgerEntry."Entry No.");

        ProdOrderComponent.Validate("Item No.", Item."No.");
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Modify(true);

        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        LibraryInventory.CreateNonInventoryTypeItem(ItemNonInventory);
        ItemNonInventory.Validate("Unit Cost", 15);
        ItemNonInventory.Modify(true);
        ProdOrderComponent.Validate("Item No.", ItemNonInventory."No.");
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Modify(true);

        LibraryManufacturing.POSTConsumption(ProdOrderLine, Item, '', '', 1, WorkDate(), Item."Standard Cost");
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ItemNonInventory, '', '', 1, WorkDate(), ItemNonInventory."Unit Cost");

        VerifyEntries(Item, ItemNonInventory, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceOrderWithNonInventoryItem()
    var
        Item: Record Item;
        ItemNonInventory: Record Item;
        ServiceItem: Record "Service Item";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateItemWithAmounts(Item);
        Item.Validate("Service Item Group", CreateServiceItemGroup());
        Item.Modify(true);

        CreateNonInventoryItemWithAmounts(ItemNonInventory);
        ItemNonInventory.Validate("Service Item Group", CreateServiceItemGroup());
        ItemNonInventory.Modify(true);

        LibrarySales.CreateCustomer(Customer);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", 1);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Qty. to Consume", 1);
        ServiceLine.Modify();

        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNonInventory."No.", 1);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Qty. to Consume", 1);
        ServiceLine.Modify();

        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        VerifyEntries(Item, ItemNonInventory, 2);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure NonInventoriableConsumptionCostIsNotIncludedToOutputCost()
    var
        CompItem: Record Item;
        NonInvtCompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Production] [Output]
        // [SCENARIO 334684] Cost of output includes only cost of inventoriable components consumption.
        Initialize();

        // [GIVEN] Item "I" of type "Inventory".
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItem."No.", '', '', 1);
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Item "NI" of type "Non-Inventory".
        CreateNonInventoryItemWithAmounts(NonInvtCompItem);

        // [GIVEN] Production item "P" with two components - "I" and "NI".
        LibraryInventory.CreateItem(ProdItem);
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, CompItem."No.", NonInvtCompItem."No.", 1);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Create and refresh production order for "P".
        // [GIVEN] Post output and consumption.
        // [GIVEN] Finish the production order.
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", 1);
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries('', '');

        // [THEN] Overall actual cost amount of the finished production order = 0.
        // [THEN] Consumption of "I" is posted as actual cost, consumption of "NI" is posted as non-inventoriable cost.
        ValueEntry.SetRange("Document No.", ProductionOrder."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", 0);
    end;

    [Test]
    [HandlerFunctions('AssemblyOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintAssemblyOrder()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        Resource: Record Resource;
    begin
        // [SCENARIO 459646] Too many decimals printed on Assembly order (Quantity per) report 902
        // [GIVEN] Create Item with Resource Asm. BOM.
        Initialize();

        CreateAssemblyItemAndResourceWithBOM(Item, Resource);

        // [GIVEN] Create Assembly Order
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, LibraryRandom.RandDateFromInRange(WorkDate(), 1, 10), Item."No.", '', LibraryRandom.RandInt(10), '');
        Commit();

        // [WHEN] Run Assembly Order report
        REPORT.Run(REPORT::"Assembly Order", true, false, AssemblyHeader);

        // [VERIFY] Verify Assembly Order Line Data
        LibraryReportDataset.LoadDataSetFile();
        VerifyComponentsReportAOLines(AssemblyHeader);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Non-inventory Item Costing");
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Non-inventory Item Costing");

        UpdateStockOutWarningOnAssemblySetup(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        Setup();
        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalTemplate.Type := ItemJournalTemplate.Type::Consumption;
        ItemJournalTemplate.Recurring := false;
        ItemJournalTemplate.Modify();

        LibraryService.SetupServiceMgtNoSeries();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Non-inventory Item Costing");
    end;

    local procedure UpdateStockOutWarningOnAssemblySetup(NewStockOutWarning: Boolean)
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Stockout Warning", NewStockOutWarning);
        AssemblySetup.Modify(true);
    end;

    local procedure Setup()
    var
        AssemblySetup: Record "Assembly Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Posted Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Released Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ManufacturingSetup.Validate("Normal Starting Time", 080000T);
        ManufacturingSetup.Validate("Normal Ending Time", 160000T);
        ManufacturingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateItemWithAmounts(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 10);
        Item.Validate(Inventory, 10000); // Inserts Item Ledger Entry
        Item.Modify(true);
        SequenceNoMgt.ClearState();
    end;

    [Scope('OnPrem')]
    procedure CreateNonInventoryItemWithAmounts(var ItemNonInventory: Record Item)
    begin
        LibraryInventory.CreateNonInventoryTypeItem(ItemNonInventory);
        ItemNonInventory.Validate("Unit Cost", 15);
        ItemNonInventory.Modify(true);
    end;

    local procedure CreateServiceItemGroup() ServiceItemGroupCode: Code[10]
    var
        ServiceItemGroup: Record "Service Item Group";
        ServiceItemGroups: TestPage "Service Item Groups";
    begin
        ServiceItemGroups.OpenEdit();
        ServiceItemGroups.New();
        ServiceItemGroupCode :=
          LibraryUtility.GenerateRandomCodeWithLength(
            ServiceItemGroup.FieldNo(Code), DATABASE::"Service Item Group", MaxStrLen(ServiceItemGroup.Code));
        ServiceItemGroups.Code.SetValue(ServiceItemGroupCode);
        ServiceItemGroups."Default Response Time (Hours)".SetValue(LibraryRandom.RandInt(10));
        ServiceItemGroups."Create Service Item".SetValue(true);
        ServiceItemGroups.OK().Invoke();
        Commit();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure VerifyEntries(Item: Record Item; ItemNonInventory: Record Item; Type: Option Assembly,Production,Service)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        case Type of
            Type::Assembly:
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Assembly Consumption");
            Type::Production:
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
            Type::Service:
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        end;
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreEqual(-Item."Standard Cost", ItemLedgerEntry."Cost Amount (Actual)", '');

        ItemLedgerEntry.SetRange("Item No.", ItemNonInventory."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Non-Invtbl.)");
        Assert.AreEqual(-ItemNonInventory."Unit Cost", ItemLedgerEntry."Cost Amount (Non-Invtbl.)", '');

        ValueEntry.SetRange("Item No.", Item."No.");
        case Type of
            Type::Assembly:
                ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntry."Entry Type"::"Assembly Consumption");
            Type::Production:
                ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
            Type::Service:
                ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        end;
        ValueEntry.FindFirst();
        Assert.AreEqual(-Item."Standard Cost", ValueEntry."Cost Amount (Actual)", '');

        ValueEntry.SetRange("Item No.", ItemNonInventory."No.");
        ValueEntry.FindFirst();
        Assert.AreEqual(-ItemNonInventory."Unit Cost", ItemLedgerEntry."Cost Amount (Non-Invtbl.)", '');
    end;

    local procedure CreateAssemblyItemAndResourceWithBOM(var Item: Record Item; var Resource: Record Resource) QuantityPer: Decimal
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::Assembly, Item."Reordering Policy"::Order,
          Item."Manufacturing Policy", '');

        // Create Resource
        LibraryAssembly.CreateResource(Resource, false, Item."Gen. Prod. Posting Group");
        QuantityPer := LibraryRandom.RandDec(1, 4);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Resource, Resource."No.", Item."No.", '', BOMComponent."Resource Usage Type"::Direct,
          QuantityPer, true);  // Use Base Unit of Measure as True and Variant as blank.
        exit(QuantityPer);
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

    local procedure VerifyComponentsReportAOLines(var AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item, AssemblyLine.Type::Resource);
        AssemblyLine.FindSet();

        repeat
            LibraryReportDataset.SetRange('No_AssemblyLine', AssemblyLine."No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('Description_AssemblyLine', AssemblyLine.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals('QuantityPer_AssemblyLine', AssemblyLine."Quantity per");
            LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_AssemblyLine', AssemblyLine.Quantity);
            LibraryReportDataset.AssertCurrentRowValueEquals('UnitOfMeasureCode_AssemblyLine', AssemblyLine."Unit of Measure Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_AssemblyLine', AssemblyLine."Location Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_AssemblyLine', AssemblyLine."Bin Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('VariantCode_AssemblyLine', AssemblyLine."Variant Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('QuantityToConsume_AssemblyLine', AssemblyLine."Quantity to Consume");
            LibraryReportDataset.AssertCurrentRowValueEquals('DueDate_AssemblyLine', Format(AssemblyLine."Due Date"));
        until AssemblyLine.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyOrderRequestPageHandler(var AssemblyOrder: TestRequestPage "Assembly Order")
    begin
        AssemblyOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    procedure ProductionJournalModalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
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

