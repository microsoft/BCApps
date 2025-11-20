codeunit 134815 "Item Blocked Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item] [Blocked]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryPlanning: Codeunit "Library - Planning";
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;
        ServiceContractOperation: Option "Create Contract from Template","Invoice for Period";
        AddingBlockedItemMsg: Label 'Item %1 is blocked, but it is allowed on this type of document.', Comment = '%1 - Item No.';
        BlockedErr: Label 'You cannot choose %1 %2 because the %3 check box is selected on its %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        SalesBlockedErr: Label 'You cannot sell %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        PurchasingBlockedErr: Label 'You cannot purchase %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        ServiceSalesBlockedErr: Label 'You cannot sell %1 %2 via service because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        BlockedTestFieldErr: Label '%1 must be equal to ''%2''', Comment = '%1 - Field Caption, %2 - Expected value';
        InvalidTableRelationErr: Label 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).', Comment = '%1 - Validating Field Caption, %2 - Validating Table Caption, %3 - Validating Value, %4 - Related Table Caption';

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure T105_ItemBlockedForSaleOnCrMemo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        Initialize();
        // [GIVEN] An item that is blocked for sales
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [WHEN] Create a line on the sales credit memo with the item 'X' that is blocked for sale
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Notification: 'You are adding a blocked item X to the document.'
        Assert.ExpectedMessage(StrSubstNo(AddingBlockedItemMsg, Item."No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesLine.RecordId);
        // [THEN] Line is created, Item is blocked for sale
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", Item."No.");
        Item.Find();
        Item.TestField("Sales Blocked");
        // [THEN] Credit Memo can be posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure T106_ItemBlockedForSaleOnRetOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Return Order]
        Initialize();
        // [GIVEN] An item that is blocked for sales
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");

        // [WHEN] Create a line on the sales return order with the item 'X' that is blocked for sale
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Notification: 'You are adding a blocked item X to the document.'
        Assert.ExpectedMessage(StrSubstNo(AddingBlockedItemMsg, Item."No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesLine.RecordId);
        // [THEN] Line is created, Item is blocked for sale
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", Item."No.");
        Item.Find();
        Item.TestField("Sales Blocked");
        // [THEN] Return order can be posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure T115_ItemBlockedForSaleOnRetOrderDescriptionLookup()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesReturnOrderPage: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Sales] [Return Order] [UI]
        Initialize();
        // [GIVEN] An item 'X' that is blocked for sales
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        // [GIVEN] New line is created on the sales return order, where "Type" is 'Item'
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");
        SalesReturnOrderPage.OpenEdit();
        SalesReturnOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesReturnOrderPage.SalesLines.Type.Value('Item');

        // [WHEN] Lookup in "No." control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        SalesReturnOrderPage.SalesLines."No.".Lookup();
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Item must be in the list');

        // [WHEN] Lookup in "Description" control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        SalesReturnOrderPage.SalesLines.Description.Lookup();
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Item must be in the list (Description)');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure T116_ItemBlockedForSaleOnCrMemoDescriptionLookup()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesCreditMemoPage: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Sales] [Credit Memo] [UI]
        Initialize();
        // [GIVEN] An item 'X' that is blocked for sales
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        // [GIVEN] New line is created on the sales credit memo, where "Type" is 'Item'
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesCreditMemoPage.OpenEdit();
        SalesCreditMemoPage.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemoPage.SalesLines.Type.Value('Item');

        // [WHEN] Lookup in "No." control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        SalesCreditMemoPage.SalesLines."No.".Lookup();
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Item must be in the list');

        // [WHEN] Lookup in "Description" control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        SalesCreditMemoPage.SalesLines.Description.Lookup();
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Item must be in the list (Description)');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_ItemBlockedForSaleOnJournal()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Sales] [Journal]
        Initialize();
        // [GIVEN] An item that is blocked for sale
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Trying to create a new journal line of entry type sale
        asserterror
          LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::Sale, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] An error appears
        Assert.ExpectedError(StrSubstNo(SalesBlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Sales Blocked")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T125_ItemBlockedForSaleOnJournalWithNegAdj()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Sales] [Journal]
        Initialize();
        // [GIVEN] An item that is blocked for sale
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Create a new journal line of entry type negative adjustment
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Line is created
        ItemJournalLine.Find();
        ItemJournalLine.TestField("Item No.", Item."No.");
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure T205_ItemBlockedForPurchaseOnCrMemo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        Initialize();
        // [GIVEN] An item that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");

        // [WHEN] Create a line in a purchase credit memo with the item 'X' that is blocked for purchase
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Notification: 'You are adding a blocked item X to the document.'
        Assert.ExpectedMessage(StrSubstNo(AddingBlockedItemMsg, Item."No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseLine.RecordId);
        // [THEN] Line is created, Item is blocked for purchasing
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("No.", Item."No.");
        Item.Find();
        Item.TestField("Purchasing Blocked");
        // [THEN] Credit Memo can be posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure T206_ItemBlockedForPurchaseOnRetOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Return Order]
        Initialize();
        // [GIVEN] An item that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");

        // [WHEN] Create a line in a purchase return order with the item 'X' that is blocked for purchase
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Notification: 'You are adding a blocked item X to the document.'
        Assert.ExpectedMessage(StrSubstNo(AddingBlockedItemMsg, Item."No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseLine.RecordId);
        // [THEN] Line is created, Item is blocked for purchasing
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("No.", Item."No.");
        Item.Find();
        Item.TestField("Purchasing Blocked");
        // [THEN] Return Order can be posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure T215_ItemBlockedForPurchOnRetOrderDescriptionLookup()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseReturnOrderPage: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Purchase] [Return Order] [UI]
        Initialize();
        // [GIVEN] An item 'X' that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);

        // [GIVEN] Create a line on the purchase return order, where "Type" is 'Item'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        PurchaseReturnOrderPage.OpenEdit();
        PurchaseReturnOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseReturnOrderPage.PurchLines.Type.Value('Item');

        // [WHEN] Lookup in "No." control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        PurchaseReturnOrderPage.PurchLines."No.".Lookup();
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Item must not be in the list');

        // [WHEN] Lookup in "Description" control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        PurchaseReturnOrderPage.PurchLines.Description.Lookup();
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Item must be in the list (Description)');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure T216_ItemBlockedForPurchOnCrMemoDescriptionLookup()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseCreditMemoPage: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [UI]
        Initialize();
        // [GIVEN] An item 'X' that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);

        // [GIVEN] Create a line on the purchase credit memo, where "Type" is 'Item'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseCreditMemoPage.OpenEdit();
        PurchaseCreditMemoPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseCreditMemoPage.PurchLines.Type.Value('Item');

        // [WHEN] Lookup in "No." control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        PurchaseCreditMemoPage.PurchLines."No.".Lookup();
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Item must not be in the list');

        // [WHEN] Lookup in "Description" control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        PurchaseCreditMemoPage.PurchLines.Description.Lookup();
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Item must be in the list (Description)');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T220_ItemBlockedForPurchaseOnJournal()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Purchase] [Journal]
        Initialize();
        // [GIVEN] An item that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Trying to create a new journal line of entry type purchase
        asserterror
          LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::Purchase, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] An error appears
        Assert.ExpectedError(StrSubstNo(PurchasingBlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Purchasing Blocked")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T225_ItemBlockedForPurchaseOnJournalWithPosAdj()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Purchase] [Journal]
        Initialize();
        // [GIVEN] An item that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Create a new journal line of entry type positive adjustment
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Line is created
        ItemJournalLine.Find();
        ItemJournalLine.TestField("Item No.", Item."No.");
    end;

    [Test]
    procedure BlockedItemOnItemJournalLine()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Journal] [UT]
        // [SCENARIO 429193] Specify blocked item number in error message in item journal.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate(Blocked, true);
        Item.Modify(true);

        asserterror LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 0);

        Assert.ExpectedError(StrSubstNo(BlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption(Blocked)));
    end;

    [Test]
    procedure BlockedItemOnAssemblyLine()
    var
        BlockedItem, Item : Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [FEATURE] [Assembly Line]
        // [SCENARIO 490172] User cannot add blocked item to assembly line: error raised immediately.
        LibraryInventory.CreateItem(Item);
        Item.Modify(true);

        // [GIVEN] Blocked Item
        LibraryInventory.CreateItem(BlockedItem);
        BlockedItem.Validate(Blocked, true);
        BlockedItem.Modify(true);

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', 1, '');

        // [WHEN] Adding item to assembly line
        // [THEN] Error 'Blocked must be equal to 'No''
        asserterror LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, BlockedItem."No.", '', 1, 1, '');
        Assert.ExpectedTestFieldError(BlockedItem.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    procedure BlockedItemOnPlanningComponent()
    var
        BlockedItem: Record Item;
        PlanningComponent: Record "Planning Component";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning Component]
        // [SCENARIO 490172] User cannot add blocked item to planning component: error raised immediately.
        CreateRequisitionLine(RequisitionLine);

        // [GIVEN] Blocked Item
        LibraryInventory.CreateItem(BlockedItem);
        BlockedItem.Validate(Blocked, true);
        BlockedItem.Modify(true);

        // [WHEN] Adding item to planning component
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);

        // [THEN] Error 'Blocked must be equal to 'No''
        asserterror PlanningComponent.Validate("Item No.", BlockedItem."No.");
        Assert.ExpectedTestFieldError(BlockedItem.FieldCaption(Blocked), Format(false));
    end;

    # region Service Blocked
    [Test]
    procedure ServiceBlockedItem_NotAllowedInServiceItem()
    var
        BlockedItem: Record Item;
        ServiceBlockedItem: Record Item;
        ServiceItem: Record "Service Item";
    begin
        // [FEATURE] [Item] [Blocked] [Service Blocked] [Service Item]
        // [SCENARIO 378441] Item with "Blocked" = true or "Service Blocked" = true not allowed in Service Item.
        Initialize();

        // [GIVEN] Item with "Blocked"
        LibraryInventory.CreateItem(BlockedItem);
        BlockedItem.Validate(Blocked, true);
        BlockedItem.Modify(true);

        // [GIVEN] Item with "Service Blocked"
        LibraryInventory.CreateItem(ServiceBlockedItem);
        ServiceBlockedItem.Validate("Service Blocked", true);
        ServiceBlockedItem.Modify(true);

        // [GIVEN] Create a Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [WHEN] Setting Item with "Blocked" to Service Item
        asserterror ServiceItem.Validate("Item No.", BlockedItem."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceItem.FieldCaption("Item No."), ServiceItem.TableCaption(), BlockedItem."No.", BlockedItem.TableCaption()));

        // [WHEN] Setting Item with "Service Blocked" to Service Item
        asserterror ServiceItem.Validate("Item No.", ServiceBlockedItem."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceItem.FieldCaption("Item No."), ServiceItem.TableCaption(), ServiceBlockedItem."No.", ServiceBlockedItem.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItem_NotAllowedInServiceItemLine_ItemIsBlockedBeforeServiceItemValidation()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Item Line] [Service Order]
        // [SCENARIO 378441] Item with "Blocked" = true not allowed in Service Item Line on Service Item validation.
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Create a Service Item Line with Item that is "Blocked"
        asserterror LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItem_NotAllowedInServiceItemLine_ItemIsBlockedAfterServiceItemValidation()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Item Line] [Service Order]
        // [SCENARIO 378441] Item with "Blocked" = true not allowed in Service Item Line. Item is not "Blocked" on Service Item validation, but it is on subsequent Item validation.
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Item Line with Item that is not "Blocked"
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Validate Item on Service Item Line
        asserterror ServiceItemLine.Validate("Item No.", Item."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceItemLine.FieldCaption("Item No."), ServiceItemLine.TableCaption(), Item."No.", Item.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItem_NotAllowedInServiceItemLine_ItemIsServiceBlockedBeforeServiceItemValidation()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [Item] [Service Blocked] [Service Item] [Service Item Line] [Service Order]
        // [SCENARIO 378441] Item with "Service Blocked" = true not allowed in Service Item Line on Service Item validation.
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Create a Service Item Line with Item that is "Service Blocked"
        asserterror LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItem_NotAllowedInServiceItemLine_ItemIsServiceBlockedAfterServiceItemValidation()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [Item] [Service Blocked] [Service Item] [Service Item Line] [Service Order]
        // [SCENARIO 378441] Item with "Service Blocked" = true not allowed in Service Item Line. Item is not "Service Blocked" on Service Item validation, but it is on subsequent Item validation.
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Item Line with Item that is not "Service Blocked"
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Validate Item on Service Item Line
        asserterror ServiceItemLine.Validate("Item No.", Item."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceItemLine.FieldCaption("Item No."), ServiceItemLine.TableCaption(), Item."No.", Item.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItem_NotAllowedInServiceLine_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Order]
        // [SCENARIO 378441] Item with "Blocked" = true not allowed in Service Line (Service Quote/Order/Invoice).
        Initialize();

        // [GIVEN] Item with "Blocked"
        LibraryInventory.CreateItem(Item);
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Order Header and Service Item Line
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [WHEN] Create Service Line with Item that is "Blocked"
        asserterror LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceLine.FieldCaption("No."), ServiceLine.TableCaption(), Item."No.", Item.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItem_NotAllowedInServiceLine_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item] [Service Blocked] [Service Order]
        // [SCENARIO 378441] Item with "Service Blocked" = true not allowed in Service Line (Service Quote/Order/Invoice).
        Initialize();

        // [GIVEN] Item with "Service Blocked"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Order Header and Service Item Line
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [WHEN] Create Service Line with Item that is "Service Blocked"
        asserterror LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceLine.FieldCaption("No."), ServiceLine.TableCaption(), Item."No.", Item.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    procedure ServiceBlockedItem_AllowedInServiceLine_ServiceCreditMemo()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item] [Service Blocked] [Service Credit Memo]
        // [SCENARIO 378441] Item with "Blocked" = false and "Service Blocked" = true allowed in Service Line of Service Credit Memo (with notification).
        Initialize();

        // [GIVEN] Item with "Service Blocked", without "Blocked"
        LibraryInventory.CreateItem(Item);
        Item.Validate(Blocked, false);
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [GIVEN] Create a Service Credit Memo Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());

        // [WHEN] Create Service Line with Item that is "Service Blocked", but not "Blocked"
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [THEN] Notification: 'Item %1 is blocked, but it is allowed on this type of document.'
        Assert.ExpectedMessage(StrSubstNo(AddingBlockedItemMsg, Item."No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(ServiceLine.RecordId());

        // [THEN] Line is created
        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        ServiceLine.TestField("No.", Item."No.");

        // [THEN] Service Credit Memo can be posted
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
    end;

    [Test]
    procedure ServiceBlockedItem_NotAllowedInStandardServiceLine_Blocked()
    var
        Item: Record Item;
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // [FEATURE] [Item] [Blocked] [Standard Service Code]
        // [SCENARIO 378441] Item with "Blocked" = true not allowed in Standard Service Line.
        Initialize();

        // [GIVEN] Item with "Blocked"
        LibraryInventory.CreateItem(Item);
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [GIVEN] Create a Standard Service Code
        LibraryService.CreateStandardServiceCode(StandardServiceCode);

        // [GIVEN] Create a Standard Service Line with Type = Item
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode.Code);
        StandardServiceLine.Validate(Type, StandardServiceLine.Type::Item);

        // [WHEN] Set Item that is "Blocked"
        asserterror StandardServiceLine.Validate("No.", Item."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, StandardServiceLine.FieldCaption("No."), StandardServiceLine.TableCaption(), Item."No.", Item.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItem_NotAllowedInStandardServiceLine_ServiceBlocked()
    var
        Item: Record Item;
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // [FEATURE] [Item] [Service Blocked] [Standard Service Code]
        // [SCENARIO 378441] Item with "Service Blocked" = true not allowed in Standard Service Line.
        Initialize();

        // [GIVEN] Item with "Blocked"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [GIVEN] Create a Standard Service Code
        LibraryService.CreateStandardServiceCode(StandardServiceCode);

        // [GIVEN] Create a Standard Service Line with Type = Item
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode.Code);
        StandardServiceLine.Validate(Type, StandardServiceLine.Type::Item);

        // [WHEN] Set Item that is "Service Blocked"
        asserterror StandardServiceLine.Validate("No.", Item."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, StandardServiceLine.FieldCaption("No."), StandardServiceLine.TableCaption(), Item."No.", Item.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItem_CannotReleaseServiceDocument_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Quote] [Release]
        // [SCENARIO 378441] Item with "Blocked" = true, cannot Release Service Document (Quote/Invoice/Order).
        Initialize();

        // [GIVEN] Item without "Blocked"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Release Service Document
        asserterror LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItem_CannotReleaseServiceDocument_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item] [Service Blocked] [Service Quote] [Release]
        // [SCENARIO 378441] Item with "Service Blocked" = true, cannot Release Service Document (Quote/Invoice/Order).
        Initialize();

        // [GIVEN] Item without "Service Blocked"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Release Service Document
        asserterror LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItem_CannotCreateServiceOrderFromQuote_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Quote] [Make Order]
        // [SCENARIO 378441] Item with "Blocked" = true, cannot Create Service Order from Quote.
        Initialize();

        // [GIVEN] Item without "Blocked"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Create Service Order from Service Quote
        asserterror LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItem_CannotCreateServiceOrderFromQuote_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item] [Service Blocked] [Service Quote] [Release]
        // [SCENARIO 378441] Item with "Service Blocked" = true, cannot Create Service Order from Quote.
        Initialize();

        // [GIVEN] Item without "Service Blocked"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Create Service Order from Service Quote
        asserterror LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItem_CannotPostShipServiceOrder_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Order] [Post]
        // [SCENARIO 378441] Item with "Blocked" = true, cannot Post (ship) Service Order.
        Initialize();

        // [GIVEN] Item without "Blocked" on Inventory
        LibraryInventory.CreateItem(Item);
        SetItemInventory(Item, LibraryRandom.RandIntInRange(15, 20));

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Order Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify(true);

        // [GIVEN] Set Item to "Blocked"
        Item.Get(Item."No.");
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Post Service Order
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [THEN] An error appears: 'You cannot choose Item'
        Assert.ExpectedError(StrSubstNo(BlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption(Blocked)));
    end;

    [Test]
    procedure ServiceBlockedItem_CannotPostShipServiceOrder_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item] [Service Blocked] [Service Order] [Post]
        // [SCENARIO 378441] Item with "Service Blocked" = true, cannot Post (ship) Service Order.
        Initialize();

        // [GIVEN] Item without "Service Blocked" on Inventory
        LibraryInventory.CreateItem(Item);
        SetItemInventory(Item, LibraryRandom.RandIntInRange(15, 20));

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Order Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify(true);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Get(Item."No.");
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Post Service Order
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [THEN] An error appears: 'You cannot sell Item via Service'
        Assert.ExpectedError(StrSubstNo(ServiceSalesBlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Service Blocked")));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_NotAllowedInServiceContractLine_ItemIsBlockedBeforeServiceItemValidation()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract]
        // [SCENARIO 378441] Item with "Blocked" = true not allowed in Service Contract Line on Service Item validation.
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Create a Service Contract Line with Item that is "Blocked"
        asserterror LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_NotAllowedInServiceContractLine_ItemIsBlockedAfterServiceItemValidation()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract]
        // [SCENARIO 378441] Item with "Blocked" = true not allowed in Service Contract Line. Item is not "Blocked" on Service Item validation, but it is on subsequent Item validation.
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Validate Item on Service Contract Line
        asserterror ServiceContractLine.Validate("Item No.", Item."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceContractLine.FieldCaption("Item No."), ServiceContractLine.TableCaption(), Item."No.", Item.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_NotAllowedInServiceContractLine_ItemIsServiceBlockedBeforeServiceItemValidation()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Service Blocked] [Service Item] [Service Contract]
        // [SCENARIO 378441] Item with "Service Blocked" = true not allowed in Service Contract Line on Service Item validation.
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Create a Service Contract Line with Item that is "Service Blocked"
        asserterror LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_NotAllowedInServiceContractLine_ItemIsServiceBlockedAfterServiceItemValidation()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Service Blocked] [Service Item] [Service Contract]
        // [SCENARIO 378441] Item with "Service Blocked" = true not allowed in Service Contract Line. Item is not "Blocked" on Service Item validation, but it is on subsequent Item validation.
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Validate Item on Service Contract Line
        asserterror ServiceContractLine.Validate("Item No.", Item."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceContractLine.FieldCaption("Item No."), ServiceContractLine.TableCaption(), Item."No.", Item.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotLockServiceContract_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Lock]
        // [SCENARIO 378441] Item with "Blocked" = true, cannot Lock "Service Contract".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Lock Service Contract
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotLockServiceContract_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Lock]
        // [SCENARIO 378441] Item with "Service Blocked" = true, cannot Lock "Service Contract".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Lock Service Contract
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotLockServiceContractQuote_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract Quote] [Lock]
        // [SCENARIO 378441] Item with "Blocked" = true, cannot Lock "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Lock Service Contract Quote
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotLockServiceContractQuote_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract Quote] [Lock]
        // [SCENARIO 378441] Item with "Service Blocked" = true, cannot Lock "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Lock Service Contract Quote
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotSignServiceContract_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Sign]
        // [SCENARIO 378441] Item with "Blocked" = true, cannot Sign "Service Contract".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Sign Service Contract
        asserterror SignServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotSignServiceContract_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Sign]
        // [SCENARIO 378441] Item with "Service Blocked" = true, cannot Sign "Service Contract".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Sign Service Contract
        asserterror SignServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotMakeServiceContractFromServiceContractQuote_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Make Contract]
        // [SCENARIO 378441] Item with "Blocked" = true, cannot Make Contract from "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Make Service Contract
        asserterror MakeServiceContractFromServiceContractQuote(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotMakeServiceContractFromServiceContractQuote_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Make Contract]
        // [SCENARIO 378441] Item with "Service Blocked" = true, cannot Make Contract from "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Make Service Contract
        asserterror MakeServiceContractFromServiceContractQuote(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotCopyServiceContract_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Copy]
        // [SCENARIO 378441] Item with "Blocked" = true, cannot Copy "Service Contract".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Copy Service Contract
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotCopyServiceContract_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Copy]
        // [SCENARIO 378441] Item with "Service Blocked" = true, cannot Copy "Service Contract".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Copy Service Contract
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotCopyServiceContractQuote_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract Quote] [Copy]
        // [SCENARIO 378441] Item with "Blocked" = true, cannot Copy "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Copy Service Contract Quote
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotCopyServiceContractQuote_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract Quote] [Copy]
        // [SCENARIO 378441] Item with "Service Blocked" = true, cannot Copy "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Copy Service Contract Quote
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotCreateContractServiceOrders_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServicePeriodDateFormula: DateFormula;
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Create Service Orders]
        // [SCENARIO 378441] Item with "Blocked" = true, cannot Create Service Orders for "Service Contract".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("First Service Date", WorkDate());
        Evaluate(ServicePeriodDateFormula, '<1Y>');
        ServiceContractHeader.Validate("Service Period", ServicePeriodDateFormula);
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Service Contract
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Invoice for Period");
        SignServiceContract(ServiceContractHeader);

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Run "Create Contract Service Orders"
        asserterror CreateServiceContractServiceOrders(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotCreateContractServiceOrders_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServicePeriodDateFormula: DateFormula;
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Create Service Orders]
        // [SCENARIO 378441] Item with "Service Blocked" = true, cannot Create Service Orders for "Service Contract".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("First Service Date", WorkDate());
        Evaluate(ServicePeriodDateFormula, '<1Y>');
        ServiceContractHeader.Validate("Service Period", ServicePeriodDateFormula);
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Service Contract
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Invoice for Period");
        SignServiceContract(ServiceContractHeader);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Run "Create Contract Service Orders"
        asserterror CreateServiceContractServiceOrders(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotCreateContractInvoices_Blocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Create Service Invoices]
        // [SCENARIO 378441] Item with "Blocked" = true, cannot Create Service Invoices for "Service Contract".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-1Y>', WorkDate()));
        ServiceContractHeader.Modify(true);

        // [GIVEN] Create a Service Contract Line with Item that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Service Contract
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Invoice for Period");
        SignServiceContract(ServiceContractHeader);

        // [GIVEN] Set Item to "Blocked"
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Run "Create Contract Invoices"
        asserterror CreateServiceContractInvoices(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItem_CannotCreateContractInvoices_ServiceBlocked()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item] [Blocked] [Service Item] [Service Contract] [Create Service Invoices]
        // [SCENARIO 378441] Item with "Service Blocked" = true, cannot Create Service Invoices for "Service Contract".
        Initialize();

        // [GIVEN] Create Item that is not "Blocked" or "Service Blocked", and create Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-1Y>', WorkDate()));
        ServiceContractHeader.Modify(true);

        // [GIVEN] Create a Service Contract Line with Item that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Service Contract
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Invoice for Period");
        SignServiceContract(ServiceContractHeader);

        // [GIVEN] Set Item to "Service Blocked"
        Item.Validate("Service Blocked", true);
        Item.Modify(true);

        // [WHEN] Run "Create Contract Invoices"
        asserterror CreateServiceContractInvoices(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, Item.FieldCaption("Service Blocked"), Format(false)));
    end;
    # endregion Service Blocked

    local procedure Initialize()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Item Blocked Test");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Item Blocked Test");

        LibraryService.SetupServiceMgtNoSeries();
        AtLeastOneServiceContractTemplateMustExist();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Item Blocked Test");
    end;

    local procedure AtLeastOneServiceContractTemplateMustExist()
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        if not ServiceContractTemplate.IsEmpty() then
            exit;

        ServiceContractTemplate.Init();
        ServiceContractTemplate.Insert(true);
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
    end;

    local procedure CreateServiceItemWithItem(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);

        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Modify(true);
    end;

    local procedure SetItemInventory(Item: Record Item; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        Item.TestField("No.");

        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);

        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalLine."Journal Batch Name");
    end;

    local procedure LockServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        LockOpenServContract.LockServContract(ServiceContractHeader);
    end;

    local procedure SignServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure MakeServiceContractFromServiceContractQuote(var ServiceContractHeader: Record "Service Contract Header")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContractQuote(ServiceContractHeader);
    end;

    local procedure CopyServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLineTo: Record "Service Contract Line";
        CopyServiceContractMgt: Codeunit "Copy Service Contract Mgt.";
    begin
        CopyServiceContractMgt.CopyServiceContractLines(ServiceContractHeader, ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.", ServiceContractLineTo);
    end;

    local procedure CreateServiceContractServiceOrders(ServiceContractHeader: Record "Service Contract Header")
    var
        CreateContractServiceOrders: Report "Create Contract Service Orders";
    begin
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        CreateContractServiceOrders.SetTableView(ServiceContractHeader);
        CreateContractServiceOrders.InitializeRequest(WorkDate(), WorkDate(), 0);
        CreateContractServiceOrders.UseRequestPage(false);
        CreateContractServiceOrders.Run();
    end;

    local procedure CreateServiceContractInvoices(ServiceContractHeader: Record "Service Contract Header")
    var
        CreateContractInvoices: Report "Create Contract Invoices";
    begin
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        CreateContractInvoices.SetTableView(ServiceContractHeader);
        CreateContractInvoices.SetOptions(WorkDate(), ServiceContractHeader."Next Invoice Date", 0);
        CreateContractInvoices.UseRequestPage(false);
        CreateContractInvoices.Run();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListModalPageHandler(var ItemLookup: TestPage "Item Lookup")
    begin
        ItemLookup.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(ItemLookup.First());
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SentNotificationHandler(var Notification: Notification): Boolean;
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [ConfirmHandler]
    procedure ServiceConfirmHandler(ConfirmMessage: Text[1024]; var Result: Boolean)
    var
        ServiceContractOperationValue: Option "Create Contract from Template","Invoice for Period";
    begin
        ServiceContractOperationValue := LibraryVariableStorage.DequeueInteger();
        case ServiceContractOperationValue of
            ServiceContractOperationValue::"Create Contract from Template":
                Result := false; // Do not use Template
            ServiceContractOperationValue::"Invoice for Period":
                Result := false; // Do not create Invoice for Period
        end;
    end;
}

