codeunit 137086 "Cost Adjustment Features Mfg."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Adjustment] [SCM] [Manufacturing]
        Initialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Initialized: Boolean;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if Initialized then
            exit;

        SetManualCostAdjustmentParameters();

        LibrarySetupStorage.SaveInventorySetup();

        Initialized := true;
    end;

    // TEST CASES:

    // 2. Adjusting cost for selected orders:
    // 2.1. Any costing method - select production order, check that other orders are not adjusted
    // 2.3. Any costing method - select several production orders
    // 2.4. Any costing method - select already adjusted order, check that nothing is adjusted
    // 2.5. Any costing method - select unfinished order, check that nothing is adjusted

    // 4. Item-by-item committing:
    // 4.4. Test scenarios with both item entries and orders to be adjusted

    // 5. Cost adjustment with parameters:
    // 5.2. Manual adjustment with item batches, entry points, production orders.

    // 6. Cost adjustment tracer:
    // 6.3. Trace items with production orders

    // 7. Action messages:
    // 7.6. Tests for many production orders to adjust

    [Test]
    procedure T21_AdjustSelectedOrders_Production()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        i: Integer;
    begin
        Initialize();

        CreateItem(Item, Item."Costing Method"::FIFO);

        for i := 1 to 2 do begin
            Clear(ProductionOrder);
            CreateProductionOrder(ProductionOrder, Item."No.", 10);
            FindFirstProdOrderLine(ProdOrderLine[i], ProductionOrder);
            PostProductionConsumptionAndOutput(ProdOrderLine[i], 10, 20.0);
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrderLine[i]."Prod. Order No.");
        end;

        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine[1]."Prod. Order No.", ProdOrderLine[1]."Line No.");
        InventoryAdjmtEntryOrder.SetRecFilter();
        InventoryAdjmtEntryOrder.RunCostAdjustment(InventoryAdjmtEntryOrder);

        Item.Find();
        Item.TestField("Cost is Adjusted", false);
        VerifyItemCost(Item."No.", 200, 100);

        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine[1]."Prod. Order No.", ProdOrderLine[1]."Line No.");
        InventoryAdjmtEntryOrder.TestField("Cost Is Adjusted", true);
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine[2]."Prod. Order No.", ProdOrderLine[2]."Line No.");
        InventoryAdjmtEntryOrder.TestField("Cost Is Adjusted", false);
    end;

    [Test]
    procedure T23_AdjustSelectedOrders_SeveralProduction()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        i: Integer;
    begin
        Initialize();

        CreateItem(Item, Item."Costing Method"::FIFO);

        for i := 1 to 2 do begin
            Clear(ProductionOrder);
            CreateProductionOrder(ProductionOrder, Item."No.", 10);
            FindFirstProdOrderLine(ProdOrderLine[i], ProductionOrder);
            PostProductionConsumptionAndOutput(ProdOrderLine[i], 10, 20.0);
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrderLine[i]."Prod. Order No.");
        end;

        // Select and process both production orders
        InventoryAdjmtEntryOrder.SetRange("Order Type", "Inventory Order Type"::Production);
        InventoryAdjmtEntryOrder.SetFilter("Order No.", '%1|%2', ProdOrderLine[1]."Prod. Order No.", ProdOrderLine[2]."Prod. Order No.");
        InventoryAdjmtEntryOrder.RunCostAdjustment(InventoryAdjmtEntryOrder);

        Item.Find();
        Item.TestField("Cost is Adjusted", true);
        VerifyItemCost(Item."No.", 400, 0); // 2 orders * 200 actual cost (fully adjusted)

        // Verify both orders got adjusted
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine[1]."Prod. Order No.", ProdOrderLine[1]."Line No.");
        InventoryAdjmtEntryOrder.TestField("Cost Is Adjusted", true);
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine[2]."Prod. Order No.", ProdOrderLine[2]."Line No.");
        InventoryAdjmtEntryOrder.TestField("Cost Is Adjusted", true);
    end;

    [Test]
    procedure T24_AdjustSelectedOrders_AlreadyAdjusted()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        i: Integer;
    begin
        Initialize();

        CreateItem(Item, Item."Costing Method"::FIFO);

        // Create two production orders
        for i := 1 to 2 do begin
            Clear(ProductionOrder);
            CreateProductionOrder(ProductionOrder, Item."No.", 10);
            FindFirstProdOrderLine(ProdOrderLine[i], ProductionOrder);
            PostProductionConsumptionAndOutput(ProdOrderLine[i], 10, 20.0);
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrderLine[i]."Prod. Order No.");
        end;

        // First adjustment on first production order
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine[1]."Prod. Order No.", ProdOrderLine[1]."Line No.");
        InventoryAdjmtEntryOrder.SetRecFilter();
        InventoryAdjmtEntryOrder.RunCostAdjustment(InventoryAdjmtEntryOrder);

        // Verify first order is adjusted, second is not
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine[1]."Prod. Order No.", ProdOrderLine[1]."Line No.");
        InventoryAdjmtEntryOrder.TestField("Cost Is Adjusted", true);
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine[2]."Prod. Order No.", ProdOrderLine[2]."Line No.");
        InventoryAdjmtEntryOrder.TestField("Cost Is Adjusted", false);

        // Record cost values after first adjustment
        VerifyItemCost(Item."No.", 200, 100); // 1 order * 200 actual cost (fully adjusted)

        // Second adjustment on first production order (already adjusted)
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine[1]."Prod. Order No.", ProdOrderLine[1]."Line No.");
        InventoryAdjmtEntryOrder.SetRecFilter();
        InventoryAdjmtEntryOrder.RunCostAdjustment(InventoryAdjmtEntryOrder);

        // Verify cost values haven't changed after second adjustment
        VerifyItemCost(Item."No.", 200, 100);

        // Verify orders' adjustment status remains unchanged
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine[1]."Prod. Order No.", ProdOrderLine[1]."Line No.");
        InventoryAdjmtEntryOrder.TestField("Cost Is Adjusted", true);
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine[2]."Prod. Order No.", ProdOrderLine[2]."Line No.");
        InventoryAdjmtEntryOrder.TestField("Cost Is Adjusted", false);

        // Verify item not fully adjusted since second order is still unadjusted
        Item.Find();
        Item.TestField("Cost is Adjusted", false);
    end;

    [Test]
    procedure T25_AdjustSelectedOrders_Unfinished()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        Initialize();

        // Create item with FIFO costing
        CreateItem(Item, Item."Costing Method"::FIFO);

        // Create production order but don't finish it
        CreateProductionOrder(ProductionOrder, Item."No.", 10);
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder);
        PostProductionConsumptionAndOutput(ProdOrderLine, 10, 20.0);
        // Deliberately NOT changing status to Finished

        // Attempt to adjust the unfinished production order
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        InventoryAdjmtEntryOrder.SetRecFilter();
        InventoryAdjmtEntryOrder.RunCostAdjustment(InventoryAdjmtEntryOrder);

        // Verify the production order is not adjusted
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        InventoryAdjmtEntryOrder.TestField("Cost Is Adjusted", false);

        // The item is adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted");

        // Verify that actual cost remains zero (not adjusted) and expected cost is present
        VerifyItemCost(Item."No.", 0, 100);

        // Now finish the production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrderLine."Prod. Order No.");

        // Adjust the production order again
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        InventoryAdjmtEntryOrder.SetRecFilter();
        InventoryAdjmtEntryOrder.RunCostAdjustment(InventoryAdjmtEntryOrder);

        // Verify the production order is adjusted
        InventoryAdjmtEntryOrder.Get("Inventory Order Type"::Production, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        InventoryAdjmtEntryOrder.TestField("Cost Is Adjusted", true);

        VerifyItemCost(Item."No.", 200, 0);
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", 10);
        Item.Validate("Last Direct Cost", 10);
        Item.Modify(true);
    end;

    local procedure CreateProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal);
    begin
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
    end;

    local procedure FindFirstProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; UnitAmount: Decimal; PostingDate: Date)
    begin
        PostItemJournalLine(ItemNo, '', Quantity, UnitAmount, PostingDate);
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UnitAmount: Decimal; PostingDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostProductionConsumptionAndOutput(ProdOrderLine: Record "Prod. Order Line"; Quantity: Decimal; UnitCost: Decimal)
    var
        ComponentItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        CreateItem(ComponentItem, ComponentItem."Costing Method"::FIFO);
        PostItemJournalLine(ComponentItem."No.", Quantity, UnitCost, WorkDate());

        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ComponentItem."No.");
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Validate("Unit Cost", UnitCost);
        ProdOrderComponent.Modify(true);
        LibraryManufacturing.PostConsumption(ProdOrderLine, ComponentItem, '', '', Quantity, WorkDate(), UnitCost);

        LibraryManufacturing.PostOutput(ProdOrderLine, Quantity, WorkDate(), 0);
    end;

    local procedure SetManualCostAdjustmentParameters()
    begin
        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAutomaticCostPosting(false);
        LibraryInventory.SetAverageCostSetup(
          "Average Cost Calculation Type"::"Item & Location & Variant", "Average Cost Period Type"::Day);
    end;

    local procedure VerifyItemCost(ItemNo: Code[20]; ActualCost: Decimal; ExpectedCost: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        ValueEntry.TestField("Cost Amount (Actual)", ActualCost);
        ValueEntry.TestField("Cost Amount (Expected)", ExpectedCost);
    end;
}