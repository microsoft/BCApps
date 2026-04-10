codeunit 134777 "SCM Item Journal Post Preview"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Item Journal]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';

    [Test]
    [Scope('OnPrem')]
    procedure TestItemJournalPreview()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemJnlPost: Codeunit "Item Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Item Journal without cost posting shows item ledger entries and value entries that will be generated when journal is posted.
        Initialize();

        // [GIVEN] Automatic Cost Posting is switched OFF in inventory setup
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Create an Item Journal Line
        InsertItemJournalLine(ItemJournalLine, 1);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror ItemJnlPost.Preview(ItemJournalLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemJournalPreviewWithMultipleLines()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemJnlPost: Codeunit "Item Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Item Journal without cost posting shows item ledger entries and value entries that will be generated when journal is posted.
        Initialize();

        // [GIVEN] Automatic Cost Posting is switched OFF in inventory setup
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Create two Item Journal Lines
        InsertItemJournalLine(ItemJournalLine, 2);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror ItemJnlPost.Preview(ItemJournalLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 2);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemJournalPreviewWithAutomaticCostPosting()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        GLEntry: Record "G/L Entry";
        ItemJnlPost: Codeunit "Item Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Item Journal with cost posting shows general ledger entries that will be generated when journal is posted.
        Initialize();

        // [GIVEN] Automatic Cost Posting is switched ON in inventory setup
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create an Item Journal Line
        InsertItemJournalLine(ItemJournalLine, 1);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror ItemJnlPost.Preview(ItemJournalLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, GLEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemJournalPreviewWithBin()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        GLEntry: Record "G/L Entry";
        WarehouseEntry: Record "Warehouse Entry";
        Location: Record Location;
        Bin: Record Bin;
        ItemJnlPost: Codeunit "Item Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Item Journal shows warehouse entries when location and bin code is set on the item journal line.
        Initialize();

        // [GIVEN] Automatic Cost Posting is switched ON in inventory setup
        LibraryInventory.SetAutomaticCostPosting(true);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(
          Bin, Location.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');

        Location."Default Bin Code" := Bin.Code;
        Location.Modify();

        // [GIVEN] Create an Item Journal Line
        InsertItemJournalLine(ItemJournalLine, 1);
        ItemJournalLine."Location Code" := Location.Code;
        ItemJournalLine."Bin Code" := Bin.Code;
        ItemJournalLine.Modify(true);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror ItemJnlPost.Preview(ItemJournalLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, GLEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, WarehouseEntry.TableCaption(), 1);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryPageHandler')]
    [Scope('OnPrem')]
    procedure TestPhysInventoryJournalPostPreview()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        ItemJnlPost: Codeunit "Item Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Quantity: Decimal;
    begin
        // [SCENARIO] Posting preview of Item Journal shows warehouse entries when location and bin code is set on the item journal line.
        Initialize();

        // [GIVEN] Create an Item, Location and add enough inventory in that location
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Location.Code, '', Item."No.", Quantity, Item."Base Unit of Measure", false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as receive.

        // [GIVEN] Create Item Journal Lines to capture the Physical Inventory Journl lines
        LibraryVariableStorage.Enqueue(Item."No.");  // Enqueue for CalculateInventoryPageHandler.
        RunCalculateInventory(ItemJournalBatch);

        // [GIVEN] Change the physical quantity
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.SetRange("Phys. Inventory", true);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Qty. (Phys. Inventory)", Quantity + 1);
        ItemJournalLine.Modify(true);

        CreateGeneralPostingSetup(ItemJournalLine."Gen. Bus. Posting Group", ItemJournalLine."Gen. Prod. Posting Group");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror ItemJnlPost.Preview(ItemJournalLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, PhysInventoryLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestConsumptionPostPreview()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemJnlPost: Codeunit "Item Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Posting preview of Item Journal shows warehouse entries when location and bin code is set on the item journal line.
        Initialize();

        // [GIVEN] Create and Release Production Order.
        CreateInitialSetupForReleasedProductionOrder(ProductionOrder, ProdOrderComponent);

        // [WHEN] Calculate Consumption report
        CalculateConsumptionJournal(ItemJournalBatch, ProductionOrder."No.");

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror ItemJnlPost.Preview(ItemJournalLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the journal is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);

        Assert.IsFalse(GLPostingPreview.Next(), 'No more entries should exist.');
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalWithPrewviewHandler')]
    procedure TestPreviewOnProductionJournalDoesNotThrowException()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO] Posting preview of Production Journal does not throw any exceptions and works as expected(Bug https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_workitems/edit/476412).
        Initialize();

        // [GIVEN] Create and Release Production Order.
        CreateInitialSetupForReleasedProductionOrder(ProductionOrder, ProdOrderComponent);

        // [GIVEN] Open Release Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [WHEN] Open Production Journal page for the selected line and preview is called.
        ReleasedProductionOrder.ProdOrderLines.First();
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [THEN] Preview does not throw any exceptions.
    end;

    [Test]
    [HandlerFunctions('ProductionJournalWithPrewviewHandler')]
    procedure TestPreviewPostingNotShowingErrorFromProductionJournal()
    var
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 495874] Preview Posting shows "There is nothing to post the journal does not contain a quantity or amount" message in Production Journal. 
        Initialize();

        // [GIVEN] Create a Item Revaluation Journal by entering Random value to Description field only
        CreateRevaluationJournal(ItemJournalLine);

        // [GIVEN] Create and Release Production Order.
        CreateInitialSetupForReleasedProductionOrder(ProductionOrder, ProdOrderComponent);

        // [GIVEN] Open Release Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [WHEN] Open Production Journal page for the selected line and preview is called.
        ReleasedProductionOrder.ProdOrderLines.First();
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [THEN] Preview does not throw any exceptions.
        // Handled in ProductionJournalWithPrewviewHandler Handler Function
    end;

    local procedure Initialize()
    var
        ItemJournalLine: Record "Item Journal Line";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Item Journal Post Preview");
        LibrarySetupStorage.Restore();
        ItemJournalLine.DeleteAll();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Item Journal Post Preview");
        IsInitialized := true;

        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryPurchase.SetOrderNoSeriesInSetup();
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Item Journal Post Preview");
    end;

    local procedure CreateGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup) then
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup, GenProdPostingGroup);
    end;

    local procedure RunCalculateInventory(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
        CalculateInventory: Report "Calculate Inventory";
    begin
        CreateItemJournalBatch(ItemJournalBatch);
        ItemJournalLine.Init();
        ItemJournalLine.Validate(ItemJournalLine."Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate(ItemJournalLine."Journal Batch Name", ItemJournalBatch.Name);
        CalculateInventory.SetItemJnlLine(ItemJournalLine);
        Commit();
        CalculateInventory.RunModal();
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::"Phys. Inventory");
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CalculateConsumptionJournal(var ItemJournalBatch: Record "Item Journal Batch"; ProductionOrderNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Consumption);
        LibraryManufacturing.CalculateConsumption(ProductionOrderNo, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure InsertItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; NoOfLinesToCreate: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Index: Integer;
    begin
        LibraryInventory.SelectItemJournalTemplateName(
              ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(
          ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);

        for Index := 1 to NoOfLinesToCreate do begin
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::Purchase, LibraryInventory.CreateItemNo(), 1);
            ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
            ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDecInRange(1, 100, 2));
            ItemJournalLine.Modify(true);
        end;
    end;

    local procedure CreateInitialSetupForReleasedProductionOrder(var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released);
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.");
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ProdOrderComponent."Item No.",
          ProdOrderComponent."Expected Quantity", WorkDate(), '');
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"): Code[20]
    begin
        CreateAndRefreshProductionOrderWithItem(
          ProductionOrder, Status, CreateItemWithRoutingAndProductionBOM(), LibraryRandom.RandDec(10, 2));
        exit(ProductionOrder."No.");
    end;

    local procedure FindProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrderStatus);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure CreateAndPostItemJournalLine(ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure CreateItemWithRoutingAndProductionBOM(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use random value for Unit Price.
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));  // Use random value for Unit Cost.
        Item.Validate("Production BOM No.", CreateProductionBOM(Item."Base Unit of Measure"));
        Item.Validate("Routing No.", CreateRouting());
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateRouting(): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateProductionBOM(UnitOfMeasureCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(CreateProductionBOMForSingleItem(Item."No.", UnitOfMeasureCode));
    end;

    local procedure CreateProductionBOMForSingleItem(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        ModifyStatusInProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure ModifyStatusInProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Status: Enum "BOM Status")
    begin
        ProductionBOMHeader.Validate(Status, Status);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndRefreshProductionOrderWithItem(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProductionOrder.Find();
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10]; ItemTracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
        if ItemTracking then
            PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateRevaluationJournal(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ClearRevaluationJournalLines(ItemJournalBatch);
        LibraryInventory.CreateItemJnlLineWithNoItem(
            ItemJournalLine, ItemJournalBatch, ItemJournalBatch."Journal Template Name",
            ItemJournalBatch.Name, ItemJournalLine."Entry Type"::" ");
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        ItemJournalLine.Description := LibraryRandom.RandText(100);
        ItemJournalLine.Modify(true);
    end;

    local procedure ClearRevaluationJournalLines(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.SetupNewBatch();
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure VerifyGLPostingPreviewLine(GLPostingPreview: TestPage "G/L Posting Preview"; TableName: Text; ExpectedEntryCount: Integer)
    begin
        Assert.AreEqual(TableName, GLPostingPreview."Table Name".Value, StrSubstNo('A record for Table Name %1 was not found.', TableName));
        Assert.AreEqual(ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger(),
          StrSubstNo('Table Name %1 Unexpected number of records.', TableName));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateInventoryPageHandler(var CalculateInventory: TestRequestPage "Calculate Inventory")
    var
        DequeueVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariant);
        CalculateInventory.Item.SetFilter("No.", DequeueVariant);
        CalculateInventory.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalWithPrewviewHandler(var ProductionJournal: TestPage "Production Journal")
    var
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        GLPostingPreview.Trap();
        ProductionJournal.PreviewPosting.Invoke();
        GLPostingPreview.OK().Invoke();
    end;
}

