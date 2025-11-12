codeunit 134394 "ERM Purchase Subform"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [Purchase]
        isInitialized := false;
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryResource: Codeunit "Library - Resource";
        isInitialized: Boolean;
        ChangeConfirmMsg: Label 'Do you want';
        CalculateInvoiceDiscountQst: Label 'Do you want to calculate the invoice discount?';
        QuoteMsg: Label 'has been converted to order number';
        BlanketMsg: Label 'has been created from blanket order';
        UnitofMeasureCodeIsEditableMsg: Label 'Unit of Measure Code should not be editable.';
        UnitofMeasureCodeIsNotEditableMsg: Label 'Unit of Measure Code should be editable.';
        UpdateInvDiscountQst: Label 'One or more lines have been invoiced. The discount distributed to invoiced lines will not be taken into account.\\Do you want to update the invoice discount?';
        EditableErr: Label '%1 should be editable';
        NotEditableErr: Label '%1 should NOT be editable';
        ChangeCurrencyConfirmQst: Label 'If you change %1, the existing purchase lines will be deleted and new purchase lines based on the new information in the header will be created.';
        ItemChargeAssignmentErr: Label 'You can only assign Item Charges for Line Types of Charge (Item).';
        MustMatchErr: Label '%1 and %2 must match.';
        InvoiceDiscPct: Label 'Invoice Disc. Pct.';
        ItemTestDescriptionLbl: Label 'Test Description';

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseOrder);

        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderAddingLinesUpdatesTotalsStatistics()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseOrder);

        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseOrder);
        // prepare dialog
        LibraryVariableStorage.Enqueue('Do you');
        LibraryVariableStorage.Enqueue(true);
        PurchaseOrder.CalculateInvoiceDiscount.Invoke();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(PurchaseOrder);
        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPerc()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseOrder);
        // prepare dialog
        LibraryVariableStorage.Enqueue('Do you');
        LibraryVariableStorage.Enqueue(true);
        PurchaseOrder.CalculateInvoiceDiscount.Invoke();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(PurchaseOrder);
        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseOrder);

        PurchaseOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.First();
        CheckOrderStatistics(PurchaseOrder);

        PurchaseOrder.PurchLines."Line Amount".SetValue(
          Round(PurchaseOrder.PurchLines."Line Amount".AsDecimal() / 2, 1));
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.First();
        CheckOrderStatistics(PurchaseOrder);

        PurchaseOrder.PurchLines."No.".SetValue('');
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.First();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(PurchaseOrder);
        CheckOrderStatistics(PurchaseOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyingLineUpdatesTotalsAndInvoiceDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseOrder);

        PurchaseOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.First();
        CheckPurchaseOrderStatistics(PurchaseOrder);

        PurchaseOrder.PurchLines."Line Amount".SetValue(
          Round(PurchaseOrder.PurchLines."Line Amount".AsDecimal() / 2, 1));
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.First();
        CheckPurchaseOrderStatistics(PurchaseOrder);

        PurchaseOrder.PurchLines."No.".SetValue('');
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.First();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(PurchaseOrder);
        CheckPurchaseOrderStatistics(PurchaseOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseOrder);

        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        PurchaseOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.First();

        CheckOrderStatistics(PurchaseOrder);

        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckOrderStatistics(PurchaseOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmtToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseOrder);

        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        PurchaseOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.First();

        CheckPurchaseOrderStatistics(PurchaseOrder);

        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckPurchaseOrderStatistics(PurchaseOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToVendorToVendorWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        AnswerYesToAllConfirmDialogs();
        PurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseOrder.PurchLines.Next();

        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToVendorToVendorWithoutDiscountsSetDiscAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        AnswerYesToAllConfirmDialogs();
        PurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseOrder.PurchLines.Next();

        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        ValidateOrderInvoiceDiscountAmountIsReadOnly(PurchaseOrder);
        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderDiscTypePercentageIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        ValidateOrderInvoiceDiscountAmountIsReadOnly(PurchaseOrder);
        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);
        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderDiscountTypeAmtIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);
        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToVendorRecalculatesForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        AnswerYesToAllConfirmDialogs();

        PurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseOrder.PurchLines.Next();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(PurchaseOrder);
        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToVendorRecalculatesForInvoiceDiscountTypePct()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        AnswerYesToAllConfirmDialogs();

        PurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseOrder.PurchLines.Next();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(PurchaseOrder);
        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToVendorSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);
        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        PurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseOrder.PurchLines.Next();

        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToVendorSetsDiscountToZeroForInvoiceDiscountTypeAmt()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);
        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        PurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseOrder.PurchLines.Next();

        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        AnswerYesToConfirmDialog();
        PurchaseOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateOrderInvoiceDiscountAmountIsReadOnly(PurchaseOrder);
        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePct()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        AnswerYesToConfirmDialog();
        PurchaseOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateOrderInvoiceDiscountAmountIsReadOnly(PurchaseOrder);
        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);
        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        PurchaseOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmt()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);
        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        PurchaseOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPostWithDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);

        CheckPostedInvoiceStatistics(PostedPurchaseInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPostWithDiscountPrecentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);

        CheckPostedInvoiceStatistics(PostedPurchaseInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderSetLocalCurrencySignOnTotals()
    var
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();

        CreateVendor(Vendor);
        Vendor."Currency Code" := GetDifferentCurrencyCode();
        Vendor.Modify(true);
        PurchaseOrder.OpenNew();

        PurchaseOrder."Buy-from Vendor Name".SetValue(Vendor."No.");
        OrderCheckCurrencyOnTotals(PurchaseOrder, Vendor."Currency Code");

        PurchaseOrder.PurchLines.New();
        OrderCheckCurrencyOnTotals(PurchaseOrder, Vendor."Currency Code");

        PurchaseOrder.PurchLines.Description.SetValue(ItemTestDescriptionLbl);
        OrderCheckCurrencyOnTotals(PurchaseOrder, Vendor."Currency Code");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderApplyManualDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        SetAllowManualDisc();

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseOrder.CalculateInvoiceDiscount.Invoke();
        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderApplyManualDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        SetAllowManualDisc();

        CreateOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseOrder.CalculateInvoiceDiscount.Invoke();
        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateInvoiceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        CheckInvoiceStatistics(PurchaseInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateInvoiceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(PurchaseInvoice);
        CheckInvoiceStatistics(PurchaseInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateInvoiceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        PurchaseInvoice.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseInvoice.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.First();
        CheckInvoiceStatistics(PurchaseInvoice);

        PurchaseInvoice.PurchLines."Line Amount".SetValue(
          Round(PurchaseInvoice.PurchLines."Line Amount".AsDecimal() / 2, 1));
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.First();
        CheckInvoiceStatistics(PurchaseInvoice);

        PurchaseInvoice.PurchLines."Line Discount %".SetValue('0');
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.First();
        CheckInvoiceStatistics(PurchaseInvoice);

        PurchaseInvoice.PurchLines."No.".SetValue('');
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.First();

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(PurchaseInvoice);
        CheckInvoiceStatistics(PurchaseInvoice);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchaseInvoice."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateInvoiceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(InvoiceDiscountAmount);

        PurchaseInvoice.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseInvoice.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.First();

        CheckInvoiceStatistics(PurchaseInvoice);

        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(InvoiceDiscountAmount);
        CheckInvoiceStatistics(PurchaseInvoice);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchaseInvoice."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToVendorToVendorWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToAllConfirmDialogs();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(NewVendor.Name);
        PurchaseInvoice.PurchLines.Next();

        CheckInvoiceStatistics(PurchaseInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(PurchaseInvoice);
        CheckInvoiceStatistics(PurchaseInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(InvoiceDiscountAmount);

        CheckInvoiceStatistics(PurchaseInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToVendorRecalculatesForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToAllConfirmDialogs();

        PurchaseInvoice."Buy-from Vendor Name".SetValue(NewVendor.Name);
        PurchaseInvoice.PurchLines.Next();

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(PurchaseInvoice);
        CheckInvoiceStatistics(PurchaseInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToVendorSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(NewVendor.Name);
        PurchaseInvoice.PurchLines.Next();

        CheckInvoiceStatistics(PurchaseInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToConfirmDialog();
        PurchaseInvoice."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(PurchaseInvoice);
        CheckInvoiceStatistics(PurchaseInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        PurchaseInvoice."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckInvoiceStatistics(PurchaseInvoice);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAddingLinesUpdatesStatisticsTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateInvoiceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        CheckPurchaseInvoiceStatistics(PurchaseInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAddingLineUpdatesStatisticseDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateInvoiceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(PurchaseInvoice);
        CheckPurchaseInvoiceStatistics(PurchaseInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesStatisticsTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateInvoiceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        PurchaseInvoice.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseInvoice.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.First();
        CheckPurchaseInvoiceStatistics(PurchaseInvoice);

        PurchaseInvoice.PurchLines."Line Amount".SetValue(
          Round(PurchaseInvoice.PurchLines."Line Amount".AsDecimal() / 2, 1));
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.First();
        CheckPurchaseInvoiceStatistics(PurchaseInvoice);

        PurchaseInvoice.PurchLines."Line Discount %".SetValue('0');
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.First();
        CheckPurchaseInvoiceStatistics(PurchaseInvoice);

        PurchaseInvoice.PurchLines."No.".SetValue('');
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.First();

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(PurchaseInvoice);
        CheckPurchaseInvoiceStatistics(PurchaseInvoice);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchaseInvoice."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesStatisticsTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateInvoiceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(InvoiceDiscountAmount);

        PurchaseInvoice.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseInvoice.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.First();

        CheckPurchaseInvoiceStatistics(PurchaseInvoice);

        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(InvoiceDiscountAmount);
        CheckPurchaseInvoiceStatistics(PurchaseInvoice);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchaseInvoice."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToVendorToVendorWithoutDiscountSetDiscountAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToAllConfirmDialogs();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(NewVendor.Name);
        PurchaseInvoice.PurchLines.Next();

        CheckPurchaseInvoiceStatistics(PurchaseInvoice);
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountTypePercIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(PurchaseInvoice);
        CheckPurchaseInvoiceStatistics(PurchaseInvoice);
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountTypeAmountIsSetWhenInvoiceOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(InvoiceDiscountAmount);

        CheckPurchaseInvoiceStatistics(PurchaseInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToVendorRecalculatesForInvoiceDiscountTypePerc()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToAllConfirmDialogs();

        PurchaseInvoice."Buy-from Vendor Name".SetValue(NewVendor.Name);
        PurchaseInvoice.PurchLines.Next();

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(PurchaseInvoice);
        CheckPurchaseInvoiceStatistics(PurchaseInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToVendorSetsDiscountToZeroForInvDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(NewVendor.Name);
        PurchaseInvoice.PurchLines.Next();

        CheckPurchaseInvoiceStatistics(PurchaseInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToConfirmDialog();
        PurchaseInvoice."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(PurchaseInvoice);
        CheckPurchaseInvoiceStatistics(PurchaseInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyindFieldOnHeaderSetsDiscountToZeroForInvDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        PurchaseInvoice."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckPurchaseInvoiceStatistics(PurchaseInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicePostWithDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);

        CheckPostedInvoiceStatistics(PostedPurchaseInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicePostWithDiscountPrecentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);

        CheckPostedInvoiceStatistics(PostedPurchaseInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceSetLocalCurrencySignOnTotals()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        CreateVendor(Vendor);
        Vendor."Currency Code" := GetDifferentCurrencyCode();
        Vendor.Modify(true);
        PurchaseInvoice.OpenNew();

        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        InvoiceCheckCurrencyOnTotals(PurchaseInvoice, Vendor."Currency Code");

        PurchaseInvoice.PurchLines.New();
        InvoiceCheckCurrencyOnTotals(PurchaseInvoice, Vendor."Currency Code");

        PurchaseInvoice.PurchLines.Description.SetValue(ItemTestDescriptionLbl);
        InvoiceCheckCurrencyOnTotals(PurchaseInvoice, Vendor."Currency Code");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceApplyManualDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        SetAllowManualDisc();

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseInvoice.CalculateInvoiceDiscount.Invoke();
        CheckInvoiceStatistics(PurchaseInvoice);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceApplyManualDiscountStatisticsUpdated()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        SetAllowManualDisc();

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseInvoice.CalculateInvoiceDiscount.Invoke();
        CheckPurchaseInvoiceStatistics(PurchaseInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceUnitofMeasureCodeNotEditableWhenItemHasSingleUOM()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 55 "Purch. Invoice Subform" is editable for an Item that has only one Unit of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base Unit of Measure.
        // [GIVEN] Purchase Invoice with one line containing Item "I".
        CreateInvoiceThroughTestPageForItemWithGivenNumberOfUOMs(PurchaseInvoice, 0);

        // [WHEN] Find the Purchase Line.
        PurchaseInvoice.PurchLines.First();

        // [THEN] "Unit of Measure Code" field is not editable.
        Assert.IsTrue(PurchaseInvoice.PurchLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsEditableMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceUnitofMeasureCodeEditableWhenItemHasMultipleUOM()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 55 "Purch. Invoice Subform" is editable for an Item that has multiple Units of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base and several additional Units of Measure.
        // [GIVEN] Purchase Invoice with one line containing Item "I".
        CreateInvoiceThroughTestPageForItemWithGivenNumberOfUOMs(PurchaseInvoice, LibraryRandom.RandInt(5));

        // [WHEN] Find the Purchase Line.
        PurchaseInvoice.PurchLines.First();

        // [THEN] "Unit of Measure Code" field is editable.
        Assert.IsTrue(PurchaseInvoice.PurchLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsNotEditableMsg);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        CheckCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(PurchaseCreditMemo);
        CheckCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.First();
        CheckCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines."Line Amount".SetValue(
          Round(PurchaseCreditMemo.PurchLines."Line Amount".AsDecimal() / 2, 1));
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.First();
        CheckCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines."Line Discount %".SetValue('0');
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.First();
        CheckCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines."No.".SetValue('');
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.First();

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(PurchaseCreditMemo);
        CheckCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseCreditMemo."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        PurchaseCreditMemo.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.First();

        CheckCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseCreditMemo."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingSellToVendorToVendorWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        AnswerYesToAllConfirmDialogs();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(NewVendor.Name);
        PurchaseCreditMemo.PurchLines.Next();

        CheckCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(PurchaseCreditMemo);
        CheckCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingSellToVendorRecalculatesForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        AnswerYesToAllConfirmDialogs();

        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(NewVendor.Name);
        PurchaseCreditMemo.PurchLines.Next();

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(PurchaseCreditMemo);
        CheckCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingSellToVendorSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(NewVendor.Name);

        CheckCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        AnswerYesToConfirmDialog();
        PurchaseCreditMemo."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(PurchaseCreditMemo);
        CheckCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        PurchaseCreditMemo."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckCreditMemoStatistics(PurchaseCreditMemo);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoAddingLinesUpdatesStatisticsTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(PurchaseCreditMemo);
        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyingLineUpdatesStatisticsTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.First();
        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines."Line Amount".SetValue(
          Round(PurchaseCreditMemo.PurchLines."Line Amount".AsDecimal() / 2, 1));
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.First();
        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines."Line Discount %".SetValue('0');
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.First();
        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines."No.".SetValue('');
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.First();

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(PurchaseCreditMemo);
        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseCreditMemo."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyingLineUpdatesStatisticsTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        PurchaseCreditMemo.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.First();

        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseCreditMemo."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingSellToVendorToVendorWithoutDiscountsSetDiscAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        AnswerYesToAllConfirmDialogs();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(NewVendor.Name);
        PurchaseCreditMemo.PurchLines.Next();

        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoDiscTypePercentageIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(PurchaseCreditMemo);
        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoDiscTypeAmountIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingSellToVendorRecalculatesForInvoiceDiscountTypePct()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        AnswerYesToAllConfirmDialogs();

        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(NewVendor.Name);
        PurchaseCreditMemo.PurchLines.Next();

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(PurchaseCreditMemo);
        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingSellToVendorSetsDiscountToZeroForInvoiceDiscTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(NewVendor.Name);

        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        AnswerYesToConfirmDialog();
        PurchaseCreditMemo."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(PurchaseCreditMemo);
        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        PurchaseCreditMemo."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoPostPurchaseInvoiceWithDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);

        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        PostedPurchaseCreditMemo.OpenEdit();
        PostedPurchaseCreditMemo.GotoRecord(PurchCrMemoHdr);

        CheckPostedCreditMemoStatistics(PostedPurchaseCreditMemo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoPostPurchaseInvoiceWithDiscountPrecentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        PostedPurchaseCreditMemo.OpenEdit();
        PostedPurchaseCreditMemo.GotoRecord(PurchCrMemoHdr);

        CheckPostedCreditMemoStatistics(PostedPurchaseCreditMemo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoSetLocalCurrencySignOnTotals()
    var
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        CreateVendor(Vendor);
        Vendor."Currency Code" := GetDifferentCurrencyCode();
        Vendor.Modify(true);
        PurchaseCreditMemo.OpenNew();

        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor.Name);
        CreditMemoCheckCurrencyOnTotals(PurchaseCreditMemo, Vendor."Currency Code");

        PurchaseCreditMemo.PurchLines.New();
        CreditMemoCheckCurrencyOnTotals(PurchaseCreditMemo, Vendor."Currency Code");

        PurchaseCreditMemo.PurchLines.Description.SetValue(ItemTestDescriptionLbl);
        CreditMemoCheckCurrencyOnTotals(PurchaseCreditMemo, Vendor."Currency Code");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoApplyManualDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        SetAllowManualDisc();

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseCreditMemo.CalculateInvoiceDiscount.Invoke();
        CheckCreditMemoStatistics(PurchaseCreditMemo);
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoUnitofMeasureCodeNotEditableWhenItemHasSingleUOM()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 98 "Purch. Cr. Memo Subform" is NOT editable for an Item that has only one Unit of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base Unit of Measure.
        // [GIVEN] Purchase Credit Memo with one line containing Item "I".
        CreateCrMemoThroughTestPageForItemWithGivenNumberOfUOMs(PurchaseCreditMemo, 0);

        // [WHEN] Find the Purchase Line.
        PurchaseCreditMemo.PurchLines.First();

        // [THEN] "Unit of Measure Code" field is not editable.
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsEditableMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoUnitofMeasureCodeEditableWhenItemHasMultipleUOM()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 98 "Purch. Cr. Memo Subform" is editable for an Item that has multiple Units of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base and several additional Units of Measure.
        // [GIVEN] Purchase Credit Memo with one line containing Item "I".
        CreateCrMemoThroughTestPageForItemWithGivenNumberOfUOMs(PurchaseCreditMemo, LibraryRandom.RandInt(5));

        // [WHEN] Find the Purchase Line.
        PurchaseCreditMemo.PurchLines.First();

        // [THEN] "Unit of Measure Code" field is editable.
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsNotEditableMsg);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateQuoteWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseQuote);

        CheckQuoteStatistics(PurchaseQuote);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateQuoteWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseQuote);

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(PurchaseQuote);
        CheckQuoteStatistics(PurchaseQuote);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateQuoteWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseQuote);

        PurchaseQuote.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseQuote.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.First();
        CheckQuoteStatistics(PurchaseQuote);

        PurchaseQuote.PurchLines."Line Amount".SetValue(
          Round(PurchaseQuote.PurchLines."Line Amount".AsDecimal() / 2, 1));
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.First();
        CheckQuoteStatistics(PurchaseQuote);

        PurchaseQuote.PurchLines."Line Discount %".SetValue('0');
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.First();
        CheckQuoteStatistics(PurchaseQuote);

        PurchaseQuote.PurchLines."No.".SetValue('');
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.First();

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(PurchaseQuote);
        CheckQuoteStatistics(PurchaseQuote);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Quote);
        PurchaseLine.SetRange("Document No.", PurchaseQuote."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateQuoteWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseQuote);

        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        PurchaseQuote.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseQuote.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.First();

        CheckQuoteStatistics(PurchaseQuote);

        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckQuoteStatistics(PurchaseQuote);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Quote);
        PurchaseLine.SetRange("Document No.", PurchaseQuote."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToVendorToVendorWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        AnswerYesToAllConfirmDialogs();
        PurchaseQuote."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseQuote.PurchLines.Next();

        CheckQuoteStatistics(PurchaseQuote);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(PurchaseQuote);
        CheckQuoteStatistics(PurchaseQuote);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);
        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckQuoteStatistics(PurchaseQuote);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToVendorRecalculatesForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        AnswerYesToAllConfirmDialogs();

        PurchaseQuote."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseQuote.PurchLines.Next();

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(PurchaseQuote);
        CheckQuoteStatistics(PurchaseQuote);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToVendorSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);
        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        PurchaseQuote."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseQuote.PurchLines.Next();

        CheckQuoteStatistics(PurchaseQuote);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        AnswerYesToConfirmDialog();
        PurchaseQuote."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(PurchaseQuote);
        CheckQuoteStatistics(PurchaseQuote);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);
        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        PurchaseQuote."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckQuoteStatistics(PurchaseQuote);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteAddingLinesUpdatesStatisticsTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateQuoteWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseQuote);

        CheckPurchaseQuoteStatistics(PurchaseQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateQuoteWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseQuote);

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(PurchaseQuote);
        CheckPurchaseQuoteStatistics(PurchaseQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyingLineUpdatesStatisticsTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateQuoteWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseQuote);

        PurchaseQuote.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseQuote.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.First();
        CheckPurchaseQuoteStatistics(PurchaseQuote);

        PurchaseQuote.PurchLines."Line Amount".SetValue(
          Round(PurchaseQuote.PurchLines."Line Amount".AsDecimal() / 2, 1));
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.First();
        CheckPurchaseQuoteStatistics(PurchaseQuote);

        PurchaseQuote.PurchLines."Line Discount %".SetValue('0');
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.First();
        CheckPurchaseQuoteStatistics(PurchaseQuote);

        PurchaseQuote.PurchLines."No.".SetValue('');
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.First();

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(PurchaseQuote);
        CheckPurchaseQuoteStatistics(PurchaseQuote);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Quote);
        PurchaseLine.SetRange("Document No.", PurchaseQuote."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyingLineUpdatesStatisticsTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateQuoteWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseQuote);

        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        PurchaseQuote.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseQuote.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.First();

        CheckPurchaseQuoteStatistics(PurchaseQuote);

        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckPurchaseQuoteStatistics(PurchaseQuote);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Quote);
        PurchaseLine.SetRange("Document No.", PurchaseQuote."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToVendorToVendorWithoutDiscSetDiscAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        AnswerYesToAllConfirmDialogs();
        PurchaseQuote."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseQuote.PurchLines.Next();

        CheckPurchaseQuoteStatistics(PurchaseQuote);
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteDiscountTypePercentageIsSetWhenInvoiceOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(PurchaseQuote);
        CheckPurchaseQuoteStatistics(PurchaseQuote);
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteDiscountTypeAmountIsSetWhenInvoiceOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);
        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckPurchaseQuoteStatistics(PurchaseQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToVendorRecalculatesForInvoiceDiscountTypePct()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        AnswerYesToAllConfirmDialogs();

        PurchaseQuote."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseQuote.PurchLines.Next();

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(PurchaseQuote);
        CheckPurchaseQuoteStatistics(PurchaseQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToVendorSetsDiscToZeroForInvoiceDiscTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);
        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        PurchaseQuote."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseQuote.PurchLines.Next();

        CheckPurchaseQuoteStatistics(PurchaseQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePct()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        AnswerYesToConfirmDialog();
        PurchaseQuote."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(PurchaseQuote);
        CheckPurchaseQuoteStatistics(PurchaseQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyindFieldOnHeaderSetsDiscToZeroForInvoiceDiscTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);
        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        PurchaseQuote."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckPurchaseQuoteStatistics(PurchaseQuote);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure QuoteMakeOrderWithDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        AnswerYesToAllConfirmDialogs();
        LibraryVariableStorage.Enqueue(QuoteMsg);
        PurchaseQuote.MakeOrder.Invoke();

        Clear(PurchaseHeader);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure QuoteMakeOrderWithDisAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        AnswerYesToAllConfirmDialogs();
        LibraryVariableStorage.Enqueue(QuoteMsg);
        PurchaseQuote.MakeOrder.Invoke();

        Clear(PurchaseHeader);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure QuoteMakeOrderWithDiscountPrecentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        AnswerYesToAllConfirmDialogs();
        LibraryVariableStorage.Enqueue(QuoteMsg);
        PurchaseQuote.MakeOrder.Invoke();

        Clear(PurchaseHeader);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure QuoteMakeOrderWithDiscountPercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        AnswerYesToAllConfirmDialogs();
        LibraryVariableStorage.Enqueue(QuoteMsg);
        PurchaseQuote.MakeOrder.Invoke();

        Clear(PurchaseHeader);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteSetLocalCurrencySignOnTotals()
    var
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        Initialize();

        CreateVendor(Vendor);
        Vendor."Currency Code" := GetDifferentCurrencyCode();
        Vendor.Modify(true);
        PurchaseQuote.OpenNew();

        PurchaseQuote."Buy-from Vendor Name".SetValue(Vendor."No.");
        QuoteCheckCurrencyOnTotals(PurchaseQuote, Vendor."Currency Code");

        PurchaseQuote.PurchLines.New();
        QuoteCheckCurrencyOnTotals(PurchaseQuote, Vendor."Currency Code");

        PurchaseQuote.PurchLines.Description.SetValue(ItemTestDescriptionLbl);
        QuoteCheckCurrencyOnTotals(PurchaseQuote, Vendor."Currency Code");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteApplyManualDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        SetAllowManualDisc();

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseQuote.CalculateInvoiceDiscount.Invoke();
        CheckQuoteStatistics(PurchaseQuote);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteApplyManualDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        SetAllowManualDisc();

        CreateQuoteWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseQuote.CalculateInvoiceDiscount.Invoke();
        CheckPurchaseQuoteStatistics(PurchaseQuote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteUnitofMeasureCodeNotEditableWhenItemHasSingleUOM()
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [Purchase Quote]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 97 "Purchase Quote Subform" is editable for an Item that has only one Unit of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base Unit of Measure.
        // [GIVEN] Purchase Quote with one line containing Item "I".
        CreateQuoteThroughTestPageForItemWithGivenNumberOfUOMs(PurchaseQuote, 0);

        // [WHEN] Find the Purchase Line.
        PurchaseQuote.PurchLines.First();

        // [THEN] "Unit of Measure Code" field is not editable.
        Assert.IsTrue(PurchaseQuote.PurchLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsEditableMsg);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateBlanketOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, BlanketPurchaseOrder);

        CheckBlanketOrderStatistics(BlanketPurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderAddingLinesUpdatesTotalsStats()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateBlanketOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, BlanketPurchaseOrder);

        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateBlanketOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, BlanketPurchaseOrder);

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketPurchaseOrder);
        CheckBlanketOrderStatistics(BlanketPurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscTypeIsPercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateBlanketOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, BlanketPurchaseOrder);

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketPurchaseOrder);
        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateBlanketOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        BlanketPurchaseOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.First();
        CheckBlanketOrderStatistics(BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines."Line Amount".SetValue(
          Round(BlanketPurchaseOrder.PurchLines."Line Amount".AsDecimal() / 2, 1));
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.First();
        CheckBlanketOrderStatistics(BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines."Line Discount %".SetValue('0');
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.First();
        CheckBlanketOrderStatistics(BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines."No.".SetValue('');
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.First();

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketPurchaseOrder);
        CheckBlanketOrderStatistics(BlanketPurchaseOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Blanket Order");
        PurchaseLine.SetRange("Document No.", BlanketPurchaseOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyingLineUpdatesTotalsAndInvoiceDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateBlanketOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        BlanketPurchaseOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.First();
        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines."Line Amount".SetValue(
          Round(BlanketPurchaseOrder.PurchLines."Line Amount".AsDecimal() / 2, 1));
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.First();
        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines."Line Discount %".SetValue('0');
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.First();
        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines."No.".SetValue('');
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.First();

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketPurchaseOrder);
        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Blanket Order");
        PurchaseLine.SetRange("Document No.", BlanketPurchaseOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateBlanketOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        BlanketPurchaseOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        BlanketPurchaseOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.First();

        CheckBlanketOrderStatistics(BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckBlanketOrderStatistics(BlanketPurchaseOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Blanket Order");
        PurchaseLine.SetRange("Document No.", BlanketPurchaseOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmtToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateBlanketOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        BlanketPurchaseOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        BlanketPurchaseOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.First();

        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);

        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Blanket Order");
        PurchaseLine.SetRange("Document No.", BlanketPurchaseOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderChangingSellToVendorToVendorWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        AnswerYesToAllConfirmDialogs();
        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        BlanketPurchaseOrder.PurchLines.Next();

        CheckBlanketOrderStatistics(BlanketPurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderChangingSellToVendorToVendorWithoutDiscountsSetDiscAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        AnswerYesToAllConfirmDialogs();
        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        BlanketPurchaseOrder.PurchLines.Next();

        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketPurchaseOrder);
        CheckBlanketOrderStatistics(BlanketPurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketPurchOrderDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketPurchaseOrder);
        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);
        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckBlanketOrderStatistics(BlanketPurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderDiscTypeAmountIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);
        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderChangingSellToVendorRecalculatesForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        AnswerYesToAllConfirmDialogs();

        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        BlanketPurchaseOrder.PurchLines.Next();

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketPurchaseOrder);
        CheckBlanketOrderStatistics(BlanketPurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderChangingSellToVendorRecalculatesForInvoiceDiscTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        AnswerYesToAllConfirmDialogs();

        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        BlanketPurchaseOrder.PurchLines.Next();

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketPurchaseOrder);
        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderChangingSellToVendorSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);
        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        BlanketPurchaseOrder.PurchLines.Next();

        CheckBlanketOrderStatistics(BlanketPurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderChangingSellToVendorSetsDiscountToZeroForInvoiceDisTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);
        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        BlanketPurchaseOrder.PurchLines.Next();

        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        AnswerYesToConfirmDialog();
        BlanketPurchaseOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketPurchaseOrder);
        CheckBlanketOrderStatistics(BlanketPurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        AnswerYesToConfirmDialog();
        BlanketPurchaseOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketPurchaseOrder);
        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);
        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        BlanketPurchaseOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckBlanketOrderStatistics(BlanketPurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);
        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        BlanketPurchaseOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler,BlanketOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderMakeOrderWithDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        AnswerYesToAllConfirmDialogs();
        LibraryVariableStorage.Enqueue(BlanketMsg);
        BlanketPurchaseOrder.MakeOrder.Invoke();

        Clear(PurchaseHeader);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler,BlanketOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderMakeOrderWithDiscAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PurchaseOrder: TestPage "Purchase Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        AnswerYesToAllConfirmDialogs();
        LibraryVariableStorage.Enqueue(BlanketMsg);
        BlanketPurchaseOrder.MakeOrder.Invoke();

        Clear(PurchaseHeader);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler,BlanketOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderMakeOrderWithDiscountPrecentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        AnswerYesToAllConfirmDialogs();
        LibraryVariableStorage.Enqueue(BlanketMsg);
        BlanketPurchaseOrder.MakeOrder.Invoke();

        Clear(PurchaseHeader);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        CheckOrderStatistics(PurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler,BlanketOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderMakeOrderWithDiscPrecentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        AnswerYesToAllConfirmDialogs();
        LibraryVariableStorage.Enqueue(BlanketMsg);
        BlanketPurchaseOrder.MakeOrder.Invoke();

        Clear(PurchaseHeader);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        CheckPurchaseOrderStatistics(PurchaseOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderSetLocalCurrencySignOnTotals()
    var
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        Initialize();

        CreateVendor(Vendor);
        Vendor."Currency Code" := GetDifferentCurrencyCode();
        Vendor.Modify(true);
        BlanketPurchaseOrder.OpenNew();

        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(Vendor."No.");
        BlanketPurchaseOrderCheckCurrencyOnTotals(BlanketPurchaseOrder, Vendor."Currency Code");

        BlanketPurchaseOrder.PurchLines.New();
        BlanketPurchaseOrderCheckCurrencyOnTotals(BlanketPurchaseOrder, Vendor."Currency Code");

        BlanketPurchaseOrder.PurchLines.Description.SetValue(ItemTestDescriptionLbl);
        BlanketPurchaseOrderCheckCurrencyOnTotals(BlanketPurchaseOrder, Vendor."Currency Code");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderApplyManualDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        SetAllowManualDisc();

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        BlanketPurchaseOrder.CalculateInvoiceDiscount.Invoke();
        CheckBlanketOrderStatistics(BlanketPurchaseOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderApplyManualDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        SetAllowManualDisc();

        CreateBlanketOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        BlanketPurchaseOrder.CalculateInvoiceDiscount.Invoke();
        CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateReturnOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseReturnOrder);

        CheckReturnOrderStatistics(PurchaseReturnOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnPurchOrderAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ItemQuantity: Decimal;
        ItemLastDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemLastDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemLastDirectCost);

        CreateReturnOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseReturnOrder);

        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateReturnOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseReturnOrder);

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(PurchaseReturnOrder);
        CheckReturnOrderStatistics(PurchaseReturnOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscTypeIsPercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateReturnOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseReturnOrder);

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(PurchaseReturnOrder);
        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateReturnOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.First();
        CheckReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines."Line Amount".SetValue(
          Round(PurchaseReturnOrder.PurchLines."Line Amount".AsDecimal() / 2, 1));
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.First();
        CheckReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines."Line Discount %".SetValue('0');
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.First();
        CheckReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines."No.".SetValue('');
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.First();

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(PurchaseReturnOrder);
        CheckReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.SetRange("Document No.", PurchaseReturnOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyingLineUpdatesTotalsAndInvDiscTypePercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateReturnOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.First();
        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines."Line Amount".SetValue(
          Round(PurchaseReturnOrder.PurchLines."Line Amount".AsDecimal() / 2, 1));
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.First();
        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines."Line Discount %".SetValue('0');
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.First();
        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines."No.".SetValue('');
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.First();

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(PurchaseReturnOrder);
        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.SetRange("Document No.", PurchaseReturnOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateReturnOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        PurchaseReturnOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.First();

        CheckReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.SetRange("Document No.", PurchaseReturnOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmtToZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateReturnOrderWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        PurchaseReturnOrder.PurchLines.First();
        ItemQuantity := ItemQuantity * 2;
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(ItemQuantity);
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.First();

        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.SetRange("Document No.", PurchaseReturnOrder."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangingSellToVendorToVendorWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);

        AnswerYesToAllConfirmDialogs();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseReturnOrder.PurchLines.Next();

        CheckReturnOrderStatistics(PurchaseReturnOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangingSellToVendorToVendorWithoutDiscountsSetDiscAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateVendor(NewVendor);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);

        AnswerYesToAllConfirmDialogs();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseReturnOrder.PurchLines.Next();

        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(PurchaseReturnOrder);
        CheckReturnOrderStatistics(PurchaseReturnOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderDiscountTypePercIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(PurchaseReturnOrder);
        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);
        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckReturnOrderStatistics(PurchaseReturnOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderDiscTypeAmountIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);
        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangingSellToVendorRecalculatesForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);

        AnswerYesToAllConfirmDialogs();

        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseReturnOrder.PurchLines.Next();

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(PurchaseReturnOrder);
        CheckReturnOrderStatistics(PurchaseReturnOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangingSellToVendorRecalculatesForInvoiceDiscountTypePerc()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);

        AnswerYesToAllConfirmDialogs();

        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseReturnOrder.PurchLines.Next();

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(PurchaseReturnOrder);
        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);
    end;


#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangingSellToVendorSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);
        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseReturnOrder.PurchLines.Next();

        CheckReturnOrderStatistics(PurchaseReturnOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangingSellToVendorSetsDiscountToZeroForInvoiceDiscTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);
        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(NewVendor."No.");
        PurchaseReturnOrder.PurchLines.Next();

        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);

        AnswerYesToConfirmDialog();
        PurchaseReturnOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(PurchaseReturnOrder);
        CheckReturnOrderStatistics(PurchaseReturnOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePerc()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);

        AnswerYesToConfirmDialog();
        PurchaseReturnOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(PurchaseReturnOrder);
        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);
        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        PurchaseReturnOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckReturnOrderStatistics(PurchaseReturnOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);
        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        PurchaseReturnOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOrderPostPurchaseInvoiceWithDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);

        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        PostedPurchaseCreditMemo.OpenEdit();
        PostedPurchaseCreditMemo.GotoRecord(PurchCrMemoHdr);

        CheckPostedCreditMemoStatistics(PostedPurchaseCreditMemo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOrderPostPurchaseInvoiceWithDiscountPrecentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        PostedPurchaseCreditMemo.OpenEdit();
        PostedPurchaseCreditMemo.GotoRecord(PurchCrMemoHdr);

        CheckPostedCreditMemoStatistics(PostedPurchaseCreditMemo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOrderSetLocalCurrencySignOnTotals()
    var
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        Initialize();

        CreateVendor(Vendor);
        Vendor."Currency Code" := GetDifferentCurrencyCode();
        Vendor.Modify(true);
        PurchaseReturnOrder.OpenNew();

        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(Vendor."No.");
        ReturnOrderCheckCurrencyOnTotals(PurchaseReturnOrder, Vendor."Currency Code");

        PurchaseReturnOrder.PurchLines.New();
        ReturnOrderCheckCurrencyOnTotals(PurchaseReturnOrder, Vendor."Currency Code");

        PurchaseReturnOrder.PurchLines.Description.SetValue(ItemTestDescriptionLbl);
        ReturnOrderCheckCurrencyOnTotals(PurchaseReturnOrder, Vendor."Currency Code");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderApplyManualDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        SetAllowManualDisc();

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseReturnOrder.CalculateInvoiceDiscount.Invoke();
        CheckReturnOrderStatistics(PurchaseReturnOrder);
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderApplyManualDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        SetAllowManualDisc();

        CreateReturnOrderWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseReturnOrder.CalculateInvoiceDiscount.Invoke();
        CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DimensionSetTreeNodeOnCalculatingTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        DimSetTreeNode: Record "Dimension Set Tree Node";
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        GLAccountNo: Code[20];
        ItemQuantity: Decimal;
        DimValueID: Integer;
    begin
        // [FEATURE] [Totals] [Dimension]
        // [SCENARIO 376946] No Dimension Set Tree Node should be created on calculating Totals
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);

        // [GIVEN] Purchase Credit Memo with Invoice Discount but not Dimensions
        GLAccountNo := CreateGLAccountForInvoiceRounding(Vendor."Vendor Posting Group");

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.FindFirst();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Default Dimension "D" on invoice rounding G/L Account
        DimValueID := CreateDimOnGLAccount(GLAccountNo);

        // [WHEN] Calculate Totals by Open Purchase Credit Memo Page
        PurchaseCreditMemo.Close();
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.Close();

        // [THEN] No Dimension Set Tree Node is created for "D"
        DimSetTreeNode.Init(); // PreCAL trick
        DimSetTreeNode.SetRange("Dimension Value ID", DimValueID);
        Assert.RecordIsEmpty(DimSetTreeNode);
    end;

    [Test]
    [HandlerFunctions('ItemUnitofMeasureModalHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLineUnitofMeasureCodeLookupItem()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
        BaseUOMCode: Code[10];
        AdditionalUOMCode: Code[10];
    begin
        // [FEATURE] [UT] [Unit of Measure]
        // [SCENARIO 161627] Lookup is active for "Unit of Measure Code" field for an Item that has multiple Units of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base and several additional Units of Measure.
        // [GIVEN] Purchase Document with one line containing Item "I".
        CreatePurchaseDocumentForItemWithGivenNumberOfUOMs(PurchaseLine, LibraryRandom.RandIntInRange(2, 5));
        BaseUOMCode := PurchaseLine."Unit of Measure Code";
        AdditionalUOMCode := FindFirstAdditionalItemUOMCode(PurchaseLine."No.", BaseUOMCode);

        // [WHEN] Invoke Lookup on "Unit of Measure Code" field. Select additional UOM.
        LibraryVariableStorage.Enqueue(AdditionalUOMCode);
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoKey(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseQuote.PurchLines."Unit of Measure Code".Lookup();
        PurchaseQuote.Close();

        // [THEN] Lookup is available. Unit of Measure Code is changed.
        PurchaseLine.Find();
        PurchaseLine.TestField("Unit of Measure Code", AdditionalUOMCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeclineConfirmationOnChangingInvDiscountAmountInPurchOrderWithPostedLine()
    var
        PurchaseHeaderNo: Code[20];
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 208219] When a line of Purchase Order is posted and "Inv. Discount Amount" is updated at subpage, then confirmation appears. If confirmation is declined, then "Inv. Discount Amount" is not changed.

        Initialize();

        // [GIVEN] Purchase Order with 2 lines
        // [GIVEN] Purchase Line 1 has "Qty. to Ship" = "Qty. to Invoice" = "Quantity"
        // [GIVEN] Purchase Line 2 has "Qty. to Receive" = "Qty. to Invoice" = 0
        // [GIVEN] Purchase Line 1 is posted
        PurchaseHeaderNo := CreatePurchOrderAndPostOneOfTwoLines();

        // [GIVEN] "Inv. Discount Amount" is updated in Purchase Order Subform
        LibraryVariableStorage.Enqueue(UpdateInvDiscountQst);
        LibraryVariableStorage.Enqueue(false);
        SetInvDiscAmountInPurchOrderSubPage(PurchaseHeaderNo);

        // [GIVEN] Confirmation appears: "One or more lines have been invoiced. The discount distributed to invoiced lines will not be taken into account.\\Do you want to update the invoice discount?"
        // Message check is performed in Confirm handler

        // [WHEN] Confirmation declined
        // FALSE is passed to Confirm handler

        // [THEN] "Inv. Discount Amount" is not changed
        VerifyInvDiscAmountInPurchOrderSubpage(PurchaseHeaderNo, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AceptConfirmationOnChangingInvDiscountAmountInPurchOrderWithPostedLine()
    var
        InvDiscountAmount: Integer;
        PurchaseHeaderNo: Code[20];
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 208219] When a line of Purchase Order is posted and "Inv. Discount Amount" is updated at subpage, then confirmation appears. If confirmation is acepted, then "Inv. Discount Amount" is changed.

        Initialize();

        // [GIVEN] Purchase Order with 2 lines
        // [GIVEN] Purchase Line 1 has "Qty. to Ship" = "Qty. to Invoice" = "Quantity"
        // [GIVEN] Purchase Line 2 has "Qty. to Receive" = "Qty. to Invoice" = 0
        // [GIVEN] Purchase Line 1 is posted
        PurchaseHeaderNo := CreatePurchOrderAndPostOneOfTwoLines();

        // [GIVEN] "Inv. Discount Amount" is updated in Purchase Order Subform
        LibraryVariableStorage.Enqueue(UpdateInvDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        InvDiscountAmount := SetInvDiscAmountInPurchOrderSubPage(PurchaseHeaderNo);

        // [GIVEN] Confirmation appears: "One or more lines have been invoiced. The discount distributed to invoiced lines will not be taken into account.\\Do you want to update the invoice discount?"
        // Message check is performed in Confirm handler

        // [WHEN] Confirmation acepted
        // TRUE is passed to Confirm handler

        // [THEN] "Inv. Discount Amount" is changed
        VerifyInvDiscAmountInPurchOrderSubpage(PurchaseHeaderNo, InvDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoConfirmationOnChangingInvDiscountAmountInPurchOrderWithoutPostedLines()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InvDiscountAmount: Integer;
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 208219] When a line of Purchase Order is posted and "Inv. Discount Amount" is updated at subpage, then confirmation appears

        Initialize();

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line
        CreateItem(Item, LibraryRandom.RandIntInRange(100, 1000));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        // [WHEN] "Inv. Discount Amount" is updated in Purchase Order Subform
        InvDiscountAmount := SetInvDiscAmountInPurchOrderSubPage(PurchaseHeader."No.");

        // [THEN] No confirmation appears and "Inv. Discount Amount" is changed
        // No Confirm handler is risen
        VerifyInvDiscAmountInPurchOrderSubpage(PurchaseHeader."No.", InvDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceSubformTotalAmountsWithBlankCurrencyCaption()
    var
        PurchaseHeader: Record "Purchase Header";
        GLSetup: Record "General Ledger Setup";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Invoice]
        // [SCENARIO 217135] Currency Captions in Purchase Invoice Subform is set to defult value if Purchase Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Purchase Invoice "PI" with Currency Code "CC"
        CurrencyCode := CreatePurchaseHeaderWithCurrencyCode(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Subform with "CC" in Total Amount Captions
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        CheckPurchaseInvoiceSubformTotalAmountCaptions(PurchaseInvoicePage, CurrencyCode);
        PurchaseInvoicePage.Close();

        // [GIVEN] "PI" Currency Code set to blank
        PurchaseHeader.Validate("Currency Code", '');
        PurchaseHeader.Modify(true);

        // [WHEN] Open Purchase Invoice Subform
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckPurchaseInvoiceSubformTotalAmountCaptions(PurchaseInvoicePage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderSubformTotalAmountsWithBlankCurrencyCaption()
    var
        PurchaseHeader: Record "Purchase Header";
        GLSetup: Record "General Ledger Setup";
        PurchaseOrderPage: TestPage "Purchase Order";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Order]
        // [SCENARIO 217135] Currency Captions in Purchase Order Subform is set to defult value if Purchase Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Purchase Order "PO" with Currency Code "CC"
        CurrencyCode := CreatePurchaseHeaderWithCurrencyCode(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // [GIVEN] Purchase Order Subform with "CC" in Total Amount Captions
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        CheckPurchaseOrderSubformTotalAmountCaptions(PurchaseOrderPage, CurrencyCode);
        PurchaseOrderPage.Close();

        // [GIVEN] "PO" Currency Code set to blank
        PurchaseHeader.Validate("Currency Code", '');
        PurchaseHeader.Modify(true);

        // [WHEN] Open Purchase Order Subform
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckPurchaseOrderSubformTotalAmountCaptions(PurchaseOrderPage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoSubformTotalAmountsWithBlankCurrencyCaption()
    var
        PurchaseHeader: Record "Purchase Header";
        GLSetup: Record "General Ledger Setup";
        PurchaseCreditMemoPage: TestPage "Purchase Credit Memo";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Credit Memo]
        // [SCENARIO 217135] Currency Captions in Purchase Credit Memo Subform is set to defult value if Purchase Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Purchase Credit Memo "PCM" with Currency Code "CC"
        CurrencyCode := CreatePurchaseHeaderWithCurrencyCode(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        // [GIVEN] Purchase Credit Memo Subform with "CC" in Total Amount Captions
        PurchaseCreditMemoPage.OpenEdit();
        PurchaseCreditMemoPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        CheckPurchaseCreditMemoSubformTotalAmountCaptions(PurchaseCreditMemoPage, CurrencyCode);
        PurchaseCreditMemoPage.Close();

        // [GIVEN] "PCM" Currency Code set to blank
        PurchaseHeader.Validate("Currency Code", '');
        PurchaseHeader.Modify(true);

        // [WHEN] Open Purchase Credit Memo Subform
        PurchaseCreditMemoPage.OpenEdit();
        PurchaseCreditMemoPage.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckPurchaseCreditMemoSubformTotalAmountCaptions(PurchaseCreditMemoPage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteSubformTotalAmountsWithBlankCurrencyCaption()
    var
        PurchaseHeader: Record "Purchase Header";
        GLSetup: Record "General Ledger Setup";
        PurchaseQuotePage: TestPage "Purchase Quote";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Quote]
        // [SCENARIO 217135] Currency Captions in Purchase Quote Subform is set to defult value if Purchase Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Purchase Quote "PQ" with Currency Code "CC"
        CurrencyCode := CreatePurchaseHeaderWithCurrencyCode(PurchaseHeader, PurchaseHeader."Document Type"::Quote);

        // [GIVEN] Purchase Quote Subform with "CC" in Total Amount Captions
        PurchaseQuotePage.OpenEdit();
        PurchaseQuotePage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        CheckPurchaseQuoteSubformTotalAmountCaptions(PurchaseQuotePage, CurrencyCode);
        PurchaseQuotePage.Close();

        // [GIVEN] "PQ" Currency Code set to blank
        PurchaseHeader.Validate("Currency Code", '');
        PurchaseHeader.Modify(true);

        // [WHEN] Open Purchase Quote Subform
        PurchaseQuotePage.OpenEdit();
        PurchaseQuotePage.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckPurchaseQuoteSubformTotalAmountCaptions(PurchaseQuotePage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderSubformTotalAmountsWithBlankCurrencyCaption()
    var
        PurchaseHeader: Record "Purchase Header";
        GLSetup: Record "General Ledger Setup";
        BlanketPurchaseOrderPage: TestPage "Blanket Purchase Order";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Blanket Order]
        // [SCENARIO 217135] Currency Captions in Blanket Purchase Order Subform is set to defult value if Purchase Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Blanket Purchase Order "BPO" with Currency Code "CC"
        CurrencyCode := CreatePurchaseHeaderWithCurrencyCode(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order");

        // [GIVEN] Blanket Purchase Order Subform with "CC" in Total Amount Captions
        BlanketPurchaseOrderPage.OpenEdit();
        BlanketPurchaseOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        CheckBlanketPurchaseOrderSubformTotalAmountCaptions(BlanketPurchaseOrderPage, CurrencyCode);
        BlanketPurchaseOrderPage.Close();

        // [GIVEN] "BPO" Currency Code set to blank
        PurchaseHeader.Validate("Currency Code", '');
        PurchaseHeader.Modify(true);

        // [WHEN] Open Blanket Purchase Order Subform
        BlanketPurchaseOrderPage.OpenEdit();
        BlanketPurchaseOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckBlanketPurchaseOrderSubformTotalAmountCaptions(BlanketPurchaseOrderPage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReturnQtyShippedIsNotEditable()
    var
        RPOSPage: TestPage "Purchase Return Order Subform";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 274634] The Return Qty Shipped field of Return Purchase Order Subform cannot be edited by user
        Initialize();
        RPOSPage.OpenEdit();
        Assert.IsFalse(RPOSPage."Return Qty. Shipped".Editable(), 'Return Qty. Shipped field must be not editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderSubformTotalAmountsWithBlankCurrencyCaption()
    var
        PurchaseHeader: Record "Purchase Header";
        GLSetup: Record "General Ledger Setup";
        PurchaseReturnOrderPage: TestPage "Purchase Return Order";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Return Order]
        // [SCENARIO 217135] Currency Captions in Purchase Return Order Subform is set to defult value if Purchase Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Purchase Return Order "PRO" with Currency Code "CC"
        CurrencyCode := CreatePurchaseHeaderWithCurrencyCode(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        // [GIVEN] Purchase Return Order Subform with "CC" in Total Amount Captions
        PurchaseReturnOrderPage.OpenEdit();
        PurchaseReturnOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        CheckPurchaseReturnOrderSubformTotalAmountCaptions(PurchaseReturnOrderPage, CurrencyCode);
        PurchaseReturnOrderPage.Close();

        // [GIVEN] "PRO" Currency Code set to blank
        PurchaseHeader.Validate("Currency Code", '');
        PurchaseHeader.Modify(true);

        // [WHEN] Open Purchase Return Order Subform
        PurchaseReturnOrderPage.OpenEdit();
        PurchaseReturnOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckPurchaseReturnOrderSubformTotalAmountCaptions(PurchaseReturnOrderPage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchQuoteSubformFieldsEditabilityWithTypeItemAndBlankNumber()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI] [Quote]
        // [SCENARIO 281160] Major purchase quote subform fields are not editable when Type = Item and No. = ''
        Initialize();

        // [GIVEN] Open New Purchase quote page and pick new customer
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item and blank "No."
        PurchaseQuote.PurchLines.New();
        PurchaseQuote.PurchLines.Type.SetValue(PurchaseLine.Type::Item);

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are non editable
        // TFS ID: 339141 Fields remain editable to keep Quick Entry feature functionable
        Assert.IsTrue(
          PurchaseQuote.PurchLines.Quantity.Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName(Quantity)));
        Assert.IsTrue(
          PurchaseQuote.PurchLines."Location Code".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Location Code")));
        Assert.IsTrue(
          PurchaseQuote.PurchLines."Direct Unit Cost".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Direct Unit Cost")));
        Assert.IsTrue(
          PurchaseQuote.PurchLines."Line Discount %".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          PurchaseQuote.PurchLines."Line Amount".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchQuoteSubformFieldsEditabilityWithTypeItemAndNotBlankNumber()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI] [Quote]
        // [SCENARIO 281160] Major purchase quote subform fields are editable when Type = Item and No. <> ''
        Initialize();

        // [GIVEN] Open New Purchase quote page and pick new customer
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item
        PurchaseQuote.PurchLines.New();
        PurchaseQuote.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseQuote.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are editable
        Assert.IsTrue(
          PurchaseQuote.PurchLines.Quantity.Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName(Quantity)));
        Assert.IsTrue(
          PurchaseQuote.PurchLines."Location Code".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Location Code")));
        Assert.IsTrue(
          PurchaseQuote.PurchLines."Direct Unit Cost".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Direct Unit Cost")));
        Assert.IsTrue(
          PurchaseQuote.PurchLines."Line Discount %".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          PurchaseQuote.PurchLines."Line Amount".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceSubformFieldsEditabilityWithTypeItemAndBlankNumber()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI] [Invoice]
        // [SCENARIO 281160] Major purchase invoice subform fields are not editable when Type = Item and No. = ''
        Initialize();

        // [GIVEN] Open New Purchase invoice page and pick new customer
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item and blank "No."
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseLine.Type::Item);

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are non editable
        // TFS ID: 339141 Fields remain editable to keep Quick Entry feature functionable
        Assert.IsTrue(
          PurchaseInvoice.PurchLines.Quantity.Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName(Quantity)));
        Assert.IsTrue(
          PurchaseInvoice.PurchLines."Location Code".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Location Code")));
        Assert.IsTrue(
          PurchaseInvoice.PurchLines."Direct Unit Cost".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Direct Unit Cost")));
        Assert.IsTrue(
          PurchaseInvoice.PurchLines."Line Discount %".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          PurchaseInvoice.PurchLines."Line Amount".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceSubformFieldsEditabilityWithTypeItemAndNotBlankNumber()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI] [Invoice]
        // [SCENARIO 281160] Major purchase invoice subform fields are editable when Type = Item and No. <> ''
        Initialize();

        // [GIVEN] Open New Purchase invoice page and pick new customer
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseInvoice.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are editable
        Assert.IsTrue(
          PurchaseInvoice.PurchLines.Quantity.Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName(Quantity)));
        Assert.IsTrue(
          PurchaseInvoice.PurchLines."Location Code".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Location Code")));
        Assert.IsTrue(
          PurchaseInvoice.PurchLines."Direct Unit Cost".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Direct Unit Cost")));
        Assert.IsTrue(
          PurchaseInvoice.PurchLines."Line Discount %".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          PurchaseInvoice.PurchLines."Line Amount".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderSubformFieldsEditabilityWithTypeItemAndBlankNumber()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Order]
        // [SCENARIO 281160] Major purchase order subform fields are not editable when Type = Item and No. = ''
        Initialize();

        // [GIVEN] Open New Purchase order page and pick new customer
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item and blank "No."
        PurchaseOrder.PurchLines.New();
        PurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);

        // [THEN] Fields Quantity, Location Code, Unit Price and Line Amount are non editable
        // TFS ID: 339141 Fields remain editable to keep Quick Entry feature functionable
        Assert.IsTrue(
          PurchaseOrder.PurchLines.Quantity.Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName(Quantity)));
        Assert.IsTrue(
          PurchaseOrder.PurchLines."Location Code".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Location Code")));
        Assert.IsTrue(
          PurchaseOrder.PurchLines."Direct Unit Cost".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Direct Unit Cost")));
        Assert.IsTrue(
          PurchaseOrder.PurchLines."Line Amount".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderSubformFieldsEditabilityWithTypeItemAndNotBlankNumber()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Order]
        // [SCENARIO 281160] Major purchase order subform fields are editable when Type = Item and No. <> ''
        Initialize();

        // [GIVEN] Open New Purchase order page and pick new customer
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item
        PurchaseOrder.PurchLines.New();
        PurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseOrder.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] Fields Quantity, Location Code, Unit Price and Line Amount are editable
        Assert.IsTrue(
          PurchaseOrder.PurchLines.Quantity.Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName(Quantity)));
        Assert.IsTrue(
          PurchaseOrder.PurchLines."Location Code".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Location Code")));
        Assert.IsTrue(
          PurchaseOrder.PurchLines."Direct Unit Cost".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Direct Unit Cost")));
        Assert.IsTrue(
          PurchaseOrder.PurchLines."Line Amount".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoSubformFieldsEditabilityWithTypeItemAndBlankNumber()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI] [Credit Memo]
        // [SCENARIO 281160] Major purchase credit memo subform fields are not editable when Type = Item and No. = ''
        Initialize();

        // [GIVEN] Open New Purchase credit memo page and pick new customer
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item and blank "No."
        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines.Type.SetValue(PurchaseLine.Type::Item);

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are non editable
        // TFS ID: 339141 Fields remain editable to keep Quick Entry feature functionable
        Assert.IsTrue(
          PurchaseCreditMemo.PurchLines.Quantity.Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName(Quantity)));
        Assert.IsTrue(
          PurchaseCreditMemo.PurchLines."Location Code".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Location Code")));
        Assert.IsTrue(
          PurchaseCreditMemo.PurchLines."Direct Unit Cost".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Direct Unit Cost")));
        Assert.IsTrue(
          PurchaseCreditMemo.PurchLines."Line Discount %".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          PurchaseCreditMemo.PurchLines."Line Amount".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoSubformFieldsEditabilityWithTypeItemAndNotBlankNumber()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI] [Credit Memo]
        // [SCENARIO 281160] Major purchase credit memo subform fields are editable when Type = Item and No. <> ''
        Initialize();

        // [GIVEN] Open New Purchase credit memo page and pick new customer
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item
        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseCreditMemo.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are editable
        Assert.IsTrue(
          PurchaseCreditMemo.PurchLines.Quantity.Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName(Quantity)));
        Assert.IsTrue(
          PurchaseCreditMemo.PurchLines."Location Code".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Location Code")));
        Assert.IsTrue(
          PurchaseCreditMemo.PurchLines."Direct Unit Cost".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Direct Unit Cost")));
        Assert.IsTrue(
          PurchaseCreditMemo.PurchLines."Line Discount %".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          PurchaseCreditMemo.PurchLines."Line Amount".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderSubformFieldsEditabilityWithTypeItemAndBlankNumber()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [UI] [Return Order]
        // [SCENARIO 281160] Major purchase return order subform fields are not editable when Type = Item and No. = ''
        Initialize();

        // [GIVEN] Open New Purchase return order page and pick new customer
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item and blank "No."
        PurchaseReturnOrder.PurchLines.New();
        PurchaseReturnOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are non editable
        // TFS ID: 339141 Fields remain editable to keep Quick Entry feature functionable
        Assert.IsTrue(
          PurchaseReturnOrder.PurchLines.Quantity.Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName(Quantity)));
        Assert.IsTrue(
          PurchaseReturnOrder.PurchLines."Location Code".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Location Code")));
        Assert.IsTrue(
          PurchaseReturnOrder.PurchLines."Direct Unit Cost".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Direct Unit Cost")));
        Assert.IsTrue(
          PurchaseReturnOrder.PurchLines."Line Discount %".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          PurchaseReturnOrder.PurchLines."Line Amount".Editable(),
          StrSubstNo(NotEditableErr, PurchaseLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderSubformFieldsEditabilityWithTypeItemAndNotBlankNumber()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [UI] [Return Order]
        // [SCENARIO 281160] Major purchase return order subform fields are editable when Type = Item and No. <> ''
        Initialize();

        // [GIVEN] Open New Purchase return order page and pick new customer
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item
        PurchaseReturnOrder.PurchLines.New();
        PurchaseReturnOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseReturnOrder.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are editable
        Assert.IsTrue(
          PurchaseReturnOrder.PurchLines.Quantity.Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName(Quantity)));
        Assert.IsTrue(
          PurchaseReturnOrder.PurchLines."Location Code".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Location Code")));
        Assert.IsTrue(
          PurchaseReturnOrder.PurchLines."Direct Unit Cost".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Direct Unit Cost")));
        Assert.IsTrue(
          PurchaseReturnOrder.PurchLines."Line Discount %".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          PurchaseReturnOrder.PurchLines."Line Amount".Editable(),
          StrSubstNo(EditableErr, PurchaseLine.FieldName("Line Amount")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Order_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Order] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Purchase Order page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreatePurchaseDocumentWithCurrency(
          PurchaseHeader, PurchaseLine, Item, CurrencyCode, PurchaseHeader."Document Type"::Order, ExchangeRate);

        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        SetCurrencyOnOrderAndVerify(PurchaseOrder, CurrencyCode, Item, PurchaseLine, ExchangeRate);

        SetCurrencyOnOrderAndVerify(PurchaseOrder, '', Item, PurchaseLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Invoice_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Invoice] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Purchase Invoice page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreatePurchaseDocumentWithCurrency(
          PurchaseHeader, PurchaseLine, Item, CurrencyCode, PurchaseHeader."Document Type"::Invoice, ExchangeRate);

        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        SetCurrencyOnInvoiceAndVerify(PurchaseInvoice, CurrencyCode, Item, PurchaseLine, ExchangeRate);

        SetCurrencyOnInvoiceAndVerify(PurchaseInvoice, '', Item, PurchaseLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Quote_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Quote] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Purchase Quote page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreatePurchaseDocumentWithCurrency(
          PurchaseHeader, PurchaseLine, Item, CurrencyCode, PurchaseHeader."Document Type"::Quote, ExchangeRate);

        OpenPurchaseQuote(PurchaseHeader, PurchaseQuote);

        SetCurrencyOnQuoteAndVerify(PurchaseQuote, CurrencyCode, Item, PurchaseLine, ExchangeRate);

        SetCurrencyOnQuoteAndVerify(PurchaseQuote, '', Item, PurchaseLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemo_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Credit Memo] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Purchase Credit Memo page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreatePurchaseDocumentWithCurrency(
          PurchaseHeader, PurchaseLine, Item, CurrencyCode, PurchaseHeader."Document Type"::"Credit Memo", ExchangeRate);

        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        SetCurrencyOnCreditMemoAndVerify(PurchaseCreditMemo, CurrencyCode, Item, PurchaseLine, ExchangeRate);

        SetCurrencyOnCreditMemoAndVerify(PurchaseCreditMemo, '', Item, PurchaseLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrder_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Return Order] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Purchase Return Order page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreatePurchaseDocumentWithCurrency(
          PurchaseHeader, PurchaseLine, Item, CurrencyCode, PurchaseHeader."Document Type"::"Return Order", ExchangeRate);

        OpenReturnOrder(PurchaseHeader, PurchaseReturnOrder);

        SetCurrencyOnReturnOrderAndVerify(PurchaseReturnOrder, CurrencyCode, Item, PurchaseLine, ExchangeRate);

        SetCurrencyOnReturnOrderAndVerify(PurchaseReturnOrder, '', Item, PurchaseLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrder_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Blanket Order] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Blanket Purchase Order page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreatePurchaseDocumentWithCurrency(
          PurchaseHeader, PurchaseLine, Item, CurrencyCode, PurchaseHeader."Document Type"::"Blanket Order", ExchangeRate);

        OpenBlanketPurchaseOrder(PurchaseHeader, BlanketPurchaseOrder);

        SetCurrencyOnBlanketOrderAndVerify(BlanketPurchaseOrder, CurrencyCode, Item, PurchaseLine, ExchangeRate);

        SetCurrencyOnBlanketOrderAndVerify(BlanketPurchaseOrder, '', Item, PurchaseLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseLineVATCaptionOnChangeBuyFromVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Caption] [UT]
        // [SCENARIO 310753] Captions endings of "Direct Unit Cost"/"Line Amount" are changed between "Incl. VAT" and "Excl. VAT" when Buy-from Vendor is changed.
        Initialize();

        // [GIVEN] Purchase Document with Buy-from Vendor "V1", that has "Prices Including VAT" = TRUE.
        // [GIVEN] Fields "Direct Unit Cost"/"Line Amount" of Purchase Line have captions "Direct Unit Cost Incl. VAT"/"Line Amount Incl. VAT".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendorNoPricesIncludingVAT(true));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        Assert.AreEqual('Direct Unit Cost Incl. VAT', PurchaseLine.FieldCaption("Direct Unit Cost"), 'Caption must contain Incl. VAT');
        Assert.AreEqual('Line Amount Incl. VAT', PurchaseLine.FieldCaption("Line Amount"), 'Caption must contain Incl. VAT');

        // [WHEN] Change Buy-from Vendor to "V2", he has "Prices Including VAT" = FALSE.
        PurchaseHeader.Validate("Pay-to Vendor No.", CreateVendorNoPricesIncludingVAT(false));

        // [THEN] Captions of the fields "Direct Unit Cost"/"Line Amount" are updated to "Direct Unit Cost Excl. VAT"/"Line Amount Excl. VAT".
        Assert.AreEqual('Direct Unit Cost Excl. VAT', PurchaseLine.FieldCaption("Direct Unit Cost"), 'Caption must contain Excl. VAT');
        Assert.AreEqual('Line Amount Excl. VAT', PurchaseLine.FieldCaption("Line Amount"), 'Caption must contain Excl. VAT');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseLineVATCaptionOnChangePayToVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Caption] [UT]
        // [SCENARIO 310753] Captions endings of "Direct Unit Cost"/"Line Amount" are changed between "Incl. VAT" and "Excl. VAT" when Pay-to Vendor is changed.
        Initialize();

        // [GIVEN] Purchase Document with Pay-to Vendor "V1", that has "Prices Including VAT" = TRUE.
        // [GIVEN] Fields "Direct Unit Cost"/"Line Amount" of Purchase Line have captions "Direct Unit Cost Incl. VAT"/"Line Amount Incl. VAT".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendorNoPricesIncludingVAT(true));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        Assert.AreEqual('Direct Unit Cost Incl. VAT', PurchaseLine.FieldCaption("Direct Unit Cost"), 'Caption must contain Incl. VAT');
        Assert.AreEqual('Line Amount Incl. VAT', PurchaseLine.FieldCaption("Line Amount"), 'Caption must contain Incl. VAT');

        // [WHEN] Change Pay-to Vendor to "V2", he has "Prices Including VAT" = FALSE.
        PurchaseHeader.Validate("Pay-to Vendor No.", CreateVendorNoPricesIncludingVAT(false));

        // [THEN] Captions of the fields "Direct Unit Cost"/"Line Amount" are updated to "Direct Unit Cost Excl. VAT"/"Line Amount Excl. VAT".
        Assert.AreEqual('Direct Unit Cost Excl. VAT', PurchaseLine.FieldCaption("Direct Unit Cost"), 'Caption must contain Excl. VAT');
        Assert.AreEqual('Line Amount Excl. VAT', PurchaseLine.FieldCaption("Line Amount"), 'Caption must contain Excl. VAT');
    end;

    [Test]
    [HandlerFunctions('ResourceUnitofMeasureModalHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLineUnitofMeasureCodeLookupResource()
    var
        Resource: Record Resource;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        UnitofMeasure: Record "Unit of Measure";
        ResourceUnitofMeasure: Record "Resource Unit of Measure";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Unit of Measure] [Resource]
        // [SCENARIO 289386] Lookup for "Unit of Measure Code" field for a Resource.
        Initialize();

        // [GIVEN] Purchase order with resource
        LibraryResource.CreateResourceNew(Resource);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));
        Assert.IsTrue(Resource."Base Unit of Measure" = PurchaseLine."Unit of Measure Code", 'Wrong unit of measure code in the purchase line');

        // [GIVEN] New resource unit of measure
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitofMeasure, Resource."No.", UnitofMeasure.Code, 1);
        LibraryVariableStorage.Enqueue(ResourceUnitofMeasure.Code);

        // [WHEN] Invoke Lookup on "Unit of Measure Code" field and assign new resource unit of measure code (ResourceUnitofMeasureModalHandler)
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoKey(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseOrder.PurchLines."Unit of Measure Code".Lookup();
        PurchaseOrder.PurchLines.Next();

        // [THEN] Lookup is available. Resource Base Unit of Measure Code is read.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(ResourceUnitofMeasure.Code, PurchaseLine."Unit of Measure Code", 'Wrong unit of measure code in the purchase line after lookup');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DrillingDownQtyToAssignFieldOnWrongTypeDoesNotRollbackPrevChanges()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        Qty: Decimal;
        QtyToReceive: Decimal;
    begin
        // [SCENARIO 366876] Drilling down "Qty. to Assign" field on purchase line of wrong type shows a warning message and does not rollback previous changes.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);
        QtyToReceive := LibraryRandom.RandInt(10);

        // [GIVEN] Purchase order with Item-type line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Modify(true);

        // [GIVEN] Open purchase order page, set "No." = some item, "Quantity" = 20 and go to a next line to save the record.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseOrder.PurchLines.Quantity.SetValue(Qty);
        PurchaseOrder.PurchLines.Next();
        Commit();

        // [GIVEN] Go back to the purchase line and update "Qty. to Receive" = 10.
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(QtyToReceive);

        // [WHEN] Staying on the line, drill down "Qty. to Assign" field.
        LibraryVariableStorage.Enqueue(ItemChargeAssignmentErr);
        PurchaseOrder.PurchLines."Qty. to Assign".DrillDown();
        PurchaseOrder.PurchLines.Next();

        // [THEN] A message is shown that we are capable of drilling down "Qty. to Assign" only on line of Item Charge type.
        // [THEN] The update of "Qty. to Receive" on the purchase line is 10 and saved to database.
        PurchaseLine.Find();
        PurchaseLine.TestField(Quantity, Qty);
        PurchaseLine.TestField("Qty. to Receive", QtyToReceive);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderDefaultLineType()
    var
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType := PurchaseLineType::Resource;
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = "Resource"
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines.FilteredTypeField.AssertEquals(PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderDefaultLineType()
    var
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType := PurchaseLineType::Resource;
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        BlanketPurchaseOrder.OpenNew();
        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = "Resource"
        BlanketPurchaseOrder.PurchLines.First();
        BlanketPurchaseOrder.PurchLines.Type.AssertEquals(PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceDefaultLineType()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType := PurchaseLineType::Resource;
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = "Resource"
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoDefaultLineType()
    var
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType := PurchaseLineType::Resource;
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = "Resource"
        PurchaseCreditMemo.PurchLines.First();
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteDefaultLineType()
    var
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType := PurchaseLineType::Resource;
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = "Resource"
        PurchaseQuote.PurchLines.First();
        PurchaseQuote.PurchLines.FilteredTypeField.AssertEquals(PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseRetOrderDefaultLineType()
    var
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType := PurchaseLineType::Resource;
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = "Resource"
        PurchaseReturnOrder.PurchLines.First();
        PurchaseReturnOrder.PurchLines.FilteredTypeField.AssertEquals(PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderDefaultLineType_Empty()
    var
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = " "
        PurchaseLineType := PurchaseLineType::" ";
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = " "
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines.FilteredTypeField.AssertEquals('Comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderDefaultLineType_Empty()
    var
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = " "
        PurchaseLineType := PurchaseLineType::" ";
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        BlanketPurchaseOrder.OpenNew();
        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = " "
        BlanketPurchaseOrder.PurchLines.First();
        BlanketPurchaseOrder.PurchLines.Type.AssertEquals(PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceDefaultLineType_Empty()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = " "
        PurchaseLineType := PurchaseLineType::" ";
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = " "
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals('Comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoDefaultLineType_Empty()
    var
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = " "
        PurchaseLineType := PurchaseLineType::" ";
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = " "
        PurchaseCreditMemo.PurchLines.First();
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals('Comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteDefaultLineType_Empty()
    var
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = " "
        PurchaseLineType := PurchaseLineType::" ";
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = " "
        PurchaseQuote.PurchLines.First();
        PurchaseQuote.PurchLines.FilteredTypeField.AssertEquals('Comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseRetOrderDefaultLineType_Empty()
    var
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] First Purchase document line "Type" = "Document Default Line Type" from purchase setup when create new Purchase document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = " "
        PurchaseLineType := PurchaseLineType::" ";
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Create new Purchase document
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(Vendor.Name);

        // [THEN] First Purchase document line "Type" = " "
        PurchaseReturnOrder.PurchLines.First();
        PurchaseReturnOrder.PurchLines.FilteredTypeField.AssertEquals('Comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderDefaultLineType_SecondLine()
    var
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseLineType: array[2] of Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from purchase setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType[1] := PurchaseLineType[1] ::Resource;
        SetDocumentDefaultLineType(PurchaseLineType[1]);

        // [GIVEN] New Purchase document with first line "Type" = "G/L Account"
        PurchaseLineType[2] := PurchaseLineType[2] ::"G/L Account";
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines.FilteredTypeField.SetValue(PurchaseLineType[2]);
        Commit();

        // [WHEN] Create Purchase document second line
        PurchaseOrder.PurchLines.New();

        // [THEN] Purchase document second line "Type" = "G/L Account"
        PurchaseOrder.PurchLines.FilteredTypeField.AssertEquals(PurchaseLineType[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderDefaultLineType_SecondLine()
    var
        Vendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PurchaseLineType: array[2] of Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from purchase setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType[1] := PurchaseLineType[1] ::Resource;
        SetDocumentDefaultLineType(PurchaseLineType[1]);

        // [GIVEN] New Purchase document with first line "Type" = "G/L Account"
        PurchaseLineType[2] := PurchaseLineType[2] ::"G/L Account";
        LibraryPurchase.CreateVendor(Vendor);
        BlanketPurchaseOrder.OpenNew();
        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(Vendor.Name);
        BlanketPurchaseOrder.PurchLines.First();
        BlanketPurchaseOrder.PurchLines.Type.SetValue(PurchaseLineType[2]);
        Commit();

        // [WHEN] Create Purchase document second line
        BlanketPurchaseOrder.PurchLines.New();

        // [THEN] Purchase document second line "Type" = "G/L Account"
        BlanketPurchaseOrder.PurchLines.Type.AssertEquals(PurchaseLineType[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteDefaultLineType_SecondLine()
    var
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseLineType: array[2] of Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from purchase setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType[1] := PurchaseLineType[1] ::Resource;
        SetDocumentDefaultLineType(PurchaseLineType[1]);

        // [GIVEN] New Purchase document with first line "Type" = "G/L Account"
        PurchaseLineType[2] := PurchaseLineType[2] ::"G/L Account";
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseQuote.PurchLines.First();
        PurchaseQuote.PurchLines.FilteredTypeField.SetValue(PurchaseLineType[2]);
        Commit();

        // [WHEN] Create Purchase document second line
        PurchaseQuote.PurchLines.New();

        // [THEN] Purchase document second line "Type" = "G/L Account"
        PurchaseQuote.PurchLines.FilteredTypeField.AssertEquals(PurchaseLineType[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceDefaultLineType_SecondLine()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PurchaseLineType: array[2] of Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from purchase setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType[1] := PurchaseLineType[1] ::Resource;
        SetDocumentDefaultLineType(PurchaseLineType[1]);

        // [GIVEN] New Purchase document with first line "Type" = "G/L Account"
        PurchaseLineType[2] := PurchaseLineType[2] ::"G/L Account";
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(PurchaseLineType[2]);
        Commit();

        // [WHEN] Create Purchase document second line
        PurchaseInvoice.PurchLines.New();

        // [THEN] Purchase document second line "Type" = "G/L Account"
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(PurchaseLineType[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoDefaultLineType_SecondLine()
    var
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PurchaseLineType: array[2] of Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from purchase setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType[1] := PurchaseLineType[1] ::Resource;
        SetDocumentDefaultLineType(PurchaseLineType[1]);

        // [GIVEN] New Purchase document with first line "Type" = "G/L Account"
        PurchaseLineType[2] := PurchaseLineType[2] ::"G/L Account";
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseCreditMemo.PurchLines.First();
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(PurchaseLineType[2]);
        Commit();

        // [WHEN] Create Purchase document second line
        PurchaseCreditMemo.PurchLines.New();

        // [THEN] Purchase document second line "Type" = "G/L Account"
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(PurchaseLineType[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseRetOrderDefaultLineType_SecondLine()
    var
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PurchaseLineType: array[2] of Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from purchase setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Resource"
        PurchaseLineType[1] := PurchaseLineType[1] ::Resource;
        SetDocumentDefaultLineType(PurchaseLineType[1]);

        // [GIVEN] New Purchase document with first line "Type" = "G/L Account"
        PurchaseLineType[2] := PurchaseLineType[2] ::"G/L Account";
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseReturnOrder.PurchLines.First();
        PurchaseReturnOrder.PurchLines.FilteredTypeField.SetValue(PurchaseLineType[2]);
        Commit();

        // [WHEN] Create Purchase document second line
        PurchaseReturnOrder.PurchLines.New();

        // [THEN] Purchase document second line "Type" = "G/L Account"
        PurchaseReturnOrder.PurchLines.FilteredTypeField.AssertEquals(PurchaseLineType[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ValidateDescriptionAfterEditPurchaseLineItemDescriptionWhenPayToVendorUpdated()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineDesc: Text;
    begin
        // [SCENARIO 474288] After changing Pay-To Vendor on a Purchase Order and you edit a line Description, you receive an error: "The requested operation is not supported. Page New - Purchase order - xxx -xxx - has to close"
        Initialize();

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line
        CreateItem(Item, LibraryRandom.RandIntInRange(100, 1000));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Pay-To Vendor Updated
        PurchaseHeader.Validate("Pay-to Vendor No.", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Modify(true);

        // [WHEN] Description is updated in Purchase Order Subform
        PurchLineDesc := SetDescriptionInPurchOrderSubPage(PurchaseHeader."No.");

        // [VERIFY] Verify: Purchase Line Description updated
        VerifyDescriptionInPurchOrderSubpage(PurchaseHeader."No.", PurchLineDesc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ValidateDescriptionAfterEditPurchaseLineGLAccDescriptionWhenPayToVendorUpdated()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineDesc: Text;
    begin
        // [SCENARIO 474288] After changing Pay-To Vendor on a Purchase Order and you edit a line Description, you receive an error: "The requested operation is not supported. Page New - Purchase order - xxx -xxx - has to close"
        Initialize();

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));

        // [WHEN] Pay-To Vendor Updated
        PurchaseHeader.Validate("Pay-to Vendor No.", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Modify(true);

        // [WHEN] Description is updated in Purchase Order Subform
        PurchLineDesc := SetDescriptionInPurchOrderSubPage(PurchaseHeader."No.");

        // [VERIFY] Verify: Purchase Line Description updated
        VerifyDescriptionInPurchOrderSubpage(PurchaseHeader."No.", PurchLineDesc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ValidateDescriptionAfterEditPurchaseLineResourceDescriptionWhenPayToVendorUpdated()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineDesc: Text;
    begin
        // [SCENARIO 474288] After changing Pay-To Vendor on a Purchase Order and you edit a line Description, you receive an error: "The requested operation is not supported. Page New - Purchase order - xxx -xxx - has to close"
        Initialize();

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, LibraryResource.CreateResourceNo(), LibraryRandom.RandInt(10));

        // [WHEN] Pay-To Vendor Updated
        PurchaseHeader.Validate("Pay-to Vendor No.", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Modify(true);

        // [WHEN] Description is updated in Purchase Order Subform
        PurchLineDesc := SetDescriptionInPurchOrderSubPage(PurchaseHeader."No.");

        // [VERIFY] Verify: Purchase Line Description updated
        VerifyDescriptionInPurchOrderSubpage(PurchaseHeader."No.", PurchLineDesc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ValidateDescriptionAfterEditPurchaseLineFixedAssetDescriptionWhenPayToVendorUpdated()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineDesc: Text;
    begin
        // [SCENARIO 474288] After changing Pay-To Vendor on a Purchase Order and you edit a line Description, you receive an error: "The requested operation is not supported. Page New - Purchase order - xxx -xxx - has to close"
        Initialize();

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line       
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", '', LibraryRandom.RandInt(10));

        // [WHEN] Pay-To Vendor Updated
        PurchaseHeader.Validate("Pay-to Vendor No.", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Modify(true);

        // [WHEN] Description is updated in Purchase Order Subform
        PurchLineDesc := SetDescriptionInPurchOrderSubPage(PurchaseHeader."No.");

        // [VERIFY] Verify: Purchase Line Description updated
        VerifyDescriptionInPurchOrderSubpage(PurchaseHeader."No.", PurchLineDesc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ValidateDescriptionAfterEditPurchaseLineChargeItemDescriptionWhenPayToVendorUpdated()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineDesc: Text;
    begin
        // [SCENARIO 474288] After changing Pay-To Vendor on a Purchase Order and you edit a line Description, you receive an error: "The requested operation is not supported. Page New - Purchase order - xxx -xxx - has to close"
        Initialize();

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line With Charge (Item)
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));

        // [WHEN] Pay-To Vendor Updated
        PurchaseHeader.Validate("Pay-to Vendor No.", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Modify(true);

        // [WHEN] Description is updated in Purchase Order Subform
        PurchLineDesc := SetDescriptionInPurchOrderSubPage(PurchaseHeader."No.");

        // [VERIFY] Verify: Purchase Line Description updated
        VerifyDescriptionInPurchOrderSubpage(PurchaseHeader."No.", PurchLineDesc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateInvoiceDiscountPercentOnPurchaseOrderPage()
    var
        Vendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseOrderSubform: TestPage "Purchase Order Subform";
        MinAmount1: Decimal;
        MinAmount2: Decimal;
        InvDiscPct: Decimal;
    begin
        // [SCENARIO 477664] Invoice Discount % field is not calculated correctly in documents.
        Initialize();

        // [GIVEN] Disable Calc. Inv. Discount on Purchases & Payables Setup.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", false);
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create two variables & save Minimum Amount values.
        MinAmount1 := LibraryRandom.RandIntInRange(1000, 1000);
        MinAmount2 := LibraryRandom.RandIntInRange(2000, 2000);

        // [GIVEN] Create two Invoice Discounts for Vendor.
        CreateInvoiceDiscForVendorWithDiscPctAndMinValue(Vendor, LibraryRandom.RandInt(0), MinAmount1);
        CreateInvoiceDiscForVendorWithDiscPctAndMinValue(Vendor, LibraryRandom.RandIntInRange(2, 2), MinAmount2);

        // [GIVEN] Create an Item 1.
        LibraryInventory.CreateItem(Item1);

        // [GIVEN] Create an Item 2.
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Create a Purchase Line for Item 1 & Validate Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item1."No.", LibraryRandom.RandInt(0));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1900, 1999, 0));
        PurchaseLine.Modify(true);

        // [GIVEN] Create a Purchase Line for Item 2 & Validate Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item2."No.", LibraryRandom.RandInt(0));
        PurchaseLine2.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(500, 501, 0));
        PurchaseLine2.Modify(true);

        // [GIVEN] Open Purchase Order Page & Calculate Invoice Discount.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseOrder.CalculateInvoiceDiscount.Invoke();

        // [GIVEN] Trap Purchase Order Page.
        PurchaseOrder.Trap();

        // [GIVEN] Open Purchase Order Subform Page & save Invoice Discount Percent value in a variable.
        PurchaseOrderSubform.OpenView();
        PurchaseOrderSubform.Filter.SetFilter("Document No.", PurchaseLine."Document No.");
        InvDiscPct := PurchaseOrderSubform."Invoice Disc. Pct.".AsDecimal();
        PurchaseOrderSubform.Close();

        // [WHEN] Find Vendor Invoice Discount.
        VendorInvoiceDisc.SetRange(Code, Vendor."No.");
        VendorInvoiceDisc.SetRange("Minimum Amount", MinAmount2);
        VendorInvoiceDisc.FindFirst();

        // [VERIFY] Verify Invoice Discount Percent applied on Purchase Order is correct.
        Assert.AreEqual(
            VendorInvoiceDisc."Discount %",
            InvDiscPct,
            StrSubstNo(MustMatchErr, VendorInvoiceDisc.FieldCaption("Discount %"), InvoiceDiscPct));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityZeroOnBlanketPurchaseOrderSubForm()
    var
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [SCENARIO 551594] Blanket purchase order subform quantity cannot be changed to zero when the item does not have Direct Unit Cost
        Initialize();

        // [GIVEN] Enable Calc. Inv. Discount on Purchases & Payables Setup
        SetCalcInvDiscount();

        // [GIVEN] Open new purchase order page and pick new customer
        BlanketPurchaseOrder.OpenNew();
        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item
        BlanketPurchaseOrder.PurchLines.New();
        BlanketPurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        BlanketPurchaseOrder.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        BlanketPurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(100));
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.Previous();
        BlanketPurchaseOrder.PurchLines.Quantity.SetValue(0);
        BlanketPurchaseOrder.PurchLines.Next();
        BlanketPurchaseOrder.PurchLines.Previous();

        // [THEN] Quantity should be Zero
        BlanketPurchaseOrder.PurchLines.Quantity.AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityZeroOnPurchaseQuoteSubForm()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO 551594] Purchase quote subform quantity cannot be changed to zero when the item does not have Direct Unit Cost
        Initialize();

        // [GIVEN] Enable Calc. Inv. Discount on Purchases & Payables Setup
        SetCalcInvDiscount();

        // [GIVEN] Open new purchase quote page and pick new customer
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item
        PurchaseQuote.PurchLines.New();
        PurchaseQuote.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseQuote.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseQuote.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(100));
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.Previous();
        PurchaseQuote.PurchLines.Quantity.SetValue(0);
        PurchaseQuote.PurchLines.Next();
        PurchaseQuote.PurchLines.Previous();

        // [THEN] Quantity should be Zero
        PurchaseQuote.PurchLines.Quantity.AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityZeroOnPurchaseOrderSubForm()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 551594] Purchase order subform quantity cannot be changed to zero when the item does not have Direct Unit Cost
        Initialize();

        // [GIVEN] Enable Calc. Inv. Discount on Purchases & Payables Setup
        SetCalcInvDiscount();

        // [GIVEN] Open new purchase order page and pick new customer
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item
        PurchaseOrder.PurchLines.New();
        PurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseOrder.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(100));
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.Previous();
        PurchaseOrder.PurchLines.Quantity.SetValue(0);
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.Previous();

        // [THEN] Quantity should be Zero
        PurchaseOrder.PurchLines.Quantity.AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityZeroOnPurchaseInvoiceSubForm()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 551594] Purchase invoice subform quantity cannot be changed to zero when the item does not have Direct Unit Cost
        Initialize();

        // [GIVEN] Enable Calc. Inv. Discount on Purchases & Payables Setup
        SetCalcInvDiscount();

        // [GIVEN] Open new purchase invoice page and pick new customer
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseInvoice.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseInvoice.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(100));
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.Previous();
        PurchaseInvoice.PurchLines.Quantity.SetValue(0);
        PurchaseInvoice.PurchLines.Next();
        PurchaseInvoice.PurchLines.Previous();

        // [THEN] Quantity should be Zero
        PurchaseInvoice.PurchLines.Quantity.AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityZeroOnPurchaseCreditMemoSubForm()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO 551594] Purchase credit memo subform quantity cannot be changed to zero when the item does not have Direct Unit Cost
        Initialize();

        // [GIVEN] Enable Calc. Inv. Discount on Purchases & Payables Setup
        SetCalcInvDiscount();

        // [GIVEN] Open new purchase credit memo page and pick new customer
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item
        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseCreditMemo.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(100));
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.Previous();
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(0);
        PurchaseCreditMemo.PurchLines.Next();
        PurchaseCreditMemo.PurchLines.Previous();

        // [THEN] Quantity should be Zero
        PurchaseCreditMemo.PurchLines.Quantity.AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityZeroOnPurchaseReturnOrderSubForm()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO 551594] Purchase return order subform quantity cannot be changed to zero when the item does not have Direct Unit Cost
        Initialize();

        // [GIVEN] Enable Calc. Inv. Discount on Purchases & Payables Setup
        SetCalcInvDiscount();

        // [GIVEN] Open new purchase return order page and pick new customer
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());

        // [WHEN] Create new line with Type = Item
        PurchaseReturnOrder.PurchLines.New();
        PurchaseReturnOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseReturnOrder.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(100));
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.Previous();
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(0);
        PurchaseReturnOrder.PurchLines.Next();
        PurchaseReturnOrder.PurchLines.Previous();

        // [THEN] Quantity should be Zero
        PurchaseReturnOrder.PurchLines.Quantity.AssertEquals(0);
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        VendorNoSeries: Text[20];
    begin
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Subform");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        LibraryPurchase.DisableWarningOnCloseUnpostedDoc();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Subform");

        LibraryPurchase.SetCalcInvDiscount(true);

        VendorNoSeries := LibraryUtility.GetGlobalNoSeriesCode();
        if PurchasesPayablesSetup."Vendor Nos." <> VendorNoSeries then begin
            PurchasesPayablesSetup.Get();
            PurchasesPayablesSetup.Validate("Vendor Nos.", VendorNoSeries);
            PurchasesPayablesSetup.Modify();
        end;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.CreateItem(Item);
        Item.Description := ItemTestDescriptionLbl;
        Item.Modify();

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        isInitialized := true;

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Subform");
        GeneralLedgerSetup.Get();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure CheckOrderStatistics(PurchaseOrder: TestPage "Purchase Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseOrder.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;
#endif

    local procedure CheckPurchaseOrderStatistics(PurchaseOrder: TestPage "Purchase Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseOrder.PurchaseOrderStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure CheckInvoiceStatistics(PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseInvoice.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure CheckCreditMemoStatistics(PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseCreditMemo.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure CheckQuoteStatistics(PurchaseQuote: TestPage "Purchase Quote")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseQuote.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;
#endif

    local procedure CheckPurchaseInvoiceStatistics(PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseInvoice.PurchaseStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    local procedure CheckPurchaseCreditMemoStatistics(PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseCreditMemo.PurchaseStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    local procedure CheckPurchaseQuoteStatistics(PurchaseQuote: TestPage "Purchase Quote")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseQuote.PurchaseStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure CheckBlanketOrderStatistics(BlanketPurchaseOrder: TestPage "Blanket Purchase Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal());
        BlanketPurchaseOrder.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;
#endif

    local procedure CheckBlanketPurchaseOrderStatistics(BlanketPurchaseOrder: TestPage "Blanket Purchase Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal());
        BlanketPurchaseOrder.PurchaseOrderStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure CheckReturnOrderStatistics(PurchaseReturnOrder: TestPage "Purchase Return Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseReturnOrder.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;
#endif

    local procedure CheckPurchaseReturnOrderStatistics(PurchaseReturnOrder: TestPage "Purchase Return Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal());
        PurchaseReturnOrder.PurchaseOrderStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    [Normal]
    local procedure CreatePurchOrderAndPostOneOfTwoLines(): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        CreateItem(Item, LibraryRandom.RandIntInRange(100, 1000));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        CreateItem(Item, LibraryRandom.RandIntInRange(100, 1000));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        exit(PurchaseHeader."No.");
    end;

    local procedure ValidateOrderInvoiceDiscountAmountIsReadOnly(var PurchaseOrder: TestPage "Purchase Order")
    begin
        Assert.IsFalse(PurchaseOrder.PurchLines."Invoice Discount Amount".Editable(),
          'Invoce discount amount shoud not be editable');
    end;

    local procedure ValidateInvoiceInvoiceDiscountAmountIsReadOnly(var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        Assert.IsFalse(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.Editable(),
          'Invoce discount amount shoud not be editable');
    end;

    local procedure ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".Editable(),
          'Invoce discount amount shoud not be editable');
    end;

    local procedure ValidateQuoteInvoiceDiscountAmountIsReadOnly(var PurchaseQuote: TestPage "Purchase Quote")
    begin
        Assert.IsFalse(PurchaseQuote.PurchLines."Invoice Discount Amount".Editable(),
          'Invoce discount amount shoud not be editable');
    end;

    local procedure ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(var BlanketPurchaseOrder: TestPage "Blanket Purchase Order")
    begin
        Assert.IsFalse(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".Editable(),
          'Invoce discount amount shoud not be editable');
    end;

    local procedure ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(var PurchaseReturnOrder: TestPage "Purchase Return Order")
    begin
        Assert.IsFalse(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".Editable(),
          'Invoce discount amount shoud not be editable');
    end;

    local procedure OrderCheckCurrencyOnTotals(PurchaseOrder: TestPage "Purchase Order"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(PurchaseOrder.PurchLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(PurchaseOrder.PurchLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(PurchaseOrder.PurchLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure InvoiceCheckCurrencyOnTotals(PurchaseInvoice: TestPage "Purchase Invoice"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(PurchaseInvoice.PurchLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(PurchaseInvoice.PurchLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(PurchaseInvoice.PurchLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure CreditMemoCheckCurrencyOnTotals(PurchaseCreditMemo: TestPage "Purchase Credit Memo"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(PurchaseCreditMemo.PurchLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure QuoteCheckCurrencyOnTotals(PurchaseQuote: TestPage "Purchase Quote"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(PurchaseQuote.PurchLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(PurchaseQuote.PurchLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(PurchaseQuote.PurchLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure BlanketPurchaseOrderCheckCurrencyOnTotals(BlanketPurchaseOrder: TestPage "Blanket Purchase Order"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(BlanketPurchaseOrder.PurchLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure ReturnOrderCheckCurrencyOnTotals(PurchaseReturnOrder: TestPage "Purchase Return Order"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(PurchaseReturnOrder.PurchLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure VerifyCurrencyInCaption(FieldCaption: Text; CurrencyCode: Code[10])
    begin
        Assert.TextEndsWith(FieldCaption, StrSubstNo('(%1)', CurrencyCode));
    end;

    local procedure GetDifferentCurrencyCode(): Code[10]
    begin
        exit(LibraryERM.CreateCurrencyWithRandomExchRates());
    end;

    local procedure CreateOrderWithOneLineThroughTestPage(Vendor: Record Vendor; Item: Record Item; ItemQuantity: Integer; var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor Name".SetValue(Vendor."No.");

        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines.Type.SetValue('Item');
        PurchaseOrder.PurchLines."No.".SetValue(Item."No.");
        PurchaseOrder.PurchLines.Quantity.SetValue(ItemQuantity);

        if DoesVendorHaveInvDiscounts(Vendor) then begin
            LibraryVariableStorage.Enqueue('Do you');
            LibraryVariableStorage.Enqueue(true);
            PurchaseOrder.CalculateInvoiceDiscount.Invoke();
        end;

        PurchaseOrder.PurchLines.Next();
    end;

    local procedure CreateInvoiceWithOneLineThroughTestPage(Vendor: Record Vendor; Item: Record Item; ItemQuantity: Integer; var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);

        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Type.SetValue('Item');
        PurchaseInvoice.PurchLines."No.".SetValue(Item."No.");
        PurchaseInvoice.PurchLines.Quantity.SetValue(ItemQuantity);

        if DoesVendorHaveInvDiscounts(Vendor) then begin
            LibraryVariableStorage.Enqueue('Do you');
            LibraryVariableStorage.Enqueue(true);
            PurchaseInvoice.CalculateInvoiceDiscount.Invoke();
        end;

        PurchaseInvoice.PurchLines.Next();
    end;

    local procedure CreateCreditMemoWithOneLineThroughTestPage(Vendor: Record Vendor; Item: Record Item; ItemQuantity: Integer; var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor.Name);

        PurchaseCreditMemo.PurchLines.First();
        PurchaseCreditMemo.PurchLines.Type.SetValue('Item');
        PurchaseCreditMemo.PurchLines."No.".SetValue(Item."No.");
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(ItemQuantity);

        if DoesVendorHaveInvDiscounts(Vendor) then begin
            LibraryVariableStorage.Enqueue('Do you');
            LibraryVariableStorage.Enqueue(true);
            PurchaseCreditMemo.CalculateInvoiceDiscount.Invoke();
        end;

        PurchaseCreditMemo.PurchLines.Next();
    end;

    local procedure CreateQuoteWithOneLineThroughTestPage(Vendor: Record Vendor; Item: Record Item; ItemQuantity: Integer; var PurchaseQuote: TestPage "Purchase Quote")
    begin
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor Name".SetValue(Vendor."No.");

        PurchaseQuote.PurchLines.First();
        PurchaseQuote.PurchLines.Type.SetValue('Item');
        PurchaseQuote.PurchLines."No.".SetValue(Item."No.");
        PurchaseQuote.PurchLines.Quantity.SetValue(ItemQuantity);

        if DoesVendorHaveInvDiscounts(Vendor) then begin
            LibraryVariableStorage.Enqueue('Do you');
            LibraryVariableStorage.Enqueue(true);
            PurchaseQuote.CalculateInvoiceDiscount.Invoke();
        end;

        PurchaseQuote.PurchLines.Next();
    end;

    local procedure CreateBlanketOrderWithOneLineThroughTestPage(Vendor: Record Vendor; Item: Record Item; ItemQuantity: Integer; var BlanketPurchaseOrder: TestPage "Blanket Purchase Order")
    begin
        BlanketPurchaseOrder.OpenNew();
        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(Vendor."No.");

        BlanketPurchaseOrder.PurchLines.First();
        BlanketPurchaseOrder.PurchLines.Type.SetValue('Item');
        BlanketPurchaseOrder.PurchLines."No.".SetValue(Item."No.");
        BlanketPurchaseOrder.PurchLines.Quantity.SetValue(ItemQuantity);

        if DoesVendorHaveInvDiscounts(Vendor) then begin
            LibraryVariableStorage.Enqueue('Do you');
            LibraryVariableStorage.Enqueue(true);
            BlanketPurchaseOrder.CalculateInvoiceDiscount.Invoke();
        end;

        BlanketPurchaseOrder.PurchLines.Next();
    end;

    local procedure CreateReturnOrderWithOneLineThroughTestPage(Vendor: Record Vendor; Item: Record Item; ItemQuantity: Integer; var PurchaseReturnOrder: TestPage "Purchase Return Order")
    begin
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(Vendor."No.");

        PurchaseReturnOrder.PurchLines.First();
        PurchaseReturnOrder.PurchLines.Type.SetValue('Item');
        PurchaseReturnOrder.PurchLines."No.".SetValue(Item."No.");
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(ItemQuantity);

        if DoesVendorHaveInvDiscounts(Vendor) then begin
            LibraryVariableStorage.Enqueue('Do you');
            LibraryVariableStorage.Enqueue(true);
            PurchaseReturnOrder.CalculateInvoiceDiscount.Invoke();
        end;

        PurchaseReturnOrder.PurchLines.Next();
    end;

    local procedure CreateInvoiceThroughTestPageForItemWithGivenNumberOfUOMs(var PurchaseInvoice: TestPage "Purchase Invoice"; NoOfAdditionalUOMs: Integer)
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        CreateItemWithGivenNumberOfAdditionalUOMs(Item, NoOfAdditionalUOMs);
        CreateInvoiceWithOneLineThroughTestPage(Vendor, Item, LibraryRandom.RandInt(10), PurchaseInvoice);
    end;

    local procedure CreateQuoteThroughTestPageForItemWithGivenNumberOfUOMs(var PurchaseQuote: TestPage "Purchase Quote"; NoOfAdditionalUOMs: Integer)
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        CreateItemWithGivenNumberOfAdditionalUOMs(Item, NoOfAdditionalUOMs);
        CreateQuoteWithOneLineThroughTestPage(Vendor, Item, LibraryRandom.RandInt(10), PurchaseQuote);
    end;

    local procedure CreateCrMemoThroughTestPageForItemWithGivenNumberOfUOMs(var PurchaseCreditMemo: TestPage "Purchase Credit Memo"; NoOfAdditionalUOMs: Integer)
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        CreateItemWithGivenNumberOfAdditionalUOMs(Item, NoOfAdditionalUOMs);
        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, LibraryRandom.RandInt(10), PurchaseCreditMemo);
    end;

    local procedure CreatePurchaseDocumentForItemWithGivenNumberOfUOMs(var PurchaseLine: Record "Purchase Line"; NoOfAdditionalUOMs: Integer)
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateVendor(Vendor);
        CreateItemWithGivenNumberOfAdditionalUOMs(Item, NoOfAdditionalUOMs);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchaseHeaderWithCurrencyCode(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"): Code[10]
    var
        CurrencyCode: Code[10];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        exit(CurrencyCode);
    end;

    local procedure CreatePurchaseDocumentWithCurrency(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var Item: Record Item; var CurrencyCode: Code[10]; DocumentType: Enum "Purchase Document Type"; ExchangeRate: Decimal)
    begin
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(LibraryRandom.RandDate(-10), ExchangeRate, ExchangeRate);

        CreateItem(Item, LibraryRandom.RandIntInRange(10, 20));

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(20, 100));
    end;

    local procedure CreateVendorNoPricesIncludingVAT(PricesIncludingVAT: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Prices Including VAT", PricesIncludingVAT);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure AddInvoiceDiscToVendor(Vendor: Record Vendor; MinimumAmount: Decimal; Percentage: Decimal)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Vendor."No.", Vendor."Currency Code", MinimumAmount);
        VendorInvoiceDisc.Validate("Discount %", Percentage);
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure OpenPurchaseOrder(PurchaseHeader: Record "Purchase Header"; var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure OpenPurchaseInvoice(PurchaseHeader: Record "Purchase Header"; var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure OpenPurchaseCreditMemo(PurchaseHeader: Record "Purchase Header"; var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure OpenPurchaseQuote(PurchaseHeader: Record "Purchase Header"; var PurchaseQuote: TestPage "Purchase Quote")
    begin
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure OpenBlanketPurchaseOrder(PurchaseHeader: Record "Purchase Header"; var BlanketPurchaseOrder: TestPage "Blanket Purchase Order")
    begin
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure OpenReturnOrder(PurchaseHeader: Record "Purchase Header"; var PurchaseReturnOrder: TestPage "Purchase Return Order")
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure CreateOrderWithRandomNumberOfLines(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Vendor: Record Vendor; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        for I := 1 to NumberOfLines do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", ItemQuantity);
            PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity);
        end;
    end;

    local procedure CreateInvoiceWithRandomNumberOfLines(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Vendor: Record Vendor; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        for I := 1 to NumberOfLines do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", ItemQuantity);
            PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity);
        end;
    end;

    local procedure CreateCreditMemoWithRandomNumberOfLines(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Vendor: Record Vendor; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());

        for I := 1 to NumberOfLines do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", ItemQuantity);
            PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity);
        end;
    end;

    local procedure CreateQuoteWithRandomNumberOfLines(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Vendor: Record Vendor; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, Vendor."No.");

        for I := 1 to NumberOfLines do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", ItemQuantity);
            PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity);
        end;
    end;

    local procedure CreateBlanketOrderWithRandomNumberOfLines(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Vendor: Record Vendor; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", Vendor."No.");

        for I := 1 to NumberOfLines do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", ItemQuantity);
            PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity);
        end;
    end;

    local procedure CreateReturnOrderWithRandomNumberOfLines(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Vendor: Record Vendor; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());

        for I := 1 to NumberOfLines do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", ItemQuantity);
            PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity);
        end;
    end;

    local procedure CreateGLAccountForInvoiceRounding(VendorPostingGroupCode: Code[20]): Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountNo: Code[20];
    begin
        LibraryPurchase.SetInvoiceRounding(true);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := 1;
        GeneralLedgerSetup.Modify();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        VendorPostingGroup.Get(VendorPostingGroupCode);
        VendorPostingGroup.Validate("Invoice Rounding Account", GLAccountNo);
        VendorPostingGroup.Modify(true);
        exit(GLAccountNo);
    end;

    local procedure CreateDimOnGLAccount(GLAccountNo: Code[20]): Integer
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionGLAcc(
          DefaultDimension, GLAccountNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify();
        exit(DimensionValue."Dimension Value ID");
    end;

    local procedure DoesVendorHaveInvDiscounts(var Vendor: Record Vendor): Boolean
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        VendorInvoiceDisc.SetRange(Code, Vendor."No.");
        VendorInvoiceDisc.SetRange("Currency Code", Vendor."Currency Code");
        exit(not VendorInvoiceDisc.IsEmpty);
    end;

    local procedure SetInvDiscAmountInPurchOrderSubPage(DocNo: Code[20]) InvDiscountAmount: Integer
    var
        PurchaseOrderSubform: TestPage "Purchase Order Subform";
    begin
        PurchaseOrderSubform.OpenEdit();
        PurchaseOrderSubform.FILTER.SetFilter("Document No.", DocNo);
        InvDiscountAmount := LibraryRandom.RandInt(100);
        PurchaseOrderSubform."Invoice Discount Amount".SetValue(InvDiscountAmount);
    end;

    local procedure SetupDataForDiscountTypePct(var Item: Record Item; var ItemQuantity: Decimal; var Vendor: Record Vendor)
    var
        MinAmt: Decimal;
        ItemLastDirectCost: Decimal;
        DiscPct: Decimal;
    begin
        ItemLastDirectCost := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemLastDirectCost, ItemLastDirectCost * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);

        CreateItem(Item, ItemLastDirectCost);
        CreateVendorWithDiscount(Vendor, DiscPct, MinAmt);
    end;

    local procedure SetupDataForDiscountTypeAmt(var Item: Record Item; var ItemQuantity: Decimal; var Vendor: Record Vendor; var InvoiceDiscountAmount: Decimal)
    begin
        SetAllowManualDisc();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor);
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(1, Round(Item."Unit Cost" * ItemQuantity, 1, '<'), 2);
    end;

    local procedure CreateVendorWithDiscount(var Vendor: Record Vendor; DiscPct: Decimal; minAmount: Decimal)
    begin
        CreateVendor(Vendor);
        AddInvoiceDiscToVendor(Vendor, minAmount, DiscPct);
    end;

    [Normal]
    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Name := Vendor."No.";
        Vendor.Modify();
    end;

    local procedure CreateItem(var Item: Record Item; LastDirectCost: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Last Direct Cost" := LastDirectCost;
        Item.Modify();
    end;

    local procedure CreateItemWithGivenNumberOfAdditionalUOMs(var Item: Record Item; NoOfAdditionalUOMs: Integer)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        while NoOfAdditionalUOMs > 0 do begin
            LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));
            NoOfAdditionalUOMs -= 1;
        end;
    end;

    local procedure FindFirstAdditionalItemUOMCode(ItemNo: Code[20]; BaseUOMCode: Code[10]): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        ItemUnitOfMeasure.SetFilter(Code, '<>%1', BaseUOMCode);
        ItemUnitOfMeasure.FindFirst();
        exit(ItemUnitOfMeasure.Code);
    end;

    local procedure SetCurrencyOnOrderAndVerify(PurchaseOrder: TestPage "Purchase Order"; CurrencyCode: Code[10]; Item: Record Item; PurchaseLine: Record "Purchase Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        PurchaseOrder."Currency Code".SetValue(CurrencyCode);
        OrderCheckCurrencyOnTotals(PurchaseOrder, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        PurchaseOrder.PurchLines."Total Amount Excl. VAT".AssertEquals(
          Round(Item."Last Direct Cost" * PurchaseLine.Quantity * ExchangeRate));
    end;

    local procedure SetCurrencyOnInvoiceAndVerify(PurchaseInvoice: TestPage "Purchase Invoice"; CurrencyCode: Code[10]; Item: Record Item; PurchaseLine: Record "Purchase Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        PurchaseInvoice."Currency Code".SetValue(CurrencyCode);
        InvoiceCheckCurrencyOnTotals(PurchaseInvoice, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AssertEquals(
          Round(Item."Last Direct Cost" * PurchaseLine.Quantity * ExchangeRate));
    end;

    local procedure SetCurrencyOnQuoteAndVerify(PurchaseQuote: TestPage "Purchase Quote"; CurrencyCode: Code[10]; Item: Record Item; PurchaseLine: Record "Purchase Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        PurchaseQuote."Currency Code".SetValue(CurrencyCode);
        QuoteCheckCurrencyOnTotals(PurchaseQuote, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        PurchaseQuote.PurchLines."Total Amount Excl. VAT".AssertEquals(
          Round(Item."Last Direct Cost" * PurchaseLine.Quantity * ExchangeRate));
    end;

    local procedure SetCurrencyOnCreditMemoAndVerify(PurchaseCreditMemo: TestPage "Purchase Credit Memo"; CurrencyCode: Code[10]; Item: Record Item; PurchaseLine: Record "Purchase Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        PurchaseCreditMemo."Currency Code".SetValue(CurrencyCode);
        CreditMemoCheckCurrencyOnTotals(PurchaseCreditMemo, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AssertEquals(
          Round(Item."Last Direct Cost" * PurchaseLine.Quantity * ExchangeRate));
    end;

    local procedure SetCurrencyOnBlanketOrderAndVerify(BlanketPurchaseOrder: TestPage "Blanket Purchase Order"; CurrencyCode: Code[10]; Item: Record Item; PurchaseLine: Record "Purchase Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        BlanketPurchaseOrder."Currency Code".SetValue(CurrencyCode);
        BlanketPurchaseOrderCheckCurrencyOnTotals(BlanketPurchaseOrder, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".AssertEquals(
          Round(Item."Last Direct Cost" * PurchaseLine.Quantity * ExchangeRate));
    end;

    local procedure SetCurrencyOnReturnOrderAndVerify(PurchaseReturnOrder: TestPage "Purchase Return Order"; CurrencyCode: Code[10]; Item: Record Item; PurchaseLine: Record "Purchase Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        PurchaseReturnOrder."Currency Code".SetValue(CurrencyCode);
        ReturnOrderCheckCurrencyOnTotals(PurchaseReturnOrder, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AssertEquals(
          Round(Item."Last Direct Cost" * PurchaseLine.Quantity * ExchangeRate));
    end;

    local procedure EnqueueChangeCurrencyCodeConfirmation()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryVariableStorage.Enqueue(
          StrSubstNo(ChangeCurrencyConfirmQst, PurchaseHeader.FieldCaption("Currency Code")));
        LibraryVariableStorage.Enqueue(true);
    end;

    local procedure SetDocumentDefaultLineType(PurchaseLineType: Enum "Purchase Line Type")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Document Default Line Type" := PurchaseLineType;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure CheckPostedInvoiceStatistics(PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    var
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
    begin
        PurchaseInvoiceStatistics.Trap();
        PostedPurchaseInvoice.Statistics.Invoke(); // opens the non modal statistics page

        Assert.AreNearlyEqual(PostedPurchaseInvoice.PurchInvLines."Invoice Discount Amount".AsDecimal(),
          PurchaseInvoiceStatistics.InvDiscAmount.AsDecimal(), 0.1, 'Invoice Discount Amount is not correct');
        Assert.AreNearlyEqual(PostedPurchaseInvoice.PurchInvLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoiceStatistics.AmountInclVAT.AsDecimal(), 0.1, 'Total Amount Incl. VAT is not correct');
        Assert.AreNearlyEqual(PostedPurchaseInvoice.PurchInvLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoiceStatistics.VATAmount.AsDecimal(), 0.1, 'VAT Amount is not correct');
    end;

    local procedure CheckPostedCreditMemoStatistics(PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo")
    var
        PurchCreditMemoStatistics: TestPage "Purch. Credit Memo Statistics";
    begin
        PurchCreditMemoStatistics.Trap();
        PostedPurchaseCreditMemo.Statistics.Invoke(); // opens the non modal statistics page

        Assert.AreNearlyEqual(PostedPurchaseCreditMemo.PurchCrMemoLines."Invoice Discount Amount".AsDecimal(),
          PurchCreditMemoStatistics.InvDiscAmount.AsDecimal(), 0.1, 'Invoice Discount Amount is not correct');
        Assert.AreNearlyEqual(PostedPurchaseCreditMemo.PurchCrMemoLines."Total Amount Incl. VAT".AsDecimal(),
          PurchCreditMemoStatistics.AmountInclVAT.AsDecimal(), 0.1, 'Total Amount Incl. VAT is not correct');
        Assert.AreNearlyEqual(PostedPurchaseCreditMemo.PurchCrMemoLines."Total VAT Amount".AsDecimal(),
          PurchCreditMemoStatistics.VATAmount.AsDecimal(), 0.1, 'VAT Amount is not correct');
    end;

    local procedure CheckPurchaseInvoiceSubformTotalAmountCaptions(PurchaseInvoicePage: TestPage "Purchase Invoice"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(PurchaseInvoicePage.PurchLines.AmountBeforeDiscount.Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseInvoicePage.PurchLines.InvoiceDiscountAmount.Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseInvoicePage.PurchLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseInvoicePage.PurchLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseInvoicePage.PurchLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure CheckPurchaseOrderSubformTotalAmountCaptions(PurchaseOrderPage: TestPage "Purchase Order"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(PurchaseOrderPage.PurchLines."Invoice Discount Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseOrderPage.PurchLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseOrderPage.PurchLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseOrderPage.PurchLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure CheckPurchaseCreditMemoSubformTotalAmountCaptions(PurchaseCreditMemoPage: TestPage "Purchase Credit Memo"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(PurchaseCreditMemoPage.PurchLines."Invoice Discount Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseCreditMemoPage.PurchLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseCreditMemoPage.PurchLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseCreditMemoPage.PurchLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure CheckPurchaseQuoteSubformTotalAmountCaptions(PurchaseQuotePage: TestPage "Purchase Quote"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(PurchaseQuotePage.PurchLines."Invoice Discount Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseQuotePage.PurchLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseQuotePage.PurchLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseQuotePage.PurchLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure CheckBlanketPurchaseOrderSubformTotalAmountCaptions(BlanketPurchaseOrderPage: TestPage "Blanket Purchase Order"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(BlanketPurchaseOrderPage.PurchLines."Invoice Discount Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(BlanketPurchaseOrderPage.PurchLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(BlanketPurchaseOrderPage.PurchLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(BlanketPurchaseOrderPage.PurchLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure CheckPurchaseReturnOrderSubformTotalAmountCaptions(PurchaseReturnOrderPage: TestPage "Purchase Return Order"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(PurchaseReturnOrderPage.PurchLines."Invoice Discount Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseReturnOrderPage.PurchLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseReturnOrderPage.PurchLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(PurchaseReturnOrderPage.PurchLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure VerifyInvDiscAmountInPurchOrderSubpage(DocNo: Code[20]; InvDiscountAmount: Integer)
    var
        PurchaseOrderSubform: TestPage "Purchase Order Subform";
    begin
        PurchaseOrderSubform.OpenEdit();
        PurchaseOrderSubform.FILTER.SetFilter("Document No.", DocNo);
        PurchaseOrderSubform."Invoice Discount Amount".AssertEquals(InvDiscountAmount);
    end;

    local procedure AnswerYesToConfirmDialog()
    begin
        AnswerYesToConfirmDialogs(1);
    end;

    local procedure AnswerYesToConfirmDialogs(ExpectedNumberOfDialogs: Integer)
    var
        I: Integer;
    begin
        for I := 1 to ExpectedNumberOfDialogs do begin
            LibraryVariableStorage.Enqueue(ChangeConfirmMsg);
            LibraryVariableStorage.Enqueue(true);
        end;
    end;

    local procedure AnswerYesToAllConfirmDialogs()
    begin
        AnswerYesToConfirmDialogs(10);
    end;

    local procedure SetDescriptionInPurchOrderSubPage(DocNo: Code[20]) PurchLineDesc: Text
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", DocNo);
        PurchLineDesc := LibraryRandom.RandText(100);
        PurchaseOrder.PurchLines.Description.SetValue(PurchLineDesc);
    end;

    local procedure VerifyDescriptionInPurchOrderSubpage(DocNo: Code[20]; PurchLineDesc: Text)
    var
        PurchaseOrderSubform: TestPage "Purchase Order Subform";
    begin
        PurchaseOrderSubform.OpenEdit();
        PurchaseOrderSubform.FILTER.SetFilter("Document No.", DocNo);
        PurchaseOrderSubform.Description.AssertEquals(PurchLineDesc);
    end;

    local procedure CreateInvoiceDiscForVendorWithDiscPctAndMinValue(var Vendor: Record Vendor; DiscountPct: Decimal; MinValue: Decimal)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(
          VendorInvoiceDisc, Vendor."No.", Vendor."Currency Code", MinValue);
        VendorInvoiceDisc.Validate("Discount %", DiscountPct);
        VendorInvoiceDisc.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
        Answer: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        LibraryVariableStorage.Dequeue(Answer);
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := Answer;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure SetAllowManualDisc()
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup.Validate("Calc. Inv. Discount", false);
        PurchasePayablesSetup.Modify(true);
    end;

    local procedure SetCalcInvDiscount()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Calc. Inv. Discount" := true;
        PurchasesPayablesSetup.Modify();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderHandler(var PurchaseOrder: TestPage "Purchase Order")
    begin
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsModalHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreEqual(InvDiscAmount, PurchaseOrderStatistics.InvDiscountAmount_General.AsDecimal(),
          'Invoice Discount Amount is not correct');
        Assert.AreEqual(TotalAmountInclVAT, PurchaseOrderStatistics.TotalInclVAT_General.AsDecimal(),
          'Total Amount Incl. VAT is not correct');
        Assert.AreEqual(VATApplied, PurchaseOrderStatistics."VATAmount[1]".AsDecimal(),
          'VAT Amount is not correct');
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreEqual(InvDiscAmount, PurchaseOrderStatistics.InvDiscountAmount_General.AsDecimal(),
          'Invoice Discount Amount is not correct');
        Assert.AreEqual(TotalAmountInclVAT, PurchaseOrderStatistics.TotalInclVAT_General.AsDecimal(),
          'Total Amount Incl. VAT is not correct');
        Assert.AreEqual(VATApplied, PurchaseOrderStatistics."VATAmount[1]".AsDecimal(),
          'VAT Amount is not correct');
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsModalHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreNearlyEqual(InvDiscAmount, PurchaseStatistics.InvDiscountAmount.AsDecimal(),
          0.5, 'Invoice Discount Amount is not correct');
        Assert.AreNearlyEqual(TotalAmountInclVAT, PurchaseStatistics.TotalAmount2.AsDecimal(),
          0.5, 'Total Amount Incl. VAT is not correct');
        Assert.AreNearlyEqual(VATApplied, PurchaseStatistics.VATAmount.AsDecimal(),
          0.5, 'VAT Amount is not correct');
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreNearlyEqual(InvDiscAmount, PurchaseStatistics.InvDiscountAmount.AsDecimal(),
          0.5, 'Invoice Discount Amount is not correct');
        Assert.AreNearlyEqual(TotalAmountInclVAT, PurchaseStatistics.TotalAmount2.AsDecimal(),
          0.5, 'Total Amount Incl. VAT is not correct');
        Assert.AreNearlyEqual(VATApplied, PurchaseStatistics.VATAmount.AsDecimal(),
          0.5, 'VAT Amount is not correct');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemUnitofMeasureModalHandler(var ItemUnitsofMeasure: TestPage "Item Units of Measure")
    var
        UnitofMeasureCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(UnitofMeasureCode);
        ItemUnitsofMeasure.FILTER.SetFilter(Code, Format(UnitofMeasureCode));
        ItemUnitsofMeasure.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceUnitofMeasureModalHandler(var ResourceUnitsofMeasure: TestPage "Resource Units of Measure")
    begin
        ResourceUnitsofMeasure.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        ResourceUnitsofMeasure.First();
        ResourceUnitsofMeasure.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure BlanketOrderMessageHandler(Msg: Text)
    begin
        Assert.IsTrue(StrPos(Msg, BlanketMsg) > 0, Msg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Msg);
    end;
}

