codeunit 134835 "Test Item Lookup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item] [Find Item] [Description] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        EditableErr: Label '%1 should be editable', Comment = '%1 is a field name';
        NotEditableErr: Label '%1 should NOT be editable', Comment = '%1 is a field name';
        ItemDoesNotExistMenuTxt: Label 'This item is not registered. To continue, choose one of the following options';

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateDescOnSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup
        CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // Exercise and Verify Existing Item
        SalesLine.Validate(Description, Item.Description);

        SalesLine.TestField("No.", Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateDescOnNotEmptySalesLine()
    var
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 308574] Validate Description in Sales Line when "No." <> '' confirmed
        Initialize();

        // [GIVEN] Item 'A' with Description 'ADescr'
        CreateItem(Item[1]);
        // [GIVEN] Item 'B' with Description 'BDescr'
        CreateItem(Item[2]);
        // [GIVEN] Sales Line with "No." = 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[1]."No.", 0);

        SalesLine.TestField("No.", Item[1]."No.");

        // [WHEN] Validate description with 'BDescr'; Confirm = True
        SalesLine.Validate(Description, Item[2].Description);

        // [THEN] Sales Line "No." = 'B'
        SalesLine.TestField("No.", Item[1]."No.");
        SalesLine.TestField(Description, Item[2].Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateDescOnSalesItemWithAnotherBlockedItem()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO] Validate Description in Sales Line when there is blocked Item with same description
        Initialize();

        // [GIVEN] Item 'A' with Description 'Descr'
        CreateItem(ItemA);

        // [GIVEN] Item 'B' with same Description 'Descr' and Blocked is 'Yes';
        CreateItem(ItemB);
        ItemB.Description := ItemA.Description;
        ItemB.Blocked := true;
        ItemB.Modify();

        // [GIVEN] Sales Line with Type = Item and "No." = ''
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // [WHEN] Validate sales line description with 'Descr'
        SalesLine.Validate(Description, ItemB.Description);

        // [THEN] Sales Line "No." = 'A'
        SalesLine.TestField("No.", ItemA."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateDescOnSalesItemWithAnotherSalesBlockedItem()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO] Validate Description in Sales Line when there is sales blocked Item with same description
        Initialize();

        // [GIVEN] Item 'A' with Description 'Descr'
        CreateItem(ItemA);

        // [GIVEN] Item 'B' with same Description 'Descr' and Sales Blocked is 'Yes';
        CreateItem(ItemB);
        ItemB.Description := ItemA.Description;
        ItemB."Sales Blocked" := true;
        ItemB.Modify();

        // [GIVEN] Sales Line with Type = Item and "No." = ''
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // [WHEN] Validate sales line description with 'Descr'
        SalesLine.Validate(Description, ItemB.Description);

        // [THEN] Sales Line "No." = 'A'
        SalesLine.TestField("No.", ItemA."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateDescOnPurchItemWithAnotherBlockedItem()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO] Validate Description in Purchase Line when there is blocked Item with same description
        Initialize();

        // [GIVEN] Item 'A' with Description 'Descr'
        CreateItem(ItemA);

        // [GIVEN] Item 'B' with same Description 'Descr' and Blocked is 'Yes';
        CreateItem(ItemB);
        ItemB.Description := ItemA.Description;
        ItemB.Blocked := true;
        ItemB.Modify();

        // [GIVEN] Purchase Line with Type = Item and "No." = ''
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);

        // [WHEN] Validate purchase line description with 'Descr'
        PurchaseLine.Validate(Description, ItemB.Description);

        // [THEN] Purchase Line "No." = 'A'
        PurchaseLine.TestField("No.", ItemA."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateDescOnPurchItemWithAnotherPurchasingBlockedItem()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO] Validate Description in Purchase Line when there is blocked Item with same description
        Initialize();

        // [GIVEN] Item 'A' with Description 'Descr'
        CreateItem(ItemA);

        // [GIVEN] Item 'B' with same Description 'Descr'
        CreateItem(ItemB);
        ItemB.Description := ItemA.Description;
        ItemB."Purchasing Blocked" := true;
        ItemB.Modify();

        // [GIVEN] Purchase Line with Type = Item and "No." = ''
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);

        // [WHEN] Validate purchase line description with 'Descr'
        PurchaseLine.Validate(Description, ItemB.Description);

        // [THEN] Purchase Line "No." = 'A'
        PurchaseLine.TestField("No.", ItemA."No.");
    end;

    [Test]
    [HandlerFunctions('CreateItemStrMenuHandler,SelectItemTemplListModalPageHandler,ItemCardModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestAutoCreateItemFromDescriptionOnSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RandomItemDescription: Text[50];
    begin
        Initialize();

        LibrarySales.SetCreateItemFromDescription(true);

        // Setup
        RandomItemDescription := CopyStr(Format(CreateGuid()), 1, 50);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate(Type, SalesLine.Type::Item);

        LibraryVariableStorage.Enqueue(ItemDoesNotExistMenuTxt);
        LibraryVariableStorage.Enqueue(1); // select "Create new item card"
        LibraryVariableStorage.Enqueue(Item.Type::Service);

        // Exercise
        SalesLine.Validate(Description, RandomItemDescription);

        // Verify
        Item.SetRange(Description, RandomItemDescription);
        Assert.AreEqual(1, Item.Count, 'Item not created correctly from Description');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResolvingDescriptionWhenRetypingExistingValueSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup
        CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate(Description, Item."No.");
        Assert.AreEqual(Item.Description, SalesLine.Description, 'Description not set correctly on first lookup');

        // Exercise
        SalesLine.Validate(Description, Item."No.");

        // Verify
        Assert.AreEqual(Item."No.", SalesLine.Description, 'Description not set correctly');
        Assert.AreEqual(Item."No.", SalesLine."No.", 'No. was changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteItemLookupInDescription()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize();

        // Setup
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // Excercise
        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(SalesQuote.SalesLines.Quantity.Editable(), 'Quantity should be editable');

        // Excercise
        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(SalesQuote.SalesLines.Quantity.Editable(), StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(SalesQuote.SalesLines."Unit Price".Editable(), StrSubstNo(EditableErr, 'Unit Price'));
        Assert.IsTrue(SalesQuote.SalesLines."Line Amount".Editable(), StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(SalesQuote.SalesLines."Line Discount %".Editable(), StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid()), 1, 20);

        // Excercise
        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType());
        SalesQuote.SalesLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(SalesQuote.SalesLines.Quantity.Editable(), StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(SalesQuote.SalesLines."Unit of Measure Code".Editable(), StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(SalesQuote.SalesLines."Unit Price".Editable(), StrSubstNo(NotEditableErr, 'Unit Price'));
        Assert.IsFalse(SalesQuote.SalesLines."Line Amount".Editable(), StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(SalesQuote.SalesLines."Line Discount %".Editable(), StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceItemLookupInDescription()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize();

        // Setup
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // Excercise
        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(SalesInvoice.SalesLines.Quantity.Editable(), 'Quantity should be editable');

        // Excercise
        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(SalesInvoice.SalesLines.Quantity.Editable(), StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(SalesInvoice.SalesLines."Unit Price".Editable(), StrSubstNo(EditableErr, 'Unit Price'));
        Assert.IsTrue(SalesInvoice.SalesLines."Line Amount".Editable(), StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(SalesInvoice.SalesLines."Line Discount %".Editable(), StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid()), 1, 20);

        // Excercise
        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType());
        SalesInvoice.SalesLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(SalesInvoice.SalesLines.Quantity.Editable(), StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(SalesInvoice.SalesLines."Unit of Measure Code".Editable(), StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(SalesInvoice.SalesLines."Unit Price".Editable(), StrSubstNo(NotEditableErr, 'Unit Price'));
        Assert.IsFalse(SalesInvoice.SalesLines."Line Amount".Editable(), StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(SalesInvoice.SalesLines."Line Discount %".Editable(), StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderItemLookupInDescription()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize();

        // Setup
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // Excercise
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(SalesOrder.SalesLines.Quantity.Editable(), 'Quantity should be editable');

        // Excercise
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(SalesOrder.SalesLines.Quantity.Editable(), StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(SalesOrder.SalesLines."Unit Price".Editable(), StrSubstNo(EditableErr, 'Unit Price'));
        Assert.IsTrue(SalesOrder.SalesLines."Line Amount".Editable(), StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(SalesOrder.SalesLines."Line Discount %".Editable(), StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid()), 1, 20);

        // Excercise
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType());
        SalesOrder.SalesLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(SalesOrder.SalesLines.Quantity.Editable(), StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(SalesOrder.SalesLines."Unit of Measure Code".Editable(), StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(SalesOrder.SalesLines."Unit Price".Editable(), StrSubstNo(NotEditableErr, 'Unit Price'));
        Assert.IsFalse(SalesOrder.SalesLines."Line Amount".Editable(), StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(SalesOrder.SalesLines."Line Discount %".Editable(), StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCreditMemoItemLookupInDescription()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize();

        // Setup
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // Excercise
        SalesCreditMemo.SalesLines.New();
        SalesCreditMemo.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(SalesCreditMemo.SalesLines.Quantity.Editable(), 'Quantity should be editable');

        // Excercise
        SalesCreditMemo.SalesLines.New();
        SalesCreditMemo.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(SalesCreditMemo.SalesLines.Quantity.Editable(), StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(SalesCreditMemo.SalesLines."Unit Price".Editable(), StrSubstNo(EditableErr, 'Unit Price'));
        Assert.IsTrue(SalesCreditMemo.SalesLines."Line Amount".Editable(), StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(SalesCreditMemo.SalesLines."Line Discount %".Editable(), StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid()), 1, 20);

        // Excercise
        SalesCreditMemo.SalesLines.New();
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType());
        SalesCreditMemo.SalesLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(SalesCreditMemo.SalesLines.Quantity.Editable(), StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(SalesCreditMemo.SalesLines."Unit of Measure Code".Editable(), StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(SalesCreditMemo.SalesLines."Unit Price".Editable(), StrSubstNo(NotEditableErr, 'Unit Price'));
        Assert.IsFalse(SalesCreditMemo.SalesLines."Line Amount".Editable(), StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(SalesCreditMemo.SalesLines."Line Discount %".Editable(), StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteItemLookupOnBlankLines()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize();

        // Setup
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Excercise
        SalesQuote.SalesLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo();
        SalesQuote.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesQuote.SalesLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, SalesQuote.SalesLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceItemLookupOnBlankLines()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize();

        // Setup
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Excercise
        SalesInvoice.SalesLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo();
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesInvoice.SalesLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, SalesInvoice.SalesLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderItemLookupOnBlankLines()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize();

        // Setup
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Excercise
        SalesOrder.SalesLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo();
        SalesOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesOrder.SalesLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, SalesOrder.SalesLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCreditMemoItemLookupOnBlankLines()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize();

        // Setup
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.New();
        SalesCreditMemo.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Excercise
        SalesCreditMemo.SalesLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo();
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesCreditMemo.SalesLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, SalesCreditMemo.SalesLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateDescOnPurchaseLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup
        CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);

        // Exercise and Verify Existing Item
        PurchaseLine.Validate(Description, Item.Description);

        PurchaseLine.TestField("No.", Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateDescOnNotEmptyPurchaseLine()
    var
        Item: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 308574] Validate Description in Purchase Line when "No." <> '' confirmed
        Initialize();

        // [GIVEN] Item 'A' with Description 'ADescr'
        CreateItem(Item[1]);
        // [GIVEN] Item 'B' with Description 'BDescr'
        CreateItem(Item[2]);
        // [GIVEN] Purchase Line with "No." = 'A'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);

        // [WHEN] Validate description with 'BDescr'; Confirm = True
        PurchaseLine.Validate(Description, Item[2].Description);

        // [THEN] Purchase Line "No." = 'B'
        PurchaseLine.TestField(Description, Item[2].Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResolvingDescriptionWhenRetypingExistingValuePurchaseLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // [GIVEN] Item No. = "X", Description = "Test"
        CreateItem(Item);

        // [GIVEN] Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate(Description, Item."No.");
        Assert.AreEqual(Item.Description, PurchaseLine.Description, 'Description not set correctly on first lookup');

        // [WHEN] Validate Description in Purchase Line with "X"
        PurchaseLine.Validate(Description, Item."No.");

        // [THEN] No. in Purchase Line = "X"
        // [THEN] Description in Purchase Line = "Test"
        Assert.AreEqual(Item."No.", PurchaseLine.Description, 'Description not set correctly');
        Assert.AreEqual(Item."No.", PurchaseLine."No.", '"No." not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceItemLookupInDescription()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize();

        // Setup
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // Excercise
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(PurchaseInvoice.PurchLines.Quantity.Editable(), 'Quantity should be editable');

        // Excercise
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(PurchaseInvoice.PurchLines.Quantity.Editable(), StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(PurchaseInvoice.PurchLines."Direct Unit Cost".Editable(), StrSubstNo(EditableErr, 'Direct Unit Cost'));
        Assert.IsTrue(PurchaseInvoice.PurchLines."Line Amount".Editable(), StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(PurchaseInvoice.PurchLines."Line Discount %".Editable(), StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid()), 1, 20);

        // Excercise
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(PurchaseLine.FormatType());
        PurchaseInvoice.PurchLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(PurchaseInvoice.PurchLines.Quantity.Editable(), StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(PurchaseInvoice.PurchLines."Unit of Measure Code".Editable(), StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(PurchaseInvoice.PurchLines."Direct Unit Cost".Editable(), StrSubstNo(NotEditableErr, 'Direct Unit Cost'));
        Assert.IsFalse(PurchaseInvoice.PurchLines."Line Amount".Editable(), StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(PurchaseInvoice.PurchLines."Line Discount %".Editable(), StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseCreditMemoItemLookupInDescription()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize();

        // Setup
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // Excercise
        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(PurchaseCreditMemo.PurchLines.Quantity.Editable(), 'Quantity should be editable');

        // Excercise
        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Verify
        Assert.IsTrue(PurchaseCreditMemo.PurchLines.Quantity.Editable(), StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Direct Unit Cost".Editable(), StrSubstNo(EditableErr, 'Direct Unit Cost'));
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Line Amount".Editable(), StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Line Discount %".Editable(), StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid()), 1, 20);

        // Excercise
        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(PurchaseLine.FormatType());
        PurchaseCreditMemo.PurchLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(PurchaseCreditMemo.PurchLines.Quantity.Editable(), StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Unit of Measure Code".Editable(), StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Direct Unit Cost".Editable(), StrSubstNo(NotEditableErr, 'Direct Unit Cost'));
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Line Amount".Editable(), StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Line Discount %".Editable(), StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceItemLookupOnBlankLines()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize();

        // Setup
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Excercise
        PurchaseInvoice.PurchLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo();
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::Item));
        PurchaseInvoice.PurchLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, PurchaseInvoice.PurchLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseCreditMemoItemLookupOnBlankLines()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize();

        // Setup
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo());

        // Excercise
        PurchaseCreditMemo.PurchLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo();
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::Item));
        PurchaseCreditMemo.PurchLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, PurchaseCreditMemo.PurchLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferLineItemNoLookupInDescription()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
    begin
        Initialize();

        // Setup
        CreateItem(Item);
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        TransferLine.Init();
        TransferLine.Validate("Document No.", TransferHeader."No.");

        // Exercise
        TransferLine.Validate(Description, Item."No.");

        // Verify
        Assert.AreEqual(Item.Description, TransferLine.Description, 'Description not set correctly');
        Assert.AreEqual(Item."No.", TransferLine."Item No.", 'No. not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferLineItemNoLookupInDescriptionItemNotFound()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TestGuid: Text[50];
    begin
        Initialize();

        // Setup
        TestGuid := CreateGuid();
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        TransferLine.Init();
        TransferLine.Validate("Document No.", TransferHeader."No.");

        // Exercise
        TransferLine.Validate(Description, TestGuid);

        // Verify
        Assert.AreEqual(TestGuid, TransferLine.Description, 'Description not set correctly');
        Assert.AreEqual('', TransferLine."Item No.", 'No. not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchLineDescriptionWithItemNo()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 232112] Validate Description in Purchase Line with Item "No."
        Initialize();

        // [GIVEN] Item "A"
        CreateItem(ItemA);

        // [GIVEN] Purchase Invoice with item "A"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemA."No.", 0);

        // [GIVEN] Item "B" with Description = 'B123'
        CreateItem(ItemB);

        // [WHEN] Validate Description in Purchase Line with Item "No." = "B"
        PurchaseLine.Validate(Description, ItemB."No.");

        Assert.AreEqual(ItemB."No.", PurchaseLine.Description, 'Description not set correctly');
        Assert.AreEqual(ItemA."No.", PurchaseLine."No.", '"No." not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDescOnSalesLine_Items_aaa_AAA()
    var
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 334557] Validating 'AAA' as a description of new sales line having type "Item" inserts item with 'AAA' description, not 'aaa'
        Initialize();

        CreateItemWithDescription(Item[1], 'aaa');
        CreateItemWithDescription(Item[2], 'AAA');

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // Exercise and Verify Existing Item
        SalesLine.Validate(Description, Item[2].Description);

        SalesLine.TestField("No.", Item[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDescOnPurchaseLine_Items_aaa_AAA()
    var
        Item: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 334557] Validating 'AAA' as a description of new purchase line having type "Item" inserts item with 'AAA' description, not 'aaa'
        Initialize();

        CreateItemWithDescription(Item[1], 'aaa');
        CreateItemWithDescription(Item[2], 'AAA');

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);

        PurchaseLine.Validate(Description, Item[2].Description);

        PurchaseLine.TestField("No.", Item[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDescOnPurchLine_ExactDesc_ValidatesUnitPrice()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        UnitPrice: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 352086] Direct Unit Cost value is assigned to Purch Line on Page when user searches item by exact description
        Initialize();

        UnitPrice := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandInt(10);

        // [GIVEN] Item I with Description = 'TestItem A' and Unit Price, Unit Cost = Last Direct Cost = X 
        CreateItemWithUnitPriceCostDescription(Item, 'TestItem A', UnitPrice, UnitCost);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Order
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoKey(PurchHeader."Document Type", PurchHeader."No.");

        // [WHEN] Item is searched by exact description 'TestItem A' in Purchase Order Line
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines.Description.SetValue(Item.Description);

        // [THEN] Item "No." = I, Direct Unit Cost = X on Purchase Line
        PurchaseOrder.PurchLines."No.".AssertEquals(Item."No.");
        PurchaseOrder.PurchLines."Direct Unit Cost".AssertEquals(UnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDescOnPurchLine_SameDesc_ValidatesUnitPrice()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        UnitPrice: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 352086] Direct Unit Cost value is assigned to Purch Line on Page when user searches item by description of another case
        Initialize();

        UnitPrice := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandInt(10);

        // [GIVEN] Item I with Description = 'TestItem A' and Unit Price, Unit Cost = Last Direct Cost = X 
        CreateItemWithUnitPriceCostDescription(Item, 'TestItem A', UnitPrice, UnitCost);

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoKey(PurchHeader."Document Type", PurchHeader."No.");

        // [WHEN] Item is searched by same description but lowercased 'testitem a' in Purchase Order Line
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines.Description.SetValue('testitem a');

        // [THEN] Item "No." = I, Direct Unit Cost = X on Purchase Line
        PurchaseOrder.PurchLines."No.".AssertEquals(Item."No.");
        PurchaseOrder.PurchLines."Direct Unit Cost".AssertEquals(UnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDescOnPurchLine_IncompleteDesc_ValidatesUnitPrice()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        UnitPrice: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 352086] Direct Unit Cost value is assigned to Purch Line on Page when user searches item by incomplete description
        Initialize();

        UnitPrice := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandInt(10);

        // [GIVEN] Item I with Description = 'TestItem A' and Unit Price, Unit Cost = Last Direct Cost = X 
        CreateItemWithUnitPriceCostDescription(Item, 'TestItem A', UnitPrice, UnitCost);

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoKey(PurchHeader."Document Type", PurchHeader."No.");

        // [WHEN] Item is searched by incomplete description 'testitem' in Purchase Order Line
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines.Description.SetValue('testitem');

        // [THEN] Item "No." = I, Direct Unit Cost = X on Purchase Line
        PurchaseOrder.PurchLines."No.".AssertEquals(Item."No.");
        PurchaseOrder.PurchLines."Direct Unit Cost".AssertEquals(UnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDescOnSalesLine_ExactDesc_ValidatesUnitPrice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales] 
        // [SCENARIO 352086] Unit Price value is assigned to Sales Line on Page when user searches item by exact description
        Initialize();

        // [GIVEN] Item I with Description = 'TestItem A' and Unit Price = X
        UnitPrice := LibraryRandom.RandInt(10);
        CreateItemWithUnitPriceCostDescription(Item, 'TestItem A', UnitPrice, UnitPrice);

        // [GIVEN] Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesHeader."Document Type", SalesHeader."No.");

        // [WHEN] Item is searched by exact description 'TestItem A' in Sales Order Line
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.Description.SetValue(Item.Description);

        // [THEN] Item "No." = I, Direct Unit Cost = X on Sales Line
        SalesOrder.SalesLines."No.".AssertEquals(Item."No.");
        SalesOrder.SalesLines."Unit Price".AssertEquals(UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDescOnSalesLine_SameDesc_ValidatesUnitPrice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 352086] Unit Price value is assigned to Sales Line on Page when user searches item by same description
        Initialize();

        // [GIVEN] Item I with Description = 'TestItem A' and Unit Price = X
        UnitPrice := LibraryRandom.RandInt(10);
        CreateItemWithUnitPriceCostDescription(Item, 'TestItem A', UnitPrice, UnitPrice);

        // [GIVEN] Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesHeader."Document Type", SalesHeader."No.");

        // [WHEN] Item is searched by same but lowercased description 'TestItem X' in Sales Order Line
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.Description.SetValue('testitem a');

        // [THEN] Item "No." = I, Direct Unit Cost = X on Sales Line
        SalesOrder.SalesLines."No.".AssertEquals(Item."No.");
        SalesOrder.SalesLines."Unit Price".AssertEquals(UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDescOnSalesLine_IncompleteDesc_ValidatesUnitPrice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 352086] Unit Price value is assigned to Sales Line on Page when user searches item by incomplete description
        Initialize();

        // [GIVEN] Item I with Description = 'TestItem A' and Unit Price = X
        UnitPrice := LibraryRandom.RandInt(10);
        CreateItemWithUnitPriceCostDescription(Item, 'TestItem A', UnitPrice, UnitPrice);

        // [GIVEN] Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesHeader."Document Type", SalesHeader."No.");

        // [WHEN] Item is searched by incomplete description 'testitem' in Sales Order Line
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.Description.SetValue('testitem');

        // [THEN] Item "No." = I, Direct Unit Cost = X on Sales Line
        SalesOrder.SalesLines."No.".AssertEquals(Item."No.");
        SalesOrder.SalesLines."Unit Price".AssertEquals(UnitPrice);
    end;

    [Test]
    procedure TestGetFirstItemNoFromLookup()
    var
        Item: Record Item;
    begin
        CreateItemWithNosAndDescription(Item, 'ABRACADABRA1000', 'MAGIC1000', 'Magic wand for the price concious sourcerer');
        CreateItemWithNosAndDescription(Item, 'ABRACADABRA1001', 'MAGIC1001', 'Magic wand for the price concious sourcerer. Painted.');
        CreateItemWithNosAndDescription(Item, 'ABRACADABRA2000', 'MAGIC2000', 'Magic wand for the ambitious sourcerer');
        CreateItemWithNosAndDescription(Item, 'CAPE1000', 'MAGIC3000', 'Regular invisibility cape');
        CreateItemWithNosAndDescription(Item, 'CAPE2000', 'MAGIC3001', 'Really invisible invisibility cape');

        Assert.AreEqual('', Item.GetFirstItemNoFromLookup(''), 'Unexpected item selected 1.');
        Assert.AreEqual('ABRACADABRA1000', Item.GetFirstItemNoFromLookup('wand'), 'Unexpected item selected 2.');
        Assert.AreEqual('ABRACADABRA1001', Item.GetFirstItemNoFromLookup('ABRACADABRA1001'), 'Unexpected item selected 2.');
        Assert.AreEqual('ABRACADABRA1001', Item.GetFirstItemNoFromLookup('MAGIC1001'), 'Unexpected item selected 3.');
        Assert.AreEqual('CAPE1000', Item.GetFirstItemNoFromLookup('regular'), 'Unexpected item selected 4.');
        Assert.AreEqual('CAPE2000', Item.GetFirstItemNoFromLookup('MAGIC3001'), 'Unexpected item selected 5.');
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Item Lookup");
        Item.DeleteAll();
        PurchaseLine.DeleteAll();
        SalesLine.DeleteAll();
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Item Lookup");
        LibraryERMCountryData.CreateVATData();
        LibraryTemplates.EnableTemplatesFeature();
        LibraryTemplates.UpdateTemplatesVATGroups();

        IsInitialized := true;

        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveSalesSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Item Lookup");
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        CreateItemWithDescription(
          Item, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)), 1, MaxStrLen(Item.Description)));
    end;

    local procedure CreateItemWithDescription(var Item: Record Item; NewDescription: Text[100])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, NewDescription);
        Item.Modify(true);
    end;

    local procedure CreateItemWithNosAndDescription(var Item: Record Item; NewNo: Text[20]; NewNo2: Text[20]; NewDescription: Text[100])
    begin
        if Item.Get(NewNo) then
            Item.Delete();
        Item.Init();
        Item."No." := NewNo;
        Item."No. 2" := NewNo2;
        Item.Description := NewDescription;
        Item.Insert(true);
    end;

    local procedure CreateItemWithUnitPriceCostDescription(var Item: Record Item; NewDescription: Text[100]; UnitPrice: Decimal; UnitCost: Decimal)
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, UnitPrice, UnitCost);
        Item.Validate(Description, NewDescription);
        Item.Validate("Last Direct Cost", UnitCost);
        Item.Modify(true);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CreateItemStrMenuHandler(OptionString: Text; var Choice: Integer; Instructions: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Instructions);
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplListModalPageHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.First();
        SelectItemTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemCardModalPageHandler(var ItemCard: TestPage "Item Card")
    begin
        ItemCard.Type.SetValue(LibraryVariableStorage.DequeueInteger());
        ItemCard.OK().Invoke();
    end;
}

