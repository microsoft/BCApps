codeunit 134778 "SCM Invt. Pick Post Preview"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Inventory Pick]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibrarySales: Codeunit "Library - Sales";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJob: codeunit "Library - Job";
        IsInitialized: Boolean;
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPickRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviewInventoryPickPost_SalesOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
        WhseActivityPost: Codeunit "Whse.-Act.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Sales] [Inventory Pick] [Preview Posting]
        // [SCENARIO] Preview Inventory Pick posting shows the ledger entries that will be grnerated when the pick is posted.
        Initialize();

        // [GIVEN] Location for Inventory Pick where the 'Require Pick' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, false, false, true, false, false);

        // [GIVEN] Sales Order created with Posting Date = WORKDATE
        CreateSalesDocumentWithLineLocation(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, '');

        // [WHEN] Inventory Pick created
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        Commit();
        SalesHeader.CreateInvtPutAwayPick();
        FindAndUpdateWhseActivityPostingDate(
          WarehouseActivityHeader, WarehouseActivityLine,
          DATABASE::"Sales Line", SalesHeader."No.",
          WarehouseActivityHeader.Type::"Invt. Pick", WorkDate() + 1);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhseActivityPost.Preview(WarehouseActivityLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the pick is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPickRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviewInventoryPickPostWithBin_SalesOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        Bin: Record Bin;
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        ValueEntry: Record "Value Entry";
        WhseActivityPost: Codeunit "Whse.-Act.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Sales] [Inventory Pick] [Preview Posting]
        // [SCENARIO] Preview Inventory Pick posting with Bin set shows the ledger entries that will be grnerated when the pick is posted.
        Initialize();

        // [GIVEN] Location for Inventory Pick where 'Require Pick' and 'Bin Mandatory' are true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, true, false, true, false, false);
        LibraryWarehouse.CreateBin(
                  Bin, Location.Code,
                  CopyStr(
                    LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
                    LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Sales Order created
        CreateSalesDocumentWithLineLocation(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Bin.Code);

        // [WHEN] Inventory Pick created
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        Commit();
        SalesHeader.CreateInvtPutAwayPick();
        FindAndUpdateWhseActivityPostingDate(
          WarehouseActivityHeader, WarehouseActivityLine,
          DATABASE::"Sales Line", SalesHeader."No.",
          WarehouseActivityHeader.Type::"Invt. Pick", WorkDate() + 1);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhseActivityPost.Preview(WarehouseActivityLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the pick is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, WarehouseEntry.TableCaption(), 1);

        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPickRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviewInventoryPickPost_ProdConsumption()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        WhseActivityPost: Codeunit "Whse.-Act.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Production] [Inventory Pick] [Preview Posting]
        // [SCENARIO] Preview Inventory Pick posting shows the ledger entries that will be grnerated when the pick is posted.
        Initialize();

        // [GIVEN] Location for Inventory Pick where the 'Require Pick' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, false, false, true, false, false);

        // [GIVEN] Create Component Item with enough in stock in the chosen location
        CreateItem(CompItem, Location.Code, '', LibraryRandom.RandDec(100, 2), CompItem."Costing Method"::Average);
        // [GIVEN] Create Production Item and set the BOM
        CreateItem(ProdItem, CompItem."Unit Cost" * 2, CompItem."Costing Method"::Average);
        CreateProductionBOM(ProdItem, CompItem);

        // [GIVEN] Create 2 level production order for prod item "P" and refresh order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, ProdItem."No.", 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        //ProductionOrder.Validate("Bin Code", );

        // [WHEN] Create Inventory Pick for the Production Order is run.
        ProductionOrder.CreateInvtPutAwayPick();

        // [THEN] Inventory Pick lines are created
        FindAndUpdateWhseActivityPostingDate(
          WarehouseActivityHeader, WarehouseActivityLine,
         Database::"Prod. Order Component", ProductionOrder."No.",
          WarehouseActivityHeader.Type::"Invt. Pick", WorkDate() + 1);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhseActivityPost.Preview(WarehouseActivityLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the pick is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPickRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviewInventoryPickPostWithBin_ProdConsumption()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        ValueEntry: Record "Value Entry";
        Location: Record Location;
        Bin: Record Bin;
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        WhseActivityPost: Codeunit "Whse.-Act.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Production] [Inventory Pick] [Preview Posting]
        // [SCENARIO] Preview Inventory Pick posting shows the ledger entries that will be grnerated when the pick is posted.
        Initialize();

        // [GIVEN] Location for Inventory Pick where the 'Require Pick' and 'Bin Mandatory' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, true, false, true, false, false);
        LibraryWarehouse.CreateBin(
                          Bin, Location.Code,
                          CopyStr(
                            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
                            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Create Component Item with enough in stock in the chosen location and bin
        CreateItem(CompItem, Location.Code, Bin.Code, LibraryRandom.RandDec(100, 2), CompItem."Costing Method"::Average);
        // [GIVEN] Create Production Item and set the BOM
        CreateItem(ProdItem, CompItem."Unit Cost" * 2, CompItem."Costing Method"::Average);
        CreateProductionBOM(ProdItem, CompItem);

        // [GIVEN] Create 2 level production order for prod item "P" and refresh order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, ProdItem."No.", 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Inventory Pick for the Production Order is run.
        ProductionOrder.CreateInvtPutAwayPick();

        // [THEN] Inventory Pick lines are created
        FindAndUpdateWhseActivityPostingDate(
          WarehouseActivityHeader, WarehouseActivityLine,
         Database::"Prod. Order Component", ProductionOrder."No.",
          WarehouseActivityHeader.Type::"Invt. Pick", WorkDate() + 1);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhseActivityPost.Preview(WarehouseActivityLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the pick is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, WarehouseEntry.TableCaption(), 1);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPickRequestPageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickPostWithLotAndBin_ProdConsumption()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        Bin: Record Bin;
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        WhseActivityPost: Codeunit "Whse.-Activity-Post";
        Qty1: Decimal;
        Qty2: Decimal;
        Lot1: Code[20];
        Lot2: Code[20];
        CannotMatchItemTrackingErr: Label 'Cannot match item tracking.\Document No.: %1, Line No.: %2, Item: %3 %4', Comment = '%1 - source document no., %2 - source document line no., %3 - item no., %4 - item description';
    begin
        // [FEATURE] [Production] [Inventory Pick] [Item Tracking]
        // [SCENARIO] Update Item Tracking on Inventory Pick of values set on Production Order Component during pick posting causes error
        Initialize();

        // [GIVEN] Location for Inventory Pick where the 'Require Pick' and 'Bin Mandatory' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, true, false, true, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, CopyStr(
                            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
                            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Create Component Item with enough in stock in the chosen location and bin
        CreateItemWithItemTrackingCode(CompItem);
        Qty1 := LibraryRandom.RandIntInRange(10, 100);
        Lot1 := LibraryUtility.GenerateGUID();
        CreateAndPostInvtAdjustmentWithItemTracking(CompItem."No.", Location.Code, Bin.Code, Qty1, Lot1);

        Qty2 := LibraryRandom.RandIntInRange(10, 100);
        Lot2 := LibraryUtility.GenerateGUID();
        CreateAndPostInvtAdjustmentWithItemTracking(CompItem."No.", Location.Code, Bin.Code, Qty2, Lot2);

        // [GIVEN] Create Production Item and set the BOM
        CreateItem(ProdItem, CompItem."Unit Cost" * 2, CompItem."Costing Method"::Average);
        CreateProductionBOM(ProdItem, CompItem);

        // [GIVEN] Create production order for prod item "P" and refresh order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, ProdItem."No.", 4);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Get Prod Order Component and set the Item Tracking
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.FindFirst();

        LibraryVariableStorage.Enqueue(Lot2);
        LibraryVariableStorage.Enqueue(ProdOrderComponent."Remaining Quantity");
        ProdOrderComponent.OpenItemTrackingLines();

        // [GIVEN] Create Inventory Pick for the Production Order is run.
        ProductionOrder.CreateInvtPutAwayPick();

        // [GIVEN] Inventory Pick lines are created
        FindWarehouseActivityLine(WarehouseActivityLine, Database::"Prod. Order Component", ProductionOrder."No.", WarehouseActivityHeader.Type::"Invt. Pick");
        WarehouseActivityLine.TestField(Quantity, ProdOrderComponent."Remaining Quantity");
        WarehouseActivityLine.TestField("Lot No.", Lot2);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        // [WHEN] Inventory Pick Line is updated with different Lot No 
        WarehouseActivityLine.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.", WarehouseActivityLine."Line No.");
        WarehouseActivityLine.Validate("Lot No.", Lot1);
        WarehouseActivityLine.Modify();

        // [THEN] During the posting of the Inventory Pick, the error is thrown
        WhseActivityPost.SetInvoiceSourceDoc(false);
        WhseActivityPost.PrintDocument(false);
        WhseActivityPost.SetSuppressCommit(false);
        WhseActivityPost.ShowHideDialog(false);
        WhseActivityPost.SetIsPreview(false);
        asserterror WhseActivityPost.Run(WarehouseActivityLine);
        Assert.ExpectedError(StrSubstNo(CannotMatchItemTrackingErr, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Line No.", ProdOrderComponent."Item No.", ProdOrderComponent.Description));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PreviewInventoryPickPostWithBin_JobUsage()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        ValueEntry: Record "Value Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        Bin: Record Bin;
        WhseActivityPost: Codeunit "Whse.-Act.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
        QtyInventory: Integer;
        QtyToUse: Integer;
        DocNo: Text;
    begin
        // [FEATURE] [Job Usage] [Inventory Pick] [Preview Posting]
        // [SCENARIO] Preview Inventory Pick posting shows the ledger entries that will be generated when the pick is posted.
        Initialize();

        // [GIVEN] Location for Inventory Pick where the 'Require Pick' and 'Bin Mandatory' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, true, false, true, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code,
                          CopyStr(
                            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
                            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", Location.Code, Bin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which has planning line that require the item from a location where 'Require pick' = Yes and 'Bin mandatory' = Yes
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", Location.Code, Bin.Code, QtyToUse);

        // [GIVEN] 'Document No.' is not empty
        // [GIVEN] 'Usage Link' is set
        DocNo := LibraryUtility.GenerateRandomCode(JobPlanningLine.FieldNo("Document No."), Database::"Job Planning Line");
        JobPlanningLine.Validate("Document No.", DocNo);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        // [WHEN] Create Inventory Pick for the Job
        Job.Get(JobPlanningLine."Job No.");
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Job Usage", Job."No.", false, true, false);

        // [THEN] Inventory Pick lines are created
        FindAndUpdateWhseActivityPostingDate(
          WarehouseActivityHeader, WarehouseActivityLine, Database::Job, Job."No.",
          WarehouseActivityHeader.Type::"Invt. Pick", WorkDate() + 1);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhseActivityPost.Preview(WarehouseActivityLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the pick is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, JobLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, WarehouseEntry.TableCaption(), 1);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPickRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ShelfNoOnWhsePickLinesPickedFromSKU()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
    begin
        // [SCENARIO 580053] Issue while creating Inventory Pick - Shelf No. value is taken from Stockkeeping Unit, as it takes priority over Item
        Initialize();

        // [GIVEN] Location for Inventory Pick where the 'Require Pick' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, false, false, true, false, false);

        // [GIVEN] Create item "A" and set Shelf No. = S1
        LibraryInventory.CreateItem(Item);
        Item.Validate("Shelf No.", LibraryUtility.GenerateGUID());
        Item.Modify(true);

        // [GIVEN] Create a stockkeeping unit, set Shelf No. = "S2" on the new SKU.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location.Code, Item."No.", '');
        SKU.Validate("Shelf No.", LibraryUtility.GenerateGUID());
        SKU.Modify(true);

        // [GIVEN] Post item "A" to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for item "A"
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Item."No.");
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [WHEN] Inventory Pick created
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        Commit();
        SalesHeader.CreateInvtPutAwayPick();

        // [THEN] "Shelf No." = "S2" on the pick line for Item "A".
        FindWarehouseActivityLine(WarehouseActivityLine, DATABASE::"Sales Line", SalesHeader."No.", WarehouseActivityHeader.Type::"Invt. Pick");
        WarehouseActivityLine.TestField("Shelf No.", SKU."Shelf No.");
    end;

    local procedure Initialize()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Invt. Pick Post Preview");
        LibrarySetupStorage.Restore();
        WarehouseEmployee.DeleteAll();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Invt. Pick Post Preview");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Invt. Pick Post Preview");
    end;

    local procedure CreateLocationWMSWithWhseEmployee(var Location: Record Location; BinMandatory: Boolean; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateItem(var Item: Record Item; LocationCode: Code[10]; BinCode: Code[10]; UnitCost: Decimal; CostingMethod: Enum "Costing Method")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItem(Item, UnitCost, CostingMethod);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", LocationCode, BinCode, LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateItem(var Item: Record Item; UnitCost: Decimal; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", UnitCost);
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Item Tracking Code", CreateItemTrackingCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateProductionBOM(var ProdItem: Record Item; CompItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", 1);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Order");
        ProdItem.Modify(true);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryJob.CreateJob(Job, Customer."No.");
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobPlanningLineWithData(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; Type: Enum "Job Planning Line Type"; Number: Code[20]; LocationCode: Code[10]; BinCode: Code[10]; Quantity: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(LineType, Type, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Number);
        JobPlanningLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            JobPlanningLine.Validate("Bin Code", BinCode);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
        Commit();
    end;

    local procedure CreateAndPostInvtAdjustmentWithUnitCost(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostInvtAdjustmentWithItemTracking(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; LotNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateSalesDocumentWithItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesDocumentWithLineLocation(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10]; BinCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", LocationCode, BinCode, LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType, Item."No.");
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        SalesLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            SalesLine.Validate("Bin Code", BinCode);
        SalesLine.Modify(true);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindAndUpdateWhseActivityPostingDate(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; PostingDate: Date)
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceType, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(ActivityType, WarehouseActivityLine."No.");
        WarehouseActivityHeader.Validate("Posting Date", PostingDate);
        WarehouseActivityHeader.Modify(true);
    end;

    local procedure VerifyGLPostingPreviewLine(GLPostingPreview: TestPage "G/L Posting Preview"; TableName: Text; ExpectedEntryCount: Integer)
    begin
        Assert.AreEqual(TableName, GLPostingPreview."Table Name".Value, StrSubstNo('A record for Table Name %1 was not found.', TableName));
        Assert.AreEqual(ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger(),
          StrSubstNo('Table Name %1 Unexpected number of records.', TableName));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInvtPickRequestPageHandler(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.New();
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;
}

