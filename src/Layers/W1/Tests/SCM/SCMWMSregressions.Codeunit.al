codeunit 137005 "SCM WMS regressions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        Initialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Initialized: Boolean;
        ExpErrorActualErrorConst: Label 'Expected error: ''%1''\Actual error: ''%2''.';
        EmptyStringConst: Label ' ';
        NoPutAwayCreatedForPrdOrdConst: Label 'No put-away created for the production order!';
        PutAwayNotDeletedConst: Label 'Put-away was not deleted! Most probably it was not successfully registered.';
        PickNotFoundInHistoryConst: Label 'Pick not in history! Post failed!';
        NoPickCreatedForProdOrdConst: Label 'No put-away created for the production order!';
        PickNotDeletedConst: Label 'Put away was not deleted! Most probably it was not successfully registered.';
        ProdOrderLinesNotCreatedConst: Label 'Production order lines not created after refresh!';
        ProdOrdCompLinesNotCrtdConst: Label 'Production order component lines not created after refresh!';
        NoOfPickCreatedConst: Label 'Number of Invt. Pick activities created: 1 out of a total of 1.';
        InboundWhseReqCreatedConst: Label 'Inbound Whse. Requests are created.';
        NoOfPutAwayCreatedConst: Label 'Number of Invt. Put-away activities created: 1 out of a total of 1.';
        KGConst: Label 'KG';
        PutAwayNotFoundInHistConst: Label 'Put Away not in history! Post failed!';
        WrongNoOfTermOperationsErr: Label 'Actual number of termination processes in prod. order %1 route %2  is 0.', Comment = '%1 = production order no., %2 = routing no.';
        NoTerminationProcessesErr: Label 'On the last operation, the Next Operation No. field must be empty.';

    local procedure Initialize()
    var
        WarehouseSetup: Record "Warehouse Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM WMS regressions");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM WMS regressions");

        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        WarehouseSetup.Get();
        WarehouseSetup."Whse. Ship Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify(true);

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM WMS regressions");
    end;

    local procedure CreateItemHierarchy(var ProdBOMHeader: Record "Production BOM Header"; var ParentItem: Record Item; var ChildItem: Record Item; QuantityPer: Integer)
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        if ChildItem."No." = '' then
            LibraryInventory.CreateItem(ChildItem);
        if ParentItem."No." = '' then
            LibraryInventory.CreateItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Modify(true);

        if ProdBOMHeader."No." = '' then
            LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeader, ParentItem."Base Unit of Measure")
        else begin
            ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::New);
            ProdBOMHeader.Modify(true);
        end;

        // Create the BOM line - or change qty if exist
        ProdBOMLine.SetRange("Production BOM No.", ProdBOMHeader."No.");
        ProdBOMLine.SetRange("Version Code", '');
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        ProdBOMLine.SetRange("No.", ChildItem."No.");
        if not ProdBOMLine.FindFirst() then
            LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeader, ProdBOMLine, '', ProdBOMLine.Type::Item, ChildItem."No.", QuantityPer)
        else begin
            ProdBOMLine.Validate("Quantity per", QuantityPer);
            ProdBOMLine.Modify(true);
        end;

        // Add the BOM to the parent item
        ParentItem.Validate("Production BOM No.", ProdBOMHeader."No.");
        ParentItem.Modify(true);

        // Certify the BOM
        ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
        ProdBOMHeader.Modify(true);

        // Reload the items as they might change in the statement above
        ParentItem.Get(ParentItem."No.");
        ChildItem.Get(ChildItem."No.");
    end;

    [Test]
    [HandlerFunctions('HNDLChgQtyOnCompLinesAndPick')]
    [Scope('OnPrem')]
    procedure ChangeQtyOnCompLinesAndPick()
    var
        Location: Record Location;
        ItemUOM: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ProdBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseRequest: Record "Warehouse Request";
        Assert: Codeunit Assert;
    begin
        // [FEATURE] [Warehouse] [Pick] [Production Order]
        // This is implementation for Scenario 1, bug 40394 from "Navision Corsica" database

        Initialize();

        // Step 1 - Create item hiercarchy: BOM with hierachy: PARENT and CHILD
        // Add a new UOM to child item = KG
        CreateItemHierarchy(ProdBOMHeader, ParentItem, ChildItem, LibraryRandom.RandInt(10));
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ChildItem."No.", KGConst, 3);

        // Step 2 - Create location with require pick and require put-away
        CreatePickPutAwayLocation(Location);

        // Step 3 - Add 1000 PCS of child item into inventory by posting item journal into created location
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          ChildItem."No.", 1000);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // Step 4 - Create released production order for new item and refresh it
        CreateReleasedProdOrderAndRefresh(ProductionOrder, ParentItem, Location.Code, LibraryRandom.RandInt(10));

        // Step 5 - change the UOM to KG on the component lines
        ChangeUOMOnComponentLines(ProductionOrder, KGConst);

        // Step 6 - create the inventory pick
        WarehouseRequest.SetFilter("Source Document", '%1|%2',
          WarehouseRequest."Source Document"::"Prod. Consumption",
          WarehouseRequest."Source Document"::"Prod. Output");
        WarehouseRequest.SetRange("Source No.", ProductionOrder."No.");
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // Step 7 - autofill qty to handle and post pick
        Assert.IsTrue(FindAndSelInvActvOnSrcNoAndLoc(WarehouseActivityHeader,
            WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", Location.Code),
          NoPutAwayCreatedForPrdOrdConst);

        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // Step 8 - verify that the pick has been posted - it has been deleted
        Assert.IsFalse(FindAndSelInvActvOnSrcNoAndLoc(WarehouseActivityHeader,
            WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", Location.Code),
          PutAwayNotDeletedConst);

        // Step 9 - Verify that pick has been posted - in history
        Assert.IsTrue(
          FindAndSelPstPickOnSrcNoAndLoc(PostedInvtPickHeader,
            PostedInvtPickHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", Location.Code),
          PickNotFoundInHistoryConst);
    end;

    [Test]
    [HandlerFunctions('HNDLChgQtyOnProdLinesAndPAway')]
    [Scope('OnPrem')]
    procedure ChangeQtyOnProdLinesAndPutAway()
    var
        Location: Record Location;
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
        WarehouseRequest: Record "Warehouse Request";
        Assert: Codeunit Assert;
    begin
        // [FEATURE] [Warehouse] [Put-Away] [Production Order] [UOM]
        // This is implementation for Scenario 2, bug 40394 from "Navision Corsica" database

        Initialize();

        // SCENARIO 2

        // Step 1 - Create item with base UOM=PCS and additional UOM=KG
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", KGConst, 3);

        // Step 2 - Create location with require pick and require put-away
        CreatePickPutAwayLocation(Location);

        // Step 3 - Create released production order for new item and refresh it
        CreateReleasedProdOrderAndRefresh(ProductionOrder, Item, Location.Code, LibraryRandom.RandInt(10));

        // Step 4 - change the UOM to KG on the production line
        ChangeUOMOnProdLine(ProductionOrder, KGConst);

        // Step 5 - Create the inbound whse req for the PO
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);

        // Step 6 - create the inventory put-away
        WarehouseRequest.SetFilter("Source Document", '%1|%2',
          WarehouseRequest."Source Document"::"Prod. Consumption",
          WarehouseRequest."Source Document"::"Prod. Output");
        WarehouseRequest.SetRange("Source No.", ProductionOrder."No.");
        LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, true, false, false);

        // Step 7 - autofill qty to handle and post put-away
        Assert.IsTrue(FindAndSelInvActvOnSrcNoAndLoc(WarehouseActivityHeader,
            WarehouseActivityHeader."Source Document"::"Prod. Output", ProductionOrder."No.", Location.Code),
          NoPickCreatedForProdOrdConst);

        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // Step 8 - verify that the put-away has been posted - it has been deleted
        Assert.IsFalse(FindAndSelInvActvOnSrcNoAndLoc(WarehouseActivityHeader,
            WarehouseActivityHeader."Source Document"::"Prod. Output", ProductionOrder."No.", Location.Code),
          PickNotDeletedConst);

        // Step 9 - Verify that put-away has been posted - in history
        Assert.IsTrue(
          FindAndSelPostPAwOnSrcNoAndLoc(PostedInvtPutAwayHeader,
            PostedInvtPutAwayHeader."Source Document"::"Prod. Output", ProductionOrder."No.", Location.Code),
          PutAwayNotFoundInHistConst);
    end;

    [Test]
    [HandlerFunctions('HNDLChgQtyOnProdLinesAndPAway')]
    [Scope('OnPrem')]
    procedure PostPutAwayFromProdOrderWithWrongRoutingFails()
    var
        Location: Record Location;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Production] [Routing] [Production Order Routing Line]
        // [SCENARIO 376980] Put-away from production order output cannot be posted if the source prod. order's routing has setup errors

        Initialize();

        CreatePickPutAwayLocation(Location);

        // [GIVEN] Create and certify a serial production routing "R"
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenter."No.");
        CertifyRouting(RoutingHeader);

        // [GIVEN] Create item with routing "R"
        CreateItemWithRouting(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh production order
        CreateReleasedProdOrderAndRefresh(ProductionOrder, Item, Location.Code, LibraryRandom.RandInt(100));

        // [GIVEN] Update the last production routing line: set "Next Operation No." to a non-existing operation no.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine."Next Operation No." := LibraryUtility.GenerateGUID();
        ProdOrderRoutingLine.Modify();

        // [WHEN] Create and post put-away from production order
        asserterror CreateAndPostPutAwayFromProdOrder(ProductionOrder);

        // [THEN] Error: production order routing has no trerminating operation
        Assert.ExpectedError(
          StrSubstNo(WrongNoOfTermOperationsErr, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing No."));
    end;

    [Test]
    [HandlerFunctions('HNDLChgQtyOnProdLinesAndPAway')]
    [Scope('OnPrem')]
    procedure PostPutAwayFromProdOrderWithParallelRoutingSucceeds()
    var
        Location: Record Location;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[2] of Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Production] [Routing] [Production Order Routing Line]
        // [SCENARIO 376980] Put-away from production order should be posted if the terminating operation in the routing is the first operaton in the list
        Initialize();

        // [GIVEN] Create a parallel production routing "R" with 2 operatioins "1" and "2"
        CreatePickPutAwayLocation(Location);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine[1], '', LibraryUtility.GenerateGUID(), RoutingLine[1].Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine[2], '', LibraryUtility.GenerateGUID(), RoutingLine[2].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Set operation "2" to be the starting routing operation, "1" - terminating operation
        RoutingLine[1]."Previous Operation No." := RoutingLine[2]."Operation No.";
        RoutingLine[1].Modify();
        RoutingLine[2]."Next Operation No." := RoutingLine[1]."Operation No.";
        RoutingLine[2].Modify();

        CertifyRouting(RoutingHeader);

        // [GIVEN] Create item with routing "R", create and refresh production order
        CreateItemWithRouting(Item, RoutingHeader."No.");
        CreateReleasedProdOrderAndRefresh(ProductionOrder, Item, Location.Code, LibraryRandom.RandInt(100));

        // [WHEN] Create and post put-away from production order
        CreateAndPostPutAwayFromProdOrder(ProductionOrder);

        // [THEN] Output item ledger entry is created
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckProdOrderRoutingDoNotExcludeFinishedLines()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRouteManagement: Codeunit "Prod. Order Route Management";
    begin
        // [FEATURE] [Production] [Routing]
        // [SCEARIO 381546] Function Check in codeunit 99000772 Prod. Order Route Management should not throw errors when verifying a route with terminating operation finished

        // [GIVEN] Production order with routing
        CreateProductionOrderWithNewItem(ProductionOrder);

        // [GIVEN] Post output from production order and mark routing line as finished
        PostProdOrderOutput(ProductionOrder);

        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [WHEN] Check production order line
        ProdOrderRouteManagement.Check(ProdOrderLine);

        // [THEN] Verification is completed successfully
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckProdOrderRoutingNextOperationNo()
    var
        Location: Record Location;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Production] [Routing] [Production Order Routing Line]
        // [SCENARIO 291617] Prod Order. Routing Line checks that a termination process exists

        Initialize();

        // [GIVEN] Location created
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create and certify a serial production routing "R"
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenter."No.");
        CertifyRouting(RoutingHeader);

        // [GIVEN] Create item with routing "R"
        CreateItemWithRouting(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh production order
        CreateReleasedProdOrderAndRefresh(ProductionOrder, Item, Location.Code, LibraryRandom.RandInt(100));

        // [WHEN] Update the last production routing line: set "Next Operation No." to a non-existing operation no.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        asserterror ProdOrderRoutingLine.Validate("Next Operation No.", LibraryUtility.GenerateGUID());

        // [THEN] Error: production order routing has no termination operation
        Assert.ExpectedError(NoTerminationProcessesErr);
    end;

    local procedure CertifyRouting(var RoutingHeader: Record "Routing Header")
    begin
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure ChangeUOMOnProdLine(ProductionOrder: Record "Production Order"; UOMCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
        Assert: Codeunit Assert;
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.IsTrue(ProdOrderLine.FindSet(), ProdOrderLinesNotCreatedConst);
        repeat
            ProdOrderLine.Validate("Unit of Measure Code", UOMCode);
            ProdOrderLine.Modify(true);
        until ProdOrderLine.Next() = 0;
    end;

    local procedure ChangeUOMOnComponentLines(ProductionOrder: Record "Production Order"; UOMCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        Assert: Codeunit Assert;
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.IsTrue(ProdOrderComponent.FindSet(), ProdOrdCompLinesNotCrtdConst);
        repeat
            ProdOrderComponent.Validate("Unit of Measure Code", UOMCode);
            ProdOrderComponent.Modify(true);
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure CreateAndPostPutAwayFromProdOrder(ProductionOrder: Record "Production Order")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreatePutAwayFromProdOrder(ProductionOrder);
        FindWarehouseActivity(WarehouseActivityHeader, WarehouseActivityHeader."Source Document"::"Prod. Output", ProductionOrder."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;

    local procedure CreateItemWithNewRouting(var Item: Record Item)
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenter."No.");
        CertifyRouting(RoutingHeader);

        CreateItemWithRouting(Item, RoutingHeader."No.");
    end;

    local procedure CreateItemWithRouting(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Output, ItemJournalTemplate.Name);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ProductionOrder."Source No.", ProductionOrder."No.");

        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();

        ItemJournalLine.Validate("Operation No.", ProdOrderRoutingLine."Operation No.");
        ItemJournalLine.Validate("Output Quantity", ProductionOrder.Quantity);
        ItemJournalLine.Validate(Finished, true);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateReleasedProdOrderAndRefresh(var ProductionOrder: Record "Production Order"; Item: Record Item; LocationCode: Code[10]; Qty: Integer)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        ProductionOrder.SetRange("No.", ProductionOrder."No.");
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreatePickPutAwayLocation(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");
        Location.Validate("Prod. Output Whse. Handling", "Prod. Output Whse. Handling"::"Inventory Put-away");
        Location.Modify(true);
    end;

    local procedure CreateProductionOrderWithNewItem(var ProductionOrder: Record "Production Order")
    var
        Item: Record Item;
    begin
        CreateItemWithNewRouting(Item);
        CreateReleasedProdOrderAndRefresh(ProductionOrder, Item, '', LibraryRandom.RandInt(100));
    end;

    local procedure CreatePutAwayFromProdOrder(ProductionOrder: Record "Production Order")
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);
    end;

    local procedure FindAndSelInvActvOnSrcNoAndLoc(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ActivitySourceType: Enum "Warehouse Activity Source Document"; ActivitySourceNo: Code[20]; LocationCode: Code[10]): Boolean
    begin
        WarehouseActivityHeader.Reset();
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.SetRange("Source Document", ActivitySourceType);
        WarehouseActivityHeader.SetRange("Source No.", ActivitySourceNo);
        exit(WarehouseActivityHeader.FindFirst())
    end;

    local procedure FindAndSelPostPAwOnSrcNoAndLoc(var PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header"; SourceDoc: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10]): Boolean
    begin
        PostedInvtPutAwayHeader.Reset();
        PostedInvtPutAwayHeader.SetRange("Location Code", LocationCode);
        PostedInvtPutAwayHeader.SetRange("Source Document", SourceDoc);
        PostedInvtPutAwayHeader.SetRange("Source No.", SourceNo);
        exit(PostedInvtPutAwayHeader.FindFirst())
    end;

    local procedure FindAndSelPstPickOnSrcNoAndLoc(var PostedInvtPickHeader: Record "Posted Invt. Pick Header"; SourceDoc: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10]): Boolean
    begin
        PostedInvtPickHeader.Reset();
        PostedInvtPickHeader.SetRange("Location Code", LocationCode);
        PostedInvtPickHeader.SetRange("Source Document", SourceDoc);
        PostedInvtPickHeader.SetRange("Source No.", SourceNo);
        exit(PostedInvtPickHeader.FindFirst())
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindWarehouseActivity(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseActivityHeader.SetRange("Source Document", SourceDocument);
        WarehouseActivityHeader.SetRange("Source No.", SourceNo);
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure PostProdOrderOutput(ProductionOrder: Record "Production Order")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalLine(ItemJournalLine, ProductionOrder);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HNDLChgQtyOnCompLinesAndPick(Message: Text[1024])
    begin
        case Message of
            NoOfPickCreatedConst:
                ;
            else
                Error(ExpErrorActualErrorConst, EmptyStringConst, Message);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HNDLChgQtyOnProdLinesAndPAway(Message: Text[1024])
    begin
        case Message of
            InboundWhseReqCreatedConst:
                ;
            NoOfPutAwayCreatedConst:
                ;
            else
                Error(ExpErrorActualErrorConst, EmptyStringConst, Message);
        end;
    end;
}

