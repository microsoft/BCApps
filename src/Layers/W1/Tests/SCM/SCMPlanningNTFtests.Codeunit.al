codeunit 137021 "SCM Planning - NTF tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
        IsInitialized := false;
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        LocationWhite: Record Location;
        LocationOne: Record Location;
        LocationTwo: Record Location;
        LocationThree: Record Location;
        TransitLocation: Record Location;
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        MSG_WHSE_JNL_REG: Label 'Do you want to register the journal lines?';
        MSG_JNL_LINE_REG: Label 'The journal lines were successfully registered.';
        MSG_WHSE_SHIP_CREATED: Label 'Warehouse Shipment Header has been created.';
        ErrorMessageCounter: Integer;
        Text001: Label 'There should be %1 line(s) in the Reservation Entry table with filters %2.';
        Text002: Label 'LN1';
        CustomizedSNTxt: Label 'X0123456789012345678901234567890123456789', Comment = 'No translation needed.';
        GlobalQty: array[2] of Decimal;
        GlobalRemainingSerialNos: array[7] of Code[50];
        GlobalHandlerAction: Integer;
        SuccessfullyPostedTxt: Label 'successfully posted.';
        WrongPostingMsgTxt: Label 'Wrong posting message: %1.';
        WrongSerialNoTxt: Label 'Wrong Serial No. after posting: %1.';
        FilterRequisitionLineMsg: Label 'There is no line within the filter: %1.';
        DaysInMonthFormula: DateFormula;
        PlanningStartDate: DateFormula;
        PlanningEndDate: DateFormula;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Planning - NTF tests");
        LibraryVariableStorage.Clear();

        LibraryApplicationArea.EnableEssentialSetup();

        // Initialize setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Planning - NTF tests");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        GlobalSetup();

        Evaluate(DaysInMonthFormula, Format('<+%1D>', CalcDate('<1M>') - Today));
        Evaluate(PlanningStartDate, '<+23D>');
        Evaluate(PlanningEndDate, '<+11M>');

        DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
        DummyJobsSetup."Apply Usage Link by Default" := false;
        DummyJobsSetup.Modify();
        LibraryJob.SetJobNoSeriesCode();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Planning - NTF tests");
    end;

    local procedure GlobalSetup()
    begin
        LibrarySales.SetOrderNoSeriesInSetup();
        LibrarySales.SetReturnOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();

        LocationSetup(LocationWhite, true, true, false);
        LocationSetup(LocationOne, false, false, false);
        LocationSetup(LocationTwo, false, false, false);
        LocationSetup(LocationThree, false, false, false);
        LocationSetup(TransitLocation, false, false, true);

        ItemJournalSetup();
        LibraryWarehouse.WarehouseJournalSetup(LocationWhite.Code, WarehouseJournalTemplate, WarehouseJournalBatch);

        TransferRoutesSetup();

        DisableWarnings();
    end;

    local procedure ItemSetup(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; SafetyLeadTime: Text[30])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Evaluate(Item."Safety Lead Time", SafetyLeadTime);
        Item.Modify(true);
    end;

    local procedure LFLItemSetup(var Item: Record Item; IncludeInventory: Boolean; ReschedulingPeriod: Text[30]; LotAccumulationPeriod: Text[30]; DampenerPeriod: Text[30]; DampenerQuantity: Integer; SafetyStock: Integer; LotSize: Integer)
    begin
        ItemSetup(Item, Item."Replenishment System"::Purchase, '<0D>');
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Include Inventory", IncludeInventory);
        Evaluate(Item."Lot Accumulation Period", LotAccumulationPeriod);
        Evaluate(Item."Rescheduling Period", ReschedulingPeriod);
        Evaluate(Item."Dampener Period", DampenerPeriod);
        Item.Validate("Dampener Quantity", DampenerQuantity);
        Item.Validate("Safety Stock Quantity", SafetyStock);
        Item.Validate("Lot Size", LotSize);
        Item.Modify(true);
    end;

    local procedure MaxQtyItemSetup(var Item: Record Item; ReorderPoint: Integer; MaximumInventory: Integer; OverflowLevel: Integer; TimeBucket: Text[30]; DampenerQuantity: Integer; SafetyStock: Integer; SafetyLeadTime: Text[30]; LotSize: Integer)
    begin
        ItemSetup(Item, Item."Replenishment System"::Purchase, SafetyLeadTime);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Maximum Qty.");
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Overflow Level", OverflowLevel);
        Evaluate(Item."Time Bucket", TimeBucket);
        Item.Validate("Dampener Quantity", DampenerQuantity);
        Item.Validate("Safety Stock Quantity", SafetyStock);
        Item.Validate("Lot Size", LotSize);
        Item.Modify(true);
    end;

    local procedure FixedReorderQtyItemSetup(var Item: Record Item; ReorderPoint: Integer; ReorderQuantity: Integer; OverflowLevel: Integer; TimeBucket: Text[30]; DampenerQuantity: Integer; SafetyStock: Integer; SafetyLeadTime: Text[30]; LotSize: Integer)
    begin
        ItemSetup(Item, Item."Replenishment System"::Purchase, SafetyLeadTime);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Validate("Overflow Level", OverflowLevel);
        Evaluate(Item."Time Bucket", TimeBucket);
        Item.Validate("Dampener Quantity", DampenerQuantity);
        Item.Validate("Safety Stock Quantity", SafetyStock);
        Item.Validate("Lot Size", LotSize);
        Item.Modify(true);
    end;

    local procedure OrderModifiersSetup(var Item: Record Item; MinOrderQty: Integer; MaxOrderQty: Integer; OrderMultiple: Integer)
    begin
        Item.Validate("Minimum Order Quantity", MinOrderQty);
        Item.Validate("Maximum Order Quantity", MaxOrderQty);
        Item.Validate("Order Multiple", OrderMultiple);
        Item.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure ClearDefaultLocation()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        Clear(WarehouseEmployee);
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.SetRange(Default, true);
        if WarehouseEmployee.FindFirst() then begin
            WarehouseEmployee.Validate(Default, false);
            WarehouseEmployee.Modify(true);
        end;
    end;

    local procedure SetDefaultLocation(LocationCode: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        Clear(WarehouseEmployee);
        WarehouseEmployee.Init();
        WarehouseEmployee.Validate("User ID", UserId);
        WarehouseEmployee.Validate("Location Code", LocationCode);
        WarehouseEmployee.Validate(Default, true);
        WarehouseEmployee.Modify(true);
    end;

    local procedure LocationSetup(var Location: Record Location; Directed: Boolean; BinMandatory: Boolean; UseAsInTransit: Boolean)
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        BinCount: Integer;
    begin
        if Directed then
            LibraryWarehouse.CreateFullWMSLocation(Location, 8)
        else begin
            LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
            // In transit location?
            if UseAsInTransit then begin
                Location.Validate("Use As In-Transit", true);
                Location.Modify(true);
                exit;
            end;

            // Skip validate trigger for bin mandatory to improve performance.
            Location."Bin Mandatory" := BinMandatory;
            Location.Modify(true);

            if BinMandatory then
                for BinCount := 1 to 4 do
                    LibraryWarehouse.CreateBin(Bin, Location.Code, 'bin' + Format(BinCount), '', '');
        end;

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure TransferRoutesSetup()
    begin
        CreateTransferRoutes(LocationWhite, LocationOne);
        CreateTransferRoutes(LocationWhite, LocationTwo);
        CreateTransferRoutes(LocationWhite, LocationThree);
        CreateTransferRoutes(LocationTwo, LocationOne);
        CreateTransferRoutes(LocationThree, LocationOne);
        CreateTransferRoutes(LocationThree, LocationTwo);
    end;

    local procedure CreateTransferRoutes(Location1: Record Location; Location2: Record Location)
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateTransferRoute(TransferRoute, Location1.Code, Location2.Code);
        LibraryWarehouse.CreateTransferRoute(TransferRoute, Location2.Code, Location1.Code);
    end;

    local procedure UpdatePlanningSetup()
    var
        InventorySetup: Record "Inventory Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Components at Location", '');
        ManufacturingSetup.Modify(true);

        InventorySetup.Get();
        InventorySetup.Validate("Current Demand Forecast", '');
        InventorySetup.Validate("Use Forecast on Locations", true);
        InventorySetup.Validate("Combined MPS/MRP Calculation", true);
        Evaluate(InventorySetup."Default Safety Lead Time", '<1D>');
        Evaluate(InventorySetup."Default Dampener Period", '');
        InventorySetup.Validate("Default Dampener %", 0);
        InventorySetup.Validate("Blank Overflow Level", InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        InventorySetup.Modify(true);
    end;

    local procedure DisableWarnings()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateJobAndPlanningLine(var JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line"; No: Code[20]; Quantity: Decimal; UsageLink: Boolean)
    begin
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, JobPlanningLine."Line Type"::Budget, JobTask, No, Quantity, UsageLink);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; LineType: Enum "Job Planning Line Line Type"; JobTask: Record "Job Task"; No: Code[20]; Quantity: Decimal; UsageLink: Boolean)
    begin
        LibraryJob.CreateJobPlanningLine(LineType, LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", No);
        JobPlanningLine.Validate("Planning Date", WorkDate());
        JobPlanningLine.Validate("Usage Link", UsageLink);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateSaleDocType(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; Item: Record Item; SalesQty: Integer; ShipmentDate: Date; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocumentType, '', Item."No.", SalesQty, LocationCode, ShipmentDate);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; Item: Record Item; SalesQty: Integer; ShipmentDate: Date; LocationCode: Code[10])
    begin
        CreateSaleDocType(SalesHeader, SalesHeader."Document Type"::Order, Item, SalesQty, ShipmentDate, LocationCode);
    end;

    local procedure CreateSalesReturnOrder(var SalesHeader: Record "Sales Header"; Item: Record Item; SalesQty: Integer; ShipmentDate: Date; LocationCode: Code[10])
    begin
        CreateSaleDocType(SalesHeader, SalesHeader."Document Type"::"Return Order", Item, SalesQty, ShipmentDate, LocationCode);
    end;

    local procedure AddSalesOrderLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; SalesQty: Integer; ShipmentDate: Date; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", SalesQty);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWith2Lines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; SalesQty1: Integer; ShipmentDate1: Date; SalesQty2: Integer; ShipmentDate2: Date; LocationCode: Code[10])
    begin
        CreateSalesOrder(SalesHeader, Item, SalesQty1, ShipmentDate1, LocationCode);
        AddSalesOrderLine(SalesHeader, SalesLine, Item, SalesQty2, ShipmentDate2, LocationCode);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; PurchaseQty: Decimal; ReceiptDate: Date; LocationCode: Code[10])
    begin
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", PurchaseQty);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Expected Receipt Date", ReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; FromLocation: Code[10]; ToLocation: Code[10]; ReceiptDate: Date; Qty: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, TransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
        TransferLine.Validate("Receipt Date", ReceiptDate);
        TransferLine.Modify(true);
    end;

    local procedure CreateRelProdOrderAndRefresh(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; DueDate: Date; LocationCode: Code[10]; OutputBinCode: Code[20])
    begin
        CreateProdOrderAndRefresh(ProductionOrder, ProductionOrder.Status::Released, ItemNo, Quantity, DueDate, LocationCode, OutputBinCode);
    end;

    local procedure CreatePlanProdOrderAndRefresh(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; DueDate: Date; LocationCode: Code[10]; OutputBinCode: Code[20])
    begin
        CreateProdOrderAndRefresh(ProductionOrder, ProductionOrder.Status::Planned, ItemNo, Quantity, DueDate, LocationCode, OutputBinCode);
    end;

    local procedure CreateFPlanProdOrderAndRefresh(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; DueDate: Date; LocationCode: Code[10]; OutputBinCode: Code[20])
    begin
        CreateProdOrderAndRefresh(ProductionOrder, ProductionOrder.Status::"Firm Planned",
          ItemNo, Quantity, DueDate, LocationCode, OutputBinCode);
    end;

    local procedure CreateProdOrderAndRefresh(var ProductionOrder: Record "Production Order"; OrderStatus: Enum "Production Order Status"; ItemNo: Code[20]; Quantity: Decimal; DueDate: Date; LocationCode: Code[10]; OutputBinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, OrderStatus, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        if LocationCode <> '' then
            ProductionOrder.Validate("Location Code", LocationCode);
        if OutputBinCode <> '' then
            ProductionOrder.Validate("Bin Code", OutputBinCode);

        // Needed for executing the validate trigger on due date
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateSKUs(Item: Record Item; LocationFilter: Text; VariantFilter: Text)
    begin
        Item.SetRange("No.", Item."No.");
        if LocationFilter <> '' then
            Item.SetFilter("Location Filter", LocationFilter);
        if VariantFilter <> '' then
            Item.SetFilter("Variant Filter", VariantFilter);

        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::"Location & Variant", false, false);
    end;

    local procedure UpdateSKUAsTransfer(Item: Record Item; Location: Code[10]; Variant: Code[10]; LocationFromCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.Get(Location, Item."No.", Variant);
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::Transfer);
        StockkeepingUnit.Validate("Transfer-from Code", LocationFromCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CalculateAndPostConsumption(ProductionOrder: Record "Production Order")
    begin
        ConsumptionJournalSetup();
        ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        Commit();
        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        Clear(ConsumptionItemJournalTemplate);
        ConsumptionItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(
          ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);

        Clear(ConsumptionItemJournalBatch);
        ConsumptionItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type,
          ConsumptionItemJournalTemplate.Name);
    end;

    local procedure GetLastWhseShipmentCreated(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; Location: Record Location)
    begin
        WarehouseShipmentHeader.Init();
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindLast();
    end;

    local procedure GetLastActvHdrCreatedNoSrc(var WhseActivityHdr: Record "Warehouse Activity Header"; Location: Record Location; ActivityType: Enum "Warehouse Activity Type")
    begin
        WhseActivityHdr.Init();
        WhseActivityHdr.SetRange("Location Code", Location.Code);
        WhseActivityHdr.SetRange(Type, ActivityType);
        WhseActivityHdr.FindLast();
    end;

    local procedure GetLastReceiptHdrCreatedNoSrc(var WhseReceiptHeader: Record "Warehouse Receipt Header"; Location: Record Location)
    begin
        WhseReceiptHeader.Init();
        WhseReceiptHeader.SetRange("Location Code", Location.Code);
        WhseReceiptHeader.FindLast();
    end;

    local procedure SetQtyToHandleOnActivityLines(WarehouseActivityHeader: Record "Warehouse Activity Header"; Qty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindSet(true);
        repeat
            WarehouseActivityLine.Validate(Quantity, Qty);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure SetQtyToHandleOnReceiptLines(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; Qty: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        Clear(WarehouseReceiptLine);
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindSet(true);
        repeat
            WarehouseReceiptLine.Validate(Quantity, Qty);
            WarehouseReceiptLine.Modify(true);
        until WarehouseReceiptLine.Next() = 0;
    end;

    local procedure RegisterWarehousePick(Location: Record Location; QtyToRegister: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        GetLastActvHdrCreatedNoSrc(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::Pick);
        SetQtyToHandleOnActivityLines(WarehouseActivityHeader, QtyToRegister);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure PostWarehouseReceipt(Location: Record Location; QtyToPost: Decimal)
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        GetLastReceiptHdrCreatedNoSrc(WarehouseReceiptHeader, Location);
        SetQtyToHandleOnReceiptLines(WarehouseReceiptHeader, QtyToPost);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure SetBOMOnItem(var ParentItem: Record Item; var ProductionBOMHeader: Record "Production BOM Header")
    begin
        // Uncertify production BOM and set UOM as the base UOM of the parent item
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);
        ProductionBOMHeader.Validate("Unit of Measure Code", ParentItem."Base Unit of Measure");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // Set the production BOM on the item
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ChildItem: Record Item; QtyPer: Integer)
    var
        UnitOfMeasure: Record "Unit of Measure";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Choose any unit of measure
        UnitOfMeasure.Init();
        UnitOfMeasure.FindFirst();
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure.Code);

        // Create component in the BOM
        ItemSetup(ChildItem, ChildItem."Replenishment System"::Purchase, '<0D>');
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '',
          ProductionBOMLine.Type::Item, ChildItem."No.", QtyPer);

        // Certify BOM
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure PurchaseSalesPlan(Item: Record Item; PurchaseQty: Integer; ReceivingDate: Date; SalesQty: Integer; ShipmentDate: Date; LocationCode: Code[10]; LocationFilter: Code[50])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, PurchaseQty, ReceivingDate, LocationCode);

        SalesPlan(Item, SalesQty, ShipmentDate, LocationCode, LocationFilter);
    end;

    local procedure SalesPlan(Item: Record Item; SalesQty: Integer; ShipmentDate: Date; LocationCode: Code[10]; LocationFilter: Code[50])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, Item, SalesQty, ShipmentDate, LocationCode);

        // Filter on location for regen plan
        if LocationFilter <> '' then begin
            Item.SetFilter("Location Filter", LocationFilter);
            Item.SetRange("No.", Item."No.");
        end;
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));
    end;

    local procedure PurchasePlan(Item: Record Item; PurchaseQty: Integer; ReceivingDate: Date; LocationCode: Code[10]; LocationFilter: Code[50])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, PurchaseQty, ReceivingDate, LocationCode);

        // Filter on location for regen plan
        if LocationFilter <> '' then begin
            Item.SetFilter("Location Filter", LocationFilter);
            Item.SetRange("No.", Item."No.");
        end;
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));
    end;

    local procedure AddInventoryDirectedLocation(Item: Record Item; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; Qty: Integer)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        ClearWarehouseJournal(WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, LocationCode,
          ZoneCode, BinCode, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, LocationCode, false);

        // Add to inventory
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", LocationCode);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure AddInventoryNonDirectLocation(Item: Record Item; LocationCode: Code[10]; BinCode: Code[10]; Qty: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure AddInventoryNonDirectLocationWithLotNo(Item: Record Item; LocationCode: Code[10]; Qty: Decimal; LotNo: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        CreateItemJnlLineWithLot(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationCode, Qty, LotNo);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure RemoveInventoryNonDirectLocationWithLotNo(Item: Record Item; LocationCode: Code[10]; Qty: Decimal; LotNo: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        CreateItemJnlLineWithLot(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", LocationCode, Qty, LotNo);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure AddInventoryBlankLocation(Item: Record Item; Qty: Integer)
    begin
        AddInventoryNonDirectLocation(Item, '', '', Qty);
    end;

    local procedure ClearItemJournal(ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
    end;

    local procedure ClearWarehouseJournal(WarehouseJournalTemplate: Record "Warehouse Journal Template"; WarehouseJournalBatch: Record "Warehouse Journal Batch")
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        Clear(WarehouseJournalLine);
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.DeleteAll();
    end;

    local procedure TestSetup()
    begin
        ErrorMessageCounter := 0;
        UpdatePlanningSetup();
        ClearDefaultLocation();
    end;

    local procedure FilterRequisitionLineOnPlanningWorksheet(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; LocationCode: Code[10]; ActionMsg: Enum "Action Message Type"; RefOrderType: Enum "Requisition Ref. Order Type"; OrigDueDate: Date; DueDate: Date; OrigQty: Decimal)
    begin
        RequisitionLine.SetCurrentKey(Type, "No.", "Variant Code", "Location Code", "Starting Date");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.SetRange("Action Message", ActionMsg);
        RequisitionLine.SetRange("Original Due Date", OrigDueDate);
        RequisitionLine.SetRange("Due Date", DueDate);
        RequisitionLine.SetRange("Original Quantity", OrigQty);
        RequisitionLine.SetRange("Ref. Order Type", RefOrderType);
        if LocationCode <> '' then
            RequisitionLine.SetRange("Location Code", LocationCode);
    end;

    local procedure AssertPlanningLine(Item: Record Item; ActionMsg: Enum "Action Message Type"; OrigDueDate: Date; DueDate: Date; OrigQty: Decimal; Quantity: Decimal; RefOrderType: Enum "Requisition Ref. Order Type"; LocationCode: Code[10]; NoOfLines: Integer)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetCurrentKey(Type, "No.", "Variant Code", "Location Code", "Starting Date");
        FilterRequisitionLineOnPlanningWorksheet(
          RequisitionLine, Item."No.", LocationCode, ActionMsg, RefOrderType, OrigDueDate, DueDate, OrigQty);
        RequisitionLine.SetRange(Quantity, Quantity);
        Assert.AreEqual(NoOfLines, RequisitionLine.Count, StrSubstNo(FilterRequisitionLineMsg, RequisitionLine.GetFilters));
    end;

    local procedure AssertPlanningLineWithMaximumOrderQty(ItemNo: Code[20]; ActionMsg: Enum "Action Message Type"; OrigDueDate: Date; DueDate: Date; OrigQty: Decimal; Quantity: Decimal; RefOrderType: Enum "Requisition Ref. Order Type"; LocationCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
        TotalQuantity: Decimal;
    begin
        FilterRequisitionLineOnPlanningWorksheet(RequisitionLine, ItemNo, LocationCode, ActionMsg, RefOrderType, OrigDueDate, DueDate, OrigQty);
        RequisitionLine.FindSet();
        repeat
            TotalQuantity += RequisitionLine.Quantity;
        until RequisitionLine.Next() = 0;
        Assert.AreEqual(Quantity, TotalQuantity, StrSubstNo(FilterRequisitionLineMsg, RequisitionLine.GetFilters));
    end;

    local procedure AssertNoLinesForItem(Item: Record Item)
    begin
        AssertNumberOfLinesForItem(Item, 0);
    end;

    local procedure AssertNumberOfLinesForItem(Item: Record Item; NoOfLines: Integer)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetCurrentKey(Type, "No.", "Variant Code", "Location Code", "Starting Date");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        Assert.AreEqual(NoOfLines, RequisitionLine.Count, 'There should be ' + Format(NoOfLines) +
          ' line(s) in the planning worksheet for item ' + Item."No.");
    end;

    local procedure SetupForTransfer(var Item: Record Item; var LocationFrom: Record Location; var LocationTo: Record Location)
    var
        TransferRoute: Record "Transfer Route";
    begin
        LFLItemSetup(Item, true, '', '<1W>', '', 0, 0, 0);
        LocationSetup(LocationFrom, false, false, false);
        LocationSetup(LocationTo, false, false, false);
        LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationFrom.Code, LocationTo.Code);
    end;

    local procedure CreateAndPostItemJnlLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJnlLine."Entry Type", ItemNo, Quantity);

        ItemJnlLine.Validate("Location Code", LocationCode);
        ItemJnlLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure CreateScenario273416(Item: Record Item; LocationFromCode: Code[10]; LocationToCode: Code[10])
    var
        TransferHeader: Record "Transfer Header";
        SalesHeader: Record "Sales Header";
    begin
        // create inventory on location From
        CreateAndPostItemJnlLine(Item."No.", 15, LocationFromCode);

        // create transfer from LocationFrom to LocationTo
        CreateTransferOrder(TransferHeader, Item."No.", LocationFromCode, LocationToCode, WorkDate() + 2, 13);
        // post Shipment of tranfer
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // create demand - sales order, use LocationTo
        CreateSalesOrder(SalesHeader, Item, 11, WorkDate() + 3, LocationToCode);

        // run planning for item and LocationTo
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", LocationToCode);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate() - 1, WorkDate() + 5);
    end;

    local procedure AssertTrackingLineForItem(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; NoOfLines: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status", "Shipment Date");
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Variant Code", VariantCode);
        ReservationEntry.SetRange("Location Code", LocationCode);

        Assert.AreEqual(NoOfLines, ReservationEntry.Count, StrSubstNo(Text001, NoOfLines, ReservationEntry.GetFilters));
    end;

    local procedure AssertTrackingLineForSource(SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; NoOfLines: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source Subtype", SourceSubType);

        Assert.AreEqual(NoOfLines, ReservationEntry.Count, StrSubstNo(Text001, NoOfLines, ReservationEntry.GetFilters));
    end;

    local procedure FinishSetupOfItem(var ItemFG: Record Item; var ItemComp: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // create LOT tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // create the second item - component
        FixedReorderQtyItemSetup(ItemComp, 0, 200, 1000, '<1W>', 0, 100, '', 0);
        OrderModifiersSetup(ItemComp, 100, 0, 100);
        ItemComp.Validate("Item Tracking Code", ItemTrackingCode.Code);
        ItemComp.Modify(true);

        // create BOM for final item for second UoM
        ProductionBOMHeader."No." := ItemFG."No.";
        CreateAndCertifyProdBOM(ProductionBOMHeader, ItemFG."Base Unit of Measure", ItemComp."No.", 12);
        ItemFG.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ItemFG.Modify(true);
    end;

    local procedure CreateAndCertifyProdBOM(var ProductionBOMHeader: Record "Production BOM Header"; UoM: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UoM);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, Quantity);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure FillInventoryForComp(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationFromCode: Code[10]; LocationToCode: Code[10]; LotNo: Code[10])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        CreateItemJnlLineWithLot(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LocationToCode, 80, LotNo);
        CreateItemJnlLineWithLot(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LocationToCode, 120, LotNo);
        CreateItemJnlLineWithLot(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LocationFromCode, 500, LotNo);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateItemJnlLineWithLot(var ItemJournalLine: Record "Item Journal Line"; ItemJnlTemplateName: Code[10]; ItemJnlBatchName: Code[10]; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; LotNo: Code[10])
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJnlTemplateName, ItemJnlBatchName, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);

        // assign Lot No to item journal line - triggers the ItemTrackingPageHandler handler
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure CreateProductionOrders(ItemNo: Code[20]; LocationCode: Code[10]; var ProductionOrder: array[3] of Record "Production Order")
    begin
        CreateRelProdOrderAndRefresh(ProductionOrder[1], ItemNo, 10, WorkDate() + 15, LocationCode, '');
        CreateRelProdOrderAndRefresh(ProductionOrder[2], ItemNo, 10, WorkDate() + 15, LocationCode, '');

        CreateFPlanProdOrderAndRefresh(ProductionOrder[3], ItemNo, 10, WorkDate() + 30, LocationCode, '');
    end;

    local procedure CreateAndShipTransfer(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; LocationFromCode: Code[10]; LocationToCode: Code[10]; Quantity: Decimal; LotNo: Code[10]; ReceiveDate: Date; QuantityToShip: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        // create transfer from LocationFrom to LocationTo
        CreateTransferOrder(TransferHeader, ItemNo, LocationFromCode, LocationToCode, ReceiveDate, Quantity);

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindSet();
        repeat
            TransferLine.Validate("Qty. to Ship", QuantityToShip);
            TransferLine.Modify(true);
            CreateItemTrackingForTransfer(TransferLine, LotNo);
        until TransferLine.Next() = 0;

        // post Shipment of tranfer
        if QuantityToShip > 0 then
            LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
    end;

    local procedure CreateItemTrackingForTransfer(TransferLine: Record "Transfer Line"; LotNo: Code[10])
    begin
        // assign Lot No to trnasfer line - triggers the ItemTrackingPageHandler handler
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(TransferLine."Quantity (Base)");
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure SetupForBug272514(var ProductionOrder: array[3] of Record "Production Order"; var TransferHeader: Record "Transfer Header"; ItemFGNo: Code[20]; ItemCompNo: Code[20]; LocationFromCode: Code[10]; LocationToCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // fill inventory for component
        FillInventoryForComp(ItemJournalLine, ItemCompNo, LocationFromCode, LocationToCode, Text002);

        // create production orders - 2x RPO and 1x FPPO
        CreateProductionOrders(ItemFGNo, LocationToCode, ProductionOrder);

        // create transfer and post shipment of it
        CreateAndShipTransfer(TransferHeader, ItemCompNo, LocationFromCode, LocationToCode, 300, Text002, WorkDate() + 7, 300);

        // post more inventory
        CreateItemJnlLineWithLot(
          ItemJournalLine, ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemCompNo, LocationToCode, 20, Text002);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateItemTrackingForFPPO(ProductionOrder: Record "Production Order"; LotNo: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationEntry: Record "Reservation Entry";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindFirst();

        ReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
        ReservationEntry.SetRange("Source ID", ProdOrderComponent."Prod. Order No.");
        ReservationEntry.SetRange("Source Type", DATABASE::"Prod. Order Component");
        ReservationEntry.SetRange("Source Subtype", ProdOrderComponent.Status);
        ReservationEntry.SetRange("Source Prod. Order Line", ProdOrderComponent."Prod. Order Line No.");
        ReservationEntry.SetRange("Source Ref. No.", ProdOrderComponent."Line No.");
        ReservationEntry.FindFirst();
        ReservationEntry.Validate("Lot No.", LotNo);

        ReservationEntry.UpdateItemTracking();
        ReservationEntry.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC11ReorderPoint()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 0, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        SalesPlan(Item, 49, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS used
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC12ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 0, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        SalesPlan(Item, 50, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS used
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W + 2D>', WorkDate())), 0, 500, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC21ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        SalesPlan(Item, 145, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W + 2D>', WorkDate())), 0, 500, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC22ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '1M', 0, 10, '', 0);
        OrderModifiersSetup(Item, 25, 0, 3);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        PurchaseSalesPlan(
          Item, 150, CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), 145, CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())),
          '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC23ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);
        OrderModifiersSetup(Item, 0, 2, 0);
        Evaluate(Item."Lead Time Calculation", '1W');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 50);

        // Exercise
        PurchaseSalesPlan(
          Item, 200, CalcDate(PlanningStartDate, CalcDate('<+1W-1D>', WorkDate())), 45, CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())),
          '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 3);
        AssertPlanningLineWithMaximumOrderQty(Item."No.", RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC24ReorderPoint()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 200, CalcDate(PlanningStartDate, CalcDate('<+1W + 2D>', WorkDate())), '');
        PurchaseSalesPlan(
          Item, 5, CalcDate(PlanningStartDate, CalcDate('<+1WD>', WorkDate())), 145, CalcDate(PlanningStartDate, CalcDate('<+1W + 1D>', WorkDate())),
          '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC25ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        SalesPlan(Item, 145, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W + 2D>', WorkDate())), 0, 490, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC26ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);
        OrderModifiersSetup(Item, 25, 0, 3);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        PurchaseSalesPlan(
          Item, 300, CalcDate(PlanningStartDate, CalcDate('<+1W + 1D>', WorkDate())), 145, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())),
          '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC27ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);
        OrderModifiersSetup(Item, 0, 5, 0);
        Evaluate(Item."Lead Time Calculation", '2W');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 50);

        // Exercise
        PurchaseSalesPlan(
          Item, 300, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 50, CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), '',
          '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLineWithMaximumOrderQty(Item."No.", RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC28ReorderPoint()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);
        Evaluate(Item."Lead Time Calculation", '2W');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 200, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '');
        PurchaseSalesPlan(
          Item, 5, CalcDate(PlanningStartDate, CalcDate('<+3D>', WorkDate())), 145, CalcDate(PlanningStartDate, CalcDate('<+3D>', WorkDate())), '',
          '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC29SafetyStock()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 10, 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 50);

        // Exercise
        SalesPlan(Item, 45, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC210SafetyStock()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 10, 0);
        OrderModifiersSetup(Item, 25, 100, 10);

        // Add inventory
        AddInventoryBlankLocation(Item, 10);

        // Exercise
        CreateSalesOrderWith2Lines(
          SalesHeader, SalesLine, Item, 155, CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())), 25,
          CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), '');
        SalesPlan(Item, 5, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 4);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 0, 30, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())), 0, 100, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())), 0, 30, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), 0, 30, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC211SafetyStock()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 10, 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 10);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 25, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 60, CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())), '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 50, CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), '');
        CreateSalesOrderWith2Lines(
          SalesHeader, SalesLine, Item, 25, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 55,
          CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())), '');
        SalesPlan(Item, 55, CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D,
          CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())), 60, 55, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D,
          CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), 50, 55, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC31ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 60, 100, 0, '', 0, 10, '', 0);
        OrderModifiersSetup(Item, 0, 50, 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 100);

        // Exercise
        SalesPlan(Item, 200, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 5);
        AssertPlanningLineWithMaximumOrderQty(Item."No.", RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 0, 110, RequisitionLine."Ref. Order Type"::Purchase, '');
        AssertPlanningLineWithMaximumOrderQty(Item."No.", RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W + 2D>', WorkDate())), 0, 90, RequisitionLine."Ref. Order Type"::Purchase, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC32ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 60, 100, 0, '', 0, 0, '', 0);
        OrderModifiersSetup(Item, 25, 0, 0);
        Evaluate(Item."Lead Time Calculation", '10D');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 100);

        // Exercise
        CreateSalesOrder(SalesHeader, Item, 75, CalcDate(PlanningStartDate, CalcDate('<+2W+3D>', WorkDate())), '');
        SalesPlan(Item, 30, CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+4W+1D>', WorkDate())), 0, 75, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC33ReorderPoint()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 60, 100, 0, '', 0, 0, '', 0);
        OrderModifiersSetup(Item, 0, 0, 10);
        Evaluate(Item."Lead Time Calculation", '1M');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 100);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 110, CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), '');
        CreateSalesOrder(SalesHeader, Item, 55, CalcDate(PlanningStartDate, CalcDate('<+3W-2D>', WorkDate())), '');
        SalesPlan(Item, 55, CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC34ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        SalesPlan(Item, 200, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 0, 60, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+2D>', WorkDate())), 0, 500, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC35ReorderPoint()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);
        Evaluate(Item."Lead Time Calculation", '1W');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 101);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 100, CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())), '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 20, CalcDate(PlanningStartDate, CalcDate('<+2w-2D>', WorkDate())), '');
        CreateSalesOrder(SalesHeader, Item, 50, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), '');
        SalesPlan(Item, 60, CalcDate(PlanningStartDate, CalcDate('<+2W-2D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC41ReorderPoint()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 50);

        // Exercise
        PurchasePlan(Item, 51, CalcDate(PlanningStartDate, CalcDate('<-1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC42ReorderPoint()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 200, 0, '', 0, 0, '', 0);
        OrderModifiersSetup(Item, 0, 0, 10);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        PurchasePlan(Item, 100, CalcDate(PlanningStartDate, CalcDate('<-1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC43SafetyStock()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 10, 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 15, CalcDate('<+4D>', WorkDate()), '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 25, CalcDate('<+8D>', WorkDate()), '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 130, CalcDate('<+10D>', WorkDate()), '');
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 75, CalcDate('<+0D>', WorkDate()), 70, CalcDate('<+2D>', WorkDate()), '');
        SalesPlan(Item, 25, CalcDate('<+6D>', WorkDate()), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC44ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 75);

        // Exercise
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 0, 500, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC45ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        SalesPlan(Item, 75, CalcDate(PlanningStartDate, CalcDate('<-1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 0, 425, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC46ReorderPoint()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        PurchaseSalesPlan(
          Item, 100, CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 75, CalcDate(PlanningStartDate, CalcDate('<-1W>', WorkDate())), '',
          '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC47ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 5);

        // Exercise
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 0, 500, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, WorkDate()), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC48ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 100);

        // Exercise
        SalesPlan(Item, 95, CalcDate(PlanningStartDate, CalcDate('<-1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 0, 490, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, WorkDate()), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC49ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '+1W', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 100);

        // Exercise
        PurchaseSalesPlan(
          Item, 100, CalcDate(PlanningStartDate, CalcDate('<+1W-1D>', WorkDate())), 95, CalcDate(PlanningStartDate, CalcDate('<-1W-1D>', WorkDate())),
          '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, WorkDate()), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC410ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Exercise
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 0, 500, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC411ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 500, 0, '', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 5);

        // Exercise
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 0, 490, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, WorkDate()), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC412SafetyStock()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 10, 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 100);

        // Exercise
        CreateSalesOrderWith2Lines(
          SalesHeader, SalesLine, Item, 25, CalcDate(PlanningStartDate, CalcDate('<-3W>', WorkDate())), 50,
          CalcDate(PlanningStartDate, CalcDate('<-2W>', WorkDate())), '');
        SalesPlan(Item, 40, CalcDate(PlanningStartDate, CalcDate('<-1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<-1D>', WorkDate())), 0, 15, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC413ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 500, 0, '2W', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        PurchaseSalesPlan(
          Item, 150, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 175, CalcDate(PlanningStartDate, CalcDate('<-1W>', WorkDate())),
          '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<-1D>', WorkDate())), 0, 25, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC51ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 200, 0, '1W', 0, 10, '', 0);
        Evaluate(Item."Lead Time Calculation", '3D');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 40, CalcDate(PlanningStartDate, CalcDate('<+2D>', WorkDate())), 40,
          CalcDate(PlanningStartDate, CalcDate('<+1W-1D>', WorkDate())), '');
        SalesPlan(Item, 180, CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+4D>', WorkDate())), 0, 200, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+3W+4D>', WorkDate())), 0, 200, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC52ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 200, 0, '1W', 0, 0, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 101);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 50, CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 150,
          CalcDate(PlanningStartDate, CalcDate('<+3D>', WorkDate())), '');
        SalesPlan(Item, 150, CalcDate(PlanningStartDate, CalcDate('<+2W-2D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 3);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 0, 200, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+2W+1D>', WorkDate())), 0, 200, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+3D>', WorkDate())), 0, 99, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC53ReorderPoint()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 200, 0, '2W', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 101);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 100, CalcDate(PlanningStartDate, CalcDate('<+2W-1D>', WorkDate())), '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 50, CalcDate(PlanningStartDate, CalcDate('<+4W-1D>', WorkDate())), '');
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 50, CalcDate(PlanningStartDate, CalcDate('<+1W-1D>', WorkDate())), 25,
          CalcDate(PlanningStartDate, CalcDate('<+2W-2D>', WorkDate())), '');
        SalesPlan(Item, 75, CalcDate(PlanningStartDate, CalcDate('<+3W+1D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC54ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 200, 0, '1W', 0, 10, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 101);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 25, CalcDate(PlanningStartDate, CalcDate('<+1W-1D>', WorkDate())), 25,
          CalcDate(PlanningStartDate, CalcDate('<+3D>', WorkDate())), '');
        SalesPlan(Item, 125, CalcDate(PlanningStartDate, CalcDate('<+3W+1D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 0, 149, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+4W+1D>', WorkDate())), 0, 125, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC55ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 200, 0, '1W', 0, 0, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 101);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 75, CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 50,
          CalcDate(PlanningStartDate, CalcDate('<+1W-2D>', WorkDate())), '');
        SalesPlan(Item, 50, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 3);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 0, 200, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 0, 50, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W-2D>', WorkDate())), 0, 24, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC56ReorderPoint()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 200, 0, '1M', 0, 0, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 101);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 49, CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 200, CalcDate(PlanningStartDate,
            CalcDate(DaysInMonthFormula, CalcDate('<-1D>', WorkDate()))), ''); // +1M-1D
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 100, CalcDate(PlanningStartDate,
            CalcDate(DaysInMonthFormula, CalcDate(DaysInMonthFormula, CalcDate('<-1D>', WorkDate())))), ''); // +2M-1D
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 75, CalcDate(PlanningStartDate, CalcDate('<+1W>', WorkDate())), 75,
          CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), '');
        SalesPlan(Item, 150, CalcDate(PlanningStartDate,
            CalcDate(DaysInMonthFormula, CalcDate('<+1D>', WorkDate()))), '', ''); // 1M+1D

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC57SafetyStock()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, false, '', '1W', '', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 25, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 50,
          CalcDate(PlanningStartDate, CalcDate('<+2W+1D>', WorkDate())), '');
        SalesPlan(Item, 63, CalcDate(PlanningStartDate, CalcDate('<+2W+2D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 0, 75, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+2W+2D>', WorkDate())), 0, 63, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC58SafetyStock()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '1W', '', 0, 10, 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 10);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 5, CalcDate(PlanningStartDate, CalcDate('<+1W-2D>', WorkDate())), 15,
          CalcDate(PlanningStartDate, CalcDate('<+1W-1D>', WorkDate())), '');
        SalesPlan(Item, 30, CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W-2D>', WorkDate())), 0, 20, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+2W>', WorkDate())), 0, 30, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC59SafetyStock()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, false, '', '10D', '', 0, 0, 0);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 55, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 30, CalcDate(PlanningStartDate, CalcDate('<+3W-2D>', WorkDate())), '');
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 55, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 10,
          CalcDate(PlanningStartDate, CalcDate('<+3W-2D>', WorkDate())), '');
        SalesPlan(Item, 20, CalcDate(PlanningStartDate, CalcDate('<+3W+3D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC61ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 250, 0, '', 0, 0, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        SalesPlan(Item, 75, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+3D>', WorkDate())), 0, 250, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC62ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 250, 0, '', 0, 0, '', 0);
        Evaluate(Item."Lead Time Calculation", '10D');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        PurchaseSalesPlan(
          Item, 25, CalcDate(PlanningStartDate, CalcDate('<+3W>', WorkDate())), 75, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())),
          '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+3W-1D>', WorkDate())), 0, 250, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC63ReorderPoint()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 250, 0, '', 0, 0, '', 0);
        Evaluate(Item."Lead Time Calculation", '10D');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        PurchaseSalesPlan(
          Item, 26, CalcDate(PlanningStartDate, CalcDate('<+3W-1D>', WorkDate())), 75, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())),
          '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC64ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 200, 0, '', 0, 10, '', 0);
        Evaluate(Item."Lead Time Calculation", '10D');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 101);

        // Exercise
        CreateSalesOrder(SalesHeader, Item, 50, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '');
        SalesPlan(Item, 25, CalcDate(PlanningStartDate, CalcDate('<+1W+2D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+3W-1D>', WorkDate())), 0, 149, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC65ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        MaxQtyItemSetup(Item, 100, 200, 0, '', 0, 10, '', 0);
        Evaluate(Item."Lead Time Calculation", '10D');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 101);

        // Exercise
        PurchaseSalesPlan(
          Item, 25, CalcDate(PlanningStartDate, CalcDate('<+3W-1D>', WorkDate())), 50, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())),
          '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+3W-1D>', WorkDate())), 0, 124, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC66SafetyStock()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, false, '', '1W', '', 0, 0, 0);
        Evaluate(Item."Lead Time Calculation", '3D');
        Item.Modify(true);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 50, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 100,
          CalcDate(PlanningStartDate, CalcDate('<+2W-1D>', WorkDate())), '');
        SalesPlan(Item, 25, CalcDate(PlanningStartDate, CalcDate('<+2W+3D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 0, 150, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+2W+3D>', WorkDate())), 0, 25, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC71ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 200, 0, '1W', 0, 0, '', 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 101);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 50, CalcDate(PlanningStartDate, CalcDate('<+1D>', WorkDate())), 150,
          CalcDate(PlanningStartDate, CalcDate('<+1W-2D>', WorkDate())), '');
        SalesPlan(Item, 150, CalcDate(PlanningStartDate, CalcDate('<+2W-2D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 3);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 0, 200, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+2W+1D>', WorkDate())), 0, 200, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W-2D>', WorkDate())), 0, 99, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC72ReorderPoint()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        FixedReorderQtyItemSetup(Item, 100, 250, 0, '', 0, 0, '', 0);
        Evaluate(Item."Lead Time Calculation", '10D');
        Item.Modify(true);

        // Add inventory
        AddInventoryBlankLocation(Item, 150);

        // Exercise
        CreateSalesOrder(SalesHeader, Item, 74, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '');
        PurchaseSalesPlan(
          Item, 25, CalcDate(PlanningStartDate, CalcDate('<+2W+3D>', WorkDate())), 1, CalcDate(PlanningStartDate, CalcDate('<+2W-2D>', WorkDate())),
          '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+3W+3D>', WorkDate())), 0, 250, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC11OrderPriorities()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 2);

        // Exercise
        CreateSalesReturnOrder(SalesHeader, Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '');
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC12OrderPriorities()
    var
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Add inventory
        AddInventoryNonDirectLocation(Item, LocationOne.Code, '', 1);

        // Exercise
        CreateTransferOrder(
          TransferHeader, Item."No.", LocationTwo.Code, LocationOne.Code, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1);
        SalesPlan(
          Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, LocationOne.Code + '|' + LocationTwo.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::Transfer, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC13OrderPriorities()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');
        CreateSalesReturnOrder(SalesHeader, Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '');
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::"Prod. Order", '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC14OrderPriorities()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Add inventory
        AddInventoryBlankLocation(Item, 1);

        // Exercise
        PurchaseSalesPlan(
          Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())),
          '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC21OrderPriorities()
    var
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateTransferOrder(
          TransferHeader, Item."No.", LocationTwo.Code, LocationOne.Code, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1);
        CreateRelProdOrderAndRefresh(
          ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, '');
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, LocationOne.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::Purchase, LocationOne.Code, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::"Prod. Order",
          LocationOne.Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC22OrderPriorities()
    var
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateTransferOrder(
          TransferHeader, Item."No.", LocationTwo.Code, LocationOne.Code, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1);
        CreateRelProdOrderAndRefresh(
          ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, '');
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, LocationOne.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::"Prod. Order",
          LocationOne.Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC23OrderPriorities()
    var
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateTransferOrder(
          TransferHeader, Item."No.", LocationTwo.Code, LocationOne.Code, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, LocationOne.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::Purchase, LocationOne.Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC24OrderPriorities()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateRelProdOrderAndRefresh(
          ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, '');
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, LocationOne.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::Purchase, LocationOne.Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC31OrderPriorities()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreatePlanProdOrderAndRefresh(ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');
        CreateRelProdOrderAndRefresh(ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC32OrderPriorities()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateFPlanProdOrderAndRefresh(ProductionOrder, Item."No.", 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');
        CreateRelProdOrderAndRefresh(ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 2, 0, RequisitionLine."Ref. Order Type"::"Prod. Order", '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC33OrderPriorities()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreatePlanProdOrderAndRefresh(ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');
        CreateFPlanProdOrderAndRefresh(ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC41OrderPriorities()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Add inventory
        AddInventoryNonDirectLocation(Item, LocationOne.Code, '', 1);
        AddInventoryNonDirectLocation(Item, LocationTwo.Code, '', 10);

        // Exercise
        CreateTransferOrder(
          TransferHeader, Item."No.", LocationTwo.Code, LocationOne.Code, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, LocationOne.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC42OrderPriorities()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);
        CreateBOM(ProductionBOMHeader, ChildItem, 1);
        SetBOMOnItem(Item, ProductionBOMHeader);

        // Add inventory
        AddInventoryBlankLocation(Item, 1);
        AddInventoryBlankLocation(ChildItem, 10);

        // Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');
        CalculateAndPostConsumption(ProductionOrder);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC43OrderPriorities()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '');
        PurchaseLine.Validate("Qty. to Receive", 1);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC44OrderPriorities()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);
        CreateBOM(ProductionBOMHeader, ChildItem, 1);
        SetBOMOnItem(Item, ProductionBOMHeader);

        // Add inventory
        AddInventoryNonDirectLocation(ChildItem, LocationOne.Code, '', 10);

        // Exercise
        CreateTransferOrder(
          TransferHeader, Item."No.", LocationTwo.Code, LocationOne.Code, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1);
        CreateRelProdOrderAndRefresh(
          ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, '');
        CalculateAndPostConsumption(ProductionOrder);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, LocationOne.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::Transfer, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC45OrderPriorities()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, Item."No.", 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '');
        PurchaseLine.Validate("Qty. to Receive", 1);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SalesPlan(Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), '', '');

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 2, 0, RequisitionLine."Ref. Order Type"::"Prod. Order", '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC51OrderPriorities()
    var
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateSalesReturnOrder(SalesHeader, Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code);
        CreateTransferOrder(
          TransferHeader, Item."No.", LocationWhite.Code, LocationOne.Code, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, LocationOne.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::Transfer, '', 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHndlRegisterWhseJnlLine,TC52MessageHandler')]
    [Scope('OnPrem')]
    procedure TC52OrderPriorities()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        Bin: Record Bin;
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItem: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);
        CreateBOM(ProductionBOMHeader, ChildItem, 1);
        SetBOMOnItem(Item, ProductionBOMHeader);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, 'PICK', 1);
        SetDefaultLocation(LocationWhite.Code);

        // Add inventory
        AddInventoryDirectedLocation(ChildItem, LocationWhite.Code, 'PICK', Bin.Code, 10);

        // Exercise
        CreateSalesReturnOrder(
          SalesHeader, Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code);
        CreateRelProdOrderAndRefresh(
          ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code, '');
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code, LocationWhite.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::"Prod. Order", '', 1);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHndlRegisterWhseJnlLine(Question: Text[1024]; var Val: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MSG_WHSE_JNL_REG) > 0, Question);
        Val := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC52MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_JNL_LINE_REG) > 0, Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC53OrderPriorities()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateSalesReturnOrder(
          SalesHeader, Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code, LocationWhite.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHndlRegisterWhseJnlLine,TC54MessageHandler')]
    [Scope('OnPrem')]
    procedure TC54OrderPriorities()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Bin: Record Bin;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, 'PICK', 1);
        SetDefaultLocation(LocationWhite.Code);

        // Add inventory
        AddInventoryDirectedLocation(Item, LocationWhite.Code, 'PICK', Bin.Code, 10);

        // Exercise
        CreateSalesReturnOrder(SalesHeader, Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code);
        CreateTransferOrder(
          TransferHeader, Item."No.", LocationWhite.Code, LocationOne.Code, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 2);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        GetLastWhseShipmentCreated(WarehouseShipmentHeader, LocationWhite);
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);
        RegisterWarehousePick(LocationWhite, 1);
        SalesPlan(Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationOne.Code, LocationOne.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC54MessageHandler(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_JNL_LINE_REG) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, MSG_WHSE_SHIP_CREATED) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHndlRegisterWhseJnlLine,TC55MessageHandler')]
    [Scope('OnPrem')]
    procedure TC55OrderPriorities()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        Bin: Record Bin;
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItem: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);
        CreateBOM(ProductionBOMHeader, ChildItem, 1);
        SetBOMOnItem(Item, ProductionBOMHeader);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, 'PICK', 1);
        SetDefaultLocation(LocationWhite.Code);

        // Add inventory
        AddInventoryDirectedLocation(ChildItem, LocationWhite.Code, 'PICK', Bin.Code, 10);

        // Exercise
        CreateSalesReturnOrder(
          SalesHeader, Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code);
        CreateRelProdOrderAndRefresh(
          ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code, '');
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehousePick(LocationWhite, 1);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code, LocationWhite.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC55MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_JNL_LINE_REG) > 0, Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC56OrderPriorities()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateSalesReturnOrder(
          SalesHeader, Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(LocationWhite, 1);
        SalesPlan(Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code, LocationWhite.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHndlRegisterWhseJnlLine,TC57MessageHandler')]
    [Scope('OnPrem')]
    procedure TC57OrderPriorities()
    var
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        Bin: Record Bin;
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItem: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);
        CreateBOM(ProductionBOMHeader, ChildItem, 1);
        SetBOMOnItem(Item, ProductionBOMHeader);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, 'PICK', 1);
        SetDefaultLocation(LocationWhite.Code);

        // Add inventory
        AddInventoryDirectedLocation(ChildItem, LocationWhite.Code, 'PICK', Bin.Code, 10);

        // Exercise
        CreateSalesReturnOrder(
          SalesHeader, Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code);
        CreateTransferOrder(
          TransferHeader, Item."No.", LocationOne.Code, LocationWhite.Code, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1);
        CreateRelProdOrderAndRefresh(
          ProductionOrder, Item."No.", 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code, '');
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehousePick(LocationWhite, 1);
        SalesPlan(Item, 1, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code, LocationWhite.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 1, 0, RequisitionLine."Ref. Order Type"::Transfer, '', 1);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC57MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_JNL_LINE_REG) > 0, Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC58OrderPriorities()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateSalesReturnOrder(
          SalesHeader, Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code);
        CreateRelProdOrderAndRefresh(
          ProductionOrder, Item."No.", 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code, '');
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(LocationWhite, 1);
        SalesPlan(Item, 2, CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), LocationWhite.Code, LocationWhite.Code);

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate(PlanningStartDate, CalcDate('<+1W+1D>', WorkDate())), 2, 0, RequisitionLine."Ref. Order Type"::"Prod. Order", '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B273416PlanOfShippedTransfer()
    var
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetupForTransfer(Item, LocationFrom, LocationTo);

        // run planning for shipped transfer and sales order
        CreateScenario273416(Item, LocationFrom.Code, LocationTo.Code);

        // verify no result in planning worksheet
        AssertNoLinesForItem(Item);
        AssertTrackingLineForItem(Item."No.", '', LocationTo.Code, 3);  // 2 are tracking sales with transfer, the third is Surplus for transfer
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure B272514ReplanOfProdOrders()
    var
        ItemFG: Record Item;
        ItemComp: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        TransferHeader: Record "Transfer Header";
        ProductionOrder: array[3] of Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetupForTransfer(ItemFG, LocationFrom, LocationTo);
        FinishSetupOfItem(ItemFG, ItemComp);

        // preparing data for test
        SetupForBug272514(ProductionOrder, TransferHeader, ItemFG."No.", ItemComp."No.", LocationFrom.Code, LocationTo.Code);

        // run planning for component and LocationTo
        ItemComp.SetRange("No.", ItemComp."No.");
        ItemComp.SetRange("Location Filter", LocationTo.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(ItemComp, WorkDate() - 1, WorkDate() + 35);

        // verify results
        AssertNoLinesForItem(ItemComp);
        AssertTrackingLineForItem(ItemComp."No.", '', LocationTo.Code, 13);  // 12 are tracking production with ILE and transfer, the last 13th is Surplus for transfer
        AssertTrackingLineForSource(5407, ProductionOrder[1].Status.AsInteger(), ProductionOrder[1]."No.", 2);  // 2 tracking entries against ILEs
        AssertTrackingLineForSource(5407, ProductionOrder[2].Status.AsInteger(), ProductionOrder[2]."No.", 3);  // 2 tracking entries against ILEs and 1 against transfer
        AssertTrackingLineForSource(5407, ProductionOrder[3].Status.AsInteger(), ProductionOrder[3]."No.", 1);  // 1 tracking entry against transfer
        AssertTrackingLineForSource(5741, 1, TransferHeader."No.", 3);  // 1 tracking entry against RPO, 1 tracking entry against FPPO, 1 surplus

        // rerun planning for a new period
        LibraryPlanning.CalcRegenPlanForPlanWksh(ItemComp, WorkDate() - 1, WorkDate() + 15);

        // verify results
        AssertNoLinesForItem(ItemComp);
        AssertTrackingLineForItem(ItemComp."No.", '', LocationTo.Code, 12);  // 10 are tracking production with ILE and transfer, last 2 are Surplus for transfer
        AssertTrackingLineForSource(5407, ProductionOrder[1].Status.AsInteger(), ProductionOrder[1]."No.", 2);  // 2 tracking entries against ILEs
        AssertTrackingLineForSource(5407, ProductionOrder[2].Status.AsInteger(), ProductionOrder[2]."No.", 3);  // 2 tracking entries against ILEs and 1 against transfer
        AssertTrackingLineForSource(5407, ProductionOrder[3].Status.AsInteger(), ProductionOrder[3]."No.", 0);  // FPPO is not tracked at all
        AssertTrackingLineForSource(5741, 1, TransferHeader."No.", 3);  // 1 tracking entry against RPO, 2 surplus entries
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure B272514ReplanOfProdOrdersWithIT()
    var
        ItemFG: Record Item;
        ItemComp: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        TransferHeader: Record "Transfer Header";
        ProductionOrder: array[3] of Record "Production Order";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetupForTransfer(ItemFG, LocationFrom, LocationTo);
        FinishSetupOfItem(ItemFG, ItemComp);

        // preparing data for test
        SetupForBug272514(ProductionOrder, TransferHeader, ItemFG."No.", ItemComp."No.", LocationFrom.Code, LocationTo.Code);

        // run planning for component and LocationTo
        ItemComp.SetRange("No.", ItemComp."No.");
        ItemComp.SetRange("Location Filter", LocationTo.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(ItemComp, WorkDate() - 1, WorkDate() + 35);

        // verify results
        AssertNoLinesForItem(ItemComp);
        AssertTrackingLineForItem(ItemComp."No.", '', LocationTo.Code, 13);  // 12 are tracking production with ILE and transfer, the last 13th is Surplus for transfer
        AssertTrackingLineForSource(5407, ProductionOrder[1].Status.AsInteger(), ProductionOrder[1]."No.", 2);  // 2 tracking entries against ILEs
        AssertTrackingLineForSource(5407, ProductionOrder[2].Status.AsInteger(), ProductionOrder[2]."No.", 3);  // 2 tracking entries against ILEs and 1 against transfer
        AssertTrackingLineForSource(5407, ProductionOrder[3].Status.AsInteger(), ProductionOrder[3]."No.", 1);  // 1 tracking entry against transfer
        AssertTrackingLineForSource(5741, 1, TransferHeader."No.", 3);  // 1 tracking entry against RPO, 1 tracking entry against FPPO, 1 surplus

        // add Item tracking for component of FPPO
        CreateItemTrackingForFPPO(ProductionOrder[3], Text002);

        // rerun planning for a new period
        LibraryPlanning.CalcRegenPlanForPlanWksh(ItemComp, WorkDate() - 1, WorkDate() + 15);

        // verify results
        AssertNoLinesForItem(ItemComp);
        AssertTrackingLineForItem(ItemComp."No.", '', LocationTo.Code, 13);  // 10 are tracking production with ILE and transfer, last 1 is Surplus for transfer
        AssertTrackingLineForSource(5407, ProductionOrder[1].Status.AsInteger(), ProductionOrder[1]."No.", 2);  // 2 tracking entries against ILEs
        AssertTrackingLineForSource(5407, ProductionOrder[2].Status.AsInteger(), ProductionOrder[2]."No.", 3);  // 2 tracking entries against ILEs and 1 against transfer
        AssertTrackingLineForSource(5407, ProductionOrder[3].Status.AsInteger(), ProductionOrder[3]."No.", 1);  // 1 surplus entry
        AssertTrackingLineForSource(5741, 1, TransferHeader."No.", 3);  // 1 tracking entry against RPO, 2 surplus entries
    end;

    [Test]
    [HandlerFunctions('PAG6510ItemTrackingLinesHandler,PAG6515EnterCustomizedSNHandler,PAG5510OutputJournalHandler,ConfirmYes,PostedMsgHandler')]
    [Scope('OnPrem')]
    procedure B335974DecreaseOutputQtyProdJnlLine()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LibraryApplicationArea.EnablePremiumSetup();

        B335974_CreateSetup(Item, Location);
        // Create prod. order
        CreateRelProdOrderAndRefresh(ProductionOrder, Item."No.", GlobalQty[1], WorkDate(), Location.Code, '');
        DefineFullItemTrackingForProdOrder(ProductionOrder);
        ReduceOutputQtyTryPostingErrExpected(ProductionOrder);
        ReduceItemTrackingTryPostNoErrorExpected(ProductionOrder);
        // Posting is now done of GlobalQty[2] items.
        // Verify that remaining items on prod.order have correct item tracking:
        VerifyRemainingProdOrderItemTrackingLines(ProductionOrder);
    end;

    local procedure JobPlanningLineTests(UsageLink: Boolean; Reserve: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseQuantity: Decimal;
        JobQuantity: Decimal;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::Purchase, '<0D>');
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        // Create orders
        PurchaseQuantity := LibraryRandom.RandDec(100, 2);
        JobQuantity := PurchaseQuantity + LibraryRandom.RandDec(100, 2);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, PurchaseQuantity, WorkDate(), '');
        CreateJobAndPlanningLine(JobTask, JobPlanningLine, Item."No.", JobQuantity, UsageLink);
        if Reserve then
            PurchaseLine.ShowReservation()
        else begin
            PurchaseLine.Validate("Job No.", JobPlanningLine."Job No.");
            PurchaseLine.Modify(true);
        end;

        // Exercise
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        if UsageLink or Reserve then begin
            AssertNumberOfLinesForItem(Item, 1);
            AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D,
              WorkDate(), PurchaseQuantity, JobQuantity, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        end else begin
            AssertNumberOfLinesForItem(Item, 1);
            AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
              WorkDate(), PurchaseQuantity, 0, RequisitionLine."Ref. Order Type"::Purchase, '', 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineNoReserveNoUsageLink()
    begin
        JobPlanningLineTests(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineNoReserveWithUsageLink()
    begin
        JobPlanningLineTests(true, false);
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure JobPlanningLineWithReservation()
    begin
        JobPlanningLineTests(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleJobPlanningLinesNoReserve()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobQuantity: Decimal;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::Purchase, '<0D>');
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        // Create orders
        JobQuantity := LibraryRandom.RandDec(100, 2);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 2 * JobQuantity, WorkDate(), '');
        CreateJobAndPlanningLine(JobTask, JobPlanningLine, Item."No.", JobQuantity, true);
        CreateJobPlanningLine(JobPlanningLine, JobPlanningLine."Line Type"::Budget, JobTask, Item."No.", JobQuantity, false);
        CreateJobPlanningLine(JobPlanningLine, JobPlanningLine."Line Type"::Budget, JobTask, Item."No.", JobQuantity, true);
        PurchaseLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchaseLine.Modify(true);

        // Exercise
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate(PlanningEndDate, WorkDate()));

        // verify no lines - only the lines with usagelink=true are considered
        AssertNoLinesForItem(Item);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveFromCurrentLineHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PAG6510ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        i: Integer;
    begin
        // HandlerActions:
        // 1: Create full item tracking information
        // 2: Set zeroes so that GlobalQty[2] items remain with qty = 1
        // 3: Validate remaining serial numbers
        case GlobalHandlerAction of
            1:
                ItemTrackingLines.CreateCustomizedSN.Invoke();
            2:
                begin
                    ItemTrackingLines.First();
                    for i := 1 to GlobalQty[1] - GlobalQty[2] do begin
                        ItemTrackingLines."Qty. to Handle (Base)".SetValue(0);
                        GlobalRemainingSerialNos[i] := ItemTrackingLines."Serial No.".Value();
                        ItemTrackingLines.Next();
                    end;
                end;
            3:
                begin
                    ItemTrackingLines.First();
                    for i := 1 to GlobalQty[1] - GlobalQty[2] do begin
                        Assert.AreEqual(
                          GlobalRemainingSerialNos[i],
                          ItemTrackingLines."Serial No.".Value,
                          StrSubstNo(WrongSerialNoTxt, ItemTrackingLines."Serial No.".Value));
                        if i < GlobalQty[1] - GlobalQty[2] then
                            ItemTrackingLines.Next();
                    end;
                end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PAG6515EnterCustomizedSNHandler(var EnterCustomizedSN: TestPage "Enter Customized SN")
    begin
        EnterCustomizedSN.CustomizedSN.SetValue(CustomizedSNTxt);
        EnterCustomizedSN.Increment.SetValue(1);
        EnterCustomizedSN.QtyToCreate.SetValue(GlobalQty[1]);
        EnterCustomizedSN.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PAG5510OutputJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal."Output Quantity".SetValue(GlobalQty[2]);
        if GlobalHandlerAction = 1 then
            asserterror ProductionJournal.Post.Invoke() // Try to post
        else
            ProductionJournal.Post.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYes(Q: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure GetNonBlockedGLAccount(): Code[10]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange(Blocked, false);
        GLAccount.FindFirst();
        exit(GLAccount."No.");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PostedMsgHandler(Msg: Text[1024])
    begin
        Assert.IsTrue(StrPos(Msg, SuccessfullyPostedTxt) > 0, StrSubstNo(WrongPostingMsgTxt, Msg));
    end;

    local procedure B335974_CreateSetup(var Item: Record Item; var Location: Record Location)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        AccNo: Code[10];
    begin
        // Create blue location:
        LibraryWarehouse.CreateLocation(Location);
        // Create item with serial no. tracking
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, Item."Inventory Posting Group");
        AccNo := GetNonBlockedGLAccount();
        InventoryPostingSetup."Inventory Account" := AccNo;
        InventoryPostingSetup."WIP Account" := AccNo;
        InventoryPostingSetup.Modify();
        LibraryInventory.UpdateInventoryPostingSetup(Location);
        LibraryItemTracking.AddSerialNoTrackingInfo(Item);
        ManufacturingSetup.Get();
        ManufacturingSetup."Preset Output Quantity" := ManufacturingSetup."Preset Output Quantity"::"Zero on All Operations";
        ManufacturingSetup.Modify(true);
        // LibraryVariableStorage.Enqueue(Variable);
        GlobalQty[1] := 10; // Quantity on the prod. order line
        GlobalQty[2] := 3;  // Output quantity on the output journal
    end;

    local procedure DefineFullItemTrackingForProdOrder(var ProductionOrder: Record "Production Order")
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // Set item tracking
        // Adjust item tracking accordingly
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GotoRecord(ProductionOrder);
        GlobalHandlerAction := 1; // Create full item tracking (serial no)
        // Set item tracking, GlobalQty[1] serial no's (done in page handler):
        ReleasedProductionOrder.ProdOrderLines.ItemTrackingLines.Invoke(); // Item Tracking Lines
    end;

    local procedure ReduceOutputQtyTryPostingErrExpected(ProductionOrder: Record "Production Order")
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // Set output qty to GlobalQty[2],done in page handler.
        // Try posting (done in page handler). Error expected:
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GotoRecord(ProductionOrder);
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke(); // Production Journal Line
    end;

    local procedure ReduceItemTrackingTryPostNoErrorExpected(ProductionOrder: Record "Production Order")
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        GlobalHandlerAction := 2; // Put zeroes in qty to handle
        // Set item tracking, GlobalQty[2] serial numbers (done in page handler).
        // No posting error expected:
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GotoRecord(ProductionOrder);
        ReleasedProductionOrder.ProdOrderLines.ItemTrackingLines.Invoke(); // Item Tracking Lines
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke(); // Production Journal Line - POSTING
    end;

    local procedure VerifyRemainingProdOrderItemTrackingLines(ProductionOrder: Record "Production Order")
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        GlobalHandlerAction := 3;
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GotoRecord(ProductionOrder);

        ReleasedProductionOrder.ProdOrderLines.ItemTrackingLines.Invoke(); // Item Tracking Lines
        // Verify remaining reservation entries:
        AssertTrackingLineForSource(
          DATABASE::"Prod. Order Line", ProductionOrder.Status.AsInteger(), ProductionOrder."No.",
          GlobalQty[1] - GlobalQty[2]);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure HF336440_NoSurplusOnTransfersPartial()
    var
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        QtyOnInventory: Decimal;
    begin
        // Setup
        Initialize();
        TestSetup();

        // Setup items and SKUs - and replenishment in a "chain" of transfers -
        // location white transfers to location 3 that transfers to location 2 that transfers to location 1
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);
        LibraryItemTracking.AddLotNoTrackingInfo(Item);
        CreateSKUs(Item, LocationOne.Code + '|' + LocationTwo.Code + '|' + LocationThree.Code + '|' + LocationWhite.Code, '');
        UpdateSKUAsTransfer(Item, LocationThree.Code, '', LocationWhite.Code);
        UpdateSKUAsTransfer(Item, LocationTwo.Code, '', LocationThree.Code);
        UpdateSKUAsTransfer(Item, LocationOne.Code, '', LocationTwo.Code);

        QtyOnInventory := LibraryRandom.RandDec(100, 2);
        AddInventoryNonDirectLocationWithLotNo(Item, LocationTwo.Code, QtyOnInventory, Text002);

        // Exercise - transfer order, ship partial
        CreateAndShipTransfer(TransferHeader, Item."No.", LocationTwo.Code, LocationOne.Code, 3 * QtyOnInventory, Text002,
          WorkDate(), QtyOnInventory);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 3);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, WorkDate(), 0, 2 * QtyOnInventory,
          RequisitionLine."Ref. Order Type"::Purchase, LocationWhite.Code, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, WorkDate(), 0, 2 * QtyOnInventory,
          RequisitionLine."Ref. Order Type"::Transfer, LocationThree.Code, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, WorkDate(), 0, 2 * QtyOnInventory,
          RequisitionLine."Ref. Order Type"::Transfer, LocationTwo.Code, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure HF339753_NoSurplusOnTransfers()
    var
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        QtyOnInventory: Decimal;
    begin
        // Setup
        Initialize();
        TestSetup();

        // Setup items and SKUs - and replenishment in a "chain" of transfers -
        // location white transfers to location 3 that transfers to location 2 that transfers to location 1
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);
        LibraryItemTracking.AddLotNoTrackingInfo(Item);
        CreateSKUs(Item, LocationOne.Code + '|' + LocationTwo.Code + '|' + LocationThree.Code + '|' + LocationWhite.Code, '');
        UpdateSKUAsTransfer(Item, LocationThree.Code, '', LocationWhite.Code);
        UpdateSKUAsTransfer(Item, LocationTwo.Code, '', LocationThree.Code);
        UpdateSKUAsTransfer(Item, LocationOne.Code, '', LocationTwo.Code);

        QtyOnInventory := LibraryRandom.RandDec(100, 2);

        // Exercise - transfer order, no shipping just add/remove inventory
        CreateAndShipTransfer(TransferHeader, Item."No.", LocationTwo.Code, LocationOne.Code, 3 * QtyOnInventory, Text002,
          WorkDate(), 0); // Qty=0 means nothing to ship
        AddInventoryNonDirectLocationWithLotNo(Item, LocationTwo.Code, QtyOnInventory, Text002);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate(PlanningEndDate, WorkDate())); // required in order to have the entries split in tab337
        RemoveInventoryNonDirectLocationWithLotNo(Item, LocationTwo.Code, QtyOnInventory, Text002);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines - check in doc section more info on the TDS
        AssertNumberOfLinesForItem(Item, 6);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, WorkDate(), 0, 2 * QtyOnInventory,
          RequisitionLine."Ref. Order Type"::Purchase, LocationWhite.Code, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, WorkDate(), 0, QtyOnInventory,
          RequisitionLine."Ref. Order Type"::Purchase, LocationWhite.Code, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, WorkDate(), 0, 2 * QtyOnInventory,
          RequisitionLine."Ref. Order Type"::Transfer, LocationThree.Code, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, WorkDate(), 0, QtyOnInventory,
          RequisitionLine."Ref. Order Type"::Transfer, LocationThree.Code, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, WorkDate(), 0, 2 * QtyOnInventory,
          RequisitionLine."Ref. Order Type"::Transfer, LocationTwo.Code, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, WorkDate(), 0, QtyOnInventory,
          RequisitionLine."Ref. Order Type"::Transfer, LocationTwo.Code, 1);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        LotNo: Code[10];
        Quantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LotNo := DequeueVariable;
        LibraryVariableStorage.Dequeue(DequeueVariable);
        Quantity := DequeueVariable;

        ItemTrackingLines."Lot No.".SetValue(LotNo);
        ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
