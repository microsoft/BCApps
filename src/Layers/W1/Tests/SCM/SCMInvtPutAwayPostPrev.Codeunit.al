codeunit 134779 "SCM Invt. PutAway Post Prev."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Inventory Put Away]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        IsInitialized: Boolean;
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPutAwayRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviewInventoryPutAwayPost_PurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
        WhseActivityPost: Codeunit "Whse.-Act.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Purchase] [Inventory PutAway] [Preview Posting]
        // [SCENARIO] Preview Inventory PutAway posting shows the ledger entries that will be grnerated when the PutAway is posted.
        Initialize();

        // [GIVEN] Location for Inventory PutAway where the 'Require PutAway' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, false, true, false, false, false);

        // [GIVEN] Purchase Order created with Posting Date = WORKDATE
        CreatePurchaseDocumentWithLineLocation(PurchaseHeader, Location.Code, '', '');

        // [WHEN] Inventory PutAway created
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        Commit();
        PurchaseHeader.CreateInvtPutAwayPick();
        FindAndUpdateWhseActivityPostingDate(
          WarehouseActivityHeader, WarehouseActivityLine,
          DATABASE::"Purchase Line", PurchaseHeader."No.",
          WarehouseActivityHeader.Type::"Invt. Put-away", WorkDate() + 1);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhseActivityPost.Preview(WarehouseActivityLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the put away is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPutAwayRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviewInventoryPutAwayPostWithItemTracking_PurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
        WhseActivityPost: Codeunit "Whse.-Act.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Purchase] [Inventory PutAway] [Preview Posting]
        // [SCENARIO] Preview Inventory PutAway posting shows the ledger entries that will be grnerated when the PutAway is posted.
        Initialize();

        // [GIVEN] Location for Inventory PutAway where the 'Require PutAway' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, false, true, false, false, false);

        // [GIVEN] Purchase Order created with Posting Date = WORKDATE
        //CreatePurchaseDocumentWithLineLocation(PurchaseHeader, Location.Code, '', CreateTrackedItem());
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateTrackedItem(), 1);

        // [WHEN] Inventory PutAway created
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        Commit();
        PurchaseHeader.CreateInvtPutAwayPick();
        FindAndUpdateWhseActivityPostingDate(
          WarehouseActivityHeader, WarehouseActivityLine,
          DATABASE::"Purchase Line", PurchaseHeader."No.",
          WarehouseActivityHeader.Type::"Invt. Put-away", WorkDate() + 1);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);
        WarehouseActivityLine.Find();
        WarehouseActivityLine.Validate("Serial No.", 'SL-001');
        WarehouseActivityLine.Modify(true);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhseActivityPost.Preview(WarehouseActivityLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the put away is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPutAwayRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviewInventoryPutAwayPostWithBin_PurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
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
        // [FEATURE] [Purchase] [Inventory PutAway] [Preview Posting]
        // [SCENARIO] Preview Inventory PutAway posting with Bin set shows the ledger entries that will be grnerated when the PutAway is posted.
        Initialize();

        // [GIVEN] Location for Inventory PutAway where 'Require PutAway' and 'Bin Mandatory' are true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, true, true, false, false, false);
        LibraryWarehouse.CreateBin(
                  Bin, Location.Code,
                  CopyStr(
                    LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
                    LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Purchase Order created
        CreatePurchaseDocumentWithLineLocation(PurchaseHeader, Location.Code, Bin.Code, '');

        // [WHEN] Inventory PutAway created
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        Commit();
        PurchaseHeader.CreateInvtPutAwayPick();
        FindAndUpdateWhseActivityPostingDate(
          WarehouseActivityHeader, WarehouseActivityLine,
          DATABASE::"Purchase Line", PurchaseHeader."No.",
          WarehouseActivityHeader.Type::"Invt. Put-away", WorkDate() + 1);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhseActivityPost.Preview(WarehouseActivityLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the put away is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, WarehouseEntry.TableCaption(), 1);

        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPutAwayRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviewInventoryPutAwayPost_ProdOutput()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
        ProdItem: Record Item;
        ProductionOrder: Record "Production Order";
        WhseActivityPost: Codeunit "Whse.-Act.-Post (Yes/No)";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Production] [Inventory PutAway] [Preview Posting]
        // [SCENARIO] Preview Inventory PutAway posting shows the ledger entries that will be grnerated when the PutAway is posted.
        Initialize();

        // [GIVEN] Location for Inventory PutAway where the 'Require PutAway' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, false, true, false, false, false);

        // [GIVEN] Create Production Item
        CreateItem(ProdItem, LibraryRandom.RandDec(100, 2), ProdItem."Costing Method"::Average);

        // [GIVEN] Create 2 level production order for prod item "P" and refresh order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, ProdItem."No.", 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        WhseOutputProdRelease.Release(ProductionOrder);

        Commit();

        // [WHEN] Create Inventory PutAway for the Production Order is run.
        ProductionOrder.CreateInvtPutAwayPick();

        // [THEN] Inventory PutAway lines are created
        FindAndUpdateWhseActivityPostingDate(
          WarehouseActivityHeader, WarehouseActivityLine,
         Database::"Prod. Order Line", ProductionOrder."No.",
          WarehouseActivityHeader.Type::"Invt. Put-away", WorkDate() + 1);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhseActivityPost.Preview(WarehouseActivityLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the PutAway is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        GLPostingPreview.OK().Invoke();
    end;

    local procedure Initialize()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Invt. PutAway Post Prev.");
        LibrarySetupStorage.Restore();
        WarehouseEmployee.DeleteAll();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Invt. PutAway Post Prev.");

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
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Invt. PutAway Post Prev.");
    end;

    local procedure CreateLocationWMSWithWhseEmployee(var Location: Record Location; BinMandatory: Boolean; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateItem(var Item: Record Item; UnitCost: Decimal; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", UnitCost);
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    local procedure CreateTrackedItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode());
        exit(Item."No.");
    end;

    local procedure CreateItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreatePurchaseDocumentWithItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchaseDocumentWithLineLocation(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; BinCode: Code[20]; ItemCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        if ItemCode = '' then
            LibraryInventory.CreateItem(Item)
        else
            Item.Get(ItemCode);

        CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
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
        Assert.AreEqual(
            TableName, GLPostingPreview."Table Name".Value, StrSubstNo('A record for Table Name %1 was not found.', TableName));
        Assert.AreEqual(
            ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger(), StrSubstNo('Table Name %1 Unexpected number of records.', TableName));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInvtPutAwayRequestPageHandler(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPickMvmt.CreateInventorytPutAway.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

