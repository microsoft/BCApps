codeunit 137200 "SCM Inventory Movement Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM] [Inventory Movement]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Movement Test");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Movement Test");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Movement Test");
    end;

    [Test]
    [HandlerFunctions('PurchaseHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementTest1()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemFinal: Record Item;
        ItemComp1: Record Item;
        ItemComp2: Record Item;
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
    begin
        // items have Flushing Method = Manual
        // no item tracking is set

        Initialize();

        // creating location with bins
        CreateLocationWithBins(Location, Bin);

        // creating two workcenters and routing which has 2 operations including Routing Link Code
        CreateRoutingWithWC(WorkCenter1, WorkCenter2, RoutingHeader);

        // creating items - one final and two components, each is linked to one operation via Routing Link Code
        CreateAllItemsWithBOM(
          ItemFinal, ItemComp1, ItemComp2,
          ItemComp1."Flushing Method"::"Pick + Manual",
          CopyStr(WorkCenter1."No.", 1, 10),
          CopyStr(WorkCenter2."No.", 1, 10),
          RoutingHeader."No.");

        // purchase components
        PurchaseComponentToWMS(ItemComp1, ItemComp2, Location);

        // create production order
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindLast();
        PrepareReleasedProdOrder(ProductionOrder, ItemFinal, Location.Code, Bin.Code);

        // Post output
        PostOutput(ProductionOrder);

        // Create and register Inventory Movement
        CreateAndRegisterInvtMovement(ProductionOrder);

        // Post consumption
        PostConsumption(ProductionOrder);

        // verify results
        VerifyConsumption(ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('PurchaseHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementTest2()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemFinal: Record Item;
        ItemComp1: Record Item;
        ItemComp2: Record Item;
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
    begin
        // items have Flushing Method = Forward
        // no item tracking is set

        Initialize();

        // creating location with bins
        CreateLocationWithBins(Location, Bin);

        // creating two workcenters and routing which has 2 operations including Routing Link Code
        CreateRoutingWithWC(WorkCenter1, WorkCenter2, RoutingHeader);

        // creating items - one final and two components, each is linked to one operation via Routing Link Code
        CreateAllItemsWithBOM(
          ItemFinal, ItemComp1, ItemComp2,
          ItemComp1."Flushing Method"::Forward,
          CopyStr(WorkCenter1."No.", 1, 10),
          CopyStr(WorkCenter2."No.", 1, 10),
          RoutingHeader."No.");

        // purchase components
        PurchaseComponentToWMS(ItemComp1, ItemComp2, Location);

        // create production order
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindLast();
        PrepareReleasedProdOrder(ProductionOrder, ItemFinal, Location.Code, Bin.Code);

        // Create and register Inventory Movement
        CreateAndRegisterInvtMovement(ProductionOrder);

        // Post output
        asserterror PostOutput(ProductionOrder);
        Assert.ExpectedErrorCannotFind(Database::"Bin Content");

        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('PurchaseHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementTest3()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemFinal: Record Item;
        ItemComp1: Record Item;
        ItemComp2: Record Item;
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
    begin
        // items have Flushing Method = Forward
        // no item tracking is set

        Initialize();

        // creating location with bins
        CreateLocationWithBins(Location, Bin);

        // creating two workcenters and routing which has 2 operations including Routing Link Code
        CreateRoutingWithWC(WorkCenter1, WorkCenter2, RoutingHeader);

        // creating items - one final and two components, each is linked to one operation via Routing Link Code
        CreateAllItemsWithBOM(
          ItemFinal, ItemComp1, ItemComp2,
          ItemComp1."Flushing Method"::Forward,
          CopyStr(WorkCenter1."No.", 1, 10),
          CopyStr(WorkCenter2."No.", 1, 10),
          RoutingHeader."No.");

        // purchase components
        PurchaseComponentToWMS(ItemComp1, ItemComp2, Location);

        // create production order
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindLast();
        PrepareReleasedProdOrder(ProductionOrder, ItemFinal, Location.Code, Bin.Code);

        // Create and register Inventory Movement - no one should be created
        CreateAndRegisterInvtMovement(ProductionOrder);

        // set bins with content in prod. order components
        SetBinsWithContent(ProductionOrder, Location.Code);

        // Post output
        PostOutput(ProductionOrder);

        // verify results
        VerifyConsumption(ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('PurchaseHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementTest4()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemFinal: Record Item;
        ItemComp1: Record Item;
        ItemComp2: Record Item;
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
    begin
        // items have Flushing Method = Backward
        // no item tracking is set

        Initialize();

        // creating location with bins
        CreateLocationWithBins(Location, Bin);

        // creating two workcenters and routing which has 2 operations including Routing Link Code
        CreateRoutingWithWC(WorkCenter1, WorkCenter2, RoutingHeader);

        // creating items - one final and two components, each is linked to one operation via Routing Link Code
        CreateAllItemsWithBOM(
          ItemFinal, ItemComp1, ItemComp2,
          ItemComp1."Flushing Method"::Backward,
          CopyStr(WorkCenter1."No.", 1, 10),
          CopyStr(WorkCenter2."No.", 1, 10),
          RoutingHeader."No.");

        // purchase components
        PurchaseComponentToWMS(ItemComp1, ItemComp2, Location);

        // create production order
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindLast();
        PrepareReleasedProdOrder(ProductionOrder, ItemFinal, Location.Code, Bin.Code);

        // Create and register Inventory Movement
        CreateAndRegisterInvtMovement(ProductionOrder);

        // Post output
        asserterror PostOutput(ProductionOrder);
        Assert.ExpectedErrorCannotFind(Database::"Bin Content");

        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('PurchaseHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementTest5()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemFinal: Record Item;
        ItemComp1: Record Item;
        ItemComp2: Record Item;
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
    begin
        // items have Flushing Method = Backward
        // no item tracking is set

        Initialize();

        // creating location with bins
        CreateLocationWithBins(Location, Bin);

        // creating two workcenters and routing which has 2 operations including Routing Link Code
        CreateRoutingWithWC(WorkCenter1, WorkCenter2, RoutingHeader);

        // creating items - one final and two components, each is linked to one operation via Routing Link Code
        CreateAllItemsWithBOM(
          ItemFinal, ItemComp1, ItemComp2,
          ItemComp1."Flushing Method"::Backward,
          CopyStr(WorkCenter1."No.", 1, 10),
          CopyStr(WorkCenter2."No.", 1, 10),
          RoutingHeader."No.");

        // purchase components
        PurchaseComponentToWMS(ItemComp1, ItemComp2, Location);

        // create production order
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindLast();
        PrepareReleasedProdOrder(ProductionOrder, ItemFinal, Location.Code, Bin.Code);

        // Create and register Inventory Movement - no one should be created
        CreateAndRegisterInvtMovement(ProductionOrder);

        // set bins with content in prod. order components
        SetBinsWithContent(ProductionOrder, Location.Code);

        // Post output
        PostOutput(ProductionOrder);

        // verify results
        VerifyConsumption(ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('PurchaseHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementTest6()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemFinal: Record Item;
        ItemComp1: Record Item;
        ItemComp2: Record Item;
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
    begin
        // items have Flushing Method = Pick + Forward
        // no item tracking is set

        Initialize();

        // creating location with bins
        CreateLocationWithBins(Location, Bin);

        // creating two workcenters and routing which has 2 operations including Routing Link Code
        CreateRoutingWithWC(WorkCenter1, WorkCenter2, RoutingHeader);

        // creating items - one final and two components, each is linked to one operation via Routing Link Code
        CreateAllItemsWithBOM(
          ItemFinal, ItemComp1, ItemComp2,
          ItemComp1."Flushing Method"::"Pick + Forward",
          CopyStr(WorkCenter1."No.", 1, 10),
          CopyStr(WorkCenter2."No.", 1, 10),
          RoutingHeader."No.");

        // purchase components
        PurchaseComponentToWMS(ItemComp1, ItemComp2, Location);

        // create production order
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindLast();
        PrepareReleasedProdOrder(ProductionOrder, ItemFinal, Location.Code, Bin.Code);

        // Create and register Inventory Movement
        CreateAndRegisterInvtMovement(ProductionOrder);

        // Post output
        PostOutput(ProductionOrder);

        // Post consumption
        PostConsumption(ProductionOrder);

        // verify results
        VerifyConsumption(ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('PurchaseHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementTest7()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemFinal: Record Item;
        ItemComp1: Record Item;
        ItemComp2: Record Item;
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
    begin
        // items have Flushing Method = Pick + Backward
        // no item tracking is set

        Initialize();

        // creating location with bins
        CreateLocationWithBins(Location, Bin);

        // creating two workcenters and routing which has 2 operations including Routing Link Code
        CreateRoutingWithWC(WorkCenter1, WorkCenter2, RoutingHeader);

        // creating items - one final and two components, each is linked to one operation via Routing Link Code
        CreateAllItemsWithBOM(
          ItemFinal, ItemComp1, ItemComp2,
          ItemComp1."Flushing Method"::"Pick + Backward",
          CopyStr(WorkCenter1."No.", 1, 10),
          CopyStr(WorkCenter2."No.", 1, 10),
          RoutingHeader."No.");

        // purchase components
        PurchaseComponentToWMS(ItemComp1, ItemComp2, Location);

        // create production order
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindLast();
        PrepareReleasedProdOrder(ProductionOrder, ItemFinal, Location.Code, Bin.Code);

        // Create and register Inventory Movement
        CreateAndRegisterInvtMovement(ProductionOrder);

        // Post output
        PostOutput(ProductionOrder);

        // Post consumption
        PostConsumption(ProductionOrder);

        // verify results
        VerifyConsumption(ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('PurchaseHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementTest10()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemFinal: Record Item;
        ItemComp1: Record Item;
        ItemComp2: Record Item;
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
    begin
        // items have Flushing Method = Manual
        // Serial Number is set

        Initialize();

        // creating location with bins
        CreateLocationWithBins(Location, Bin);

        // creating two workcenters and routing which has 2 operations including Routing Link Code
        CreateRoutingWithWC(WorkCenter1, WorkCenter2, RoutingHeader);

        // creating items - one final and two components, each is linked to one operation via Routing Link Code
        CreateAllItemsWithBOM(
          ItemFinal, ItemComp1, ItemComp2,
          ItemComp1."Flushing Method"::"Pick + Manual",
          CopyStr(WorkCenter1."No.", 1, 10),
          CopyStr(WorkCenter2."No.", 1, 10),
          RoutingHeader."No.");

        SetItemTracking(ItemComp1);

        // purchase components
        PurchaseComponentWithITToWMS(ItemComp1, ItemComp2, Location);

        // create production order
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindLast();
        PrepareReleasedProdOrder(ProductionOrder, ItemFinal, Location.Code, Bin.Code);
        AddSerialNumberToComponent(ProductionOrder);
        // Post output
        PostOutput(ProductionOrder);

        // Create and register Inventory Movement
        CreateAndRegisterInvtMovement(ProductionOrder);

        // Post consumption
        PostConsumption(ProductionOrder);

        // verify results
        VerifyConsumption(ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandlerSimple')]
    procedure MovementFromDedicatedBin()
    var
        Bin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
    begin
        // [FEATURE] [Dedicated] [Bin]
        // [SCENARIO 314511] Inventory Movement from Dedicated Bin is allowed

        // [GIVEN] Bin was set as Dedicated
        LibraryWarehouse.FindBin(Bin, CreateLocationWithWhseEmployeeAndNumberOfBins(2), '', 1);
        Bin.Validate(Dedicated, true);
        Bin.Modify(true);

        // [GIVEN] Item had stock of 10 PCS in the Bin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, LibraryInventory.CreateItemNo(), Bin."Location Code", Bin.Code, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Internal Movement with 10 PCS of the Item with the Bin set as From-Bin
        LibraryWarehouse.FindBin(Bin, Bin."Location Code", '', 2);
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Bin."Location Code", Bin.Code);
        LibraryWarehouse.CreateInternalMovementLine(
          InternalMovementHeader, InternalMovementLine, ItemJournalLine."Item No.", ItemJournalLine."Bin Code", Bin.Code,
          ItemJournalLine.Quantity);

        // [GIVEN] Created Inventory Movement from Internal Movement
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.", ItemJournalLine."Item No.");
        WarehouseActivityLine.SetRange("Bin Code", ItemJournalLine."Bin Code");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Register Inventory Movement
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        // [THEN] Registered Invt. Movement Take Line has 10 PCS of the Item and the Bin
        RegisteredInvtMovementLine.SetRange("Item No.", ItemJournalLine."Item No.");
        RegisteredInvtMovementLine.SetRange("Action Type", RegisteredInvtMovementLine."Action Type"::Take);
        RegisteredInvtMovementLine.FindFirst();
        RegisteredInvtMovementLine.TestField("Bin Code", ItemJournalLine."Bin Code");
        RegisteredInvtMovementLine.TestField(Quantity, ItemJournalLine.Quantity);

        RegisteredInvtMovementLine.SetRange("Action Type", RegisteredInvtMovementLine."Action Type"::Place);
        RegisteredInvtMovementLine.FindFirst();
        RegisteredInvtMovementLine.TestField("Bin Code", Bin.Code);
        RegisteredInvtMovementLine.TestField(Quantity, ItemJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandlerSimple')]
    procedure InventoryMovementFromMovementWorksheetPopulatesSpecialEquipmentFromItem()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Inventory Movement] [Movement Worksheet] [Special Equipment]
        // [SCENARIO] Inventory Movement can be created from the Movement Worksheet and can be registered with 'Special Equipment Code' on basic warehouse
        InventoryMovementFromMovementWorksheetPopulatesSpecialEquipment(Location."Special Equipment"::"According to SKU/Item");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandlerSimple')]
    procedure InventoryMovementFromMovementWorksheetPopulatesSpecialEquipmentFromBin()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Inventory Movement] [Movement Worksheet] [Special Equipment]
        // [SCENARIO] Inventory Movement can be created from the Movement Worksheet and can be registered with 'Special Equipment Code' on basic warehouse
        InventoryMovementFromMovementWorksheetPopulatesSpecialEquipment(Location."Special Equipment"::"According to Bin");
    end;

    procedure InventoryMovementFromMovementWorksheetPopulatesSpecialEquipment(SpecialEquipmentPolicy: Option)
    var
        FromBin: Record Bin;
        ToBin: Record Bin;
        Item: Record Item;
        SpecialEquipment: Record "Special Equipment";
        ItemJournalLine: Record "Item Journal Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
        CreateInventoryPickMovement: Codeunit "Create Inventory Pick/Movement";
    begin
        // [GIVEN] Location with 3 bins are created and 'Special Equipment' is set to SKU/Item
        LibraryWarehouse.FindBin(FromBin, CreateLocationWithWhseEmployeeAndNumberOfBins(Location, 3), '', 1);
        Location.Validate("Special Equipment", SpecialEquipmentPolicy);
        Location.Modify(true);

        LibraryInventory.CreateItem(Item);
        SpecialEquipment.FindFirst();
        FromBin.Validate("Special Equipment Code", SpecialEquipment.Code);
        FromBin.Modify(true);
        SpecialEquipment.Next();
        Item.Validate("Special Equipment Code", SpecialEquipment.Code);
        Item.Modify(true);

        // [GIVEN] Create WorksheetName for the newly created Location
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);

        // [GIVEN] Item had stock of 10 PCS in the FromBin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", FromBin."Location Code", FromBin.Code, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Warehouse Worksheet Line to move those items from FromBin to ToBin
        LibraryWarehouse.FindBin(ToBin, FromBin."Location Code", '', 2);
        ToBin.Validate("Special Equipment Code", FromBin."Special Equipment Code");
        ToBin.Modify(true);
        LibraryWarehouse.CreateWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetTemplate.Name, WhseWorksheetName.Name, Location.Code, WhseWorksheetLine."Whse. Document Type"::"Whse. Mov.-Worksheet");
        WhseWorksheetLine.Validate("Item No.", ItemJournalLine."Item No.");
        WhseWorksheetLine.Validate("From Bin Code", FromBin.Code);
        WhseWorksheetLine.Validate("To Bin Code", ToBin.Code);
        WhseWorksheetLine.Validate(Quantity, ItemJournalLine.Quantity);
        WhseWorksheetLine.Modify(true);

        // [WHEN] Create Inventory Movement from Warehouse Worksheet Line
        CreateInventoryPickMovement.CreateInvtMvntWithoutSource(WhseWorksheetLine);

        // [THEN] Inventory Movement document is created
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.", ItemJournalLine."Item No.");
        WarehouseActivityLine.SetRange("Bin Code", ItemJournalLine."Bin Code");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Register Inventory Movement
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Registered Invt. Movement Take Line has 10 PCS of the Item with Bin and Special Equipment Code set 
        RegisteredInvtMovementLine.SetRange("Item No.", ItemJournalLine."Item No.");
        RegisteredInvtMovementLine.SetRange("Action Type", RegisteredInvtMovementLine."Action Type"::Take);
        RegisteredInvtMovementLine.FindFirst();
        RegisteredInvtMovementLine.TestField("Bin Code", FromBin.Code);
        RegisteredInvtMovementLine.TestField(Quantity, ItemJournalLine.Quantity);
        case SpecialEquipmentPolicy of
            Location."Special Equipment"::"According to Bin":
                RegisteredInvtMovementLine.TestField("Special Equipment Code", FromBin."Special Equipment Code");
            Location."Special Equipment"::"According to SKU/Item":
                RegisteredInvtMovementLine.TestField("Special Equipment Code", Item."Special Equipment Code");
        end;

        RegisteredInvtMovementLine.SetRange("Action Type", RegisteredInvtMovementLine."Action Type"::Place);
        RegisteredInvtMovementLine.FindFirst();
        RegisteredInvtMovementLine.TestField("Bin Code", ToBin.Code);
        RegisteredInvtMovementLine.TestField(Quantity, ItemJournalLine.Quantity);
        case SpecialEquipmentPolicy of
            Location."Special Equipment"::"According to Bin":
                RegisteredInvtMovementLine.TestField("Special Equipment Code", ToBin."Special Equipment Code");
            Location."Special Equipment"::"According to SKU/Item":
                RegisteredInvtMovementLine.TestField("Special Equipment Code", Item."Special Equipment Code");
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandlerSimple')]
    procedure InventoryMovementFromMovementWorksheet()
    var
        FromBin: Record Bin;
        ToBin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
        CreateInventoryPickMovement: Codeunit "Create Inventory Pick/Movement";
    begin
        // [FEATURE] [Inventory Movement] [Movement Worksheet]
        // [SCENARIO] Inventory Movement can be created from the Movement Worksheet and canbe registered

        // [GIVEN] Location with 3 bins are created
        LibraryWarehouse.FindBin(FromBin, CreateLocationWithWhseEmployeeAndNumberOfBins(Location, 3), '', 1);

        // [GIVEN] Create WorksheetName for the newly created Location
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);

        // [GIVEN] Item had stock of 10 PCS in the FromBin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, LibraryInventory.CreateItemNo(), FromBin."Location Code", FromBin.Code, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Warehouse Worksheet Line to move those items from FromBin to ToBin
        LibraryWarehouse.FindBin(ToBin, FromBin."Location Code", '', 2);
        LibraryWarehouse.CreateWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetTemplate.Name, WhseWorksheetName.Name, Location.Code, WhseWorksheetLine."Whse. Document Type"::"Whse. Mov.-Worksheet");
        WhseWorksheetLine.Validate("Item No.", ItemJournalLine."Item No.");
        WhseWorksheetLine.Validate("From Bin Code", FromBin.Code);
        WhseWorksheetLine.Validate("To Bin Code", ToBin.Code);
        WhseWorksheetLine.Validate(Quantity, ItemJournalLine.Quantity);
        WhseWorksheetLine.Modify(true);

        // [WHEN] Create Inventory Movement from Warehouse Worksheet Line
        CreateInventoryPickMovement.CreateInvtMvntWithoutSource(WhseWorksheetLine);
        // [THEN] Inventory Movement document is created
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.", ItemJournalLine."Item No.");
        WarehouseActivityLine.SetRange("Bin Code", ItemJournalLine."Bin Code");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Register Inventory Movement
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        // [THEN] Registered Invt. Movement Take Line has 10 PCS of the Item and the Bin
        RegisteredInvtMovementLine.SetRange("Item No.", ItemJournalLine."Item No.");
        RegisteredInvtMovementLine.SetRange("Action Type", RegisteredInvtMovementLine."Action Type"::Take);
        RegisteredInvtMovementLine.FindFirst();
        RegisteredInvtMovementLine.TestField("Bin Code", FromBin.Code);
        RegisteredInvtMovementLine.TestField(Quantity, ItemJournalLine.Quantity);

        RegisteredInvtMovementLine.SetRange("Action Type", RegisteredInvtMovementLine."Action Type"::Place);
        RegisteredInvtMovementLine.FindFirst();
        RegisteredInvtMovementLine.TestField("Bin Code", ToBin.Code);
        RegisteredInvtMovementLine.TestField(Quantity, ItemJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandlerSimple,SetSNOnItemTrackingLinesModalPageHandler,QuantityToCreatePageHandler,SetSNOnWhseItemTrackingLinesModalPageHandler')]
    procedure InventoryMovementFromMovementWorksheetWithItemTracking()
    var
        Item: Record Item;
        FromBin: Record Bin;
        ToBin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
        CreateInventoryPickMovement: Codeunit "Create Inventory Pick/Movement";
    begin
        // [FEATURE] [Inventory Movement] [Movement Worksheet] [Item Tracking]
        // [SCENARIO] Inventory Movement can be created from the Movement Worksheet and canbe registered

        // [GIVEN] Location with 3 bins are created
        LibraryWarehouse.FindBin(FromBin, CreateLocationWithWhseEmployeeAndNumberOfBins(Location, 3), '', 1);

        // [GIVEN] Create WorksheetName for the newly created Location
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);

        // [GIVEN] Serially tracked Item has stock of 10 PCS in the FromBin
        LibraryInventory.CreateItem(Item);
        SetItemTracking(Item);

        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", FromBin."Location Code", FromBin.Code, LibraryRandom.RandInt(10));
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Warehouse Worksheet Line to move those items from FromBin to ToBin
        LibraryWarehouse.FindBin(ToBin, FromBin."Location Code", '', 2);
        LibraryWarehouse.CreateWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetTemplate.Name, WhseWorksheetName.Name, Location.Code, WhseWorksheetLine."Whse. Document Type"::"Whse. Mov.-Worksheet");
        WhseWorksheetLine.Validate("Item No.", ItemJournalLine."Item No.");
        WhseWorksheetLine.Validate("From Bin Code", FromBin.Code);
        WhseWorksheetLine.Validate("To Bin Code", ToBin.Code);
        WhseWorksheetLine.Validate(Quantity, ItemJournalLine.Quantity);
        WhseWorksheetLine.Modify(true);

        // [GIVEN] Assign item tracking information
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Qty. (Base)");
        WhseWorksheetLine.OpenItemTrackingLines();

        // [WHEN] Create Inventory Movement from Warehouse Worksheet Line
        CreateInventoryPickMovement.CreateInvtMvntWithoutSource(WhseWorksheetLine);

        // [THEN] Inventory Movement document is created and item tracking is transferred
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.SetRange("Item No.", ItemJournalLine."Item No.");
        WarehouseActivityLine.SetFilter("Bin Code", '<>%1', '');
        WarehouseActivityLine.SetFilter("Serial No.", '<>%1', '');
        Assert.RecordCount(WarehouseActivityLine, ItemJournalLine.Quantity * 2);

        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Register Inventory Movement
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Registered Invt. Movement Take Line has 10 PCS of the Item, Bin and item tracking
        RegisteredInvtMovementLine.SetRange("Item No.", ItemJournalLine."Item No.");
        RegisteredInvtMovementLine.SetRange("Action Type", RegisteredInvtMovementLine."Action Type"::Take);
        RegisteredInvtMovementLine.SetFilter("Serial No.", '<>%1', '');
        RegisteredInvtMovementLine.SetRange(Quantity, 1);
        Assert.RecordCount(RegisteredInvtMovementLine, ItemJournalLine.Quantity);

        RegisteredInvtMovementLine.SetRange("Action Type", RegisteredInvtMovementLine."Action Type"::Place);
        Assert.RecordCount(RegisteredInvtMovementLine, ItemJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandlerSimple')]
    procedure InventoryMovementCarriesZoneInfoAllTheWayToWarehouseEntries()
    var
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Zone: array[2] of Record Zone;
        Bin: array[2] of Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
        WarehouseEntry: Record "Warehouse Entry";
        CreateInventoryPickMovement: Codeunit "Create Inventory Pick/Movement";
    begin
        // [FEATURE] [Inventory Movement] [Register Movement]
        // [SCENARIO] Inventory Movement carries the zone and bin information from the document to the warehouse entries

        // [GIVEN] Location with 2 bins are created
        CreateLocationWithWhseEmployeeAndNumberOfBins(Location, 2);

        // [GIVEN] Both the Bins belong to different Zones
        LibraryWarehouse.CreateZone(Zone[1], '', Location.Code, '', '', '', 0, false);
        LibraryWarehouse.CreateZone(Zone[2], '', Location.Code, '', '', '', 0, false);
        LibraryWarehouse.FindBin(Bin[1], Location.Code, '', 1);
        Bin[1].Validate("Zone Code", Zone[1].Code);
        Bin[1].Modify(true);
        LibraryWarehouse.FindBin(Bin[2], Location.Code, '', 2);
        Bin[2].Validate("Zone Code", Zone[2].Code);
        Bin[2].Modify(true);

        // [GIVEN] Create WorksheetName for the newly created Location
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);

        // [GIVEN] Item has stock of 10 PCS in Bin[1]
        LibraryInventory.CreateItem(Item);

        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Bin[1]."Location Code", Bin[1].Code, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Warehouse Worksheet Line to move those items from FromBin to ToBin
        LibraryWarehouse.CreateWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetTemplate.Name, WhseWorksheetName.Name, Location.Code, WhseWorksheetLine."Whse. Document Type"::"Whse. Mov.-Worksheet");
        WhseWorksheetLine.Validate("Item No.", ItemJournalLine."Item No.");
        WhseWorksheetLine.Validate("From Bin Code", Bin[1].Code);
        WhseWorksheetLine.Validate("To Bin Code", Bin[2].Code);
        WhseWorksheetLine.Validate(Quantity, ItemJournalLine.Quantity);
        WhseWorksheetLine.Modify(true);

        // [WHEN] Create Inventory Movement from Warehouse Worksheet Line
        CreateInventoryPickMovement.CreateInvtMvntWithoutSource(WhseWorksheetLine);

        // [THEN] Inventory Movement document is created and zone and bin information is set on the movement lines
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.SetRange("Item No.", ItemJournalLine."Item No.");
        WarehouseActivityLine.SetFilter("Bin Code", '<>%1', '');
        WarehouseActivityLine.SetFilter("Zone Code", '<>%1', '');
        Assert.RecordCount(WarehouseActivityLine, 2);

        // [THEN] Take Inventory Movement line has zone and bin information for the "from bin"
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Zone Code", Zone[1].Code);
        WarehouseActivityLine.TestField("Bin Code", Bin[1].Code);

        // [THEN] Place Inventory Movement line has zone and bin information for the "to bin"
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Zone Code", Zone[2].Code);
        WarehouseActivityLine.TestField("Bin Code", Bin[2].Code);

        // [GIVEN] Autofill the quantity on the movement document 
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Register Inventory Movement
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Registered Invt. Movement Take Line has zone and bin set correctly
        RegisteredInvtMovementLine.SetRange("Item No.", ItemJournalLine."Item No.");
        RegisteredInvtMovementLine.SetRange("Action Type", RegisteredInvtMovementLine."Action Type"::Take);
        Assert.RecordCount(RegisteredInvtMovementLine, 1);

        // [THEN] Registered Invt. Movement Place Line has zone and bin set correctly
        RegisteredInvtMovementLine.SetRange("Action Type", RegisteredInvtMovementLine."Action Type"::Place);
        Assert.RecordCount(RegisteredInvtMovementLine, 1);

        // [THEN] Warehouse Entries have zone and bin set correctly
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        Assert.RecordCount(WarehouseEntry, 2);
        WarehouseEntry.SetFilter(Quantity, '< %1', 0);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Zone Code", Zone[1].Code);
        WarehouseEntry.TestField("Bin Code", Bin[1].Code);

        WarehouseEntry.SetFilter(Quantity, '> %1', 0);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Zone Code", Zone[2].Code);
        WarehouseEntry.TestField("Bin Code", Bin[2].Code);
    end;

    local procedure CreateLocationWithWhseEmployeeAndNumberOfBins(NumberOfBins: Integer): Code[10]
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
    begin
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NumberOfBins, false);
        exit(Location.Code);
    end;

    local procedure CreateLocationWithWhseEmployeeAndNumberOfBins(var Location: Record Location; NumberOfBins: Integer): Code[10]
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NumberOfBins, false);
        exit(Location.Code);
    end;

    local procedure CreateLocationWithBins(var Location: Record Location; var Bin: Record Bin)
    var
        i: Integer;
        j: Integer;
        BinName: Code[20];
    begin
        // creating location
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, false, false);

        // creating 9 bins
        for i := 1 to 3 do
            for j := 1 to 3 do begin
                BinName := 'B0' + Format(i) + '-00' + Format(j);
                LibraryWarehouse.CreateBin(Bin, Location.Code, BinName, '', '');
            end;
    end;

    local procedure CreateFinalItem(var ItemRec: Record Item)
    begin
        LibraryInventory.CreateItem(ItemRec);
        ItemRec.Validate("Replenishment System", ItemRec."Replenishment System"::"Prod. Order");
        ItemRec.Modify(true);
    end;

    local procedure CreateCompItem(var ItemRec: Record Item; FlushingType: Enum "Flushing Method")
    begin
        LibraryInventory.CreateItem(ItemRec);
        ItemRec.Validate("Flushing Method", FlushingType);
        ItemRec.Validate("Replenishment System", ItemRec."Replenishment System"::Purchase);
        ItemRec.Modify(true);
    end;

    local procedure SetItemTracking(var ItemRec: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemRec.Get(ItemRec."No.");
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        ItemRec.Validate("Item Tracking Code", ItemTrackingCode.Code);
        ItemRec."Serial Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        ItemRec.Modify(true);
    end;

    local procedure CreateBOM(var ProdBOMHeaderRec: Record "Production BOM Header"; UnitofMeasure: Code[10]; ItemComp1Rec: Record Item; ItemComp2Rec: Record Item; RoutingLinkCode1: Code[10]; RoutingLinkCode2: Code[10])
    var
        ProdBOMLineRec: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeaderRec, UnitofMeasure);

        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeaderRec, ProdBOMLineRec, '', ProdBOMLineRec.Type::Item, ItemComp1Rec."No.", 1);
        ProdBOMLineRec.Validate("Routing Link Code", RoutingLinkCode1);
        ProdBOMLineRec.Modify(true);

        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeaderRec, ProdBOMLineRec, '', ProdBOMLineRec.Type::Item, ItemComp2Rec."No.", 1);
        ProdBOMLineRec.Validate("Routing Link Code", RoutingLinkCode2);
        ProdBOMLineRec.Modify(true);

        ProdBOMHeaderRec.Validate(Status, ProdBOMHeaderRec.Status::Certified);
        ProdBOMHeaderRec.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenterRec: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenterRec);
        WorkCenterRec.Validate(Capacity, 1);
        WorkCenterRec.Validate(Efficiency, 100);
        WorkCenterRec.Modify(true);

        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenterRec, CalcDate('<CY-3M>', WorkDate()), CalcDate('<CM+1Y>', WorkDate()));
    end;

    local procedure CreateRouting(var RoutingHeaderRec: Record "Routing Header"; WorkCenterRec1: Record "Work Center"; WorkCenterRec2: Record "Work Center")
    var
        RoutingLineRec: Record "Routing Line";
        RoutingLinkRec: Record "Routing Link";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeaderRec, RoutingHeaderRec.Type::Serial);

        RoutingLinkRec.Init();
        RoutingLinkRec.Validate(Code, CopyStr(WorkCenterRec1."No.", 1, 10));
        RoutingLinkRec.Insert(true);

        // the first operation
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeaderRec, RoutingLineRec, '', '10',
          RoutingLineRec.Type::"Work Center", WorkCenterRec1."No.");

        RoutingLineRec.Validate("Setup Time", 1);
        RoutingLineRec.Validate("Run Time", 1);
        RoutingLineRec.Validate("Routing Link Code", RoutingLinkRec.Code);
        RoutingLineRec.Modify(true);

        RoutingLinkRec.Validate(Code, CopyStr(WorkCenterRec2."No.", 1, 10));
        RoutingLinkRec.Insert(true);

        // the second operation
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeaderRec, RoutingLineRec, '', '20',
          RoutingLineRec.Type::"Work Center", WorkCenterRec2."No.");

        RoutingLineRec.Validate("Setup Time", 1);
        RoutingLineRec.Validate("Run Time", 1);
        RoutingLineRec.Validate("Routing Link Code", RoutingLinkRec.Code);
        RoutingLineRec.Modify(true);

        RoutingHeaderRec.Validate(Status, RoutingHeaderRec.Status::Certified);
        RoutingHeaderRec.Modify(true);
    end;

    [HandlerFunctions('PurchaseHandler')]
    local procedure PurchaseComponentToWMS(ItemRecComp1: Record Item; ItemRecComp2: Record Item; LocationRec: Record Location)
    var
        BinRec: Record Bin;
        PurchaseHeaderRec: Record "Purchase Header";
        PurchaseLineRec: Record "Purchase Line";
        WarehouseActivityHeaderRec: Record "Warehouse Activity Header";
    begin
        BinRec.SetRange("Location Code", LocationRec.Code);
        BinRec.FindFirst();

        // creating purchase order with 2 lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderRec, PurchaseHeaderRec."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLineRec, PurchaseHeaderRec, PurchaseLineRec.Type::Item, ItemRecComp1."No.", 11);
        PurchaseLineRec.Validate("Location Code", LocationRec.Code);
        PurchaseLineRec.Validate("Bin Code", BinRec.Code);
        PurchaseLineRec.Validate("Direct Unit Cost", 11);
        PurchaseLineRec.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLineRec, PurchaseHeaderRec, PurchaseLineRec.Type::Item, ItemRecComp2."No.", 13);
        PurchaseLineRec.Validate("Location Code", LocationRec.Code);
        PurchaseLineRec.Validate("Bin Code", BinRec.Code);
        PurchaseLineRec.Validate("Direct Unit Cost", 13);
        PurchaseLineRec.Modify(true);

        // creating inventory put-away
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeaderRec);
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeaderRec);

        // posting inventory put-away
        WarehouseActivityHeaderRec.SetRange("Location Code", LocationRec.Code);
        WarehouseActivityHeaderRec.FindFirst();
        WarehouseActivityHeaderRec.Validate("External Document No.2", PurchaseHeaderRec."No.");
        WarehouseActivityHeaderRec.Modify(true);

        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeaderRec);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeaderRec, true);
    end;

    [HandlerFunctions('PurchaseHandler')]
    local procedure PurchaseComponentWithITToWMS(ItemRecComp1: Record Item; ItemRecComp2: Record Item; LocationRec: Record Location)
    var
        BinRec: Record Bin;
        PurchaseHeaderRec: Record "Purchase Header";
        PurchaseLineRec: Record "Purchase Line";
        VendorRec: Record Vendor;
        WarehouseActivityHeaderRec: Record "Warehouse Activity Header";
    begin
        LibraryPurchase.CreateVendor(VendorRec);
        BinRec.SetRange("Location Code", LocationRec.Code);
        BinRec.Find('-');

        // creating purchase order with 4 lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderRec, PurchaseHeaderRec."Document Type"::Order, VendorRec."No.");

        LibraryPurchase.CreatePurchaseLine(PurchaseLineRec, PurchaseHeaderRec, PurchaseLineRec.Type::Item, ItemRecComp1."No.", 2);
        PurchaseLineRec.Validate("Location Code", LocationRec.Code);
        PurchaseLineRec.Validate("Bin Code", BinRec.Code);
        PurchaseLineRec.Validate("Direct Unit Cost", 11);
        PurchaseLineRec.Modify(true);
        AddSerialNumberToPurchase(PurchaseLineRec, 10);

        BinRec.Next();
        LibraryPurchase.CreatePurchaseLine(PurchaseLineRec, PurchaseHeaderRec, PurchaseLineRec.Type::Item, ItemRecComp1."No.", 3);
        PurchaseLineRec.Validate("Location Code", LocationRec.Code);
        PurchaseLineRec.Validate("Bin Code", BinRec.Code);
        PurchaseLineRec.Validate("Direct Unit Cost", 11);
        PurchaseLineRec.Modify(true);
        AddSerialNumberToPurchase(PurchaseLineRec, 20);

        LibraryPurchase.CreatePurchaseLine(PurchaseLineRec, PurchaseHeaderRec, PurchaseLineRec.Type::Item, ItemRecComp2."No.", 3);
        PurchaseLineRec.Validate("Location Code", LocationRec.Code);
        PurchaseLineRec.Validate("Bin Code", BinRec.Code);
        PurchaseLineRec.Validate("Direct Unit Cost", 13);
        PurchaseLineRec.Modify(true);

        BinRec.Next();
        LibraryPurchase.CreatePurchaseLine(PurchaseLineRec, PurchaseHeaderRec, PurchaseLineRec.Type::Item, ItemRecComp2."No.", 5);
        PurchaseLineRec.Validate("Location Code", LocationRec.Code);
        PurchaseLineRec.Validate("Bin Code", BinRec.Code);
        PurchaseLineRec.Validate("Direct Unit Cost", 13);
        PurchaseLineRec.Modify(true);

        // creating inventory put-away
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeaderRec);
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeaderRec);

        // posting inventory put-away
        WarehouseActivityHeaderRec.SetRange("Location Code", LocationRec.Code);
        WarehouseActivityHeaderRec.FindFirst();
        WarehouseActivityHeaderRec.Validate("External Document No.2", PurchaseHeaderRec."No.");
        WarehouseActivityHeaderRec.Modify(true);

        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeaderRec);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeaderRec, true);
    end;

    local procedure AddSerialNumberToPurchase(PurchaseLine: Record "Purchase Line"; SerialNumberKoef: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
        i: Integer;
    begin
        for i := 1 to PurchaseLine.Quantity do
            LibraryItemTracking.CreatePurchOrderItemTracking(
              ReservationEntry, PurchaseLine,
              'S' + Format(SerialNumberKoef + i), '', 1);
    end;

    local procedure AddSerialNumberToComponent(ProductionOrder: Record "Production Order")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationEntry: Record "Reservation Entry";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindFirst();

        LibraryManufacturing.CreateProdOrderCompItemTracking(ReservationEntry, ProdOrderComponent, 'S11', '', 1);
        LibraryManufacturing.CreateProdOrderCompItemTracking(ReservationEntry, ProdOrderComponent, 'S12', '', 1);
        LibraryManufacturing.CreateProdOrderCompItemTracking(ReservationEntry, ProdOrderComponent, 'S23', '', 1);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PurchaseHandler(Message: Text[1024])
    begin
    end;

    local procedure PrepareReleasedProdOrder(var ProductionOrder: Record "Production Order"; ItemRec: Record Item; LocationCode: Code[10]; BinCode: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        Bin: Record Bin;
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned",
          ProductionOrder."Source Type"::Item, ItemRec."No.", 3);

        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", CalcDate('<CM+1M>', WorkDate()));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);

        // change bins in component list
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetFilter(Code, '<>%1', BinCode);
        Bin.FindLast();

        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", 10000);

        if ProdOrderComponent.Find('-') then
            repeat
                ProdOrderComponent."Bin Code" := Bin.Code;
                ProdOrderComponent.Modify(true);
            until ProdOrderComponent.Next() = 0;

        // release Production Order
        ReleaseProductionOrder(ProductionOrder, LocationCode);
    end;

    local procedure ReleaseProductionOrder(var ProductionOrder: Record "Production Order"; LocationCode: Code[10])
    begin
        ProductionOrder.Find('=');
        LibraryManufacturing.ChangeProdOrderStatus(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Due Date", true);

        ProductionOrder.SetRange("Source No.", ProductionOrder."Source No.");
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("Location Code", LocationCode);
        ProductionOrder.FindLast();
    end;

    local procedure PostOutput(ProductionOrder: Record "Production Order")
    var
        ItemJournalLine: Record "Item Journal Line";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // post output of the first operation
        LibraryManufacturing.OutputJournalExplodeRouting(ProductionOrder);

        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Output);

        ItemJournalLine.FindLast();
        ItemJournalLine.Delete(true);
        LibraryManufacturing.PostOutputJournal();

        // post output of the second operation via Inventory Put-away
        WarehouseRequest.Reset();
        WarehouseRequest.SetCurrentKey("Source Document", "Source No.");
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Prod. Output");
        WarehouseRequest.SetRange("Source No.", ProductionOrder."No.");

        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);
        LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, true, false, false);

        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Invt. Put-away");
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Prod. Output");
        WarehouseActivityHeader.SetRange("Source No.", ProductionOrder."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;

    local procedure CreateAndRegisterInvtMovement(ProductionOrder: Record "Production Order")
    var
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseRequest.Reset();
        WarehouseRequest.SetCurrentKey("Source Document", "Source No.");
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Prod. Consumption");
        WarehouseRequest.SetRange("Source No.", ProductionOrder."No.");

        LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, true, false, true);

        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Invt. Movement");
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Prod. Consumption");
        WarehouseActivityHeader.SetRange("Source No.", ProductionOrder."No.");

        // according Flushing method the Invt. Movement hasn't had to be created
        if WarehouseActivityHeader.FindFirst() then begin
            LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
            LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        end;
    end;

    local procedure PostConsumption(ProductionOrder: Record "Production Order")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindFirst();
        LibraryManufacturing.CalculateConsumptionForJournal(ProductionOrder, ProdOrderComponent, WorkDate() + 30, true);
        LibraryManufacturing.PostConsumptionJournal();
    end;

    local procedure VerifyConsumption(ProductionOrder: Record "Production Order")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ConsumedQty: Decimal;
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        if ProdOrderComponent.Find('-') then
            repeat
                ItemLedgerEntry.SetCurrentKey("Item No.", "Entry Type", "Variant Code", "Drop Shipment");
                ItemLedgerEntry.SetRange("Item No.", ProdOrderComponent."Item No.");
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
                ConsumedQty := 0;
                if ItemLedgerEntry.Find('-') then
                    repeat
                        ConsumedQty += ItemLedgerEntry.Quantity;
                    until ItemLedgerEntry.Next() = 0;
                Assert.AreEqual(
                  -ProdOrderComponent."Expected Quantity",
                  ConsumedQty,
                  'Wrong consumed quantity for item ' + ItemLedgerEntry."Item No.");
            until ProdOrderComponent.Next() = 0;
    end;

    local procedure SetBinsWithContent(ProductionOrder: Record "Production Order"; LocationCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        BinContent: Record "Bin Content";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        if ProdOrderComponent.Find('-') then
            repeat
                BinContent.SetRange("Location Code", LocationCode);
                BinContent.SetRange("Item No.", ProdOrderComponent."Item No.");
                BinContent.FindFirst();
                ProdOrderComponent.Validate("Bin Code", BinContent."Bin Code");
                ProdOrderComponent.Modify(true);
            until ProdOrderComponent.Next() = 0;
    end;

    local procedure CreateRoutingWithWC(var WorkCenterRec1: Record "Work Center"; var WorkCenterRec2: Record "Work Center"; var RoutingHeaderRec: Record "Routing Header")
    begin
        CreateWorkCenter(WorkCenterRec1);
        CreateWorkCenter(WorkCenterRec2);

        CreateRouting(RoutingHeaderRec, WorkCenterRec1, WorkCenterRec2);
    end;

    local procedure CreateAllItemsWithBOM(var ItemFinal: Record Item; var ItemComp1: Record Item; var ItemComp2: Record Item; FlushMethod: Enum "Flushing Method"; RLC1: Code[10]; RLC2: Code[10]; RoutingCode: Code[20])
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        CreateFinalItem(ItemFinal);
        CreateCompItem(ItemComp1, FlushMethod);
        CreateCompItem(ItemComp2, FlushMethod);

        CreateBOM(
          ProdBOMHeader, ItemFinal."Base Unit of Measure",
          ItemComp1, ItemComp2, RLC1, RLC2);

        // finalize item for production
        ItemFinal.Validate("Routing No.", RoutingCode);
        ItemFinal.Validate("Production BOM No.", ProdBOMHeader."No.");
        ItemFinal.Modify(true);
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandlerSimple(Message: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetSNOnWhseItemTrackingLinesModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Index: Integer;
        QtyToHandle: Integer;
        ItemNo: Code[20];
    begin
        ItemNo := LibraryVariableStorage.DequeueText();
        QtyToHandle := LibraryVariableStorage.DequeueInteger();

        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        for Index := 1 to QtyToHandle do begin
            WhseItemTrackingLines.New();
            WhseItemTrackingLines."Serial No.".SetValue(ItemLedgerEntry."Serial No.");
            WhseItemTrackingLines.Quantity.SetValue(1);
            //WhseItemTrackingLines.Next();
            ItemLedgerEntry.Next();
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetSNOnItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign &Serial No.".Invoke();
        ItemTrackingLines.OK().Invoke();
        /*        ItemNo := WhseItemTrackingLines."Item No.".Value();
                QtyToHandle := WhseItemTrackingLines."Qty. to Handle (Base)".AsInteger();

                ItemLedgerEntry.SetRange("Item No.", ItemNo);
                ItemLedgerEntry.FindSet();
                WhseItemTrackingLines.First();
                for Index := 1 to QtyToHandle do begin
                    WhseItemTrackingLines."Serial No.".SetValue(ItemLedgerEntry."Serial No.");
                    WhseItemTrackingLines.Quantity.SetValue(1);
                    WhseItemTrackingLines.Next();
                    ItemLedgerEntry.Next();
                end;
                WhseItemTrackingLines.OK().Invoke();*/
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;
}

