codeunit 134393 "ERM Sales Subform"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [Sales]
        isInitialized := false;
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        ChangeConfirmMsg: Label 'Do you want';
        CalculateInvoiceDiscountQst: Label 'Do you want to calculate the invoice discount?';
        BlanketOrderMsg: Label 'has been created from blanket order';
        ExternalDocNoErr: Label '"External Doc. No." is not available on the "Blanket Sales Order" page';
        UnitofMeasureCodeIsEditableMsg: Label 'Unit of Measure Code should not be editable.', Comment = '%1: FieldCaption';
        UnitofMeasureCodeIsNotEditableMsg: Label 'Unit of Measure Code should be editable.';
        UpdateInvDiscountQst: Label 'One or more lines have been invoiced. The discount distributed to invoiced lines will not be taken into account.\\Do you want to update the invoice discount?';
        EditableErr: Label '%1 should be editable';
        NotEditableErr: Label '%1 should NOT be editable';
        ChangeCurrencyConfirmQst: Label 'If you change %1, the existing sales lines will be deleted and new sales lines based on the new information on the header will be created.';
        ItemChargeAssignmentErr: Label 'You can only assign Item Charges for Line Types of Charge (Item).';
        MustMatchErr: Label '%1 and %2 must match.';
        InvoiceDiscPct: Label 'Invoice Disc. Pct.';
        ItemTestDescriptionLbl: Label 'Test Description';

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateInvoiceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);

        CheckInvoiceStatistics(SalesInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateInvoiceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);
        // prepare dialog
        LibraryVariableStorage.Enqueue('Do you');
        LibraryVariableStorage.Enqueue(true);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();

        CheckInvoiceStatistics(SalesInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateInvoiceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);

        SalesInvoice.SalesLines.First();
        ItemQuantity := ItemQuantity * 2;
        SalesInvoice.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();

        CheckInvoiceStatistics(SalesInvoice);

        SalesInvoice.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();

        CheckInvoiceStatistics(SalesInvoice);

        SalesInvoice.SalesLines."Line Amount".SetValue(
          Round(SalesInvoice.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();
        CheckInvoiceStatistics(SalesInvoice);

        SalesInvoice.SalesLines."Line Discount %".SetValue('0');
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();
        CheckInvoiceStatistics(SalesInvoice);

        SalesInvoice.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(SalesInvoice);
        CheckInvoiceStatistics(SalesInvoice);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesInvoice."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateInvoiceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);

        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        ItemQuantity := ItemQuantity * 2;
        SalesInvoice.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();

        CheckInvoiceStatistics(SalesInvoice);

        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckInvoiceStatistics(SalesInvoice);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesInvoice."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvioceDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesInvoice(SalesHeader, SalesInvoice);

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(SalesInvoice);
        CheckInvoiceStatistics(SalesInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvioceDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckInvoiceStatistics(SalesInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();

        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();

        SalesInvoice."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesInvoice.SalesLines.Next();

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(SalesInvoice);
        CheckInvoiceStatistics(SalesInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();

        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesInvoice."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesInvoice.SalesLines.Next();

        CheckInvoiceStatistics(SalesInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();
        SalesInvoice."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesInvoice.SalesLines.Next();

        CheckInvoiceStatistics(SalesInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyindFieldOnHeaderRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustomerDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();
        SalesInvoice."Bill-to Name".SetValue(NewCustomer.Name);
        SalesInvoice.SalesLines.Next();

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(SalesInvoice);
        CheckInvoiceStatistics(SalesInvoice);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustomerDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesInvoice."Bill-to Name".SetValue(NewCustomer.Name);

        CheckInvoiceStatistics(SalesInvoice);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAddingLinesUpdatesTotalsNonModalStats()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateInvoiceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);

        CheckInvoiceSalesStatistics(SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentageNonModalStats()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateInvoiceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);
        // prepare dialog
        LibraryVariableStorage.Enqueue('Do you');
        LibraryVariableStorage.Enqueue(true);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();

        CheckInvoiceSalesStatistics(SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesTotalsAndInvDiscTypePctNonModalStats()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateInvoiceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);

        SalesInvoice.SalesLines.First();
        ItemQuantity := ItemQuantity * 2;
        SalesInvoice.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();

        CheckInvoiceSalesStatistics(SalesInvoice);

        SalesInvoice.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();

        CheckInvoiceSalesStatistics(SalesInvoice);

        SalesInvoice.SalesLines."Line Amount".SetValue(
          Round(SalesInvoice.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();
        CheckInvoiceSalesStatistics(SalesInvoice);

        SalesInvoice.SalesLines."Line Discount %".SetValue('0');
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();
        CheckInvoiceSalesStatistics(SalesInvoice);

        SalesInvoice.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(SalesInvoice);
        CheckInvoiceSalesStatistics(SalesInvoice);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesInvoice."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZeroNonModalStats()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateInvoiceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);

        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        ItemQuantity := ItemQuantity * 2;
        SalesInvoice.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();

        CheckInvoiceSalesStatistics(SalesInvoice);

        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckInvoiceSalesStatistics(SalesInvoice);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesInvoice."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvioceDiscountTypePercentageIsSetWhenInvoiceIsOpenedNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesInvoice(SalesHeader, SalesInvoice);

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(SalesInvoice);
        CheckInvoiceSalesStatistics(SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvioceDiscountTypeAmountIsSetWhenInvoiceIsOpenedNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckInvoiceSalesStatistics(SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentageNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();

        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();

        SalesInvoice."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesInvoice.SalesLines.Next();

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(SalesInvoice);
        CheckInvoiceSalesStatistics(SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmountNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();

        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesInvoice."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesInvoice.SalesLines.Next();

        CheckInvoiceSalesStatistics(SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZeroNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();
        SalesInvoice."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesInvoice.SalesLines.Next();

        CheckInvoiceSalesStatistics(SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyindFieldOnHeaderRecalculatesForInvoiceDiscountTypePercentageNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustomerDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();
        SalesInvoice."Bill-to Name".SetValue(NewCustomer.Name);
        SalesInvoice.SalesLines.Next();

        ValidateInvoiceInvoiceDiscountAmountIsReadOnly(SalesInvoice);
        CheckInvoiceSalesStatistics(SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmountNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustomerDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesInvoice."Bill-to Name".SetValue(NewCustomer.Name);

        CheckInvoiceSalesStatistics(SalesInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicePostSalesInvoiceWithDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        SalesInvoiceHeader.SetFilter("Pre-Assigned No.", SalesHeader."No.");
        Assert.IsTrue(SalesInvoiceHeader.FindFirst(), 'Posted Invoice was not found');

        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        CheckPostedInvoiceStatistics(PostedSalesInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicePostSalesInvoiceWithDiscountPrecentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        SalesInvoiceHeader.SetFilter("Pre-Assigned No.", SalesHeader."No.");
        Assert.IsTrue(SalesInvoiceHeader.FindFirst(), 'Posted Invoice was not found');

        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        CheckPostedInvoiceStatistics(PostedSalesInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceLocalCurrencySignIsSetOnTotals()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        CreateCustomer(Customer);
        Customer."Currency Code" := GetDifferentCurrencyCode();
        Customer.Modify(true);
        SalesInvoice.OpenNew();

        SalesInvoice."Sell-to Customer Name".SetValue(Customer."No.");
        InvoiceCheckCurrencyOnTotals(SalesInvoice, Customer."Currency Code");

        SalesInvoice.SalesLines.New();
        InvoiceCheckCurrencyOnTotals(SalesInvoice, Customer."Currency Code");

        SalesInvoice."Currency Code".SetValue('');
        InvoiceCheckCurrencyOnTotals(SalesInvoice, GeneralLedgerSetup.GetCurrencyCode(''));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure InvoiceApplyManualDiscount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();
        CheckInvoiceStatistics(SalesInvoice);
    end;
#endif
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceApplyManualDiscountNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();
        CheckInvoiceSalesStatistics(SalesInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceUnitofMeasureCodeNotEditableWhenItemHasSingleUOM()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 47 "Sales Invoice Subform" is NOT editable for an Item that has only one Unit of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base Unit of Measure.
        // [GIVEN] Sales Invoice with one line containing Item "I".
        CreateInvoiceThroughTestPageForItemWithGivenNumberOfUOMs(SalesInvoice, 0);

        // [WHEN] Find the Sales Line.
        SalesInvoice.SalesLines.First();

        // [THEN] Field is not editable.
        Assert.IsTrue(SalesInvoice.SalesLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsEditableMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceUnitofMeasureCodeEditableWhenItemHasMultipleUOM()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 47 "Sales Invoice Subform" is editable for an Item that has multiple Units of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base and several additional Units of Measure.
        // [GIVEN] Sales Invoice with one line containing Item "I".
        CreateInvoiceThroughTestPageForItemWithGivenNumberOfUOMs(SalesInvoice, LibraryRandom.RandInt(5));

        // [WHEN] Find the Sales Line.
        SalesInvoice.SalesLines.First();

        // [THEN] "Unit of Measure Code" field is editable.
        Assert.IsTrue(SalesInvoice.SalesLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsNotEditableMsg);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesOrder);

        CheckOrderStatistics(SalesOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesOrder);

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatistics(SalesOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesOrder);

        SalesOrder.SalesLines.First();
        ItemQuantity := ItemQuantity * 2;
        SalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();
        CheckOrderStatistics(SalesOrder);

        SalesOrder.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();
        CheckOrderStatistics(SalesOrder);

        SalesOrder.SalesLines."Line Amount".SetValue(
          Round(SalesOrder.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();
        CheckOrderStatistics(SalesOrder);

        SalesOrder.SalesLines."Line Discount %".SetValue('0');
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();
        CheckOrderStatistics(SalesOrder);

        SalesOrder.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatistics(SalesOrder);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrder."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesOrder);

        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        ItemQuantity := ItemQuantity * 2;
        SalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();

        CheckOrderStatistics(SalesOrder);

        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckOrderStatistics(SalesOrder);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrder."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);

        AnswerYesToAllConfirmDialogs();
        SalesOrder."Sell-to Customer Name".SetValue(NewCustomer.Name);
        SalesOrder.SalesLines.Next();

        CheckOrderStatistics(SalesOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesOrder(SalesHeader, SalesOrder);

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatistics(SalesOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckOrderStatistics(SalesOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);

        AnswerYesToAllConfirmDialogs();

        SalesOrder."Sell-to Customer Name".SetValue(NewCustomer.Name);
        SalesOrder.SalesLines.Next();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatistics(SalesOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesOrder."Sell-to Customer Name".SetValue(NewCustomer.Name);

        CheckOrderStatistics(SalesOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesOrder(SalesHeader, SalesOrder);

        AnswerYesToConfirmDialog();
        SalesOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatistics(SalesOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        SalesOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckOrderStatistics(SalesOrder);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderAddingLinesUpdatesTotalsNM()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesOrder);

        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentageNM()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesOrder);

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyingLineUpdatesTotalsAndInvDiscTypePctNM()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesOrder);

        SalesOrder.SalesLines.First();
        ItemQuantity := ItemQuantity * 2;
        SalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();
        CheckOrderStatisticsNM(SalesOrder);

        SalesOrder.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();
        CheckOrderStatisticsNM(SalesOrder);

        SalesOrder.SalesLines."Line Amount".SetValue(
          Round(SalesOrder.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();
        CheckOrderStatisticsNM(SalesOrder);

        SalesOrder.SalesLines."Line Discount %".SetValue('0');
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();
        CheckOrderStatisticsNM(SalesOrder);

        SalesOrder.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatisticsNM(SalesOrder);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrder."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZeroNM()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesOrder);

        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        ItemQuantity := ItemQuantity * 2;
        SalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();

        CheckOrderStatisticsNM(SalesOrder);

        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckOrderStatisticsNM(SalesOrder);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrder."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZeroNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);

        AnswerYesToAllConfirmDialogs();
        SalesOrder."Sell-to Customer Name".SetValue(NewCustomer.Name);
        SalesOrder.SalesLines.Next();

        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderDiscountTypePercentageIsSetWhenInvoiceIsOpenedNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesOrder(SalesHeader, SalesOrder);

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderDiscountTypeAmountIsSetWhenInvoiceIsOpenedNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentageNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);

        AnswerYesToAllConfirmDialogs();

        SalesOrder."Sell-to Customer Name".SetValue(NewCustomer.Name);
        SalesOrder.SalesLines.Next();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmountNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesOrder."Sell-to Customer Name".SetValue(NewCustomer.Name);

        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentageNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesOrder(SalesHeader, SalesOrder);

        AnswerYesToConfirmDialog();
        SalesOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmountNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        SalesOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPostSalesInvoiceWithDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        SalesHeader.Validate(Invoice, true);
        SalesHeader.Validate(Ship, true);
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        SalesInvoiceHeader.SetFilter("Order No.", SalesHeader."No.");
        Assert.IsTrue(SalesInvoiceHeader.FindFirst(), 'Posted Order was not found');

        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        CheckPostedInvoiceStatistics(PostedSalesInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPostSalesInvoiceWithDiscountPrecentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesHeader.Validate(Invoice, true);
        SalesHeader.Validate(Ship, true);
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        SalesInvoiceHeader.SetFilter("Order No.", SalesHeader."No.");
        Assert.IsTrue(SalesInvoiceHeader.FindFirst(), 'Posted Order was not found');

        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        CheckPostedInvoiceStatistics(PostedSalesInvoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderSetLocalCurrencySignOnTotals()
    var
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        CreateCustomer(Customer);
        Customer."Currency Code" := GetDifferentCurrencyCode();
        Customer.Modify(true);
        SalesOrder.OpenNew();

        SalesOrder."Sell-to Customer Name".SetValue(Customer."No.");
        OrderCheckCurrencyOnTotals(SalesOrder, Customer."Currency Code");

        SalesOrder.SalesLines.New();
        OrderCheckCurrencyOnTotals(SalesOrder, Customer."Currency Code");

        SalesOrder."Currency Code".SetValue('');
        OrderCheckCurrencyOnTotals(SalesOrder, GeneralLedgerSetup.GetCurrencyCode(''));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure OrderApplyManualDiscount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesOrder.CalculateInvoiceDiscount.Invoke();
        CheckOrderStatistics(SalesOrder);
    end;
#endif
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OrderApplyManualDiscountNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesOrder.CalculateInvoiceDiscount.Invoke();
        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderUnitofMeasureCodeNotEditableWhenItemHasSingleUOM()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales Order]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 46 "Sales Order Subform" is NOT editable for an Item that has only one Unit of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base Unit of Measure.
        // [GIVEN] Sales Order with one line containing Item "I".
        CreateOrderThroughTestPageForItemWithGivenNumberOfUOMs(SalesOrder, 0);

        // [WHEN] Find the Sales Line.
        SalesOrder.SalesLines.First();

        // [THEN] Field is editable.
        Assert.IsTrue(SalesOrder.SalesLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsEditableMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderUnitofMeasureCodeEditableWhenItemHasMultipleUOM()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales Order]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 46 "Sales Order Subform" is editable for an Item that has multiple Units of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base and several additional Units of Measure.
        // [GIVEN] Sales Order with one line containing Item "I".
        CreateOrderThroughTestPageForItemWithGivenNumberOfUOMs(SalesOrder, LibraryRandom.RandInt(5));

        // [WHEN] Find the Sales Line.
        SalesOrder.SalesLines.First();

        // [THEN] "Unit of Measure Code" field is editable.
        Assert.IsTrue(SalesOrder.SalesLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsNotEditableMsg);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateQuoteWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesQuote);

        CheckQuoteStatistics(SalesQuote);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateQuoteWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesQuote);

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(SalesQuote);
        CheckQuoteStatistics(SalesQuote);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateQuoteWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesQuote);

        ItemQuantity := ItemQuantity * 2;
        SalesQuote.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.First();
        CheckQuoteStatistics(SalesQuote);

        SalesQuote.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.First();
        CheckQuoteStatistics(SalesQuote);

        SalesQuote.SalesLines."Line Amount".SetValue(
          Round(SalesQuote.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.First();
        CheckQuoteStatistics(SalesQuote);

        SalesQuote.SalesLines."Line Discount %".SetValue('0');
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.First();
        CheckQuoteStatistics(SalesQuote);

        SalesQuote.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.First();

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(SalesQuote);
        CheckQuoteStatistics(SalesQuote);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
        SalesLine.SetRange("Document No.", SalesQuote."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesQuote(SalesHeader, SalesQuote);

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(SalesQuote);
        CheckQuoteStatistics(SalesQuote);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckQuoteStatistics(SalesQuote);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);

        AnswerYesToAllConfirmDialogs();
        SalesQuote."Sell-to Customer Name".SetValue(NewCustomer.Name);
        SalesQuote.SalesLines.Next();

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(SalesQuote);
        CheckQuoteStatistics(SalesQuote);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesQuote."Sell-to Customer Name".SetValue(NewCustomer.Name);

        CheckQuoteStatistics(SalesQuote);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);

        AnswerYesToAllConfirmDialogs();
        SalesQuote."Sell-to Customer Name".SetValue(NewCustomer.Name);
        SalesQuote.SalesLines.Next();

        CheckQuoteStatistics(SalesQuote);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesQuote(SalesHeader, SalesQuote);

        AnswerYesToConfirmDialog();
        SalesQuote."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(SalesQuote);
        CheckQuoteStatistics(SalesQuote);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesQuote."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        CheckQuoteStatistics(SalesQuote);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteAddingLinesUpdatesTotalsNonModalStats()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateQuoteWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesQuote);

        CheckQuoteSalesStatistics(SalesQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentageNonModalStats()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateQuoteWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesQuote);

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(SalesQuote);
        CheckQuoteSalesStatistics(SalesQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyingLineUpdatesTotalsAndInvDiscTypePctNonModalStats()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateQuoteWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesQuote);

        ItemQuantity := ItemQuantity * 2;
        SalesQuote.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.First();
        CheckQuoteSalesStatistics(SalesQuote);

        SalesQuote.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.First();
        CheckQuoteSalesStatistics(SalesQuote);

        SalesQuote.SalesLines."Line Amount".SetValue(
          Round(SalesQuote.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.First();
        CheckQuoteSalesStatistics(SalesQuote);

        SalesQuote.SalesLines."Line Discount %".SetValue('0');
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.First();
        CheckQuoteSalesStatistics(SalesQuote);

        SalesQuote.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.First();

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(SalesQuote);
        CheckQuoteSalesStatistics(SalesQuote);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
        SalesLine.SetRange("Document No.", SalesQuote."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteDiscountTypePercentageIsSetWhenInvoiceIsOpenedNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesQuote(SalesHeader, SalesQuote);

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(SalesQuote);
        CheckQuoteSalesStatistics(SalesQuote);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteDiscountTypeAmountIsSetWhenInvoiceIsOpenedNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckQuoteSalesStatistics(SalesQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentageNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);

        AnswerYesToAllConfirmDialogs();
        SalesQuote."Sell-to Customer Name".SetValue(NewCustomer.Name);
        SalesQuote.SalesLines.Next();

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(SalesQuote);
        CheckQuoteSalesStatistics(SalesQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmountNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesQuote."Sell-to Customer Name".SetValue(NewCustomer.Name);

        CheckQuoteSalesStatistics(SalesQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZeroNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);

        AnswerYesToAllConfirmDialogs();
        SalesQuote."Sell-to Customer Name".SetValue(NewCustomer.Name);
        SalesQuote.SalesLines.Next();

        CheckQuoteSalesStatistics(SalesQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentageNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesQuote(SalesHeader, SalesQuote);

        AnswerYesToConfirmDialog();
        SalesQuote."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        Assert.IsFalse(SalesLine.IsEmpty(), 'Sales Line not found');

        ValidateQuoteInvoiceDiscountAmountIsReadOnly(SalesQuote);
        CheckQuoteSalesStatistics(SalesQuote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmountNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesQuote."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        Assert.IsFalse(SalesLine.IsEmpty(), 'Sales Line not found');

        CheckQuoteSalesStatistics(SalesQuote);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteMakeOrderDiscountTypePercentageIsKept()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesQuote(SalesHeader, SalesQuote);

        SalesOrder.Trap();
        AnswerYesToAllConfirmDialogs();
        SalesQuote.MakeOrder.Invoke();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatistics(SalesOrder);
    end;
#endif
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteMakeOrderDiscountTypePercentageIsKeptNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesQuote(SalesHeader, SalesQuote);

        SalesOrder.Trap();
        AnswerYesToAllConfirmDialogs();
        SalesQuote.MakeOrder.Invoke();

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteSetLocalCurrencySignOnTotals()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        CreateCustomer(Customer);
        Customer."Currency Code" := GetDifferentCurrencyCode();
        Customer.Modify(true);
        SalesQuote.OpenNew();

        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);
        QuoteCheckCurrencyOnTotals(SalesQuote, Customer."Currency Code");

        SalesQuote.SalesLines.New();
        QuoteCheckCurrencyOnTotals(SalesQuote, Customer."Currency Code");

        SalesQuote."Currency Code".SetValue('');
        QuoteCheckCurrencyOnTotals(SalesQuote, GeneralLedgerSetup.GetCurrencyCode(''));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure QuoteApplyManualDiscount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesQuote.CalculateInvoiceDiscount.Invoke();
        CheckQuoteStatistics(SalesQuote);
    end;
#endif
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure QuoteApplyManualDiscountNonModal()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesQuote.CalculateInvoiceDiscount.Invoke();
        CheckQuoteSalesStatistics(SalesQuote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteUnitofMeasureCodeNotEditableWhenItemHasSingleUOM()
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 95 "Sales Quote Subform" is NOT editable for an Item that has only one Unit of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base Unit of Measure.
        // [GIVEN] Sales Quote with one line containing Item "I".
        CreateQuoteThroughTestPageForItemWithGivenNumberOfUOMs(SalesQuote, 0);

        // [WHEN] Find the Sales Line.
        SalesQuote.SalesLines.First();

        // [THEN] Field is editable.
        Assert.IsTrue(SalesQuote.SalesLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsEditableMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteUnitofMeasureCodeEditableWhenItemHasMultipleUOM()
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 95 "Sales Quote Subform" is editable for an Item that has multiple Units of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base and several additional Units of Measure.
        // [GIVEN] Sales Quote with one line containing Item "I".
        CreateQuoteThroughTestPageForItemWithGivenNumberOfUOMs(SalesQuote, LibraryRandom.RandInt(5));

        // [WHEN] Find the Sales Line.
        SalesQuote.SalesLines.First();

        // [THEN] "Unit of Measure Code" field is editable.
        Assert.IsTrue(SalesQuote.SalesLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsNotEditableMsg);
    end;

#if not CLEAN26
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateBlanketOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, BlanketSalesOrder);
        CheckBlanketOrderStatistics(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateBlanketOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, BlanketSalesOrder);

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketSalesOrder);

        CheckBlanketOrderStatistics(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateBlanketOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, BlanketSalesOrder);

        ItemQuantity := ItemQuantity * 2;
        BlanketSalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.First();
        CheckBlanketOrderStatistics(BlanketSalesOrder);

        BlanketSalesOrder.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.First();
        CheckBlanketOrderStatistics(BlanketSalesOrder);

        BlanketSalesOrder.SalesLines."Line Amount".SetValue(
          Round(BlanketSalesOrder.SalesLines."Line Amount".AsDecimal() / 2, 1));
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.First();
        CheckBlanketOrderStatistics(BlanketSalesOrder);

        BlanketSalesOrder.SalesLines."Line Discount %".SetValue('0');
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.First();
        CheckBlanketOrderStatistics(BlanketSalesOrder);

        BlanketSalesOrder.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.First();

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketSalesOrder);
        CheckBlanketOrderStatistics(BlanketSalesOrder);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Blanket Order");
        SalesLine.SetRange("Document No.", BlanketSalesOrder."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketSalesOrder);
        CheckBlanketOrderStatistics(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);
        BlanketSalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckBlanketOrderStatistics(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrdereChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        AnswerYesToAllConfirmDialogs();
        BlanketSalesOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");
        BlanketSalesOrder.SalesLines.Next();

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketSalesOrder);
        CheckBlanketOrderStatistics(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);
        BlanketSalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        BlanketSalesOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");

        CheckBlanketOrderStatistics(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderChangeSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        AnswerYesToAllConfirmDialogs();
        BlanketSalesOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");
        BlanketSalesOrder.SalesLines.Next();

        CheckBlanketOrderStatistics(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        AnswerYesToConfirmDialog();
        BlanketSalesOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketSalesOrder);
        CheckBlanketOrderStatistics(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);
        BlanketSalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        BlanketSalesOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        CheckBlanketOrderStatistics(BlanketSalesOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,BlanketOrderConvertedMessageHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderMakeOrderDiscountTypePercentageIsKept()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        AnswerYesToAllConfirmDialogs();
        BlanketSalesOrder.MakeOrder.Invoke();

        SalesHeader.Reset();
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst();

        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatistics(SalesOrder);
    end;
#endif
    [Test]
    [HandlerFunctions('ConfirmHandler,BlanketOrderConvertedMessageHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderMakeOrderDiscountTypePercentageIsKeptNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        AnswerYesToAllConfirmDialogs();
        BlanketSalesOrder.MakeOrder.Invoke();

        SalesHeader.Reset();
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst();

        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        ValidateOrderInvoiceDiscountAmountIsReadOnly(SalesOrder);
        CheckOrderStatisticsNM(SalesOrder);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderAddingLinesUpdatesTotalsNM()
    var
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateBlanketOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, BlanketSalesOrder);
        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentageNM()
    var
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateBlanketOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, BlanketSalesOrder);

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketSalesOrder);

        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyingLineUpdatesTotalsAndInvDiscTypePctNM()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateBlanketOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, BlanketSalesOrder);

        ItemQuantity := ItemQuantity * 2;
        BlanketSalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.First();
        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);

        BlanketSalesOrder.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.First();
        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);

        BlanketSalesOrder.SalesLines."Line Amount".SetValue(
          Round(BlanketSalesOrder.SalesLines."Line Amount".AsDecimal() / 2, 1));
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.First();
        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);

        BlanketSalesOrder.SalesLines."Line Discount %".SetValue('0');
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.First();
        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);

        BlanketSalesOrder.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.First();

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketSalesOrder);
        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Blanket Order");
        SalesLine.SetRange("Document No.", BlanketSalesOrder."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderDiscountTypePercentageIsSetWhenInvoiceIsOpenedNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketSalesOrder);
        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderDiscountTypeAmountIsSetWhenInvoiceIsOpenedNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);
        BlanketSalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrdereChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentageNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        AnswerYesToAllConfirmDialogs();
        BlanketSalesOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");
        BlanketSalesOrder.SalesLines.Next();

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketSalesOrder);
        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmountNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);
        BlanketSalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        BlanketSalesOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");

        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderChangeSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZeroNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        AnswerYesToAllConfirmDialogs();
        BlanketSalesOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");
        BlanketSalesOrder.SalesLines.Next();

        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentageNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        AnswerYesToConfirmDialog();
        BlanketSalesOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(BlanketSalesOrder);
        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmountNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);
        BlanketSalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        BlanketSalesOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderSetLocalCurrencySignOnTotals()
    var
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        Initialize();

        CreateCustomer(Customer);
        Customer."Currency Code" := GetDifferentCurrencyCode();
        Customer.Modify(true);
        BlanketSalesOrder.OpenNew();

        BlanketSalesOrder."Sell-to Customer Name".SetValue(Customer."No.");
        BlanketOrderCheckCurrencyOnTotals(BlanketSalesOrder, Customer."Currency Code");

        BlanketSalesOrder.SalesLines.New();
        BlanketOrderCheckCurrencyOnTotals(BlanketSalesOrder, Customer."Currency Code");

        BlanketSalesOrder.SalesLines.Description.SetValue(ItemTestDescriptionLbl);
        BlanketOrderCheckCurrencyOnTotals(BlanketSalesOrder, Customer."Currency Code");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderApplyManualDiscount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        BlanketSalesOrder.CalculateInvoiceDiscount.Invoke();
        CheckBlanketOrderStatistics(BlanketSalesOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateReturnOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesReturnOrder);
        CheckReturnOrderStatistics(SalesReturnOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateReturnOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesReturnOrder);

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(SalesReturnOrder);
        CheckReturnOrderStatistics(SalesReturnOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateReturnOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesReturnOrder);

        SalesReturnOrder.SalesLines.First();
        ItemQuantity := ItemQuantity * 2;
        SalesReturnOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();
        CheckReturnOrderStatistics(SalesReturnOrder);

        SalesReturnOrder.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();
        CheckReturnOrderStatistics(SalesReturnOrder);

        SalesReturnOrder.SalesLines."Line Amount".SetValue(
          Round(SalesReturnOrder.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();
        CheckReturnOrderStatistics(SalesReturnOrder);

        SalesReturnOrder.SalesLines."Line Discount %".SetValue('0');
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();
        CheckReturnOrderStatistics(SalesReturnOrder);

        SalesReturnOrder.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(SalesReturnOrder);
        CheckReturnOrderStatistics(SalesReturnOrder);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesReturnOrder."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZero()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateReturnOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesReturnOrder);

        SalesReturnOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        ItemQuantity := ItemQuantity * 2;
        SalesReturnOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();

        CheckReturnOrderStatistics(SalesReturnOrder);

        SalesReturnOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckReturnOrderStatistics(SalesReturnOrder);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesReturnOrder."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        CheckReturnOrderStatistics(SalesReturnOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);
        SalesReturnOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckReturnOrderStatistics(SalesReturnOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        AnswerYesToAllConfirmDialogs();

        SalesReturnOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesReturnOrder.SalesLines.Next();

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(SalesReturnOrder);
        CheckReturnOrderStatistics(SalesReturnOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);
        SalesReturnOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesReturnOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesReturnOrder.SalesLines.Next();

        CheckReturnOrderStatistics(SalesReturnOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangeSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        AnswerYesToAllConfirmDialogs();
        SalesReturnOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesReturnOrder.SalesLines.Next();

        CheckReturnOrderStatistics(SalesReturnOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        AnswerYesToConfirmDialog();
        SalesReturnOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(SalesReturnOrder);
        CheckReturnOrderStatistics(SalesReturnOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);
        SalesReturnOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        SalesReturnOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        CheckReturnOrderStatistics(SalesReturnOrder);
    end;
#endif
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrderApplyManualDiscountNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateBlanketOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        BlanketSalesOrder.CalculateInvoiceDiscount.Invoke();
        CheckBlanketOrderStatisticsNM(BlanketSalesOrder);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderAddingLinesUpdatesTotalsNM()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateReturnOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesReturnOrder);
        CheckReturnOrderStatisticsNM(SalesReturnOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentageNM()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateReturnOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesReturnOrder);

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(SalesReturnOrder);
        CheckReturnOrderStatisticsNM(SalesReturnOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyingLineUpdatesTotalsAndInvDiscTypePctNM()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateReturnOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesReturnOrder);

        SalesReturnOrder.SalesLines.First();
        ItemQuantity := ItemQuantity * 2;
        SalesReturnOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();
        CheckReturnOrderStatisticsNM(SalesReturnOrder);

        SalesReturnOrder.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();
        CheckReturnOrderStatisticsNM(SalesReturnOrder);

        SalesReturnOrder.SalesLines."Line Amount".SetValue(
          Round(SalesReturnOrder.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();
        CheckReturnOrderStatisticsNM(SalesReturnOrder);

        SalesReturnOrder.SalesLines."Line Discount %".SetValue('0');
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();
        CheckReturnOrderStatisticsNM(SalesReturnOrder);

        SalesReturnOrder.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(SalesReturnOrder);
        CheckReturnOrderStatisticsNM(SalesReturnOrder);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesReturnOrder."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyingLineUpdatesTotalsAndSetsInvDiscTypeAmountToZeroNM()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateReturnOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesReturnOrder);

        SalesReturnOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        ItemQuantity := ItemQuantity * 2;
        SalesReturnOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();

        CheckReturnOrderStatisticsNM(SalesReturnOrder);

        SalesReturnOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckReturnOrderStatisticsNM(SalesReturnOrder);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesReturnOrder."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderDiscountTypePercentageIsSetWhenInvoiceIsOpenedNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        CheckReturnOrderStatisticsNM(SalesReturnOrder);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderDiscountTypeAmountIsSetWhenInvoiceIsOpenedNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);
        SalesReturnOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckReturnOrderStatisticsNM(SalesReturnOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentageNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        AnswerYesToAllConfirmDialogs();

        SalesReturnOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesReturnOrder.SalesLines.Next();

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(SalesReturnOrder);
        CheckReturnOrderStatisticsNM(SalesReturnOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmountNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);
        SalesReturnOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesReturnOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesReturnOrder.SalesLines.Next();

        CheckReturnOrderStatisticsNM(SalesReturnOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderChangeSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZeroNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        AnswerYesToAllConfirmDialogs();
        SalesReturnOrder."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesReturnOrder.SalesLines.Next();

        CheckReturnOrderStatisticsNM(SalesReturnOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentageNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        AnswerYesToConfirmDialog();
        SalesReturnOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(SalesReturnOrder);
        CheckReturnOrderStatisticsNM(SalesReturnOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmountNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);
        SalesReturnOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        SalesReturnOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        CheckReturnOrderStatisticsNM(SalesReturnOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOrderPostInvoiceDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NumberOfLines: Integer;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        SalesHeader.Validate(Invoice, true);
        SalesHeader.Validate(Receive, true);
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        SalesCrMemoHeader.SetFilter("Sell-to Customer No.", Customer."No.");
        Assert.IsTrue(SalesCrMemoHeader.FindFirst(), 'Posted ReturnOrder was not found');

        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);
        CheckPostedCreditMemoStatistics(PostedSalesCreditMemo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOrderPostInvoiceDiscountPrecentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesHeader.Validate(Invoice, true);
        SalesHeader.Validate(Receive, true);
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        SalesCrMemoHeader.SetFilter("Sell-to Customer No.", Customer."No.");
        Assert.IsTrue(SalesCrMemoHeader.FindFirst(), 'Posted ReturnOrder was not found');

        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);

        CheckPostedCreditMemoStatistics(PostedSalesCreditMemo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOrderSetLocalCurrencySignOnTotals()
    var
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        Initialize();

        CreateCustomer(Customer);
        Customer."Currency Code" := GetDifferentCurrencyCode();
        Customer.Modify(true);
        SalesReturnOrder.OpenNew();

        SalesReturnOrder."Sell-to Customer Name".SetValue(Customer."No.");
        ReturnOrderCheckCurrencyOnTotals(SalesReturnOrder, Customer."Currency Code");

        SalesReturnOrder.SalesLines.New();
        ReturnOrderCheckCurrencyOnTotals(SalesReturnOrder, Customer."Currency Code");

        SalesReturnOrder.SalesLines.Description.SetValue(ItemTestDescriptionLbl);
        ReturnOrderCheckCurrencyOnTotals(SalesReturnOrder, Customer."Currency Code");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderApplyManualDiscount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesReturnOrder.CalculateInvoiceDiscount.Invoke();
        CheckReturnOrderStatistics(SalesReturnOrder);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);

        CheckCreditMemoStatistics(SalesCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(SalesCreditMemo);
        CheckCreditMemoStatistics(SalesCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUOM: Record "Item Unit of Measure";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);

        ItemQuantity := ItemQuantity * 2;
        SalesCreditMemo.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();
        CheckCreditMemoStatistics(SalesCreditMemo);

        SalesCreditMemo.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();
        CheckCreditMemoStatistics(SalesCreditMemo);

        UnitOfMeasure.Init();
        UnitOfMeasure.Validate(
          Code,
          LibraryUtility.GenerateRandomCode(UnitOfMeasure.FieldNo(Code), DATABASE::"Unit of Measure"));
        UnitOfMeasure.Insert();

        ItemUOM.Init();
        ItemUOM.Validate("Item No.", Item."No.");
        ItemUOM.Validate(Code, UnitOfMeasure.Code);
        ItemUOM.Validate("Qty. per Unit of Measure", 5);
        ItemUOM.Insert();
        SalesCreditMemo.SalesLines."Unit of Measure Code".SetValue(ItemUOM.Code);
        TotalAmount := ItemQuantity * Item."Unit Price" * 5;
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();
        CheckCreditMemoStatistics(SalesCreditMemo);

        SalesCreditMemo.SalesLines."Line Amount".SetValue(
          Round(SalesCreditMemo.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();
        CheckCreditMemoStatistics(SalesCreditMemo);

        SalesCreditMemo.SalesLines."Line Discount %".SetValue('0');
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();
        CheckCreditMemoStatistics(SalesCreditMemo);

        SalesCreditMemo.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(SalesCreditMemo);
        CheckCreditMemoStatistics(SalesCreditMemo);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesCreditMemo."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoInvioceDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(SalesCreditMemo);
        CheckCreditMemoStatistics(SalesCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoInvioceDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckCreditMemoStatistics(SalesCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        AnswerYesToAllConfirmDialogs();

        SalesCreditMemo."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesCreditMemo.SalesLines.Next();

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(SalesCreditMemo);
        CheckCreditMemoStatistics(SalesCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesCreditMemo."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesCreditMemo.SalesLines.Next();

        CheckCreditMemoStatistics(SalesCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangeSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        AnswerYesToAllConfirmDialogs();
        SalesCreditMemo."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesCreditMemo.SalesLines.Next();

        CheckCreditMemoStatistics(SalesCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        AnswerYesToConfirmDialog();
        SalesCreditMemo."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(SalesCreditMemo);
        CheckCreditMemoStatistics(SalesCreditMemo);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        SalesCreditMemo."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        CheckCreditMemoStatistics(SalesCreditMemo);
    end;
#endif
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderApplyManualDiscountNM()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateReturnOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesReturnOrder.CalculateInvoiceDiscount.Invoke();
        CheckReturnOrderStatisticsNM(SalesReturnOrder);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoAddingLinesUpdatesTotalsNonModalStats()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);

        CheckCreditMemoSalesStatistics(SalesCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentageNonModalStats()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(SalesCreditMemo);
        CheckCreditMemoSalesStatistics(SalesCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyingLineUpdatesTotalsAndInvDiscTypePctNonModalStats()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUOM: Record "Item Unit of Measure";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);

        ItemQuantity := ItemQuantity * 2;
        SalesCreditMemo.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();
        CheckCreditMemoSalesStatistics(SalesCreditMemo);

        SalesCreditMemo.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();
        CheckCreditMemoSalesStatistics(SalesCreditMemo);

        UnitOfMeasure.Init();
        UnitOfMeasure.Validate(
          Code,
          LibraryUtility.GenerateRandomCode(UnitOfMeasure.FieldNo(Code), DATABASE::"Unit of Measure"));
        UnitOfMeasure.Insert();

        ItemUOM.Init();
        ItemUOM.Validate("Item No.", Item."No.");
        ItemUOM.Validate(Code, UnitOfMeasure.Code);
        ItemUOM.Validate("Qty. per Unit of Measure", 5);
        ItemUOM.Insert();
        SalesCreditMemo.SalesLines."Unit of Measure Code".SetValue(ItemUOM.Code);
        TotalAmount := ItemQuantity * Item."Unit Price" * 5;
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();
        CheckCreditMemoSalesStatistics(SalesCreditMemo);

        SalesCreditMemo.SalesLines."Line Amount".SetValue(
          Round(SalesCreditMemo.SalesLines."Line Amount".AsDecimal() / 2, 1));
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();
        CheckCreditMemoSalesStatistics(SalesCreditMemo);

        SalesCreditMemo.SalesLines."Line Discount %".SetValue('0');
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();
        CheckCreditMemoSalesStatistics(SalesCreditMemo);

        SalesCreditMemo.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(SalesCreditMemo);
        CheckCreditMemoSalesStatistics(SalesCreditMemo);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesCreditMemo."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoInvioceDiscountTypePercentageIsSetWhenInvoiceIsOpenedNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(SalesCreditMemo);
        CheckCreditMemoSalesStatistics(SalesCreditMemo);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoInvioceDiscountTypeAmountIsSetWhenInvoiceIsOpenedNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        CheckCreditMemoSalesStatistics(SalesCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentageNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        AnswerYesToAllConfirmDialogs();

        SalesCreditMemo."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesCreditMemo.SalesLines.Next();

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(SalesCreditMemo);
        CheckCreditMemoSalesStatistics(SalesCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingSellToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmountNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToAllConfirmDialogs();
        SalesCreditMemo."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesCreditMemo.SalesLines.Next();

        CheckCreditMemoSalesStatistics(SalesCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangeSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZeroNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        CreateCustomer(NewCustomer);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        AnswerYesToAllConfirmDialogs();
        SalesCreditMemo."Sell-to Customer Name".SetValue(NewCustomer."No.");
        SalesCreditMemo.SalesLines.Next();

        CheckCreditMemoSalesStatistics(SalesCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyindFieldOnHeaderUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentageNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        AnswerYesToConfirmDialog();
        SalesCreditMemo."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        Assert.IsFalse(SalesLine.IsEmpty(), 'Sales Line not found');

        ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(SalesCreditMemo);
        CheckCreditMemoSalesStatistics(SalesCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyindFieldOnHeaderSetsDiscountToZeroForInvoiceDiscountTypeAmountNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        SalesCreditMemo."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        Assert.IsFalse(SalesLine.IsEmpty(), 'Sales Line not found');

        CheckCreditMemoSalesStatistics(SalesCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoPostInvoiceDiscountAmount()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        AnswerYesToConfirmDialog();
        SalesCreditMemo.Post.Invoke();

        SalesCrMemoHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesCrMemoHeader.FindLast();

        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);

        CheckPostedCreditMemoStatistics(PostedSalesCreditMemo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoPostInvoiceDiscountPrecentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        SalesCrMemoHeader.SetFilter("Pre-Assigned No.", SalesHeader."No.");
        Assert.IsTrue(SalesCrMemoHeader.FindFirst(), 'Posted CreditMemo was not found');

        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);

        CheckPostedCreditMemoStatistics(PostedSalesCreditMemo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoSetLocalCurrencySignOnTotals()
    var
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        CreateCustomer(Customer);
        Customer."Currency Code" := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        Customer.Modify(true);
        SalesCreditMemo.OpenNew();

        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer."No.");
        CreditMemoCheckCurrencyOnTotals(SalesCreditMemo, Customer."Currency Code");

        SalesCreditMemo.SalesLines.New();
        CreditMemoCheckCurrencyOnTotals(SalesCreditMemo, Customer."Currency Code");

        SalesCreditMemo."Currency Code".SetValue('');
        CreditMemoCheckCurrencyOnTotals(SalesCreditMemo, GeneralLedgerSetup.GetCurrencyCode(''));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoApplyManualDiscount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesCreditMemo.CalculateInvoiceDiscount.Invoke();
        CheckCreditMemoStatistics(SalesCreditMemo);
    end;
#endif
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoApplyManualDiscountNonModalStats()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        SetAllowManualDisc();

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        LibraryVariableStorage.Enqueue(CalculateInvoiceDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        SalesCreditMemo.CalculateInvoiceDiscount.Invoke();
        CheckCreditMemoSalesStatistics(SalesCreditMemo);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoUnitofMeasureCodeNotEditableWhenItemHasSingleUOM()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 96 "Sales Cr. Memo Subform" is  editable for an Item that has only one Unit of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base Unit of Measure.
        // [GIVEN] Sales Credit Memo with one line containing Item "I".
        CreateCrMemoThroughTestPageForItemWithGivenNumberOfUOMs(SalesCreditMemo, 0);

        // [WHEN] Find the Sales Line.
        SalesCreditMemo.SalesLines.First();

        // [THEN] Field is editable.
        Assert.IsTrue(SalesCreditMemo.SalesLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsEditableMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoUnitofMeasureCodeEditableWhenItemHasMultipleUOM()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 161627] Field "Unit of Measure Code" in page 96 "Sales Cr. Memo Subform" is editable for an Item that has multiple Units of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base and several additional Units of Measure.
        // [GIVEN] Sales Credit Memo with one line containing Item "I".
        CreateCrMemoThroughTestPageForItemWithGivenNumberOfUOMs(SalesCreditMemo, LibraryRandom.RandInt(5));

        // [WHEN] Find the Sales Line.
        SalesCreditMemo.SalesLines.First();

        // [THEN] "Unit of Measure Code" field is editable.
        Assert.IsTrue(SalesCreditMemo.SalesLines."Unit of Measure Code".Editable(), UnitofMeasureCodeIsNotEditableMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExternalDocNoBlanketSalesOrderPage()
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [Blanket Order] [Sales]
        // [SCENARIO 375875] Blanket Sales Order Page should have "External Document No." enabled
        Initialize();

        BlanketSalesOrder.Trap();
        BlanketSalesOrder.OpenNew();

        Assert.IsTrue(BlanketSalesOrder."External Document No.".Enabled(), ExternalDocNoErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DimensionSetTreeNodeOnCalculatingTotals()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        DimSetTreeNode: Record "Dimension Set Tree Node";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        GLAccountNo: Code[20];
        ItemQuantity: Decimal;
        DimValueID: Integer;
    begin
        // [FEATURE] [Totals] [Dimension]
        // [SCENARIO 376946] No Dimension Set Tree Node should be created on calculating Totals
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        // [GIVEN] Sales Credit Memo with Invoice Discount but not Dimensions
        GLAccountNo := CreateGLAccountForInvoiceRounding(Customer."Customer Posting Group");

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);

        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.FindFirst();
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Default Dimension "D" on invoice rounding G/L Account
        DimValueID := CreateDimOnGLAccount(GLAccountNo);

        // [WHEN] Calculate Totals by Open Sales Credit Memo Page
        SalesCreditMemo.Close();
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.Close();

        // [THEN] No Dimension Set Tree Node is created for "D"
        DimSetTreeNode.Init(); // PreCAL trick
        DimSetTreeNode.SetRange("Dimension Value ID", DimValueID);
        Assert.RecordIsEmpty(DimSetTreeNode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesLineAccountNoAfterRelease()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Totals] [Service charge] [Invoice Discount]
        // [SCENARIO 378348] It should be not possible to change sales line account number for released document
        Initialize();

        CreateCustomerWithServiceChargeDiscount(Customer);

        // [GIVEN] Released Sales Order with one line and Sales Invoice Discount
        CreateOrderAndCalcDiscounts(SalesHeader, Customer."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Change service charge account number
        UpdateAccountNoOnSalesLine(
          SalesHeader."No.", LibraryERM.CreateGLAccountWithSalesSetup());

        // [THEN] No Error
    end;

    [Test]
    [HandlerFunctions('ItemUnitofMeasureModalHandler')]
    [Scope('OnPrem')]
    procedure SalesLineUnitofMeasureCodeLookupItem()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        BaseUOMCode: Code[10];
        AdditionalUOMCode: Code[10];
    begin
        // [FEATURE] [UT] [Unit of Measure]
        // [SCENARIO 161627] Lookup is active for "Unit of Measure Code" field for an Item that has multiple Units of Measure.
        Initialize();

        // [GIVEN] Item "I" with Base and several additional Units of Measure.
        // [GIVEN] Sales Document with one line containing Item "I".
        CreateSalesDocumentForItemWithGivenNumberOfUOMs(SalesLine, LibraryRandom.RandIntInRange(2, 5));
        BaseUOMCode := SalesLine."Unit of Measure Code";
        AdditionalUOMCode := FindFirstAdditionalItemUOMCode(SalesLine."No.", BaseUOMCode);

        // [WHEN] Invoke Lookup on "Unit of Measure Code" field. Select first additional UOM.
        LibraryVariableStorage.Enqueue(AdditionalUOMCode);
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesLine."Document Type", SalesLine."Document No.");
        SalesOrder.SalesLines."Unit of Measure Code".Lookup();
        SalesOrder.Close();

        // [THEN] Lookup is available. Unit of Measure Code is changed.
        SalesLine.Find();
        SalesLine.TestField("Unit of Measure Code", AdditionalUOMCode);
    end;

    [Test]
    [HandlerFunctions('ResourceUnitofMeasureModalHandler')]
    [Scope('OnPrem')]
    procedure SalesLineUnitofMeasureCodeLookupResource()
    var
        Resource: Record Resource;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesOrder: TestPage "Sales Order";
        ResourceUOMCode: Variant;
    begin
        // [FEATURE] [UT] [Unit of Measure]
        // [SCENARIO 161627] Lookup is active for "Unit of Measure Code" field for a Resource.
        Initialize();

        // [GIVEN] Sales Document with one line containing a Resource.
        LibraryResource.CreateResource(Resource, '');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Resource.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Resource.Modify();
        ResourceUOMCode := Resource."Base Unit of Measure";
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));

        // [WHEN] Invoke Lookup on "Unit of Measure Code" field.
        LibraryVariableStorage.Enqueue(ResourceUOMCode);
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesLine."Document Type", SalesLine."Document No.");
        SalesOrder.SalesLines."Unit of Measure Code".Lookup();

        // [THEN] Lookup is available. Resource Base Unit of Measure Code is read.
        SalesLine.Find();
        SalesLine.TestField("Unit of Measure Code", Format(ResourceUOMCode));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeclineConfirmationOnChangingInvDiscountAmountInSalesOrderWithPostedLine()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 208219] When a line of Sales Order is posted and "Inv. Discount Amount" is updated at subpage, then confirmation appears. If confirmation is declined, then "Inv. Discount Amount" is not changed.

        Initialize();

        // [GIVEN] Sales Order with 2 lines
        // [GIVEN] Sales Line 1 has "Qty. to Ship" = "Qty. to Invoice" = "Quantity"
        // [GIVEN] Sales Line 2 has "Qty. to Ship" = "Qty. to Invoice" = 0
        // [GIVEN] Sales Line 1 is posted
        SalesHeaderNo := CreateSalesOrderAndPostOneOfTwoLines();

        // [GIVEN] "Inv. Discount Amount" is updated in Sales Order Subform
        LibraryVariableStorage.Enqueue(UpdateInvDiscountQst);
        LibraryVariableStorage.Enqueue(false);
        SetInvDiscAmountInSalesOrderSubPage(SalesHeaderNo);

        // [GIVEN] Confirmation appears: "One or more lines have been invoiced. The discount distributed to invoiced lines will not be taken into account.\\Do you want to update the invoice discount?"
        // Message check is performed in Confirm handler

        // [WHEN] Confirmation declined
        // FALSE is passed to Confirm handler

        // [THEN] "Inv. Discount Amount" is not changed
        VerifyInvDiscAmountInSalesOrderSubpage(SalesHeaderNo, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AceptConfirmationOnChangingInvDiscountAmountInSalesOrderWithPostedLine()
    var
        InvDiscountAmount: Integer;
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 208219] When a line of Sales Order is posted and "Inv. Discount Amount" is updated at subpage, then confirmation appears. If confirmation is acepted, then "Inv. Discount Amount" is changed.

        Initialize();

        // [GIVEN] Sales Order with 2 lines
        // [GIVEN] Sales Line 1 has "Qty. to Ship" = "Qty. to Invoice" = "Quantity"
        // [GIVEN] Sales Line 2 has "Qty. to Ship" = "Qty. to Invoice" = 0
        // [GIVEN] Sales Line 1 is posted
        SalesHeaderNo := CreateSalesOrderAndPostOneOfTwoLines();

        // [GIVEN] "Inv. Discount Amount" is updated in Sales Order Subform
        LibraryVariableStorage.Enqueue(UpdateInvDiscountQst);
        LibraryVariableStorage.Enqueue(true);
        InvDiscountAmount := SetInvDiscAmountInSalesOrderSubPage(SalesHeaderNo);

        // [GIVEN] Confirmation appears: "One or more lines have been invoiced. The discount distributed to invoiced lines will not be taken into account.\\Do you want to update the invoice discount?"
        // Message check is performed in Confirm handler

        // [WHEN] Confirmation acepted
        // TRUE is passed to Confirm handler

        // [THEN] "Inv. Discount Amount" is changed
        VerifyInvDiscAmountInSalesOrderSubpage(SalesHeaderNo, InvDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoConfirmationOnChangingInvDiscountAmountInSalesOrderWithoutPostedLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvDiscountAmount: Integer;
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 208219] When a line of Sales Order is posted and "Inv. Discount Amount" is updated at subpage, then confirmation appears

        Initialize();

        // [GIVEN] Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line has "Qty. to Ship" = "Qty. to Invoice" = "Quantity"
        CreateItem(Item, LibraryRandom.RandIntInRange(100, 1000));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [WHEN] "Inv. Discount Amount" is updated in Sales Order Subform
        InvDiscountAmount := SetInvDiscAmountInSalesOrderSubPage(SalesHeader."No.");

        // [THEN] No confirmation appears and "Inv. Discount Amount" is changed
        // No Confirm handler is risen
        VerifyInvDiscAmountInSalesOrderSubpage(SalesHeader."No.", InvDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderSubformTotalAmountsWithBlankCurrencyCaption()
    var
        SalesHeader: Record "Sales Header";
        GLSetup: Record "General Ledger Setup";
        SalesOrderPage: TestPage "Sales Order";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Order]
        // [SCENARIO 217135] Currency Captions in Sales Order Subform is set to defult value if Sales Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Sales Order "SO" with Currency Code "CC"
        CurrencyCode := CreateSalesHeaderWithCurrencyCode(SalesHeader, SalesHeader."Document Type"::Order);

        // [GIVEN] Sales Order Subform with "CC" in Total Amount Captions
        SalesOrderPage.OpenEdit();
        SalesOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");
        CheckSalesOrderSubformTotalAmountCaptions(SalesOrderPage, CurrencyCode);
        SalesOrderPage.Close();

        // [GIVEN] "SO" Currency Code set to blank
        SalesHeader.Validate("Currency Code", '');
        SalesHeader.Modify(true);

        // [WHEN] Open Sales Order Subform
        SalesOrderPage.OpenEdit();
        SalesOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckSalesOrderSubformTotalAmountCaptions(SalesOrderPage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteSubformTotalAmountsWithBlankCurrencyCaption()
    var
        SalesHeader: Record "Sales Header";
        GLSetup: Record "General Ledger Setup";
        SalesQuotePage: TestPage "Sales Quote";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Quote]
        // [SCENARIO 217135] Currency Captions in Sales Quote Subform is set to defult value if Sales Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Sales Quote "SQ" with Currency Code "CC"
        CurrencyCode := CreateSalesHeaderWithCurrencyCode(SalesHeader, SalesHeader."Document Type"::Quote);

        // [GIVEN] Sales Quote Subform with "CC" in Total Amount Captions
        SalesQuotePage.OpenEdit();
        SalesQuotePage.FILTER.SetFilter("No.", SalesHeader."No.");
        CheckSalesQuoteSubformTotalAmountCaptions(SalesQuotePage, CurrencyCode);
        SalesQuotePage.Close();

        // [GIVEN] "SQ" Currency Code set to blank
        SalesHeader.Validate("Currency Code", '');
        SalesHeader.Modify(true);

        // [WHEN] Open Sales Quote Subform
        SalesQuotePage.OpenEdit();
        SalesQuotePage.FILTER.SetFilter("No.", SalesHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckSalesQuoteSubformTotalAmountCaptions(SalesQuotePage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSubformTotalAmountsWithBlankCurrencyCaption()
    var
        SalesHeader: Record "Sales Header";
        GLSetup: Record "General Ledger Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Invoice]
        // [SCENARIO 217135] Currency Captions in Sales Invoice Subform is set to defult value if Sales Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Sales Invoice "SI" with Currency Code "CC"
        CurrencyCode := CreateSalesHeaderWithCurrencyCode(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] Sales Invoice Subform with "CC" in Total Amount Captions
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesHeader."No.");
        CheckSalesInvoiceSubformTotalAmountCaptions(SalesInvoicePage, CurrencyCode);
        SalesInvoicePage.Close();

        // [GIVEN] "SI" Currency Code set to blank
        SalesHeader.Validate("Currency Code", '');
        SalesHeader.Modify(true);

        // [WHEN] Open Sales Invoice Subform
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckSalesInvoiceSubformTotalAmountCaptions(SalesInvoicePage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoSubformTotalAmountsWithBlankCurrencyCaption()
    var
        SalesHeader: Record "Sales Header";
        GLSetup: Record "General Ledger Setup";
        SalesCreditMemoPage: TestPage "Sales Credit Memo";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Credit Memo]
        // [SCENARIO 217135] Currency Captions in Sales Credit Memo Subform is set to defult value if Sales Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Sales Credit Memo "SCM" with Currency Code "CC"
        CurrencyCode := CreateSalesHeaderWithCurrencyCode(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        // [GIVEN] Sales Credit Memo Subform with "CC" in Total Amount Captions
        SalesCreditMemoPage.OpenEdit();
        SalesCreditMemoPage.FILTER.SetFilter("No.", SalesHeader."No.");
        CheckSalesCreditMemoSubformTotalAmountCaptions(SalesCreditMemoPage, CurrencyCode);
        SalesCreditMemoPage.Close();

        // [GIVEN] "SCM" Currency Code set to blank
        SalesHeader.Validate("Currency Code", '');
        SalesHeader.Modify(true);

        // [WHEN] Open Sales Credit Memo Subform
        SalesCreditMemoPage.OpenEdit();
        SalesCreditMemoPage.FILTER.SetFilter("No.", SalesHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckSalesCreditMemoSubformTotalAmountCaptions(SalesCreditMemoPage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderSubformTotalAmountsWithBlankCurrencyCaption()
    var
        SalesHeader: Record "Sales Header";
        GLSetup: Record "General Ledger Setup";
        BlanketSalesOrderPage: TestPage "Blanket Sales Order";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Blanket Order]
        // [SCENARIO 217135] Currency Captions in Blanket Sales Order Subform is set to defult value if Sales Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Blanket Sales Order "BSO" with Currency Code "CC"
        CurrencyCode := CreateSalesHeaderWithCurrencyCode(SalesHeader, SalesHeader."Document Type"::"Blanket Order");

        // [GIVEN] Blanket Sales Order Subform with "CC" in Total Amount Captions
        BlanketSalesOrderPage.OpenEdit();
        BlanketSalesOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");
        CheckSalesBlanketOrderSubformTotalAmountCaptions(BlanketSalesOrderPage, CurrencyCode);
        BlanketSalesOrderPage.Close();

        // [GIVEN] "BSO" Currency Code set to blank
        SalesHeader.Validate("Currency Code", '');
        SalesHeader.Modify(true);

        // [WHEN] Open Blanket Sales Order Subform
        BlanketSalesOrderPage.OpenEdit();
        BlanketSalesOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckSalesBlanketOrderSubformTotalAmountCaptions(BlanketSalesOrderPage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderSubformTotalAmountsWithBlankCurrencyCaption()
    var
        SalesHeader: Record "Sales Header";
        GLSetup: Record "General Ledger Setup";
        SalesReturnOrderPage: TestPage "Sales Return Order";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Return Order]
        // [SCENARIO 217135] Currency Captions in Sales Return Order Subform is set to defult value if Sales Header Currency Code is set to blank
        Initialize();

        // [GIVEN] Sales Return Order "SRO" with Currency Code "CC"
        CurrencyCode := CreateSalesHeaderWithCurrencyCode(SalesHeader, SalesHeader."Document Type"::"Return Order");

        // [GIVEN] Sales Return Order Subform with "CC" in Total Amount Captions
        SalesReturnOrderPage.OpenEdit();
        SalesReturnOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");
        CheckSalesReturnOrderSubformTotalAmountCaptions(SalesReturnOrderPage, CurrencyCode);
        SalesReturnOrderPage.Close();

        // [GIVEN] "SRO" Currency Code set to blank
        SalesHeader.Validate("Currency Code", '');
        SalesHeader.Modify(true);

        // [WHEN] Open Sales Return Order Subform
        SalesReturnOrderPage.OpenEdit();
        SalesReturnOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");

        // [THEN] Total Amount Captions has default Currency Code
        GLSetup.Get();
        CheckSalesReturnOrderSubformTotalAmountCaptions(SalesReturnOrderPage, GLSetup.GetCurrencyCode(''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteSubformFieldsEditabilityWithTypeItemAndBlankNumber()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Quote]
        // [SCENARIO 281160] Major sales quote subform fields are not editable when Type = Item and No. = ''
        Initialize();

        // [GIVEN] Open New Sales quote page and pick new customer
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // [WHEN] Create new line with Type = Item and blank "No."
        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines.Type.SetValue(SalesLine.Type::Item);

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are non editable
        // TFS ID: 339141 Fields remain editable to keep Quick Entry feature functionable
        Assert.IsTrue(
          SalesQuote.SalesLines.Quantity.Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName(Quantity)));
        Assert.IsTrue(
          SalesQuote.SalesLines."Location Code".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Location Code")));
        Assert.IsTrue(
          SalesQuote.SalesLines."Unit Price".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Unit Price")));
        Assert.IsTrue(
          SalesQuote.SalesLines."Line Discount %".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          SalesQuote.SalesLines."Line Amount".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteSubformFieldsEditabilityWithTypeItemAndNotBlankNumber()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Quote]
        // [SCENARIO 281160] Major sales quote subform fields are editable when Type = Item and No. <> ''
        Initialize();

        // [GIVEN] Open New Sales quote page and pick new customer
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // [WHEN] Create new line with Type = Item
        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesQuote.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are editable
        Assert.IsTrue(
          SalesQuote.SalesLines.Quantity.Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName(Quantity)));
        Assert.IsTrue(
          SalesQuote.SalesLines."Location Code".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Location Code")));
        Assert.IsTrue(
          SalesQuote.SalesLines."Unit Price".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Unit Price")));
        Assert.IsTrue(
          SalesQuote.SalesLines."Line Discount %".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          SalesQuote.SalesLines."Line Amount".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSubformFieldsEditabilityWithTypeItemAndBlankNumber()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Invoice]
        // [SCENARIO 281160] Major sales invoice subform fields are not editable when Type = Item and No. = ''
        Initialize();

        // [GIVEN] Open New Sales invoice page and pick new customer
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // [WHEN] Create new line with Type = Item and blank "No."
        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines.Type.SetValue(SalesLine.Type::Item);

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are non editable
        // TFS ID: 339141 Fields remain editable to keep Quick Entry feature functionable
        Assert.IsTrue(
          SalesInvoice.SalesLines.Quantity.Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName(Quantity)));
        Assert.IsTrue(
          SalesInvoice.SalesLines."Location Code".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Location Code")));
        Assert.IsTrue(
          SalesInvoice.SalesLines."Unit Price".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Unit Price")));
        Assert.IsTrue(
          SalesInvoice.SalesLines."Line Discount %".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          SalesInvoice.SalesLines."Line Amount".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSubformFieldsEditabilityWithTypeItemAndNotBlankNumber()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Invoice]
        // [SCENARIO 281160] Major sales invoice subform fields are editable when Type = Item and No. <> ''
        Initialize();

        // [GIVEN] Open New Sales invoice page and pick new customer
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // [WHEN] Create new line with Type = Item
        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesInvoice.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are editable
        Assert.IsTrue(
          SalesInvoice.SalesLines.Quantity.Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName(Quantity)));
        Assert.IsTrue(
          SalesInvoice.SalesLines."Location Code".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Location Code")));
        Assert.IsTrue(
          SalesInvoice.SalesLines."Unit Price".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Unit Price")));
        Assert.IsTrue(
          SalesInvoice.SalesLines."Line Discount %".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          SalesInvoice.SalesLines."Line Amount".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderSubformFieldsEditabilityWithTypeItemAndBlankNumber()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Order]
        // [SCENARIO 281160] Major sales order subform fields are not editable when Type = Item and No. = ''
        Initialize();

        // [GIVEN] Open New Sales order page and pick new customer
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // [WHEN] Create new line with Type = Item and blank "No."
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);

        // [THEN] Fields Location Code, Unit Price, Line Discount % and Line Amount are non editable
        // TFS ID: 330349 Quantity is still editable to work with current Quick Entry functionality
        // TFS ID: 339141 Fields remain editable to keep Quick Entry feature functionable
        Assert.IsTrue(
          SalesOrder.SalesLines.Quantity.Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName(Quantity)));
        Assert.IsTrue(
          SalesOrder.SalesLines."Location Code".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Location Code")));
        Assert.IsTrue(
          SalesOrder.SalesLines."Unit Price".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Unit Price")));
        Assert.IsTrue(
          SalesOrder.SalesLines."Line Discount %".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          SalesOrder.SalesLines."Line Amount".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderSubformFieldsEditabilityWithTypeItemAndNotBlankNumber()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Order]
        // [SCENARIO 281160] Major sales order subform fields are editable when Type = Item and No. <> ''
        Initialize();

        // [GIVEN] Open New Sales order page and pick new customer
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // [WHEN] Create new line with Type = Item
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesOrder.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are editable
        Assert.IsTrue(
          SalesOrder.SalesLines.Quantity.Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName(Quantity)));
        Assert.IsTrue(
          SalesOrder.SalesLines."Location Code".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Location Code")));
        Assert.IsTrue(
          SalesOrder.SalesLines."Unit Price".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Unit Price")));
        Assert.IsTrue(
          SalesOrder.SalesLines."Line Discount %".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          SalesOrder.SalesLines."Line Amount".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoSubformFieldsEditabilityWithTypeItemAndBlankNumber()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI] [Credit Memo]
        // [SCENARIO 281160] Major sales credit memo subform fields are not editable when Type = Item and No. = ''
        Initialize();

        // [GIVEN] Open New Sales credit memo page and pick new customer
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // [WHEN] Create new line with Type = Item and blank "No."
        SalesCreditMemo.SalesLines.New();
        SalesCreditMemo.SalesLines.Type.SetValue(SalesLine.Type::Item);

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are non editable
        // TFS ID: 339141 Fields remain editable to keep Quick Entry feature functionable
        Assert.IsTrue(
          SalesCreditMemo.SalesLines.Quantity.Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName(Quantity)));
        Assert.IsTrue(
          SalesCreditMemo.SalesLines."Location Code".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Location Code")));
        Assert.IsTrue(
          SalesCreditMemo.SalesLines."Unit Price".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Unit Price")));
        Assert.IsTrue(
          SalesCreditMemo.SalesLines."Line Discount %".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          SalesCreditMemo.SalesLines."Line Amount".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoSubformFieldsEditabilityWithTypeItemAndNotBlankNumber()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI] [Credit Memo]
        // [SCENARIO 281160] Major sales credit memo subform fields are editable when Type = Item and No. <> ''
        Initialize();

        // [GIVEN] Open New Sales credit memo page and pick new customer
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // [WHEN] Create new line with Type = Item
        SalesCreditMemo.SalesLines.New();
        SalesCreditMemo.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesCreditMemo.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are editable
        Assert.IsTrue(
          SalesCreditMemo.SalesLines.Quantity.Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName(Quantity)));
        Assert.IsTrue(
          SalesCreditMemo.SalesLines."Location Code".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Location Code")));
        Assert.IsTrue(
          SalesCreditMemo.SalesLines."Unit Price".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Unit Price")));
        Assert.IsTrue(
          SalesCreditMemo.SalesLines."Line Discount %".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          SalesCreditMemo.SalesLines."Line Amount".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderSubformFieldsEditabilityWithTypeItemAndBlankNumber()
    var
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [UI] [Return Order]
        // [SCENARIO 281160] Major sales return order subform fields are not editable when Type = Item and No. = ''
        Initialize();

        // [GIVEN] Open New Sales return order page and pick new customer
        SalesReturnOrder.OpenNew();
        SalesReturnOrder."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // [WHEN] Create new line with Type = Item and blank "No."
        SalesReturnOrder.SalesLines.New();
        SalesReturnOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are non editable
        // TFS ID: 339141 Fields remain editable to keep Quick Entry feature functionable
        Assert.IsTrue(
          SalesReturnOrder.SalesLines.Quantity.Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName(Quantity)));
        Assert.IsTrue(
          SalesReturnOrder.SalesLines."Location Code".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Location Code")));
        Assert.IsTrue(
          SalesReturnOrder.SalesLines."Unit Price".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Unit Price")));
        Assert.IsTrue(
          SalesReturnOrder.SalesLines."Line Discount %".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          SalesReturnOrder.SalesLines."Line Amount".Editable(),
          StrSubstNo(NotEditableErr, SalesLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderSubformFieldsEditabilityWithTypeItemAndNotBlankNumber()
    var
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [UI] [Return Order]
        // [SCENARIO 281160] Major sales return order subform fields are editable when Type = Item and No. <> ''
        Initialize();

        // [GIVEN] Open New Sales return order page and pick new customer
        SalesReturnOrder.OpenNew();
        SalesReturnOrder."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());

        // [WHEN] Create new line with Type = Item
        SalesReturnOrder.SalesLines.New();
        SalesReturnOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesReturnOrder.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] Fields Quantity, Location Code, Unit Price, Line Discount % and Line Amount are editable
        Assert.IsTrue(
          SalesReturnOrder.SalesLines.Quantity.Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName(Quantity)));
        Assert.IsTrue(
          SalesReturnOrder.SalesLines."Location Code".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Location Code")));
        Assert.IsTrue(
          SalesReturnOrder.SalesLines."Unit Price".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Unit Price")));
        Assert.IsTrue(
          SalesReturnOrder.SalesLines."Line Discount %".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Line Discount %")));
        Assert.IsTrue(
          SalesReturnOrder.SalesLines."Line Amount".Editable(),
          StrSubstNo(EditableErr, SalesLine.FieldName("Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceStatisticsServiceItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        SalesInvoiceStatistics: TestPage "Sales Invoice Statistics";
        PostedInvoiceNo: Code[20];
        InvRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Service Item]
        // [SCENARIO 294617] Posted sales invoice statistics shows proper value of Adjusted Cost (LCY) Adjusted Profit (LCY) for item with type Service
        Initialize();

        //Modify General Ledger Setup "Inv. Rounding Precision (LCY)" to 0.01 
        GeneralLedgerSetup.get();
        InvRoundingPrecision := GeneralLedgerSetup."Inv. Rounding Precision (LCY)";
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", 0.01);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Item "I" with "Type" = "Service", Unit Cost = 60, Unit Price = 100
        LibraryInventory.CreateServiceTypeItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Price", Item."Unit Cost" + LibraryRandom.RandDec(100, 2));
        Item.Modify();

        // [GIVEN] Create and post sales order with item "I", Quantity = 1
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Statistics for posted invoice is being opened
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", PostedInvoiceNo);
        SalesInvoiceStatistics.Trap();
        PostedSalesInvoice.Statistics.Invoke();

        // [THEN] Adjusted Cost (LCY) = 60
        Assert.AreNearlyEqual(
          SalesLine.Quantity * Item."Unit Cost",
          SalesInvoiceStatistics.AdjustedCostLCY.AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(),
          'Invalid Adjusted Cost (LCY) value');

        // [THEN] Adjusted Profit (LCY) = 40
        Assert.AreNearlyEqual(
          SalesLine.Quantity * (Item."Unit Price" - Item."Unit Cost"),
          SalesInvoiceStatistics.AdjustedProfitLCY.AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(),
          'Invalid Adjusted Profit (LCY) value');

        // TearDown: Update general ledger setup with old value.
        GeneralLedgerSetup.get();
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", InvRoundingPrecision);
        GeneralLedgerSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoStatisticsServiceItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        SalesCreditMemoStatistics: TestPage "Sales Credit Memo Statistics";
        PostedCrMemoNo: Code[20];
        InvRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Service Item]
        // [SCENARIO 294617] Posted sales credit memo statistics shows proper value of Adjusted Cost (LCY) and Adjusted Profit (LCY) for item with type Service
        Initialize();

        //Modify General Ledger Setup "Inv. Rounding Precision (LCY)" to 0.01 
        GeneralLedgerSetup.get();
        InvRoundingPrecision := GeneralLedgerSetup."Inv. Rounding Precision (LCY)";
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", 0.01);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Item "I" with "Type" = "Service", Unit Cost = 60, Unit Price = 100
        LibraryInventory.CreateServiceTypeItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Price", Item."Unit Cost" + LibraryRandom.RandDec(100, 2));
        Item.Modify();

        // [GIVEN] Create and post sales credit memo with item "I", Quantity = 1
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PostedCrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Statistics for posted credit memo is being opened
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", PostedCrMemoNo);
        SalesCreditMemoStatistics.Trap();
        PostedSalesCreditMemo.Statistics.Invoke();

        // [THEN] Adjusted Cost (LCY) = 60
        Assert.AreNearlyEqual(
          SalesLine.Quantity * Item."Unit Cost",
          SalesCreditMemoStatistics.AdjustedCostLCY.AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(),
          'Invalid Adjusted Cost (LCY) value');

        // [THEN] Adjusted Profit (LCY) = 40
        Assert.AreNearlyEqual(
          SalesLine.Quantity * (Item."Unit Price" - Item."Unit Cost"),
          SalesCreditMemoStatistics.AdjustedProfitLCY.AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(),
          'Invalid Adjusted Profit (LCY) value');

        // TearDown: Update general ledger setup with old value.
        GeneralLedgerSetup.get();
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", InvRoundingPrecision);
        GeneralLedgerSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Order_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Order] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Sales Order page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreateSalesDocumentWithCurrency(SalesHeader, SalesLine, Item, CurrencyCode, SalesHeader."Document Type"::Order, ExchangeRate);

        OpenSalesOrder(SalesHeader, SalesOrder);

        SetCurrencyOnOrderAndVerify(SalesOrder, CurrencyCode, Item, SalesLine, ExchangeRate);

        SetCurrencyOnOrderAndVerify(SalesOrder, '', Item, SalesLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Invoice_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Invoice] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Sales Invoice page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreateSalesDocumentWithCurrency(SalesHeader, SalesLine, Item, CurrencyCode, SalesHeader."Document Type"::Invoice, ExchangeRate);

        OpenSalesInvoice(SalesHeader, SalesInvoice);

        SetCurrencyOnInvoiceAndVerify(SalesInvoice, CurrencyCode, Item, SalesLine, ExchangeRate);

        SetCurrencyOnInvoiceAndVerify(SalesInvoice, '', Item, SalesLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Quote_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Quote] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Sales Quote page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreateSalesDocumentWithCurrency(SalesHeader, SalesLine, Item, CurrencyCode, SalesHeader."Document Type"::Quote, ExchangeRate);

        OpenSalesQuote(SalesHeader, SalesQuote);

        SetCurrencyOnQuoteAndVerify(SalesQuote, CurrencyCode, Item, SalesLine, ExchangeRate);

        SetCurrencyOnQuoteAndVerify(SalesQuote, '', Item, SalesLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemo_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Credit Memo] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Sales Credit Memo page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreateSalesDocumentWithCurrency(
          SalesHeader, SalesLine, Item, CurrencyCode, SalesHeader."Document Type"::"Credit Memo", ExchangeRate);

        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        SetCurrencyOnCreditMemoAndVerify(SalesCreditMemo, CurrencyCode, Item, SalesLine, ExchangeRate);

        SetCurrencyOnCreditMemoAndVerify(SalesCreditMemo, '', Item, SalesLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrder_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Return Order] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Sales Return Order page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreateSalesDocumentWithCurrency(
          SalesHeader, SalesLine, Item, CurrencyCode, SalesHeader."Document Type"::"Return Order", ExchangeRate);

        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        SetCurrencyOnReturnOrderAndVerify(SalesReturnOrder, CurrencyCode, Item, SalesLine, ExchangeRate);

        SetCurrencyOnReturnOrderAndVerify(SalesReturnOrder, '', Item, SalesLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BlanketOrder_SetAndCleanCurrencyCode()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Blanket Order] [UI] [Document Totals]
        // [SCENARIO 300107] Cleaning "Currency Code" on Blanket Sales Order page causes request to update existing lines
        // [SCENARIO 300107] and further amount / caption update on document total fields in case of positive reply to the request
        Initialize();

        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);

        CreateSalesDocumentWithCurrency(
          SalesHeader, SalesLine, Item, CurrencyCode, SalesHeader."Document Type"::"Blanket Order", ExchangeRate);

        OpenBlanketOrder(SalesHeader, BlanketSalesOrder);

        SetCurrencyOnBlanketOrderAndVerify(BlanketSalesOrder, CurrencyCode, Item, SalesLine, ExchangeRate);

        SetCurrencyOnBlanketOrderAndVerify(BlanketSalesOrder, '', Item, SalesLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesLineVATCaptionOnChangeSellToCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Caption] [UT]
        // [SCENARIO 310753] Captions endings of "Unit Price"/"Line Amount" are changed between "Incl. VAT" and "Excl. VAT" when Sell-to Customer is changed.
        Initialize();

        // [GIVEN] Sales Document with Sell-to Customer "C1", that has "Prices Including VAT" = TRUE.
        // [GIVEN] Fields "Unit Price"/"Line Amount" of Sales Line have captions "Unit Price Incl. VAT"/"Line Amount Incl. VAT".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNoPricesIncludingVAT(true));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        Assert.AreEqual('Unit Price Incl. VAT', SalesLine.FieldCaption("Unit Price"), 'Caption must contain Incl. VAT');
        Assert.AreEqual('Line Amount Incl. VAT', SalesLine.FieldCaption("Line Amount"), 'Caption must contain Incl. VAT');

        // [WHEN] Change Sell-to Customer to "C2", he has "Prices Including VAT" = FALSE.
        SalesHeader.Validate("Sell-to Customer No.", CreateCustomerNoPricesIncludingVAT(false));

        // [THEN] Captions of the fields "Unit Price"/"Line Amount" are updated to "Unit Price Excl. VAT"/"Line Amount Excl. VAT".
        Assert.AreEqual('Unit Price Excl. VAT', SalesLine.FieldCaption("Unit Price"), 'Caption must contain Excl. VAT');
        Assert.AreEqual('Line Amount Excl. VAT', SalesLine.FieldCaption("Line Amount"), 'Caption must contain Excl. VAT');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesLineVATCaptionOnChangeBillToCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Caption] [UT]
        // [SCENARIO 310753] Captions endings of "Unit Price"/"Line Amount" are changed between "Incl. VAT" and "Excl. VAT" when Bill-to Customer is changed.
        Initialize();

        // [GIVEN] Sales Document with Bill-to Customer "C1", that has "Prices Including VAT" = TRUE.
        // [GIVEN] Fields "Unit Price"/"Line Amount" of Sales Line have captions "Unit Price Incl. VAT"/"Line Amount Incl. VAT".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNoPricesIncludingVAT(true));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        Assert.AreEqual('Unit Price Incl. VAT', SalesLine.FieldCaption("Unit Price"), 'Caption must contain Incl. VAT');
        Assert.AreEqual('Line Amount Incl. VAT', SalesLine.FieldCaption("Line Amount"), 'Caption must contain Incl. VAT');

        // [WHEN] Change Bill-to Customer to "C2", he has "Prices Including VAT" = FALSE.
        SalesHeader.Validate("Bill-to Customer No.", CreateCustomerNoPricesIncludingVAT(false));

        // [THEN] Captions of the fields "Unit Price"/"Line Amount" are updated to "Unit Price Excl. VAT"/"Line Amount Excl. VAT".
        Assert.AreEqual('Unit Price Excl. VAT', SalesLine.FieldCaption("Unit Price"), 'Caption must contain Excl. VAT');
        Assert.AreEqual('Line Amount Excl. VAT', SalesLine.FieldCaption("Line Amount"), 'Caption must contain Excl. VAT');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DrillingDownQtyToAssignFieldOnWrongTypeDoesNotRollbackPrevChanges()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Qty: Decimal;
        QtyToShip: Decimal;
    begin
        // [SCENARIO 366876] Drilling down "Qty. to Assign" field on sales line of wrong type shows a warning message and does not rollback previous changes.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);
        QtyToShip := LibraryRandom.RandInt(10);

        // [GIVEN] Sales order with Item-type line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);

        // [GIVEN] Open sales order page, set "No." = some item, "Quantity" = 20 and go to a next line to save the record.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        SalesOrder.SalesLines.Quantity.SetValue(Qty);
        SalesOrder.SalesLines.Next();
        Commit();

        // [GIVEN] Go back to the sales line and update "Qty. to Ship" = 10.
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines."Qty. to Ship".SetValue(QtyToShip);

        // [WHEN] Staying on the line, drill down "Qty. to Assign" field.
        LibraryVariableStorage.Enqueue(ItemChargeAssignmentErr);
        SalesOrder.SalesLines."Qty. to Assign".DrillDown();
        SalesOrder.SalesLines.Next();

        // [THEN] A message is shown that we are capable of drilling down "Qty. to Assign" only on line of Item Charge type.
        // [THEN] The update of "Qty. to Ship" on the sales line is 10 and saved to database.
        SalesLine.Find();
        SalesLine.TestField(Quantity, Qty);
        SalesLine.TestField("Qty. to Ship", QtyToShip);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDefaultLineType()
    var
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType := SalesLineType::Resource;
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = "Resource"
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderDefaultLineType()
    var
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType := SalesLineType::Resource;
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        BlanketSalesOrder.OpenNew();
        BlanketSalesOrder."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = "Resource"
        BlanketSalesOrder.SalesLines.First();
        BlanketSalesOrder.SalesLines.Type.AssertEquals(SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceDefaultLineType()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType := SalesLineType::Resource;
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = "Resource"
        SalesInvoice.SalesLines.First();
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoDefaultLineType()
    var
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType := SalesLineType::Resource;
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = "Resource"
        SalesCreditMemo.SalesLines.First();
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteDefaultLineType()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType := SalesLineType::Resource;
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = "Resource"
        SalesQuote.SalesLines.First();
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRetOrderDefaultLineType()
    var
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType := SalesLineType::Resource;
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        SalesReturnOrder.OpenNew();
        SalesReturnOrder."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = "Resource"
        SalesReturnOrder.SalesLines.First();
        SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals(SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDefaultLineType_Empty()
    var
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = " "
        SalesLineType := SalesLineType::" ";
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = " "
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals('Comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderDefaultLineType_Empty()
    var
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = " "
        SalesLineType := SalesLineType::" ";
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        BlanketSalesOrder.OpenNew();
        BlanketSalesOrder."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = " "
        BlanketSalesOrder.SalesLines.First();
        BlanketSalesOrder.SalesLines.Type.AssertEquals(SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceDefaultLineType_Empty()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = " "
        SalesLineType := SalesLineType::" ";
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = " "
        SalesInvoice.SalesLines.First();
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals('Comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoDefaultLineType_Empty()
    var
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = " "
        SalesLineType := SalesLineType::" ";
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = " "
        SalesCreditMemo.SalesLines.First();
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals('Comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteDefaultLineType_Empty()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = " "
        SalesLineType := SalesLineType::" ";
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = " "
        SalesQuote.SalesLines.First();
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals('Comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRetOrderDefaultLineType_Empty()
    var
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] First sales document line "Type" = "Document Default Line Type" from sales setup when create new sales document
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = " "
        SalesLineType := SalesLineType::" ";
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Create new sales document
        LibrarySales.CreateCustomer(Customer);
        SalesReturnOrder.OpenNew();
        SalesReturnOrder."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] First sales document line "Type" = " "
        SalesReturnOrder.SalesLines.First();
        SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals('Comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDefaultLineType_SecondLine()
    var
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        SalesLineType: array[2] of Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from sales setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType[1] := SalesLineType[1] ::Resource;
        SetDocumentDefaultLineType(SalesLineType[1]);

        // [GIVEN] New sales document with first line "Type" = "G/L Account"
        SalesLineType[2] := SalesLineType[2] ::"G/L Account";
        LibrarySales.CreateCustomer(Customer);
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.FilteredTypeField.SetValue(SalesLineType[2]);
        Commit();

        // [WHEN] Create sales document second line
        SalesOrder.SalesLines.New();

        // [THEN] Sales document second line "Type" = "G/L Account"
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(SalesLineType[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderDefaultLineType_SecondLine()
    var
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        SalesLineType: array[2] of Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from sales setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType[1] := SalesLineType[1] ::Resource;
        SetDocumentDefaultLineType(SalesLineType[1]);

        // [GIVEN] New sales document with first line "Type" = "G/L Account"
        SalesLineType[2] := SalesLineType[2] ::"G/L Account";
        LibrarySales.CreateCustomer(Customer);
        BlanketSalesOrder.OpenNew();
        BlanketSalesOrder."Sell-to Customer Name".SetValue(Customer.Name);
        BlanketSalesOrder.SalesLines.First();
        BlanketSalesOrder.SalesLines.Type.SetValue(SalesLineType[2]);
        Commit();

        // [WHEN] Create sales document second line
        BlanketSalesOrder.SalesLines.New();

        // [THEN] Sales document second line "Type" = "G/L Account"
        BlanketSalesOrder.SalesLines.Type.AssertEquals(SalesLineType[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteDefaultLineType_SecondLine()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        SalesLineType: array[2] of Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from sales setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType[1] := SalesLineType[1] ::Resource;
        SetDocumentDefaultLineType(SalesLineType[1]);

        // [GIVEN] New sales document with first line "Type" = "G/L Account"
        SalesLineType[2] := SalesLineType[2] ::"G/L Account";
        LibrarySales.CreateCustomer(Customer);
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);
        SalesQuote.SalesLines.First();
        SalesQuote.SalesLines.FilteredTypeField.SetValue(SalesLineType[2]);
        Commit();

        // [WHEN] Create sales document second line
        SalesQuote.SalesLines.New();

        // [THEN] Sales document second line "Type" = "G/L Account"
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(SalesLineType[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceDefaultLineType_SecondLine()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        SalesLineType: array[2] of Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from sales setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType[1] := SalesLineType[1] ::Resource;
        SetDocumentDefaultLineType(SalesLineType[1]);

        // [GIVEN] New sales document with first line "Type" = "G/L Account"
        SalesLineType[2] := SalesLineType[2] ::"G/L Account";
        LibrarySales.CreateCustomer(Customer);
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);
        SalesInvoice.SalesLines.First();
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(SalesLineType[2]);
        Commit();

        // [WHEN] Create sales document second line
        SalesInvoice.SalesLines.New();

        // [THEN] Sales document second line "Type" = "G/L Account"
        SalesInvoice.SalesLines.FilteredTypeField.AssertEquals(SalesLineType[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoDefaultLineType_SecondLine()
    var
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        SalesLineType: array[2] of Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from sales setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType[1] := SalesLineType[1] ::Resource;
        SetDocumentDefaultLineType(SalesLineType[1]);

        // [GIVEN] New sales document with first line "Type" = "G/L Account"
        SalesLineType[2] := SalesLineType[2] ::"G/L Account";
        LibrarySales.CreateCustomer(Customer);
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);
        SalesCreditMemo.SalesLines.First();
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(SalesLineType[2]);
        Commit();

        // [WHEN] Create sales document second line
        SalesCreditMemo.SalesLines.New();

        // [THEN] Sales document second line "Type" = "G/L Account"
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(SalesLineType[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRetOrderDefaultLineType_SecondLine()
    var
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
        SalesLineType: array[2] of Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales document SECOND line "Type" = xRec.Type, without any dependency on the "Document Default Line Type" from sales setup
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Resource"
        SalesLineType[1] := SalesLineType[1] ::Resource;
        SetDocumentDefaultLineType(SalesLineType[1]);

        // [GIVEN] New sales document with first line "Type" = "G/L Account"
        SalesLineType[2] := SalesLineType[2] ::"G/L Account";
        LibrarySales.CreateCustomer(Customer);
        SalesReturnOrder.OpenNew();
        SalesReturnOrder."Sell-to Customer Name".SetValue(Customer.Name);
        SalesReturnOrder.SalesLines.First();
        SalesReturnOrder.SalesLines.FilteredTypeField.SetValue(SalesLineType[2]);
        Commit();

        // [WHEN] Create sales document second line
        SalesReturnOrder.SalesLines.New();

        // [THEN] Sales document second line "Type" = "G/L Account"
        SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals(SalesLineType[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateInvoiceDiscountPercentOnSalesOrderPage()
    var
        Customer: Record Customer;
        Item1: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesOrder: TestPage "Sales Order";
        SalesOrderSubform: TestPage "Sales Order Subform";
        MinAmount1: Decimal;
        MinAmount2: Decimal;
        InvDiscPct: Decimal;
    begin
        // [SCENARIO 477664] Invoice Discount % field is not calculated correctly in documents.
        Initialize();

        // [GIVEN] Disable Calc. Inv. Discount on Sales & Receivables Setup.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", false);
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create two variables & save Minimum Amount values.
        MinAmount1 := LibraryRandom.RandIntInRange(1000, 1000);
        MinAmount2 := LibraryRandom.RandIntInRange(2000, 2000);

        // [GIVEN] Create two Invoice Discounts for Customer.
        CreateInvoiceDiscForCustWithDiscPctAndMinValue(Customer, LibraryRandom.RandInt(0), MinAmount1);
        CreateInvoiceDiscForCustWithDiscPctAndMinValue(Customer, LibraryRandom.RandIntInRange(2, 2), MinAmount2);

        // [GIVEN] Create an Item 1.
        LibraryInventory.CreateItem(Item1);

        // [GIVEN] Create an Item 2.
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create a Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Create a Sales Line for Item 1 & Validate Unit Price.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item1."No.", LibraryRandom.RandInt(0));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1900, 1999, 0));
        SalesLine.Modify(true);

        // [GIVEN] Create a Sales Line for Item 2 & Validate Unit Price.
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, Item2."No.", LibraryRandom.RandInt(0));
        SalesLine2.Validate("Unit Price", LibraryRandom.RandDecInRange(500, 501, 0));
        SalesLine2.Modify(true);

        // [GIVEN] Open Sales Order Page & Calculate Invoice Discount.
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesLine."Document No.");
        SalesOrder.CalculateInvoiceDiscount.Invoke();

        // [GIVEN] Trap Sales Order Page.
        SalesOrder.Trap();

        // [GIVEN] Open Sales Order Subform Page & save Invoice Discount Percent value in a variable.
        SalesOrderSubform.OpenView();
        SalesOrderSubform.Filter.SetFilter("Document No.", SalesLine."Document No.");
        InvDiscPct := SalesOrderSubform."Invoice Disc. Pct.".AsDecimal();
        SalesOrderSubform.Close();

        // [WHEN] Find Customer Invoice Discount.
        CustInvoiceDisc.SetRange(Code, Customer."No.");
        CustInvoiceDisc.SetRange("Minimum Amount", MinAmount2);
        CustInvoiceDisc.FindFirst();

        // [VERIFY] Verify Invoice Discount Percent applied on Sales Order is correct.
        Assert.AreEqual(
           CustInvoiceDisc."Discount %",
           InvDiscPct,
           StrSubstNo(MustMatchErr, CustInvoiceDisc.FieldCaption("Discount %"), InvoiceDiscPct));
    end;

    local procedure Initialize()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Subform");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Subform");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryInventory.CreateItem(Item);
        Item.Description := ItemTestDescriptionLbl;
        Item.Modify();

        LibrarySales.SetStockoutWarning(false);
        LibrarySales.SetCalcInvDiscount(true);

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Subform");
        GeneralLedgerSetup.Get();
    end;

    local procedure CreateCustomerWithDiscount(var Customer: Record Customer; DiscPct: Decimal; minAmount: Decimal)
    begin
        CreateCustomer(Customer);
        AddInvoiceDiscToCustomer(Customer, minAmount, DiscPct);
    end;

    local procedure CreateCustomerWithServiceChargeDiscount(var Customer: Record Customer)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", Customer."Currency Code", 0);
        CustInvoiceDisc.Validate("Service Charge", LibraryRandom.RandDecInDecimalRange(10, 20, 2));
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := Customer."No.";
        Customer.Modify();
    end;

    local procedure CreateItem(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
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

    local procedure CreateSalesOrderAndPostOneOfTwoLines(): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        CreateItem(Item, LibraryRandom.RandIntInRange(100, 1000));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        CreateItem(Item, LibraryRandom.RandIntInRange(100, 1000));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesHeaderWithCurrencyCode(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"): Code[10]
    var
        CurrencyCode: Code[10];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        exit(CurrencyCode);
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

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure CheckInvoiceStatistics(SalesInvoice: TestPage "Sales Invoice")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesInvoice.SalesLines."Total VAT Amount".AsDecimal());
        SalesInvoice.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;
#endif
    local procedure CheckInvoiceSalesStatistics(SalesInvoice: TestPage "Sales Invoice")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesInvoice.SalesLines."Total VAT Amount".AsDecimal());
        SalesInvoice.SalesStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure CheckOrderStatistics(SalesOrder: TestPage "Sales Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(
          DoInvoiceRounding(SalesOrder."Currency Code".Value, SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal()));
        LibraryVariableStorage.Enqueue(SalesOrder.SalesLines."Total VAT Amount".AsDecimal());
        SalesOrder.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure CheckQuoteStatistics(SalesQuote: TestPage "Sales Quote")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesQuote.SalesLines."Total VAT Amount".AsDecimal());
        SalesQuote.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure CheckBlanketOrderStatistics(BlanketSalesOrder: TestPage "Blanket Sales Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(
          DoInvoiceRounding(BlanketSalesOrder."Currency Code".Value, BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal()));
        LibraryVariableStorage.Enqueue(BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal());
        BlanketSalesOrder.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure CheckReturnOrderStatistics(SalesReturnOrder: TestPage "Sales Return Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(
          DoInvoiceRounding(SalesReturnOrder."Currency Code".Value, SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal()));
        LibraryVariableStorage.Enqueue(SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal());
        SalesReturnOrder.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure CheckCreditMemoStatistics(SalesCreditMemo: TestPage "Sales Credit Memo")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesCreditMemo.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesCreditMemo.SalesLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal());
        SalesCreditMemo.Statistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;
#endif
    local procedure CheckQuoteSalesStatistics(SalesQuote: TestPage "Sales Quote")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesQuote.SalesLines."Total VAT Amount".AsDecimal());
        SalesQuote.SalesStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    local procedure CheckOrderStatisticsNM(SalesOrder: TestPage "Sales Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(
          DoInvoiceRounding(SalesOrder."Currency Code".Value, SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal()));
        LibraryVariableStorage.Enqueue(SalesOrder.SalesLines."Total VAT Amount".AsDecimal());
        SalesOrder.SalesOrderStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    local procedure CheckBlanketOrderStatisticsNM(BlanketSalesOrder: TestPage "Blanket Sales Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(
          DoInvoiceRounding(BlanketSalesOrder."Currency Code".Value, BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal()));
        LibraryVariableStorage.Enqueue(BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal());
        BlanketSalesOrder.SalesOrderStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    local procedure CheckReturnOrderStatisticsNM(SalesReturnOrder: TestPage "Sales Return Order")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(
          DoInvoiceRounding(SalesReturnOrder."Currency Code".Value, SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal()));
        LibraryVariableStorage.Enqueue(SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal());
        SalesReturnOrder.SalesOrderStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    local procedure CheckCreditMemoSalesStatistics(SalesCreditMemo: TestPage "Sales Credit Memo")
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SalesCreditMemo.SalesLines."Invoice Discount Amount".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesCreditMemo.SalesLines."Total Amount Incl. VAT".AsDecimal());
        LibraryVariableStorage.Enqueue(SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal());
        SalesCreditMemo.SalesStatistics.Invoke(); // opens the statistics page an code "jumps" to modal page handler
    end;

    local procedure CheckPostedInvoiceStatistics(PostedSalesInvoice: TestPage "Posted Sales Invoice")
    var
        SalesInvoiceStatistics: TestPage "Sales Invoice Statistics";
    begin
        SalesInvoiceStatistics.Trap();
        PostedSalesInvoice.Statistics.Invoke(); // opens the non modal statistics page

        Assert.AreNearlyEqual(PostedSalesInvoice.SalesInvLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoiceStatistics.InvDiscAmount.AsDecimal(), 0.1, 'Invoice Discount Amount is not correct');
        Assert.AreNearlyEqual(PostedSalesInvoice.SalesInvLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoiceStatistics.AmountInclVAT.AsDecimal(), 0.1, 'Total Amount Incl. VAT is not correct');
        Assert.AreNearlyEqual(PostedSalesInvoice.SalesInvLines."Total VAT Amount".AsDecimal(),
          SalesInvoiceStatistics.VATAmount.AsDecimal(), 0.1, 'VAT Amount is not correct');
    end;

    local procedure CheckPostedCreditMemoStatistics(PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo")
    var
        SalesCreditMemoStatistics: TestPage "Sales Credit Memo Statistics";
    begin
        SalesCreditMemoStatistics.Trap();
        PostedSalesCreditMemo.Statistics.Invoke(); // opens the statistics non modal page

        Assert.AreNearlyEqual(PostedSalesCreditMemo.SalesCrMemoLines."Invoice Discount Amount".AsDecimal(),
          SalesCreditMemoStatistics.InvDiscAmount.AsDecimal(), 0.1, 'Invoice Discount Amount is not correct');
        Assert.AreNearlyEqual(PostedSalesCreditMemo.SalesCrMemoLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCreditMemoStatistics.AmountInclVAT.AsDecimal(), 0.1, 'Total Amount Incl. VAT is not correct');
        Assert.AreNearlyEqual(PostedSalesCreditMemo.SalesCrMemoLines."Total VAT Amount".AsDecimal(),
          SalesCreditMemoStatistics.VATAmount.AsDecimal(), 0.1, 'VAT Amount is not correct');
    end;

    local procedure CheckSalesOrderSubformTotalAmountCaptions(SalesOrderPage: TestPage "Sales Order"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(SalesOrderPage.SalesLines."TotalSalesLine.""Line Amount""".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesOrderPage.SalesLines."Invoice Discount Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesOrderPage.SalesLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesOrderPage.SalesLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesOrderPage.SalesLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure CheckSalesQuoteSubformTotalAmountCaptions(SalesQuotePage: TestPage "Sales Quote"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(SalesQuotePage.SalesLines."Subtotal Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesQuotePage.SalesLines."Invoice Discount Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesQuotePage.SalesLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesQuotePage.SalesLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesQuotePage.SalesLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure CheckSalesInvoiceSubformTotalAmountCaptions(SalesInvoicePage: TestPage "Sales Invoice"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(SalesInvoicePage.SalesLines."TotalSalesLine.""Line Amount""".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesInvoicePage.SalesLines."Invoice Discount Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesInvoicePage.SalesLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesInvoicePage.SalesLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesInvoicePage.SalesLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure CheckSalesCreditMemoSubformTotalAmountCaptions(SalesCreditMemoPage: TestPage "Sales Credit Memo"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(SalesCreditMemoPage.SalesLines."Invoice Discount Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesCreditMemoPage.SalesLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesCreditMemoPage.SalesLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesCreditMemoPage.SalesLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure CheckSalesBlanketOrderSubformTotalAmountCaptions(BlanketSalesOrderPage: TestPage "Blanket Sales Order"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(BlanketSalesOrderPage.SalesLines."Invoice Discount Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(BlanketSalesOrderPage.SalesLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(BlanketSalesOrderPage.SalesLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(BlanketSalesOrderPage.SalesLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure CheckSalesReturnOrderSubformTotalAmountCaptions(SalesReturnOrderPage: TestPage "Sales Return Order"; CurrencyCode: Code[10])
    var
        CurrencySubsting: Text;
    begin
        CurrencySubsting := StrSubstNo('(%1)', CurrencyCode);
        Assert.TextEndsWith(SalesReturnOrderPage.SalesLines."Invoice Discount Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesReturnOrderPage.SalesLines."Total Amount Excl. VAT".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesReturnOrderPage.SalesLines."Total VAT Amount".Caption, CurrencySubsting);
        Assert.TextEndsWith(SalesReturnOrderPage.SalesLines."Total Amount Incl. VAT".Caption, CurrencySubsting);
    end;

    local procedure ValidateOrderInvoiceDiscountAmountIsReadOnly(var SalesOrder: TestPage "Sales Order")
    begin
        Assert.IsFalse(SalesOrder.SalesLines."Invoice Discount Amount".Editable(), 'Invoice discount amount shoud not be editable');
    end;

    local procedure ValidateInvoiceInvoiceDiscountAmountIsReadOnly(var SalesInvoice: TestPage "Sales Invoice")
    begin
        Assert.IsFalse(SalesInvoice.SalesLines."Invoice Discount Amount".Editable(), 'Invoice discount amount shoud not be editable');
    end;

    local procedure ValidateQuoteInvoiceDiscountAmountIsReadOnly(var SalesQuote: TestPage "Sales Quote")
    begin
        Assert.IsFalse(SalesQuote.SalesLines."Invoice Discount Amount".Editable(), 'Invoice discount amount shoud not be editable');
    end;

    local procedure ValidateCreditMemoInvoiceDiscountAmountIsReadOnly(var SalesCreditMemo: TestPage "Sales Credit Memo")
    begin
        Assert.IsFalse(SalesCreditMemo.SalesLines."Invoice Discount Amount".Editable(), 'Invoice discount amount shoud not be editable');
    end;

    local procedure ValidateBlanketOrderInvoiceDiscountAmountIsReadOnly(var BlanketSalesOrder: TestPage "Blanket Sales Order")
    begin
        Assert.IsFalse(BlanketSalesOrder.SalesLines."Invoice Discount Amount".Editable(), 'Invoice discount amount shoud not be editable');
    end;

    local procedure ValidateReturnOrderInvoiceDiscountAmountIsReadOnly(var SalesReturnOrder: TestPage "Sales Return Order")
    begin
        Assert.IsFalse(SalesReturnOrder.SalesLines."Invoice Discount Amount".Editable(), 'Invoice discount amount shoud not be editable');
    end;

    local procedure InvoiceCheckCurrencyOnTotals(SalesInvoice: TestPage "Sales Invoice"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(SalesInvoice.SalesLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(SalesInvoice.SalesLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(SalesInvoice.SalesLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure OrderCheckCurrencyOnTotals(SalesOrder: TestPage "Sales Order"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(SalesOrder.SalesLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(SalesOrder.SalesLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(SalesOrder.SalesLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure QuoteCheckCurrencyOnTotals(SalesQuote: TestPage "Sales Quote"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(SalesQuote.SalesLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(SalesQuote.SalesLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(SalesQuote.SalesLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure BlanketOrderCheckCurrencyOnTotals(BlanketSalesOrder: TestPage "Blanket Sales Order"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(BlanketSalesOrder.SalesLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure ReturnOrderCheckCurrencyOnTotals(SalesReturnOrder: TestPage "Sales Return Order"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(SalesReturnOrder.SalesLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(SalesReturnOrder.SalesLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(SalesReturnOrder.SalesLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure CreditMemoCheckCurrencyOnTotals(SalesCreditMemo: TestPage "Sales Credit Memo"; ExpectedCurrencySign: Code[10])
    begin
        VerifyCurrencyInCaption(SalesCreditMemo.SalesLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(SalesCreditMemo.SalesLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign);
        VerifyCurrencyInCaption(SalesCreditMemo.SalesLines."Total VAT Amount".Caption, ExpectedCurrencySign);
    end;

    local procedure VerifyCurrencyInCaption(FieldCaption: Text; CurrencyCode: Code[10])
    begin
        Assert.TextEndsWith(FieldCaption, StrSubstNo('(%1)', CurrencyCode));
    end;

    local procedure CreateSalesDocumentWithCurrency(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var Item: Record Item; var CurrencyCode: Code[10]; DocumentType: Enum "Sales Document Type"; ExchangeRate: Decimal)
    begin
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(LibraryRandom.RandDate(-10), ExchangeRate, ExchangeRate);

        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(10, 20));
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(20, 100));
    end;

    local procedure CreateInvoiceWithOneLineThroughTestPage(Customer: Record Customer; Item: Record Item; ItemQuantity: Integer; var SalesInvoice: TestPage "Sales Invoice")
    begin
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer."No.");

        SalesInvoice.SalesLines.First();
        SalesInvoice.SalesLines.Type.SetValue('Item');
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        SalesInvoice.SalesLines.Quantity.SetValue(ItemQuantity);

        // Trigger Save
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.First();
    end;

    local procedure CreateOrderWithOneLineThroughTestPage(Customer: Record Customer; Item: Record Item; ItemQuantity: Integer; var SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);

        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.Type.SetValue('Item');
        SalesOrder.SalesLines."No.".SetValue(Item."No.");
        SalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);

        if DoesCustomerHaveInvDiscounts(Customer) then begin
            LibraryVariableStorage.Enqueue('Do you');
            LibraryVariableStorage.Enqueue(true);
            SalesOrder.CalculateInvoiceDiscount.Invoke();
        end;

        // Trigger Save
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.First();
    end;

    local procedure CreateQuoteWithOneLineThroughTestPage(Customer: Record Customer; Item: Record Item; ItemQuantity: Integer; var SalesQuote: TestPage "Sales Quote")
    begin
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);

        SalesQuote.SalesLines.First();
        SalesQuote.SalesLines.Type.SetValue('Item');
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.SalesLines.Quantity.SetValue(ItemQuantity);

        if DoesCustomerHaveInvDiscounts(Customer) then begin
            LibraryVariableStorage.Enqueue('Do you');
            LibraryVariableStorage.Enqueue(true);
            SalesQuote.CalculateInvoiceDiscount.Invoke();
        end;

        // Trigger Save
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.First();
    end;

    local procedure CreateBlanketOrderWithOneLineThroughTestPage(Customer: Record Customer; Item: Record Item; ItemQuantity: Integer; var BlanketSalesOrder: TestPage "Blanket Sales Order")
    begin
        BlanketSalesOrder.OpenNew();
        BlanketSalesOrder."Sell-to Customer Name".SetValue(Customer."No.");

        BlanketSalesOrder.SalesLines.First();
        BlanketSalesOrder.SalesLines.Type.SetValue('Item');
        BlanketSalesOrder.SalesLines."No.".SetValue(Item."No.");
        BlanketSalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);

        if DoesCustomerHaveInvDiscounts(Customer) then begin
            LibraryVariableStorage.Enqueue('Do you');
            LibraryVariableStorage.Enqueue(true);
            BlanketSalesOrder.CalculateInvoiceDiscount.Invoke();
        end;

        // Trigger Save
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.First();
    end;

    local procedure CreateReturnOrderWithOneLineThroughTestPage(Customer: Record Customer; Item: Record Item; ItemQuantity: Integer; var SalesReturnOrder: TestPage "Sales Return Order")
    begin
        SalesReturnOrder.OpenNew();
        SalesReturnOrder."Sell-to Customer Name".SetValue(Customer."No.");

        SalesReturnOrder.SalesLines.First();
        SalesReturnOrder.SalesLines.Type.SetValue('Item');
        SalesReturnOrder.SalesLines."No.".SetValue(Item."No.");
        SalesReturnOrder.SalesLines.Quantity.SetValue(ItemQuantity);

        if DoesCustomerHaveInvDiscounts(Customer) then begin
            LibraryVariableStorage.Enqueue('Do you');
            LibraryVariableStorage.Enqueue(true);
            SalesReturnOrder.CalculateInvoiceDiscount.Invoke();
        end;

        // Trigger Save
        SalesReturnOrder.SalesLines.Next();
        SalesReturnOrder.SalesLines.First();
    end;

    local procedure CreateCreditMemoWithOneLineThroughTestPage(Customer: Record Customer; Item: Record Item; ItemQuantity: Integer; var SalesCreditMemo: TestPage "Sales Credit Memo")
    begin
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer."No.");

        SalesCreditMemo.SalesLines.First();
        SalesCreditMemo.SalesLines.Type.SetValue('Item');
        SalesCreditMemo.SalesLines."No.".SetValue(Item."No.");
        SalesCreditMemo.SalesLines.Quantity.SetValue(ItemQuantity);

        if DoesCustomerHaveInvDiscounts(Customer) then begin
            LibraryVariableStorage.Enqueue('Do you');
            LibraryVariableStorage.Enqueue(true);
            SalesCreditMemo.CalculateInvoiceDiscount.Invoke();
        end;

        // Trigger Save
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.First();
    end;

    local procedure CreateOrderThroughTestPageForItemWithGivenNumberOfUOMs(var SalesOrder: TestPage "Sales Order"; NoOfAdditionalUOMs: Integer)
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        CreateItemWithGivenNumberOfAdditionalUOMs(Item, NoOfAdditionalUOMs);
        CreateOrderWithOneLineThroughTestPage(Customer, Item, LibraryRandom.RandInt(10), SalesOrder);
    end;

    local procedure CreateInvoiceThroughTestPageForItemWithGivenNumberOfUOMs(var SalesInvoice: TestPage "Sales Invoice"; NoOfAdditionalUOMs: Integer)
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        CreateItemWithGivenNumberOfAdditionalUOMs(Item, NoOfAdditionalUOMs);
        CreateInvoiceWithOneLineThroughTestPage(Customer, Item, LibraryRandom.RandInt(10), SalesInvoice);
    end;

    local procedure CreateQuoteThroughTestPageForItemWithGivenNumberOfUOMs(var SalesQuote: TestPage "Sales Quote"; NoOfAdditionalUOMs: Integer)
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        CreateItemWithGivenNumberOfAdditionalUOMs(Item, NoOfAdditionalUOMs);
        CreateQuoteWithOneLineThroughTestPage(Customer, Item, LibraryRandom.RandInt(10), SalesQuote);
    end;

    local procedure CreateCrMemoThroughTestPageForItemWithGivenNumberOfUOMs(var SalesCreditMemo: TestPage "Sales Credit Memo"; NoOfAdditionalUOMs: Integer)
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        CreateItemWithGivenNumberOfAdditionalUOMs(Item, NoOfAdditionalUOMs);
        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, LibraryRandom.RandInt(10), SalesCreditMemo);
    end;

    local procedure CreateSalesDocumentForItemWithGivenNumberOfUOMs(var SalesLine: Record "Sales Line"; NoOfAdditionalUOMs: Integer)
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        CreateCustomer(Customer);
        CreateItemWithGivenNumberOfAdditionalUOMs(Item, NoOfAdditionalUOMs);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateCustomerNoPricesIncludingVAT(PricesIncludingVAT: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Prices Including VAT", PricesIncludingVAT);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccountForInvoiceRounding(CustomerPostingGroupCode: Code[20]): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountNo: Code[20];
    begin
        LibrarySales.SetInvoiceRounding(true);
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        CustomerPostingGroup.Validate("Invoice Rounding Account", GLAccountNo);
        CustomerPostingGroup.Modify(true);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := 1;
        GeneralLedgerSetup.Modify();
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

    local procedure DoInvoiceRounding(CurrencyCode: Code[10]; Amount: Decimal): Decimal
    var
        Currency: Record Currency;
    begin
        if not Currency.Get(CurrencyCode) then
            Currency.InitRoundingPrecision();
        exit(Round(Amount, Currency."Invoice Rounding Precision", Currency.InvoiceRoundingDirection()))
    end;

    local procedure DoesCustomerHaveInvDiscounts(var Customer: Record Customer): Boolean
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvoiceDisc.SetRange(Code, Customer."No.");
        CustInvoiceDisc.SetRange("Currency Code", Customer."Currency Code");
        exit(not CustInvoiceDisc.IsEmpty);
    end;

    local procedure GetDifferentCurrencyCode(): Code[10]
    begin
        exit(LibraryERM.CreateCurrencyWithRandomExchRates());
    end;

    local procedure AddInvoiceDiscToCustomer(Customer: Record Customer; MinimumAmount: Decimal; Percentage: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", Customer."Currency Code", MinimumAmount);
        CustInvoiceDisc.Validate("Discount %", Percentage);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure OpenSalesInvoice(SalesHeader: Record "Sales Header"; var SalesInvoice: TestPage "Sales Invoice")
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
    end;

    local procedure OpenSalesOrder(SalesHeader: Record "Sales Header"; var SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
    end;

    local procedure OpenSalesCreditMemo(SalesHeader: Record "Sales Header"; var SalesCreditMemo: TestPage "Sales Credit Memo")
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", SalesHeader."No.");
    end;

    local procedure OpenSalesQuote(SalesHeader: Record "Sales Header"; var SalesQuote: TestPage "Sales Quote")
    begin
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", SalesHeader."No.");
    end;

    local procedure OpenBlanketOrder(SalesHeader: Record "Sales Header"; var BlanketSalesOrder: TestPage "Blanket Sales Order")
    begin
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
    end;

    local procedure OpenSalesReturnOrder(SalesHeader: Record "Sales Header"; var SalesReturnOrder: TestPage "Sales Return Order")
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", SalesHeader."No.");
    end;

    local procedure CreateInvoiceWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 30);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        for I := 1 to NumberOfLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ItemQuantity);
    end;

    local procedure CreateOrderWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        for I := 1 to NumberOfLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ItemQuantity);
    end;

    local procedure CreateCreditMemoWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 30);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        for I := 1 to NumberOfLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ItemQuantity);
    end;

    local procedure CreateQuoteWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        for I := 1 to NumberOfLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ItemQuantity);
    end;

    local procedure CreateBlanketOrderWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Customer."No.");

        for I := 1 to NumberOfLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ItemQuantity);
    end;

    local procedure CreateReturnOrderWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 30);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");

        for I := 1 to NumberOfLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ItemQuantity);
    end;

    local procedure CreateOrderAndCalcDiscounts(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateItem(Item, LibraryRandom.RandDecInDecimalRange(1000, 2000, 2));

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesCalcDiscountByType.ResetRecalculateInvoiceDisc(SalesHeader);
    end;

    local procedure SetInvDiscAmountInSalesOrderSubPage(DocNo: Code[20]) InvDiscountAmount: Integer
    var
        SalesOrderSubform: TestPage "Sales Order Subform";
    begin
        SalesOrderSubform.OpenEdit();
        SalesOrderSubform.FILTER.SetFilter("Document No.", DocNo);
        InvDiscountAmount := LibraryRandom.RandInt(100);
        SalesOrderSubform."Invoice Discount Amount".SetValue(InvDiscountAmount);
    end;

    local procedure SetupDataForDiscountTypePct(var Item: Record Item; var ItemQuantity: Decimal; var Customer: Record Customer)
    var
        MinAmt: Decimal;
        ItemUnitPrice: Decimal;
        DiscPct: Decimal;
    begin
        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemUnitPrice, ItemUnitPrice * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);

        CreateItem(Item, ItemUnitPrice);
        CreateCustomerWithDiscount(Customer, DiscPct, MinAmt);
    end;

    local procedure SetupDataForDiscountTypeAmt(var Item: Record Item; var ItemQuantity: Decimal; var Customer: Record Customer; var InvoiceDiscountAmount: Decimal)
    begin
        SetAllowManualDisc();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer);
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(1, Round(Item."Unit Price" * ItemQuantity, 1, '<'), 2);
    end;

    local procedure UpdateAccountNoOnSalesLine(DocumentNo: Code[20]; NewAccountNo: Code[20])
    var
        RefSalesLine: Record "Sales Line";
        SalesOrderSubform: TestPage "Sales Order Subform";
    begin
        SalesOrderSubform.OpenEdit();
        SalesOrderSubform.FILTER.SetFilter("Document No.", DocumentNo);
        SalesOrderSubform.FILTER.SetFilter(Type, Format(RefSalesLine.Type::"G/L Account"));
        SalesOrderSubform."No.".SetValue(NewAccountNo);
    end;

    local procedure SetCurrencyOnOrderAndVerify(SalesOrder: TestPage "Sales Order"; CurrencyCode: Code[10]; Item: Record Item; SalesLine: Record "Sales Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        SalesOrder."Currency Code".SetValue(CurrencyCode);
        OrderCheckCurrencyOnTotals(SalesOrder, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        SalesOrder.SalesLines."Total Amount Excl. VAT".AssertEquals(Round(Item."Unit Price" * SalesLine.Quantity * ExchangeRate));
    end;

    local procedure SetCurrencyOnInvoiceAndVerify(SalesInvoice: TestPage "Sales Invoice"; CurrencyCode: Code[10]; Item: Record Item; SalesLine: Record "Sales Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        SalesInvoice."Currency Code".SetValue(CurrencyCode);
        InvoiceCheckCurrencyOnTotals(SalesInvoice, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        SalesInvoice.SalesLines."Total Amount Excl. VAT".AssertEquals(Round(Item."Unit Price" * SalesLine.Quantity * ExchangeRate));
    end;

    local procedure SetCurrencyOnQuoteAndVerify(SalesQuote: TestPage "Sales Quote"; CurrencyCode: Code[10]; Item: Record Item; SalesLine: Record "Sales Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        SalesQuote."Currency Code".SetValue(CurrencyCode);
        QuoteCheckCurrencyOnTotals(SalesQuote, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        SalesQuote.SalesLines."Total Amount Excl. VAT".AssertEquals(Round(Item."Unit Price" * SalesLine.Quantity * ExchangeRate));
    end;

    local procedure SetCurrencyOnCreditMemoAndVerify(SalesCreditMemo: TestPage "Sales Credit Memo"; CurrencyCode: Code[10]; Item: Record Item; SalesLine: Record "Sales Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        SalesCreditMemo."Currency Code".SetValue(CurrencyCode);
        CreditMemoCheckCurrencyOnTotals(SalesCreditMemo, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AssertEquals(Round(Item."Unit Price" * SalesLine.Quantity * ExchangeRate));
    end;

    local procedure SetCurrencyOnBlanketOrderAndVerify(BlanketSalesOrder: TestPage "Blanket Sales Order"; CurrencyCode: Code[10]; Item: Record Item; SalesLine: Record "Sales Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        BlanketSalesOrder."Currency Code".SetValue(CurrencyCode);
        BlanketOrderCheckCurrencyOnTotals(BlanketSalesOrder, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".AssertEquals(Round(Item."Unit Price" * SalesLine.Quantity * ExchangeRate));
    end;

    local procedure SetCurrencyOnReturnOrderAndVerify(SalesReturnOrder: TestPage "Sales Return Order"; CurrencyCode: Code[10]; Item: Record Item; SalesLine: Record "Sales Line"; ExchangeRate: Decimal)
    begin
        EnqueueChangeCurrencyCodeConfirmation();

        SalesReturnOrder."Currency Code".SetValue(CurrencyCode);
        ReturnOrderCheckCurrencyOnTotals(SalesReturnOrder, GeneralLedgerSetup.GetCurrencyCode(CurrencyCode));
        SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AssertEquals(Round(Item."Unit Price" * SalesLine.Quantity * ExchangeRate));
    end;

    local procedure EnqueueChangeCurrencyCodeConfirmation()
    begin
        LibraryVariableStorage.Enqueue(ChangeCurrencyConfirmQst);
        LibraryVariableStorage.Enqueue(true);
    end;

    local procedure VerifyInvDiscAmountInSalesOrderSubpage(DocNo: Code[20]; InvDiscountAmount: Integer)
    var
        SalesOrderSubform: TestPage "Sales Order Subform";
    begin
        SalesOrderSubform.OpenEdit();
        SalesOrderSubform.FILTER.SetFilter("Document No.", DocNo);
        SalesOrderSubform."Invoice Discount Amount".AssertEquals(InvDiscountAmount);
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

    local procedure SetDocumentDefaultLineType(SalesLineType: Enum "Sales Line Type")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Document Default Line Type" := SalesLineType;
        SalesReceivablesSetup.Modify();
    end;

    local procedure CreateInvoiceDiscForCustWithDiscPctAndMinValue(var Customer: Record Customer; DiscountPct: Decimal; MinValue: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(
          CustInvoiceDisc, Customer."No.", Customer."Currency Code", MinValue);
        CustInvoiceDisc.Validate("Discount %", DiscountPct);
        CustInvoiceDisc.Modify(true);
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
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", false);
        SalesReceivablesSetup.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure BlanketOrderConvertedMessageHandler(Msg: Text[1024])
    begin
        Assert.ExpectedMessage(BlanketOrderMsg, Msg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Msg);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsModalHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreNearlyEqual(InvDiscAmount, SalesStatistics.InvDiscountAmount.AsDecimal(),
          0.2, 'Invoice Discount Amount is not correct');
        Assert.AreNearlyEqual(TotalAmountInclVAT, SalesStatistics.TotalAmount2.AsDecimal(),
          0.2, 'Total Amount Incl. VAT is not correct');
        Assert.AreNearlyEqual(VATApplied, SalesStatistics.VATAmount.AsDecimal(),
          0.2, 'VAT Amount is not correct');
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreNearlyEqual(InvDiscAmount, SalesStatistics.InvDiscountAmount.AsDecimal(),
          0.2, 'Invoice Discount Amount is not correct');
        Assert.AreNearlyEqual(TotalAmountInclVAT, SalesStatistics.TotalAmount2.AsDecimal(),
          0.2, 'Total Amount Incl. VAT is not correct');
        Assert.AreNearlyEqual(VATApplied, SalesStatistics.VATAmount.AsDecimal(),
          0.2, 'VAT Amount is not correct');
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
    var
        UnitOfMeasureCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(UnitOfMeasureCode);
        ResourceUnitsofMeasure.FILTER.SetFilter(Code, '<>' + Format(UnitOfMeasureCode));
        Assert.IsFalse(ResourceUnitsofMeasure.First(), 'List should be empty');
        ResourceUnitsofMeasure.FILTER.SetFilter(Code, Format(UnitOfMeasureCode));
        Assert.IsTrue(ResourceUnitsofMeasure.First(), 'List should not be empty');
        ResourceUnitsofMeasure.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsModalHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreEqual(InvDiscAmount, SalesOrderStatistics.InvDiscountAmount_General.AsDecimal(),
          'Invoice Discount Amount is not correct');
        Assert.AreEqual(TotalAmountInclVAT, SalesOrderStatistics."TotalAmount2[1]".AsDecimal(),
          'Total Amount Incl. VAT is not correct');
        Assert.AreEqual(VATApplied, SalesOrderStatistics.VATAmount.AsDecimal(),
          'VAT Amount is not correct');
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        VATApplied: Variant;
        TotalAmountInclVAT: Variant;
        InvDiscAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount);
        LibraryVariableStorage.Dequeue(TotalAmountInclVAT);
        LibraryVariableStorage.Dequeue(VATApplied);

        Assert.AreEqual(InvDiscAmount, SalesOrderStatistics.InvDiscountAmount_General.AsDecimal(),
          'Invoice Discount Amount is not correct');
        Assert.AreEqual(TotalAmountInclVAT, SalesOrderStatistics."TotalAmount2[1]".AsDecimal(),
          'Total Amount Incl. VAT is not correct');
        Assert.AreEqual(VATApplied, SalesOrderStatistics.VATAmount.AsDecimal(),
          'VAT Amount is not correct');
    end;
}

