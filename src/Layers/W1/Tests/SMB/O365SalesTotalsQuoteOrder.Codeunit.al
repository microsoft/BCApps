codeunit 138006 "O365 Sales Totals Quote/Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Invoice Discount] [SMB] [Sales]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        ChangeConfirmMsg: Label 'Do you want';

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
        ItemNoSeries: Text[20];
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Sales Totals Quote/Order");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Sales Totals Quote/Order");

        ClearTable(DATABASE::"Res. Ledger Entry");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());

        SalesSetup.Get();
        SalesSetup."Stockout Warning" := false;
        SalesSetup.Modify();

        InventorySetup.Get();
        ItemNoSeries := LibraryUtility.GetGlobalNoSeriesCode();
        if InventorySetup."Item Nos." <> ItemNoSeries then begin
            InventorySetup.Validate("Item Nos.", ItemNoSeries);
            InventorySetup.Modify();
        end;

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Sales Totals Quote/Order");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::"Res. Ledger Entry":
                ResLedgerEntry.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    [Test]
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

        CheckTotals(
          ItemQuantity * Item."Unit Price", true, SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesQuote.SalesLines."Total VAT Amount".AsDecimal());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QuoteAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        ItemQuantity: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateQuoteWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesQuote);
        SalesQuote.CalculateInvoiceDiscount.Invoke();

        CheckQuoteDiscountTypePercentage(DiscPct, ItemQuantity * Item."Unit Price", SalesQuote, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QuoteModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
        NewLineAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateQuoteWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesQuote);

        ItemQuantity := ItemQuantity * 2;
        SalesQuote.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesQuote.CalculateInvoiceDiscount.Invoke();
        TotalAmount := ItemQuantity * Item."Unit Price";
        CheckQuoteDiscountTypePercentage(DiscPct, TotalAmount, SalesQuote, true, '');

        SalesQuote.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        SalesQuote.CalculateInvoiceDiscount.Invoke();
        TotalAmount := 2 * TotalAmount;
        CheckQuoteDiscountTypePercentage(DiscPct, TotalAmount, SalesQuote, true, '');

        NewLineAmount := Round(SalesQuote.SalesLines."Line Amount".AsDecimal() / 100 * DiscPct, 1);
        SalesQuote.SalesLines."Line Amount".SetValue(NewLineAmount);
        SalesQuote.CalculateInvoiceDiscount.Invoke();
        CheckQuoteDiscountTypePercentage(DiscPct, NewLineAmount, SalesQuote, true, '');

        SalesQuote.SalesLines."Line Discount %".SetValue('0');
        SalesQuote.CalculateInvoiceDiscount.Invoke();
        CheckQuoteDiscountTypePercentage(DiscPct, TotalAmount, SalesQuote, true, '');

        SalesQuote.SalesLines."No.".SetValue('');
        SalesQuote.CalculateInvoiceDiscount.Invoke();
        TotalAmount := 0;
        CheckQuoteDiscountTypePercentage(0, TotalAmount, SalesQuote, false, '');

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
        SalesLine.SetRange("Document No.", SalesQuote."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        OpenSalesQuote(SalesHeader, SalesQuote);

        TotalAmount := Item."Unit Price" * ItemQuantity * NumberOfLines;
        CheckQuoteDiscountTypePercentage(DiscPct, TotalAmount, SalesQuote, true, '');
    end;

    [Test]
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
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        OpenSalesQuote(SalesHeader, SalesQuote);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckQuoteDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesQuote, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QuoteChangingVATBusPostingGroupUpdatesTotalsAndDiscounts()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        LibraryApplicationArea.EnableVATSetup();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesQuote(SalesHeader, SalesQuote);

        SalesQuote."VAT Bus. Posting Group".SetValue(
          LibrarySmallBusiness.FindVATBusPostingGroupZeroVAT(Item."VAT Prod. Posting Group"));

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckQuoteDiscountTypePercentage(DiscPct, TotalAmount, SalesQuote, false, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QuoteChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);

        SalesQuote."Sell-to Customer Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckQuoteDiscountTypePercentage(NewCustDiscPct, TotalAmount, SalesQuote, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
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
        TotalAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesQuote(SalesHeader, SalesQuote);

        SalesQuote."Sell-to Customer Name".SetValue(NewCustomer.Name);
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckQuoteDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesQuote, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure QuoteChangeSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        CreateCustomer(NewCustomer);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);

        AnswerYesToAllConfirmDialogs();
        SalesQuote."Sell-to Customer Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckQuoteDiscountTypePercentage(0, TotalAmount, SalesQuote, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QuoteChangingBillToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        NewCustomerDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesQuote(SalesHeader, SalesQuote);

        SalesQuote."Bill-to Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckQuoteDiscountTypePercentage(NewCustomerDiscPct, TotalAmount, SalesQuote, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QuoteChangingBillToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
        NewCustomerDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesQuote(SalesHeader, SalesQuote);

        SalesQuote."Bill-to Name".SetValue(NewCustomer."No.");
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckQuoteDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesQuote, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QuoteChangingCurrencyUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        OpenSalesQuote(SalesHeader, SalesQuote);

        SalesQuote."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        TotalAmount := NumberOfLines * SalesLine."Line Amount";
        CheckQuoteDiscountTypePercentage(DiscPct, TotalAmount, SalesQuote, true, SalesQuote."Currency Code".Value);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QuoteChangingCurrencySetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesQuote(SalesHeader, SalesQuote);

        SalesQuote."Currency Code".SetValue(GetDifferentCurrencyCode());
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        TotalAmount := NumberOfLines * SalesLine."Line Amount";
        CheckQuoteDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesQuote, true, SalesQuote."Currency Code".Value);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure QuoteMakeInvoiceDiscountTypePercentageIsKept()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        SalesInvoice.Trap();
        OpenSalesQuote(SalesHeader, SalesQuote);
        SalesQuote.SalesLines."Invoice Disc. Pct.".SetValue(DiscPct);

        AnswerYesToAllConfirmDialogs();
        SalesQuote.MakeInvoice.Invoke();

        TotalAmount := Item."Unit Price" * ItemQuantity * NumberOfLines;
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, SalesInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure QuoteMakeInvoiceDiscountTypeAmountIsKept()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        SalesInvoice.Trap();
        OpenSalesQuote(SalesHeader, SalesQuote);

        AnswerYesToAllConfirmDialogs();
        SalesQuote.MakeInvoice.Invoke();

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckInvoiceDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesInvoice, true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteSetLocalCurrencySignOnTotals()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesQuote: TestPage "Sales Quote";
        ItemUnitPrice: Decimal;
    begin
        Initialize();

        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        Customer."Currency Code" := GetDifferentCurrencyCode();
        Customer.Modify(true);
        SalesQuote.OpenNew();

        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);
        QuoteCheckCurrencyOnTotals(SalesQuote, Customer."Currency Code");

        SalesQuote.SalesLines.New();
        QuoteCheckCurrencyOnTotals(SalesQuote, Customer."Currency Code");

        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        QuoteCheckCurrencyOnTotals(SalesQuote, Customer."Currency Code");
    end;

    [Test]
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

        CheckTotals(
          ItemQuantity * Item."Unit Price", true, SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesOrder.SalesLines."Total VAT Amount".AsDecimal());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure OrderAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        ItemQuantity: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesOrder);
        SalesOrder.CalculateInvoiceDiscount.Invoke();

        CheckOrderDiscountTypePercentage(DiscPct, ItemQuantity * Item."Unit Price", SalesOrder, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure OrderModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
        NewLineAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateOrderWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesOrder);

        ItemQuantity := ItemQuantity * 2;
        SalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        SalesOrder.CalculateInvoiceDiscount.Invoke();
        CheckOrderDiscountTypePercentage(DiscPct, TotalAmount, SalesOrder, true, '');

        SalesOrder.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        SalesOrder.CalculateInvoiceDiscount.Invoke();
        CheckOrderDiscountTypePercentage(DiscPct, TotalAmount, SalesOrder, true, '');

        NewLineAmount := Round(SalesOrder.SalesLines."Line Amount".AsDecimal() / 100 * DiscPct, 1);
        SalesOrder.SalesLines."Line Amount".SetValue(NewLineAmount);
        SalesOrder.CalculateInvoiceDiscount.Invoke();
        CheckOrderDiscountTypePercentage(DiscPct, NewLineAmount, SalesOrder, true, '');

        SalesOrder.SalesLines."Line Discount %".SetValue('0');
        SalesOrder.CalculateInvoiceDiscount.Invoke();
        CheckOrderDiscountTypePercentage(DiscPct, TotalAmount, SalesOrder, true, '');

        SalesOrder.SalesLines."No.".SetValue('');
        TotalAmount := 0;
        SalesOrder.CalculateInvoiceDiscount.Invoke();
        CheckOrderDiscountTypePercentage(0, TotalAmount, SalesOrder, false, '');

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrder."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        OpenSalesOrder(SalesHeader, SalesOrder);

        TotalAmount := Item."Unit Price" * ItemQuantity * NumberOfLines;
        CheckOrderDiscountTypePercentage(DiscPct, TotalAmount, SalesOrder, true, '');
    end;

    [Test]
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
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        OpenSalesOrder(SalesHeader, SalesOrder);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckOrderDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesOrder, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure OrderChangingVATBusPostingGroupUpdatesTotalsAndDiscounts()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        LibraryApplicationArea.EnableVATSetup();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesOrder(SalesHeader, SalesOrder);

        SalesOrder."VAT Bus. Posting Group".SetValue(
          LibrarySmallBusiness.FindVATBusPostingGroupZeroVAT(Item."VAT Prod. Posting Group"));

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckOrderDiscountTypePercentage(DiscPct, TotalAmount, SalesOrder, false, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure OrderChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);

        SalesOrder."Sell-to Customer Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckOrderDiscountTypePercentage(NewCustDiscPct, TotalAmount, SalesOrder, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
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
        TotalAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesOrder(SalesHeader, SalesOrder);

        SalesOrder."Sell-to Customer Name".SetValue(NewCustomer.Name);
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckOrderDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesOrder, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OrderChangeSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        CreateCustomer(NewCustomer);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);

        AnswerYesToAllConfirmDialogs();
        SalesOrder."Sell-to Customer Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckOrderDiscountTypePercentage(0, TotalAmount, SalesOrder, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure OrderChangingBillToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        NewCustomerDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesOrder(SalesHeader, SalesOrder);

        SalesOrder."Bill-to Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckOrderDiscountTypePercentage(NewCustomerDiscPct, TotalAmount, SalesOrder, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure OrderChangingBillToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
        NewCustomerDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustomerDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustomerDiscPct, 0);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesOrder(SalesHeader, SalesOrder);

        SalesOrder."Bill-to Name".SetValue(NewCustomer."No.");
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckOrderDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesOrder, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure OrderChangingCurrencyUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        OpenSalesOrder(SalesHeader, SalesOrder);

        SalesOrder."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        TotalAmount := NumberOfLines * SalesLine."Line Amount";
        CheckOrderDiscountTypePercentage(DiscPct, TotalAmount, SalesOrder, true, SalesOrder."Currency Code".Value);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure OrderChangingCurrencySetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesOrder: TestPage "Sales Order";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesOrder(SalesHeader, SalesOrder);

        CurrencyCode := GetDifferentCurrencyCode();
        SalesOrder."Currency Code".SetValue(CurrencyCode);
        Assert.AreEqual(0, SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(), 'Invoice discount not set to 0');

        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindLast();
        InvoiceDiscountAmount := InvoiceDiscountAmount /
          (CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        TotalAmount := NumberOfLines * SalesLine."Line Amount";
        CheckOrderDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesOrder, true, SalesOrder."Currency Code".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderSetLocalCurrencySignOnTotals()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesOrder: TestPage "Sales Order";
        ItemUnitPrice: Decimal;
    begin
        Initialize();

        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        Customer."Currency Code" := GetDifferentCurrencyCode();
        Customer.Modify(true);
        SalesOrder.OpenNew();

        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);
        OrderCheckCurrencyOnTotals(SalesOrder, Customer."Currency Code");

        SalesOrder.SalesLines.New();
        OrderCheckCurrencyOnTotals(SalesOrder, Customer."Currency Code");

        SalesOrder.SalesLines."No.".SetValue(Item."No.");
        OrderCheckCurrencyOnTotals(SalesOrder, Customer."Currency Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure OrderBillToNameValidationSavesBilltoICPartnerChange()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        ItemUnitPrice: Decimal;
        Lines: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Bill-to IC Partner Code" is changed on Sales Order "Bill-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();

        // [GIVEN] Sales Order "SO01" with Sales Lines created for Customer "CU01" and no discount
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        CreateOrderWithRandomNumberOfLines(SalesHeader, Item, Customer, 1, Lines);
        OpenSalesOrder(SalesHeader, SalesOrder);

        // [GIVEN] Customer "CU02" with "IC Partner Code" = "ICP01"
        CreateCustomer(Customer);
        Customer."IC Partner Code" := LibraryUtility.GenerateGUID();
        Customer.Modify(true);

        // [WHEN] Set "Bill-to Name" to "CU02" on Sales Order Page for "SO01"
        SalesOrder."Bill-to Name".SetValue(Customer."No.");

        // [THEN] "Bill-to IC Partner Code" is changed to "ICP01" on "SO01"
        SalesHeader.Find();
        SalesHeader.TestField("Bill-to IC Partner Code", Customer."IC Partner Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QuoteBillToNameValidationSavesBilltoICPartnerChange()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        ItemUnitPrice: Decimal;
        Lines: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Bill-to IC Partner Code" is changed on Sales Quote "Bill-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();

        // [GIVEN] Sales Quote "SQ01" with Sales Lines created for Customer "CU01" and no discount
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        CreateQuoteWithRandomNumberOfLines(SalesHeader, Item, Customer, 1, Lines);
        OpenSalesQuote(SalesHeader, SalesQuote);

        // [GIVEN] Customer "CU02" with "IC Partner Code" = "ICP01"
        CreateCustomer(Customer);
        Customer."IC Partner Code" := LibraryUtility.GenerateGUID();
        Customer.Modify(true);

        // [WHEN] Set "Bill-to Name" to "CU02" on Sales Quote Page for "SQ01"
        SalesQuote."Bill-to Name".SetValue(Customer."No.");

        // [THEN] "Bill-to IC Partner Code" is changed to "ICP01" on "SQ01"
        SalesHeader.Find();
        SalesHeader.TestField("Bill-to IC Partner Code", Customer."IC Partner Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReturnOrderBillToNameValidationSavesBilltoICPartnerChange()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
        ItemUnitPrice: Decimal;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Bill-to IC Partner Code" is changed on Sales Return Order "Bill-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();
        LibraryApplicationArea.EnableReturnOrderSetup();

        // [GIVEN] Sales Return Order "SO01" with Sales Lines created for Customer "CU01" and no discount
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        CreateSalesHeaderWithDocTypeAndNumberOfLines(
          SalesHeader, Item, Customer, 1, 1, SalesHeader."Document Type"::"Return Order");
        OpenSalesReturnOrder(SalesHeader, SalesReturnOrder);

        // [GIVEN] Customer "CU02" with "IC Partner Code" = "ICP01"
        CreateCustomer(Customer);
        Customer."IC Partner Code" := LibraryUtility.GenerateGUID();
        Customer.Modify(true);

        // [WHEN] Set "Bill-to Name" to "CU02" on Sales Return Order Page for "SO01"
        SalesReturnOrder."Bill-to Name".SetValue(Customer."No.");

        // [THEN] "Bill-to IC Partner Code" is changed to "ICP01" on "SO01"
        SalesHeader.Find();
        SalesHeader.TestField("Bill-to IC Partner Code", Customer."IC Partner Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure BlanketOrderBillToNameValidationSavesBilltoICPartnerChange()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        ItemUnitPrice: Decimal;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Bill-to IC Partner Code" is changed on Blanket Sales Order "Bill-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();

        // [GIVEN] Blanket Sales Order "SO01" with Sales Lines created for Customer "CU01" and no discount
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        CreateSalesHeaderWithDocTypeAndNumberOfLines(
          SalesHeader, Item, Customer, 1, 1, SalesHeader."Document Type"::"Blanket Order");
        OpenSalesBlanketOrder(SalesHeader, BlanketSalesOrder);

        // [GIVEN] Customer "CU02" with "IC Partner Code" = "ICP01"
        CreateCustomer(Customer);
        Customer."IC Partner Code" := LibraryUtility.GenerateGUID();
        Customer.Modify(true);

        // [WHEN] Set "Bill-to Name" to "CU02" on Blanket Sales Order Page for "SO01"
        BlanketSalesOrder."Bill-to Name".SetValue(Customer."No.");

        // [THEN] "Bill-to IC Partner Code" is changed to "ICP01" on "SO01"
        SalesHeader.Find();
        SalesHeader.TestField("Bill-to IC Partner Code", Customer."IC Partner Code");
    end;

    local procedure CreateCustomerWithDiscount(var Customer: Record Customer; DiscPct: Decimal; MinimumAmount: Decimal)
    begin
        CreateCustomer(Customer);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscPct, MinimumAmount, '');
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        Customer.Name := Customer."No.";
        Customer.Modify();
    end;

    local procedure CreateItem(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Modify();
    end;

    local procedure CheckExistOrAddCurrencyExchageRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.SetFilter("Starting Date", '<=%1', WorkDate());
        if not CurrencyExchangeRate.FindFirst() then
            LibrarySmallBusiness.CreateCurrencyExchangeRate(CurrencyExchangeRate, CurrencyCode, WorkDate());
    end;

    local procedure CheckInvoiceDiscountTypePercentage(DiscPct: Decimal; TotalAmountWithoutDiscount: Decimal; SalesInvoice: TestPage "Sales Invoice"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        DiscAmt: Decimal;
        TotalAmount: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);

        DiscAmt := TotalAmountWithoutDiscount * DiscPct / 100;
        RoundAmount(DiscAmt, CurrencyCode);

        TotalAmount := TotalAmountWithoutDiscount - DiscAmt;

        Assert.AreEqual(
          DiscPct, SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          'Customer Discount Percentage was not set to correct value');
        Assert.AreEqual(
          DiscAmt, SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          'Customer Invoice Discount Amount was not set to correct value');

        CheckTotals(
          TotalAmount, VATApplied, SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesInvoice.SalesLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckInvoiceDiscountTypeAmount(InvoiceDiscAmt: Decimal; TotalAmountWithoutDiscount: Decimal; SalesInvoice: TestPage "Sales Invoice"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);
        RoundAmount(InvoiceDiscAmt, CurrencyCode);

        DiscPct := Round(InvoiceDiscAmt * 100 / TotalAmountWithoutDiscount, 0.00001);

        Assert.AreEqual(
          DiscPct, SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          'Customer Discount Percentage was not set to the correct value');
        Assert.AreEqual(
          InvoiceDiscAmt, SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          'Invoice Discount Amount was not set to correct value');

        TotalAmount := TotalAmountWithoutDiscount - InvoiceDiscAmt;
        CheckTotals(
          TotalAmount, VATApplied, SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesInvoice.SalesLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckQuoteDiscountTypePercentage(DiscPct: Decimal; TotalAmountWithoutDiscount: Decimal; SalesQuote: TestPage "Sales Quote"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        DiscAmt: Decimal;
        TotalAmount: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);

        DiscAmt := TotalAmountWithoutDiscount * DiscPct / 100;
        RoundAmount(DiscAmt, CurrencyCode);

        TotalAmount := TotalAmountWithoutDiscount - DiscAmt;

        SalesQuote.SalesLines."Invoice Disc. Pct.".AssertEquals(DiscPct);
        SalesQuote.SalesLines."Invoice Discount Amount".AssertEquals(DiscAmt);

        CheckTotals(
          TotalAmount, VATApplied, SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesQuote.SalesLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckQuoteDiscountTypeAmount(InvoiceDiscAmt: Decimal; TotalAmountWithoutDiscount: Decimal; SalesQuote: TestPage "Sales Quote"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        DiscPct := Round(InvoiceDiscAmt * 100 / TotalAmountWithoutDiscount, 0.00001);

        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);
        RoundAmount(InvoiceDiscAmt, CurrencyCode);

        Assert.AreEqual(
          DiscPct, SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          'Customer Discount Percentage should be zero for Invoice Discount Type Amount');
        Assert.AreEqual(
          InvoiceDiscAmt, SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          'Invoice Discount Amount was not set to correct value');

        TotalAmount := TotalAmountWithoutDiscount - InvoiceDiscAmt;
        CheckTotals(
          TotalAmount, VATApplied, SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesQuote.SalesLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckOrderDiscountTypePercentage(DiscPct: Decimal; TotalAmountWithoutDiscount: Decimal; SalesOrder: TestPage "Sales Order"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        DiscAmt: Decimal;
        TotalAmount: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);

        DiscAmt := TotalAmountWithoutDiscount * DiscPct / 100;
        RoundAmount(DiscAmt, CurrencyCode);

        TotalAmount := TotalAmountWithoutDiscount - DiscAmt;

        SalesOrder.SalesLines."Invoice Disc. Pct.".AssertEquals(DiscPct);
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(DiscAmt);

        CheckTotals(
          TotalAmount, VATApplied, SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesOrder.SalesLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckOrderDiscountTypeAmount(InvoiceDiscAmt: Decimal; TotalAmountWithoutDiscount: Decimal; SalesOrder: TestPage "Sales Order"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        DiscPct := Round(InvoiceDiscAmt * 100 / TotalAmountWithoutDiscount, 0.01);

        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);
        RoundAmount(InvoiceDiscAmt, CurrencyCode);

        Assert.AreEqual(
          DiscPct, Round(SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(), 0.01),
          'Wrong Customer Discount Percentage for Invoice Discount Type Amount');
        Assert.AreEqual(
          InvoiceDiscAmt, SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          'Invoice Discount Amount was not set to correct value');

        TotalAmount := TotalAmountWithoutDiscount - InvoiceDiscAmt;
        CheckTotals(
          TotalAmount, VATApplied, SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesOrder.SalesLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckTotals(ExpectedAmountExclVAT: Decimal; VATApplied: Boolean; ActualAmountInclVAT: Decimal; ActualAmountExclVAT: Decimal; ActualVATAmount: Decimal)
    begin
        Assert.AreNearlyEqual(ExpectedAmountExclVAT, ActualAmountExclVAT, 0.12, 'Totals Amount was not updated correctly');

        if VATApplied then
            Assert.IsTrue(ActualAmountInclVAT > ActualAmountExclVAT, 'Totals Amount Incl. VAT was not updated correctly')
        else
            Assert.AreEqual(ActualAmountInclVAT, ActualAmountExclVAT, 'Totals Amount Incl. VAT was not updated correctly');

        Assert.AreEqual(ActualAmountInclVAT - ActualAmountExclVAT, ActualVATAmount, 'Total VAT Amount was not updated correctly');
    end;

    local procedure QuoteCheckCurrencyOnTotals(SalesQuote: TestPage "Sales Quote"; ExpectedCurrencySign: Code[10])
    begin
        Assert.AreNotEqual(
          0, StrPos(SalesQuote.SalesLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign),
          'Currency sign is wrong on totals for Amount Exc. VAT');
        Assert.AreNotEqual(
          0, StrPos(SalesQuote.SalesLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign),
          'Currency sign is wrong on totals for Amount Inc. VAT');
        Assert.AreNotEqual(
          0, StrPos(SalesQuote.SalesLines."Total VAT Amount".Caption, ExpectedCurrencySign),
          'Currency sign is wrong on totals for VAT Amount');
    end;

    local procedure OrderCheckCurrencyOnTotals(SalesOrder: TestPage "Sales Order"; ExpectedCurrencySign: Code[10])
    begin
        Assert.AreNotEqual(
          0, StrPos(SalesOrder.SalesLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign),
          'Currency sign is wrong on totals for Amount Exc. VAT');
        Assert.AreNotEqual(
          0, StrPos(SalesOrder.SalesLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign),
          'Currency sign is wrong on totals for Amount Inc. VAT');
        Assert.AreNotEqual(
          0, StrPos(SalesOrder.SalesLines."Total VAT Amount".Caption, ExpectedCurrencySign),
          'Currency sign is wrong on totals for VAT Amount');
    end;

    local procedure GetDifferentCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Init();
        Currency.SetFilter(Code, '<>%1', LibraryERM.GetLCYCode());
        Currency.FindFirst();
        CheckExistOrAddCurrencyExchageRate(Currency.Code);

        exit(Currency.Code);
    end;

    local procedure CreateQuoteWithOneLineThroughTestPage(Customer: Record Customer; Item: Record Item; ItemQuantity: Integer; var SalesQuote: TestPage "Sales Quote")
    begin
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);

        SalesQuote.SalesLines.First();
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesQuote.SalesLines.Next();
        SalesQuote.SalesLines.Previous();
    end;

    local procedure CreateOrderWithOneLineThroughTestPage(Customer: Record Customer; Item: Record Item; ItemQuantity: Integer; var SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);

        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines."No.".SetValue(Item."No.");
        SalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.Previous();
    end;

    local procedure OpenSalesQuote(SalesHeader: Record "Sales Header"; var SalesQuote: TestPage "Sales Quote")
    begin
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.SalesLines.Next();
    end;

    local procedure OpenSalesOrder(SalesHeader: Record "Sales Header"; var SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesReturnOrder(SalesHeader: Record "Sales Header"; var SalesReturnOrder: TestPage "Sales Return Order")
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesBlanketOrder(SalesHeader: Record "Sales Header"; var BlanketSalesOrder: TestPage "Blanket Sales Order")
    begin
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);
    end;

    local procedure CreateQuoteWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer; ItemQuantity: Decimal; var NumberOfLines: Integer)
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 30);

        CreateSalesHeaderWithDocTypeAndNumberOfLines(
          SalesHeader, Item, Customer, ItemQuantity, NumberOfLines, SalesHeader."Document Type"::Quote);
    end;

    local procedure CreateOrderWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer; ItemQuantity: Decimal; var NumberOfLines: Integer)
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        CreateSalesHeaderWithDocTypeAndNumberOfLines(
          SalesHeader, Item, Customer, ItemQuantity, NumberOfLines, SalesHeader."Document Type"::Order);
    end;

    local procedure CreateSalesHeaderWithDocTypeAndNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer; ItemQuantity: Decimal; NumberOfLines: Integer; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");

        for I := 1 to NumberOfLines do
            LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, ItemQuantity);
    end;

    local procedure RoundAmount(var Amount: Decimal; CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then begin
            Currency.SetFilter(Code, CurrencyCode);
            Currency.FindFirst();
            Amount := Round(Amount, Currency."Amount Rounding Precision");
        end else
            Amount := Round(Amount, LibraryERM.GetAmountRoundingPrecision());
    end;

    local procedure SetupDataForDiscountTypePct(var Item: Record Item; var ItemQuantity: Decimal; var Customer: Record Customer; var DiscPct: Decimal)
    var
        MinAmt: Decimal;
        ItemUnitPrice: Decimal;
    begin
        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemUnitPrice, ItemUnitPrice * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);

        CreateItem(Item, ItemUnitPrice);
        CreateCustomerWithDiscount(Customer, DiscPct, MinAmt);
    end;

    local procedure SetupDataForDiscountTypeAmt(var Item: Record Item; var ItemQuantity: Decimal; var Customer: Record Customer; var InvoiceDiscountAmount: Decimal)
    var
        DiscPct: Decimal;
    begin
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(1, Round(Item."Unit Price" * ItemQuantity, 1, '<'), 2);
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
}

