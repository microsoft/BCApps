codeunit 138004 "O365 Sales Totals Invoice/Cr.M"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Invoice Discount] [SMB] [Sales]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        ChangeConfirmMsg: Label 'Do you want';
        PostMsg: Label 'post';
        OpenPostedInvMsg: Label 'Do you want to open';
        LeaveDocWithoutPostingTxt: Label 'This document is not posted.';
        FieldShouldBeEditableTxt: Label 'Field should be editable.';
        FieldShouldNotBeEditableTxt: Label 'Field should not be editable.';

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
        ItemNoSeries: Text[20];
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Sales Totals Invoice/Cr.M");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Sales Totals Invoice/Cr.M");

        ClearTable(DATABASE::"Res. Ledger Entry");

        SalesSetup.Get();
        SalesSetup."Stockout Warning" := false;
        SalesSetup.Modify();

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        InventorySetup.Get();
        ItemNoSeries := LibraryUtility.GetGlobalNoSeriesCode();
        if InventorySetup."Item Nos." <> ItemNoSeries then begin
            InventorySetup.Validate("Item Nos.", ItemNoSeries);
            InventorySetup.Modify();
        end;

        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Sales Totals Invoice/Cr.M");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::"Res. Ledger Entry":
                ResLedgerEntry.DeleteAll();
            DATABASE::"Warehouse Entry":
                WarehouseEntry.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    [Test]
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

        CreateInvoceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);

        CheckTotals(
          ItemQuantity * Item."Unit Price", true, SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesInvoice.SalesLines."Total VAT Amount".AsDecimal());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateInvoceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();

        CheckInvoiceDiscountTypePercentage(DiscPct, ItemQuantity * Item."Unit Price", SalesInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
        NewLineAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateInvoceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();

        ItemQuantity := ItemQuantity * 2;
        SalesInvoice.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();
        TotalAmount := ItemQuantity * Item."Unit Price";
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, SalesInvoice, true, '');

        SalesInvoice.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        SalesInvoice.CalculateInvoiceDiscount.Invoke();
        TotalAmount := 2 * TotalAmount;
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, SalesInvoice, true, '');

        NewLineAmount := Round(SalesInvoice.SalesLines."Line Amount".AsDecimal() / 100 * DiscPct, 1);
        SalesInvoice.SalesLines."Line Amount".SetValue(NewLineAmount);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();
        CheckInvoiceDiscountTypePercentage(DiscPct, NewLineAmount, SalesInvoice, true, '');

        SalesInvoice.SalesLines."Line Discount %".SetValue('0');
        SalesInvoice.CalculateInvoiceDiscount.Invoke();
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, SalesInvoice, true, '');

        SalesInvoice.SalesLines."No.".SetValue('');
        SalesInvoice.CalculateInvoiceDiscount.Invoke();
        TotalAmount := 0;
        CheckInvoiceDiscountTypePercentage(0, TotalAmount, SalesInvoice, false, '');

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesInvoice."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesTotalsAndKeepsInvDiscTypeAmount()
    var
        Customer: Record Customer;
        Item: Record Item;
        Item2: Record Item;
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateInvoceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);

        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        ItemQuantity := ItemQuantity * 2;
        SalesInvoice.SalesLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Price";
        Assert.AreNotEqual(TotalAmount, SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          'The value should not be equal');

        SalesInvoice.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        TotalAmount := 2 * TotalAmount;
        Assert.AreNotEqual(TotalAmount, SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          'The value should not be equal');

        SalesInvoice.SalesLines."Line Amount".SetValue(SalesInvoice.SalesLines."Line Amount".AsDecimal());
        Assert.AreNotEqual(TotalAmount, SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          'The value should not be equal');

        SalesInvoice.SalesLines."Line Discount %".SetValue('0');
        Assert.AreNotEqual(TotalAmount, SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          'The value should not be equal');

        CreateItem(Item2, Item."Unit Price" / 2);

        TotalAmount := Item2."Unit Price" * ItemQuantity;
        SalesInvoice.SalesLines."No.".SetValue(Item2."No.");
        Assert.AreNotEqual(TotalAmount, SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          'The value should not be equal');

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesInvoice."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvioceDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        OpenSalesInvoice(SalesHeader, SalesInvoice);

        TotalAmount := Item."Unit Price" * ItemQuantity * NumberOfLines;
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, SalesInvoice, true, '');
    end;

    [Test]
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
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        OpenSalesInvoice(SalesHeader, SalesInvoice);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckInvoiceDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceChangingVATBusPostingGroupUpdatesTotalsAndDiscounts()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        LibraryApplicationArea.EnableVATSetup();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToConfirmDialog();
        SalesInvoice."VAT Bus. Posting Group".SetValue(
          LibrarySmallBusiness.FindVATBusPostingGroupZeroVAT(Item."VAT Prod. Posting Group"));

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, SalesInvoice, false, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
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

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        SalesInvoice."Sell-to Customer Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckInvoiceDiscountTypePercentage(NewCustDiscPct, TotalAmount, SalesInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
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
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        CreateCustomer(NewCustomer);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();

        SalesInvoice."Sell-to Customer Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckInvoiceDiscountTypeAmount(0, TotalAmount, SalesInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangeSellToCustomerToCustomerWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        CreateCustomer(NewCustomer);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();

        SalesInvoice."Sell-to Customer Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckInvoiceDiscountTypePercentage(0, TotalAmount, SalesInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceChangingBillToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
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

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();
        SalesInvoice."Bill-to Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckInvoiceDiscountTypePercentage(NewCustomerDiscPct, TotalAmount, SalesInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingBillToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        CreateCustomer(NewCustomer);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToAllConfirmDialogs();
        SalesInvoice."Bill-to Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckInvoiceDiscountTypeAmount(0, TotalAmount, SalesInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingCurrencyUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToConfirmDialog();
        SalesInvoice."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        TotalAmount := NumberOfLines * SalesLine."Line Amount";
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, SalesInvoice, true, SalesInvoice."Currency Code".Value);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingCurrencySetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        AnswerYesToConfirmDialog();
        SalesInvoice."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        TotalAmount := NumberOfLines * SalesLine."Line Amount";
        CheckInvoiceDiscountTypeAmount(0, TotalAmount, SalesInvoice, true, SalesInvoice."Currency Code".Value);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoicePostSalesInvoiceOpensDialogAndPostedInvoice()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();

        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateInvoceWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesInvoice);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        LibraryVariableStorage.Enqueue(PostMsg);
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue(OpenPostedInvMsg);
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue(LeaveDocWithoutPostingTxt);
        LibraryVariableStorage.Enqueue(true);

        PostedSalesInvoice.Trap();
        LibrarySales.EnableConfirmOnPostingDoc();
        SalesInvoice.Post.Invoke();

        TotalAmount := Item."Unit Price" * ItemQuantity;
        CheckPostedInvoiceDiscountAmountAndTotals(InvoiceDiscountAmount, TotalAmount, PostedSalesInvoice, true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceTotalsAreCalculatedWhenPostedInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        SalesInvoiceHeader.SetFilter("Pre-Assigned No.", SalesHeader."No.");
        Assert.IsTrue(SalesInvoiceHeader.FindFirst(), 'Posted Invoice was not found');

        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        InvoiceDiscountAmount := TotalAmount * DiscPct / 100;

        CheckPostedInvoiceDiscountAmountAndTotals(InvoiceDiscountAmount, TotalAmount, PostedSalesInvoice, true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceSetLocalCurrencySignOnTotals()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesInvoice: TestPage "Sales Invoice";
        ItemUnitPrice: Decimal;
    begin
        Initialize();

        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        Customer."Currency Code" := GetDifferentCurrencyCode();
        Customer.Modify(true);
        SalesInvoice.OpenNew();

        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);
        InvoiceCheckCurrencyOnTotals(SalesInvoice, Customer."Currency Code");

        SalesInvoice.SalesLines.New();
        InvoiceCheckCurrencyOnTotals(SalesInvoice, Customer."Currency Code");

        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        InvoiceCheckCurrencyOnTotals(SalesInvoice, Customer."Currency Code");
    end;

    [Test]
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

        CheckTotals(
          ItemQuantity * Item."Unit Price", true, SalesCreditMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemQuantity: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);
        SalesCreditMemo.CalculateInvoiceDiscount.Invoke();

        CheckCreditMemoDiscountTypePercentage(DiscPct, ItemQuantity * Item."Unit Price", SalesCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ItemUOM: Record "Item Unit of Measure";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
        NewLineAmount: Decimal;
    begin
        Initialize();
        ClearTable(DATABASE::"Warehouse Entry");
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);

        ItemQuantity := ItemQuantity * 2;
        SalesCreditMemo.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesCreditMemo.CalculateInvoiceDiscount.Invoke();
        TotalAmount := ItemQuantity * Item."Unit Price";
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, SalesCreditMemo, true, '');

        SalesCreditMemo.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        SalesCreditMemo.CalculateInvoiceDiscount.Invoke();
        TotalAmount := 2 * TotalAmount;
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, SalesCreditMemo, true, '');

        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", 5);

        SalesCreditMemo.SalesLines."Unit of Measure Code".SetValue(ItemUOM.Code);
        SalesCreditMemo.CalculateInvoiceDiscount.Invoke();
        TotalAmount := ItemQuantity * Item."Unit Price" * 5;
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, SalesCreditMemo, true, '');

        NewLineAmount := Round(SalesCreditMemo.SalesLines."Line Amount".AsDecimal() / 100 * 2, 1);
        SalesCreditMemo.SalesLines."Line Amount".SetValue(NewLineAmount);
        SalesCreditMemo.CalculateInvoiceDiscount.Invoke();
        CheckCreditMemoDiscountTypePercentage(DiscPct, NewLineAmount, SalesCreditMemo, true, '');

        SalesCreditMemo.SalesLines."Line Discount %".SetValue('0');
        SalesCreditMemo.CalculateInvoiceDiscount.Invoke();
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, SalesCreditMemo, true, '');

        SalesCreditMemo.SalesLines."No.".SetValue('');
        SalesCreditMemo.CalculateInvoiceDiscount.Invoke();
        TotalAmount := 0;
        CheckCreditMemoDiscountTypePercentage(0, TotalAmount, SalesCreditMemo, false, '');

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesCreditMemo."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoModifyingLineUpdatesTotalsAndKeepsInvDiscTypeAmount()
    var
        Customer: Record Customer;
        Item: Record Item;
        Item2: Record Item;
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);

        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        ItemQuantity := ItemQuantity * 2;
        SalesCreditMemo.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.Previous();

        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        TotalAmount := ItemQuantity * Item."Unit Price";
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesCreditMemo, true, '');

        SalesCreditMemo.SalesLines."Unit Price".SetValue(2 * Item."Unit Price");
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.Previous();
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        TotalAmount := 2 * TotalAmount;
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesCreditMemo, true, '');

        TotalAmount := TotalAmount / 2;
        SalesCreditMemo.SalesLines."Line Amount".SetValue(TotalAmount);
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.Previous();
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesCreditMemo, true, '');

        SalesCreditMemo.SalesLines."Line Discount %".SetValue('0');
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.Previous();
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        TotalAmount := TotalAmount * 2;
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesCreditMemo, true, '');

        CreateItem(Item2, Item."Unit Price" / 2);

        TotalAmount := Item2."Unit Price" * ItemQuantity;
        SalesCreditMemo.SalesLines."No.".SetValue(Item2."No.");
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.Previous();
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesCreditMemo, true, '');
        Assert.AreEqual(
          InvoiceDiscountAmount, SalesCreditMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          'Invoice discount amount has been changed');

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesCreditMemo."No.".Value);
        SalesLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoInvioceDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        TotalAmount := Item."Unit Price" * ItemQuantity * NumberOfLines;
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, SalesCreditMemo, true, '');
    end;

    [Test]
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
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingVATBusPostingGroupUpdatesTotalsAndDiscounts()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        LibraryApplicationArea.EnableVATSetup();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);

        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        SalesCreditMemo."VAT Bus. Posting Group".SetValue(
          LibrarySmallBusiness.FindVATBusPostingGroupZeroVAT(Item."VAT Prod. Posting Group"));

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, SalesCreditMemo, false, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingSellToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
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

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        SalesCreditMemo."Sell-to Customer Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckCreditMemoDiscountTypePercentage(NewCustDiscPct, TotalAmount, SalesCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
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
        TotalAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCustomerWithDiscount(NewCustomer, NewCustDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        SalesCreditMemo."Sell-to Customer Name".SetValue(NewCustomer.Name);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
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
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        CreateCustomer(NewCustomer);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        AnswerYesToAllConfirmDialogs();

        SalesCreditMemo."Sell-to Customer Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckCreditMemoDiscountTypePercentage(0, TotalAmount, SalesCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingBillToCustomerRecalculatesForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
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

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        SalesCreditMemo."Bill-to Name".SetValue(NewCustomer.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckCreditMemoDiscountTypePercentage(NewCustomerDiscPct, TotalAmount, SalesCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingBillToCustomerSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        NewCustomer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
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

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        SalesCreditMemo."Bill-to Name".SetValue(NewCustomer.Name);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingCurrencyUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        SalesCreditMemo."Currency Code".SetValue(GetDifferentCurrencyCode());

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        TotalAmount := NumberOfLines * SalesLine."Line Amount";
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, SalesCreditMemo, true, SalesCreditMemo."Currency Code".Value);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingCurrencySetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        SalesCreditMemo."Currency Code".SetValue(GetDifferentCurrencyCode());
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        TotalAmount := NumberOfLines * SalesLine."Line Amount";
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, SalesCreditMemo, true, SalesCreditMemo."Currency Code".Value);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoPostSalesInvoiceOpensDialogAndPostedInvoice()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Customer, InvoiceDiscountAmount);

        CreateCreditMemoWithOneLineThroughTestPage(Customer, Item, ItemQuantity, SalesCreditMemo);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        LibraryVariableStorage.Enqueue(PostMsg);
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue(OpenPostedInvMsg);
        LibraryVariableStorage.Enqueue(true);

        PostedSalesCreditMemo.Trap();
        LibrarySales.EnableConfirmOnPostingDoc();
        SalesCreditMemo.Post.Invoke();

        TotalAmount := Item."Unit Price" * ItemQuantity;
        CheckPostedCreditMemoDiscountAmountAndTotals(InvoiceDiscountAmount, TotalAmount, PostedSalesCreditMemo, true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoCreditTotalsAreCalculatedWhenPostedInvoiceIsOpened()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);

        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, ItemQuantity, NumberOfLines);
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.OK().Invoke();

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        SalesCrMemoHeader.SetFilter("Pre-Assigned No.", SalesHeader."No.");
        Assert.IsTrue(SalesCrMemoHeader.FindFirst(), 'Posted CreditMemo was not found');

        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Price";
        InvoiceDiscountAmount := TotalAmount * DiscPct / 100;

        CheckPostedCreditMemoDiscountAmountAndTotals(InvoiceDiscountAmount, TotalAmount, PostedSalesCreditMemo, true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoSetLocalCurrencySignOnTotals()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemUnitPrice: Decimal;
    begin
        Initialize();

        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        Customer."Currency Code" := GetDifferentCurrencyCode();
        Customer.Modify(true);
        SalesCreditMemo.OpenNew();

        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);
        CreditMemoCheckCurrencyOnTotals(SalesCreditMemo, Customer."Currency Code");

        SalesCreditMemo.SalesLines.New();
        CreditMemoCheckCurrencyOnTotals(SalesCreditMemo, Customer."Currency Code");

        SalesCreditMemo.SalesLines."No.".SetValue(Item."No.");
        CreditMemoCheckCurrencyOnTotals(SalesCreditMemo, Customer."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEditableStateForInvoiceDiscountFields()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        SalesQuote: TestPage "Sales Quote";
        SalesInvoice: TestPage "Sales Invoice";
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        CreateCustomer(Customer);
        CreateItem(Item, LibraryRandom.RandDec(100, 2));

        CreateQuoteWithOneLineThroughTestPage(Customer, Item, LibraryRandom.RandInt(10), SalesQuote);

        Assert.IsTrue(SalesQuote.SalesLines."Invoice Disc. Pct.".Editable(), FieldShouldBeEditableTxt);
        Assert.IsTrue(SalesQuote.SalesLines."Invoice Discount Amount".Editable(), FieldShouldBeEditableTxt);

        SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuote."No.".Value());
        SalesQuote.Close();

        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        Assert.IsFalse(SalesQuote.SalesLines."Invoice Disc. Pct.".Editable(), FieldShouldNotBeEditableTxt);
        Assert.IsFalse(SalesQuote.SalesLines."Invoice Discount Amount".Editable(), FieldShouldNotBeEditableTxt);
        SalesQuote.Close();

        CreateInvoceWithOneLineThroughTestPage(Customer, Item, LibraryRandom.RandInt(10), SalesInvoice);

        Assert.IsTrue(SalesInvoice.SalesLines."Invoice Disc. Pct.".Editable(), FieldShouldBeEditableTxt);
        Assert.IsTrue(SalesInvoice.SalesLines."Invoice Discount Amount".Editable(), FieldShouldBeEditableTxt);

        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoice."No.".Value());
        SalesInvoice.Close();

        CreateOrderWithOneLineThroughTestPage(Customer, Item, LibraryRandom.RandInt(10), SalesOrder);

        Assert.IsTrue(SalesOrder.SalesLines."Invoice Disc. Pct.".Editable(), FieldShouldBeEditableTxt);
        Assert.IsTrue(SalesOrder.SalesLines."Invoice Discount Amount".Editable(), FieldShouldBeEditableTxt);

        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrder."No.".Value());
        SalesOrder.Close();

        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        Assert.IsFalse(SalesOrder.SalesLines."Invoice Disc. Pct.".Editable(), FieldShouldNotBeEditableTxt);
        Assert.IsFalse(SalesOrder.SalesLines."Invoice Discount Amount".Editable(), FieldShouldNotBeEditableTxt);
        SalesOrder.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoiceBillToNameValidationSavesBilltoICPartnerChange()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        ItemUnitPrice: Decimal;
        Lines: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Bill-to IC Partner Code" is changed on Sales Invoice "Bill-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();

        // [GIVEN] Sales Invoice "SI01" with Sales Lines created for Customer "CU01" and no discount
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        CreateInvoiceWithRandomNumberOfLines(SalesHeader, Item, Customer, 1, Lines);
        OpenSalesInvoice(SalesHeader, SalesInvoice);

        // [GIVEN] Customer "CU02" with "IC Partner Code" = "ICP01"
        CreateCustomer(Customer);
        Customer."IC Partner Code" := LibraryUtility.GenerateGUID();
        Customer.Modify(true);

        // [WHEN] Set "Bill-to Name" to "CU02" on Sales Invoice Page for "SI01"
        SalesInvoice."Bill-to Name".SetValue(Customer."No.");

        // [THEN] "Bill-to IC Partner Code" is changed to "ICP01" on "SI01"
        SalesHeader.Find();
        SalesHeader.TestField("Bill-to IC Partner Code", Customer."IC Partner Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CrMemoBillToNameValidationSavesBilltoICPartnerChange()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemUnitPrice: Decimal;
        Lines: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Bill-to IC Partner Code" is changed on Sales Credit Memo "Bill-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();

        // [GIVEN] Sales Credit Memo "SC01" with Sales Lines created for Customer "CU01" and no discount
        ItemUnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitPrice);
        CreateCustomer(Customer);
        CreateCreditMemoWithRandomNumberOfLines(SalesHeader, Item, Customer, 1, Lines);
        OpenSalesCreditMemo(SalesHeader, SalesCreditMemo);

        // [GIVEN] Customer "CU02" with "IC Partner Code" = "ICP01"
        CreateCustomer(Customer);
        Customer."IC Partner Code" := LibraryUtility.GenerateGUID();
        Customer.Modify(true);

        // [WHEN] Set "Bill-to Name" to "CU02" on Sales Credit Memo Page for "SC01"
        SalesCreditMemo."Bill-to Name".SetValue(Customer."No.");

        // [THEN] "Bill-to IC Partner Code" is changed to "ICP01" on "SC01"
        SalesHeader.Find();
        SalesHeader.TestField("Bill-to IC Partner Code", Customer."IC Partner Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure RecurringSalesLinesInvoiceDiscountCalculations()
    var
        Customer: Record Customer;
        Item: Record Item;
        StandardSalesCode: Record "Standard Sales Code";
        StandardSalesLine: Record "Standard Sales Line";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] When automatic recurring sales lines are added to sales order, the discount is calculated properly.
        Initialize();

        // [GIVEN] Customer with 5 % discount for min. ammount of 10.
        CreateCustomerWithDiscount(Customer, 5, 10);

        // [GIVEN] A recurring sales line for customer with item costing 100 and quantity set to 1.
        CreateItem(Item, 100);
        LibrarySales.CreateStandardSalesCode(StandardSalesCode);
        LibrarySales.CreateStandardSalesLine(StandardSalesLine, StandardSalesCode.Code);
        StandardSalesLine.Validate(Type, StandardSalesLine.Type::Item);
        StandardSalesLine.Validate("No.", Item."No.");
        StandardSalesLine.Validate(Quantity, 1);
        StandardSalesLine.Modify(true);
        LibrarySmallBusiness.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer."No.", StandardSalesCode.Code);
        StandardCustomerSalesCode.Validate(
            "Insert Rec. Lines On Orders", StandardCustomerSalesCode."Insert Rec. Lines On Orders"::Automatic
        );
        StandardCustomerSalesCode.Modify(true);

        // [WHEN] Creating a new sales order for the customer and calculating discount amount.
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer."No.");
        SalesOrder.CalculateInvoiceDiscount.Invoke();

        // [THEN] The discount is applied to to the inserted sales line.
        Assert.AreEqual(5, SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(), 'Expected discount to be applied.');
        Assert.AreEqual(95, SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(), 'Expected discount to be applied.');
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
          Round(DiscPct, 0.01), Round(SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(), 0.01),
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

    local procedure CheckCreditMemoDiscountTypePercentage(DiscPct: Decimal; TotalAmountWithoutDiscount: Decimal; SalesCreditMemo: TestPage "Sales Credit Memo"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        DiscAmt: Decimal;
        TotalAmount: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);

        DiscAmt := TotalAmountWithoutDiscount * DiscPct / 100;
        RoundAmount(DiscAmt, CurrencyCode);

        TotalAmount := TotalAmountWithoutDiscount - DiscAmt;

        SalesCreditMemo.SalesLines."Invoice Disc. Pct.".AssertEquals(DiscPct);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".AssertEquals(DiscAmt);

        CheckTotals(
          TotalAmount, VATApplied, SalesCreditMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckCreditMemoDiscountTypeAmount(InvoiceDiscAmt: Decimal; TotalAmountWithoutDiscount: Decimal; SalesCreditMemo: TestPage "Sales Credit Memo"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        DiscPct := Round(InvoiceDiscAmt * 100 / TotalAmountWithoutDiscount, 0.00001);

        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);
        RoundAmount(InvoiceDiscAmt, CurrencyCode);

        SalesCreditMemo.SalesLines."Invoice Disc. Pct.".AssertEquals(DiscPct);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".AssertEquals(InvoiceDiscAmt);

        TotalAmount := TotalAmountWithoutDiscount - InvoiceDiscAmt;
        CheckTotals(
          TotalAmount, VATApplied, SalesCreditMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(), SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckPostedInvoiceDiscountAmountAndTotals(InvoiceDiscAmt: Decimal; TotalAmountWithoutDiscount: Decimal; PostedSalesInvoice: TestPage "Posted Sales Invoice"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        TotalAmount: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);
        RoundAmount(InvoiceDiscAmt, CurrencyCode);

        PostedSalesInvoice.SalesInvLines."Invoice Discount Amount".AssertEquals(InvoiceDiscAmt);

        TotalAmount := TotalAmountWithoutDiscount - InvoiceDiscAmt;
        CheckTotals(
          TotalAmount, VATApplied, PostedSalesInvoice.SalesInvLines."Total Amount Incl. VAT".AsDecimal(),
          PostedSalesInvoice.SalesInvLines."Total Amount Excl. VAT".AsDecimal(),
          PostedSalesInvoice.SalesInvLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckPostedCreditMemoDiscountAmountAndTotals(InvoiceDiscAmt: Decimal; TotalAmountWithoutDiscount: Decimal; PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        TotalAmount: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);
        RoundAmount(InvoiceDiscAmt, CurrencyCode);

        PostedSalesCreditMemo.SalesCrMemoLines."Invoice Discount Amount".AssertEquals(InvoiceDiscAmt);

        TotalAmount := TotalAmountWithoutDiscount - InvoiceDiscAmt;
        CheckTotals(
          TotalAmount, VATApplied, PostedSalesCreditMemo.SalesCrMemoLines."Total Amount Incl. VAT".AsDecimal(),
          PostedSalesCreditMemo.SalesCrMemoLines."Total Amount Excl. VAT".AsDecimal(),
          PostedSalesCreditMemo.SalesCrMemoLines."Total VAT Amount".AsDecimal());
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

    local procedure InvoiceCheckCurrencyOnTotals(SalesInvoice: TestPage "Sales Invoice"; ExpectedCurrencySign: Code[10])
    begin
        Assert.AreNotEqual(
          0, StrPos(SalesInvoice.SalesLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign),
          'Currency sign is wrong on totals for Amount Exc. VAT');
        Assert.AreNotEqual(
          0, StrPos(SalesInvoice.SalesLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign),
          'Currency sign is wrong on totals for Amount Inc. VAT');
        Assert.AreNotEqual(
          0, StrPos(SalesInvoice.SalesLines."Total VAT Amount".Caption, ExpectedCurrencySign),
          'Currency sign is wrong on totals for VAT Amount');
    end;

    local procedure CreditMemoCheckCurrencyOnTotals(SalesCreditMemo: TestPage "Sales Credit Memo"; ExpectedCurrencySign: Code[10])
    begin
        Assert.AreNotEqual(
          0, StrPos(SalesCreditMemo.SalesLines."Total Amount Excl. VAT".Caption, ExpectedCurrencySign),
          'Currency sign is wrong on totals for Amount Exc. VAT');
        Assert.AreNotEqual(
          0, StrPos(SalesCreditMemo.SalesLines."Total Amount Incl. VAT".Caption, ExpectedCurrencySign),
          'Currency sign is wrong on totals for Amount Inc. VAT');
        Assert.AreNotEqual(
          0, StrPos(SalesCreditMemo.SalesLines."Total VAT Amount".Caption, ExpectedCurrencySign),
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

    local procedure CreateInvoceWithOneLineThroughTestPage(Customer: Record Customer; Item: Record Item; ItemQuantity: Integer; var SalesInvoice: TestPage "Sales Invoice")
    begin
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);

        SalesInvoice.SalesLines.First();
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        SalesInvoice.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesInvoice.SalesLines.Next();
        SalesInvoice.SalesLines.Previous();
    end;

    local procedure CreateCreditMemoWithOneLineThroughTestPage(Customer: Record Customer; Item: Record Item; ItemQuantity: Integer; var SalesCreditMemo: TestPage "Sales Credit Memo")
    begin
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);

        SalesCreditMemo.SalesLines.First();
        SalesCreditMemo.SalesLines."No.".SetValue(Item."No.");
        SalesCreditMemo.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesCreditMemo.SalesLines.Next();
        SalesCreditMemo.SalesLines.Previous();
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

    local procedure OpenSalesInvoice(SalesHeader: Record "Sales Header"; var SalesInvoice: TestPage "Sales Invoice")
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesCreditMemo(SalesHeader: Record "Sales Header"; var SalesCreditMemo: TestPage "Sales Credit Memo")
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
    end;

    local procedure CreateInvoiceWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 30);

        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);

        for I := 1 to NumberOfLines do
            LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, ItemQuantity);
    end;

    local procedure CreateCreditMemoWithRandomNumberOfLines(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Customer: Record Customer; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 30);

        LibrarySmallBusiness.CreateSalesCrMemoHeader(SalesHeader, Customer);

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
        ItemUnitPrice: Decimal;
    begin
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(1, Round(Item."Unit Price" * ItemQuantity, 1, '<'), 2);

        CreateCustomer(Customer);
        CreateItem(Item, ItemUnitPrice);
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

