codeunit 137611 "SCM Costing Rollup Sev 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        IsInitialized: Boolean;
        InsufficientQuantityErr: Label 'You have insufficient quantity of Item';
        CannotApplyErr: Label 'You cannot apply';
        SelectADimensionValueErr: Label 'Select a Dimension Value';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';

    [Test]
    [Scope('OnPrem')]
    procedure PS40530()
    var
        FinalItem: Record Item;
        CompItem: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ToLocation: Record Location;
        Qty: Decimal;
    begin
        Initialize();
        Qty := 1;

        // setup production
        SetupProduction(
          FinalItem, CompItem, ProdOrderLine, '', FinalItem."Costing Method"::FIFO, CompItem."Costing Method"::FIFO, WorkDate(), Qty, Qty);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(FinalItem."No." + '|' + CompItem."No.", '');

        // Post output.
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, WorkDate(), Qty, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // create location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);

        // Reclassify into second location.
        LibraryInventory.PostReclassificationJournalLine(FinalItem, WorkDate(), '', ToLocation.Code, '', '', '', Qty);

        // fill inventory with component
        CreateInventory(CompItem, 10, '', 0);

        asserterror CreateAndPostConsumption(FinalItem, ProdOrderLine, ToLocation);
        Assert.ExpectedError(InsufficientQuantityErr);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PS52326()
    var
        OldInventorySetup: Record "Inventory Setup";
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        Initialize();
        OldInventorySetup.Get();
        SetInventorySetup(
          OldInventorySetup, true,
          OldInventorySetup."Automatic Cost Posting",
          OldInventorySetup."Expected Cost Posting to G/L", OldInventorySetup."Automatic Cost Adjustment");

        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, 0, 0, 0, '');

        // create locations
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);

        // fill inventory with item
        CreateInventory(Item, 142.7, FromLocation.Code, 8.458);

        // create and post transfer
        CreateAndPostTransfer(FromLocation, ToLocation, Item, 132.5);

        // Post Receipt of negative purchase
        PostNegativePurchase(PurchaseHeader, Item, FromLocation, -28.7);

        // undo purchase
        PostUndoReceipt(PurchaseHeader, Item);

        // Adjustment
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Sales order for item and ToLocation
        LibrarySales.PostSalesOrder(SalesHeader, Item, ToLocation.Code, '', 3.9, WorkDate(), 0, true, true);

        // Adjustment
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify adjustment
        LibraryCosting.CheckAdjustment(Item);

        // restore Inventory Setup
        SetInventorySetup(
          OldInventorySetup, false,
          OldInventorySetup."Automatic Cost Posting",
          OldInventorySetup."Expected Cost Posting to G/L", OldInventorySetup."Automatic Cost Adjustment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PS52587()
    var
        OldInventorySetup: Record "Inventory Setup";
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        PostingDate: Date;
    begin
        Initialize();
        OldInventorySetup.Get();
        SetInventorySetup(OldInventorySetup, true, false, false, OldInventorySetup."Automatic Cost Adjustment"::Never);
        LibraryInventory.CreateItem(Item, Item."Costing Method"::FIFO, 0, 0, 0, '');

        // create location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');

        PostingDate := WorkDate();

        // fill inventory with item
        CreateInventory(Item, 10, Location.Code, 5);
        WorkDate := PostingDate + 1;
        CreateInventory(Item, 10, Location.Code, 0);

        // Sales order - shipment only
        WorkDate := PostingDate + 2;
        LibrarySales.PostSalesOrder(SalesHeader, Item, Location.Code, '', 15, WorkDate(), 0, true, false);

        // revaluation remaining quantity
        WorkDate := PostingDate + 3;
        RevaluateItem(Item, WorkDate(), 5);

        // invoice sales through invoice and Get Shipment
        WorkDate := PostingDate + 4;
        PostInvoiceOfShipment(SalesHeader, Item, WorkDate());

        // Sales after revaluation
        WorkDate := PostingDate + 5;
        Clear(SalesHeader);
        LibrarySales.PostSalesOrder(SalesHeader, Item, Location.Code, '', 3, WorkDate(), 0, true, true);

        // Adjustment
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify adjustment
        LibraryCosting.CheckAdjustment(Item);

        // restore Inventory Setup
        SetInventorySetup(
          OldInventorySetup, false,
          OldInventorySetup."Automatic Cost Posting",
          OldInventorySetup."Expected Cost Posting to G/L", OldInventorySetup."Automatic Cost Adjustment");

        WorkDate := PostingDate;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF207811()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        ItemTrackingCode: Record "Item Tracking Code";
        ExactCostReversing: Boolean;
        Qty: Decimal;
    begin
        Initialize();
        Qty := 102.53;

        SalesReceivablesSetup.Get();
        ExactCostReversing := SalesReceivablesSetup."Exact Cost Reversing Mandatory";
        SetSalesSetup(SalesReceivablesSetup, true);

        // item tracking for item - lot tracking only
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateItem(Item, Item."Costing Method"::FIFO, 0, 0, 0, ItemTrackingCode.Code);

        // create location, customer
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibrarySales.CreateCustomer(Customer);

        // setup of VAT posting group for item according to customer
        SetVATPostingGroupInItem(Item, Customer);

        // create inventory for item
        CreateInventoryWithIT(Item, Qty, Item."No.", Location.Code);

        // special sales
        PostSalesWithDiscount(SalesHeader, Item, Location, Customer, Qty);

        // Sales Credit Memo
        CreateAndPostSalesCreditMemo(SalesHeader, Customer);

        LibraryCosting.CheckAdjustment(Item);

        SetSalesSetup(SalesReceivablesSetup, ExactCostReversing);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF217370()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ItemOne: Record Item;
        ItemTwo: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        ExactCostReversing: Boolean;
    begin
        Initialize();

        PurchasesPayablesSetup.Get();
        ExactCostReversing := PurchasesPayablesSetup."Exact Cost Reversing Mandatory";
        SetPurchaseSetup(PurchasesPayablesSetup, true);

        // create 2 items, one location
        LibraryInventory.CreateItem(ItemOne, ItemOne."Costing Method"::FIFO, 0, 0, 0, '');
        LibraryInventory.CreateItem(ItemTwo, ItemTwo."Costing Method"::FIFO, 0, 0, 0, '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // Create Purchase Order for 2 items, receive
        CreateAndReceivePurchOrderWith2Items(PurchaseHeader, ItemOne, ItemTwo, Location, 1, 100, 1, 100);
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");

        // Create Purchase Invoice for previous receipt and post it
        CreateAndPostPurchInvoice(Vendor);

        // Create Purchase Return Order for previous receipt
        CreateAndShipPurchReturnOrder(Vendor, ItemTwo, PurchaseHeader."No.");

        // Create Purchase Credit Memo for previous shipment
        CreateAndPostPurchCreditMemo(Vendor);

        // restore purchase setup
        SetPurchaseSetup(PurchasesPayablesSetup, ExactCostReversing);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF217583()
    var
        ArrayOfItem: array[3] of Record Item;
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        Initialize();

        // create 3 items with Item Tracking and BOM between
        ProductionSetupFor217583(ArrayOfItem);

        // create inventory for components
        Quantity := 1000;
        CreateInventoryWithIT(ArrayOfItem[1], Quantity, ArrayOfItem[1]."No.", '');
        CreateInventoryWithIT(ArrayOfItem[2], Quantity, ArrayOfItem[2]."No.", '');

        // Create Released Production Order
        CreateAndPostRelProdOrder(ProductionOrder, ArrayOfItem, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF329160()
    var
        OldInventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        UnitCost: Decimal;
        Quantity: Decimal;
        FirstOutputEntryNo: Integer;
        NegativeOutputEntryNo: Integer;
    begin
        Initialize();
        OldInventorySetup.Get();
        SetInventorySetup(OldInventorySetup, true, false, false, OldInventorySetup."Automatic Cost Adjustment"::Never);

        // Setup Item: Unit Cost = Last Direct Cost
        UnitCost := 25;
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, UnitCost, 0, 0, '');
        Item."Last Direct Cost" := UnitCost;
        Item.Modify();

        // Setup Production Order
        Quantity := 10;
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, false, false, false);

        // Post output for production with same quantity twice
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        LibraryManufacturing.CreateOutputJournalLine(ItemJnlBatch, ProdOrderLine, WorkDate(), Quantity, UnitCost);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
        FirstOutputEntryNo := FindLastItemLedgEntry();
        LibraryManufacturing.CreateOutputJournalLine(ItemJnlBatch, ProdOrderLine, WorkDate(), Quantity, UnitCost);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        // Post negative output for production - same quantity applied to first output entry
        LibraryManufacturing.CreateOutputJournalLine(ItemJnlBatch, ProdOrderLine, WorkDate(), -Quantity, UnitCost);
        FindLastJournalLine(ItemJnlBatch, ItemJnlLine);
        ItemJnlLine."Applies-to Entry" := FirstOutputEntryNo;
        ItemJnlLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        // Add Item as component to production order
        AddComponentToProd(ProdOrderLine, Item."No.", 1);

        // Post consumption negative quantity applied from entry negative output
        LibraryManufacturing.CreateConsumptionJournalLine(ItemJnlBatch, ProdOrderLine, Item, WorkDate(), '', '', -Quantity, UnitCost);
        FindLastJournalLine(ItemJnlBatch, ItemJnlLine);
        NegativeOutputEntryNo := FindLastItemLedgEntry();
        ItemJnlLine."Applies-from Entry" := NegativeOutputEntryNo;
        ItemJnlLine.Modify();
        asserterror LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        // Verify error and that posting is blocked *)
        Assert.ExpectedError(CannotApplyErr);

        // *) Finish production order and adjust cost - adjust cost was looping when the above step was alowed
        // LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder,ProductionOrder.Status::Finished,WORKDATE,FALSE);
        // LibraryCosting.AdjustCostItemEntries(Item."No.",'');

        // Restore Inventory Setup
        SetInventorySetup(
          OldInventorySetup, false,
          OldInventorySetup."Automatic Cost Posting",
          OldInventorySetup."Expected Cost Posting to G/L", OldInventorySetup."Automatic Cost Adjustment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF245349()
    var
        OldInventorySetup: Record "Inventory Setup";
        Location: Record Location;
        Dimension: Record Dimension;
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        DefaultDimension: Record "Default Dimension";
        InvtPostingGroupCode: Code[20];
        AccountNo: Code[20];
    begin
        Initialize();
        OldInventorySetup.Get();
        SetInventorySetup(OldInventorySetup, true, true, false, OldInventorySetup."Automatic Cost Adjustment"::Always);

        // create location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // Setup dimension for inventory account
        SetupDimensionInInventoryAccount(Location.Code, InvtPostingGroupCode, Dimension, AccountNo);

        // create item
        LibraryInventory.CreateItem(Item, Item."Costing Method"::FIFO, 0, 0, 0, '');
        Item.Validate("Inventory Posting Group", InvtPostingGroupCode);
        Item.Modify();

        // posting Sales - the first posting should show error

        asserterror
          CreateAndPostSalesWithDimensions(Item, Dimension, Location.Code, false);
        Assert.ExpectedError(SelectADimensionValueErr);
        ClearLastError();

        // now we will post sales with dimension so it should pass
        CreateAndPostSalesWithDimensions(Item, Dimension, Location.Code, true);

        // Creating Phys. Inventory Journal
        CreatePhysInvtJournal(ItemJournalBatch, ItemJournalLine, Item);

        // the first posting should show error
        asserterror LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        Assert.ExpectedError(SelectADimensionValueErr);
        ClearLastError();

        // set dimension to Phys. Inventory
        AddDimensionToPhysInvt(ItemJournalLine, Dimension);

        // Validation - posting has to be successful
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // restore Inventory Setup
        SetInventorySetup(
          OldInventorySetup, false,
          OldInventorySetup."Automatic Cost Posting",
          OldInventorySetup."Expected Cost Posting to G/L", OldInventorySetup."Automatic Cost Adjustment");
        // restore dimension setup
        DefaultDimension.Init();
        DefaultDimension.Validate("Table ID", DATABASE::"G/L Account");
        DefaultDimension.Validate("No.", AccountNo);
        DefaultDimension.Validate("Dimension Code", Dimension.Code);
        DefaultDimension.Delete();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Rollup Sev 1");
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Rollup Sev 1");

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Rollup Sev 1");
    end;

    local procedure SetupProduction(var ParentItem: Record Item; var CompItem: Record Item; var ProdOrderLine: Record "Prod. Order Line"; LocationCode: Code[10]; ParentCostingMethod: Enum "Costing Method"; CompCostingMethod: Enum "Costing Method"; ProdOrderDate: Date; ProducedQty: Decimal; QtyPer: Decimal)
    var
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Setup produced and component item.
        LibraryInventory.CreateItem(ParentItem, ParentCostingMethod, LibraryRandom.RandDec(100, 2), 0, 0, '');
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Modify();

        LibraryInventory.CreateItem(CompItem, CompCostingMethod, LibraryRandom.RandDec(100, 2), 0, 0, '');

        // Setup BOM and Routing.
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ParentItem, CompItem, QtyPer, '');

        // Released production order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem, LocationCode, '', ProducedQty, ProdOrderDate);
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure CreateInventory(Item: Record Item; Quantity: Decimal; LocationCode: Code[10]; UnitAmount: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);

        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, LocationCode, '', WorkDate(),
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, UnitAmount);

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure CreateAndPostConsumption(FinalItem: Record Item; ProdOrderLine: Record "Prod. Order Line"; Location: Record Location)
    var
        ProductionOrder: Record "Production Order";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption);

        ProdOrderComponent.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");

        // run calculation of consumption
        ProductionOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        ConsumptionJournalCalcConsumption(ProductionOrder, ProdOrderComponent, ItemJournalBatch, WorkDate(), 0);

        // add a new line with for item manually
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, FinalItem, Location.Code, '', WorkDate(), ItemJournalLine."Entry Type"::"Negative Adjmt.", 1, 0);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure ConsumptionJournalCalcConsumption(var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component"; ItemJournalBatch: Record "Item Journal Batch"; PostingDate: Date; CalcBasedOn: Option)
    var
        ProductionOrder2: Record "Production Order";
        ProdOrderComponent2: Record "Prod. Order Component";
        CalcConsumption: Report "Calc. Consumption";
    begin
        Commit();
        CalcConsumption.InitializeRequest(PostingDate, CalcBasedOn);
        CalcConsumption.SetTemplateAndBatchName(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // settings filters on the Prod Order
        if ProductionOrder.HasFilter then
            ProductionOrder2.CopyFilters(ProductionOrder)
        else begin
            ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
            ProductionOrder2.SetRange(Status, ProductionOrder.Status);
            ProductionOrder2.SetRange("No.", ProductionOrder."No.");
        end;
        CalcConsumption.SetTableView(ProductionOrder2);

        // settings filters on the Prod Order components
        if ProdOrderComponent.HasFilter then
            ProdOrderComponent2.CopyFilters(ProdOrderComponent)
        else begin
            ProdOrderComponent.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.",
              ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.");
            ProdOrderComponent2.SetRange(Status, ProdOrderComponent.Status);
            ProdOrderComponent2.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
            ProdOrderComponent2.SetRange("Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
            ProdOrderComponent2.SetRange("Line No.", ProdOrderComponent."Line No.");
        end;
        CalcConsumption.SetTableView(ProdOrderComponent2);

        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();
    end;

    local procedure SetInventorySetup(InventorySetup: Record "Inventory Setup"; NewSetup: Boolean; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        SavedInventorySetup: Record "Inventory Setup";
    begin
        if NewSetup then begin
            InventorySetup."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant";
            InventorySetup."Average Cost Period" := InventorySetup."Average Cost Period"::Day;
            InventorySetup."Automatic Cost Posting" := AutomaticCostPosting;
            InventorySetup."Expected Cost Posting to G/L" := ExpectedCostPosting;
            InventorySetup."Automatic Cost Adjustment" := AutomaticCostAdjustment;
        end else begin
            SavedInventorySetup.Get();
            SavedInventorySetup."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type";
            SavedInventorySetup."Average Cost Period" := InventorySetup."Average Cost Period";
            SavedInventorySetup."Automatic Cost Posting" := AutomaticCostPosting;
            SavedInventorySetup."Expected Cost Posting to G/L" := ExpectedCostPosting;
            SavedInventorySetup."Automatic Cost Adjustment" := AutomaticCostAdjustment;
            InventorySetup := SavedInventorySetup;
        end;
        InventorySetup.Modify();
        CODEUNIT.Run(CODEUNIT::"Change Average Cost Setting", InventorySetup);
    end;

    local procedure CreateAndPostTransfer(FromLocation: Record Location; ToLocation: Record Location; Item: Record Item; Qty: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        InTransitLocation: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(InTransitLocation);
        InTransitLocation.Validate("Use As In-Transit", true);
        InTransitLocation.Modify();

        LibraryInventory.CreateAndPostTransferOrder(
          TransferHeader, Item, FromLocation, ToLocation, InTransitLocation, '', Qty, WorkDate(), WorkDate(), true, true);
    end;

    local procedure PostNegativePurchase(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Location: Record Location; Qty: Decimal)
    begin
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, Location.Code, '', Qty, WorkDate(), 0, true, false);
    end;

    local procedure PostUndoReceipt(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
    begin
        PurchRcptLine.SetCurrentKey("Buy-from Vendor No.");
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", Item."No.");
        PurchRcptLine.FindFirst();

        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);
    end;

    local procedure RevaluateItem(var Item: Record Item; RevaluationDate: Date; RevaluationCost: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, Item, RevaluationDate, "Inventory Value Calc. Per"::"Item Ledger Entry", Item."Costing Method" <> Item."Costing Method"::Average,
          Item."Costing Method" <> Item."Costing Method"::Average,
          false, "Inventory Value Calc. Base"::" ", false, '', '');

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", RevaluationCost);
        ItemJournalLine.Modify();

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostInvoiceOfShipment(var SalesHeader: Record "Sales Header"; var Item: Record Item; PostingDate: Date)
    var
        InvoiceSalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        Customer.Get(SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesHeader(InvoiceSalesHeader, InvoiceSalesHeader."Document Type"::Invoice, Customer."No.");
        InvoiceSalesHeader.Validate("Posting Date", PostingDate);
        InvoiceSalesHeader.Modify(true);

        SalesShipmentHeader.SetCurrentKey("Order No.");
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();

        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetRange("No.", Item."No.");
        SalesGetShipment.SetSalesHeader(InvoiceSalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);

        LibrarySales.PostSalesDocument(InvoiceSalesHeader, true, true);
    end;

    local procedure SetSalesSetup(var SalesReceivablesSetup: Record "Sales & Receivables Setup"; NewSetup: Boolean)
    begin
        SalesReceivablesSetup."Exact Cost Reversing Mandatory" := NewSetup;
        SalesReceivablesSetup.Modify();
    end;

    local procedure SetVATPostingGroupInItem(var Item: Record Item; var Customer: Record Customer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst();

        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify();
    end;

    local procedure PostSalesWithDiscount(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Location: Record Location; var Customer: Record Customer; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit Price", 215);
        SalesLine.Validate("Line Discount %", 15);
        SalesLine.Modify(true);

        // Lot No for sales
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', Item."No.", Qty);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesCreditMemo(var SalesHeader: Record "Sales Header"; var Customer: Record Customer)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // Get Posted Document Line to Reverse
        SalesInvoiceLine.SetCurrentKey("Sell-to Customer No.", Type, "Document No.");
        SalesInvoiceLine.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();

        CopyDocumentMgt.SetProperties(false, false, false, false, true, true, false);
        CopyDocumentMgt.CopySalesInvLinesToDoc(SalesHeader, SalesInvoiceLine, LinesNotCopied, MissingExCostRevLink);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure SetPurchaseSetup(var PurchasePayablesSetup: Record "Purchases & Payables Setup"; NewSetup: Boolean)
    begin
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup."Exact Cost Reversing Mandatory" := NewSetup;
        PurchasePayablesSetup.Modify();
    end;

    local procedure CreateAndReceivePurchOrderWith2Items(var PurchaseHeader: Record "Purchase Header"; var ItemOne: Record Item; var ItemTwo: Record Item; var Location: Record Location; QtyOne: Decimal; CostOne: Decimal; QtyTwo: Decimal; CostTwo: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemOne, Location.Code, '', QtyOne, WorkDate(), CostOne);

        // second line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemTwo."No.", QtyTwo);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Direct Unit Cost", CostTwo);
        PurchaseLine.Modify(true);

        // Receive only
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateAndPostPurchInvoice(var Vendor: Record Vendor)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        PurchRcptLine.SetCurrentKey("Buy-from Vendor No.");
        PurchRcptLine.SetRange("Buy-from Vendor No.", Vendor."No.");

        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateAndShipPurchReturnOrder(var Vendor: Record Vendor; var Item: Record Item; PurchaseOrderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");

        // copy document functionality
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters("Purchase Document Type From"::Order, PurchaseOrderNo, false, true);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.RunModal();

        // setting "Appl.-to Entry"
        ItemLedgerEntry.FindLast();
        Assert.AreEqual(Item."No.", ItemLedgerEntry."Item No.", '');

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.Find('+');
        repeat
            PurchaseLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
            PurchaseLine.Modify();
            ItemLedgerEntry."Entry No." -= 1;
        until PurchaseLine.Next(-1) = 0;

        // Ship only
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateAndPostPurchCreditMemo(var Vendor: Record Vendor)
    var
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");

        ReturnShipmentLine.SetCurrentKey("Buy-from Vendor No.");
        ReturnShipmentLine.SetRange("Buy-from Vendor No.", Vendor."No.");

        PurchGetReturnShipments.SetPurchHeader(PurchaseHeader);
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure ProductionSetupFor217583(var Item: array[3] of Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // item tracking for all items - lot tracking only
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // 3 items, the first and seconds are components, the third is final product
        LibraryInventory.CreateItem(Item[1], Item[1]."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2), 0, 0, ItemTrackingCode.Code);
        LibraryInventory.CreateItem(Item[2], Item[2]."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2), 0, 0, ItemTrackingCode.Code);
        LibraryInventory.CreateItem(Item[3], Item[3]."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2), 0, 0, ItemTrackingCode.Code);

        // Setup BOM - 2 components
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[3]."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[2]."No.", 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();

        // update final item
        Item[3].Validate("Replenishment System", Item[3]."Replenishment System"::"Prod. Order");
        Item[3].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[3].Modify();
    end;

    local procedure CreateInventoryWithIT(var Item: Record Item; Quantity: Decimal; LotNo: Code[50]; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, LocationCode, '', WorkDate(),
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, 1);

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, Quantity);

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure CreateAndPostRelProdOrder(var ProductionOrder: Record "Production Order"; var ArrayOfItem: array[3] of Record Item; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // create and refresh production order
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ArrayOfItem[3], '', '', Quantity, WorkDate());
        FindProdOrderLine(ProdOrderLine, ProductionOrder);

        // post consumption of component 1
        CreateAndPostConsumptionWithIT(ProdOrderLine, ArrayOfItem[1]."No.", ArrayOfItem[1]."No.", Quantity);

        // we need to know ILE created by posting output
        ItemLedgerEntry.FindLast();

        // post output according to scenario - positive, negative, positive output split into many output lines
        CreateAndPostOutputWithIT(ProdOrderLine, 0);
        CreateAndPostOutputWithIT(ProdOrderLine, ItemLedgerEntry."Entry No." + 1);
        CreateAndPostOutputWithIT(ProdOrderLine, 0);

        // post consumption of component 2
        CreateAndPostConsumptionWithIT(ProdOrderLine, ArrayOfItem[2]."No.", ArrayOfItem[2]."No.", Quantity);
    end;

    local procedure CreateAndPostConsumptionWithIT(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    var
        ProductionOrder: Record "Production Order";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption);

        ProdOrderComponent.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.SetRange("Item No.", ItemNo);

        // run calculation of consumption for given item
        ProductionOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        ConsumptionJournalCalcConsumption(ProductionOrder, ProdOrderComponent, ItemJournalBatch, WorkDate(), 1);

        FindLastJournalLine(ItemJournalBatch, ItemJournalLine);

        // add item tracking
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, Quantity);

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure CreateAndPostOutputWithIT(var ProdOrderLine: Record "Prod. Order Line"; ApplyEntryNo: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        LineNo: Integer;
        i: Integer;
        Quantity: Decimal;
    begin
        if ApplyEntryNo = 0 then begin
            LibraryManufacturing.OutputJournalExplodeOrderLineRouting(ItemJournalBatch, ProdOrderLine, WorkDate());
            Quantity := 9;
        end else begin
            CreateOutputJnlLine(ItemJournalBatch, ProdOrderLine);
            Quantity := -9;
        end;

        FindLastJournalLine(ItemJournalBatch, ItemJournalLine);

        // according to scenario we have to post more output then planned and has to be split into 115 posting lines
        LineNo := ItemJournalLine."Line No.";
        ItemJournalLine.Validate("Output Quantity", Quantity);
        ItemJournalLine.Modify();

        // add item tracking for the first line
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', ItemJournalLine."Item No.", Quantity);
        if ApplyEntryNo > 0 then begin
            // posting reverse output
            ReservationEntry."Appl.-to Item Entry" := ApplyEntryNo;
            ReservationEntry.Modify();
        end;

        // creating the remaining ouput lines
        for i := 1 to 114 do begin
            LineNo += 10000;
            ItemJournalLine."Line No." := LineNo;
            ItemJournalLine.Insert();

            // add item tracking for the new line line
            ReservationEntry."Source Ref. No." := LineNo;
            ReservationEntry."Entry No." += 1;
            if ApplyEntryNo > 0 then begin
                // posting reverse output
                ApplyEntryNo += 1;
                ReservationEntry."Appl.-to Item Entry" := ApplyEntryNo;
            end;
            ReservationEntry.Insert();
        end;

        // posting output
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure AddComponentToProd(ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; QtyPer: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
        LastLineNo: Integer;
    begin
        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        if ProdOrderComp.FindLast() then
            LastLineNo := ProdOrderComp."Line No.";

        ProdOrderComp.Init();
        ProdOrderComp.Status := ProdOrderLine.Status;
        ProdOrderComp."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        ProdOrderComp."Prod. Order Line No." := ProdOrderLine."Line No.";
        ProdOrderComp."Line No." := LastLineNo + 10000;
        ProdOrderComp.Validate("Item No.", ItemNo);
        ProdOrderComp.Validate("Quantity per", QtyPer);
        ProdOrderComp.Insert();
    end;

    local procedure FindLastJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.FindLast();
    end;

    local procedure FindLastItemLedgEntry(): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.FindLast();
        exit(ItemLedgEntry."Entry No.");
    end;

    local procedure CreateOutputJnlLine(var ItemJournalBatch: Record "Item Journal Batch"; var ProdOrderLine: Record "Prod. Order Line")
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Output);

        Item.Get(ProdOrderLine."Item No.");
        LibraryInventory.MakeItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, WorkDate(), ItemJournalLine."Entry Type"::"Positive Adjmt.", 0);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Output);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJournalLine.Validate("Item No.", ProdOrderLine."Item No.");
        ItemJournalLine.SetUpNewLine(ItemJournalLine);
        ItemJournalLine.Insert();
    end;

    local procedure SetupDimensionInInventoryAccount(LocationCode: Code[10]; var InvtPostingGroupCode: Code[20]; var Dimension: Record Dimension; var AccountNo: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();

        InventoryPostingSetup.SetRange("Location Code", LocationCode);
        InventoryPostingSetup.FindFirst();

        InvtPostingGroupCode := InventoryPostingSetup."Invt. Posting Group Code";
        AccountNo := InventoryPostingSetup."Inventory Account";

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"G/L Account", AccountNo);
        DefaultDimension.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 2 Code");
        DefaultDimension.SetRange("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        if not DefaultDimension.FindFirst() then begin
            LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
            LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"G/L Account", AccountNo,
              GeneralLedgerSetup."Global Dimension 2 Code", DimensionValue.Code);
            DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
            DefaultDimension.Modify();
        end;
        Dimension.Get(DefaultDimension."Dimension Code");
    end;

    local procedure CreateAndPostSalesWithDimensions(var Item: Record Item; var Dimension: Record Dimension; LocationCode: Code[10]; AddDimensions: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
    begin
        // create Sales order
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, LocationCode, '', 4, WorkDate(), 10);

        // add dimension to sales line
        if AddDimensions then begin
            DimensionValue.SetRange("Dimension Code", Dimension.Code);
            DimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
            DimensionValue.FindFirst();

            SalesLine.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
            SalesLine.Modify();
        end;

        // post Ship + Invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePhysInvtJournal(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item)
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::"Phys. Inventory");
        LibraryInventory.MakeItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, WorkDate(), ItemJournalLine."Entry Type"::"Positive Adjmt.", 0);

        Commit();  // Commit required before running this Report.
        Item.SetRange("No.", Item."No.");
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, WorkDate(), false, false);

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.FindLast();
        ItemJournalLine.Validate("Qty. (Phys. Inventory)", 0);
        ItemJournalLine.Validate("Unit Amount", 7.5);
        ItemJournalLine.Modify();
    end;

    local procedure AddDimensionToPhysInvt(var ItemJournalLine: Record "Item Journal Line"; var Dimension: Record Dimension)
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.FindLast();

        ItemJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        ItemJournalLine.Insert();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;
}

