codeunit 134817 "Item Variant Blocked Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Variant] [Blocked]
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
        BlockedErr: Label 'You cannot choose %1 %2 because the %3 check box is selected on its %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        SalesBlockedErr: Label 'You cannot sell %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        PurchasingBlockedErr: Label 'You cannot purchase %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        ServiceSalesBlockedErr: Label 'You cannot sell %1 %2 via service because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        ItemVariantPrimaryKeyLbl: Label '%1, %2', Comment = '%1 - Item No., %2 - Variant Code', Locked = true;
        BlockedItemVariantNotificationMsg: Label 'Item Variant %1 for Item %2 is blocked, but it is allowed on this type of document.', Comment = '%1 - Item Variant Code, %2 - Item No.';
        BlockedTestFieldErr: Label '%1 must be equal to ''%2''', Comment = '%1 - Field Caption, %2 - Expected value';
        InvalidTableRelationErr: Label 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).', Comment = '%1 - Validating Field Caption, %2 - Validating Table Caption, %3 - Validating Value, %4 - Related Table Caption';

    [Test]
    procedure ItemVariantBlockedForSaleOnInvoice()
    var
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Invoice]
        Initialize();

        // [GIVEN] An item variant that is blocked for sales
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Sales Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Sales Invoice
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] Create a line on the sales invoice with the item that is blocked for sale
        asserterror CreateItemSalesLineWithItemVariant(SalesLine, SalesHeader, ItemVariant);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, SalesLine.FieldCaption("Variant Code"), SalesLine.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    procedure ItemVariantBlockedForSaleOnCrMemo()
    var
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        Initialize();

        // [GIVEN] An item variant that is blocked for sales
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Sales Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Sales Credit Memo
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [WHEN] Create a line on the sales credit memo with the item 'X' that is blocked for sale
        CreateItemSalesLineWithItemVariant(SalesLine, SalesHeader, ItemVariant);

        // [THEN] Notification: 'You are adding a blocked item variant X to the document.'
        Assert.ExpectedMessage(StrSubstNo(BlockedItemVariantNotificationMsg, ItemVariant.Code, ItemVariant."Item No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesLine.RecordId);

        // [THEN] Line is created, Item is blocked for sale
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", ItemVariant."Item No.");
        SalesLine.TestField("Variant Code", ItemVariant.Code);
        ItemVariant.Find();
        ItemVariant.TestField("Sales Blocked");

        // [THEN] Credit Memo can be posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    procedure ItemVariantBlockedForSaleOnRetOrder()
    var
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Return Order]
        Initialize();

        // [GIVEN] An item variant that is blocked for sales
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Sales Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Sales Return Order
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");

        // [WHEN] Create a line on the sales return order with the item 'X' that is blocked for sale
        CreateItemSalesLineWithItemVariant(SalesLine, SalesHeader, ItemVariant);

        // [THEN] Notification: 'You are adding a blocked item variant X to the document.'
        Assert.ExpectedMessage(StrSubstNo(BlockedItemVariantNotificationMsg, ItemVariant.Code, ItemVariant."Item No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesLine.RecordId);

        // [THEN] Line is created, Item is blocked for sale
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", ItemVariant."Item No.");
        SalesLine.TestField("Variant Code", ItemVariant.Code);
        ItemVariant.Find();
        ItemVariant.TestField("Sales Blocked");

        // [THEN] Return Order can be posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    procedure ItemVariantBlockedForSaleOnJournal()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Sales] [Journal]
        Initialize();

        // [GIVEN] An item variant that is blocked for sales
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Sales Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Trying to create a new journal line of entry type sale
        asserterror CreateItemJournalLineWithItemVariant(ItemJournalLine, ItemJournalBatch, Enum::"Item Ledger Entry Type"::Sale, ItemVariant);

        // [THEN] An error appears
        Assert.ExpectedError(StrSubstNo(SalesBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Sales Blocked")));
    end;

    [Test]
    procedure ItemVariantBlockedForSaleOnItemJournalPosting()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Sales] [Journal]
        Initialize();

        // [GIVEN] An item variant that is not blocked for sales
        CreateItemVariant(ItemVariant);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] Create a new journal line of entry type sale
        CreateItemJournalLineWithItemVariant(ItemJournalLine, ItemJournalBatch, Enum::"Item Ledger Entry Type"::Sale, ItemVariant);

        // [GIVEN] Update item variant to be blocked for sales
        ItemVariant.Validate("Sales Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Trying to post item journal line of entry type sale
        asserterror LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [THEN] An error appears
        Assert.ExpectedError(StrSubstNo(SalesBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Sales Blocked")));
    end;

    [Test]
    procedure ItemVariantBlockedForSaleOnJournalWithNegAdj()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Sales] [Journal]
        Initialize();

        // [GIVEN] An item variant that is blocked for sales
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Sales Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Create a new journal line of entry type negative adjustment
        CreateItemJournalLineWithItemVariant(ItemJournalLine, ItemJournalBatch, Enum::"Item Ledger Entry Type"::"Negative Adjmt.", ItemVariant);

        // [THEN] Line is created
        ItemJournalLine.Find();
        ItemJournalLine.TestField("Item No.", ItemVariant."Item No.");
        ItemJournalLine.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    procedure ItemVariantBlockedForPurchaseOnInvoice()
    var
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Invoice]
        Initialize();

        // [GIVEN] An item variant that is blocked for purchase
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Purchase Invoice
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [WHEN] Create a line on the purchase invoice with the item variant that is blocked for sale
        asserterror CreateItemPurchaseLineWithItemVariant(PurchaseLine, PurchaseHeader, ItemVariant);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, PurchaseLine.FieldCaption("Variant Code"), PurchaseLine.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    procedure ItemVariantBlockedForPurchaseOnCrMemo()
    var
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        Initialize();

        // [GIVEN] An item variant that is blocked for purchase
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Purchase Credit Memo
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");

        // [WHEN] Create a line in a purchase credit memo with the item with item variant 'X' that is blocked for purchase
        CreateItemPurchaseLineWithItemVariant(PurchaseLine, PurchaseHeader, ItemVariant);

        // [THEN] Notification: 'You are adding a blocked item variant X to the document.'
        Assert.ExpectedMessage(StrSubstNo(BlockedItemVariantNotificationMsg, ItemVariant.Code, ItemVariant."Item No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseLine.RecordId());

        // [THEN] Line is created, Item Variant is blocked for purchasing
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("No.", ItemVariant."Item No.");
        PurchaseLine.TestField("Variant Code", ItemVariant.Code);
        ItemVariant.Find();
        ItemVariant.TestField("Purchasing Blocked");

        // [THEN] Credit Memo can be posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    procedure ItemVariantBlockedForPurchaseOnRetOrder()
    var
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Return Order]
        Initialize();

        // [GIVEN] An item variant that is blocked for purchase
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Purchase Return Order
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");

        // [WHEN] Create a line in a purchase return order with the item with item variant 'X' that is blocked for purchase
        CreateItemPurchaseLineWithItemVariant(PurchaseLine, PurchaseHeader, ItemVariant);

        // [THEN] Notification: 'You are adding a blocked item variant X to the document.'
        Assert.ExpectedMessage(StrSubstNo(BlockedItemVariantNotificationMsg, ItemVariant.Code, ItemVariant."Item No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseLine.RecordId());

        // [THEN] Line is created, Item Variant is blocked for purchasing
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("No.", ItemVariant."Item No.");
        PurchaseLine.TestField("Variant Code", ItemVariant.Code);
        ItemVariant.Find();
        ItemVariant.TestField("Purchasing Blocked");

        // [THEN] Return Order can be posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVariantBlockedForPurchaseOnJournal()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Purchase] [Journal]
        Initialize();

        // [GIVEN] An item that is blocked for purchase
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Trying to create a new journal line of entry type purchase
        asserterror CreateItemJournalLineWithItemVariant(ItemJournalLine, ItemJournalBatch, Enum::"Item Ledger Entry Type"::Purchase, ItemVariant);

        // [THEN] An error appears
        Assert.ExpectedError(StrSubstNo(PurchasingBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Purchasing Blocked")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVariantBlockedForPurchaseOnItemJournalPosting()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Purchase] [Journal]
        Initialize();

        // [GIVEN] An item variant that is not blocked for purchase
        CreateItemVariant(ItemVariant);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] Create a new journal line of entry type purchase
        CreateItemJournalLineWithItemVariant(ItemJournalLine, ItemJournalBatch, Enum::"Item Ledger Entry Type"::Purchase, ItemVariant);

        // [GIVEN] Update item variant to be blocked for purchase
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Trying to post item journal line of entry type purchase
        asserterror LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [THEN] An error appears
        Assert.ExpectedError(StrSubstNo(PurchasingBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Purchasing Blocked")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVariantBlockedForPurchaseOnJournalWithPosAdj()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Purchase] [Journal]
        Initialize();

        // [GIVEN] An item variant that is blocked for purchase
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Create a new journal line of entry type positive adjustment
        CreateItemJournalLineWithItemVariant(ItemJournalLine, ItemJournalBatch, Enum::"Item Ledger Entry Type"::"Positive Adjmt.", ItemVariant);

        // [THEN] Line is created
        ItemJournalLine.Find();
        ItemJournalLine.TestField("Item No.", ItemVariant."Item No.");
        ItemJournalLine.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    procedure ItemVariantBlockedOnAssemblyLine()
    var
        Item: Record Item;
        BlockedItemVariant: Record "Item Variant";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [FEATURE] [Assembly Line]
        // [SCENARIO 490172] User cannot add blocked item variant to assembly line: error raised immediately.
        LibraryInventory.CreateItem(Item);
        Item.Modify(true);

        // [GIVEN] Blocked Item Variant
        LibraryInventory.CreateItemVariant(BlockedItemVariant, Item."No.");
        BlockedItemVariant.Validate(Blocked, true);
        BlockedItemVariant.Modify(true);

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', 1, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", '', 1, 1, '');
        AssemblyLine.Validate("No.", Item."No.");

        // [WHEN] Adding item variant to assembly line
        asserterror AssemblyLine.Validate("Variant Code", BlockedItemVariant.Code);

        // [THEN] Error 'Blocked must be equal to 'No''
        Assert.ExpectedTestFieldError(BlockedItemVariant.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    procedure ItemVariantBlockedOnPlanningComponent()
    var
        Item: Record Item;
        BlockedItemVariant: Record "Item Variant";
        PlanningComponent: Record "Planning Component";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning Component]
        // [SCENARIO 490172] User cannot add blocked item variant to planning component: error raised immediately.
        LibraryInventory.CreateItem(Item);
        Item.Modify(true);
        CreateRequisitionLine(RequisitionLine);

        // [GIVEN] Blocked Item Variant
        LibraryInventory.CreateItemVariant(BlockedItemVariant, Item."No.");
        BlockedItemVariant.Validate(Blocked, true);
        BlockedItemVariant.Modify(true);

        // [WHEN] Adding item to planning component
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", Item."No.");

        // [THEN] Error 'Blocked must be equal to 'No''
        asserterror PlanningComponent.Validate("Variant Code", BlockedItemVariant."Code");
        Assert.ExpectedTestFieldError(BlockedItemVariant.FieldCaption(Blocked), Format(false));
    end;

    # region Service Blocked
    [Test]
    procedure ServiceBlockedItemVariant_NotAllowedInServiceItem()
    var
        Item: Record Item;
        BlockedItemVariant: Record "Item Variant";
        ServiceBlockedItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Blocked] [Service Item]
        // [SCENARIO 378441] Item Variant with "Blocked" = true or "Service Blocked" = true not allowed in Service Item.
        Initialize();

        // [GIVEN] Item that is not blocked
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Item Variant with "Blocked"
        LibraryInventory.CreateItemVariant(BlockedItemVariant, Item."No.");
        BlockedItemVariant.Validate(Blocked, true);
        BlockedItemVariant.Modify(true);

        // [GIVEN] Item Variant with "Service Blocked"
        LibraryInventory.CreateItemVariant(ServiceBlockedItemVariant, Item."No.");
        ServiceBlockedItemVariant.Validate("Service Blocked", true);
        ServiceBlockedItemVariant.Modify(true);

        // [GIVEN] Create a Service Item with Item
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate("Item No.", Item."No.");

        // [WHEN] Setting Item Variant with "Blocked" to Service Item
        asserterror ServiceItem.Validate("Variant Code", BlockedItemVariant.Code);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceItem.FieldCaption("Variant Code"), ServiceItem.TableCaption(), BlockedItemVariant.Code, BlockedItemVariant.TableCaption()));

        // [WHEN] Setting Item Variant with "Service Blocked" to Service Item
        asserterror ServiceItem.Validate("Variant Code", ServiceBlockedItemVariant.Code);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceItem.FieldCaption("Variant Code"), ServiceItem.TableCaption(), ServiceBlockedItemVariant.Code, ServiceBlockedItemVariant.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_NotAllowedInServiceItemLine_ItemVariantIsBlockedBeforeServiceItemValidation()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Item Line] [Service Order]
        // [SCENARIO 378441] Item Variant with "Blocked" = true not allowed in Service Item Line on Service Item validation.
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Create a Service Item Line with Item Variant that is "Blocked"
        asserterror LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_NotAllowedInServiceItemLine_ItemVariantIsBlockedAfterServiceItemValidation()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Item Line] [Service Order]
        // [SCENARIO 378441] Item Variant with "Blocked" = true not allowed in Service Item Line. Item Variant is not "Blocked" on Service Item validation, but it is on subsequent Item Variant validation.
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Item Line with Item Variant that is not "Blocked"
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Validate Item Variant on Service Item Line
        asserterror ServiceItemLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceItemLine.FieldCaption("Variant Code"), ServiceItemLine.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_NotAllowedInServiceItemLine_ItemVariantIsServiceBlockedBeforeServiceItemValidation()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [Item Variant] [Service Blocked] [Service Item] [Service Item Line] [Service Order]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true not allowed in Service Item Line on Service Item validation.
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Create a Service Item Line with Item Variant that is "Service Blocked"
        asserterror LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_NotAllowedInServiceItemLine_ItemVariantIsServiceBlockedAfterServiceItemValidation()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [Item Variant] [Service Blocked] [Service Item] [Service Item Line] [Service Order]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true not allowed in Service Item Line. Item Variant is not "Service Blocked" on Service Item validation, but it is on subsequent Item Variant validation.
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item Variant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Item Line with Item Variant that is not "Service Blocked"
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Validate Item Variant on Service Item Line
        asserterror ServiceItemLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceItemLine.FieldCaption("Variant Code"), ServiceItemLine.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_NotAllowedInServiceLine_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Order]
        // [SCENARIO 378441] Item Variant with "Blocked" = true not allowed in Service Line (Service Quote/Order/Invoice).
        Initialize();

        // [GIVEN] Item Variant with "Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Order Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");

        // [WHEN] Validate Item Variant on Service Line
        asserterror ServiceLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceLine.FieldCaption("Variant Code"), ServiceLine.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_NotAllowedInServiceLine_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item Variant] [Service Blocked] [Service Order]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true not allowed in Service Line (Service Quote/Order/Invoice).
        Initialize();

        // [GIVEN] Item Variant with "Service Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Order Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");

        // [WHEN] Validate Item Variant on Service Line
        asserterror ServiceLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceLine.FieldCaption("Variant Code"), ServiceLine.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    procedure ServiceBlockedItemVariant_AllowedInServiceLine_ServiceCreditMemo()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item Variant] [Service Blocked] [Service Credit Memo]
        // [SCENARIO 378441] Item Variant with "Blocked" = false and "Service Blocked" = true allowed in Service Line of Service Credit Memo (with notification).
        Initialize();

        // [GIVEN] Item Variant with "Service Blocked", without "Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.Validate(Blocked, false);
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Create a Service Credit Memo Header and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");

        // [WHEN] Validate Item Variant that is "Service Blocked", but not "Blocked" on Service Line
        ServiceLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] Notification: 'Item Variant %1 for Item %2 is blocked, but it is allowed on this type of document'
        Assert.ExpectedMessage(StrSubstNo(BlockedItemVariantNotificationMsg, ItemVariant.Code, ItemVariant."Item No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(ServiceLine.RecordId());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [THEN] Line is created
        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        ServiceLine.TestField("No.", ItemVariant."Item No.");
        ServiceLine.TestField("Variant Code", ItemVariant.Code);

        // [THEN] Service Credit Memo can be posted
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
    end;

    [Test]
    procedure ServiceBlockedItemVariant_NotAllowedInStandardServiceLine_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Standard Service Code]
        // [SCENARIO 378441] Item Variant with "Blocked" = true not allowed in Standard Service Line.
        Initialize();

        // [GIVEN] Item Variant with "Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [GIVEN] Create a Standard Service Code
        LibraryService.CreateStandardServiceCode(StandardServiceCode);

        // [GIVEN] Create a Standard Service Line with Type = Item
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode.Code);
        StandardServiceLine.Validate(Type, StandardServiceLine.Type::Item);
        StandardServiceLine.Validate("No.", Item."No.");

        // [WHEN] Set Item Variant that is "Blocked"
        asserterror StandardServiceLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, StandardServiceLine.FieldCaption("Variant Code"), StandardServiceLine.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_NotAllowedInStandardServiceLine_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // [FEATURE] [Item Variant] [Service Blocked] [Standard Service Code]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true not allowed in Standard Service Line.
        Initialize();

        // [GIVEN] Item Variant with "Service Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Create a Standard Service Code
        LibraryService.CreateStandardServiceCode(StandardServiceCode);

        // [GIVEN] Create a Standard Service Line with Type = Item
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode.Code);
        StandardServiceLine.Validate(Type, StandardServiceLine.Type::Item);
        StandardServiceLine.Validate("No.", Item."No.");

        // [WHEN] Set Item Variant that is "Service Blocked"
        asserterror StandardServiceLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, StandardServiceLine.FieldCaption("Variant Code"), StandardServiceLine.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_CannotReleaseServiceDocument_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Quote] [Release]
        // [SCENARIO 378441] Item Variant with "Blocked" = true, cannot Release Service Document (Quote/Invoice/Order).
        Initialize();

        // [GIVEN] Item Variant without "Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item Variant
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Variant Code", ItemVariant.Code);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Release Service Document
        asserterror LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_CannotReleaseServiceDocument_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item Variant] [Service Blocked] [Service Quote] [Release]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true, cannot Release Service Document (Quote/Invoice/Order).
        Initialize();

        // [GIVEN] Item Variant without "Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item Variant
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Variant Code", ItemVariant.Code);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Release Service Document
        asserterror LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_CannotCreateServiceOrderFromQuote_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Quote] [Make Order]
        // [SCENARIO 378441] Item Variant with "Blocked" = true, cannot Create Service Order from Quote.
        Initialize();

        // [GIVEN] Item Variant without "Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item Variant
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Variant Code", ItemVariant.Code);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Create Service Order from Service Quote
        asserterror LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_CannotCreateServiceOrderFromQuote_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item Variant] [Service Blocked] [Service Quote] [Release]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true, cannot Create Service Order from Quote.
        Initialize();

        // [GIVEN] Item Variant without "Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item Variant
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Variant Code", ItemVariant.Code);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Create Service Order from Service Quote
        asserterror LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_CannotPostShipServiceOrder_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Order] [Post]
        // [SCENARIO 378441] Item Variant with "Blocked" = true, cannot Post (ship) Service Order.
        Initialize();

        // [GIVEN] Item Variant without "Blocked" on Inventory
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        SetItemVariantInventory(ItemVariant, LibraryRandom.RandIntInRange(15, 20));

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Order Header, Service Item Line and Service Line with Item Variant
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Variant Code", ItemVariant.Code);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify(true);

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Get(ItemVariant."Item No.", ItemVariant.Code);
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Post Service Order
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [THEN] An error appears: 'You cannot choose Item Variant'
        Assert.ExpectedError(StrSubstNo(BlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption(Blocked)));
    end;

    [Test]
    procedure ServiceBlockedItemVariant_CannotPostShipServiceOrder_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Item Variant] [Service Blocked] [Service Order] [Post]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true, cannot Post (ship) Service Order.
        Initialize();

        // [GIVEN] Item Variant without "Service Blocked" on Inventory
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        SetItemVariantInventory(ItemVariant, LibraryRandom.RandIntInRange(15, 20));

        // [GIVEN] Create a Service Item without Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Order Header, Service Item Line and Service Line with Item Variant
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Variant Code", ItemVariant.Code);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify(true);

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Get(ItemVariant."Item No.", ItemVariant.Code);
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Post Service Order
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [THEN] An error appears: 'You cannot sell Item Variant via service'
        Assert.ExpectedError(StrSubstNo(ServiceSalesBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Service Blocked")));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_NotAllowedInServiceContractLine_ItemVariantIsBlockedBeforeServiceItemValidation()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract]
        // [SCENARIO 378441] Item Variant with "Blocked" = true not allowed in Service Contract Line on Service Item validation.
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Create a Service Contract Line with Item that is "Blocked"
        asserterror LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_NotAllowedInServiceContractLine_ItemVariantIsBlockedAfterServiceItemValidation()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract]
        // [SCENARIO 378441] Item Variant with "Blocked" = true not allowed in Service Contract Line. Item Variant is not "Blocked" on Service Item validation, but it is on subsequent Item validation.
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Validate Item Variant on Service Contract Line
        asserterror ServiceContractLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceContractLine.FieldCaption("Variant Code"), ServiceContractLine.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_NotAllowedInServiceContractLine_ItemVariantIsServiceBlockedBeforeServiceItemValidation()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Service Blocked] [Service Item] [Service Contract]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true not allowed in Service Contract Line on Service Item validation.
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Create a Service Contract Line with Item Variant that is "Service Blocked"
        asserterror LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_NotAllowedInServiceContractLine_ItemVariantIsServiceBlockedAfterServiceItemValidation()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Service Blocked] [Service Item] [Service Contract]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true not allowed in Service Contract Line. Item Variant is not "Blocked" on Service Item validation, but it is on subsequent Item validation.
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Validate Item Variant on Service Contract Line
        asserterror ServiceContractLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceContractLine.FieldCaption("Variant Code"), ServiceContractLine.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotLockServiceContract_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Lock]
        // [SCENARIO 378441] Item Variant with "Blocked" = true, cannot Lock "Service Contract".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.        
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Lock Service Contract
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotLockServiceContract_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Lock]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true, cannot Lock "Service Contract".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Lock Service Contract
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotLockServiceContractQuote_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract Quote] [Lock]
        // [SCENARIO 378441] Item Variant with "Blocked" = true, cannot Lock "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Lock Service Contract Quote
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotLockServiceContractQuote_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract Quote] [Lock]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true, cannot Lock "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Lock Service Contract Quote
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotSignServiceContract_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Sign]
        // [SCENARIO 378441] Item Variant with "Blocked" = true, cannot Sign "Service Contract".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.        
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Sign Service Contract
        asserterror SignServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotSignServiceContract_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Sign]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true, cannot Sign "Service Contract".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Sign Service Contract
        asserterror SignServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotMakeServiceContractFromServiceContractQuote_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Make Contract]
        // [SCENARIO 378441] Item Variant with "Blocked" = true, cannot Make Contract from "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.        
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Make Service Contract
        asserterror MakeServiceContractFromServiceContractQuote(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotMakeServiceContractFromServiceContractQuote_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Make Contract]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true, cannot Make Contract from "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Make Service Contract
        asserterror MakeServiceContractFromServiceContractQuote(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotCopyServiceContract_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Copy]
        // [SCENARIO 378441] Item Variant with "Blocked" = true, cannot Copy "Service Contract".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.        
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Copy Service Contract
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotCopyServiceContract_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Copy]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true, cannot Copy "Service Contract".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Copy Service Contract
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotCopyServiceContractQuote_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract Quote] [Copy]
        // [SCENARIO 378441] Item Variant with "Blocked" = true, cannot Copy "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Copy Service Contract Quote
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotCopyServiceContractQuote_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract Quote] [Copy]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true, cannot Copy "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Copy Service Contract Quote
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotCreateContractServiceOrders_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServicePeriodDateFormula: DateFormula;
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Create Service Orders]
        // [SCENARIO 378441] Item Variant with "Blocked" = true, cannot Create Service Orders for "Service Contract".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
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

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Run "Create Contract Service Orders"
        asserterror CreateServiceContractServiceOrders(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotCreateContractServiceOrders_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServicePeriodDateFormula: DateFormula;
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Create Service Orders]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true, cannot Create Service Orders for "Service Contract".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Service Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
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

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Run "Create Contract Service Orders"
        asserterror CreateServiceContractServiceOrders(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotCreateContractInvoices_Blocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Create Service Invoices]
        // [SCENARIO 378441] Item Variant with "Blocked" = true, cannot Create Service Invoices for "Service Contract".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-1Y>', WorkDate()));
        ServiceContractHeader.Modify(true);

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
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

        // [GIVEN] Set Item Variant to "Blocked"
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Run "Create Contract Invoices"
        asserterror CreateServiceContractInvoices(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption(Blocked), Format(false)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure ServiceBlockedItemVariant_CannotCreateContractInvoices_ServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Item Variant] [Blocked] [Service Item] [Service Contract] [Create Service Invoices]
        // [SCENARIO 378441] Item Variant with "Service Blocked" = true, cannot Create Service Invoices for "Service Contract".
        Initialize();

        // [GIVEN] Create Item Variant that is not "Blocked" or "Service Blocked", and create Service Item with Item VAriant
        CreateServiceItemWithItemVariant(ServiceItem, '', Item, ItemVariant);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-1Y>', WorkDate()));
        ServiceContractHeader.Modify(true);

        // [GIVEN] Create a Service Contract Line with Item Variant that is not "Blocked"
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Variant Code", ItemVariant.Code);
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

        // [GIVEN] Set Item Variant to "Service Blocked"
        ItemVariant.Validate("Service Blocked", true);
        ItemVariant.Modify(true);

        // [WHEN] Run "Create Contract Invoices"
        asserterror CreateServiceContractInvoices(ServiceContractHeader);

        // [THEN] An error appears: 'Service Blocked must be equal to 'No''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ItemVariant.FieldCaption("Service Blocked"), Format(false)));
    end;
    # endregion Service Blocked

    local procedure Initialize()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Item Blocked Test");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Item Blocked Test");

        LibraryService.SetupServiceMgtNoSeries();
        AtLeastOneServiceContractTemplateMustExist();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Item Blocked Test");
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

    local procedure CreateItemVariant(var ItemVariant: Record "Item Variant")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
    end;

    procedure CreateItemSalesLineWithItemVariant(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemVariant: Record "Item Variant")
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemVariant."Item No.", 0);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        SalesLine.Modify();
    end;

    procedure CreateItemPurchaseLineWithItemVariant(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemVariant: Record "Item Variant")
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemVariant."Item No.", 0);
        PurchaseLine.Validate("Variant Code", ItemVariant.Code);
        PurchaseLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify();
    end;

    procedure CreateItemJournalLineWithItemVariant(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; ItemVariant: Record "Item Variant")
    begin
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemLedgerEntryType, ItemVariant."Item No.", 0);
        ItemJournalLine.Validate("Variant Code", ItemVariant.Code);
        ItemJournalLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Modify();
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

    local procedure CreateServiceItemWithItemVariant(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; var Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", ItemVariant."Item No.");
        ServiceItem.Validate("Variant Code", ItemVariant.Code);
        ServiceItem.Modify(true);
    end;

    local procedure SetItemVariantInventory(ItemVariant: Record "Item Variant"; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemVariant.TestField("Item No.");
        ItemVariant.TestField(Code);

        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemVariant."Item No.", Quantity);
        ItemJournalLine.Validate("Variant Code", ItemVariant.Code);
        ItemJournalLine.Modify(true);

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
        CreateContractInvoices.SetOptions(WorkDate(), WorkDate(), 0);
        CreateContractInvoices.UseRequestPage(false);
        CreateContractInvoices.Run();
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

