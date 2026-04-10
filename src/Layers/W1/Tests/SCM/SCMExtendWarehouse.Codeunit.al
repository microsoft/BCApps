codeunit 137030 "SCM Extend Warehouse"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        IsInitialized := false;
    end;

    var
        LocationWhite: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        IsInitialized: Boolean;
        ErrorMessageCounter: Integer;
        ROUTING_LINE_10: Label '10';
        ROUTING_LINE_20: Label '20';
        MSG_INVENTORY_MOVEMENT: Label 'inventory movement';
        MSG_INVENTORY_MOVEMENT_LINE: Label 'inventory movement line';
        MSG_THERE_NOTHING_TO_HANDLE: Label 'There is nothing to handle.';
        MSG_THERE_NOTHING_TO_CREATE: Label 'There is nothing to create.';
        MSG_NOTHING_TO_HANDLE: Label 'Nothing to handle.';
        MSG_CHANGE_LOC: Label 'will be removed. Are you sure that you want to continue?';
        MSG_ACTIVITIES_CREATED: Label 'activities created';
        MSG_WHSE_PICK: Label 'warehouse pick';
        MSG_WHSE_PICK_LINE: Label 'warehouse pick line';
        MSG_CREATE_MVMT: Label 'Do you want to create Inventory Movement?';
        MSG_WSHE_CREATED: Label 'Warehouse Shipment Header has been created.';
        MSG_QTY_NOT_RESERVED: Label 'Expected quantity not reserved.';
        MSG_USE_BIN: Label 'use this bin?';
        MSG_BEEN_CREATED: Label 'has been created';
        MSG_INVENTORY_PICK_LINE: Label 'inventory pick line';
        MSG_INVENTORY_PICK: Label 'inventory pick';
        MSG_MOVMT_CREATED: Label 'Number of Invt. Movement activities created: ';
        Text001: Label 'Qty. to Handle must';
        Text002: Label 'Qty. to Handle must not be Qty. Outstanding';
        MSG_THERE_NOTHING_TO_REGISTER: Label 'There is nothing to register.';
        Text003: Label 'The total base quantity to take 10 must be equal to the total base quantity to place 0.';
        Text004: Label 'activities created';
        Text006: Label 'Do you still want to delete the Warehouse Activity Line';
        MSG_HAS_BEEN_CREATED: Label 'has been created.';
        MSG_UNMATCHED_BIN_CODE: Label 'This change may have caused bin codes on some production order component lines to be different from those on the production order routing line. Do you want to automatically align all of these unmatched bin codes?';
        MSG_PICK_CREATED: Label 'Number of Invt. Pick activities created: ';
        MSG_MUST_SPECIFY_LOCATION: Label 'Location Code must have a value in Warehouse Activity Header';
        MSG_DIRECT_NO: Label 'Directed Put-away and Pick must be';
        MSG_UPDATE_LINES: Label 'You have changed the To Bin Code on the Internal Movement Header, but it has not been changed on the existing internal movement lines.';
        MSG_WHSEEMPLEE: Label 'You cannot use Location Code';
        MSG_BIN_MANDATORY: Label 'Bin Mandatory must be ';
        UnitOfMeasureErr: Label 'The field Unit of Measure Code of table Internal Movement Line contains a value (%1) that cannot be found in the related table (Item Unit of Measure).', Comment = '%1= Unit of Measure Code.';
        BinCodeErr: Label 'Bin Code on Warehouse Activity Line should be equal to Bin Code on Whse Worksheet Line';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Extend Warehouse");
        // Initialize setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Extend Warehouse");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        GlobalSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Extend Warehouse");
    end;

    local procedure GlobalSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        NoSeriesSetup();

        // Journals setup
        ItemJournalSetup();
        ConsumptionJournalSetup();
        OutputJournalSetup();

        // Location setup - full WMS location takes time to create
        // for performance reasons create it once and reuse
        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 10);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, false);

        DisableWarnings();
    end;

    local procedure DisableWarnings()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure NoSeriesSetup()
    var
        InventorySetup: Record "Inventory Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
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

    local procedure ItemSetup(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; FlushingMethod: Enum "Flushing Method")
    begin
        LibraryInventory.CreateItem(Item);

        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
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

    local procedure OutputJournalSetup()
    begin
        Clear(OutputItemJournalTemplate);
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);

        Clear(OutputItemJournalBatch);
        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
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

    local procedure LocationSetup(var Location: Record Location; RequireReceive: Boolean; RequireShipment: Boolean; RequirePutAway: Boolean; RequirePick: Boolean; BinMandatory: Boolean; NoOfDedicBins: Integer; NoOfOtherBins: Integer)
    var
        WarehouseEmployee: Record "Warehouse Employee";
        BinCount: Integer;
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);

        for BinCount := 1 to NoOfOtherBins do
            CreateBins(Location, 'bin' + Format(BinCount), false);
        for BinCount := 1 to NoOfDedicBins do
            CreateBins(Location, 'bin' + Format(BinCount + NoOfOtherBins), true);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateBins(Location: Record Location; BinName: Text[20]; Dedicated: Boolean)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, Location.Code, BinName, '', '');
        Bin.Validate(Dedicated, Dedicated);
        Bin.Modify(true);
    end;

    local procedure ParentItemSetupOnBOM(var ParentItem: Record Item; ProductionBOMHeader: Record "Production BOM Header")
    begin
        // Create parent item
        ItemSetup(ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Flushing Method"::"Pick + Manual");

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

    local procedure ParentItemSetupOnBOMAndRouting(var ParentItem: Record Item; ProductionBOMHeader: Record "Production BOM Header"; RoutingHeader: Record "Routing Header")
    begin
        ParentItemSetupOnBOM(ParentItem, ProductionBOMHeader);
        ParentItem.Validate("Routing No.", RoutingHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateBOM(var ProductionBOMHeader: Record "Production BOM Header"; NoOfComponents: Integer; QtyPer: Integer)
    var
        ChildItem: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ProductionBOMLine: Record "Production BOM Line";
        Counter: Integer;
    begin
        // Choose any unit of measure
        UnitOfMeasure.Init();
        UnitOfMeasure.FindFirst();
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure.Code);

        // Create component lines in the BOM
        for Counter := 1 to NoOfComponents do begin
            ItemSetup(ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Flushing Method"::"Pick + Manual");
            LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '',
              ProductionBOMLine.Type::Item, ChildItem."No.", QtyPer);
        end;

        // Certify BOM
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center"; FlushingMethod: Enum "Flushing Method")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Modify(true);
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenter: Record "Work Center"; FlushingMethod: Enum "Flushing Method")
    begin
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenter."No.", 1);
        MachineCenter.Validate("Flushing Method", FlushingMethod);
        MachineCenter.Modify(true);
    end;

    local procedure RoutingSetup(var RoutingHeader: Record "Routing Header"; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: Record "Machine Center")
    begin
        CreateWorkCenter(WorkCenter[1], WorkCenter[1]."Flushing Method"::Manual);
        CreateMachineCenter(MachineCenter, WorkCenter[1], MachineCenter."Flushing Method"::Manual);
        CreateWorkCenter(WorkCenter[2], WorkCenter[2]."Flushing Method"::Manual);

        CreateRouting(RoutingHeader, MachineCenter, WorkCenter[2]);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateRouting(var RoutingHeader: Record "Routing Header"; MachineCenter: Record "Machine Center"; WorkCenter: Record "Work Center")
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', ROUTING_LINE_10, RoutingLine.Type::"Machine Center", MachineCenter."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', ROUTING_LINE_20, RoutingLine.Type::"Work Center", WorkCenter."No.");
    end;

    local procedure SetBinsOnWC(var WorkCenter: Record "Work Center"; LocationCode: Code[10]; ToBinCode: Code[20]; FromBinCode: Code[20]; OSFBBinCode: Code[20])
    begin
        WorkCenter.Validate("Location Code", LocationCode);
        WorkCenter.Validate("To-Production Bin Code", ToBinCode);
        WorkCenter.Validate("From-Production Bin Code", FromBinCode);
        WorkCenter.Validate("Open Shop Floor Bin Code", OSFBBinCode);
        WorkCenter.Modify(true);
    end;

    local procedure SetBinsOnMC(var MachineCenter: Record "Machine Center"; ToBinCode: Code[20]; FromBinCode: Code[20]; OSFBBinCode: Code[20])
    begin
        MachineCenter.Validate("To-Production Bin Code", ToBinCode);
        MachineCenter.Validate("From-Production Bin Code", FromBinCode);
        MachineCenter.Validate("Open Shop Floor Bin Code", OSFBBinCode);
        MachineCenter.Modify(true);
    end;

    local procedure SetBinsOnLocation(var Location: Record Location; ToBinCode: Code[20]; FromBinCode: Code[20]; OSFBBinCode: Code[20])
    begin
        Location.Validate("To-Production Bin Code", ToBinCode);
        Location.Validate("From-Production Bin Code", FromBinCode);
        Location.Validate("Open Shop Floor Bin Code", OSFBBinCode);
        Location.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; Location: Record Location; Bin: Record Bin; Quantity: Integer; ShipmentDate: Date)
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Quantity, Location.Code, ShipmentDate);
        if not Location."Require Shipment" then
            SalesLine.Validate("Bin Code", Bin.Code);
        SalesLine.Modify(true);
    end;

    local procedure ReserveSalesLine(var SalesLine: Record "Sales Line"; FullReservation: Boolean; QtyToReserve: Integer)
    var
        ReservationManagement: Codeunit "Reservation Management";
    begin
        ReservationManagement.SetReservSource(SalesLine);
        ReservationManagement.AutoReserve(FullReservation, '', SalesLine."Shipment Date",
          Round(QtyToReserve / SalesLine."Qty. per Unit of Measure", 0.00001), QtyToReserve);
        SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
    end;

    local procedure ReserveComponentLine(var ProdOrderComp: Record "Prod. Order Component"; FullReservation: Boolean; QtyToReserve: Integer)
    var
        ReservationManagement: Codeunit "Reservation Management";
    begin
        ReservationManagement.SetReservSource(ProdOrderComp);
        ReservationManagement.AutoReserve(FullReservation, '', ProdOrderComp."Due Date",
          Round(QtyToReserve / ProdOrderComp."Qty. per Unit of Measure", 0.00001), QtyToReserve);
        ProdOrderComp.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
    end;

    local procedure CreateInternalMovementGetBin(var InternalMovementHeader: Record "Internal Movement Header"; Item: Record Item; Location: Record Location; ToBin: Record Bin; BinContentFilter: Code[100])
    begin
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, ToBin.Code);
        LibraryWarehouse.GetBinContentInternalMovement(InternalMovementHeader, Location.Code, Item."No.", BinContentFilter);
    end;

    local procedure CreateInternalMovement(var InternalMovementHeader: Record "Internal Movement Header"; Location: Record Location; ToBin: Record Bin; Item: Record Item; FromBin: Record Bin; Quantity: Decimal)
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, ToBin.Code);
        LibraryWarehouse.CreateInternalMovementLine(
          InternalMovementHeader, InternalMovementLine, Item."No.", FromBin.Code, ToBin.Code, Quantity);
        InternalMovementLine.Validate("From Bin Code", FromBin.Code);
        InternalMovementLine.Validate("To Bin Code", ToBin.Code);
        InternalMovementLine.Modify(true);
    end;

    local procedure SetBinOnWhseShipmentLines(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; Bin: Record Bin)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.Init();
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindSet(true);

        if WarehouseShipmentHeader.Status = WarehouseShipmentHeader.Status::Released then
            LibraryWarehouse.ReopenWhseShipment(WarehouseShipmentHeader);

        repeat
            WarehouseShipmentLine.Validate("Bin Code", Bin.Code);
            WarehouseShipmentLine.Modify(true);
        until WarehouseShipmentLine.Next() = 0;
    end;

    local procedure SetBinAndCreateWhsePick(Location: Record Location; Bin: Record Bin)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WarehouseShipmentHeader.Init();
        WarehouseShipmentHeader.SetCurrentKey("Location Code");
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindLast();
        SetBinOnWhseShipmentLines(WarehouseShipmentHeader, Bin);
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);
    end;

    local procedure AutoFillQtyAndRegisterInvtMvmt(Location: Record Location)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.Init();
        WarehouseActivityHeader.SetCurrentKey("Location Code");
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindLast();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterInventoryMovement(Location: Record Location)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.Init();
        WarehouseActivityHeader.SetCurrentKey("Location Code");
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindLast();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindChild(ParentItem: Record Item; var ChildItem: Record Item; ChildIndex: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ParentItem."Production BOM No.");
        ProductionBOMLine.FindSet(true);

        if ChildIndex > 1 then
            ProductionBOMLine.Next(ChildIndex - 1);

        ChildItem.Get(ProductionBOMLine."No.");
    end;

    local procedure FindBin(var Bin: Record Bin; Location: Record Location; Dedicated: Boolean; BinIndex: Integer)
    begin
        Bin.Init();
        Bin.Reset();
        Bin.SetRange("Location Code", Location.Code);
        if Location."Directed Put-away and Pick" then
            Bin.SetRange("Zone Code", 'PRODUCTION');
        Bin.SetRange(Dedicated, Dedicated);
        Bin.FindSet(true);

        if BinIndex > 1 then
            Bin.Next(BinIndex - 1);
    end;

    local procedure FindComponent(var ProdOrderComp: Record "Prod. Order Component"; ProdOrderHdr: Record "Production Order"; ComponentItem: Record Item; ComponentIndex: Integer)
    begin
        ProdOrderComp.Init();
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderHdr."No.");
        ProdOrderComp.SetRange("Item No.", ComponentItem."No.");
        ProdOrderComp.FindSet(true);

        if ComponentIndex > 1 then
            ProdOrderComp.Next(ComponentIndex - 1);
    end;

    local procedure ChangeFlushingMethodOnItem(var Item: Record Item; FlushingMethod: Enum "Flushing Method")
    begin
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
    end;

    local procedure CreateRelProdOrderAndRefresh(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; OutputBinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", OutputBinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure SetBinCodeOnCompLines(var ProductionOrder: Record "Production Order"; Bin: Record Bin)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindSet(true);
        repeat
            ProdOrderComponent."Bin Code" := Bin.Code;
            ProdOrderComponent.Modify(true);
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure ChangeBinForComponent(ProdOrderComponent: Record "Prod. Order Component"; ToBinCode: Code[20])
    begin
        ProdOrderComponent."Bin Code" := ToBinCode;
        ProdOrderComponent.Modify(true);
    end;

    local procedure ChangeQtyOnCompLines(ProductionOrder: Record "Production Order"; NewQuantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindSet(true);
        repeat
            ProdOrderComponent.Validate("Quantity per", NewQuantity);
            ProdOrderComponent.Modify(true);
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure ChangeFromBinCodeOnIntMovLines(InternalMovementHeader: Record "Internal Movement Header"; NewBin: Record Bin)
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        Clear(InternalMovementLine);
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        InternalMovementLine.FindSet(true);
        repeat
            InternalMovementLine.Validate("From Bin Code", NewBin.Code);
            InternalMovementLine.Modify(true);
        until InternalMovementLine.Next() = 0;
    end;

    local procedure ChangeQtyOnIntMovLines(InternalMovementHeader: Record "Internal Movement Header"; Qty: Decimal)
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        Clear(InternalMovementLine);
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        InternalMovementLine.FindSet(true);
        repeat
            InternalMovementLine.Validate(Quantity, Qty);
            InternalMovementLine.Modify(true);
        until InternalMovementLine.Next() = 0;
    end;

    local procedure ChangeItemQtyOnInternalMvmt(InternalMovementHeader: Record "Internal Movement Header"; Item: Record Item; Quantity: Decimal)
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        InternalMovementLine.SetRange("Item No.", Item."No.");
        InternalMovementLine.FindSet(true);
        repeat
            InternalMovementLine.Validate(Quantity, Quantity);
            InternalMovementLine.Modify(true);
        until InternalMovementLine.Next() = 0;
    end;

    local procedure CalculateAndPostConsumption(ProductionOrder: Record "Production Order")
    begin
        ClearJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        Commit();
        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure AddInventoryNonDirectLocation(Item: Record Item; Location: Record Location; Bin: Record Bin; Qty: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ClearJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure AddVariantsToItem(Item: Record Item; VariantCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
    begin
        Clear(ItemVariant);
        ItemVariant.Init();
        ItemVariant.Validate("Item No.", Item."No.");
        ItemVariant.Validate(Code, VariantCode);
        ItemVariant.Insert(true);
    end;

    local procedure AddInvForVariantNonDirectedLoc(Item: Record Item; VariantCode: Code[10]; Location: Record Location; Bin: Record Bin; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ClearJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);

        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure AddComponentToProdOrder(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; QuantityPer: Decimal; LocationCode: Code[10]; BinCode: Code[20]; FlushingMethod: Enum "Flushing Method")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindLast();

        ProdOrderComponent.Init();
        ProdOrderComponent."Line No." += 10000;
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Validate("Flushing Method", FlushingMethod);
        ProdOrderComponent.Validate("Bin Code", BinCode);
        ProdOrderComponent.Validate("Quantity per", QuantityPer);
        ProdOrderComponent.Insert(true);
    end;

    local procedure ExplodeOutputJournal(ItemNo: Code[20]; ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ClearJournal(OutputItemJournalTemplate, OutputItemJournalBatch);

        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ItemNo, ProductionOrderNo);

        CODEUNIT.Run(CODEUNIT::"Output Jnl.-Expl. Route", ItemJournalLine);
    end;

    local procedure ExplodeAndPostOutputJournal(ItemNo: Code[20]; ProductionOrderNo: Code[20])
    begin
        ExplodeOutputJournal(ItemNo, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(OutputItemJournalTemplate.Name, OutputItemJournalBatch.Name);
    end;

    local procedure ChangeVariantAndBinOfComponent(ProductionOrder: Record "Production Order"; VariantCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        if ItemNo <> '' then
            ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindSet(true);
        repeat
            ProdOrderComponent.Validate("Variant Code", VariantCode);
            ProdOrderComponent."Bin Code" := BinCode;
            ProdOrderComponent.Modify(true);
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure FillQtyToHandle(ProductionOrder: Record "Production Order"; ActionType: Enum "Warehouse Action Type"; QtyToHandle: Decimal; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetCurrentKey(
          "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Unit of Measure Code");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
        WarehouseActivityLine.SetRange("Source Subtype", ProductionOrder.Status);
        WarehouseActivityLine.SetRange("Source No.", ProductionOrder."No.");
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Prod. Consumption");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure DeleteActivityTypeWithSrcDoc(ProductionOrder: Record "Production Order"; Location: Record Location; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetCurrentKey("Source Document", "Source No.", "Location Code");
        WarehouseActivityHeader.SetRange("Source Subtype", ProductionOrder.Status);
        WarehouseActivityHeader.SetRange("Source No.", ProductionOrder."No.");
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.SetRange(Type, ActivityType);
        WarehouseActivityHeader.FindFirst();
        WarehouseActivityHeader.Delete(true);
    end;

    local procedure ChangeBinInWhseActivityLine(ProductionOrder: Record "Production Order"; ActivityType: Enum "Warehouse Activity Type"; Quantity: Decimal; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetCurrentKey(
          "Activity Type", "No.", "Location Code", "Source Document", "Source No.", "Action Type", "Zone Code");
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Source No.", ProductionOrder."No.");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
        WarehouseActivityLine.SetRange("Location Code", ProductionOrder."Location Code");
        WarehouseActivityLine.SetRange(Quantity, Quantity);
        WarehouseActivityLine.FindSet(true);
        repeat
            WarehouseActivityLine.Validate("Bin Code", BinCode);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure SplitWhseActivityLine(ProductionOrder: Record "Production Order"; ActionType: Enum "Warehouse Action Type"; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetCurrentKey(
          "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Unit of Measure Code");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
        WarehouseActivityLine.SetRange("Source Subtype", ProductionOrder.Status);
        WarehouseActivityLine.SetRange("Source No.", ProductionOrder."No.");
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Prod. Consumption");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);
    end;

    local procedure DeleteWhseActivityLine(ProductionOrder: Record "Production Order"; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetCurrentKey(
          "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Unit of Measure Code");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
        WarehouseActivityLine.SetRange("Source Subtype", ProductionOrder.Status);
        WarehouseActivityLine.SetRange("Source No.", ProductionOrder."No.");
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Prod. Consumption");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindLast();
        WarehouseActivityLine.Delete(true);
    end;

    local procedure AutofillQtyToHandle(ProductionOrder: Record "Production Order")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetCurrentKey("Source Document", "Source No.", "Location Code");
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Prod. Consumption");
        WarehouseActivityHeader.SetRange("Source No.", ProductionOrder."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
    end;

    local procedure DeleteQtyToHandle(ProductionOrder: Record "Production Order")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetCurrentKey(
          "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Unit of Measure Code");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
        WarehouseActivityLine.SetRange("Source Subtype", ProductionOrder.Status);
        WarehouseActivityLine.SetRange("Source No.", ProductionOrder."No.");
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Prod. Consumption");
        WarehouseActivityLine.DeleteQtyToHandle(WarehouseActivityLine);
    end;

    local procedure GetLastActvHdrCreatedNoSource(var WhseActivityHdr: Record "Warehouse Activity Header"; Location: Record Location; ActivityType: Enum "Warehouse Activity Type")
    begin
        WhseActivityHdr.Init();
        WhseActivityHdr.SetRange("Location Code", Location.Code);
        WhseActivityHdr.SetRange(Type, ActivityType);
        WhseActivityHdr.FindLast();
    end;

    local procedure GetLastActvHdrCreatedWithSrc(var WhseActivityHdr: Record "Warehouse Activity Header"; Location: Record Location; ActivityType: Enum "Warehouse Activity Type"; SourceDoc: Enum "Warehouse Activity Source Document"; SourceNo: Code[30])
    begin
        WhseActivityHdr.Init();
        WhseActivityHdr.SetRange("Location Code", Location.Code);
        WhseActivityHdr.SetRange(Type, ActivityType);
        WhseActivityHdr.SetRange("Source Document", SourceDoc);
        WhseActivityHdr.SetRange("Source No.", SourceNo);
        WhseActivityHdr.FindLast();
    end;

    local procedure AssertActivityHdr(var WhseActivityHdr: Record "Warehouse Activity Header"; Location: Record Location; ActivityType: Enum "Warehouse Activity Type"; SourceDoc: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; NoOfLines: Integer; Message: Text[30])
    begin
        WhseActivityHdr.Init();
        WhseActivityHdr.SetCurrentKey("Source Document", "Source No.", "Location Code");
        WhseActivityHdr.SetRange("Source Document", SourceDoc);
        WhseActivityHdr.SetRange("Source No.", SourceNo);
        WhseActivityHdr.SetRange("Location Code", Location.Code);
        WhseActivityHdr.SetRange(Type, ActivityType);
        Assert.AreEqual(NoOfLines, WhseActivityHdr.Count, 'There are no ' + Format(NoOfLines) + ' ' + Message + ' within the filter: ' +
          WhseActivityHdr.GetFilters);
        if NoOfLines > 0 then
            WhseActivityHdr.FindSet(true);
    end;

    local procedure AssertNoActivityHdr(var WhseActivityHdr: Record "Warehouse Activity Header"; Location: Record Location; ActivityType: Enum "Warehouse Activity Type"; SourceDoc: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; Message: Text[30])
    begin
        AssertActivityHdr(WhseActivityHdr, Location, ActivityType, SourceDoc, SourceNo, 0, Message);
    end;

    local procedure AssertInvtMovement(ProductionOrder: Record "Production Order"; Item: Record Item; Location: Record Location; FromBin: Record Bin; ToBin: Record Bin; Quantity: Decimal; QuantityToHandle: Decimal; ExpectedCount: Integer)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", ExpectedCount, 'Inventory Movement');

        if ExpectedCount > 0 then begin
            AssertActivityLine(WarehouseActivityHeader, Item, FromBin, WarehouseActivityLine."Action Type"::Take,
              Quantity, QuantityToHandle, ExpectedCount, 'Inventory Movement line');
            AssertActivityLine(WarehouseActivityHeader, Item, ToBin, WarehouseActivityLine."Action Type"::Place,
              Quantity, QuantityToHandle, ExpectedCount, 'Inventory Movement line');
        end;
    end;

    local procedure AssertQtyOnInvtPick(WhseActivityHdr: Record "Warehouse Activity Header"; Qty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.SetRange("Activity Type", WhseActivityHdr.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHdr."No.");
        WhseActivityLine.FindFirst();
        WhseActivityLine.TestField(Quantity, Qty);
    end;

    local procedure AssertWhseActivityHdr(var WhseActivityHdr: Record "Warehouse Activity Header"; Location: Record Location; ActivityType: Enum "Warehouse Activity Type"; Message: Text[30])
    begin
        WhseActivityHdr.Init();
        WhseActivityHdr.SetRange("Location Code", Location.Code);
        WhseActivityHdr.SetRange(Type, ActivityType);
        WhseActivityHdr.FindLast();
        Assert.IsTrue(WhseActivityHdr.Count > 0, 'There are no ' + Message + ' within the filter: ' +
          WhseActivityHdr.GetFilters);
    end;

    local procedure AssertActivityLine(WhseActivityHdr: Record "Warehouse Activity Header"; Item: Record Item; Bin: Record Bin; ActionType: Enum "Warehouse Action Type"; Qty: Decimal; QtyToHandle: Decimal; NoOfLines: Integer; Message: Text[30])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.SetRange("No.", WhseActivityHdr."No.");
        WhseActivityLine.SetRange("Item No.", Item."No.");
        WhseActivityLine.SetRange("Bin Code", Bin.Code);
        WhseActivityLine.SetRange("Action Type", ActionType);
        WhseActivityLine.SetRange(Quantity, Qty);
        WhseActivityLine.SetRange("Qty. to Handle", QtyToHandle);
        Assert.AreEqual(NoOfLines, WhseActivityLine.Count, 'There are no ' + Format(NoOfLines) + ' ' + Message + ' within the filter: ' +
          WhseActivityLine.GetFilters);
    end;

    local procedure AssertInternalMovementLine(InternalMovementHeader: Record "Internal Movement Header"; Item: Record Item; Location: Record Location; FromBin: Record Bin; ToBin: Record Bin; Qty: Decimal; ExpectedCount: Integer)
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        Clear(InternalMovementLine);
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        InternalMovementLine.SetRange("Location Code", Location.Code);
        InternalMovementLine.SetRange("From Bin Code", FromBin.Code);
        InternalMovementLine.SetRange("To Bin Code", ToBin.Code);
        InternalMovementLine.SetRange("Item No.", Item."No.");
        InternalMovementLine.SetRange(Quantity, Qty);
        Assert.AreEqual(ExpectedCount, InternalMovementLine.Count, 'There are no ' + Format(ExpectedCount) +
          ' internal movement lines within the filter: ' + InternalMovementLine.GetFilters);
    end;

    local procedure AssertInternalMovementDeleted(InternalMovementHeader: Record "Internal Movement Header")
    var
        InternalMovementHeaderSecond: Record "Internal Movement Header";
    begin
        Clear(InternalMovementHeaderSecond);
        InternalMovementHeaderSecond.SetRange("No.", InternalMovementHeader."No.");
        Assert.AreEqual(0, InternalMovementHeaderSecond.Count, 'Internal movement is not deleted!');
    end;

    local procedure AssertRegisteredInvtMovement(var RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr."; SourceProdOrder: Record "Production Order"; SourceDoc: Enum "Warehouse Activity Source Document"; Item: Record Item; FromBin: Record Bin; ToBin: Record Bin; Quantity: Decimal; ExpectedCountOfHdr: Integer; ReturnHdrNo: Integer)
    var
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
    begin
        AssertRegisteredInvtMvmtHdr(RegisteredInvtMovementHdr, SourceProdOrder, SourceDoc, ExpectedCountOfHdr, ReturnHdrNo,
          'Registered Inventory Movement');

        if ExpectedCountOfHdr > 0 then begin
            AssertRegisteredInvtMvmtLine(RegisteredInvtMovementHdr, Item, FromBin, RegisteredInvtMovementLine."Action Type"::Take,
              Quantity, 1, 'Registered Inventory Movement line');
            AssertRegisteredInvtMvmtLine(RegisteredInvtMovementHdr, Item, ToBin, RegisteredInvtMovementLine."Action Type"::Place,
              Quantity, 1, 'Registered Inventory Movement line');
        end;
    end;

    local procedure AssertRegisteredInvtMvmtHdr(var RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr."; SourceProdOrder: Record "Production Order"; SourceDoc: Enum "Warehouse Activity Source Document"; ExpectedCountOfHdr: Integer; ReturnHdrNo: Integer; Message: Text[1024])
    begin
        RegisteredInvtMovementHdr.Reset();
        RegisteredInvtMovementHdr.SetRange("Source No.", SourceProdOrder."No.");
        RegisteredInvtMovementHdr.SetRange("Source Document", SourceDoc);
        RegisteredInvtMovementHdr.SetRange("Source Type", DATABASE::"Prod. Order Component");
        RegisteredInvtMovementHdr.SetRange("Source Subtype", SourceProdOrder.Status);

        Assert.AreEqual(
          ExpectedCountOfHdr, RegisteredInvtMovementHdr.Count, CopyStr('There are not ' + Format(ExpectedCountOfHdr) +
            Message + ' within the filter: ' + RegisteredInvtMovementHdr.GetFilters, 1, 1024));

        RegisteredInvtMovementHdr.FindSet(true);
        if ReturnHdrNo > 1 then
            RegisteredInvtMovementHdr.Next(ReturnHdrNo - 1);
    end;

    local procedure AssertRegisteredInvtMvmtLine(RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr."; Item: Record Item; Bin: Record Bin; ActionType: Enum "Warehouse Action Type"; Quantity: Decimal; ExpectedCount: Integer; Message: Text[1024])
    var
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
    begin
        RegisteredInvtMovementLine.SetRange("No.", RegisteredInvtMovementHdr."No.");
        RegisteredInvtMovementLine.SetRange("Action Type", ActionType);
        RegisteredInvtMovementLine.SetRange(Quantity, Quantity);
        RegisteredInvtMovementLine.SetRange("Bin Code", Bin.Code);
        RegisteredInvtMovementLine.SetRange("Item No.", Item."No.");

        Assert.AreEqual(
          ExpectedCount, RegisteredInvtMovementLine.Count, CopyStr('There are no ' + Format(ExpectedCount) + Message +
            ' within the filter: ' + RegisteredInvtMovementLine.GetFilters, 1, 1024));
    end;

    local procedure AssertActivityLineCount(WhseActivityHdr: Record "Warehouse Activity Header"; ExpectedNoOfLines: Integer)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.SetRange("No.", WhseActivityHdr."No.");
        WhseActivityLine.SetRange("Activity Type", WhseActivityHdr.Type);
        Assert.AreEqual(ExpectedNoOfLines, WhseActivityLine.Count, 'Mismatch in number of lines for the warehouse activity header');
    end;

    local procedure AssertCannotCreateIntlMvmt(InternalMovementHeader: Record "Internal Movement Header"; LocationCode: Code[10]; ToBinCode: Code[20]; Message: Text[1024])
    begin
        Commit(); // as assert error will roll-back
        asserterror
          LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, LocationCode, ToBinCode);
        Assert.IsTrue(StrPos(GetLastErrorText, Message) > 0, GetLastErrorText);

        ClearLastError();
    end;

    local procedure AssertCannotCreateInvtMvmt(InternalMovementHeader: Record "Internal Movement Header")
    begin
        Commit(); // as assert error will roll-back
        asserterror
          LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
        Assert.IsTrue(StrPos(GetLastErrorText, MSG_THERE_NOTHING_TO_HANDLE) > 0, GetLastErrorText);

        ClearLastError();
    end;

    local procedure AssertCannotCreateInvtMvmtMan(WarehouseActivityHeader: Record "Warehouse Activity Header"; Message: Text[1024])
    begin
        Commit(); // as assert error will roll-back
        asserterror
          LibraryWarehouse.GetSourceDocInventoryMovement(WarehouseActivityHeader);
        Assert.IsTrue(StrPos(GetLastErrorText, Message) > 0, GetLastErrorText);

        ClearLastError();
    end;

    local procedure AssertCannotCreateInvtMvmtProd(ProductionOrder: Record "Production Order")
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        Commit(); // as assert error will roll-back
        asserterror
          LibraryWarehouse.CreateInvtPutPickMovement(
            WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);
        Assert.IsTrue(StrPos(GetLastErrorText, MSG_THERE_NOTHING_TO_CREATE) > 0, GetLastErrorText);

        ClearLastError();
    end;

    local procedure AssertCannotCreateWhsePick(Location: Record Location; Bin: Record Bin)
    begin
        Commit(); // as assert error will roll-back
        asserterror
          SetBinAndCreateWhsePick(Location, Bin);
        Assert.IsTrue(StrPos(GetLastErrorText, MSG_NOTHING_TO_HANDLE) > 0, GetLastErrorText);

        ClearLastError();
    end;

    local procedure AssertCannotRegisterInvtMovm(Location: Record Location; Message: Text[1024])
    begin
        Commit(); // as assert error will roll-back
        asserterror
          RegisterInventoryMovement(Location);
        Assert.IsTrue(StrPos(GetLastErrorText, Message) > 0, GetLastErrorText);

        ClearLastError();
    end;

    local procedure AssertCannotSplitLine(ProductionOrder: Record "Production Order"; Qty: Decimal; Message: Text[1024])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        Commit(); // as assert error will roll-back
        asserterror
          SplitWhseActivityLine(ProductionOrder, WarehouseActivityLine."Action Type"::Take, Qty);
        Assert.IsTrue(StrPos(GetLastErrorText, Message) > 0, GetLastErrorText);

        ClearLastError();
    end;

    local procedure AssertProdOrderComponent(ProductionOrder: Record "Production Order"; ComponentItemNo: Code[30]; RemainingQty: Decimal; ExpQuantity: Decimal; PickedQuantity: Decimal; PickedQuantityBase: Decimal; LocationCode: Code[30]; BinCode: Code[30]; ExpectedCount: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItemNo);
        ProdOrderComponent.SetRange("Remaining Quantity", RemainingQty);
        ProdOrderComponent.SetRange("Expected Quantity", ExpQuantity);
        ProdOrderComponent.SetRange("Qty. Picked", PickedQuantity);
        ProdOrderComponent.SetRange("Qty. Picked (Base)", PickedQuantityBase);
        ProdOrderComponent.SetRange("Location Code", LocationCode);
        ProdOrderComponent.SetRange("Bin Code", BinCode);

        Assert.AreEqual(
          ExpectedCount, ProdOrderComponent.Count, 'There are no ' + Format(ExpectedCount) +
          ' production order component lines within the filter:  ' + ProdOrderComponent.GetFilters);
    end;

    local procedure AssertProdOrderLine(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]; BinCode: Code[20]; NoOfLines: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.SetRange(Quantity, Quantity);
        ProdOrderLine.SetRange("Location Code", LocationCode);
        ProdOrderLine.SetRange("Bin Code", BinCode);

        Assert.AreEqual(
          NoOfLines, ProdOrderLine.Count, 'There are no ' + Format(NoOfLines) +
          ' production order lines within the filter: ' + ProdOrderLine.GetFilters);
    end;

    local procedure AssertProdOrderRoutingLine(ProductionOrder: Record "Production Order"; OperationNo: Text[10]; Type: Enum "Capacity Type Routing"; No: Code[20]; LocationCode: Code[10]; ToBinCode: Code[20]; FromBinCode: Code[20]; OSFBBinCode: Code[20]; NoOfLines: Integer)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.SetRange(Type, Type);
        ProdOrderRoutingLine.SetRange("No.", No);
        ProdOrderRoutingLine.SetRange("Location Code", LocationCode);
        ProdOrderRoutingLine.SetRange("To-Production Bin Code", ToBinCode);
        ProdOrderRoutingLine.SetRange("From-Production Bin Code", FromBinCode);
        ProdOrderRoutingLine.SetRange("Open Shop Floor Bin Code", OSFBBinCode);

        Assert.AreEqual(
          NoOfLines, ProdOrderRoutingLine.Count, 'There are no ' + Format(NoOfLines) +
          ' production order routing lines within the filter: ' + ProdOrderRoutingLine.GetFilters);
    end;

    local procedure AssertOutputJournalLine(ProductionOrder: Record "Production Order"; OperationNo: Text[10]; Type: Enum "Capacity Type Routing"; No: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; NoOfLines: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", OutputItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", OutputItemJournalBatch.Name);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.SetRange("Operation No.", OperationNo);
        ItemJournalLine.SetRange(Type, Type);
        ItemJournalLine.SetRange("No.", No);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.SetRange("Bin Code", BinCode);

        Assert.AreEqual(
          NoOfLines, ItemJournalLine.Count,
          'There are no ' + Format(NoOfLines) + ' output journal lines within the filter: ' + ItemJournalLine.GetFilters);
    end;

    local procedure AssertWarehouseEntry(BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal; SourceType: Integer; SourceNo: Code[20]; SourceSubtype: Option; SourceDoc: Enum "Warehouse Journal Source Document"; ExpectedCount: Integer)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseEntry.SetRange("Source Type", SourceType);
        WarehouseEntry.SetRange("Source Subtype", SourceSubtype);
        if SourceType <> DATABASE::"Item Journal Line" then
            WarehouseEntry.SetRange("Source No.", SourceNo);
        WarehouseEntry.SetRange("Source Document", SourceDoc);
        WarehouseEntry.SetRange("Bin Code", BinCode);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Variant Code", VariantCode);
        WarehouseEntry.SetRange(Quantity, Quantity);

        Assert.AreEqual(
          ExpectedCount, WarehouseEntry.Count, 'There is wrong number within the filter: ' +
          WarehouseEntry.GetFilters);
    end;

    local procedure TestSetup()
    begin
        UpdatePlanningSetup();
        ErrorMessageCounter := 0;
    end;

    local procedure DedicatedBinTestSetup(var ParentItem: Record Item; var Location: Record Location; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: Record "Machine Center"; var ToBin: array[2] of Record Bin; var FromBin: array[2] of Record Bin; var OSFBBin: array[2] of Record Bin)
    var
        RoutingHeader: Record "Routing Header";
        BOMHeader: Record "Production BOM Header";
    begin
        // Test setup
        TestSetup();

        // Create Produced item and child
        CreateBOM(BOMHeader, 2, 2);
        RoutingSetup(RoutingHeader, WorkCenter, MachineCenter);
        ParentItemSetupOnBOMAndRouting(ParentItem, BOMHeader, RoutingHeader);
        PopulateBinsTestSetup(Location, ToBin, FromBin, OSFBBin);

        // Reload location code as it changed
        Location.Get(Location.Code);
    end;

    local procedure PopulateBinsTestSetup(Location: Record Location; var ToBin: array[2] of Record Bin; var FromBin: array[2] of Record Bin; var OSFBBin: array[2] of Record Bin)
    begin
        FindBin(ToBin[1], Location, not Location."Directed Put-away and Pick", 1);
        FindBin(FromBin[1], Location, not Location."Directed Put-away and Pick", 2);
        FindBin(OSFBBin[1], Location, not Location."Directed Put-away and Pick", 3);
        FindBin(ToBin[2], Location, not Location."Directed Put-away and Pick", 4);
        FindBin(FromBin[2], Location, not Location."Directed Put-away and Pick", 5);
        FindBin(OSFBBin[2], Location, not Location."Directed Put-away and Pick", 6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItemAvailabilityWhenCreatingPickAndExistReservedQtyForProdOrder()
    var
        Item: Record Item;
        ItemComponent: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QtyUnit: Decimal;

    begin
        Initialize();
        QtyUnit := LibraryRandom.RandIntInRange(30, 50);

        // [GIVEN] Parent item with child item and Production BOM
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");
        CreateBOM(ProductionBOMHeader, 1, 2 * QtyUnit);
        ParentItemSetupOnBOM(Item, ProductionBOMHeader);
        FindChild(Item, ItemComponent, 1);

        // [GIVEN] Warehouse employee with default location directed put-away and pick
        SetWarehouseEmployeeDefaultLocation(LocationWhite.Code);

        // [GIVEN] location directed put-away and pick with dedicated bins for production
        SetProductionBinsAsDedicated(LocationWhite);

        // [GIVEN] Inventory in pickable bin of component item 
        FindBinForPick(Bin, LocationWhite, false, 1);
        UpdateInventoryUsingWarehouseJournal(Bin, ItemComponent, 3 * QtyUnit, ItemComponent."Base Unit of Measure", false);

        // [GIVEN] Released Production Order with reserved quantity
        CreateRelProdOrderAndRefresh(ProductionOrder, Item."No.", 1, LocationWhite.Code, '');
        FindComponent(ProdOrderComponent, ProductionOrder, ItemComponent, 1);
        ReserveComponentLine(ProdOrderComponent, false, 2 * QtyUnit);

        // [GIVEN] Created warehouse pick from production, partly registered and deleted rest
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        UpdateQtyToHandleRegisterPickAndDeleteRest(ProdOrderComponent, 2 * QtyUnit, 0.9);

        Clear(ProductionOrder);
        Clear(ProdOrderComponent);
        Clear(WarehouseActivityLine);

        // [WHEN] Create new production order for same item and warehouse pick from production
        CreateRelProdOrderAndRefresh(ProductionOrder, Item."No.", 1, LocationWhite.Code, '');
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        FindComponent(ProdOrderComponent, ProductionOrder, ItemComponent, 1);

        // [THEN] Warehouse activity lines are created just for the remaining quantity
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
         WarehouseActivityLine, Database::"Prod. Order Component", ProdOrderComponent."Status".AsInteger(), ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
        WarehouseActivityLine.TestField(Quantity, QtyUnit);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC1TC11Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC1TC11(Location);
    end;

    local procedure SC1TC11(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        FromBin: Record Bin;
        ToBin: Record Bin;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 20);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, ToBin.Code);
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        // Create inventory movement - no location code
        LibraryWarehouse.CreateInventoryMovementHeader(WarehouseActivityHeader, '');

        // check that get source doc returns error
        AssertCannotCreateInvtMvmtMan(WarehouseActivityHeader, MSG_MUST_SPECIFY_LOCATION);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC31MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_HAS_BEEN_CREATED) > 0, Message);
    end;

    [Test]
    [HandlerFunctions('TC31MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC31Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 0, 2);
        SC3TC31GetBinContent(Location);
    end;

    [Test]
    [HandlerFunctions('TC31MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC31Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 0, 2);
        SC3TC31GetBinContent(Location);
    end;

    local procedure SC3TC31GetBinContent(Location: Record Location)
    var
        Item: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 10);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);

        // Assert internal movement line
        AssertInternalMovementLine(InternalMovementHeader, Item, Location, FirstBin, SecondBin, 10, 1);

        // set qty to handle and create movement
        LibraryWarehouse.SetQtyToHandleInternalMovement(InternalMovementHeader, 5);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Verify that inventory movement is created and internal movement deleted
        AssertInternalMovementDeleted(InternalMovementHeader);
        GetLastActvHdrCreatedNoSource(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement");
        AssertActivityLine(WhseActivityHdr, Item, FirstBin, WhseActivityLine."Action Type"::Take, 5, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, SecondBin, WhseActivityLine."Action Type"::Place, 5, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
    end;

    [Test]
    [HandlerFunctions('TC31MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC32Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 0, 3);
        SC3TC32GetBinContent(Location);
    end;

    [Test]
    [HandlerFunctions('TC31MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC32Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 0, 3);
        SC3TC32GetBinContent(Location);
    end;

    local procedure SC3TC32GetBinContent(Location: Record Location)
    var
        Item: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        ThirdBin: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);
        FindBin(ThirdBin, Location, false, 3);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 10);
        AddInventoryNonDirectLocation(Item, Location, SecondBin, 20);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, ThirdBin,
          FirstBin.Code + '|' + SecondBin.Code);

        // Assert internal movement line
        AssertInternalMovementLine(InternalMovementHeader, Item, Location, FirstBin, ThirdBin, 10, 1);
        AssertInternalMovementLine(InternalMovementHeader, Item, Location, SecondBin, ThirdBin, 20, 1);

        // set qty to handle and create movement
        LibraryWarehouse.SetQtyToHandleInternalMovement(InternalMovementHeader, 5);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Verify that inventory movement is created and internal movement deleted
        AssertInternalMovementDeleted(InternalMovementHeader);
        GetLastActvHdrCreatedNoSource(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement");
        AssertActivityLine(WhseActivityHdr, Item, FirstBin, WhseActivityLine."Action Type"::Take, 5, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, SecondBin, WhseActivityLine."Action Type"::Take, 5, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, ThirdBin, WhseActivityLine."Action Type"::Place, 5, 0, 2, MSG_INVENTORY_MOVEMENT_LINE);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC33DirectedLocation()
    var
        Item: Record Item;
        FirstBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, LocationWhite, false, 1);

        // Exercise
        Commit(); // as assert error will roll-back
        asserterror
          CreateInternalMovementGetBin(InternalMovementHeader, Item, LocationWhite, FirstBin, '');
        Assert.IsTrue(StrPos(GetLastErrorText, MSG_DIRECT_NO) > 0, GetLastErrorText);

        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('TC31MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC37Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 0, 2);
        SC3TC37Register(Location);
    end;

    [Test]
    [HandlerFunctions('TC31MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC37Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 0, 2);
        SC3TC37Register(Location);
    end;

    local procedure SC3TC37Register(Location: Record Location)
    var
        Item: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 10);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);

        // set qty to handle and create movement
        LibraryWarehouse.SetQtyToHandleInternalMovement(InternalMovementHeader, 5);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        AutoFillQtyAndRegisterInvtMvmt(Location);

        // Check the warehouse entries
        AssertWarehouseEntry(FirstBin.Code, Item."No.", '', 10, DATABASE::"Item Journal Line", '',
          0, WarehouseEntry."Source Document"::"Item Jnl.", 1);
        AssertWarehouseEntry(FirstBin.Code, Item."No.", '', -5, 0, '', 0, "Warehouse Activity Source Document"::" ", 1);
        AssertWarehouseEntry(SecondBin.Code, Item."No.", '', 5, 0, '', 0, "Warehouse Activity Source Document"::" ", 1);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC38MessageHandler(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_THERE_NOTHING_TO_HANDLE) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('TC38MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC38Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 0, 2);
        SC3TC38NotInTheBin(Location);
    end;

    [Test]
    [HandlerFunctions('TC38MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC38Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 0, 2);
        SC3TC38NotInTheBin(Location);
    end;

    local procedure SC3TC38NotInTheBin(Location: Record Location)
    var
        Item: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 10);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);

        // Change from bin code and assert line
        ChangeFromBinCodeOnIntMovLines(InternalMovementHeader, SecondBin);
        AssertInternalMovementLine(InternalMovementHeader, Item, Location, SecondBin, SecondBin, 0, 1);

        // try to create movement
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC39MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_HAS_BEEN_CREATED) > 0, Message);
    end;

    [Test]
    [HandlerFunctions('TC39MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC39Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 0, 2);
        SC3TC39InternalMovManual(Location);
    end;

    [Test]
    [HandlerFunctions('TC39MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC39Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 0, 2);
        SC3TC39InternalMovManual(Location);
    end;

    local procedure SC3TC39InternalMovManual(Location: Record Location)
    var
        Item: Record Item;
        FromBin: Record Bin;
        ToBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FromBin, 10);

        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, ToBin.Code);
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, Item."No.", FromBin.Code, ToBin.Code, 10);
        ChangeQtyOnIntMovLines(InternalMovementHeader, 5);

        // create movement
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Assert invt movement
        AssertInternalMovementDeleted(InternalMovementHeader);
        GetLastActvHdrCreatedNoSource(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement");
        AssertActivityLine(WhseActivityHdr, Item, FromBin, WhseActivityLine."Action Type"::Take, 5, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, ToBin, WhseActivityLine."Action Type"::Place, 5, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC310MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_HAS_BEEN_CREATED) > 0, Message);
    end;

    [Test]
    [HandlerFunctions('TC310MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC310Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 0, 2);
        SC3TC310IntlMovManual2Lines(Location);
    end;

    [Test]
    [HandlerFunctions('TC310MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC310Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 0, 2);
        SC3TC310IntlMovManual2Lines(Location);
    end;

    local procedure SC3TC310IntlMovManual2Lines(Location: Record Location)
    var
        Item: Record Item;
        FromBin1: Record Bin;
        FromBin2: Record Bin;
        ToBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FromBin1, Location, false, 1);
        FindBin(FromBin2, Location, false, 2);
        FindBin(ToBin, Location, false, 3);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FromBin1, 10);
        AddInventoryNonDirectLocation(Item, Location, FromBin2, 20);

        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, ToBin.Code);
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, Item."No.", FromBin1.Code, ToBin.Code, 10);
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, Item."No.", FromBin2.Code, ToBin.Code, 20);
        ChangeQtyOnIntMovLines(InternalMovementHeader, 5);

        // create movement
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Assert invt movement
        AssertInternalMovementDeleted(InternalMovementHeader);
        GetLastActvHdrCreatedNoSource(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement");
        AssertActivityLine(WhseActivityHdr, Item, FromBin1, WhseActivityLine."Action Type"::Take, 5, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, FromBin2, WhseActivityLine."Action Type"::Take, 5, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, ToBin, WhseActivityLine."Action Type"::Place, 5, 0, 2, MSG_INVENTORY_MOVEMENT_LINE);
    end;

    [Test]
    [HandlerFunctions('TC31MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC313Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC3TC313(Location);
    end;

    local procedure SC3TC313(Location: Record Location)
    var
        TestItem: Record Item;
        FromBin: Record Bin;
        ToBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Test setup
        TestSetup();

        ItemSetup(TestItem, TestItem."Replenishment System"::Purchase, TestItem."Flushing Method"::"Pick + Manual");

        FindBin(FromBin, Location, false, 1);
        AddInventoryNonDirectLocation(TestItem, Location, FromBin, 10);

        // create Internal Movement
        FindBin(ToBin, Location, false, 2);
        CreateInternalMovement(InternalMovementHeader, Location, ToBin, TestItem, FromBin, 10);
        ChangeItemQtyOnInternalMvmt(InternalMovementHeader, TestItem, 5);

        // create Inventory Movement
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
        AssertInternalMovementDeleted(InternalMovementHeader);

        GetLastActvHdrCreatedNoSource(
          WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement");
        AssertActivityLine(
          WarehouseActivityHeader, TestItem, FromBin, WarehouseActivityLine."Action Type"::Take,
          5, 0, 1, 'Inventory Movement line');
        AssertActivityLine(
          WarehouseActivityHeader, TestItem, ToBin, WarehouseActivityLine."Action Type"::Place,
          5, 0, 1, 'Inventory Movement line');

        // autofill Qty. to Handle and Register Invt. Movement
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        AssertNoActivityHdr(
          WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::" ", '', 'Inventory Movement Header');

        AssertWarehouseEntry(
          FromBin.Code, TestItem."No.", '', 10, DATABASE::"Item Journal Line", '', 0,
          WarehouseEntry."Source Document"::"Item Jnl.", 1);
        AssertWarehouseEntry(FromBin.Code, TestItem."No.", '', -5, 0, '', 0, "Warehouse Activity Source Document"::" ", 1);
        AssertWarehouseEntry(ToBin.Code, TestItem."No.", '', 5, 0, '', 0, "Warehouse Activity Source Document"::" ", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC314Blue()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, false, false, 6, 4);
        SC3TC314(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC314Green()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, false, 6, 4);
        SC3TC314(Location);
    end;

    local procedure SC3TC314(Location: Record Location)
    var
        Item: Record Item;
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::Purchase, Item."Flushing Method"::"Pick + Manual");

        // create an internal movement - Error message that Bin mandatory is required should be displayed.
        InternalMovementHeader.Init();
        AssertCannotCreateIntlMvmt(InternalMovementHeader, Location.Code, '', MSG_BIN_MANDATORY);
    end;

    [Test]
    [HandlerFunctions('TC315MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC315Silver()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Bin] [Inventory Movement] [Internal Movement]
        // [SCENARIO 313841] When create Inventory Movement from Internal Movement with two lines and 2nd line has zero Qty
        // [SCENARIO 313841] then Inventory Movement is created from the 1st line, Internal Movement has only 2nd line
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC3TC315(Location);
    end;

    [Test]
    [HandlerFunctions('TC315MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC315Orange()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Bin] [Inventory Movement] [Internal Movement]
        // [SCENARIO 313841] When create Inventory Movement from Internal Movement with two lines and 2nd line has zero Qty
        // [SCENARIO 313841] then Inventory Movement is created from the 1st line, Internal Movement has only 2nd line
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC3TC315(Location);
    end;

    local procedure SC3TC315(Location: Record Location)
    var
        Item: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        ThirdBin: Record Bin;
        ToBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::Purchase, Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);
        FindBin(ThirdBin, Location, false, 3);
        FindBin(ToBin, Location, false, 4);

        // Add to inventory
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 10);
        AddInventoryNonDirectLocation(Item, Location, SecondBin, 10);

        // Create internal movement and get bin content
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, ToBin, FirstBin.Code + '|' + SecondBin.Code);

        // Verify new internal movement lines
        AssertInternalMovementLine(InternalMovementHeader, Item, Location, FirstBin, ToBin, 10, 1);
        AssertInternalMovementLine(InternalMovementHeader, Item, Location, SecondBin, ToBin, 10, 1);

        // Change the From Bin Code in the second line to a bin that does not contain item TEST
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        InternalMovementLine.SetRange("From Bin Code", SecondBin.Code);
        InternalMovementLine.FindFirst();
        InternalMovementLine.Validate("From Bin Code", ThirdBin.Code); // Quantity becomes <zero> in the line
        InternalMovementLine.Modify(true);

        // Use function -> Create inventory movement
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Verify that inventory movement is created and internal movement is not deleted
        AssertInternalMovementLine(InternalMovementHeader, Item, Location, ThirdBin, ToBin, 0, 1);
        GetLastActvHdrCreatedNoSource(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement");
        AssertActivityLine(WhseActivityHdr, Item, FirstBin, WhseActivityLine."Action Type"::Take, 10, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, ToBin, WhseActivityLine."Action Type"::Place, 10, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLineCount(WhseActivityHdr, 2);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC315MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_BEEN_CREATED) > 0, Message);
    end;

    [Test]
    [HandlerFunctions('TC316MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC316Silver()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Bin] [Inventory Movement] [Internal Movement]
        // [SCENARIO 313841] When create Inventory Movement from Internal Movement with two lines and 2nd line has wrong From-Bin
        // [SCENARIO 313841] then Inventory Movement is created from the 1st line, Internal Movement has only 2nd line
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC3TC316(Location);
    end;

    [Test]
    [HandlerFunctions('TC316MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC316Orange()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Bin] [Inventory Movement] [Internal Movement]
        // [SCENARIO 313841] When create Inventory Movement from Internal Movement with two lines and 2nd line has wrong From-Bin
        // [SCENARIO 313841] then Inventory Movement is created from the 1st line, Internal Movement has only 2nd line
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC3TC316(Location);
    end;

    local procedure SC3TC316(Location: Record Location)
    var
        Item: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        ToBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::Purchase, Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);
        FindBin(ToBin, Location, false, 3);

        // Add to inventory
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 10);
        AddInventoryNonDirectLocation(Item, Location, SecondBin, 10);

        // Create internal movement and get bin content
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, ToBin, FirstBin.Code + '|' + SecondBin.Code);

        // Verify new internal movement lines
        AssertInternalMovementLine(InternalMovementHeader, Item, Location, FirstBin, ToBin, 10, 1);
        AssertInternalMovementLine(InternalMovementHeader, Item, Location, SecondBin, ToBin, 10, 1);

        // Change the From Bin Code in the second line to same bin as first line- check Quantity field is changed to 0.
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        InternalMovementLine.SetRange("From Bin Code", SecondBin.Code);
        InternalMovementLine.FindFirst();
        InternalMovementLine.Validate("From Bin Code", FirstBin.Code);
        InternalMovementLine.Modify(true);
        Assert.AreEqual(0, InternalMovementLine.Quantity, 'Quantity not zeroed out.');

        // Change the qty on second line to 10
        InternalMovementLine.Validate(Quantity, 10);
        InternalMovementLine.Modify(true);

        // Use function -> Create inventory movement
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Verify that inventory movement is created and internal movement is not deleted
        AssertInternalMovementLine(InternalMovementHeader, Item, Location, FirstBin, ToBin, 10, 1);
        GetLastActvHdrCreatedNoSource(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement");
        AssertActivityLine(WhseActivityHdr, Item, FirstBin, WhseActivityLine."Action Type"::Take, 10, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, ToBin, WhseActivityLine."Action Type"::Place, 10, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLineCount(WhseActivityHdr, 2);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC316MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_BEEN_CREATED) > 0, Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC317Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC3TC317(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC317Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC3TC317(Location);
    end;

    local procedure SC3TC317(Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
        SecondBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();

        // clear the warehouse employee entries
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.DeleteAll(true);

        // create an internal movement - check for error
        SecondBin.Init();
        AssertCannotCreateIntlMvmt(InternalMovementHeader, Location.Code, SecondBin.Code, MSG_WHSEEMPLEE);

        // Add current user to whse employee, location TEST, default = yes
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // create an internal movement - no error
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, SecondBin.Code);

        // Clear the location code
        Commit(); // as assert error will roll-back
        asserterror
          InternalMovementHeader.Validate("Location Code", '');
        Assert.IsTrue(StrPos(GetLastErrorText, MSG_WHSEEMPLEE) > 0, 'User allowed to blank loc code on internal movement.');
    end;

    [Test]
    [HandlerFunctions('TC318MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC318Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC3TC318(Location);
    end;

    [Test]
    [HandlerFunctions('TC318MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC3TC318Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC3TC318(Location);
    end;

    local procedure SC3TC318(Location: Record Location)
    var
        Item: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        ThirdBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::Purchase, Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);
        FindBin(ThirdBin, Location, false, 3);

        // Add to inventory
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 10);

        // Create internal movement and get bin content
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);

        // Verify internal movement line
        AssertInternalMovementLine(InternalMovementHeader, Item, Location, FirstBin, SecondBin, 10, 1);

        // Change the To Bin Code to a different value
        InternalMovementHeader.Validate("To Bin Code", ThirdBin.Code);
        InternalMovementHeader.Modify(true);

        // Create inventory movement
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Verify that inventory movement is created and internal movement deleted
        AssertInternalMovementDeleted(InternalMovementHeader);
        GetLastActvHdrCreatedNoSource(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement");
        AssertActivityLine(WhseActivityHdr, Item, FirstBin, WhseActivityLine."Action Type"::Take, 10, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, SecondBin, WhseActivityLine."Action Type"::Place, 10, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC318MessageHandler(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;
        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_UPDATE_LINES) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, MSG_BEEN_CREATED) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC41Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC41(Location);
    end;

    local procedure SC4TC41(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin, ToBin, 20, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC42Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC42(Location);
    end;

    local procedure SC4TC42(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 3);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin, ToBin, 3, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerNothing')]
    [Scope('OnPrem')]
    procedure SC4TC43Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC43(Location);
    end;

    local procedure SC4TC43(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        FromBin: Record Bin;
        ToBin: Record Bin;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);

        // create Released Production Order for Silver location and refresh it
        FindBin(ToBin, Location, false, 3);
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement is not created
        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerNothing')]
    [Scope('OnPrem')]
    procedure SC4TC44Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC44(Location);
    end;

    local procedure SC4TC44(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);

        // create Released Production Order for Silver location and refresh it
        FindBin(ToBin, Location, false, 3);
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        // change quantity of component
        ChangeQtyOnCompLines(ProductionOrder, 0);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement is not created
        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC45Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC45(Location);
    end;

    local procedure SC4TC45(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin1: Record Bin;
        FromBin2: Record Bin;
        ToBin: Record Bin;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin1, Location, false, 1);
        FindBin(FromBin2, Location, false, 2);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin1, 6);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin2, 4);

        // create Released Production Order for Silver location and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 5, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin1, ToBin, 6, 0, 1);
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin2, ToBin, 4, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC46Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC46(Location);
    end;

    local procedure SC4TC46(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin1: Record Bin;
        FromBin2: Record Bin;
        ToBin: Record Bin;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin1, Location, false, 1);
        FindBin(FromBin2, Location, false, 2);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin1, 3);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin2, 4);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 5, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin1, ToBin, 3, 0, 1);
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin2, ToBin, 4, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC47Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC47(Location);
    end;

    local procedure SC4TC47(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // split Take line
        SplitWhseActivityLine(ProductionOrder, WarehouseActivityLine."Action Type"::Take, 6);

        // check Inventory Movement
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, MSG_INVENTORY_MOVEMENT);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, FromBin, WarehouseActivityLine."Action Type"::Take,
          6, 6, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, FromBin, WarehouseActivityLine."Action Type"::Take,
          14, 14, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,DeleteWhseActivityLineConfirm')]
    [Scope('OnPrem')]
    procedure SC4TC48Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC48(Location);
    end;

    local procedure SC4TC48(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // split Take line
        SplitWhseActivityLine(ProductionOrder, WarehouseActivityLine."Action Type"::Take, 6);

        // delete the last Take line
        DeleteWhseActivityLine(ProductionOrder, WarehouseActivityLine."Action Type"::Take);
        NotificationLifecycleMgt.RecallAllNotifications();

        // check Inventory Movement
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, MSG_INVENTORY_MOVEMENT);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, FromBin, WarehouseActivityLine."Action Type"::Take,
          6, 6, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
    end;

    [Test]
    [HandlerFunctions('MessageHandler_TC49')]
    [Scope('OnPrem')]
    procedure SC4TC49Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC49(Location);
    end;

    local procedure SC4TC49(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // split Take line
        SplitWhseActivityLine(ProductionOrder, WarehouseActivityLine."Action Type"::Take, 6);

        // delete the Place line
        DeleteWhseActivityLine(ProductionOrder, WarehouseActivityLine."Action Type"::Place);
        NotificationLifecycleMgt.RecallAllNotifications();

        // check Inventory Movement has no lines
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, MSG_INVENTORY_MOVEMENT);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, FromBin, WarehouseActivityLine."Action Type"::Take,
          6, 0, 0, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, FromBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 0, MSG_INVENTORY_MOVEMENT_LINE);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC410Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC410(Location);
    end;

    local procedure SC4TC410(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // split Take line
        AssertCannotSplitLine(ProductionOrder, 0, Text001);
        AssertCannotSplitLine(ProductionOrder, 20, Text002);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC411Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC411(Location);
    end;

    local procedure SC4TC411(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // split Take line
        SplitWhseActivityLine(ProductionOrder, WarehouseActivityLine."Action Type"::Take, 6);

        // Autofill Qty. to Handle
        AutofillQtyToHandle(ProductionOrder);

        // check Inventory Movement
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, MSG_INVENTORY_MOVEMENT);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, FromBin, WarehouseActivityLine."Action Type"::Take,
          6, 6, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, FromBin, WarehouseActivityLine."Action Type"::Take,
          14, 14, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 20, 1, MSG_INVENTORY_MOVEMENT_LINE);

        // delete Qty. to Handle
        DeleteQtyToHandle(ProductionOrder);

        // check Inventory Movement
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, MSG_INVENTORY_MOVEMENT);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, FromBin, WarehouseActivityLine."Action Type"::Take,
          6, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, FromBin, WarehouseActivityLine."Action Type"::Take,
          14, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC412Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC412(Location);
    end;

    local procedure SC4TC412(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseEntry: Record "Warehouse Entry";
        ChildItem: Record Item;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Autofill Qty. to Handle
        AutofillQtyToHandle(ProductionOrder);

        RegisterInventoryMovement(Location);

        // check Warehouse Entries
        AssertWarehouseEntry(
          FromBin.Code, ChildItem."No.", '', 100, DATABASE::"Item Journal Line", '',
          0, WarehouseEntry."Source Document"::"Item Jnl.", 1);

        AssertWarehouseEntry(
          FromBin.Code, ChildItem."No.", '', -20, DATABASE::"Prod. Order Component", ProductionOrder."No.",
          ProductionOrder.Status.AsInteger(), WarehouseEntry."Source Document"::"Prod. Consumption", 1);

        AssertWarehouseEntry(
          ToBin.Code, ChildItem."No.", '', 20, DATABASE::"Prod. Order Component", ProductionOrder."No.",
          ProductionOrder.Status.AsInteger(), WarehouseEntry."Source Document"::"Prod. Consumption", 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC413Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC413(Location);
    end;

    local procedure SC4TC413(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        ChildItem: Record Item;
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindChild(ParentItem, ChildItem, 1);

        // Creating 2 variants
        AddVariantsToItem(ChildItem, 'ONE');
        AddVariantsToItem(ChildItem, 'TWO');

        // Positive adjustment
        FindBin(FromBin, Location, false, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);
        AddInvForVariantNonDirectedLoc(ChildItem, 'ONE', Location, FromBin, 100);

        // create Released Production Order and refresh it
        FindBin(ToBin, Location, false, 3);
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        ChangeVariantAndBinOfComponent(ProductionOrder, 'ONE', ToBin.Code, '');

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Autofill Qty. to Handle
        AutofillQtyToHandle(ProductionOrder);

        RegisterInventoryMovement(Location);

        // check Warehouse Entries
        FindChild(ParentItem, ChildItem, 1);

        AssertWarehouseEntry(
          FromBin.Code, ChildItem."No.", 'ONE', 100, DATABASE::"Item Journal Line", '',
          0, WarehouseEntry."Source Document"::"Item Jnl.", 1);

        AssertWarehouseEntry(
          FromBin.Code, ChildItem."No.", 'ONE', -20, DATABASE::"Prod. Order Component", ProductionOrder."No.",
          ProductionOrder.Status.AsInteger(), WarehouseEntry."Source Document"::"Prod. Consumption", 1);

        AssertWarehouseEntry(
          ToBin.Code, ChildItem."No.", 'ONE', 20, DATABASE::"Prod. Order Component", ProductionOrder."No.",
          ProductionOrder.Status.AsInteger(), WarehouseEntry."Source Document"::"Prod. Consumption", 1);

        AssertWarehouseEntry(
          FromBin.Code, ChildItem."No.", '', 100, DATABASE::"Item Journal Line", '',
          0, WarehouseEntry."Source Document"::"Item Jnl.", 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC414Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC414(Location);
    end;

    local procedure SC4TC414(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ChildItem: Record Item;
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Autofill Qty. to Handle
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Take, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Place, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        RegisterInventoryMovement(Location);

        // check Inventory Movement
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin, ToBin, 20, 10, 1);

        // Check whse entries
        AssertWarehouseEntry(
          FromBin.Code, ChildItem."No.", '', 100, DATABASE::"Item Journal Line", '',
          0, WarehouseEntry."Source Document"::"Item Jnl.", 1);

        AssertWarehouseEntry(
          FromBin.Code, ChildItem."No.", '', -10, DATABASE::"Prod. Order Component", ProductionOrder."No.",
          ProductionOrder.Status.AsInteger(), WarehouseEntry."Source Document"::"Prod. Consumption", 1);

        AssertWarehouseEntry(
          ToBin.Code, ChildItem."No.", '', 10, DATABASE::"Prod. Order Component", ProductionOrder."No.",
          ProductionOrder.Status.AsInteger(), WarehouseEntry."Source Document"::"Prod. Consumption", 1);

        // Autofill and register
        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        // check Warehouse Entries
        AssertWarehouseEntry(
          FromBin.Code, ChildItem."No.", '', 100, DATABASE::"Item Journal Line", '',
          0, WarehouseEntry."Source Document"::"Item Jnl.", 1);

        AssertWarehouseEntry(
          FromBin.Code, ChildItem."No.", '', -10, DATABASE::"Prod. Order Component", ProductionOrder."No.",
          ProductionOrder.Status.AsInteger(), WarehouseEntry."Source Document"::"Prod. Consumption", 2);

        AssertWarehouseEntry(
          ToBin.Code, ChildItem."No.", '', 10, DATABASE::"Prod. Order Component", ProductionOrder."No.",
          ProductionOrder.Status.AsInteger(), WarehouseEntry."Source Document"::"Prod. Consumption", 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC415Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC415(Location);
    end;

    local procedure SC4TC415(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        // Change bin of component
        FindBin(ToBin, Location, true, 1);
        ChangeVariantAndBinOfComponent(ProductionOrder, '', ToBin.Code, '');

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Autofill Qty. to Handle
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Take, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Place, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        RegisterInventoryMovement(Location);

        // check Inventory Movement Lines
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin, ToBin, 20, 10, 1);

        // check Registered Inventory Movement
        AssertRegisteredInvtMovement(
          RegisteredInvtMovementHdr, ProductionOrder, WarehouseRequest."Source Document"::"Prod. Consumption",
          ChildItem, FromBin, ToBin, 10, 1, 1);

        // Autofill and register
        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        // check Registered Inventory Movements
        AssertRegisteredInvtMovement(
          RegisteredInvtMovementHdr, ProductionOrder, WarehouseRequest."Source Document"::"Prod. Consumption",
          ChildItem, FromBin, ToBin, 10, 2, 1);
        AssertRegisteredInvtMovement(
          RegisteredInvtMovementHdr, ProductionOrder, WarehouseRequest."Source Document"::"Prod. Consumption",
          ChildItem, FromBin, ToBin, 10, 2, 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC416Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC416(Location);
    end;

    local procedure SC4TC416(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Autofill Qty. to Handle
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Take, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Place, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        RegisterInventoryMovement(Location);

        // check Inventory Movement Lines
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin, ToBin, 20, 10, 1);

        // check component
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 20, 20, 10, 10, Location.Code, ToBin.Code, 1);

        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        // check component
        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC417Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC417(Location);
    end;

    local procedure SC4TC417(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Assert cannot register
        AssertCannotRegisterInvtMovm(Location, MSG_THERE_NOTHING_TO_REGISTER);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC418Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC418(Location);
    end;

    local procedure SC4TC418(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Take, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        // Assert cannot register
        AssertCannotRegisterInvtMovm(Location, Text003);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC419Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC419(Location);
    end;

    local procedure SC4TC419(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        // Change bin of component
        FindBin(ToBin, Location, true, 1);
        ChangeVariantAndBinOfComponent(ProductionOrder, '', ToBin.Code, '');

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Autofill Qty. to Handle
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Take, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Place, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        RegisterInventoryMovement(Location);
        DeleteActivityTypeWithSrcDoc(ProductionOrder, Location, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement Lines
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin, ToBin, 10, 0, 1);

        // Autofill Qty. to Handle
        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        // check component
        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('TC420MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC420Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC420(Location);
    end;

    local procedure SC4TC420(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        // Create invt movement
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Fill Qty. to Handle
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Take, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Place, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        // Register partial invt movement and delete
        RegisterInventoryMovement(Location);
        DeleteActivityTypeWithSrcDoc(ProductionOrder, Location, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        // Create inventory pick
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // Check that movement cannot be created - nothing to create msg
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Post partial invt pick and delete
        ChangeBinInWhseActivityLine(
          ProductionOrder, WarehouseActivityLine."Activity Type"::"Invt. Pick", 10, ToBin.Code);
        FillQtyToHandle(ProductionOrder, WarehouseActivityLine."Action Type"::Take, 5, WarehouseActivityLine."Activity Type"::"Invt. Pick");
        GetLastActvHdrCreatedWithSrc(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Pick",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        DeleteActivityTypeWithSrcDoc(ProductionOrder, Location, WarehouseActivityLine."Activity Type"::"Invt. Pick");

        // Create invt movement
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement Lines
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin, ToBin, 10, 0, 1);
    end;

    [Test]
    [HandlerFunctions('TC421MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC421Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC421(Location);
    end;

    local procedure SC4TC421(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        // Create invt movement
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Autofill Qty. to Handle
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Take, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Place, 10, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        // Register partially and delete
        RegisterInventoryMovement(Location);
        DeleteActivityTypeWithSrcDoc(ProductionOrder, Location, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        // Create invt pick
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // Post invt pick partially and delete
        ChangeBinInWhseActivityLine(ProductionOrder, WarehouseActivityLine."Activity Type"::"Invt. Pick", 10, ToBin.Code);
        FillQtyToHandle(ProductionOrder, WarehouseActivityLine."Action Type"::Take, 5, WarehouseActivityLine."Activity Type"::"Invt. Pick");
        GetLastActvHdrCreatedWithSrc(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Pick",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        DeleteActivityTypeWithSrcDoc(ProductionOrder, Location, WarehouseActivityLine."Activity Type"::"Invt. Pick");

        // Verify prod order comp
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 15, 20, 10, 10, Location.Code, ToBin.Code, 1);

        // Create invt movement
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement Lines
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin, ToBin, 10, 0, 1);

        // Autofill and register invt movement
        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        // Post consumption and verify comp lines
        CalculateAndPostConsumption(ProductionOrder);
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC422Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC422(Location);
    end;

    local procedure SC4TC422(Location: Record Location)
    var
        ArrayOfItem: array[5] of Record Item;
        ProductionOrder: Record "Production Order";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        // Test setup
        TestSetup();
        PC6(ArrayOfItem);

        FindBin(FromBin, Location, false, 1);
        for i := 2 to 5 do
            AddInventoryNonDirectLocation(ArrayOfItem[i], Location, FromBin, 100);

        // create Released Production Order for Silver location and refresh it
        FindBin(ToBin, Location, false, 3);
        CreateRelProdOrderAndRefresh(ProductionOrder, ArrayOfItem[1]."No.", 10, Location.Code, ToBin.Code);
        SetBinCodeOnCompLines(ProductionOrder, FromBin);

        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[5]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);

        // Change bin of component
        FindBin(ToBin, Location, true, 1);
        ChangeVariantAndBinOfComponent(ProductionOrder, '', ToBin.Code, ArrayOfItem[5]."No.");

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement Lines
        AssertInvtMovement(ProductionOrder, ArrayOfItem[5], Location, FromBin, ToBin, 20, 0, 1);

        // Autofill Qty. to Handle
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Take, 20, WarehouseActivityLine."Activity Type"::"Invt. Movement");
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Place, 20, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        RegisterInventoryMovement(Location);

        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[5]."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);

        ExplodeAndPostOutputJournal(ArrayOfItem[1]."No.", ProductionOrder."No.");

        // finish released production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        ProductionOrder.Status := ProductionOrder.Status::Finished;

        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[5]."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC425Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC425(Location);
    end;

    local procedure SC4TC425(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        FromBin: Record Bin;
        ToBin: Record Bin;
        ChildItem: Record Item;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindChild(ParentItem, ChildItem, 1);
        ChangeFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Forward);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 40);

        // create Released Production Order for Silver location and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, FromBin);

        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);

        FindBin(ToBin, Location, true, 1);
        AddComponentToProdOrder(ProductionOrder, ChildItem."No.", 2, Location.Code, ToBin.Code, ChildItem."Flushing Method");

        AssertCannotCreateInvtMvmtProd(ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC426Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC426(Location);
    end;

    local procedure SC4TC426(Location: Record Location)
    var
        ParentItem: Record Item;
        WarehouseRequest: Record "Warehouse Request";
        ProductionOrder: Record "Production Order";
        FromBin: Record Bin;
        ToBin: Record Bin;
        ChildItem: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindChild(ParentItem, ChildItem, 1);
        ChangeFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::"Pick + Forward");

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 40);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, FromBin);

        // validate component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);

        FindBin(ToBin, Location, true, 1);
        AddComponentToProdOrder(ProductionOrder, ChildItem."No.", 2, Location.Code, ToBin.Code, ChildItem."Flushing Method");

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement Lines
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin, ToBin, 20, 0, 1);

        // Autofill Qty. to Handle
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Take, 20, WarehouseActivityLine."Activity Type"::"Invt. Movement");
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Place, 20, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        RegisterInventoryMovement(Location);

        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);

        CalculateAndPostConsumption(ProductionOrder);
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC427Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC427(Location);
    end;

    local procedure SC4TC427(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        FromBin: Record Bin;
        ToBin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ChildItem: Record Item;
        OldToBin: Record Bin;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindChild(ParentItem, ChildItem, 1);
        ChangeFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::"Pick + Backward");

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 40);

        // create Released Production Order and refresh it
        OldToBin := ToBin;
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, ToBin.Code);
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        // Assert comp lines
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 20, 20, 0, 0, Location.Code, ToBin.Code, 1);

        FindBin(ToBin, Location, true, 1);
        AddComponentToProdOrder(ProductionOrder, ChildItem."No.", 2, Location.Code, ToBin.Code, ChildItem."Flushing Method");

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, MSG_INVENTORY_MOVEMENT);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, FromBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 2, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, OldToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem, ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);

        // Autofill Qty. to Handle
        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 20, 20, 20, 20, Location.Code, OldToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);

        ExplodeAndPostOutputJournal(ParentItem."No.", ProductionOrder."No.");

        // Finish the released production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        ProductionOrder.Status := ProductionOrder.Status::Finished;

        // Assert components again
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 0, 20, 20, 20, Location.Code, OldToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC428Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC428(Location);
    end;

    local procedure SC4TC428(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        FromBin: Record Bin;
        ToBin: Record Bin;
        ChildItem: Record Item;
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindChild(ParentItem, ChildItem, 1);
        ChangeFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);

        FindBin(FromBin, Location, false, 1);
        FindBin(ToBin, Location, false, 3);

        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 40);

        // create Released Production Order and refresh it
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, ToBin.Code);
        SetBinCodeOnCompLines(ProductionOrder, FromBin);

        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);

        FindBin(ToBin, Location, true, 1);
        AddComponentToProdOrder(ProductionOrder, ChildItem."No.", 2, Location.Code, FromBin.Code, ChildItem."Flushing Method");

        // Check that movement cannot be created
        AssertCannotCreateInvtMvmtProd(ProductionOrder);

        ExplodeAndPostOutputJournal(ParentItem."No.", ProductionOrder."No.");

        // finish released production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        ProductionOrder.Status := ProductionOrder.Status::Finished;

        AssertProdOrderComponent(ProductionOrder, ChildItem."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC429Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC429(Location);
    end;

    local procedure SC4TC429(Location: Record Location)
    var
        ArrayOfItem: array[4] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        FromBin: Record Bin;
        ProductionOrder: Record "Production Order";
        ToBin: Record Bin;
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Test setup
        TestSetup();
        PC429(ArrayOfItem, ProductionBOMHeader, RoutingHeader, ArrayOfItem[3]."Flushing Method"::Forward);

        // Add inventory
        FindBin(FromBin, Location, false, 1);
        AddInventoryNonDirectLocation(ArrayOfItem[2], Location, FromBin, 40);
        AddInventoryNonDirectLocation(ArrayOfItem[3], Location, FromBin, 40);

        // create Released Production Order for location and refresh it
        FindBin(ToBin, Location, false, 3);
        CreateRelProdOrderAndRefresh(ProductionOrder, ArrayOfItem[1]."No.", 10, Location.Code, ToBin.Code);
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        // Validate components
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 0, 0, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 20, 20, 0, 0, Location.Code, ToBin.Code, 1);

        // Add new component line
        AddComponentToProdOrder(
          ProductionOrder, ArrayOfItem[2]."No.", 2, Location.Code, ToBin.Code, ArrayOfItem[2]."Flushing Method"::Backward);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement Lines
        AssertInvtMovement(ProductionOrder, ArrayOfItem[2], Location, FromBin, ToBin, 20, 0, 1);

        // Autofill Qty. to Handle
        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        // Assert that invt movement deleted
        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');

        // Assert comp lines
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 20, 20, 0, 0, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 0, 0, Location.Code, ToBin.Code, 1);

        FindComponent(ProdOrderComponent, ProductionOrder, ArrayOfItem[2], 2);
        ChangeBinForComponent(ProdOrderComponent, FromBin.Code);
        FindComponent(ProdOrderComponent, ProductionOrder, ArrayOfItem[3], 1);
        ChangeBinForComponent(ProdOrderComponent, FromBin.Code);

        // Post output and consumption
        CalculateAndPostConsumption(ProductionOrder);
        ExplodeAndPostOutputJournal(ArrayOfItem[1]."No.", ProductionOrder."No.");

        // Change status to finish
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        ProductionOrder.Status := ProductionOrder.Status::Finished;

        // Verify
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC430Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC430(Location);
    end;

    local procedure SC4TC430(Location: Record Location)
    var
        ArrayOfItem: array[4] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        FromBin: Record Bin;
        ProductionOrder: Record "Production Order";
        ToBin: Record Bin;
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Test setup
        TestSetup();

        PC429(ArrayOfItem, ProductionBOMHeader, RoutingHeader, ArrayOfItem[3]."Flushing Method"::"Pick + Forward");

        FindBin(FromBin, Location, false, 1);
        AddInventoryNonDirectLocation(ArrayOfItem[2], Location, FromBin, 40);
        AddInventoryNonDirectLocation(ArrayOfItem[3], Location, FromBin, 40);

        // create Released Production Order and refresh it
        FindBin(ToBin, Location, false, 3);
        CreateRelProdOrderAndRefresh(ProductionOrder, ArrayOfItem[1]."No.", 10, Location.Code, ToBin.Code);
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 0, 0, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 20, 20, 0, 0, Location.Code, ToBin.Code, 1);

        AddComponentToProdOrder(
          ProductionOrder, ArrayOfItem[2]."No.", 2, Location.Code, ToBin.Code, ArrayOfItem[2]."Flushing Method"::Backward);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, 'Inventory Movement');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[2], FromBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[2], ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[3], FromBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[3], ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, 'Inventory Movement line');

        // Autofill Qty. to Handle
        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        // Assert invt movment deleted
        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');

        // Assert comp lines
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 0, 0, Location.Code, ToBin.Code, 1);

        FindComponent(ProdOrderComponent, ProductionOrder, ArrayOfItem[2], 2);
        ChangeBinForComponent(ProdOrderComponent, FromBin.Code);
        FindComponent(ProdOrderComponent, ProductionOrder, ArrayOfItem[3], 1);
        ChangeBinForComponent(ProdOrderComponent, FromBin.Code);

        // Post output and consumption
        CalculateAndPostConsumption(ProductionOrder);
        ExplodeAndPostOutputJournal(ArrayOfItem[1]."No.", ProductionOrder."No.");

        // finish the released production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        ProductionOrder.Status := ProductionOrder.Status::Finished;

        // Assert comp on finished prod order
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC431Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC431(Location);
    end;

    local procedure SC4TC431(Location: Record Location)
    var
        ArrayOfItem: array[4] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        FromBin: Record Bin;
        ProductionOrder: Record "Production Order";
        ToBin: Record Bin;
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WorkCenter: Record "Work Center";
    begin
        // Test setup
        TestSetup();

        PC431(
          ArrayOfItem, ProductionBOMHeader, RoutingHeader,
          ArrayOfItem[3]."Flushing Method"::Forward,
          ArrayOfItem[4]."Flushing Method"::Backward,
          WorkCenter."Flushing Method"::Forward);

        // add positive adjustment of items
        FindBin(FromBin, Location, false, 1);
        AddInventoryNonDirectLocation(ArrayOfItem[2], Location, FromBin, 40);
        AddInventoryNonDirectLocation(ArrayOfItem[3], Location, FromBin, 40);
        AddInventoryNonDirectLocation(ArrayOfItem[4], Location, FromBin, 40);

        // create Released Production Order and refresh it
        FindBin(ToBin, Location, false, 3);
        CreateRelProdOrderAndRefresh(ProductionOrder, ArrayOfItem[1]."No.", 10, Location.Code, ToBin.Code);
        SetBinCodeOnCompLines(ProductionOrder, FromBin);

        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);

        // step 4 changing Bin of CHILD
        FindComponent(ProdOrderComponent, ProductionOrder, ArrayOfItem[2], 1);
        ChangeBinForComponent(ProdOrderComponent, ToBin.Code);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, 'Inventory Movement');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[2], FromBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[2], ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, 'Inventory Movement line');

        // Autofill Qty. to Handle and registration
        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        // Assert invt movment deleted
        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');

        // Assert comp lines
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);

        // Post output and consumption
        ExplodeAndPostOutputJournal(ArrayOfItem[1]."No.", ProductionOrder."No.");
        CalculateAndPostConsumption(ProductionOrder);

        // finish the released production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        ProductionOrder.Status := ProductionOrder.Status::Finished;

        // Assert comp on finished prod order
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC432Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC432(Location);
    end;

    local procedure SC4TC432(Location: Record Location)
    var
        ArrayOfItem: array[4] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        FromBin: Record Bin;
        ProductionOrder: Record "Production Order";
        ToBin: Record Bin;
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WorkCenter: Record "Work Center";
    begin
        // Test setup
        TestSetup();

        PC431(
          ArrayOfItem, ProductionBOMHeader, RoutingHeader,
          ArrayOfItem[3]."Flushing Method"::"Pick + Forward",
          ArrayOfItem[4]."Flushing Method"::"Pick + Backward",
          WorkCenter."Flushing Method"::Forward);

        // add positive adjustment of items
        FindBin(FromBin, Location, false, 1);
        AddInventoryNonDirectLocation(ArrayOfItem[2], Location, FromBin, 40);
        AddInventoryNonDirectLocation(ArrayOfItem[3], Location, FromBin, 40);
        AddInventoryNonDirectLocation(ArrayOfItem[4], Location, FromBin, 40);

        // create Released Production Order and refresh it
        FindBin(ToBin, Location, false, 3);
        CreateRelProdOrderAndRefresh(ProductionOrder, ArrayOfItem[1]."No.", 10, Location.Code, ToBin.Code);
        SetBinCodeOnCompLines(ProductionOrder, FromBin);

        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);

        // step 4 changing Bin of CHILD
        FindComponent(ProdOrderComponent, ProductionOrder, ArrayOfItem[2], 1);
        ChangeBinForComponent(ProdOrderComponent, ToBin.Code);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, 'Inventory Movement');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[2], FromBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[2], ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, 'Inventory Movement line');

        // Autofill Qty. to Handle and registration
        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        // Assert invt movment deleted
        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');

        // Assert comp lines
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);

        // Post output and consumption
        ExplodeAndPostOutputJournal(ArrayOfItem[1]."No.", ProductionOrder."No.");
        CalculateAndPostConsumption(ProductionOrder);

        // finish the released production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        ProductionOrder.Status := ProductionOrder.Status::Finished;

        // Assert comp on finished prod order
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC433Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC433(Location);
    end;

    local procedure SC4TC433(Location: Record Location)
    var
        ArrayOfItem: array[4] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        FromBin: Record Bin;
        ProductionOrder: Record "Production Order";
        ToBin: Record Bin;
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WorkCenter: Record "Work Center";
    begin
        // Test setup
        TestSetup();

        PC431(
          ArrayOfItem, ProductionBOMHeader, RoutingHeader,
          ArrayOfItem[3]."Flushing Method"::Forward,
          ArrayOfItem[4]."Flushing Method"::Backward,
          WorkCenter."Flushing Method"::Backward);

        // add positive adjustment of items
        FindBin(FromBin, Location, false, 1);
        AddInventoryNonDirectLocation(ArrayOfItem[2], Location, FromBin, 40);
        AddInventoryNonDirectLocation(ArrayOfItem[3], Location, FromBin, 40);
        AddInventoryNonDirectLocation(ArrayOfItem[4], Location, FromBin, 40);

        // create Released Production Order and refresh it
        FindBin(ToBin, Location, false, 3);
        CreateRelProdOrderAndRefresh(ProductionOrder, ArrayOfItem[1]."No.", 10, Location.Code, ToBin.Code);
        SetBinCodeOnCompLines(ProductionOrder, FromBin);

        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);

        // step 4 changing Bin of CHILD
        FindComponent(ProdOrderComponent, ProductionOrder, ArrayOfItem[2], 1);
        ChangeBinForComponent(ProdOrderComponent, ToBin.Code);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, 'Inventory Movement');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[2], FromBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[2], ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, 'Inventory Movement line');

        // Autofill Qty. to Handle and registration
        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        // Assert invt movment deleted
        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');

        // Assert comp lines
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);

        // Post output and consumption
        ExplodeAndPostOutputJournal(ArrayOfItem[1]."No.", ProductionOrder."No.");
        CalculateAndPostConsumption(ProductionOrder);

        // finish the released production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        ProductionOrder.Status := ProductionOrder.Status::Finished;

        // Assert comp on finished prod order
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 0, 20, 20, 20, Location.Code, FromBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC434Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC434(Location);
    end;

    local procedure SC4TC434(Location: Record Location)
    var
        ArrayOfItem: array[4] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        FromBin: Record Bin;
        ProductionOrder: Record "Production Order";
        ToBin: Record Bin;
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WorkCenter: Record "Work Center";
    begin
        // Test setup
        TestSetup();

        PC431(
          ArrayOfItem, ProductionBOMHeader, RoutingHeader,
          ArrayOfItem[3]."Flushing Method"::"Pick + Forward",
          ArrayOfItem[4]."Flushing Method"::"Pick + Backward",
          WorkCenter."Flushing Method"::Backward);

        // add positive adjustment of items
        FindBin(FromBin, Location, false, 1);
        AddInventoryNonDirectLocation(ArrayOfItem[2], Location, FromBin, 40);
        AddInventoryNonDirectLocation(ArrayOfItem[3], Location, FromBin, 40);
        AddInventoryNonDirectLocation(ArrayOfItem[4], Location, FromBin, 40);

        // create Released Production Order and refresh it
        FindBin(ToBin, Location, false, 3);
        CreateRelProdOrderAndRefresh(ProductionOrder, ArrayOfItem[1]."No.", 10, Location.Code, ToBin.Code);
        SetBinCodeOnCompLines(ProductionOrder, FromBin);

        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 20, 20, 0, 0, Location.Code, FromBin.Code, 1);

        // step 4 changing Bin of all components
        SetBinCodeOnCompLines(ProductionOrder, ToBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // check Inventory Movement
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, 'Inventory Movement');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[2], FromBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[2], ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[3], FromBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[3], ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[4], FromBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ArrayOfItem[4], ToBin, WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, 'Inventory Movement line');

        // Autofill Qty. to Handle and registration
        AutofillQtyToHandle(ProductionOrder);
        RegisterInventoryMovement(Location);

        // Assert invt movment deleted
        AssertNoActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 'Inventory Movement');

        // Assert comp lines
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 20, 20, 20, 20, Location.Code, ToBin.Code, 1);

        // Post output and consumption
        ExplodeAndPostOutputJournal(ArrayOfItem[1]."No.", ProductionOrder."No.");
        CalculateAndPostConsumption(ProductionOrder);

        // finish the released production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        ProductionOrder.Status := ProductionOrder.Status::Finished;

        // Assert comp on finished prod order
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[2]."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[3]."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ArrayOfItem[4]."No.", 0, 20, 20, 20, Location.Code, ToBin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC4TC435Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC4TC435(Location);
    end;

    local procedure SC4TC435(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        FromBin: Record Bin;
        ToBin: Record Bin;
        DummyLocation: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        DummyLocation := DummyLocation;
        FindBin(FromBin, Location, false, 1);
        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FromBin, 100);
        AddInventoryNonDirectLocation(ChildItem, DummyLocation, ToBin, 100);

        // create Released Production Order and refresh it
        FindBin(ToBin, Location, false, 3);
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        AddComponentToProdOrder(ProductionOrder, ChildItem."No.", 1, Location.Code, ToBin.Code, ChildItem."Flushing Method");

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // verify invt movement
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FromBin, ToBin, 10, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC71Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC71DedicatedBinMCPriorit(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC71White()
    begin
        // Setup
        Initialize();

        SC7TC71DedicatedBinMCPriorit(LocationWhite);
    end;

    local procedure SC7TC71DedicatedBinMCPriorit(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[2].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[2].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[1].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC72Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC72DedicatedBinWCPriorit(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC72White()
    begin
        // Setup
        Initialize();

        SC7TC72DedicatedBinWCPriorit(LocationWhite);
    end;

    local procedure SC7TC72DedicatedBinWCPriorit(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, '', '', '');
        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code, 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC73Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC73DedicatedBinLCPriorit(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC73White()
    begin
        // Setup
        Initialize();

        SC7TC73DedicatedBinLCPriorit(LocationWhite);
    end;

    local procedure SC7TC73DedicatedBinLCPriorit(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, '', '', '');
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, '', '', '');
        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, '', '', '', 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderBinCodePriorityWhite()
    begin
        // Setup
        Initialize();

        HeaderBinCodePriority(LocationWhite);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderBinCodePriorityOrange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 8);
        HeaderBinCodePriority(Location);
    end;

    local procedure HeaderBinCodePriority(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        BinCode: Record Bin;
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, '', '', '');
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, '', '', '');
        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // Create and refresh prod Order - Exercise
        FindBin(BinCode, Location, false, 10);
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, BinCode.Code);

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, BinCode.Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, '', '', '', 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, BinCode.Code, OSFBBin[2].Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeOutputJournalHeaderWhite()
    begin
        // Setup
        Initialize();

        BinCodeOutputJournalHeader(LocationWhite);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeOutputJournalHeaderOrange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 8);
        BinCodeOutputJournalHeader(Location);
    end;

    local procedure BinCodeOutputJournalHeader(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        BinCode: Record Bin;
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, '', '', '');
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, '', '', '');

        // Create and refresh prod Order - Exercise
        FindBin(BinCode, Location, false, 10);
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, BinCode.Code);

        // Run explode route on Output Journal
        ExplodeOutputJournal(ParentItem."No.", ProductionOrder."No.");

        // Assert output journal line
        AssertOutputJournalLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, BinCode.Code, 1);
        AssertOutputJournalLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, BinCode.Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeOutputJournalLocationWhite()
    begin
        // Setup
        Initialize();

        BinCodeOutputJournalLocation(LocationWhite);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeOutputJournalLocationOrange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 8);
        BinCodeOutputJournalLocation(Location);
    end;

    local procedure BinCodeOutputJournalLocation(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        BinCode: Record Bin;
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, '', '', '');
        SetBinsOnWC(WorkCenter[2], Location.Code, '', '', '');
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, '', '', '');

        // Create and refresh prod Order - Exercise
        FindBin(BinCode, Location, false, 10);
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Run explode route on Output Journal
        ExplodeOutputJournal(ParentItem."No.", ProductionOrder."No.");

        // Assert output journal line
        AssertOutputJournalLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, Location."From-Production Bin Code", 1);
        AssertOutputJournalLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, Location."From-Production Bin Code", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC74Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 8);
        SC7TC74DedicatedBinBCPriorit(Location);
    end;

    local procedure SC7TC74DedicatedBinBCPriorit(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, '', '', '');
        SetBinsOnWC(WorkCenter[1], Location.Code, '', '', '');
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, '', '', '');
        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        FindBin(FirstBin, Location, false, 7);
        FindBin(SecondBin, Location, false, 8);

        Location.Validate("Default Bin Selection", Location."Default Bin Selection"::"Last-Used Bin");
        Location.Modify(true);

        AddInventoryNonDirectLocation(ChildItem1, Location, FirstBin, 40);
        AddInventoryNonDirectLocation(ChildItem2, Location, SecondBin, 100);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, FirstBin.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, SecondBin.Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, '', '', '', 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC75Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC75DedicatedBinEmptPriorit(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC75White()
    begin
        // Setup
        Initialize();

        SC7TC75DedicatedBinEmptPriorit(LocationWhite);
    end;

    local procedure SC7TC75DedicatedBinEmptPriorit(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, '', '', '');
        SetBinsOnWC(WorkCenter[1], Location.Code, '', '', '');
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, '', '', '');
        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, '', 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, '', 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, '', '', '', 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC77Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC77DedicatedBinBackward(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC77White()
    begin
        // Setup
        Initialize();

        SC7TC77DedicatedBinBackward(LocationWhite);
    end;

    local procedure SC7TC77DedicatedBinBackward(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        FindChild(ParentItem, ChildItem1, 1);
        ChildItem1.Validate("Flushing Method", ChildItem1."Flushing Method"::Backward);
        ChildItem1.Modify(true);
        FindChild(ParentItem, ChildItem2, 2);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, OSFBBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code, 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC78Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC78DedicatedBinForward(Location);
    end;

    local procedure SC7TC78DedicatedBinForward(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);

        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        FindChild(ParentItem, ChildItem1, 1);
        ChildItem1.Validate("Flushing Method", ChildItem1."Flushing Method"::Forward);
        ChildItem1.Modify(true);
        FindChild(ParentItem, ChildItem2, 2);

        AddInventoryNonDirectLocation(ChildItem1, Location, OSFBBin[1], 40);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 0, 20, 0, 0, Location.Code, OSFBBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code, 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC79Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC79DedicatedBinPForward(Location);
    end;

    local procedure SC7TC79DedicatedBinPForward(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);

        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        FindChild(ParentItem, ChildItem1, 1);
        ChildItem1.Validate("Flushing Method", ChildItem1."Flushing Method"::"Pick + Forward");
        ChildItem1.Modify(true);
        FindChild(ParentItem, ChildItem2, 2);

        AddInventoryNonDirectLocation(ChildItem1, Location, ToBin[1], 40);

        // Create and refresh prod Order - Exercise
        asserterror CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        Assert.ExpectedError('must not be 0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC710Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC710DedicatedBinPBackward(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC710White()
    begin
        // Setup
        Initialize();

        SC7TC710DedicatedBinPBackward(LocationWhite);
    end;

    local procedure SC7TC710DedicatedBinPBackward(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        FindChild(ParentItem, ChildItem1, 1);
        ChildItem1.Validate("Flushing Method", ChildItem1."Flushing Method"::"Pick + Backward");
        ChildItem1.Modify(true);
        FindChild(ParentItem, ChildItem2, 2);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code, 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ChangeLocationWCConfirmHandler(Question: Text[1024]; var Val: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MSG_CHANGE_LOC) > 0, Question);
        Val := true;
    end;

    [Test]
    [HandlerFunctions('ChangeLocationWCConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC7TC711Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC711DedicatedBinNoChange(Location);
    end;

    [Test]
    [HandlerFunctions('ChangeLocationWCConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC7TC711White()
    begin
        // Setup
        Initialize();

        SC7TC711DedicatedBinNoChange(LocationWhite);
    end;

    local procedure SC7TC711DedicatedBinNoChange(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code, 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);

        // Change master data
        SetBinsOnWC(WorkCenter[1], '', '', '', '');
        SetBinsOnWC(WorkCenter[2], '', '', '', '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code, 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SC7TC712ConfirmHandler(Question: Text[1024]; var Val: Boolean)
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            2:
                Assert.IsTrue(StrPos(Question, MSG_CHANGE_LOC) > 0, Question);
            1:
                Assert.IsTrue(StrPos(Question, MSG_UNMATCHED_BIN_CODE) > 0, Question);
        end;

        Val := true;
    end;

    [Test]
    [HandlerFunctions('SC7TC712ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC7TC712Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC712DedicatedBinRfhRouting(Location);
    end;

    [Test]
    [HandlerFunctions('SC7TC712ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC7TC712White()
    begin
        // Setup
        Initialize();

        SC7TC712DedicatedBinRfhRouting(LocationWhite);
    end;

    local procedure SC7TC712DedicatedBinRfhRouting(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code, 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);

        // Change master data
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);

        // Refresh routings
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, false, false);

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[2].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[2].Code, 1);

        // Assert prodorder line bin code - should not be changed
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[1].Code, FromBin[2].Code, OSFBBin[1].Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC713Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC713DedicatedBinRfhComp(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC713White()
    begin
        // Setup
        Initialize();

        SC7TC713DedicatedBinRfhComp(LocationWhite);
    end;

    local procedure SC7TC713DedicatedBinRfhComp(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code, 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);

        // Change master data
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);

        // Refresh routings
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, false, true, false);

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[1].Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, Location.Code, FromBin[2].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code, 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC715Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC715DedicatedBinDiffLoc(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC715White()
    begin
        // Setup
        Initialize();

        SC7TC715DedicatedBinDiffLoc(LocationWhite);
    end;

    local procedure SC7TC715DedicatedBinDiffLoc(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        LocationSilv: Record Location;
        ToBinS: Record Bin;
        FromBinS: Record Bin;
        OSFBBinS: Record Bin;
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // Create SILVER like location
        LocationSetup(LocationSilv, false, false, false, false, true, 6, 4);
        FindBin(ToBinS, LocationSilv, true, 1);
        FindBin(FromBinS, LocationSilv, true, 2);
        FindBin(OSFBBinS, LocationSilv, true, 3);
        SetBinsOnLocation(LocationSilv, ToBinS.Code, FromBinS.Code, OSFBBinS.Code);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, LocationSilv.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, LocationSilv.Code, ToBinS.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, LocationSilv.Code, ToBinS.Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, LocationSilv.Code, FromBinS.Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", LocationSilv.Code, '', '', '', 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", LocationSilv.Code, '', FromBinS.Code, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC716Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC716DedicatedBinCompAtLoc(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC716White()
    begin
        // Setup
        Initialize();

        SC7TC716DedicatedBinCompAtLoc(LocationWhite);
    end;

    local procedure SC7TC716DedicatedBinCompAtLoc(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        LocationSilv: Record Location;
        LocationW: Record Location;
        ToBinS: Record Bin;
        FromBinS: Record Bin;
        OSFBBinS: Record Bin;
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // Create SILVER like location
        LocationSetup(LocationSilv, false, false, false, false, true, 6, 4);
        FindBin(ToBinS, LocationSilv, true, 1);
        FindBin(FromBinS, LocationSilv, true, 2);
        FindBin(OSFBBinS, LocationSilv, true, 3);
        SetBinsOnLocation(LocationSilv, ToBinS.Code, FromBinS.Code, OSFBBinS.Code);

        // Create another WHITE like location
        LibraryWarehouse.CreateFullWMSLocation(LocationW, 10);

        // Set components at location
        LibraryManufacturing.SetComponentsAtLocation(LocationSilv.Code);

        // Create and refresh production order on WHITE like location
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, LocationW.Code, LocationW."From-Production Bin Code");

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, LocationSilv.Code, ToBinS.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, LocationSilv.Code, ToBinS.Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, LocationW.Code, LocationW."From-Production Bin Code", 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", LocationW.Code, '', '', '', 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", LocationW.Code, '', LocationW."From-Production Bin Code", '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC717Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC717DedicatedBinChgLocComp(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC717White()
    begin
        // Setup
        Initialize();

        SC7TC717DedicatedBinChgLocComp(LocationWhite);
    end;

    local procedure SC7TC717DedicatedBinChgLocComp(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        LocationSilv: Record Location;
        LocationW: Record Location;
        ToBinS: Record Bin;
        FromBinS: Record Bin;
        OSFBBinS: Record Bin;
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // Create SILVER like location
        LocationSetup(LocationSilv, false, false, false, false, true, 6, 4);
        FindBin(ToBinS, LocationSilv, true, 1);
        FindBin(FromBinS, LocationSilv, true, 2);
        FindBin(OSFBBinS, LocationSilv, true, 3);
        SetBinsOnLocation(LocationSilv, ToBinS.Code, FromBinS.Code, OSFBBinS.Code);

        // Create another WHITE like location
        LibraryWarehouse.CreateFullWMSLocation(LocationW, 10);

        // Set components at location
        LibraryManufacturing.SetComponentsAtLocation(LocationSilv.Code);

        // Create and refresh production order on WHITE like location
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, LocationW.Code, LocationW."From-Production Bin Code");

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, LocationSilv.Code, ToBinS.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, LocationSilv.Code, ToBinS.Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, LocationW.Code, LocationW."From-Production Bin Code", 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", LocationW.Code, '', '', '', 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", LocationW.Code, '', LocationW."From-Production Bin Code", '', 1);

        // Change location code on the second component line
        FindComponent(ProdOrderComponent, ProductionOrder, ChildItem2, 1);
        ProdOrderComponent.Validate("Location Code", LocationW.Code);
        ProdOrderComponent.Modify(true);

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, LocationSilv.Code, ToBinS.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, LocationW.Code, LocationW."To-Production Bin Code", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC718Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC718DedicatedBinChgLocComp(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC718White()
    begin
        // Setup
        Initialize();

        SC7TC718DedicatedBinChgLocComp(LocationWhite);
    end;

    local procedure SC7TC718DedicatedBinChgLocComp(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        LocationSilv: Record Location;
        LocationW: Record Location;
        ToBinS: Record Bin;
        FromBinS: Record Bin;
        OSFBBinS: Record Bin;
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);
        ChildItem2.Validate("Flushing Method", ChildItem2."Flushing Method"::Backward);
        ChildItem2.Modify(true);

        // Create SILVER like location
        LocationSetup(LocationSilv, false, false, false, false, true, 6, 4);
        FindBin(ToBinS, LocationSilv, true, 1);
        FindBin(FromBinS, LocationSilv, true, 2);
        FindBin(OSFBBinS, LocationSilv, true, 3);
        SetBinsOnLocation(LocationSilv, ToBinS.Code, FromBinS.Code, OSFBBinS.Code);

        // Create another WHITE like location
        LibraryWarehouse.CreateFullWMSLocation(LocationW, 10);

        // Set components at location
        LibraryManufacturing.SetComponentsAtLocation(LocationSilv.Code);

        // Create and refresh production order on WHITE like location
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, LocationW.Code, LocationW."From-Production Bin Code");

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, LocationSilv.Code, ToBinS.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, LocationSilv.Code, OSFBBinS.Code, 1);

        // Assert prodorder line bin code
        AssertProdOrderLine(ProductionOrder, ParentItem."No.", 10, LocationW.Code, LocationW."From-Production Bin Code", 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter."No.", LocationW.Code, '', '', '', 1);
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_20, RoutingLine.Type::"Work Center",
          WorkCenter[2]."No.", LocationW.Code, '', LocationW."From-Production Bin Code", '', 1);

        // Change location code on the second component line
        FindComponent(ProdOrderComponent, ProductionOrder, ChildItem2, 1);
        ProdOrderComponent.Validate("Location Code", LocationW.Code);
        ProdOrderComponent.Modify(true);

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, LocationSilv.Code, ToBinS.Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, LocationW.Code, LocationW."Open Shop Floor Bin Code", 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SC7TC719Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, false, true, true, true, 6, 4);
        SC7TC719DedicatedInvtMovm(Location);
    end;

    local procedure SC7TC719DedicatedInvtMovm(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);

        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        AddInventoryNonDirectLocation(ChildItem1, Location, FirstBin, 100);
        AddInventoryNonDirectLocation(ChildItem2, Location, SecondBin, 100);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, Location.Code, ToBin[2].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, Location.Code, ToBin[2].Code, 1);

        // Create invt movement
        LibraryWarehouse.CreateInvtPutPickMovement(WarehouseActivityHeader."Source Document"::"Prod. Consumption",
          ProductionOrder."No.", false, false, true);

        // Verify movement
        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Movement",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, 'Inventory Movement');
        AssertActivityLine(WarehouseActivityHeader, ChildItem1, FirstBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ChildItem1, ToBin[2], WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ChildItem2, SecondBin, WarehouseActivityLine."Action Type"::Take,
          20, 0, 1, 'Inventory Movement line');
        AssertActivityLine(WarehouseActivityHeader, ChildItem2, ToBin[2], WarehouseActivityLine."Action Type"::Place,
          20, 0, 1, 'Inventory Movement line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7TC721Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC7TC721DedicatedWhsePick(Location);
    end;

    local procedure SC7TC721DedicatedWhsePick(Location: Record Location)
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Test setup
        DedicatedBinTestSetup(ParentItem, Location, WorkCenter, MachineCenter, ToBin, FromBin, OSFBBin);
        SetBinsOnLocation(Location, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[1], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnWC(WorkCenter[2], Location.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        MachineCenter.Get(MachineCenter."No.");
        SetBinsOnMC(MachineCenter, ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);

        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        FindBin(Bin, Location, false, 1);

        AddInventoryNonDirectLocation(ChildItem1, Location, Bin, 100);
        AddInventoryNonDirectLocation(ChildItem2, Location, Bin, 100);

        // Create and refresh prod Order - Exercise
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, Location.Code, '');

        FindComponent(ProdOrderComponent, ProductionOrder, ChildItem1, 1);
        ChangeBinForComponent(ProdOrderComponent, FromBin[2].Code);
        FindComponent(ProdOrderComponent, ProductionOrder, ChildItem2, 1);
        ChangeBinForComponent(ProdOrderComponent, FromBin[1].Code);

        // Create warehouse pick
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        AssertActivityHdr(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::Pick,
          "Warehouse Activity Source Document"::" ", '', 1, MSG_WHSE_PICK);
        AssertActivityLine(WarehouseActivityHeader, ChildItem1, Bin, WarehouseActivityLine."Action Type"::Take, 20, 20, 1,
          MSG_WHSE_PICK_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem1, FromBin[2], WarehouseActivityLine."Action Type"::Place, 20, 20, 1,
          MSG_WHSE_PICK_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem2, Bin, WarehouseActivityLine."Action Type"::Take, 20, 20, 1,
          MSG_WHSE_PICK_LINE);
        AssertActivityLine(WarehouseActivityHeader, ChildItem2, FromBin[1], WarehouseActivityLine."Action Type"::Place, 20, 20, 1,
          MSG_WHSE_PICK_LINE);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC81MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_ACTIVITIES_CREATED) > 0, Message);
    end;

    [Test]
    [HandlerFunctions('TC81MessageHandler')]
    [Scope('OnPrem')]
    procedure SC8TC81Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC81InvtPick(Location);
    end;

    local procedure SC8TC81InvtPick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, FirstBin, 1, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Verify that inventory pick is created
        AssertActivityHdr(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Pick",
          WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", 1, MSG_INVENTORY_PICK);
        AssertActivityLine(WhseActivityHdr, Item, FirstBin, WhseActivityLine."Action Type"::Take, 1, 0, 1, MSG_INVENTORY_PICK);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC8TC81Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC8TC81WhsePick(Location);
    end;

    local procedure SC8TC81WhsePick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, FirstBin, 1, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        SetBinAndCreateWhsePick(Location, SecondBin);

        // Verify that whse pick is created
        AssertWhseActivityHdr(WhseActivityHdr, Location, WhseActivityHdr.Type::Pick,
          MSG_WHSE_PICK);
        AssertActivityLine(WhseActivityHdr, Item, FirstBin, WhseActivityLine."Action Type"::Take, 1, 1, 1, MSG_WHSE_PICK_LINE);
        AssertActivityLine(WhseActivityHdr, Item, SecondBin, WhseActivityLine."Action Type"::Place, 1, 1, 1, MSG_WHSE_PICK_LINE);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC82MessageHandler(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_ACTIVITIES_CREATED) > 0, Message);
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CreateInvtMvmntConfirmHandler(Question: Text[1024]; var Val: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MSG_CREATE_MVMT) > 0, Question);
        Val := true;
    end;

    [Test]
    [HandlerFunctions('TC82MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC82Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC82InvtPick(Location);
    end;

    local procedure SC8TC82InvtPick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, FirstBin, 1, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Check that invt movement cannot be created - nothing to handle message
        AssertCannotCreateInvtMvmt(InternalMovementHeader);
    end;

    [Test]
    [HandlerFunctions('CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC82Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC8TC82WhsePick(Location);
    end;

    local procedure SC8TC82WhsePick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, FirstBin, 1, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        SetBinAndCreateWhsePick(Location, SecondBin);

        // Check that invt movement cannot be created - nothing to handle message
        AssertCannotCreateInvtMvmt(InternalMovementHeader);
    end;

    [Test]
    [HandlerFunctions('CreateInvtMvmntConfirmHandler,TC31MessageHandler')]
    [Scope('OnPrem')]
    procedure SC8TC83Silver()
    var
        Item: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        Location: Record Location;
        InternalMovementHeader: Record "Internal Movement Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Internal Movement] [Inventory Movement] [Reservation] [Bin]
        // [SCENARIO 202492] Inventory Movement could be created from Internal Movement if quantity in a bin is reserved.
        Initialize();

        // [GIVEN] Location "L" set up for mandatory bin.
        // [GIVEN] Item "I" with inventory in bin "B1" in location "L".
        // [GIVEN] Internal movement of item "I" from bin "B1" to "B2".
        // [GIVEN] Reserved sales order of "I" from bin "B1".
        CreateInternalMovementFromBinWithReservedQty(InternalMovementHeader, Item, FirstBin, SecondBin, Location);

        // [WHEN] Create Inventory Movement from Internal Movement.
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // [THEN] Internal Movement is deleted.
        AssertInternalMovementDeleted(InternalMovementHeader);

        // [THEN] Inventory Movement of item "I" from bin "B1" to "B2" is created.
        GetLastActvHdrCreatedNoSource(WhseActivityHeader, Location, WhseActivityHeader.Type::"Invt. Movement");
        AssertActivityLine(
          WhseActivityHeader, Item, FirstBin, WhseActivityLine."Action Type"::Take, 1, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(
          WhseActivityHeader, Item, SecondBin, WhseActivityLine."Action Type"::Place, 1, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
    end;

    local procedure CreateInternalMovementFromBinWithReservedQty(var InternalMovementHeader: Record "Internal Movement Header"; var Item: Record Item; var FirstBin: Record Bin; var SecondBin: Record Bin; var Location: Record Location)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LocationSetup(Location, false, false, false, true, true, 6, 4);
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, FirstBin, 1, WorkDate());
        ReserveSalesLine(SalesLine, true, 1);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC84MessageHandlerSilver(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_HAS_BEEN_CREATED) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, MSG_THERE_NOTHING_TO_CREATE) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('TC84MessageHandlerSilver,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC84Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC84InvtPick(Location);
    end;

    local procedure SC8TC84InvtPick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, FirstBin, 1, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // This shouldn't be created - handle message - nothing to create
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Register the invt movement
        AutoFillQtyAndRegisterInvtMvmt(Location);

        // Change bin code on sales line and create the pick for the Sales order
        SalesLine.Find();
        SalesLine.Validate("Bin Code", SecondBin.Code);
        SalesLine.Modify(true);
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Verify that inventory pick is created
        AssertActivityHdr(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Pick",
          WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", 1, MSG_INVENTORY_PICK);
        AssertActivityLine(WhseActivityHdr, Item, SecondBin, WhseActivityLine."Action Type"::Take, 1, 0, 1, MSG_INVENTORY_PICK);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC84MessageHandlerOrange(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_HAS_BEEN_CREATED) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, MSG_WSHE_CREATED) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('TC84MessageHandlerOrange,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC84Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC8TC84WhsePick(Location);
    end;

    local procedure SC8TC84WhsePick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, FirstBin, 1, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // This shouldn't be created - handle message - nothing to create
        AssertCannotCreateWhsePick(Location, SecondBin);

        // Register the invt movement
        AutoFillQtyAndRegisterInvtMvmt(Location);

        // Change bin code on the shipment lines and create the pick
        SetBinAndCreateWhsePick(Location, FirstBin);

        // Verify that whse pick is created
        AssertWhseActivityHdr(WhseActivityHdr, Location, WhseActivityHdr.Type::Pick,
          MSG_WHSE_PICK);
        AssertActivityLine(WhseActivityHdr, Item, SecondBin, WhseActivityLine."Action Type"::Take, 1, 1, 1, MSG_WHSE_PICK_LINE);
        AssertActivityLine(WhseActivityHdr, Item, FirstBin, WhseActivityLine."Action Type"::Place, 1, 1, 1, MSG_WHSE_PICK_LINE);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC85MessageHandler(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_HAS_BEEN_CREATED) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('TC85MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC85Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC85InvtPick(Location);
    end;

    local procedure SC8TC85InvtPick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, FirstBin, 1, WorkDate());
        ReserveSalesLine(SalesLine, true, 1);

        // Check reserved qty
        Assert.AreEqual(1, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);
    end;

    [Test]
    [HandlerFunctions('TC85MessageHandler,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC85Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC8TC85WhsePick(Location);
    end;

    local procedure SC8TC85WhsePick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, SecondBin, FirstBin.Code);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, FirstBin, 1, WorkDate());
        ReserveSalesLine(SalesLine, true, 1);

        // Check reserved qty
        Assert.AreEqual(1, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);
    end;

    [Test]
    [HandlerFunctions('TC81MessageHandler')]
    [Scope('OnPrem')]
    procedure SC8TC86Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC86InvtPick(Location);
    end;

    local procedure SC8TC86InvtPick(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        ProductionOrder: Record "Production Order";
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FirstBin, 3);

        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 1, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, SecondBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        CreateSalesOrder(SalesHeader, SalesLine, ChildItem, Location, FirstBin, 2, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Verify that inventory pick is created
        AssertActivityHdr(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Pick",
          WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", 1, MSG_INVENTORY_PICK);
        AssertActivityLine(WhseActivityHdr, ChildItem, FirstBin, WhseActivityLine."Action Type"::Take, 1, 0, 1, MSG_INVENTORY_PICK);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC87MessageHandler(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_ACTIVITIES_CREATED) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, MSG_THERE_NOTHING_TO_CREATE) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('TC87MessageHandler')]
    [Scope('OnPrem')]
    procedure SC8TC87Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC87InvtPick(Location);
    end;

    local procedure SC8TC87InvtPick(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FirstBin, 2);

        // Create prod order
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 1, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, SecondBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);
        CreateSalesOrder(SalesHeader, SalesLine, ChildItem, Location, FirstBin, 2, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // This shouldn't be created - handle message - nothing to create
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Register the invt movement
        AutoFillQtyAndRegisterInvtMvmt(Location);

        // Change bin code on sales line and create the pick for the Sales order
        SalesLine.Find();
        SalesLine.Validate("Bin Code", SecondBin.Code);
        SalesLine.Modify(true);
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Verify that inventory pick is created
        AssertActivityHdr(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Pick",
          WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", 1, MSG_INVENTORY_PICK);
        AssertActivityLine(WhseActivityHdr, ChildItem, SecondBin, WhseActivityLine."Action Type"::Take, 2, 0, 1, MSG_INVENTORY_PICK);
    end;

    [Test]
    [HandlerFunctions('TC87MessageHandler')]
    [Scope('OnPrem')]
    procedure SC8TC88Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC88InvtPick(Location);
    end;

    local procedure SC8TC88InvtPick(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FirstBin, 3);

        // Create prod order
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 1, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, SecondBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FirstBin, SecondBin, 2, 0, 1);

        // Create and reserve sales order
        CreateSalesOrder(SalesHeader, SalesLine, ChildItem, Location, FirstBin, 2, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        ReserveSalesLine(SalesLine, true, 2);

        // Check reserved qty
        Assert.AreEqual(1, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);
    end;

    [Test]
    [HandlerFunctions('TC87MessageHandler')]
    [Scope('OnPrem')]
    procedure SC8TC89Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC89InvtPick(Location);
    end;

    local procedure SC8TC89InvtPick(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FirstBin, 2);

        // Create rel prod order
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 1, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, SecondBin);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FirstBin, SecondBin, 2, 0, 1);

        // Create sales order and reserve
        CreateSalesOrder(SalesHeader, SalesLine, ChildItem, Location, FirstBin, 2, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        ReserveSalesLine(SalesLine, true, 2);

        // Check reserved qty
        Assert.AreEqual(0, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);

        // Register the invt movement
        AutoFillQtyAndRegisterInvtMvmt(Location);

        ReserveSalesLine(SalesLine, true, 2);

        // Check reserved qty
        Assert.AreEqual(2, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);
    end;

    [Test]
    [HandlerFunctions('TC87MessageHandler')]
    [Scope('OnPrem')]
    procedure SC8TC810Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC810InvtPick(Location);
    end;

    local procedure SC8TC810InvtPick(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FirstBin, 2);

        // Create rel prod order
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 1, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, SecondBin);

        CreateSalesOrder(SalesHeader, SalesLine, ChildItem, Location, FirstBin, 2, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Verify that inventory pick is created
        AssertActivityHdr(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Pick",
          WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", 1, MSG_INVENTORY_PICK);
        AssertActivityLine(WhseActivityHdr, ChildItem, FirstBin, WhseActivityLine."Action Type"::Take, 2, 0, 1, MSG_INVENTORY_PICK);

        // This shouldn't be created - handle message - nothing to create
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC811MessageHandler(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_THERE_NOTHING_TO_CREATE) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('TC811MessageHandler')]
    [Scope('OnPrem')]
    procedure SC8TC811Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC811InvtPick(Location);
    end;

    local procedure SC8TC811InvtPick(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);

        // Exercise
        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FirstBin, 2);

        // Create rel prod order
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 1, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, SecondBin);

        CreateSalesOrder(SalesHeader, SalesLine, ChildItem, Location, FirstBin, 2, WorkDate());
        ReserveSalesLine(SalesLine, true, 2);

        // Check reserved qty
        Assert.AreEqual(2, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);

        // This shouldn't be created - handle message - nothing to create
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UseBinConfirmHandler(Question: Text[1024]; var Val: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MSG_USE_BIN) > 0, Question);
        Val := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC812MessageHandlerSilver(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_THERE_NOTHING_TO_CREATE) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('TC812MessageHandlerSilver,UseBinConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC812Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC812InvtPick(Location);
    end;

    local procedure SC8TC812InvtPick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, true, 1);
        FindBin(SecondBin, Location, true, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, FirstBin, 1, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // This shouldn't be created - handle message - nothing to create
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
    end;

    [Test]
    [HandlerFunctions('UseBinConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC813Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC813InvtPick(Location);
    end;

    local procedure SC8TC813InvtPick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBin: Record Bin;
        SecondBin: Record Bin;
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBin, Location, true, 1);
        FindBin(SecondBin, Location, true, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, FirstBin, 1, WorkDate());
        ReserveSalesLine(SalesLine, true, 2);

        // Check reserved qty
        Assert.AreEqual(1, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC814MessageHandlerSilver(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_BEEN_CREATED) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, MSG_THERE_NOTHING_TO_CREATE) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('TC814MessageHandlerSilver,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC814Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC814InvtPick(Location);
    end;

    local procedure SC8TC814InvtPick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBinD: Record Bin;
        SecondBinND: Record Bin;
        ThirdBinND: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBinD, Location, true, 1);
        FindBin(SecondBinND, Location, false, 2);
        FindBin(ThirdBinND, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBinD, 1);
        AddInventoryNonDirectLocation(Item, Location, SecondBinND, 2);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, SecondBinND, 1, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, ThirdBinND, SecondBinND.Code);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Verify that inventory movement is created
        GetLastActvHdrCreatedNoSource(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement");
        AssertActivityLine(WhseActivityHdr, Item, SecondBinND, WhseActivityLine."Action Type"::Take, 2, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, ThirdBinND, WhseActivityLine."Action Type"::Place, 2, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);

        // This shouldn't be created - handle message - nothing to create
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Set qty to handle 1 on invt movement and register
        LibraryWarehouse.SetQtyHandleInventoryMovement(WhseActivityHdr, 1);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHdr);

        // Create pick again
        SalesLine.Find();
        SalesLine.Validate("Bin Code", ThirdBinND.Code);
        SalesLine.Modify(true);
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Verify pick
        AssertActivityHdr(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Pick",
          WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", 1, MSG_INVENTORY_PICK);
        AssertActivityLine(WhseActivityHdr, Item, ThirdBinND, WhseActivityLine."Action Type"::Take, 1, 0, 1, MSG_INVENTORY_PICK_LINE);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC814MessageHandlerOrange(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_BEEN_CREATED) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, MSG_BEEN_CREATED) > 0, Message);
            3:
                Assert.IsTrue(StrPos(Message, MSG_THERE_NOTHING_TO_CREATE) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('TC814MessageHandlerOrange,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC814Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC8TC814WhsePick(Location);
    end;

    local procedure SC8TC814WhsePick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBinD: Record Bin;
        SecondBinND: Record Bin;
        ThirdBinND: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        InternalMovementHeader: Record "Internal Movement Header";
        FourthBinND: Record Bin;
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBinD, Location, true, 1);
        FindBin(SecondBinND, Location, false, 2);
        FindBin(ThirdBinND, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBinD, 1);
        AddInventoryNonDirectLocation(Item, Location, SecondBinND, 2);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, SecondBinND, 1, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, ThirdBinND, SecondBinND.Code);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Verify that inventory movement is created
        GetLastActvHdrCreatedNoSource(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement");
        AssertActivityLine(WhseActivityHdr, Item, SecondBinND, WhseActivityLine."Action Type"::Take, 2, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, ThirdBinND, WhseActivityLine."Action Type"::Place, 2, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);

        // This shouldn't be created - handle message - nothing to create
        AssertCannotCreateWhsePick(Location, ThirdBinND);

        // Set qty to handle 1 on invt movement and register
        LibraryWarehouse.SetQtyHandleInventoryMovement(WhseActivityHdr, 1);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHdr);

        Commit(); // as assert error will roll-back
        asserterror SetBinAndCreateWhsePick(Location, SecondBinND);
        Assert.IsTrue(StrPos(GetLastErrorText, MSG_NOTHING_TO_HANDLE) > 0,
          'Creating picks with same bin on Take & Place lines not allowed');
        ClearLastError();

        // Change shipment bin to a bin where the item does not exist
        FindBin(FourthBinND, Location, false, 3);
        SetBinAndCreateWhsePick(Location, FourthBinND);

        // Verify that whse pick is created
        AssertWhseActivityHdr(WhseActivityHdr, Location, WhseActivityHdr.Type::Pick,
          MSG_WHSE_PICK);
        AssertActivityLine(WhseActivityHdr, Item, ThirdBinND, WhseActivityLine."Action Type"::Take, 1, 1, 1, MSG_WHSE_PICK_LINE);
        AssertActivityLine(WhseActivityHdr, Item, FourthBinND, WhseActivityLine."Action Type"::Place, 1, 1, 1, MSG_WHSE_PICK_LINE);
    end;

    [Test]
    [HandlerFunctions('TC814MessageHandlerSilver,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC815Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC815InvtPick(Location);
    end;

    local procedure SC8TC815InvtPick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBinD: Record Bin;
        SecondBinND: Record Bin;
        ThirdBinND: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBinD, Location, true, 1);
        FindBin(SecondBinND, Location, false, 2);
        FindBin(ThirdBinND, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBinD, 1);
        AddInventoryNonDirectLocation(Item, Location, SecondBinND, 1);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, SecondBinND, 2, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, ThirdBinND, SecondBinND.Code);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Verify that inventory movement is created
        GetLastActvHdrCreatedNoSource(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement");
        AssertActivityLine(WhseActivityHdr, Item, SecondBinND, WhseActivityLine."Action Type"::Take, 1, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, ThirdBinND, WhseActivityLine."Action Type"::Place, 1, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);

        // Reserve and check reserved qty
        ReserveSalesLine(SalesLine, true, 1);
        Assert.AreEqual(1, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);
    end;

    [Test]
    [HandlerFunctions('TC814MessageHandlerOrange,CreateInvtMvmntConfirmHandler')]
    [Scope('OnPrem')]
    procedure SC8TC815Orange()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, true, true, true, true, true, 6, 4);
        SC8TC815WhsePick(Location);
    end;

    local procedure SC8TC815WhsePick(Location: Record Location)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstBinD: Record Bin;
        SecondBinND: Record Bin;
        ThirdBinND: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        // Test setup
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");

        FindBin(FirstBinD, Location, true, 1);
        FindBin(SecondBinND, Location, false, 2);
        FindBin(ThirdBinND, Location, false, 2);

        // Exercise
        AddInventoryNonDirectLocation(Item, Location, FirstBinD, 1);
        AddInventoryNonDirectLocation(Item, Location, SecondBinND, 1);
        CreateSalesOrder(SalesHeader, SalesLine, Item, Location, SecondBinND, 2, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        CreateInternalMovementGetBin(InternalMovementHeader, Item, Location, ThirdBinND, SecondBinND.Code);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // Verify that inventory movement is created
        GetLastActvHdrCreatedNoSource(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement");
        AssertActivityLine(WhseActivityHdr, Item, SecondBinND, WhseActivityLine."Action Type"::Take, 1, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);
        AssertActivityLine(WhseActivityHdr, Item, ThirdBinND, WhseActivityLine."Action Type"::Place, 1, 0, 1, MSG_INVENTORY_MOVEMENT_LINE);

        // Reserve and check reserved qty
        ReserveSalesLine(SalesLine, true, 1);
        Assert.AreEqual(1, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC816MessageHandler(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;

        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_MOVMT_CREATED) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, MSG_THERE_NOTHING_TO_CREATE) > 0, Message);
            3:
                Assert.IsTrue(StrPos(Message, MSG_ACTIVITIES_CREATED) > 0, Message);
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure SC8TC816Silver()
    var
        Location: Record Location;
    begin
        // [SCENARIO 314511] Internal Movement from Dedicated Bin B10 to non-dedicated Bin B2 is registered, Invt. Pick from Bin B2
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC816InvtPick(Location);
    end;

    local procedure SC8TC816InvtPick(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        FirstBinD: Record Bin;
        FirstBinND: Record Bin;
        SecondBinND: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FirstBinD, Location, true, 1);
        FindBin(FirstBinND, Location, false, 1);
        FindBin(SecondBinND, Location, false, 2);

        // Exercise
        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FirstBinD, 2);
        AddInventoryNonDirectLocation(ChildItem, Location, FirstBinND, 2);
        CreateSalesOrder(SalesHeader, SalesLine, ChildItem, Location, FirstBinND, 1, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Create rel prod order
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 1, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, SecondBinND);

        // Create inventory movement with source doc (movement from dedicated bin is created)
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Set qty to handle 1 on invt movement and register
        GetLastActvHdrCreatedWithSrc(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement",
          WhseActivityHdr."Source Document"::"Prod. Consumption", ProductionOrder."No.");
        LibraryWarehouse.SetQtyHandleInventoryMovement(WhseActivityHdr, 1);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHdr);

        // Create pick
        SalesLine.Find();
        SalesLine.Validate("Bin Code", SecondBinND.Code);
        SalesLine.Modify(true);
        LibraryWarehouse.CreateInvtPutPickMovement(WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Verify that inventory pick is created
        AssertActivityHdr(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Pick",
          WhseActivityHdr."Source Document"::"Sales Order", SalesHeader."No.", 1, MSG_INVENTORY_PICK);
        AssertActivityLine(WhseActivityHdr, ChildItem, SecondBinND, WhseActivityLine."Action Type"::Take, 1, 0, 1, MSG_INVENTORY_PICK);
    end;

    [Test]
    [HandlerFunctions('TC816MessageHandler')]
    [Scope('OnPrem')]
    procedure SC8TC817Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC817InvtPick(Location);
    end;

    local procedure SC8TC817InvtPick(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        FirstBinD: Record Bin;
        FirstBinND: Record Bin;
        SecondBinND: Record Bin;
        WhseActivityHdr: Record "Warehouse Activity Header";
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FirstBinD, Location, true, 1);
        FindBin(FirstBinND, Location, false, 1);
        FindBin(SecondBinND, Location, false, 2);

        // Exercise
        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FirstBinND, 2);
        CreateSalesOrder(SalesHeader, SalesLine, ChildItem, Location, FirstBinND, 1, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Create rel prod order
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 1, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, SecondBinND);

        // Create inventory movement with source doc
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);
        AssertInvtMovement(ProductionOrder, ChildItem, Location, FirstBinND, SecondBinND, 2, 0, 1);

        // Reserve and check reserved qty
        ReserveSalesLine(SalesLine, true, 1);
        Assert.AreEqual(0, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);

        // Set qty to handle 1 on invt movement and register
        GetLastActvHdrCreatedWithSrc(WhseActivityHdr, Location, WhseActivityHdr.Type::"Invt. Movement",
          WhseActivityHdr."Source Document"::"Prod. Consumption", ProductionOrder."No.");
        LibraryWarehouse.SetQtyHandleInventoryMovement(WhseActivityHdr, 1);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHdr);

        // Reserve and check reserved qty
        ReserveSalesLine(SalesLine, true, 1);
        Assert.AreEqual(1, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);
    end;

    [Test]
    [HandlerFunctions('TC816MessageHandler')]
    [Scope('OnPrem')]
    procedure SC8TC818Silver()
    var
        Location: Record Location;
    begin
        // Setup
        Initialize();

        LocationSetup(Location, false, false, false, true, true, 6, 4);
        SC8TC818InvtPick(Location);
    end;

    local procedure SC8TC818InvtPick(Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        FirstBinD: Record Bin;
        FirstBinND: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Test setup
        TestSetup();
        PC5(ParentItem);

        FindBin(FirstBinD, Location, true, 1);
        FindBin(FirstBinND, Location, false, 1);

        // Exercise
        FindChild(ParentItem, ChildItem, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, FirstBinND, 20);
        CreateSalesOrder(SalesHeader, SalesLine, ChildItem, Location, FirstBinND, 20, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Create rel prod order
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 1, Location.Code, '');
        SetBinCodeOnCompLines(ProductionOrder, FirstBinD);

        // Reserve and check reserved qty
        FindComponent(ProdOrderComponent, ProductionOrder, ChildItem, 1);
        ReserveComponentLine(ProdOrderComponent, false, 2);
        Assert.AreEqual(2, ProdOrderComponent."Reserved Quantity", MSG_QTY_NOT_RESERVED);

        // Create inventory movement with source doc
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // Autofill qty to handle on invt movement and register
        AutoFillQtyAndRegisterInvtMvmt(Location);

        // Reserve and check reserved qty
        ReserveSalesLine(SalesLine, true, 20);
        Assert.AreEqual(18, SalesLine."Reserved Quantity", MSG_QTY_NOT_RESERVED);
    end;

    [Test]
    [HandlerFunctions('InvtPickCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure RecreateInvtPickAfterDeletePartiallyPostedInvtPick()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
    begin
        // Verify the Quantity on recreated Inventory Pick Line after deleting the partially posted Inventory Pick.

        // Setup: Create Production Item. Create Location. Add Inventory for the Child Item.
        Initialize();
        TestSetup();
        Quantity := LibraryRandom.RandInt(10);
        ParentItem.Init();
        PC5(ParentItem);
        LocationSetup(Location, false, false, false, true, true, 0, 1);
        FindChild(ParentItem, ChildItem, 1);
        FindBin(Bin, Location, false, 1);
        AddInventoryNonDirectLocation(ChildItem, Location, Bin, Quantity * 3); // Quantity * 3 is more than the "ProductionOrder.Quantity" * QtyPer.

        // Create Released Production Order and refresh it.
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", Quantity, Location.Code, '');

        // Create inventory pick.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // Post inventory pick partially.
        // Total quantity of the child item is Quantity * QtyPer = Quantity * 2
        FillQtyToHandle(
          ProductionOrder, WarehouseActivityLine."Action Type"::Take, Quantity, WarehouseActivityLine."Activity Type"::"Invt. Pick");
        GetLastActvHdrCreatedWithSrc(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Pick",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        // Exercise: Delete the rest inventory pick, then Recreate inventory pick with remaining quantity.
        DeleteActivityTypeWithSrcDoc(ProductionOrder, Location, WarehouseActivityLine."Activity Type"::"Invt. Pick");
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // Verify: Verify Quantity of Inventory Pick Line
        GetLastActvHdrCreatedWithSrc(WarehouseActivityHeader, Location, WarehouseActivityHeader.Type::"Invt. Pick",
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.");
        AssertQtyOnInvtPick(WarehouseActivityHeader, Quantity);
    end;

    [Test]
    [HandlerFunctions('ProdOrderRoutingModalPageHandler')]
    [Scope('OnPrem')]
    procedure BinCodeOnProdOrderLineAfterViewingProdOrderRouring()
    var
        Item: Record Item;
        Bin: array[2] of Record Bin;
        RoutingHeader: Record "Routing Header";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Routing] [Bin] [Production Order]
        // [SCENARIO 359569] Bin Code on Prod. Order Line remains equal to bin code on Production Order after viewing prod. order routing lines.
        Initialize();

        // [GIVEN] Bins "B1", "B2".
        FindBin(Bin[1], LocationWhite, false, 1);
        FindBin(Bin[2], LocationWhite, false, 2);

        // [GIVEN] Create routing, set "From-Production Bin Code" on the work center = "B1".
        RoutingSetup(RoutingHeader, WorkCenter, MachineCenter);
        SetBinsOnWC(WorkCenter[2], LocationWhite.Code, '', Bin[1].Code, '');

        // [GIVEN] Create production item and set routing number.
        ItemSetup(Item, Item."Replenishment System"::"Prod. Order", Item."Flushing Method"::"Pick + Manual");
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // [GIVEN] Create and refresh released production order, set "Bin Code" = "B2" on the header.
        CreateRelProdOrderAndRefresh(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), LocationWhite.Code, Bin[2].Code);

        // [WHEN] Open and close Routing page for the production order line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.ShowRouting();

        // [THEN] "Bin Code" on the prod. order line remains "B2".
        ProdOrderLine.Find();
        ProdOrderLine.TestField("Bin Code", ProductionOrder."Bin Code");
    end;

    [Test]
    [HandlerFunctions('SyncBinCodeOnProdComponentConfirm')]
    procedure VerifyBinCodeIsNotUpdatedOnProdOrderComponentOnUpdateBinCodeOnRoutingLine()
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        ProdBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        MachineCenter: array[2] of Record "Machine Center";
        ToBin: array[2] of Record Bin;
        FromBin: array[2] of Record Bin;
        OSFBBin: array[2] of Record Bin;
    begin
        // [SCENARIO 454691] Verify Bin Code is not updated on Prod. Order Component on update Bin Code on Routing Line
        // [GIVEN]
        Initialize();

        // [GIVEN] Create Production BOM
        CreateBOM(ProdBOMHeader, 2, 2);

        // [GIVEN] Create Work Center with White Location
        CreateWorkCenterWithWhiteLocation(WorkCenter);

        // [GIVEN] Create Machine Centers
        CreateMachineCentersWithLocation(MachineCenter, WorkCenter);

        // [GIVEN] Create Routing
        CreateRoutingWithLines(RoutingHeader, MachineCenter[1], WorkCenter);

        // [GIVEN] Setup Parent Item on BOM and Routing
        ParentItemSetupOnBOMAndRouting(ParentItem, ProdBOMHeader, RoutingHeader);

        // [GIVEN] Populate Bins Test Setup
        PopulateBinsTestSetup(LocationWhite, ToBin, FromBin, OSFBBin);

        // Reload location code as it changed
        LocationWhite.Get(LocationWhite.Code);

        // [GIVEN] Set Bins on Location
        SetBinsOnLocation(LocationWhite, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);

        // [GIVEN] Set Bins on Machine Centers
        SetBinsOnMC(MachineCenter[1], ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code);
        SetBinsOnMC(MachineCenter[2], ToBin[2].Code, FromBin[2].Code, OSFBBin[2].Code);

        FindChild(ParentItem, ChildItem1, 1);
        FindChild(ParentItem, ChildItem2, 2);

        // [GIVEN] Create and refresh Production Order
        CreateRelProdOrderAndRefresh(ProductionOrder, ParentItem."No.", 10, LocationWhite.Code, '');

        // Assert component lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, LocationWhite.Code, ToBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, LocationWhite.Code, ToBin[1].Code, 1);

        // Assert routing lines
        AssertProdOrderRoutingLine(ProductionOrder, ROUTING_LINE_10, RoutingLine.Type::"Machine Center",
          MachineCenter[1]."No.", LocationWhite.Code, ToBin[1].Code, FromBin[1].Code, OSFBBin[1].Code, 1);

        // [WHEN] Change Machine Center on Routing Line
        UpdateMachineCenterOnRoutingLine(ProductionOrder, MachineCenter);

        // [THEN] Vecrify Bin Code are not updated on Component Lines
        AssertProdOrderComponent(ProductionOrder, ChildItem1."No.", 20, 20, 0, 0, LocationWhite.Code, ToBin[1].Code, 1);
        AssertProdOrderComponent(ProductionOrder, ChildItem2."No.", 20, 20, 0, 0, LocationWhite.Code, ToBin[1].Code, 1);
    end;

    [Test]
    procedure ValidateUnitofMeasureCodeOnInternalMovementLine()
    var
        FromBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        ToBin: Record Bin;
        UnitOfMeasureCode: Code[20];
    begin
        // [SCENARIO 560909] Unit of Measure Code should have Item Unit of Measure on Invernal Movement Line. 
        Initialize();

        // [GIVEN] Get Manufacturing Setup.
        UpdatePlanningSetup();

        // [GIVEN] Create an Item with Setup.
        ItemSetup(Item, Item."Replenishment System"::Purchase, Item."Flushing Method"::"Pick + Manual");

        // [GIVEN] Create a Location with setup.
        LocationSetup(Location, false, false, false, true, true,
            LibraryRandom.RandIntInRange(6, 6), LibraryRandom.RandIntInRange(4, 4));

        // [GIVEN] Find From Bin.
        FindBin(FromBin, Location, false, LibraryRandom.RandInt(1));

        // [GIVEN] Add Inventory on Location.
        AddInventoryNonDirectLocation(Item, Location, FromBin, LibraryRandom.RandInt(10));

        // [GIVEN] Find To Bin.
        FindBin(ToBin, Location, false, LibraryRandom.RandIntInRange(2, 2));

        // [GIVEN] Create Internal Movement Header with Location and To Bin.
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, ToBin.Code);

        // [GIVEN] Create Internal Movement Line
        LibraryWarehouse.CreateInternalMovementLine(
            InternalMovementHeader,
            InternalMovementLine,
            Item."No.",
            FromBin.Code,
            ToBin.Code,
            LibraryRandom.RandInt(10));

        // [GIVEN] Store any Code as Unit of Measure.
        UnitOfMeasureCode := LibraryRandom.RandText(3);

        // [WHEN] Validate Unit of Measure in Internal Movement Line.
        asserterror InternalMovementLine.Validate("Unit of Measure Code", UnitOfMeasureCode);

        // [THEN] Item Unit of Measure should be for Unit Of Measure Code.
        Assert.ExpectedError(StrSubstNo(UnitOfMeasureErr, UnitOfMeasureCode));
    end;

    [Test]
    [HandlerFunctions('CreateInvtMvmntConfirmHandler,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure MovementWorksheetCreateInventoryMovementWothCorrectBin()
    var
        Item: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        ThirdBin: Record Bin;
        FourthBin: Record Bin;
        Location: Record Location;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO 578567] Movement Worksheet Create Inventory Movement with Correct Bin Code
        Initialize();

        // [GIVEN] Create Location with Pick According to FEFO as true.
        LocationSetup(Location, true, true, true, true, true, 0, 4);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);

        //[GIVEN] Create Item with Assembly Replenishment System and Manual Flushing Method.
        TestSetup();
        ItemSetup(Item, Item."Replenishment System"::Assembly, Item."Flushing Method"::Manual);

        // [GIVEN] Create Bins.
        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);
        FindBin(ThirdBin, Location, false, 3);
        FindBin(FourthBin, Location, false, 4);

        // [GIVEN] Create Inventory in Bins.
        AddInventoryNonDirectLocation(Item, Location, FirstBin, 1);
        AddInventoryNonDirectLocation(Item, Location, SecondBin, 1);
        AddInventoryNonDirectLocation(Item, Location, ThirdBin, 1);
        AddInventoryNonDirectLocation(Item, Location, FourthBin, 1);

        // [GIVEN] Create Whse Worksheet Line with Item and from Bin = ThirdBin, To Bin = SecondBin.
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, ThirdBin, SecondBin, Item."No.", '', 1);

        // [WHEN] Create Inventory Movement from Whse Worksheet Line.
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // [THEN] Verify that Inventory Movement is created.
        FindWarehouseActivityLine(WarehouseActivityLine, 0, Location.Code, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        // [THEN] Verify that Bin Code on Warehouse Activity Line is equal to Bin Code on Whse Worksheet Line.
        Assert.IsTrue(WarehouseActivityLine."Bin Code" = ThirdBin.Code, BinCodeErr);
        WarehouseActivityLine.Next();
        Assert.IsTrue(WarehouseActivityLine."Bin Code" = SecondBin.Code, BinCodeErr);
    end;

    [Test]
    [HandlerFunctions('CreateInvtMvmntConfirmHandler,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure MovementWorksheetCreateInventoryMovementWithCorrectBinForTrackingItem()
    var
        Item: Record Item;
        FirstBin: Record Bin;
        SecondBin: Record Bin;
        ThirdBin: Record Bin;
        FourthBin: Record Bin;
        ItemTrackingCode: Record "Item Tracking Code";
        Location: Record Location;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        NoSeries: Codeunit "No. Series";
        LotNo: Code[50];
    begin
        // [SCENARIO 610410] Movement worksheet creates Inventory Movement with the correct Take line/From Bin when Pick According to FEFO for item tracking items
        Initialize();

        // [GIVEN] Create Location with Pick According to FEFO as true.
        LocationSetup(Location, true, true, true, true, true, 0, 4);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);

        //[GIVEN] Create Item with Assembly Replenishment System and Manual Flushing Method.
        TestSetup();
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Modify(true);

        // [GIVEN] Set Item Tracking Code to use Expiration Dates.
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create Bins.
        FindBin(FirstBin, Location, false, 1);
        FindBin(SecondBin, Location, false, 2);
        FindBin(ThirdBin, Location, false, 3);
        FindBin(FourthBin, Location, false, 4);

        // [GIVEN] Create Lot No for Item.
        LotNo := NoSeries.GetNextNo(Item."Lot Nos.", WorkDate(), true);

        // [GIVEN] Create Inventory in Bins with Lot No.
        CreateAndPostInventoryAdjustmentWithLotNo(Item, Location.Code, LotNo, FirstBin, LibraryRandom.RandInt(1000));
        CreateAndPostInventoryAdjustmentWithLotNo(Item, Location.Code, LotNo, SecondBin, LibraryRandom.RandInt(1200));
        CreateAndPostInventoryAdjustmentWithLotNo(Item, Location.Code, LotNo, ThirdBin, LibraryRandom.RandInt(2000));

        // [GIVEN] Create Whse Worksheet Line with Item and from Bin = ThirdBin, To Bin = FourthBin.
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, ThirdBin, FourthBin, Item."No.", '', 100);

        // [WHEN] Create Inventory Movement from Whse Worksheet Line.
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // [THEN] Verify that Inventory Movement is created.
        FindWarehouseActivityLine(WarehouseActivityLine, 0, Location.Code, WarehouseActivityLine."Activity Type"::"Invt. Movement");

        // [THEN] Verify that Bin Code on Warehouse Activity Line is equal to Bin Code on Whse Worksheet Line.
        Assert.IsTrue(WarehouseActivityLine."Bin Code" = ThirdBin.Code, BinCodeErr);
        WarehouseActivityLine.Next();
        Assert.IsTrue(WarehouseActivityLine."Bin Code" = FourthBin.Code, BinCodeErr);
    end;

    local procedure UpdateMachineCenterOnRoutingLine(var ProductionOrder: Record "Production Order"; var MachineCenter: array[2] of Record "Machine Center")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Operation No.", ROUTING_LINE_10);
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Machine Center");
        ProdOrderRoutingLine.SetRange("No.", MachineCenter[1]."No.");
        ProdOrderRoutingLine.SetRange("Location Code", LocationWhite.Code);
        if ProdOrderRoutingLine.FindFirst() then begin
            ProdOrderRoutingLine.Validate("No.", MachineCenter[2]."No.");
            ProdOrderRoutingLine.Modify(true);
        end;
    end;

    local procedure CreateRoutingWithLines(var RoutingHeader: Record "Routing Header"; var MachineCenter: Record "Machine Center"; var WorkCenter: Record "Work Center")
    begin
        CreateRouting(RoutingHeader, MachineCenter, WorkCenter);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateWorkCenterWithWhiteLocation(var WorkCenter: Record "Work Center")
    begin
        CreateWorkCenter(WorkCenter, WorkCenter."Flushing Method"::Manual);
        WorkCenter.Validate("Location Code", LocationWhite.Code);
        WorkCenter.Modify(true);
    end;

    local procedure CreateMachineCentersWithLocation(var MachineCenter: array[2] of Record "Machine Center"; var WorkCenter: Record "Work Center")
    begin
        CreateMachineCenter(MachineCenter[1], WorkCenter, MachineCenter[1]."Flushing Method"::Manual);
        MachineCenter[1].Validate("Location Code", LocationWhite.Code);
        MachineCenter[1].Modify(true);
        CreateMachineCenter(MachineCenter[2], WorkCenter, MachineCenter[2]."Flushing Method"::Manual);
        MachineCenter[2].Validate("Location Code", LocationWhite.Code);
        MachineCenter[2].Modify(true);
    end;

    local procedure PC5(var ParentItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateBOM(ProductionBOMHeader, 1, 2);
        ParentItemSetupOnBOM(ParentItem, ProductionBOMHeader);
    end;

    local procedure PC7(var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[4] of Record "Machine Center")
    var
        i: Integer;
    begin
        for i := 1 to 2 do
            CreateWorkCenter(WorkCenter[i], WorkCenter[i]."Flushing Method"::Manual);

        for i := 1 to 4 do
            if i in [1, 3] then
                CreateMachineCenter(MachineCenter[i], WorkCenter[1], MachineCenter[i]."Flushing Method"::Manual)
            else
                CreateMachineCenter(MachineCenter[i], WorkCenter[2], MachineCenter[i]."Flushing Method"::Manual);
    end;

    local procedure PC429(var Item: array[4] of Record Item; var ProductionBOMHeader: Record "Production BOM Header"; var RoutingHeader: Record "Routing Header"; FlushingMethod: Enum "Flushing Method")
    var
        ArrayOfWorkCenter: array[2] of Record "Work Center";
        ArrayOfMachineCenter: array[4] of Record "Machine Center";
        RoutingLink: Record "Routing Link";
        RoutingLine: Record "Routing Line";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        PC7(ArrayOfWorkCenter, ArrayOfMachineCenter);

        CreateRouting(RoutingHeader, ArrayOfMachineCenter[1], ArrayOfWorkCenter[2]);
        CreateBOM(ProductionBOMHeader, 2, 2);
        ParentItemSetupOnBOMAndRouting(Item[1], ProductionBOMHeader, RoutingHeader);

        FindChild(Item[1], Item[2], 1);
        FindChild(Item[1], Item[3], 2);
        ChangeFlushingMethodOnItem(Item[3], FlushingMethod);

        // routing link code to Routing
        RoutingLink.Init();
        RoutingLink.Validate(Code, CopyStr(ArrayOfWorkCenter[2]."No.", 1, 10));
        RoutingLink.Insert(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.FindLast();

        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // routing link code to Production BOM
        ProductionBOMHeader.Get(ProductionBOMHeader."No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure PC6(var Item: array[5] of Record Item)
    var
        UnitOfMeasure: Record "Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        i: Integer;
    begin
        ItemSetup(Item[1], Item[1]."Replenishment System"::"Prod. Order", Item[1]."Flushing Method"::"Pick + Manual");

        UnitOfMeasure.Init();
        UnitOfMeasure.FindFirst();
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure.Code);

        // Create component lines in the BOM
        for i := 2 to 5 do begin
            ItemSetup(Item[i], Item[i]."Replenishment System"::Purchase, "Flushing Method".FromInteger(i - 1));
            LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '',
              ProductionBOMLine.Type::Item, Item[i]."No.", 2);
        end;

        // Certify BOM
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        Item[1].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[1].Modify(true);
    end;

    local procedure UpdateInventoryUsingWarehouseJournal(Bin: Record Bin; Item: Record Item; Quantity: Decimal; UnitOfMeasureCode: Code[10]; ItemTracking: Boolean)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        LibraryWarehouse.WarehouseJournalSetup(Bin."Location Code", WarehouseJournalTemplate, WarehouseJournalBatch);
        CreateAndRegisterWarehouseJournalLine(WarehouseJournalBatch, Bin, Item, Quantity, UnitOfMeasureCode, ItemTracking);
        CalculateWarehouseAdjustmentAndPostItemJournalLine(Item);
    end;

    local procedure CreateAndRegisterWarehouseJournalLine(WarehouseJournalBatch: Record "Warehouse Journal Batch"; Bin: Record Bin; Item: Record Item; Quantity: Decimal; UnitOfMeasureCode: Code[10]; ItemTracking: Boolean)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        WarehouseJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseJournalLine.Modify(true);
        if ItemTracking then
            WarehouseJournalLine.OpenItemTrackingLines();
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
    end;

    local procedure CalculateWarehouseAdjustmentAndPostItemJournalLine(var Item: Record Item)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure SetProductionBinsAsDedicated(Location: Record Location)
    var
        Bin: Record Bin;
    begin
        if not Location."Directed Put-away and Pick" then
            exit;

        Bin.Get(Location.Code, Location."From-Production Bin Code");
        if not Bin.Dedicated then begin
            Bin.Dedicated := true;
            Bin.Modify(true);
        end;

        Bin.Get(Location.Code, Location."To-Production Bin Code");
        if not Bin.Dedicated then begin
            Bin.Dedicated := true;
            Bin.Modify(true);
        end;
    end;

    local procedure UpdateQtyToHandleRegisterPickAndDeleteRest(ProdOrderComponent: Record "Prod. Order Component"; PickLineQty: Decimal; Rate: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
        WarehouseActivityLine, Database::"Prod. Order Component", ProdOrderComponent."Status".AsInteger(), ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");

        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader."Type");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        if WarehouseActivityLine.FindSet(true) then
            repeat
                WarehouseActivityLine.TestField(Quantity, PickLineQty);
                WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity * Rate);
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;

        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.");
        WarehouseActivityHeader.Delete(true);
    end;

    local procedure SetWarehouseEmployeeDefaultLocation(LocationCode: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        if UserId() = '' then
            exit;

        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.SetRange("Location Code", LocationCode);
        WarehouseEmployee.SetRange(Default, true);
        if WarehouseEmployee.IsEmpty then begin
            WarehouseEmployee.SetRange("Location Code");
            if WarehouseEmployee.FindFirst() then begin
                WarehouseEmployee.Default := false;
                WarehouseEmployee.Modify(true);
            end;

            WarehouseEmployee.SetRange("Location Code", LocationCode);
            if not WarehouseEmployee.FindFirst() then
                LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, true)
            else begin
                WarehouseEmployee.Default := true;
                WarehouseEmployee.Modify(true);
            end;
        end;
    end;

    local procedure FindBinForPick(var Bin: Record Bin; Location: Record Location; Dedicated: Boolean; BinIndex: Integer)
    begin
        Bin.Init();
        Bin.Reset();
        Bin.SetRange("Location Code", Location.Code);
        if Location."Directed Put-away and Pick" then
            Bin.SetRange("Zone Code", 'PICK');

        Bin.SetRange(Dedicated, Dedicated);
        Bin.FindSet(true);

        if BinIndex > 1 then
            Bin.Next(BinIndex - 1);
    end;

    local procedure PC431(var Item: array[4] of Record Item; var ProductionBOMHeader: Record "Production BOM Header"; var RoutingHeader: Record "Routing Header"; FlushingMethodOfChild1: Enum "Flushing Method"; FlushingMethodOfChild2: Enum "Flushing Method"; FlushingMethodOfWorkCenter: Enum "Flushing Method")
    var
        ProductionBOMLine: Record "Production BOM Line";
        RoutingLink: Record "Routing Link";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        PC429(Item, ProductionBOMHeader, RoutingHeader, FlushingMethodOfChild1);

        LibraryInventory.CreateItem(Item[4]);
        ChangeFlushingMethodOnItem(Item[4], FlushingMethodOfChild2);

        // routing link code to Production BOM
        ProductionBOMHeader.Get(ProductionBOMHeader."No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        RoutingLink.Get(ProductionBOMLine."Routing Link Code");

        // add a new line to Production BOM with Routing Link code
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '',
          ProductionBOMLine.Type::Item, Item[4]."No.", 2);

        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // Flushing Method of Work center
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.FindLast();
        WorkCenter.Get(RoutingLine."No.");
        WorkCenter.Validate("Flushing Method", FlushingMethodOfWorkCenter);
        WorkCenter.Modify(true);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; LocationCode: Code[10]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure CreateAndPostInventoryAdjustmentWithLotNo(Item: Record Item; LocationCode: Code[10]; var LotNo: Code[50]; Bin: Record Bin; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
    begin
        if LotNo = '' then
            LotNo := NoSeries.GetNextNo(Item."Lot Nos.", WorkDate(), true);

        ClearJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingModalPageHandler(var ProdOrderRouting: TestPage "Prod. Order Routing")
    begin
        ProdOrderRouting.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerNothing(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_THERE_NOTHING_TO_CREATE) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler_TC49(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;
        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, Text004) > 0, Message);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC420MessageHandler(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;
        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_MOVMT_CREATED) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, MSG_PICK_CREATED) > 0, Message);
            3:
                Assert.IsTrue(StrPos(Message, MSG_THERE_NOTHING_TO_CREATE) > 0, Message);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TC421MessageHandler(Message: Text[1024])
    begin
        ErrorMessageCounter += 1;
        case ErrorMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, MSG_MOVMT_CREATED) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, MSG_PICK_CREATED) > 0, Message);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_MOVMT_CREATED) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerSimple(Message: Text)
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure InvtPickCreatedMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_PICK_CREATED) > 0, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DeleteWhseActivityLineConfirm(Question: Text[1024]; var Val: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, Text006) > 0, Question);
        Val := true;
    end;

    [ConfirmHandler]
    procedure SyncBinCodeOnProdComponentConfirm(Question: Text[1024]; var Val: Boolean)
    begin
        Val := false;
    end;
}

