codeunit 137011 "SCM Revaluation-II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Revaluation] [SCM]
        isInitialized := false;
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        RevaluationItemJournalTemplate: Record "Item Journal Template";
        RevaluationItemJournalBatch: Record "Item Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        ErrMessageQtyMustBeEqual: Label 'Item Quantity Must Be Equal.';
        CostMustBeEqualErr: Label 'Costs must be Equal.';
        ProductionOrderNo: Code[20];
        ErrMsgCostAmount: Label 'The amounts must be equal.';
        RevaluationPerEntryNotAllowedErr: Label 'This item has already been revalued with the Calculate Inventory Value function, so you cannot use the Applies-to Entry field as that may change the valuation.';
        AutomaticCostAdjustment: Option Never,Day,Week,Month,Quarter,Year,Always;
        AverageCostPeriod: Enum "Average Cost Period Type";

    [Test]
    [Scope('OnPrem')]
    procedure StdPurchRevalSales()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        InventoryPostingGroup: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        Qty: Decimal;
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
        InitialInventory: Decimal;
    begin
        // Covers TFS_TC_ID = 6202
        // Setup: Update Inventory Setup, Create Item and Purchase Order and Post Purchase Order.
        Initialize();

        UpdateInventorySetup(true, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        LocationCode := CreateLocationCode(InventoryPostingGroup);
        ItemNo := CreateItem("Costing Method"::Standard, InventoryPostingGroup);
        UpdateItemInventory(ItemNo, LocationCode);
        Qty := LibraryRandom.RandInt(10) + 50;
        CreatePurchaseOrder(PurchaseHeader, ItemNo, '', Qty, LocationCode, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo);
        CalcInventoryValue(Item, ItemJournalLine);
        Item.CalcFields(Inventory);
        InitialInventory := Item.Inventory;

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line, Create and Post Sales Order, Run Adjust Cost Item Entries.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateSalesOrder(SalesHeader, Item."No.", Qty, LocationCode, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify: Verify Value Entries.
        VerifyValueEntry(Qty, Item."No.", OldUnitCost, NewUnitCost, OldUnitCost - NewUnitCost, InitialInventory, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdPurchSalesLessInvoiceReval()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        InventoryPostingGroup: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        Qty: Decimal;
        InvQty: Decimal;
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
        InitialInventory: Decimal;
    begin
        // Covers TFS_TC_ID = 6175
        // Setup: Update Inventory Setup, Create Item and Purchase Order and Post Purchase Order as Receive.
        // Create and Post Sales Order, Reopen Purchase Order and Post Purchase Order with Less Qty to Invoice.
        Initialize();

        UpdateInventorySetup(true, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        LocationCode := CreateLocationCode(InventoryPostingGroup);
        ItemNo := CreateItem("Costing Method"::Standard, InventoryPostingGroup);
        UpdateItemInventory(ItemNo, LocationCode);
        Qty := LibraryRandom.RandInt(10) + 50;
        CreatePurchaseOrder(PurchaseHeader, ItemNo, '', Qty, LocationCode, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        InitialInventory := Item.Inventory;
        CreateSalesOrder(SalesHeader, ItemNo, Qty, LocationCode, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        InvQty := Qty - 10;
        PurchaseOrderInvoiceLessQty(PurchaseHeader."No.", InvQty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line, Run Adjust Cost Item Entries.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify: Verify Value Entries.
        VerifyValueEntryLessInvoice(Item."No.", OldUnitCost, OldUnitCost - NewUnitCost, InitialInventory, Qty, InvQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdPurchTwiceRevalTwice()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        InventoryPostingGroup: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        Qty: Decimal;
        InvQty: Decimal;
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
        OldUnitCost2: Decimal;
        NewUnitCost2: Decimal;
    begin
        // Covers TFS_TC_ID = 6169,6173
        // Setup: Update Inventory Setup, Create Item and Purchase Order and Post Purchase Order as Receive.
        Initialize();

        UpdateInventorySetup(true, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        LocationCode := CreateLocationCode(InventoryPostingGroup);
        ItemNo := CreateItem("Costing Method"::Standard, InventoryPostingGroup);
        Qty := LibraryRandom.RandInt(10) + 50;
        CreatePurchaseOrder(PurchaseHeader, ItemNo, '', Qty, LocationCode, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line.
        // Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreatePurchaseOrder(PurchaseHeader2, ItemNo, '', LibraryRandom.RandInt(10), LocationCode, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, false);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        InvQty := Qty - 10;
        PurchaseOrderInvoiceLessQty(PurchaseHeader."No.", InvQty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line.
        OldUnitCost2 := Item."Standard Cost";
        NewUnitCost2 :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify: Verify Value Entries. check that without Sales Order.
        VerifyValueEntryRevalNoSales(Item."No.", OldUnitCost, NewUnitCost - OldUnitCost, NewUnitCost2 - OldUnitCost2, Qty, InvQty);
    end;

    [Test]
    procedure StdPurchTwiceRevalTwiceNegativeEntryNo()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        InventoryPostingGroup: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        Qty: Decimal;
        InvQty: Decimal;
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
        OldUnitCost2: Decimal;
        NewUnitCost2: Decimal;
    begin
        // Same test as StdPurchTwiceRevalTwice, but one set of item ledger entries have negative entry nos (from a committted preview)
        // Setup: Update Inventory Setup, Create Item and Purchase Order and Post Purchase Order as Receive.
        Initialize();

        UpdateInventorySetup(true, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        LocationCode := CreateLocationCode(InventoryPostingGroup);
        ItemNo := CreateItem("Costing Method"::Standard, InventoryPostingGroup);
        Qty := LibraryRandom.RandInt(10) + 50;
        CreatePurchaseOrder(PurchaseHeader, ItemNo, '', Qty, LocationCode, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line.
        // Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreatePurchaseOrder(PurchaseHeader2, ItemNo, '', LibraryRandom.RandInt(10), LocationCode, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, false);

        NegateEntryNoOnLastItemRegister();

        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        InvQty := Qty - 10;
        PurchaseOrderInvoiceLessQty(PurchaseHeader."No.", InvQty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line.
        OldUnitCost2 := Item."Standard Cost";
        NewUnitCost2 :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify: Verify Value Entries. check that without Sales Order.
        VerifyValueEntryRevalNoSales(Item."No.", OldUnitCost, NewUnitCost - OldUnitCost, NewUnitCost2 - OldUnitCost2, Qty, InvQty);
    end;

    local procedure NegateEntryNoOnLastItemRegister()
    var
        ItemRegister: Record "Item Register";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ValueEntry2: Record "Value Entry";
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemRegister.FindLast();
        ItemLedgerEntry.SetRange("Entry No.", ItemRegister."From Entry No.", ItemRegister."To Entry No.");
        if ItemLedgerEntry.FindSet(true) then
            repeat
                ItemLedgerEntry2 := ItemLedgerEntry;
                ItemLedgerEntry2."Entry No." -= 2000000000;
                ItemLedgerEntry2."Item Register No." -= 2000000000;
                if ItemLedgerEntry2."Applies-to Entry" > 0 then
                    ItemLedgerEntry2."Applies-to Entry" -= 2000000000;
                ItemLedgerEntry.Delete();
                ItemLedgerEntry2.Insert();
                ItemApplicationEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
                ItemApplicationEntry.ModifyAll("Item Ledger Entry No.", ItemLedgerEntry2."Entry No.");
                ItemApplicationEntry.SetRange("Item Ledger Entry No.");
                ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Entry No.");
                ItemApplicationEntry.ModifyAll("Inbound Item Entry No.", ItemLedgerEntry2."Entry No.");
                ItemApplicationEntry.SetRange("Inbound Item Entry No.");
                ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgerEntry."Entry No.");
                ItemApplicationEntry.ModifyAll("Outbound Item Entry No.", ItemLedgerEntry2."Entry No.");
                ItemApplicationEntry.SetRange("Outbound Item Entry No.");
                ItemApplicationEntry.SetRange("Transferred-from Entry No.", ItemLedgerEntry."Entry No.");
                ItemApplicationEntry.ModifyAll("Transferred-from Entry No.", ItemLedgerEntry2."Entry No.");
                ItemApplicationEntry.SetRange("Transferred-from Entry No.");
            until ItemLedgerEntry.Next() = 0;

        ValueEntry.SetRange("Entry No.", ItemRegister."From Value Entry No.", ItemRegister."To Value Entry No.");
        if ValueEntry.FindSet(true) then
            repeat
                ValueEntry2 := ValueEntry;
                ValueEntry2."Entry No." -= 2000000000;
                ValueEntry2."Item Ledger Entry No." -= 2000000000;
                ValueEntry2."Item Register No." -= 2000000000;
                if ValueEntry2."Applies-to Entry" > 0 then
                    ValueEntry2."Applies-to Entry" -= 2000000000;
                ValueEntry.Delete();
                ValueEntry2.Insert();
            until ValueEntry.Next() = 0;

        ItemRegister.Delete();
        ItemRegister."No." -= 2000000000;
        ItemRegister."From Entry No." -= 2000000000;
        ItemRegister."To Entry No." -= 2000000000;
        ItemRegister."From Value Entry No." -= 2000000000;
        ItemRegister."To Value Entry No." -= 2000000000;
        ItemRegister.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdPurchRevalTwiceSales()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        InventoryPostingGroup: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        Qty: Decimal;
        InvQty: Decimal;
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
        OldUnitCost2: Decimal;
        NewUnitCost2: Decimal;
    begin
        // Covers TFS_TC_ID = 6170,6171,6178
        // Setup: Update Inventory Setup, Create Item and Purchase Order and Post Purchase Order as Receive.
        Initialize();

        UpdateInventorySetup(true, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        LocationCode := CreateLocationCode(InventoryPostingGroup);
        ItemNo := CreateItem("Costing Method"::Standard, InventoryPostingGroup);
        Qty := LibraryRandom.RandInt(10) + 50;
        CreatePurchaseOrder(PurchaseHeader, ItemNo, '', Qty, LocationCode, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        InvQty := Qty - 10;
        PurchaseOrderInvoiceLessQty(PurchaseHeader."No.", Qty - 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line.
        OldUnitCost2 := Item."Standard Cost";
        NewUnitCost2 :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateSalesOrder(SalesHeader, Item."No.", Qty, LocationCode, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify: Verify Value Entries after twice revaluation.
        VerifyValueEntryRevalTwice(Item."No.", OldUnitCost, NewUnitCost - OldUnitCost, NewUnitCost2 - OldUnitCost2, NewUnitCost2, Qty, InvQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgPurchRevalSales()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        InventoryPostingGroup: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        Qty: Decimal;
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
    begin
        // Covers TFS_TC_ID = 4009
        // Setup: Update Inventory Setup, Create Item and Purchase Order and Post Purchase Order.
        Initialize();

        UpdateInventorySetup(true, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);
        LibraryInventory.SetAverageCostSetupInAccPeriods("Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        LocationCode := CreateLocationCode(InventoryPostingGroup);
        ItemNo := CreateItem("Costing Method"::Average, InventoryPostingGroup);
        Qty := LibraryRandom.RandInt(10) + 50;
        CreatePurchaseOrder(PurchaseHeader, ItemNo, '', Qty, LocationCode, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        TransferQtyDiffLocation(ItemNo, LocationCode);

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line.
        OldUnitCost := Item."Unit Cost";
        NewUnitCost :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateSalesOrder(SalesHeader, Item."No.", Qty, LocationCode, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify: Verify Value Entries, GL entries for multiple locations.
        VerifyValueEntry(Qty, Item."No.", OldUnitCost, NewUnitCost, OldUnitCost - NewUnitCost, 0, false, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CalculateStdCostMenuHandler,ProdJournalPageHandler')]
    [Scope('OnPrem')]
    procedure StdPurchRevalProduction()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        LocationCode: Code[10];
        InventoryPostingGroup: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ProductionItemNo: Code[20];
        RoutingNo: Code[10];
        Qty: Decimal;
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
        OldUnitCost2: Decimal;
        NewUnitCost2: Decimal;
        OldUnitCost3: Decimal;
        NewUnitCost3: Decimal;
    begin
        // Covers TFS_TC_ID = 6209,4006
        // Setup: Update Manufacturing Setup and Inventory Setup.
        Initialize();

        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        UpdateInventorySetup(true, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        // Create Work Center and Machine Center with required Flushing method and Create Routing.
        CreateRoutingSetup(RoutingNo);

        // Create child Items with the required Costing method and the parent Item with Routing No. and Production BOM No.
        LocationCode := CreateLocationCode(InventoryPostingGroup);
        ItemNo := CreateItem(Item."Costing Method"::Standard, InventoryPostingGroup);
        ItemNo2 := CreateItem(Item."Costing Method"::Standard, InventoryPostingGroup);
        CreateProdItemWithBOM(Item, Item."Costing Method"::Standard, ItemNo, ItemNo2, InventoryPostingGroup, RoutingNo);
        ProductionItemNo := Item."No.";
        Clear(Item);

        // Calculate Standard Cost for the parent Item.
        CalculateStandardCost.CalcItem(ProductionItemNo, false);
        Qty := LibraryRandom.RandInt(10) + 50;
        CreatePurchaseOrder(PurchaseHeader, ItemNo, ItemNo2, Qty, LocationCode, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value for component Item 1.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory for component Item 1.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line for component Item 1.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Item Cost with revalued cost for component Item 1.
        VerifyItemCost(ItemNo, NewUnitCost);

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value for component Item 2.
        LibraryCosting.AdjustCostItemEntries(ItemNo2, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo2);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory for component Item 2.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line for component Item 2.
        OldUnitCost2 := Item."Standard Cost";
        NewUnitCost2 :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost2);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Item Cost with revalued cost for component Item 2.
        VerifyItemCost(ItemNo2, NewUnitCost2);

        // Create and Refresh Production Order and Post Production Journal.
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionItemNo, LibraryRandom.RandInt(9) + 1, LocationCode);
        ProductionOrderNo := ProductionOrder."No.";
        PostProductionJournal(ProductionOrder);

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value for Finished Item.
        LibraryCosting.AdjustCostItemEntries(ProductionItemNo, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ProductionItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory for Finished Item.
        VerifyRevaluedInventory(Item);

        // Exercise: Post Revaluation Journal for Finished Item.
        OldUnitCost3 := Item."Standard Cost";
        NewUnitCost3 :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost3);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Item Cost with revalued cost for Finished Item.
        VerifyItemCost(ProductionItemNo, NewUnitCost3);

        // Exercise: Finish Production Order and Run Adjust Cost Item Entries.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        LibraryCosting.AdjustCostItemEntries('', '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Verify Value Entries.
        VerifyValueEntryComponentItem(Qty, ItemNo, OldUnitCost, NewUnitCost, OldUnitCost - NewUnitCost);
        VerifyValueEntryComponentItem(Qty, ItemNo2, OldUnitCost2, NewUnitCost2, OldUnitCost2 - NewUnitCost2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CalculateStdCostMenuHandler,ProdJournalPageHandler')]
    procedure StdPurchRevalProductionNegativeEntryNo()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        LocationCode: Code[10];
        InventoryPostingGroup: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ProductionItemNo: Code[20];
        RoutingNo: Code[10];
        Qty: Decimal;
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
        OldUnitCost2: Decimal;
        NewUnitCost2: Decimal;
        OldUnitCost3: Decimal;
        NewUnitCost3: Decimal;
    begin
        // Covers TFS_TC_ID = 6209,4006
        // Setup: Update Manufacturing Setup and Inventory Setup.
        Initialize();

        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        UpdateInventorySetup(true, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        // Create Work Center and Machine Center with required Flushing method and Create Routing.
        CreateRoutingSetup(RoutingNo);

        // Create child Items with the required Costing method and the parent Item with Routing No. and Production BOM No.
        LocationCode := CreateLocationCode(InventoryPostingGroup);
        ItemNo := CreateItem(Item."Costing Method"::Standard, InventoryPostingGroup);
        ItemNo2 := CreateItem(Item."Costing Method"::Standard, InventoryPostingGroup);
        CreateProdItemWithBOM(Item, Item."Costing Method"::Standard, ItemNo, ItemNo2, InventoryPostingGroup, RoutingNo);
        ProductionItemNo := Item."No.";
        Clear(Item);

        // Calculate Standard Cost for the parent Item.
        CalculateStandardCost.CalcItem(ProductionItemNo, false);
        Qty := LibraryRandom.RandInt(10) + 50;
        CreatePurchaseOrder(PurchaseHeader, ItemNo, ItemNo2, Qty, LocationCode, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value for component Item 1.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory for component Item 1.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line for component Item 1.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Item Cost with revalued cost for component Item 1.
        VerifyItemCost(ItemNo, NewUnitCost);

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value for component Item 2.
        LibraryCosting.AdjustCostItemEntries(ItemNo2, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ItemNo2);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory for component Item 2.
        VerifyRevaluedInventory(Item);

        // Exercise: Update Revalued Unit Cost and Post Item Journal Line for component Item 2.
        OldUnitCost2 := Item."Standard Cost";
        NewUnitCost2 :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost2);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Item Cost with revalued cost for component Item 2.
        VerifyItemCost(ItemNo2, NewUnitCost2);

        // Create and Refresh Production Order and Post Production Journal.
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionItemNo, LibraryRandom.RandInt(9) + 1, LocationCode);
        ProductionOrderNo := ProductionOrder."No.";
        PostProductionJournal(ProductionOrder);

        NegateEntryNoOnLastItemRegister();

        // Exercise: Run Adjust Cost Item Entries, Create Revaluation Journal, Calculate Inventory Value for Finished Item.
        LibraryCosting.AdjustCostItemEntries(ProductionItemNo, '');
        CreateRevaluationJournal(ItemJournalLine);
        Item.Get(ProductionItemNo);
        CalcInventoryValue(Item, ItemJournalLine);

        // Verify: Verify that Revalued Inventory is equal to Calculated Inventory for Finished Item.
        VerifyRevaluedInventory(Item);

        // Exercise: Post Revaluation Journal for Finished Item.
        OldUnitCost3 := Item."Standard Cost";
        NewUnitCost3 :=
          UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost3);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Item Cost with revalued cost for Finished Item.
        VerifyItemCost(ProductionItemNo, NewUnitCost3);

        // Exercise: Finish Production Order and Run Adjust Cost Item Entries.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        LibraryCosting.AdjustCostItemEntries('', '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Verify Value Entries.
        VerifyValueEntryComponentItem(Qty, ItemNo, OldUnitCost, NewUnitCost, OldUnitCost - NewUnitCost);
        VerifyValueEntryComponentItem(Qty, ItemNo2, OldUnitCost2, NewUnitCost2, OldUnitCost2 - NewUnitCost2);
    end;

    [Test]
    [HandlerFunctions('ProdJournalPageHandler')]
    [Scope('OnPrem')]
    procedure FIFORevalProduction()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InventoryPostingGroup: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        NegLedgerEntryDocNo: Code[20];
        Quantity: Integer;
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
        ExpectedCostAmount: Decimal;
    begin
        // Setup: Update Inventory Setup.
        Initialize();

        UpdateInventorySetup(false, false, AutomaticCostAdjustment::Always, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        // Create child Items with required Costing method and Inventory,Create Production BOM.
        CreateLocationCode(InventoryPostingGroup);
        ItemNo := CreateItem(Item."Costing Method"::FIFO, InventoryPostingGroup);
        ItemNo2 := CreateItem(Item."Costing Method"::FIFO, InventoryPostingGroup);
        UpdateItemInventory(ItemNo, '');
        UpdateItemInventory(ItemNo2, '');
        CreateProdItemWithBOM(Item, Item."Costing Method"::FIFO, ItemNo, ItemNo2, InventoryPostingGroup, '');

        // Create Production Order, Refresh and Post Production Journal.
        Quantity := LibraryRandom.RandInt(2);  // Required at multiple places.
        CreateAndRefreshRelProdOrder(ProductionOrder, Item."No.", Quantity, '');
        ProductionOrderNo := ProductionOrder."No.";
        PostProductionJournal(ProductionOrder);

        // Create Output with negative qty, apply to existing item ledger entry for production item, post to make the Output Nil.
        SelectItemLedgerEntry(ItemLedgerEntry, Item."No.");
        CreateOutputJournal(ItemJournalLine, Item."No.", ProductionOrderNo, -Quantity);
        UpdateAppliesToEntry(ItemJournalLine, ItemLedgerEntry."Entry No.");
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        NegLedgerEntryDocNo := ItemJournalLine."Document No.";

        // Post Output again with positive quantity, finish the Released Production Order and Adjust Cost.
        CreateOutputJournal(ItemJournalLine, Item."No.", ProductionOrderNo, Quantity);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // Exercise: Finish Production Order and run Adjust Cost.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // Verify: Verify Cost Amount (Actual) for both positive and negative entries in Item Ledger Entry.
        Item.Get(Item."No.");
        OldUnitCost := Item."Unit Cost";
        ExpectedCostAmount := OldUnitCost * Quantity;
        VerifyItemLedgerEntryCostAmt(ItemLedgerEntry."Document No.", ExpectedCostAmount);
        VerifyItemLedgerEntryCostAmt(NegLedgerEntryDocNo, -ExpectedCostAmount);

        // Create Revaluation Journal and apply to first ILE of production Item.
        CreateRevaluationJournal(ItemJournalLine);
        UpdateRevalAppliesToEntry(ItemJournalLine, Item."No.", ItemLedgerEntry."Entry No.");

        // Exercise: Post Revalaution Journal with new Unit Cost for production item.
        NewUnitCost :=
          UpdateRevaluedUnitCost(
            RevaluationItemJournalBatch."Journal Template Name", RevaluationItemJournalBatch.Name, Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Cost Amount (Actual) for both positive and negative entries in Item Ledger Entry.
        ExpectedCostAmount := NewUnitCost * Quantity;
        VerifyItemLedgerEntryCostAmt(ItemLedgerEntry."Document No.", ExpectedCostAmount);
        VerifyItemLedgerEntryCostAmt(NegLedgerEntryDocNo, -ExpectedCostAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PerEntryRevaluationCanBePostedIfNoPartialRevaluation()
    var
        Item: Record Item;
        NewUnitCost: Decimal;
    begin
        Initialize();

        UpdateInventorySetup(false, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        CreateItemWithInventoryValue(Item);
        NewUnitCost := PostItemLedgerEntryRevaluation(Item);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        Item.Find('=');
        Assert.AreEqual(NewUnitCost, Item."Unit Cost", CostMustBeEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PerEntryRevaluationCannotBePostedAfterPartialRevaluation()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        Initialize();

        UpdateInventorySetup(false, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        CreateItemWithInventoryValue(Item);
        PostItemRevaluation(Item, WorkDate());

        CreateRevaluationJournal(ItemJournalLine);
        SelectPurchItemLedgEntry(ItemLedgerEntry, Item."No.");
        asserterror UpdateRevalAppliesToEntry(ItemJournalLine, Item."No.", ItemLedgerEntry."Entry No.");

        Assert.ExpectedError(RevaluationPerEntryNotAllowedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialRevaluationCanBePostedAfterPerEntry()
    var
        Item: Record Item;
        NewUnitCost: Decimal;
    begin
        Initialize();

        UpdateInventorySetup(false, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);
        LibraryInventory.SetAverageCostSetupInAccPeriods("Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        CreateItemWithInventoryValue(Item);
        PostItemLedgerEntryRevaluation(Item);
        NewUnitCost := PostItemRevaluation(Item, WorkDate());
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        Item.Find('=');
        Assert.AreEqual(NewUnitCost, Item."Unit Cost", CostMustBeEqualErr);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure OutputRevaluedAndRevertedIncludedInCostAdjustment()
    var
        ComponentItem: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        Quantity: Integer;
        ValuationDate: Date;
    begin
        // [FEATURE] [Production Order] [Adjust Cost Item Entries]
        // [SCENARIO 378471] "Adjust Cost - Item Entries" job should consider reversed prod. order output when it is revalued on a later date

        Initialize();

        // [GIVEN] Create component item "I1" with "Average" costing method and produced item "I2" which includes "I1" in its prod. BOM, costing method = "Standard"
        CreateItemWithUnitCost(ComponentItem, ComponentItem."Costing Method"::Average, LibraryRandom.RandDec(100, 2));
        CreateItemWithProductionBOM(ParentItem, ComponentItem."No.", 1);

        Quantity := LibraryRandom.RandInt(10);
        ValuationDate := WorkDate() + LibraryRandom.RandInt(5);
        // [GIVEN] Post income of item "I1" on inventory with unit cost = "C"
        UpdateItemInventory(ComponentItem."No.", '');
        // [GIVEN] Create production order for item "I2" and post output of "X" pcs on workdate
        CreateAndRefreshRelProdOrder(ProductionOrder, ParentItem."No.", Quantity, '');
        PostOutputJournalOnDate(ProductionOrder."No.", ParentItem."No.", Quantity, WorkDate());

        // [GIVEN] Consume component item "I1"
        PostProdOrderConsumption(ProductionOrder."No.");
        // [GIVEN] Revaluate item "I2" on WorkDate() + 3
        PostItemRevaluation(ParentItem, ValuationDate);
        // [GIVEN] Revert output on WorkDate() + 3 days
        RevertProdOrderOutput(ProductionOrder."No.", ParentItem."No.", ValuationDate);
        // [GIVEN] Post new output on WorkDate() + 3
        PostOutputJournalOnDate(ProductionOrder."No.", ParentItem."No.", Quantity, ValuationDate);

        // [GIVEN] Finish production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] Run cost adjustment
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ParentItem."No.", ComponentItem."No."), '');

        // [THEN] Total direct cost amount of item "I2" is "X" * "C"
        ComponentItem.Find();
        VerifyDirectCostAmount(ParentItem."No.", Quantity * ComponentItem."Unit Cost");
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardCostVarianceForwardedToAppliedOutboudOutput()
    var
        ComponentItem: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemLedgEntryNo: array[3] of Integer;
        I: Integer;
    begin
        // [FEATURE] [Production Order] [Adjust Cost Item Entries] [Post Inventory Cost to G/L]
        // [SCENARIO 378538] Standard cost variance created during WIP adjustment and forwarded to applied output reversal entry, can be posted to G/L

        Initialize();

        // [GIVEN] Component item "I1" with unit cost 17.33333
        CreateItemWithUnitCost(ComponentItem, ComponentItem."Costing Method"::FIFO, 17.33333);

        // [GIVEN] Manufactured item "I2" which includes "I1" as a component
        CreateItemWithProductionBOM(ParentItem, ComponentItem."No.", 1);

        // [GIVEN] Create released production order for 5 pcs of item "I2"
        UpdateItemInventory(ComponentItem."No.", '');
        CreateAndRefreshRelProdOrder(ProductionOrder, ParentItem."No.", 5, '');

        // [GIVEN] Post production order consumption and output of 5 pcs
        PostProdOrderConsumption(ProductionOrder."No.");
        PostOutputJournalOnDate(ProductionOrder."No.", ParentItem."No.", 5, WorkDate());

        // [GIVEN] Post 3 additional output entries, 2 pcs each
        for I := 1 to 3 do
            ItemLedgEntryNo[I] := PostOutputJournalFindEntry(ProductionOrder."No.", ParentItem."No.", 2, WorkDate());

        // [GIVEN] Revert extra output with fixed cost application
        RevertProdOrderOutputEntry(ProductionOrder."No.", ParentItem."No.", -2, ItemLedgEntryNo[2]);
        RevertProdOrderOutputEntry(ProductionOrder."No.", ParentItem."No.", -2, ItemLedgEntryNo[3]);
        RevertProdOrderOutputEntry(ProductionOrder."No.", ParentItem."No.", -2, ItemLedgEntryNo[1]);

        // [GIVEN] Revaluate item "I1". New unit cost = 17.335
        RevaluateItem(ComponentItem, 0.002);

        // [GIVEN] Finish production order and run cost adjustment for item "I1"
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        LibraryCosting.AdjustCostItemEntries(ParentItem."No.", '');

        // [WHEN] Post inventory cost to G/L
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] All actual cost amounts are posted to G/L
        VerifyActualCostPostedToGL(ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliesToEntryInRevaluationJournalWithDeletedItem()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        RevaluationJournal: TestPage "Revaluation Journal";
        PostingDate: Date;
    begin
        // [FEATURE] [Applies-to Entry]
        // [SCENARIO 359734] It should be possible to post revaluation of an item ledger entry when there are ILE's with blank "Item No."

        Initialize();

        UpdateInventorySetup(false, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        // [GIVEN] Item "I1" with average costing method
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Average);

        // [GIVEN] Purchase item in a closed accounting period. This is required to be able to delete the item later
        PostingDate := LibraryFiscalYear.GetLastPostingDate(true);
        PostItemJournalLine(
          ItemJournalLine."Entry Type"::Purchase, Item."No.", LibraryRandom.RandDec(100, 2), '', LibraryRandom.RandDec(100, 2), PostingDate);

        // [GIVEN] Run "Adjust Cost - Item Entries" job to make revaluation possible
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Calculate inventory value for item "I1" and post revaluation per item
        CreateRevaluationJournal(ItemJournalLine);
        CalcInventoryValueOnDate(Item, ItemJournalLine, PostingDate);
        UpdateRevaluedUnitCost(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.",
          LibraryRandom.RandDecInRange(200, 300, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sell all stock of item "I1"
        Item.CalcFields(Inventory);
        PostItemJournalLine(ItemJournalLine."Entry Type"::Sale, Item."No.", Item.Inventory, '', LibraryRandom.RandDec(100, 2), PostingDate);

        // [GIVEN] Adjust cost of item "I1" and delete the item
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        Item.Find();
        Item.Delete(true);

        // [GIVEN] Create item "I2" with average costing method and post an inbound item ledger entry for "I2"
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Average);
        PostItemJournalLine(
          ItemJournalLine."Entry Type"::Purchase, Item."No.", LibraryRandom.RandDec(100, 2), '', LibraryRandom.RandDec(100, 2), PostingDate);

        // [GIVEN] Create a revaluation journal line for item "I2"
        CreateRevaluationJournal(ItemJournalLine);
        RevaluationJournal.OpenEdit();
        RevaluationJournal.GotoRecord(ItemJournalLine);
        RevaluationJournal."Item No.".SetValue(Item."No.");

        SelectPurchItemLedgEntry(ItemLedgerEntry, Item."No.");

        // [WHEN] Set the "Applies-to Entry" in the journal line
        RevaluationJournal."Applies-to Entry".SetValue(ItemLedgerEntry."Entry No.");

        // [THEN] Entry No. is validated
        RevaluationJournal.Quantity.AssertEquals(ItemLedgerEntry.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedCostNotIncludedInAvgCostCalculationForItemWithAvgCostingMethod()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemJournalLine: Record "Item Journal Line";
        PostingDate: Date;
        UnitCost: array[3] of Decimal;
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Calculate Inventory Value] [Average Costing Method] [Unit Cost]
        // [SCENARIO 209978] Expected cost should not be included in average cost calculation for item with Costing Method = Average.
        Initialize();

        UpdateInventorySetup(
          false, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::"Item & Location & Variant", AverageCostPeriod::Day);

        // [GIVEN] Item with Costing Method = Average.
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        // [GIVEN] Two purchase orders "P1" and "P2" for the item.
        // [GIVEN] "P1" is received and invoiced, "P2" is received but not invoiced.
        Qty := LibraryRandom.RandInt(10);
        for i := 1 to 2 do
            UnitCost[i] := LibraryRandom.RandDec(100, 2);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        PostingDate := GetLatestPostingDate();
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, Location.Code, '', Qty, PostingDate, UnitCost[1], true, true);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, Location.Code, '', Qty, PostingDate, UnitCost[2], true, false);

        // [WHEN] Calculate inventory value in revaluation journal for the item.
        CreateRevaluationJournalAndCalcInventoryValueByLocAndVar(Item);

        // [THEN] Unit Cost on the revaluation journal line is equal to the direct unit cost in "P1".
        FilterRevaluationJournalLine(ItemJournalLine, Item."No.", Location.Code);
        VerifyRevaluationJournalLine(ItemJournalLine, Qty, UnitCost[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferRelatedToNotInvoicedPurchNotIncludedInAvgCostCalculationWithFilterOnSourceLoc()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        UnitCost: array[3] of Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Calculate Inventory Value] [Average Costing Method] [Unit Cost] [Transfer]
        // [SCENARIO 209978] Calculate inventory value run with a filter by location should exclude from average cost calculation not posted purchases and outbound transfers applied to them.
        Initialize();

        UpdateInventorySetup(
          false, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::"Item & Location & Variant", AverageCostPeriod::Day);

        // [GIVEN] Item with Costing Method = Average.
        // [GIVEN] Received not invoiced purchase "P1" on location "L1".
        // [GIVEN] Transfer of the received quantity from location "L1" to "L2".
        // [GIVEN] Received and invoiced purchase "P2" on location "L1".
        CreateAvgCostItemAndPostPurchasesAndTransfer(Item, FromLocation, ToLocation, Qty, UnitCost);

        // [WHEN] Calculate inventory value in revaluation journal for the item and location filter = "L1".
        Item.SetRange("Location Filter", FromLocation.Code);
        CreateRevaluationJournalAndCalcInventoryValueByLocAndVar(Item);

        // [THEN] Unit Cost on the revaluation journal line is equal to the direct unit cost in "P2".
        FilterRevaluationJournalLine(ItemJournalLine, Item."No.", FromLocation.Code);
        VerifyRevaluationJournalLine(ItemJournalLine, Qty, UnitCost[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferRelatedToNotInvoicedPurchNotIncludedInAvgCostCalculationWithFilterOnDestLoc()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        UnitCost: array[3] of Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Calculate Inventory Value] [Average Costing Method] [Unit Cost] [Transfer]
        // [SCENARIO 209978] Calculate inventory value run with a filter by location should exclude from average cost calculation inbound transfers applied to not posted purchases.
        Initialize();

        UpdateInventorySetup(
          false, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::"Item & Location & Variant", AverageCostPeriod::Day);

        // [GIVEN] Item with Costing Method = Average.
        // [GIVEN] Received not invoiced purchase "P1" on location "L1".
        // [GIVEN] Transfer of the received quantity from location "L1" to "L2".
        // [GIVEN] Received and invoiced purchase "P2" on location "L2".
        CreateAvgCostItemAndPostPurchasesAndTransfer(Item, FromLocation, ToLocation, Qty, UnitCost);

        // [WHEN] Calculate inventory value in revaluation journal for the item and location filter = "L2".
        Item.SetFilter("Location Filter", ToLocation.Code);
        CreateRevaluationJournalAndCalcInventoryValueByLocAndVar(Item);

        // [THEN] Unit Cost on the revaluation journal line is equal to the direct unit cost in "P2".
        FilterRevaluationJournalLine(ItemJournalLine, Item."No.", ToLocation.Code);
        VerifyRevaluationJournalLine(ItemJournalLine, Qty, UnitCost[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferRelatedToNotInvoicedPurchNotIncludedInAvgCostCalculationWithNoLocFilter()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        UnitCost: array[3] of Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Calculate Inventory Value] [Average Costing Method] [Unit Cost] [Transfer]
        // [SCENARIO 209978] Calculate inventory value run without location filter should exclude from average cost calculation not invoiced purchases and transfers applied to them.
        Initialize();

        UpdateInventorySetup(
          false, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::"Item & Location & Variant", AverageCostPeriod::Day);

        // [GIVEN] Item with Costing Method = Average.
        // [GIVEN] Received not invoiced purchase "P1" on location "L1".
        // [GIVEN] Transfer of the received quantity from location "L1" to "L2".
        // [GIVEN] Received and invoiced purchase "P2" on location "L1".
        // [GIVEN] Received and invoiced purchase "P3" on location "L2".
        CreateAvgCostItemAndPostPurchasesAndTransfer(Item, FromLocation, ToLocation, Qty, UnitCost);

        // [WHEN] Calculate inventory value in revaluation journal for the item with no location filter.
        CreateRevaluationJournalAndCalcInventoryValueByLocAndVar(Item);

        // [THEN] Unit Cost on the revaluation journal line with location "L1" is equal to the direct unit cost in "P2".
        FilterRevaluationJournalLine(ItemJournalLine, Item."No.", FromLocation.Code);
        VerifyRevaluationJournalLine(ItemJournalLine, Qty, UnitCost[2]);

        // [THEN] Unit Cost on the revaluation journal line with location "L2" is equal to the direct unit cost in "P3".
        FilterRevaluationJournalLine(ItemJournalLine, Item."No.", ToLocation.Code);
        VerifyRevaluationJournalLine(ItemJournalLine, Qty, UnitCost[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgCostOnWorkdateDoesNotIncludeActualCostPostedOnLaterDate()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemJournalLine: Record "Item Journal Line";
        UnitCost: array[2] of Decimal;
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Calculate Inventory Value] [Average Costing Method] [Unit Cost]
        // [SCENARIO 209978] Average cost calculation should include only actual cost posted no later than the revaluation date.
        Initialize();

        UpdateInventorySetup(
          false, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::"Item & Location & Variant", AverageCostPeriod::Day);

        // [GIVEN] Item with Costing Method = Average.
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        // [GIVEN] Partially posted purchase order on WORKDATE.
        // [GIVEN] Received quantity = invoiced quantity = "q". Full quantity of the purchase line = "Q".
        // [GIVEN] Direct Unit Cost on the purchase line = "X".
        for i := 1 to ArrayLen(Qty) do begin
            Qty[i] := LibraryRandom.RandInt(10);
            UnitCost[i] := LibraryRandom.RandDec(100, 2);
        end;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryPurchase.PostPurchaseOrderPartially(
          PurchaseHeader, Item, Location.Code, '', Qty[1] + Qty[2], GetLatestPostingDate(),
          UnitCost[1], true, Qty[1], true, Qty[1]);

        // [GIVEN] Direct Unit Cost on the purchase line is updated to "Y".
        // [GIVEN] Remaining quantity ("Q" - "q") in the purchase is received and invoiced.
        UpdatePostingDateAndVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        UpdateDirectUnitCostOnPurchaseLine(PurchaseHeader, UnitCost[2]);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Calculate inventory value in revaluation journal for the item.
        CreateRevaluationJournalAndCalcInventoryValueByLocAndVar(Item);

        // [THEN] Unit Cost on the revaluation journal line is equal to "X".
        FilterRevaluationJournalLine(ItemJournalLine, Item."No.", Location.Code);
        VerifyRevaluationJournalLine(ItemJournalLine, Qty[1], UnitCost[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryValueForLocationAndVariantWithSpecialCharacters()
    var
        Item: Record Item;
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        UnitCost: Decimal;
        Qty: Decimal;
    begin
        // [SCENARIO 200674] Inventory value can be calculated in revaluation journal when item variant code and location code contain filtering symbols ">", "<", "="

        Initialize();

        // [GIVEN] Set "Average Cost Calc. Type" = "Item & Location & Variant"
        UpdateInventorySetup(
          false, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::"Item & Location & Variant", AverageCostPeriod::Day);

        // [GIVEN] Item "I" with "Average" costing method
        UnitCost := LibraryRandom.RandIntInRange(100, 200);
        Qty := LibraryRandom.RandInt(100);
        CreateItemWithUnitCost(Item, Item."Costing Method"::Average, UnitCost);

        // [GIVEN] Location with a code containing a special character "L>"
        Location.Init();
        Location.Validate(Code, CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Location.Code) - 1) + '>');
        Location.Insert(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);

        // [GIVEN] Item variant with a code containing a special character "V="
        ItemVariant.Init();
        ItemVariant.Validate("Item No.", Item."No.");
        ItemVariant.Validate(Code, CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ItemVariant.Code) - 1) + '=');
        ItemVariant.Insert(true);

        // [GIVEN] Post item stock for item "I", variant "V=", on location "L>". Quantity = "Q", Unit cost = "C"
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', Qty);
        ItemJournalLine.Validate("Variant Code", ItemVariant.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Calculate inventory value for item "I"
        CreateRevaluationJournal(ItemJournalLine);
        CalcInventoryValueWithLocationAndVariant(Item, ItemJournalLine, WorkDate(), true, true);

        // [THEN] Calculated unit cost = "C", calculated inventory value = "C" * "Q"
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Unit Cost (Calculated)", UnitCost);
        ItemJournalLine.TestField("Inventory Value (Calculated)", UnitCost * Qty);
    end;

    [Test]
    procedure PartialRevaluationWithConsiderationOfUnitCostPrecisionError()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Rounding] [Unit of Measure]
        // [SCENARIO 416071] Consider unit cost rounding when posting revaluation of an item entry.
        Initialize();

        // [GIVEN] Item with base unit of measure "PCS" and alternate UoM "BOX" = 1,000,000 PCS.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1000000);

        // [GIVEN] Create and post item journal line, quantity = 1 "BOX", amount = 663.
        // [GIVEN] A unit cost is thus equal to 0.000663 and rounded to 0.00066.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 1);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Purchase);
        ItemJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ItemJournalLine.Validate(Amount, 663);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Note the posted item entry "X" has cost amount = 663.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", 663);

        // [GIVEN] Run the cost adjustment prior to revaluation.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Create a revaluation journal line, select the item entry "X" and the new inventory value = 0.
        CreateRevaluationJournal(ItemJournalLine);
        ItemJournalLine.Validate("Item No.", Item."No.");
        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Validate("Inventory Value (Revalued)", 0);
        ItemJournalLine.Modify(true);

        // [WHEN] Post the revaluation journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] The item entry "X" has cost amount = 0.
        ItemLedgerEntry.Find();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Revaluation-II");
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Revaluation-II");

        GeneralLedgerSetup.Get();

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        NoSeriesSetup();
        OutputJournalSetup();
        RevaluationJournalSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Revaluation-II");
    end;

    local procedure NoSeriesSetup()
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure OutputJournalSetup()
    begin
        Clear(OutputItemJournalTemplate);
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        OutputItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        OutputItemJournalTemplate.Modify(true);

        Clear(OutputItemJournalBatch);
        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
        OutputItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        OutputItemJournalBatch.Modify(true);
    end;

    local procedure RevaluationJournalSetup()
    begin
        Clear(RevaluationItemJournalTemplate);
        RevaluationItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(RevaluationItemJournalTemplate, RevaluationItemJournalTemplate.Type::Revaluation);

        Clear(RevaluationItemJournalBatch);
        RevaluationItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(RevaluationItemJournalBatch, RevaluationItemJournalTemplate.Type,
          RevaluationItemJournalTemplate.Name);
    end;

    local procedure ClearJournal(ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
    end;

    local procedure CreateItem(ItemCostingMethod: Enum "Costing Method"; InventoryPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Inventory Posting Group", InventoryPostingGroup);

        if ItemCostingMethod = ItemCostingMethod::Standard then begin
            Item.Validate("Costing Method", Item."Costing Method"::Standard);
            Item.Validate("Standard Cost", LibraryRandom.RandDec(50, 2));
            Item.Validate("Last Direct Cost", Item."Standard Cost");
        end else begin
            Item.Validate("Costing Method", ItemCostingMethod);
            Item.Validate("Unit Cost", LibraryRandom.RandDec(50, 2));
            Item.Validate("Last Direct Cost", Item."Unit Cost");
        end;
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithCostingMethod(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    local procedure CreateItemWithInventoryValue(var Item: Record Item)
    var
        LocationCode: Code[10];
        InventoryPostingGroup: Code[20];
        ItemNo: Code[20];
    begin
        LocationCode := CreateLocationCode(InventoryPostingGroup);
        ItemNo := CreateItem(Item."Costing Method"::Average, InventoryPostingGroup);
        Item.Get(ItemNo);
        UpdateItemInventory(Item."No.", LocationCode);
    end;

    local procedure CreateItemWithProductionBOM(var ParentItem: Record Item; ChildItemNo: Code[20]; QtyPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        LibraryInventory.CreateItem(ParentItem);

        CreateProductionBOM(ProductionBOMHeader, ChildItemNo, ParentItem."Base Unit of Measure", QtyPer);
        ParentItem.Validate("Costing Method", ParentItem."Costing Method"::Standard);
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Modify(true);

        CalculateStandardCost.CalcItem(ParentItem."No.", false);
    end;

    local procedure CreateItemWithUnitCost(var Item: Record Item; CostingMethod: Enum "Costing Method"; UnitCost: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", UnitCost);
        Item.Validate("Last Direct Cost", UnitCost);
        Item.Modify(true);
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // Create Item Journal to populate Item Quantity.
        Item.Get(ItemNo);
        PostItemJournalLine(
          ItemJournalLine."Entry Type"::Purchase, ItemNo, LibraryRandom.RandInt(10) + 10, LocationCode, Item."Unit Cost", WorkDate());
    end;

    local procedure CreateLocationsForTransfer(var FromLocation: Record Location; var ToLocation: Record Location; var InTransitLocation: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; ItemNo2: Code[20]; Qty: Decimal; LocationCode: Code[10]; ProductionComponents: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        if ProductionComponents then
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo2, Qty);
    end;

    local procedure CreateLocationCode(var InventoryPostingGroup: Code[20]): Code[10]
    var
        Location: Record Location;
        InventoryPostingGroupRec: Record "Inventory Posting Group";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        InventoryPostingGroupRec.FindFirst();
        InventoryPostingGroup := InventoryPostingGroupRec.Code;
        exit(Location.Code);
    end;

    local procedure PurchaseOrderInvoiceLessQty(PurchaseDocumentNo: Code[20]; InvoiceQty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseDocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Qty. to Invoice", InvoiceQty);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ChildItemNo: Code[20]; UOMCode: Code[10]; QtyPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UOMCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ChildItemNo, QtyPer);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateRevaluationJournal(var ItemJournalLine: Record "Item Journal Line")
    begin
        ClearJournal(RevaluationItemJournalTemplate, RevaluationItemJournalBatch);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, RevaluationItemJournalBatch, RevaluationItemJournalBatch."Journal Template Name",
          RevaluationItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateRevaluationJournalAndCalcInventoryValueByLocAndVar(var Item: Record Item)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        CreateRevaluationJournal(ItemJournalLine);
        CalcInventoryValueWithLocationAndVariant(Item, ItemJournalLine, GetLatestPostingDate(), true, true);
    end;

    local procedure CalcInventoryValue(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line")
    begin
        CalcInventoryValueOnDate(Item, ItemJournalLine, WorkDate());
    end;

    local procedure CalcInventoryValueOnDate(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line"; PostingDate: Date)
    begin
        CalcInventoryValueWithLocationAndVariant(Item, ItemJournalLine, PostingDate, false, false);
    end;

    local procedure CalcInventoryValueWithLocationAndVariant(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line"; PostingDate: Date; ByLocation: Boolean; ByVariant: Boolean)
    begin
        Item.SetRecFilter();
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, PostingDate, ItemJournalLine."Document No.", "Inventory Value Calc. Per"::Item,
          ByLocation, ByVariant, true, "Inventory Value Calc. Base"::" ", false);
    end;

    local procedure UpdateRevaluedUnitCost(JournalTemplateName: Text[10]; JournalTemplateBatch: Text[10]; ItemNo: Code[20]; OldUnitCost: Decimal): Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalTemplateBatch);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", OldUnitCost + LibraryRandom.RandDec(50, 2));
        ItemJournalLine.Modify(true);
        exit(ItemJournalLine."Unit Cost (Revalued)");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; RevaluedQuantity: Decimal; LocationCode: Code[10]; ByLocation: Boolean)
    var
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, '');
        if ByLocation then begin
            ItemLedgerEntry.SetRange("Item No.", ItemNo);
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Transfer Receipt");
            ItemLedgerEntry.SetFilter(Quantity, '>0');
            ItemLedgerEntry.FindFirst();
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, RevaluedQuantity - ItemLedgerEntry.Quantity);
            SalesLine.Validate("Location Code", LocationCode);
            LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, ItemNo, ItemLedgerEntry.Quantity);
            SalesLine.Validate("Location Code", ItemLedgerEntry."Location Code");
        end else begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, RevaluedQuantity);
            SalesLine.Validate("Location Code", LocationCode);
        end;
        SalesLine.Modify(true);
    end;

    local procedure TransferQtyDiffLocation(ItemNo: Code[20]; FromLocation: Code[10])
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Location: Record Location;
        InventoryPostingGroup: Code[20];
    begin
        // Create a Transfer Order to Transfer a Random Quantity to a Different Location.
        Location.SetRange("Use As In-Transit", true);
        Location.FindFirst();
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, CreateLocationCode(InventoryPostingGroup), Location.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, LibraryRandom.RandInt(5));
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
    end;

    local procedure CreateRoutingSetup(var RoutingNo: Code[20])
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        WorkCenterGroup: Record "Work Center Group";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ShopCalendarCode: Code[10];
        WorkCenterNo: Code[20];
    begin
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();
        LibraryManufacturing.CreateWorkCenterGroup(WorkCenterGroup);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Minutes);

        // Create Work Center and Machine Center for Routing.
        CreateWorkCenter(ShopCalendarCode, WorkCenterNo, WorkCenter."Flushing Method"::Manual);
        CalculateWorkCntrCalendar(WorkCenterNo);
        CreateMachineCenter(
          MachineCenter, WorkCenterNo, MachineCenter."Flushing Method"::Manual,
          LibraryRandom.RandInt(5), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandInt(5), 1);  // Capacity Value important for test.
        CalculateMachineCntrCalendar(MachineCenter."No.");
        CreateRouting(WorkCenterNo, MachineCenter."No.", RoutingNo);
    end;

    local procedure CreateWorkCenter(ShopCalendarCode: Code[10]; var WorkCenterNo: Code[20]; FlushingMethod: Enum "Flushing Method")
    var
        WorkCenter: Record "Work Center";
    begin
        // Create Work Center with required fields where Capacity value : 1,  important for test.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Indirect Cost %", LibraryRandom.RandInt(5));
        WorkCenter.Validate("Overhead Rate", LibraryRandom.RandInt(5));
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20]; FlushingMethod: Enum "Flushing Method"; Capacity: Decimal; DirectUnitCost: Decimal; IndirectCostPercentage: Decimal; OverheadRate: Decimal)
    begin
        // Create Machine Center with required fields.
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenterNo, Capacity);
        MachineCenter.Validate(Name, MachineCenter."No.");
        MachineCenter.Validate("Direct Unit Cost", DirectUnitCost);
        MachineCenter.Validate("Indirect Cost %", IndirectCostPercentage);
        MachineCenter.Validate("Overhead Rate", OverheadRate);
        MachineCenter.Validate("Flushing Method", FlushingMethod);
        MachineCenter.Modify(true);
    end;

    local procedure CreateRouting(WorkCenterNo: Code[20]; MachineCenterNo: Code[20]; var RoutingNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, WorkCenterNo,
          CopyStr(LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
            MaxStrLen(RoutingLine."Operation No.")), LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, MachineCenterNo,
          CopyStr(LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
            MaxStrLen(RoutingLine."Operation No.")), LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));

        // Certify Routing after Routing lines creation.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        RoutingNo := RoutingHeader."No.";
    end;

    local procedure CreateProdItemWithBOM(var Item: Record Item; ItemCostingMethod: Enum "Costing Method"; ItemNo: Code[20]; ItemNo2: Code[20]; InventoryPostingGroup: Code[20]; RoutingNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Production BOM.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ItemNo, ItemNo2, LibraryRandom.RandInt(5));

        // Create Parent item and attach Production BOM.
        CreateProductionItem(
          Item, ItemCostingMethod, Item."Reordering Policy"::"Lot-for-Lot",
          Item."Flushing Method"::"Pick + Manual", RoutingNo, ProductionBOMHeader."No.", InventoryPostingGroup);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ItemCostingMethod: Enum "Costing Method"; ItemReorderPolicy: Enum "Reordering Policy"; FlushingMethod: Enum "Flushing Method"; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; InventoryPostingGroup: Code[20])
    begin
        // Create Item with required fields where random values not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, ItemCostingMethod, LibraryRandom.RandDec(10, 2), ItemReorderPolicy, FlushingMethod, RoutingNo, ProductionBOMNo);
        Item.Validate("Inventory Posting Group", InventoryPostingGroup);
        Item.Modify(true);
    end;

    local procedure CalculateMachineCntrCalendar(MachineCenterNo: Code[20])
    var
        MachineCenter: Record "Machine Center";
    begin
        // Calculate Calendar for Machine Center with dates having a difference of 1 Month.
        MachineCenter.Get(MachineCenterNo);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
    end;

    local procedure CalculateWorkCntrCalendar(WorkCenterNo: Code[20])
    var
        WorkCenter: Record "Work Center";
    begin
        // Calculate Calendar for Work Center with dates having a difference of 1 Month.
        WorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
    end;

    local procedure CreateAndRefreshRelProdOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Qty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAvgCostItemAndPostPurchasesAndTransfer(var Item: Record Item; var FromLocation: Record Location; var ToLocation: Record Location; var Qty: Decimal; var UnitCost: array[3] of Decimal)
    var
        InTransitLocation: Record Location;
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        PostingDate: Date;
        i: Integer;
    begin
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);
        CreateLocationsForTransfer(FromLocation, ToLocation, InTransitLocation);

        Qty := LibraryRandom.RandInt(10);
        for i := 1 to ArrayLen(UnitCost) do
            UnitCost[i] := LibraryRandom.RandDec(100, 2);

        PostingDate := GetLatestPostingDate();

        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, FromLocation.Code, '', Qty, PostingDate, UnitCost[1], true, false);
        LibraryInventory.CreateAndPostTransferOrder(
          TransferHeader, Item, FromLocation, ToLocation, InTransitLocation, '', Qty, PostingDate, PostingDate, true, true);

        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, FromLocation.Code, '', Qty, PostingDate, UnitCost[2], true, true);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, ToLocation.Code, '', Qty, PostingDate, UnitCost[3], true, true);
    end;

    local procedure FilterRevaluationJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Location Code", LocationCode);
    end;

    local procedure FindProdOrderOutputEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure GetLatestPostingDate(): Date
    var
        PostingDate: Date;
    begin
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);
        if WorkDate() >= PostingDate then
            exit(WorkDate());
        exit(PostingDate);
    end;

    local procedure PostItemJournalLine(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; UnitAmount: Decimal; PostingDate: Date)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure PostItemLedgerEntryRevaluation(Item: Record Item): Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        CreateRevaluationJournal(ItemJournalLine);
        SelectPurchItemLedgEntry(ItemLedgerEntry, Item."No.");
        UpdateRevalAppliesToEntry(ItemJournalLine, Item."No.", ItemLedgerEntry."Entry No.");

        exit(PostRevaluationJournalLine(Item, ItemJournalLine));
    end;

    local procedure PostItemRevaluation(Item: Record Item; PostingDate: Date): Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateRevaluationJournal(ItemJournalLine);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        CalcInventoryValueOnDate(Item, ItemJournalLine, PostingDate);

        exit(PostRevaluationJournalLine(Item, ItemJournalLine));
    end;

    local procedure PostOutputJournalOnDate(ProdOrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournal(ItemJournalLine, ItemNo, ProdOrderNo, Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostOutputJournalFindEntry(ProdOrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        PostOutputJournalOnDate(ProdOrderNo, ItemNo, Quantity, PostingDate);

        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderNo);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.FindLast();

        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure PostProdOrderConsumption(ProdOrderNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryManufacturing.CalculateConsumption(ProdOrderNo, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure PostProductionJournal(var ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure PostRevaluationJournalLine(Item: Record Item; ItemJournalLine: Record "Item Journal Line"): Decimal
    var
        NewUnitCost: Decimal;
    begin
        NewUnitCost :=
          UpdateRevaluedUnitCost(
            ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", Item."Unit Cost");

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        exit(NewUnitCost);
    end;

    local procedure RevaluateItem(var Item: Record Item; UnitCostDiff: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateRevaluationJournal(ItemJournalLine);
        CalcInventoryValueOnDate(Item, ItemJournalLine, WorkDate());
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.FindLast();
        ItemJournalLine.Validate("Unit Cost (Revalued)", ItemJournalLine."Unit Cost (Calculated)" + UnitCostDiff);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure RevertProdOrderOutput(ProdOrderNo: Code[20]; ItemNo: Code[20]; PostingDate: Date)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
    begin
        FindProdOrderOutputEntry(ItemLedgerEntry, ProdOrderNo, ItemNo);

        CreateOutputJournal(ItemJournalLine, ItemNo, ProdOrderNo, -ItemLedgerEntry.Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
        UpdateAppliesToEntry(ItemJournalLine, ItemLedgerEntry."Entry No.");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure RevertProdOrderOutputEntry(ProdOrderNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; ApplToEntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournal(ItemJournalLine, ItemNo, ProdOrderNo, Qty);
        ItemJournalLine.Validate("Posting Date", WorkDate());
        ItemJournalLine.Modify(true);
        UpdateAppliesToEntry(ItemJournalLine, ApplToEntryNo);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SelectItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure SelectPurchItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure CreateOutputJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        NoSeries: Codeunit "No. Series";
    begin
        ClearJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ItemNo, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", Quantity);
        ItemJournalLine.Validate(
          "Document No.", NoSeries.PeekNextNo(OutputItemJournalBatch."No. Series", ItemJournalLine."Posting Date"));
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateAppliesToEntry(var ItemJournalLine: Record "Item Journal Line"; AppliesToEntry: Integer)
    begin
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateRevalAppliesToEntry(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; AppliesToEntry: Integer)
    begin
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        ItemJournalLine.Validate("Item No.", ItemNo);
        UpdateAppliesToEntry(ItemJournalLine, AppliesToEntry);
    end;

    local procedure UpdatePostingDateAndVendorInvoiceNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Posting Date", LibraryRandom.RandDateFrom(GetLatestPostingDate(), 10));
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateDirectUnitCostOnPurchaseLine(PurchaseHeader: Record "Purchase Header"; NewUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Direct Unit Cost", NewUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateInventorySetup(AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean; AutomaticCostAdjmt: Option; AvgCostCalcType: Enum "Average Cost Calculation Type"; AvgCostPeriod: Enum "Average Cost Period Type")
    begin
        LibraryInventory.SetAutomaticCostPosting(AutomaticCostPosting);
        LibraryInventory.SetExpectedCostPosting(ExpectedCostPosting);
        case AutomaticCostAdjmt of
            AutomaticCostAdjustment::Always:
                LibraryInventory.SetAutomaticCostAdjmtAlways();
            AutomaticCostAdjustment::Never:
                LibraryInventory.SetAutomaticCostAdjmtNever();
        end;
        LibraryInventory.UpdateAverageCostSettings(AvgCostCalcType, AvgCostPeriod);
    end;

    local procedure VerifyActualCostPostedToGL(ProdOrderNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProdOrderNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        ValueEntry.FindSet();
        repeat
            ValueEntry.TestField("Cost Posted to G/L", ValueEntry."Cost Amount (Actual)");
        until ValueEntry.Next() = 0;
    end;

    local procedure VerifyDirectCostAmount(ItemNo: Code[20]; ExpectedAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", ExpectedAmount);
    end;

    local procedure VerifyRevaluedInventory(Item: Record Item)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Item.CalcFields(Inventory);
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        Assert.AreEqual(Item.Inventory, ItemJournalLine.Quantity, ErrMessageQtyMustBeEqual);
    end;

    local procedure VerifyRevaluationJournalLine(var ItemJournalLine: Record "Item Journal Line"; Qty: Decimal; UnitCost: Decimal)
    begin
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(Quantity, Qty);
        ItemJournalLine.TestField("Unit Cost (Calculated)", UnitCost);
        ItemJournalLine.TestField("Inventory Value (Calculated)", Qty * UnitCost);
    end;

    local procedure VerifyItemCost(ProductionItemNo: Code[20]; NewUnitCost: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ProductionItemNo);
        Assert.AreNearlyEqual(NewUnitCost, Item."Standard Cost", GeneralLedgerSetup."Amount Rounding Precision", CostMustBeEqualErr);
    end;

    local procedure VerifyValueEntry(Qty: Integer; ItemNo: Code[20]; CostBeforeReval: Decimal; CostAfterReval: Decimal; AdjustedRevalCost: Decimal; InitialInvt: Decimal; InvtExistBeforePurchase: Boolean; IsTransfer: Boolean)
    begin
        // Verify Cost for Revaluation Entries.
        VerifyValueEntryRevaluation(Qty, ItemNo, AdjustedRevalCost, InitialInvt, InvtExistBeforePurchase);

        // Verify Cost for all posted Entries.
        if not IsTransfer then
            VerifyValueEntryTotal(Qty, ItemNo, CostBeforeReval, CostAfterReval, AdjustedRevalCost, InitialInvt, InvtExistBeforePurchase);
    end;

    local procedure VerifyValueEntryRevaluation(Qty: Integer; ItemNo: Code[20]; AdjustedRevaluationCost: Decimal; InitialInventory: Decimal; InventoryExistBeforePurchase: Boolean)
    var
        ExpectedCostPostedGLRevalue: Decimal;
    begin
        ExpectedCostPostedGLRevalue :=
          CalcPurchaseInvoiceCost(Qty, AdjustedRevaluationCost, InitialInventory, InventoryExistBeforePurchase);
        Assert.AreNearlyEqual(
          -ExpectedCostPostedGLRevalue, ActualValueEntriesCostPostedGL(ItemNo, true, false), GeneralLedgerSetup."Amount Rounding Precision",
          CostMustBeEqualErr);
    end;

    local procedure VerifyValueEntryTotal(Qty: Integer; ItemNo: Code[20]; CostBeforeReval: Decimal; CostAfterReval: Decimal; AdjustedRevalCost: Decimal; InitialInvt: Decimal; InvtExistBeforePurchase: Boolean)
    var
        ExpectedCostPostedGL: Decimal;
    begin
        ExpectedCostPostedGL :=
          CalcPurchaseInvoiceCost(Qty, CostBeforeReval, InitialInvt, InvtExistBeforePurchase) -
          CalcPurchaseInvoiceCost(Qty, AdjustedRevalCost, InitialInvt, InvtExistBeforePurchase) - Qty * CostAfterReval;
        Assert.AreNearlyEqual(
          ExpectedCostPostedGL, ActualValueEntriesCostPostedGL(ItemNo, false, false), GeneralLedgerSetup."Amount Rounding Precision",
          CostMustBeEqualErr);
    end;

    local procedure VerifyValueEntryComponentItem(Qty: Integer; ItemNo: Code[20]; CostBeforeReval: Decimal; CostAfterReval: Decimal; AdjustedRevalCost: Decimal)
    begin
        // Verify Cost for Revaluation Entries.
        VerifyValueEntryRevaluation(Qty, ItemNo, AdjustedRevalCost, 0, false);

        // Verify Cost for all posted Entries.
        VerifyValueEntryProdTotal(Qty, ItemNo, CostBeforeReval, CostAfterReval, AdjustedRevalCost);
    end;

    local procedure VerifyValueEntryProdTotal(Qty: Integer; ItemNo: Code[20]; CostBeforeReval: Decimal; CostAfterReval: Decimal; AdjustedRevalCost: Decimal)
    var
        ExpectedCostPostedGL: Decimal;
    begin
        ExpectedCostPostedGL :=
          CalcPurchaseInvoiceCost(Qty, CostBeforeReval, 0, false) -
          CalcPurchaseInvoiceCost(Qty, AdjustedRevalCost, 0, false) -
          CalcConsumptionAmount(ItemNo, CostAfterReval);
        Assert.AreNearlyEqual(
          ExpectedCostPostedGL, ActualValueEntriesCostPostedGL(ItemNo, false, false), GeneralLedgerSetup."Amount Rounding Precision",
          CostMustBeEqualErr);
    end;

    local procedure VerifyValueEntryLessInvoice(ItemNo: Code[20]; CostBeforeReval: Decimal; AdjustedRevalCost: Decimal; InitialInvt: Decimal; PurchaseQty: Decimal; InvoiceQty: Decimal)
    var
        ExpectedCostPostedGL: Decimal;
    begin
        // Verify Cost for Revaluation Entries.
        ExpectedCostPostedGL :=
          (CostBeforeReval * InvoiceQty) / (CostBeforeReval * PurchaseQty) * (InitialInvt - PurchaseQty) * AdjustedRevalCost;
        Assert.AreNearlyEqual(
          -ExpectedCostPostedGL, ActualValueEntriesCostPostedGL(ItemNo, true, false), GeneralLedgerSetup."Amount Rounding Precision",
          CostMustBeEqualErr);
    end;

    local procedure VerifyValueEntryRevalTwice(ItemNo: Code[20]; CostBeforeReval: Decimal; AdjustedRevalCost: Decimal; AdjustedRevalCost2: Decimal; CostAfterReval: Decimal; PurchSalesQty: Decimal; InvoiceQty: Decimal)
    var
        ExpectedCostPostedGL: Decimal;
    begin
        // Verify Cost for all posted Entries.
        ExpectedCostPostedGL :=
          InvoiceQty * (CostBeforeReval + AdjustedRevalCost) +
          (CostBeforeReval * InvoiceQty) / (CostBeforeReval * PurchSalesQty) * (PurchSalesQty * AdjustedRevalCost2) -
          PurchSalesQty * CostAfterReval;
        Assert.AreNearlyEqual(
          ExpectedCostPostedGL, ActualValueEntriesCostPostedGL(ItemNo, false, false), GeneralLedgerSetup."Amount Rounding Precision",
          CostMustBeEqualErr);
    end;

    local procedure VerifyValueEntryRevalNoSales(ItemNo: Code[20]; CostBeforeReval: Decimal; AdjustedRevalCost: Decimal; AdjustedRevalCost2: Decimal; PurchQty: Decimal; InvoiceQty: Decimal)
    var
        ExpectedCostPostedGL: Decimal;
    begin
        // Verify Cost for all posted Entries.
        ExpectedCostPostedGL :=
          InvoiceQty * (CostBeforeReval + AdjustedRevalCost) +
          ((CostBeforeReval * InvoiceQty) / (CostBeforeReval * PurchQty)) * (PurchQty * AdjustedRevalCost2);
        Assert.AreNearlyEqual(
          ExpectedCostPostedGL, ActualValueEntriesCostPostedGL(ItemNo, false, false), GeneralLedgerSetup."Amount Rounding Precision",
          CostMustBeEqualErr);
    end;

    local procedure ActualValueEntriesCostPostedGL(ItemNo: Code[20]; RevaluationFilter: Boolean; PositiveEntry: Boolean) CostPostedGL: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        if RevaluationFilter then
            ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.SetRange("Item No.", ItemNo);
        if PositiveEntry then
            ValueEntry.SetFilter("Cost Posted to G/L", '>0');
        ValueEntry.FindSet();
        repeat
            CostPostedGL += ValueEntry."Cost Posted to G/L";
        until ValueEntry.Next() = 0;
    end;

    local procedure CalcPurchaseInvoiceCost(Qty: Integer; UnitCost: Decimal; InitialInventory: Decimal; InventoryExistBeforePurchase: Boolean): Decimal
    var
        QtyFromItemJournal: Decimal;
    begin
        if InventoryExistBeforePurchase then begin
            QtyFromItemJournal := InitialInventory - Qty;
            exit(Qty * UnitCost + QtyFromItemJournal * UnitCost);
        end;
        exit(Qty * UnitCost);
    end;

    local procedure CalcConsumptionAmount(ItemNo: Code[20]; UnitCost: Decimal): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.CalcFields("Act. Consumption (Qty)");
        exit(ProdOrderComponent."Act. Consumption (Qty)" * UnitCost);
    end;

    local procedure VerifyItemLedgerEntryCostAmt(DocumentNo: Code[20]; ExpectedCostAmount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreEqual(ExpectedCostAmount, ItemLedgerEntry."Cost Amount (Actual)", ErrMsgCostAmount);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdJournalPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet();
        repeat
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
        until ItemJournalLine.Next() = 0;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalculateStdCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Calculate Standard Cost for All Level when Costing Method Standard.
        Choice := 2;
    end;
}

