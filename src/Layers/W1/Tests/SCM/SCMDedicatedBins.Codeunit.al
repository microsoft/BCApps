codeunit 137502 "SCM Dedicated Bins"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Bin] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        MessageCounter: Integer;
        IsInitialized: Boolean;
        AutomaticBinUpdate: Label 'This change may have caused bin codes on some production order component lines to be different from those on the production order routing line. Do you want to automatically align all of these unmatched bin codes?';
        ErrLocationOnResourceCard: Label 'Location %1 must be set up with Bin Mandatory if the Work Center %2 uses it.';
        CfmRemoveAllBinCode: Label 'If you change the %1, then all bin codes on the %2 and related %3 will be removed. Are you sure that you want to continue?';
        CfmBinDedicated: Label 'The bin B1 is Dedicated.\Do you still want to use this bin?';
        VSTF190324Msg1: Label 'There is nothing to create.';
        MSG_INVT_PICK_CREATED: Label 'Number of Invt. Pick activities created: 1 out of a total of 1.';

    [Normal]
    local procedure Initialize()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Dedicated Bins");
        // Initialize setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Dedicated Bins");
        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        // set Manufacturing Setup Component @ Location = blank
        LibraryManufacturing.SetComponentsAtLocation('');
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Default Flushing Method", ManufacturingSetup."Default Flushing Method"::"Pick + Manual");
        ManufacturingSetup.Modify(true);
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Dedicated Bins");
    end;

    local procedure CreateWhseLocation(var Location: Record Location; DirectedPickPutAway: Boolean; RequireReceive: Boolean; RequirePutAway: Boolean; RequireShipment: Boolean; RequirePick: Boolean; BinMandatory: Boolean)
    var
        WhseEmployee: Record "Warehouse Employee";
    begin
        WhseEmployee.DeleteAll(true);
        if DirectedPickPutAway then
            LibraryWarehouse.CreateFullWMSLocation(Location, 2)
        else
            LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location.Code, DirectedPickPutAway);
    end;

    local procedure CreateBin(var Bin: Record Bin; LocationCode: Code[10]; ZoneCode: Code[10]; BinTypeCode: Code[10])
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, '', ZoneCode, BinTypeCode);
    end;

    local procedure CreateAndPostPositiveAdjustmt(var Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WhseJournalTemplate: Record "Warehouse Journal Template";
        WhseJournalBatch: Record "Warehouse Journal Batch";
    begin
        FindItemJournal(ItemJournalTemplate, ItemJournalBatch);
        Location.Get(LocationCode);
        if Location."Directed Put-away and Pick" then begin
            LibraryWarehouse.WarehouseJournalSetup(LocationCode, WhseJournalTemplate, WhseJournalBatch);
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WhseJournalTemplate.Name, WhseJournalBatch.Name,
              LocationCode, '', BinCode, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
            LibraryWarehouse.PostWhseJournalLine(WhseJournalTemplate.Name, WhseJournalBatch.Name, Location.Code);
            Item.SetRange("Location Filter", LocationCode);
            LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');
        end else begin
            LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
            ItemJournalLine.Validate("Location Code", LocationCode);
            ItemJournalLine.Validate("Bin Code", BinCode);
            ItemJournalLine.Modify(true);
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndReserveSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; ReservedQty: Decimal)
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, ReservedQty, LocationCode, WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('SetupDefaultBinsConfirmHndl')]
    [Scope('OnPrem')]
    procedure SetupDefaultBins()
    begin
        Initialize();
        // A. Choosing a location with "Require Pick"/ "Require put-away"/"Bin Mandatory" as FALSE
        SetupDefaultBinsScenario(false, false, false);
        // B. Same as above but Require Receive and Require Shipment set to TRUE
        SetupDefaultBinsScenario(true, true, false);
        // C. Same as A. but Directed picks and put-way set to TRUE
        SetupDefaultBinsScenario(true, true, true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SetupDefaultBinsConfirmHndl(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CfmRemoveAllBinCode) > 0, 'Incorrect confirm dialog: ' + Question);
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('ConsumptionBinsConfirmHndl')]
    [Scope('OnPrem')]
    procedure ConsumptionBins()
    begin
        Initialize();
        ConsumptionBinsScenario();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConsumptionBinsConfirmHndl(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, AutomaticBinUpdate) > 0, 'Incorrect confirm dialog: ' + Question);
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('DedicatedBinsMsgHndl,DedicatedBinsConfirmHndl')]
    [Scope('OnPrem')]
    procedure DedicatedBins()
    begin
        Initialize();
        DedicatedBinsScenarioA();
        DedicatedBinsScenarioB();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DedicatedBinsMsgHndl(Message: Text[1024])
    var
        GotExpectedMessage: Boolean;
    begin
        GotExpectedMessage := (StrPos(Message, MSG_INVT_PICK_CREATED) > 0) or
          (StrPos(Message, 'Warehouse Shipment Header has been created') > 0);
        Assert.IsTrue(GotExpectedMessage, 'Unexpected message: ' + Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DedicatedBinsConfirmHndl(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CfmBinDedicated) > 0, 'Incorrect confirm dialog: ' + Question);
        Reply := true;
    end;

    local procedure FindItemJournal(var ItemJournalTemplate: Record "Item Journal Template"; var ItemJournalBatch: Record "Item Journal Batch")
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure FindWhseJournal(var WhseJournalTemplate: Record "Warehouse Journal Template"; var WhseJournalBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10])
    begin
        WhseJournalTemplate.SetRange(Type, WhseJournalTemplate.Type::Item);
        WhseJournalTemplate.FindFirst();
        WhseJournalBatch.SetRange("Journal Template Name", WhseJournalTemplate.Name);
        if LocationCode <> '' then
            WhseJournalBatch.SetRange("Location Code", LocationCode);
        WhseJournalBatch.FindFirst();
    end;

    local procedure FindWhsePickRequestForShipment(var WhsePickRequest: Record "Whse. Pick Request"; WhseShipmentNo: Code[20])
    begin
        WhsePickRequest.SetRange(Status, WhsePickRequest.Status::Released);
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Shipment);
        WhsePickRequest.SetRange("Document No.", WhseShipmentNo);
        WhsePickRequest.FindFirst();
    end;

    local procedure SetupDefaultBinsScenario(RequireReceive: Boolean; RequireShipment: Boolean; DirectedPickAndPut: Boolean)
    var
        Location: Record Location;
        BinType: Record "Bin Type";
        OpenShpFlrBin: Record Bin;
        InbBin: Record Bin;
        OutBin: Record Bin;
        MCOpenShpFlrBin: Record Bin;
        MCInbBin: Record Bin;
        MCOutBin: Record Bin;
        AdjustmentBin: Record Bin;
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Zone: Record Zone;
        WarehouseJnlLine: Record "Warehouse Journal Line";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ErrorText: Text[250];
    begin
        // create location
        CreateLocation(Location);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Shipment", RequireShipment);
        if DirectedPickAndPut then begin
            Location.Validate("Bin Mandatory", true);
            Location.Validate("Directed Put-away and Pick", true);
        end;
        Location.Modify(true);

        // create bins
        if DirectedPickAndPut then begin
            BinType.SetRange(Receive, false);
            BinType.SetRange(Ship, false);
            BinType.SetRange("Put Away", false);
            BinType.SetRange(Pick, false);
            BinType.FindFirst();
            LibraryWarehouse.CreateZone(Zone, 'ZONE', Location.Code, BinType.Code, '', '', 0, false);
        end;
        LibraryWarehouse.CreateBin(OpenShpFlrBin, Location.Code, 'OpenSFB', Zone.Code, Zone."Bin Type Code");
        LibraryWarehouse.CreateBin(InbBin, Location.Code, 'InbB', Zone.Code, Zone."Bin Type Code");
        LibraryWarehouse.CreateBin(OutBin, Location.Code, 'OutB', Zone.Code, Zone."Bin Type Code");
        LibraryWarehouse.CreateBin(MCOpenShpFlrBin, Location.Code, 'MCOpenSFB', Zone.Code, Zone."Bin Type Code");
        LibraryWarehouse.CreateBin(MCInbBin, Location.Code, 'MCInbB', Zone.Code, Zone."Bin Type Code");
        LibraryWarehouse.CreateBin(MCOutBin, Location.Code, 'MCOutB', Zone.Code, Zone."Bin Type Code");

        // create resource
        LibraryManufacturing.CreateWorkCenter(WorkCenter);

        // assign location code
        if not DirectedPickAndPut then begin
            Commit(); // added to save the data before ASSERTERROR call- as it rolls back all changes yet
            asserterror WorkCenter.Validate("Location Code", Location.Code);
            Assert.AssertNothingInsideFilter();
        end;

        // Bin Mandatory = TRUE
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        // assign location code
        WorkCenter.Validate("Location Code", Location.Code);
        WorkCenter.Modify(true);

        // set outbound & inbound bin
        WorkCenter.Validate("From-Production Bin Code", OutBin.Code);
        WorkCenter.Validate("Open Shop Floor Bin Code", OpenShpFlrBin.Code);
        WorkCenter.Validate("To-Production Bin Code", InbBin.Code);
        WorkCenter.Modify(true);

        // create default machine center
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", 0);

        // verify location code on machine center
        Assert.AreEqual(WorkCenter."Location Code", MachineCenter."Location Code", 'Location in machine center matches work center');

        // set up bin codes for machine center
        MachineCenter.Validate("Open Shop Floor Bin Code", MCOpenShpFlrBin.Code);
        MachineCenter.Validate("To-Production Bin Code", MCInbBin.Code);
        MachineCenter.Validate("From-Production Bin Code", MCOutBin.Code);
        MachineCenter.Modify(true);

        // set location code = blank on WC
        WorkCenter.Validate("Location Code", '');
        WorkCenter.Modify(true);
        // verify all bins are set to blank
        Assert.AreEqual('', WorkCenter."Open Shop Floor Bin Code", 'Bin code should have been blank');
        Assert.AreEqual('', WorkCenter."To-Production Bin Code", 'Bin code should have been blank');
        Assert.AreEqual('', WorkCenter."From-Production Bin Code", 'Bin code should have been blank');
        MachineCenter.Get(MachineCenter."No.");
        Assert.AreEqual(WorkCenter."Location Code", MachineCenter."Location Code", 'Location code should have been blank');
        Assert.AreEqual('', MachineCenter."Open Shop Floor Bin Code", 'Bin code should have been blank');
        Assert.AreEqual('', MachineCenter."To-Production Bin Code", 'Bin code should have been blank');
        Assert.AreEqual('', MachineCenter."From-Production Bin Code", 'Bin code should have been blank');

        // set data back to where it was- set location and bins
        WorkCenter.Validate("Location Code", Location.Code);
        WorkCenter.Validate("Open Shop Floor Bin Code", OpenShpFlrBin.Code);
        WorkCenter.Validate("To-Production Bin Code", InbBin.Code);
        WorkCenter.Validate("From-Production Bin Code", OutBin.Code);
        WorkCenter.Modify(true);
        MachineCenter.Get(MachineCenter."No.");
        MachineCenter.Validate("Open Shop Floor Bin Code", MCOpenShpFlrBin.Code);
        MachineCenter.Validate("To-Production Bin Code", MCInbBin.Code);
        MachineCenter.Modify(true);

        // set Bin Mandatory = FALSE
        if not DirectedPickAndPut then begin
            Commit(); // added to save the data before ASSERTERROR call- as it rolls back all changes yet
            asserterror Location.Validate("Bin Mandatory", false);
            ErrorText := StrSubstNo(ErrLocationOnResourceCard,
                Location.Code,
                WorkCenter."No.");
            Assert.IsTrue(StrPos(GetLastErrorText, ErrorText) > 0, 'Unexpected error message: ' + GetLastErrorText);
            ClearLastError();
        end;

        // create an item and post 10 PCS on the outbound bin
        FindItemJournal(ItemJournalTemplate, ItemJournalBatch);
        CreateItem(Item);
        if DirectedPickAndPut then begin
            FindWhseJournal(WarehouseJournalTemplate, WarehouseJournalBatch, '');
            LibraryWarehouse.CreateBin(AdjustmentBin, Location.Code, 'AdjB', Zone.Code, Zone."Bin Type Code");
            Location.Validate("Adjustment Bin Code", AdjustmentBin.Code);
            Location.Modify(true);
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJnlLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name,
              Location.Code, '', OutBin.Code, WarehouseJnlLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
            LibraryWarehouse.PostWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code);
            LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');
        end else begin
            LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
            ItemJournalLine.Validate("Location Code", Location.Code);
            ItemJournalLine.Validate("Bin Code", OutBin.Code);
            ItemJournalLine.Modify(true);
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // empty the bin
        if DirectedPickAndPut then begin
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJnlLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name,
              Location.Code, '', OutBin.Code, WarehouseJnlLine."Entry Type"::"Negative Adjmt.", Item."No.", -10);
            LibraryWarehouse.PostWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code);
            LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');
        end else begin
            LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", 10);
            ItemJournalLine.Validate("Location Code", Location.Code);
            ItemJournalLine.Validate("Bin Code", OutBin.Code);
            ItemJournalLine.Modify(true);
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // delete location & related inventory setups
        InventoryPostingSetup.SetRange("Location Code", Location.Code);
        InventoryPostingSetup.DeleteAll();
        Location.Delete(true);
        // verify all location codes and bin codes are set to empty
        WorkCenter.Get(WorkCenter."No."); // refresh
        Assert.AreEqual('', WorkCenter."Location Code", 'Location code should have been blank');
        Assert.AreEqual('', WorkCenter."Open Shop Floor Bin Code", 'Bin code should have been blank');
        Assert.AreEqual('', WorkCenter."To-Production Bin Code", 'Bin code should have been blank');
        Assert.AreEqual('', WorkCenter."From-Production Bin Code", 'Bin code should have been blank');
        MachineCenter.Get(MachineCenter."No."); // refresh
        Assert.AreEqual('', MachineCenter."Location Code", 'Location code should have been blank');
        Assert.AreEqual('', MachineCenter."Open Shop Floor Bin Code", 'Bin code should have been blank');
        Assert.AreEqual('', MachineCenter."To-Production Bin Code", 'Bin code should have been blank');
        Assert.AreEqual('', MachineCenter."From-Production Bin Code", 'Bin code should have been blank');
    end;

    local procedure ConsumptionBinsScenario()
    var
        WorkCenter1: Record "Work Center";
        MachineCenter1: Record "Machine Center";
        MachineCenter2: Record "Machine Center";
        MachineCenter3: Record "Machine Center";
        WorkCenter2: Record "Work Center";
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        ChildItem3: Record Item;
        ParentItem: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Location2: Record Location;
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent2: Record "Prod. Order Component";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        // create resources
        LibraryManufacturing.CreateWorkCenter(WorkCenter1);
        LibraryManufacturing.CreateMachineCenter(MachineCenter1, WorkCenter1."No.", 1);
        LibraryManufacturing.CreateMachineCenter(MachineCenter2, WorkCenter1."No.", 1);
        LibraryManufacturing.CreateMachineCenter(MachineCenter3, WorkCenter1."No.", 1);
        LibraryManufacturing.CreateWorkCenter(WorkCenter2);

        // create items
        CreateItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Modify(true);
        CreateItem(ChildItem1);
        CreateItem(ChildItem2);
        CreateItem(ChildItem3);
        ChildItem3.Validate("Flushing Method", ChildItem3."Flushing Method"::Backward);
        ChildItem3.Modify(true);
        // create bom
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeader, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProdBOMHeader, ProdBOMLine, '', ProdBOMLine.Type::Item, ChildItem1."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
          ProdBOMHeader, ProdBOMLine, '', ProdBOMLine.Type::Item, ChildItem2."No.", 1);
        ProdBOMLine.Validate("Routing Link Code", '100');
        ProdBOMLine.Modify(true);
        LibraryManufacturing.CreateProductionBOMLine(
          ProdBOMHeader, ProdBOMLine, '', ProdBOMLine.Type::Item, ChildItem3."No.", 1);
        ProdBOMLine.Validate("Routing Link Code", '200');
        ProdBOMLine.Modify(true);
        ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
        ProdBOMHeader.Modify(true);
        ParentItem.Validate("Production BOM No.", ProdBOMHeader."No.");
        // create routing
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter1."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Machine Center", MachineCenter1."No.");
        RoutingLine.Validate("Routing Link Code", '100');
        RoutingLine.Modify(true);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', '30', RoutingLine.Type::"Machine Center", MachineCenter2."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', '40', RoutingLine.Type::"Machine Center", MachineCenter3."No.");
        RoutingLine.Validate("Routing Link Code", '200');
        RoutingLine.Modify(true);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', '50', RoutingLine.Type::"Work Center", WorkCenter2."No.");
        RoutingLine.Validate("Routing Link Code", '300');
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        ParentItem.Validate("Routing No.", RoutingHeader."No.");
        ParentItem.Modify(true);

        // create location and bins
        CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Pick", true);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'WC1-OSFB', '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'WC1-IB', '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'MC1-OSFB', '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'MC1-IB', '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'MC2-OSFB', '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'MC2-IB', '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'LOC-OSFB', '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'LOC-IB', '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'DUMMY', '', '');
        Location.Validate("Open Shop Floor Bin Code", 'LOC-OSFB');
        Location.Validate("To-Production Bin Code", 'LOC-IB');
        Location.Modify(true);

        // set default bins on resources
        WorkCenter1.Validate("Location Code", Location.Code);
        WorkCenter1.Validate("Open Shop Floor Bin Code", 'WC1-OSFB');
        WorkCenter1.Validate("To-Production Bin Code", 'WC1-IB');
        WorkCenter1.Modify(true);
        MachineCenter1.Get(MachineCenter1."No.");
        Assert.AreEqual(WorkCenter1."Location Code", MachineCenter1."Location Code", 'Location code should have been set already');
        MachineCenter1.Validate("Open Shop Floor Bin Code", 'MC1-OSFB');
        MachineCenter1.Validate("To-Production Bin Code", 'MC1-IB');
        MachineCenter1.Modify(true);
        MachineCenter2.Get(MachineCenter2."No.");
        Assert.AreEqual(WorkCenter1."Location Code", MachineCenter2."Location Code", 'Location code should have been set already');
        MachineCenter2.Validate("Open Shop Floor Bin Code", 'MC2-OSFB');
        MachineCenter2.Validate("To-Production Bin Code", 'MC2-IB');
        MachineCenter2.Modify(true);

        // create released prod order
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, ParentItem."No.", 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // VERIFY
        // routing lines bin codes
        ProdOrderRtngLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        AssertBinCodesOnProdRtngs(ProdOrderRtngLine, '10', 'WC1-OSFB', 'WC1-IB');
        AssertBinCodesOnProdRtngs(ProdOrderRtngLine, '20', 'MC1-OSFB', 'MC1-IB');
        AssertBinCodesOnProdRtngs(ProdOrderRtngLine, '30', 'MC2-OSFB', 'MC2-IB');
        AssertBinCodesOnProdRtngs(ProdOrderRtngLine, '40', 'WC1-OSFB', 'WC1-IB');
        AssertBinCodesOnProdRtngs(ProdOrderRtngLine, '50', '', '');
        // component lines bin codes
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem1."No.", '', ChildItem1."Flushing Method", Location.Code, 'WC1-IB');
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem2."No.", '100', ChildItem2."Flushing Method", Location.Code, 'MC1-IB');
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem3."No.", '200', ChildItem3."Flushing Method", Location.Code, 'WC1-OSFB');

        ManufacturingSetup.Get();

        // set flushing method = Forward for X-CHILD1
        ProdOrderComponent.SetRange("Item No.", ChildItem1."No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Flushing Method", ProdOrderComponent."Flushing Method"::Forward);
        ProdOrderComponent.Modify(true);
        AssertBinCodesOnComponents(ProdOrderComponent,
          ChildItem1."No.",
          '',
          ProdOrderComponent."Flushing Method"::Forward,
          Location.Code,
          WorkCenter1."Open Shop Floor Bin Code");
        ProdOrderComponent.Validate("Item No.");
        ProdOrderComponent.Modify(true);
        AssertBinCodesOnComponents(ProdOrderComponent,
          ChildItem1."No.",
          '',
          ManufacturingSetup."Default Flushing Method",
          Location.Code,
          WorkCenter1."To-Production Bin Code");

        // create new location & bins
        CreateLocation(Location2);
        LibraryWarehouse.CreateBin(Bin, Location2.Code, 'X', '', '');
        LibraryWarehouse.CreateBin(Bin, Location2.Code, 'Y', '', '');
        Location2.Validate("Bin Mandatory", true);
        Location2.Modify(true);
        Location2.Validate("Open Shop Floor Bin Code", 'X');
        Location2.Validate("To-Production Bin Code", 'Y');
        Location2.Modify(true);

        // create a new component line and verify filled in bin code
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent2, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent2.Validate("Item No.", ChildItem3."No.");
        ProdOrderComponent2.Validate("Quantity per", 1);
        ProdOrderComponent2.Validate("Location Code", Location2.Code);
        ProdOrderComponent2.Modify(true);
        AssertBinCodesOnComponents(ProdOrderComponent,
          ChildItem3."No.", '', ChildItem3."Flushing Method", Location2.Code, Location2."Open Shop Floor Bin Code");

        // refresh prod. order - calculate only routing
        FindItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, false, false);
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem1."No.", '', ManufacturingSetup."Default Flushing Method",
          Location.Code, WorkCenter1."To-Production Bin Code");
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem2."No.", '100', ChildItem2."Flushing Method",
          Location.Code, MachineCenter1."To-Production Bin Code");
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem3."No.", '200', ChildItem3."Flushing Method",
          Location.Code, WorkCenter1."Open Shop Floor Bin Code");
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem3."No.", '', ChildItem3."Flushing Method",
          Location2.Code, Location2."Open Shop Floor Bin Code");

        // change last line for X-CHILD3 to have Routing Link Code and Manual Flushing and location as first one
        ProdOrderComponent.SetRange("Item No.", ChildItem3."No.");
        ProdOrderComponent.FindLast();
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Validate("Routing Link Code", '300');
        ProdOrderComponent.Validate("Flushing Method", ProdOrderComponent."Flushing Method"::"Pick + Manual");
        ProdOrderComponent.Modify(true);
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem3."No.", '300', ProdOrderComponent."Flushing Method"::"Pick + Manual",
          Location.Code, Location."To-Production Bin Code");

        // change the bin code on this component line and refresh (only calc. routing)
        ProdOrderComponent.Validate("Bin Code", 'DUMMY');
        ProdOrderComponent.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, false, false);
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem1."No.", '', ManufacturingSetup."Default Flushing Method",
          Location.Code, WorkCenter1."To-Production Bin Code");
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem2."No.", '100', ManufacturingSetup."Default Flushing Method",
          Location.Code, MachineCenter1."To-Production Bin Code");
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem3."No.", '200', ProdOrderComponent."Flushing Method"::Backward,
          Location.Code, WorkCenter1."Open Shop Floor Bin Code");
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem3."No.", '300', ProdOrderComponent."Flushing Method"::"Pick + Manual",
          Location.Code, Location."To-Production Bin Code");

        // refresh prod. order by ONLY calc. components
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, false, true, false);
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem1."No.", '', ChildItem1."Flushing Method", Location.Code, 'WC1-IB');
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem2."No.", '100', ChildItem2."Flushing Method", Location.Code, 'MC1-IB');
        AssertBinCodesOnComponents(ProdOrderComponent, ChildItem3."No.", '200', ChildItem3."Flushing Method", Location.Code, 'WC1-OSFB');
    end;

    local procedure DedicatedBinsScenarioA()
    var
        Location: Record Location;
        Bin1: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        BinShpt: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        Zone: Record Zone;
        BinContent: Record "Bin Content";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        BinType: Record "Bin Type";
    begin
        // create location with 3 bins
        CreateLocation(Location);
        LibraryWarehouse.CreateBin(Bin1, Location.Code, 'B1', '', '');
        Bin1.Validate(Dedicated, true);
        Bin1.Modify(true);
        LibraryWarehouse.CreateBin(Bin2, Location.Code, 'B2', '', '');
        LibraryWarehouse.CreateBin(Bin3, Location.Code, 'B3', '', '');
        LibraryWarehouse.CreateBin(BinShpt, Location.Code, 'Shpt', '', '');

        // make location X as Require Pick & Bin Mandatory
        Location.Validate("Require Pick", true);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        // create item
        CreateItem(Item);

        // post inventory for item
        FindItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 100);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin1.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin2.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin3.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // create sales order for 3 PCS of X-CHILD. Release. Create inventory pick.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 3);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // Verify that the inventory pick is created for a total of 2 PCS, 1 each from bins B2 and B3
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Source No.", SalesHeader."No.");
        WhseActivityLine.SetRange("Source Type", DATABASE::"Sales Line");
        WhseActivityLine.SetRange("Source Subtype", SalesHeader."Document Type");
        Assert.AreEqual(2, WhseActivityLine.Count, 'Expected 2 lines on Inventory pick.');
        WhseActivityLine.FindSet(false);
        repeat
            Assert.AreEqual(1, WhseActivityLine.Quantity, 'Expected 1 PCS.');
            Assert.AreNotEqual(Bin1.Code, WhseActivityLine."Bin Code", 'Nothing shud b taken from bin1');
        until WhseActivityLine.Next() = 0;

        // Delete the inventory pick
        WhseActivityHeader.Get(WhseActivityHeader.Type::"Invt. Pick", WhseActivityLine."No.");
        WhseActivityHeader.Delete(true);

        // Set location X to have Require Shipment = TRUE.
        Location.Validate("Require Shipment", true);
        Location.Modify(true);

        // set sales line to bin Shpt and create bin content
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', BinShpt.Code, Item."No.", '', Item."Base Unit of Measure");
        SalesLine.Find();
        SalesLine.Validate("Bin Code", BinShpt.Code);
        SalesLine.Modify(true);

        // From sales order create warehouse shipment. Create pick
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WhseShipmentLine.SetRange("Source Subtype", SalesHeader."Document Type");
        WhseShipmentLine.FindLast();
        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);

        // Verify that the pick is created for 2 PCS each in the Take lines from bins B2 and B3
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Source No.", SalesHeader."No.");
        WhseActivityLine.SetRange("Source Type", DATABASE::"Sales Line");
        WhseActivityLine.SetRange("Source Subtype", SalesHeader."Document Type");
        Assert.AreEqual(2, WhseActivityLine.Count, 'Expected 2 lines on pick.');
        WhseActivityLine.FindSet(false);
        repeat
            Assert.AreEqual(1, WhseActivityLine.Quantity, 'Expected 1 PCS.');
            Assert.AreNotEqual(Bin1.Code, WhseActivityLine."Bin Code", 'Nothing shud b taken from bin1');
        until WhseActivityLine.Next() = 0;

        // delete previous activities
        WhseActivityHeader.Get(WhseActivityHeader.Type::Pick, WhseActivityLine."No.");
        WhseActivityHeader.Delete(true);
        WhseShipmentHeader.Get(WhseShipmentHeader."No.");
        LibraryWarehouse.ReopenWhseShipment(WhseShipmentHeader);
        WhseShipmentHeader.Get(WhseShipmentHeader."No.");
        WhseShipmentHeader.Delete(true);

        // Try to set location to have Directed picks and put-away to TRUE. Expect no error.
        Location.Validate("Directed Put-away and Pick", true);
        Location.Modify(true);

        // Create another location with 2 bins B1 and B2 and set Directed put-way and Pick = TRUE
        CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Directed Put-away and Pick", true);
        Location.Modify(true);
        BinType.SetRange(Pick, true);
        BinType.SetRange("Put Away", false);
        BinType.FindFirst();
        LibraryWarehouse.CreateZone(Zone, 'ZONE', Location.Code, BinType.Code, '', '', 0, false);
        LibraryWarehouse.CreateBin(Bin1, Location.Code, 'B1', Zone.Code, Zone."Bin Type Code");

        // Now try to set B1 to dedicated. Expect no error.
        Bin1.Validate(Dedicated, true);
        Bin1.Modify(true);
    end;

    local procedure DedicatedBinsScenarioB()
    var
        Location: Record Location;
        Bin1: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        BinContent: Record "Bin Content";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // create location with 3 bins
        CreateLocation(Location);
        LibraryWarehouse.CreateBin(Bin1, Location.Code, 'B1', '', '');
        Bin1.Validate(Dedicated, true);
        Bin1.Modify(true);
        LibraryWarehouse.CreateBin(Bin2, Location.Code, 'B2', '', '');

        // make location X as Bin Mandatory
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        // create item
        CreateItem(Item);

        // create positive adjustment of 10 PCS each of item into the two bins
        FindItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin1.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin2.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // make sure that bin content B1 is default
        BinContent.Get(Location.Code, Bin2.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, false);
        BinContent.Modify(true);
        BinContent.Get(Location.Code, Bin1.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // create sales for 1 PCS
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // verify that bin code is not B1
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreNotEqual(Bin1.Code, SalesLine."Bin Code", 'Bin code is not B1');

        // Now set the bin code to B1.- a confirm dialog pops up
        SalesLine.Validate("Bin Code", Bin1.Code);
        SalesLine.Modify(true);
        // Verify bin is set to B1
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(Bin1.Code, SalesLine."Bin Code", 'bin is set to B1');

        // Create a purchase order for the item 1 PCS for the location.
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
        PurchLine.Validate("Location Code", Location.Code);
        PurchLine.Modify(true);

        // verify that the bin code is B1
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreEqual(Bin1.Code, PurchLine."Bin Code", 'Bin code is B1');

        // Now set quantity to -1 from 1 on the purchase line.- a confirm dialog pops up
        PurchLine.Validate(Quantity, -1);
        PurchLine.Modify(true);
        // Verify bin is set to B1
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreEqual(Bin1.Code, PurchLine."Bin Code", 'bin is set to B1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickFromShipmentWithAnotherDocReservedFromDedicatedBin()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Dedicated Bin] [Shipment] [Pick] [Reservation]
        // [SCENARIO 340437] Creating pick from shipment directly takes reserved quantity in dedicated bin into account.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Location set up for required shipment and pick. "Directed put-away and pick" = FALSE.
        // [GIVEN] Ordinary bin "B" and dedicated bin "D".
        CreateWhseLocation(Location, false, false, false, true, true, true);
        CreateBin(Bin[1], Location.Code, '', '');
        CreateBin(Bin[2], Location.Code, '', '');
        // Bin[2].Validate(Dedicated, true); // setting dedicated bin as a default shipment bin is not supported now
        // Bin[2].Modify(true);

        // [GIVEN] Set up the dedicated bin "D" as a default shipment bin.
        Location.Validate("Shipment Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Create item and post 60 pcs to bin "B".
        LibraryInventory.CreateItem(Item);
        CreateAndPostPositiveAdjustmt(Item, Location.Code, Bin[1].Code, 3 * Qty);

        // [GIVEN] Sales order "SO1" for 20 pcs fully reserved from the inventory.
        // [GIVEN] Create warehouse shipment, pick and register the pick.
        // [GIVEN] 20 pcs is thereby moved from bin "B" to the dedicated bin "D".
        CreateAndReserveSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, Qty, Qty);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Sales order "SO2" for 20 pcs fully reserved from the inventory.
        CreateAndReserveSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, Qty, Qty);

        // [GIVEN] Sales order "SO3" for 40 pcs, partially (20 pcs) reserved from the inventory.
        // [GIVEN] Create warehouse shipment.
        CreateAndReserveSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, 2 * Qty, Qty);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No."));

        // [WHEN] Create pick for "SO3".
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] A warehouse pick for 20 pcs is created, that is 60 in inventory minus 40 reserved for "SO1" and "SO2".
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, Qty);
        WarehouseActivityLine.TestField("Qty. to Handle", Qty);

        // [THEN] The pick can be successfully registered.
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickFromPickWorksheetWithAnotherDocReservedFromDedicatedBin()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Dedicated Bin] [Shipment] [Pick Worksheet] [Pick] [Reservation]
        // [SCENARIO 340437] Creating pick from shipment via pick worksheet takes reserved quantity in dedicated bin into account.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Location set up for required shipment and pick. "Directed put-away and pick" = FALSE.
        // [GIVEN] Ordinary bin "B" and dedicated bin "D".
        CreateWhseLocation(Location, false, false, false, true, true, true);
        CreateBin(Bin[1], Location.Code, '', '');
        CreateBin(Bin[2], Location.Code, '', '');
        // Bin[2].Validate(Dedicated, true); // setting dedicated bin as a default shipment bin is not supported now
        // Bin[2].Modify(true);

        // [GIVEN] Set up the dedicated bin "D" as a default shipment bin.
        Location.Validate("Shipment Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Create item and post 60 pcs to bin "B".
        LibraryInventory.CreateItem(Item);
        CreateAndPostPositiveAdjustmt(Item, Location.Code, Bin[1].Code, 3 * Qty);

        // [GIVEN] Sales order "SO1" for 20 pcs fully reserved from the inventory.
        // [GIVEN] Create warehouse shipment, pick and register the pick.
        // [GIVEN] 20 pcs is thereby moved from bin "B" to the dedicated bin "D".
        CreateAndReserveSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, Qty, Qty);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Sales order "SO2" for 20 pcs fully reserved from the inventory.
        CreateAndReserveSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, Qty, Qty);

        // [GIVEN] Sales order "SO3" for 40 pcs, partially (20 pcs) reserved from the inventory.
        // [GIVEN] Create warehouse shipment.
        CreateAndReserveSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, 2 * Qty, Qty);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No."));
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [WHEN] Open warehouse worksheet and pull the shipment for "SO3".
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        FindWhsePickRequestForShipment(WhsePickRequest, WarehouseShipmentHeader."No.");
        LibraryWarehouse.GetOutboundSourceDocuments(WhsePickRequest, WhseWorksheetName, Location.Code);

        // [THEN] Whse. worksheet line for full quantity (40 pcs) is created.
        // [THEN] "Qty. to Handle" on the worksheet line = 20 pcs.
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplate.Name);
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.SetRange("Item No.", Item."No.");
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.TestField(Quantity, 2 * Qty);
        WhseWorksheetLine.TestField("Qty. to Handle", Qty);

        // [THEN] A warehouse pick for 20 pcs will be created when you run "Create Pick" on the whse. worksheet.
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name,
          Location.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, Qty);
        WarehouseActivityLine.TestField("Qty. to Handle", Qty);

        // [THEN] This warehouse pick can be successfully registered.
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S465188_CreatePickFromPickWorksheetWithQtyOnDedicatedBinInQCZone()
    var
        Location: Record Location;
        Zone: Record Zone;
        BinPutPick: Record Bin;
        BinPutAwayDedicated: Record Bin;
        BinReceipt: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReceiveQty: Decimal;
        QCQty: Decimal;
        ShipQty: Decimal;
    begin
        // [FEATURE] [Dedicated Bin] [Warehouse Receipt] [Warehouse Put-away] [Warehouse Reclassification Journal] [Warehouse Shipment] [Pick Worksheet] [Warehouse Pick]
        // [SCENARIO 465188] Dealing with WMS and Dedicated Bin, Available Qty. to Pick should not use non-pickable bin QC.
        Initialize();
        ReceiveQty := LibraryRandom.RandIntInRange(20, 30);
        QCQty := LibraryRandom.RandIntInRange(1, 9);
        ShipQty := LibraryRandom.RandIntInRange(10, 19);

        // [GIVEN] Create Location with "Directed put-away and pick" and Warehouse Employee.
        CreateWhseLocation(Location, true, true, true, true, true, true);

        // [GIVEN] Create Bin for Put-away.
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        CreateBin(BinPutPick, Location.Code, Zone.Code, Zone."Bin Type Code");

        // [GIVEN] Create Dedicated Bin for QC.
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, false), false);
        CreateBin(BinPutAwayDedicated, Location.Code, Zone.Code, Zone."Bin Type Code");
        BinPutAwayDedicated.Validate(Dedicated, true);
        BinPutAwayDedicated.Modify(true);

        // [GIVEN] Create Bin for Receipt and set on Location as "Receipt Bin Code".
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(true, false, false, false), false);
        CreateBin(BinReceipt, Location.Code, Zone.Code, Zone."Bin Type Code");
        Location.Validate("Receipt Bin Code", BinReceipt.Code);
        Location.Modify(true);

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order with Item on ReceiveQty.
        CreatePurchaseOrderForLocation(PurchaseHeader, PurchaseLine, Location.Code, Item."No.", ReceiveQty);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create and Post Warehouse Receipt.
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Register Warehouse Put-away.
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Move QCQty part of received Qty. to QC Dedicated Bin.
        CreateWarehouseReclassificationJournal(WarehouseJournalLine,
          Location.Code, BinPutPick."Zone Code", BinPutPick.Code, BinPutAwayDedicated."Zone Code", BinPutAwayDedicated.Code, Item."No.", QCQty);
        LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code", true);

        // [GIVEN] Create Sales Order with Item on ShipQty.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ShipQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [GIVEN] Release Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create and Release Warehouse Shipment.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No."));
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [WHEN] Open Pick pick Worksheetand get created Warehouse Shipment.
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        FindWhsePickRequestForShipment(WhsePickRequest, WarehouseShipmentHeader."No.");
        LibraryWarehouse.GetOutboundSourceDocuments(WhsePickRequest, WhseWorksheetName, Location.Code);

        // [THEN] Whse. Worksheet Line has full "Qty. to Handle" and "Available Qty. to Pick" without Qty. on QC Dedicated Bin.
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplate.Name);
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.SetRange("Item No.", Item."No.");
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.TestField(Quantity, ShipQty);
        WhseWorksheetLine.TestField("Qty. to Handle", ShipQty);
        Assert.AreEqual(ReceiveQty - QCQty, WhseWorksheetLine.AvailableQtyToPick(), StrSubstNo('%1 must be %2, but it is %3.', 'Available Qty. to Pick', ReceiveQty - QCQty, WhseWorksheetLine.AvailableQtyToPick()));

        // [WHEN] "Create Pick" from Pick Worksheet.
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name,
          Location.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        // [THEN] Worksheet Activity Line has full "Qty. to Handle".
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, ShipQty);
        WarehouseActivityLine.TestField("Qty. to Handle", ShipQty);

        // [THEN] Warehouse Pick can be successfully registered.
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure CreateLocation(var Location: Record Location)
    var
        WhseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location.Code, true);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
    end;

    local procedure AssertBinCodesOnProdRtngs(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; OperationNo: Code[10]; OpenShopFloorBin: Code[20]; InboundBin: Code[20])
    begin
        ProdOrderRtngLine.SetRange("Operation No.", OperationNo);
        Assert.AreEqual(1, ProdOrderRtngLine.Count, 'Incorrect no. of routing lines with same operation no.: ' + OperationNo);
        ProdOrderRtngLine.FindFirst();
        Assert.AreEqual(OpenShopFloorBin, ProdOrderRtngLine."Open Shop Floor Bin Code", 'Incorrect open shop floor bin code.');
        Assert.AreEqual(InboundBin, ProdOrderRtngLine."To-Production Bin Code", 'Incorrect To-Production Bin Code.');
        // remove filter
        ProdOrderRtngLine.SetRange("Operation No.");
    end;

    local procedure AssertBinCodesOnComponents(var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20]; RoutingLinkCode: Code[10]; FlushingMethod: Enum "Flushing Method"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.SetRange("Routing Link Code", RoutingLinkCode);
        ProdOrderComponent.SetRange("Flushing Method", FlushingMethod);
        Assert.AreEqual(1, ProdOrderComponent.Count, 'Incorrect no. of component lines');
        ProdOrderComponent.FindFirst();
        Assert.AreEqual(LocationCode, ProdOrderComponent."Location Code", 'Incorrect location code.');
        Assert.AreEqual(BinCode, ProdOrderComponent."Bin Code", 'Incorrect bin code.');
        // remove filters
        ProdOrderComponent.SetRange("Item No.");
        ProdOrderComponent.SetRange("Routing Link Code");
        ProdOrderComponent.SetRange("Flushing Method");
    end;

    local procedure CreatePurchaseOrderForLocation(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), Database::"Purchase Header"));
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostWhseReceiptFromPO(var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(FindWarehouseReceiptNo(SourceDocument, SourceNo));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure FindWarehouseReceiptNo(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
        exit(WarehouseReceiptLine."No.");
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange(Type, Type);
        WarehouseActivityHeader.SetRange("No.", FindWarehouseActivityNo(SourceNo, Type));
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindWarehouseActivityNo(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"): Code[20]
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
        exit(WarehouseActivityLine."No.");
    end;

    local procedure CreateWarehouseReclassificationJournal(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; FromZoneCode: Code[10]; FromBinCode: Code[20]; ToZoneCode: Code[10]; ToBinCode: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Reclassification, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          LocationCode, FromZoneCode, FromBinCode, WarehouseJournalLine."Entry Type"::Movement, ItemNo, Qty);
        WarehouseJournalLine.Validate("From Zone Code", FromZoneCode);
        WarehouseJournalLine.Validate("From Bin Code", FromBinCode);
        WarehouseJournalLine.Validate("To Zone Code", ToZoneCode);
        WarehouseJournalLine.Validate("To Bin Code", ToBinCode);
        WarehouseJournalLine.Modify(true);
    end;

    [Test]
    [HandlerFunctions('VSTF190342MsgHndl')]
    [Scope('OnPrem')]
    procedure VSTF190342InvtPick()
    var
        Location: Record Location;
    begin
        CreateWhseLocation(Location, false, false, false, false, true, true);
        VSTF190342Scenario(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF190342WhsePick()
    var
        Location: Record Location;
    begin
        CreateWhseLocation(Location, false, false, false, true, true, true);
        VSTF190342Scenario(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF190342BinOnly()
    var
        Location: Record Location;
    begin
        CreateWhseLocation(Location, false, false, false, false, false, true);
        VSTF190342Scenario(Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF190342WMS()
    var
        Location: Record Location;
    begin
        CreateWhseLocation(Location, true, true, true, true, true, true);
        VSTF190342Scenario(Location);
    end;

    local procedure VSTF190342Scenario(var Location: Record Location)
    var
        ItemParent: Record Item;
        ItemChild: Record Item;
        Bin: Record Bin;
        BinDedicated: Record Bin;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        WarehouseRequest: Record "Warehouse Request";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        Zone: Record Zone;
    begin
        MessageCounter := 0;

        // create two bins- one of them being dedicated. Assign dedicated bin to To-Production Bin Code
        if Location."Directed Put-away and Pick" then begin
            LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
            CreateBin(Bin, Location.Code, Zone.Code, Zone."Bin Type Code");

            LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, false, false), false);
            CreateBin(BinDedicated, Location.Code, Zone.Code, Zone."Bin Type Code");
        end else begin
            CreateBin(Bin, Location.Code, '', '');
            CreateBin(BinDedicated, Location.Code, '', '');
        end;
        BinDedicated.Validate(Dedicated, true);
        BinDedicated.Modify(true);
        Location.Validate("To-Production Bin Code", BinDedicated.Code);
        Location.Modify(true);

        // create two items- one a parent of the other
        CreateItem(ItemChild);
        CreateItem(ItemParent);
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeader, ItemParent."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeader, ProdBOMLine, '', ProdBOMLine.Type::Item, ItemChild."No.", 1);
        ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
        ProdBOMHeader.Modify(true);
        ItemParent.Validate("Production BOM No.", ProdBOMHeader."No.");
        ItemParent.Modify(true);

        // put in 10 PCS of child item into inventory
        // for invt pick, put into dedicated bin - so that consumption can be posted directly from there
        // for bin mandatory, put into dedicated bin - to make a postable inventory pick directly from dedicated bin
        if not Location."Require Shipment" then
            CreateAndPostPositiveAdjustmt(ItemChild, Location.Code, BinDedicated.Code, 10)
        else
            // for whse. pick, put into non-dedicated bin - to make warehouse pick to the dedicated bin
            // for WMS, put into non-dedicated bin - to make warehouse pick to the dedicated bin
            CreateAndPostPositiveAdjustmt(ItemChild, Location.Code, Bin.Code, 10);

        // Create released prod. order for 1 PCS of PARENT from this location. Refresh and check that bin on the component line is dedicated
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, ItemParent."No.", 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderComp.SetRange(Status, ProductionOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComp.SetRange("Item No.", ItemChild."No.");
        ProdOrderComp.FindFirst();
        Assert.AreEqual(BinDedicated.Code, ProdOrderComp."Bin Code", 'Unmatched bin code- should be copied from location card');

        // Create pick and register
        WarehouseRequest.SetCurrentKey("Source Document", "Source No.");
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Prod. Consumption");
        WarehouseRequest.SetRange("Source No.", ProductionOrder."No.");
        if not Location."Require Shipment" then begin
            // for inventory pick,
            if Location."Require Pick" then begin
                // Expect a message- nothing to create. Because pick cannot be created FROM dedicated bin. EXIT
                LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, false, true, false);
                exit; // end test case here
            end // For bin mandatory, do nothing
        end else
            if Location."Require Pick" then begin
                // for warehouse picks, create and register pick
                LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
                WhseActivityLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
                WhseActivityLine.SetRange("Source Subtype", ProductionOrder.Status);
                WhseActivityLine.SetRange("Source No.", ProductionOrder."No.");
                WhseActivityLine.FindFirst();
                WhseActivityHeader.SetRange(Type, WhseActivityLine."Activity Type");
                WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
                WhseActivityHeader.FindFirst();
                LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
            end;

        // calculate consumption and post
        LibraryManufacturing.CalculateConsumptionForJournal(ProductionOrder, ProdOrderComp, WorkDate(), false);
        LibraryManufacturing.PostConsumptionJournal();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure VSTF190342MsgHndl(Message: Text[1024])
    begin
        MessageCounter += 1;
        case MessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, VSTF190324Msg1) > 0, 'Unexpected message: ' + Message);
        end;
    end;
}

